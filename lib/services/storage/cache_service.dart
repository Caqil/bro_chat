import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import '../../core/exceptions/app_exception.dart';

class CacheService {
  static CacheService? _instance;

  // Box names
  static const String _messagesBox = 'messages';
  static const String _chatsBox = 'chats';
  static const String _usersBox = 'users';
  static const String _groupsBox = 'groups';
  static const String _filesBox = 'files';
  static const String _callsBox = 'calls';
  static const String _settingsBox = 'settings';
  static const String _mediaBox = 'media';
  static const String _generalBox = 'general';

  // Cache entry wrapper
  final Map<String, Box> _boxes = {};

  CacheService._internal();

  factory CacheService() {
    _instance ??= CacheService._internal();
    return _instance!;
  }

  Future<void> init() async {
    try {
      await Hive.initFlutter();

      // Get application documents directory
      final appDocDir = await getApplicationDocumentsDirectory();
      final cachePath = '${appDocDir.path}/cache';

      // Create cache directory if it doesn't exist
      final cacheDir = Directory(cachePath);
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }

      // Open all boxes
      await _openBoxes();

      // Clean up expired entries
      await _cleanupExpiredEntries();

      if (kDebugMode) {
        print('✅ Cache service initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing cache service: $e');
      }
      rethrow;
    }
  }

  Future<void> _openBoxes() async {
    final boxNames = [
      _messagesBox,
      _chatsBox,
      _usersBox,
      _groupsBox,
      _filesBox,
      _callsBox,
      _settingsBox,
      _mediaBox,
      _generalBox,
    ];

    for (final boxName in boxNames) {
      try {
        final box = await Hive.openBox(boxName);
        _boxes[boxName] = box;
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error opening box $boxName: $e');
        }
      }
    }
  }

  Box _getBox(String boxName) {
    final box = _boxes[boxName];
    if (box == null || !box.isOpen) {
      throw CacheException('Cache box $boxName is not available');
    }
    return box;
  }

  // Messages Cache
  Future<void> cacheMessage(
    String messageId,
    Map<String, dynamic> message,
  ) async {
    try {
      final box = _getBox(_messagesBox);
      final entry = CacheEntry(
        data: message,
        timestamp: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );

      await box.put(messageId, entry.toJson());

      if (kDebugMode) {
        print('✅ Message cached: $messageId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error caching message: $e');
      }
      throw CacheException.writeError(messageId);
    }
  }

  Future<Map<String, dynamic>?> getCachedMessage(String messageId) async {
    try {
      final box = _getBox(_messagesBox);
      final entryJson = box.get(messageId);

      if (entryJson == null) {
        return null;
      }

      final entry = CacheEntry.fromJson(entryJson);

      if (entry.isExpired) {
        await box.delete(messageId);
        return null;
      }

      return entry.data;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting cached message: $e');
      }
      return null;
    }
  }

  Future<void> cacheMessages(List<Map<String, dynamic>> messages) async {
    try {
      final box = _getBox(_messagesBox);
      final batch = <String, dynamic>{};

      for (final message in messages) {
        final messageId = message['id'] as String?;
        if (messageId != null) {
          final entry = CacheEntry(
            data: message,
            timestamp: DateTime.now(),
            expiresAt: DateTime.now().add(const Duration(days: 30)),
          );
          batch[messageId] = entry.toJson();
        }
      }

      await box.putAll(batch);

      if (kDebugMode) {
        print('✅ Cached ${messages.length} messages');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error caching messages: $e');
      }
    }
  }

  Future<List<Map<String, dynamic>>> getCachedMessages(
    String chatId, {
    int limit = 50,
    String? beforeMessageId,
  }) async {
    try {
      final box = _getBox(_messagesBox);
      final messages = <Map<String, dynamic>>[];

      for (final key in box.keys) {
        try {
          final entryJson = box.get(key);
          if (entryJson == null) continue;

          final entry = CacheEntry.fromJson(entryJson);

          if (entry.isExpired) {
            await box.delete(key);
            continue;
          }

          final message = entry.data;
          if (message['chat_id'] == chatId) {
            messages.add(message);
          }
        } catch (e) {
          // Skip invalid entries
          continue;
        }
      }

      // Sort by timestamp (newest first)
      messages.sort((a, b) {
        final aTime =
            DateTime.tryParse(a['created_at'] ?? '') ?? DateTime.now();
        final bTime =
            DateTime.tryParse(b['created_at'] ?? '') ?? DateTime.now();
        return bTime.compareTo(aTime);
      });

      // Apply beforeMessageId filter if provided
      if (beforeMessageId != null) {
        final beforeIndex = messages.indexWhere(
          (m) => m['id'] == beforeMessageId,
        );
        if (beforeIndex > 0) {
          return messages.sublist(beforeIndex + 1).take(limit).toList();
        }
      }

      return messages.take(limit).toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting cached messages: $e');
      }
      return [];
    }
  }

  // Chats Cache
  Future<void> cacheChat(String chatId, Map<String, dynamic> chat) async {
    try {
      final box = _getBox(_chatsBox);
      final entry = CacheEntry(
        data: chat,
        timestamp: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 7)),
      );

      await box.put(chatId, entry.toJson());

      if (kDebugMode) {
        print('✅ Chat cached: $chatId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error caching chat: $e');
      }
      throw CacheException.writeError(chatId);
    }
  }

  Future<Map<String, dynamic>?> getCachedChat(String chatId) async {
    try {
      final box = _getBox(_chatsBox);
      final entryJson = box.get(chatId);

      if (entryJson == null) {
        return null;
      }

      final entry = CacheEntry.fromJson(entryJson);

      if (entry.isExpired) {
        await box.delete(chatId);
        return null;
      }

      return entry.data;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting cached chat: $e');
      }
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getCachedChats() async {
    try {
      final box = _getBox(_chatsBox);
      final chats = <Map<String, dynamic>>[];

      for (final key in box.keys) {
        try {
          final entryJson = box.get(key);
          if (entryJson == null) continue;

          final entry = CacheEntry.fromJson(entryJson);

          if (entry.isExpired) {
            await box.delete(key);
            continue;
          }

          chats.add(entry.data);
        } catch (e) {
          // Skip invalid entries
          continue;
        }
      }

      // Sort by last message timestamp
      chats.sort((a, b) {
        final aTime =
            DateTime.tryParse(a['last_message_at'] ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bTime =
            DateTime.tryParse(b['last_message_at'] ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

      return chats;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting cached chats: $e');
      }
      return [];
    }
  }

  // Users Cache
  Future<void> cacheUser(String userId, Map<String, dynamic> user) async {
    try {
      final box = _getBox(_usersBox);
      final entry = CacheEntry(
        data: user,
        timestamp: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 6)),
      );

      await box.put(userId, entry.toJson());
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error caching user: $e');
      }
    }
  }

  Future<Map<String, dynamic>?> getCachedUser(String userId) async {
    try {
      final box = _getBox(_usersBox);
      final entryJson = box.get(userId);

      if (entryJson == null) {
        return null;
      }

      final entry = CacheEntry.fromJson(entryJson);

      if (entry.isExpired) {
        await box.delete(userId);
        return null;
      }

      return entry.data;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting cached user: $e');
      }
      return null;
    }
  }

  // Groups Cache
  Future<void> cacheGroup(String groupId, Map<String, dynamic> group) async {
    try {
      final box = _getBox(_groupsBox);
      final entry = CacheEntry(
        data: group,
        timestamp: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 2)),
      );

      await box.put(groupId, entry.toJson());
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error caching group: $e');
      }
    }
  }

  Future<Map<String, dynamic>?> getCachedGroup(String groupId) async {
    try {
      final box = _getBox(_groupsBox);
      final entryJson = box.get(groupId);

      if (entryJson == null) {
        return null;
      }

      final entry = CacheEntry.fromJson(entryJson);

      if (entry.isExpired) {
        await box.delete(groupId);
        return null;
      }

      return entry.data;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting cached group: $e');
      }
      return null;
    }
  }

  // Files Cache
  Future<void> cacheFile(
    String fileId,
    Uint8List fileData, {
    String? mimeType,
    Duration? expiry,
  }) async {
    try {
      final box = _getBox(_filesBox);
      final entry = CacheEntry(
        data: {
          'data': fileData,
          'mime_type': mimeType,
          'size': fileData.length,
        },
        timestamp: DateTime.now(),
        expiresAt: DateTime.now().add(expiry ?? const Duration(days: 7)),
      );

      await box.put(fileId, entry.toJson());

      if (kDebugMode) {
        print('✅ File cached: $fileId (${fileData.length} bytes)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error caching file: $e');
      }
      throw CacheException.writeError(fileId);
    }
  }

  Future<Uint8List?> getCachedFile(String fileId) async {
    try {
      final box = _getBox(_filesBox);
      final entryJson = box.get(fileId);

      if (entryJson == null) {
        return null;
      }

      final entry = CacheEntry.fromJson(entryJson);

      if (entry.isExpired) {
        await box.delete(fileId);
        return null;
      }

      final fileData = entry.data['data'];
      if (fileData is List<int>) {
        return Uint8List.fromList(fileData);
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting cached file: $e');
      }
      return null;
    }
  }

  // Media Cache (thumbnails, compressed images, etc.)
  Future<void> cacheMedia(
    String mediaId,
    Uint8List mediaData, {
    String? type,
    Duration? expiry,
  }) async {
    try {
      final box = _getBox(_mediaBox);
      final entry = CacheEntry(
        data: {'data': mediaData, 'type': type, 'size': mediaData.length},
        timestamp: DateTime.now(),
        expiresAt: DateTime.now().add(expiry ?? const Duration(days: 14)),
      );

      await box.put(mediaId, entry.toJson());
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error caching media: $e');
      }
    }
  }

  Future<Uint8List?> getCachedMedia(String mediaId) async {
    try {
      final box = _getBox(_mediaBox);
      final entryJson = box.get(mediaId);

      if (entryJson == null) {
        return null;
      }

      final entry = CacheEntry.fromJson(entryJson);

      if (entry.isExpired) {
        await box.delete(mediaId);
        return null;
      }

      final mediaData = entry.data['data'];
      if (mediaData is List<int>) {
        return Uint8List.fromList(mediaData);
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting cached media: $e');
      }
      return null;
    }
  }

  // Call History Cache
  Future<void> cacheCall(String callId, Map<String, dynamic> call) async {
    try {
      final box = _getBox(_callsBox);
      final entry = CacheEntry(
        data: call,
        timestamp: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );

      await box.put(callId, entry.toJson());
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error caching call: $e');
      }
    }
  }

  Future<List<Map<String, dynamic>>> getCachedCalls() async {
    try {
      final box = _getBox(_callsBox);
      final calls = <Map<String, dynamic>>[];

      for (final key in box.keys) {
        try {
          final entryJson = box.get(key);
          if (entryJson == null) continue;

          final entry = CacheEntry.fromJson(entryJson);

          if (entry.isExpired) {
            await box.delete(key);
            continue;
          }

          calls.add(entry.data);
        } catch (e) {
          // Skip invalid entries
          continue;
        }
      }

      // Sort by timestamp (newest first)
      calls.sort((a, b) {
        final aTime =
            DateTime.tryParse(a['created_at'] ?? '') ?? DateTime.now();
        final bTime =
            DateTime.tryParse(b['created_at'] ?? '') ?? DateTime.now();
        return bTime.compareTo(aTime);
      });

      return calls;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting cached calls: $e');
      }
      return [];
    }
  }

  // General Cache
  Future<void> cache(String key, dynamic data, {Duration? expiry}) async {
    try {
      final box = _getBox(_generalBox);
      final entry = CacheEntry(
        data: data,
        timestamp: DateTime.now(),
        expiresAt: DateTime.now().add(expiry ?? const Duration(hours: 1)),
      );

      await box.put(key, entry.toJson());
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error caching data: $e');
      }
      throw CacheException.writeError(key);
    }
  }

  Future<T?> get<T>(String key) async {
    try {
      final box = _getBox(_generalBox);
      final entryJson = box.get(key);

      if (entryJson == null) {
        return null;
      }

      final entry = CacheEntry.fromJson(entryJson);

      if (entry.isExpired) {
        await box.delete(key);
        return null;
      }

      return entry.data as T?;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting cached data: $e');
      }
      return null;
    }
  }

  // Cache Management
  Future<void> clearExpiredEntries() async {
    await _cleanupExpiredEntries();
  }

  Future<void> _cleanupExpiredEntries() async {
    try {
      for (final box in _boxes.values) {
        final keysToDelete = <dynamic>[];

        for (final key in box.keys) {
          try {
            final entryJson = box.get(key);
            if (entryJson == null) continue;

            final entry = CacheEntry.fromJson(entryJson);
            if (entry.isExpired) {
              keysToDelete.add(key);
            }
          } catch (e) {
            // Delete invalid entries
            keysToDelete.add(key);
          }
        }

        if (keysToDelete.isNotEmpty) {
          await box.deleteAll(keysToDelete);

          if (kDebugMode) {
            print(
              '✅ Cleaned up ${keysToDelete.length} expired entries from ${box.name}',
            );
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error cleaning up expired entries: $e');
      }
    }
  }

  Future<dynamic> getCachedData(String key) async {
    try {
      final box = _getBox(_generalBox);
      final entryJson = box.get(key);

      if (entryJson == null) {
        return null;
      }

      final entry = CacheEntry.fromJson(entryJson);

      if (entry.isExpired) {
        await box.delete(key);
        return null;
      }

      return entry.data;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting cached data: $e');
      }
      return null;
    }
  }

  Future<void> clearCache([String? boxName]) async {
    try {
      if (boxName != null) {
        final box = _getBox(boxName);
        await box.clear();

        if (kDebugMode) {
          print('✅ Cache cleared for box: $boxName');
        }
      } else {
        for (final box in _boxes.values) {
          await box.clear();
        }

        if (kDebugMode) {
          print('✅ All cache cleared');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error clearing cache: $e');
      }
    }
  }

  Future<void> deleteCacheEntry(String key, [String? boxName]) async {
    try {
      final box = _getBox(boxName ?? _generalBox);
      await box.delete(key);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error deleting cache entry: $e');
      }
    }
  }

  // Cache Statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final stats = <String, dynamic>{};
      int totalEntries = 0;
      int totalSize = 0;

      for (final entry in _boxes.entries) {
        final boxName = entry.key;
        final box = entry.value;

        int boxEntries = box.length;
        int boxSize = 0;

        // Estimate size (this is approximate)
        for (final key in box.keys) {
          try {
            final value = box.get(key);
            if (value != null) {
              boxSize += jsonEncode(value).length;
            }
          } catch (e) {
            // Skip invalid entries
          }
        }

        stats[boxName] = {
          'entries': boxEntries,
          'size_bytes': boxSize,
          'size_mb': (boxSize / (1024 * 1024)).toStringAsFixed(2),
        };

        totalEntries += boxEntries;
        totalSize += boxSize;
      }

      stats['total'] = {
        'entries': totalEntries,
        'size_bytes': totalSize,
        'size_mb': (totalSize / (1024 * 1024)).toStringAsFixed(2),
      };

      return stats;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting cache stats: $e');
      }
      return {};
    }
  }

  // Cache Size Management
  Future<void> limitCacheSize(int maxSizeBytes) async {
    try {
      final stats = await getCacheStats();
      final totalSize = stats['total']['size_bytes'] as int;

      if (totalSize > maxSizeBytes) {
        if (kDebugMode) {
          print('⚠️ Cache size limit exceeded: ${totalSize} > ${maxSizeBytes}');
        }

        // Start with media and files as they're usually largest
        await _cleanOldestEntries(_mediaBox, maxSizeBytes ~/ 4);
        await _cleanOldestEntries(_filesBox, maxSizeBytes ~/ 4);
        await _cleanOldestEntries(_messagesBox, maxSizeBytes ~/ 4);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error limiting cache size: $e');
      }
    }
  }

  Future<void> _cleanOldestEntries(String boxName, int maxSize) async {
    try {
      final box = _getBox(boxName);
      final entries = <MapEntry<dynamic, CacheEntry>>[];

      // Load all entries with timestamps
      for (final key in box.keys) {
        try {
          final entryJson = box.get(key);
          if (entryJson != null) {
            final entry = CacheEntry.fromJson(entryJson);
            entries.add(MapEntry(key, entry));
          }
        } catch (e) {
          // Delete invalid entries
          await box.delete(key);
        }
      }

      // Sort by timestamp (oldest first)
      entries.sort((a, b) => a.value.timestamp.compareTo(b.value.timestamp));

      // Calculate current size and remove oldest entries
      int currentSize = 0;
      final keysToDelete = <dynamic>[];

      for (final entry in entries) {
        final entrySize = jsonEncode(entry.value.toJson()).length;

        if (currentSize + entrySize > maxSize && entries.length > 1) {
          keysToDelete.add(entry.key);
        } else {
          currentSize += entrySize;
        }
      }

      if (keysToDelete.isNotEmpty) {
        await box.deleteAll(keysToDelete);

        if (kDebugMode) {
          print(
            '✅ Cleaned up ${keysToDelete.length} old entries from $boxName',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error cleaning oldest entries: $e');
      }
    }
  }

  Future<void> dispose() async {
    try {
      for (final box in _boxes.values) {
        if (box.isOpen) {
          await box.close();
        }
      }
      _boxes.clear();

      if (kDebugMode) {
        print('✅ Cache service disposed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error disposing cache service: $e');
      }
    }
  }
}

// Cache entry model
class CacheEntry {
  final dynamic data;
  final DateTime timestamp;
  final DateTime expiresAt;

  CacheEntry({
    required this.data,
    required this.timestamp,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
    };
  }

  factory CacheEntry.fromJson(Map<String, dynamic> json) {
    return CacheEntry(
      data: json['data'],
      timestamp: DateTime.parse(json['timestamp']),
      expiresAt: DateTime.parse(json['expires_at']),
    );
  }
}
