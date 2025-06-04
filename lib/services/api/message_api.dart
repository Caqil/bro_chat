import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/dio_config.dart';
import '../../core/constants/api_constants.dart';
import '../../core/exceptions/network_exception.dart';
import '../../models/chat/message_model.dart';
import '../../models/common/api_response.dart';

class MessageAPI {
  final Dio _dio;

  MessageAPI(this._dio);

  /// Send a message
  Future<ApiResponse<MessageModel>> sendMessage({
    required String chatId,
    required String type,
    required String content,
    String? replyToId,
    List<String>? mentions,
    Map<String, dynamic>? metadata,
    DateTime? scheduledAt,
    List<String>? fileIds,
    bool? ephemeral,
    int? ephemeralTtl,
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
          if (fileIds != null) 'file_ids': fileIds,
          if (ephemeral != null) 'ephemeral': ephemeral,
          if (ephemeralTtl != null) 'ephemeral_ttl': ephemeralTtl,
        },
      );

      return ApiResponse.fromJson(
        response.data,
        (data) => MessageModel.fromJson(data),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Send text message
  Future<ApiResponse<MessageModel>> sendTextMessage({
    required String chatId,
    required String content,
    String? replyToId,
    List<String>? mentions,
  }) async {
    return sendMessage(
      chatId: chatId,
      type: 'text',
      content: content,
      replyToId: replyToId,
      mentions: mentions,
    );
  }

  /// Send media message
  Future<ApiResponse<MessageModel>> sendMediaMessage({
    required String chatId,
    required String type, // 'image', 'video', 'audio', 'document'
    required String content,
    required List<String> fileIds,
    String? replyToId,
    Map<String, dynamic>? mediaMetadata,
  }) async {
    return sendMessage(
      chatId: chatId,
      type: type,
      content: content,
      fileIds: fileIds,
      replyToId: replyToId,
      metadata: mediaMetadata,
    );
  }

  /// Send location message
  Future<ApiResponse<MessageModel>> sendLocationMessage({
    required String chatId,
    required double latitude,
    required double longitude,
    String? address,
    String? placeName,
    String content = 'Location shared',
  }) async {
    return sendMessage(
      chatId: chatId,
      type: 'location',
      content: content,
      metadata: {
        'location': {
          'latitude': latitude,
          'longitude': longitude,
          if (address != null) 'address': address,
          if (placeName != null) 'place_name': placeName,
        },
      },
    );
  }

  /// Send contact message
  Future<ApiResponse<MessageModel>> sendContactMessage({
    required String chatId,
    required String contactName,
    required String phoneNumber,
    String? email,
    String? avatar,
    String content = 'Contact shared',
  }) async {
    return sendMessage(
      chatId: chatId,
      type: 'contact',
      content: content,
      metadata: {
        'contact': {
          'name': contactName,
          'phone_number': phoneNumber,
          if (email != null) 'email': email,
          if (avatar != null) 'avatar': avatar,
        },
      },
    );
  }

  /// Send voice note
  Future<ApiResponse<MessageModel>> sendVoiceNote({
    required String chatId,
    required String fileId,
    required int duration,
    String? waveform,
    String content = 'Voice message',
  }) async {
    return sendMessage(
      chatId: chatId,
      type: 'voice',
      content: content,
      fileIds: [fileId],
      metadata: {
        'voice': {
          'duration': duration,
          if (waveform != null) 'waveform': waveform,
        },
      },
    );
  }

  /// Send sticker message
  Future<ApiResponse<MessageModel>> sendStickerMessage({
    required String chatId,
    required String stickerPack,
    required String stickerId,
    String content = 'Sticker',
  }) async {
    return sendMessage(
      chatId: chatId,
      type: 'sticker',
      content: content,
      metadata: {
        'sticker': {'pack': stickerPack, 'sticker_id': stickerId},
      },
    );
  }

  /// Schedule message
  Future<ApiResponse<MessageModel>> scheduleMessage({
    required String chatId,
    required String type,
    required String content,
    required DateTime scheduledAt,
    String? replyToId,
    List<String>? mentions,
    Map<String, dynamic>? metadata,
  }) async {
    return sendMessage(
      chatId: chatId,
      type: type,
      content: content,
      scheduledAt: scheduledAt,
      replyToId: replyToId,
      mentions: mentions,
      metadata: metadata,
    );
  }

  /// Get messages for a chat
  Future<ApiResponse<List<MessageModel>>> getMessages({
    required String chatId,
    int page = 1,
    int limit = 50,
    String? before,
    String? after,
    String? senderId,
    String? type,
    DateTime? dateFrom,
    DateTime? dateTo,
    bool? hasMedia,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'chat_id': chatId,
        'page': page,
        'limit': limit,
        if (before != null) 'before': before,
        if (after != null) 'after': after,
        if (senderId != null) 'sender_id': senderId,
        if (type != null) 'type': type,
        if (dateFrom != null) 'date_from': dateFrom.toIso8601String(),
        if (dateTo != null) 'date_to': dateTo.toIso8601String(),
        if (hasMedia != null) 'has_media': hasMedia,
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
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get single message
  Future<ApiResponse<MessageModel>> getMessage(String messageId) async {
    try {
      final response = await _dio.get(ApiConstants.getMessage(messageId));
      return ApiResponse.fromJson(
        response.data,
        (data) => MessageModel.fromJson(data),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Update/Edit message
  Future<ApiResponse<MessageModel>> updateMessage(
    String messageId, {
    required String content,
    String? reason,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await _dio.put(
        ApiConstants.updateMessage(messageId),
        data: {
          'content': content,
          if (reason != null) 'reason': reason,
          if (metadata != null) 'metadata': metadata,
        },
      );

      return ApiResponse.fromJson(
        response.data,
        (data) => MessageModel.fromJson(data),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Delete message
  Future<ApiResponse<void>> deleteMessage(
    String messageId, {
    bool forEveryone = false,
    String? reason,
  }) async {
    try {
      final response = await _dio.delete(
        ApiConstants.deleteMessage(messageId),
        data: {
          'for_everyone': forEveryone,
          if (reason != null) 'reason': reason,
        },
      );

      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Add reaction to message
  Future<ApiResponse<void>> addReaction(String messageId, String emoji) async {
    try {
      final response = await _dio.post(
        ApiConstants.addReaction(messageId),
        data: {'emoji': emoji},
      );

      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Remove reaction from message
  Future<ApiResponse<void>> removeReaction(String messageId) async {
    try {
      final response = await _dio.delete(
        ApiConstants.removeReaction(messageId),
      );
      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get message reactions
  Future<ApiResponse<List<MessageReaction>>> getMessageReactions(
    String messageId,
  ) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.getMessage(messageId)}/reactions',
      );
      return ApiResponse.fromJson(
        response.data,
        (data) => (data as List)
            .map((reaction) => MessageReaction.fromJson(reaction))
            .toList(),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Mark message as read
  Future<ApiResponse<void>> markMessageAsRead(String messageId) async {
    try {
      final response = await _dio.put(
        ApiConstants.markMessageAsRead(messageId),
      );
      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Mark multiple messages as read
  Future<ApiResponse<void>> markMultipleAsRead(List<String> messageIds) async {
    try {
      final response = await _dio.put(
        ApiConstants.markMultipleAsRead,
        data: {'message_ids': messageIds},
      );

      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Forward message
  Future<ApiResponse<MessageModel>> forwardMessage(
    String messageId,
    String toChatId, {
    String? additionalContent,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.forwardMessage(messageId),
        data: {
          'to_chat_id': toChatId,
          if (additionalContent != null)
            'additional_content': additionalContent,
        },
      );

      return ApiResponse.fromJson(
        response.data,
        (data) => MessageModel.fromJson(data),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Bulk forward messages
  Future<ApiResponse<List<MessageModel>>> bulkForwardMessages(
    List<String> messageIds,
    String toChatId, {
    String? additionalContent,
  }) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.sendMessage}/bulk-forward',
        data: {
          'message_ids': messageIds,
          'to_chat_id': toChatId,
          if (additionalContent != null)
            'additional_content': additionalContent,
        },
      );

      return ApiResponse.fromJson(
        response.data,
        (data) => (data as List)
            .map((message) => MessageModel.fromJson(message))
            .toList(),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Bulk delete messages
  Future<ApiResponse<BulkDeleteResult>> bulkDeleteMessages(
    List<String> messageIds, {
    bool forEveryone = false,
  }) async {
    try {
      final response = await _dio.delete(
        ApiConstants.bulkDeleteMessages,
        data: {'message_ids': messageIds, 'for_everyone': forEveryone},
      );

      return ApiResponse.fromJson(
        response.data,
        (data) => BulkDeleteResult.fromJson(data),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Search messages
  Future<ApiResponse<List<MessageModel>>> searchMessages({
    String? chatId,
    required String query,
    String? type,
    String? senderId,
    DateTime? dateFrom,
    DateTime? dateTo,
    int page = 1,
    int limit = 20,
    bool? hasMedia,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'q': query,
        'page': page,
        'limit': limit,
        if (chatId != null) 'chat_id': chatId,
        if (type != null) 'type': type,
        if (senderId != null) 'sender_id': senderId,
        if (dateFrom != null) 'date_from': dateFrom.toIso8601String(),
        if (dateTo != null) 'date_to': dateTo.toIso8601String(),
        if (hasMedia != null) 'has_media': hasMedia,
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
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get message thread/replies
  Future<ApiResponse<List<MessageModel>>> getMessageThread(
    String messageId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'limit': limit};

      final response = await _dio.get(
        '${ApiConstants.getMessage(messageId)}/thread',
        queryParameters: queryParams,
      );

      return ApiResponse.fromJson(
        response.data,
        (data) => (data as List)
            .map((message) => MessageModel.fromJson(message))
            .toList(),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Pin message
  Future<ApiResponse<void>> pinMessage(String messageId) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.getMessage(messageId)}/pin',
      );
      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Unpin message
  Future<ApiResponse<void>> unpinMessage(String messageId) async {
    try {
      final response = await _dio.delete(
        '${ApiConstants.getMessage(messageId)}/pin',
      );
      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get pinned messages for chat
  Future<ApiResponse<List<MessageModel>>> getPinnedMessages(
    String chatId,
  ) async {
    try {
      final response = await _dio.get('/chats/$chatId/pinned-messages');
      return ApiResponse.fromJson(
        response.data,
        (data) => (data as List)
            .map((message) => MessageModel.fromJson(message))
            .toList(),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Report message
  Future<ApiResponse<void>> reportMessage(
    String messageId, {
    required String reason,
    String? description,
  }) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.getMessage(messageId)}/report',
        data: {
          'reason': reason,
          if (description != null) 'description': description,
        },
      );

      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get scheduled messages
  Future<ApiResponse<List<MessageModel>>> getScheduledMessages({
    String? chatId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (chatId != null) 'chat_id': chatId,
      };

      final response = await _dio.get(
        '${ApiConstants.sendMessage}/scheduled',
        queryParameters: queryParams,
      );

      return ApiResponse.fromJson(
        response.data,
        (data) => (data as List)
            .map((message) => MessageModel.fromJson(message))
            .toList(),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Cancel scheduled message
  Future<ApiResponse<void>> cancelScheduledMessage(String messageId) async {
    try {
      final response = await _dio.delete(
        '${ApiConstants.sendMessage}/scheduled/$messageId',
      );
      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Update scheduled message
  Future<ApiResponse<MessageModel>> updateScheduledMessage(
    String messageId, {
    String? content,
    DateTime? scheduledAt,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (content != null) updateData['content'] = content;
      if (scheduledAt != null)
        updateData['scheduled_at'] = scheduledAt.toIso8601String();
      if (metadata != null) updateData['metadata'] = metadata;

      final response = await _dio.put(
        '${ApiConstants.sendMessage}/scheduled/$messageId',
        data: updateData,
      );

      return ApiResponse.fromJson(
        response.data,
        (data) => MessageModel.fromJson(data),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get message delivery status
  Future<ApiResponse<MessageDeliveryStatus>> getMessageDeliveryStatus(
    String messageId,
  ) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.getMessage(messageId)}/delivery',
      );
      return ApiResponse.fromJson(
        response.data,
        (data) => MessageDeliveryStatus.fromJson(data),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get message read receipts
  Future<ApiResponse<List<MessageReadReceipt>>> getMessageReadReceipts(
    String messageId,
  ) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.getMessage(messageId)}/read-receipts',
      );
      return ApiResponse.fromJson(
        response.data,
        (data) => (data as List)
            .map((receipt) => MessageReadReceipt.fromJson(receipt))
            .toList(),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Star message
  Future<ApiResponse<void>> starMessage(String messageId) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.getMessage(messageId)}/star',
      );
      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Unstar message
  Future<ApiResponse<void>> unstarMessage(String messageId) async {
    try {
      final response = await _dio.delete(
        '${ApiConstants.getMessage(messageId)}/star',
      );
      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get starred messages
  Future<ApiResponse<List<MessageModel>>> getStarredMessages({
    int page = 1,
    int limit = 20,
    String? chatId,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (chatId != null) 'chat_id': chatId,
      };

      final response = await _dio.get(
        '${ApiConstants.sendMessage}/starred',
        queryParameters: queryParams,
      );

      return ApiResponse.fromJson(
        response.data,
        (data) => (data as List)
            .map((message) => MessageModel.fromJson(message))
            .toList(),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get message statistics
  Future<ApiResponse<MessageStats>> getMessageStats() async {
    try {
      final response = await _dio.get(ApiConstants.getMessageStats);
      return ApiResponse.fromJson(
        response.data,
        (data) => MessageStats.fromJson(data),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Translate message
  Future<ApiResponse<MessageTranslation>> translateMessage(
    String messageId,
    String targetLanguage,
  ) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.getMessage(messageId)}/translate',
        data: {'target_language': targetLanguage},
      );

      return ApiResponse.fromJson(
        response.data,
        (data) => MessageTranslation.fromJson(data),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get message mentions
  Future<ApiResponse<List<MessageMention>>> getMessageMentions(
    String messageId,
  ) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.getMessage(messageId)}/mentions',
      );
      return ApiResponse.fromJson(
        response.data,
        (data) => (data as List)
            .map((mention) => MessageMention.fromJson(mention))
            .toList(),
      );
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
class MessageReaction {
  final String id;
  final String messageId;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String emoji;
  final DateTime createdAt;

  MessageReaction({
    required this.id,
    required this.messageId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.emoji,
    required this.createdAt,
  });

  factory MessageReaction.fromJson(Map<String, dynamic> json) {
    return MessageReaction(
      id: json['id'],
      messageId: json['message_id'],
      userId: json['user_id'],
      userName: json['user_name'],
      userAvatar: json['user_avatar'],
      emoji: json['emoji'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class BulkDeleteResult {
  final int successful;
  final int failed;
  final List<String> failedMessageIds;
  final List<String> errors;

  BulkDeleteResult({
    required this.successful,
    required this.failed,
    required this.failedMessageIds,
    required this.errors,
  });

  factory BulkDeleteResult.fromJson(Map<String, dynamic> json) {
    return BulkDeleteResult(
      successful: json['successful'],
      failed: json['failed'],
      failedMessageIds: List<String>.from(json['failed_message_ids'] ?? []),
      errors: List<String>.from(json['errors'] ?? []),
    );
  }
}

class MessageDeliveryStatus {
  final String messageId;
  final String status; // 'sent', 'delivered', 'read', 'failed'
  final DateTime sentAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final List<MessageDeliveryRecipient> recipients;

  MessageDeliveryStatus({
    required this.messageId,
    required this.status,
    required this.sentAt,
    this.deliveredAt,
    this.readAt,
    required this.recipients,
  });

  factory MessageDeliveryStatus.fromJson(Map<String, dynamic> json) {
    return MessageDeliveryStatus(
      messageId: json['message_id'],
      status: json['status'],
      sentAt: DateTime.parse(json['sent_at']),
      deliveredAt: json['delivered_at'] != null
          ? DateTime.parse(json['delivered_at'])
          : null,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      recipients: (json['recipients'] as List)
          .map((recipient) => MessageDeliveryRecipient.fromJson(recipient))
          .toList(),
    );
  }
}

class MessageDeliveryRecipient {
  final String userId;
  final String userName;
  final String status; // 'sent', 'delivered', 'read', 'failed'
  final DateTime? deliveredAt;
  final DateTime? readAt;

  MessageDeliveryRecipient({
    required this.userId,
    required this.userName,
    required this.status,
    this.deliveredAt,
    this.readAt,
  });

  factory MessageDeliveryRecipient.fromJson(Map<String, dynamic> json) {
    return MessageDeliveryRecipient(
      userId: json['user_id'],
      userName: json['user_name'],
      status: json['status'],
      deliveredAt: json['delivered_at'] != null
          ? DateTime.parse(json['delivered_at'])
          : null,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
    );
  }
}

class MessageReadReceipt {
  final String userId;
  final String userName;
  final String? userAvatar;
  final DateTime readAt;

  MessageReadReceipt({
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.readAt,
  });

  factory MessageReadReceipt.fromJson(Map<String, dynamic> json) {
    return MessageReadReceipt(
      userId: json['user_id'],
      userName: json['user_name'],
      userAvatar: json['user_avatar'],
      readAt: DateTime.parse(json['read_at']),
    );
  }
}

class MessageStats {
  final int totalMessages;
  final int todayMessages;
  final int weekMessages;
  final int monthMessages;
  final Map<String, int> messagesByType;
  final Map<String, int> messagesByHour;
  final Map<String, int> messagesByDay;
  final double averageMessageLength;
  final int totalReactions;
  final int totalForwards;

  MessageStats({
    required this.totalMessages,
    required this.todayMessages,
    required this.weekMessages,
    required this.monthMessages,
    required this.messagesByType,
    required this.messagesByHour,
    required this.messagesByDay,
    required this.averageMessageLength,
    required this.totalReactions,
    required this.totalForwards,
  });

  factory MessageStats.fromJson(Map<String, dynamic> json) {
    return MessageStats(
      totalMessages: json['total_messages'],
      todayMessages: json['today_messages'],
      weekMessages: json['week_messages'],
      monthMessages: json['month_messages'],
      messagesByType: Map<String, int>.from(json['messages_by_type'] ?? {}),
      messagesByHour: Map<String, int>.from(json['messages_by_hour'] ?? {}),
      messagesByDay: Map<String, int>.from(json['messages_by_day'] ?? {}),
      averageMessageLength: (json['average_message_length'] as num).toDouble(),
      totalReactions: json['total_reactions'],
      totalForwards: json['total_forwards'],
    );
  }
}

class MessageTranslation {
  final String messageId;
  final String originalText;
  final String translatedText;
  final String sourceLanguage;
  final String targetLanguage;
  final double confidence;
  final DateTime translatedAt;

  MessageTranslation({
    required this.messageId,
    required this.originalText,
    required this.translatedText,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.confidence,
    required this.translatedAt,
  });

  factory MessageTranslation.fromJson(Map<String, dynamic> json) {
    return MessageTranslation(
      messageId: json['message_id'],
      originalText: json['original_text'],
      translatedText: json['translated_text'],
      sourceLanguage: json['source_language'],
      targetLanguage: json['target_language'],
      confidence: (json['confidence'] as num).toDouble(),
      translatedAt: DateTime.parse(json['translated_at']),
    );
  }
}

class MessageMention {
  final String userId;
  final String userName;
  final String? userAvatar;
  final int startIndex;
  final int endIndex;

  MessageMention({
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.startIndex,
    required this.endIndex,
  });

  factory MessageMention.fromJson(Map<String, dynamic> json) {
    return MessageMention(
      userId: json['user_id'],
      userName: json['user_name'],
      userAvatar: json['user_avatar'],
      startIndex: json['start_index'],
      endIndex: json['end_index'],
    );
  }
}

// Riverpod provider
final messageAPIProvider = Provider<MessageAPI>((ref) {
  final dio = ref.watch(dioProvider);
  return MessageAPI(dio);
});
