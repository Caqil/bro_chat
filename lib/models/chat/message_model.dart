class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String? senderName; // Add sender name for WebSocket events
  final MessageType type;
  final String content;
  final String? mediaUrl;
  final String? thumbnailUrl;
  final Map<String, dynamic>? metadata;
  final String? replyToId;
  final MessageModel? replyToMessage;
  final List<String> mentions;
  final List<MessageReaction> reactions;
  final MessageStatusType status;
  final bool isEdited;
  final bool isDeleted;
  final bool isForwarded;
  final String? forwardedFromChatId;
  final String? forwardedFromUserId;
  final DateTime? scheduledAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<MessageReadReceipt> readReceipts;
  final bool isFromCurrentUser; // Add for WebSocket compatibility

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.senderName,
    required this.type,
    required this.content,
    this.mediaUrl,
    this.thumbnailUrl,
    this.metadata,
    this.replyToId,
    this.replyToMessage,
    this.mentions = const [],
    this.reactions = const [],
    this.status = MessageStatusType.sent,
    this.isEdited = false,
    this.isDeleted = false,
    this.isForwarded = false,
    this.forwardedFromChatId,
    this.forwardedFromUserId,
    this.scheduledAt,
    required this.createdAt,
    required this.updatedAt,
    this.readReceipts = const [],
    this.isFromCurrentUser = false,
  });

  // Factory constructor for WebSocket events (replaces ChatMessage.fromJson)
  factory MessageModel.fromWebSocket(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] ?? '',
      chatId: json['chat_id'] ?? '',
      senderId: json['sender_id'] ?? '',
      senderName: json['sender_name'],
      type: MessageType.fromString(json['type']),
      content: json['content'] ?? '',
      mediaUrl: json['media_url'],
      metadata: json['metadata'],
      replyToId: json['reply_to_id'],
      mentions: List<String>.from(json['mentions'] ?? []),
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] ??
            json['created_at'] ??
            DateTime.now().toIso8601String(),
      ),
      isFromCurrentUser: json['is_from_current_user'] ?? false,
      status: MessageStatusType.fromString(json['status']),
    );
  }

  // Factory constructor for API responses (existing fromJson)
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] ?? json['_id'] ?? '',
      chatId: json['chat_id'] ?? '',
      senderId: json['sender_id'] ?? '',
      senderName: json['sender_name'],
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
      status: MessageStatusType.fromString(json['status']),
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
      isFromCurrentUser: json['is_from_current_user'] ?? false,
    );
  }

  // Add copyWith method
  MessageModel copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? senderName,
    MessageType? type,
    String? content,
    String? mediaUrl,
    String? thumbnailUrl,
    Map<String, dynamic>? metadata,
    String? replyToId,
    MessageModel? replyToMessage,
    List<String>? mentions,
    List<MessageReaction>? reactions,
    MessageStatusType? status,
    bool? isEdited,
    bool? isDeleted,
    bool? isForwarded,
    String? forwardedFromChatId,
    String? forwardedFromUserId,
    DateTime? scheduledAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<MessageReadReceipt>? readReceipts,
    bool? isFromCurrentUser,
  }) {
    return MessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      type: type ?? this.type,
      content: content ?? this.content,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      metadata: metadata ?? this.metadata,
      replyToId: replyToId ?? this.replyToId,
      replyToMessage: replyToMessage ?? this.replyToMessage,
      mentions: mentions ?? this.mentions,
      reactions: reactions ?? this.reactions,
      status: status ?? this.status,
      isEdited: isEdited ?? this.isEdited,
      isDeleted: isDeleted ?? this.isDeleted,
      isForwarded: isForwarded ?? this.isForwarded,
      forwardedFromChatId: forwardedFromChatId ?? this.forwardedFromChatId,
      forwardedFromUserId: forwardedFromUserId ?? this.forwardedFromUserId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      readReceipts: readReceipts ?? this.readReceipts,
      isFromCurrentUser: isFromCurrentUser ?? this.isFromCurrentUser,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_id': chatId,
      'sender_id': senderId,
      if (senderName != null) 'sender_name': senderName,
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
      'is_from_current_user': isFromCurrentUser,
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
  callEnded,
  messageReceived,
  messageRead,
  messageDelivered,
  messageDeleted,
  messageEdited,
  userTyping,
  userStoppedTyping,
  userOnline,
  userOffline,
  userLastSeen,
  chatCreated,
  chatDeleted,
  chatArchived,
  chatMuted,
  participantAdded,
  participantRemoved,
  groupUpdated,
  memberRoleChanged,
  callInitiated,
  callAnswered,
  callJoined,
  callLeft,
  callRinging,
  callBusy,
  fileUploaded,
  fileDeleted,
  systemMaintenance,
  systemBroadcast,
  tokenExpired,
  sessionTerminated,
  unknown;

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
      case MessageType.messageReceived:
        return 'message_received';
      case MessageType.messageRead:
        return 'message_read';
      case MessageType.messageDelivered:
        return 'message_delivered';
      case MessageType.messageDeleted:
        return 'message_deleted';
      case MessageType.messageEdited:
        return 'message_edited';
      case MessageType.userTyping:
        return 'user_typing';
      case MessageType.userStoppedTyping:
        return 'user_stopped_typing';
      case MessageType.userOnline:
        return 'user_online';
      case MessageType.userOffline:
        return 'user_offline';
      case MessageType.userLastSeen:
        return 'user_last_seen';
      case MessageType.chatCreated:
        return 'chat_created';
      case MessageType.chatDeleted:
        return 'chat_deleted';
      case MessageType.chatArchived:
        return 'chat_archived';
      case MessageType.chatMuted:
        return 'chat_muted';
      case MessageType.participantAdded:
        return 'participant_added';
      case MessageType.participantRemoved:
        return 'participant_removed';
      case MessageType.groupUpdated:
        return 'group_updated';
      case MessageType.memberRoleChanged:
        return 'member_role_changed';
      case MessageType.callInitiated:
        return 'call_initiated';
      case MessageType.callAnswered:
        return 'call_answered';
      case MessageType.callJoined:
        return 'call_joined';
      case MessageType.callLeft:
        return 'call_left';
      case MessageType.callRinging:
        return 'call_ringing';
      case MessageType.callBusy:
        return 'call_busy';
      case MessageType.fileUploaded:
        return 'file_uploaded';
      case MessageType.fileDeleted:
        return 'file_deleted';
      case MessageType.systemMaintenance:
        return 'system_maintenance';
      case MessageType.systemBroadcast:
        return 'system_broadcast';
      case MessageType.tokenExpired:
        return 'token_expired';
      case MessageType.sessionTerminated:
        return 'session_terminated';
      case MessageType.unknown:
        return 'unknown';
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
      case 'message_received':
        return MessageType.messageReceived;
      case 'message_read':
        return MessageType.messageRead;
      case 'message_delivered':
        return MessageType.messageDelivered;
      case 'message_deleted':
        return MessageType.messageDeleted;
      case 'message_edited':
        return MessageType.messageEdited;
      case 'user_typing':
        return MessageType.userTyping;
      case 'user_stopped_typing':
        return MessageType.userStoppedTyping;
      case 'user_online':
        return MessageType.userOnline;
      case 'user_offline':
        return MessageType.userOffline;
      case 'user_last_seen':
        return MessageType.userLastSeen;
      case 'chat_created':
        return MessageType.chatCreated;
      case 'chat_deleted':
        return MessageType.chatDeleted;
      case 'chat_archived':
        return MessageType.chatArchived;
      case 'chat_muted':
        return MessageType.chatMuted;
      case 'participant_added':
        return MessageType.participantAdded;
      case 'participant_removed':
        return MessageType.participantRemoved;
      case 'group_updated':
        return MessageType.groupUpdated;
      case 'member_role_changed':
        return MessageType.memberRoleChanged;
      case 'call_initiated':
        return MessageType.callInitiated;
      case 'call_answered':
        return MessageType.callAnswered;
      case 'call_joined':
        return MessageType.callJoined;
      case 'call_left':
        return MessageType.callLeft;
      case 'call_ringing':
        return MessageType.callRinging;
      case 'call_busy':
        return MessageType.callBusy;
      case 'file_uploaded':
        return MessageType.fileUploaded;
      case 'file_deleted':
        return MessageType.fileDeleted;
      case 'system_maintenance':
        return MessageType.systemMaintenance;
      case 'system_broadcast':
        return MessageType.systemBroadcast;
      case 'token_expired':
        return MessageType.tokenExpired;
      case 'session_terminated':
        return MessageType.sessionTerminated;
      case 'unknown':
        return MessageType.unknown;
      default:
        return MessageType.unknown;
    }
  }
}

enum MessageStatusType {
  sending,
  sent,
  delivered,
  read,
  failed;

  String get value => name;

  static MessageStatusType fromString(String? value) {
    switch (value) {
      case 'sending':
        return MessageStatusType.sending;
      case 'sent':
        return MessageStatusType.sent;
      case 'delivered':
        return MessageStatusType.delivered;
      case 'read':
        return MessageStatusType.read;
      case 'failed':
        return MessageStatusType.failed;
      default:
        return MessageStatusType.sent;
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
