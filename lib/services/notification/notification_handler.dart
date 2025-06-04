import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../core/config/dio_config.dart';
import '../storage/local_storage.dart';
import '../websocket/websocket_service.dart';
import '../websocket/chat_socket.dart';
import '../websocket/call_socket.dart';
import 'fcm_service.dart';
import 'local_notification.dart';

enum NotificationType {
  message,
  call,
  groupMessage,
  groupUpdate,
  statusUpdate,
  systemAnnouncement,
  reminder,
  fileUpload,
  callMissed,
  callEnded,
  userOnline,
  userOffline,
  reaction,
  mention,
}

enum NotificationPriority { low, normal, high, urgent }

class NotificationData {
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final NotificationPriority priority;
  final DateTime timestamp;
  final String? imageUrl;
  final String? actionUrl;
  final List<String>? actions;

  NotificationData({
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    this.priority = NotificationPriority.normal,
    DateTime? timestamp,
    this.imageUrl,
    this.actionUrl,
    this.actions,
  }) : timestamp = timestamp ?? DateTime.now();

  factory NotificationData.fromFCM(RemoteMessage message) {
    final data = message.data;
    return NotificationData(
      type: _parseNotificationType(data['type']),
      title: message.notification?.title ?? data['title'] ?? 'Notification',
      body: message.notification?.body ?? data['body'] ?? '',
      data: data,
      priority: _parseNotificationPriority(data['priority']),
      imageUrl: data['image_url'],
      actionUrl: data['action_url'],
      actions: data['actions']?.toString().split(','),
    );
  }

  factory NotificationData.fromWebSocket(WebSocketEvent event) {
    return NotificationData(
      type: _parseWebSocketEventType(event.type),
      title: _generateTitleFromWebSocketEvent(event),
      body: _generateBodyFromWebSocketEvent(event),
      data: event.data,
      priority: _getWebSocketEventPriority(event.type),
    );
  }

  static NotificationType _parseNotificationType(String? type) {
    switch (type?.toLowerCase()) {
      case 'message':
        return NotificationType.message;
      case 'call':
        return NotificationType.call;
      case 'group_message':
        return NotificationType.groupMessage;
      case 'group_update':
        return NotificationType.groupUpdate;
      case 'status_update':
        return NotificationType.statusUpdate;
      case 'system_announcement':
        return NotificationType.systemAnnouncement;
      case 'reminder':
        return NotificationType.reminder;
      case 'file_upload':
        return NotificationType.fileUpload;
      case 'call_missed':
        return NotificationType.callMissed;
      case 'call_ended':
        return NotificationType.callEnded;
      case 'user_online':
        return NotificationType.userOnline;
      case 'user_offline':
        return NotificationType.userOffline;
      case 'reaction':
        return NotificationType.reaction;
      case 'mention':
        return NotificationType.mention;
      default:
        return NotificationType.message;
    }
  }

  static NotificationPriority _parseNotificationPriority(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'low':
        return NotificationPriority.low;
      case 'normal':
        return NotificationPriority.normal;
      case 'high':
        return NotificationPriority.high;
      case 'urgent':
        return NotificationPriority.urgent;
      default:
        return NotificationPriority.normal;
    }
  }

  static NotificationType _parseWebSocketEventType(
    WebSocketEventType eventType,
  ) {
    switch (eventType) {
      case WebSocketEventType.messageReceived:
        return NotificationType.message;
      case WebSocketEventType.callInitiated:
        return NotificationType.call;
      case WebSocketEventType.callEnded:
        return NotificationType.callEnded;
      case WebSocketEventType.messageReaction:
        return NotificationType.reaction;
      case WebSocketEventType.groupUpdated:
        return NotificationType.groupUpdate;
      case WebSocketEventType.memberAdded:
      case WebSocketEventType.memberRemoved:
        return NotificationType.groupUpdate;
      case WebSocketEventType.statusUpdated:
        return NotificationType.statusUpdate;
      case WebSocketEventType.userOnline:
        return NotificationType.userOnline;
      case WebSocketEventType.userOffline:
        return NotificationType.userOffline;
      case WebSocketEventType.systemBroadcast:
        return NotificationType.systemAnnouncement;
      default:
        return NotificationType.message;
    }
  }

  static String _generateTitleFromWebSocketEvent(WebSocketEvent event) {
    switch (event.type) {
      case WebSocketEventType.messageReceived:
        return event.data['sender_name'] ?? 'New Message';
      case WebSocketEventType.callInitiated:
        return 'Incoming Call';
      case WebSocketEventType.callEnded:
        return 'Call Ended';
      case WebSocketEventType.messageReaction:
        return 'New Reaction';
      case WebSocketEventType.groupUpdated:
        return 'Group Updated';
      case WebSocketEventType.memberAdded:
        return 'New Member Added';
      case WebSocketEventType.memberRemoved:
        return 'Member Removed';
      case WebSocketEventType.userOnline:
        return '${event.data['user_name']} is online';
      case WebSocketEventType.userOffline:
        return '${event.data['user_name']} went offline';
      case WebSocketEventType.systemBroadcast:
        return 'System Announcement';
      default:
        return 'Notification';
    }
  }

  static String _generateBodyFromWebSocketEvent(WebSocketEvent event) {
    switch (event.type) {
      case WebSocketEventType.messageReceived:
        return event.data['content'] ?? 'New message received';
      case WebSocketEventType.callInitiated:
        final callerName = event.data['caller_name'] ?? 'Someone';
        return '$callerName is calling you';
      case WebSocketEventType.callEnded:
        return 'Call has ended';
      case WebSocketEventType.messageReaction:
        final emoji = event.data['emoji'] ?? '👍';
        final userName = event.data['user_name'] ?? 'Someone';
        return '$userName reacted with $emoji';
      case WebSocketEventType.groupUpdated:
        return 'Group information has been updated';
      case WebSocketEventType.memberAdded:
        final memberName = event.data['member_name'] ?? 'Someone';
        return '$memberName was added to the group';
      case WebSocketEventType.memberRemoved:
        final memberName = event.data['member_name'] ?? 'Someone';
        return '$memberName was removed from the group';
      case WebSocketEventType.systemBroadcast:
        return event.data['message'] ?? 'System announcement';
      default:
        return event.data['message'] ?? 'New notification';
    }
  }

  static NotificationPriority _getWebSocketEventPriority(
    WebSocketEventType eventType,
  ) {
    switch (eventType) {
      case WebSocketEventType.callInitiated:
        return NotificationPriority.urgent;
      case WebSocketEventType.messageReceived:
        return NotificationPriority.high;
      case WebSocketEventType.systemBroadcast:
        return NotificationPriority.high;
      case WebSocketEventType.groupUpdated:
      case WebSocketEventType.memberAdded:
      case WebSocketEventType.memberRemoved:
        return NotificationPriority.normal;
      case WebSocketEventType.messageReaction:
      case WebSocketEventType.userOnline:
      case WebSocketEventType.userOffline:
        return NotificationPriority.low;
      default:
        return NotificationPriority.normal;
    }
  }
}

class NotificationHandler {
  static NotificationHandler? _instance;

  final FCMService _fcmService = FCMService();
  final LocalNotificationService _localNotificationService =
      LocalNotificationService();
  final WebSocketService _webSocketService = WebSocketService();
  final ChatSocketService _chatSocketService = ChatSocketService();
  final CallSocketService _callSocketService = CallSocketService();
  final LocalStorage _localStorage = LocalStorage();

  // Streams for handling notifications
  final StreamController<NotificationData> _notificationController =
      StreamController<NotificationData>.broadcast();

  // Notification state
  bool _isInitialized = false;
  bool _isInForeground = true;
  String? _currentChatId;
  final Map<String, Timer> _debounceTimers = {};
  final Map<String, List<NotificationData>> _groupedNotifications = {};

  // Notification settings cache
  Map<String, dynamic>? _notificationSettings;
  DateTime? _settingsLastUpdated;

  // Subscription management
  final List<StreamSubscription> _subscriptions = [];

  NotificationHandler._internal();

  factory NotificationHandler() {
    _instance ??= NotificationHandler._internal();
    return _instance!;
  }

  // Getters
  Stream<NotificationData> get notificationStream =>
      _notificationController.stream;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize services
      await _localNotificationService.initialize();
      await _fcmService.initialize(
        localNotificationService: _localNotificationService,
        dio: DioConfig.instance,
      );

      // Load notification settings
      await _loadNotificationSettings();

      // Set up listeners
      _setupListeners();

      // Handle any pending notifications
      await _handlePendingNotifications();

      _isInitialized = true;

      if (kDebugMode) {
        print('✅ Notification Handler initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing Notification Handler: $e');
      }
      rethrow;
    }
  }

  void _setupListeners() {
    // FCM message listener
    _subscriptions.add(_fcmService.messageStream.listen(_handleFCMMessage));

    // WebSocket event listener
    _subscriptions.add(
      _webSocketService.eventStream.listen(_handleWebSocketEvent),
    );

    // Chat socket event listener
    _subscriptions.add(
      _chatSocketService.messageReceived.listen(_handleChatMessage),
    );

    // Call socket event listener
    _subscriptions.add(_callSocketService.callEvents.listen(_handleCallEvent));

    // Local notification action listener
    _subscriptions.add(
      _localNotificationService.actionStream.listen(_handleNotificationAction),
    );
  }

  Future<void> _handleFCMMessage(RemoteMessage message) async {
    try {
      if (kDebugMode) {
        print('🔔 Handling FCM message: ${message.messageId}');
      }

      final notificationData = NotificationData.fromFCM(message);
      await _processNotification(notificationData);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling FCM message: $e');
      }
    }
  }

  Future<void> _handleWebSocketEvent(WebSocketEvent event) async {
    try {
      // Only create notifications for relevant events
      if (!_shouldCreateNotificationForWebSocketEvent(event)) {
        return;
      }

      if (kDebugMode) {
        print('🔔 Handling WebSocket event: ${event.type.name}');
      }

      final notificationData = NotificationData.fromWebSocket(event);
      await _processNotification(notificationData);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling WebSocket event: $e');
      }
    }
  }

  Future<void> _handleChatMessage(ChatMessage message) async {
    try {
      // Don't show notification for current chat if app is in foreground
      if (_isInForeground && message.chatId == _currentChatId) {
        return;
      }

      // Don't show notification for own messages
      if (message.isFromCurrentUser) {
        return;
      }

      if (kDebugMode) {
        print('🔔 Handling chat message: ${message.id}');
      }

      final notificationData = NotificationData(
        type: NotificationType.message,
        title: message.senderName ?? 'New Message',
        body: _getMessagePreview(message),
        data: {
          'chat_id': message.chatId,
          'message_id': message.id,
          'sender_id': message.senderId,
          'sender_name': message.senderName,
          'message_type': message.type,
        },
        priority: NotificationPriority.high,
      );

      await _processNotification(notificationData);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling chat message: $e');
      }
    }
  }

  Future<void> _handleCallEvent(CallEvent event) async {
    try {
      if (event.type == CallEventType.incomingCall) {
        if (kDebugMode) {
          print('🔔 Handling incoming call');
        }

        final callData = event.data;
        final notificationData = NotificationData(
          type: NotificationType.call,
          title: 'Incoming Call',
          body: '${callData?['caller_name']} is calling you',
          data: {
            'call_id': event.callId,
            'caller_id': callData?['caller_id'],
            'caller_name': callData?['caller_name'],
            'call_type': event.callType?.name ?? 'voice',
          },
          priority: NotificationPriority.urgent,
        );

        await _processNotification(notificationData);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling call event: $e');
      }
    }
  }

  Future<void> _handleNotificationAction(NotificationResponse response) async {
    try {
      if (kDebugMode) {
        print('🔔 Handling notification action: ${response.actionId}');
      }

      if (response.payload != null) {
        final data = jsonDecode(response.payload!);
        await _routeNotificationAction(data, response.actionId);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling notification action: $e');
      }
    }
  }

  Future<void> _processNotification(NotificationData notification) async {
    try {
      // Check if notifications are enabled
      if (!await _areNotificationsEnabled()) {
        return;
      }

      // Check if this type of notification is enabled
      if (!await _isNotificationTypeEnabled(notification.type)) {
        return;
      }

      // Check Do Not Disturb mode
      if (await _isDoNotDisturbActive()) {
        // Only allow urgent notifications during DND
        if (notification.priority != NotificationPriority.urgent) {
          return;
        }
      }

      // Add to stream
      _notificationController.add(notification);

      // Handle grouping and debouncing
      await _handleNotificationGrouping(notification);

      // Show notification based on type
      await _showNotification(notification);

      // Update badge count
      await _updateBadgeCount();

      // Log notification for analytics
      await _logNotification(notification);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error processing notification: $e');
      }
    }
  }

  Future<void> _handleNotificationGrouping(
    NotificationData notification,
  ) async {
    final groupKey = _getNotificationGroupKey(notification);

    if (groupKey != null) {
      // Add to group
      _groupedNotifications.putIfAbsent(groupKey, () => []);
      _groupedNotifications[groupKey]!.add(notification);

      // Debounce grouped notifications
      _debounceTimers[groupKey]?.cancel();
      _debounceTimers[groupKey] = Timer(
        const Duration(seconds: 2),
        () => _showGroupedNotification(groupKey),
      );
    }
  }

  Future<void> _showNotification(NotificationData notification) async {
    try {
      switch (notification.type) {
        case NotificationType.message:
        case NotificationType.groupMessage:
          await _showMessageNotification(notification);
          break;

        case NotificationType.call:
          await _showCallNotification(notification);
          break;

        case NotificationType.groupUpdate:
          await _showGroupNotification(notification);
          break;

        case NotificationType.statusUpdate:
          await _showStatusNotification(notification);
          break;

        case NotificationType.systemAnnouncement:
          await _showSystemNotification(notification);
          break;

        case NotificationType.reaction:
          await _showReactionNotification(notification);
          break;

        case NotificationType.mention:
          await _showMentionNotification(notification);
          break;

        case NotificationType.reminder:
          await _showReminderNotification(notification);
          break;

        default:
          await _showGenericNotification(notification);
          break;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error showing notification: $e');
      }
    }
  }

  Future<void> _showMessageNotification(NotificationData notification) async {
    await _localNotificationService.showMessageNotification(
      title: notification.title,
      body: notification.body,
      chatId: notification.data['chat_id'],
      senderId: notification.data['sender_id'],
      senderName: notification.data['sender_name'],
      messageType: notification.data['message_type'],
      imageUrl: notification.imageUrl,
      payload: jsonEncode(notification.data),
      isGroupMessage: notification.type == NotificationType.groupMessage,
    );
  }

  Future<void> _showCallNotification(NotificationData notification) async {
    await _localNotificationService.showCallNotification(
      title: notification.title,
      body: notification.body,
      callId: notification.data['call_id'] ?? '',
      callerId: notification.data['caller_id'] ?? '',
      callerName: notification.data['caller_name'] ?? '',
      callType: notification.data['call_type'] ?? 'voice',
      payload: jsonEncode(notification.data),
    );
  }

  Future<void> _showGroupNotification(NotificationData notification) async {
    await _localNotificationService.showGroupNotification(
      title: notification.title,
      body: notification.body,
      groupId: notification.data['group_id'],
      groupName: notification.data['group_name'],
      senderId: notification.data['sender_id'],
      senderName: notification.data['sender_name'],
      payload: jsonEncode(notification.data),
    );
  }

  Future<void> _showStatusNotification(NotificationData notification) async {
    await _localNotificationService.showStatusNotification(
      title: notification.title,
      body: notification.body,
      userId: notification.data['user_id'],
      userName: notification.data['user_name'],
      statusId: notification.data['status_id'],
      payload: jsonEncode(notification.data),
    );
  }

  Future<void> _showSystemNotification(NotificationData notification) async {
    await _localNotificationService.showGeneralNotification(
      title: notification.title,
      body: notification.body,
      payload: jsonEncode(notification.data),
      imageUrl: notification.imageUrl,
    );
  }

  Future<void> _showReactionNotification(NotificationData notification) async {
    // Only show reaction notifications if enabled
    final settings = await _getNotificationSettings();
    if (!settings['reaction_notifications']) {
      return;
    }

    await _localNotificationService.showGeneralNotification(
      title: notification.title,
      body: notification.body,
      payload: jsonEncode(notification.data),
    );
  }

  Future<void> _showMentionNotification(NotificationData notification) async {
    // Mentions should always be shown with high priority
    await _localNotificationService.showMessageNotification(
      title: notification.title,
      body: notification.body,
      chatId: notification.data['chat_id'],
      senderId: notification.data['sender_id'],
      senderName: notification.data['sender_name'],
      messageType: 'mention',
      payload: jsonEncode(notification.data),
    );
  }

  Future<void> _showReminderNotification(NotificationData notification) async {
    await _localNotificationService.showGeneralNotification(
      title: notification.title,
      body: notification.body,
      payload: jsonEncode(notification.data),
    );
  }

  Future<void> _showGenericNotification(NotificationData notification) async {
    await _localNotificationService.showGeneralNotification(
      title: notification.title,
      body: notification.body,
      payload: jsonEncode(notification.data),
      imageUrl: notification.imageUrl,
    );
  }

  Future<void> _showGroupedNotification(String groupKey) async {
    final notifications = _groupedNotifications[groupKey];
    if (notifications == null || notifications.isEmpty) return;

    try {
      if (notifications.length == 1) {
        // Show single notification
        await _showNotification(notifications.first);
      } else {
        // Show grouped notification
        final firstNotification = notifications.first;
        final title = _getGroupedNotificationTitle(groupKey, notifications);
        final body = _getGroupedNotificationBody(notifications);

        await _localNotificationService.showGeneralNotification(
          title: title,
          body: body,
          payload: jsonEncode({
            'type': 'grouped',
            'group_key': groupKey,
            'count': notifications.length,
            'notifications': notifications.map((n) => n.data).toList(),
          }),
        );
      }

      // Clear the group
      _groupedNotifications.remove(groupKey);
      _debounceTimers.remove(groupKey);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error showing grouped notification: $e');
      }
    }
  }

  // Helper methods
  bool _shouldCreateNotificationForWebSocketEvent(WebSocketEvent event) {
    // Don't create notifications for certain event types
    switch (event.type) {
      case WebSocketEventType.userTyping:
      case WebSocketEventType.userStoppedTyping:
      case WebSocketEventType.presenceUpdate:
        return false;

      case WebSocketEventType.messageReceived:
        // Don't duplicate if we already got FCM notification
        return !_isInForeground;

      default:
        return true;
    }
  }

  String _getMessagePreview(ChatMessage message) {
    switch (message.type) {
      case 'text':
        return message.content;
      case 'image':
        return '📷 Photo';
      case 'video':
        return '🎥 Video';
      case 'audio':
        return '🎵 Audio';
      case 'document':
        return '📄 Document';
      case 'location':
        return '📍 Location';
      case 'contact':
        return '👤 Contact';
      case 'voice_note':
        return '🎤 Voice message';
      default:
        return message.content.isNotEmpty ? message.content : 'New message';
    }
  }

  String? _getNotificationGroupKey(NotificationData notification) {
    switch (notification.type) {
      case NotificationType.message:
      case NotificationType.groupMessage:
        return 'chat_${notification.data['chat_id']}';

      case NotificationType.groupUpdate:
        return 'group_${notification.data['group_id']}';

      case NotificationType.reaction:
        return 'reactions_${notification.data['message_id']}';

      default:
        return null;
    }
  }

  String _getGroupedNotificationTitle(
    String groupKey,
    List<NotificationData> notifications,
  ) {
    if (groupKey.startsWith('chat_')) {
      final chatName =
          notifications.first.data['chat_name'] ??
          notifications.first.data['sender_name'] ??
          'Chat';
      return '$chatName (${notifications.length} messages)';
    } else if (groupKey.startsWith('group_')) {
      final groupName = notifications.first.data['group_name'] ?? 'Group';
      return '$groupName (${notifications.length} updates)';
    } else {
      return '${notifications.length} notifications';
    }
  }

  String _getGroupedNotificationBody(List<NotificationData> notifications) {
    if (notifications.length <= 3) {
      return notifications.map((n) => n.body).join('\n');
    } else {
      final firstThree = notifications.take(3).map((n) => n.body).join('\n');
      final remaining = notifications.length - 3;
      return '$firstThree\n...and $remaining more';
    }
  }

  Future<void> _routeNotificationAction(
    Map<String, dynamic> data,
    String? actionId,
  ) async {
    final type = data['type'];

    switch (type) {
      case 'message':
      case 'grouped':
        await _handleMessageNotificationAction(data, actionId);
        break;

      case 'call':
        await _handleCallNotificationAction(data, actionId);
        break;

      case 'group':
        await _handleGroupNotificationAction(data, actionId);
        break;

      default:
        await _handleGenericNotificationAction(data, actionId);
        break;
    }
  }

  Future<void> _handleMessageNotificationAction(
    Map<String, dynamic> data,
    String? actionId,
  ) async {
    final chatId = data['chat_id'];

    switch (actionId) {
      case 'reply':
        // Navigate to chat screen for reply
        await _navigateToChat(chatId);
        break;

      case 'mark_read':
        await _markChatAsRead(chatId);
        break;

      default:
        // Default action - open chat
        await _navigateToChat(chatId);
        break;
    }
  }

  Future<void> _handleCallNotificationAction(
    Map<String, dynamic> data,
    String? actionId,
  ) async {
    final callId = data['call_id'];

    switch (actionId) {
      case 'answer':
        await _answerCall(callId);
        break;

      case 'decline':
        await _declineCall(callId);
        break;

      default:
        // Default action - open call screen
        await _navigateToCall(callId);
        break;
    }
  }

  Future<void> _handleGroupNotificationAction(
    Map<String, dynamic> data,
    String? actionId,
  ) async {
    final groupId = data['group_id'];

    switch (actionId) {
      case 'view_group':
        await _navigateToGroup(groupId);
        break;

      default:
        await _navigateToGroup(groupId);
        break;
    }
  }

  Future<void> _handleGenericNotificationAction(
    Map<String, dynamic> data,
    String? actionId,
  ) async {
    final actionUrl = data['action_url'];

    if (actionUrl != null) {
      await _openUrl(actionUrl);
    } else {
      // Default action - open app
      await _openApp();
    }
  }

  // Navigation methods (these would integrate with your navigation system)
  Future<void> _navigateToChat(String chatId) async {
    // Implementation depends on your navigation system
    if (kDebugMode) {
      print('📱 Navigate to chat: $chatId');
    }
  }

  Future<void> _navigateToCall(String callId) async {
    if (kDebugMode) {
      print('📞 Navigate to call: $callId');
    }
  }

  Future<void> _navigateToGroup(String groupId) async {
    if (kDebugMode) {
      print('👥 Navigate to group: $groupId');
    }
  }

  Future<void> _openUrl(String url) async {
    if (kDebugMode) {
      print('🔗 Open URL: $url');
    }
  }

  Future<void> _openApp() async {
    if (kDebugMode) {
      print('📱 Open app');
    }
  }

  // Action handlers
  Future<void> _markChatAsRead(String chatId) async {
    try {
      // This would call your API to mark chat as read
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

  Future<void> _answerCall(String callId) async {
    try {
      // This would call your call service to answer the call
      if (kDebugMode) {
        print('📞 Answering call: $callId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error answering call: $e');
      }
    }
  }

  Future<void> _declineCall(String callId) async {
    try {
      // This would call your call service to decline the call
      await _localNotificationService.cancelCallNotification();

      if (kDebugMode) {
        print('📞 Declining call: $callId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error declining call: $e');
      }
    }
  }

  // Settings and permissions
  Future<void> _loadNotificationSettings() async {
    try {
      _notificationSettings = _localStorage.getNotificationSettings();
      _settingsLastUpdated = DateTime.now();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading notification settings: $e');
      }
    }
  }

  Future<Map<String, dynamic>> _getNotificationSettings() async {
    // Refresh settings if they're older than 5 minutes
    if (_notificationSettings == null ||
        _settingsLastUpdated == null ||
        DateTime.now().difference(_settingsLastUpdated!).inMinutes > 5) {
      await _loadNotificationSettings();
    }

    return _notificationSettings ?? {};
  }

  Future<bool> _areNotificationsEnabled() async {
    final settings = await _getNotificationSettings();
    return settings['enabled'] ?? true;
  }

  Future<bool> _isNotificationTypeEnabled(NotificationType type) async {
    final settings = await _getNotificationSettings();

    switch (type) {
      case NotificationType.message:
        return settings['message_notifications'] ?? true;

      case NotificationType.call:
        return settings['call_notifications'] ?? true;

      case NotificationType.groupMessage:
      case NotificationType.groupUpdate:
        return settings['group_notifications'] ?? true;

      case NotificationType.statusUpdate:
        return settings['status_notifications'] ?? true;

      case NotificationType.systemAnnouncement:
        return settings['system_notifications'] ?? true;

      case NotificationType.reaction:
        return settings['reaction_notifications'] ?? false;

      case NotificationType.mention:
        return true; // Always show mentions

      default:
        return true;
    }
  }

  Future<bool> _isDoNotDisturbActive() async {
    final settings = await _getNotificationSettings();

    if (!settings['do_not_disturb']) {
      return false;
    }

    // Check quiet hours
    final quietHoursStart = settings['quiet_hours_start'] ?? '22:00';
    final quietHoursEnd = settings['quiet_hours_end'] ?? '07:00';

    final now = DateTime.now();
    final currentTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    // Simple time range check (doesn't handle midnight crossing properly)
    return currentTime.compareTo(quietHoursStart) >= 0 ||
        currentTime.compareTo(quietHoursEnd) <= 0;
  }

  Future<void> _updateBadgeCount() async {
    try {
      final currentCount = _localStorage.getInt('total_unread_count') ?? 0;
      await _localStorage.setInt('total_unread_count', currentCount + 1);

      // Update system badge
      await _localNotificationService.updateBadgeCount(currentCount + 1);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating badge count: $e');
      }
    }
  }

  Future<void> _logNotification(NotificationData notification) async {
    try {
      // Log notification for analytics
      final logData = {
        'type': notification.type.name,
        'timestamp': notification.timestamp.toIso8601String(),
        'priority': notification.priority.name,
        'has_image': notification.imageUrl != null,
        'has_actions': notification.actions != null,
      };

      // Save to local storage for later analytics upload
      final logs = _localStorage.getStringList('notification_logs') ?? [];
      logs.add(jsonEncode(logData));

      // Keep only last 100 logs
      if (logs.length > 100) {
        logs.removeRange(0, logs.length - 100);
      }

      await _localStorage.setStringList('notification_logs', logs);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error logging notification: $e');
      }
    }
  }

  Future<void> _handlePendingNotifications() async {
    try {
      // Handle any background messages that weren't processed
      final backgroundMessages =
          _localStorage.getStringList('background_messages') ?? [];

      for (final messageJson in backgroundMessages) {
        try {
          final messageData = jsonDecode(messageJson);
          // Process background message
          if (kDebugMode) {
            print(
              '🔔 Processing pending notification: ${messageData['message_id']}',
            );
          }
        } catch (e) {
          if (kDebugMode) {
            print('❌ Error processing background message: $e');
          }
        }
      }

      // Clear processed messages
      await _localStorage.setStringList('background_messages', []);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling pending notifications: $e');
      }
    }
  }

  // App state management
  void setAppForegroundState(bool isInForeground) {
    _isInForeground = isInForeground;

    if (kDebugMode) {
      print(
        '📱 App ${isInForeground ? 'entered foreground' : 'entered background'}',
      );
    }
  }

  void setCurrentChatId(String? chatId) {
    _currentChatId = chatId;

    if (kDebugMode) {
      print('📱 Current chat set to: $chatId');
    }
  }

  // Public API methods
  Future<void> updateNotificationSettings(Map<String, dynamic> settings) async {
    try {
      _notificationSettings = settings;
      _settingsLastUpdated = DateTime.now();

      await _localStorage.setNotificationSettings(settings);
      await _fcmService.updateNotificationSettings(settings);

      if (kDebugMode) {
        print('✅ Notification settings updated');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating notification settings: $e');
      }
    }
  }

  Future<void> clearAllNotifications() async {
    try {
      await _localNotificationService.cancelAllNotifications();
      await _localStorage.setInt('total_unread_count', 0);

      if (kDebugMode) {
        print('✅ All notifications cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error clearing notifications: $e');
      }
    }
  }

  Future<void> testNotification({
    String title = 'Test Notification',
    String body = 'This is a test notification',
    NotificationType type = NotificationType.message,
  }) async {
    final notification = NotificationData(
      type: type,
      title: title,
      body: body,
      data: {'test': true},
      priority: NotificationPriority.normal,
    );

    await _processNotification(notification);
  }

  Future<Map<String, dynamic>> getNotificationStats() async {
    try {
      final fcmStats = await _fcmService.getNotificationStats();
      final pendingNotifications = await _localNotificationService
          .getPendingNotifications();
      final activeNotifications = await _localNotificationService
          .getActiveNotifications();

      return {
        'fcm': fcmStats,
        'pending_count': pendingNotifications.length,
        'active_count': activeNotifications.length,
        'total_unread': _localStorage.getInt('total_unread_count') ?? 0,
        'is_initialized': _isInitialized,
        'is_foreground': _isInForeground,
        'current_chat': _currentChatId,
        'settings_last_updated': _settingsLastUpdated?.toIso8601String(),
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
    // Cancel all subscriptions
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();

    // Cancel all timers
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();

    // Clear grouped notifications
    _groupedNotifications.clear();

    // Close stream
    await _notificationController.close();

    // Dispose services
    await _fcmService.dispose();
    await _localNotificationService.dispose();

    if (kDebugMode) {
      print('✅ Notification Handler disposed');
    }
  }
}

// Riverpod providers
final notificationHandlerProvider = Provider<NotificationHandler>((ref) {
  return NotificationHandler();
});

final notificationStreamProvider = StreamProvider<NotificationData>((ref) {
  final handler = ref.watch(notificationHandlerProvider);
  return handler.notificationStream;
});

final notificationStatsProvider = FutureProvider<Map<String, dynamic>>((ref) {
  final handler = ref.watch(notificationHandlerProvider);
  return handler.getNotificationStats();
});
