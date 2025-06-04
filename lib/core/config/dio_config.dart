import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_config.dart';
import '../services/storage/secure_storage.dart';
import '../exceptions/network_exception.dart';
import '../exceptions/auth_exception.dart';

class DioConfig {
  static Dio? _dio;
  static final SecureStorage _storage = SecureStorage();

  static Dio get instance {
    _dio ??= _createDio();
    return _dio!;
  }

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': '${AppConfig.appName}/${AppConfig.appVersion}',
          'X-App-Version': AppConfig.appVersion,
          'X-Platform': Platform.isAndroid ? 'android' : 'ios',
          'X-OS-Version': Platform.operatingSystemVersion,
        },
        validateStatus: (status) => status! < 500,
      ),
    );

    // Add interceptors
    dio.interceptors.add(_AuthInterceptor());
    dio.interceptors.add(_ErrorInterceptor());

    if (AppConfig.enableNetworkLogs) {
      dio.interceptors.add(_LoggingInterceptor());
    }

    return dio;
  }

  static void clearInstance() {
    _dio?.close();
    _dio = null;
  }

  static Future<void> updateAuthToken(String token) async {
    instance.options.headers['Authorization'] = 'Bearer $token';
  }

  static void clearAuthToken() {
    instance.options.headers.remove('Authorization');
  }
}

class _AuthInterceptor extends Interceptor {
  final SecureStorage _storage = SecureStorage();

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Add auth token if available
    final token = await _storage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    // Add device info for specific endpoints
    if (options.path.contains('/calls/') || options.path.contains('/auth/')) {
      options.headers['X-Device-ID'] = await _getDeviceId();
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Try to refresh token
      final refreshed = await _refreshToken();
      if (refreshed) {
        // Retry the original request
        final retryOptions = err.requestOptions;
        final token = await _storage.getAccessToken();
        retryOptions.headers['Authorization'] = 'Bearer $token';

        try {
          final response = await DioConfig.instance.fetch(retryOptions);
          handler.resolve(response);
          return;
        } catch (e) {
          // If retry fails, continue with original error
        }
      }

      // Clear tokens and redirect to login
      await _storage.clearTokens();
      DioConfig.clearAuthToken();
      handler.next(
        DioException(
          requestOptions: err.requestOptions,
          error: AuthException.sessionExpired(),
          type: DioExceptionType.badResponse,
          response: err.response,
        ),
      );
      return;
    }

    handler.next(err);
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        return false;
      }

      final response = await Dio().post(
        '${AppConfig.baseUrl}/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        await _storage.saveTokens(data['access_token'], data['refresh_token']);
        await DioConfig.updateAuthToken(data['access_token']);
        return true;
      }
    } catch (e) {
      debugPrint('Token refresh failed: $e');
    }

    return false;
  }

  Future<String> _getDeviceId() async {
    // Get or generate device ID
    String? deviceId = await _storage.getDeviceId();
    if (deviceId == null) {
      deviceId = _generateDeviceId();
      await _storage.saveDeviceId(deviceId);
    }
    return deviceId;
  }

  String _generateDeviceId() {
    return '${Platform.operatingSystem}_${DateTime.now().millisecondsSinceEpoch}';
  }
}

class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    NetworkException exception;

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        exception = NetworkException.timeout();
        break;

      case DioExceptionType.connectionError:
        exception = NetworkException.noConnection();
        break;

      case DioExceptionType.badResponse:
        exception = _handleHttpError(err);
        break;

      case DioExceptionType.cancel:
        exception = NetworkException.requestCancelled();
        break;

      default:
        exception = NetworkException.unknown(err.message ?? 'Unknown error');
    }

    handler.next(
      DioException(
        requestOptions: err.requestOptions,
        error: exception,
        type: err.type,
        response: err.response,
      ),
    );
  }

  NetworkException _handleHttpError(DioException err) {
    final statusCode = err.response?.statusCode ?? 0;
    final data = err.response?.data;

    String message = 'An error occurred';
    String? errorCode;

    if (data is Map<String, dynamic>) {
      message = data['message'] ?? data['error'] ?? message;
      errorCode = data['code']?.toString();
    }

    switch (statusCode) {
      case 400:
        return NetworkException.badRequest(message, errorCode);
      case 401:
        return AuthException.unauthorized(message);
      case 403:
        return AuthException.forbidden(message);
      case 404:
        return NetworkException.notFound(message);
      case 409:
        return NetworkException.conflict(message);
      case 422:
        return NetworkException.validationError(message, data);
      case 429:
        return NetworkException.tooManyRequests();
      case 500:
        return NetworkException.serverError(message);
      case 502:
      case 503:
      case 504:
        return NetworkException.serviceUnavailable();
      default:
        return NetworkException.unknown(message);
    }
  }
}

class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('🔵 REQUEST[${options.method}] => PATH: ${options.path}');
    debugPrint('🔵 Headers: ${options.headers}');
    if (options.data != null) {
      debugPrint('🔵 Data: ${options.data}');
    }
    if (options.queryParameters.isNotEmpty) {
      debugPrint('🔵 Query: ${options.queryParameters}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint(
      '🟢 RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}',
    );
    debugPrint('🟢 Data: ${response.data}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint(
      '🔴 ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}',
    );
    debugPrint('🔴 Message: ${err.message}');
    if (err.response?.data != null) {
      debugPrint('🔴 Data: ${err.response?.data}');
    }
    handler.next(err);
  }
}

// Upload progress tracker
class UploadProgressTracker {
  final String uploadId;
  final ValueNotifier<double> progress = ValueNotifier(0.0);
  final ValueNotifier<String> status = ValueNotifier('preparing');

  UploadProgressTracker(this.uploadId);

  void updateProgress(double value) {
    progress.value = value.clamp(0.0, 1.0);
    if (value >= 1.0) {
      status.value = 'completed';
    } else if (value > 0) {
      status.value = 'uploading';
    }
  }

  void setError(String error) {
    status.value = 'error';
  }

  void dispose() {
    progress.dispose();
    status.dispose();
  }
}

// Dio provider for Riverpod
final dioProvider = Provider<Dio>((ref) {
  return DioConfig.instance;
});

// HTTP client with retry mechanism
class RetryDio {
  final Dio _dio = DioConfig.instance;
  final int maxRetries;
  final Duration retryDelay;

  RetryDio({this.maxRetries = 3, this.retryDelay = const Duration(seconds: 1)});

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _retryRequest(
      () => _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    return _retryRequest(
      () => _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      ),
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    return _retryRequest(
      () => _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      ),
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _retryRequest(
      () => _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
    );
  }

  Future<Response<T>> _retryRequest<T>(
    Future<Response<T>> Function() request,
  ) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        return await request();
      } catch (e) {
        attempts++;

        if (attempts >= maxRetries || !_shouldRetry(e)) {
          rethrow;
        }

        await Future.delayed(retryDelay * attempts);
      }
    }

    throw Exception('Max retry attempts reached');
  }

  bool _shouldRetry(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          return true;
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          return statusCode != null && (statusCode >= 500 || statusCode == 429);
        default:
          return false;
      }
    }
    return false;
  }
}
