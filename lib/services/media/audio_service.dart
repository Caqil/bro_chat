import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sound/flutter_sound.dart' hide PlayerState;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../core/exceptions/app_exception.dart';
import '../../core/config/app_config.dart';
import '../storage/cache_service.dart';
import '../storage/local_storage.dart';

enum AudioServiceState {
  idle,
  initializing,
  initialized,
  recording,
  playing,
  paused,
  stopped,
  error,
}

enum AudioFormat { aac, mp3, wav, opus, flac }

enum AudioQuality { low, medium, high, veryHigh }

class AudioRecordingInfo {
  final String id;
  final String filePath;
  final Duration duration;
  final int fileSize;
  final AudioFormat format;
  final int sampleRate;
  final int bitRate;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  AudioRecordingInfo({
    required this.id,
    required this.filePath,
    required this.duration,
    required this.fileSize,
    required this.format,
    required this.sampleRate,
    required this.bitRate,
    required this.createdAt,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'file_path': filePath,
      'duration_ms': duration.inMilliseconds,
      'file_size': fileSize,
      'format': format.name,
      'sample_rate': sampleRate,
      'bit_rate': bitRate,
      'created_at': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory AudioRecordingInfo.fromJson(Map<String, dynamic> json) {
    return AudioRecordingInfo(
      id: json['id'],
      filePath: json['file_path'],
      duration: Duration(milliseconds: json['duration_ms']),
      fileSize: json['file_size'],
      format: AudioFormat.values.firstWhere(
        (f) => f.name == json['format'],
        orElse: () => AudioFormat.aac,
      ),
      sampleRate: json['sample_rate'],
      bitRate: json['bit_rate'],
      createdAt: DateTime.parse(json['created_at']),
      metadata: json['metadata'],
    );
  }
}

class AudioPlayerInfo {
  final String id;
  final String filePath;
  final Duration duration;
  final Duration position;
  final double volume;
  final bool isPlaying;
  final bool isPaused;
  final bool isCompleted;

  AudioPlayerInfo({
    required this.id,
    required this.filePath,
    required this.duration,
    required this.position,
    required this.volume,
    required this.isPlaying,
    required this.isPaused,
    required this.isCompleted,
  });

  AudioPlayerInfo copyWith({
    String? id,
    String? filePath,
    Duration? duration,
    Duration? position,
    double? volume,
    bool? isPlaying,
    bool? isPaused,
    bool? isCompleted,
  }) {
    return AudioPlayerInfo(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      duration: duration ?? this.duration,
      position: position ?? this.position,
      volume: volume ?? this.volume,
      isPlaying: isPlaying ?? this.isPlaying,
      isPaused: isPaused ?? this.isPaused,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class AudioService {
  static AudioService? _instance;

  final CacheService _cacheService;
  final LocalStorage _localStorage;

  // Flutter Sound components
  FlutterSoundRecorder? _recorder;
  FlutterSoundPlayer? _player;

  // Additional audio players for concurrent playback
  final Map<String, AudioPlayer> _audioPlayers = {};

  // Service state
  AudioServiceState _state = AudioServiceState.idle;
  bool _isInitialized = false;

  // Recording state
  AudioRecordingInfo? _currentRecording;
  String? _recordingPath;
  Timer? _recordingTimer;
  Duration _recordingDuration = Duration.zero;

  // Playback state
  final Map<String, AudioPlayerInfo> _playbackInfos = {};

  // Settings
  AudioFormat _recordingFormat = AudioFormat.aac;
  AudioQuality _recordingQuality = AudioQuality.medium;
  double _playbackVolume = 1.0;
  double _recordingGain = 1.0;
  bool _enableNoiseReduction = true;
  bool _enableEchoCancellation = true;

  // Event streams
  final StreamController<AudioServiceState> _stateController =
      StreamController<AudioServiceState>.broadcast();
  final StreamController<AudioRecordingInfo> _recordingController =
      StreamController<AudioRecordingInfo>.broadcast();
  final StreamController<AudioPlayerInfo> _playbackController =
      StreamController<AudioPlayerInfo>.broadcast();
  final StreamController<Duration> _recordingDurationController =
      StreamController<Duration>.broadcast();

  // Recording history
  final List<AudioRecordingInfo> _recordingHistory = [];
  static const int _maxHistoryItems = 50;

  AudioService._internal()
    : _cacheService = CacheService(),
      _localStorage = LocalStorage() {
    _initialize();
  }

  factory AudioService() {
    _instance ??= AudioService._internal();
    return _instance!;
  }

  // Getters
  AudioServiceState get state => _state;
  bool get isInitialized => _isInitialized;
  bool get isRecording => _state == AudioServiceState.recording;
  bool get isPlaying => _state == AudioServiceState.playing;
  AudioRecordingInfo? get currentRecording => _currentRecording;
  Duration get recordingDuration => _recordingDuration;
  List<AudioRecordingInfo> get recordingHistory =>
      List.unmodifiable(_recordingHistory);

  // Streams
  Stream<AudioServiceState> get stateStream => _stateController.stream;
  Stream<AudioRecordingInfo> get recordingUpdates =>
      _recordingController.stream;
  Stream<AudioPlayerInfo> get playbackUpdates => _playbackController.stream;
  Stream<Duration> get recordingDurationStream =>
      _recordingDurationController.stream;

  void _initialize() {
    _loadSettings();
    _loadRecordingHistory();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = _localStorage.getMap('audio_settings');
      if (settings != null) {
        _recordingFormat = AudioFormat.values.firstWhere(
          (f) => f.name == settings['recording_format'],
          orElse: () => AudioFormat.aac,
        );
        _recordingQuality = AudioQuality.values.firstWhere(
          (q) => q.name == settings['recording_quality'],
          orElse: () => AudioQuality.medium,
        );
        _playbackVolume = settings['playback_volume']?.toDouble() ?? 1.0;
        _recordingGain = settings['recording_gain']?.toDouble() ?? 1.0;
        _enableNoiseReduction = settings['enable_noise_reduction'] ?? true;
        _enableEchoCancellation = settings['enable_echo_cancellation'] ?? true;
      }

      if (kDebugMode) {
        print('✅ Audio settings loaded');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading audio settings: $e');
      }
    }
  }

  Future<void> _saveSettings() async {
    try {
      final settings = {
        'recording_format': _recordingFormat.name,
        'recording_quality': _recordingQuality.name,
        'playback_volume': _playbackVolume,
        'recording_gain': _recordingGain,
        'enable_noise_reduction': _enableNoiseReduction,
        'enable_echo_cancellation': _enableEchoCancellation,
      };

      await _localStorage.setMap('audio_settings', settings);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving audio settings: $e');
      }
    }
  }

  Future<void> _loadRecordingHistory() async {
    try {
      final history = await _cacheService.getCachedData('audio_recordings');
      if (history != null && history is List) {
        _recordingHistory.clear();
        for (final item in history) {
          _recordingHistory.add(AudioRecordingInfo.fromJson(item));
        }
      }

      if (kDebugMode) {
        print(
          '✅ Audio recording history loaded: ${_recordingHistory.length} items',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading recording history: $e');
      }
    }
  }

  Future<void> _saveRecordingHistory() async {
    try {
      final historyData = _recordingHistory.map((r) => r.toJson()).toList();
      await _cacheService.cache('audio_recordings', historyData);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving recording history: $e');
      }
    }
  }

  void _setState(AudioServiceState newState) {
    if (_state != newState) {
      _state = newState;
      _stateController.add(newState);

      if (kDebugMode) {
        print('🎵 Audio service state: ${newState.name}');
      }
    }
  }

  // Public API

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _setState(AudioServiceState.initializing);

      // Initialize recorder
      _recorder = FlutterSoundRecorder();
      await _recorder!.openRecorder();

      // Initialize player
      _player = FlutterSoundPlayer();
      await _player!.openPlayer();

      // Set up player callbacks
      _player!.onProgress!.listen((event) {
        // Handle playback progress
      });

      _isInitialized = true;
      _setState(AudioServiceState.initialized);

      if (kDebugMode) {
        print('✅ Audio service initialized');
      }
    } catch (e) {
      _setState(AudioServiceState.error);

      if (kDebugMode) {
        print('❌ Error initializing audio service: $e');
      }

      throw MediaException.recordingFailed();
    }
  }

  Future<bool> checkMicrophonePermission() async {
    try {
      final status = await Permission.microphone.status;
      return status.isGranted;
    } catch (e) {
      return false;
    }
  }

  Future<bool> requestMicrophonePermission() async {
    try {
      final status = await Permission.microphone.request();
      return status.isGranted;
    } catch (e) {
      return false;
    }
  }

  Future<void> startRecording({
    String? fileName,
    AudioFormat? format,
    AudioQuality? quality,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      if (_state == AudioServiceState.recording) {
        throw Exception('Already recording');
      }

      // Check microphone permission
      if (!await checkMicrophonePermission()) {
        final granted = await requestMicrophonePermission();
        if (!granted) {
          throw PermissionException.microphone();
        }
      }

      // Generate recording path
      final recordingFormat = format ?? _recordingFormat;
      final recordingQuality = quality ?? _recordingQuality;

      _recordingPath = await _generateRecordingPath(fileName, recordingFormat);

      // Configure recording settings
      final codec = _getCodecFromFormat(recordingFormat);
      final bitRate = _getBitRateFromQuality(recordingQuality);
      final sampleRate = _getSampleRateFromQuality(recordingQuality);

      // Start recording
      await _recorder!.startRecorder(
        toFile: _recordingPath,
        codec: codec,
        bitRate: bitRate,
        sampleRate: sampleRate,
      );

      _setState(AudioServiceState.recording);
      _recordingDuration = Duration.zero;

      // Start recording timer
      _startRecordingTimer();

      if (kDebugMode) {
        print('🎤 Recording started: $_recordingPath');
      }
    } catch (e) {
      _setState(AudioServiceState.error);

      if (kDebugMode) {
        print('❌ Error starting recording: $e');
      }

      if (e is PermissionException) {
        rethrow;
      } else {
        throw MediaException.recordingFailed();
      }
    }
  }

  Future<AudioRecordingInfo?> stopRecording() async {
    try {
      if (_state != AudioServiceState.recording) {
        return null;
      }

      // Stop recording
      final recordingPath = await _recorder!.stopRecorder();
      _stopRecordingTimer();

      if (recordingPath == null || !File(recordingPath).existsSync()) {
        throw Exception('Recording file not found');
      }

      // Get file info
      final file = File(recordingPath);
      final fileSize = await file.length();

      // Create recording info
      final recordingInfo = AudioRecordingInfo(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        filePath: recordingPath,
        duration: _recordingDuration,
        fileSize: fileSize,
        format: _recordingFormat,
        sampleRate: _getSampleRateFromQuality(_recordingQuality),
        bitRate: _getBitRateFromQuality(_recordingQuality),
        createdAt: DateTime.now(),
      );

      _currentRecording = recordingInfo;
      _addToHistory(recordingInfo);

      _setState(AudioServiceState.initialized);
      _recordingController.add(recordingInfo);

      if (kDebugMode) {
        print('🎤 Recording completed: ${recordingInfo.duration}');
      }

      return recordingInfo;
    } catch (e) {
      _setState(AudioServiceState.error);

      if (kDebugMode) {
        print('❌ Error stopping recording: $e');
      }

      throw MediaException.recordingFailed();
    }
  }

  Future<void> cancelRecording() async {
    try {
      if (_state != AudioServiceState.recording) {
        return;
      }

      await _recorder!.stopRecorder();
      _stopRecordingTimer();

      // Delete the recording file
      if (_recordingPath != null && File(_recordingPath!).existsSync()) {
        await File(_recordingPath!).delete();
      }

      _setState(AudioServiceState.initialized);
      _recordingDuration = Duration.zero;

      if (kDebugMode) {
        print('🎤 Recording cancelled');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error cancelling recording: $e');
      }
    }
  }

  Future<void> playAudio(String filePath, {String? playerId}) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      final id = playerId ?? 'default';

      // Stop any existing playback for this player
      await stopAudio(id);

      // Create or get audio player
      AudioPlayer audioPlayer;
      if (_audioPlayers.containsKey(id)) {
        audioPlayer = _audioPlayers[id]!;
      } else {
        audioPlayer = AudioPlayer();
        _audioPlayers[id] = audioPlayer;

        // Set up player listeners
        _setupAudioPlayerListeners(audioPlayer, id, filePath);
      }

      // Start playback
      await audioPlayer.play(DeviceFileSource(filePath));
      await audioPlayer.setVolume(_playbackVolume);

      _setState(AudioServiceState.playing);

      if (kDebugMode) {
        print('🔊 Audio playback started: $filePath');
      }
    } catch (e) {
      _setState(AudioServiceState.error);

      if (kDebugMode) {
        print('❌ Error playing audio: $e');
      }

      throw MediaException.playbackFailed();
    }
  }

  Future<void> pauseAudio(String playerId) async {
    try {
      final audioPlayer = _audioPlayers[playerId];
      if (audioPlayer != null) {
        await audioPlayer.pause();
        _setState(AudioServiceState.paused);

        if (kDebugMode) {
          print('⏸️ Audio playback paused: $playerId');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error pausing audio: $e');
      }
    }
  }

  Future<void> resumeAudio(String playerId) async {
    try {
      final audioPlayer = _audioPlayers[playerId];
      if (audioPlayer != null) {
        await audioPlayer.resume();
        _setState(AudioServiceState.playing);

        if (kDebugMode) {
          print('▶️ Audio playback resumed: $playerId');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error resuming audio: $e');
      }
    }
  }

  Future<void> stopAudio(String playerId) async {
    try {
      final audioPlayer = _audioPlayers[playerId];
      if (audioPlayer != null) {
        await audioPlayer.stop();

        if (_audioPlayers.length == 1) {
          _setState(AudioServiceState.initialized);
        }

        if (kDebugMode) {
          print('⏹️ Audio playback stopped: $playerId');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error stopping audio: $e');
      }
    }
  }

  Future<void> seekAudio(String playerId, Duration position) async {
    try {
      final audioPlayer = _audioPlayers[playerId];
      if (audioPlayer != null) {
        await audioPlayer.seek(position);

        if (kDebugMode) {
          print('⏭️ Audio seek: $playerId to ${position.inSeconds}s');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error seeking audio: $e');
      }
    }
  }

  Future<void> setVolume(double volume, {String? playerId}) async {
    try {
      final clampedVolume = volume.clamp(0.0, 1.0);

      if (playerId != null) {
        final audioPlayer = _audioPlayers[playerId];
        if (audioPlayer != null) {
          await audioPlayer.setVolume(clampedVolume);
        }
      } else {
        _playbackVolume = clampedVolume;
        for (final audioPlayer in _audioPlayers.values) {
          await audioPlayer.setVolume(clampedVolume);
        }
        await _saveSettings();
      }

      if (kDebugMode) {
        print('🔊 Volume set to: ${(clampedVolume * 100).round()}%');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error setting volume: $e');
      }
    }
  }

  void _setupAudioPlayerListeners(
    AudioPlayer player,
    String id,
    String filePath,
  ) {
    player.onDurationChanged.listen((duration) {
      _updatePlaybackInfo(id, filePath, duration: duration);
    });

    player.onPositionChanged.listen((position) {
      _updatePlaybackInfo(id, filePath, position: position);
    });

    player.onPlayerStateChanged.listen((state) {
      final isPlaying = state == PlayerState.playing;
      final isPaused = state == PlayerState.paused;
      final isCompleted = state == PlayerState.completed;

      _updatePlaybackInfo(
        id,
        filePath,
        isPlaying: isPlaying,
        isPaused: isPaused,
        isCompleted: isCompleted,
      );

      if (isCompleted) {
        _setState(AudioServiceState.initialized);
      }
    });
  }

  void _updatePlaybackInfo(
    String id,
    String filePath, {
    Duration? duration,
    Duration? position,
    bool? isPlaying,
    bool? isPaused,
    bool? isCompleted,
  }) {
    final currentInfo =
        _playbackInfos[id] ??
        AudioPlayerInfo(
          id: id,
          filePath: filePath,
          duration: Duration.zero,
          position: Duration.zero,
          volume: _playbackVolume,
          isPlaying: false,
          isPaused: false,
          isCompleted: false,
        );

    final updatedInfo = currentInfo.copyWith(
      duration: duration,
      position: position,
      isPlaying: isPlaying,
      isPaused: isPaused,
      isCompleted: isCompleted,
    );

    _playbackInfos[id] = updatedInfo;
    _playbackController.add(updatedInfo);
  }

  void _startRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(milliseconds: 100), (
      timer,
    ) {
      _recordingDuration += const Duration(milliseconds: 100);
      _recordingDurationController.add(_recordingDuration);
    });
  }

  void _stopRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
  }

  Future<String> _generateRecordingPath(
    String? fileName,
    AudioFormat format,
  ) async {
    final directory = await getApplicationDocumentsDirectory();
    final recordingsDir = Directory('${directory.path}/recordings');

    if (!await recordingsDir.exists()) {
      await recordingsDir.create(recursive: true);
    }

    final name =
        fileName ?? 'recording_${DateTime.now().millisecondsSinceEpoch}';
    final extension = _getFileExtension(format);

    return '${recordingsDir.path}/$name.$extension';
  }

  Codec _getCodecFromFormat(AudioFormat format) {
    switch (format) {
      case AudioFormat.aac:
        return Codec.aacADTS;
      case AudioFormat.mp3:
        return Codec.mp3;
      case AudioFormat.wav:
        return Codec.pcm16WAV;
      case AudioFormat.opus:
        return Codec.opusOGG;
      case AudioFormat.flac:
        return Codec.flac;
    }
  }

  String _getFileExtension(AudioFormat format) {
    switch (format) {
      case AudioFormat.aac:
        return 'aac';
      case AudioFormat.mp3:
        return 'mp3';
      case AudioFormat.wav:
        return 'wav';
      case AudioFormat.opus:
        return 'opus';
      case AudioFormat.flac:
        return 'flac';
    }
  }

  int _getBitRateFromQuality(AudioQuality quality) {
    switch (quality) {
      case AudioQuality.low:
        return 64000;
      case AudioQuality.medium:
        return 128000;
      case AudioQuality.high:
        return 192000;
      case AudioQuality.veryHigh:
        return 320000;
    }
  }

  int _getSampleRateFromQuality(AudioQuality quality) {
    switch (quality) {
      case AudioQuality.low:
        return 22050;
      case AudioQuality.medium:
        return 44100;
      case AudioQuality.high:
        return 44100;
      case AudioQuality.veryHigh:
        return 48000;
    }
  }

  void _addToHistory(AudioRecordingInfo recording) {
    _recordingHistory.insert(0, recording);

    // Limit history size
    if (_recordingHistory.length > _maxHistoryItems) {
      _recordingHistory.removeRange(_maxHistoryItems, _recordingHistory.length);
    }

    _saveRecordingHistory();
  }

  // Settings

  void updateRecordingFormat(AudioFormat format) {
    _recordingFormat = format;
    _saveSettings();
  }

  void updateRecordingQuality(AudioQuality quality) {
    _recordingQuality = quality;
    _saveSettings();
  }

  void updateRecordingGain(double gain) {
    _recordingGain = gain.clamp(0.1, 3.0);
    _saveSettings();
  }

  void updateNoiseReduction(bool enabled) {
    _enableNoiseReduction = enabled;
    _saveSettings();
  }

  void updateEchoCancellation(bool enabled) {
    _enableEchoCancellation = enabled;
    _saveSettings();
  }

  // Utility methods

  Future<Duration?> getAudioDuration(String filePath) async {
    try {
      final audioPlayer = AudioPlayer();
      await audioPlayer.setSource(DeviceFileSource(filePath));

      final completer = Completer<Duration?>();

      audioPlayer.onDurationChanged.listen((duration) {
        if (!completer.isCompleted) {
          completer.complete(duration);
        }
      });

      // Timeout after 5 seconds
      Timer(const Duration(seconds: 5), () {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      });

      final duration = await completer.future;
      await audioPlayer.dispose();

      return duration;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting audio duration: $e');
      }
      return null;
    }
  }

  Future<void> deleteRecording(String recordingId) async {
    try {
      final recording = _recordingHistory.firstWhere(
        (r) => r.id == recordingId,
        orElse: () => throw Exception('Recording not found'),
      );

      // Delete file
      final file = File(recording.filePath);
      if (await file.exists()) {
        await file.delete();
      }

      // Remove from history
      _recordingHistory.removeWhere((r) => r.id == recordingId);
      await _saveRecordingHistory();

      if (kDebugMode) {
        print('🗑️ Recording deleted: $recordingId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error deleting recording: $e');
      }
    }
  }

  void clearRecordingHistory() {
    _recordingHistory.clear();
    _saveRecordingHistory();

    if (kDebugMode) {
      print('🗑️ Recording history cleared');
    }
  }

  AudioPlayerInfo? getPlaybackInfo(String playerId) {
    return _playbackInfos[playerId];
  }

  // Cleanup

  Future<void> dispose() async {
    _stopRecordingTimer();

    // Stop all playback
    for (final audioPlayer in _audioPlayers.values) {
      await audioPlayer.dispose();
    }
    _audioPlayers.clear();

    // Close recorder and player
    await _recorder?.closeRecorder();
    await _player?.closePlayer();

    await _stateController.close();
    await _recordingController.close();
    await _playbackController.close();
    await _recordingDurationController.close();

    _playbackInfos.clear();

    if (kDebugMode) {
      print('✅ Audio service disposed');
    }
  }
}

// Riverpod providers
final audioServiceProvider = Provider<AudioService>((ref) {
  return AudioService();
});

final audioStateProvider = StreamProvider<AudioServiceState>((ref) {
  final service = ref.watch(audioServiceProvider);
  return service.stateStream;
});

final recordingUpdatesProvider = StreamProvider<AudioRecordingInfo>((ref) {
  final service = ref.watch(audioServiceProvider);
  return service.recordingUpdates;
});

final playbackUpdatesProvider = StreamProvider<AudioPlayerInfo>((ref) {
  final service = ref.watch(audioServiceProvider);
  return service.playbackUpdates;
});

final recordingDurationProvider = StreamProvider<Duration>((ref) {
  final service = ref.watch(audioServiceProvider);
  return service.recordingDurationStream;
});

final recordingHistoryProvider = Provider<List<AudioRecordingInfo>>((ref) {
  final service = ref.watch(audioServiceProvider);
  return service.recordingHistory;
});

final isRecordingProvider = Provider<bool>((ref) {
  final service = ref.watch(audioServiceProvider);
  return service.isRecording;
});

final isPlayingProvider = Provider<bool>((ref) {
  final service = ref.watch(audioServiceProvider);
  return service.isPlaying;
});
