import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/api_constants.dart';
import '../storage/secure_storage.dart';
import '../storage/local_storage.dart';
import 'local_notification.dart';

enum FCMTopicType {
  allUsers,
  announcements,
  groupUpdates,
  callNotifications,
  statusUpdates,
}

class FCMService {
  static FCMService? _instance;

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final SecureStorage _secureStorage = SecureStorage();
  final LocalStorage _localStorage = LocalStorage();
  late LocalNotificationService _localNotificationService;
  late Dio _dio;

  // Streams for handling messages
  final StreamController<RemoteMessage> _messageController =
      StreamController<RemoteMessage>.broadcast();
  final StreamController<String> _tokenController =
      StreamController<String>.broadcast();

  // Current FCM token
  String? _currentToken;
  bool _isInitialized = false;

  FCMService._internal();

  factory FCMService() {
    _instance ??= FCMService._internal();
    return _instance!;
  }

  // Getters
  Stream<RemoteMessage> get messageStream => _messageController.stream;
  Stream<String> get tokenStream => _tokenController.stream;
  String? get currentToken => _currentToken;
  bool get isInitialized => _isInitialized;

  Future<void> initialize({
    required LocalNotificationService localNotificationService,
    required Dio dio,
  }) async {
    if (_isInitialized) return;

    try {
      _localNotificationService = localNotificationService;
      _dio = dio;

      // Request notification permissions
      await _requestPermissions();

      // Configure FCM
      await _configureFCM();

      // Get and handle FCM token
      await _handleTokenRefresh();

      // Set up message handlers
      _setupMessageHandlers();

      // Subscribe to default topics
      await _subscribeToDefaultTopics();

      _isInitialized = true;

      if (kDebugMode) {
        print('✅ FCM Service initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing FCM Service: $e');
      }
      rethrow;
    }
  }

  Future<void> _requestPermissions() async {
    try {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (kDebugMode) {
        print('FCM Permission Status: ${settings.authorizationStatus}');
      }

      // Save permission status
      await _localStorage.setString(
        'fcm_permission_status',
        settings.authorizationStatus.name,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error requesting FCM permissions: $e');
      }
    }
  }

  Future<void> _configureFCM() async {
    try {
      // Configure FCM options
      if (Platform.isIOS) {
        await _firebaseMessaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      // Configure auto initialization
      await _firebaseMessaging.setAutoInitEnabled(true);

      if (kDebugMode) {
        print('✅ FCM configured successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error configuring FCM: $e');
      }
    }
  }

  Future<void> _handleTokenRefresh() async {
    try {
      // Get current token
      _currentToken = await _firebaseMessaging.getToken();

      if (_currentToken != null) {
        await _saveFCMToken(_currentToken!);
        await _sendTokenToServer(_currentToken!);
        _tokenController.add(_currentToken!);

        if (kDebugMode) {
          print('📱 FCM Token: $_currentToken');
        }
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((String token) async {
        _currentToken = token;
        await _saveFCMToken(token);
        await _sendTokenToServer(token);
        _tokenController.add(token);

        if (kDebugMode) {
          print('🔄 FCM Token refreshed: $token');
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling token refresh: $e');
      }
    }
  }

  Future<void> _saveFCMToken(String token) async {
    try {
      await _secureStorage.saveFcmToken(token);
      await _localStorage.setString('fcm_token', token);
      await _localStorage.setString(
        'fcm_token_timestamp',
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving FCM token: $e');
      }
    }
  }

  Future<void> _sendTokenToServer(String token) async {
    try {
      final accessToken = await _secureStorage.getAccessToken();
      if (accessToken == null) return;

      final deviceId = await _secureStorage.getDeviceId();

      await _dio.post(
        '/api/auth/fcm-token',
        data: {
          'fcm_token': token,
          'device_id': deviceId,
          'platform': Platform.operatingSystem,
          'app_version': AppConfig.appVersion,
        },
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      if (kDebugMode) {
        print('✅ FCM token sent to server');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error sending FCM token to server: $e');
      }
    }
  }

  void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle message when app is opened from background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Handle message when app is launched from terminated state
    _handleInitialMessage();
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    try {
      if (kDebugMode) {
        print('📱 Foreground message received: ${message.messageId}');
        print('Data: ${message.data}');
      }

      // Add to stream
      _messageController.add(message);

      // Show local notification for foreground messages
      await _showLocalNotification(message);

      // Update badge count
      await _updateBadgeCount();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling foreground message: $e');
      }
    }
  }

  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    try {
      if (kDebugMode) {
        print('📱 App opened from notification: ${message.messageId}');
      }

      // Add to stream
      _messageController.add(message);

      // Handle notification action
      await _handleNotificationAction(message);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling message opened app: $e');
      }
    }
  }

  Future<void> _handleInitialMessage() async {
    try {
      final RemoteMessage? initialMessage = await _firebaseMessaging
          .getInitialMessage();

      if (initialMessage != null) {
        if (kDebugMode) {
          print(
            '📱 App launched from notification: ${initialMessage.messageId}',
          );
        }

        // Add to stream
        _messageController.add(initialMessage);

        // Handle notification action
        await _handleNotificationAction(initialMessage);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling initial message: $e');
      }
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      final notificationType = _getNotificationType(message.data);

      switch (notificationType) {
        case 'message':
          await _localNotificationService.showMessageNotification(
            title: message.notification?.title ?? 'New Message',
            body: message.notification?.body ?? '',
            chatId: message.data['chat_id'],
            senderId: message.data['sender_id'],
            senderName: message.data['sender_name'],
            messageType: message.data['message_type'] ?? 'text',
            payload: jsonEncode(message.data),
          );
          break;

        case 'call':
          await _localNotificationService.showCallNotification(
            title: message.notification?.title ?? 'Incoming Call',
            body: message.notification?.body ?? '',
            callId: message.data['call_id'],
            callerId: message.data['caller_id'],
            callerName: message.data['caller_name'],
            callType: message.data['call_type'] ?? 'voice',
            payload: jsonEncode(message.data),
          );
          break;

        case 'group':
          await _localNotificationService.showGroupNotification(
            title: message.notification?.title ?? 'Group Update',
            body: message.notification?.body ?? '',
            groupId: message.data['group_id'],
            groupName: message.data['group_name'],
            payload: jsonEncode(message.data),
          );
          break;

        case 'status':
          await _localNotificationService.showStatusNotification(
            title: message.notification?.title ?? 'Status Update',
            body: message.notification?.body ?? '',
            userId: message.data['user_id'],
            userName: message.data['user_name'],
            payload: jsonEncode(message.data),
          );
          break;

        default:
          await _localNotificationService.showGeneralNotification(
            title: message.notification?.title ?? 'Notification',
            body: message.notification?.body ?? '',
            payload: jsonEncode(message.data),
          );
          break;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error showing local notification: $e');
      }
    }
  }

  Future<void> _handleNotificationAction(RemoteMessage message) async {
    try {
      final notificationType = _getNotificationType(message.data);
      final action = message.data['action'];

      switch (notificationType) {
        case 'message':
          await _handleMessageNotificationAction(message.data, action);
          break;

        case 'call':
          await _handleCallNotificationAction(message.data, action);
          break;

        case 'group':
          await _handleGroupNotificationAction(message.data, action);
          break;

        case 'status':
          await _handleStatusNotificationAction(message.data, action);
          break;

        default:
          await _handleGenericNotificationAction(message.data, action);
          break;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling notification action: $e');
      }
    }
  }

  Future<void> _handleMessageNotificationAction(
    Map<String, dynamic> data,
    String? action,
  ) async {
    final chatId = data['chat_id'];
    if (chatId == null) return;

    switch (action) {
      case 'reply':
        // Navigate to chat screen
        // This would typically use your navigation service
        break;

      case 'mark_read':
        await _markChatAsRead(chatId);
        break;

      default:
        // Default action - open chat
        break;
    }
  }

  Future<void> _handleCallNotificationAction(
    Map<String, dynamic> data,
    String? action,
  ) async {
    final callId = data['call_id'];
    if (callId == null) return;

    switch (action) {
      case 'answer':
        // Handle call answer
        await _answerCall(callId);
        break;

      case 'decline':
        // Handle call decline
        await _declineCall(callId);
        break;

      default:
        // Default action - open call screen
        break;
    }
  }

  Future<void> _handleGroupNotificationAction(
    Map<String, dynamic> data,
    String? action,
  ) async {
    final groupId = data['group_id'];
    if (groupId == null) return;

    switch (action) {
      case 'view_group':
        // Navigate to group screen
        break;

      default:
        // Default action
        break;
    }
  }

  Future<void> _handleStatusNotificationAction(
    Map<String, dynamic> data,
    String? action,
  ) async {
    final userId = data['user_id'];
    if (userId == null) return;

    switch (action) {
      case 'view_status':
        // Navigate to status screen
        break;

      default:
        // Default action
        break;
    }
  }

  Future<void> _handleGenericNotificationAction(
    Map<String, dynamic> data,
    String? action,
  ) async {
    // Handle generic notification actions
    final url = data['url'];
    if (url != null) {
      // Open URL
    }
  }

  String _getNotificationType(Map<String, dynamic> data) {
    return data['type'] ?? data['notification_type'] ?? 'general';
  }

  Future<void> _updateBadgeCount() async {
    try {
      // Get unread count from local storage or API
      final unreadCount = await _getUnreadMessageCount();

      // Update badge through local notifications plugin
      await _localNotificationService.updateBadgeCount(unreadCount);

      // Save badge count
      await _localStorage.setInt('badge_count', unreadCount);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating badge count: $e');
      }
    }
  }

  Future<int> _getUnreadMessageCount() async {
    try {
      // This would typically call your API to get unread count
      return _localStorage.getInt('unread_message_count') ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // Topic subscription methods
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);

      // Save subscription locally
      final subscriptions = await _getTopicSubscriptions();
      subscriptions.add(topic);
      await _saveTopicSubscriptions(subscriptions);

      if (kDebugMode) {
        print('✅ Subscribed to topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error subscribing to topic $topic: $e');
      }
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);

      // Remove subscription locally
      final subscriptions = await _getTopicSubscriptions();
      subscriptions.remove(topic);
      await _saveTopicSubscriptions(subscriptions);

      if (kDebugMode) {
        print('✅ Unsubscribed from topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error unsubscribing from topic $topic: $e');
      }
    }
  }

  Future<void> subscribeToUserTopic(String userId) async {
    await subscribeToTopic('user_$userId');
  }

  Future<void> subscribeToGroupTopic(String groupId) async {
    await subscribeToTopic('group_$groupId');
  }

  Future<void> subscribeToTypedTopic(FCMTopicType topicType) async {
    final topicName = _getTopicName(topicType);
    await subscribeToTopic(topicName);
  }

  Future<void> unsubscribeFromTypedTopic(FCMTopicType topicType) async {
    final topicName = _getTopicName(topicType);
    await unsubscribeFromTopic(topicName);
  }

  String _getTopicName(FCMTopicType topicType) {
    switch (topicType) {
      case FCMTopicType.allUsers:
        return 'all_users';
      case FCMTopicType.announcements:
        return 'announcements';
      case FCMTopicType.groupUpdates:
        return 'group_updates';
      case FCMTopicType.callNotifications:
        return 'call_notifications';
      case FCMTopicType.statusUpdates:
        return 'status_updates';
    }
  }

  Future<List<String>> _getTopicSubscriptions() async {
    final subscriptionsJson = _localStorage.getString('fcm_subscriptions');
    if (subscriptionsJson == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(subscriptionsJson);
      return decoded.cast<String>();
    } catch (e) {
      return [];
    }
  }

  Future<void> _saveTopicSubscriptions(List<String> subscriptions) async {
    await _localStorage.setString(
      'fcm_subscriptions',
      jsonEncode(subscriptions),
    );
  }

  Future<void> _subscribeToDefaultTopics() async {
    try {
      // Subscribe to default topics for all users
      await subscribeToTypedTopic(FCMTopicType.allUsers);
      await subscribeToTypedTopic(FCMTopicType.announcements);

      if (kDebugMode) {
        print('✅ Subscribed to default topics');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error subscribing to default topics: $e');
      }
    }
  }

  // Helper methods for actions
  Future<void> _markChatAsRead(String chatId) async {
    try {
      final accessToken = await _secureStorage.getAccessToken();
      if (accessToken == null) return;

      await _dio.put(
        ApiConstants.markChatAsRead(chatId),
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      if (kDebugMode) {
        print('✅ Marked chat as read: $chatId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error marking chat as read: $e');
      }
    }
  }

  Future<void> _answerCall(String callId) async {
    try {
      final accessToken = await _secureStorage.getAccessToken();
      if (accessToken == null) return;

      await _dio.post(
        ApiConstants.answerCall(callId),
        data: {'accept': true},
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      if (kDebugMode) {
        print('✅ Answered call: $callId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error answering call: $e');
      }
    }
  }

  Future<void> _declineCall(String callId) async {
    try {
      final accessToken = await _secureStorage.getAccessToken();
      if (accessToken == null) return;

      await _dio.post(
        ApiConstants.answerCall(callId),
        data: {'accept': false},
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      if (kDebugMode) {
        print('✅ Declined call: $callId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error declining call: $e');
      }
    }
  }

  // Settings management
  Future<void> updateNotificationSettings(Map<String, dynamic> settings) async {
    try {
      await _localStorage.setNotificationSettings(settings);

      // Update server settings
      await _sendNotificationSettingsToServer(settings);

      if (kDebugMode) {
        print('✅ Notification settings updated');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating notification settings: $e');
      }
    }
  }

  Future<void> _sendNotificationSettingsToServer(
    Map<String, dynamic> settings,
  ) async {
    try {
      final accessToken = await _secureStorage.getAccessToken();
      if (accessToken == null) return;

      await _dio.put(
        '/api/auth/notification-settings',
        data: settings,
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error sending notification settings to server: $e');
      }
    }
  }

  // Statistics and debugging
  Future<Map<String, dynamic>> getNotificationStats() async {
    try {
      final subscriptions = await _getTopicSubscriptions();
      final permissionStatus = _localStorage.getString('fcm_permission_status');
      final tokenTimestamp = _localStorage.getString('fcm_token_timestamp');
      final badgeCount = _localStorage.getInt('badge_count') ?? 0;

      return {
        'token': _currentToken,
        'permission_status': permissionStatus,
        'token_timestamp': tokenTimestamp,
        'subscriptions': subscriptions,
        'badge_count': badgeCount,
        'is_initialized': _isInitialized,
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting notification stats: $e');
      }
      return {};
    }
  }

  // Cleanup
  Future<void> dispose() async {
    await _messageController.close();
    await _tokenController.close();

    if (kDebugMode) {
      print('✅ FCM Service disposed');
    }
  }
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print('📱 Background message received: ${message.messageId}');
  }

  // Handle background message
  // Note: Limited operations available in background
  try {
    // Update badge count
    final localStorage = LocalStorage();
    await localStorage.init();

    final currentCount = localStorage.getInt('unread_message_count') ?? 0;
    await localStorage.setInt('unread_message_count', currentCount + 1);

    // You can also store the message for later processing
    final messages = localStorage.getStringList('background_messages') ?? [];
    messages.add(
      jsonEncode({
        'message_id': message.messageId,
        'data': message.data,
        'timestamp': DateTime.now().toIso8601String(),
      }),
    );

    // Keep only last 100 background messages
    if (messages.length > 100) {
      messages.removeRange(0, messages.length - 100);
    }

    await localStorage.setStringList('background_messages', messages);
  } catch (e) {
    if (kDebugMode) {
      print('❌ Error in background message handler: $e');
    }
  }
}

// Riverpod providers
final fcmServiceProvider = Provider<FCMService>((ref) {
  return FCMService();
});

final fcmTokenProvider = StreamProvider<String>((ref) {
  final service = ref.watch(fcmServiceProvider);
  return service.tokenStream;
});

final fcmMessageProvider = StreamProvider<RemoteMessage>((ref) {
  final service = ref.watch(fcmServiceProvider);
  return service.messageStream;
});

final currentFcmTokenProvider = Provider<String?>((ref) {
  final service = ref.watch(fcmServiceProvider);
  return service.currentToken;
});
