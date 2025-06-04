import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:http/http.dart' as http;

import '../../core/constants/app_constants.dart';
import '../storage/local_storage.dart';

enum NotificationChannel { messages, calls, groups, status, system, reminders }

enum NotificationAction {
  reply,
  markRead,
  answer,
  decline,
  viewMessage,
  viewGroup,
  viewStatus,
  openApp,
}

class LocalNotificationService {
  static LocalNotificationService? _instance;

  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  final LocalStorage _localStorage = LocalStorage();

  // Streams for handling notification actions
  final StreamController<NotificationResponse> _actionController =
      StreamController<NotificationResponse>.broadcast();

  bool _isInitialized = false;
  int _notificationId = 0;

  LocalNotificationService._internal();

  factory LocalNotificationService() {
    _instance ??= LocalNotificationService._internal();
    return _instance!;
  }

  // Getters
  Stream<NotificationResponse> get actionStream => _actionController.stream;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

      // Initialize timezone data
      tz.initializeTimeZones();

      // Configure initialization settings
      await _configureNotifications();

      // Create notification channels
      await _createNotificationChannels();

      _isInitialized = true;

      if (kDebugMode) {
        print('✅ Local Notification Service initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing Local Notification Service: $e');
      }
      rethrow;
    }
  }

  Future<void> _configureNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const DarwinInitializationSettings initializationSettingsMacOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    final LinuxInitializationSettings initializationSettingsLinux =
        LinuxInitializationSettings(
          defaultActionName: 'Open notification',
          defaultIcon: AssetsLinuxIcon('icons/app_icon.png'),
        );

    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
          macOS: initializationSettingsMacOS,
          linux: initializationSettingsLinux,
        );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          _onDidReceiveBackgroundNotificationResponse,
    );
  }

  Future<void> _onDidReceiveNotificationResponse(
    NotificationResponse notificationResponse,
  ) async {
    try {
      if (kDebugMode) {
        print('📱 Notification tapped: ${notificationResponse.payload}');
      }

      _actionController.add(notificationResponse);
      await _handleNotificationAction(notificationResponse);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling notification response: $e');
      }
    }
  }

  @pragma('vm:entry-point')
  static Future<void> _onDidReceiveBackgroundNotificationResponse(
    NotificationResponse notificationResponse,
  ) async {
    try {
      if (kDebugMode) {
        print(
          '📱 Background notification action: ${notificationResponse.payload}',
        );
      }

      // Handle background notification action
      final instance = LocalNotificationService();
      if (!instance.isInitialized) {
        await instance.initialize();
      }

      instance._actionController.add(notificationResponse);
      await instance._handleNotificationAction(notificationResponse);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling background notification response: $e');
      }
    }
  }

  Future<void> _createNotificationChannels() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      if (androidImplementation != null) {
        // Messages channel
        await androidImplementation.createNotificationChannel(
          const AndroidNotificationChannel(
            AppConstants.messageChannelId,
            AppConstants.messageChannelName,
            description: 'Notifications for messages',
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
            enableLights: true,
            ledColor: Color.fromARGB(255, 255, 0, 0),
          ),
        );

        // Calls channel
        await androidImplementation.createNotificationChannel(
          const AndroidNotificationChannel(
            AppConstants.callChannelId,
            AppConstants.callChannelName,
            description: 'Notifications for calls',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
            enableLights: true,
            ledColor: Color.fromARGB(255, 0, 255, 0),
          ),
        );

        // Groups channel
        await androidImplementation.createNotificationChannel(
          const AndroidNotificationChannel(
            AppConstants.groupChannelId,
            AppConstants.groupChannelName,
            description: 'Notifications for groups',
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          ),
        );

        // System channel
        await androidImplementation.createNotificationChannel(
          const AndroidNotificationChannel(
            AppConstants.systemChannelId,
            AppConstants.systemChannelName,
            description: 'System notifications',
            importance: Importance.defaultImportance,
            playSound: false,
            enableVibration: false,
          ),
        );

        if (kDebugMode) {
          print('✅ Android notification channels created');
        }
      }
    }
  }

  Future<void> showMessageNotification({
    required String title,
    required String body,
    String? chatId,
    String? senderId,
    String? senderName,
    String? messageType,
    String? imageUrl,
    String? payload,
    bool isGroupMessage = false,
  }) async {
    try {
      final settings = _localStorage.getNotificationSettings();
      if (!settings['enabled'] || !settings['message_notifications']) {
        return;
      }

      final id = _getNextNotificationId();

      // Create notification payload
      final notificationPayload = jsonEncode({
        'type': 'message',
        'chat_id': chatId,
        'sender_id': senderId,
        'sender_name': senderName,
        'message_type': messageType,
        'action': 'view_message',
        'data': payload,
      });

      // Create Android notification details
      final androidDetails = AndroidNotificationDetails(
        AppConstants.messageChannelId,
        AppConstants.messageChannelName,
        channelDescription: 'Notifications for messages',
        importance: Importance.high,
        priority: Priority.high,
        ticker: 'New message',
        icon: '@mipmap/ic_launcher',
        largeIcon: await _getAvatarDrawableResource(senderId),
        styleInformation: await _getMessageStyleInformation(
          body,
          messageType,
          imageUrl,
        ),
        actions: _getMessageActions(isGroupMessage),
        category: AndroidNotificationCategory.message,
        visibility: NotificationVisibility.private,
        autoCancel: true,
        ongoing: false,
        silent: !settings['sound'],
        enableVibration: settings['vibration'],
        playSound: settings['sound'],
        sound: settings['sound']
            ? RawResourceAndroidNotificationSound(
                settings['message_sound']?.replaceAll('.mp3', '') ??
                    'notification',
              )
            : null,
        color: const Color.fromARGB(255, 33, 150, 243),
        ledColor: const Color.fromARGB(255, 33, 150, 243),
        ledOnMs: 1000,
        ledOffMs: 500,
      );

      // Create iOS notification details
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: 'MESSAGE_CATEGORY',
        threadIdentifier: 'message_thread',
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
        payload: notificationPayload,
      );

      // Update notification count
      await _updateMessageNotificationCount(chatId);

      if (kDebugMode) {
        print('✅ Message notification shown: $title');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error showing message notification: $e');
      }
    }
  }

  Future<void> showCallNotification({
    required String title,
    required String body,
    required String callId,
    required String callerId,
    required String callerName,
    required String callType,
    String? avatarUrl,
    String? payload,
  }) async {
    try {
      final settings = _localStorage.getNotificationSettings();
      if (!settings['enabled'] || !settings['call_notifications']) {
        return;
      }

      final id = _getNextNotificationId();

      final notificationPayload = jsonEncode({
        'type': 'call',
        'call_id': callId,
        'caller_id': callerId,
        'caller_name': callerName,
        'call_type': callType,
        'action': 'view_call',
        'data': payload,
      });

      // Create full-screen intent for incoming calls
      final androidDetails = AndroidNotificationDetails(
        AppConstants.callChannelId,
        AppConstants.callChannelName,
        channelDescription: 'Notifications for calls',
        importance: Importance.max,
        priority: Priority.max,
        category: AndroidNotificationCategory.call,
        fullScreenIntent: true,
        ongoing: true,
        autoCancel: false,
        icon: '@mipmap/ic_launcher',
        largeIcon: await _getAvatarDrawableResource(callerId),
        actions: _getCallActions(callType),
        enableVibration: true,
        playSound: true,
        sound: RawResourceAndroidNotificationSound(
          settings['call_sound']?.replaceAll('.mp3', '') ?? 'ringtone',
        ),
        color: const Color.fromARGB(255, 76, 175, 80),
        timeoutAfter: 30000, // 30 seconds timeout
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: 'CALL_CATEGORY',
        threadIdentifier: 'call_thread',
        interruptionLevel: InterruptionLevel.critical,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
        payload: notificationPayload,
      );

      // Store call notification ID for later cancellation
      await _localStorage.setString(
        'active_call_notification_id',
        id.toString(),
      );

      if (kDebugMode) {
        print('✅ Call notification shown: $title');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error showing call notification: $e');
      }
    }
  }

  Future<void> showGroupNotification({
    required String title,
    required String body,
    String? groupId,
    String? groupName,
    String? senderId,
    String? senderName,
    String? payload,
  }) async {
    try {
      final settings = _localStorage.getNotificationSettings();
      if (!settings['enabled'] || !settings['group_notifications']) {
        return;
      }

      final id = _getNextNotificationId();

      final notificationPayload = jsonEncode({
        'type': 'group',
        'group_id': groupId,
        'group_name': groupName,
        'sender_id': senderId,
        'sender_name': senderName,
        'action': 'view_group',
        'data': payload,
      });

      final androidDetails = AndroidNotificationDetails(
        AppConstants.groupChannelId,
        AppConstants.groupChannelName,
        channelDescription: 'Notifications for groups',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        largeIcon: await _getGroupDrawableResource(groupId),
        actions: _getGroupActions(),
        category: AndroidNotificationCategory.social,
        autoCancel: true,
        enableVibration: settings['vibration'],
        playSound: settings['sound'],
        color: const Color.fromARGB(255, 156, 39, 176),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: 'GROUP_CATEGORY',
        threadIdentifier: 'group_thread',
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
        payload: notificationPayload,
      );

      if (kDebugMode) {
        print('✅ Group notification shown: $title');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error showing group notification: $e');
      }
    }
  }

  Future<void> showStatusNotification({
    required String title,
    required String body,
    String? userId,
    String? userName,
    String? statusId,
    String? payload,
  }) async {
    try {
      final settings = _localStorage.getNotificationSettings();
      if (!settings['enabled'] || !settings['status_notifications']) {
        return;
      }

      final id = _getNextNotificationId();

      final notificationPayload = jsonEncode({
        'type': 'status',
        'user_id': userId,
        'user_name': userName,
        'status_id': statusId,
        'action': 'view_status',
        'data': payload,
      });

      final androidDetails = AndroidNotificationDetails(
        AppConstants.groupChannelId,
        AppConstants.groupChannelName,
        channelDescription: 'Notifications for status updates',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
        largeIcon: await _getAvatarDrawableResource(userId),
        autoCancel: true,
        enableVibration: false,
        playSound: false,
        color: const Color.fromARGB(255, 255, 152, 0),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: false,
        categoryIdentifier: 'STATUS_CATEGORY',
        threadIdentifier: 'status_thread',
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
        payload: notificationPayload,
      );

      if (kDebugMode) {
        print('✅ Status notification shown: $title');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error showing status notification: $e');
      }
    }
  }

  Future<void> showGeneralNotification({
    required String title,
    required String body,
    String? payload,
    String? imageUrl,
    List<AndroidNotificationAction>? actions,
  }) async {
    try {
      final settings = _localStorage.getNotificationSettings();
      if (!settings['enabled']) {
        return;
      }

      final id = _getNextNotificationId();

      final notificationPayload =
          payload ?? jsonEncode({'type': 'general', 'action': 'open_app'});

      final androidDetails = AndroidNotificationDetails(
        AppConstants.systemChannelId,
        AppConstants.systemChannelName,
        channelDescription: 'General notifications',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
        styleInformation: imageUrl != null
            ? await _getBigPictureStyleInformation(imageUrl)
            : null,
        actions: actions,
        autoCancel: true,
        enableVibration: settings['vibration'],
        playSound: settings['sound'],
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: 'GENERAL_CATEGORY',
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
        payload: notificationPayload,
      );

      if (kDebugMode) {
        print('✅ General notification shown: $title');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error showing general notification: $e');
      }
    }
  }

  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    NotificationChannel channel = NotificationChannel.system,
  }) async {
    try {
      final id = _getNextNotificationId();

      final androidDetails = AndroidNotificationDetails(
        _getChannelId(channel),
        _getChannelName(channel),
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
        autoCancel: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        notificationDetails,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      if (kDebugMode) {
        print('✅ Notification scheduled for: $scheduledDate');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error scheduling notification: $e');
      }
    }
  }

  Future<void> cancelNotification(int id) async {
    try {
      await _flutterLocalNotificationsPlugin.cancel(id);

      if (kDebugMode) {
        print('✅ Notification cancelled: $id');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error cancelling notification: $e');
      }
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();

      if (kDebugMode) {
        print('✅ All notifications cancelled');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error cancelling all notifications: $e');
      }
    }
  }

  Future<void> cancelCallNotification() async {
    try {
      final callNotificationId = _localStorage.getString(
        'active_call_notification_id',
      );
      if (callNotificationId != null) {
        await cancelNotification(int.parse(callNotificationId));
        await _localStorage.remove('active_call_notification_id');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error cancelling call notification: $e');
      }
    }
  }

  // Helper methods
  int _getNextNotificationId() {
    return ++_notificationId;
  }

  String _getChannelId(NotificationChannel channel) {
    switch (channel) {
      case NotificationChannel.messages:
        return AppConstants.messageChannelId;
      case NotificationChannel.calls:
        return AppConstants.callChannelId;
      case NotificationChannel.groups:
        return AppConstants.groupChannelId;
      case NotificationChannel.status:
        return AppConstants.groupChannelId;
      case NotificationChannel.system:
        return AppConstants.systemChannelId;
      case NotificationChannel.reminders:
        return AppConstants.systemChannelId;
    }
  }

  String _getChannelName(NotificationChannel channel) {
    switch (channel) {
      case NotificationChannel.messages:
        return AppConstants.messageChannelName;
      case NotificationChannel.calls:
        return AppConstants.callChannelName;
      case NotificationChannel.groups:
        return AppConstants.groupChannelName;
      case NotificationChannel.status:
        return AppConstants.groupChannelName;
      case NotificationChannel.system:
        return AppConstants.systemChannelName;
      case NotificationChannel.reminders:
        return AppConstants.systemChannelName;
    }
  }

  Future<StyleInformation?> _getMessageStyleInformation(
    String body,
    String? messageType,
    String? imageUrl,
  ) async {
    try {
      if (messageType == 'image' && imageUrl != null) {
        return await _getBigPictureStyleInformation(imageUrl);
      } else {
        return BigTextStyleInformation(
          body,
          contentTitle: null,
          summaryText: null,
        );
      }
    } catch (e) {
      return BigTextStyleInformation(body);
    }
  }

  Future<BigPictureStyleInformation?> _getBigPictureStyleInformation(
    String imageUrl,
  ) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        final Uint8List imageBytes = response.bodyBytes;
        return BigPictureStyleInformation(
          ByteArrayAndroidBitmap(imageBytes),
          contentTitle: null,
          summaryText: null,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading notification image: $e');
      }
    }
    return null;
  }

  Future<DrawableResourceAndroidBitmap?> _getAvatarDrawableResource(
    String? userId,
  ) async {
    // This would typically load user avatar from cache or API
    // For now, return default avatar
    try {
      return const DrawableResourceAndroidBitmap('@drawable/default_avatar');
    } catch (e) {
      return null;
    }
  }

  Future<DrawableResourceAndroidBitmap?> _getGroupDrawableResource(
    String? groupId,
  ) async {
    // This would typically load group avatar from cache or API
    // For now, return default group icon
    try {
      return const DrawableResourceAndroidBitmap('@drawable/default_group');
    } catch (e) {
      return null;
    }
  }

  List<AndroidNotificationAction> _getMessageActions(bool isGroupMessage) {
    return [
      AndroidNotificationAction(
        'reply',
        'Reply',
        icon: DrawableResourceAndroidBitmap('@drawable/ic_reply'),
        inputs: const [
          AndroidNotificationActionInput(label: 'Type a message...'),
        ],
      ),
      AndroidNotificationAction(
        'mark_read',
        'Mark as Read',
        icon: DrawableResourceAndroidBitmap('@drawable/ic_check'),
      ),
    ];
  }

  List<AndroidNotificationAction> _getCallActions(String callType) {
    return [
      AndroidNotificationAction(
        'answer',
        'Answer',
        icon: DrawableResourceAndroidBitmap('@drawable/ic_call'),
      ),
      AndroidNotificationAction(
        'decline',
        'Decline',
        icon: DrawableResourceAndroidBitmap('@drawable/ic_call_end'),
      ),
    ];
  }

  List<AndroidNotificationAction> _getGroupActions() {
    return [
      AndroidNotificationAction(
        'view_group',
        'View Group',
        icon: DrawableResourceAndroidBitmap('@drawable/ic_group'),
      ),
      AndroidNotificationAction(
        'mark_read',
        'Mark as Read',
        icon: DrawableResourceAndroidBitmap('@drawable/ic_check'),
      ),
    ];
  }

  Future<void> _handleNotificationAction(
    NotificationResponse notificationResponse,
  ) async {
    try {
      if (notificationResponse.payload == null) return;

      final payloadData = jsonDecode(notificationResponse.payload!);
      final type = payloadData['type'];
      final action = notificationResponse.actionId ?? payloadData['action'];

      switch (type) {
        case 'message':
          await _handleMessageAction(payloadData, action);
          break;
        case 'call':
          await _handleCallAction(payloadData, action);
          break;
        case 'group':
          await _handleGroupAction(payloadData, action);
          break;
        case 'status':
          await _handleStatusAction(payloadData, action);
          break;
        default:
          await _handleGenericAction(payloadData, action);
          break;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling notification action: $e');
      }
    }
  }

  Future<void> _handleMessageAction(
    Map<String, dynamic> data,
    String? action,
  ) async {
    final chatId = data['chat_id'];

    switch (action) {
      case 'reply':
        // This would typically open the chat screen or show a reply interface
        // For now, we'll just log it
        if (kDebugMode) {
          print('📱 Reply action for chat: $chatId');
        }
        break;

      case 'mark_read':
        await _markChatAsRead(chatId);
        break;

      default:
        // Default action - open chat
        if (kDebugMode) {
          print('📱 Open chat: $chatId');
        }
        break;
    }
  }

  Future<void> _handleCallAction(
    Map<String, dynamic> data,
    String? action,
  ) async {
    final callId = data['call_id'];

    switch (action) {
      case 'answer':
        if (kDebugMode) {
          print('📞 Answer call: $callId');
        }
        await cancelCallNotification();
        break;

      case 'decline':
        if (kDebugMode) {
          print('📞 Decline call: $callId');
        }
        await cancelCallNotification();
        break;

      default:
        // Default action - open call screen
        if (kDebugMode) {
          print('📞 Open call: $callId');
        }
        break;
    }
  }

  Future<void> _handleGroupAction(
    Map<String, dynamic> data,
    String? action,
  ) async {
    final groupId = data['group_id'];

    switch (action) {
      case 'view_group':
        if (kDebugMode) {
          print('👥 View group: $groupId');
        }
        break;

      case 'mark_read':
        await _markChatAsRead(groupId);
        break;

      default:
        if (kDebugMode) {
          print('👥 Open group: $groupId');
        }
        break;
    }
  }

  Future<void> _handleStatusAction(
    Map<String, dynamic> data,
    String? action,
  ) async {
    final userId = data['user_id'];

    switch (action) {
      case 'view_status':
        if (kDebugMode) {
          print('📸 View status: $userId');
        }
        break;

      default:
        if (kDebugMode) {
          print('📸 Open status: $userId');
        }
        break;
    }
  }

  Future<void> _handleGenericAction(
    Map<String, dynamic> data,
    String? action,
  ) async {
    switch (action) {
      case 'open_app':
        if (kDebugMode) {
          print('📱 Open app');
        }
        break;

      default:
        if (kDebugMode) {
          print('📱 Generic action: $action');
        }
        break;
    }
  }

  Future<void> _markChatAsRead(String? chatId) async {
    if (chatId == null) return;

    try {
      // This would typically call your API to mark the chat as read
      // For now, we'll just update local storage
      await _localStorage.setString(
        'last_read_$chatId',
        DateTime.now().toIso8601String(),
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

  Future<void> _updateMessageNotificationCount(String? chatId) async {
    if (chatId == null) return;

    try {
      final currentCount = _localStorage.getInt('unread_count_$chatId') ?? 0;
      await _localStorage.setInt('unread_count_$chatId', currentCount + 1);

      final totalCount = _localStorage.getInt('total_unread_count') ?? 0;
      await _localStorage.setInt('total_unread_count', totalCount + 1);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating notification count: $e');
      }
    }
  }

  // Utility methods
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _flutterLocalNotificationsPlugin
          .pendingNotificationRequests();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting pending notifications: $e');
      }
      return [];
    }
  }

  Future<List<ActiveNotification>> getActiveNotifications() async {
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      if (androidImplementation != null) {
        return await androidImplementation.getActiveNotifications();
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting active notifications: $e');
      }
      return [];
    }
  }

  Future<bool> hasNotificationPermission() async {
    try {
      if (Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            _flutterLocalNotificationsPlugin
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >();

        if (androidImplementation != null) {
          return await androidImplementation.areNotificationsEnabled() ?? false;
        }
      }
      return true; // Assume permission granted on other platforms
    } catch (e) {
      return false;
    }
  }

  Future<void> requestNotificationPermission() async {
    try {
      if (Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            _flutterLocalNotificationsPlugin
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >();

        if (androidImplementation != null) {
          await androidImplementation.requestNotificationsPermission();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error requesting notification permission: $e');
      }
    }
  }

  // Badge count management
  Future<void> updateBadgeCount(int count) async {
    try {
      if (Platform.isAndroid) {
        // Android doesn't have native badge support, but we can use notification badges
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            _flutterLocalNotificationsPlugin
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >();

        if (androidImplementation != null) {
          // For Android, we can show a persistent notification with the count
          // or use a third-party badge library
          await _localStorage.setInt('badge_count', count);
        }
      } else if (Platform.isIOS) {
        // For iOS, we need to use a badge plugin like flutter_app_badger
        // or handle it through the notification payload
        await _localStorage.setInt('badge_count', count);

        // If you want to use flutter_app_badger, add it to pubspec.yaml and uncomment:
        // import 'package:flutter_app_badger/flutter_app_badger.dart';
        // await FlutterAppBadger.updateBadgeCount(count);

        if (kDebugMode) {
          print('📱 Badge count updated to: $count');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating badge count: $e');
      }
    }
  }

  Future<void> clearBadgeCount() async {
    await updateBadgeCount(0);
  }

  // Cleanup
  Future<void> dispose() async {
    await _actionController.close();

    if (kDebugMode) {
      print('✅ Local Notification Service disposed');
    }
  }
}

// Riverpod providers
final localNotificationServiceProvider = Provider<LocalNotificationService>((
  ref,
) {
  return LocalNotificationService();
});

final notificationActionProvider = StreamProvider<NotificationResponse>((ref) {
  final service = ref.watch(localNotificationServiceProvider);
  return service.actionStream;
});
