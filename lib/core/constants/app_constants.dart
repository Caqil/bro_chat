import 'package:flutter/material.dart';

class AppConstants {
  // App Information
  static const String appName = 'Bro Chat';
  static const String appSlogan = 'Connect with your bros';
  static const String appDescription =
      'A modern messaging app for staying connected';
  static const String appVersion = '1.0.0';
  static const String buildNumber = '1';
  static const String packageName = 'com.brochat.app';

  // Developer Information
  static const String developerName = 'Bro Chat Team';
  static const String developerEmail = 'support@brochat.com';
  static const String developerWebsite = 'https://brochat.com';

  // Store Information
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=$packageName';
  static const String appStoreUrl = 'https://apps.apple.com/app/id123456789';

  // Social Media
  static const String facebookUrl = 'https://facebook.com/brochat';
  static const String twitterUrl = 'https://twitter.com/brochat';
  static const String instagramUrl = 'https://instagram.com/brochat';
  static const String linkedinUrl = 'https://linkedin.com/company/brochat';

  // Legal URLs
  static const String privacyPolicyUrl = 'https://brochat.com/privacy';
  static const String termsOfServiceUrl = 'https://brochat.com/terms';
  static const String helpCenterUrl = 'https://help.brochat.com';
  static const String contactUsUrl = 'https://brochat.com/contact';

  // Animation Durations
  static const Duration fastAnimation = Duration(milliseconds: 150);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);
  static const Duration verySlowAnimation = Duration(milliseconds: 800);

  // UI Dimensions
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double extraLargePadding = 32.0;

  static const double defaultMargin = 16.0;
  static const double smallMargin = 8.0;
  static const double largeMargin = 24.0;
  static const double extraLargeMargin = 32.0;

  static const double defaultRadius = 12.0;
  static const double smallRadius = 8.0;
  static const double largeRadius = 16.0;
  static const double extraLargeRadius = 24.0;
  static const double circularRadius = 50.0;

  static const double defaultElevation = 4.0;
  static const double smallElevation = 2.0;
  static const double largeElevation = 8.0;

  // Icon Sizes
  static const double smallIconSize = 16.0;
  static const double defaultIconSize = 24.0;
  static const double largeIconSize = 32.0;
  static const double extraLargeIconSize = 48.0;

  // Avatar Sizes
  static const double smallAvatarSize = 32.0;
  static const double defaultAvatarSize = 48.0;
  static const double largeAvatarSize = 64.0;
  static const double extraLargeAvatarSize = 96.0;
  static const double profileAvatarSize = 120.0;

  // Button Heights
  static const double smallButtonHeight = 32.0;
  static const double defaultButtonHeight = 48.0;
  static const double largeButtonHeight = 56.0;

  // Input Field Heights
  static const double defaultInputHeight = 48.0;
  static const double largeInputHeight = 56.0;
  static const double multilineInputHeight = 120.0;

  // Message Bubble Dimensions
  static const double messageBubbleMaxWidth = 280.0;
  static const double messageBubbleMinHeight = 40.0;
  static const double messageBubblePadding = 12.0;
  static const double messageBubbleRadius = 16.0;

  // Chat UI Dimensions
  static const double chatTileHeight = 72.0;
  static const double messageInputHeight = 56.0;
  static const double attachmentButtonSize = 40.0;
  static const double voiceNoteButtonSize = 48.0;

  // Media Dimensions
  static const double thumbnailSize = 60.0;
  static const double mediaThumbnailSize = 200.0;
  static const double documentIconSize = 40.0;

  // Status Bar
  static const double statusBarHeight = 24.0;
  static const double appBarHeight = 56.0;
  static const double bottomNavHeight = 60.0;

  // Timeouts and Delays
  static const Duration networkTimeout = Duration(seconds: 30);
  static const Duration shortTimeout = Duration(seconds: 5);
  static const Duration mediumTimeout = Duration(seconds: 15);
  static const Duration longTimeout = Duration(minutes: 2);

  static const Duration typingTimeout = Duration(seconds: 3);
  static const Duration presenceTimeout = Duration(seconds: 30);
  static const Duration cacheTimeout = Duration(hours: 1);

  static const Duration debounceDelay = Duration(milliseconds: 500);
  static const Duration searchDelay = Duration(milliseconds: 300);
  static const Duration autoSaveDelay = Duration(seconds: 2);

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  static const int infiniteScrollThreshold = 5;

  // Limits
  static const int maxUsernameLength = 30;
  static const int minUsernameLength = 3;
  static const int maxNameLength = 50;
  static const int minNameLength = 2;
  static const int maxBioLength = 500;
  static const int maxStatusLength = 139;

  static const int maxMessageLength = 4096;
  static const int maxGroupNameLength = 50;
  static const int maxGroupDescriptionLength = 500;
  static const int maxGroupMembers = 256;

  static const int maxFileSize = 50 * 1024 * 1024; // 50MB
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const int maxVideoSize = 100 * 1024 * 1024; // 100MB
  static const int maxAudioSize = 10 * 1024 * 1024; // 10MB

  // Message Limits
  static const int maxMentions = 10;
  static const int maxBulkSelection = 100;
  static const int maxBulkDelete = 50;
  static const int maxSearchResults = 100;

  // Call Limits
  static const int maxCallDuration = 4 * 60 * 60; // 4 hours
  static const int maxCallParticipants = 10;
  static const int callRingingTimeout = 30;

  // Security
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int otpLength = 6;
  static const int maxOtpAttempts = 3;
  static const Duration otpExpiry = Duration(minutes: 5);
  static const Duration sessionTimeout = Duration(days: 30);

  // Local Storage Keys
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  static const String settingsKey = 'app_settings';
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language';
  static const String notificationKey = 'notification_settings';
  static const String privacyKey = 'privacy_settings';
  static const String onboardingKey = 'onboarding_completed';
  static const String deviceIdKey = 'device_id';
  static const String fcmTokenKey = 'fcm_token';

  // Notification Channels
  static const String messageChannelId = 'messages';
  static const String callChannelId = 'calls';
  static const String groupChannelId = 'groups';
  static const String systemChannelId = 'system';

  static const String messageChannelName = 'Messages';
  static const String callChannelName = 'Calls';
  static const String groupChannelName = 'Groups';
  static const String systemChannelName = 'System';

  // Supported File Types
  static const List<String> imageTypes = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
  static const List<String> videoTypes = ['mp4', 'mov', 'avi', 'mkv', '3gp'];
  static const List<String> audioTypes = ['mp3', 'wav', 'aac', 'ogg', 'm4a'];
  static const List<String> documentTypes = [
    'pdf',
    'doc',
    'docx',
    'xls',
    'xlsx',
    'ppt',
    'pptx',
    'txt',
  ];

  // Emoji Categories
  static const List<String> emojiCategories = [
    'Smileys & People',
    'Animals & Nature',
    'Food & Drink',
    'Activities',
    'Travel & Places',
    'Objects',
    'Symbols',
    'Flags',
  ];

  // Quick Reactions
  static const List<String> quickReactions = [
    '👍',
    '❤️',
    '😂',
    '😮',
    '😢',
    '😡',
  ];

  // Status Types
  static const String statusTypeText = 'text';
  static const String statusTypeImage = 'image';
  static const String statusTypeVideo = 'video';

  // Privacy Options
  static const String privacyEveryone = 'everyone';
  static const String privacyContacts = 'contacts';
  static const String privacyNobody = 'nobody';

  // Theme Options
  static const String themeSystem = 'system';
  static const String themeLight = 'light';
  static const String themeDark = 'dark';

  // Language Options
  static const Map<String, String> supportedLanguages = {
    'en': 'English',
    'es': 'Español',
    'fr': 'Français',
    'de': 'Deutsch',
    'it': 'Italiano',
    'pt': 'Português',
    'ru': 'Русский',
    'ja': '日本語',
    'ko': '한국어',
    'zh': '中文',
    'ar': 'العربية',
    'hi': 'हिन्दी',
  };

  // Date Formats
  static const String dateFormat = 'MMM dd, yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'MMM dd, yyyy HH:mm';
  static const String messageDateFormat = 'HH:mm';
  static const String chatListDateFormat = 'MMM dd';
  static const String fullDateFormat = 'EEEE, MMMM dd, yyyy';

  // Regular Expressions
  static const String emailRegex =
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const String phoneRegex = r'^\+?[1-9]\d{1,14}$';
  static const String usernameRegex = r'^[a-zA-Z0-9._-]{3,30}$';
  static const String urlRegex = r'https?://[^\s]+';
  static const String mentionRegex = r'@[\w.]+';

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
  static const bool enableBiometricAuth = true;
  static const bool enablePushNotifications = true;
  static const bool enableInAppPurchases = false;
  static const bool enableAnalytics = true;
  static const bool enableCrashReporting = true;

  // Default Values
  static const bool defaultNotificationsEnabled = true;
  static const bool defaultSoundEnabled = true;
  static const bool defaultVibrationEnabled = true;
  static const bool defaultPreviewEnabled = true;
  static const bool defaultGroupNotificationsEnabled = true;
  static const bool defaultReadReceiptsEnabled = true;
  static const bool defaultLastSeenEnabled = true;
  static const bool defaultOnlineStatusEnabled = true;
  static const bool defaultTypingIndicatorEnabled = true;

  // Asset Paths
  static const String iconPath = 'assets/icons';
  static const String imagePath = 'assets/images';
  static const String animationPath = 'assets/animations';
  static const String fontPath = 'assets/fonts';

  // Common Asset Names
  static const String appIcon = 'app_icon.png';
  static const String splashLogo = 'splash_logo.png';
  static const String onboardingImage1 = 'onboarding_1.png';
  static const String onboardingImage2 = 'onboarding_2.png';
  static const String onboardingImage3 = 'onboarding_3.png';
  static const String emptyChatsImage = 'empty_chats.png';
  static const String emptySearchImage = 'empty_search.png';
  static const String errorImage = 'error.png';

  // Audio Assets
  static const String messageSentSound = 'message_sent.mp3';
  static const String messageReceivedSound = 'message_received.mp3';
  static const String callIncomingSound = 'call_incoming.mp3';
  static const String callOutgoingSound = 'call_outgoing.mp3';
  static const String callEndSound = 'call_end.mp3';
  static const String notificationSound = 'notification.mp3';

  // Environment Variables
  static const String envDevelopment = 'development';
  static const String envStaging = 'staging';
  static const String envProduction = 'production';

  // Error Messages
  static const String networkErrorMessage =
      'Please check your internet connection';
  static const String serverErrorMessage =
      'Something went wrong. Please try again';
  static const String unknownErrorMessage = 'An unexpected error occurred';
  static const String timeoutErrorMessage =
      'Request timed out. Please try again';
  static const String unauthorizedErrorMessage =
      'You are not authorized to perform this action';
  static const String forbiddenErrorMessage = 'Access denied';
  static const String notFoundErrorMessage =
      'The requested resource was not found';

  // Success Messages
  static const String loginSuccessMessage = 'Login successful';
  static const String registrationSuccessMessage = 'Registration successful';
  static const String otpSentMessage = 'OTP sent successfully';
  static const String otpVerifiedMessage = 'Phone number verified successfully';
  static const String profileUpdatedMessage = 'Profile updated successfully';
  static const String passwordChangedMessage = 'Password changed successfully';
  static const String messageSentMessage = 'Message sent';
  static const String fileUploadedMessage = 'File uploaded successfully';
}
