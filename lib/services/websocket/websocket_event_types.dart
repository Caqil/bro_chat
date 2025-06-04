import '../../models/chat/message_model.dart';

// Chat Message from WebSocket
class ChatMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String type;
  final String content;
  final DateTime createdAt;
  final String? replyToId;
  final List<String> mentions;
  final bool isFromCurrentUser;
  final String? mediaUrl;
  final Map<String, dynamic>? metadata;

  ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.type,
    required this.content,
    required this.createdAt,
    this.replyToId,
    this.mentions = const [],
    this.isFromCurrentUser = false,
    this.mediaUrl,
    this.metadata,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      chatId: json['chat_id'] ?? '',
      senderId: json['sender_id'] ?? '',
      type: json['type'] ?? 'text',
      content: json['content'] ?? '',
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      replyToId: json['reply_to_id'],
      mentions: List<String>.from(json['mentions'] ?? []),
      isFromCurrentUser: json['is_from_current_user'] ?? false,
      mediaUrl: json['media_url'],
      metadata: json['metadata'],
    );
  }
}

// Message Status Update from WebSocket
class MessageStatusUpdate {
  final String messageId;
  final MessageStatusType status;
  final String? userId;
  final DateTime timestamp;

  MessageStatusUpdate({
    required this.messageId,
    required this.status,
    this.userId,
    required this.timestamp,
  });

  factory MessageStatusUpdate.fromJson(Map<String, dynamic> json) {
    return MessageStatusUpdate(
      messageId: json['message_id'] ?? '',
      status: MessageStatusType.fromString(json['status']),
      userId: json['user_id'],
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

// Chat Update from WebSocket
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

  factory ChatUpdate.fromJson(Map<String, dynamic> json) {
    return ChatUpdate(
      type: _parseUpdateType(json['type']),
      chatId: json['chat_id'] ?? '',
      data: json['data'] ?? {},
    );
  }

  static ChatUpdateType _parseUpdateType(String? type) {
    switch (type) {
      case 'chat_created':
        return ChatUpdateType.chatCreated;
      case 'chat_deleted':
        return ChatUpdateType.chatDeleted;
      case 'chat_updated':
        return ChatUpdateType.chatUpdated;
      case 'participant_added':
        return ChatUpdateType.participantAdded;
      case 'participant_removed':
        return ChatUpdateType.participantRemoved;
      case 'message_deleted':
        return ChatUpdateType.messageDeleted;
      case 'message_edited':
        return ChatUpdateType.messageEdited;
      default:
        return ChatUpdateType.chatUpdated;
    }
  }
}

// Message Reaction Action
enum ReactionAction {
  add,
  remove;

  static ReactionAction fromString(String? value) {
    switch (value) {
      case 'add':
        return ReactionAction.add;
      case 'remove':
        return ReactionAction.remove;
      default:
        return ReactionAction.add;
    }
  }
}

// Extended Message Reaction for WebSocket
class MessageReactionEvent {
  final String messageId;
  final String userId;
  final String userName;
  final String emoji;
  final ReactionAction action;
  final DateTime timestamp;

  MessageReactionEvent({
    required this.messageId,
    required this.userId,
    required this.userName,
    required this.emoji,
    required this.action,
    required this.timestamp,
  });

  factory MessageReactionEvent.fromJson(Map<String, dynamic> json) {
    return MessageReactionEvent(
      messageId: json['message_id'] ?? '',
      userId: json['user_id'] ?? '',
      userName: json['user_name'] ?? '',
      emoji: json['emoji'] ?? '',
      action: ReactionAction.fromString(json['action']),
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

// Typing Status
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

  factory TypingStatus.fromJson(Map<String, dynamic> json) {
    return TypingStatus(
      chatId: json['chat_id'] ?? '',
      userId: json['user_id'] ?? '',
      userName: json['user_name'],
      isTyping: json['is_typing'] ?? false,
      typingUsers: Set<String>.from(json['typing_users'] ?? []),
    );
  }
}
