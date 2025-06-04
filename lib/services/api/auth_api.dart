import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/dio_config.dart';
import '../../core/constants/api_constants.dart';
import '../../core/exceptions/network_exception.dart';
import '../../core/exceptions/auth_exception.dart';
import '../../models/auth/auth_response.dart';
import '../../models/auth/user_model.dart';
import '../../models/auth/login_request.dart';
import '../../models/auth/register_request.dart';
import '../../models/auth/otp_request.dart';
import '../../models/common/api_response.dart';

class AuthAPI {
  final Dio _dio;

  AuthAPI(this._dio);

  /// Register a new user
  Future<ApiResponse<AuthResponse>> register(RegisterRequest request) async {
    try {
      final response = await _dio.post(
        ApiConstants.authRegister,
        data: request.toJson(),
      );

      return ApiResponse.fromJson(
        response.data,
        (data) => AuthResponse.fromJson(data),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Verify OTP during registration
  Future<ApiResponse<AuthResponse>> verifyOTP(OTPRequest request) async {
    try {
      final response = await _dio.post(
        ApiConstants.authVerifyOTP,
        data: request.toJson(),
      );

      return ApiResponse.fromJson(
        response.data,
        (data) => AuthResponse.fromJson(data),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Login with phone number and password
  Future<ApiResponse<AuthResponse>> login(LoginRequest request) async {
    try {
      final response = await _dio.post(
        ApiConstants.authLogin,
        data: request.toJson(),
      );

      return ApiResponse.fromJson(
        response.data,
        (data) => AuthResponse.fromJson(data),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Refresh access token
  Future<ApiResponse<AuthResponse>> refreshToken(String refreshToken) async {
    try {
      final response = await _dio.post(
        ApiConstants.authRefresh,
        data: {'refresh_token': refreshToken},
      );

      return ApiResponse.fromJson(
        response.data,
        (data) => AuthResponse.fromJson(data),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Resend OTP
  Future<ApiResponse<void>> resendOTP(ResendOTPRequest request) async {
    try {
      final response = await _dio.post(
        ApiConstants.authResendOTP,
        data: request.toJson(),
      );

      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Logout user
  Future<ApiResponse<void>> logout() async {
    try {
      final response = await _dio.post(ApiConstants.authLogout);
      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Validate current token
  Future<ApiResponse<void>> validateToken() async {
    try {
      final response = await _dio.get(ApiConstants.authValidate);
      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get current user profile
  Future<ApiResponse<UserModel>> getProfile() async {
    try {
      final response = await _dio.get(ApiConstants.authProfile);
      return ApiResponse.fromJson(
        response.data,
        (data) => UserModel.fromJson(data),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Update user profile
  Future<ApiResponse<UserModel>> updateProfile({
    String? name,
    String? email,
    String? username,
    String? bio,
    String? avatar,
    Map<String, dynamic>? privacySettings,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (email != null) updateData['email'] = email;
      if (username != null) updateData['username'] = username;
      if (bio != null) updateData['bio'] = bio;
      if (avatar != null) updateData['avatar'] = avatar;
      if (privacySettings != null)
        updateData['privacy_settings'] = privacySettings;

      final response = await _dio.put(
        ApiConstants.authProfile,
        data: updateData,
      );

      return ApiResponse.fromJson(
        response.data,
        (data) => UserModel.fromJson(data),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Change password
  Future<ApiResponse<void>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.put(
        ApiConstants.authChangePassword,
        data: {'old_password': oldPassword, 'new_password': newPassword},
      );

      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Update online status
  Future<ApiResponse<void>> updateOnlineStatus(bool isOnline) async {
    try {
      final response = await _dio.put(
        '${ApiConstants.authProfile}/status',
        data: {
          'is_online': isOnline,
          if (!isOnline) 'last_seen': DateTime.now().toIso8601String(),
        },
      );

      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get user devices
  Future<ApiResponse<List<DeviceModel>>> getDevices() async {
    try {
      final response = await _dio.get(ApiConstants.authDevices);
      return ApiResponse.fromJson(
        response.data,
        (data) => (data as List)
            .map((device) => DeviceModel.fromJson(device))
            .toList(),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Register device for push notifications
  Future<ApiResponse<void>> registerDevice({
    required String deviceId,
    required String fcmToken,
    required String platform,
    String? deviceName,
  }) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.authDevices}/register',
        data: {
          'device_id': deviceId,
          'fcm_token': fcmToken,
          'platform': platform,
          if (deviceName != null) 'device_name': deviceName,
        },
      );

      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Update FCM token
  Future<ApiResponse<void>> updateFCMToken(String fcmToken) async {
    try {
      final response = await _dio.put(
        '${ApiConstants.authDevices}/fcm-token',
        data: {'fcm_token': fcmToken},
      );

      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Remove device
  Future<ApiResponse<void>> removeDevice(String deviceId) async {
    try {
      final response = await _dio.delete(
        '${ApiConstants.authDevices}/$deviceId',
      );
      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Search users by phone number or username
  Future<ApiResponse<List<UserModel>>> searchUsers({
    required String query,
    int limit = 10,
  }) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.authProfile}/search',
        queryParameters: {'q': query, 'limit': limit},
      );

      return ApiResponse.fromJson(
        response.data,
        (data) =>
            (data as List).map((user) => UserModel.fromJson(user)).toList(),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get user by ID
  Future<ApiResponse<UserModel>> getUserById(String userId) async {
    try {
      final response = await _dio.get('${ApiConstants.authProfile}/$userId');
      return ApiResponse.fromJson(
        response.data,
        (data) => UserModel.fromJson(data),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Block user
  Future<ApiResponse<void>> blockUser(String userId) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.authProfile}/block/$userId',
      );
      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Unblock user
  Future<ApiResponse<void>> unblockUser(String userId) async {
    try {
      final response = await _dio.delete(
        '${ApiConstants.authProfile}/block/$userId',
      );
      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get blocked users
  Future<ApiResponse<List<UserModel>>> getBlockedUsers() async {
    try {
      final response = await _dio.get('${ApiConstants.authProfile}/blocked');
      return ApiResponse.fromJson(
        response.data,
        (data) =>
            (data as List).map((user) => UserModel.fromJson(user)).toList(),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Request account deletion
  Future<ApiResponse<void>> requestAccountDeletion({
    required String reason,
    String? feedback,
  }) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.authProfile}/delete-request',
        data: {'reason': reason, if (feedback != null) 'feedback': feedback},
      );

      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Cancel account deletion request
  Future<ApiResponse<void>> cancelAccountDeletion() async {
    try {
      final response = await _dio.delete(
        '${ApiConstants.authProfile}/delete-request',
      );
      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Export user data
  Future<ApiResponse<Map<String, dynamic>>> exportUserData() async {
    try {
      final response = await _dio.get('${ApiConstants.authProfile}/export');
      return ApiResponse.fromJson(response.data, (data) => data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Enable two-factor authentication
  Future<ApiResponse<Map<String, dynamic>>> enableTwoFactor() async {
    try {
      final response = await _dio.post(
        '${ApiConstants.authProfile}/2fa/enable',
      );
      return ApiResponse.fromJson(response.data, (data) => data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Disable two-factor authentication
  Future<ApiResponse<void>> disableTwoFactor(String code) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.authProfile}/2fa/disable',
        data: {'code': code},
      );
      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Verify two-factor authentication code
  Future<ApiResponse<void>> verifyTwoFactor(String code) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.authProfile}/2fa/verify',
        data: {'code': code},
      );
      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException error) {
    switch (error.response?.statusCode) {
      case 400:
        return AuthException.invalidCredentials(
          error.response?.data?['message'],
        );
      case 401:
        return AuthException.sessionExpired();
      case 403:
        return AuthException.forbidden();
      case 404:
        return AuthException.userNotFound();
      case 409:
        final message = error.response?.data?['message'] ?? '';
        if (message.contains('phone')) {
          return AuthException.phoneNumberExists();
        } else if (message.contains('email')) {
          return AuthException.emailExists();
        } else if (message.contains('username')) {
          return AuthException.usernameExists();
        }
        return AuthException.userAlreadyExists();
      case 422:
        return AuthException.invalidPhoneNumber(
          error.response?.data?['message'],
        );
      case 429:
        return AuthException.tooManyLoginAttempts();
      default:
        return NetworkException.fromStatusCode(
          error.response?.statusCode ?? 0,
          error.response?.data?['message'] ?? 'Unknown error',
        );
    }
  }
}

// Data models for requests
class ResendOTPRequest {
  final String phoneNumber;
  final String countryCode;

  ResendOTPRequest({required this.phoneNumber, required this.countryCode});

  Map<String, dynamic> toJson() {
    return {'phone_number': phoneNumber, 'country_code': countryCode};
  }
}

class DeviceModel {
  final String id;
  final String name;
  final String platform;
  final DateTime lastSeen;
  final bool isActive;
  final bool isCurrent;

  DeviceModel({
    required this.id,
    required this.name,
    required this.platform,
    required this.lastSeen,
    required this.isActive,
    this.isCurrent = false,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: json['id'],
      name: json['name'],
      platform: json['platform'],
      lastSeen: DateTime.parse(json['last_seen']),
      isActive: json['is_active'] ?? false,
      isCurrent: json['is_current'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'platform': platform,
      'last_seen': lastSeen.toIso8601String(),
      'is_active': isActive,
      'is_current': isCurrent,
    };
  }
}

// Riverpod provider
final authAPIProvider = Provider<AuthAPI>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthAPI(dio);
});
