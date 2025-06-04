import 'dart:async';
import 'package:bro_chat/models/chat/message_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../../services/api/api_service.dart';
import '../../services/storage/cache_service.dart';
import '../../services/websocket/chat_socket.dart';
import '../../services/websocket/websocket_event_types.dart';
import '../../models/group/group_model.dart';
import '../../models/group/group_settings.dart';
import '../../models/common/api_response.dart';

enum GroupType { private, public, broadcast, channel }

enum GroupPrivacy { open, closed, secret }

enum GroupJoinMethod { invite, link, approval, free }

class GroupInfo {
  final String id;
  final String name;
  final String? description;
  final String? avatar;
  final GroupType type;
  final GroupPrivacy privacy;
  final GroupJoinMethod joinMethod;
  final String ownerId;
  final List<String> adminIds;
  final List<String> moderatorIds;
  final int memberCount;
  final int maxMembers;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastActivityAt;
  final GroupSettings settings;
  final bool isActive;
  final bool isArchived;
  final bool isMuted;
  final bool isPinned;
  final String? inviteLink;
  final DateTime? inviteLinkExpiry;
  final Map<String, dynamic>? metadata;
  final List<String> tags;
  final String? category;
  final bool isVerified;
  final int messageCount;
  final String? lastMessageId;
  final DateTime? lastMessageAt;

  GroupInfo({
    required this.id,
    required this.name,
    this.description,
    this.avatar,
    this.type = GroupType.private,
    this.privacy = GroupPrivacy.closed,
    this.joinMethod = GroupJoinMethod.invite,
    required this.ownerId,
    this.adminIds = const [],
    this.moderatorIds = const [],
    this.memberCount = 0,
    this.maxMembers = 500,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.lastActivityAt,
    GroupSettings? settings,
    this.isActive = true,
    this.isArchived = false,
    this.isMuted = false,
    this.isPinned = false,
    this.inviteLink,
    this.inviteLinkExpiry,
    this.metadata,
    this.tags = const [],
    this.category,
    this.isVerified = false,
    this.messageCount = 0,
    this.lastMessageId,
    this.lastMessageAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now(),
       settings = settings ?? GroupSettings();

  GroupInfo copyWith({
    String? id,
    String? name,
    String? description,
    String? avatar,
    GroupType? type,
    GroupPrivacy? privacy,
    GroupJoinMethod? joinMethod,
    String? ownerId,
    List<String>? adminIds,
    List<String>? moderatorIds,
    int? memberCount,
    int? maxMembers,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastActivityAt,
    GroupSettings? settings,
    bool? isActive,
    bool? isArchived,
    bool? isMuted,
    bool? isPinned,
    String? inviteLink,
    DateTime? inviteLinkExpiry,
    Map<String, dynamic>? metadata,
    List<String>? tags,
    String? category,
    bool? isVerified,
    int? messageCount,
    String? lastMessageId,
    DateTime? lastMessageAt,
  }) {
    return GroupInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      avatar: avatar ?? this.avatar,
      type: type ?? this.type,
      privacy: privacy ?? this.privacy,
      joinMethod: joinMethod ?? this.joinMethod,
      ownerId: ownerId ?? this.ownerId,
      adminIds: adminIds ?? this.adminIds,
      moderatorIds: moderatorIds ?? this.moderatorIds,
      memberCount: memberCount ?? this.memberCount,
      maxMembers: maxMembers ?? this.maxMembers,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      settings: settings ?? this.settings,
      isActive: isActive ?? this.isActive,
      isArchived: isArchived ?? this.isArchived,
      isMuted: isMuted ?? this.isMuted,
      isPinned: isPinned ?? this.isPinned,
      inviteLink: inviteLink ?? this.inviteLink,
      inviteLinkExpiry: inviteLinkExpiry ?? this.inviteLinkExpiry,
      metadata: metadata ?? this.metadata,
      tags: tags ?? this.tags,
      category: category ?? this.category,
      isVerified: isVerified ?? this.isVerified,
      messageCount: messageCount ?? this.messageCount,
      lastMessageId: lastMessageId ?? this.lastMessageId,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
    );
  }

  bool get isPublic => privacy == GroupPrivacy.open;
  bool get isPrivate =>
      privacy == GroupPrivacy.closed || privacy == GroupPrivacy.secret;
  bool get canJoinFreely => joinMethod == GroupJoinMethod.free;
  bool get requiresApproval => joinMethod == GroupJoinMethod.approval;
  bool get hasInviteLink =>
      inviteLink != null &&
      (inviteLinkExpiry == null || DateTime.now().isBefore(inviteLinkExpiry!));
  bool get isFull => memberCount >= maxMembers;
  bool get hasRecentActivity =>
      lastActivityAt != null &&
      DateTime.now().difference(lastActivityAt!).inDays < 7;

  String get displayType {
    switch (type) {
      case GroupType.private:
        return 'Private Group';
      case GroupType.public:
        return 'Public Group';
      case GroupType.broadcast:
        return 'Broadcast';
      case GroupType.channel:
        return 'Channel';
    }
  }

  String get displayPrivacy {
    switch (privacy) {
      case GroupPrivacy.open:
        return 'Open';
      case GroupPrivacy.closed:
        return 'Closed';
      case GroupPrivacy.secret:
        return 'Secret';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'avatar': avatar,
      'type': type.name,
      'privacy': privacy.name,
      'join_method': joinMethod.name,
      'owner_id': ownerId,
      'admin_ids': adminIds,
      'moderator_ids': moderatorIds,
      'member_count': memberCount,
      'max_members': maxMembers,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_activity_at': lastActivityAt?.toIso8601String(),
      'settings': settings.toJson(),
      'is_active': isActive,
      'is_archived': isArchived,
      'is_muted': isMuted,
      'is_pinned': isPinned,
      'invite_link': inviteLink,
      'invite_link_expiry': inviteLinkExpiry?.toIso8601String(),
      'metadata': metadata,
      'tags': tags,
      'category': category,
      'is_verified': isVerified,
      'message_count': messageCount,
      'last_message_id': lastMessageId,
      'last_message_at': lastMessageAt?.toIso8601String(),
    };
  }

  factory GroupInfo.fromJson(Map<String, dynamic> json) {
    return GroupInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      avatar: json['avatar'],
      type: GroupType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => GroupType.private,
      ),
      privacy: GroupPrivacy.values.firstWhere(
        (p) => p.name == json['privacy'],
        orElse: () => GroupPrivacy.closed,
      ),
      joinMethod: GroupJoinMethod.values.firstWhere(
        (j) => j.name == json['join_method'],
        orElse: () => GroupJoinMethod.invite,
      ),
      ownerId: json['owner_id'] ?? '',
      adminIds: List<String>.from(json['admin_ids'] ?? []),
      moderatorIds: List<String>.from(json['moderator_ids'] ?? []),
      memberCount: json['member_count'] ?? 0,
      maxMembers: json['max_members'] ?? 500,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
      lastActivityAt: json['last_activity_at'] != null
          ? DateTime.tryParse(json['last_activity_at'])
          : null,
      settings: json['settings'] != null
          ? GroupSettings.fromJson(json['settings'])
          : GroupSettings(),
      isActive: json['is_active'] ?? true,
      isArchived: json['is_archived'] ?? false,
      isMuted: json['is_muted'] ?? false,
      isPinned: json['is_pinned'] ?? false,
      inviteLink: json['invite_link'],
      inviteLinkExpiry: json['invite_link_expiry'] != null
          ? DateTime.tryParse(json['invite_link_expiry'])
          : null,
      metadata: json['metadata'],
      tags: List<String>.from(json['tags'] ?? []),
      category: json['category'],
      isVerified: json['is_verified'] ?? false,
      messageCount: json['message_count'] ?? 0,
      lastMessageId: json['last_message_id'],
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.tryParse(json['last_message_at'])
          : null,
    );
  }
}

class GroupState {
  final GroupInfo? group;
  final bool isLoading;
  final String? error;
  final bool isInitialized;
  final DateTime? lastFetchTime;
  final bool isJoining;
  final bool isLeaving;
  final bool isUpdating;

  GroupState({
    this.group,
    this.isLoading = false,
    this.error,
    this.isInitialized = false,
    this.lastFetchTime,
    this.isJoining = false,
    this.isLeaving = false,
    this.isUpdating = false,
  });

  GroupState copyWith({
    GroupInfo? group,
    bool? isLoading,
    String? error,
    bool? isInitialized,
    DateTime? lastFetchTime,
    bool? isJoining,
    bool? isLeaving,
    bool? isUpdating,
  }) {
    return GroupState(
      group: group ?? this.group,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isInitialized: isInitialized ?? this.isInitialized,
      lastFetchTime: lastFetchTime ?? this.lastFetchTime,
      isJoining: isJoining ?? this.isJoining,
      isLeaving: isLeaving ?? this.isLeaving,
      isUpdating: isUpdating ?? this.isUpdating,
    );
  }

  bool get hasGroup => group != null;
  bool get isPublicGroup => group?.isPublic ?? false;
  bool get isPrivateGroup => group?.isPrivate ?? false;
  bool get canJoinFreely => group?.canJoinFreely ?? false;
  bool get requiresApproval => group?.requiresApproval ?? false;
  bool get hasInviteLink => group?.hasInviteLink ?? false;
  bool get isFull => group?.isFull ?? false;
  bool get isArchived => group?.isArchived ?? false;
  bool get isMuted => group?.isMuted ?? false;
  bool get isPinned => group?.isPinned ?? false;
}

class GroupNotifier extends StateNotifier<AsyncValue<GroupState>> {
  final String groupId;
  final ApiService _apiService;
  final CacheService _cacheService;
  final ChatSocketService _chatSocketService;

  StreamSubscription<ChatUpdate>? _groupUpdateSubscription;
  StreamSubscription<MessageModel>? _messageSubscription;
  Timer? _activityTimer;

  static const Duration _activityUpdateInterval = Duration(minutes: 5);

  GroupNotifier({
    required this.groupId,
    required ApiService apiService,
    required CacheService cacheService,
    required ChatSocketService chatSocketService,
  }) : _apiService = apiService,
       _cacheService = cacheService,
       _chatSocketService = chatSocketService,
       super(AsyncValue.data(GroupState())) {
    _initialize();
  }

  void _initialize() async {
    state = AsyncValue.data(state.value!.copyWith(isLoading: true));

    try {
      _setupSubscriptions();
      await _loadGroup();
      _startActivityTracking();

      state = AsyncValue.data(
        state.value!.copyWith(
          isLoading: false,
          isInitialized: true,
          lastFetchTime: DateTime.now(),
        ),
      );

      if (kDebugMode) print('✅ Group provider initialized for: $groupId');
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      if (kDebugMode) print('❌ Error initializing group provider: $e');
    }
  }

  void _setupSubscriptions() {
    // Listen to group updates
    _groupUpdateSubscription = _chatSocketService
        .getUpdatesForChat(groupId)
        .listen(_handleGroupUpdate);

    // Listen to messages to update activity
    _messageSubscription = _chatSocketService
        .getMessagesForChat(groupId)
        .listen(_handleNewMessage);
  }

  void _handleGroupUpdate(ChatUpdate update) {
    switch (update.type) {
      case ChatUpdateType.chatUpdated:
        _handleGroupInfoUpdate(update.data);
        break;
      case ChatUpdateType.participantAdded:
        _handleMemberCountChange(1);
        break;
      case ChatUpdateType.participantRemoved:
        _handleMemberCountChange(-1);
        break;
      default:
        break;
    }
  }

  void _handleGroupInfoUpdate(Map<String, dynamic> data) {
    state.whenData((groupState) {
      if (groupState.group == null) return;

      GroupInfo updatedGroup = groupState.group!;

      if (data.containsKey('name')) {
        updatedGroup = updatedGroup.copyWith(name: data['name']);
      }
      if (data.containsKey('description')) {
        updatedGroup = updatedGroup.copyWith(description: data['description']);
      }
      if (data.containsKey('avatar')) {
        updatedGroup = updatedGroup.copyWith(avatar: data['avatar']);
      }
      if (data.containsKey('settings')) {
        updatedGroup = updatedGroup.copyWith(
          settings: GroupSettings.fromJson(data['settings']),
        );
      }
      if (data.containsKey('is_muted')) {
        updatedGroup = updatedGroup.copyWith(isMuted: data['is_muted']);
      }
      if (data.containsKey('is_pinned')) {
        updatedGroup = updatedGroup.copyWith(isPinned: data['is_pinned']);
      }
      if (data.containsKey('is_archived')) {
        updatedGroup = updatedGroup.copyWith(isArchived: data['is_archived']);
      }

      updatedGroup = updatedGroup.copyWith(updatedAt: DateTime.now());

      state = AsyncValue.data(groupState.copyWith(group: updatedGroup));
      _cacheGroup(updatedGroup);
    });
  }

  void _handleMemberCountChange(int change) {
    state.whenData((groupState) {
      if (groupState.group == null) return;

      final updatedGroup = groupState.group!.copyWith(
        memberCount: (groupState.group!.memberCount + change)
            .clamp(0, double.infinity)
            .toInt(),
        updatedAt: DateTime.now(),
      );

      state = AsyncValue.data(groupState.copyWith(group: updatedGroup));
      _cacheGroup(updatedGroup);
    });
  }

  void _handleNewMessage(MessageModel message) {
    state.whenData((groupState) {
      if (groupState.group == null) return;

      final updatedGroup = groupState.group!.copyWith(
        lastActivityAt: message.createdAt,
        lastMessageId: message.id,
        lastMessageAt: message.createdAt,
        messageCount: groupState.group!.messageCount + 1,
      );

      state = AsyncValue.data(groupState.copyWith(group: updatedGroup));
    });
  }

  void _startActivityTracking() {
    _activityTimer = Timer.periodic(_activityUpdateInterval, (_) {
      _updateLastActivity();
    });
  }

  Future<void> _updateLastActivity() async {
    try {
      // This would typically send a heartbeat to the server
      // For now, we'll just update the local timestamp
      state.whenData((groupState) {
        if (groupState.group != null) {
          final updatedGroup = groupState.group!.copyWith(
            lastActivityAt: DateTime.now(),
          );
          state = AsyncValue.data(groupState.copyWith(group: updatedGroup));
        }
      });
    } catch (e) {
      if (kDebugMode) print('❌ Error updating activity: $e');
    }
  }

  Future<void> _loadGroup() async {
    try {
      // Load from cache first
      final cachedGroup = await _loadGroupFromCache();

      if (cachedGroup != null) {
        state = AsyncValue.data(state.value!.copyWith(group: cachedGroup));
      }

      // Load from API
      await _loadGroupFromAPI();
    } catch (e) {
      if (kDebugMode) print('❌ Error loading group: $e');
      rethrow;
    }
  }

  Future<GroupInfo?> _loadGroupFromCache() async {
    try {
      final cachedData = await _cacheService.getCachedGroup(groupId);
      return cachedData != null ? GroupInfo.fromJson(cachedData) : null;
    } catch (e) {
      if (kDebugMode) print('❌ Error loading group from cache: $e');
      return null;
    }
  }

  Future<void> _loadGroupFromAPI() async {
    try {
      final response = await _apiService.getGroup(groupId);

      if (response.success && response.data != null) {
        final group = response.data as GroupInfo;
        await _cacheGroup(group);

        state = AsyncValue.data(
          state.value!.copyWith(group: group, lastFetchTime: DateTime.now()),
        );

        if (kDebugMode) print('✅ Loaded group from API: ${group.name}');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error loading group from API: $e');

      state.whenData((groupState) {
        if (groupState.group == null) {
          state = AsyncValue.error(e, StackTrace.current);
        } else {
          state = AsyncValue.data(groupState.copyWith(error: e.toString()));
        }
      });
    }
  }

  // Public methods for group management
  Future<void> updateGroup({
    String? name,
    String? description,
    String? avatar,
    GroupType? type,
    GroupPrivacy? privacy,
    GroupJoinMethod? joinMethod,
    int? maxMembers,
    GroupSettings? settings,
    List<String>? tags,
    String? category,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      state = AsyncValue.data(state.value!.copyWith(isUpdating: true));

      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (avatar != null) updateData['avatar'] = avatar;
      if (type != null) updateData['type'] = type.name;
      if (privacy != null) updateData['privacy'] = privacy.name;
      if (joinMethod != null) updateData['join_method'] = joinMethod.name;
      if (maxMembers != null) updateData['max_members'] = maxMembers;
      if (settings != null) updateData['settings'] = settings.toJson();
      if (tags != null) updateData['tags'] = tags;
      if (category != null) updateData['category'] = category;
      if (metadata != null) updateData['metadata'] = metadata;

      final response = await _apiService.updateGroup(groupId, updateData);

      if (response.success && response.data != null) {
        final updatedGroup = response.data as GroupInfo;

        state = AsyncValue.data(
          state.value!.copyWith(group: updatedGroup, isUpdating: false),
        );

        await _cacheGroup(updatedGroup);
        if (kDebugMode) print('✅ Group updated: ${updatedGroup.name}');
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      state = AsyncValue.data(
        state.value!.copyWith(isUpdating: false, error: e.toString()),
      );
      if (kDebugMode) print('❌ Error updating group: $e');
      rethrow;
    }
  }

  Future<void> joinGroup({String? inviteCode}) async {
    try {
      state = AsyncValue.data(state.value!.copyWith(isJoining: true));

      final response = inviteCode != null
          ? await _apiService.joinGroupByInvite(inviteCode)
          : await _apiService.joinGroup(groupId);

      if (response.success) {
        state.whenData((groupState) {
          if (groupState.group != null) {
            final updatedGroup = groupState.group!.copyWith(
              memberCount: groupState.group!.memberCount + 1,
            );
            state = AsyncValue.data(
              groupState.copyWith(group: updatedGroup, isJoining: false),
            );
          }
        });

        if (kDebugMode) print('✅ Joined group: $groupId');
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      state = AsyncValue.data(
        state.value!.copyWith(isJoining: false, error: e.toString()),
      );
      if (kDebugMode) print('❌ Error joining group: $e');
      rethrow;
    }
  }

  Future<void> leaveGroup() async {
    try {
      state = AsyncValue.data(state.value!.copyWith(isLeaving: true));

      final response = await _apiService.leaveGroup(groupId);

      if (response.success) {
        state.whenData((groupState) {
          if (groupState.group != null) {
            final updatedGroup = groupState.group!.copyWith(
              memberCount: (groupState.group!.memberCount - 1)
                  .clamp(0, double.infinity)
                  .toInt(),
            );
            state = AsyncValue.data(
              groupState.copyWith(group: updatedGroup, isLeaving: false),
            );
          }
        });

        if (kDebugMode) print('✅ Left group: $groupId');
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      state = AsyncValue.data(
        state.value!.copyWith(isLeaving: false, error: e.toString()),
      );
      if (kDebugMode) print('❌ Error leaving group: $e');
      rethrow;
    }
  }

  Future<void> deleteGroup() async {
    try {
      final response = await _apiService.deleteGroup(groupId);

      if (response.success) {
        state = AsyncValue.data(GroupState(isInitialized: true));
        await _cacheService.removeCachedGroup(groupId);
        if (kDebugMode) print('✅ Group deleted: $groupId');
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error deleting group: $e');
      rethrow;
    }
  }

  Future<void> archiveGroup(bool archive) async {
    try {
      final response = await _apiService.archiveGroup(groupId, archive);

      if (response.success) {
        state.whenData((groupState) {
          if (groupState.group != null) {
            final updatedGroup = groupState.group!.copyWith(
              isArchived: archive,
              updatedAt: DateTime.now(),
            );
            state = AsyncValue.data(groupState.copyWith(group: updatedGroup));
            _cacheGroup(updatedGroup);
          }
        });

        if (kDebugMode) {
          print('✅ Group ${archive ? 'archived' : 'unarchived'}: $groupId');
        }
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error archiving group: $e');
      rethrow;
    }
  }

  Future<void> muteGroup({required bool mute, DateTime? mutedUntil}) async {
    try {
      final response = await _apiService.muteGroup(
        groupId,
        mute: mute,
        mutedUntil: mutedUntil,
      );

      if (response.success) {
        state.whenData((groupState) {
          if (groupState.group != null) {
            final updatedGroup = groupState.group!.copyWith(
              isMuted: mute,
              updatedAt: DateTime.now(),
            );
            state = AsyncValue.data(groupState.copyWith(group: updatedGroup));
            _cacheGroup(updatedGroup);
          }
        });

        if (kDebugMode) {
          print('✅ Group ${mute ? 'muted' : 'unmuted'}: $groupId');
        }
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error muting group: $e');
      rethrow;
    }
  }

  Future<void> pinGroup(bool pin) async {
    try {
      final response = await _apiService.pinGroup(groupId, pin);

      if (response.success) {
        state.whenData((groupState) {
          if (groupState.group != null) {
            final updatedGroup = groupState.group!.copyWith(
              isPinned: pin,
              updatedAt: DateTime.now(),
            );
            state = AsyncValue.data(groupState.copyWith(group: updatedGroup));
            _cacheGroup(updatedGroup);
          }
        });

        if (kDebugMode) {
          print('✅ Group ${pin ? 'pinned' : 'unpinned'}: $groupId');
        }
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error pinning group: $e');
      rethrow;
    }
  }

  Future<String?> generateInviteLink({
    DateTime? expiresAt,
    int? maxUses,
  }) async {
    try {
      final response = await _apiService.generateGroupInviteLink(
        groupId,
        expiresAt: expiresAt,
        maxUses: maxUses,
      );

      if (response.success && response.data != null) {
        final inviteLink = response.data['invite_link'] as String;
        final expiry = response.data['expires_at'] != null
            ? DateTime.tryParse(response.data['expires_at'])
            : null;

        state.whenData((groupState) {
          if (groupState.group != null) {
            final updatedGroup = groupState.group!.copyWith(
              inviteLink: inviteLink,
              inviteLinkExpiry: expiry,
            );
            state = AsyncValue.data(groupState.copyWith(group: updatedGroup));
            _cacheGroup(updatedGroup);
          }
        });

        if (kDebugMode) print('✅ Invite link generated: $inviteLink');
        return inviteLink;
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error generating invite link: $e');
      rethrow;
    }
  }

  Future<void> revokeInviteLink() async {
    try {
      final response = await _apiService.revokeGroupInviteLink(groupId);

      if (response.success) {
        state.whenData((groupState) {
          if (groupState.group != null) {
            final updatedGroup = groupState.group!.copyWith(
              inviteLink: null,
              inviteLinkExpiry: null,
            );
            state = AsyncValue.data(groupState.copyWith(group: updatedGroup));
            _cacheGroup(updatedGroup);
          }
        });

        if (kDebugMode) print('✅ Invite link revoked: $groupId');
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error revoking invite link: $e');
      rethrow;
    }
  }

  Future<void> refreshGroup() async {
    await _loadGroupFromAPI();
  }

  Future<void> _cacheGroup(GroupInfo group) async {
    try {
      await _cacheService.cacheGroup(group.id, group.toJson());
    } catch (e) {
      if (kDebugMode) print('❌ Error caching group: $e');
    }
  }

  // Getters
  GroupInfo? get group => state.value?.group;
  bool get isLoading => state.value?.isLoading ?? false;
  bool get isJoining => state.value?.isJoining ?? false;
  bool get isLeaving => state.value?.isLeaving ?? false;
  bool get isUpdating => state.value?.isUpdating ?? false;
  bool get hasGroup => state.value?.hasGroup ?? false;
  bool get isPublicGroup => state.value?.isPublicGroup ?? false;
  bool get isPrivateGroup => state.value?.isPrivateGroup ?? false;
  bool get canJoinFreely => state.value?.canJoinFreely ?? false;
  bool get requiresApproval => state.value?.requiresApproval ?? false;
  bool get hasInviteLink => state.value?.hasInviteLink ?? false;
  bool get isFull => state.value?.isFull ?? false;
  bool get isArchived => state.value?.isArchived ?? false;
  bool get isMuted => state.value?.isMuted ?? false;
  bool get isPinned => state.value?.isPinned ?? false;

  @override
  void dispose() {
    _groupUpdateSubscription?.cancel();
    _messageSubscription?.cancel();
    _activityTimer?.cancel();
    super.dispose();
  }
}

// Providers
final groupProvider = StateNotifierProvider.autoDispose
    .family<GroupNotifier, AsyncValue<GroupState>, String>((ref, groupId) {
      final apiService = ref.watch(apiServiceProvider);
      final cacheService = CacheService();
      final chatSocketService = ref.watch(chatSocketServiceProvider);

      return GroupNotifier(
        groupId: groupId,
        apiService: apiService,
        cacheService: cacheService,
        chatSocketService: chatSocketService,
      );
    });

// Convenience providers
final groupDataProvider = Provider.family<GroupInfo?, String>((ref, groupId) {
  final groupState = ref.watch(groupProvider(groupId));
  return groupState.whenOrNull(data: (state) => state.group);
});

final groupLoadingProvider = Provider.family<bool, String>((ref, groupId) {
  final groupState = ref.watch(groupProvider(groupId));
  return groupState.whenOrNull(data: (state) => state.isLoading) ?? false;
});

final groupNameProvider = Provider.family<String, String>((ref, groupId) {
  final group = ref.watch(groupDataProvider(groupId));
  return group?.name ?? 'Group';
});

final groupTypeProvider = Provider.family<GroupType, String>((ref, groupId) {
  final group = ref.watch(groupDataProvider(groupId));
  return group?.type ?? GroupType.private;
});

final groupPrivacyProvider = Provider.family<GroupPrivacy, String>((
  ref,
  groupId,
) {
  final group = ref.watch(groupDataProvider(groupId));
  return group?.privacy ?? GroupPrivacy.closed;
});

final groupMemberCountProvider = Provider.family<int, String>((ref, groupId) {
  final group = ref.watch(groupDataProvider(groupId));
  return group?.memberCount ?? 0;
});

final groupOwnerIdProvider = Provider.family<String, String>((ref, groupId) {
  final group = ref.watch(groupDataProvider(groupId));
  return group?.ownerId ?? '';
});

final groupAdminIdsProvider = Provider.family<List<String>, String>((
  ref,
  groupId,
) {
  final group = ref.watch(groupDataProvider(groupId));
  return group?.adminIds ?? [];
});

final isGroupMutedProvider = Provider.family<bool, String>((ref, groupId) {
  final group = ref.watch(groupDataProvider(groupId));
  return group?.isMuted ?? false;
});

final isGroupPinnedProvider = Provider.family<bool, String>((ref, groupId) {
  final group = ref.watch(groupDataProvider(groupId));
  return group?.isPinned ?? false;
});

final isGroupArchivedProvider = Provider.family<bool, String>((ref, groupId) {
  final group = ref.watch(groupDataProvider(groupId));
  return group?.isArchived ?? false;
});

final groupSettingsProvider = Provider.family<GroupSettings, String>((
  ref,
  groupId,
) {
  final group = ref.watch(groupDataProvider(groupId));
  return group?.settings ?? GroupSettings();
});

final groupInviteLinkProvider = Provider.family<String?, String>((
  ref,
  groupId,
) {
  final group = ref.watch(groupDataProvider(groupId));
  return group?.inviteLink;
});

final hasGroupInviteLinkProvider = Provider.family<bool, String>((
  ref,
  groupId,
) {
  final group = ref.watch(groupDataProvider(groupId));
  return group?.hasInviteLink ?? false;
});

final isGroupFullProvider = Provider.family<bool, String>((ref, groupId) {
  final group = ref.watch(groupDataProvider(groupId));
  return group?.isFull ?? false;
});

final groupJoiningProvider = Provider.family<bool, String>((ref, groupId) {
  final groupState = ref.watch(groupProvider(groupId));
  return groupState.whenOrNull(data: (state) => state.isJoining) ?? false;
});

final groupLeavingProvider = Provider.family<bool, String>((ref, groupId) {
  final groupState = ref.watch(groupProvider(groupId));
  return groupState.whenOrNull(data: (state) => state.isLeaving) ?? false;
});

final groupUpdatingProvider = Provider.family<bool, String>((ref, groupId) {
  final groupState = ref.watch(groupProvider(groupId));
  return groupState.whenOrNull(data: (state) => state.isUpdating) ?? false;
});
