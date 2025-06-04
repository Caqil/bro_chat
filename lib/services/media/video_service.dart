import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/exceptions/app_exception.dart';
import '../../core/config/app_config.dart';
import '../storage/cache_service.dart';
import '../storage/local_storage.dart';

enum VideoFormat { mp4, avi, mov, mkv, webm, flv, wmv, m4v }

enum VideoQuality {
  low, // 480p
  medium, // 720p
  high, // 1080p
  ultra, // 4K
  original,
}

enum VideoCodec { h264, h265, vp8, vp9, av1 }

enum AudioCodec { aac, mp3, opus, vorbis }

class VideoInfo {
  final String path;
  final String name;
  final Duration duration;
  final int width;
  final int height;
  final int fileSize;
  final VideoFormat format;
  final double frameRate;
  final int bitRate;
  final VideoCodec? videoCodec;
  final AudioCodec? audioCodec;
  final DateTime createdAt;
  final DateTime? modifiedAt;
  final String? thumbnailPath;
  final Map<String, dynamic>? metadata;

  VideoInfo({
    required this.path,
    required this.name,
    required this.duration,
    required this.width,
    required this.height,
    required this.fileSize,
    required this.format,
    required this.frameRate,
    required this.bitRate,
    this.videoCodec,
    this.audioCodec,
    required this.createdAt,
    this.modifiedAt,
    this.thumbnailPath,
    this.metadata,
  });

  double get aspectRatio => width / height;
  bool get isPortrait => height > width;
  bool get isLandscape => width > height;
  bool get isSquare => width == height;
  bool get hasThumbnail => thumbnailPath != null;
  String get resolution => '${width}x$height';

  VideoInfo copyWith({
    String? path,
    String? name,
    Duration? duration,
    int? width,
    int? height,
    int? fileSize,
    VideoFormat? format,
    double? frameRate,
    int? bitRate,
    VideoCodec? videoCodec,
    AudioCodec? audioCodec,
    DateTime? createdAt,
    DateTime? modifiedAt,
    String? thumbnailPath,
    Map<String, dynamic>? metadata,
  }) {
    return VideoInfo(
      path: path ?? this.path,
      name: name ?? this.name,
      duration: duration ?? this.duration,
      width: width ?? this.width,
      height: height ?? this.height,
      fileSize: fileSize ?? this.fileSize,
      format: format ?? this.format,
      frameRate: frameRate ?? this.frameRate,
      bitRate: bitRate ?? this.bitRate,
      videoCodec: videoCodec ?? this.videoCodec,
      audioCodec: audioCodec ?? this.audioCodec,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'name': name,
      'duration_ms': duration.inMilliseconds,
      'width': width,
      'height': height,
      'file_size': fileSize,
      'format': format.name,
      'frame_rate': frameRate,
      'bit_rate': bitRate,
      'video_codec': videoCodec?.name,
      'audio_codec': audioCodec?.name,
      'created_at': createdAt.toIso8601String(),
      'modified_at': modifiedAt?.toIso8601String(),
      'thumbnail_path': thumbnailPath,
      'metadata': metadata,
    };
  }

  factory VideoInfo.fromJson(Map<String, dynamic> json) {
    return VideoInfo(
      path: json['path'],
      name: json['name'],
      duration: Duration(milliseconds: json['duration_ms']),
      width: json['width'],
      height: json['height'],
      fileSize: json['file_size'],
      format: VideoFormat.values.firstWhere(
        (f) => f.name == json['format'],
        orElse: () => VideoFormat.mp4,
      ),
      frameRate: json['frame_rate']?.toDouble() ?? 0.0,
      bitRate: json['bit_rate'] ?? 0,
      videoCodec: json['video_codec'] != null
          ? VideoCodec.values.firstWhere(
              (c) => c.name == json['video_codec'],
              orElse: () => VideoCodec.h264,
            )
          : null,
      audioCodec: json['audio_codec'] != null
          ? AudioCodec.values.firstWhere(
              (c) => c.name == json['audio_codec'],
              orElse: () => AudioCodec.aac,
            )
          : null,
      createdAt: DateTime.parse(json['created_at']),
      modifiedAt: json['modified_at'] != null
          ? DateTime.parse(json['modified_at'])
          : null,
      thumbnailPath: json['thumbnail_path'],
      metadata: json['metadata'],
    );
  }

  @override
  String toString() {
    return 'VideoInfo(name: $name, duration: ${duration.inSeconds}s, resolution: $resolution)';
  }
}

class VideoProcessingOptions {
  final VideoQuality quality;
  final VideoFormat format;
  final VideoCodec videoCodec;
  final AudioCodec audioCodec;
  final int? maxWidth;
  final int? maxHeight;
  final int? bitRate;
  final double? frameRate;
  final Duration? startTime;
  final Duration? endTime;
  final bool removeAudio;
  final bool maintainAspectRatio;

  const VideoProcessingOptions({
    this.quality = VideoQuality.medium,
    this.format = VideoFormat.mp4,
    this.videoCodec = VideoCodec.h264,
    this.audioCodec = AudioCodec.aac,
    this.maxWidth,
    this.maxHeight,
    this.bitRate,
    this.frameRate,
    this.startTime,
    this.endTime,
    this.removeAudio = false,
    this.maintainAspectRatio = true,
  });

  VideoProcessingOptions copyWith({
    VideoQuality? quality,
    VideoFormat? format,
    VideoCodec? videoCodec,
    AudioCodec? audioCodec,
    int? maxWidth,
    int? maxHeight,
    int? bitRate,
    double? frameRate,
    Duration? startTime,
    Duration? endTime,
    bool? removeAudio,
    bool? maintainAspectRatio,
  }) {
    return VideoProcessingOptions(
      quality: quality ?? this.quality,
      format: format ?? this.format,
      videoCodec: videoCodec ?? this.videoCodec,
      audioCodec: audioCodec ?? this.audioCodec,
      maxWidth: maxWidth ?? this.maxWidth,
      maxHeight: maxHeight ?? this.maxHeight,
      bitRate: bitRate ?? this.bitRate,
      frameRate: frameRate ?? this.frameRate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      removeAudio: removeAudio ?? this.removeAudio,
      maintainAspectRatio: maintainAspectRatio ?? this.maintainAspectRatio,
    );
  }
}

class VideoPlayerInfo {
  final String id;
  final String videoPath;
  final VideoPlayerController controller;
  final Duration duration;
  final Duration position;
  final bool isPlaying;
  final bool isBuffering;
  final bool isCompleted;
  final double volume;
  final double playbackSpeed;

  VideoPlayerInfo({
    required this.id,
    required this.videoPath,
    required this.controller,
    required this.duration,
    required this.position,
    required this.isPlaying,
    required this.isBuffering,
    required this.isCompleted,
    required this.volume,
    required this.playbackSpeed,
  });

  VideoPlayerInfo copyWith({
    String? id,
    String? videoPath,
    VideoPlayerController? controller,
    Duration? duration,
    Duration? position,
    bool? isPlaying,
    bool? isBuffering,
    bool? isCompleted,
    double? volume,
    double? playbackSpeed,
  }) {
    return VideoPlayerInfo(
      id: id ?? this.id,
      videoPath: videoPath ?? this.videoPath,
      controller: controller ?? this.controller,
      duration: duration ?? this.duration,
      position: position ?? this.position,
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      isCompleted: isCompleted ?? this.isCompleted,
      volume: volume ?? this.volume,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
    );
  }
}

class VideoService {
  static VideoService? _instance;

  final CacheService _cacheService;
  final LocalStorage _localStorage;

  // Video info cache
  final Map<String, VideoInfo> _videoInfoCache = {};
  final Map<String, String> _thumbnailCache = {};

  // Video players
  final Map<String, VideoPlayerInfo> _videoPlayers = {};

  // Event streams
  final StreamController<VideoInfo> _videoProcessedController =
      StreamController<VideoInfo>.broadcast();
  final StreamController<VideoPlayerInfo> _playerUpdatedController =
      StreamController<VideoPlayerInfo>.broadcast();

  // Processing queue
  final List<Future<void>> _processingQueue = [];
  int _maxConcurrentProcessing = 2;

  VideoService._internal()
    : _cacheService = CacheService(),
      _localStorage = LocalStorage() {
    _initialize();
  }

  factory VideoService() {
    _instance ??= VideoService._internal();
    return _instance!;
  }

  // Streams
  Stream<VideoInfo> get videoProcessedStream =>
      _videoProcessedController.stream;
  Stream<VideoPlayerInfo> get playerUpdatedStream =>
      _playerUpdatedController.stream;

  void _initialize() {
    _loadVideoCache();
  }

  Future<void> _loadVideoCache() async {
    try {
      final cacheData = await _cacheService.getCachedData('video_info_cache');
      if (cacheData != null && cacheData is Map) {
        _videoInfoCache.clear();
        for (final entry in cacheData.entries) {
          _videoInfoCache[entry.key] = VideoInfo.fromJson(entry.value);
        }
      }

      if (kDebugMode) {
        print('✅ Video cache loaded: ${_videoInfoCache.length} items');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading video cache: $e');
      }
    }
  }

  Future<void> _saveVideoCache() async {
    try {
      final cacheData = <String, dynamic>{};
      for (final entry in _videoInfoCache.entries) {
        cacheData[entry.key] = entry.value.toJson();
      }
      await _cacheService.cache('video_info_cache', cacheData);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving video cache: $e');
      }
    }
  }

  // Public API

  Future<VideoInfo?> getVideoInfo(String videoPath) async {
    try {
      // Check cache first
      if (_videoInfoCache.containsKey(videoPath)) {
        return _videoInfoCache[videoPath];
      }

      final file = File(videoPath);
      if (!await file.exists()) {
        return null;
      }

      // Create video player controller to get basic info
      final controller = VideoPlayerController.file(file);
      await controller.initialize();

      final stat = await file.stat();
      final fileName = videoPath.split('/').last;
      final format = _getVideoFormatFromExtension(fileName);

      final videoInfo = VideoInfo(
        path: videoPath,
        name: fileName,
        duration: controller.value.duration,
        width: controller.value.size.width.toInt(),
        height: controller.value.size.height.toInt(),
        fileSize: stat.size,
        format: format,
        frameRate: 30.0, // Default, would need FFprobe for accurate info
        bitRate: 0, // Would need FFprobe for accurate info
        createdAt: stat.modified,
        modifiedAt: stat.modified,
      );

      await controller.dispose();

      // Enhanced info using FFprobe if available
      final enhancedInfo = await _getEnhancedVideoInfo(videoInfo);

      // Cache the info
      _videoInfoCache[videoPath] = enhancedInfo;
      _saveVideoCache();

      return enhancedInfo;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting video info: $e');
      }
      return null;
    }
  }

  Future<VideoInfo> _getEnhancedVideoInfo(VideoInfo basicInfo) async {
    try {
      // Use FFprobe to get detailed video information
      final session = await FFmpegKit.execute(
        '-i "${basicInfo.path}" -v quiet -print_format json -show_format -show_streams',
      );

      final returnCode = await session.getReturnCode();
      if (ReturnCode.isSuccess(returnCode)) {
        final output = await session.getOutput();
        if (output != null) {
          // Parse FFprobe output for enhanced info
          // This is a simplified version - actual implementation would parse JSON
          return basicInfo.copyWith(
            frameRate: 30.0, // Parse from output
            bitRate: 1000000, // Parse from output
            videoCodec: VideoCodec.h264, // Parse from output
            audioCodec: AudioCodec.aac, // Parse from output
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting enhanced video info: $e');
      }
    }

    return basicInfo;
  }

  Future<String?> generateThumbnail(
    String videoPath, {
    Duration? timeMs,
    int maxSize = 200,
    int quality = 75,
  }) async {
    try {
      // Check cache first
      final cacheKey =
          '${videoPath}_${timeMs?.inMilliseconds ?? 0}_${maxSize}_$quality';
      if (_thumbnailCache.containsKey(cacheKey)) {
        return _thumbnailCache[cacheKey];
      }

      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: await _generateThumbnailPath(videoPath),
        imageFormat: ImageFormat.JPEG,
        maxHeight: maxSize,
        maxWidth: maxSize,
        timeMs: timeMs?.inMilliseconds ?? 0,
        quality: quality,
      );

      if (thumbnailPath != null) {
        _thumbnailCache[cacheKey] = thumbnailPath;

        // Limit cache size
        if (_thumbnailCache.length > 50) {
          final oldestKey = _thumbnailCache.keys.first;
          final oldThumbnail = _thumbnailCache.remove(oldestKey);
          if (oldThumbnail != null) {
            try {
              await File(oldThumbnail).delete();
            } catch (e) {
              // Ignore deletion errors
            }
          }
        }

        if (kDebugMode) {
          print('✅ Video thumbnail generated: $thumbnailPath');
        }
      }

      return thumbnailPath;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error generating video thumbnail: $e');
      }
      throw MediaException.thumbnailGenerationFailed();
    }
  }

  Future<String> _generateThumbnailPath(String videoPath) async {
    final directory = await getApplicationDocumentsDirectory();
    final thumbnailsDir = Directory('${directory.path}/video_thumbnails');

    if (!await thumbnailsDir.exists()) {
      await thumbnailsDir.create(recursive: true);
    }

    final fileName = videoPath.split('/').last.split('.').first;
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    return '${thumbnailsDir.path}/${fileName}_$timestamp.jpg';
  }

  Future<String?> compressVideo(
    String inputPath,
    VideoQuality quality, {
    VideoProcessingOptions? options,
    Function(double)? onProgress,
  }) async {
    try {
      // Add to processing queue if at capacity
      if (_processingQueue.length >= _maxConcurrentProcessing) {
        await Future.wait(_processingQueue.take(1));
      }

      final processingFuture = _compressVideoInternal(
        inputPath,
        quality,
        options,
        onProgress,
      );
      _processingQueue.add(processingFuture);

      final result = await processingFuture;
      _processingQueue.remove(processingFuture);

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error compressing video: $e');
      }
      throw MediaException.compressionFailed();
    }
  }

  Future<String?> _compressVideoInternal(
    String inputPath,
    VideoQuality quality,
    VideoProcessingOptions? options,
    Function(double)? onProgress,
  ) async {
    try {
      final file = File(inputPath);
      if (!await file.exists()) {
        throw FileException.notFound(inputPath);
      }

      final outputPath = await _generateOutputPath(
        inputPath,
        options?.format ?? VideoFormat.mp4,
      );
      final processingOptions =
          options ?? VideoProcessingOptions(quality: quality);

      final ffmpegCommand = _buildFFmpegCommand(
        inputPath,
        outputPath,
        processingOptions,
      );

      if (kDebugMode) {
        print('🎬 Starting video compression: $ffmpegCommand');
      }

      final session = await FFmpegKit.execute(ffmpegCommand);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        // Update cache
        _videoInfoCache.remove(inputPath);

        // Get new video info
        final videoInfo = await getVideoInfo(outputPath);
        if (videoInfo != null) {
          _videoProcessedController.add(videoInfo);
        }

        if (kDebugMode) {
          print('✅ Video compressed: $inputPath -> $outputPath');
        }

        return outputPath;
      } else {
        final output = await session.getOutput();
        if (kDebugMode) {
          print('❌ FFmpeg failed: $output');
        }
        throw MediaException.compressionFailed();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error in video compression internal: $e');
      }
      rethrow;
    }
  }

  String _buildFFmpegCommand(
    String inputPath,
    String outputPath,
    VideoProcessingOptions options,
  ) {
    final commands = <String>[
      '-i "$inputPath"',
      '-c:v ${_getVideoCodecString(options.videoCodec)}',
    ];

    // Audio codec
    if (options.removeAudio) {
      commands.add('-an');
    } else {
      commands.add('-c:a ${_getAudioCodecString(options.audioCodec)}');
    }

    // Video quality settings
    final qualitySettings = _getQualitySettings(options.quality);
    commands.addAll(qualitySettings);

    // Resize if specified
    if (options.maxWidth != null || options.maxHeight != null) {
      final resizeFilter = _buildResizeFilter(options);
      if (resizeFilter.isNotEmpty) {
        commands.add('-vf "$resizeFilter"');
      }
    }

    // Trim video if specified
    if (options.startTime != null) {
      commands.add('-ss ${options.startTime!.inSeconds}');
    }
    if (options.endTime != null && options.startTime != null) {
      final duration =
          options.endTime!.inSeconds - options.startTime!.inSeconds;
      commands.add('-t $duration');
    }

    // Frame rate
    if (options.frameRate != null) {
      commands.add('-r ${options.frameRate}');
    }

    // Bit rate
    if (options.bitRate != null) {
      commands.add('-b:v ${options.bitRate}');
    }

    // Output settings
    commands.addAll([
      '-movflags +faststart', // For MP4 web optimization
      '-y', // Overwrite output file
      '"$outputPath"',
    ]);

    return commands.join(' ');
  }

  String _getVideoCodecString(VideoCodec codec) {
    switch (codec) {
      case VideoCodec.h264:
        return 'libx264';
      case VideoCodec.h265:
        return 'libx265';
      case VideoCodec.vp8:
        return 'libvpx';
      case VideoCodec.vp9:
        return 'libvpx-vp9';
      case VideoCodec.av1:
        return 'libaom-av1';
    }
  }

  String _getAudioCodecString(AudioCodec codec) {
    switch (codec) {
      case AudioCodec.aac:
        return 'aac';
      case AudioCodec.mp3:
        return 'libmp3lame';
      case AudioCodec.opus:
        return 'libopus';
      case AudioCodec.vorbis:
        return 'libvorbis';
    }
  }

  List<String> _getQualitySettings(VideoQuality quality) {
    switch (quality) {
      case VideoQuality.low:
        return ['-crf 28', '-preset fast'];
      case VideoQuality.medium:
        return ['-crf 23', '-preset medium'];
      case VideoQuality.high:
        return ['-crf 18', '-preset slow'];
      case VideoQuality.ultra:
        return ['-crf 15', '-preset slower'];
      case VideoQuality.original:
        return ['-crf 0', '-preset ultrafast'];
    }
  }

  String _buildResizeFilter(VideoProcessingOptions options) {
    if (options.maxWidth == null && options.maxHeight == null) {
      return '';
    }

    if (options.maintainAspectRatio) {
      if (options.maxWidth != null && options.maxHeight != null) {
        return 'scale=${options.maxWidth}:${options.maxHeight}:force_original_aspect_ratio=decrease';
      } else if (options.maxWidth != null) {
        return 'scale=${options.maxWidth}:-1';
      } else {
        return 'scale=-1:${options.maxHeight}';
      }
    } else {
      return 'scale=${options.maxWidth ?? -1}:${options.maxHeight ?? -1}';
    }
  }

  Future<String> _generateOutputPath(
    String inputPath,
    VideoFormat format,
  ) async {
    final directory = await getApplicationDocumentsDirectory();
    final processedDir = Directory('${directory.path}/processed_videos');

    if (!await processedDir.exists()) {
      await processedDir.create(recursive: true);
    }

    final fileName = inputPath.split('/').last.split('.').first;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = _getFileExtension(format);

    return '${processedDir.path}/${fileName}_$timestamp.$extension';
  }

  Future<String?> convertVideo(
    String inputPath, {
    required VideoFormat format,
    VideoCodec? videoCodec,
    AudioCodec? audioCodec,
    Function(double)? onProgress,
  }) async {
    final options = VideoProcessingOptions(
      format: format,
      videoCodec: videoCodec ?? VideoCodec.h264,
      audioCodec: audioCodec ?? AudioCodec.aac,
      quality: VideoQuality.medium,
    );

    return await compressVideo(
      inputPath,
      VideoQuality.medium,
      options: options,
      onProgress: onProgress,
    );
  }

  Future<String?> trimVideo(
    String inputPath, {
    required Duration startTime,
    required Duration endTime,
    VideoFormat? format,
  }) async {
    final options = VideoProcessingOptions(
      startTime: startTime,
      endTime: endTime,
      format: format ?? VideoFormat.mp4,
      quality: VideoQuality.medium,
    );

    return await compressVideo(
      inputPath,
      VideoQuality.medium,
      options: options,
    );
  }

  Future<String?> extractAudio(
    String inputPath, {
    AudioCodec codec = AudioCodec.aac,
    int? bitRate,
  }) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final audioDir = Directory('${directory.path}/extracted_audio');

      if (!await audioDir.exists()) {
        await audioDir.create(recursive: true);
      }

      final fileName = inputPath.split('/').last.split('.').first;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = _getAudioExtension(codec);
      final outputPath = '${audioDir.path}/${fileName}_$timestamp.$extension';

      final commands = <String>[
        '-i "$inputPath"',
        '-vn', // No video
        '-c:a ${_getAudioCodecString(codec)}',
        if (bitRate != null) '-b:a ${bitRate}k',
        '-y',
        '"$outputPath"',
      ];

      final ffmpegCommand = commands.join(' ');
      final session = await FFmpegKit.execute(ffmpegCommand);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        if (kDebugMode) {
          print('✅ Audio extracted: $inputPath -> $outputPath');
        }
        return outputPath;
      } else {
        throw MediaException.compressionFailed();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error extracting audio: $e');
      }
      return null;
    }
  }

  // Video Player Management

  Future<String> createVideoPlayer(String videoPath) async {
    try {
      final playerId = DateTime.now().millisecondsSinceEpoch.toString();
      final controller = VideoPlayerController.file(File(videoPath));

      await controller.initialize();

      final playerInfo = VideoPlayerInfo(
        id: playerId,
        videoPath: videoPath,
        controller: controller,
        duration: controller.value.duration,
        position: Duration.zero,
        isPlaying: false,
        isBuffering: false,
        isCompleted: false,
        volume: 1.0,
        playbackSpeed: 1.0,
      );

      _videoPlayers[playerId] = playerInfo;
      _setupPlayerListeners(playerId);

      if (kDebugMode) {
        print('🎬 Video player created: $playerId');
      }

      return playerId;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error creating video player: $e');
      }
      throw MediaException.playbackFailed();
    }
  }

  void _setupPlayerListeners(String playerId) {
    final playerInfo = _videoPlayers[playerId];
    if (playerInfo == null) return;

    playerInfo.controller.addListener(() {
      final updatedInfo = playerInfo.copyWith(
        position: playerInfo.controller.value.position,
        isPlaying: playerInfo.controller.value.isPlaying,
        isBuffering: playerInfo.controller.value.isBuffering,
        isCompleted:
            playerInfo.controller.value.position >=
            playerInfo.controller.value.duration,
      );

      _videoPlayers[playerId] = updatedInfo;
      _playerUpdatedController.add(updatedInfo);
    });
  }

  Future<void> playVideo(String playerId) async {
    final playerInfo = _videoPlayers[playerId];
    if (playerInfo != null) {
      await playerInfo.controller.play();
    }
  }

  Future<void> pauseVideo(String playerId) async {
    final playerInfo = _videoPlayers[playerId];
    if (playerInfo != null) {
      await playerInfo.controller.pause();
    }
  }

  Future<void> seekVideo(String playerId, Duration position) async {
    final playerInfo = _videoPlayers[playerId];
    if (playerInfo != null) {
      await playerInfo.controller.seekTo(position);
    }
  }

  Future<void> setVolume(String playerId, double volume) async {
    final playerInfo = _videoPlayers[playerId];
    if (playerInfo != null) {
      await playerInfo.controller.setVolume(volume.clamp(0.0, 1.0));

      final updatedInfo = playerInfo.copyWith(volume: volume);
      _videoPlayers[playerId] = updatedInfo;
      _playerUpdatedController.add(updatedInfo);
    }
  }

  Future<void> setPlaybackSpeed(String playerId, double speed) async {
    final playerInfo = _videoPlayers[playerId];
    if (playerInfo != null) {
      await playerInfo.controller.setPlaybackSpeed(speed);

      final updatedInfo = playerInfo.copyWith(playbackSpeed: speed);
      _videoPlayers[playerId] = updatedInfo;
      _playerUpdatedController.add(updatedInfo);
    }
  }

  VideoPlayerController? getPlayerController(String playerId) {
    return _videoPlayers[playerId]?.controller;
  }

  VideoPlayerInfo? getPlayerInfo(String playerId) {
    return _videoPlayers[playerId];
  }

  Future<void> disposePlayer(String playerId) async {
    final playerInfo = _videoPlayers.remove(playerId);
    if (playerInfo != null) {
      await playerInfo.controller.dispose();

      if (kDebugMode) {
        print('🎬 Video player disposed: $playerId');
      }
    }
  }

  // Utility methods

  VideoFormat _getVideoFormatFromExtension(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'mp4':
      case 'm4v':
        return VideoFormat.mp4;
      case 'avi':
        return VideoFormat.avi;
      case 'mov':
        return VideoFormat.mov;
      case 'mkv':
        return VideoFormat.mkv;
      case 'webm':
        return VideoFormat.webm;
      case 'flv':
        return VideoFormat.flv;
      case 'wmv':
        return VideoFormat.wmv;
      default:
        return VideoFormat.mp4;
    }
  }

  String _getFileExtension(VideoFormat format) {
    switch (format) {
      case VideoFormat.mp4:
        return 'mp4';
      case VideoFormat.avi:
        return 'avi';
      case VideoFormat.mov:
        return 'mov';
      case VideoFormat.mkv:
        return 'mkv';
      case VideoFormat.webm:
        return 'webm';
      case VideoFormat.flv:
        return 'flv';
      case VideoFormat.wmv:
        return 'wmv';
      case VideoFormat.m4v:
        return 'm4v';
    }
  }

  String _getAudioExtension(AudioCodec codec) {
    switch (codec) {
      case AudioCodec.aac:
        return 'aac';
      case AudioCodec.mp3:
        return 'mp3';
      case AudioCodec.opus:
        return 'opus';
      case AudioCodec.vorbis:
        return 'ogg';
    }
  }

  bool isVideoFile(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    return [
      'mp4',
      'avi',
      'mov',
      'mkv',
      'webm',
      'flv',
      'wmv',
      'm4v',
    ].contains(extension);
  }

  Future<void> clearVideoCache() async {
    _videoInfoCache.clear();
    await _saveVideoCache();

    if (kDebugMode) {
      print('🗑️ Video cache cleared');
    }
  }

  Future<void> clearThumbnailCache() async {
    // Delete thumbnail files
    for (final thumbnailPath in _thumbnailCache.values) {
      try {
        await File(thumbnailPath).delete();
      } catch (e) {
        // Ignore deletion errors
      }
    }

    _thumbnailCache.clear();

    if (kDebugMode) {
      print('🗑️ Video thumbnail cache cleared');
    }
  }

  // Settings

  void setMaxConcurrentProcessing(int maxConcurrent) {
    _maxConcurrentProcessing = maxConcurrent.clamp(1, 5);
  }

  // Cleanup

  Future<void> dispose() async {
    // Wait for all processing to complete
    if (_processingQueue.isNotEmpty) {
      await Future.wait(_processingQueue);
    }

    // Dispose all video players
    for (final playerId in _videoPlayers.keys.toList()) {
      await disposePlayer(playerId);
    }

    await _videoProcessedController.close();
    await _playerUpdatedController.close();

    _videoInfoCache.clear();
    _thumbnailCache.clear();

    if (kDebugMode) {
      print('✅ Video service disposed');
    }
  }
}

// Riverpod providers
final videoServiceProvider = Provider<VideoService>((ref) {
  return VideoService();
});

final videoProcessedProvider = StreamProvider<VideoInfo>((ref) {
  final service = ref.watch(videoServiceProvider);
  return service.videoProcessedStream;
});

final videoPlayerUpdatedProvider = StreamProvider<VideoPlayerInfo>((ref) {
  final service = ref.watch(videoServiceProvider);
  return service.playerUpdatedStream;
});

final videoPlayerProvider = Provider.family<VideoPlayerInfo?, String>((
  ref,
  playerId,
) {
  final service = ref.watch(videoServiceProvider);
  return service.getPlayerInfo(playerId);
});
