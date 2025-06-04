import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/config/dio_config.dart';
import '../../models/auth/auth_response.dart';
import '../../models/auth/user_model.dart';
import '../../models/auth/login_request.dart';
import '../../models/auth/register_request.dart';
import '../../models/auth/otp_request.dart';
import '../../models/common/api_response.dart';
import '../../core/constants/api_constants.dart';
import '../../services/storage/secure_storage.dart';
import 'auth_state.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final Dio _dio;
  final SecureStorage _storage;
  Timer? _tokenRefreshTimer;

  AuthNotifier(this._dio, this._storage) : super(const AuthState.initial()) {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    state = const AuthState.loading();

    try {
      final accessToken = await _storage.getAccessToken();
      final refreshToken = await _storage.getRefreshToken();

      if (accessToken != null && refreshToken != null) {
        // Validate token
        final isValid = await _validateToken(accessToken);
        if (isValid) {
          final user = await _getCurrentUser();
          if (user != null) {
            state = AuthState.authenticated(
              user: user,
              accessToken: accessToken,
              refreshToken: refreshToken,
            );
            _scheduleTokenRefresh();
            return;
          }
        }
      }

      state = const AuthState.unauthenticated();
    } catch (e) {
      state = const AuthState.unauthenticated();
    }
  }

  Future<bool> register(RegisterRequest request) async {
    state = const AuthState.loading();

    try {
      final response = await _dio.post(
        ApiConstants.authRegister,
        data: request.toJson(),
      );

      final apiResponse = ApiResponse.fromJson(
        response.data,
        (data) => AuthResponse.fromJson(data),
      );

      if (apiResponse.success && apiResponse.data != null) {
        final authResponse = apiResponse.data!;

        // Check if we have valid auth data
        if (authResponse.accessToken != null &&
            authResponse.refreshToken != null &&
            authResponse.user != null) {
          await _saveTokens(
            authResponse.accessToken!,
            authResponse.refreshToken!,
          );

          state = AuthState.authenticated(
            user: authResponse.user!,
            accessToken: authResponse.accessToken!,
            refreshToken: authResponse.refreshToken!,
          );
          _scheduleTokenRefresh();
          return true;
        } else {
          state = AuthState.error('Invalid authentication data received');
          return false;
        }
      } else {
        state = AuthState.error(apiResponse.message);
        return false;
      }
    } on DioException catch (e) {
      final errorMessage =
          e.response?.data?['message'] ?? 'Registration failed';
      state = AuthState.error(errorMessage);
      return false;
    } catch (e) {
      state = AuthState.error('An unexpected error occurred');
      return false;
    }
  }

  Future<bool> verifyOTP(OTPRequest request) async {
    state = const AuthState.loading();

    try {
      final response = await _dio.post(
        ApiConstants.authVerifyOTP,
        data: request.toJson(),
      );

      final apiResponse = ApiResponse.fromJson(
        response.data,
        (data) => AuthResponse.fromJson(data),
      );

      if (apiResponse.success && apiResponse.data != null) {
        final authResponse = apiResponse.data!;

        // Check if we have valid auth data
        if (authResponse.accessToken != null &&
            authResponse.refreshToken != null &&
            authResponse.user != null) {
          await _saveTokens(
            authResponse.accessToken!,
            authResponse.refreshToken!,
          );

          state = AuthState.authenticated(
            user: authResponse.user!,
            accessToken: authResponse.accessToken!,
            refreshToken: authResponse.refreshToken!,
          );
          _scheduleTokenRefresh();
          return true;
        } else {
          state = AuthState.error('Invalid authentication data received');
          return false;
        }
      } else {
        state = AuthState.error(apiResponse.message);
        return false;
      }
    } on DioException catch (e) {
      final errorMessage =
          e.response?.data?['message'] ?? 'OTP verification failed';
      state = AuthState.error(errorMessage);
      return false;
    } catch (e) {
      state = AuthState.error('An unexpected error occurred');
      return false;
    }
  }

  Future<bool> login(LoginRequest request) async {
    state = const AuthState.loading();

    try {
      final response = await _dio.post(
        ApiConstants.authLogin,
        data: request.toJson(),
      );

      final apiResponse = ApiResponse.fromJson(
        response.data,
        (data) => AuthResponse.fromJson(data),
      );

      if (apiResponse.success && apiResponse.data != null) {
        final authResponse = apiResponse.data!;

        // Check if we have valid auth data
        if (authResponse.accessToken != null &&
            authResponse.refreshToken != null &&
            authResponse.user != null) {
          await _saveTokens(
            authResponse.accessToken!,
            authResponse.refreshToken!,
          );

          state = AuthState.authenticated(
            user: authResponse.user!,
            accessToken: authResponse.accessToken!,
            refreshToken: authResponse.refreshToken!,
          );
          _scheduleTokenRefresh();
          return true;
        } else {
          state = AuthState.error('Invalid authentication data received');
          return false;
        }
      } else {
        state = AuthState.error(apiResponse.message);
        return false;
      }
    } on DioException catch (e) {
      final errorMessage = e.response?.data?['message'] ?? 'Login failed';
      state = AuthState.error(errorMessage);
      return false;
    } catch (e) {
      state = AuthState.error('An unexpected error occurred');
      return false;
    }
  }

  Future<bool> resendOTP(ResendOTPRequest request) async {
    try {
      final response = await _dio.post(
        ApiConstants.authResendOTP,
        data: request.toJson(),
      );

      final apiResponse = ApiResponse.fromJson(response.data, null);
      return apiResponse.success;
    } catch (e) {
      return false;
    }
  }

  Future<bool> refreshToken() async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null) return false;

      final response = await _dio.post(
        ApiConstants.authRefresh,
        data: {'refresh_token': refreshToken},
      );

      final apiResponse = ApiResponse.fromJson(
        response.data,
        (data) => AuthResponse.fromJson(data),
      );

      if (apiResponse.success && apiResponse.data != null) {
        final authResponse = apiResponse.data!;

        // Check if we have valid auth data
        if (authResponse.accessToken != null &&
            authResponse.refreshToken != null &&
            authResponse.user != null) {
          await _saveTokens(
            authResponse.accessToken!,
            authResponse.refreshToken!,
          );

          state = AuthState.authenticated(
            user: authResponse.user!,
            accessToken: authResponse.accessToken!,
            refreshToken: authResponse.refreshToken!,
          );
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    try {
      final accessToken = await _storage.getAccessToken();
      if (accessToken != null) {
        await _dio.post(
          ApiConstants.authLogout,
          options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
        );
      }
    } catch (e) {
      // Ignore logout errors
    } finally {
      await _clearTokens();
      _tokenRefreshTimer?.cancel();
      state = const AuthState.unauthenticated();
    }
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    try {
      final response = await _dio.put(
        ApiConstants.authChangePassword,
        data: {'old_password': oldPassword, 'new_password': newPassword},
      );

      final apiResponse = ApiResponse.fromJson(response.data, null);
      return apiResponse.success;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _validateToken(String token) async {
    try {
      final response = await _dio.get(
        ApiConstants.authValidate,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<UserModel?> _getCurrentUser() async {
    try {
      final response = await _dio.get(ApiConstants.authProfile);
      final apiResponse = ApiResponse.fromJson(
        response.data,
        (data) => UserModel.fromJson(data),
      );

      return apiResponse.success ? apiResponse.data : null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    await _storage.saveTokens(accessToken, refreshToken);
    await DioConfig.updateAuthToken(accessToken);
  }

  Future<void> _clearTokens() async {
    await _storage.clearTokens();
    DioConfig.clearAuthToken();
  }

  void _scheduleTokenRefresh() {
    _tokenRefreshTimer?.cancel();
    _tokenRefreshTimer = Timer.periodic(
      const Duration(minutes: 50), // Refresh every 50 minutes
      (_) => refreshToken(),
    );
  }

  @override
  void dispose() {
    _tokenRefreshTimer?.cancel();
    super.dispose();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = SecureStorage();
  return AuthNotifier(dio, storage);
});

// Convenience providers
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState.maybeWhen(
    authenticated: (_, __, ___) => true,
    orElse: () => false,
  );
});

final currentUserProvider = Provider<UserModel?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.maybeWhen(
    authenticated: (user, _, __) => user,
    orElse: () => null,
  );
});

final accessTokenProvider = Provider<String?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.maybeWhen(
    authenticated: (_, token, __) => token,
    orElse: () => null,
  );
});
