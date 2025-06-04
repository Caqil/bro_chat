class ParticipantModel {
  final String userId;
  final String name;
  final String? avatar;
  final ParticipantRole role;
  final bool isOnline;
  final DateTime? lastSeen;
  final DateTime joinedAt;
  final bool isMuted;
  final DateTime? mutedUntil;
  final String? mutedBy;

  ParticipantModel({
    required this.userId,
    required this.name,
    this.avatar,
    this.role = ParticipantRole.member,
    this.isOnline = false,
    this.lastSeen,
    required this.joinedAt,
    this.isMuted = false,
    this.mutedUntil,
    this.mutedBy,
  });

  factory ParticipantModel.fromJson(Map<String, dynamic> json) {
    return ParticipantModel(
      userId: json['user_id'] ?? '',
      name: json['name'] ?? '',
      avatar: json['avatar'],
      role: ParticipantRole.fromString(json['role']),
      isOnline: json['is_online'] ?? false,
      lastSeen: json['last_seen'] != null
          ? DateTime.parse(json['last_seen'])
          : null,
      joinedAt: DateTime.parse(json['joined_at']),
      isMuted: json['is_muted'] ?? false,
      mutedUntil: json['muted_until'] != null
          ? DateTime.parse(json['muted_until'])
          : null,
      mutedBy: json['muted_by'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      if (avatar != null) 'avatar': avatar,
      'role': role.value,
      'is_online': isOnline,
      if (lastSeen != null) 'last_seen': lastSeen!.toIso8601String(),
      'joined_at': joinedAt.toIso8601String(),
      'is_muted': isMuted,
      if (mutedUntil != null) 'muted_until': mutedUntil!.toIso8601String(),
      if (mutedBy != null) 'muted_by': mutedBy,
    };
  }
}

enum ParticipantRole {
  member,
  admin,
  owner;

  String get value => name;

  static ParticipantRole fromString(String? value) {
    switch (value) {
      case 'member':
        return ParticipantRole.member;
      case 'admin':
        return ParticipantRole.admin;
      case 'owner':
        return ParticipantRole.owner;
      default:
        return ParticipantRole.member;
    }
  }
}
