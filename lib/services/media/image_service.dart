import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/exceptions/app_exception.dart';
import '../../core/config/app_config.dart';
import '../storage/cache_service.dart';
import '../storage/local_storage.dart';
import 'file_picker_service.dart';

enum ImageFormat { jpeg, png, gif, bmp, webp }

enum ImageQuality { low, medium, high, original }

enum ImageFilterType {
  none,
  grayscale,
  sepia,
  vintage,
  blur,
  sharpen,
  brighten,
  darken,
  contrast,
  saturation,
}

class ImageDataInfo {
  final String path;
  final String name;
  final int width;
  final int height;
  final int fileSize;
  final ImageFormat format;
  final DateTime createdAt;
  final DateTime? modifiedAt;
  final Map<String, dynamic>? metadata;

  ImageDataInfo({
    required this.path,
    required this.name,
    required this.width,
    required this.height,
    required this.fileSize,
    required this.format,
    required this.createdAt,
    this.modifiedAt,
    this.metadata,
  });

  double get aspectRatio => width / height;
  bool get isPortrait => height > width;
  bool get isLandscape => width > height;
  bool get isSquare => width == height;

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'name': name,
      'width': width,
      'height': height,
      'file_size': fileSize,
      'format': format.name,
      'created_at': createdAt.toIso8601String(),
      'modified_at': modifiedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory ImageDataInfo.fromJson(Map<String, dynamic> json) {
    return ImageDataInfo(
      path: json['path'],
      name: json['name'],
      width: json['width'],
      height: json['height'],
      fileSize: json['file_size'],
      format: ImageFormat.values.firstWhere(
        (f) => f.name == json['format'],
        orElse: () => ImageFormat.jpeg,
      ),
      createdAt: DateTime.parse(json['created_at']),
      modifiedAt: json['modified_at'] != null
          ? DateTime.parse(json['modified_at'])
          : null,
      metadata: json['metadata'],
    );
  }

  @override
  String toString() {
    return 'ImageInfo(name: $name, size: ${width}x$height, format: ${format.name})';
  }
}

class ImageProcessingOptions {
  final int? maxWidth;
  final int? maxHeight;
  final int? quality;
  final ImageFormat? format;
  final bool maintainAspectRatio;
  final bool stripMetadata;
  final ImageFilterType filter;
  final double? filterIntensity;

  const ImageProcessingOptions({
    this.maxWidth,
    this.maxHeight,
    this.quality,
    this.format,
    this.maintainAspectRatio = true,
    this.stripMetadata = false,
    this.filter = ImageFilterType.none,
    this.filterIntensity,
  });

  ImageProcessingOptions copyWith({
    int? maxWidth,
    int? maxHeight,
    int? quality,
    ImageFormat? format,
    bool? maintainAspectRatio,
    bool? stripMetadata,
    ImageFilterType? filter,
    double? filterIntensity,
  }) {
    return ImageProcessingOptions(
      maxWidth: maxWidth ?? this.maxWidth,
      maxHeight: maxHeight ?? this.maxHeight,
      quality: quality ?? this.quality,
      format: format ?? this.format,
      maintainAspectRatio: maintainAspectRatio ?? this.maintainAspectRatio,
      stripMetadata: stripMetadata ?? this.stripMetadata,
      filter: filter ?? this.filter,
      filterIntensity: filterIntensity ?? this.filterIntensity,
    );
  }
}

class ImageService {
  static ImageService? _instance;

  final CacheService _cacheService;
  final LocalStorage _localStorage;
  final FilePickerService _filePickerService;

  // Image cache
  final Map<String, ImageDataInfo> _imageInfoCache = {};
  final Map<String, Uint8List> _imageBytesCache = {};
  final Map<String, String> _thumbnailCache = {};

  // Event streams
  final StreamController<ImageDataInfo> _imageProcessedController =
      StreamController<ImageDataInfo>.broadcast();

  // Processing queue
  final List<Future<void>> _processingQueue = [];
  int _maxConcurrentProcessing = 3;

  ImageService._internal()
    : _cacheService = CacheService(),
      _localStorage = LocalStorage(),
      _filePickerService = FilePickerService() {
    _initialize();
  }

  factory ImageService() {
    _instance ??= ImageService._internal();
    return _instance!;
  }

  // Streams
  Stream<ImageDataInfo> get imageProcessedStream =>
      _imageProcessedController.stream;

  void _initialize() {
    _loadImageCache();
  }

  Future<void> _loadImageCache() async {
    try {
      final cacheData = await _cacheService.getCachedData('image_info_cache');
      if (cacheData != null && cacheData is Map) {
        _imageInfoCache.clear();
        for (final entry in cacheData.entries) {
          _imageInfoCache[entry.key] = ImageDataInfo.fromJson(entry.value);
        }
      }

      if (kDebugMode) {
        print('✅ Image cache loaded: ${_imageInfoCache.length} items');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading image cache: $e');
      }
    }
  }

  Future<void> _saveImageCache() async {
    try {
      final cacheData = <String, dynamic>{};
      for (final entry in _imageInfoCache.entries) {
        cacheData[entry.key] = entry.value.toJson();
      }
      await _cacheService.cache('image_info_cache', cacheData);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving image cache: $e');
      }
    }
  }

  // Public API

  Future<ImageDataInfo?> getImageInfo(String imagePath) async {
    try {
      // Check cache first
      if (_imageInfoCache.containsKey(imagePath)) {
        return _imageInfoCache[imagePath];
      }

      final file = File(imagePath);
      if (!await file.exists()) {
        return null;
      }

      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        throw MediaException.thumbnailGenerationFailed();
      }

      final stat = await file.stat();
      final fileName = imagePath.split('/').last;
      final format = _getImageFormatFromExtension(fileName);

      final imageInfo = ImageDataInfo(
        path: imagePath,
        name: fileName,
        width: image.width,
        height: image.height,
        fileSize: stat.size,
        format: format,
        createdAt: stat.modified,
        modifiedAt: stat.modified,
      );

      // Cache the info
      _imageInfoCache[imagePath] = imageInfo;
      _saveImageCache();

      return imageInfo;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting image info: $e');
      }
      return null;
    }
  }

  Future<Uint8List?> getImageBytes(String imagePath) async {
    try {
      // Check cache first
      if (_imageBytesCache.containsKey(imagePath)) {
        return _imageBytesCache[imagePath];
      }

      final file = File(imagePath);
      if (!await file.exists()) {
        return null;
      }

      final bytes = await file.readAsBytes();

      // Cache if reasonable size (< 5MB)
      if (bytes.length < 5 * 1024 * 1024) {
        _imageBytesCache[imagePath] = bytes;

        // Limit cache size
        if (_imageBytesCache.length > 20) {
          final oldestKey = _imageBytesCache.keys.first;
          _imageBytesCache.remove(oldestKey);
        }
      }

      return bytes;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting image bytes: $e');
      }
      return null;
    }
  }

  Future<String?> processImage(
    String inputPath,
    ImageProcessingOptions options, {
    String? outputPath,
  }) async {
    try {
      // Add to processing queue if at capacity
      if (_processingQueue.length >= _maxConcurrentProcessing) {
        await Future.wait(_processingQueue.take(1));
      }

      final processingFuture = _processImageInternal(
        inputPath,
        options,
        outputPath,
      );
      _processingQueue.add(processingFuture);

      final result = await processingFuture;
      _processingQueue.remove(processingFuture);

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error processing image: $e');
      }
      throw MediaException.compressionFailed();
    }
  }

  Future<String?> _processImageInternal(
    String inputPath,
    ImageProcessingOptions options,
    String? outputPath,
  ) async {
    try {
      final inputFile = File(inputPath);
      if (!await inputFile.exists()) {
        throw FileException.notFound(inputPath);
      }

      final inputBytes = await inputFile.readAsBytes();
      img.Image? image = img.decodeImage(inputBytes);

      if (image == null) {
        throw MediaException.compressionFailed();
      }

      // Apply transformations
      image = await _applyImageTransformations(image, options);

      // Generate output path if not provided
      final finalOutputPath =
          outputPath ??
          await _generateOutputPath(
            inputPath,
            options.format ?? _getImageFormatFromExtension(inputPath),
          );

      // Encode and save
      final outputBytes = await _encodeImage(image, options);
      final outputFile = File(finalOutputPath);
      await outputFile.writeAsBytes(outputBytes);

      // Update cache
      _imageBytesCache.remove(inputPath);
      _imageInfoCache.remove(inputPath);

      // Get new image info
      final imageInfo = await getImageInfo(finalOutputPath);
      if (imageInfo != null) {
        _imageProcessedController.add(imageInfo);
      }

      if (kDebugMode) {
        print('✅ Image processed: $inputPath -> $finalOutputPath');
      }

      return finalOutputPath;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error in image processing internal: $e');
      }
      rethrow;
    }
  }

  Future<img.Image> _applyImageTransformations(
    img.Image image,
    ImageProcessingOptions options,
  ) async {
    img.Image processedImage = image;

    // Resize if needed
    if (options.maxWidth != null || options.maxHeight != null) {
      processedImage = await _resizeImage(processedImage, options);
    }

    // Apply filter
    if (options.filter != ImageFilterType.none) {
      processedImage = await _applyImageFilter(processedImage, options);
    }

    return processedImage;
  }

  Future<img.Image> _resizeImage(
    img.Image image,
    ImageProcessingOptions options,
  ) async {
    int newWidth = image.width;
    int newHeight = image.height;

    if (options.maxWidth != null && options.maxHeight != null) {
      if (options.maintainAspectRatio) {
        final aspectRatio = image.width / image.height;
        final targetAspectRatio = options.maxWidth! / options.maxHeight!;

        if (aspectRatio > targetAspectRatio) {
          newWidth = options.maxWidth!;
          newHeight = (options.maxWidth! / aspectRatio).round();
        } else {
          newHeight = options.maxHeight!;
          newWidth = (options.maxHeight! * aspectRatio).round();
        }
      } else {
        newWidth = options.maxWidth!;
        newHeight = options.maxHeight!;
      }
    } else if (options.maxWidth != null) {
      newWidth = options.maxWidth!;
      if (options.maintainAspectRatio) {
        newHeight = (newWidth * image.height / image.width).round();
      }
    } else if (options.maxHeight != null) {
      newHeight = options.maxHeight!;
      if (options.maintainAspectRatio) {
        newWidth = (newHeight * image.width / image.height).round();
      }
    }

    if (newWidth != image.width || newHeight != image.height) {
      return img.copyResize(
        image,
        width: newWidth,
        height: newHeight,
        interpolation: img.Interpolation.linear,
      );
    }

    return image;
  }

  Future<img.Image> _applyImageFilter(
    img.Image image,
    ImageProcessingOptions options,
  ) async {
    final intensity = options.filterIntensity ?? 1.0;

    switch (options.filter) {
      case ImageFilterType.grayscale:
        return img.grayscale(image);

      case ImageFilterType.sepia:
        return img.sepia(image);

      case ImageFilterType.blur:
        final radius = (intensity * 3).clamp(1, 10).toInt();
        return img.gaussianBlur(image, radius: radius);

      case ImageFilterType.sharpen:
        return img.convolution(image, filter: [0, -1, 0, -1, 5, -1, 0, -1, 0]);

      case ImageFilterType.contrast:
        final contrast = (120 * intensity).round();
        return img.contrast(image, contrast: contrast);

      case ImageFilterType.saturation:
        final saturation = (1.5 * intensity);
        return img.adjustColor(image, saturation: saturation);

      case ImageFilterType.none:
      default:
        return image;
    }
  }

  Future<Uint8List> _encodeImage(
    img.Image image,
    ImageProcessingOptions options,
  ) async {
    final format = options.format ?? ImageFormat.jpeg;
    final quality = options.quality ?? 85;

    switch (format) {
      case ImageFormat.jpeg:
        return Uint8List.fromList(img.encodeJpg(image, quality: quality));
      case ImageFormat.png:
        return Uint8List.fromList(img.encodePng(image));
      case ImageFormat.gif:
        return Uint8List.fromList(img.encodeGif(image));
      case ImageFormat.bmp:
        return Uint8List.fromList(img.encodeBmp(image));
      case ImageFormat.webp:
        return Uint8List.fromList(img.encodePng(image));
    }
  }

  Future<String> _generateOutputPath(
    String inputPath,
    ImageFormat format,
  ) async {
    final directory = await getApplicationDocumentsDirectory();
    final processedDir = Directory('${directory.path}/processed_images');

    if (!await processedDir.exists()) {
      await processedDir.create(recursive: true);
    }

    final fileName = inputPath.split('/').last.split('.').first;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = _getFileExtension(format);

    return '${processedDir.path}/${fileName}_$timestamp.$extension';
  }

  Future<String?> generateThumbnail(
    String imagePath, {
    int maxSize = 200,
    ImageFormat format = ImageFormat.jpeg,
    int quality = 75,
  }) async {
    try {
      // Check cache first
      final cacheKey = '${imagePath}_${maxSize}_${format.name}_$quality';
      if (_thumbnailCache.containsKey(cacheKey)) {
        return _thumbnailCache[cacheKey];
      }

      final options = ImageProcessingOptions(
        maxWidth: maxSize,
        maxHeight: maxSize,
        quality: quality,
        format: format,
        maintainAspectRatio: true,
      );

      final thumbnailPath = await processImage(imagePath, options);

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
      }

      return thumbnailPath;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error generating thumbnail: $e');
      }
      throw MediaException.thumbnailGenerationFailed();
    }
  }

  Future<String?> compressImage(
    String imagePath, {
    int quality = 85,
    int? maxWidth,
    int? maxHeight,
    ImageFormat? format,
  }) async {
    final options = ImageProcessingOptions(
      quality: quality,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      format: format,
      maintainAspectRatio: true,
    );

    return await processImage(imagePath, options);
  }

  Future<String?> cropImage(
    String imagePath, {
    required int x,
    required int y,
    required int width,
    required int height,
  }) async {
    try {
      final inputFile = File(imagePath);
      if (!await inputFile.exists()) {
        throw FileException.notFound(imagePath);
      }

      final inputBytes = await inputFile.readAsBytes();
      img.Image? image = img.decodeImage(inputBytes);

      if (image == null) {
        throw MediaException.compressionFailed();
      }

      // Validate crop bounds
      if (x < 0 ||
          y < 0 ||
          x + width > image.width ||
          y + height > image.height) {
        throw ArgumentError('Crop bounds are invalid');
      }

      final croppedImage = img.copyCrop(
        image,
        x: x,
        y: y,
        width: width,
        height: height,
      );

      final outputPath = await _generateOutputPath(imagePath, ImageFormat.jpeg);
      final outputBytes = img.encodeJpg(croppedImage, quality: 90);

      await File(outputPath).writeAsBytes(outputBytes);

      if (kDebugMode) {
        print('✅ Image cropped: $imagePath -> $outputPath');
      }

      return outputPath;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error cropping image: $e');
      }
      throw MediaException.compressionFailed();
    }
  }

  Future<String?> rotateImage(String imagePath, double degrees) async {
    try {
      final inputFile = File(imagePath);
      if (!await inputFile.exists()) {
        throw FileException.notFound(imagePath);
      }

      final inputBytes = await inputFile.readAsBytes();
      img.Image? image = img.decodeImage(inputBytes);

      if (image == null) {
        throw MediaException.compressionFailed();
      }

      final rotatedImage = img.copyRotate(image, angle: degrees);

      final outputPath = await _generateOutputPath(imagePath, ImageFormat.jpeg);
      final outputBytes = img.encodeJpg(rotatedImage, quality: 90);

      await File(outputPath).writeAsBytes(outputBytes);

      if (kDebugMode) {
        print('✅ Image rotated: $imagePath -> $outputPath (${degrees}°)');
      }

      return outputPath;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error rotating image: $e');
      }
      throw MediaException.compressionFailed();
    }
  }

  Future<String?> flipImage(
    String imagePath, {
    bool horizontal = false,
    bool vertical = false,
  }) async {
    try {
      final inputFile = File(imagePath);
      if (!await inputFile.exists()) {
        throw FileException.notFound(imagePath);
      }

      final inputBytes = await inputFile.readAsBytes();
      img.Image? image = img.decodeImage(inputBytes);

      if (image == null) {
        throw MediaException.compressionFailed();
      }

      img.Image flippedImage = image;

      if (horizontal) {
        flippedImage = img.flipHorizontal(flippedImage);
      }

      if (vertical) {
        flippedImage = img.flipVertical(flippedImage);
      }

      final outputPath = await _generateOutputPath(imagePath, ImageFormat.jpeg);
      final outputBytes = img.encodeJpg(flippedImage, quality: 90);

      await File(outputPath).writeAsBytes(outputBytes);

      if (kDebugMode) {
        print('✅ Image flipped: $imagePath -> $outputPath');
      }

      return outputPath;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error flipping image: $e');
      }
      throw MediaException.compressionFailed();
    }
  }

  Future<Uint8List?> captureWidget(
    GlobalKey key, {
    double pixelRatio = 1.0,
    ImageFormat format = ImageFormat.png,
    int quality = 100,
  }) async {
    try {
      final RenderRepaintBoundary boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary;

      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        throw MediaException.compressionFailed();
      }

      Uint8List bytes = byteData.buffer.asUint8List();

      // Convert format if needed
      if (format != ImageFormat.png) {
        final img.Image? decodedImage = img.decodeImage(bytes);
        if (decodedImage != null) {
          bytes = await _encodeImage(
            decodedImage,
            ImageProcessingOptions(format: format, quality: quality),
          );
        }
      }

      return bytes;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error capturing widget: $e');
      }
      throw MediaException.compressionFailed();
    }
  }

  Future<String?> saveWidgetAsImage(
    GlobalKey key,
    String fileName, {
    double pixelRatio = 1.0,
    ImageFormat format = ImageFormat.png,
    int quality = 100,
  }) async {
    try {
      final bytes = await captureWidget(
        key,
        pixelRatio: pixelRatio,
        format: format,
        quality: quality,
      );

      if (bytes == null) return null;

      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';

      await File(filePath).writeAsBytes(bytes);

      if (kDebugMode) {
        print('✅ Widget saved as image: $filePath');
      }

      return filePath;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving widget as image: $e');
      }
      return null;
    }
  }

  // Utility methods

  ImageFormat _getImageFormatFromExtension(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return ImageFormat.jpeg;
      case 'png':
        return ImageFormat.png;
      case 'gif':
        return ImageFormat.gif;
      case 'bmp':
        return ImageFormat.bmp;
      case 'webp':
        return ImageFormat.webp;
      default:
        return ImageFormat.jpeg;
    }
  }

  String _getFileExtension(ImageFormat format) {
    switch (format) {
      case ImageFormat.jpeg:
        return 'jpg';
      case ImageFormat.png:
        return 'png';
      case ImageFormat.gif:
        return 'gif';
      case ImageFormat.bmp:
        return 'bmp';
      case ImageFormat.webp:
        return 'webp';
    }
  }

  bool isImageFile(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension);
  }

  Future<List<String>> getRecentImages({int limit = 20}) async {
    try {
      final recentFiles = _filePickerService.recentFiles
          .where((file) => file.isImage)
          .take(limit)
          .map((file) => file.path)
          .toList();

      return recentFiles;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting recent images: $e');
      }
      return [];
    }
  }

  Future<void> clearImageCache() async {
    _imageInfoCache.clear();
    _imageBytesCache.clear();
    await _saveImageCache();

    if (kDebugMode) {
      print('🗑️ Image cache cleared');
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
      print('🗑️ Thumbnail cache cleared');
    }
  }

  Future<void> deleteProcessedImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();

        // Remove from caches
        _imageInfoCache.remove(imagePath);
        _imageBytesCache.remove(imagePath);

        // Remove thumbnails
        final keysToRemove = _thumbnailCache.keys
            .where((key) => key.startsWith(imagePath))
            .toList();

        for (final key in keysToRemove) {
          final thumbnailPath = _thumbnailCache.remove(key);
          if (thumbnailPath != null) {
            try {
              await File(thumbnailPath).delete();
            } catch (e) {
              // Ignore deletion errors
            }
          }
        }

        if (kDebugMode) {
          print('🗑️ Processed image deleted: $imagePath');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error deleting processed image: $e');
      }
    }
  }

  // Batch operations

  Future<List<String>> batchProcessImages(
    List<String> imagePaths,
    ImageProcessingOptions options, {
    Function(int processed, int total)? onProgress,
  }) async {
    final results = <String>[];

    for (int i = 0; i < imagePaths.length; i++) {
      try {
        final result = await processImage(imagePaths[i], options);
        if (result != null) {
          results.add(result);
        }

        onProgress?.call(i + 1, imagePaths.length);
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error processing image ${imagePaths[i]}: $e');
        }
      }
    }

    return results;
  }

  Future<List<String>> batchGenerateThumbnails(
    List<String> imagePaths, {
    int maxSize = 200,
    ImageFormat format = ImageFormat.jpeg,
    int quality = 75,
    Function(int processed, int total)? onProgress,
  }) async {
    final results = <String>[];

    for (int i = 0; i < imagePaths.length; i++) {
      try {
        final result = await generateThumbnail(
          imagePaths[i],
          maxSize: maxSize,
          format: format,
          quality: quality,
        );
        if (result != null) {
          results.add(result);
        }

        onProgress?.call(i + 1, imagePaths.length);
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error generating thumbnail for ${imagePaths[i]}: $e');
        }
      }
    }

    return results;
  }

  // Settings

  void setMaxConcurrentProcessing(int maxConcurrent) {
    _maxConcurrentProcessing = maxConcurrent.clamp(1, 10);
  }

  // Cleanup

  Future<void> dispose() async {
    // Wait for all processing to complete
    if (_processingQueue.isNotEmpty) {
      await Future.wait(_processingQueue);
    }

    await _imageProcessedController.close();

    _imageInfoCache.clear();
    _imageBytesCache.clear();
    _thumbnailCache.clear();

    if (kDebugMode) {
      print('✅ Image service disposed');
    }
  }
}

// Riverpod providers
final imageServiceProvider = Provider<ImageService>((ref) {
  return ImageService();
});

final imageProcessedProvider = StreamProvider<ImageDataInfo>((ref) {
  final service = ref.watch(imageServiceProvider);
  return service.imageProcessedStream;
});

final recentImagesProvider = FutureProvider.family<List<String>, int>((
  ref,
  limit,
) async {
  final service = ref.watch(imageServiceProvider);
  return service.getRecentImages(limit: limit);
});
