import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../storage/secure_storage.dart';

enum WebSocketConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
  authenticating,
  authenticated,
}

enum WebSocketEventType {
  // Connection events
  connect,
  disconnect,
  error,
  reconnect,

  // Authentication
  authenticate,
  authSuccess,
  authError,

  // Chat events
  messageReceived,
  messageDelivered,
  messageRead,
  messageDeleted,
  messageEdited,
  messageReaction,

  // Typing events
  userTyping,
  userStoppedTyping,

  // Presence events
  userOnline,
  userOffline,
  userLastSeen,
  presenceUpdate,

  // Chat management
  chatCreated,
  chatDeleted,
  chatUpdated,
  chatArchived,
  chatMuted,
  participantAdded,
  participantRemoved,
  participantUpdated,

  // Group events
  groupCreated,
  groupDeleted,
  groupUpdated,
  memberAdded,
  memberRemoved,
  memberRoleChanged,
  memberMuted,
  memberBanned,

  // Call events
  callInitiated,
  callAnswered,
  callRejected,
  callEnded,
  callJoined,
  callLeft,
  callRinging,
  callBusy,
  callMediaUpdate,
  callQualityUpdate,

  // File events
  fileUploaded,
  fileProgress,
  fileError,

  // Status events
  statusUpdated,
  statusDeleted,
  statusViewed,

  // System events
  systemMaintenance,
  systemBroadcast,
  systemUpdate,
  forceLogout,
  rateLimitExceeded,

  // Custom events
  custom,
  unknown,
}

class WebSocketEvent {
  final WebSocketEventType type;
  final Map<String, dynamic> data;
  final String? id;
  final DateTime timestamp;
  final String? userId;
  final String? chatId;

  WebSocketEvent({
    required this.type,
    required this.data,
    this.id,
    DateTime? timestamp,
    this.userId,
    this.chatId,
  }) : timestamp = timestamp ?? DateTime.now();

  factory WebSocketEvent.fromJson(Map<String, dynamic> json) {
    return WebSocketEvent(
      type: _parseEventType(json['type']),
      data: json['data'] ?? {},
      id: json['id'],
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp']) ?? DateTime.now()
          : DateTime.now(),
      userId: json['user_id'],
      chatId: json['chat_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'data': data,
      if (id != null) 'id': id,
      'timestamp': timestamp.toIso8601String(),
      if (userId != null) 'user_id': userId,
      if (chatId != null) 'chat_id': chatId,
    };
  }

  static WebSocketEventType _parseEventType(String? type) {
    if (type == null) return WebSocketEventType.unknown;

    try {
      return WebSocketEventType.values.firstWhere(
        (e) => e.name == type,
        orElse: () => WebSocketEventType.unknown,
      );
    } catch (e) {
      return WebSocketEventType.unknown;
    }
  }
}

class WebSocketService {
  static WebSocketService? _instance;

  // WebSocket connection
  WebSocketChannel? _channel;
  WebSocketConnectionState _state = WebSocketConnectionState.disconnected;

  // Event streams
  final StreamController<WebSocketEvent> _eventController =
      StreamController<WebSocketEvent>.broadcast();
  final StreamController<WebSocketConnectionState> _stateController =
      StreamController<WebSocketConnectionState>.broadcast();

  // Reconnection logic
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  Timer? _connectionTimeoutTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _heartbeatInterval = Duration(seconds: 30);
  static const Duration _connectionTimeout = Duration(seconds: 30);
  static const Duration _initialReconnectDelay = Duration(seconds: 2);

  // Dependencies
  final SecureStorage _storage = SecureStorage();

  // Event queue for offline messages
  final List<WebSocketEvent> _pendingEvents = [];
  bool _isOnline = true;

  // Subscriptions
  final Map<String, Set<String>> _subscriptions = {};

  WebSocketService._internal();

  factory WebSocketService() {
    _instance ??= WebSocketService._internal();
    return _instance!;
  }

  // Getters
  WebSocketConnectionState get state => _state;
  Stream<WebSocketEvent> get eventStream => _eventController.stream;
  Stream<WebSocketConnectionState> get stateStream => _stateController.stream;
  bool get isConnected =>
      _state == WebSocketConnectionState.connected ||
      _state == WebSocketConnectionState.authenticated;
  bool get isAuthenticated => _state == WebSocketConnectionState.authenticated;

  Future<void> connect() async {
    if (_state == WebSocketConnectionState.connecting ||
        _state == WebSocketConnectionState.connected) {
      return;
    }

    try {
      _setState(WebSocketConnectionState.connecting);
      _startConnectionTimeout();

      final token = await _storage.getAccessToken();
      if (token == null || token.isEmpty) {
        throw Exception('No access token available');
      }

      final uri = Uri.parse('${AppConfig.websocketUrl}?token=$token');

      if (AppConfig.enableWebSocketLogs) {
        debugPrint('🔌 Connecting to WebSocket: $uri');
      }

      _channel = WebSocketChannel.connect(uri);

      // Listen to WebSocket stream
      _channel!.stream.listen(_onMessage, onError: _onError, onDone: _onDone);

      _setState(WebSocketConnectionState.connected);
      _cancelConnectionTimeout();
      _resetReconnectAttempts();
      _startHeartbeat();
      _authenticate();
      _processPendingEvents();

      if (AppConfig.enableWebSocketLogs) {
        debugPrint('✅ WebSocket connected successfully');
      }
    } catch (e) {
      if (AppConfig.enableWebSocketLogs) {
        debugPrint('❌ WebSocket connection failed: $e');
      }
      _setState(WebSocketConnectionState.error);
      _scheduleReconnect();
    }
  }

  Future<void> disconnect() async {
    _stopHeartbeat();
    _stopReconnectTimer();
    _cancelConnectionTimeout();

    if (_channel != null) {
      try {
        await _channel!.sink.close(status.normalClosure);
      } catch (e) {
        if (AppConfig.enableWebSocketLogs) {
          debugPrint('⚠️ Error closing WebSocket: $e');
        }
      }
      _channel = null;
    }

    _setState(WebSocketConnectionState.disconnected);

    if (AppConfig.enableWebSocketLogs) {
      debugPrint('🔌 WebSocket disconnected');
    }
  }

  Future<void> _authenticate() async {
    try {
      _setState(WebSocketConnectionState.authenticating);

      final deviceId = await _storage.getDeviceId();
      final fcmToken = await _storage.getFcmToken();

      final authEvent = WebSocketEvent(
        type: WebSocketEventType.authenticate,
        data: {
          'device_id': deviceId,
          'fcm_token': fcmToken,
          'platform': Platform.operatingSystem,
          'app_version': AppConfig.appVersion,
        },
      );

      _sendEvent(authEvent);

      if (AppConfig.enableWebSocketLogs) {
        debugPrint('🔐 Authentication request sent');
      }
    } catch (e) {
      if (AppConfig.enableWebSocketLogs) {
        debugPrint('❌ Authentication failed: $e');
      }
      _setState(WebSocketConnectionState.error);
    }
  }

  void _sendEvent(WebSocketEvent event) {
    if (!isConnected || _channel == null) {
      if (AppConfig.enableWebSocketLogs) {
        debugPrint('⚠️ Cannot send event: WebSocket not connected');
      }

      // Queue event for later
      if (event.type != WebSocketEventType.authenticate) {
        _pendingEvents.add(event);
      }
      return;
    }

    try {
      final jsonMessage = jsonEncode(event.toJson());
      _channel!.sink.add(jsonMessage);

      if (AppConfig.enableWebSocketLogs) {
        debugPrint('📤 Sent: ${event.type.name}');
      }
    } catch (e) {
      if (AppConfig.enableWebSocketLogs) {
        debugPrint('❌ Failed to send event: $e');
      }
    }
  }

  void _onMessage(dynamic data) {
    try {
      final json = jsonDecode(data as String) as Map<String, dynamic>;
      final event = WebSocketEvent.fromJson(json);

      if (AppConfig.enableWebSocketLogs) {
        debugPrint('📥 Received: ${event.type.name}');
      }

      // Handle special system events
      switch (event.type) {
        case WebSocketEventType.authSuccess:
          _setState(WebSocketConnectionState.authenticated);
          _handleSubscriptions();
          break;
        case WebSocketEventType.authError:
          _setState(WebSocketConnectionState.error);
          break;
        case WebSocketEventType.forceLogout:
          _handleForceLogout();
          return;
        case WebSocketEventType.rateLimitExceeded:
          _handleRateLimit(event);
          break;
        default:
          break;
      }

      _eventController.add(event);
    } catch (e) {
      if (AppConfig.enableWebSocketLogs) {
        debugPrint('❌ Failed to parse WebSocket message: $e');
      }
    }
  }

  void _onError(error) {
    if (AppConfig.enableWebSocketLogs) {
      debugPrint('❌ WebSocket error: $error');
    }

    _setState(WebSocketConnectionState.error);
    _scheduleReconnect();
  }

  void _onDone() {
    if (AppConfig.enableWebSocketLogs) {
      debugPrint('🔌 WebSocket connection closed');
    }

    _setState(WebSocketConnectionState.disconnected);
    _stopHeartbeat();

    if (_reconnectAttempts < _maxReconnectAttempts) {
      _scheduleReconnect();
    }
  }

  void _setState(WebSocketConnectionState newState) {
    if (_state != newState) {
      _state = newState;
      _stateController.add(newState);

      if (AppConfig.enableWebSocketLogs) {
        debugPrint('🔄 WebSocket state: ${newState.name}');
      }
    }
  }

  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (timer) {
      if (isConnected) {
        _sendHeartbeat();
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _sendHeartbeat() {
    final heartbeatEvent = WebSocketEvent(
      type: WebSocketEventType.custom,
      data: {
        'action': 'ping',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
    _sendEvent(heartbeatEvent);
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      if (AppConfig.enableWebSocketLogs) {
        debugPrint('❌ Max reconnect attempts reached');
      }
      return;
    }

    _stopReconnectTimer();
    _setState(WebSocketConnectionState.reconnecting);

    // Exponential backoff with jitter
    final baseDelay = _initialReconnectDelay.inMilliseconds;
    final exponentialDelay = baseDelay * pow(2, _reconnectAttempts);
    final jitter = Random().nextInt(1000);
    final totalDelay = Duration(
      milliseconds: exponentialDelay.toInt() + jitter,
    );

    _reconnectAttempts++;

    if (AppConfig.enableWebSocketLogs) {
      debugPrint(
        '🔄 Scheduling reconnect attempt $_reconnectAttempts in ${totalDelay.inSeconds}s',
      );
    }

    _reconnectTimer = Timer(totalDelay, () {
      connect();
    });
  }

  void _stopReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  void _resetReconnectAttempts() {
    _reconnectAttempts = 0;
  }

  void _startConnectionTimeout() {
    _cancelConnectionTimeout();
    _connectionTimeoutTimer = Timer(_connectionTimeout, () {
      if (_state == WebSocketConnectionState.connecting) {
        if (AppConfig.enableWebSocketLogs) {
          debugPrint('⏰ Connection timeout');
        }
        _setState(WebSocketConnectionState.error);
        _scheduleReconnect();
      }
    });
  }

  void _cancelConnectionTimeout() {
    _connectionTimeoutTimer?.cancel();
    _connectionTimeoutTimer = null;
  }

  void _processPendingEvents() {
    if (_pendingEvents.isNotEmpty && isAuthenticated) {
      for (final event in _pendingEvents) {
        _sendEvent(event);
      }
      _pendingEvents.clear();

      if (AppConfig.enableWebSocketLogs) {
        debugPrint('✅ Processed ${_pendingEvents.length} pending events');
      }
    }
  }

  void _handleForceLogout() {
    if (AppConfig.enableWebSocketLogs) {
      debugPrint('🚪 Force logout received');
    }

    // Clear tokens and disconnect
    _storage.clearTokens();
    disconnect();
  }

  void _handleRateLimit(WebSocketEvent event) {
    final retryAfter = event.data['retry_after'] as int? ?? 60;

    if (AppConfig.enableWebSocketLogs) {
      debugPrint('⚠️ Rate limit exceeded. Retry after ${retryAfter}s');
    }

    // Disconnect and wait before reconnecting
    disconnect();
    Timer(Duration(seconds: retryAfter), () {
      connect();
    });
  }

  void _handleSubscriptions() {
    // Re-subscribe to channels after authentication
    for (final entry in _subscriptions.entries) {
      final channel = entry.key;
      final events = entry.value;
      _subscribeToChannel(channel, events);
    }
  }

  // Public API methods
  void sendMessage(Map<String, dynamic> messageData) {
    final event = WebSocketEvent(
      type: WebSocketEventType.messageReceived,
      data: messageData,
      chatId: messageData['chat_id'],
    );
    _sendEvent(event);
  }

  void sendTyping(String chatId, bool isTyping) {
    final event = WebSocketEvent(
      type: isTyping
          ? WebSocketEventType.userTyping
          : WebSocketEventType.userStoppedTyping,
      data: {'chat_id': chatId},
      chatId: chatId,
    );
    _sendEvent(event);
  }

  void sendPresenceUpdate(bool isOnline) {
    final event = WebSocketEvent(
      type: isOnline
          ? WebSocketEventType.userOnline
          : WebSocketEventType.userOffline,
      data: {
        'timestamp': DateTime.now().toIso8601String(),
        'is_online': isOnline,
      },
    );
    _sendEvent(event);
  }

  void markMessageAsRead(String messageId, String chatId) {
    final event = WebSocketEvent(
      type: WebSocketEventType.messageRead,
      data: {
        'message_id': messageId,
        'chat_id': chatId,
        'read_at': DateTime.now().toIso8601String(),
      },
      chatId: chatId,
    );
    _sendEvent(event);
  }

  void sendReaction(String messageId, String chatId, String emoji) {
    final event = WebSocketEvent(
      type: WebSocketEventType.messageReaction,
      data: {
        'message_id': messageId,
        'chat_id': chatId,
        'emoji': emoji,
        'action': 'add',
      },
      chatId: chatId,
    );
    _sendEvent(event);
  }

  void removeReaction(String messageId, String chatId) {
    final event = WebSocketEvent(
      type: WebSocketEventType.messageReaction,
      data: {'message_id': messageId, 'chat_id': chatId, 'action': 'remove'},
      chatId: chatId,
    );
    _sendEvent(event);
  }

  // Call-related events
  void initiateCall(Map<String, dynamic> callData) {
    final event = WebSocketEvent(
      type: WebSocketEventType.callInitiated,
      data: callData,
      chatId: callData['chat_id'],
    );
    _sendEvent(event);
  }

  void answerCall(String callId, bool accept) {
    final event = WebSocketEvent(
      type: accept
          ? WebSocketEventType.callAnswered
          : WebSocketEventType.callRejected,
      data: {'call_id': callId, 'accepted': accept},
    );
    _sendEvent(event);
  }

  void endCall(String callId) {
    final event = WebSocketEvent(
      type: WebSocketEventType.callEnded,
      data: {'call_id': callId},
    );
    _sendEvent(event);
  }

  void updateCallMedia(String callId, Map<String, dynamic> mediaState) {
    final event = WebSocketEvent(
      type: WebSocketEventType.callMediaUpdate,
      data: {'call_id': callId, ...mediaState},
    );
    _sendEvent(event);
  }

  // Subscription management
  void subscribeToChat(String chatId) {
    _addSubscription('chat:$chatId', {
      WebSocketEventType.messageReceived.name,
      WebSocketEventType.messageDeleted.name,
      WebSocketEventType.messageEdited.name,
      WebSocketEventType.messageReaction.name,
      WebSocketEventType.userTyping.name,
      WebSocketEventType.userStoppedTyping.name,
      WebSocketEventType.participantAdded.name,
      WebSocketEventType.participantRemoved.name,
    });
  }

  void unsubscribeFromChat(String chatId) {
    _removeSubscription('chat:$chatId');
  }

  void subscribeToUser(String userId) {
    _addSubscription('user:$userId', {
      WebSocketEventType.presenceUpdate.name,
      WebSocketEventType.userOnline.name,
      WebSocketEventType.userOffline.name,
      WebSocketEventType.userLastSeen.name,
    });
  }

  void unsubscribeFromUser(String userId) {
    _removeSubscription('user:$userId');
  }

  void subscribeToGroup(String groupId) {
    _addSubscription('group:$groupId', {
      WebSocketEventType.groupUpdated.name,
      WebSocketEventType.memberAdded.name,
      WebSocketEventType.memberRemoved.name,
      WebSocketEventType.memberRoleChanged.name,
    });
  }

  void unsubscribeFromGroup(String groupId) {
    _removeSubscription('group:$groupId');
  }

  void _addSubscription(String channel, Set<String> events) {
    _subscriptions[channel] = events;
    if (isAuthenticated) {
      _subscribeToChannel(channel, events);
    }
  }

  void _removeSubscription(String channel) {
    _subscriptions.remove(channel);
    if (isAuthenticated) {
      _unsubscribeFromChannel(channel);
    }
  }

  void _subscribeToChannel(String channel, Set<String> events) {
    final event = WebSocketEvent(
      type: WebSocketEventType.custom,
      data: {
        'action': 'subscribe',
        'channel': channel,
        'events': events.toList(),
      },
    );
    _sendEvent(event);
  }

  void _unsubscribeFromChannel(String channel) {
    final event = WebSocketEvent(
      type: WebSocketEventType.custom,
      data: {'action': 'unsubscribe', 'channel': channel},
    );
    _sendEvent(event);
  }

  // Network status handling
  void setNetworkStatus(bool isOnline) {
    if (_isOnline != isOnline) {
      _isOnline = isOnline;

      if (isOnline) {
        if (_state == WebSocketConnectionState.disconnected) {
          connect();
        }
      } else {
        if (isConnected) {
          disconnect();
        }
      }
    }
  }

  // Custom events
  void sendCustomEvent(String action, Map<String, dynamic> data) {
    final event = WebSocketEvent(
      type: WebSocketEventType.custom,
      data: {'action': action, ...data},
    );
    _sendEvent(event);
  }

  // Event filtering
  Stream<WebSocketEvent> filterEvents(WebSocketEventType type) {
    return eventStream.where((event) => event.type == type);
  }

  Stream<WebSocketEvent> filterEventsByChat(String chatId) {
    return eventStream.where((event) => event.chatId == chatId);
  }

  Stream<WebSocketEvent> filterEventsByUser(String userId) {
    return eventStream.where((event) => event.userId == userId);
  }

  // Cleanup
  Future<void> dispose() async {
    await disconnect();
    await _eventController.close();
    await _stateController.close();
    _pendingEvents.clear();
    _subscriptions.clear();

    if (AppConfig.enableWebSocketLogs) {
      debugPrint('✅ WebSocket service disposed');
    }
  }
}

// Riverpod providers
final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  return WebSocketService();
});

final webSocketStateProvider = StreamProvider<WebSocketConnectionState>((ref) {
  final service = ref.watch(webSocketServiceProvider);
  return service.stateStream;
});

final webSocketEventProvider = StreamProvider<WebSocketEvent>((ref) {
  final service = ref.watch(webSocketServiceProvider);
  return service.eventStream;
});

final webSocketConnectedProvider = Provider<bool>((ref) {
  final state = ref.watch(webSocketStateProvider);
  return state.when(
    data: (state) =>
        state == WebSocketConnectionState.connected ||
        state == WebSocketConnectionState.authenticated,
    loading: () => false,
    error: (_, __) => false,
  );
});
