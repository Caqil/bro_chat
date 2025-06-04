import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/dio_config.dart';
import '../../core/constants/api_constants.dart';
import '../../core/exceptions/network_exception.dart';
import '../../models/group/group_member.dart';
import '../../models/group/group_model.dart';
import '../../models/common/api_response.dart';

class GroupAPI {
  final Dio _dio;

  GroupAPI(this._dio);

  /// Create a new group
  Future<ApiResponse<GroupModel>> createGroup({
    required String name,
    String? description,
    bool isPublic = false,
    List<String>? members,
    String? avatar,
    Map<String, dynamic>? settings,
    Map<String, dynamic>? permissions,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.createGroup,
        data: {
          'name': name,
          if (description != null) 'description': description,
          'is_public': isPublic,
          if (members != null) 'members': members,
          if (avatar != null) 'avatar': avatar,
          if (settings != null) 'settings': settings,
          if (permissions != null) 'permissions': permissions,
        },
      );

      return ApiResponse.fromJson(
        response.data,
        (data) => GroupModel.fromJson(data),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get group details
  Future<ApiResponse<GroupModel>> getGroup(String groupId) async {
    try {
      final response = await _dio.get(ApiConstants.getGroup(groupId));
      return ApiResponse.fromJson(
        response.data,
        (data) => GroupModel.fromJson(data),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Update group details
  Future<ApiResponse<GroupModel>> updateGroup(
    String groupId, {
    String? name,
    String? description,
    String? avatar,
    bool? isPublic,
    Map<String, dynamic>? settings,
    Map<String, dynamic>? permissions,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (avatar != null) updateData['avatar'] = avatar;
      if (isPublic != null) updateData['is_public'] = isPublic;
      if (settings != null) updateData['settings'] = settings;
      if (permissions != null) updateData['permissions'] = permissions;

      final response = await _dio.put(
        ApiConstants.updateGroup(groupId),
        data: updateData,
      );

      return ApiResponse.fromJson(
        response.data,
        (data) => GroupModel.fromJson(data),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Delete group
  Future<ApiResponse<void>> deleteGroup(String groupId) async {
    try {
      final response = await _dio.delete(ApiConstants.deleteGroup(groupId));
      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get group members
  Future<ApiResponse<List<GroupMember>>> getGroupMembers(
    String groupId, {
    String? role,
    String? status,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (role != null) 'role': role,
        if (status != null) 'status': status,
      };

      final response = await _dio.get(
        ApiConstants.getGroupMembers(groupId),
        queryParameters: queryParams,
      );

      return ApiResponse.fromJson(
        response.data,
        (data) => (data as List)
            .map((member) => GroupMember.fromJson(member))
            .toList(),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Add member to group
  Future<ApiResponse<void>> addGroupMember(
    String groupId,
    String userId, {
    String role = 'member',
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.addGroupMember(groupId),
        data: {'user_id': userId, 'role': role},
      );

      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Bulk add members to group
  Future<ApiResponse<BulkMemberResult>> addGroupMembers(
    String groupId,
    List<String> userIds, {
    String role = 'member',
  }) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.addGroupMember(groupId)}/bulk',
        data: {'user_ids': userIds, 'role': role},
      );

      return ApiResponse.fromJson(
        response.data,
        (data) => BulkMemberResult.fromJson(data),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Update member role
  Future<ApiResponse<void>> updateMemberRole(
    String groupId,
    String userId,
    String role,
  ) async {
    try {
      final response = await _dio.put(
        ApiConstants.updateMemberRole(groupId, userId),
        data: {'role': role},
      );

      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Remove member from group
  Future<ApiResponse<void>> removeGroupMember(
    String groupId,
    String userId,
  ) async {
    try {
      final response = await _dio.delete(
        ApiConstants.removeGroupMember(groupId, userId),
      );

      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Leave group
  Future<ApiResponse<void>> leaveGroup(String groupId) async {
    try {
      final response = await _dio.post(ApiConstants.leaveGroup(groupId));
      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get user's groups
  Future<ApiResponse<List<GroupModel>>> getMyGroups({
    String? role,
    bool? isPublic,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (role != null) 'role': role,
        if (isPublic != null) 'is_public': isPublic,
      };

      final response = await _dio.get(
        ApiConstants.getMyGroups,
        queryParameters: queryParams,
      );

      return ApiResponse.fromJson(
        response.data,
        (data) =>
            (data as List).map((group) => GroupModel.fromJson(group)).toList(),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Mute member
  Future<ApiResponse<void>> muteMember(
    String groupId,
    String userId, {
    String duration = '24h',
    String? reason,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.muteMember(groupId, userId),
        data: {'duration': duration, if (reason != null) 'reason': reason},
      );

      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Unmute member
  Future<ApiResponse<void>> unmuteMember(String groupId, String userId) async {
    try {
      final response = await _dio.delete(
        ApiConstants.unmuteMember(groupId, userId),
      );

      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Ban member
  Future<ApiResponse<void>> banMember(
    String groupId,
    String userId, {
    String? reason,
    DateTime? until,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.banMember(groupId, userId),
        data: {
          if (reason != null) 'reason': reason,
          if (until != null) 'until': until.toIso8601String(),
        },
      );

      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Unban member
  Future<ApiResponse<void>> unbanMember(String groupId, String userId) async {
    try {
      final response = await _dio.delete(
        ApiConstants.unbanMember(groupId, userId),
      );

      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get banned members
  Future<ApiResponse<List<BannedMember>>> getBannedMembers(
    String groupId,
  ) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.getGroup(groupId)}/banned',
      );
      return ApiResponse.fromJson(
        response.data,
        (data) => (data as List)
            .map((member) => BannedMember.fromJson(member))
            .toList(),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get muted members
  Future<ApiResponse<List<MutedMember>>> getMutedMembers(String groupId) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.getGroup(groupId)}/muted',
      );
      return ApiResponse.fromJson(
        response.data,
        (data) => (data as List)
            .map((member) => MutedMember.fromJson(member))
            .toList(),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get join requests
  Future<ApiResponse<List<JoinRequest>>> getJoinRequests(
    String groupId, {
    String? status = 'pending',
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (status != null) 'status': status,
      };

      final response = await _dio.get(
        '${ApiConstants.getGroup(groupId)}/requests',
        queryParameters: queryParams,
      );

      return ApiResponse.fromJson(
        response.data,
        (data) => (data as List)
            .map((request) => JoinRequest.fromJson(request))
            .toList(),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Request to join group
  Future<ApiResponse<void>> requestToJoinGroup(
    String groupId, {
    String? message,
  }) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.getGroup(groupId)}/join',
        data: {if (message != null) 'message': message},
      );

      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Approve join request
  Future<ApiResponse<void>> approveJoinRequest(
    String groupId,
    String userId,
  ) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.getGroup(groupId)}/requests/$userId/approve',
      );

      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Reject join request
  Future<ApiResponse<void>> rejectJoinRequest(
    String groupId,
    String userId, {
    String? reason,
  }) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.getGroup(groupId)}/requests/$userId/reject',
        data: {if (reason != null) 'reason': reason},
      );

      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Search groups
  Future<ApiResponse<List<GroupModel>>> searchGroups({
    required String query,
    bool? public,
    String? category,
    int limit = 10,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'q': query,
        'limit': limit,
        if (public != null) 'public': public,
        if (category != null) 'category': category,
      };

      final response = await _dio.get(
        ApiConstants.searchGroups,
        queryParameters: queryParams,
      );

      return ApiResponse.fromJson(
        response.data,
        (data) =>
            (data as List).map((group) => GroupModel.fromJson(group)).toList(),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get public groups
  Future<ApiResponse<List<GroupModel>>> getPublicGroups({
    int page = 1,
    int limit = 20,
    String? category,
    String? sortBy = 'members',
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        'sort_by': sortBy,
        if (category != null) 'category': category,
      };

      final response = await _dio.get(
        ApiConstants.getPublicGroups,
        queryParameters: queryParams,
      );

      return ApiResponse.fromJson(
        response.data,
        (data) =>
            (data as List).map((group) => GroupModel.fromJson(group)).toList(),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get group statistics
  Future<ApiResponse<GroupStats>> getGroupStats(String groupId) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.getGroup(groupId)}/stats',
      );
      return ApiResponse.fromJson(
        response.data,
        (data) => GroupStats.fromJson(data),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Generate invite link
  Future<ApiResponse<GroupInvite>> generateInviteLink(
    String groupId, {
    String? expiresIn = '7d',
    int? maxUses = 10,
    String? role = 'member',
  }) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.getGroup(groupId)}/invite-link',
        data: {
          if (expiresIn != null) 'expires_in': expiresIn,
          if (maxUses != null) 'max_uses': maxUses,
          'role': role,
        },
      );

      return ApiResponse.fromJson(
        response.data,
        (data) => GroupInvite.fromJson(data),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get group invites
  Future<ApiResponse<List<GroupInvite>>> getGroupInvites(String groupId) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.getGroup(groupId)}/invites',
      );
      return ApiResponse.fromJson(
        response.data,
        (data) => (data as List)
            .map((invite) => GroupInvite.fromJson(invite))
            .toList(),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Revoke invite link
  Future<ApiResponse<void>> revokeInviteLink(
    String groupId,
    String inviteId,
  ) async {
    try {
      final response = await _dio.delete(
        '${ApiConstants.getGroup(groupId)}/invites/$inviteId',
      );

      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Join group by invite code
  Future<ApiResponse<void>> joinByInviteCode(String inviteCode) async {
    try {
      final response = await _dio.get('/groups/join/$inviteCode');
      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Transfer group ownership
  Future<ApiResponse<void>> transferOwnership(
    String groupId,
    String newOwnerId,
  ) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.getGroup(groupId)}/transfer',
        data: {'new_owner_id': newOwnerId},
      );

      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Set group permissions
  Future<ApiResponse<void>> setGroupPermissions(
    String groupId,
    Map<String, dynamic> permissions,
  ) async {
    try {
      final response = await _dio.put(
        '${ApiConstants.getGroup(groupId)}/permissions',
        data: {'permissions': permissions},
      );

      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get group permissions
  Future<ApiResponse<Map<String, dynamic>>> getGroupPermissions(
    String groupId,
  ) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.getGroup(groupId)}/permissions',
      );
      return ApiResponse.fromJson(response.data, (data) => data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Set member permissions
  Future<ApiResponse<void>> setMemberPermissions(
    String groupId,
    String userId,
    Map<String, dynamic> permissions,
  ) async {
    try {
      final response = await _dio.put(
        '${ApiConstants.getGroup(groupId)}/members/$userId/permissions',
        data: {'permissions': permissions},
      );

      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get member permissions
  Future<ApiResponse<Map<String, dynamic>>> getMemberPermissions(
    String groupId,
    String userId,
  ) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.getGroup(groupId)}/members/$userId/permissions',
      );

      return ApiResponse.fromJson(response.data, (data) => data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Report group
  Future<ApiResponse<void>> reportGroup(
    String groupId, {
    required String reason,
    String? description,
    List<String>? evidenceFileIds,
  }) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.getGroup(groupId)}/report',
        data: {
          'reason': reason,
          if (description != null) 'description': description,
          if (evidenceFileIds != null) 'evidence_file_ids': evidenceFileIds,
        },
      );

      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get group categories
  Future<ApiResponse<List<GroupCategory>>> getGroupCategories() async {
    try {
      final response = await _dio.get('/groups/categories');
      return ApiResponse.fromJson(
        response.data,
        (data) => (data as List)
            .map((category) => GroupCategory.fromJson(category))
            .toList(),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Archive group
  Future<ApiResponse<void>> archiveGroup(String groupId) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.getGroup(groupId)}/archive',
      );
      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Unarchive group
  Future<ApiResponse<void>> unarchiveGroup(String groupId) async {
    try {
      final response = await _dio.delete(
        '${ApiConstants.getGroup(groupId)}/archive',
      );
      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException error) {
    return NetworkException.fromStatusCode(
      error.response?.statusCode ?? 0,
      error.response?.data?['message'] ?? 'Unknown error',
      response: error.response?.data,
    );
  }
}

// Data models
class BulkMemberResult {
  final int successful;
  final int failed;
  final List<String> failedUserIds;
  final List<String> errors;

  BulkMemberResult({
    required this.successful,
    required this.failed,
    required this.failedUserIds,
    required this.errors,
  });

  factory BulkMemberResult.fromJson(Map<String, dynamic> json) {
    return BulkMemberResult(
      successful: json['successful'],
      failed: json['failed'],
      failedUserIds: List<String>.from(json['failed_user_ids'] ?? []),
      errors: List<String>.from(json['errors'] ?? []),
    );
  }
}

class BannedMember {
  final String userId;
  final String name;
  final String? avatar;
  final String reason;
  final String bannedBy;
  final DateTime bannedAt;
  final DateTime? until;

  BannedMember({
    required this.userId,
    required this.name,
    this.avatar,
    required this.reason,
    required this.bannedBy,
    required this.bannedAt,
    this.until,
  });

  factory BannedMember.fromJson(Map<String, dynamic> json) {
    return BannedMember(
      userId: json['user_id'],
      name: json['name'],
      avatar: json['avatar'],
      reason: json['reason'],
      bannedBy: json['banned_by'],
      bannedAt: DateTime.parse(json['banned_at']),
      until: json['until'] != null ? DateTime.parse(json['until']) : null,
    );
  }
}

class MutedMember {
  final String userId;
  final String name;
  final String? avatar;
  final String reason;
  final String mutedBy;
  final DateTime mutedAt;
  final DateTime until;

  MutedMember({
    required this.userId,
    required this.name,
    this.avatar,
    required this.reason,
    required this.mutedBy,
    required this.mutedAt,
    required this.until,
  });

  factory MutedMember.fromJson(Map<String, dynamic> json) {
    return MutedMember(
      userId: json['user_id'],
      name: json['name'],
      avatar: json['avatar'],
      reason: json['reason'],
      mutedBy: json['muted_by'],
      mutedAt: DateTime.parse(json['muted_at']),
      until: DateTime.parse(json['until']),
    );
  }
}

class JoinRequest {
  final String id;
  final String userId;
  final String name;
  final String? avatar;
  final String? message;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime requestedAt;
  final String? processedBy;
  final DateTime? processedAt;

  JoinRequest({
    required this.id,
    required this.userId,
    required this.name,
    this.avatar,
    this.message,
    required this.status,
    required this.requestedAt,
    this.processedBy,
    this.processedAt,
  });

  factory JoinRequest.fromJson(Map<String, dynamic> json) {
    return JoinRequest(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      avatar: json['avatar'],
      message: json['message'],
      status: json['status'],
      requestedAt: DateTime.parse(json['requested_at']),
      processedBy: json['processed_by'],
      processedAt: json['processed_at'] != null
          ? DateTime.parse(json['processed_at'])
          : null,
    );
  }
}

class GroupStats {
  final String groupId;
  final int totalMembers;
  final int totalMessages;
  final int totalMedia;
  final int activeMembersToday;
  final int activeMembersWeek;
  final DateTime createdAt;
  final DateTime? lastActivityAt;
  final Map<String, int> membersByRole;
  final Map<String, int> messagesByType;

  GroupStats({
    required this.groupId,
    required this.totalMembers,
    required this.totalMessages,
    required this.totalMedia,
    required this.activeMembersToday,
    required this.activeMembersWeek,
    required this.createdAt,
    this.lastActivityAt,
    required this.membersByRole,
    required this.messagesByType,
  });

  factory GroupStats.fromJson(Map<String, dynamic> json) {
    return GroupStats(
      groupId: json['group_id'],
      totalMembers: json['total_members'],
      totalMessages: json['total_messages'],
      totalMedia: json['total_media'],
      activeMembersToday: json['active_members_today'],
      activeMembersWeek: json['active_members_week'],
      createdAt: DateTime.parse(json['created_at']),
      lastActivityAt: json['last_activity_at'] != null
          ? DateTime.parse(json['last_activity_at'])
          : null,
      membersByRole: Map<String, int>.from(json['members_by_role'] ?? {}),
      messagesByType: Map<String, int>.from(json['messages_by_type'] ?? {}),
    );
  }
}

class GroupInvite {
  final String id;
  final String groupId;
  final String inviteCode;
  final String inviteUrl;
  final String role;
  final int maxUses;
  final int usedCount;
  final DateTime? expiresAt;
  final String createdBy;
  final DateTime createdAt;
  final bool isActive;

  GroupInvite({
    required this.id,
    required this.groupId,
    required this.inviteCode,
    required this.inviteUrl,
    required this.role,
    required this.maxUses,
    required this.usedCount,
    this.expiresAt,
    required this.createdBy,
    required this.createdAt,
    required this.isActive,
  });

  factory GroupInvite.fromJson(Map<String, dynamic> json) {
    return GroupInvite(
      id: json['id'],
      groupId: json['group_id'],
      inviteCode: json['invite_code'],
      inviteUrl: json['invite_url'],
      role: json['role'],
      maxUses: json['max_uses'],
      usedCount: json['used_count'],
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : null,
      createdBy: json['created_by'],
      createdAt: DateTime.parse(json['created_at']),
      isActive: json['is_active'] ?? true,
    );
  }
}

class GroupCategory {
  final String id;
  final String name;
  final String description;
  final String icon;
  final int groupCount;

  GroupCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.groupCount,
  });

  factory GroupCategory.fromJson(Map<String, dynamic> json) {
    return GroupCategory(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      icon: json['icon'],
      groupCount: json['group_count'],
    );
  }
}

// Riverpod provider
final groupAPIProvider = Provider<GroupAPI>((ref) {
  final dio = ref.watch(dioProvider);
  return GroupAPI(dio);
});
