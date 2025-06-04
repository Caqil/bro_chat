import '../common/pagination_model.dart';
import 'file_model.dart';

class UploadResponse {
  final bool success;
  final String message;
  final FileModel? file;
  final String? uploadId;
  final double? progress;
  final UploadStatus status;
  final String? error;

  UploadResponse({
    required this.success,
    required this.message,
    this.file,
    this.uploadId,
    this.progress,
    this.status = UploadStatus.completed,
    this.error,
  });

  factory UploadResponse.fromJson(Map<String, dynamic> json) {
    return UploadResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      file: json['file'] != null ? FileModel.fromJson(json['file']) : null,
      uploadId: json['upload_id'],
      progress: json['progress']?.toDouble(),
      status: UploadStatus.fromString(json['status']),
      error: json['error'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      if (file != null) 'file': file!.toJson(),
      if (uploadId != null) 'upload_id': uploadId,
      if (progress != null) 'progress': progress,
      'status': status.value,
      if (error != null) 'error': error,
    };
  }

  // Factory constructors
  factory UploadResponse.success({
    required FileModel file,
    String message = 'File uploaded successfully',
  }) {
    return UploadResponse(
      success: true,
      message: message,
      file: file,
      status: UploadStatus.completed,
    );
  }

  factory UploadResponse.progress({
    required String uploadId,
    required double progress,
    String message = 'Uploading...',
  }) {
    return UploadResponse(
      success: false,
      message: message,
      uploadId: uploadId,
      progress: progress,
      status: UploadStatus.uploading,
    );
  }

  factory UploadResponse.error({required String error, String? uploadId}) {
    return UploadResponse(
      success: false,
      message: error,
      uploadId: uploadId,
      status: UploadStatus.failed,
      error: error,
    );
  }

  factory UploadResponse.cancelled({String? uploadId}) {
    return UploadResponse(
      success: false,
      message: 'Upload cancelled',
      uploadId: uploadId,
      status: UploadStatus.cancelled,
    );
  }

  // Utility getters
  bool get isUploading => status == UploadStatus.uploading;
  bool get isCompleted => status == UploadStatus.completed && success;
  bool get isFailed =>
      status == UploadStatus.failed || (!success && error != null);
  bool get isCancelled => status == UploadStatus.cancelled;

  int get progressPercentage => ((progress ?? 0.0) * 100).round();
}

enum UploadStatus {
  pending,
  uploading,
  processing,
  completed,
  failed,
  cancelled;

  String get value => name;

  static UploadStatus fromString(String? value) {
    switch (value) {
      case 'pending':
        return UploadStatus.pending;
      case 'uploading':
        return UploadStatus.uploading;
      case 'processing':
        return UploadStatus.processing;
      case 'completed':
        return UploadStatus.completed;
      case 'failed':
        return UploadStatus.failed;
      case 'cancelled':
        return UploadStatus.cancelled;
      default:
        return UploadStatus.pending;
    }
  }
}

// Additional models for file management
class FileUploadRequest {
  final String filename;
  final String mimeType;
  final int size;
  final FilePurpose purpose;
  final String? chatId;
  final bool isPublic;
  final Map<String, dynamic> metadata;

  FileUploadRequest({
    required this.filename,
    required this.mimeType,
    required this.size,
    required this.purpose,
    this.chatId,
    this.isPublic = false,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'filename': filename,
      'mime_type': mimeType,
      'size': size,
      'purpose': purpose.value,
      if (chatId != null) 'chat_id': chatId,
      'is_public': isPublic,
      'metadata': metadata,
    };
  }
}

class FilesListResponse {
  final bool success;
  final List<FileModel> files;
  final PaginationModel? pagination;

  FilesListResponse({
    required this.success,
    required this.files,
    this.pagination,
  });

  factory FilesListResponse.fromJson(Map<String, dynamic> json) {
    return FilesListResponse(
      success: json['success'] ?? false,
      files: (json['data'] as List? ?? [])
          .map((e) => FileModel.fromJson(e))
          .toList(),
      pagination: json['pagination'] != null
          ? PaginationModel.fromJson(json['pagination'])
          : null,
    );
  }
}
