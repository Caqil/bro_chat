import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/dio_config.dart';
import '../../core/constants/api_constants.dart';
import '../../core/exceptions/network_exception.dart';
import '../storage/cache_service.dart';
import '../storage/secure_storage.dart';

class ApiService {
  static ApiService? _instance;
  final Dio _dio;
  final SecureStorage _storage;
  final CacheService _cacheService;

  ApiService._internal(this._dio, this._storage, this._cacheService);

  factory ApiService() {
    _instance ??= ApiService._internal(
      DioConfig.instance,
      SecureStorage(),
      CacheService(),
    );
    return _instance!;
  }

  // Authentication API
  Future<ApiResponse<AuthResponse>> register({
    required String name,
    required String phoneNumber,
    required String countryCode,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.authRegister,
        data: {
          'name': name,
          'phone_number': phoneNumber,
          'country_code': countryCode,
          'password': password,
        },
      );

      return ApiResponse.fromJson(
        response.data,
        (data) => AuthResponse.fromJson(data),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<AuthResponse>> verifyOTP({
    required String phoneNumber,
    required String countryCode,
    required String otp,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.authVerifyOTP,
        data: {
          'phone_number': phoneNumber,
          'country_code': countryCode,
          'otp': otp,
        },
      );

      return ApiResponse.fromJson(
        response.data,
        (data) => AuthResponse.fromJson(data),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<AuthResponse>> login({
    required String phoneNumber,
    required String countryCode,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.authLogin,
        data: {
          'phone_number': phoneNumber,
          'country_code': countryCode,
          'password': password,
        },
      );

      return ApiResponse.fromJson(
        response.data,
        (data) => AuthResponse.fromJson(data),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<AuthResponse>> refreshToken(String refreshToken) async {
    try {
      final response = await _dio.post(
        ApiConstants.authRefresh,
        data: {'refresh_token': refreshToken},
      );

      return ApiResponse.fromJson(
        response.data,
        (data) => AuthResponse.fromJson(data),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<void>> resendOTP({
    required String phoneNumber,
    required String countryCode,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.authResendOTP,
        data: {'phone_number': phoneNumber, 'country_code': countryCode},
      );

      return ApiResponse.fromJson(response.data, null);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<void>> logout() async {
    try {
      final response = await _dio.post(ApiConstants.authLogout);
      return ApiResponse.fromJson(response.data, null);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<void>> validateToken() async {
    try {
      final response = await _dio.get(ApiConstants.authValidate);
      return ApiResponse.fromJson(response.data, null);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Profile API
  Future<ApiResponse<UserModel>> getProfile() async {
    try {
      final response = await _dio.get(ApiConstants.authProfile);
      return ApiResponse.fromJson(
        response.data,
        (data) => UserModel.fromJson(data),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<UserModel>> updateProfile({
    String? name,
    String? email,
    String? username,
    String? bio,
    String? avatar,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (email != null) updateData['email'] = email;
      if (username != null) updateData['username'] = username;
      if (bio != null) updateData['bio'] = bio;
      if (avatar != null) updateData['avatar'] = avatar;

      final response = await _dio.put(
        ApiConstants.authProfile,
        data: updateData,
      );

      return ApiResponse.fromJson(
        response.data,
        (data) => UserModel.fromJson(data),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<void>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.put(
        ApiConstants.authChangePassword,
        data: {'old_password': oldPassword, 'new_password': newPassword},
      );

      return ApiResponse.fromJson(response.data, null);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Chat API
  Future<ApiResponse<ChatModel>> createChat({
    required String type,
    required List<String> participants,
    String? name,
    String? description,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.createChat,
        data: {
          'type': type,
          'participants': participants,
          if (name != null) 'name': name,
          if (description != null) 'description': description,
        },
      );

      return ApiResponse.fromJson(
        response.data,
        (data) => ChatModel.fromJson(data),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<List<ChatModel>>> getUserChats({
    int page = 1,
    int limit = 20,
    String? type,
    bool? archived,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (type != null) 'type': type,
        if (archived != null) 'archived': archived,
      };

      final response = await _dio.get(
        ApiConstants.getUserChats,
        queryParameters: queryParams,
      );

      return ApiResponse.fromJson(
        response.data,
        (data) =>
            (data as List).map((chat) => ChatModel.fromJson(chat)).toList(),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<ChatModel>> getChat(String chatId) async {
    try {
      final response = await _dio.get(ApiConstants.getChat(chatId));
      return ApiResponse.fromJson(
        response.data,
        (data) => ChatModel.fromJson(data),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<ChatModel>> updateChat(
    String chatId, {
    String? name,
    String? description,
    Map<String, dynamic>? settings,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (settings != null) updateData['settings'] = settings;

      final response = await _dio.put(
        ApiConstants.updateChat(chatId),
        data: updateData,
      );

      return ApiResponse.fromJson(
        response.data,
        (data) => ChatModel.fromJson(data),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<void>> deleteChat(String chatId) async {
    try {
      final response = await _dio.delete(ApiConstants.deleteChat(chatId));
      return ApiResponse.fromJson(response.data, null);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<void>> addParticipant(String chatId, String userId) async {
    try {
      final response = await _dio.post(
        ApiConstants.addParticipant(chatId),
        data: {'user_id': userId},
      );

      return ApiResponse.fromJson(response.data, null);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<void>> removeParticipant(
    String chatId,
    String userId,
  ) async {
    try {
      final response = await _dio.delete(
        ApiConstants.removeParticipant(chatId, userId),
      );

      return ApiResponse.fromJson(response.data, null);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<void>> archiveChat(String chatId, bool archive) async {
    try {
      final response = await _dio.put(
        '${ApiConstants.archiveChat(chatId)}?archive=$archive',
      );

      return ApiResponse.fromJson(response.data, null);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<void>> muteChat(
    String chatId, {
    required bool mute,
    DateTime? mutedUntil,
  }) async {
    try {
      final response = await _dio.put(
        ApiConstants.muteChat(chatId),
        data: {
          'mute': mute,
          if (mutedUntil != null) 'muted_until': mutedUntil.toIso8601String(),
        },
      );

      return ApiResponse.fromJson(response.data, null);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<void>> pinChat(String chatId, bool pin) async {
    try {
      final response = await _dio.put(
        '${ApiConstants.pinChat(chatId)}?pin=$pin',
      );

      return ApiResponse.fromJson(response.data, null);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<void>> markChatAsRead(String chatId) async {
    try {
      final response = await _dio.put(ApiConstants.markChatAsRead(chatId));
      return ApiResponse.fromJson(response.data, null);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Message API
  Future<ApiResponse<MessageModel>> sendMessage({
    required String chatId,
    required String type,
    required String content,
    String? replyToId,
    List<String>? mentions,
    Map<String, dynamic>? metadata,
    DateTime? scheduledAt,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.sendMessage,
        data: {
          'chat_id': chatId,
          'type': type,
          'content': content,
          if (replyToId != null) 'reply_to_id': replyToId,
          if (mentions != null) 'mentions': mentions,
          if (metadata != null) 'metadata': metadata,
          if (scheduledAt != null)
            'scheduled_at': scheduledAt.toIso8601String(),
        },
      );

      return ApiResponse.fromJson(
        response.data,
        (data) => MessageModel.fromJson(data),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<List<MessageModel>>> getMessages({
    required String chatId,
    int page = 1,
    int limit = 50,
    String? before,
    String? senderId,
    String? type,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'chat_id': chatId,
        'page': page,
        'limit': limit,
        if (before != null) 'before': before,
        if (senderId != null) 'sender_id': senderId,
        if (type != null) 'type': type,
        if (dateFrom != null) 'date_from': dateFrom.toIso8601String(),
        if (dateTo != null) 'date_to': dateTo.toIso8601String(),
      };

      final response = await _dio.get(
        ApiConstants.getMessages,
        queryParameters: queryParams,
      );

      return ApiResponse.fromJson(
        response.data,
        (data) => (data as List)
            .map((message) => MessageModel.fromJson(message))
            .toList(),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<MessageModel>> getMessage(String messageId) async {
    try {
      final response = await _dio.get(ApiConstants.getMessage(messageId));
      return ApiResponse.fromJson(
        response.data,
        (data) => MessageModel.fromJson(data),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<MessageModel>> updateMessage(
    String messageId, {
    required String content,
    String? reason,
  }) async {
    try {
      final response = await _dio.put(
        ApiConstants.updateMessage(messageId),
        data: {'content': content, if (reason != null) 'reason': reason},
      );

      return ApiResponse.fromJson(
        response.data,
        (data) => MessageModel.fromJson(data),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<void>> deleteMessage(
    String messageId, {
    bool forEveryone = false,
  }) async {
    try {
      final response = await _dio.delete(
        '${ApiConstants.deleteMessage(messageId)}?for_everyone=$forEveryone',
      );

      return ApiResponse.fromJson(response.data, null);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<void>> addReaction(String messageId, String emoji) async {
    try {
      final response = await _dio.post(
        ApiConstants.addReaction(messageId),
        data: {'emoji': emoji},
      );

      return ApiResponse.fromJson(response.data, null);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<void>> removeReaction(String messageId) async {
    try {
      final response = await _dio.delete(
        ApiConstants.removeReaction(messageId),
      );
      return ApiResponse.fromJson(response.data, null);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<void>> markMessageAsRead(String messageId) async {
    try {
      final response = await _dio.put(
        ApiConstants.markMessageAsRead(messageId),
      );
      return ApiResponse.fromJson(response.data, null);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<void>> forwardMessage(
    String messageId,
    String toChatId,
  ) async {
    try {
      final response = await _dio.post(
        ApiConstants.forwardMessage(messageId),
        data: {'to_chat_id': toChatId},
      );

      return ApiResponse.fromJson(response.data, null);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<void>> markMultipleAsRead(List<String> messageIds) async {
    try {
      final response = await _dio.put(
        ApiConstants.markMultipleAsRead,
        data: {'message_ids': messageIds},
      );

      return ApiResponse.fromJson(response.data, null);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<void>> bulkDeleteMessages(
    List<String> messageIds, {
    bool forEveryone = false,
  }) async {
    try {
      final response = await _dio.delete(
        ApiConstants.bulkDeleteMessages,
        data: {'message_ids': messageIds, 'for_everyone': forEveryone},
      );

      return ApiResponse.fromJson(response.data, null);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<List<MessageModel>>> searchMessages({
    String? chatId,
    required String query,
    String? type,
    String? senderId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'q': query,
        'page': page,
        'limit': limit,
        if (chatId != null) 'chat_id': chatId,
        if (type != null) 'type': type,
        if (senderId != null) 'sender_id': senderId,
      };

      final response = await _dio.get(
        ApiConstants.searchMessages,
        queryParameters: queryParams,
      );

      return ApiResponse.fromJson(
        response.data,
        (data) => (data as List)
            .map((message) => MessageModel.fromJson(message))
            .toList(),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Group API
  Future<ApiResponse<GroupModel>> createGroup({
    required String name,
    String? description,
    bool isPublic = false,
    List<String>? members,
    String? avatar,
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
        },
      );

      return ApiResponse.fromJson(
        response.data,
        (data) => GroupModel.fromJson(data),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<GroupModel>> getGroup(String groupId) async {
    try {
      final response = await _dio.get(ApiConstants.getGroup(groupId));
      return ApiResponse.fromJson(
        response.data,
        (data) => GroupModel.fromJson(data),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<GroupModel>> updateGroup(
    String groupId, {
    String? name,
    String? description,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;

      final response = await _dio.put(
        ApiConstants.updateGroup(groupId),
        data: updateData,
      );

      return ApiResponse.fromJson(
        response.data,
        (data) => GroupModel.fromJson(data),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<void>> deleteGroup(String groupId) async {
    try {
      final response = await _dio.delete(ApiConstants.deleteGroup(groupId));
      return ApiResponse.fromJson(response.data, null);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<List<GroupMemberModel>>> getGroupMembers(
    String groupId,
  ) async {
    try {
      final response = await _dio.get(ApiConstants.getGroupMembers(groupId));
      return ApiResponse.fromJson(
        response.data,
        (data) => (data as List)
            .map((member) => GroupMemberModel.fromJson(member))
            .toList(),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

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
    } catch (e) {
      throw _handleError(e);
    }
  }

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
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<void>> removeGroupMember(
    String groupId,
    String userId,
  ) async {
    try {
      final response = await _dio.delete(
        ApiConstants.removeGroupMember(groupId, userId),
      );

      return ApiResponse.fromJson(response.data, null);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<void>> leaveGroup(String groupId) async {
    try {
      final response = await _dio.post(ApiConstants.leaveGroup(groupId));
      return ApiResponse.fromJson(response.data, null);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<List<GroupModel>>> getMyGroups() async {
    try {
      final response = await _dio.get(ApiConstants.getMyGroups);
      return ApiResponse.fromJson(
        response.data,
        (data) =>
            (data as List).map((group) => GroupModel.fromJson(group)).toList(),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

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
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<void>> unmuteMember(String groupId, String userId) async {
    try {
      final response = await _dio.delete(
        ApiConstants.unmuteMember(groupId, userId),
      );

      return ApiResponse.fromJson(response.data, null);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<void>> banMember(
    String groupId,
    String userId, {
    String? reason,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.banMember(groupId, userId),
        data: {if (reason != null) 'reason': reason},
      );

      return ApiResponse.fromJson(response.data, null);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<void>> unbanMember(String groupId, String userId) async {
    try {
      final response = await _dio.delete(
        ApiConstants.unbanMember(groupId, userId),
      );

      return ApiResponse.fromJson(response.data, null);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<List<GroupModel>>> searchGroups({
    required String query,
    bool? public,
    int limit = 10,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'q': query,
        'limit': limit,
        if (public != null) 'public': public,
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
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<List<GroupModel>>> getPublicGroups({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'limit': limit};

      final response = await _dio.get(
        ApiConstants.getPublicGroups,
        queryParameters: queryParams,
      );

      return ApiResponse.fromJson(
        response.data,
        (data) =>
            (data as List).map((group) => GroupModel.fromJson(group)).toList(),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Call API
  Future<ApiResponse<CallModel>> initiateCall({
    required List<String> participantIds,
    required String chatId,
    required String type,
    bool videoEnabled = false,
    bool audioEnabled = true,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.initiateCall,
        data: {
          'participant_ids': participantIds,
          'chat_id': chatId,
          'type': type,
          'video_enabled': videoEnabled,
          'audio_enabled': audioEnabled,
        },
      );

      return ApiResponse.fromJson(
        response.data,
        (data) => CallModel.fromJson(data),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<void>> answerCall(
    String callId, {
    required bool accept,
    Map<String, dynamic>? deviceInfo,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.answerCall(callId),
        data: {
          'accept': accept,
          if (deviceInfo != null) 'device_info': deviceInfo,
        },
      );

      return ApiResponse.fromJson(response.data, null);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<void>> endCall(
    String callId, {
    String reason = 'normal',
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.endCall(callId),
        data: {'reason': reason},
      );

      return ApiResponse.fromJson(response.data, null);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<void>> joinCall(
    String callId, {
    Map<String, dynamic>? deviceInfo,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.joinCall(callId),
        data: {if (deviceInfo != null) 'device_info': deviceInfo},
      );

      return ApiResponse.fromJson(response.data, null);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<void>> leaveCall(String callId) async {
    try {
      final response = await _dio.post(ApiConstants.leaveCall(callId));
      return ApiResponse.fromJson(response.data, null);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<CallModel>> getCall(String callId) async {
    try {
      final response = await _dio.get(ApiConstants.getCall(callId));
      return ApiResponse.fromJson(
        response.data,
        (data) => CallModel.fromJson(data),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<List<CallModel>>> getCallHistory({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'limit': limit};

      final response = await _dio.get(
        ApiConstants.getCallHistory,
        queryParameters: queryParams,
      );

      return ApiResponse.fromJson(
        response.data,
        (data) =>
            (data as List).map((call) => CallModel.fromJson(call)).toList(),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<void>> updateMediaState(
    String callId, {
    bool? videoEnabled,
    bool? audioEnabled,
    bool? screenSharing,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (videoEnabled != null) updateData['video_enabled'] = videoEnabled;
      if (audioEnabled != null) updateData['audio_enabled'] = audioEnabled;
      if (screenSharing != null) updateData['screen_sharing'] = screenSharing;

      final response = await _dio.put(
        ApiConstants.updateMediaState(callId),
        data: updateData,
      );

      return ApiResponse.fromJson(response.data, null);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<void>> updateQualityMetrics(
    String callId, {
    required double qualityScore,
    required double rtt,
    required double jitter,
    required double packetLoss,
  }) async {
    try {
      final response = await _dio.put(
        ApiConstants.updateQualityMetrics(callId),
        data: {
          'quality_score': qualityScore,
          'rtt': rtt,
          'jitter': jitter,
          'packet_loss': packetLoss,
        },
      );

      return ApiResponse.fromJson(response.data, null);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // File API
  Future<ApiResponse<FileModel>> uploadFile({
    required File file,
    required String purpose,
    String? chatId,
    bool public = false,
    Function(int, int)? onProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path),
        'purpose': purpose,
        'public': public,
        if (chatId != null) 'chat_id': chatId,
      });

      final response = await _dio.post(
        ApiConstants.uploadFile,
        data: formData,
        onSendProgress: onProgress,
      );

      return ApiResponse.fromJson(
        response.data,
        (data) => FileModel.fromJson(data),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Uint8List> downloadFile(String fileId) async {
    try {
      final response = await _dio.get(
        ApiConstants.downloadFile(fileId),
        options: Options(responseType: ResponseType.bytes),
      );

      return Uint8List.fromList(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<FileModel>> getFileInfo(String fileId) async {
    try {
      final response = await _dio.get(ApiConstants.getFileInfo(fileId));
      return ApiResponse.fromJson(
        response.data,
        (data) => FileModel.fromJson(data),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Uint8List> getFileThumbnail(
    String fileId, {
    String size = 'medium',
  }) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.getFileThumbnail(fileId)}?size=$size',
        options: Options(responseType: ResponseType.bytes),
      );

      return Uint8List.fromList(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<void>> deleteFile(String fileId) async {
    try {
      final response = await _dio.delete(ApiConstants.deleteFile(fileId));
      return ApiResponse.fromJson(response.data, null);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<List<FileModel>>> getUserFiles({
    String? purpose,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (purpose != null) 'purpose': purpose,
      };

      final response = await _dio.get(
        ApiConstants.getUserFiles,
        queryParameters: queryParams,
      );

      return ApiResponse.fromJson(
        response.data,
        (data) =>
            (data as List).map((file) => FileModel.fromJson(file)).toList(),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<List<FileModel>>> searchFiles({
    required String query,
    String? type,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'q': query,
        if (type != null) 'type': type,
      };

      final response = await _dio.get(
        ApiConstants.searchFiles,
        queryParameters: queryParams,
      );

      return ApiResponse.fromJson(
        response.data,
        (data) =>
            (data as List).map((file) => FileModel.fromJson(file)).toList(),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<List<FileModel>>> getChatFiles(
    String chatId, {
    String? type,
  }) async {
    try {
      final queryParams = <String, dynamic>{if (type != null) 'type': type};

      final response = await _dio.get(
        ApiConstants.getChatFiles(chatId),
        queryParameters: queryParams,
      );

      return ApiResponse.fromJson(
        response.data,
        (data) =>
            (data as List).map((file) => FileModel.fromJson(file)).toList(),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Device Management
  Future<ApiResponse<List<DeviceModel>>> getDevices() async {
    try {
      final response = await _dio.get(ApiConstants.authDevices);
      return ApiResponse.fromJson(
        response.data,
        (data) => (data as List)
            .map((device) => DeviceModel.fromJson(device))
            .toList(),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Statistics
  Future<ApiResponse<Map<String, dynamic>>> getMessageStats() async {
    try {
      final response = await _dio.get(ApiConstants.getMessageStats);
      return ApiResponse.fromJson(response.data, (data) => data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> getChatStats() async {
    try {
      final response = await _dio.get(ApiConstants.getChatStats);
      return ApiResponse.fromJson(response.data, (data) => data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> getCallStats() async {
    try {
      final response = await _dio.get(ApiConstants.getCallStats);
      return ApiResponse.fromJson(response.data, (data) => data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> getFileStats() async {
    try {
      final response = await _dio.get(ApiConstants.getFileStats);
      return ApiResponse.fromJson(response.data, (data) => data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Error handling
  Exception _handleError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return NetworkException.timeout();

        case DioExceptionType.connectionError:
          return NetworkException.noConnection();

        case DioExceptionType.badResponse:
          return _handleHttpError(error);

        case DioExceptionType.cancel:
          return NetworkException.requestCancelled();

        default:
          return NetworkException.unknown(error.message ?? 'Unknown error');
      }
    }

    return NetworkException.unknown(error.toString());
  }

  NetworkException _handleHttpError(DioException error) {
    final statusCode = error.response?.statusCode ?? 0;
    final data = error.response?.data;

    String message = 'An error occurred';
    String? errorCode;

    if (data is Map<String, dynamic>) {
      message = data['message'] ?? data['error'] ?? message;
      errorCode = data['code']?.toString();
    }

    return NetworkException.fromStatusCode(
      statusCode,
      message,
      errorCode: errorCode,
      response: data,
    );
  }
}

// Generic API Response model
class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final Map<String, dynamic>? meta;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.meta,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T? Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'],
      meta: json['meta'],
    );
  }
}

// Riverpod provider
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

// Data models (simplified - you would have these defined elsewhere)
class AuthResponse {
  final UserModel user;
  final String accessToken;
  final String refreshToken;

  AuthResponse({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: UserModel.fromJson(json['user']),
      accessToken: json['access_token'],
      refreshToken: json['refresh_token'],
    );
  }
}

class UserModel {
  final String id;
  final String name;
  final String phoneNumber;
  final String? email;
  final String? username;
  final String? bio;
  final String? avatar;
  final bool isOnline;
  final DateTime? lastSeen;

  UserModel({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.email,
    this.username,
    this.bio,
    this.avatar,
    this.isOnline = false,
    this.lastSeen,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      phoneNumber: json['phone_number'],
      email: json['email'],
      username: json['username'],
      bio: json['bio'],
      avatar: json['avatar'],
      isOnline: json['is_online'] ?? false,
      lastSeen: json['last_seen'] != null
          ? DateTime.parse(json['last_seen'])
          : null,
    );
  }
}

class ChatModel {
  final String id;
  final String type;
  final String? name;
  final String? description;
  final List<String> participants;
  final DateTime createdAt;
  final DateTime? lastMessageAt;

  ChatModel({
    required this.id,
    required this.type,
    this.name,
    this.description,
    required this.participants,
    required this.createdAt,
    this.lastMessageAt,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id'],
      type: json['type'],
      name: json['name'],
      description: json['description'],
      participants: List<String>.from(json['participants'] ?? []),
      createdAt: DateTime.parse(json['created_at']),
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'])
          : null,
    );
  }
}

class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String type;
  final String content;
  final DateTime createdAt;
  final DateTime? editedAt;
  final String? replyToId;
  final List<String> mentions;
  final Map<String, dynamic>? metadata;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.type,
    required this.content,
    required this.createdAt,
    this.editedAt,
    this.replyToId,
    this.mentions = const [],
    this.metadata,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      chatId: json['chat_id'],
      senderId: json['sender_id'],
      type: json['type'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      editedAt: json['edited_at'] != null
          ? DateTime.parse(json['edited_at'])
          : null,
      replyToId: json['reply_to_id'],
      mentions: List<String>.from(json['mentions'] ?? []),
      metadata: json['metadata'],
    );
  }
}

class GroupModel {
  final String id;
  final String name;
  final String? description;
  final bool isPublic;
  final String? avatar;
  final DateTime createdAt;

  GroupModel({
    required this.id,
    required this.name,
    this.description,
    required this.isPublic,
    this.avatar,
    required this.createdAt,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      isPublic: json['is_public'] ?? false,
      avatar: json['avatar'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class GroupMemberModel {
  final String userId;
  final String role;
  final DateTime joinedAt;

  GroupMemberModel({
    required this.userId,
    required this.role,
    required this.joinedAt,
  });

  factory GroupMemberModel.fromJson(Map<String, dynamic> json) {
    return GroupMemberModel(
      userId: json['user_id'],
      role: json['role'],
      joinedAt: DateTime.parse(json['joined_at']),
    );
  }
}

class CallModel {
  final String id;
  final String chatId;
  final String type;
  final String status;
  final List<String> participants;
  final DateTime createdAt;
  final DateTime? endedAt;

  CallModel({
    required this.id,
    required this.chatId,
    required this.type,
    required this.status,
    required this.participants,
    required this.createdAt,
    this.endedAt,
  });

  factory CallModel.fromJson(Map<String, dynamic> json) {
    return CallModel(
      id: json['id'],
      chatId: json['chat_id'],
      type: json['type'],
      status: json['status'],
      participants: List<String>.from(json['participants'] ?? []),
      createdAt: DateTime.parse(json['created_at']),
      endedAt: json['ended_at'] != null
          ? DateTime.parse(json['ended_at'])
          : null,
    );
  }
}

class FileModel {
  final String id;
  final String name;
  final String mimeType;
  final int size;
  final String purpose;
  final String url;
  final DateTime createdAt;

  FileModel({
    required this.id,
    required this.name,
    required this.mimeType,
    required this.size,
    required this.purpose,
    required this.url,
    required this.createdAt,
  });

  factory FileModel.fromJson(Map<String, dynamic> json) {
    return FileModel(
      id: json['id'],
      name: json['name'],
      mimeType: json['mime_type'],
      size: json['size'],
      purpose: json['purpose'],
      url: json['url'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class DeviceModel {
  final String id;
  final String name;
  final String platform;
  final DateTime lastSeen;
  final bool isActive;

  DeviceModel({
    required this.id,
    required this.name,
    required this.platform,
    required this.lastSeen,
    required this.isActive,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: json['id'],
      name: json['name'],
      platform: json['platform'],
      lastSeen: DateTime.parse(json['last_seen']),
      isActive: json['is_active'] ?? false,
    );
  }
}
