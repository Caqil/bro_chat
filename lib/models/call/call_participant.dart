import 'package:bro_chat/models/call/call_model.dart';

class CallParticipant {
  final String userId;
  final String name;
  final String? avatar;
  final ParticipantStatus status;
  final DateTime joinedAt;
  final DateTime? leftAt;
  final MediaState mediaState;
  final DeviceInfo deviceInfo;
  final bool isMuted;
  final bool isVideoEnabled;
  final bool isScreenSharing;
  final CallQuality? quality;

  CallParticipant({
    required this.userId,
    required this.name,
    this.avatar,
    required this.status,
    required this.joinedAt,
    this.leftAt,
    required this.mediaState,
    required this.deviceInfo,
    this.isMuted = false,
    this.isVideoEnabled = false,
    this.isScreenSharing = false,
    this.quality,
  });

  factory CallParticipant.fromJson(Map<String, dynamic> json) {
    return CallParticipant(
      userId: json['user_id'] ?? '',
      name: json['name'] ?? '',
      avatar: json['avatar'],
      status: ParticipantStatus.fromString(json['status']),
      joinedAt: DateTime.parse(json['joined_at']),
      leftAt: json['left_at'] != null ? DateTime.parse(json['left_at']) : null,
      mediaState: MediaState.fromJson(json['media_state'] ?? {}),
      deviceInfo: DeviceInfo.fromJson(json['device_info'] ?? {}),
      isMuted: json['is_muted'] ?? false,
      isVideoEnabled: json['is_video_enabled'] ?? false,
      isScreenSharing: json['is_screen_sharing'] ?? false,
      quality: json['quality'] != null
          ? CallQuality.fromJson(json['quality'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      if (avatar != null) 'avatar': avatar,
      'status': status.value,
      'joined_at': joinedAt.toIso8601String(),
      if (leftAt != null) 'left_at': leftAt!.toIso8601String(),
      'media_state': mediaState.toJson(),
      'device_info': deviceInfo.toJson(),
      'is_muted': isMuted,
      'is_video_enabled': isVideoEnabled,
      'is_screen_sharing': isScreenSharing,
      if (quality != null) 'quality': quality!.toJson(),
    };
  }
}

enum ParticipantStatus {
  invited,
  ringing,
  connecting,
  connected,
  disconnected,
  left;

  String get value => name;

  static ParticipantStatus fromString(String? value) {
    switch (value) {
      case 'invited':
        return ParticipantStatus.invited;
      case 'ringing':
        return ParticipantStatus.ringing;
      case 'connecting':
        return ParticipantStatus.connecting;
      case 'connected':
        return ParticipantStatus.connected;
      case 'disconnected':
        return ParticipantStatus.disconnected;
      case 'left':
        return ParticipantStatus.left;
      default:
        return ParticipantStatus.disconnected;
    }
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
