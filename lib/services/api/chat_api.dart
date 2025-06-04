import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/dio_config.dart';
import '../../core/constants/api_constants.dart';
import '../../core/exceptions/network_exception.dart';
import '../../models/chat/chat_model.dart';
import '../../models/common/api_response.dart';

class ChatAPI {
  final Dio _dio;

  ChatAPI(this._dio);

  /// Create a new chat
  Future<ApiResponse<ChatModel>> createChat({
    required String type,
    required List<String> participants,
    String? name,
    String? description,
    String? avatar,
    Map<String, dynamic>? settings,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.createChat,
        data: {
          'type': type,
          'participants': participants,
          if (name != null) 'name': name,
          if (description != null) 'description': description,
          if (avatar != null) 'avatar': avatar,
          if (settings != null) 'settings': settings,
        },
      );

      return ApiResponse.fromJson(
        response.data,
        (data) => ChatModel.fromJson(data),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get user's chat list
  Future<ApiResponse<List<ChatModel>>> getUserChats({
    int page = 1,
    int limit = 20,
    String? type,
    bool? archived,
    bool? muted,
    bool? pinned,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (type != null) 'type': type,
        if (archived != null) 'archived': archived,
        if (muted != null) 'muted': muted,
        if (pinned != null) 'pinned': pinned,
        if (search != null) 'search': search,
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
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get chat details by ID
  Future<ApiResponse<ChatModel>> getChat(String chatId) async {
    try {
      final response = await _dio.get(ApiConstants.getChat(chatId));
      return ApiResponse.fromJson(
        response.data,
        (data) => ChatModel.fromJson(data),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Update chat details
  Future<ApiResponse<ChatModel>> updateChat(
    String chatId, {
    String? name,
    String? description,
    String? avatar,
    Map<String, dynamic>? settings,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (avatar != null) updateData['avatar'] = avatar;
      if (settings != null) updateData['settings'] = settings;

      final response = await _dio.put(
        ApiConstants.updateChat(chatId),
        data: updateData,
      );

      return ApiResponse.fromJson(
        response.data,
        (data) => ChatModel.fromJson(data),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Delete chat
  Future<ApiResponse<void>> deleteChat(String chatId) async {
    try {
      final response = await _dio.delete(ApiConstants.deleteChat(chatId));
      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Add participant to chat
  Future<ApiResponse<void>> addParticipant(
    String chatId,
    String userId, {
    String role = 'member',
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.addParticipant(chatId),
        data: {'user_id': userId, 'role': role},
      );

      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Remove participant from chat
  Future<ApiResponse<void>> removeParticipant(
    String chatId,
    String userId,
  ) async {
    try {
      final response = await _dio.delete(
        ApiConstants.removeParticipant(chatId, userId),
      );

      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get chat participants
  Future<ApiResponse<List<ChatParticipant>>> getChatParticipants(
    String chatId,
  ) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.getChat(chatId)}/participants',
      );
      return ApiResponse.fromJson(
        response.data,
        (data) => (data as List)
            .map((participant) => ChatParticipant.fromJson(participant))
            .toList(),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Update participant role
  Future<ApiResponse<void>> updateParticipantRole(
    String chatId,
    String userId,
    String role,
  ) async {
    try {
      final response = await _dio.put(
        '${ApiConstants.getChat(chatId)}/participants/$userId',
        data: {'role': role},
      );

      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Archive/Unarchive chat
  Future<ApiResponse<void>> archiveChat(String chatId, bool archive) async {
    try {
      final response = await _dio.put(
        ApiConstants.archiveChat(chatId),
        data: {'archived': archive},
      );

      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Mute/Unmute chat
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
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Pin/Unpin chat
  Future<ApiResponse<void>> pinChat(String chatId, bool pin) async {
    try {
      final response = await _dio.put(
        ApiConstants.pinChat(chatId),
        data: {'pinned': pin},
      );

      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Mark chat as read
  Future<ApiResponse<void>> markChatAsRead(String chatId) async {
    try {
      final response = await _dio.put(ApiConstants.markChatAsRead(chatId));
      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Set chat wallpaper
  Future<ApiResponse<void>> setChatWallpaper(
    String chatId,
    String wallpaperUrl,
  ) async {
    try {
      final response = await _dio.put(
        '${ApiConstants.updateChat(chatId)}/wallpaper',
        data: {'wallpaper': wallpaperUrl},
      );

      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Clear chat history
  Future<ApiResponse<void>> clearChatHistory(String chatId) async {
    try {
      final response = await _dio.delete(
        '${ApiConstants.getChat(chatId)}/history',
      );
      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Leave chat
  Future<ApiResponse<void>> leaveChat(String chatId) async {
    try {
      final response = await _dio.post('${ApiConstants.getChat(chatId)}/leave');
      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get chat media
  Future<ApiResponse<List<ChatMedia>>> getChatMedia(
    String chatId, {
    String? type,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (type != null) 'type': type,
      };

      final response = await _dio.get(
        '${ApiConstants.getChat(chatId)}/media',
        queryParameters: queryParams,
      );

      return ApiResponse.fromJson(
        response.data,
        (data) =>
            (data as List).map((media) => ChatMedia.fromJson(media)).toList(),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Search chats
  Future<ApiResponse<List<ChatModel>>> searchChats({
    required String query,
    String? type,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'q': query,
        'limit': limit,
        if (type != null) 'type': type,
      };

      final response = await _dio.get(
        '${ApiConstants.getUserChats}/search',
        queryParameters: queryParams,
      );

      return ApiResponse.fromJson(
        response.data,
        (data) =>
            (data as List).map((chat) => ChatModel.fromJson(chat)).toList(),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get chat statistics
  Future<ApiResponse<ChatStats>> getChatStats(String chatId) async {
    try {
      final response = await _dio.get('${ApiConstants.getChat(chatId)}/stats');
      return ApiResponse.fromJson(
        response.data,
        (data) => ChatStats.fromJson(data),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Export chat history
  Future<ApiResponse<Map<String, dynamic>>> exportChatHistory(
    String chatId, {
    DateTime? from,
    DateTime? to,
    String format = 'json',
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'format': format,
        if (from != null) 'from': from.toIso8601String(),
        if (to != null) 'to': to.toIso8601String(),
      };

      final response = await _dio.get(
        '${ApiConstants.getChat(chatId)}/export',
        queryParameters: queryParams,
      );

      return ApiResponse.fromJson(response.data, (data) => data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Set chat draft
  Future<ApiResponse<void>> setChatDraft(String chatId, String content) async {
    try {
      final response = await _dio.put(
        '${ApiConstants.getChat(chatId)}/draft',
        data: {'content': content},
      );

      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get chat draft
  Future<ApiResponse<String?>> getChatDraft(String chatId) async {
    try {
      final response = await _dio.get('${ApiConstants.getChat(chatId)}/draft');
      return ApiResponse.fromJson(
        response.data,
        (data) => data['content'] as String?,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Clear chat draft
  Future<ApiResponse<void>> clearChatDraft(String chatId) async {
    try {
      final response = await _dio.delete(
        '${ApiConstants.getChat(chatId)}/draft',
      );
      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Report chat
  Future<ApiResponse<void>> reportChat(
    String chatId, {
    required String reason,
    String? description,
    List<String>? messageIds,
  }) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.getChat(chatId)}/report',
        data: {
          'reason': reason,
          if (description != null) 'description': description,
          if (messageIds != null) 'message_ids': messageIds,
        },
      );

      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get chat encryption info
  Future<ApiResponse<ChatEncryption>> getChatEncryption(String chatId) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.getChat(chatId)}/encryption',
      );
      return ApiResponse.fromJson(
        response.data,
        (data) => ChatEncryption.fromJson(data),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Update chat encryption
  Future<ApiResponse<void>> updateChatEncryption(
    String chatId, {
    required bool enabled,
    String? publicKey,
  }) async {
    try {
      final response = await _dio.put(
        '${ApiConstants.getChat(chatId)}/encryption',
        data: {
          'enabled': enabled,
          if (publicKey != null) 'public_key': publicKey,
        },
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
class ChatParticipant {
  final String userId;
  final String name;
  final String? avatar;
  final String role;
  final DateTime joinedAt;
  final DateTime? lastSeen;
  final bool isOnline;

  ChatParticipant({
    required this.userId,
    required this.name,
    this.avatar,
    required this.role,
    required this.joinedAt,
    this.lastSeen,
    required this.isOnline,
  });

  factory ChatParticipant.fromJson(Map<String, dynamic> json) {
    return ChatParticipant(
      userId: json['user_id'],
      name: json['name'],
      avatar: json['avatar'],
      role: json['role'],
      joinedAt: DateTime.parse(json['joined_at']),
      lastSeen: json['last_seen'] != null
          ? DateTime.parse(json['last_seen'])
          : null,
      isOnline: json['is_online'] ?? false,
    );
  }
}

class ChatMedia {
  final String id;
  final String messageId;
  final String type;
  final String url;
  final String? thumbnailUrl;
  final String fileName;
  final int size;
  final DateTime createdAt;

  ChatMedia({
    required this.id,
    required this.messageId,
    required this.type,
    required this.url,
    this.thumbnailUrl,
    required this.fileName,
    required this.size,
    required this.createdAt,
  });

  factory ChatMedia.fromJson(Map<String, dynamic> json) {
    return ChatMedia(
      id: json['id'],
      messageId: json['message_id'],
      type: json['type'],
      url: json['url'],
      thumbnailUrl: json['thumbnail_url'],
      fileName: json['file_name'],
      size: json['size'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class ChatStats {
  final int totalMessages;
  final int totalMedia;
  final int totalParticipants;
  final DateTime createdAt;
  final DateTime? lastMessageAt;
  final Map<String, int> messagesByType;
  final Map<String, int> mediaByType;

  ChatStats({
    required this.totalMessages,
    required this.totalMedia,
    required this.totalParticipants,
    required this.createdAt,
    this.lastMessageAt,
    required this.messagesByType,
    required this.mediaByType,
  });

  factory ChatStats.fromJson(Map<String, dynamic> json) {
    return ChatStats(
      totalMessages: json['total_messages'],
      totalMedia: json['total_media'],
      totalParticipants: json['total_participants'],
      createdAt: DateTime.parse(json['created_at']),
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'])
          : null,
      messagesByType: Map<String, int>.from(json['messages_by_type'] ?? {}),
      mediaByType: Map<String, int>.from(json['media_by_type'] ?? {}),
    );
  }
}

class ChatEncryption {
  final bool enabled;
  final String? algorithm;
  final String? publicKey;
  final DateTime? keyCreatedAt;

  ChatEncryption({
    required this.enabled,
    this.algorithm,
    this.publicKey,
    this.keyCreatedAt,
  });

  factory ChatEncryption.fromJson(Map<String, dynamic> json) {
    return ChatEncryption(
      enabled: json['enabled'],
      algorithm: json['algorithm'],
      publicKey: json['public_key'],
      keyCreatedAt: json['key_created_at'] != null
          ? DateTime.parse(json['key_created_at'])
          : null,
    );
  }
}

// Riverpod provider
final chatAPIProvider = Provider<ChatAPI>((ref) {
  final dio = ref.watch(dioProvider);
  return ChatAPI(dio);
});
