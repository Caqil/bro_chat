class CallSettings {
  final bool videoEnabled;
  final bool audioEnabled;
  final bool screenSharingEnabled;
  final bool recordingEnabled;
  final int maxParticipants;
  final bool requireApproval;
  final String? meetingPassword;
  final bool waitingRoomEnabled;
  final bool muteOnJoin;
  final bool disableVideo;

  CallSettings({
    this.videoEnabled = true,
    this.audioEnabled = true,
    this.screenSharingEnabled = true,
    this.recordingEnabled = false,
    this.maxParticipants = 10,
    this.requireApproval = false,
    this.meetingPassword,
    this.waitingRoomEnabled = false,
    this.muteOnJoin = false,
    this.disableVideo = false,
  });

  factory CallSettings.fromJson(Map<String, dynamic> json) {
    return CallSettings(
      videoEnabled: json['video_enabled'] ?? true,
      audioEnabled: json['audio_enabled'] ?? true,
      screenSharingEnabled: json['screen_sharing_enabled'] ?? true,
      recordingEnabled: json['recording_enabled'] ?? false,
      maxParticipants: json['max_participants'] ?? 10,
      requireApproval: json['require_approval'] ?? false,
      meetingPassword: json['meeting_password'],
      waitingRoomEnabled: json['waiting_room_enabled'] ?? false,
      muteOnJoin: json['mute_on_join'] ?? false,
      disableVideo: json['disable_video'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'video_enabled': videoEnabled,
      'audio_enabled': audioEnabled,
      'screen_sharing_enabled': screenSharingEnabled,
      'recording_enabled': recordingEnabled,
      'max_participants': maxParticipants,
      'require_approval': requireApproval,
      if (meetingPassword != null) 'meeting_password': meetingPassword,
      'waiting_room_enabled': waitingRoomEnabled,
      'mute_on_join': muteOnJoin,
      'disable_video': disableVideo,
    };
  }
}
