class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final MessageType type;
  final String content;
  final String? mediaUrl;
  final String? thumbnailUrl;
  final Map<String, dynamic>? metadata;
  final String? replyToId;
  final MessageModel? replyToMessage;
  final List<String> mentions;
  final List<MessageReaction> reactions;
  final MessageStatus status;
  final bool isEdited;
  final bool isDeleted;
  final bool isForwarded;
  final String? forwardedFromChatId;
  final String? forwardedFromUserId;
  final DateTime? scheduledAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<MessageReadReceipt> readReceipts;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.type,
    required this.content,
    this.mediaUrl,
    this.thumbnailUrl,
    this.metadata,
    this.replyToId,
    this.replyToMessage,
    this.mentions = const [],
    this.reactions = const [],
    this.status = MessageStatus.sent,
    this.isEdited = false,
    this.isDeleted = false,
    this.isForwarded = false,
    this.forwardedFromChatId,
    this.forwardedFromUserId,
    this.scheduledAt,
    required this.createdAt,
    required this.updatedAt,
    this.readReceipts = const [],
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] ?? json['_id'] ?? '',
      chatId: json['chat_id'] ?? '',
      senderId: json['sender_id'] ?? '',
      type: MessageType.fromString(json['type']),
      content: json['content'] ?? '',
      mediaUrl: json['media_url'],
      thumbnailUrl: json['thumbnail_url'],
      metadata: json['metadata'],
      replyToId: json['reply_to_id'],
      replyToMessage: json['reply_to_message'] != null
          ? MessageModel.fromJson(json['reply_to_message'])
          : null,
      mentions: List<String>.from(json['mentions'] ?? []),
      reactions: (json['reactions'] as List? ?? [])
          .map((e) => MessageReaction.fromJson(e))
          .toList(),
      status: MessageStatus.fromString(json['status']),
      isEdited: json['is_edited'] ?? false,
      isDeleted: json['is_deleted'] ?? false,
      isForwarded: json['is_forwarded'] ?? false,
      forwardedFromChatId: json['forwarded_from_chat_id'],
      forwardedFromUserId: json['forwarded_from_user_id'],
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.parse(json['scheduled_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      readReceipts: (json['read_receipts'] as List? ?? [])
          .map((e) => MessageReadReceipt.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_id': chatId,
      'sender_id': senderId,
      'type': type.value,
      'content': content,
      if (mediaUrl != null) 'media_url': mediaUrl,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      if (metadata != null) 'metadata': metadata,
      if (replyToId != null) 'reply_to_id': replyToId,
      if (replyToMessage != null) 'reply_to_message': replyToMessage!.toJson(),
      'mentions': mentions,
      'reactions': reactions.map((e) => e.toJson()).toList(),
      'status': status.value,
      'is_edited': isEdited,
      'is_deleted': isDeleted,
      'is_forwarded': isForwarded,
      if (forwardedFromChatId != null)
        'forwarded_from_chat_id': forwardedFromChatId,
      if (forwardedFromUserId != null)
        'forwarded_from_user_id': forwardedFromUserId,
      if (scheduledAt != null) 'scheduled_at': scheduledAt!.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'read_receipts': readReceipts.map((e) => e.toJson()).toList(),
    };
  }

  bool get hasMedia => mediaUrl != null;
  bool get isReply => replyToId != null;
  bool get hasReactions => reactions.isNotEmpty;
  bool get isScheduled =>
      scheduledAt != null && DateTime.now().isBefore(scheduledAt!);
}

enum MessageType {
  text,
  image,
  video,
  audio,
  document,
  voiceNote,
  location,
  contact,
  sticker,
  gif,
  groupCreated,
  groupDeleted,
  memberAdded,
  memberRemoved,
  callStarted,
  callEnded;

  String get value {
    switch (this) {
      case MessageType.text:
        return 'text';
      case MessageType.image:
        return 'image';
      case MessageType.video:
        return 'video';
      case MessageType.audio:
        return 'audio';
      case MessageType.document:
        return 'document';
      case MessageType.voiceNote:
        return 'voice_note';
      case MessageType.location:
        return 'location';
      case MessageType.contact:
        return 'contact';
      case MessageType.sticker:
        return 'sticker';
      case MessageType.gif:
        return 'gif';
      case MessageType.groupCreated:
        return 'group_created';
      case MessageType.groupDeleted:
        return 'group_deleted';
      case MessageType.memberAdded:
        return 'member_added';
      case MessageType.memberRemoved:
        return 'member_removed';
      case MessageType.callStarted:
        return 'call_started';
      case MessageType.callEnded:
        return 'call_ended';
    }
  }

  static MessageType fromString(String? value) {
    switch (value) {
      case 'text':
        return MessageType.text;
      case 'image':
        return MessageType.image;
      case 'video':
        return MessageType.video;
      case 'audio':
        return MessageType.audio;
      case 'document':
        return MessageType.document;
      case 'voice_note':
        return MessageType.voiceNote;
      case 'location':
        return MessageType.location;
      case 'contact':
        return MessageType.contact;
      case 'sticker':
        return MessageType.sticker;
      case 'gif':
        return MessageType.gif;
      case 'group_created':
        return MessageType.groupCreated;
      case 'group_deleted':
        return MessageType.groupDeleted;
      case 'member_added':
        return MessageType.memberAdded;
      case 'member_removed':
        return MessageType.memberRemoved;
      case 'call_started':
        return MessageType.callStarted;
      case 'call_ended':
        return MessageType.callEnded;
      default:
        return MessageType.text;
    }
  }
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed;

  String get value => name;

  static MessageStatus fromString(String? value) {
    switch (value) {
      case 'sending':
        return MessageStatus.sending;
      case 'sent':
        return MessageStatus.sent;
      case 'delivered':
        return MessageStatus.delivered;
      case 'read':
        return MessageStatus.read;
      case 'failed':
        return MessageStatus.failed;
      default:
        return MessageStatus.sent;
    }
  }
}

class MessageReaction {
  final String emoji;
  final String userId;
  final String userName;
  final DateTime createdAt;

  MessageReaction({
    required this.emoji,
    required this.userId,
    required this.userName,
    required this.createdAt,
  });

  factory MessageReaction.fromJson(Map<String, dynamic> json) {
    return MessageReaction(
      emoji: json['emoji'] ?? '',
      userId: json['user_id'] ?? '',
      userName: json['user_name'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'emoji': emoji,
      'user_id': userId,
      'user_name': userName,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class MessageReadReceipt {
  final String userId;
  final String userName;
  final DateTime readAt;

  MessageReadReceipt({
    required this.userId,
    required this.userName,
    required this.readAt,
  });

  factory MessageReadReceipt.fromJson(Map<String, dynamic> json) {
    return MessageReadReceipt(
      userId: json['user_id'] ?? '',
      userName: json['user_name'] ?? '',
      readAt: DateTime.parse(json['read_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'user_name': userName,
      'read_at': readAt.toIso8601String(),
    };
  }
}
