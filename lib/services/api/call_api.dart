import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/dio_config.dart';
import '../../core/constants/api_constants.dart';
import '../../core/exceptions/network_exception.dart';
import '../../models/call/call_model.dart';
import '../../models/common/api_response.dart';

class CallAPI {
  final Dio _dio;

  CallAPI(this._dio);

  /// Initiate a new call
  Future<ApiResponse<CallModel>> initiateCall({
    required List<String> participantIds,
    required String chatId,
    required String type, // 'voice', 'video', 'group'
    bool videoEnabled = false,
    bool audioEnabled = true,
    Map<String, dynamic>? metadata,
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
          if (metadata != null) 'metadata': metadata,
        },
      );

      return ApiResponse.fromJson(
        response.data,
        (data) => CallModel.fromJson(data),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Answer an incoming call
  Future<ApiResponse<void>> answerCall(
    String callId, {
    required bool accept,
    Map<String, dynamic>? deviceInfo,
    bool videoEnabled = false,
    bool audioEnabled = true,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.answerCall(callId),
        data: {
          'accept': accept,
          'video_enabled': videoEnabled,
          'audio_enabled': audioEnabled,
          if (deviceInfo != null) 'device_info': deviceInfo,
        },
      );

      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// End an active call
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
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Join an ongoing call
  Future<ApiResponse<void>> joinCall(
    String callId, {
    Map<String, dynamic>? deviceInfo,
    bool videoEnabled = false,
    bool audioEnabled = true,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.joinCall(callId),
        data: {
          'video_enabled': videoEnabled,
          'audio_enabled': audioEnabled,
          if (deviceInfo != null) 'device_info': deviceInfo,
        },
      );

      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Leave an ongoing call
  Future<ApiResponse<void>> leaveCall(String callId) async {
    try {
      final response = await _dio.post(ApiConstants.leaveCall(callId));
      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get call details
  Future<ApiResponse<CallModel>> getCall(String callId) async {
    try {
      final response = await _dio.get(ApiConstants.getCall(callId));
      return ApiResponse.fromJson(
        response.data,
        (data) => CallModel.fromJson(data),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get call history
  Future<ApiResponse<List<CallModel>>> getCallHistory({
    int page = 1,
    int limit = 20,
    String? type,
    String? status,
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (type != null) 'type': type,
        if (status != null) 'status': status,
        if (from != null) 'from': from.toIso8601String(),
        if (to != null) 'to': to.toIso8601String(),
      };

      final response = await _dio.get(
        ApiConstants.getCallHistory,
        queryParameters: queryParams,
      );

      return ApiResponse.fromJson(
        response.data,
        (data) =>
            (data as List).map((call) => CallModel.fromJson(call)).toList(),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Update media state during call
  Future<ApiResponse<void>> updateMediaState(
    String callId, {
    bool? videoEnabled,
    bool? audioEnabled,
    bool? screenSharing,
    String? cameraFacing,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (videoEnabled != null) updateData['video_enabled'] = videoEnabled;
      if (audioEnabled != null) updateData['audio_enabled'] = audioEnabled;
      if (screenSharing != null) updateData['screen_sharing'] = screenSharing;
      if (cameraFacing != null) updateData['camera_facing'] = cameraFacing;

      final response = await _dio.put(
        ApiConstants.updateMediaState(callId),
        data: updateData,
      );

      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Update call quality metrics
  Future<ApiResponse<void>> updateQualityMetrics(
    String callId, {
    required double qualityScore,
    required double rtt,
    required double jitter,
    required double packetLoss,
    Map<String, dynamic>? additionalMetrics,
  }) async {
    try {
      final response = await _dio.put(
        ApiConstants.updateQualityMetrics(callId),
        data: {
          'quality_score': qualityScore,
          'rtt': rtt,
          'jitter': jitter,
          'packet_loss': packetLoss,
          if (additionalMetrics != null) ...additionalMetrics,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get call participants
  Future<ApiResponse<List<CallParticipant>>> getCallParticipants(
    String callId,
  ) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.getCall(callId)}/participants',
      );
      return ApiResponse.fromJson(
        response.data,
        (data) => (data as List)
            .map((participant) => CallParticipant.fromJson(participant))
            .toList(),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Start call recording
  Future<ApiResponse<void>> startRecording(String callId) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.getCall(callId)}/recording/start',
      );
      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Stop call recording
  Future<ApiResponse<void>> stopRecording(String callId) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.getCall(callId)}/recording/stop',
      );
      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get call recordings
  Future<ApiResponse<List<CallRecording>>> getCallRecordings(
    String callId,
  ) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.getCall(callId)}/recordings',
      );
      return ApiResponse.fromJson(
        response.data,
        (data) => (data as List)
            .map((recording) => CallRecording.fromJson(recording))
            .toList(),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get WebRTC configuration
  Future<ApiResponse<WebRTCConfig>> getWebRTCConfig() async {
    try {
      final response = await _dio.get(
        '${ApiConstants.initiateCall}/webrtc-config',
      );
      return ApiResponse.fromJson(
        response.data,
        (data) => WebRTCConfig.fromJson(data),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Exchange WebRTC offer/answer
  Future<ApiResponse<void>> exchangeWebRTCSignal(
    String callId, {
    required String type, // 'offer', 'answer', 'ice-candidate'
    required Map<String, dynamic> signal,
    String? targetUserId,
  }) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.getCall(callId)}/webrtc-signal',
        data: {
          'type': type,
          'signal': signal,
          if (targetUserId != null) 'target_user_id': targetUserId,
        },
      );

      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Report call issue
  Future<ApiResponse<void>> reportCallIssue(
    String callId, {
    required String issue,
    String? description,
    Map<String, dynamic>? diagnostics,
  }) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.getCall(callId)}/report',
        data: {
          'issue': issue,
          if (description != null) 'description': description,
          if (diagnostics != null) 'diagnostics': diagnostics,
        },
      );

      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get call statistics
  Future<ApiResponse<CallStats>> getCallStats(String callId) async {
    try {
      final response = await _dio.get('${ApiConstants.getCall(callId)}/stats');
      return ApiResponse.fromJson(
        response.data,
        (data) => CallStats.fromJson(data),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Block caller
  Future<ApiResponse<void>> blockCaller(String userId) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.initiateCall}/block',
        data: {'user_id': userId},
      );
      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Unblock caller
  Future<ApiResponse<void>> unblockCaller(String userId) async {
    try {
      final response = await _dio.delete(
        '${ApiConstants.initiateCall}/block/$userId',
      );
      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get blocked callers
  Future<ApiResponse<List<String>>> getBlockedCallers() async {
    try {
      final response = await _dio.get('${ApiConstants.initiateCall}/blocked');
      return ApiResponse.fromJson(
        response.data,
        (data) => List<String>.from(data),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Schedule a call
  Future<ApiResponse<CallModel>> scheduleCall({
    required List<String> participantIds,
    required String chatId,
    required String type,
    required DateTime scheduledAt,
    String? title,
    String? description,
    bool videoEnabled = false,
    bool audioEnabled = true,
    Map<String, dynamic>? settings,
  }) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.initiateCall}/schedule',
        data: {
          'participant_ids': participantIds,
          'chat_id': chatId,
          'type': type,
          'scheduled_at': scheduledAt.toIso8601String(),
          if (title != null) 'title': title,
          if (description != null) 'description': description,
          'video_enabled': videoEnabled,
          'audio_enabled': audioEnabled,
          if (settings != null) 'settings': settings,
        },
      );

      return ApiResponse.fromJson(
        response.data,
        (data) => CallModel.fromJson(data),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Cancel scheduled call
  Future<ApiResponse<void>> cancelScheduledCall(String callId) async {
    try {
      final response = await _dio.delete(
        '${ApiConstants.getCall(callId)}/schedule',
      );
      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get scheduled calls
  Future<ApiResponse<List<CallModel>>> getScheduledCalls({
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (from != null) 'from': from.toIso8601String(),
        if (to != null) 'to': to.toIso8601String(),
      };

      final response = await _dio.get(
        '${ApiConstants.initiateCall}/scheduled',
        queryParameters: queryParams,
      );

      return ApiResponse.fromJson(
        response.data,
        (data) =>
            (data as List).map((call) => CallModel.fromJson(call)).toList(),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Send DTMF tones
  Future<ApiResponse<void>> sendDTMF(String callId, String tones) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.getCall(callId)}/dtmf',
        data: {'tones': tones},
      );
      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get call logs for debugging
  Future<ApiResponse<List<CallLog>>> getCallLogs(
    String callId, {
    String? level,
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (level != null) 'level': level,
        if (from != null) 'from': from.toIso8601String(),
        if (to != null) 'to': to.toIso8601String(),
      };

      final response = await _dio.get(
        '${ApiConstants.getCall(callId)}/logs',
        queryParameters: queryParams,
      );

      return ApiResponse.fromJson(
        response.data,
        (data) => (data as List).map((log) => CallLog.fromJson(log)).toList(),
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
class CallParticipant {
  final String userId;
  final String name;
  final String? avatar;
  final String status; // 'joined', 'left', 'connecting', 'disconnected'
  final bool audioEnabled;
  final bool videoEnabled;
  final bool screenSharing;
  final DateTime joinedAt;
  final DateTime? leftAt;
  final Map<String, dynamic>? metadata;

  CallParticipant({
    required this.userId,
    required this.name,
    this.avatar,
    required this.status,
    required this.audioEnabled,
    required this.videoEnabled,
    required this.screenSharing,
    required this.joinedAt,
    this.leftAt,
    this.metadata,
  });

  factory CallParticipant.fromJson(Map<String, dynamic> json) {
    return CallParticipant(
      userId: json['user_id'],
      name: json['name'],
      avatar: json['avatar'],
      status: json['status'],
      audioEnabled: json['audio_enabled'] ?? true,
      videoEnabled: json['video_enabled'] ?? false,
      screenSharing: json['screen_sharing'] ?? false,
      joinedAt: DateTime.parse(json['joined_at']),
      leftAt: json['left_at'] != null ? DateTime.parse(json['left_at']) : null,
      metadata: json['metadata'],
    );
  }
}

class CallRecording {
  final String id;
  final String callId;
  final String url;
  final int duration;
  final int size;
  final String format;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String status;

  CallRecording({
    required this.id,
    required this.callId,
    required this.url,
    required this.duration,
    required this.size,
    required this.format,
    required this.startedAt,
    this.endedAt,
    required this.status,
  });

  factory CallRecording.fromJson(Map<String, dynamic> json) {
    return CallRecording(
      id: json['id'],
      callId: json['call_id'],
      url: json['url'],
      duration: json['duration'],
      size: json['size'],
      format: json['format'],
      startedAt: DateTime.parse(json['started_at']),
      endedAt: json['ended_at'] != null
          ? DateTime.parse(json['ended_at'])
          : null,
      status: json['status'],
    );
  }
}

class WebRTCConfig {
  final List<Map<String, dynamic>> iceServers;
  final int iceCandidatePoolSize;
  final String bundlePolicy;
  final String rtcpMuxPolicy;
  final Map<String, dynamic>? additionalConfig;

  WebRTCConfig({
    required this.iceServers,
    required this.iceCandidatePoolSize,
    required this.bundlePolicy,
    required this.rtcpMuxPolicy,
    this.additionalConfig,
  });

  factory WebRTCConfig.fromJson(Map<String, dynamic> json) {
    return WebRTCConfig(
      iceServers: List<Map<String, dynamic>>.from(json['ice_servers']),
      iceCandidatePoolSize: json['ice_candidate_pool_size'],
      bundlePolicy: json['bundle_policy'],
      rtcpMuxPolicy: json['rtcp_mux_policy'],
      additionalConfig: json['additional_config'],
    );
  }
}

class CallStats {
  final String callId;
  final int totalDuration;
  final int participants;
  final double averageQuality;
  final double averageRTT;
  final double averageJitter;
  final double averagePacketLoss;
  final int reconnections;
  final Map<String, dynamic> mediaStats;
  final DateTime createdAt;

  CallStats({
    required this.callId,
    required this.totalDuration,
    required this.participants,
    required this.averageQuality,
    required this.averageRTT,
    required this.averageJitter,
    required this.averagePacketLoss,
    required this.reconnections,
    required this.mediaStats,
    required this.createdAt,
  });

  factory CallStats.fromJson(Map<String, dynamic> json) {
    return CallStats(
      callId: json['call_id'],
      totalDuration: json['total_duration'],
      participants: json['participants'],
      averageQuality: (json['average_quality'] as num).toDouble(),
      averageRTT: (json['average_rtt'] as num).toDouble(),
      averageJitter: (json['average_jitter'] as num).toDouble(),
      averagePacketLoss: (json['average_packet_loss'] as num).toDouble(),
      reconnections: json['reconnections'],
      mediaStats: Map<String, dynamic>.from(json['media_stats']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class CallLog {
  final String id;
  final String callId;
  final String level; // 'debug', 'info', 'warning', 'error'
  final String message;
  final Map<String, dynamic>? data;
  final DateTime timestamp;

  CallLog({
    required this.id,
    required this.callId,
    required this.level,
    required this.message,
    this.data,
    required this.timestamp,
  });

  factory CallLog.fromJson(Map<String, dynamic> json) {
    return CallLog(
      id: json['id'],
      callId: json['call_id'],
      level: json['level'],
      message: json['message'],
      data: json['data'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

// Riverpod provider
final callAPIProvider = Provider<CallAPI>((ref) {
  final dio = ref.watch(dioProvider);
  return CallAPI(dio);
});
