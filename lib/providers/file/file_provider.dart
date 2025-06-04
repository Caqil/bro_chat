import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';

import '../../services/api/api_service.dart';
import '../../services/storage/cache_service.dart';
import '../../models/file/file_model.dart';
import '../../models/common/api_response.dart';


class FileInfo {
  final String id;
  final String name;
  final String path;
  final String? url;
  final FileType type;
  final FilePurpose purpose;
  final FileStatus status;
  final int size;
  final String mimeType;
  final DateTime createdAt;
  final DateTime? uploadedAt;
  final double? uploadProgress;
  final String? thumbnailPath;
  final String? thumbnailUrl;
  final Map<String, dynamic>? metadata;
  final String? error;
  final bool isDownloaded;
  final bool isCompressed;

  FileInfo({
    required this.id,
    required this.name,
    required this.path,
    this.url,
    required this.type,
    required this.purpose,
    this.status = FileStatus.ready,
    required this.size,
    required this.mimeType,
    DateTime? createdAt,
    this.uploadedAt,
    this.uploadProgress,
    this.thumbnailPath,
    this.thumbnailUrl,
    this.metadata,
    this.error,
    this.isDownloaded = false,
    this.isCompressed = false,
  }) : createdAt = createdAt ?? DateTime.now();

  FileInfo copyWith({
    String? id,
    String? name,
    String? path,
    String? url,
    FileType? type,
    FilePurpose? purpose,
    FileStatus? status,
    int? size,
    String? mimeType,
    DateTime? createdAt,
    DateTime? uploadedAt,
    double? uploadProgress,
    String? thumbnailPath,
    String? thumbnailUrl,
    Map<String, dynamic>? metadata,
    String? error,
    bool? isDownloaded,
    bool? isCompressed,
  }) {
    return FileInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      url: url ?? this.url,
      type: type ?? this.type,
      purpose: purpose ?? this.purpose,
      status: status ?? this.status,
      size: size ?? this.size,
      mimeType: mimeType ?? this.mimeType,
      createdAt: createdAt ?? this.createdAt,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      metadata: metadata ?? this.metadata,
      error: error,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      isCompressed: isCompressed ?? this.isCompressed,
    );
  }

  bool get isUploading => status == FileStatus.uploading;
  bool get isUploaded => status == FileStatus.uploaded;
  bool get hasFailed => status == FileStatus.failed;
  bool get isProcessing => status == FileStatus.processing;
  bool get isReady => status == FileStatus.ready;

  String get extension => name.split('.').last.toLowerCase();
  String get sizeFormatted => _formatFileSize(size);

  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'url': url,
      'type': type.name,
      'purpose': purpose.name,
      'status': status.name,
      'size': size,
      'mime_type': mimeType,
      'created_at': createdAt.toIso8601String(),
      'uploaded_at': uploadedAt?.toIso8601String(),
      'upload_progress': uploadProgress,
      'thumbnail_path': thumbnailPath,
      'thumbnail_url': thumbnailUrl,
      'metadata': metadata,
      'error': error,
      'is_downloaded': isDownloaded,
      'is_compressed': isCompressed,
    };
  }

  factory FileInfo.fromJson(Map<String, dynamic> json) {
    return FileInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      path: json['path'] ?? '',
      url: json['url'],
      type: FileType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => FileType.other,
      ),
      purpose: FilePurpose.values.firstWhere(
        (e) => e.name == json['purpose'],
        orElse: () => FilePurpose.other,
      ),
      status: FileStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => FileStatus.ready,
      ),
      size: json['size'] ?? 0,
      mimeType: json['mime_type'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      uploadedAt: json['uploaded_at'] != null
          ? DateTime.tryParse(json['uploaded_at'])
          : null,
      uploadProgress: json['upload_progress']?.toDouble(),
      thumbnailPath: json['thumbnail_path'],
      thumbnailUrl: json['thumbnail_url'],
      metadata: json['metadata'],
      error: json['error'],
      isDownloaded: json['is_downloaded'] ?? false,
      isCompressed: json['is_compressed'] ?? false,
    );
  }
}

class FileState {
  final Map<String, FileInfo> files;
  final bool isLoading;
  final String? error;
  final bool isInitialized;
  final Map<String, double> uploadProgress;
  final Map<String, double> downloadProgress;
  final int totalFiles;
  final int totalSize;
  final String storageUsed;
  final DateTime? lastUpdate;

  FileState({
    this.files = const {},
    this.isLoading = false,
    this.error,
    this.isInitialized = false,
    this.uploadProgress = const {},
    this.downloadProgress = const {},
    this.totalFiles = 0,
    this.totalSize = 0,
    this.storageUsed = '0 B',
    this.lastUpdate,
  });

  FileState copyWith({
    Map<String, FileInfo>? files,
    bool? isLoading,
    String? error,
    bool? isInitialized,
    Map<String, double>? uploadProgress,
    Map<String, double>? downloadProgress,
    int? totalFiles,
    int? totalSize,
    String? storageUsed,
    DateTime? lastUpdate,
  }) {
    return FileState(
      files: files ?? this.files,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isInitialized: isInitialized ?? this.isInitialized,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      totalFiles: totalFiles ?? this.totalFiles,
      totalSize: totalSize ?? this.totalSize,
      storageUsed: storageUsed ?? this.storageUsed,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }

  FileInfo? getFile(String fileId) => files[fileId];

  List<FileInfo> getFilesByType(FileType type) {
    return files.values.where((file) => file.type == type).toList();
  }

  List<FileInfo> getFilesByPurpose(FilePurpose purpose) {
    return files.values.where((file) => file.purpose == purpose).toList();
  }

  List<FileInfo> getFilesByStatus(FileStatus status) {
    return files.values.where((file) => file.status == status).toList();
  }

  List<FileInfo> get uploadingFiles => getFilesByStatus(FileStatus.uploading);
  List<FileInfo> get failedFiles => getFilesByStatus(FileStatus.failed);
  List<FileInfo> get recentFiles {
    final fileList = files.values.toList();
    fileList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return fileList.take(20).toList();
  }
}

class FileNotifier extends StateNotifier<AsyncValue<FileState>> {
  final ApiService _apiService;
  final CacheService _cacheService;

  final Map<String, CancelToken> _uploadCancelTokens = {};
  final Map<String, CancelToken> _downloadCancelTokens = {};
  Timer? _storageCleanupTimer;

  static const Duration _cleanupInterval = Duration(hours: 24);
  static const int _maxCacheSize = 500 * 1024 * 1024; // 500MB

  FileNotifier({
    required ApiService apiService,
    required CacheService cacheService,
  }) : _apiService = apiService,
       _cacheService = cacheService,
       super(AsyncValue.data(FileState())) {
    _initialize();
  }

  void _initialize() async {
    state = AsyncValue.data(state.value!.copyWith(isLoading: true));

    try {
      await _loadCachedFiles();
      await _calculateStorageUsage();
      _startStorageCleanup();

      state = AsyncValue.data(
        state.value!.copyWith(
          isLoading: false,
          isInitialized: true,
          lastUpdate: DateTime.now(),
        ),
      );

      if (kDebugMode) print('✅ File provider initialized');
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      if (kDebugMode) print('❌ Error initializing file provider: $e');
    }
  }

  Future<void> _loadCachedFiles() async {
    try {
      final cachedFiles = await _cacheService.getCachedFiles();
      final fileMap = <String, FileInfo>{};

      for (final fileData in cachedFiles) {
        final file = FileInfo.fromJson(fileData);
        fileMap[file.id] = file;
      }

      state = AsyncValue.data(
        state.value!.copyWith(files: fileMap, totalFiles: fileMap.length),
      );
    } catch (e) {
      if (kDebugMode) print('❌ Error loading cached files: $e');
    }
  }

  Future<void> _calculateStorageUsage() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      int totalSize = 0;

      if (await appDir.exists()) {
        final files = appDir.listSync(recursive: true);
        for (final file in files) {
          if (file is File) {
            totalSize += await file.length();
          }
        }
      }

      final storageUsed = FileInfo._formatFileSize(totalSize);

      state = AsyncValue.data(
        state.value!.copyWith(totalSize: totalSize, storageUsed: storageUsed),
      );
    } catch (e) {
      if (kDebugMode) print('❌ Error calculating storage usage: $e');
    }
  }

  void _startStorageCleanup() {
    _storageCleanupTimer = Timer.periodic(_cleanupInterval, (_) {
      _cleanupOldFiles();
    });
  }

  Future<void> _cleanupOldFiles() async {
    try {
      if (state.value!.totalSize > _maxCacheSize) {
        final files = state.value!.files.values.toList();
        files.sort((a, b) => a.createdAt.compareTo(b.createdAt));

        int deletedSize = 0;
        final filesToDelete = <String>[];

        for (final file in files) {
          if (deletedSize >= _maxCacheSize * 0.3) break; // Delete 30% of cache

          if (file.isDownloaded && !file.isUploading) {
            try {
              final fileObj = File(file.path);
              if (await fileObj.exists()) {
                deletedSize += await fileObj.length();
                await fileObj.delete();
                filesToDelete.add(file.id);
              }
            } catch (e) {
              if (kDebugMode) print('❌ Error deleting file: $e');
            }
          }
        }

        if (filesToDelete.isNotEmpty) {
          state.whenData((fileState) {
            final updatedFiles = Map<String, FileInfo>.from(fileState.files);
            for (final fileId in filesToDelete) {
              updatedFiles.remove(fileId);
            }

            state = AsyncValue.data(
              fileState.copyWith(
                files: updatedFiles,
                totalFiles: updatedFiles.length,
              ),
            );
          });

          await _calculateStorageUsage();

          if (kDebugMode) {
            print('🧹 Cleaned up ${filesToDelete.length} old files');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error cleaning up old files: $e');
    }
  }

  Future<FileInfo> uploadFile({
    required File file,
    required FilePurpose purpose,
    String? chatId,
    bool public = false,
    bool compress = true,
    Map<String, dynamic>? metadata,
  }) async {
    final fileId = DateTime.now().millisecondsSinceEpoch
        .toString(); // Moved outside try block
    try {
      final mimeType = _getMimeType(file.path);
      final fileType = _getFileType(mimeType);
      final fileSize = await file.length();

      // Create initial file info
      final fileInfo = FileInfo(
        id: fileId,
        name: file.path.split('/').last,
        path: file.path,
        type: fileType,
        purpose: purpose,
        status: FileStatus.uploading,
        size: fileSize,
        mimeType: mimeType,
        metadata: metadata,
        isCompressed: compress,
      );

      // Add to state
      state.whenData((fileState) {
        final updatedFiles = Map<String, FileInfo>.from(fileState.files);
        updatedFiles[fileId] = fileInfo;

        state = AsyncValue.data(
          fileState.copyWith(
            files: updatedFiles,
            totalFiles: updatedFiles.length,
          ),
        );
      });

      // Create cancel token for upload
      final cancelToken = CancelToken();
      _uploadCancelTokens[fileId] = cancelToken;

      // Upload file
      final response = await _apiService.uploadFile(
        file: file,
        purpose: purpose.name,
        chatId: chatId,
        public: public,
        onProgress: (sent, total) {
          final progress = sent / total;
          _updateUploadProgress(fileId, progress);
        },
      );

      if (response.success && response.data != null) {
        final uploadedFile = response.data!;

        // Update file info with server response
        final updatedFileInfo = fileInfo.copyWith(
          url: uploadedFile.url,
          status: FileStatus.uploaded,
          uploadedAt: DateTime.now(),
          uploadProgress: 1.0,
          thumbnailUrl: uploadedFile.thumbnailUrl,
        );

        state.whenData((fileState) {
          final updatedFiles = Map<String, FileInfo>.from(fileState.files);
          updatedFiles[fileId] = updatedFileInfo;

          state = AsyncValue.data(
            fileState.copyWith(
              files: updatedFiles,
              uploadProgress: Map<String, double>.from(fileState.uploadProgress)
                ..remove(fileId),
            ),
          );
        });

        await _cacheFile(updatedFileInfo);
        _uploadCancelTokens.remove(fileId);

        if (kDebugMode) print('✅ File uploaded: ${fileInfo.name}');
        return updatedFileInfo;
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      // Update file status to failed
      state.whenData((fileState) {
        final updatedFiles = Map<String, FileInfo>.from(fileState.files);
        final failedFile = updatedFiles[fileId];
        if (failedFile != null) {
          // Check if file exists
          updatedFiles[fileId] = failedFile.copyWith(
            status: FileStatus.failed,
            error: e.toString(),
          );
          state = AsyncValue.data(
            fileState.copyWith(
              files: updatedFiles,
              uploadProgress: Map<String, double>.from(fileState.uploadProgress)
                ..remove(fileId),
            ),
          );
        }
      });

      _uploadCancelTokens.remove(fileId);
      if (kDebugMode) print('❌ Error uploading file: $e');
      rethrow;
    }
  }

  Future<FileInfo> downloadFile(String fileId) async {
    try {
      final fileInfo = state.value?.files[fileId];
      if (fileInfo == null) {
        throw Exception('File not found');
      }

      if (fileInfo.isDownloaded) {
        return fileInfo;
      }

      // Create cancel token for download
      final cancelToken = CancelToken();
      _downloadCancelTokens[fileId] = cancelToken;

      // Get download directory
      final appDir = await getApplicationDocumentsDirectory();
      final downloadDir = Directory('${appDir.path}/downloads');
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      final localPath = '${downloadDir.path}/${fileInfo.name}';

      // Download file
      final response = await _apiService.downloadFile(
        fileId: fileId,
        savePath: localPath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            _updateDownloadProgress(fileId, progress);
          }
        },
        cancelToken: cancelToken,
      );

      if (response.success) {
        // Update file info
        final updatedFileInfo = fileInfo.copyWith(
          path: localPath,
          isDownloaded: true,
        );

        state.whenData((fileState) {
          final updatedFiles = Map<String, FileInfo>.from(fileState.files);
          updatedFiles[fileId] = updatedFileInfo;

          state = AsyncValue.data(
            fileState.copyWith(
              files: updatedFiles,
              downloadProgress: Map<String, double>.from(
                fileState.downloadProgress,
              )..remove(fileId),
            ),
          );
        });

        await _cacheFile(updatedFileInfo);
        _downloadCancelTokens.remove(fileId);

        if (kDebugMode) print('✅ File downloaded: ${fileInfo.name}');
        return updatedFileInfo;
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      _downloadCancelTokens.remove(fileId);
      if (kDebugMode) print('❌ Error downloading file: $e');
      rethrow;
    }
  }

  void _updateUploadProgress(String fileId, double progress) {
    state.whenData((fileState) {
      final updatedProgress = Map<String, double>.from(
        fileState.uploadProgress,
      );
      updatedProgress[fileId] = progress;

      final updatedFiles = Map<String, FileInfo>.from(fileState.files);
      final fileInfo = updatedFiles[fileId];
      if (fileInfo != null) {
        updatedFiles[fileId] = fileInfo.copyWith(uploadProgress: progress);
      }

      state = AsyncValue.data(
        fileState.copyWith(
          uploadProgress: updatedProgress,
          files: updatedFiles,
        ),
      );
    });
  }

  void _updateDownloadProgress(String fileId, double progress) {
    state.whenData((fileState) {
      final updatedProgress = Map<String, double>.from(
        fileState.downloadProgress,
      );
      updatedProgress[fileId] = progress;

      state = AsyncValue.data(
        fileState.copyWith(downloadProgress: updatedProgress),
      );
    });
  }

  Future<void> cancelUpload(String fileId) async {
    try {
      final cancelToken = _uploadCancelTokens[fileId];
      if (cancelToken != null) {
        cancelToken.cancel('Upload cancelled by user');
        _uploadCancelTokens.remove(fileId);

        state.whenData((fileState) {
          final updatedFiles = Map<String, FileInfo>.from(fileState.files);
          final fileInfo = updatedFiles[fileId];
          if (fileInfo != null) {
            updatedFiles[fileId] = fileInfo.copyWith(
              status: FileStatus.cancelled,
            );
          }

          state = AsyncValue.data(
            fileState.copyWith(
              files: updatedFiles,
              uploadProgress: Map<String, double>.from(fileState.uploadProgress)
                ..remove(fileId),
            ),
          );
        });

        if (kDebugMode) print('❌ Upload cancelled: $fileId');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error cancelling upload: $e');
    }
  }

  Future<void> cancelDownload(String fileId) async {
    try {
      final cancelToken = _downloadCancelTokens[fileId];
      if (cancelToken != null) {
        cancelToken.cancel('Download cancelled by user');
        _downloadCancelTokens.remove(fileId);

        state.whenData((fileState) {
          state = AsyncValue.data(
            fileState.copyWith(
              downloadProgress: Map<String, double>.from(
                fileState.downloadProgress,
              )..remove(fileId),
            ),
          );
        });

        if (kDebugMode) print('❌ Download cancelled: $fileId');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error cancelling download: $e');
    }
  }

  Future<void> deleteFile(String fileId) async {
    try {
      final fileInfo = state.value?.files[fileId];
      if (fileInfo == null) return;

      // Delete from server
      final response = await _apiService.deleteFile(fileId);
      if (response.success) {
        // Delete local file
        if (fileInfo.isDownloaded) {
          final file = File(fileInfo.path);
          if (await file.exists()) {
            await file.delete();
          }
        }

        // Remove from state
        state.whenData((fileState) {
          final updatedFiles = Map<String, FileInfo>.from(fileState.files);
          updatedFiles.remove(fileId);

          state = AsyncValue.data(
            fileState.copyWith(
              files: updatedFiles,
              totalFiles: updatedFiles.length,
            ),
          );
        });

        await _calculateStorageUsage();
        if (kDebugMode) print('✅ File deleted: ${fileInfo.name}');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error deleting file: $e');
      rethrow;
    }
  }

  Future<void> retryUpload(String fileId) async {
    try {
      final fileInfo = state.value?.files[fileId];
      if (fileInfo == null || !fileInfo.hasFailed) return;

      final file = File(fileInfo.path);
      if (!await file.exists()) {
        throw Exception('Local file not found');
      }

      await uploadFile(
        file: file,
        purpose: fileInfo.purpose,
        compress: fileInfo.isCompressed,
        metadata: fileInfo.metadata,
      );
    } catch (e) {
      if (kDebugMode) print('❌ Error retrying upload: $e');
      rethrow;
    }
  }

  Future<void> _cacheFile(FileInfo fileInfo) async {
    try {
      await _cacheService.cacheFile(fileInfo.id, fileInfo.toJson());
    } catch (e) {
      if (kDebugMode) print('❌ Error caching file: $e');
    }
  }

  String _getMimeType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }

  FileType _getFileType(String mimeType) {
    if (mimeType.startsWith('image/')) return FileType.image;
    if (mimeType.startsWith('video/')) return FileType.video;
    if (mimeType.startsWith('audio/')) return FileType.audio;
    if (mimeType.contains('pdf') ||
        mimeType.contains('document') ||
        mimeType.contains('text'))
      return FileType.document;
    if (mimeType.contains('zip') || mimeType.contains('archive'))
      return FileType.archive;
    return FileType.other;
  }

  // Getters
  Map<String, FileInfo> get files => state.value?.files ?? {};
  bool get isLoading => state.value?.isLoading ?? false;
  int get totalFiles => state.value?.totalFiles ?? 0;
  String get storageUsed => state.value?.storageUsed ?? '0 B';
  List<FileInfo> get recentFiles => state.value?.recentFiles ?? [];
  List<FileInfo> get uploadingFiles => state.value?.uploadingFiles ?? [];
  List<FileInfo> get failedFiles => state.value?.failedFiles ?? [];

  @override
  void dispose() {
    // Cancel all ongoing operations
    for (final cancelToken in _uploadCancelTokens.values) {
      cancelToken.cancel('Provider disposed');
    }
    for (final cancelToken in _downloadCancelTokens.values) {
      cancelToken.cancel('Provider disposed');
    }

    _uploadCancelTokens.clear();
    _downloadCancelTokens.clear();
    _storageCleanupTimer?.cancel();

    super.dispose();
  }
}

// Providers
final fileProvider = StateNotifierProvider<FileNotifier, AsyncValue<FileState>>(
  (ref) {
    return FileNotifier(
      apiService: ref.watch(apiServiceProvider),
      cacheService: CacheService(),
    );
  },
);

// Convenience providers
final filesMapProvider = Provider<Map<String, FileInfo>>((ref) {
  final fileState = ref.watch(fileProvider);
  return fileState.whenOrNull(data: (state) => state.files) ?? {};
});

final fileLoadingProvider = Provider<bool>((ref) {
  final fileState = ref.watch(fileProvider);
  return fileState.whenOrNull(data: (state) => state.isLoading) ?? false;
});

final fileByIdProvider = Provider.family<FileInfo?, String>((ref, fileId) {
  final files = ref.watch(filesMapProvider);
  return files[fileId];
});

final filesByTypeProvider = Provider.family<List<FileInfo>, FileType>((
  ref,
  type,
) {
  final fileState = ref.watch(fileProvider);
  return fileState.whenOrNull(data: (state) => state.getFilesByType(type)) ??
      [];
});

final filesByPurposeProvider = Provider.family<List<FileInfo>, FilePurpose>((
  ref,
  purpose,
) {
  final fileState = ref.watch(fileProvider);
  return fileState.whenOrNull(
        data: (state) => state.getFilesByPurpose(purpose),
      ) ??
      [];
});

final recentFilesProvider = Provider<List<FileInfo>>((ref) {
  final fileState = ref.watch(fileProvider);
  return fileState.whenOrNull(data: (state) => state.recentFiles) ?? [];
});

final uploadingFilesProvider = Provider<List<FileInfo>>((ref) {
  final fileState = ref.watch(fileProvider);
  return fileState.whenOrNull(data: (state) => state.uploadingFiles) ?? [];
});

final failedFilesProvider = Provider<List<FileInfo>>((ref) {
  final fileState = ref.watch(fileProvider);
  return fileState.whenOrNull(data: (state) => state.failedFiles) ?? [];
});

final uploadProgressProvider = Provider.family<double?, String>((ref, fileId) {
  final fileState = ref.watch(fileProvider);
  return fileState.whenOrNull(data: (state) => state.uploadProgress[fileId]);
});

final downloadProgressProvider = Provider.family<double?, String>((
  ref,
  fileId,
) {
  final fileState = ref.watch(fileProvider);
  return fileState.whenOrNull(data: (state) => state.downloadProgress[fileId]);
});

final storageUsageProvider = Provider<Map<String, dynamic>>((ref) {
  final fileState = ref.watch(fileProvider);
  return fileState.whenOrNull(
        data: (state) => {
          'total_files': state.totalFiles,
          'total_size': state.totalSize,
          'storage_used': state.storageUsed,
        },
      ) ??
      {};
});
