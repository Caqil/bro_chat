import 'chat_settings.dart';
import 'message_model.dart';
import 'participant_model.dart';

class ChatModel {
  final String id;
  final String name;
  final String? description;
  final ChatType type;
  final String? avatar;
  final List<ParticipantModel> participants;
  final MessageModel? lastMessage;
  final int unreadCount;
  final bool isArchived;
  final bool isMuted;
  final bool isPinned;
  final DateTime? mutedUntil;
  final ChatSettings settings;
  final String? draftMessage;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatModel({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    this.avatar,
    required this.participants,
    this.lastMessage,
    this.unreadCount = 0,
    this.isArchived = false,
    this.isMuted = false,
    this.isPinned = false,
    this.mutedUntil,
    required this.settings,
    this.draftMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  // Add copyWith method
  ChatModel copyWith({
    String? id,
    String? name,
    String? description,
    ChatType? type,
    String? avatar,
    List<ParticipantModel>? participants,
    MessageModel? lastMessage,
    int? unreadCount,
    bool? isArchived,
    bool? isMuted,
    bool? isPinned,
    DateTime? mutedUntil,
    ChatSettings? settings,
    String? draftMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      avatar: avatar ?? this.avatar,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      isArchived: isArchived ?? this.isArchived,
      isMuted: isMuted ?? this.isMuted,
      isPinned: isPinned ?? this.isPinned,
      mutedUntil: mutedUntil ?? this.mutedUntil,
      settings: settings ?? this.settings,
      draftMessage: draftMessage ?? this.draftMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      type: ChatType.fromString(json['type']),
      avatar: json['avatar'],
      participants: (json['participants'] as List? ?? [])
          .map((e) => ParticipantModel.fromJson(e))
          .toList(),
      lastMessage: json['last_message'] != null
          ? MessageModel.fromJson(json['last_message'])
          : null,
      unreadCount: json['unread_count'] ?? 0,
      isArchived: json['is_archived'] ?? false,
      isMuted: json['is_muted'] ?? false,
      isPinned: json['is_pinned'] ?? false,
      mutedUntil: json['muted_until'] != null
          ? DateTime.parse(json['muted_until'])
          : null,
      settings: ChatSettings.fromJson(json['settings'] ?? {}),
      draftMessage: json['draft_message'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      'type': type.value,
      if (avatar != null) 'avatar': avatar,
      'participants': participants.map((e) => e.toJson()).toList(),
      if (lastMessage != null) 'last_message': lastMessage!.toJson(),
      'unread_count': unreadCount,
      'is_archived': isArchived,
      'is_muted': isMuted,
      'is_pinned': isPinned,
      if (mutedUntil != null) 'muted_until': mutedUntil!.toIso8601String(),
      'settings': settings.toJson(),
      if (draftMessage != null) 'draft_message': draftMessage,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isGroup => type == ChatType.group;
  bool get isPrivate => type == ChatType.private;
  bool get hasUnreadMessages => unreadCount > 0;
}

enum ChatType {
  private,
  group,
  broadcast,
  bot,
  support;

  String get value => name;

  static ChatType fromString(String? value) {
    switch (value) {
      case 'private':
        return ChatType.private;
      case 'group':
        return ChatType.group;
      case 'broadcast':
        return ChatType.broadcast;
      case 'bot':
        return ChatType.bot;
      case 'support':
        return ChatType.support;
      default:
        return ChatType.private;
    }
  }
}
