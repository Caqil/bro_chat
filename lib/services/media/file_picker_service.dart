import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mime/mime.dart';

import '../../core/exceptions/app_exception.dart';
import '../../core/config/app_config.dart';
import '../storage/cache_service.dart';
import '../storage/local_storage.dart';

enum FilePickerSource { gallery, camera, document, audio, video, any }

enum FilePickerMode { single, multiple }

class PickedFileInfo {
  final String path;
  final String name;
  final String? extension;
  final int size;
  final DateTime dateModified;
  final String? mimeType;
  final Uint8List? bytes;
  final FilePickerSource source;

  PickedFileInfo({
    required this.path,
    required this.name,
    this.extension,
    required this.size,
    required this.dateModified,
    this.mimeType,
    this.bytes,
    required this.source,
  });

  bool get isImage => _isImageMimeType(mimeType);
  bool get isVideo => _isVideoMimeType(mimeType);
  bool get isAudio => _isAudioMimeType(mimeType);
  bool get isDocument => _isDocumentMimeType(mimeType);

  static bool _isImageMimeType(String? mimeType) {
    if (mimeType == null) return false;
    return mimeType.startsWith('image/');
  }

  static bool _isVideoMimeType(String? mimeType) {
    if (mimeType == null) return false;
    return mimeType.startsWith('video/');
  }

  static bool _isAudioMimeType(String? mimeType) {
    if (mimeType == null) return false;
    return mimeType.startsWith('audio/');
  }

  static bool _isDocumentMimeType(String? mimeType) {
    if (mimeType == null) return false;
    return AppConfig.allowedDocumentTypes.contains(mimeType);
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'name': name,
      'extension': extension,
      'size': size,
      'date_modified': dateModified.toIso8601String(),
      'mime_type': mimeType,
      'source': source.name,
    };
  }

  factory PickedFileInfo.fromJson(Map<String, dynamic> json) {
    return PickedFileInfo(
      path: json['path'],
      name: json['name'],
      extension: json['extension'],
      size: json['size'],
      dateModified: DateTime.parse(json['date_modified']),
      mimeType: json['mime_type'],
      source: FilePickerSource.values.firstWhere(
        (s) => s.name == json['source'],
        orElse: () => FilePickerSource.any,
      ),
    );
  }

  @override
  String toString() {
    return 'PickedFileInfo(name: $name, size: ${_formatFileSize(size)}, type: $mimeType)';
  }

  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
}

class FilePickerOptions {
  final FilePickerMode mode;
  final List<String>? allowedExtensions;
  final List<String>? allowedMimeTypes;
  final int? maxFileSize;
  final int? maxFiles;
  final bool allowCompression;
  final int? imageQuality;
  final int? maxWidth;
  final int? maxHeight;

  const FilePickerOptions({
    this.mode = FilePickerMode.single,
    this.allowedExtensions,
    this.allowedMimeTypes,
    this.maxFileSize,
    this.maxFiles,
    this.allowCompression = true,
    this.imageQuality,
    this.maxWidth,
    this.maxHeight,
  });

  FilePickerOptions copyWith({
    FilePickerMode? mode,
    List<String>? allowedExtensions,
    List<String>? allowedMimeTypes,
    int? maxFileSize,
    int? maxFiles,
    bool? allowCompression,
    int? imageQuality,
    int? maxWidth,
    int? maxHeight,
  }) {
    return FilePickerOptions(
      mode: mode ?? this.mode,
      allowedExtensions: allowedExtensions ?? this.allowedExtensions,
      allowedMimeTypes: allowedMimeTypes ?? this.allowedMimeTypes,
      maxFileSize: maxFileSize ?? this.maxFileSize,
      maxFiles: maxFiles ?? this.maxFiles,
      allowCompression: allowCompression ?? this.allowCompression,
      imageQuality: imageQuality ?? this.imageQuality,
      maxWidth: maxWidth ?? this.maxWidth,
      maxHeight: maxHeight ?? this.maxHeight,
    );
  }
}

class FilePickerService {
  static FilePickerService? _instance;

  final CacheService _cacheService;
  final LocalStorage _localStorage;
  final ImagePicker _imagePicker;

  // Recently picked files
  final List<PickedFileInfo> _recentFiles = [];
  static const int _maxRecentFiles = 20;

  // Event streams
  final StreamController<List<PickedFileInfo>> _filePickedController =
      StreamController<List<PickedFileInfo>>.broadcast();

  FilePickerService._internal()
    : _cacheService = CacheService(),
      _localStorage = LocalStorage(),
      _imagePicker = ImagePicker() {
    _initialize();
  }

  factory FilePickerService() {
    _instance ??= FilePickerService._internal();
    return _instance!;
  }

  // Getters
  List<PickedFileInfo> get recentFiles => List.unmodifiable(_recentFiles);

  // Streams
  Stream<List<PickedFileInfo>> get filePickedStream =>
      _filePickedController.stream;

  void _initialize() {
    _loadRecentFiles();
  }

  Future<void> _loadRecentFiles() async {
    try {
      final recentFilesData = await _cacheService.getCachedData('recent_files');
      if (recentFilesData != null && recentFilesData is List) {
        _recentFiles.clear();
        for (final item in recentFilesData) {
          _recentFiles.add(PickedFileInfo.fromJson(item));
        }
      }

      if (kDebugMode) {
        print('✅ Recent files loaded: ${_recentFiles.length} items');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading recent files: $e');
      }
    }
  }

  Future<void> _saveRecentFiles() async {
    try {
      final recentFilesData = _recentFiles.map((f) => f.toJson()).toList();
      await _cacheService.cache('recent_files', recentFilesData);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving recent files: $e');
      }
    }
  }

  // Permission methods

  Future<bool> checkStoragePermission() async {
    try {
      if (Platform.isAndroid) {
        final status = await Permission.storage.status;
        return status.isGranted;
      } else {
        // iOS doesn't require explicit storage permission for file picker
        return true;
      }
    } catch (e) {
      return false;
    }
  }

  Future<bool> requestStoragePermission() async {
    try {
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        return status.isGranted;
      } else {
        return true;
      }
    } catch (e) {
      return false;
    }
  }

  Future<bool> checkCameraPermission() async {
    try {
      final status = await Permission.camera.status;
      return status.isGranted;
    } catch (e) {
      return false;
    }
  }

  Future<bool> requestCameraPermission() async {
    try {
      final status = await Permission.camera.request();
      return status.isGranted;
    } catch (e) {
      return false;
    }
  }

  // Public API

  Future<List<PickedFileInfo>?> pickFiles({
    required FilePickerSource source,
    FilePickerOptions? options,
  }) async {
    try {
      final pickerOptions = options ?? const FilePickerOptions();

      switch (source) {
        case FilePickerSource.gallery:
          return await _pickFromGallery(pickerOptions);
        case FilePickerSource.camera:
          return await _pickFromCamera(pickerOptions);
        case FilePickerSource.document:
          return await _pickDocuments(pickerOptions);
        case FilePickerSource.audio:
          return await _pickAudio(pickerOptions);
        case FilePickerSource.video:
          return await _pickVideo(pickerOptions);
        case FilePickerSource.any:
          return await _pickAnyFile(pickerOptions);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error picking files: $e');
      }

      if (e.toString().contains('permission')) {
        throw PermissionException.storage();
      } else if (e.toString().contains('cancelled')) {
        return null;
      } else {
        throw FileException.accessDenied('Unknown');
      }
    }
  }

  Future<List<PickedFileInfo>?> _pickFromGallery(
    FilePickerOptions options,
  ) async {
    try {
      List<XFile> pickedFiles = [];

      if (options.mode == FilePickerMode.multiple) {
        pickedFiles = await _imagePicker.pickMultipleMedia(
          maxWidth: options.maxWidth?.toDouble(),
          maxHeight: options.maxHeight?.toDouble(),
          imageQuality: options.imageQuality,
        );
      } else {
        final pickedFile = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          maxWidth: options.maxWidth?.toDouble(),
          maxHeight: options.maxHeight?.toDouble(),
          imageQuality: options.imageQuality,
        );
        if (pickedFile != null) {
          pickedFiles = [pickedFile];
        }
      }

      if (pickedFiles.isEmpty) return null;

      final result = <PickedFileInfo>[];
      for (final file in pickedFiles) {
        final fileInfo = await _createPickedFileInfo(
          file.path,
          FilePickerSource.gallery,
          options,
        );
        if (fileInfo != null) {
          result.add(fileInfo);
        }
      }

      if (result.isNotEmpty) {
        _addToRecentFiles(result);
        _filePickedController.add(result);
      }

      return result.isEmpty ? null : result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error picking from gallery: $e');
      }
      rethrow;
    }
  }

  Future<List<PickedFileInfo>?> _pickFromCamera(
    FilePickerOptions options,
  ) async {
    try {
      // Check camera permission
      if (!await checkCameraPermission()) {
        final granted = await requestCameraPermission();
        if (!granted) {
          throw PermissionException.camera();
        }
      }

      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: options.maxWidth?.toDouble(),
        maxHeight: options.maxHeight?.toDouble(),
        imageQuality: options.imageQuality,
      );

      if (pickedFile == null) return null;

      final fileInfo = await _createPickedFileInfo(
        pickedFile.path,
        FilePickerSource.camera,
        options,
      );

      if (fileInfo != null) {
        final result = [fileInfo];
        _addToRecentFiles(result);
        _filePickedController.add(result);
        return result;
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error picking from camera: $e');
      }
      rethrow;
    }
  }

  Future<List<PickedFileInfo>?> _pickDocuments(
    FilePickerOptions options,
  ) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions:
            options.allowedExtensions ??
            ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt'],
        allowMultiple: options.mode == FilePickerMode.multiple,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return null;

      final pickedFiles = <PickedFileInfo>[];
      for (final file in result.files) {
        if (file.path != null) {
          final fileInfo = await _createPickedFileInfoFromPlatformFile(
            file,
            FilePickerSource.document,
            options,
          );
          if (fileInfo != null) {
            pickedFiles.add(fileInfo);
          }
        }
      }

      if (pickedFiles.isNotEmpty) {
        _addToRecentFiles(pickedFiles);
        _filePickedController.add(pickedFiles);
      }

      return pickedFiles.isEmpty ? null : pickedFiles;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error picking documents: $e');
      }
      rethrow;
    }
  }

  Future<List<PickedFileInfo>?> _pickAudio(FilePickerOptions options) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: options.mode == FilePickerMode.multiple,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return null;

      final pickedFiles = <PickedFileInfo>[];
      for (final file in result.files) {
        if (file.path != null) {
          final fileInfo = await _createPickedFileInfoFromPlatformFile(
            file,
            FilePickerSource.audio,
            options,
          );
          if (fileInfo != null) {
            pickedFiles.add(fileInfo);
          }
        }
      }

      if (pickedFiles.isNotEmpty) {
        _addToRecentFiles(pickedFiles);
        _filePickedController.add(pickedFiles);
      }

      return pickedFiles.isEmpty ? null : pickedFiles;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error picking audio: $e');
      }
      rethrow;
    }
  }

  Future<List<PickedFileInfo>?> _pickVideo(FilePickerOptions options) async {
    try {
      final pickedFile = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 10),
      );

      if (pickedFile == null) return null;

      final fileInfo = await _createPickedFileInfo(
        pickedFile.path,
        FilePickerSource.video,
        options,
      );

      if (fileInfo != null) {
        final result = [fileInfo];
        _addToRecentFiles(result);
        _filePickedController.add(result);
        return result;
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error picking video: $e');
      }
      rethrow;
    }
  }

  Future<List<PickedFileInfo>?> _pickAnyFile(FilePickerOptions options) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: options.mode == FilePickerMode.multiple,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return null;

      final pickedFiles = <PickedFileInfo>[];
      for (final file in result.files) {
        if (file.path != null) {
          final fileInfo = await _createPickedFileInfoFromPlatformFile(
            file,
            FilePickerSource.any,
            options,
          );
          if (fileInfo != null) {
            pickedFiles.add(fileInfo);
          }
        }
      }

      if (pickedFiles.isNotEmpty) {
        _addToRecentFiles(pickedFiles);
        _filePickedController.add(pickedFiles);
      }

      return pickedFiles.isEmpty ? null : pickedFiles;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error picking any file: $e');
      }
      rethrow;
    }
  }

  Future<PickedFileInfo?> _createPickedFileInfo(
    String filePath,
    FilePickerSource source,
    FilePickerOptions options,
  ) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      final stat = await file.stat();
      final mimeType = lookupMimeType(filePath);

      // Check file size
      if (options.maxFileSize != null && stat.size > options.maxFileSize!) {
        throw FileException.tooLarge(filePath, options.maxFileSize!);
      }

      // Check mime type
      if (options.allowedMimeTypes != null && mimeType != null) {
        if (!options.allowedMimeTypes!.contains(mimeType)) {
          throw FileException.unsupportedFormat(filePath, mimeType);
        }
      }

      final fileName = filePath.split('/').last;
      final extension = fileName.contains('.')
          ? fileName.split('.').last.toLowerCase()
          : null;

      return PickedFileInfo(
        path: filePath,
        name: fileName,
        extension: extension,
        size: stat.size,
        dateModified: stat.modified,
        mimeType: mimeType,
        source: source,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error creating picked file info: $e');
      }
      if (e is FileException) rethrow;
      return null;
    }
  }

  Future<PickedFileInfo?> _createPickedFileInfoFromPlatformFile(
    PlatformFile platformFile,
    FilePickerSource source,
    FilePickerOptions options,
  ) async {
    try {
      // Check file size
      if (options.maxFileSize != null &&
          platformFile.size > options.maxFileSize!) {
        throw FileException.tooLarge(platformFile.path!, options.maxFileSize!);
      }

      // Check mime type
      if (options.allowedMimeTypes != null && platformFile.path != null) {
        final mimeType = lookupMimeType(platformFile.path!);
        if (mimeType != null && !options.allowedMimeTypes!.contains(mimeType)) {
          throw FileException.unsupportedFormat(platformFile.path!, mimeType);
        }
      }

      DateTime dateModified = DateTime.now();
      if (platformFile.path != null) {
        final file = File(platformFile.path!);
        if (await file.exists()) {
          final stat = await file.stat();
          dateModified = stat.modified;
        }
      }

      return PickedFileInfo(
        path: platformFile.path!,
        name: platformFile.name,
        extension: platformFile.extension,
        size: platformFile.size,
        dateModified: dateModified,
        mimeType: lookupMimeType(platformFile.path!),
        bytes: platformFile.bytes,
        source: source,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error creating picked file info from platform file: $e');
      }
      if (e is FileException) rethrow;
      return null;
    }
  }

  void _addToRecentFiles(List<PickedFileInfo> files) {
    for (final file in files) {
      // Remove if already exists
      _recentFiles.removeWhere((f) => f.path == file.path);

      // Add to beginning
      _recentFiles.insert(0, file);
    }

    // Limit size
    if (_recentFiles.length > _maxRecentFiles) {
      _recentFiles.removeRange(_maxRecentFiles, _recentFiles.length);
    }

    _saveRecentFiles();
  }

  // Utility methods

  Future<String> copyFileToAppDirectory(
    PickedFileInfo fileInfo, {
    String? newName,
  }) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = newName ?? fileInfo.name;
      final newPath = '${appDir.path}/$fileName';

      final sourceFile = File(fileInfo.path);
      await sourceFile.copy(newPath);

      if (kDebugMode) {
        print('📁 File copied to app directory: $newPath');
      }

      return newPath;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error copying file to app directory: $e');
      }
      throw FileException.accessDenied(fileInfo.path);
    }
  }

  Future<Uint8List?> readFileBytes(PickedFileInfo fileInfo) async {
    try {
      if (fileInfo.bytes != null) {
        return fileInfo.bytes;
      }

      final file = File(fileInfo.path);
      if (await file.exists()) {
        return await file.readAsBytes();
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error reading file bytes: $e');
      }
      return null;
    }
  }

  bool isFileSizeValid(PickedFileInfo fileInfo, int maxSize) {
    return fileInfo.size <= maxSize;
  }

  bool isFileTypeValid(PickedFileInfo fileInfo, List<String> allowedTypes) {
    if (fileInfo.mimeType == null) return false;
    return allowedTypes.contains(fileInfo.mimeType);
  }

  List<PickedFileInfo> filterFilesByType(
    List<PickedFileInfo> files,
    List<String> allowedTypes,
  ) {
    return files.where((file) => isFileTypeValid(file, allowedTypes)).toList();
  }

  List<PickedFileInfo> filterFilesBySize(
    List<PickedFileInfo> files,
    int maxSize,
  ) {
    return files.where((file) => isFileSizeValid(file, maxSize)).toList();
  }

  Future<bool> deleteFile(PickedFileInfo fileInfo) async {
    try {
      final file = File(fileInfo.path);
      if (await file.exists()) {
        await file.delete();

        // Remove from recent files
        _recentFiles.removeWhere((f) => f.path == fileInfo.path);
        await _saveRecentFiles();

        if (kDebugMode) {
          print('🗑️ File deleted: ${fileInfo.path}');
        }

        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error deleting file: $e');
      }
      return false;
    }
  }

  void clearRecentFiles() {
    _recentFiles.clear();
    _saveRecentFiles();

    if (kDebugMode) {
      print('🗑️ Recent files cleared');
    }
  }

  // Get file info for existing file
  Future<PickedFileInfo?> getFileInfo(
    String filePath,
    FilePickerSource source,
  ) async {
    return await _createPickedFileInfo(
      filePath,
      source,
      const FilePickerOptions(),
    );
  }

  // Shortcut methods for common use cases

  Future<PickedFileInfo?> pickSingleImage({
    int? imageQuality,
    int? maxWidth,
    int? maxHeight,
  }) async {
    final options = FilePickerOptions(
      mode: FilePickerMode.single,
      imageQuality: imageQuality,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      maxFileSize: AppConfig.maxImageSize,
    );

    final result = await pickFiles(
      source: FilePickerSource.gallery,
      options: options,
    );

    return result?.first;
  }

  Future<List<PickedFileInfo>?> pickMultipleImages({
    int? maxFiles,
    int? imageQuality,
    int? maxWidth,
    int? maxHeight,
  }) async {
    final options = FilePickerOptions(
      mode: FilePickerMode.multiple,
      maxFiles: maxFiles,
      imageQuality: imageQuality,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      maxFileSize: AppConfig.maxImageSize,
    );

    return await pickFiles(source: FilePickerSource.gallery, options: options);
  }

  Future<PickedFileInfo?> takePhoto({
    int? imageQuality,
    int? maxWidth,
    int? maxHeight,
  }) async {
    final options = FilePickerOptions(
      mode: FilePickerMode.single,
      imageQuality: imageQuality,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      maxFileSize: AppConfig.maxImageSize,
    );

    final result = await pickFiles(
      source: FilePickerSource.camera,
      options: options,
    );

    return result?.first;
  }

  Future<PickedFileInfo?> pickSingleDocument() async {
    final options = FilePickerOptions(
      mode: FilePickerMode.single,
      allowedMimeTypes: AppConfig.allowedDocumentTypes,
      maxFileSize: AppConfig.maxFileSize,
    );

    final result = await pickFiles(
      source: FilePickerSource.document,
      options: options,
    );

    return result?.first;
  }

  Future<PickedFileInfo?> pickSingleVideo() async {
    final options = FilePickerOptions(
      mode: FilePickerMode.single,
      allowedMimeTypes: AppConfig.allowedVideoTypes,
      maxFileSize: AppConfig.maxFileSize,
    );

    final result = await pickFiles(
      source: FilePickerSource.video,
      options: options,
    );

    return result?.first;
  }

  Future<PickedFileInfo?> pickSingleAudio() async {
    final options = FilePickerOptions(
      mode: FilePickerMode.single,
      allowedMimeTypes: AppConfig.allowedAudioTypes,
      maxFileSize: AppConfig.maxFileSize,
    );

    final result = await pickFiles(
      source: FilePickerSource.audio,
      options: options,
    );

    return result?.first;
  }

  // Cleanup

  Future<void> dispose() async {
    await _filePickedController.close();

    if (kDebugMode) {
      print('✅ File picker service disposed');
    }
  }
}

// Riverpod providers
final filePickerServiceProvider = Provider<FilePickerService>((ref) {
  return FilePickerService();
});

final filePickedProvider = StreamProvider<List<PickedFileInfo>>((ref) {
  final service = ref.watch(filePickerServiceProvider);
  return service.filePickedStream;
});

final recentFilesProvider = Provider<List<PickedFileInfo>>((ref) {
  final service = ref.watch(filePickerServiceProvider);
  return service.recentFiles;
});

final storagePermissionProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(filePickerServiceProvider);
  return service.checkStoragePermission();
});

final cameraPermissionProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(filePickerServiceProvider);
  return service.checkCameraPermission();
});
