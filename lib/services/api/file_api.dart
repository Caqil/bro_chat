import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/dio_config.dart';
import '../../core/constants/api_constants.dart';
import '../../core/exceptions/network_exception.dart';
import '../../core/exceptions/app_exception.dart';
import '../../models/file/file_model.dart';
import '../../models/common/api_response.dart';

class FileAPI {
  final Dio _dio;

  FileAPI(this._dio);

  /// Upload a file
  Future<ApiResponse<FileModel>> uploadFile({
    required File file,
    required String purpose, // 'message', 'avatar', 'document', 'media'
    String? chatId,
    String? messageId,
    bool public = false,
    Function(int, int)? onProgress,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Validate file size
      final fileSize = await file.length();
      if (fileSize > 50 * 1024 * 1024) {
        // 50MB limit
        throw FileException.tooLarge(file.path, 50 * 1024 * 1024);
      }

      final fileName = file.path.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
        'purpose': purpose,
        'public': public,
        if (chatId != null) 'chat_id': chatId,
        if (messageId != null) 'message_id': messageId,
        if (metadata != null) 'metadata': metadata,
      });

      final response = await _dio.post(
        ApiConstants.uploadFile,
        data: formData,
        onSendProgress: onProgress,
      );

      return ApiResponse.fromJson(
        response.data,
        (data) => FileModel.fromJson(data),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Upload file from bytes
  Future<ApiResponse<FileModel>> uploadFileFromBytes({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    required String purpose,
    String? chatId,
    String? messageId,
    bool public = false,
    Function(int, int)? onProgress,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Validate file size
      if (bytes.length > 50 * 1024 * 1024) {
        // 50MB limit
        throw FileException.tooLarge(fileName, 50 * 1024 * 1024);
      }

      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: fileName,
          contentType: DioMediaType.parse(mimeType),
        ),
        'purpose': purpose,
        'public': public,
        if (chatId != null) 'chat_id': chatId,
        if (messageId != null) 'message_id': messageId,
        if (metadata != null) 'metadata': metadata,
      });

      final response = await _dio.post(
        ApiConstants.uploadFile,
        data: formData,
        onSendProgress: onProgress,
      );

      return ApiResponse.fromJson(
        response.data,
        (data) => FileModel.fromJson(data),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Download a file
  Future<Uint8List> downloadFile(
    String fileId, {
    Function(int, int)? onProgress,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.downloadFile(fileId),
        options: Options(responseType: ResponseType.bytes),
        onReceiveProgress: onProgress,
      );

      return Uint8List.fromList(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get file information
  Future<ApiResponse<FileModel>> getFileInfo(String fileId) async {
    try {
      final response = await _dio.get(ApiConstants.getFileInfo(fileId));
      return ApiResponse.fromJson(
        response.data,
        (data) => FileModel.fromJson(data),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get file thumbnail
  Future<Uint8List> getFileThumbnail(
    String fileId, {
    String size = 'medium', // 'small', 'medium', 'large'
    Function(int, int)? onProgress,
  }) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.getFileThumbnail(fileId)}?size=$size',
        options: Options(responseType: ResponseType.bytes),
        onReceiveProgress: onProgress,
      );

      return Uint8List.fromList(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Delete a file
  Future<ApiResponse<void>> deleteFile(String fileId) async {
    try {
      final response = await _dio.delete(ApiConstants.deleteFile(fileId));
      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get user's files
  Future<ApiResponse<List<FileModel>>> getUserFiles({
    String? purpose,
    String? mimeType,
    int page = 1,
    int limit = 20,
    String? search,
    DateTime? from,
    DateTime? to,
    String? sortBy = 'created_at',
    String? sortOrder = 'desc',
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        'sort_by': sortBy,
        'sort_order': sortOrder,
        if (purpose != null) 'purpose': purpose,
        if (mimeType != null) 'mime_type': mimeType,
        if (search != null) 'search': search,
        if (from != null) 'from': from.toIso8601String(),
        if (to != null) 'to': to.toIso8601String(),
      };

      final response = await _dio.get(
        ApiConstants.getUserFiles,
        queryParameters: queryParams,
      );

      return ApiResponse.fromJson(
        response.data,
        (data) =>
            (data as List).map((file) => FileModel.fromJson(file)).toList(),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Search files
  Future<ApiResponse<List<FileModel>>> searchFiles({
    required String query,
    String? type,
    String? purpose,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'q': query,
        'limit': limit,
        if (type != null) 'type': type,
        if (purpose != null) 'purpose': purpose,
      };

      final response = await _dio.get(
        ApiConstants.searchFiles,
        queryParameters: queryParams,
      );

      return ApiResponse.fromJson(
        response.data,
        (data) =>
            (data as List).map((file) => FileModel.fromJson(file)).toList(),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get chat files
  Future<ApiResponse<List<FileModel>>> getChatFiles(
    String chatId, {
    String? type,
    String? purpose,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (type != null) 'type': type,
        if (purpose != null) 'purpose': purpose,
      };

      final response = await _dio.get(
        ApiConstants.getChatFiles(chatId),
        queryParameters: queryParams,
      );

      return ApiResponse.fromJson(
        response.data,
        (data) =>
            (data as List).map((file) => FileModel.fromJson(file)).toList(),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Share file
  Future<ApiResponse<FileShare>> shareFile(
    String fileId, {
    List<String>? userIds,
    List<String>? chatIds,
    String? expiresAt,
    bool? downloadable = true,
    String? password,
  }) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.getFileInfo(fileId)}/share',
        data: {
          if (userIds != null) 'user_ids': userIds,
          if (chatIds != null) 'chat_ids': chatIds,
          if (expiresAt != null) 'expires_at': expiresAt,
          'downloadable': downloadable,
          if (password != null) 'password': password,
        },
      );

      return ApiResponse.fromJson(
        response.data,
        (data) => FileShare.fromJson(data),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get file shares
  Future<ApiResponse<List<FileShare>>> getFileShares(String fileId) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.getFileInfo(fileId)}/shares',
      );
      return ApiResponse.fromJson(
        response.data,
        (data) =>
            (data as List).map((share) => FileShare.fromJson(share)).toList(),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Revoke file share
  Future<ApiResponse<void>> revokeFileShare(
    String fileId,
    String shareId,
  ) async {
    try {
      final response = await _dio.delete(
        '${ApiConstants.getFileInfo(fileId)}/shares/$shareId',
      );
      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Generate file preview
  Future<ApiResponse<FilePreview>> generatePreview(
    String fileId, {
    String? type = 'image', // 'image', 'pdf', 'document'
    int? page,
    int? width,
    int? height,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (type != null) 'type': type,
        if (page != null) 'page': page,
        if (width != null) 'width': width,
        if (height != null) 'height': height,
      };

      final response = await _dio.post(
        '${ApiConstants.getFileInfo(fileId)}/preview',
        queryParameters: queryParams,
      );

      return ApiResponse.fromJson(
        response.data,
        (data) => FilePreview.fromJson(data),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get file preview
  Future<Uint8List> getFilePreview(
    String fileId,
    String previewId, {
    Function(int, int)? onProgress,
  }) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.getFileInfo(fileId)}/preview/$previewId',
        options: Options(responseType: ResponseType.bytes),
        onReceiveProgress: onProgress,
      );

      return Uint8List.fromList(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Bulk delete files
  Future<ApiResponse<BulkOperationResult>> bulkDeleteFiles(
    List<String> fileIds,
  ) async {
    try {
      final response = await _dio.delete(
        '${ApiConstants.getUserFiles}/bulk',
        data: {'file_ids': fileIds},
      );

      return ApiResponse.fromJson(
        response.data,
        (data) => BulkOperationResult.fromJson(data),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Update file metadata
  Future<ApiResponse<FileModel>> updateFileMetadata(
    String fileId, {
    String? name,
    String? description,
    Map<String, dynamic>? customMetadata,
    List<String>? tags,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (customMetadata != null)
        updateData['custom_metadata'] = customMetadata;
      if (tags != null) updateData['tags'] = tags;

      final response = await _dio.put(
        ApiConstants.getFileInfo(fileId),
        data: updateData,
      );

      return ApiResponse.fromJson(
        response.data,
        (data) => FileModel.fromJson(data),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get file statistics
  Future<ApiResponse<FileStats>> getFileStats() async {
    try {
      final response = await _dio.get(ApiConstants.getFileStats);
      return ApiResponse.fromJson(
        response.data,
        (data) => FileStats.fromJson(data),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get storage quota
  Future<ApiResponse<StorageQuota>> getStorageQuota() async {
    try {
      final response = await _dio.get('${ApiConstants.getUserFiles}/quota');
      return ApiResponse.fromJson(
        response.data,
        (data) => StorageQuota.fromJson(data),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Scan file for viruses/malware
  Future<ApiResponse<FileScanResult>> scanFile(String fileId) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.getFileInfo(fileId)}/scan',
      );
      return ApiResponse.fromJson(
        response.data,
        (data) => FileScanResult.fromJson(data),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get file scan result
  Future<ApiResponse<FileScanResult>> getFileScanResult(String fileId) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.getFileInfo(fileId)}/scan',
      );
      return ApiResponse.fromJson(
        response.data,
        (data) => FileScanResult.fromJson(data),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Create file backup
  Future<ApiResponse<void>> createFileBackup(
    List<String> fileIds, {
    String? name,
    String? description,
  }) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.getUserFiles}/backup',
        data: {
          'file_ids': fileIds,
          if (name != null) 'name': name,
          if (description != null) 'description': description,
        },
      );

      return ApiResponse.fromJson(response.data, null);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get file backups
  Future<ApiResponse<List<FileBackup>>> getFileBackups() async {
    try {
      final response = await _dio.get('${ApiConstants.getUserFiles}/backups');
      return ApiResponse.fromJson(
        response.data,
        (data) => (data as List)
            .map((backup) => FileBackup.fromJson(backup))
            .toList(),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Restore file from backup
  Future<ApiResponse<List<FileModel>>> restoreFromBackup(
    String backupId,
  ) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.getUserFiles}/backups/$backupId/restore',
      );

      return ApiResponse.fromJson(
        response.data,
        (data) =>
            (data as List).map((file) => FileModel.fromJson(file)).toList(),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException error) {
    switch (error.response?.statusCode) {
      case 413:
        return FileException.tooLarge('File', 50 * 1024 * 1024);
      case 415:
        return FileException.unsupportedFormat('File', 'unknown');
      case 404:
        return FileException.notFound('File');
      case 403:
        return FileException.accessDenied('File');
      default:
        return NetworkException.fromStatusCode(
          error.response?.statusCode ?? 0,
          error.response?.data?['message'] ?? 'Unknown error',
          response: error.response?.data,
        );
    }
  }
}

// Data models
class FileShare {
  final String id;
  final String fileId;
  final String shareUrl;
  final DateTime? expiresAt;
  final bool downloadable;
  final bool hasPassword;
  final int accessCount;
  final DateTime createdAt;

  FileShare({
    required this.id,
    required this.fileId,
    required this.shareUrl,
    this.expiresAt,
    required this.downloadable,
    required this.hasPassword,
    required this.accessCount,
    required this.createdAt,
  });

  factory FileShare.fromJson(Map<String, dynamic> json) {
    return FileShare(
      id: json['id'],
      fileId: json['file_id'],
      shareUrl: json['share_url'],
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : null,
      downloadable: json['downloadable'] ?? true,
      hasPassword: json['has_password'] ?? false,
      accessCount: json['access_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class FilePreview {
  final String id;
  final String fileId;
  final String type;
  final String url;
  final int? width;
  final int? height;
  final int? page;
  final DateTime createdAt;

  FilePreview({
    required this.id,
    required this.fileId,
    required this.type,
    required this.url,
    this.width,
    this.height,
    this.page,
    required this.createdAt,
  });

  factory FilePreview.fromJson(Map<String, dynamic> json) {
    return FilePreview(
      id: json['id'],
      fileId: json['file_id'],
      type: json['type'],
      url: json['url'],
      width: json['width'],
      height: json['height'],
      page: json['page'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class BulkOperationResult {
  final int successful;
  final int failed;
  final List<String> failedIds;
  final List<String> errors;

  BulkOperationResult({
    required this.successful,
    required this.failed,
    required this.failedIds,
    required this.errors,
  });

  factory BulkOperationResult.fromJson(Map<String, dynamic> json) {
    return BulkOperationResult(
      successful: json['successful'],
      failed: json['failed'],
      failedIds: List<String>.from(json['failed_ids'] ?? []),
      errors: List<String>.from(json['errors'] ?? []),
    );
  }
}

class FileStats {
  final int totalFiles;
  final int totalSize;
  final Map<String, int> filesByType;
  final Map<String, int> filesByPurpose;
  final Map<String, int> sizeByType;
  final DateTime lastUpdated;

  FileStats({
    required this.totalFiles,
    required this.totalSize,
    required this.filesByType,
    required this.filesByPurpose,
    required this.sizeByType,
    required this.lastUpdated,
  });

  factory FileStats.fromJson(Map<String, dynamic> json) {
    return FileStats(
      totalFiles: json['total_files'],
      totalSize: json['total_size'],
      filesByType: Map<String, int>.from(json['files_by_type'] ?? {}),
      filesByPurpose: Map<String, int>.from(json['files_by_purpose'] ?? {}),
      sizeByType: Map<String, int>.from(json['size_by_type'] ?? {}),
      lastUpdated: DateTime.parse(json['last_updated']),
    );
  }
}

class StorageQuota {
  final int used;
  final int total;
  final int remaining;
  final double usagePercentage;
  final Map<String, int> usageByPurpose;

  StorageQuota({
    required this.used,
    required this.total,
    required this.remaining,
    required this.usagePercentage,
    required this.usageByPurpose,
  });

  factory StorageQuota.fromJson(Map<String, dynamic> json) {
    return StorageQuota(
      used: json['used'],
      total: json['total'],
      remaining: json['remaining'],
      usagePercentage: (json['usage_percentage'] as num).toDouble(),
      usageByPurpose: Map<String, int>.from(json['usage_by_purpose'] ?? {}),
    );
  }
}

class FileScanResult {
  final String fileId;
  final String status; // 'scanning', 'clean', 'infected', 'error'
  final bool safe;
  final List<String>? threats;
  final String? scanEngine;
  final DateTime? scannedAt;
  final Map<String, dynamic>? details;

  FileScanResult({
    required this.fileId,
    required this.status,
    required this.safe,
    this.threats,
    this.scanEngine,
    this.scannedAt,
    this.details,
  });

  factory FileScanResult.fromJson(Map<String, dynamic> json) {
    return FileScanResult(
      fileId: json['file_id'],
      status: json['status'],
      safe: json['safe'] ?? false,
      threats: json['threats'] != null
          ? List<String>.from(json['threats'])
          : null,
      scanEngine: json['scan_engine'],
      scannedAt: json['scanned_at'] != null
          ? DateTime.parse(json['scanned_at'])
          : null,
      details: json['details'],
    );
  }
}

class FileBackup {
  final String id;
  final String name;
  final String? description;
  final int fileCount;
  final int totalSize;
  final DateTime createdAt;
  final String status; // 'creating', 'completed', 'failed'

  FileBackup({
    required this.id,
    required this.name,
    this.description,
    required this.fileCount,
    required this.totalSize,
    required this.createdAt,
    required this.status,
  });

  factory FileBackup.fromJson(Map<String, dynamic> json) {
    return FileBackup(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      fileCount: json['file_count'],
      totalSize: json['total_size'],
      createdAt: DateTime.parse(json['created_at']),
      status: json['status'],
    );
  }
}

// Riverpod provider
final fileAPIProvider = Provider<FileAPI>((ref) {
  final dio = ref.watch(dioProvider);
  return FileAPI(dio);
});
