import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';

import '../../core/constants/app_constants.dart';

class SecureStorage {
  static SecureStorage? _instance;
  late FlutterSecureStorage _storage;

  SecureStorage._internal() {
    _initializeStorage();
  }

  factory SecureStorage() {
    _instance ??= SecureStorage._internal();
    return _instance!;
  }

  void _initializeStorage() {
    const androidOptions = AndroidOptions(
      encryptedSharedPreferences: true,
      sharedPreferencesName: 'bro_chat_secure_prefs',
      preferencesKeyPrefix: 'brochat_',
    );

    const iosOptions = IOSOptions(
      groupId: 'group.com.brochat.app',
      accountName: 'BroChat',
      accessibility: KeychainAccessibility.first_unlock_this_device,
    );

    const linuxOptions = LinuxOptions();

    const webOptions = WebOptions(
      dbName: 'bro_chat_secure_storage',
      publicKey: 'BroChat-Storage-Key',
    );

    const macOsOptions = MacOsOptions(
      groupId: 'group.com.brochat.app',
      accountName: 'BroChat',
      accessibility: KeychainAccessibility.first_unlock_this_device,
    );

    const windowsOptions = WindowsOptions(useBackwardCompatibility: false);

    _storage = const FlutterSecureStorage(
      aOptions: androidOptions,
      iOptions: iosOptions,
      lOptions: linuxOptions,
      webOptions: webOptions,
      mOptions: macOsOptions,
      wOptions: windowsOptions,
    );
  }

  // Authentication tokens
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    try {
      await Future.wait([
        _storage.write(key: AppConstants.tokenKey, value: accessToken),
        _storage.write(key: AppConstants.refreshTokenKey, value: refreshToken),
        _storage.write(
          key: 'token_timestamp',
          value: DateTime.now().millisecondsSinceEpoch.toString(),
        ),
      ]);

      if (kDebugMode) {
        print('✅ Tokens saved successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving tokens: $e');
      }
      rethrow;
    }
  }

  Future<String?> getAccessToken() async {
    try {
      final token = await _storage.read(key: AppConstants.tokenKey);

      // Check if token is expired
      if (token != null && await _isTokenExpired()) {
        if (kDebugMode) {
          print('⚠️ Access token is expired');
        }
        return null;
      }

      return token;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting access token: $e');
      }
      return null;
    }
  }

  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: AppConstants.refreshTokenKey);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting refresh token: $e');
      }
      return null;
    }
  }

  Future<bool> hasValidTokens() async {
    try {
      final accessToken = await getAccessToken();
      final refreshToken = await getRefreshToken();
      return accessToken != null && refreshToken != null;
    } catch (e) {
      return false;
    }
  }

  Future<void> clearTokens() async {
    try {
      await Future.wait([
        _storage.delete(key: AppConstants.tokenKey),
        _storage.delete(key: AppConstants.refreshTokenKey),
        _storage.delete(key: 'token_timestamp'),
      ]);

      if (kDebugMode) {
        print('✅ Tokens cleared successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error clearing tokens: $e');
      }
    }
  }

  Future<bool> _isTokenExpired() async {
    try {
      final timestampStr = await _storage.read(key: 'token_timestamp');
      if (timestampStr == null) return true;

      final timestamp = int.tryParse(timestampStr);
      if (timestamp == null) return true;

      final tokenDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();

      // Consider token expired if it's older than 23 hours (1 hour buffer)
      return now.difference(tokenDate).inHours >= 23;
    } catch (e) {
      return true;
    }
  }

  // User data
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    try {
      final jsonString = jsonEncode(userData);
      await _storage.write(key: AppConstants.userKey, value: jsonString);

      if (kDebugMode) {
        print('✅ User data saved successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving user data: $e');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final jsonString = await _storage.read(key: AppConstants.userKey);
      if (jsonString == null) return null;

      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting user data: $e');
      }
      return null;
    }
  }

  Future<void> clearUserData() async {
    try {
      await _storage.delete(key: AppConstants.userKey);

      if (kDebugMode) {
        print('✅ User data cleared successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error clearing user data: $e');
      }
    }
  }

  // Device ID
  Future<void> saveDeviceId(String deviceId) async {
    try {
      await _storage.write(key: AppConstants.deviceIdKey, value: deviceId);

      if (kDebugMode) {
        print('✅ Device ID saved: $deviceId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving device ID: $e');
      }
      rethrow;
    }
  }

  Future<String?> getDeviceId() async {
    try {
      return await _storage.read(key: AppConstants.deviceIdKey);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting device ID: $e');
      }
      return null;
    }
  }

  // FCM Token
  Future<void> saveFcmToken(String fcmToken) async {
    try {
      await _storage.write(key: AppConstants.fcmTokenKey, value: fcmToken);

      if (kDebugMode) {
        print('✅ FCM token saved');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving FCM token: $e');
      }
      rethrow;
    }
  }

  Future<String?> getFcmToken() async {
    try {
      return await _storage.read(key: AppConstants.fcmTokenKey);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting FCM token: $e');
      }
      return null;
    }
  }

  // Biometric settings
  Future<void> setBiometricEnabled(bool enabled) async {
    try {
      await _storage.write(key: 'biometric_enabled', value: enabled.toString());
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error setting biometric enabled: $e');
      }
    }
  }

  Future<bool> isBiometricEnabled() async {
    try {
      final value = await _storage.read(key: 'biometric_enabled');
      return value == 'true';
    } catch (e) {
      return false;
    }
  }

  // Pin/Passcode
  Future<void> savePin(String pin) async {
    try {
      final hashedPin = _hashPin(pin);
      await _storage.write(key: 'user_pin', value: hashedPin);

      if (kDebugMode) {
        print('✅ Pin saved successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving pin: $e');
      }
      rethrow;
    }
  }

  Future<bool> verifyPin(String pin) async {
    try {
      final storedHash = await _storage.read(key: 'user_pin');
      if (storedHash == null) return false;

      final hashedPin = _hashPin(pin);
      return storedHash == hashedPin;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error verifying pin: $e');
      }
      return false;
    }
  }

  Future<bool> hasPin() async {
    try {
      final pin = await _storage.read(key: 'user_pin');
      return pin != null && pin.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<void> clearPin() async {
    try {
      await _storage.delete(key: 'user_pin');

      if (kDebugMode) {
        print('✅ Pin cleared successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error clearing pin: $e');
      }
    }
  }

  String _hashPin(String pin) {
    final bytes = utf8.encode(pin + 'brochat_salt_2024');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Chat encryption keys
  Future<void> saveChatKey(String chatId, String key) async {
    try {
      await _storage.write(key: 'chat_key_$chatId', value: key);

      if (kDebugMode) {
        print('✅ Chat key saved for: $chatId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving chat key: $e');
      }
      rethrow;
    }
  }

  Future<String?> getChatKey(String chatId) async {
    try {
      return await _storage.read(key: 'chat_key_$chatId');
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting chat key: $e');
      }
      return null;
    }
  }

  Future<void> deleteChatKey(String chatId) async {
    try {
      await _storage.delete(key: 'chat_key_$chatId');

      if (kDebugMode) {
        print('✅ Chat key deleted for: $chatId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error deleting chat key: $e');
      }
    }
  }

  // WebRTC credentials
  Future<void> saveWebRTCCredentials(Map<String, dynamic> credentials) async {
    try {
      final jsonString = jsonEncode(credentials);
      await _storage.write(key: 'webrtc_credentials', value: jsonString);

      if (kDebugMode) {
        print('✅ WebRTC credentials saved');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving WebRTC credentials: $e');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getWebRTCCredentials() async {
    try {
      final jsonString = await _storage.read(key: 'webrtc_credentials');
      if (jsonString == null) return null;

      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting WebRTC credentials: $e');
      }
      return null;
    }
  }

  // Security settings
  Future<void> saveSecuritySettings(Map<String, dynamic> settings) async {
    try {
      final jsonString = jsonEncode(settings);
      await _storage.write(key: 'security_settings', value: jsonString);

      if (kDebugMode) {
        print('✅ Security settings saved');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving security settings: $e');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getSecuritySettings() async {
    try {
      final jsonString = await _storage.read(key: 'security_settings');
      if (jsonString == null) return null;

      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting security settings: $e');
      }
      return null;
    }
  }

  // Generic secure storage methods
  Future<void> setString(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error setting string for key $key: $e');
      }
      rethrow;
    }
  }

  Future<String?> getString(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting string for key $key: $e');
      }
      return null;
    }
  }

  Future<void> setBool(String key, bool value) async {
    try {
      await _storage.write(key: key, value: value.toString());
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error setting bool for key $key: $e');
      }
      rethrow;
    }
  }

  Future<bool?> getBool(String key) async {
    try {
      final value = await _storage.read(key: key);
      if (value == null) return null;
      return value.toLowerCase() == 'true';
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting bool for key $key: $e');
      }
      return null;
    }
  }

  Future<void> setInt(String key, int value) async {
    try {
      await _storage.write(key: key, value: value.toString());
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error setting int for key $key: $e');
      }
      rethrow;
    }
  }

  Future<int?> getInt(String key) async {
    try {
      final value = await _storage.read(key: key);
      if (value == null) return null;
      return int.tryParse(value);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting int for key $key: $e');
      }
      return null;
    }
  }

  Future<void> setObject(String key, Map<String, dynamic> value) async {
    try {
      final jsonString = jsonEncode(value);
      await _storage.write(key: key, value: jsonString);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error setting object for key $key: $e');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getObject(String key) async {
    try {
      final jsonString = await _storage.read(key: key);
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
      await _storage.delete(key: key);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error removing key $key: $e');
      }
    }
  }

  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();

      if (kDebugMode) {
        print('✅ All secure storage cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error clearing all secure storage: $e');
      }
    }
  }

  Future<Map<String, String>> getAllKeys() async {
    try {
      return await _storage.readAll();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting all keys: $e');
      }
      return {};
    }
  }

  Future<bool> containsKey(String key) async {
    try {
      return await _storage.containsKey(key: key);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking if key exists $key: $e');
      }
      return false;
    }
  }

  // Backup and restore
  Future<Map<String, String>> exportData() async {
    try {
      final allData = await _storage.readAll();

      // Filter out sensitive data that shouldn't be backed up
      final filteredData = Map<String, String>.from(allData);
      filteredData.removeWhere(
        (key, value) =>
            key.contains('pin') ||
            key.contains('biometric') ||
            key.contains('chat_key_'),
      );

      return filteredData;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error exporting data: $e');
      }
      return {};
    }
  }

  Future<void> importData(Map<String, String> data) async {
    try {
      for (final entry in data.entries) {
        await _storage.write(key: entry.key, value: entry.value);
      }

      if (kDebugMode) {
        print('✅ Data imported successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error importing data: $e');
      }
      rethrow;
    }
  }

  // Session management
  Future<void> saveSessionInfo(Map<String, dynamic> sessionInfo) async {
    try {
      await setObject('session_info', sessionInfo);

      if (kDebugMode) {
        print('✅ Session info saved');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving session info: $e');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getSessionInfo() async {
    try {
      return await getObject('session_info');
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting session info: $e');
      }
      return null;
    }
  }

  Future<void> clearSession() async {
    try {
      await Future.wait([
        clearTokens(),
        clearUserData(),
        remove('session_info'),
      ]);

      if (kDebugMode) {
        print('✅ Session cleared successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error clearing session: $e');
      }
    }
  }
}
