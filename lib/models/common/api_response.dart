import 'error_model.dart';
import 'pagination_model.dart';

class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final ErrorModel? error;
  final PaginationModel? pagination;
  final Map<String, dynamic>? meta;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.error,
    this.pagination,
    this.meta,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'],
      error: json['error'] != null ? ErrorModel.fromJson(json['error']) : null,
      pagination: json['pagination'] != null
          ? PaginationModel.fromJson(json['pagination'])
          : null,
      meta: json['meta'],
    );
  }

  Map<String, dynamic> toJson([dynamic Function(T?)? toJsonT]) {
    return {
      'success': success,
      'message': message,
      if (data != null) 'data': toJsonT != null ? toJsonT(data) : data,
      if (error != null) 'error': error!.toJson(),
      if (pagination != null) 'pagination': pagination!.toJson(),
      if (meta != null) 'meta': meta,
    };
  }

  // Factory constructors for common responses
  factory ApiResponse.success({
    required String message,
    T? data,
    PaginationModel? pagination,
    Map<String, dynamic>? meta,
  }) {
    return ApiResponse<T>(
      success: true,
      message: message,
      data: data,
      pagination: pagination,
      meta: meta,
    );
  }

  factory ApiResponse.error({
    required String message,
    ErrorModel? error,
    String? code,
    Map<String, dynamic>? details,
  }) {
    return ApiResponse<T>(
      success: false,
      message: message,
      error:
          error ?? ErrorModel(message: message, code: code, details: details),
    );
  }

  factory ApiResponse.loading({String message = 'Loading...'}) {
    return ApiResponse<T>(success: false, message: message);
  }

  // Utility methods
  bool get isSuccess => success && error == null;
  bool get isError => !success || error != null;
  bool get hasData => data != null;
  bool get hasPagination => pagination != null;
}

// Specialized response types
class ApiListResponse<T> extends ApiResponse<List<T>> {
  ApiListResponse({
    required super.success,
    required super.message,
    super.data,
    super.error,
    super.pagination,
    super.meta,
  });

  factory ApiListResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    List<T>? dataList;
    if (json['data'] is List) {
      dataList = (json['data'] as List)
          .map((item) => fromJsonT(item as Map<String, dynamic>))
          .toList();
    }

    return ApiListResponse<T>(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: dataList,
      error: json['error'] != null ? ErrorModel.fromJson(json['error']) : null,
      pagination: json['pagination'] != null
          ? PaginationModel.fromJson(json['pagination'])
          : null,
      meta: json['meta'],
    );
  }

  int get itemCount => data?.length ?? 0;
  bool get isEmpty => itemCount == 0;
  bool get isNotEmpty => itemCount > 0;
}
