import 'dart:async';
import 'dart:io';
import 'package:bro_chat/models/file/file_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

import '../../services/api/api_service.dart';
import '../../services/storage/cache_service.dart';
import '../common/connectivity_provider.dart';
import 'file_provider.dart';

enum UploadStatus { queued, uploading, paused, completed, failed, cancelled }

enum UploadPriority { low, normal, high, urgent }

class UploadTask {
  final String id;
  final File file;
  final FilePurpose purpose;
  final String? chatId;
  final String? groupId;
  final bool public;
  final UploadStatus status;
  final UploadPriority priority;
  final double progress;
  final int uploadedBytes;
  final int totalBytes;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? error;
  final int retryCount;
  final Map<String, dynamic>? metadata;
  final CancelToken? cancelToken;
  final bool autoRetry;
  final Duration? estimatedTimeRemaining;
  final double? uploadSpeed; // bytes per second

  UploadTask({
    required this.id,
    required this.file,
    required this.purpose,
    this.chatId,
    this.groupId,
    this.public = false,
    this.status = UploadStatus.queued,
    this.priority = UploadPriority.normal,
    this.progress = 0.0,
    this.uploadedBytes = 0,
    this.totalBytes = 0,
    DateTime? createdAt,
    this.startedAt,
    this.completedAt,
    this.error,
    this.retryCount = 0,
    this.metadata,
    this.cancelToken,
    this.autoRetry = true,
    this.estimatedTimeRemaining,
    this.uploadSpeed,
  }) : createdAt = createdAt ?? DateTime.now();

  UploadTask copyWith({
    String? id,
    File? file,
    FilePurpose? purpose,
    String? chatId,
    String? groupId,
    bool? public,
    UploadStatus? status,
    UploadPriority? priority,
    double? progress,
    int? uploadedBytes,
    int? totalBytes,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
    String? error,
    int? retryCount,
    Map<String, dynamic>? metadata,
    CancelToken? cancelToken,
    bool? autoRetry,
    Duration? estimatedTimeRemaining,
    double? uploadSpeed,
  }) {
    return UploadTask(
      id: id ?? this.id,
      file: file ?? this.file,
      purpose: purpose ?? this.purpose,
      chatId: chatId ?? this.chatId,
      groupId: groupId ?? this.groupId,
      public: public ?? this.public,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      progress: progress ?? this.progress,
      uploadedBytes: uploadedBytes ?? this.uploadedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      error: error,
      retryCount: retryCount ?? this.retryCount,
      metadata: metadata ?? this.metadata,
      cancelToken: cancelToken ?? this.cancelToken,
      autoRetry: autoRetry ?? this.autoRetry,
      estimatedTimeRemaining:
          estimatedTimeRemaining ?? this.estimatedTimeRemaining,
      uploadSpeed: uploadSpeed ?? this.uploadSpeed,
    );
  }

  bool get isQueued => status == UploadStatus.queued;
  bool get isUploading => status == UploadStatus.uploading;
  bool get isPaused => status == UploadStatus.paused;
  bool get isCompleted => status == UploadStatus.completed;
  bool get isFailed => status == UploadStatus.failed;
  bool get isCancelled => status == UploadStatus.cancelled;
  bool get canRetry => isFailed && autoRetry && retryCount < 3;
  bool get canPause => isUploading;
  bool get canResume => isPaused;
  bool get canCancel => isQueued || isUploading || isPaused;

  String get fileName => file.path.split('/').last;
  String get fileSizeFormatted => _formatFileSize(totalBytes);
  String get uploadedSizeFormatted => _formatFileSize(uploadedBytes);
  double get progressPercentage => progress * 100;

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
      'file_path': file.path,
      'purpose': purpose.name,
      'chat_id': chatId,
      'group_id': groupId,
      'public': public,
      'status': status.name,
      'priority': priority.name,
      'progress': progress,
      'uploaded_bytes': uploadedBytes,
      'total_bytes': totalBytes,
      'created_at': createdAt.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'error': error,
      'retry_count': retryCount,
      'metadata': metadata,
      'auto_retry': autoRetry,
      'estimated_time_remaining': estimatedTimeRemaining?.inMilliseconds,
      'upload_speed': uploadSpeed,
    };
  }

  factory UploadTask.fromJson(Map<String, dynamic> json) {
    return UploadTask(
      id: json['id'] ?? '',
      file: File(json['file_path'] ?? ''),
      purpose: FilePurpose.values.firstWhere(
        (e) => e.name == json['purpose'],
        orElse: () => FilePurpose.other,
      ),
      chatId: json['chat_id'],
      groupId: json['group_id'],
      public: json['public'] ?? false,
      status: UploadStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => UploadStatus.queued,
      ),
      priority: UploadPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => UploadPriority.normal,
      ),
      progress: json['progress']?.toDouble() ?? 0.0,
      uploadedBytes: json['uploaded_bytes'] ?? 0,
      totalBytes: json['total_bytes'] ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      startedAt: json['started_at'] != null
          ? DateTime.tryParse(json['started_at'])
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'])
          : null,
      error: json['error'],
      retryCount: json['retry_count'] ?? 0,
      metadata: json['metadata'],
      autoRetry: json['auto_retry'] ?? true,
      estimatedTimeRemaining: json['estimated_time_remaining'] != null
          ? Duration(milliseconds: json['estimated_time_remaining'])
          : null,
      uploadSpeed: json['upload_speed']?.toDouble(),
    );
  }
}

class UploadState {
  final Map<String, UploadTask> tasks;
  final List<String> uploadQueue;
  final bool isUploading;
  final bool isPaused;
  final String? currentUploadId;
  final int maxConcurrentUploads;
  final bool wifiOnlyMode;
  final bool autoRetryEnabled;
  final bool isInitialized;
  final DateTime? lastUpdate;
  final Map<String, double> speedHistory;
  final int totalUploads;
  final int completedUploads;
  final int failedUploads;

  UploadState({
    this.tasks = const {},
    this.uploadQueue = const [],
    this.isUploading = false,
    this.isPaused = false,
    this.currentUploadId,
    this.maxConcurrentUploads = 3,
    this.wifiOnlyMode = false,
    this.autoRetryEnabled = true,
    this.isInitialized = false,
    this.lastUpdate,
    this.speedHistory = const {},
    this.totalUploads = 0,
    this.completedUploads = 0,
    this.failedUploads = 0,
  });

  UploadState copyWith({
    Map<String, UploadTask>? tasks,
    List<String>? uploadQueue,
    bool? isUploading,
    bool? isPaused,
    String? currentUploadId,
    int? maxConcurrentUploads,
    bool? wifiOnlyMode,
    bool? autoRetryEnabled,
    bool? isInitialized,
    DateTime? lastUpdate,
    Map<String, double>? speedHistory,
    int? totalUploads,
    int? completedUploads,
    int? failedUploads,
  }) {
    return UploadState(
      tasks: tasks ?? this.tasks,
      uploadQueue: uploadQueue ?? this.uploadQueue,
      isUploading: isUploading ?? this.isUploading,
      isPaused: isPaused ?? this.isPaused,
      currentUploadId: currentUploadId,
      maxConcurrentUploads: maxConcurrentUploads ?? this.maxConcurrentUploads,
      wifiOnlyMode: wifiOnlyMode ?? this.wifiOnlyMode,
      autoRetryEnabled: autoRetryEnabled ?? this.autoRetryEnabled,
      isInitialized: isInitialized ?? this.isInitialized,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      speedHistory: speedHistory ?? this.speedHistory,
      totalUploads: totalUploads ?? this.totalUploads,
      completedUploads: completedUploads ?? this.completedUploads,
      failedUploads: failedUploads ?? this.failedUploads,
    );
  }

  UploadTask? getTask(String taskId) => tasks[taskId];

  List<UploadTask> get allTasks => tasks.values.toList();
  List<UploadTask> get queuedTasks =>
      tasks.values.where((t) => t.isQueued).toList();
  List<UploadTask> get uploadingTasks =>
      tasks.values.where((t) => t.isUploading).toList();
  List<UploadTask> get pausedTasks =>
      tasks.values.where((t) => t.isPaused).toList();
  List<UploadTask> get completedTasks =>
      tasks.values.where((t) => t.isCompleted).toList();
  List<UploadTask> get failedTasks =>
      tasks.values.where((t) => t.isFailed).toList();
  List<UploadTask> get retryableTasks =>
      tasks.values.where((t) => t.canRetry).toList();

  int get activeUploadsCount => uploadingTasks.length;
  bool get hasQueuedTasks => queuedTasks.isNotEmpty;
  bool get hasFailedTasks => failedTasks.isNotEmpty;
  bool get hasRetryableTasks => retryableTasks.isNotEmpty;

  double get overallProgress {
    if (tasks.isEmpty) return 0.0;
    final totalProgress = tasks.values.fold(
      0.0,
      (sum, task) => sum + task.progress,
    );
    return totalProgress / tasks.length;
  }

  double get averageUploadSpeed {
    if (speedHistory.isEmpty) return 0.0;
    final totalSpeed = speedHistory.values.fold(
      0.0,
      (sum, speed) => sum + speed,
    );
    return totalSpeed / speedHistory.length;
  }
}

class UploadNotifier extends StateNotifier<AsyncValue<UploadState>> {
  final ApiService _apiService;
  final CacheService _cacheService;
  final ConnectivityNotifier _connectivityNotifier;

  Timer? _uploadProcessor;
  Timer? _speedCalculator;
  final Map<String, DateTime> _uploadStartTimes = {};
  final Map<String, int> _lastUploadedBytes = {};

  static const Duration _processingInterval = Duration(milliseconds: 500);
  static const Duration _speedCalculationInterval = Duration(seconds: 2);

  UploadNotifier({
    required ApiService apiService,
    required CacheService cacheService,
    required ConnectivityNotifier connectivityNotifier,
  }) : _apiService = apiService,
       _cacheService = cacheService,
       _connectivityNotifier = connectivityNotifier,
       super(AsyncValue.data(UploadState())) {
    _initialize();
  }

  void _initialize() async {
    try {
      await _loadPendingUploads();
      _startUploadProcessor();
      _startSpeedCalculator();

      state = AsyncValue.data(
        state.value!.copyWith(isInitialized: true, lastUpdate: DateTime.now()),
      );

      if (kDebugMode) print('✅ Upload provider initialized');
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      if (kDebugMode) print('❌ Error initializing upload provider: $e');
    }
  }

  Future<void> _loadPendingUploads() async {
    try {
      final pendingUploads = await _cacheService.getPendingUploads();
      final tasks = <String, UploadTask>{};
      final queue = <String>[];

      for (final uploadData in pendingUploads) {
        final task = UploadTask.fromJson(uploadData);
        tasks[task.id] = task;

        if (task.isQueued || task.isPaused) {
          queue.add(task.id);
        }
      }

      // Sort queue by priority and creation time
      queue.sort((a, b) {
        final taskA = tasks[a]!;
        final taskB = tasks[b]!;

        // First sort by priority
        final priorityComparison = taskB.priority.index.compareTo(
          taskA.priority.index,
        );
        if (priorityComparison != 0) return priorityComparison;

        // Then by creation time
        return taskA.createdAt.compareTo(taskB.createdAt);
      });

      state = AsyncValue.data(
        state.value!.copyWith(
          tasks: tasks,
          uploadQueue: queue,
          totalUploads: tasks.length,
          completedUploads: tasks.values.where((t) => t.isCompleted).length,
          failedUploads: tasks.values.where((t) => t.isFailed).length,
        ),
      );
    } catch (e) {
      if (kDebugMode) print('❌ Error loading pending uploads: $e');
    }
  }

  void _startUploadProcessor() {
    _uploadProcessor = Timer.periodic(_processingInterval, (_) {
      _processUploadQueue();
    });
  }

  void _startSpeedCalculator() {
    _speedCalculator = Timer.periodic(_speedCalculationInterval, (_) {
      _calculateUploadSpeeds();
    });
  }

  Future<void> _processUploadQueue() async {
    final currentState = state.value!;

    // Check if we can start more uploads
    if (currentState.isPaused ||
        currentState.activeUploadsCount >= currentState.maxConcurrentUploads ||
        !currentState.hasQueuedTasks) {
      return;
    }

    // Check connectivity
    final isConnected = _connectivityNotifier.state.isConnected;
    if (!isConnected) return;

    // Check WiFi-only mode
    if (currentState.wifiOnlyMode &&
        _connectivityNotifier.state.type != ConnectivityType.wifi) {
      return;
    }

    // Get next task to upload
    final nextTaskId = currentState.uploadQueue.first;
    final nextTask = currentState.tasks[nextTaskId];

    if (nextTask != null && nextTask.isQueued) {
      await _startUpload(nextTask);
    }
  }

  void _calculateUploadSpeeds() {
    state.whenData((uploadState) {
      final updatedTasks = <String, UploadTask>{};
      final updatedSpeedHistory = Map<String, double>.from(
        uploadState.speedHistory,
      );

      for (final task in uploadState.uploadingTasks) {
        final lastBytes = _lastUploadedBytes[task.id] ?? 0;
        final currentBytes = task.uploadedBytes;
        final bytesDiff = currentBytes - lastBytes;

        if (bytesDiff > 0) {
          final speed = bytesDiff / _speedCalculationInterval.inSeconds;
          updatedSpeedHistory[task.id] = speed;

          // Calculate estimated time remaining
          final remainingBytes = task.totalBytes - currentBytes;
          final estimatedTime = speed > 0
              ? Duration(seconds: (remainingBytes / speed).round())
              : null;

          updatedTasks[task.id] = task.copyWith(
            uploadSpeed: speed,
            estimatedTimeRemaining: estimatedTime,
          );
        }

        _lastUploadedBytes[task.id] = currentBytes;
      }

      if (updatedTasks.isNotEmpty) {
        state = AsyncValue.data(
          uploadState.copyWith(
            tasks: {...uploadState.tasks, ...updatedTasks},
            speedHistory: updatedSpeedHistory,
            lastUpdate: DateTime.now(),
          ),
        );
      }
    });
  }

  // Public methods
  Future<String> addUpload({
    required File file,
    required FilePurpose purpose,
    String? chatId,
    String? groupId,
    bool public = false,
    UploadPriority priority = UploadPriority.normal,
    bool autoRetry = true,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final taskId = DateTime.now().millisecondsSinceEpoch.toString();
      final fileSize = await file.length();

      final task = UploadTask(
        id: taskId,
        file: file,
        purpose: purpose,
        chatId: chatId,
        groupId: groupId,
        public: public,
        priority: priority,
        totalBytes: fileSize,
        autoRetry: autoRetry,
        metadata: metadata,
      );

      state.whenData((uploadState) {
        final updatedTasks = Map<String, UploadTask>.from(uploadState.tasks);
        updatedTasks[taskId] = task;

        final updatedQueue = List<String>.from(uploadState.uploadQueue);

        // Insert based on priority
        int insertIndex = updatedQueue.length;
        for (int i = 0; i < updatedQueue.length; i++) {
          final existingTask = updatedTasks[updatedQueue[i]]!;
          if (task.priority.index > existingTask.priority.index) {
            insertIndex = i;
            break;
          }
        }
        updatedQueue.insert(insertIndex, taskId);

        state = AsyncValue.data(
          uploadState.copyWith(
            tasks: updatedTasks,
            uploadQueue: updatedQueue,
            totalUploads: updatedTasks.length,
            lastUpdate: DateTime.now(),
          ),
        );
      });

      await _cacheUploadTask(task);

      if (kDebugMode) print('➕ Upload task added: ${task.fileName}');
      return taskId;
    } catch (e) {
      if (kDebugMode) print('❌ Error adding upload: $e');
      rethrow;
    }
  }

  Future<void> _startUpload(UploadTask task) async {
    try {
      final cancelToken = CancelToken();
      _uploadStartTimes[task.id] = DateTime.now();

      final updatedTask = task.copyWith(
        status: UploadStatus.uploading,
        startedAt: DateTime.now(),
        cancelToken: cancelToken,
      );

      _updateTask(updatedTask);

      final response = await _apiService.uploadFile(
        file: task.file,
        purpose: task.purpose.name,
        chatId: task.chatId,
        public: task.public,
        onProgress: (sent, total) {
          _updateUploadProgress(task.id, sent, total);
        },
      );

      if (response.success && response.data != null) {
        final completedTask = updatedTask.copyWith(
          status: UploadStatus.completed,
          progress: 1.0,
          uploadedBytes: task.totalBytes,
          completedAt: DateTime.now(),
        );

        _updateTask(completedTask);
        _removeFromQueue(task.id);

        if (kDebugMode) print('✅ Upload completed: ${task.fileName}');
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      await _handleUploadError(task.id, e);
    }
  }

  Future<void> _handleUploadError(String taskId, dynamic error) async {
    final task = state.value!.tasks[taskId];
    if (task == null) return;

    final shouldRetry =
        task.autoRetry &&
        task.retryCount < 3 &&
        !error.toString().contains('cancelled');

    if (shouldRetry) {
      // Retry after delay
      final retryDelay = Duration(seconds: (task.retryCount + 1) * 2);

      final retryTask = task.copyWith(
        status: UploadStatus.queued,
        retryCount: task.retryCount + 1,
        error: error.toString(),
      );

      _updateTask(retryTask);

      Timer(retryDelay, () {
        state.whenData((uploadState) {
          final updatedQueue = List<String>.from(uploadState.uploadQueue);
          if (!updatedQueue.contains(taskId)) {
            updatedQueue.insert(0, taskId); // High priority for retries
            state = AsyncValue.data(
              uploadState.copyWith(uploadQueue: updatedQueue),
            );
          }
        });
      });

      if (kDebugMode) {
        print(
          '🔄 Upload retry scheduled: ${task.fileName} (attempt ${task.retryCount + 1})',
        );
      }
    } else {
      final failedTask = task.copyWith(
        status: UploadStatus.failed,
        error: error.toString(),
      );

      _updateTask(failedTask);
      _removeFromQueue(taskId);

      if (kDebugMode) print('❌ Upload failed: ${task.fileName} - $error');
    }
  }

  void _updateUploadProgress(String taskId, int sent, int total) {
    final progress = total > 0 ? sent / total : 0.0;

    state.whenData((uploadState) {
      final task = uploadState.tasks[taskId];
      if (task != null && task.isUploading) {
        final updatedTask = task.copyWith(
          progress: progress,
          uploadedBytes: sent,
        );

        final updatedTasks = Map<String, UploadTask>.from(uploadState.tasks);
        updatedTasks[taskId] = updatedTask;

        state = AsyncValue.data(
          uploadState.copyWith(tasks: updatedTasks, lastUpdate: DateTime.now()),
        );
      }
    });
  }

  void _updateTask(UploadTask task) {
    state.whenData((uploadState) {
      final updatedTasks = Map<String, UploadTask>.from(uploadState.tasks);
      updatedTasks[task.id] = task;

      final completedCount = updatedTasks.values
          .where((t) => t.isCompleted)
          .length;
      final failedCount = updatedTasks.values.where((t) => t.isFailed).length;

      state = AsyncValue.data(
        uploadState.copyWith(
          tasks: updatedTasks,
          completedUploads: completedCount,
          failedUploads: failedCount,
          lastUpdate: DateTime.now(),
        ),
      );
    });

    _cacheUploadTask(task);
  }

  void _removeFromQueue(String taskId) {
    state.whenData((uploadState) {
      final updatedQueue = List<String>.from(uploadState.uploadQueue);
      updatedQueue.remove(taskId);

      state = AsyncValue.data(
        uploadState.copyWith(
          uploadQueue: updatedQueue,
          isUploading: updatedQueue.isNotEmpty,
        ),
      );
    });
  }

  Future<void> pauseUpload(String taskId) async {
    final task = state.value!.tasks[taskId];
    if (task == null || !task.canPause) return;

    try {
      task.cancelToken?.cancel('Upload paused by user');

      final pausedTask = task.copyWith(status: UploadStatus.paused);

      _updateTask(pausedTask);

      if (kDebugMode) print('⏸️ Upload paused: ${task.fileName}');
    } catch (e) {
      if (kDebugMode) print('❌ Error pausing upload: $e');
    }
  }

  Future<void> resumeUpload(String taskId) async {
    final task = state.value!.tasks[taskId];
    if (task == null || !task.canResume) return;

    try {
      final resumedTask = task.copyWith(status: UploadStatus.queued);

      _updateTask(resumedTask);

      state.whenData((uploadState) {
        final updatedQueue = List<String>.from(uploadState.uploadQueue);
        if (!updatedQueue.contains(taskId)) {
          updatedQueue.insert(0, taskId); // High priority for resumed uploads
          state = AsyncValue.data(
            uploadState.copyWith(uploadQueue: updatedQueue),
          );
        }
      });

      if (kDebugMode) print('▶️ Upload resumed: ${task.fileName}');
    } catch (e) {
      if (kDebugMode) print('❌ Error resuming upload: $e');
    }
  }

  Future<void> cancelUpload(String taskId) async {
    final task = state.value!.tasks[taskId];
    if (task == null || !task.canCancel) return;

    try {
      task.cancelToken?.cancel('Upload cancelled by user');

      final cancelledTask = task.copyWith(status: UploadStatus.cancelled);

      _updateTask(cancelledTask);
      _removeFromQueue(taskId);

      if (kDebugMode) print('❌ Upload cancelled: ${task.fileName}');
    } catch (e) {
      if (kDebugMode) print('❌ Error cancelling upload: $e');
    }
  }

  Future<void> retryUpload(String taskId) async {
    final task = state.value!.tasks[taskId];
    if (task == null || !task.canRetry) return;

    await resumeUpload(taskId);
  }

  Future<void> retryAllFailed() async {
    final failedTasks = state.value!.failedTasks;

    for (final task in failedTasks) {
      if (task.canRetry) {
        await retryUpload(task.id);
      }
    }

    if (kDebugMode) print('🔄 Retrying ${failedTasks.length} failed uploads');
  }

  Future<void> pauseAllUploads() async {
    state.whenData((uploadState) {
      state = AsyncValue.data(uploadState.copyWith(isPaused: true));
    });

    final uploadingTasks = state.value!.uploadingTasks;
    for (final task in uploadingTasks) {
      await pauseUpload(task.id);
    }

    if (kDebugMode) print('⏸️ All uploads paused');
  }

  Future<void> resumeAllUploads() async {
    state.whenData((uploadState) {
      state = AsyncValue.data(uploadState.copyWith(isPaused: false));
    });

    if (kDebugMode) print('▶️ All uploads resumed');
  }

  Future<void> clearCompleted() async {
    state.whenData((uploadState) {
      final updatedTasks = Map<String, UploadTask>.from(uploadState.tasks);
      final completedTaskIds = <String>[];

      updatedTasks.removeWhere((key, task) {
        if (task.isCompleted) {
          completedTaskIds.add(key);
          return true;
        }
        return false;
      });

      state = AsyncValue.data(
        uploadState.copyWith(
          tasks: updatedTasks,
          totalUploads: updatedTasks.length,
          completedUploads: 0,
        ),
      );
    });

    if (kDebugMode) print('🧹 Cleared completed uploads');
  }

  Future<void> updateSettings({
    int? maxConcurrentUploads,
    bool? wifiOnlyMode,
    bool? autoRetryEnabled,
  }) async {
    state.whenData((uploadState) {
      state = AsyncValue.data(
        uploadState.copyWith(
          maxConcurrentUploads:
              maxConcurrentUploads ?? uploadState.maxConcurrentUploads,
          wifiOnlyMode: wifiOnlyMode ?? uploadState.wifiOnlyMode,
          autoRetryEnabled: autoRetryEnabled ?? uploadState.autoRetryEnabled,
        ),
      );
    });

    if (kDebugMode) print('⚙️ Upload settings updated');
  }

  Future<void> _cacheUploadTask(UploadTask task) async {
    try {
      await _cacheService.cacheUploadTask(task.id, task.toJson());
    } catch (e) {
      if (kDebugMode) print('❌ Error caching upload task: $e');
    }
  }

  // Getters
  Map<String, UploadTask> get tasks => state.value?.tasks ?? {};
  bool get isUploading => state.value?.isUploading ?? false;
  bool get isPaused => state.value?.isPaused ?? false;
  int get totalUploads => state.value?.totalUploads ?? 0;
  int get completedUploads => state.value?.completedUploads ?? 0;
  int get failedUploads => state.value?.failedUploads ?? 0;
  List<UploadTask> get queuedTasks => state.value?.queuedTasks ?? [];
  List<UploadTask> get uploadingTasks => state.value?.uploadingTasks ?? [];
  List<UploadTask> get failedTasks => state.value?.failedTasks ?? [];
  double get overallProgress => state.value?.overallProgress ?? 0.0;

  @override
  void dispose() {
    _uploadProcessor?.cancel();
    _speedCalculator?.cancel();

    // Cancel all ongoing uploads
    final uploadingTasks = state.value?.uploadingTasks ?? [];
    for (final task in uploadingTasks) {
      task.cancelToken?.cancel('Provider disposed');
    }

    super.dispose();
  }
}

// Providers
final uploadProvider =
    StateNotifierProvider<UploadNotifier, AsyncValue<UploadState>>((ref) {
      return UploadNotifier(
        apiService: ref.watch(apiServiceProvider),
        cacheService: CacheService(),
        connectivityNotifier: ref.watch(connectivityProvider.notifier),
      );
    });

// Convenience providers
final uploadTasksProvider = Provider<Map<String, UploadTask>>((ref) {
  final uploadState = ref.watch(uploadProvider);
  return uploadState.whenOrNull(data: (state) => state.tasks) ?? {};
});

final isUploadingProvider = Provider<bool>((ref) {
  final uploadState = ref.watch(uploadProvider);
  return uploadState.whenOrNull(data: (state) => state.isUploading) ?? false;
});

final uploadTaskProvider = Provider.family<UploadTask?, String>((ref, taskId) {
  final tasks = ref.watch(uploadTasksProvider);
  return tasks[taskId];
});

final queuedUploadsProvider = Provider<List<UploadTask>>((ref) {
  final uploadState = ref.watch(uploadProvider);
  return uploadState.whenOrNull(data: (state) => state.queuedTasks) ?? [];
});

final activeUploadsProvider = Provider<List<UploadTask>>((ref) {
  final uploadState = ref.watch(uploadProvider);
  return uploadState.whenOrNull(data: (state) => state.uploadingTasks) ?? [];
});

final failedUploadsProvider = Provider<List<UploadTask>>((ref) {
  final uploadState = ref.watch(uploadProvider);
  return uploadState.whenOrNull(data: (state) => state.failedTasks) ?? [];
});

final uploadProgressProvider = Provider<double>((ref) {
  final uploadState = ref.watch(uploadProvider);
  return uploadState.whenOrNull(data: (state) => state.overallProgress) ?? 0.0;
});

final uploadStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final uploadState = ref.watch(uploadProvider);
  return uploadState.whenOrNull(
        data: (state) => {
          'total': state.totalUploads,
          'completed': state.completedUploads,
          'failed': state.failedUploads,
          'active': state.activeUploadsCount,
          'queued': state.queuedTasks.length,
          'average_speed': state.averageUploadSpeed,
        },
      ) ??
      {};
});
