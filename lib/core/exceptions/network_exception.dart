import 'app_exception.dart';

class NetworkException extends AppException {
  final int? statusCode;
  final Map<String, dynamic>? response;

  const NetworkException(
    super.message, {
    super.code,
    this.statusCode,
    this.response,
    super.details,
    super.stackTrace,
  });

  // No internet connection
  factory NetworkException.noConnection([String? message]) {
    return NetworkException(
      message ?? 'No internet connection',
      code: 'NO_CONNECTION',
    );
  }

  // Connection timeout
  factory NetworkException.timeout([String? message]) {
    return NetworkException(message ?? 'Request timed out', code: 'TIMEOUT');
  }

  // Server unreachable
  factory NetworkException.serverUnreachable([String? message]) {
    return NetworkException(
      message ?? 'Server is unreachable',
      code: 'SERVER_UNREACHABLE',
    );
  }

  // Request cancelled
  factory NetworkException.requestCancelled([String? message]) {
    return NetworkException(
      message ?? 'Request was cancelled',
      code: 'REQUEST_CANCELLED',
    );
  }

  // Bad request (400)
  factory NetworkException.badRequest(String message, [String? errorCode]) {
    return NetworkException(
      message,
      code: errorCode ?? 'BAD_REQUEST',
      statusCode: 400,
    );
  }

  // Unauthorized (401)
  factory NetworkException.unauthorized(String message, [String? errorCode]) {
    return NetworkException(
      message,
      code: errorCode ?? 'UNAUTHORIZED',
      statusCode: 401,
    );
  }

  // Forbidden (403)
  factory NetworkException.forbidden(String message, [String? errorCode]) {
    return NetworkException(
      message,
      code: errorCode ?? 'FORBIDDEN',
      statusCode: 403,
    );
  }

  // Not found (404)
  factory NetworkException.notFound(String message, [String? errorCode]) {
    return NetworkException(
      message,
      code: errorCode ?? 'NOT_FOUND',
      statusCode: 404,
    );
  }

  // Method not allowed (405)
  factory NetworkException.methodNotAllowed(
    String message, [
    String? errorCode,
  ]) {
    return NetworkException(
      message,
      code: errorCode ?? 'METHOD_NOT_ALLOWED',
      statusCode: 405,
    );
  }

  // Conflict (409)
  factory NetworkException.conflict(String message, [String? errorCode]) {
    return NetworkException(
      message,
      code: errorCode ?? 'CONFLICT',
      statusCode: 409,
    );
  }

  // Validation error (422)
  factory NetworkException.validationError(
    String message,
    dynamic validationData,
  ) {
    return NetworkException(
      message,
      code: 'VALIDATION_ERROR',
      statusCode: 422,
      response: validationData is Map<String, dynamic> ? validationData : null,
    );
  }

  // Too many requests (429)
  factory NetworkException.tooManyRequests([String? message]) {
    return NetworkException(
      message ?? 'Too many requests. Please try again later',
      code: 'TOO_MANY_REQUESTS',
      statusCode: 429,
    );
  }

  // Internal server error (500)
  factory NetworkException.serverError(String message, [String? errorCode]) {
    return NetworkException(
      message,
      code: errorCode ?? 'SERVER_ERROR',
      statusCode: 500,
    );
  }

  // Bad gateway (502)
  factory NetworkException.badGateway([String? message]) {
    return NetworkException(
      message ?? 'Bad gateway',
      code: 'BAD_GATEWAY',
      statusCode: 502,
    );
  }

  // Service unavailable (503)
  factory NetworkException.serviceUnavailable([String? message]) {
    return NetworkException(
      message ?? 'Service temporarily unavailable',
      code: 'SERVICE_UNAVAILABLE',
      statusCode: 503,
    );
  }

  // Gateway timeout (504)
  factory NetworkException.gatewayTimeout([String? message]) {
    return NetworkException(
      message ?? 'Gateway timeout',
      code: 'GATEWAY_TIMEOUT',
      statusCode: 504,
    );
  }

  // Unknown network error
  factory NetworkException.unknown(String message, [int? statusCode]) {
    return NetworkException(
      message,
      code: 'UNKNOWN_ERROR',
      statusCode: statusCode,
    );
  }

  // DNS resolution failed
  factory NetworkException.dnsFailure([String? message]) {
    return NetworkException(
      message ?? 'Failed to resolve server address',
      code: 'DNS_FAILURE',
    );
  }

  // SSL/TLS error
  factory NetworkException.sslError([String? message]) {
    return NetworkException(
      message ?? 'SSL/TLS connection error',
      code: 'SSL_ERROR',
    );
  }

  // Certificate error
  factory NetworkException.certificateError([String? message]) {
    return NetworkException(
      message ?? 'Server certificate error',
      code: 'CERTIFICATE_ERROR',
    );
  }

  // Proxy error
  factory NetworkException.proxyError([String? message]) {
    return NetworkException(
      message ?? 'Proxy connection error',
      code: 'PROXY_ERROR',
    );
  }

  // Network changed during request
  factory NetworkException.networkChanged([String? message]) {
    return NetworkException(
      message ?? 'Network connection changed',
      code: 'NETWORK_CHANGED',
    );
  }

  // File too large
  factory NetworkException.fileTooBig(String maxSize, [String? message]) {
    return NetworkException(
      message ?? 'File is too large. Maximum size: $maxSize',
      code: 'FILE_TOO_BIG',
      details: {'maxSize': maxSize},
    );
  }

  // Quota exceeded
  factory NetworkException.quotaExceeded(String quotaType, [String? message]) {
    return NetworkException(
      message ?? '$quotaType quota exceeded',
      code: 'QUOTA_EXCEEDED',
      details: {'quotaType': quotaType},
    );
  }

  // Rate limit exceeded
  factory NetworkException.rateLimitExceeded([String? message]) {
    return NetworkException(
      message ?? 'Rate limit exceeded. Please slow down',
      code: 'RATE_LIMIT_EXCEEDED',
    );
  }

  // Maintenance mode
  factory NetworkException.maintenanceMode([String? message]) {
    return NetworkException(
      message ?? 'Service is under maintenance',
      code: 'MAINTENANCE_MODE',
      statusCode: 503,
    );
  }

  // API version not supported
  factory NetworkException.unsupportedApiVersion([String? message]) {
    return NetworkException(
      message ?? 'API version not supported',
      code: 'UNSUPPORTED_API_VERSION',
    );
  }

  // Payload too large (413)
  factory NetworkException.payloadTooLarge([String? message]) {
    return NetworkException(
      message ?? 'Request payload too large',
      code: 'PAYLOAD_TOO_LARGE',
      statusCode: 413,
    );
  }

  // Bandwidth limit exceeded
  factory NetworkException.bandwidthLimitExceeded([String? message]) {
    return NetworkException(
      message ?? 'Bandwidth limit exceeded',
      code: 'BANDWIDTH_LIMIT_EXCEEDED',
      statusCode: 509,
    );
  }

  @override
  String get userMessage {
    switch (code) {
      case 'NO_CONNECTION':
        return 'No internet connection. Please check your network';
      case 'TIMEOUT':
        return 'Request timed out. Please try again';
      case 'SERVER_UNREACHABLE':
        return 'Cannot reach server. Please try again later';
      case 'REQUEST_CANCELLED':
        return 'Request was cancelled';
      case 'BAD_REQUEST':
        return 'Invalid request. Please check your input';
      case 'UNAUTHORIZED':
        return 'Authentication required. Please login again';
      case 'FORBIDDEN':
        return 'Access denied. You do not have permission';
      case 'NOT_FOUND':
        return 'Resource not found';
      case 'METHOD_NOT_ALLOWED':
        return 'Operation not allowed';
      case 'CONFLICT':
        return 'Data conflict. Please refresh and try again';
      case 'VALIDATION_ERROR':
        return _getValidationErrorMessage();
      case 'TOO_MANY_REQUESTS':
        return 'Too many requests. Please wait and try again';
      case 'SERVER_ERROR':
        return 'Server error. Please try again later';
      case 'BAD_GATEWAY':
        return 'Service temporarily unavailable';
      case 'SERVICE_UNAVAILABLE':
        return 'Service is temporarily unavailable';
      case 'GATEWAY_TIMEOUT':
        return 'Service timeout. Please try again';
      case 'DNS_FAILURE':
        return 'Cannot connect to server. Check your connection';
      case 'SSL_ERROR':
        return 'Secure connection failed';
      case 'CERTIFICATE_ERROR':
        return 'Server certificate error';
      case 'PROXY_ERROR':
        return 'Proxy connection error';
      case 'NETWORK_CHANGED':
        return 'Network connection changed. Please try again';
      case 'FILE_TOO_BIG':
        final maxSize = details?['maxSize'] as String?;
        return 'File is too large${maxSize != null ? '. Maximum size: $maxSize' : ''}';
      case 'QUOTA_EXCEEDED':
        final quotaType = details?['quotaType'] as String?;
        return '${quotaType ?? 'Usage'} quota exceeded';
      case 'RATE_LIMIT_EXCEEDED':
        return 'Too many requests. Please slow down';
      case 'MAINTENANCE_MODE':
        return 'Service is under maintenance. Please try again later';
      case 'UNSUPPORTED_API_VERSION':
        return 'App version is outdated. Please update';
      case 'PAYLOAD_TOO_LARGE':
        return 'Data is too large to send';
      case 'BANDWIDTH_LIMIT_EXCEEDED':
        return 'Bandwidth limit exceeded';
      case 'UNKNOWN_ERROR':
      default:
        return statusCode != null
            ? 'Network error (${statusCode}). Please try again'
            : 'Network error. Please try again';
    }
  }

  @override
  bool get isRetryable {
    switch (code) {
      case 'NO_CONNECTION':
      case 'TIMEOUT':
      case 'SERVER_UNREACHABLE':
      case 'DNS_FAILURE':
      case 'NETWORK_CHANGED':
      case 'SERVER_ERROR':
      case 'BAD_GATEWAY':
      case 'SERVICE_UNAVAILABLE':
      case 'GATEWAY_TIMEOUT':
      case 'UNKNOWN_ERROR':
        return true;
      case 'TOO_MANY_REQUESTS':
      case 'RATE_LIMIT_EXCEEDED':
        return true; // Retryable after delay
      default:
        return false;
    }
  }

  @override
  bool get isCritical {
    switch (code) {
      case 'UNAUTHORIZED':
      case 'FORBIDDEN':
      case 'UNSUPPORTED_API_VERSION':
        return true;
      default:
        return false;
    }
  }

  // Check if error is client-side
  bool get isClientError {
    return statusCode != null && statusCode! >= 400 && statusCode! < 500;
  }

  // Check if error is server-side
  bool get isServerError {
    return statusCode != null && statusCode! >= 500 && statusCode! < 600;
  }

  // Check if error is a network connectivity issue
  bool get isConnectivityError {
    switch (code) {
      case 'NO_CONNECTION':
      case 'TIMEOUT':
      case 'SERVER_UNREACHABLE':
      case 'DNS_FAILURE':
      case 'NETWORK_CHANGED':
        return true;
      default:
        return false;
    }
  }

  // Check if error should show retry button
  bool get shouldShowRetry {
    return isRetryable && !isRateLimited;
  }

  // Check if error is due to rate limiting
  bool get isRateLimited {
    switch (code) {
      case 'TOO_MANY_REQUESTS':
      case 'RATE_LIMIT_EXCEEDED':
      case 'BANDWIDTH_LIMIT_EXCEEDED':
        return true;
      default:
        return false;
    }
  }

  // Get suggested retry delay in seconds
  int get suggestedRetryDelay {
    switch (code) {
      case 'TOO_MANY_REQUESTS':
      case 'RATE_LIMIT_EXCEEDED':
        return 60; // 1 minute
      case 'BANDWIDTH_LIMIT_EXCEEDED':
        return 300; // 5 minutes
      case 'SERVICE_UNAVAILABLE':
      case 'MAINTENANCE_MODE':
        return 900; // 15 minutes
      default:
        return 5; // 5 seconds
    }
  }

  // Get validation error message from response
  String _getValidationErrorMessage() {
    if (response != null) {
      // Try to extract first validation error
      if (response!['errors'] is Map) {
        final errors = response!['errors'] as Map;
        if (errors.isNotEmpty) {
          final firstError = errors.values.first;
          if (firstError is String) {
            return firstError;
          } else if (firstError is List && firstError.isNotEmpty) {
            return firstError.first.toString();
          }
        }
      }

      // Try to get message from response
      if (response!['message'] is String) {
        return response!['message'];
      }
    }

    return 'Please check your input and try again';
  }

  // Get validation errors as map
  Map<String, dynamic>? get validationErrors {
    if (response != null && response!['errors'] is Map) {
      return Map<String, dynamic>.from(response!['errors']);
    }
    return null;
  }

  // Check if specific field has validation error
  bool hasValidationError(String field) {
    final errors = validationErrors;
    return errors != null && errors.containsKey(field);
  }

  // Get validation error for specific field
  String? getValidationError(String field) {
    final errors = validationErrors;
    if (errors != null && errors.containsKey(field)) {
      final error = errors[field];
      if (error is String) {
        return error;
      } else if (error is List && error.isNotEmpty) {
        return error.first.toString();
      }
    }
    return null;
  }

  // Create network exception from HTTP status code
  factory NetworkException.fromStatusCode(
    int statusCode,
    String message, {
    String? errorCode,
    dynamic response,
  }) {
    switch (statusCode) {
      case 400:
        return NetworkException.badRequest(message, errorCode);
      case 401:
        return NetworkException.unauthorized(message, errorCode);
      case 403:
        return NetworkException.forbidden(message, errorCode);
      case 404:
        return NetworkException.notFound(message, errorCode);
      case 405:
        return NetworkException.methodNotAllowed(message, errorCode);
      case 409:
        return NetworkException.conflict(message, errorCode);
      case 413:
        return NetworkException.payloadTooLarge(message);
      case 422:
        return NetworkException.validationError(message, response);
      case 429:
        return NetworkException.tooManyRequests(message);
      case 500:
        return NetworkException.serverError(message, errorCode);
      case 502:
        return NetworkException.badGateway(message);
      case 503:
        return NetworkException.serviceUnavailable(message);
      case 504:
        return NetworkException.gatewayTimeout(message);
      case 509:
        return NetworkException.bandwidthLimitExceeded(message);
      default:
        return NetworkException.unknown(message, statusCode);
    }
  }
}
