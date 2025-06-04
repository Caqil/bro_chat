import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:bro_chat/core/config/app_config.dart';
import 'package:bro_chat/models/file/file_model.dart';
import 'package:crypto/crypto.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;

class FileUtils {
  // Private constructor to prevent instantiation
  FileUtils._();

  // File size constants
  static const int bytesInKB = 1024;
  static const int bytesInMB = 1024 * 1024;
  static const int bytesInGB = 1024 * 1024 * 1024;

  // Supported file types
  static const List<String> imageExtensions = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    'bmp',
    'svg',
  ];
  static const List<String> videoExtensions = [
    'mp4',
    'mov',
    'avi',
    'mkv',
    '3gp',
    'webm',
    'flv',
    'wmv',
  ];
  static const List<String> audioExtensions = [
    'mp3',
    'wav',
    'aac',
    'ogg',
    'm4a',
    'flac',
    'wma',
  ];
  static const List<String> documentExtensions = [
    'pdf',
    'doc',
    'docx',
    'xls',
    'xlsx',
    'ppt',
    'pptx',
    'txt',
    'rtf',
  ];
  static const List<String> archiveExtensions = [
    'zip',
    'rar',
    '7z',
    'tar',
    'gz',
    'bz2',
  ];
  static const List<String> codeExtensions = [
    'dart',
    'js',
    'ts',
    'html',
    'css',
    'json',
    'xml',
    'yaml',
    'py',
    'java',
    'cpp',
    'c',
    'h',
  ];

  // Format file size in human readable format
  static String formatFileSize(int bytes) {
    if (bytes < bytesInKB) {
      return '${bytes}B';
    } else if (bytes < bytesInMB) {
      return '${(bytes / bytesInKB).toStringAsFixed(1)}KB';
    } else if (bytes < bytesInGB) {
      return '${(bytes / bytesInMB).toStringAsFixed(1)}MB';
    } else {
      return '${(bytes / bytesInGB).toStringAsFixed(1)}GB';
    }
  }

  // Parse file size from string (e.g., "1.5MB" -> bytes)
  static int? parseFileSize(String sizeString) {
    final regex = RegExp(
      r'^(\d+(?:\.\d+)?)\s*(B|KB|MB|GB)$',
      caseSensitive: false,
    );
    final match = regex.firstMatch(sizeString.trim());

    if (match == null) return null;

    final value = double.tryParse(match.group(1)!) ?? 0;
    final unit = match.group(2)!.toUpperCase();

    switch (unit) {
      case 'B':
        return value.round();
      case 'KB':
        return (value * bytesInKB).round();
      case 'MB':
        return (value * bytesInMB).round();
      case 'GB':
        return (value * bytesInGB).round();
      default:
        return null;
    }
  }

  // Get file extension from path or filename
  static String getFileExtension(String filePath) {
    return path.extension(filePath).toLowerCase().replaceFirst('.', '');
  }

  // Get filename without extension
  static String getFileNameWithoutExtension(String filePath) {
    return path.basenameWithoutExtension(filePath);
  }

  // Get filename with extension
  static String getFileName(String filePath) {
    return path.basename(filePath);
  }

  // Get directory path
  static String getDirectoryPath(String filePath) {
    return path.dirname(filePath);
  }

  // Get MIME type from file extension
  static String? getMimeType(String filePath) {
    return lookupMimeType(filePath);
  }

  // Get MIME type from file bytes
  static String? getMimeTypeFromBytes(Uint8List bytes, {String? headerBytes}) {
    return lookupMimeType('', headerBytes: bytes);
  }

  // Check if file is an image
  static bool isImage(String filePath) {
    final extension = getFileExtension(filePath);
    return imageExtensions.contains(extension);
  }

  // Check if file is a video
  static bool isVideo(String filePath) {
    final extension = getFileExtension(filePath);
    return videoExtensions.contains(extension);
  }

  // Check if file is an audio file
  static bool isAudio(String filePath) {
    final extension = getFileExtension(filePath);
    return audioExtensions.contains(extension);
  }

  // Check if file is a document
  static bool isDocument(String filePath) {
    final extension = getFileExtension(filePath);
    return documentExtensions.contains(extension);
  }

  // Check if file is an archive
  static bool isArchive(String filePath) {
    final extension = getFileExtension(filePath);
    return archiveExtensions.contains(extension);
  }

  // Check if file is a code file
  static bool isCode(String filePath) {
    final extension = getFileExtension(filePath);
    return codeExtensions.contains(extension);
  }

  // Get file type category
  static FileType getFileType(String filePath) {
    if (isImage(filePath)) return FileType.image;
    if (isVideo(filePath)) return FileType.video;
    if (isAudio(filePath)) return FileType.audio;
    if (isDocument(filePath)) return FileType.document;
    if (isArchive(filePath)) return FileType.archive;
    return FileType.other;
  }

  // Get file icon based on extension
  static String getFileIcon(String filePath) {
    final type = getFileType(filePath);
    final extension = getFileExtension(filePath);

    switch (type) {
      case FileType.image:
        return '🖼️';
      case FileType.video:
        return '🎬';
      case FileType.audio:
        return '🎵';
      case FileType.archive:
        return '📦';
      case FileType.document:
        switch (extension) {
          case 'pdf':
            return '📄';
          case 'doc':
          case 'docx':
            return '📝';
          case 'xls':
          case 'xlsx':
            return '📊';
          case 'ppt':
          case 'pptx':
            return '📋';
          default:
            return '📄';
        }
      default:
        return '📎';
    }
  }

  // Validate file size
  static bool isValidFileSize(int bytes, FileType type) {
    switch (type) {
      case FileType.image:
        return bytes <= AppConfig.maxImageSize;
      case FileType.video:
      case FileType.audio:
      case FileType.document:
      case FileType.archive:
      case FileType.other:
        return bytes <= AppConfig.maxFileSize;
    }
  }

  // Validate file type
  static bool isValidFileType(
    String filePath, {
    List<String>? allowedExtensions,
  }) {
    final extension = getFileExtension(filePath);

    if (allowedExtensions != null) {
      return allowedExtensions.contains(extension);
    }

    // Check against app's allowed types
    return AppConfig.allowedImageTypes.any(
          (type) => type.contains(extension),
        ) ||
        AppConfig.allowedVideoTypes.any((type) => type.contains(extension)) ||
        AppConfig.allowedAudioTypes.any((type) => type.contains(extension)) ||
        AppConfig.allowedDocumentTypes.any((type) => type.contains(extension));
  }

  // Generate unique filename
  static String generateUniqueFileName(String originalName) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = getFileExtension(originalName);
    final nameWithoutExt = getFileNameWithoutExtension(originalName);
    return '${nameWithoutExt}_$timestamp${extension.isNotEmpty ? '.$extension' : ''}';
  }

  // Sanitize filename
  static String sanitizeFileName(String fileName) {
    // Remove invalid characters for file systems
    return fileName
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .trim();
  }

  // Calculate file hash (MD5)
  static String calculateMD5(List<int> bytes) {
    return md5.convert(bytes).toString();
  }

  // Calculate file hash (SHA256)
  static String calculateSHA256(List<int> bytes) {
    return sha256.convert(bytes).toString();
  }

  // Read file as bytes
  static Future<Uint8List?> readFileAsBytes(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
    } catch (e) {
      print('Error reading file: $e');
    }
    return null;
  }

  // Read file as string
  static Future<String?> readFileAsString(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.readAsString();
      }
    } catch (e) {
      print('Error reading file: $e');
    }
    return null;
  }

  // Write bytes to file
  static Future<bool> writeBytes(String filePath, List<int> bytes) async {
    try {
      final file = File(filePath);
      await file.create(recursive: true);
      await file.writeAsBytes(bytes);
      return true;
    } catch (e) {
      print('Error writing file: $e');
      return false;
    }
  }

  // Write string to file
  static Future<bool> writeString(String filePath, String content) async {
    try {
      final file = File(filePath);
      await file.create(recursive: true);
      await file.writeAsString(content);
      return true;
    } catch (e) {
      print('Error writing file: $e');
      return false;
    }
  }

  // Copy file
  static Future<bool> copyFile(
    String sourcePath,
    String destinationPath,
  ) async {
    try {
      final sourceFile = File(sourcePath);
      if (await sourceFile.exists()) {
        await sourceFile.copy(destinationPath);
        return true;
      }
    } catch (e) {
      print('Error copying file: $e');
    }
    return false;
  }

  // Move file
  static Future<bool> moveFile(
    String sourcePath,
    String destinationPath,
  ) async {
    try {
      final sourceFile = File(sourcePath);
      if (await sourceFile.exists()) {
        await sourceFile.rename(destinationPath);
        return true;
      }
    } catch (e) {
      print('Error moving file: $e');
    }
    return false;
  }

  // Delete file
  static Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (e) {
      print('Error deleting file: $e');
    }
    return false;
  }

  // Check if file exists
  static Future<bool> fileExists(String filePath) async {
    try {
      return await File(filePath).exists();
    } catch (e) {
      return false;
    }
  }

  // Get file size
  static Future<int?> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
    } catch (e) {
      print('Error getting file size: $e');
    }
    return null;
  }

  // Get file modified date
  static Future<DateTime?> getFileModifiedDate(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final stat = await file.stat();
        return stat.modified;
      }
    } catch (e) {
      print('Error getting file date: $e');
    }
    return null;
  }

  // Create directory
  static Future<bool> createDirectory(String dirPath) async {
    try {
      final directory = Directory(dirPath);
      await directory.create(recursive: true);
      return true;
    } catch (e) {
      print('Error creating directory: $e');
      return false;
    }
  }

  // List files in directory
  static Future<List<String>> listFiles(
    String dirPath, {
    String? extension,
  }) async {
    try {
      final directory = Directory(dirPath);
      if (await directory.exists()) {
        final files = <String>[];
        await for (final entity in directory.list()) {
          if (entity is File) {
            final filePath = entity.path;
            if (extension == null || getFileExtension(filePath) == extension) {
              files.add(filePath);
            }
          }
        }
        return files;
      }
    } catch (e) {
      print('Error listing files: $e');
    }
    return [];
  }

  // Get directory size
  static Future<int> getDirectorySize(String dirPath) async {
    int totalSize = 0;
    try {
      final directory = Directory(dirPath);
      if (await directory.exists()) {
        await for (final entity in directory.list(recursive: true)) {
          if (entity is File) {
            try {
              totalSize += await entity.length();
            } catch (e) {
              // Skip files that can't be read
            }
          }
        }
      }
    } catch (e) {
      print('Error calculating directory size: $e');
    }
    return totalSize;
  }

  // Clean up temporary files
  static Future<void> cleanupTempFiles(
    String tempDir, {
    Duration? olderThan,
  }) async {
    try {
      final directory = Directory(tempDir);
      if (await directory.exists()) {
        final cutoffTime = DateTime.now().subtract(
          olderThan ?? const Duration(hours: 24),
        );

        await for (final entity in directory.list()) {
          if (entity is File) {
            try {
              final stat = await entity.stat();
              if (stat.modified.isBefore(cutoffTime)) {
                await entity.delete();
              }
            } catch (e) {
              // Skip files that can't be deleted
            }
          }
        }
      }
    } catch (e) {
      print('Error cleaning up temp files: $e');
    }
  }

  // Compress image (placeholder - would need image processing library)
  static Future<Uint8List?> compressImage(
    Uint8List imageBytes, {
    int quality = 85,
    int? maxWidth,
    int? maxHeight,
  }) async {
    // This would require an image processing library like image or flutter_image_compress
    // For now, return the original bytes
    return imageBytes;
  }

  // Generate thumbnail (placeholder - would need image processing library)
  static Future<Uint8List?> generateThumbnail(
    Uint8List imageBytes, {
    int width = 150,
    int height = 150,
  }) async {
    // This would require an image processing library
    // For now, return the original bytes
    return imageBytes;
  }

  // Get video duration (placeholder - would need video processing library)
  static Future<Duration?> getVideoDuration(String videoPath) async {
    // This would require a video processing library
    // For now, return null
    return null;
  }

  // Extract video thumbnail (placeholder - would need video processing library)
  static Future<Uint8List?> extractVideoThumbnail(
    String videoPath, {
    Duration? position,
  }) async {
    // This would require a video processing library
    // For now, return null
    return null;
  }

  // Get audio duration (placeholder - would need audio processing library)
  static Future<Duration?> getAudioDuration(String audioPath) async {
    // This would require an audio processing library
    // For now, return null
    return null;
  }

  // Convert bytes to base64
  static String bytesToBase64(List<int> bytes) {
    return base64Encode(bytes);
  }

  // Convert base64 to bytes
  static Uint8List base64ToBytes(String base64String) {
    return base64Decode(base64String);
  }

  // Check if path is absolute
  static bool isAbsolutePath(String filePath) {
    return path.isAbsolute(filePath);
  }

  // Join paths
  static String joinPaths(
    String part1,
    String part2, [
    String? part3,
    String? part4,
  ]) {
    if (part4 != null) {
      return path.join(part1, part2, part3!, part4);
    } else if (part3 != null) {
      return path.join(part1, part2, part3);
    } else {
      return path.join(part1, part2);
    }
  }

  // Normalize path
  static String normalizePath(String filePath) {
    return path.normalize(filePath);
  }

  // Get relative path
  static String relativePath(String from, String to) {
    return path.relative(to, from: from);
  }

  // Split path into components
  static List<String> splitPath(String filePath) {
    return path.split(filePath);
  }

  // Check if filename is valid
  static bool isValidFileName(String fileName) {
    // Check for invalid characters
    if (RegExp(r'[<>:"/\\|?*]').hasMatch(fileName)) {
      return false;
    }

    // Check for reserved names (Windows)
    final reservedNames = [
      'CON',
      'PRN',
      'AUX',
      'NUL',
      'COM1',
      'COM2',
      'COM3',
      'COM4',
      'COM5',
      'COM6',
      'COM7',
      'COM8',
      'COM9',
      'LPT1',
      'LPT2',
      'LPT3',
      'LPT4',
      'LPT5',
      'LPT6',
      'LPT7',
      'LPT8',
      'LPT9',
    ];

    final nameWithoutExt = getFileNameWithoutExtension(fileName).toUpperCase();
    if (reservedNames.contains(nameWithoutExt)) {
      return false;
    }

    // Check length
    if (fileName.length > 255) {
      return false;
    }

    return true;
  }

  // Get safe filename
  static String getSafeFileName(String fileName) {
    if (isValidFileName(fileName)) {
      return fileName;
    }
    return sanitizeFileName(fileName);
  }

  // Calculate download progress
  static double calculateProgress(int downloaded, int total) {
    if (total <= 0) return 0.0;
    return (downloaded / total).clamp(0.0, 1.0);
  }

  // Format download speed
  static String formatSpeed(int bytesPerSecond) {
    if (bytesPerSecond < bytesInKB) {
      return '${bytesPerSecond}B/s';
    } else if (bytesPerSecond < bytesInMB) {
      return '${(bytesPerSecond / bytesInKB).toStringAsFixed(1)}KB/s';
    } else {
      return '${(bytesPerSecond / bytesInMB).toStringAsFixed(1)}MB/s';
    }
  }

  // Estimate remaining time
  static String estimateRemainingTime(int remainingBytes, int bytesPerSecond) {
    if (bytesPerSecond <= 0) return 'Unknown';

    final seconds = remainingBytes / bytesPerSecond;

    if (seconds < 60) {
      return '${seconds.round()}s';
    } else if (seconds < 3600) {
      return '${(seconds / 60).round()}m';
    } else {
      return '${(seconds / 3600).round()}h';
    }
  }
}
