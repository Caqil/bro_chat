class ErrorModel {
  final String message;
  final String? code;
  final Map<String, dynamic>? details;
  final List<ValidationError>? validationErrors;
  final String? stackTrace;
  final int? statusCode;

  ErrorModel({
    required this.message,
    this.code,
    this.details,
    this.validationErrors,
    this.stackTrace,
    this.statusCode,
  });

  factory ErrorModel.fromJson(Map<String, dynamic> json) {
    return ErrorModel(
      message: json['message'] ?? json['error'] ?? 'Unknown error',
      code: json['code'],
      details: json['details'],
      validationErrors: json['validation_errors'] != null
          ? (json['validation_errors'] as List)
                .map((e) => ValidationError.fromJson(e))
                .toList()
          : null,
      stackTrace: json['stack_trace'],
      statusCode: json['status_code'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      if (code != null) 'code': code,
      if (details != null) 'details': details,
      if (validationErrors != null)
        'validation_errors': validationErrors!.map((e) => e.toJson()).toList(),
      if (stackTrace != null) 'stack_trace': stackTrace,
      if (statusCode != null) 'status_code': statusCode,
    };
  }

  // Factory constructors for common errors
  factory ErrorModel.network({String? message}) {
    return ErrorModel(
      message: message ?? 'Network error. Please check your connection.',
      code: 'NETWORK_ERROR',
    );
  }

  factory ErrorModel.server({String? message}) {
    return ErrorModel(
      message: message ?? 'Server error. Please try again later.',
      code: 'SERVER_ERROR',
      statusCode: 500,
    );
  }

  factory ErrorModel.unauthorized({String? message}) {
    return ErrorModel(
      message: message ?? 'Unauthorized. Please login again.',
      code: 'UNAUTHORIZED',
      statusCode: 401,
    );
  }

  factory ErrorModel.forbidden({String? message}) {
    return ErrorModel(
      message: message ?? 'Access forbidden.',
      code: 'FORBIDDEN',
      statusCode: 403,
    );
  }

  factory ErrorModel.notFound({String? message}) {
    return ErrorModel(
      message: message ?? 'Resource not found.',
      code: 'NOT_FOUND',
      statusCode: 404,
    );
  }

  factory ErrorModel.validation({
    required String message,
    required List<ValidationError> errors,
  }) {
    return ErrorModel(
      message: message,
      code: 'VALIDATION_ERROR',
      validationErrors: errors,
      statusCode: 422,
    );
  }

  factory ErrorModel.timeout({String? message}) {
    return ErrorModel(
      message: message ?? 'Request timed out. Please try again.',
      code: 'TIMEOUT',
    );
  }

  factory ErrorModel.unknown({String? message}) {
    return ErrorModel(
      message: message ?? 'An unexpected error occurred.',
      code: 'UNKNOWN_ERROR',
    );
  }

  // Error type checking
  bool get isNetworkError => code == 'NETWORK_ERROR';
  bool get isServerError => statusCode != null && statusCode! >= 500;
  bool get isClientError =>
      statusCode != null && statusCode! >= 400 && statusCode! < 500;
  bool get isValidationError => code == 'VALIDATION_ERROR';
  bool get isAuthError => code == 'UNAUTHORIZED' || code == 'FORBIDDEN';

  // Get user-friendly message
  String get userMessage {
    switch (code) {
      case 'NETWORK_ERROR':
        return 'Please check your internet connection and try again.';
      case 'SERVER_ERROR':
        return 'Something went wrong on our end. Please try again later.';
      case 'UNAUTHORIZED':
        return 'Please login to continue.';
      case 'FORBIDDEN':
        return 'You don\'t have permission to perform this action.';
      case 'NOT_FOUND':
        return 'The requested item could not be found.';
      case 'VALIDATION_ERROR':
        return validationErrors?.first.message ?? message;
      case 'TIMEOUT':
        return 'The request took too long. Please try again.';
      default:
        return message;
    }
  }
}

class ValidationError {
  final String field;
  final String message;
  final String? code;
  final dynamic value;

  ValidationError({
    required this.field,
    required this.message,
    this.code,
    this.value,
  });

  factory ValidationError.fromJson(Map<String, dynamic> json) {
    return ValidationError(
      field: json['field'] ?? '',
      message: json['message'] ?? '',
      code: json['code'],
      value: json['value'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'field': field,
      'message': message,
      if (code != null) 'code': code,
      if (value != null) 'value': value,
    };
  }
}
