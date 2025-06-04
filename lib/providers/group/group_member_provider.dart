import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../../services/api/api_service.dart';
import '../../services/storage/cache_service.dart';
import '../../services/websocket/websocket_event_types.dart';
import '../../services/websocket/chat_socket.dart';

enum MemberRole { owner, admin, moderator, member, guest }

enum MemberStatus { active, muted, banned, suspended, left, removed, pending }

enum MemberPermission {
  canSendMessages,
  canSendMedia,
  canAddMembers,
  canRemoveMembers,
  canChangeGroupInfo,
  canDeleteMessages,
  canPinMessages,
  canManageRoles,
  canManageBans,
  canViewMemberList,
  canStartCalls,
  canShareScreen,
}

class GroupMemberInfo {
  final String userId;
  final String groupId;
  final String name;
  final String? username;
  final String? avatar;
  final String? email;
  final String? phone;
  final MemberRole role;
  final MemberStatus status;
  final Set<MemberPermission> permissions;
  final DateTime joinedAt;
  final DateTime? lastActiveAt;
  final DateTime? mutedUntil;
  final DateTime? bannedUntil;
  final String? mutedBy;
  final String? bannedBy;
  final String? muteReason;
  final String? banReason;
  final bool isOnline;
  final String? customTitle;
  final Map<String, dynamic>? metadata;

  GroupMemberInfo({
    required this.userId,
    required this.groupId,
    required this.name,
    this.username,
    this.avatar,
    this.email,
    this.phone,
    this.role = MemberRole.member,
    this.status = MemberStatus.active,
    this.permissions = const {},
    DateTime? joinedAt,
    this.lastActiveAt,
    this.mutedUntil,
    this.bannedUntil,
    this.mutedBy,
    this.bannedBy,
    this.muteReason,
    this.banReason,
    this.isOnline = false,
    this.customTitle,
    this.metadata,
  }) : joinedAt = joinedAt ?? DateTime.now();

  GroupMemberInfo copyWith({
    String? userId,
    String? groupId,
    String? name,
    String? username,
    String? avatar,
    String? email,
    String? phone,
    MemberRole? role,
    MemberStatus? status,
    Set<MemberPermission>? permissions,
    DateTime? joinedAt,
    DateTime? lastActiveAt,
    DateTime? mutedUntil,
    DateTime? bannedUntil,
    String? mutedBy,
    String? bannedBy,
    String? muteReason,
    String? banReason,
    bool? isOnline,
    String? customTitle,
    Map<String, dynamic>? metadata,
  }) {
    return GroupMemberInfo(
      userId: userId ?? this.userId,
      groupId: groupId ?? this.groupId,
      name: name ?? this.name,
      username: username ?? this.username,
      avatar: avatar ?? this.avatar,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      status: status ?? this.status,
      permissions: permissions ?? this.permissions,
      joinedAt: joinedAt ?? this.joinedAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      mutedUntil: mutedUntil ?? this.mutedUntil,
      bannedUntil: bannedUntil ?? this.bannedUntil,
      mutedBy: mutedBy ?? this.mutedBy,
      bannedBy: bannedBy ?? this.bannedBy,
      muteReason: muteReason ?? this.muteReason,
      banReason: banReason ?? this.banReason,
      isOnline: isOnline ?? this.isOnline,
      customTitle: customTitle ?? this.customTitle,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isOwner => role == MemberRole.owner;
  bool get isAdmin => role == MemberRole.admin || isOwner;
  bool get isModerator => role == MemberRole.moderator || isAdmin;
  bool get canManageMembers => isAdmin;
  bool get canManageGroup => isOwner;
  bool get isMuted =>
      status == MemberStatus.muted ||
      (mutedUntil != null && DateTime.now().isBefore(mutedUntil!));
  bool get isBanned =>
      status == MemberStatus.banned ||
      (bannedUntil != null && DateTime.now().isBefore(bannedUntil!));
  bool get isActive => status == MemberStatus.active && !isMuted && !isBanned;

  bool hasPermission(MemberPermission permission) {
    if (isOwner) return true; // Owner has all permissions
    return permissions.contains(permission);
  }

  String get displayName => customTitle != null ? '$name ($customTitle)' : name;
  String get roleDisplayName {
    switch (role) {
      case MemberRole.owner:
        return 'Owner';
      case MemberRole.admin:
        return 'Admin';
      case MemberRole.moderator:
        return 'Moderator';
      case MemberRole.member:
        return 'Member';
      case MemberRole.guest:
        return 'Guest';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'group_id': groupId,
      'name': name,
      'username': username,
      'avatar': avatar,
      'email': email,
      'phone': phone,
      'role': role.name,
      'status': status.name,
      'permissions': permissions.map((p) => p.name).toList(),
      'joined_at': joinedAt.toIso8601String(),
      'last_active_at': lastActiveAt?.toIso8601String(),
      'muted_until': mutedUntil?.toIso8601String(),
      'banned_until': bannedUntil?.toIso8601String(),
      'muted_by': mutedBy,
      'banned_by': bannedBy,
      'mute_reason': muteReason,
      'ban_reason': banReason,
      'is_online': isOnline,
      'custom_title': customTitle,
      'metadata': metadata,
    };
  }

  factory GroupMemberInfo.fromJson(Map<String, dynamic> json) {
    final permissionsList = json['permissions'] as List<dynamic>? ?? [];
    final permissions = <MemberPermission>{};

    for (final permissionName in permissionsList) {
      try {
        final permission = MemberPermission.values.firstWhere(
          (p) => p.name == permissionName,
        );
        permissions.add(permission);
      } catch (e) {
        // Ignore unknown permissions
      }
    }

    return GroupMemberInfo(
      userId: json['user_id'] ?? '',
      groupId: json['group_id'] ?? '',
      name: json['name'] ?? '',
      username: json['username'],
      avatar: json['avatar'],
      email: json['email'],
      phone: json['phone'],
      role: MemberRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => MemberRole.member,
      ),
      status: MemberStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => MemberStatus.active,
      ),
      permissions: permissions,
      joinedAt: DateTime.tryParse(json['joined_at'] ?? '') ?? DateTime.now(),
      lastActiveAt: json['last_active_at'] != null
          ? DateTime.tryParse(json['last_active_at'])
          : null,
      mutedUntil: json['muted_until'] != null
          ? DateTime.tryParse(json['muted_until'])
          : null,
      bannedUntil: json['banned_until'] != null
          ? DateTime.tryParse(json['banned_until'])
          : null,
      mutedBy: json['muted_by'],
      bannedBy: json['banned_by'],
      muteReason: json['mute_reason'],
      banReason: json['ban_reason'],
      isOnline: json['is_online'] ?? false,
      customTitle: json['custom_title'],
      metadata: json['metadata'],
    );
  }
}

class GroupMemberState {
  final String groupId;
  final Map<String, GroupMemberInfo> members;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final bool isInitialized;
  final DateTime? lastFetchTime;
  final String searchQuery;
  final MemberRole? roleFilter;
  final MemberStatus? statusFilter;
  final int page;

  GroupMemberState({
    required this.groupId,
    this.members = const {},
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.isInitialized = false,
    this.lastFetchTime,
    this.searchQuery = '',
    this.roleFilter,
    this.statusFilter,
    this.page = 1,
  });

  GroupMemberState copyWith({
    String? groupId,
    Map<String, GroupMemberInfo>? members,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    bool? isInitialized,
    DateTime? lastFetchTime,
    String? searchQuery,
    MemberRole? roleFilter,
    MemberStatus? statusFilter,
    int? page,
  }) {
    return GroupMemberState(
      groupId: groupId ?? this.groupId,
      members: members ?? this.members,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      isInitialized: isInitialized ?? this.isInitialized,
      lastFetchTime: lastFetchTime ?? this.lastFetchTime,
      searchQuery: searchQuery ?? this.searchQuery,
      roleFilter: roleFilter ?? this.roleFilter,
      statusFilter: statusFilter ?? this.statusFilter,
      page: page ?? this.page,
    );
  }

  GroupMemberInfo? getMember(String userId) => members[userId];

  List<GroupMemberInfo> get memberList => members.values.toList();

  List<GroupMemberInfo> get filteredMembers {
    var filtered = memberList;

    // Apply search filter
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((member) {
        return member.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
            (member.username?.toLowerCase().contains(
                  searchQuery.toLowerCase(),
                ) ??
                false) ||
            (member.customTitle?.toLowerCase().contains(
                  searchQuery.toLowerCase(),
                ) ??
                false);
      }).toList();
    }

    // Apply role filter
    if (roleFilter != null) {
      filtered = filtered.where((member) => member.role == roleFilter).toList();
    }

    // Apply status filter
    if (statusFilter != null) {
      filtered = filtered
          .where((member) => member.status == statusFilter)
          .toList();
    }

    // Sort by role priority, then by name
    filtered.sort((a, b) {
      final roleComparison = a.role.index.compareTo(b.role.index);
      if (roleComparison != 0) return roleComparison;
      return a.name.compareTo(b.name);
    });

    return filtered;
  }

  List<GroupMemberInfo> get owners =>
      memberList.where((m) => m.isOwner).toList();
  List<GroupMemberInfo> get admins =>
      memberList.where((m) => m.isAdmin).toList();
  List<GroupMemberInfo> get moderators =>
      memberList.where((m) => m.isModerator).toList();
  List<GroupMemberInfo> get activeMembers =>
      memberList.where((m) => m.isActive).toList();
  List<GroupMemberInfo> get onlineMembers =>
      memberList.where((m) => m.isOnline).toList();
  List<GroupMemberInfo> get mutedMembers =>
      memberList.where((m) => m.isMuted).toList();
  List<GroupMemberInfo> get bannedMembers =>
      memberList.where((m) => m.isBanned).toList();

  int get totalMembers => members.length;
  int get onlineCount => onlineMembers.length;
  int get adminCount => admins.length;
  int get mutedCount => mutedMembers.length;
  int get bannedCount => bannedMembers.length;
}

class GroupMemberNotifier extends StateNotifier<AsyncValue<GroupMemberState>> {
  final String groupId;
  final ApiService _apiService;
  final CacheService _cacheService;
  final ChatSocketService _chatSocketService;

  StreamSubscription<ChatUpdate>? _groupUpdateSubscription;
  Timer? _onlineStatusTimer;
  Timer? _searchDebounceTimer;

  static const int _membersPerPage = 50;
  static const Duration _onlineStatusInterval = Duration(minutes: 2);
  static const Duration _searchDebounceDelay = Duration(milliseconds: 500);

  GroupMemberNotifier({
    required this.groupId,
    required ApiService apiService,
    required CacheService cacheService,
    required ChatSocketService chatSocketService,
  }) : _apiService = apiService,
       _cacheService = cacheService,
       _chatSocketService = chatSocketService,
       super(AsyncValue.data(GroupMemberState(groupId: groupId))) {
    _initialize();
  }

  void _initialize() async {
    state = AsyncValue.data(state.value!.copyWith(isLoading: true));

    try {
      _setupSubscriptions();
      await _loadMembers();
      _startOnlineStatusUpdates();

      state = AsyncValue.data(
        state.value!.copyWith(
          isLoading: false,
          isInitialized: true,
          lastFetchTime: DateTime.now(),
        ),
      );

      if (kDebugMode)
        print('✅ Group member provider initialized for group: $groupId');
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      if (kDebugMode) print('❌ Error initializing group member provider: $e');
    }
  }

  void _setupSubscriptions() {
    _groupUpdateSubscription = _chatSocketService
        .getUpdatesForChat(groupId)
        .listen(_handleGroupUpdate);
  }

  void _handleGroupUpdate(ChatUpdate update) {
    switch (update.type) {
      case ChatUpdateType.participantAdded:
        _handleMemberAdded(update.data);
        break;
      case ChatUpdateType.participantRemoved:
        _handleMemberRemoved(update.data);
        break;
      default:
        break;
    }
  }

  void _handleMemberAdded(Map<String, dynamic> data) {
    final userId = data['user_id'] as String?;
    if (userId == null) return;

    state.whenData((memberState) {
      if (!memberState.members.containsKey(userId)) {
        // Fetch member details
        _fetchMemberDetails(userId);
      }
    });
  }

  void _handleMemberRemoved(Map<String, dynamic> data) {
    final userId = data['user_id'] as String?;
    if (userId == null) return;

    state.whenData((memberState) {
      final updatedMembers = Map<String, GroupMemberInfo>.from(
        memberState.members,
      );
      updatedMembers.remove(userId);

      state = AsyncValue.data(memberState.copyWith(members: updatedMembers));
    });

    _cacheMemberState();
  }

  void _startOnlineStatusUpdates() {
    _onlineStatusTimer = Timer.periodic(_onlineStatusInterval, (_) {
      _updateOnlineStatus();
    });
  }

  Future<void> _updateOnlineStatus() async {
    try {
      final memberIds = state.value?.members.keys.toList() ?? [];
      if (memberIds.isEmpty) return;

      final response = await _apiService.getUsersOnlineStatus(memberIds);

      if (response.success && response.data != null) {
        final onlineStatuses = response.data as Map<String, bool>;

        state.whenData((memberState) {
          final updatedMembers = <String, GroupMemberInfo>{};

          for (final entry in memberState.members.entries) {
            final isOnline = onlineStatuses[entry.key] ?? false;
            updatedMembers[entry.key] = entry.value.copyWith(
              isOnline: isOnline,
              lastActiveAt: isOnline
                  ? DateTime.now()
                  : entry.value.lastActiveAt,
            );
          }

          state = AsyncValue.data(
            memberState.copyWith(members: updatedMembers),
          );
        });
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error updating online status: $e');
    }
  }

  Future<void> _loadMembers() async {
    try {
      // Load from cache first
      final cachedMembers = await _loadMembersFromCache();

      if (cachedMembers.isNotEmpty) {
        state = AsyncValue.data(state.value!.copyWith(members: cachedMembers));
      }

      // Load from API
      await _loadMembersFromAPI();
    } catch (e) {
      if (kDebugMode) print('❌ Error loading members: $e');
      rethrow;
    }
  }

  Future<Map<String, GroupMemberInfo>> _loadMembersFromCache() async {
    try {
      final cachedData = await _cacheService.getCachedGroupMembers(groupId);
      final members = <String, GroupMemberInfo>{};

      for (final memberData in cachedData) {
        final member = GroupMemberInfo.fromJson(memberData);
        members[member.userId] = member;
      }

      return members;
    } catch (e) {
      if (kDebugMode) print('❌ Error loading members from cache: $e');
      return {};
    }
  }

  Future<void> _loadMembersFromAPI() async {
    try {
      final response = await _apiService.getGroupMembers(
        groupId,
        page: 1,
        limit: _membersPerPage,
      );

      if (response.success && response.data != null) {
        final apiMembers = response.data as List<GroupMemberInfo>;
        final memberMap = <String, GroupMemberInfo>{};

        for (final member in apiMembers) {
          memberMap[member.userId] = member;
        }

        state = AsyncValue.data(
          state.value!.copyWith(
            members: memberMap,
            hasMore: apiMembers.length >= _membersPerPage,
            page: 1,
          ),
        );

        await _cacheMemberState();

        if (kDebugMode) print('✅ Loaded ${apiMembers.length} members from API');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error loading members from API: $e');

      state.whenData((memberState) {
        if (memberState.members.isEmpty) {
          state = AsyncValue.error(e, StackTrace.current);
        } else {
          state = AsyncValue.data(memberState.copyWith(error: e.toString()));
        }
      });
    }
  }

  Future<void> loadMoreMembers() async {
    final currentState = state.value;
    if (currentState == null ||
        currentState.isLoadingMore ||
        !currentState.hasMore) {
      return;
    }

    state = AsyncValue.data(currentState.copyWith(isLoadingMore: true));

    try {
      final response = await _apiService.getGroupMembers(
        groupId,
        page: currentState.page + 1,
        limit: _membersPerPage,
      );

      if (response.success && response.data != null) {
        final newMembers = response.data as List<GroupMemberInfo>;
        final updatedMembers = Map<String, GroupMemberInfo>.from(
          currentState.members,
        );

        for (final member in newMembers) {
          updatedMembers[member.userId] = member;
        }

        state = AsyncValue.data(
          currentState.copyWith(
            members: updatedMembers,
            isLoadingMore: false,
            hasMore: newMembers.length >= _membersPerPage,
            page: currentState.page + 1,
          ),
        );

        await _cacheMemberState();
      }
    } catch (e) {
      state = AsyncValue.data(
        currentState.copyWith(isLoadingMore: false, error: e.toString()),
      );
    }
  }

  Future<void> _fetchMemberDetails(String userId) async {
    try {
      final response = await _apiService.getGroupMember(groupId, userId);

      if (response.success && response.data != null) {
        final member = response.data as GroupMemberInfo;

        state.whenData((memberState) {
          final updatedMembers = Map<String, GroupMemberInfo>.from(
            memberState.members,
          );
          updatedMembers[userId] = member;

          state = AsyncValue.data(
            memberState.copyWith(members: updatedMembers),
          );
        });

        await _cacheMemberState();
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error fetching member details: $e');
    }
  }

  // Public methods for member management
  Future<void> addMember(
    String userId, {
    MemberRole role = MemberRole.member,
  }) async {
    try {
      final response = await _apiService.addGroupMember(
        groupId,
        userId,
        role: role.name,
      );

      if (response.success) {
        await _fetchMemberDetails(userId);
        if (kDebugMode) print('✅ Member added: $userId');
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error adding member: $e');
      rethrow;
    }
  }

  Future<void> removeMember(String userId) async {
    try {
      final response = await _apiService.removeGroupMember(groupId, userId);

      if (response.success) {
        state.whenData((memberState) {
          final updatedMembers = Map<String, GroupMemberInfo>.from(
            memberState.members,
          );
          updatedMembers.remove(userId);

          state = AsyncValue.data(
            memberState.copyWith(members: updatedMembers),
          );
        });

        await _cacheMemberState();
        if (kDebugMode) print('✅ Member removed: $userId');
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error removing member: $e');
      rethrow;
    }
  }

  Future<void> updateMemberRole(String userId, MemberRole newRole) async {
    try {
      final response = await _apiService.updateGroupMemberRole(
        groupId,
        userId,
        newRole.name,
      );

      if (response.success) {
        state.whenData((memberState) {
          final member = memberState.members[userId];
          if (member != null) {
            final updatedMembers = Map<String, GroupMemberInfo>.from(
              memberState.members,
            );
            updatedMembers[userId] = member.copyWith(role: newRole);

            state = AsyncValue.data(
              memberState.copyWith(members: updatedMembers),
            );
          }
        });

        await _cacheMemberState();
        if (kDebugMode)
          print('✅ Member role updated: $userId -> ${newRole.name}');
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error updating member role: $e');
      rethrow;
    }
  }

  Future<void> muteMember(
    String userId, {
    Duration? duration,
    String? reason,
  }) async {
    try {
      final response = await _apiService.muteGroupMember(
        groupId,
        userId,
        duration: duration?.inMilliseconds,
        reason: reason,
      );

      if (response.success) {
        state.whenData((memberState) {
          final member = memberState.members[userId];
          if (member != null) {
            final mutedUntil = duration != null
                ? DateTime.now().add(duration)
                : null;

            final updatedMembers = Map<String, GroupMemberInfo>.from(
              memberState.members,
            );
            updatedMembers[userId] = member.copyWith(
              status: MemberStatus.muted,
              mutedUntil: mutedUntil,
              muteReason: reason,
            );

            state = AsyncValue.data(
              memberState.copyWith(members: updatedMembers),
            );
          }
        });

        await _cacheMemberState();
        if (kDebugMode) print('✅ Member muted: $userId');
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error muting member: $e');
      rethrow;
    }
  }

  Future<void> unmuteMember(String userId) async {
    try {
      final response = await _apiService.unmuteGroupMember(groupId, userId);

      if (response.success) {
        state.whenData((memberState) {
          final member = memberState.members[userId];
          if (member != null) {
            final updatedMembers = Map<String, GroupMemberInfo>.from(
              memberState.members,
            );
            updatedMembers[userId] = member.copyWith(
              status: MemberStatus.active,
              mutedUntil: null,
              muteReason: null,
            );

            state = AsyncValue.data(
              memberState.copyWith(members: updatedMembers),
            );
          }
        });

        await _cacheMemberState();
        if (kDebugMode) print('✅ Member unmuted: $userId');
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error unmuting member: $e');
      rethrow;
    }
  }

  Future<void> banMember(
    String userId, {
    Duration? duration,
    String? reason,
  }) async {
    try {
      final response = await _apiService.banGroupMember(
        groupId,
        userId,
        duration: duration?.inMilliseconds,
        reason: reason,
      );

      if (response.success) {
        state.whenData((memberState) {
          final member = memberState.members[userId];
          if (member != null) {
            final bannedUntil = duration != null
                ? DateTime.now().add(duration)
                : null;

            final updatedMembers = Map<String, GroupMemberInfo>.from(
              memberState.members,
            );
            updatedMembers[userId] = member.copyWith(
              status: MemberStatus.banned,
              bannedUntil: bannedUntil,
              banReason: reason,
            );

            state = AsyncValue.data(
              memberState.copyWith(members: updatedMembers),
            );
          }
        });

        await _cacheMemberState();
        if (kDebugMode) print('✅ Member banned: $userId');
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error banning member: $e');
      rethrow;
    }
  }

  Future<void> unbanMember(String userId) async {
    try {
      final response = await _apiService.unbanGroupMember(groupId, userId);

      if (response.success) {
        state.whenData((memberState) {
          final member = memberState.members[userId];
          if (member != null) {
            final updatedMembers = Map<String, GroupMemberInfo>.from(
              memberState.members,
            );
            updatedMembers[userId] = member.copyWith(
              status: MemberStatus.active,
              bannedUntil: null,
              banReason: null,
            );

            state = AsyncValue.data(
              memberState.copyWith(members: updatedMembers),
            );
          }
        });

        await _cacheMemberState();
        if (kDebugMode) print('✅ Member unbanned: $userId');
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error unbanning member: $e');
      rethrow;
    }
  }

  Future<void> setCustomTitle(String userId, String? title) async {
    try {
      final response = await _apiService.setGroupMemberTitle(
        groupId,
        userId,
        title,
      );

      if (response.success) {
        state.whenData((memberState) {
          final member = memberState.members[userId];
          if (member != null) {
            final updatedMembers = Map<String, GroupMemberInfo>.from(
              memberState.members,
            );
            updatedMembers[userId] = member.copyWith(customTitle: title);

            state = AsyncValue.data(
              memberState.copyWith(members: updatedMembers),
            );
          }
        });

        await _cacheMemberState();
        if (kDebugMode) print('✅ Member title updated: $userId -> $title');
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error setting custom title: $e');
      rethrow;
    }
  }

  // Search and filter methods
  void setSearchQuery(String query) {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(_searchDebounceDelay, () {
      state.whenData((memberState) {
        state = AsyncValue.data(memberState.copyWith(searchQuery: query));
      });
    });
  }

  void setRoleFilter(MemberRole? role) {
    state.whenData((memberState) {
      state = AsyncValue.data(memberState.copyWith(roleFilter: role));
    });
  }

  void setStatusFilter(MemberStatus? status) {
    state.whenData((memberState) {
      state = AsyncValue.data(memberState.copyWith(statusFilter: status));
    });
  }

  void clearFilters() {
    state.whenData((memberState) {
      state = AsyncValue.data(
        memberState.copyWith(
          searchQuery: '',
          roleFilter: null,
          statusFilter: null,
        ),
      );
    });
  }

  Future<void> refreshMembers() async {
    state.whenData((memberState) {
      state = AsyncValue.data(memberState.copyWith(page: 1, hasMore: true));
    });

    await _loadMembersFromAPI();
  }

  Future<void> _cacheMemberState() async {
    try {
      final members = state.value?.members.values.toList() ?? [];
      final memberData = members.map((m) => m.toJson()).toList();
      await _cacheService.cacheGroupMembers(groupId, memberData);
    } catch (e) {
      if (kDebugMode) print('❌ Error caching member state: $e');
    }
  }

  // Getters
  Map<String, GroupMemberInfo> get members => state.value?.members ?? {};
  List<GroupMemberInfo> get memberList => state.value?.memberList ?? [];
  List<GroupMemberInfo> get filteredMembers =>
      state.value?.filteredMembers ?? [];
  bool get isLoading => state.value?.isLoading ?? false;
  bool get isLoadingMore => state.value?.isLoadingMore ?? false;
  int get totalMembers => state.value?.totalMembers ?? 0;
  int get onlineCount => state.value?.onlineCount ?? 0;

  @override
  void dispose() {
    _groupUpdateSubscription?.cancel();
    _onlineStatusTimer?.cancel();
    _searchDebounceTimer?.cancel();
    super.dispose();
  }
}

// Providers
final groupMemberProvider = StateNotifierProvider.autoDispose
    .family<GroupMemberNotifier, AsyncValue<GroupMemberState>, String>((
      ref,
      groupId,
    ) {
      final apiService = ref.watch(apiServiceProvider);
      final cacheService = CacheService();
      final chatSocketService = ref.watch(chatSocketServiceProvider);

      return GroupMemberNotifier(
        groupId: groupId,
        apiService: apiService,
        cacheService: cacheService,
        chatSocketService: chatSocketService,
      );
    });

// Convenience providers
final groupMembersProvider = Provider.family<List<GroupMemberInfo>, String>((
  ref,
  groupId,
) {
  final memberState = ref.watch(groupMemberProvider(groupId));
  return memberState.whenOrNull(data: (state) => state.memberList) ?? [];
});

final filteredGroupMembersProvider =
    Provider.family<List<GroupMemberInfo>, String>((ref, groupId) {
      final memberState = ref.watch(groupMemberProvider(groupId));
      return memberState.whenOrNull(data: (state) => state.filteredMembers) ??
          [];
    });

final groupMemberLoadingProvider = Provider.family<bool, String>((
  ref,
  groupId,
) {
  final memberState = ref.watch(groupMemberProvider(groupId));
  return memberState.whenOrNull(data: (state) => state.isLoading) ?? false;
});

final groupMemberByIdProvider =
    Provider.family<GroupMemberInfo?, (String, String)>((ref, params) {
      final groupId = params.$1;
      final userId = params.$2;
      final memberState = ref.watch(groupMemberProvider(groupId));
      return memberState.whenOrNull(data: (state) => state.getMember(userId));
    });

final groupOnlineMembersProvider =
    Provider.family<List<GroupMemberInfo>, String>((ref, groupId) {
      final memberState = ref.watch(groupMemberProvider(groupId));
      return memberState.whenOrNull(data: (state) => state.onlineMembers) ?? [];
    });

final groupAdminsProvider = Provider.family<List<GroupMemberInfo>, String>((
  ref,
  groupId,
) {
  final memberState = ref.watch(groupMemberProvider(groupId));
  return memberState.whenOrNull(data: (state) => state.admins) ?? [];
});

final groupMemberCountProvider = Provider.family<int, String>((ref, groupId) {
  final memberState = ref.watch(groupMemberProvider(groupId));
  return memberState.whenOrNull(data: (state) => state.totalMembers) ?? 0;
});

final groupOnlineCountProvider = Provider.family<int, String>((ref, groupId) {
  final memberState = ref.watch(groupMemberProvider(groupId));
  return memberState.whenOrNull(data: (state) => state.onlineCount) ?? 0;
});
