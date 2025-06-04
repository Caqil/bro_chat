import 'group_member.dart';
import 'group_settings.dart';

class GroupModel {
  final String id;
  final String name;
  final String? description;
  final String? avatar;
  final bool isPublic;
  final int maxMembers;
  final int memberCount;
  final String ownerId;
  final List<GroupMember> members;
  final GroupSettings settings;
  final GroupPermissions permissions;
  final List<String> tags;
  final String? inviteCode;
  final DateTime? inviteCodeExpiresAt;
  final GroupStats? stats;
  final DateTime createdAt;
  final DateTime updatedAt;

  GroupModel({
    required this.id,
    required this.name,
    this.description,
    this.avatar,
    this.isPublic = false,
    this.maxMembers = 256,
    this.memberCount = 0,
    required this.ownerId,
    this.members = const [],
    required this.settings,
    required this.permissions,
    this.tags = const [],
    this.inviteCode,
    this.inviteCodeExpiresAt,
    this.stats,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      avatar: json['avatar'],
      isPublic: json['is_public'] ?? false,
      maxMembers: json['max_members'] ?? 256,
      memberCount: json['member_count'] ?? 0,
      ownerId: json['owner_id'] ?? '',
      members: (json['members'] as List? ?? [])
          .map((e) => GroupMember.fromJson(e))
          .toList(),
      settings: GroupSettings.fromJson(json['settings'] ?? {}),
      permissions: GroupPermissions.fromJson(json['permissions'] ?? {}),
      tags: List<String>.from(json['tags'] ?? []),
      inviteCode: json['invite_code'],
      inviteCodeExpiresAt: json['invite_code_expires_at'] != null
          ? DateTime.parse(json['invite_code_expires_at'])
          : null,
      stats: json['stats'] != null ? GroupStats.fromJson(json['stats']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      if (avatar != null) 'avatar': avatar,
      'is_public': isPublic,
      'max_members': maxMembers,
      'member_count': memberCount,
      'owner_id': ownerId,
      'members': members.map((e) => e.toJson()).toList(),
      'settings': settings.toJson(),
      'permissions': permissions.toJson(),
      'tags': tags,
      if (inviteCode != null) 'invite_code': inviteCode,
      if (inviteCodeExpiresAt != null)
        'invite_code_expires_at': inviteCodeExpiresAt!.toIso8601String(),
      if (stats != null) 'stats': stats!.toJson(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Utility getters
  bool get isFull => memberCount >= maxMembers;
  bool get hasInviteCode => inviteCode != null;
  bool get isInviteCodeExpired =>
      inviteCodeExpiresAt != null &&
      DateTime.now().isAfter(inviteCodeExpiresAt!);

  GroupMember? getMember(String userId) {
    try {
      return members.firstWhere((member) => member.userId == userId);
    } catch (e) {
      return null;
    }
  }

  bool isMember(String userId) => getMember(userId) != null;
  bool isOwner(String userId) => ownerId == userId;
  bool isAdmin(String userId) {
    final member = getMember(userId);
    return member?.role == GroupRole.admin || isOwner(userId);
  }

  List<GroupMember> get admins =>
      members.where((m) => m.role == GroupRole.admin).toList();
  List<GroupMember> get regularMembers =>
      members.where((m) => m.role == GroupRole.member).toList();
}

class GroupStats {
  final int totalMessages;
  final int totalMedia;
  final int totalFiles;
  final int activeMembersToday;
  final int activeMembersWeek;
  final DateTime? lastActivity;

  GroupStats({
    this.totalMessages = 0,
    this.totalMedia = 0,
    this.totalFiles = 0,
    this.activeMembersToday = 0,
    this.activeMembersWeek = 0,
    this.lastActivity,
  });

  factory GroupStats.fromJson(Map<String, dynamic> json) {
    return GroupStats(
      totalMessages: json['total_messages'] ?? 0,
      totalMedia: json['total_media'] ?? 0,
      totalFiles: json['total_files'] ?? 0,
      activeMembersToday: json['active_members_today'] ?? 0,
      activeMembersWeek: json['active_members_week'] ?? 0,
      lastActivity: json['last_activity'] != null
          ? DateTime.parse(json['last_activity'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_messages': totalMessages,
      'total_media': totalMedia,
      'total_files': totalFiles,
      'active_members_today': activeMembersToday,
      'active_members_week': activeMembersWeek,
      if (lastActivity != null)
        'last_activity': lastActivity!.toIso8601String(),
    };
  }
}
