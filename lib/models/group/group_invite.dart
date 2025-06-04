
import 'group_settings.dart';

class GroupInvite {
  final String id;
  final String groupId;
  final String groupName;
  final String? groupAvatar;
  final String invitedBy;
  final String inviterName;
  final String? inviterAvatar;
  final String inviteCode;
  final String? message;
  final InviteStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final int maxUses;
  final int currentUses;
  final List<String> usedBy;

  GroupInvite({
    required this.id,
    required this.groupId,
    required this.groupName,
    this.groupAvatar,
    required this.invitedBy,
    required this.inviterName,
    this.inviterAvatar,
    required this.inviteCode,
    this.message,
    this.status = InviteStatus.pending,
    required this.createdAt,
    required this.expiresAt,
    this.maxUses = 100,
    this.currentUses = 0,
    this.usedBy = const [],
  });

  factory GroupInvite.fromJson(Map<String, dynamic> json) {
    return GroupInvite(
      id: json['id'] ?? json['_id'] ?? '',
      groupId: json['group_id'] ?? '',
      groupName: json['group_name'] ?? '',
      groupAvatar: json['group_avatar'],
      invitedBy: json['invited_by'] ?? '',
      inviterName: json['inviter_name'] ?? '',
      inviterAvatar: json['inviter_avatar'],
      inviteCode: json['invite_code'] ?? '',
      message: json['message'],
      status: InviteStatus.fromString(json['status']),
      createdAt: DateTime.parse(json['created_at']),
      expiresAt: DateTime.parse(json['expires_at']),
      maxUses: json['max_uses'] ?? 100,
      currentUses: json['current_uses'] ?? 0,
      usedBy: List<String>.from(json['used_by'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'group_name': groupName,
      if (groupAvatar != null) 'group_avatar': groupAvatar,
      'invited_by': invitedBy,
      'inviter_name': inviterName,
      if (inviterAvatar != null) 'inviter_avatar': inviterAvatar,
      'invite_code': inviteCode,
      if (message != null) 'message': message,
      'status': status.value,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'max_uses': maxUses,
      'current_uses': currentUses,
      'used_by': usedBy,
    };
  }

  // Utility getters
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isMaxUsesReached => currentUses >= maxUses;
  bool get isValid =>
      !isExpired && !isMaxUsesReached && status == InviteStatus.active;
  int get remainingUses => maxUses - currentUses;
  Duration get timeRemaining => expiresAt.difference(DateTime.now());
}

enum InviteStatus {
  pending,
  active,
  expired,
  revoked,
  used;

  String get value => name;

  static InviteStatus fromString(String? value) {
    switch (value) {
      case 'pending':
        return InviteStatus.pending;
      case 'active':
        return InviteStatus.active;
      case 'expired':
        return InviteStatus.expired;
      case 'revoked':
        return InviteStatus.revoked;
      case 'used':
        return InviteStatus.used;
      default:
        return InviteStatus.pending;
    }
  }
}

// Additional request/response models
class CreateGroupRequest {
  final String name;
  final String? description;
  final String? avatar;
  final bool isPublic;
  final List<String> members;
  final GroupSettings? settings;
  final List<String>? tags;

  CreateGroupRequest({
    required this.name,
    this.description,
    this.avatar,
    this.isPublic = false,
    this.members = const [],
    this.settings,
    this.tags,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (description != null) 'description': description,
      if (avatar != null) 'avatar': avatar,
      'is_public': isPublic,
      'members': members,
      if (settings != null) 'settings': settings!.toJson(),
      if (tags != null) 'tags': tags,
    };
  }
}

class JoinGroupRequest {
  final String? message;

  JoinGroupRequest({this.message});

  Map<String, dynamic> toJson() {
    return {if (message != null) 'message': message};
  }
}
