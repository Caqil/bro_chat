import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/cache_service.dart';
import 'websocket_service.dart';

class ChatSocketService {
  static ChatSocketService? _instance;

  final WebSocketService _webSocketService;
  final CacheService _cacheService;

  // Streams for different chat events
  final StreamController<ChatMessage> _messageReceivedController =
      StreamController<ChatMessage>.broadcast();
  final StreamController<MessageStatus> _messageStatusController =
      StreamController<MessageStatus>.broadcast();
  final StreamController<TypingStatus> _typingController =
      StreamController<TypingStatus>.broadcast();
  final StreamController<ChatUpdate> _chatUpdateController =
      StreamController<ChatUpdate>.broadcast();
  final StreamController<MessageReaction> _reactionController =
      StreamController<MessageReaction>.broadcast();

  // Active subscriptions
  final Set<String> _subscribedChats = <String>{};
  final Map<String, Timer> _typingTimers = {};

  // Typing users cache
  final Map<String, Set<String>> _typingUsers = {}; // chatId -> Set of user IDs

  // Message delivery tracking
  final Map<String, Completer<bool>> _messageDeliveryCompleters = {};

  // Read receipt tracking
  final Map<String, Set<String>> _messageReadBy =
      {}; // messageId -> Set of user IDs

  ChatSocketService._internal()
    : _webSocketService = WebSocketService(),
      _cacheService = CacheService() {
    _initialize();
  }

  factory ChatSocketService() {
    _instance ??= ChatSocketService._internal();
    return _instance!;
  }

  // Getters for streams
  Stream<ChatMessage> get messageReceived => _messageReceivedController.stream;
  Stream<MessageStatus> get messageStatus => _messageStatusController.stream;
  Stream<TypingStatus> get typingStatus => _typingController.stream;
  Stream<ChatUpdate> get chatUpdates => _chatUpdateController.stream;
  Stream<MessageReaction> get reactions => _reactionController.stream;

  void _initialize() {
    // Listen to WebSocket events
    _webSocketService.eventStream.listen(_handleWebSocketEvent);

    // Listen to connection state changes
    _webSocketService.stateStream.listen(_handleConnectionStateChange);
  }

  void _handleWebSocketEvent(WebSocketEvent event) {
    switch (event.type) {
      case WebSocketEventType.messageReceived:
        _handleMessageReceived(event);
        break;
      case WebSocketEventType.messageDelivered:
        _handleMessageDelivered(event);
        break;
      case WebSocketEventType.messageRead:
        _handleMessageRead(event);
        break;
      case WebSocketEventType.messageDeleted:
        _handleMessageDeleted(event);
        break;
      case WebSocketEventType.messageEdited:
        _handleMessageEdited(event);
        break;
      case WebSocketEventType.messageReaction:
        _handleMessageReaction(event);
        break;
      case WebSocketEventType.userTyping:
        _handleUserTyping(event);
        break;
      case WebSocketEventType.userStoppedTyping:
        _handleUserStoppedTyping(event);
        break;
      case WebSocketEventType.chatCreated:
        _handleChatCreated(event);
        break;
      case WebSocketEventType.chatDeleted:
        _handleChatDeleted(event);
        break;
      case WebSocketEventType.chatUpdated:
        _handleChatUpdated(event);
        break;
      case WebSocketEventType.participantAdded:
        _handleParticipantAdded(event);
        break;
      case WebSocketEventType.participantRemoved:
        _handleParticipantRemoved(event);
        break;
      default:
        break;
    }
  }

  void _handleConnectionStateChange(WebSocketConnectionState state) {
    if (state == WebSocketConnectionState.authenticated) {
      // Re-subscribe to all chats
      _resubscribeToChats();
    } else if (state == WebSocketConnectionState.disconnected) {
      // Clear typing indicators
      _clearAllTypingIndicators();
    }
  }

  void _resubscribeToChats() {
    for (final chatId in _subscribedChats) {
      _webSocketService.subscribeToChat(chatId);
    }
  }

  // Message handling
  void _handleMessageReceived(WebSocketEvent event) {
    try {
      final message = ChatMessage.fromJson(event.data);

      // Cache the message
      _cacheService.cacheMessage(message.id, event.data);

      // Emit the message
      _messageReceivedController.add(message);

      // Send delivery confirmation if not from current user
      if (!message.isFromCurrentUser) {
        _sendMessageDelivered(message.id, message.chatId);
      }

      if (kDebugMode) {
        print('📥 Message received: ${message.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling received message: $e');
      }
    }
  }

  void _handleMessageDelivered(WebSocketEvent event) {
    try {
      final messageId = event.data['message_id'] as String;
      final deliveredTo = event.data['delivered_to'] as String;
      final deliveredAt =
          DateTime.tryParse(event.data['delivered_at'] ?? '') ?? DateTime.now();

      final status = MessageStatus(
        messageId: messageId,
        status: MessageStatusType.delivered,
        userId: deliveredTo,
        timestamp: deliveredAt,
      );

      _messageStatusController.add(status);

      // Complete delivery future if waiting
      final completer = _messageDeliveryCompleters.remove(messageId);
      completer?.complete(true);

      if (kDebugMode) {
        print('✅ Message delivered: $messageId to $deliveredTo');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling message delivered: $e');
      }
    }
  }

  void _handleMessageRead(WebSocketEvent event) {
    try {
      final messageId = event.data['message_id'] as String;
      final readBy = event.data['read_by'] as String;
      final readAt =
          DateTime.tryParse(event.data['read_at'] ?? '') ?? DateTime.now();

      // Track who read the message
      _messageReadBy.putIfAbsent(messageId, () => <String>{}).add(readBy);

      final status = MessageStatus(
        messageId: messageId,
        status: MessageStatusType.read,
        userId: readBy,
        timestamp: readAt,
      );

      _messageStatusController.add(status);

      if (kDebugMode) {
        print('👁️ Message read: $messageId by $readBy');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling message read: $e');
      }
    }
  }

  void _handleMessageDeleted(WebSocketEvent event) {
    try {
      final messageId = event.data['message_id'] as String;
      final chatId = event.data['chat_id'] as String;
      final deletedBy = event.data['deleted_by'] as String;
      final forEveryone = event.data['for_everyone'] as bool? ?? false;

      final update = ChatUpdate(
        type: ChatUpdateType.messageDeleted,
        chatId: chatId,
        data: {
          'message_id': messageId,
          'deleted_by': deletedBy,
          'for_everyone': forEveryone,
        },
      );

      _chatUpdateController.add(update);

      if (kDebugMode) {
        print('🗑️ Message deleted: $messageId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling message deleted: $e');
      }
    }
  }

  void _handleMessageEdited(WebSocketEvent event) {
    try {
      final messageId = event.data['message_id'] as String;
      final chatId = event.data['chat_id'] as String;
      final newContent = event.data['content'] as String;
      final editedAt =
          DateTime.tryParse(event.data['edited_at'] ?? '') ?? DateTime.now();

      final update = ChatUpdate(
        type: ChatUpdateType.messageEdited,
        chatId: chatId,
        data: {
          'message_id': messageId,
          'content': newContent,
          'edited_at': editedAt.toIso8601String(),
        },
      );

      _chatUpdateController.add(update);

      if (kDebugMode) {
        print('✏️ Message edited: $messageId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling message edited: $e');
      }
    }
  }

  void _handleMessageReaction(WebSocketEvent event) {
    try {
      final reaction = MessageReaction.fromJson(event.data);
      _reactionController.add(reaction);

      if (kDebugMode) {
        print(
          '${reaction.action == ReactionAction.add ? '👍' : '👎'} Reaction: ${reaction.emoji} on ${reaction.messageId}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling message reaction: $e');
      }
    }
  }

  // Typing indicators
  void _handleUserTyping(WebSocketEvent event) {
    try {
      final chatId = event.data['chat_id'] as String;
      final userId = event.data['user_id'] as String;
      final userName = event.data['user_name'] as String?;

      // Add user to typing list
      _typingUsers.putIfAbsent(chatId, () => <String>{}).add(userId);

      // Set timeout to remove typing indicator
      _typingTimers['${chatId}_$userId']?.cancel();
      _typingTimers['${chatId}_$userId'] = Timer(
        const Duration(seconds: 5),
        () {
          _removeTypingUser(chatId, userId);
        },
      );

      final typingStatus = TypingStatus(
        chatId: chatId,
        userId: userId,
        userName: userName,
        isTyping: true,
        typingUsers: Set.from(_typingUsers[chatId] ?? {}),
      );

      _typingController.add(typingStatus);

      if (kDebugMode) {
        print('⌨️ User typing: $userName in $chatId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling user typing: $e');
      }
    }
  }

  void _handleUserStoppedTyping(WebSocketEvent event) {
    try {
      final chatId = event.data['chat_id'] as String;
      final userId = event.data['user_id'] as String;
      final userName = event.data['user_name'] as String?;

      _removeTypingUser(chatId, userId);

      final typingStatus = TypingStatus(
        chatId: chatId,
        userId: userId,
        userName: userName,
        isTyping: false,
        typingUsers: Set.from(_typingUsers[chatId] ?? {}),
      );

      _typingController.add(typingStatus);

      if (kDebugMode) {
        print('⌨️ User stopped typing: $userName in $chatId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling user stopped typing: $e');
      }
    }
  }

  void _removeTypingUser(String chatId, String userId) {
    _typingUsers[chatId]?.remove(userId);
    _typingTimers.remove('${chatId}_$userId')?.cancel();

    if (_typingUsers[chatId]?.isEmpty == true) {
      _typingUsers.remove(chatId);
    }
  }

  void _clearAllTypingIndicators() {
    _typingUsers.clear();
    for (final timer in _typingTimers.values) {
      timer.cancel();
    }
    _typingTimers.clear();
  }

  // Chat management
  void _handleChatCreated(WebSocketEvent event) {
    try {
      final chatId = event.data['chat_id'] as String;

      final update = ChatUpdate(
        type: ChatUpdateType.chatCreated,
        chatId: chatId,
        data: event.data,
      );

      _chatUpdateController.add(update);

      if (kDebugMode) {
        print('💬 Chat created: $chatId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling chat created: $e');
      }
    }
  }

  void _handleChatDeleted(WebSocketEvent event) {
    try {
      final chatId = event.data['chat_id'] as String;

      // Unsubscribe from the deleted chat
      unsubscribeFromChat(chatId);

      final update = ChatUpdate(
        type: ChatUpdateType.chatDeleted,
        chatId: chatId,
        data: event.data,
      );

      _chatUpdateController.add(update);

      if (kDebugMode) {
        print('🗑️ Chat deleted: $chatId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling chat deleted: $e');
      }
    }
  }

  void _handleChatUpdated(WebSocketEvent event) {
    try {
      final chatId = event.data['chat_id'] as String;

      final update = ChatUpdate(
        type: ChatUpdateType.chatUpdated,
        chatId: chatId,
        data: event.data,
      );

      _chatUpdateController.add(update);

      if (kDebugMode) {
        print('📝 Chat updated: $chatId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling chat updated: $e');
      }
    }
  }

  void _handleParticipantAdded(WebSocketEvent event) {
    try {
      final chatId = event.data['chat_id'] as String;
      final userId = event.data['user_id'] as String;

      final update = ChatUpdate(
        type: ChatUpdateType.participantAdded,
        chatId: chatId,
        data: {
          'user_id': userId,
          'added_by': event.data['added_by'],
          'added_at': event.data['added_at'],
        },
      );

      _chatUpdateController.add(update);

      if (kDebugMode) {
        print('👥 Participant added: $userId to $chatId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling participant added: $e');
      }
    }
  }

  void _handleParticipantRemoved(WebSocketEvent event) {
    try {
      final chatId = event.data['chat_id'] as String;
      final userId = event.data['user_id'] as String;

      final update = ChatUpdate(
        type: ChatUpdateType.participantRemoved,
        chatId: chatId,
        data: {
          'user_id': userId,
          'removed_by': event.data['removed_by'],
          'removed_at': event.data['removed_at'],
        },
      );

      _chatUpdateController.add(update);

      if (kDebugMode) {
        print('👥 Participant removed: $userId from $chatId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling participant removed: $e');
      }
    }
  }

  // Public API methods

  // Chat subscription
  void subscribeToChat(String chatId) {
    if (!_subscribedChats.contains(chatId)) {
      _subscribedChats.add(chatId);
      _webSocketService.subscribeToChat(chatId);

      if (kDebugMode) {
        print('🔔 Subscribed to chat: $chatId');
      }
    }
  }

  void unsubscribeFromChat(String chatId) {
    if (_subscribedChats.contains(chatId)) {
      _subscribedChats.remove(chatId);
      _webSocketService.unsubscribeFromChat(chatId);

      // Clean up typing indicators for this chat
      _typingUsers.remove(chatId);
      final keysToRemove = _typingTimers.keys
          .where((key) => key.startsWith('${chatId}_'))
          .toList();
      for (final key in keysToRemove) {
        _typingTimers.remove(key)?.cancel();
      }

      if (kDebugMode) {
        print('🔕 Unsubscribed from chat: $chatId');
      }
    }
  }

  // Message sending
  Future<bool> sendMessage(Map<String, dynamic> messageData) async {
    try {
      final messageId = messageData['id'] as String;

      // Create a completer for delivery confirmation
      final completer = Completer<bool>();
      _messageDeliveryCompleters[messageId] = completer;

      // Send the message
      _webSocketService.sendMessage(messageData);

      // Wait for delivery confirmation with timeout
      return await completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          _messageDeliveryCompleters.remove(messageId);
          return false;
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error sending message: $e');
      }
      return false;
    }
  }

  void _sendMessageDelivered(String messageId, String chatId) {
    _webSocketService.markMessageAsRead(messageId, chatId);
  }

  // Typing indicators
  void startTyping(String chatId) {
    _webSocketService.sendTyping(chatId, true);
  }

  void stopTyping(String chatId) {
    _webSocketService.sendTyping(chatId, false);
  }

  // Message actions
  void markMessageAsRead(String messageId, String chatId) {
    _webSocketService.markMessageAsRead(messageId, chatId);
  }

  void addReaction(String messageId, String chatId, String emoji) {
    _webSocketService.sendReaction(messageId, chatId, emoji);
  }

  void removeReaction(String messageId, String chatId) {
    _webSocketService.removeReaction(messageId, chatId);
  }

  // Utility methods
  Set<String> getTypingUsers(String chatId) {
    return Set.from(_typingUsers[chatId] ?? {});
  }

  bool isUserTyping(String chatId, String userId) {
    return _typingUsers[chatId]?.contains(userId) ?? false;
  }

  Set<String> getMessageReadBy(String messageId) {
    return Set.from(_messageReadBy[messageId] ?? {});
  }

  bool isMessageReadBy(String messageId, String userId) {
    return _messageReadBy[messageId]?.contains(userId) ?? false;
  }

  List<String> getSubscribedChats() {
    return List.from(_subscribedChats);
  }

  // Filtered streams
  Stream<ChatMessage> getMessagesForChat(String chatId) {
    return messageReceived.where((message) => message.chatId == chatId);
  }

  Stream<MessageStatus> getStatusForMessage(String messageId) {
    return messageStatus.where((status) => status.messageId == messageId);
  }

  Stream<TypingStatus> getTypingForChat(String chatId) {
    return typingStatus.where((status) => status.chatId == chatId);
  }

  Stream<ChatUpdate> getUpdatesForChat(String chatId) {
    return chatUpdates.where((update) => update.chatId == chatId);
  }

  Stream<MessageReaction> getReactionsForMessage(String messageId) {
    return reactions.where((reaction) => reaction.messageId == messageId);
  }

  // Cleanup
  Future<void> dispose() async {
    // Clear typing timers
    for (final timer in _typingTimers.values) {
      timer.cancel();
    }
    _typingTimers.clear();

    // Clear data
    _subscribedChats.clear();
    _typingUsers.clear();
    _messageDeliveryCompleters.clear();
    _messageReadBy.clear();

    // Close streams
    await _messageReceivedController.close();
    await _messageStatusController.close();
    await _typingController.close();
    await _chatUpdateController.close();
    await _reactionController.close();

    if (kDebugMode) {
      print('✅ Chat socket service disposed');
    }
  }
}

// Data models
class ChatMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String? senderName;
  final String content;
  final String type;
  final DateTime createdAt;
  final DateTime? editedAt;
  final String? replyToId;
  final List<String> mentions;
  final Map<String, dynamic>? metadata;
  final bool isFromCurrentUser;

  ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.senderName,
    required this.content,
    required this.type,
    required this.createdAt,
    this.editedAt,
    this.replyToId,
    this.mentions = const [],
    this.metadata,
    this.isFromCurrentUser = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      chatId: json['chat_id'],
      senderId: json['sender_id'],
      senderName: json['sender_name'],
      content: json['content'] ?? '',
      type: json['type'] ?? 'text',
      createdAt: DateTime.parse(json['created_at']),
      editedAt: json['edited_at'] != null
          ? DateTime.parse(json['edited_at'])
          : null,
      replyToId: json['reply_to_id'],
      mentions: List<String>.from(json['mentions'] ?? []),
      metadata: json['metadata'],
      isFromCurrentUser: json['is_from_current_user'] ?? false,
    );
  }
}

enum MessageStatusType { sent, delivered, read, failed }

class MessageStatus {
  final String messageId;
  final MessageStatusType status;
  final String? userId;
  final DateTime timestamp;

  MessageStatus({
    required this.messageId,
    required this.status,
    this.userId,
    required this.timestamp,
  });
}

class TypingStatus {
  final String chatId;
  final String userId;
  final String? userName;
  final bool isTyping;
  final Set<String> typingUsers;

  TypingStatus({
    required this.chatId,
    required this.userId,
    this.userName,
    required this.isTyping,
    required this.typingUsers,
  });
}

enum ChatUpdateType {
  chatCreated,
  chatDeleted,
  chatUpdated,
  participantAdded,
  participantRemoved,
  messageDeleted,
  messageEdited,
}

class ChatUpdate {
  final ChatUpdateType type;
  final String chatId;
  final Map<String, dynamic> data;

  ChatUpdate({required this.type, required this.chatId, required this.data});
}

enum ReactionAction { add, remove }

class MessageReaction {
  final String messageId;
  final String chatId;
  final String userId;
  final String? userName;
  final String emoji;
  final ReactionAction action;
  final DateTime timestamp;

  MessageReaction({
    required this.messageId,
    required this.chatId,
    required this.userId,
    this.userName,
    required this.emoji,
    required this.action,
    required this.timestamp,
  });

  factory MessageReaction.fromJson(Map<String, dynamic> json) {
    return MessageReaction(
      messageId: json['message_id'],
      chatId: json['chat_id'],
      userId: json['user_id'],
      userName: json['user_name'],
      emoji: json['emoji'],
      action: json['action'] == 'add'
          ? ReactionAction.add
          : ReactionAction.remove,
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

// Riverpod providers
final chatSocketServiceProvider = Provider<ChatSocketService>((ref) {
  return ChatSocketService();
});

final chatMessagesProvider = StreamProvider.family<ChatMessage, String>((
  ref,
  chatId,
) {
  final service = ref.watch(chatSocketServiceProvider);
  return service.getMessagesForChat(chatId);
});

final chatTypingProvider = StreamProvider.family<TypingStatus, String>((
  ref,
  chatId,
) {
  final service = ref.watch(chatSocketServiceProvider);
  return service.getTypingForChat(chatId);
});

final chatUpdatesProvider = StreamProvider.family<ChatUpdate, String>((
  ref,
  chatId,
) {
  final service = ref.watch(chatSocketServiceProvider);
  return service.getUpdatesForChat(chatId);
});

final messageStatusProvider = StreamProvider.family<MessageStatus, String>((
  ref,
  messageId,
) {
  final service = ref.watch(chatSocketServiceProvider);
  return service.getStatusForMessage(messageId);
});

final messageReactionsProvider = StreamProvider.family<MessageReaction, String>(
  (ref, messageId) {
    final service = ref.watch(chatSocketServiceProvider);
    return service.getReactionsForMessage(messageId);
  },
);
