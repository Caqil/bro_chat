class UserModel {
  final String id;
  final String name;
  final String phoneNumber;
  final String countryCode;
  final String? email;
  final String? username;
  final String? avatar;
  final String? bio;
  final UserStatus status;
  final UserRole role;
  final bool isVerified;
  final bool isOnline;
  final DateTime? lastSeen;
  final UserPrivacySettings? privacySettings;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.countryCode,
    this.email,
    this.username,
    this.avatar,
    this.bio,
    this.status = UserStatus.active,
    this.role = UserRole.user,
    this.isVerified = false,
    this.isOnline = false,
    this.lastSeen,
    this.privacySettings,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      countryCode: json['country_code'] ?? '',
      email: json['email'],
      username: json['username'],
      avatar: json['avatar'],
      bio: json['bio'],
      status: UserStatus.fromString(json['status']),
      role: UserRole.fromString(json['role']),
      isVerified: json['is_verified'] ?? false,
      isOnline: json['is_online'] ?? false,
      lastSeen: json['last_seen'] != null 
          ? DateTime.parse(json['last_seen']) 
          : null,
      privacySettings: json['privacy_settings'] != null
          ? UserPrivacySettings.fromJson(json['privacy_settings'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone_number': phoneNumber,
      'country_code': countryCode,
      if (email != null) 'email': email,
      if (username != null) 'username': username,
      if (avatar != null) 'avatar': avatar,
      if (bio != null) 'bio': bio,
      'status': status.value,
      'role': role.value,
      'is_verified': isVerified,
      'is_online': isOnline,
      if (lastSeen != null) 'last_seen': lastSeen!.toIso8601String(),
      if (privacySettings != null) 'privacy_settings': privacySettings!.toJson(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? username,
    String? avatar,
    String? bio,
    UserStatus? status,
    bool? isOnline,
    DateTime? lastSeen,
    UserPrivacySettings? privacySettings,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      phoneNumber: phoneNumber,
      countryCode: countryCode,
      email: email ?? this.email,
      username: username ?? this.username,
      avatar: avatar ?? this.avatar,
      bio: bio ?? this.bio,
      status: status ?? this.status,
      role: role,
      isVerified: isVerified,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      privacySettings: privacySettings ?? this.privacySettings,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

enum UserStatus {
  active,
  inactive,
  banned,
  suspended;

  String get value => name;

  static UserStatus fromString(String? value) {
    switch (value) {
      case 'active':
        return UserStatus.active;
      case 'inactive':
        return UserStatus.inactive;
      case 'banned':
        return UserStatus.banned;
      case 'suspended':
        return UserStatus.suspended;
      default:
        return UserStatus.active;
    }
  }
}

enum UserRole {
  user,
  moderator,
  admin;

  String get value => name;

  static UserRole fromString(String? value) {
    switch (value) {
      case 'user':
        return UserRole.user;
      case 'moderator':
        return UserRole.moderator;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.user;
    }
  }
}

class UserPrivacySettings {
  final String lastSeen;
  final String profilePhoto;
  final String about;
  final String status;
  final String groups;
  final bool readReceipts;

  UserPrivacySettings({
    this.lastSeen = 'contacts',
    this.profilePhoto = 'contacts',
    this.about = 'contacts',
    this.status = 'contacts',
    this.groups = 'contacts',
    this.readReceipts = true,
  });

  factory UserPrivacySettings.fromJson(Map<String, dynamic> json) {
    return UserPrivacySettings(
      lastSeen: json['last_seen'] ?? 'contacts',
      profilePhoto: json['profile_photo'] ?? 'contacts',
      about: json['about'] ?? 'contacts',
      status: json['status'] ?? 'contacts',
      groups: json['groups'] ?? 'contacts',
      readReceipts: json['read_receipts'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'last_seen': lastSeen,
      'profile_photo': profilePhoto,
      'about': about,
      'status': status,
      'groups': groups,
      'read_receipts': readReceipts,
    };
  }
}