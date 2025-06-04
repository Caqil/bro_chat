import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';

class LocalStorage {
  static LocalStorage? _instance;
  SharedPreferences? _prefs;

  LocalStorage._internal();

  factory LocalStorage() {
    _instance ??= LocalStorage._internal();
    return _instance!;
  }

  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();

      if (kDebugMode) {
        print('✅ Local storage initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing local storage: $e');
      }
      rethrow;
    }
  }

  SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('LocalStorage not initialized. Call init() first.');
    }
    return _prefs!;
  }

  // App Settings
  Future<void> setThemeMode(String themeMode) async {
    try {
      await prefs.setString(AppConstants.themeKey, themeMode);

      if (kDebugMode) {
        print('✅ Theme mode set to: $themeMode');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error setting theme mode: $e');
      }
    }
  }

  String getThemeMode() {
    try {
      return prefs.getString(AppConstants.themeKey) ?? AppConstants.themeSystem;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting theme mode: $e');
      }
      return AppConstants.themeSystem;
    }
  }

  Future<void> setLanguage(String languageCode) async {
    try {
      await prefs.setString(AppConstants.languageKey, languageCode);

      if (kDebugMode) {
        print('✅ Language set to: $languageCode');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error setting language: $e');
      }
    }
  }

  String getLanguage() {
    try {
      return prefs.getString(AppConstants.languageKey) ?? 'en';
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting language: $e');
      }
      return 'en';
    }
  }

  // Notification Settings
  Future<void> setNotificationSettings(Map<String, dynamic> settings) async {
    try {
      final jsonString = jsonEncode(settings);
      await prefs.setString(AppConstants.notificationKey, jsonString);

      if (kDebugMode) {
        print('✅ Notification settings saved');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error setting notification settings: $e');
      }
    }
  }

  Map<String, dynamic> getNotificationSettings() {
    try {
      final jsonString = prefs.getString(AppConstants.notificationKey);
      if (jsonString == null) {
        return _getDefaultNotificationSettings();
      }

      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting notification settings: $e');
      }
      return _getDefaultNotificationSettings();
    }
  }

  Map<String, dynamic> _getDefaultNotificationSettings() {
    return {
      'enabled': AppConstants.defaultNotificationsEnabled,
      'sound': AppConstants.defaultSoundEnabled,
      'vibration': AppConstants.defaultVibrationEnabled,
      'preview': AppConstants.defaultPreviewEnabled,
      'group_notifications': AppConstants.defaultGroupNotificationsEnabled,
      'call_notifications': true,
      'status_notifications': true,
      'message_sound': AppConstants.messageReceivedSound,
      'call_sound': AppConstants.callIncomingSound,
      'do_not_disturb': false,
      'quiet_hours_start': '22:00',
      'quiet_hours_end': '07:00',
    };
  }

  // Privacy Settings
  Future<void> setPrivacySettings(Map<String, dynamic> settings) async {
    try {
      final jsonString = jsonEncode(settings);
      await prefs.setString(AppConstants.privacyKey, jsonString);

      if (kDebugMode) {
        print('✅ Privacy settings saved');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error setting privacy settings: $e');
      }
    }
  }

  Map<String, dynamic> getPrivacySettings() {
    try {
      final jsonString = prefs.getString(AppConstants.privacyKey);
      if (jsonString == null) {
        return _getDefaultPrivacySettings();
      }

      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting privacy settings: $e');
      }
      return _getDefaultPrivacySettings();
    }
  }

  Map<String, dynamic> _getDefaultPrivacySettings() {
    return {
      'last_seen': AppConstants.privacyContacts,
      'profile_photo': AppConstants.privacyContacts,
      'about': AppConstants.privacyContacts,
      'status': AppConstants.privacyContacts,
      'read_receipts': AppConstants.defaultReadReceiptsEnabled,
      'groups': AppConstants.privacyContacts,
      'online_status': AppConstants.defaultOnlineStatusEnabled,
      'typing_indicator': AppConstants.defaultTypingIndicatorEnabled,
      'blocked_users': <String>[],
    };
  }

  // Chat Settings
  Future<void> setChatSettings(Map<String, dynamic> settings) async {
    try {
      final jsonString = jsonEncode(settings);
      await prefs.setString('chat_settings', jsonString);

      if (kDebugMode) {
        print('✅ Chat settings saved');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error setting chat settings: $e');
      }
    }
  }

  Map<String, dynamic> getChatSettings() {
    try {
      final jsonString = prefs.getString('chat_settings');
      if (jsonString == null) {
        return _getDefaultChatSettings();
      }

      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting chat settings: $e');
      }
      return _getDefaultChatSettings();
    }
  }

  Map<String, dynamic> _getDefaultChatSettings() {
    return {
      'wallpaper': 'default',
      'font_size': 'medium',
      'bubble_style': 'modern',
      'enter_to_send': false,
      'auto_download_photos': true,
      'auto_download_videos': false,
      'auto_download_documents': false,
      'auto_download_audio': true,
      'save_photos_to_gallery': true,
      'compression_quality': 'medium',
      'show_typing_indicator': true,
      'show_read_receipts': true,
    };
  }

  // Call Settings
  Future<void> setCallSettings(Map<String, dynamic> settings) async {
    try {
      final jsonString = jsonEncode(settings);
      await prefs.setString('call_settings', jsonString);

      if (kDebugMode) {
        print('✅ Call settings saved');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error setting call settings: $e');
      }
    }
  }

  Map<String, dynamic> getCallSettings() {
    try {
      final jsonString = prefs.getString('call_settings');
      if (jsonString == null) {
        return _getDefaultCallSettings();
      }

      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting call settings: $e');
      }
      return _getDefaultCallSettings();
    }
  }

  Map<String, dynamic> _getDefaultCallSettings() {
    return {
      'use_cellular_data': false,
      'low_data_usage': false,
      'auto_answer_speaker': false,
      'noise_reduction': true,
      'echo_cancellation': true,
      'video_quality': 'medium',
      'audio_quality': 'high',
      'camera_position': 'front',
      'proximity_sensor': true,
    };
  }

  // Media Settings
  Future<void> setMediaSettings(Map<String, dynamic> settings) async {
    try {
      final jsonString = jsonEncode(settings);
      await prefs.setString('media_settings', jsonString);

      if (kDebugMode) {
        print('✅ Media settings saved');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error setting media settings: $e');
      }
    }
  }

  Map<String, dynamic> getMediaSettings() {
    try {
      final jsonString = prefs.getString('media_settings');
      if (jsonString == null) {
        return _getDefaultMediaSettings();
      }

      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting media settings: $e');
      }
      return _getDefaultMediaSettings();
    }
  }

  Map<String, dynamic> _getDefaultMediaSettings() {
    return {
      'photo_upload_quality': 'auto',
      'video_upload_quality': 'auto',
      'document_auto_download': false,
      'voice_note_boost': false,
      'media_visibility': true,
      'auto_play_gifs': true,
      'auto_play_videos': false,
      'download_path': 'default',
    };
  }

  // Onboarding
  Future<void> setOnboardingCompleted(bool completed) async {
    try {
      await prefs.setBool(AppConstants.onboardingKey, completed);

      if (kDebugMode) {
        print('✅ Onboarding status set to: $completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error setting onboarding status: $e');
      }
    }
  }

  bool isOnboardingCompleted() {
    try {
      return prefs.getBool(AppConstants.onboardingKey) ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting onboarding status: $e');
      }
      return false;
    }
  }

  // First launch
  Future<void> setFirstLaunch(bool isFirst) async {
    try {
      await prefs.setBool('first_launch', isFirst);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error setting first launch: $e');
      }
    }
  }

  bool isFirstLaunch() {
    try {
      return prefs.getBool('first_launch') ?? true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting first launch: $e');
      }
      return true;
    }
  }

  // App version tracking
  Future<void> setAppVersion(String version) async {
    try {
      await prefs.setString('app_version', version);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error setting app version: $e');
      }
    }
  }

  String? getAppVersion() {
    try {
      return prefs.getString('app_version');
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting app version: $e');
      }
      return null;
    }
  }

  // Debug settings
  Future<void> setDebugMode(bool enabled) async {
    try {
      await prefs.setBool('debug_mode', enabled);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error setting debug mode: $e');
      }
    }
  }

  bool isDebugMode() {
    try {
      return prefs.getBool('debug_mode') ?? false;
    } catch (e) {
      return false;
    }
  }

  // Recent searches
  Future<void> addRecentSearch(String query) async {
    try {
      final searches = getRecentSearches();
      searches.remove(query); // Remove if already exists
      searches.insert(0, query); // Add to beginning

      // Keep only last 20 searches
      if (searches.length > 20) {
        searches.removeRange(20, searches.length);
      }

      await prefs.setStringList('recent_searches', searches);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error adding recent search: $e');
      }
    }
  }

  List<String> getRecentSearches() {
    try {
      return prefs.getStringList('recent_searches') ?? [];
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting recent searches: $e');
      }
      return [];
    }
  }

  Future<void> clearRecentSearches() async {
    try {
      await prefs.remove('recent_searches');
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error clearing recent searches: $e');
      }
    }
  }

  // Favorite contacts
  Future<void> addFavoriteContact(String contactId) async {
    try {
      final favorites = getFavoriteContacts();
      if (!favorites.contains(contactId)) {
        favorites.add(contactId);
        await prefs.setStringList('favorite_contacts', favorites);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error adding favorite contact: $e');
      }
    }
  }

  Future<void> removeFavoriteContact(String contactId) async {
    try {
      final favorites = getFavoriteContacts();
      favorites.remove(contactId);
      await prefs.setStringList('favorite_contacts', favorites);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error removing favorite contact: $e');
      }
    }
  }

  List<String> getFavoriteContacts() {
    try {
      return prefs.getStringList('favorite_contacts') ?? [];
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting favorite contacts: $e');
      }
      return [];
    }
  }

  // Blocked contacts (local cache)
  Future<void> setBlockedContacts(List<String> blockedIds) async {
    try {
      await prefs.setStringList('blocked_contacts', blockedIds);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error setting blocked contacts: $e');
      }
    }
  }

  List<String> getBlockedContacts() {
    try {
      return prefs.getStringList('blocked_contacts') ?? [];
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting blocked contacts: $e');
      }
      return [];
    }
  }

  // Chat wallpapers
  Future<void> setChatWallpaper(String chatId, String wallpaperPath) async {
    try {
      await prefs.setString('wallpaper_$chatId', wallpaperPath);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error setting chat wallpaper: $e');
      }
    }
  }

  String? getChatWallpaper(String chatId) {
    try {
      return prefs.getString('wallpaper_$chatId');
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting chat wallpaper: $e');
      }
      return null;
    }
  }

  Future<void> removeChatWallpaper(String chatId) async {
    try {
      await prefs.remove('wallpaper_$chatId');
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error removing chat wallpaper: $e');
      }
    }
  }

  // Draft messages
  Future<void> setDraftMessage(String chatId, String content) async {
    try {
      await prefs.setString('draft_$chatId', content);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error setting draft message: $e');
      }
    }
  }

  String? getDraftMessage(String chatId) {
    try {
      return prefs.getString('draft_$chatId');
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting draft message: $e');
      }
      return null;
    }
  }

  Future<void> clearDraftMessage(String chatId) async {
    try {
      await prefs.remove('draft_$chatId');
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error clearing draft message: $e');
      }
    }
  }

  // Last seen timestamps
  Future<void> setLastSeenChat(String chatId, DateTime timestamp) async {
    try {
      await prefs.setInt('last_seen_$chatId', timestamp.millisecondsSinceEpoch);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error setting last seen chat: $e');
      }
    }
  }

  DateTime? getLastSeenChat(String chatId) {
    try {
      final timestamp = prefs.getInt('last_seen_$chatId');
      if (timestamp == null) return null;
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting last seen chat: $e');
      }
      return null;
    }
  }

  // Usage statistics
  Future<void> incrementMessageCount() async {
    try {
      final count = getMessageCount();
      await prefs.setInt('message_count', count + 1);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error incrementing message count: $e');
      }
    }
  }

  int getMessageCount() {
    try {
      return prefs.getInt('message_count') ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<void> incrementCallCount() async {
    try {
      final count = getCallCount();
      await prefs.setInt('call_count', count + 1);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error incrementing call count: $e');
      }
    }
  }

  int getCallCount() {
    try {
      return prefs.getInt('call_count') ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // Data usage tracking
  Future<void> addDataUsage(int bytes, String type) async {
    try {
      final key = 'data_usage_$type';
      final current = prefs.getInt(key) ?? 0;
      await prefs.setInt(key, current + bytes);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error adding data usage: $e');
      }
    }
  }

  int getDataUsage(String type) {
    try {
      return prefs.getInt('data_usage_$type') ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<void> resetDataUsage() async {
    try {
      final keys = prefs.getKeys().where(
        (key) => key.startsWith('data_usage_'),
      );
      for (final key in keys) {
        await prefs.remove(key);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error resetting data usage: $e');
      }
    }
  }

  // Generic methods
  Future<void> setString(String key, String value) async {
    try {
      await prefs.setString(key, value);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error setting string for key $key: $e');
      }
    }
  }

  String? getString(String key) {
    try {
      return prefs.getString(key);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting string for key $key: $e');
      }
      return null;
    }
  }

  Future<void> setBool(String key, bool value) async {
    try {
      await prefs.setBool(key, value);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error setting bool for key $key: $e');
      }
    }
  }

  bool? getBool(String key) {
    try {
      return prefs.getBool(key);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting bool for key $key: $e');
      }
      return null;
    }
  }

  Future<void> setInt(String key, int value) async {
    try {
      await prefs.setInt(key, value);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error setting int for key $key: $e');
      }
    }
  }

  int? getInt(String key) {
    try {
      return prefs.getInt(key);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting int for key $key: $e');
      }
      return null;
    }
  }

  Future<void> setDouble(String key, double value) async {
    try {
      await prefs.setDouble(key, value);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error setting double for key $key: $e');
      }
    }
  }

  double? getDouble(String key) {
    try {
      return prefs.getDouble(key);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting double for key $key: $e');
      }
      return null;
    }
  }

  Future<void> setStringList(String key, List<String> value) async {
    try {
      await prefs.setStringList(key, value);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error setting string list for key $key: $e');
      }
    }
  }

  List<String>? getStringList(String key) {
    try {
      return prefs.getStringList(key);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting string list for key $key: $e');
      }
      return null;
    }
  }

  Future<void> setObject(String key, Map<String, dynamic> value) async {
    try {
      final jsonString = jsonEncode(value);
      await prefs.setString(key, jsonString);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error setting object for key $key: $e');
      }
    }
  }

  Map<String, dynamic>? getObject(String key) {
    try {
      final jsonString = prefs.getString(key);
      if (jsonString == null) return null;

      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting object for key $key: $e');
      }
      return null;
    }
  }

  Future<void> remove(String key) async {
    try {
      await prefs.remove(key);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error removing key $key: $e');
      }
    }
  }

  Future<void> clear() async {
    try {
      await prefs.clear();

      if (kDebugMode) {
        print('✅ Local storage cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error clearing local storage: $e');
      }
    }
  }

  Set<String> getKeys() {
    try {
      return prefs.getKeys();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting keys: $e');
      }
      return <String>{};
    }
  }

  bool containsKey(String key) {
    try {
      return prefs.containsKey(key);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking if key exists $key: $e');
      }
      return false;
    }
  }

  // Export/import for backup
  Map<String, dynamic> exportSettings() {
    try {
      final allKeys = getKeys();
      final settings = <String, dynamic>{};

      for (final key in allKeys) {
        // Skip sensitive or temporary data
        if (key.startsWith('draft_') ||
            key.startsWith('last_seen_') ||
            key.contains('cache_')) {
          continue;
        }

        final value = prefs.get(key);
        if (value != null) {
          settings[key] = value;
        }
      }

      return settings;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error exporting settings: $e');
      }
      return {};
    }
  }

  Future<void> importSettings(Map<String, dynamic> settings) async {
    try {
      for (final entry in settings.entries) {
        final value = entry.value;

        if (value is String) {
          await prefs.setString(entry.key, value);
        } else if (value is bool) {
          await prefs.setBool(entry.key, value);
        } else if (value is int) {
          await prefs.setInt(entry.key, value);
        } else if (value is double) {
          await prefs.setDouble(entry.key, value);
        } else if (value is List<String>) {
          await prefs.setStringList(entry.key, value);
        }
      }

      if (kDebugMode) {
        print('✅ Settings imported successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error importing settings: $e');
      }
    }
  }
  Future<bool> setMap(String key, Map<String, dynamic> value) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(value);
    return await prefs.setString(key, jsonString);
  } catch (e) {
    if (kDebugMode) {
      print('❌ Error setting map: $e');
    }
    return false;
  }
}

// Get a Map from JSON string
Map<String, dynamic>? getMap(String key) {
  try {
    final prefs = _prefs;
    if (prefs == null) return null;
    
    final jsonString = prefs.getString(key);
    if (jsonString == null) return null;
    
    return Map<String, dynamic>.from(jsonDecode(jsonString));
  } catch (e) {
    if (kDebugMode) {
      print('❌ Error getting map: $e');
    }
    return null;
  }
}
}
