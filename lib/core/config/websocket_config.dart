import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/storage/secure_storage.dart';
import 'app_config.dart';

enum WebSocketState { disconnected, connecting, connected, reconnecting, error }

enum MessageType {
  // Chat messages
  messageReceived,
  messageRead,
  messageDelivered,
  messageDeleted,
  messageEdited,

  // Typing indicators
  userTyping,
  userStoppedTyping,

  // Presence
  userOnline,
  userOffline,
  userLastSeen,

  // Chat events
  chatCreated,
  chatDeleted,
  chatArchived,
  chatMuted,
  participantAdded,
  participantRemoved,

  // Group events
  groupCreated,
  groupDeleted,
  groupUpdated,
  memberAdded,
  memberRemoved,
  memberRoleChanged,

  // Call events
  callInitiated,
  callAnswered,
  callEnded,
  callJoined,
  callLeft,
  callRinging,
  callBusy,

  // File events
  fileUploaded,
  fileDeleted,

  // System events
  systemMaintenance,
  systemBroadcast,

  // Authentication events
  tokenExpired,
  sessionTerminated,

  // Unknown
  unknown,
}

class WebSocketMessage {
  final MessageType type;
  final Map<String, dynamic> data;
  final String? id;
  final DateTime timestamp;

  WebSocketMessage({
    required this.type,
    required this.data,
    this.id,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory WebSocketMessage.fromJson(Map<String, dynamic> json) {
    return WebSocketMessage(
      type: _parseMessageType(json['type']),
      data: json['data'] ?? {},
      id: json['id'],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'data': data,
      if (id != null) 'id': id,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  static MessageType _parseMessageType(String? type) {
    if (type == null) return MessageType.unknown;

    try {
      return MessageType.values.firstWhere(
        (e) => e.name == type,
        orElse: () => MessageType.unknown,
      );
    } catch (e) {
      return MessageType.unknown;
    }
  }
}

class WebSocketConfig {
  static WebSocketChannel? _channel;
  static WebSocketState _state = WebSocketState.disconnected;
  static StreamController<WebSocketMessage>? _messageController;
  static StreamController<WebSocketState>? _stateController;
  static Timer? _heartbeatTimer;
  static Timer? _reconnectTimer;
  static int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _heartbeatInterval = Duration(seconds: 30);
  static const Duration _reconnectDelay = Duration(seconds: 3);
  static final SecureStorage _storage = SecureStorage();

  // Getters
  static WebSocketState get state => _state;
  static Stream<WebSocketMessage> get messageStream =>
      _messageController?.stream ?? const Stream.empty();
  static Stream<WebSocketState> get stateStream =>
      _stateController?.stream ?? const Stream.empty();
  static bool get isConnected => _state == WebSocketState.connected;

  // Initialize WebSocket connection
  static Future<void> connect() async {
    if (_state == WebSocketState.connecting ||
        _state == WebSocketState.connected) {
      return;
    }

    try {
      _setState(WebSocketState.connecting);

      final token = await _storage.getAccessToken();
      if (token == null || token.isEmpty) {
        throw Exception('No access token available');
      }

      final uri = Uri.parse('${AppConfig.websocketUrl}?token=$token');

      if (AppConfig.enableWebSocketLogs) {
        debugPrint('🔌 Connecting to WebSocket: $uri');
      }

      _channel = WebSocketChannel.connect(uri);
      _messageController ??= StreamController<WebSocketMessage>.broadcast();
      _stateController ??= StreamController<WebSocketState>.broadcast();

      // Listen to WebSocket stream
      _channel!.stream.listen(_onMessage, onError: _onError, onDone: _onDone);

      _setState(WebSocketState.connected);
      _resetReconnectAttempts();
      _startHeartbeat();

      if (AppConfig.enableWebSocketLogs) {
        debugPrint('✅ WebSocket connected successfully');
      }
    } catch (e) {
      if (AppConfig.enableWebSocketLogs) {
        debugPrint('❌ WebSocket connection failed: $e');
      }
      _setState(WebSocketState.error);
      _scheduleReconnect();
    }
  }

  // Disconnect WebSocket
  static Future<void> disconnect() async {
    _stopHeartbeat();
    _stopReconnectTimer();

    if (_channel != null) {
      await _channel!.sink.close(status.normalClosure);
      _channel = null;
    }

    _setState(WebSocketState.disconnected);

    if (AppConfig.enableWebSocketLogs) {
      debugPrint('🔌 WebSocket disconnected');
    }
  }

  // Send message
  static void sendMessage(WebSocketMessage message) {
    if (_state != WebSocketState.connected || _channel == null) {
      if (AppConfig.enableWebSocketLogs) {
        debugPrint('⚠️ Cannot send message: WebSocket not connected');
      }
      return;
    }

    try {
      final jsonMessage = jsonEncode(message.toJson());
      _channel!.sink.add(jsonMessage);

      if (AppConfig.enableWebSocketLogs) {
        debugPrint('📤 Sent: ${message.type.name}');
      }
    } catch (e) {
      if (AppConfig.enableWebSocketLogs) {
        debugPrint('❌ Failed to send message: $e');
      }
    }
  }

  // Send typing indicator
  static void sendTyping(String chatId, bool isTyping) {
    sendMessage(
      WebSocketMessage(
        type: isTyping ? MessageType.userTyping : MessageType.userStoppedTyping,
        data: {'chat_id': chatId},
      ),
    );
  }

  // Send presence update
  static void sendPresenceUpdate(bool isOnline) {
    sendMessage(
      WebSocketMessage(
        type: isOnline ? MessageType.userOnline : MessageType.userOffline,
        data: {'timestamp': DateTime.now().toIso8601String()},
      ),
    );
  }

  // Send message read acknowledgment
  static void sendMessageRead(String messageId, String chatId) {
    sendMessage(
      WebSocketMessage(
        type: MessageType.messageRead,
        data: {
          'message_id': messageId,
          'chat_id': chatId,
          'read_at': DateTime.now().toIso8601String(),
        },
      ),
    );
  }

  // Handle incoming messages
  static void _onMessage(dynamic data) {
    try {
      final json = jsonDecode(data as String) as Map<String, dynamic>;
      final message = WebSocketMessage.fromJson(json);

      if (AppConfig.enableWebSocketLogs) {
        debugPrint('📥 Received: ${message.type.name}');
      }

      // Handle special system messages
      if (message.type == MessageType.tokenExpired) {
        _handleTokenExpired();
        return;
      }

      if (message.type == MessageType.sessionTerminated) {
        _handleSessionTerminated();
        return;
      }

      _messageController?.add(message);
    } catch (e) {
      if (AppConfig.enableWebSocketLogs) {
        debugPrint('❌ Failed to parse WebSocket message: $e');
      }
    }
  }

  // Handle WebSocket errors
  static void _onError(error) {
    if (AppConfig.enableWebSocketLogs) {
      debugPrint('❌ WebSocket error: $error');
    }

    _setState(WebSocketState.error);
    _scheduleReconnect();
  }

  // Handle WebSocket closure
  static void _onDone() {
    if (AppConfig.enableWebSocketLogs) {
      debugPrint('🔌 WebSocket connection closed');
    }

    _setState(WebSocketState.disconnected);
    _stopHeartbeat();

    if (_reconnectAttempts < _maxReconnectAttempts) {
      _scheduleReconnect();
    }
  }

  // Update connection state
  static void _setState(WebSocketState newState) {
    if (_state != newState) {
      _state = newState;
      _stateController?.add(newState);

      if (AppConfig.enableWebSocketLogs) {
        debugPrint('🔄 WebSocket state: ${newState.name}');
      }
    }
  }

  // Start heartbeat
  static void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (timer) {
      if (_state == WebSocketState.connected) {
        sendMessage(
          WebSocketMessage(
            type: MessageType.unknown, // Use as ping
            data: {'ping': DateTime.now().millisecondsSinceEpoch},
          ),
        );
      }
    });
  }

  // Stop heartbeat
  static void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  // Schedule reconnection
  static void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      if (AppConfig.enableWebSocketLogs) {
        debugPrint('❌ Max reconnect attempts reached');
      }
      return;
    }

    _stopReconnectTimer();
    _setState(WebSocketState.reconnecting);

    final delay = _reconnectDelay * (_reconnectAttempts + 1);
    _reconnectAttempts++;

    if (AppConfig.enableWebSocketLogs) {
      debugPrint(
        '🔄 Scheduling reconnect attempt $_reconnectAttempts in ${delay.inSeconds}s',
      );
    }

    _reconnectTimer = Timer(delay, () {
      connect();
    });
  }

  // Stop reconnect timer
  static void _stopReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  // Reset reconnect attempts
  static void _resetReconnectAttempts() {
    _reconnectAttempts = 0;
  }

  // Handle token expiration
  static void _handleTokenExpired() {
    if (AppConfig.enableWebSocketLogs) {
      debugPrint('🔑 Token expired, disconnecting WebSocket');
    }
    disconnect();
  }

  // Handle session termination
  static void _handleSessionTerminated() {
    if (AppConfig.enableWebSocketLogs) {
      debugPrint('🚪 Session terminated, disconnecting WebSocket');
    }
    disconnect();
  }

  // Cleanup resources
  static Future<void> dispose() async {
    await disconnect();
    await _messageController?.close();
    await _stateController?.close();
    _messageController = null;
    _stateController = null;
  }
}

// Riverpod providers
final webSocketStateProvider = StreamProvider<WebSocketState>((ref) {
  return WebSocketConfig.stateStream;
});

final webSocketMessageProvider = StreamProvider<WebSocketMessage>((ref) {
  return WebSocketConfig.messageStream;
});

final webSocketControllerProvider = Provider<WebSocketController>((ref) {
  return WebSocketController();
});

// WebSocket controller class
class WebSocketController {
  void connect() => WebSocketConfig.connect();
  void disconnect() => WebSocketConfig.disconnect();
  void sendMessage(WebSocketMessage message) =>
      WebSocketConfig.sendMessage(message);
  void sendTyping(String chatId, bool isTyping) =>
      WebSocketConfig.sendTyping(chatId, isTyping);
  void sendPresenceUpdate(bool isOnline) =>
      WebSocketConfig.sendPresenceUpdate(isOnline);
  void sendMessageRead(String messageId, String chatId) =>
      WebSocketConfig.sendMessageRead(messageId, chatId);

  bool get isConnected => WebSocketConfig.isConnected;
  WebSocketState get state => WebSocketConfig.state;
}

// Helper extension for WebSocket message types
extension MessageTypeExtension on MessageType {
  bool get isMessageEvent {
    switch (this) {
      case MessageType.messageReceived:
      case MessageType.messageRead:
      case MessageType.messageDelivered:
      case MessageType.messageDeleted:
      case MessageType.messageEdited:
        return true;
      default:
        return false;
    }
  }

  bool get isTypingEvent {
    switch (this) {
      case MessageType.userTyping:
      case MessageType.userStoppedTyping:
        return true;
      default:
        return false;
    }
  }

  bool get isPresenceEvent {
    switch (this) {
      case MessageType.userOnline:
      case MessageType.userOffline:
      case MessageType.userLastSeen:
        return true;
      default:
        return false;
    }
  }

  bool get isCallEvent {
    switch (this) {
      case MessageType.callInitiated:
      case MessageType.callAnswered:
      case MessageType.callEnded:
      case MessageType.callJoined:
      case MessageType.callLeft:
      case MessageType.callRinging:
      case MessageType.callBusy:
        return true;
      default:
        return false;
    }
  }
}
