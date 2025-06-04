import 'package:bro_chat/models/call/call_settings.dart';

class CallModel {
  final String id;
  final String chatId;
  final String initiatorId;
  final List<String> participantIds;
  final CallType type;
  final CallStatus status;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final Duration? duration;
  final String? endReason;
  final CallQuality? quality;
  final bool isRecording;
  final String? recordingUrl;
  final CallSettings settings;
  final DateTime createdAt;
  final DateTime updatedAt;

  CallModel({
    required this.id,
    required this.chatId,
    required this.initiatorId,
    required this.participantIds,
    required this.type,
    required this.status,
    this.startedAt,
    this.endedAt,
    this.duration,
    this.endReason,
    this.quality,
    this.isRecording = false,
    this.recordingUrl,
    required this.settings,
    required this.createdAt,
    required this.updatedAt,
  });

  // Add copyWith method
  CallModel copyWith({
    String? id,
    String? chatId,
    String? initiatorId,
    List<String>? participantIds,
    CallType? type,
    CallStatus? status,
    DateTime? startedAt,
    DateTime? endedAt,
    Duration? duration,
    String? endReason,
    CallQuality? quality,
    bool? isRecording,
    String? recordingUrl,
    CallSettings? settings,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CallModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      initiatorId: initiatorId ?? this.initiatorId,
      participantIds: participantIds ?? this.participantIds,
      type: type ?? this.type,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      duration: duration ?? this.duration,
      endReason: endReason ?? this.endReason,
      quality: quality ?? this.quality,
      isRecording: isRecording ?? this.isRecording,
      recordingUrl: recordingUrl ?? this.recordingUrl,
      settings: settings ?? this.settings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory CallModel.fromJson(Map<String, dynamic> json) {
    return CallModel(
      id: json['id'] ?? json['_id'] ?? '',
      chatId: json['chat_id'] ?? '',
      initiatorId: json['initiator_id'] ?? '',
      participantIds: List<String>.from(json['participant_ids'] ?? []),
      type: CallType.fromString(json['type']),
      status: CallStatus.fromString(json['status']),
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'])
          : null,
      endedAt: json['ended_at'] != null
          ? DateTime.parse(json['ended_at'])
          : null,
      duration: json['duration'] != null
          ? Duration(seconds: json['duration'])
          : null,
      endReason: json['end_reason'],
      quality: json['quality'] != null
          ? CallQuality.fromJson(json['quality'])
          : null,
      isRecording: json['is_recording'] ?? false,
      recordingUrl: json['recording_url'],
      settings: CallSettings.fromJson(json['settings'] ?? {}),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_id': chatId,
      'initiator_id': initiatorId,
      'participant_ids': participantIds,
      'type': type.value,
      'status': status.value,
      if (startedAt != null) 'started_at': startedAt!.toIso8601String(),
      if (endedAt != null) 'ended_at': endedAt!.toIso8601String(),
      if (duration != null) 'duration': duration!.inSeconds,
      if (endReason != null) 'end_reason': endReason,
      if (quality != null) 'quality': quality!.toJson(),
      'is_recording': isRecording,
      if (recordingUrl != null) 'recording_url': recordingUrl,
      'settings': settings.toJson(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isActive =>
      status == CallStatus.ongoing || status == CallStatus.ringing;
  bool get isEnded => status == CallStatus.ended || status == CallStatus.missed;
  bool get isVideoCall => type == CallType.video || type == CallType.group;
}

enum CallType {
  voice,
  video,
  group,
  conference;

  String get value => name;

  static CallType fromString(String? value) {
    switch (value) {
      case 'voice':
        return CallType.voice;
      case 'video':
        return CallType.video;
      case 'group':
        return CallType.group;
      case 'conference':
        return CallType.conference;
      default:
        return CallType.voice;
    }
  }
}

enum CallStatus {
  initiating,
  ringing,
  connecting,
  ongoing,
  ended,
  missed,
  declined,
  busy,
  failed;

  String get value => name;

  static CallStatus fromString(String? value) {
    switch (value) {
      case 'initiating':
        return CallStatus.initiating;
      case 'ringing':
        return CallStatus.ringing;
      case 'connecting':
        return CallStatus.connecting;
      case 'ongoing':
        return CallStatus.ongoing;
      case 'ended':
        return CallStatus.ended;
      case 'missed':
        return CallStatus.missed;
      case 'declined':
        return CallStatus.declined;
      case 'busy':
        return CallStatus.busy;
      case 'failed':
        return CallStatus.failed;
      default:
        return CallStatus.failed;
    }
  }
}

class CallQuality {
  final double qualityScore;
  final int rtt; // Round trip time
  final int jitter;
  final double packetLoss;
  final int bandwidth;
  final String networkType;

  CallQuality({
    required this.qualityScore,
    required this.rtt,
    required this.jitter,
    required this.packetLoss,
    required this.bandwidth,
    required this.networkType,
  });

  factory CallQuality.fromJson(Map<String, dynamic> json) {
    return CallQuality(
      qualityScore: (json['quality_score'] ?? 0.0).toDouble(),
      rtt: json['rtt'] ?? 0,
      jitter: json['jitter'] ?? 0,
      packetLoss: (json['packet_loss'] ?? 0.0).toDouble(),
      bandwidth: json['bandwidth'] ?? 0,
      networkType: json['network_type'] ?? 'unknown',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quality_score': qualityScore,
      'rtt': rtt,
      'jitter': jitter,
      'packet_loss': packetLoss,
      'bandwidth': bandwidth,
      'network_type': networkType,
    };
  }
}

class MediaState {
  final bool audioEnabled;
  final bool videoEnabled;
  final bool screenSharing;
  final String? audioDevice;
  final String? videoDevice;

  MediaState({
    this.audioEnabled = true,
    this.videoEnabled = false,
    this.screenSharing = false,
    this.audioDevice,
    this.videoDevice,
  });

  factory MediaState.fromJson(Map<String, dynamic> json) {
    return MediaState(
      audioEnabled: json['audio_enabled'] ?? true,
      videoEnabled: json['video_enabled'] ?? false,
      screenSharing: json['screen_sharing'] ?? false,
      audioDevice: json['audio_device'],
      videoDevice: json['video_device'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'audio_enabled': audioEnabled,
      'video_enabled': videoEnabled,
      'screen_sharing': screenSharing,
      if (audioDevice != null) 'audio_device': audioDevice,
      if (videoDevice != null) 'video_device': videoDevice,
    };
  }
}

class DeviceInfo {
  final String platform;
  final String? browser;
  final String? version;
  final String? os;

  DeviceInfo({required this.platform, this.browser, this.version, this.os});

  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      platform: json['platform'] ?? 'unknown',
      browser: json['browser'],
      version: json['version'],
      os: json['os'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'platform': platform,
      if (browser != null) 'browser': browser,
      if (version != null) 'version': version,
      if (os != null) 'os': os,
    };
  }
}
