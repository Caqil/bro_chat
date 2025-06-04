import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../services/storage/cache_service.dart';
import '../common/permission_provider.dart';
import 'file_provider.dart';

enum MediaType { image, video, audio }

enum MediaSource { camera, gallery, microphone, file }

enum MediaQuality { low, medium, high, original }

enum CameraLensDirection { front, back, external }

class MediaFile {
  final String id;
  final String path;
  final MediaType type;
  final MediaSource source;
  final int size;
  final Duration? duration;
  final int? width;
  final int? height;
  final double? aspectRatio;
  final DateTime createdAt;
  final String? thumbnailPath;
  final bool isCompressed;
  final MediaQuality quality;
  final Map<String, dynamic>? metadata;

  MediaFile({
    required this.id,
    required this.path,
    required this.type,
    required this.source,
    required this.size,
    this.duration,
    this.width,
    this.height,
    this.aspectRatio,
    DateTime? createdAt,
    this.thumbnailPath,
    this.isCompressed = false,
    this.quality = MediaQuality.medium,
    this.metadata,
  }) : createdAt = createdAt ?? DateTime.now();

  MediaFile copyWith({
    String? id,
    String? path,
    MediaType? type,
    MediaSource? source,
    int? size,
    Duration? duration,
    int? width,
    int? height,
    double? aspectRatio,
    DateTime? createdAt,
    String? thumbnailPath,
    bool? isCompressed,
    MediaQuality? quality,
    Map<String, dynamic>? metadata,
  }) {
    return MediaFile(
      id: id ?? this.id,
      path: path ?? this.path,
      type: type ?? this.type,
      source: source ?? this.source,
      size: size ?? this.size,
      duration: duration ?? this.duration,
      width: width ?? this.width,
      height: height ?? this.height,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      createdAt: createdAt ?? this.createdAt,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      isCompressed: isCompressed ?? this.isCompressed,
      quality: quality ?? this.quality,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isImage => type == MediaType.image;
  bool get isVideo => type == MediaType.video;
  bool get isAudio => type == MediaType.audio;

  String get extension => path.split('.').last.toLowerCase();
  String get filename => path.split('/').last;
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
      'path': path,
      'type': type.name,
      'source': source.name,
      'size': size,
      'duration': duration?.inMilliseconds,
      'width': width,
      'height': height,
      'aspect_ratio': aspectRatio,
      'created_at': createdAt.toIso8601String(),
      'thumbnail_path': thumbnailPath,
      'is_compressed': isCompressed,
      'quality': quality.name,
      'metadata': metadata,
    };
  }

  factory MediaFile.fromJson(Map<String, dynamic> json) {
    return MediaFile(
      id: json['id'] ?? '',
      path: json['path'] ?? '',
      type: MediaType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MediaType.image,
      ),
      source: MediaSource.values.firstWhere(
        (e) => e.name == json['source'],
        orElse: () => MediaSource.gallery,
      ),
      size: json['size'] ?? 0,
      duration: json['duration'] != null
          ? Duration(milliseconds: json['duration'])
          : null,
      width: json['width'],
      height: json['height'],
      aspectRatio: json['aspect_ratio']?.toDouble(),
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      thumbnailPath: json['thumbnail_path'],
      isCompressed: json['is_compressed'] ?? false,
      quality: MediaQuality.values.firstWhere(
        (e) => e.name == json['quality'],
        orElse: () => MediaQuality.medium,
      ),
      metadata: json['metadata'],
    );
  }
}

class MediaState {
  final List<MediaFile> recentMedia;
  final bool isLoading;
  final String? error;
  final bool isInitialized;
  final bool isCameraInitialized;
  final CameraController? cameraController;
  final List<CameraDescription> availableCameras;
  final CameraLensDirection currentCameraDirection;
  final bool isRecording;
  final bool flashEnabled;
  final MediaQuality defaultImageQuality;
  final MediaQuality defaultVideoQuality;
  final bool autoCompress;
  final int maxImageSize;
  final Duration maxVideoDuration;

  MediaState({
    this.recentMedia = const [],
    this.isLoading = false,
    this.error,
    this.isInitialized = false,
    this.isCameraInitialized = false,
    this.cameraController,
    this.availableCameras = const [],
    this.currentCameraDirection = CameraLensDirection.back,
    this.isRecording = false,
    this.flashEnabled = false,
    this.defaultImageQuality = MediaQuality.high,
    this.defaultVideoQuality = MediaQuality.medium,
    this.autoCompress = true,
    this.maxImageSize = 1920,
    this.maxVideoDuration = const Duration(minutes: 5),
  });

  MediaState copyWith({
    List<MediaFile>? recentMedia,
    bool? isLoading,
    String? error,
    bool? isInitialized,
    bool? isCameraInitialized,
    CameraController? cameraController,
    List<CameraDescription>? availableCameras,
    CameraLensDirection? currentCameraDirection,
    bool? isRecording,
    bool? flashEnabled,
    MediaQuality? defaultImageQuality,
    MediaQuality? defaultVideoQuality,
    bool? autoCompress,
    int? maxImageSize,
    Duration? maxVideoDuration,
  }) {
    return MediaState(
      recentMedia: recentMedia ?? this.recentMedia,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isInitialized: isInitialized ?? this.isInitialized,
      isCameraInitialized: isCameraInitialized ?? this.isCameraInitialized,
      cameraController: cameraController ?? this.cameraController,
      availableCameras: availableCameras ?? this.availableCameras,
      currentCameraDirection:
          currentCameraDirection ?? this.currentCameraDirection,
      isRecording: isRecording ?? this.isRecording,
      flashEnabled: flashEnabled ?? this.flashEnabled,
      defaultImageQuality: defaultImageQuality ?? this.defaultImageQuality,
      defaultVideoQuality: defaultVideoQuality ?? this.defaultVideoQuality,
      autoCompress: autoCompress ?? this.autoCompress,
      maxImageSize: maxImageSize ?? this.maxImageSize,
      maxVideoDuration: maxVideoDuration ?? this.maxVideoDuration,
    );
  }

  List<MediaFile> get images => recentMedia.where((m) => m.isImage).toList();
  List<MediaFile> get videos => recentMedia.where((m) => m.isVideo).toList();
  List<MediaFile> get audio => recentMedia.where((m) => m.isAudio).toList();

  MediaFile? getMediaById(String id) {
    try {
      return recentMedia.firstWhere((m) => m.id == id);
    } catch (e) {
      return null;
    }
  }
}

class MediaNotifier extends StateNotifier<AsyncValue<MediaState>> {
  final ImagePicker _imagePicker;
  final CacheService _cacheService;
  final PermissionNotifier _permissionNotifier;
  final FileNotifier _fileNotifier;

  Timer? _mediaCleanupTimer;

  static const Duration _cleanupInterval = Duration(hours: 6);
  static const int _maxRecentMedia = 100;

  MediaNotifier({
    required ImagePicker imagePicker,
    required CacheService cacheService,
    required PermissionNotifier permissionNotifier,
    required FileNotifier fileNotifier,
  }) : _imagePicker = imagePicker,
       _cacheService = cacheService,
       _permissionNotifier = permissionNotifier,
       _fileNotifier = fileNotifier,
       super(AsyncValue.data(MediaState())) {
    _initialize();
  }

  void _initialize() async {
    state = AsyncValue.data(state.value!.copyWith(isLoading: true));

    try {
      await _loadRecentMedia();
      await _initializeCamera();
      _startMediaCleanup();

      state = AsyncValue.data(
        state.value!.copyWith(isLoading: false, isInitialized: true),
      );

      if (kDebugMode) print('✅ Media provider initialized');
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      if (kDebugMode) print('❌ Error initializing media provider: $e');
    }
  }

  Future<void> _loadRecentMedia() async {
    try {
      final cachedMedia = await _cacheService.getCachedMedia();
      final mediaList = cachedMedia
          .map((data) => MediaFile.fromJson(data))
          .toList();

      // Sort by creation date, most recent first
      mediaList.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      state = AsyncValue.data(
        state.value!.copyWith(
          recentMedia: mediaList.take(_maxRecentMedia).toList(),
        ),
      );
    } catch (e) {
      if (kDebugMode) print('❌ Error loading recent media: $e');
    }
  }

  Future<void> _initializeCamera() async {
    try {
      // Check camera permission
      final cameraPermission = await _permissionNotifier.requestPermission(
        AppPermission.camera,
      );
      if (!cameraPermission) {
        if (kDebugMode) print('⚠️ Camera permission not granted');
        return;
      }

      // Get available cameras
      final cameras = await availableCameras();

      if (cameras.isNotEmpty) {
        final backCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first,
        );

        final controller = CameraController(
          backCamera,
          ResolutionPreset.high,
          enableAudio: true,
        );

        await controller.initialize();

        state = AsyncValue.data(
          state.value!.copyWith(
            cameraController: controller,
            availableCameras: cameras,
            isCameraInitialized: true,
          ),
        );

        if (kDebugMode) print('✅ Camera initialized');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error initializing camera: $e');
    }
  }

  void _startMediaCleanup() {
    _mediaCleanupTimer = Timer.periodic(_cleanupInterval, (_) {
      _cleanupOldMedia();
    });
  }

  Future<void> _cleanupOldMedia() async {
    try {
      final currentMedia = state.value!.recentMedia;
      if (currentMedia.length <= _maxRecentMedia) return;

      // Keep only the most recent media files
      final sortedMedia = List<MediaFile>.from(currentMedia);
      sortedMedia.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final recentMedia = sortedMedia.take(_maxRecentMedia).toList();

      // Delete old media files
      final oldMedia = sortedMedia.skip(_maxRecentMedia).toList();
      for (final media in oldMedia) {
        try {
          final file = File(media.path);
          if (await file.exists()) {
            await file.delete();
          }

          if (media.thumbnailPath != null) {
            final thumbnail = File(media.thumbnailPath!);
            if (await thumbnail.exists()) {
              await thumbnail.delete();
            }
          }
        } catch (e) {
          if (kDebugMode) print('❌ Error deleting old media: $e');
        }
      }

      state = AsyncValue.data(state.value!.copyWith(recentMedia: recentMedia));

      await _cacheRecentMedia();

      if (kDebugMode) print('🧹 Cleaned up ${oldMedia.length} old media files');
    } catch (e) {
      if (kDebugMode) print('❌ Error cleaning up old media: $e');
    }
  }

  // Public methods
  Future<MediaFile?> pickImageFromGallery({
    MediaQuality? quality,
    bool compress = true,
    int? maxWidth,
    int? maxHeight,
  }) async {
    try {
      final permission = await _permissionNotifier.requestPermission(
        AppPermission.photos,
      );
      if (!permission) {
        throw Exception('Photos permission not granted');
      }

      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxWidth?.toDouble() ?? state.value!.maxImageSize.toDouble(),
        maxHeight:
            maxHeight?.toDouble() ?? state.value!.maxImageSize.toDouble(),
        imageQuality: _getImageQuality(
          quality ?? state.value!.defaultImageQuality,
        ),
      );

      if (pickedFile != null) {
        return await _processPickedImage(
          pickedFile,
          MediaSource.gallery,
          compress,
        );
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error picking image from gallery: $e');
      state = AsyncValue.data(state.value!.copyWith(error: e.toString()));
    }
    return null;
  }

  Future<MediaFile?> pickVideoFromGallery({
    MediaQuality? quality,
    Duration? maxDuration,
  }) async {
    try {
      final permission = await _permissionNotifier.requestPermission(
        AppPermission.photos,
      );
      if (!permission) {
        throw Exception('Photos permission not granted');
      }

      final pickedFile = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: maxDuration ?? state.value!.maxVideoDuration,
      );

      if (pickedFile != null) {
        return await _processPickedVideo(pickedFile, MediaSource.gallery);
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error picking video from gallery: $e');
      state = AsyncValue.data(state.value!.copyWith(error: e.toString()));
    }
    return null;
  }

  Future<MediaFile?> takePhoto({
    MediaQuality? quality,
    bool compress = true,
    bool useFlash = false,
  }) async {
    try {
      final controller = state.value!.cameraController;
      if (controller == null || !controller.value.isInitialized) {
        await _initializeCamera();
      }

      if (useFlash != state.value!.flashEnabled) {
        await toggleFlash();
      }

      final image = await controller!.takePicture();
      return await _processPickedImage(image, MediaSource.camera, compress);
    } catch (e) {
      if (kDebugMode) print('❌ Error taking photo: $e');
      state = AsyncValue.data(state.value!.copyWith(error: e.toString()));
    }
    return null;
  }

  Future<MediaFile?> recordVideo({
    Duration? maxDuration,
    MediaQuality? quality,
  }) async {
    try {
      final controller = state.value!.cameraController;
      if (controller == null || !controller.value.isInitialized) {
        await _initializeCamera();
      }

      state = AsyncValue.data(state.value!.copyWith(isRecording: true));

      await controller!.startVideoRecording();

      // Set timer for max duration
      Timer? maxDurationTimer;
      if (maxDuration != null) {
        maxDurationTimer = Timer(maxDuration, () async {
          if (state.value!.isRecording) {
            await stopVideoRecording();
          }
        });
      }

      return null; // Video will be returned when stopVideoRecording is called
    } catch (e) {
      state = AsyncValue.data(
        state.value!.copyWith(isRecording: false, error: e.toString()),
      );
      if (kDebugMode) print('❌ Error starting video recording: $e');
    }
    return null;
  }

  Future<MediaFile?> stopVideoRecording() async {
    try {
      final controller = state.value!.cameraController;
      if (controller == null || !state.value!.isRecording) return null;

      final video = await controller.stopVideoRecording();
      state = AsyncValue.data(state.value!.copyWith(isRecording: false));

      return await _processPickedVideo(video, MediaSource.camera);
    } catch (e) {
      state = AsyncValue.data(
        state.value!.copyWith(isRecording: false, error: e.toString()),
      );
      if (kDebugMode) print('❌ Error stopping video recording: $e');
    }
    return null;
  }

  Future<void> switchCamera() async {
    try {
      final controller = state.value!.cameraController;
      if (controller == null) return;

      final cameras = state.value!.availableCameras;
      final currentDirection = state.value!.currentCameraDirection;

      CameraDescription? newCamera;
      CameraLensDirection newDirection;

      if (currentDirection == CameraLensDirection.back) {
        newCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => cameras.first,
        );
        newDirection = CameraLensDirection.front;
      } else {
        newCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first,
        );
        newDirection = CameraLensDirection.back;
      }

      await controller.dispose();

      final newController = CameraController(
        newCamera,
        ResolutionPreset.high,
        enableAudio: true,
      );

      await newController.initialize();

      state = AsyncValue.data(
        state.value!.copyWith(
          cameraController: newController,
          currentCameraDirection: newDirection,
        ),
      );

      if (kDebugMode) print('📷 Camera switched to ${newDirection.name}');
    } catch (e) {
      if (kDebugMode) print('❌ Error switching camera: $e');
      state = AsyncValue.data(state.value!.copyWith(error: e.toString()));
    }
  }

  Future<void> toggleFlash() async {
    try {
      final controller = state.value!.cameraController;
      if (controller == null) return;

      final newFlashState = !state.value!.flashEnabled;
      await controller.setFlashMode(
        newFlashState ? FlashMode.torch : FlashMode.off,
      );

      state = AsyncValue.data(
        state.value!.copyWith(flashEnabled: newFlashState),
      );

      if (kDebugMode)
        print('🔦 Flash ${newFlashState ? 'enabled' : 'disabled'}');
    } catch (e) {
      if (kDebugMode) print('❌ Error toggling flash: $e');
    }
  }

  Future<MediaFile> _processPickedImage(
    XFile pickedFile,
    MediaSource source,
    bool compress,
  ) async {
    final file = File(pickedFile.path);
    final size = await file.length();
    final bytes = await file.readAsBytes();

    // Get image dimensions
    final image = await decodeImageFromList(bytes);
    final width = image.width;
    final height = image.height;
    final aspectRatio = width / height;

    final mediaFile = MediaFile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      path: pickedFile.path,
      type: MediaType.image,
      source: source,
      size: size,
      width: width,
      height: height,
      aspectRatio: aspectRatio,
      isCompressed: compress,
    );

    await _addToRecentMedia(mediaFile);
    return mediaFile;
  }

  Future<MediaFile> _processPickedVideo(
    XFile pickedFile,
    MediaSource source,
  ) async {
    final file = File(pickedFile.path);
    final size = await file.length();

    final mediaFile = MediaFile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      path: pickedFile.path,
      type: MediaType.video,
      source: source,
      size: size,
    );

    await _addToRecentMedia(mediaFile);
    return mediaFile;
  }

  Future<void> _addToRecentMedia(MediaFile mediaFile) async {
    state.whenData((mediaState) {
      final updatedMedia = [mediaFile, ...mediaState.recentMedia];
      state = AsyncValue.data(
        mediaState.copyWith(
          recentMedia: updatedMedia.take(_maxRecentMedia).toList(),
        ),
      );
    });

    await _cacheRecentMedia();
  }

  Future<Uint8List?> generateThumbnail(MediaFile mediaFile) async {
    try {
      if (mediaFile.isImage) {
        final file = File(mediaFile.path);
        final bytes = await file.readAsBytes();

        // Generate thumbnail (you might want to use a library like image package)
        return bytes; // Placeholder - implement actual thumbnail generation
      } else if (mediaFile.isVideo) {
        // Generate video thumbnail (you might want to use video_thumbnail package)
        return null; // Placeholder - implement video thumbnail generation
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error generating thumbnail: $e');
    }
    return null;
  }

  Future<void> deleteMedia(String mediaId) async {
    try {
      final mediaFile = state.value!.getMediaById(mediaId);
      if (mediaFile == null) return;

      // Delete file
      final file = File(mediaFile.path);
      if (await file.exists()) {
        await file.delete();
      }

      // Delete thumbnail if exists
      if (mediaFile.thumbnailPath != null) {
        final thumbnail = File(mediaFile.thumbnailPath!);
        if (await thumbnail.exists()) {
          await thumbnail.delete();
        }
      }

      // Remove from state
      state.whenData((mediaState) {
        final updatedMedia = mediaState.recentMedia
            .where((m) => m.id != mediaId)
            .toList();
        state = AsyncValue.data(mediaState.copyWith(recentMedia: updatedMedia));
      });

      await _cacheRecentMedia();

      if (kDebugMode) print('✅ Media deleted: $mediaId');
    } catch (e) {
      if (kDebugMode) print('❌ Error deleting media: $e');
    }
  }

  int _getImageQuality(MediaQuality quality) {
    switch (quality) {
      case MediaQuality.low:
        return 30;
      case MediaQuality.medium:
        return 60;
      case MediaQuality.high:
        return 85;
      case MediaQuality.original:
        return 100;
    }
  }

  Future<void> _cacheRecentMedia() async {
    try {
      final mediaData = state.value!.recentMedia
          .map((m) => m.toJson())
          .toList();
      await _cacheService.cacheMedia(mediaData);
    } catch (e) {
      if (kDebugMode) print('❌ Error caching recent media: $e');
    }
  }

  // Getters
  List<MediaFile> get recentMedia => state.value?.recentMedia ?? [];
  bool get isLoading => state.value?.isLoading ?? false;
  bool get isCameraInitialized => state.value?.isCameraInitialized ?? false;
  bool get isRecording => state.value?.isRecording ?? false;
  bool get flashEnabled => state.value?.flashEnabled ?? false;
  CameraController? get cameraController => state.value?.cameraController;

  @override
  void dispose() {
    state.value?.cameraController?.dispose();
    _mediaCleanupTimer?.cancel();
    super.dispose();
  }
}

// Providers
final mediaProvider =
    StateNotifierProvider<MediaNotifier, AsyncValue<MediaState>>((ref) {
      return MediaNotifier(
        imagePicker: ImagePicker(),
        cacheService: CacheService(),
        permissionNotifier: ref.watch(permissionProvider.notifier),
        fileNotifier: ref.watch(fileProvider.notifier),
      );
    });

// Convenience providers
final recentMediaProvider = Provider<List<MediaFile>>((ref) {
  final mediaState = ref.watch(mediaProvider);
  return mediaState.whenOrNull(data: (state) => state.recentMedia) ?? [];
});

final mediaLoadingProvider = Provider<bool>((ref) {
  final mediaState = ref.watch(mediaProvider);
  return mediaState.whenOrNull(data: (state) => state.isLoading) ?? false;
});

final cameraInitializedProvider = Provider<bool>((ref) {
  final mediaState = ref.watch(mediaProvider);
  return mediaState.whenOrNull(data: (state) => state.isCameraInitialized) ??
      false;
});

final isRecordingProvider = Provider<bool>((ref) {
  final mediaState = ref.watch(mediaProvider);
  return mediaState.whenOrNull(data: (state) => state.isRecording) ?? false;
});

final flashEnabledProvider = Provider<bool>((ref) {
  final mediaState = ref.watch(mediaProvider);
  return mediaState.whenOrNull(data: (state) => state.flashEnabled) ?? false;
});

final cameraControllerProvider = Provider<CameraController?>((ref) {
  final mediaState = ref.watch(mediaProvider);
  return mediaState.whenOrNull(data: (state) => state.cameraController);
});

final imageFilesProvider = Provider<List<MediaFile>>((ref) {
  final mediaState = ref.watch(mediaProvider);
  return mediaState.whenOrNull(data: (state) => state.images) ?? [];
});

final videoFilesProvider = Provider<List<MediaFile>>((ref) {
  final mediaState = ref.watch(mediaProvider);
  return mediaState.whenOrNull(data: (state) => state.videos) ?? [];
});

final audioFilesProvider = Provider<List<MediaFile>>((ref) {
  final mediaState = ref.watch(mediaProvider);
  return mediaState.whenOrNull(data: (state) => state.audio) ?? [];
});

final mediaByIdProvider = Provider.family<MediaFile?, String>((ref, mediaId) {
  final mediaState = ref.watch(mediaProvider);
  return mediaState.whenOrNull(data: (state) => state.getMediaById(mediaId));
});
