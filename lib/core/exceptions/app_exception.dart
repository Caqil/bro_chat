abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;
  final StackTrace? stackTrace;

  const AppException(this.message, {this.code, this.details, this.stackTrace});

  @override
  String toString() {
    return 'AppException: $message${code != null ? ' (Code: $code)' : ''}';
  }

  // Convert exception to user-friendly message
  String get userMessage => message;

  // Check if exception is critical
  bool get isCritical => false;

  // Check if exception is retryable
  bool get isRetryable => false;
}

class ValidationException extends AppException {
  final Map<String, dynamic>? errors;

  const ValidationException(
    super.message, {
    super.code,
    this.errors,
    super.stackTrace,
  });

  factory ValidationException.field(String field, String message) {
    return ValidationException(
      'Validation failed for field: $field',
      code: 'VALIDATION_ERROR',
      errors: {field: message},
    );
  }

  factory ValidationException.multiple(Map<String, dynamic> errors) {
    return ValidationException(
      'Multiple validation errors',
      code: 'VALIDATION_ERROR',
      errors: errors,
    );
  }

  @override
  String get userMessage {
    if (errors != null && errors!.isNotEmpty) {
      final firstError = errors!.values.first;
      return firstError is String ? firstError : message;
    }
    return message;
  }
}

class CacheException extends AppException {
  const CacheException(
    super.message, {
    super.code,
    super.details,
    super.stackTrace,
  });

  factory CacheException.notFound(String key) {
    return CacheException(
      'Cache entry not found: $key',
      code: 'CACHE_NOT_FOUND',
    );
  }

  factory CacheException.expired(String key) {
    return CacheException('Cache entry expired: $key', code: 'CACHE_EXPIRED');
  }

  factory CacheException.writeError(String key) {
    return CacheException(
      'Failed to write cache entry: $key',
      code: 'CACHE_WRITE_ERROR',
    );
  }

  factory CacheException.readError(String key) {
    return CacheException(
      'Failed to read cache entry: $key',
      code: 'CACHE_READ_ERROR',
    );
  }

  @override
  bool get isRetryable =>
      code == 'CACHE_WRITE_ERROR' || code == 'CACHE_READ_ERROR';
}

class StorageException extends AppException {
  const StorageException(
    super.message, {
    super.code,
    super.details,
    super.stackTrace,
  });

  factory StorageException.notFound(String key) {
    return StorageException(
      'Storage key not found: $key',
      code: 'STORAGE_NOT_FOUND',
    );
  }

  factory StorageException.writeError(String key) {
    return StorageException(
      'Failed to write to storage: $key',
      code: 'STORAGE_WRITE_ERROR',
    );
  }

  factory StorageException.readError(String key) {
    return StorageException(
      'Failed to read from storage: $key',
      code: 'STORAGE_READ_ERROR',
    );
  }

  factory StorageException.permissionDenied() {
    return const StorageException(
      'Storage permission denied',
      code: 'STORAGE_PERMISSION_DENIED',
    );
  }

  factory StorageException.quotaExceeded() {
    return const StorageException(
      'Storage quota exceeded',
      code: 'STORAGE_QUOTA_EXCEEDED',
    );
  }

  @override
  String get userMessage {
    switch (code) {
      case 'STORAGE_PERMISSION_DENIED':
        return 'Storage permission is required';
      case 'STORAGE_QUOTA_EXCEEDED':
        return 'Storage space is full';
      default:
        return 'Storage error occurred';
    }
  }

  @override
  bool get isRetryable =>
      code == 'STORAGE_WRITE_ERROR' || code == 'STORAGE_READ_ERROR';
}

class FileException extends AppException {
  const FileException(
    super.message, {
    super.code,
    super.details,
    super.stackTrace,
  });

  factory FileException.notFound(String path) {
    return FileException('File not found: $path', code: 'FILE_NOT_FOUND');
  }

  factory FileException.accessDenied(String path) {
    return FileException(
      'File access denied: $path',
      code: 'FILE_ACCESS_DENIED',
    );
  }

  factory FileException.tooLarge(String path, int maxSize) {
    return FileException(
      'File too large: $path (max: ${_formatFileSize(maxSize)})',
      code: 'FILE_TOO_LARGE',
      details: {'path': path, 'maxSize': maxSize},
    );
  }

  factory FileException.unsupportedFormat(String path, String format) {
    return FileException(
      'Unsupported file format: $format',
      code: 'FILE_UNSUPPORTED_FORMAT',
      details: {'path': path, 'format': format},
    );
  }

  factory FileException.corruptedFile(String path) {
    return FileException('Corrupted file: $path', code: 'FILE_CORRUPTED');
  }

  factory FileException.uploadFailed(String path) {
    return FileException(
      'File upload failed: $path',
      code: 'FILE_UPLOAD_FAILED',
    );
  }

  factory FileException.downloadFailed(String path) {
    return FileException(
      'File download failed: $path',
      code: 'FILE_DOWNLOAD_FAILED',
    );
  }

  @override
  String get userMessage {
    switch (code) {
      case 'FILE_NOT_FOUND':
        return 'File not found';
      case 'FILE_ACCESS_DENIED':
        return 'Cannot access file';
      case 'FILE_TOO_LARGE':
        final maxSize = details?['maxSize'] as int?;
        return 'File is too large${maxSize != null ? ' (max: ${_formatFileSize(maxSize)})' : ''}';
      case 'FILE_UNSUPPORTED_FORMAT':
        return 'Unsupported file format';
      case 'FILE_CORRUPTED':
        return 'File is corrupted';
      case 'FILE_UPLOAD_FAILED':
        return 'Failed to upload file';
      case 'FILE_DOWNLOAD_FAILED':
        return 'Failed to download file';
      default:
        return 'File error occurred';
    }
  }

  @override
  bool get isRetryable =>
      code == 'FILE_UPLOAD_FAILED' || code == 'FILE_DOWNLOAD_FAILED';

  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
}

class MediaException extends AppException {
  const MediaException(
    super.message, {
    super.code,
    super.details,
    super.stackTrace,
  });

  factory MediaException.cameraNotAvailable() {
    return const MediaException(
      'Camera not available',
      code: 'CAMERA_NOT_AVAILABLE',
    );
  }

  factory MediaException.microphoneNotAvailable() {
    return const MediaException(
      'Microphone not available',
      code: 'MICROPHONE_NOT_AVAILABLE',
    );
  }

  factory MediaException.recordingFailed() {
    return const MediaException('Recording failed', code: 'RECORDING_FAILED');
  }

  factory MediaException.playbackFailed() {
    return const MediaException('Playback failed', code: 'PLAYBACK_FAILED');
  }

  factory MediaException.compressionFailed() {
    return const MediaException(
      'Media compression failed',
      code: 'COMPRESSION_FAILED',
    );
  }

  factory MediaException.thumbnailGenerationFailed() {
    return const MediaException(
      'Thumbnail generation failed',
      code: 'THUMBNAIL_FAILED',
    );
  }

  @override
  String get userMessage {
    switch (code) {
      case 'CAMERA_NOT_AVAILABLE':
        return 'Camera is not available';
      case 'MICROPHONE_NOT_AVAILABLE':
        return 'Microphone is not available';
      case 'RECORDING_FAILED':
        return 'Recording failed';
      case 'PLAYBACK_FAILED':
        return 'Playback failed';
      case 'COMPRESSION_FAILED':
        return 'Media processing failed';
      case 'THUMBNAIL_FAILED':
        return 'Cannot generate thumbnail';
      default:
        return 'Media error occurred';
    }
  }

  @override
  bool get isRetryable => true;
}

class PermissionException extends AppException {
  const PermissionException(
    super.message, {
    super.code,
    super.details,
    super.stackTrace,
  });

  factory PermissionException.camera() {
    return const PermissionException(
      'Camera permission denied',
      code: 'CAMERA_PERMISSION_DENIED',
    );
  }

  factory PermissionException.microphone() {
    return const PermissionException(
      'Microphone permission denied',
      code: 'MICROPHONE_PERMISSION_DENIED',
    );
  }

  factory PermissionException.storage() {
    return const PermissionException(
      'Storage permission denied',
      code: 'STORAGE_PERMISSION_DENIED',
    );
  }

  factory PermissionException.location() {
    return const PermissionException(
      'Location permission denied',
      code: 'LOCATION_PERMISSION_DENIED',
    );
  }

  factory PermissionException.contacts() {
    return const PermissionException(
      'Contacts permission denied',
      code: 'CONTACTS_PERMISSION_DENIED',
    );
  }

  factory PermissionException.notification() {
    return const PermissionException(
      'Notification permission denied',
      code: 'NOTIFICATION_PERMISSION_DENIED',
    );
  }

  factory PermissionException.phone() {
    return const PermissionException(
      'Phone permission denied',
      code: 'PHONE_PERMISSION_DENIED',
    );
  }

  @override
  String get userMessage {
    switch (code) {
      case 'CAMERA_PERMISSION_DENIED':
        return 'Camera permission is required';
      case 'MICROPHONE_PERMISSION_DENIED':
        return 'Microphone permission is required';
      case 'STORAGE_PERMISSION_DENIED':
        return 'Storage permission is required';
      case 'LOCATION_PERMISSION_DENIED':
        return 'Location permission is required';
      case 'CONTACTS_PERMISSION_DENIED':
        return 'Contacts permission is required';
      case 'NOTIFICATION_PERMISSION_DENIED':
        return 'Notification permission is required';
      case 'PHONE_PERMISSION_DENIED':
        return 'Phone permission is required';
      default:
        return 'Permission is required';
    }
  }
}

class ConfigurationException extends AppException {
  const ConfigurationException(
    super.message, {
    super.code,
    super.details,
    super.stackTrace,
  });

  factory ConfigurationException.missingApiKey() {
    return const ConfigurationException(
      'API key not configured',
      code: 'MISSING_API_KEY',
    );
  }

  factory ConfigurationException.invalidConfiguration(String config) {
    return ConfigurationException(
      'Invalid configuration: $config',
      code: 'INVALID_CONFIGURATION',
    );
  }

  factory ConfigurationException.featureNotEnabled(String feature) {
    return ConfigurationException(
      'Feature not enabled: $feature',
      code: 'FEATURE_NOT_ENABLED',
    );
  }

  @override
  String get userMessage {
    switch (code) {
      case 'MISSING_API_KEY':
        return 'Service configuration error';
      case 'INVALID_CONFIGURATION':
        return 'App configuration error';
      case 'FEATURE_NOT_ENABLED':
        return 'This feature is not available';
      default:
        return 'Configuration error';
    }
  }

  @override
  bool get isCritical => true;
}

class BiometricException extends AppException {
  const BiometricException(
    super.message, {
    super.code,
    super.details,
    super.stackTrace,
  });

  factory BiometricException.notAvailable() {
    return const BiometricException(
      'Biometric authentication not available',
      code: 'BIOMETRIC_NOT_AVAILABLE',
    );
  }

  factory BiometricException.notEnrolled() {
    return const BiometricException(
      'No biometric credentials enrolled',
      code: 'BIOMETRIC_NOT_ENROLLED',
    );
  }

  factory BiometricException.authenticationFailed() {
    return const BiometricException(
      'Biometric authentication failed',
      code: 'BIOMETRIC_AUTH_FAILED',
    );
  }

  factory BiometricException.userCancelled() {
    return const BiometricException(
      'Biometric authentication cancelled',
      code: 'BIOMETRIC_CANCELLED',
    );
  }

  factory BiometricException.tooManyAttempts() {
    return const BiometricException(
      'Too many failed biometric attempts',
      code: 'BIOMETRIC_TOO_MANY_ATTEMPTS',
    );
  }

  @override
  String get userMessage {
    switch (code) {
      case 'BIOMETRIC_NOT_AVAILABLE':
        return 'Biometric authentication is not available';
      case 'BIOMETRIC_NOT_ENROLLED':
        return 'Please set up biometric authentication in device settings';
      case 'BIOMETRIC_AUTH_FAILED':
        return 'Biometric authentication failed';
      case 'BIOMETRIC_CANCELLED':
        return 'Authentication cancelled';
      case 'BIOMETRIC_TOO_MANY_ATTEMPTS':
        return 'Too many failed attempts. Please try again later';
      default:
        return 'Biometric authentication error';
    }
  }

  @override
  bool get isRetryable =>
      code != 'BIOMETRIC_NOT_AVAILABLE' && code != 'BIOMETRIC_NOT_ENROLLED';
}

class LocationException extends AppException {
  const LocationException(
    super.message, {
    super.code,
    super.details,
    super.stackTrace,
  });

  factory LocationException.serviceDisabled() {
    return const LocationException(
      'Location service is disabled',
      code: 'LOCATION_SERVICE_DISABLED',
    );
  }

  factory LocationException.permissionDenied() {
    return const LocationException(
      'Location permission denied',
      code: 'LOCATION_PERMISSION_DENIED',
    );
  }

  factory LocationException.timeout() {
    return const LocationException(
      'Location request timeout',
      code: 'LOCATION_TIMEOUT',
    );
  }

  factory LocationException.notAvailable() {
    return const LocationException(
      'Location not available',
      code: 'LOCATION_NOT_AVAILABLE',
    );
  }

  @override
  String get userMessage {
    switch (code) {
      case 'LOCATION_SERVICE_DISABLED':
        return 'Please enable location services';
      case 'LOCATION_PERMISSION_DENIED':
        return 'Location permission is required';
      case 'LOCATION_TIMEOUT':
        return 'Location request timed out';
      case 'LOCATION_NOT_AVAILABLE':
        return 'Location is not available';
      default:
        return 'Location error occurred';
    }
  }

  @override
  bool get isRetryable => code != 'LOCATION_PERMISSION_DENIED';
}

// Exception handler utility
class ExceptionHandler {
  static String getErrorMessage(dynamic error) {
    if (error is AppException) {
      return error.userMessage;
    } else if (error is Exception) {
      return error.toString();
    } else {
      return 'An unexpected error occurred';
    }
  }

  static bool isRetryable(dynamic error) {
    if (error is AppException) {
      return error.isRetryable;
    }
    return false;
  }

  static bool isCritical(dynamic error) {
    if (error is AppException) {
      return error.isCritical;
    }
    return false;
  }

  static void logException(AppException exception) {
    // Log exception details for debugging
    print('Exception: ${exception.message}');
    print('Code: ${exception.code}');
    print('Details: ${exception.details}');
    if (exception.stackTrace != null) {
      print('Stack trace: ${exception.stackTrace}');
    }
  }
}
