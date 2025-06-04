class ChatSettings {
  final bool muteNotifications;
  final bool autoDeleteMessages;
  final Duration? autoDeleteDuration;
  final bool readReceipts;
  final bool typingIndicators;
  final bool lastSeen;
  final bool mediaAutoDownload;
  final String wallpaper;
  final Map<String, dynamic> customSettings;

  ChatSettings({
    this.muteNotifications = false,
    this.autoDeleteMessages = false,
    this.autoDeleteDuration,
    this.readReceipts = true,
    this.typingIndicators = true,
    this.lastSeen = true,
    this.mediaAutoDownload = true,
    this.wallpaper = 'default',
    this.customSettings = const {},
  });

  factory ChatSettings.fromJson(Map<String, dynamic> json) {
    return ChatSettings(
      muteNotifications: json['mute_notifications'] ?? false,
      autoDeleteMessages: json['auto_delete_messages'] ?? false,
      autoDeleteDuration: json['auto_delete_duration'] != null
          ? Duration(seconds: json['auto_delete_duration'])
          : null,
      readReceipts: json['read_receipts'] ?? true,
      typingIndicators: json['typing_indicators'] ?? true,
      lastSeen: json['last_seen'] ?? true,
      mediaAutoDownload: json['media_auto_download'] ?? true,
      wallpaper: json['wallpaper'] ?? 'default',
      customSettings: Map<String, dynamic>.from(json['custom_settings'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mute_notifications': muteNotifications,
      'auto_delete_messages': autoDeleteMessages,
      if (autoDeleteDuration != null)
        'auto_delete_duration': autoDeleteDuration!.inSeconds,
      'read_receipts': readReceipts,
      'typing_indicators': typingIndicators,
      'last_seen': lastSeen,
      'media_auto_download': mediaAutoDownload,
      'wallpaper': wallpaper,
      'custom_settings': customSettings,
    };
  }
}
