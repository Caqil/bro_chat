import 'package:flutter/foundation.dart';

class AppConfig {
  static const String appName = 'Bro Chat';
  static const String appVersion = '1.0.0';
  static const String buildNumber = '1';

  // Environment Configuration
  static const bool isDevelopment = kDebugMode;
  static const bool isProduction = !kDebugMode;

  // API Configuration
  static String get baseUrl {
    return isDevelopment
        ? 'http://localhost:8080/api'
        : 'https://api.brochat.com/api';
  }

  static String get websocketUrl {
    return isDevelopment
        ? 'ws://localhost:8080/ws'
        : 'wss://api.brochat.com/ws';
  }

  // File Upload Configuration
  static const int maxFileSize = 50 * 1024 * 1024; // 50MB
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB for avatars
  static const List<String> allowedImageTypes = [
    'image/jpeg',
    'image/png',
    'image/gif',
    'image/webp',
  ];

  static const List<String> allowedVideoTypes = [
    'video/mp4',
    'video/mov',
    'video/avi',
    'video/mkv',
  ];

  static const List<String> allowedAudioTypes = [
    'audio/mp3',
    'audio/wav',
    'audio/aac',
    'audio/ogg',
  ];

  static const List<String> allowedDocumentTypes = [
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'text/plain',
  ];

  // Message Configuration
  static const int maxMessageLength = 4096;
  static const int maxMentions = 10;
  static const int maxBulkMessages = 100;
  static const int maxBulkDelete = 50;

  // Group Configuration
  static const int maxGroupMembers = 256;
  static const int maxGroupNameLength = 50;
  static const int maxGroupDescriptionLength = 500;

  // Call Configuration
  static const int maxCallParticipants = 10;
  static const int callTimeoutSeconds = 30;
  static const int reconnectAttempts = 3;

  // Cache Configuration
  static const Duration cacheExpiration = Duration(hours: 24);
  static const Duration tokenRefreshThreshold = Duration(minutes: 5);

  // Pagination Configuration
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  static const int chatPageSize = 50;
  static const int messagePageSize = 50;

  // Notification Configuration
  static const String fcmSenderId =
      '123456789012'; // Replace with your sender ID
  static const String fcmApiKey =
      'your-fcm-api-key'; // Replace with your API key

  // Security Configuration
  static const Duration otpExpiration = Duration(minutes: 5);
  static const int maxOtpAttempts = 3;
  static const Duration sessionTimeout = Duration(hours: 24);

  // UI Configuration
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration toastDuration = Duration(seconds: 3);
  static const Duration typingIndicatorTimeout = Duration(seconds: 3);

  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
  static const String settingsKey = 'app_settings';
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language_code';

  // Deep Link Configuration
  static const String appScheme = 'brochat';
  static const String webDomain = 'brochat.com';

  // Feature Flags
  static const bool enableVoiceCalls = true;
  static const bool enableVideoCalls = true;
  static const bool enableGroupCalls = true;
  static const bool enableScreenSharing = true;
  static const bool enableLocationSharing = true;
  static const bool enableContactSharing = true;
  static const bool enableStatusFeature = true;
  static const bool enableE2EEncryption = true;
  static const bool enableCloudBackup = true;
  static const bool enableDarkMode = true;

  // Debug Configuration
  static const bool enableNetworkLogs = isDevelopment;
  static const bool enableWebSocketLogs = isDevelopment;
  static const bool enablePerformanceLogs = isDevelopment;

  // Rate Limiting
  static const int maxMessagesPerMinute = 60;
  static const int maxCallsPerHour = 10;
  static const int maxFileUploadsPerHour = 50;

  // Validation Configuration
  static RegExp get phoneNumberRegex => RegExp(r'^\+?[1-9]\d{1,14}$');
  static RegExp get usernameRegex => RegExp(r'^[a-zA-Z0-9._-]{3,30}$');
  static RegExp get emailRegex =>
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

  // Country Codes (Sample - Add more as needed)
  static const Map<String, String> countryCodes = {
    'US': '+1',
    'GB': '+44',
    'IN': '+91',
    'CA': '+1',
    'AU': '+61',
    'DE': '+49',
    'FR': '+33',
    'IT': '+39',
    'ES': '+34',
    'BR': '+55',
    'JP': '+81',
    'KR': '+82',
    'CN': '+86',
    'RU': '+7',
    'SA': '+966',
    'AE': '+971',
    'PK': '+92',
    'BD': '+880',
    'NG': '+234',
    'EG': '+20',
  };

  // Time Zones
  static const List<String> supportedTimeZones = [
    'UTC',
    'America/New_York',
    'America/Los_Angeles',
    'Europe/London',
    'Europe/Berlin',
    'Asia/Tokyo',
    'Asia/Shanghai',
    'Asia/Kolkata',
    'Australia/Sydney',
  ];

  // Language Codes
  static const List<String> supportedLanguages = [
    'en', // English
    'es', // Spanish
    'fr', // French
    'de', // German
    'it', // Italian
    'pt', // Portuguese
    'ru', // Russian
    'ja', // Japanese
    'ko', // Korean
    'zh', // Chinese
    'ar', // Arabic
    'hi', // Hindi
  ];

  // Media Quality Settings
  static const Map<String, Map<String, dynamic>> mediaQuality = {
    'image': {
      'thumbnail': {'width': 150, 'height': 150, 'quality': 70},
      'preview': {'width': 800, 'height': 600, 'quality': 80},
      'full': {'width': 1920, 'height': 1080, 'quality': 90},
    },
    'video': {
      'low': {'width': 480, 'height': 360, 'bitrate': 500000},
      'medium': {'width': 720, 'height': 480, 'bitrate': 1000000},
      'high': {'width': 1280, 'height': 720, 'bitrate': 2000000},
    },
    'audio': {
      'low': {'bitrate': 64000, 'sampleRate': 22050},
      'medium': {'bitrate': 128000, 'sampleRate': 44100},
      'high': {'bitrate': 192000, 'sampleRate': 48000},
    },
  };

  // WebRTC Configuration
  static const Map<String, dynamic> webrtcConfig = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ],
    'iceCandidatePoolSize': 10,
    'bundlePolicy': 'max-bundle',
    'rtcpMuxPolicy': 'require',
  };
}
