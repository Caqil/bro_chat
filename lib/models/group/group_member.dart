class GroupMember {
  final String userId;
  final String name;
  final String? avatar;
  final GroupRole role;
  final GroupMemberStatus status;
  final DateTime joinedAt;
  final DateTime? leftAt;
  final String? invitedBy;
  final bool isMuted;
  final DateTime? mutedUntil;
  final String? mutedBy;
  final bool isBanned;
  final DateTime? bannedUntil;
  final String? bannedBy;
  final String? banReason;
  final int warningCount;
  final DateTime? lastSeen;
  final DateTime? lastActivity;

  GroupMember({
    required this.userId,
    required this.name,
    this.avatar,
    this.role = GroupRole.member,
    this.status = GroupMemberStatus.active,
    required this.joinedAt,
    this.leftAt,
    this.invitedBy,
    this.isMuted = false,
    this.mutedUntil,
    this.mutedBy,
    this.isBanned = false,
    this.bannedUntil,
    this.bannedBy,
    this.banReason,
    this.warningCount = 0,
    this.lastSeen,
    this.lastActivity,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      userId: json['user_id'] ?? '',
      name: json['name'] ?? '',
      avatar: json['avatar'],
      role: GroupRole.fromString(json['role']),
      status: GroupMemberStatus.fromString(json['status']),
      joinedAt: DateTime.parse(json['joined_at']),
      leftAt: json['left_at'] != null ? DateTime.parse(json['left_at']) : null,
      invitedBy: json['invited_by'],
      isMuted: json['is_muted'] ?? false,
      mutedUntil: json['muted_until'] != null
          ? DateTime.parse(json['muted_until'])
          : null,
      mutedBy: json['muted_by'],
      isBanned: json['is_banned'] ?? false,
      bannedUntil: json['banned_until'] != null
          ? DateTime.parse(json['banned_until'])
          : null,
      bannedBy: json['banned_by'],
      banReason: json['ban_reason'],
      warningCount: json['warning_count'] ?? 0,
      lastSeen: json['last_seen'] != null
          ? DateTime.parse(json['last_seen'])
          : null,
      lastActivity: json['last_activity'] != null
          ? DateTime.parse(json['last_activity'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      if (avatar != null) 'avatar': avatar,
      'role': role.value,
      'status': status.value,
      'joined_at': joinedAt.toIso8601String(),
      if (leftAt != null) 'left_at': leftAt!.toIso8601String(),
      if (invitedBy != null) 'invited_by': invitedBy,
      'is_muted': isMuted,
      if (mutedUntil != null) 'muted_until': mutedUntil!.toIso8601String(),
      if (mutedBy != null) 'muted_by': mutedBy,
      'is_banned': isBanned,
      if (bannedUntil != null) 'banned_until': bannedUntil!.toIso8601String(),
      if (bannedBy != null) 'banned_by': bannedBy,
      if (banReason != null) 'ban_reason': banReason,
      'warning_count': warningCount,
      if (lastSeen != null) 'last_seen': lastSeen!.toIso8601String(),
      if (lastActivity != null)
        'last_activity': lastActivity!.toIso8601String(),
    };
  }

  // Utility getters
  bool get isOwner => role == GroupRole.owner;
  bool get isAdmin => role == GroupRole.admin;
  bool get isModerator => role == GroupRole.moderator;
  bool get canModerate => isOwner || isAdmin || isModerator;
  bool get isTemporarilyMuted =>
      isMuted && mutedUntil != null && DateTime.now().isBefore(mutedUntil!);
  bool get isTemporarilyBanned =>
      isBanned && bannedUntil != null && DateTime.now().isBefore(bannedUntil!);
}

enum GroupRole {
  owner,
  admin,
  moderator,
  member;

  String get value => name;

  static GroupRole fromString(String? value) {
    switch (value) {
      case 'owner':
        return GroupRole.owner;
      case 'admin':
        return GroupRole.admin;
      case 'moderator':
        return GroupRole.moderator;
      case 'member':
        return GroupRole.member;
      default:
        return GroupRole.member;
    }
  }
}

enum GroupMemberStatus {
  active,
  left,
  kicked,
  muted,
  banned;

  String get value => name;

  static GroupMemberStatus fromString(String? value) {
    switch (value) {
      case 'active':
        return GroupMemberStatus.active;
      case 'left':
        return GroupMemberStatus.left;
      case 'kicked':
        return GroupMemberStatus.kicked;
      case 'muted':
        return GroupMemberStatus.muted;
      case 'banned':
        return GroupMemberStatus.banned;
      default:
        return GroupMemberStatus.active;
    }
  }
}
