import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../core/exceptions/app_exception.dart';
import '../../core/config/app_config.dart';
import '../storage/secure_storage.dart';
import '../storage/cache_service.dart';
import 'signaling_service.dart';

enum WebRTCState {
  idle,
  initializing,
  initialized,
  connecting,
  connected,
  reconnecting,
  disconnected,
  failed,
}

enum MediaStreamType { local, remote, screen }

class MediaStreamInfo {
  final String id;
  final MediaStream stream;
  final MediaStreamType type;
  final String? peerId;
  final bool hasAudio;
  final bool hasVideo;
  final DateTime createdAt;

  MediaStreamInfo({
    required this.id,
    required this.stream,
    required this.type,
    this.peerId,
    required this.hasAudio,
    required this.hasVideo,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'peer_id': peerId,
      'has_audio': hasAudio,
      'has_video': hasVideo,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class WebRTCStats {
  final String peerId;
  final Map<String, dynamic> stats;
  final DateTime timestamp;

  WebRTCStats({required this.peerId, required this.stats, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();
}

class WebRTCService {
  static WebRTCService? _instance;

  final SignalingService _signalingService;
  final SecureStorage _secureStorage;
  final CacheService _cacheService;

  // WebRTC state
  WebRTCState _state = WebRTCState.idle;
  bool _isInitialized = false;

  // Media streams
  final Map<String, MediaStreamInfo> _mediaStreams = {};
  MediaStream? _localStream;
  MediaStream? _screenStream;

  // Media constraints and configuration
  Map<String, dynamic>? _mediaConstraints;
  Map<String, dynamic>? _webrtcConfig;

  // Event streams
  final StreamController<WebRTCState> _stateController =
      StreamController<WebRTCState>.broadcast();
  final StreamController<MediaStreamInfo> _streamController =
      StreamController<MediaStreamInfo>.broadcast();
  final StreamController<WebRTCStats> _statsController =
      StreamController<WebRTCStats>.broadcast();

  // Statistics collection
  Timer? _statsTimer;
  final Map<String, List<WebRTCStats>> _statsHistory = {};

  // Media settings
  bool _audioEnabled = true;
  bool _videoEnabled = false;
  bool _speakerEnabled = false;
  String _selectedAudioDevice = '';
  String _selectedVideoDevice = '';
  List<MediaDeviceInfo> _audioDevices = [];
  List<MediaDeviceInfo> _videoDevices = [];

  WebRTCService._internal()
    : _signalingService = SignalingService(),
      _secureStorage = SecureStorage(),
      _cacheService = CacheService() {
    _initialize();
  }

  factory WebRTCService() {
    _instance ??= WebRTCService._internal();
    return _instance!;
  }

  // Getters
  WebRTCState get state => _state;
  bool get isInitialized => _isInitialized;
  MediaStream? get localStream => _localStream;
  MediaStream? get screenStream => _screenStream;
  bool get audioEnabled => _audioEnabled;
  bool get videoEnabled => _videoEnabled;
  bool get speakerEnabled => _speakerEnabled;
  List<MediaDeviceInfo> get audioDevices => List.unmodifiable(_audioDevices);
  List<MediaDeviceInfo> get videoDevices => List.unmodifiable(_videoDevices);
  List<MediaStreamInfo> get mediaStreams => _mediaStreams.values.toList();

  // Streams
  Stream<WebRTCState> get stateStream => _stateController.stream;
  Stream<MediaStreamInfo> get streamUpdates => _streamController.stream;
  Stream<WebRTCStats> get statsStream => _statsController.stream;

  void _initialize() {
    _loadConfiguration();
    _setupSignalingListeners();
  }

  Future<void> _loadConfiguration() async {
    try {
      _webrtcConfig = await _secureStorage.getWebRTCCredentials();

      if (_webrtcConfig == null) {
        _webrtcConfig = AppConfig.webrtcConfig;
      }

      _mediaConstraints = {
        'audio': {
          'mandatory': {
            'echoCancellation': true,
            'noiseSuppression': true,
            'autoGainControl': true,
          },
          'optional': [],
        },
        'video': {
          'mandatory': {
            'minWidth': '640',
            'minHeight': '480',
            'minFrameRate': '15',
          },
          'optional': [
            {'maxWidth': '1280'},
            {'maxHeight': '720'},
            {'maxFrameRate': '30'},
          ],
        },
      };

      if (kDebugMode) {
        print('✅ WebRTC configuration loaded');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading WebRTC configuration: $e');
      }
    }
  }

  void _setupSignalingListeners() {
    _signalingService.eventStream.listen(_handleSignalingEvent);
  }

  void _handleSignalingEvent(SignalingEvent event) {
    switch (event.type) {
      case SignalingEventType.connectionStateChange:
        _handleConnectionStateChange(event);
        break;
      default:
        break;
    }
  }

  void _handleConnectionStateChange(SignalingEvent event) {
    final eventType = event.data['event'] as String?;

    switch (eventType) {
      case 'remote_stream_added':
        _handleRemoteStreamAdded(event);
        break;
      case 'remote_stream_removed':
        _handleRemoteStreamRemoved(event);
        break;
    }
  }

  void _handleRemoteStreamAdded(SignalingEvent event) {
    final peerId = event.data['peer_id'] as String;
    final streamId = event.data['stream_id'] as String;

    // This would typically be called by the signaling service
    // when a remote stream is actually added
    if (kDebugMode) {
      print('📺 Remote stream added from $peerId: $streamId');
    }
  }

  void _handleRemoteStreamRemoved(SignalingEvent event) {
    final peerId = event.data['peer_id'] as String;
    final streamId = event.data['stream_id'] as String;

    _removeMediaStream(streamId);

    if (kDebugMode) {
      print('📺 Remote stream removed from $peerId: $streamId');
    }
  }

  void _setState(WebRTCState newState) {
    if (_state != newState) {
      _state = newState;
      _stateController.add(newState);

      if (kDebugMode) {
        print('🔄 WebRTC state: ${newState.name}');
      }
    }
  }

  // Public API

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _setState(WebRTCState.initializing);

      // Initialize WebRTC
      await WebRTC.initialize();

      // Enumerate devices
      await _enumerateDevices();

      _isInitialized = true;
      _setState(WebRTCState.initialized);

      if (kDebugMode) {
        print('✅ WebRTC service initialized');
      }
    } catch (e) {
      _setState(WebRTCState.failed);

      if (kDebugMode) {
        print('❌ Error initializing WebRTC: $e');
      }

      throw MediaException.recordingFailed();
    }
  }

  Future<void> _enumerateDevices() async {
    try {
      final devices = await navigator.mediaDevices.enumerateDevices();

      _audioDevices = devices
          .where((device) => device.kind == 'audioinput')
          .toList();

      _videoDevices = devices
          .where((device) => device.kind == 'videoinput')
          .toList();

      // Set default devices
      if (_audioDevices.isNotEmpty && _selectedAudioDevice.isEmpty) {
        _selectedAudioDevice = _audioDevices.first.deviceId;
      }

      if (_videoDevices.isNotEmpty && _selectedVideoDevice.isEmpty) {
        _selectedVideoDevice = _videoDevices.first.deviceId;
      }

      if (kDebugMode) {
        print('🎤 Found ${_audioDevices.length} audio devices');
        print('📷 Found ${_videoDevices.length} video devices');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error enumerating devices: $e');
      }
    }
  }

  Future<MediaStream> createLocalStream({
    bool audio = true,
    bool video = false,
    String? audioDeviceId,
    String? videoDeviceId,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      final constraints = <String, dynamic>{};

      if (audio) {
        constraints['audio'] = {
          'deviceId': audioDeviceId ?? _selectedAudioDevice,
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
        };
      } else {
        constraints['audio'] = false;
      }

      if (video) {
        constraints['video'] = {
          'deviceId': videoDeviceId ?? _selectedVideoDevice,
          'width': {'min': 640, 'ideal': 1280, 'max': 1920},
          'height': {'min': 480, 'ideal': 720, 'max': 1080},
          'frameRate': {'min': 15, 'ideal': 24, 'max': 30},
        };
      } else {
        constraints['video'] = false;
      }

      final stream = await navigator.mediaDevices.getUserMedia(constraints);

      _localStream = stream;
      _audioEnabled = audio;
      _videoEnabled = video;

      final streamInfo = MediaStreamInfo(
        id: stream.id,
        stream: stream,
        type: MediaStreamType.local,
        hasAudio: audio,
        hasVideo: video,
      );

      _mediaStreams[stream.id] = streamInfo;
      _streamController.add(streamInfo);

      // Add stream to signaling service
      await _signalingService.addLocalStream(stream);

      if (kDebugMode) {
        print('📹 Local stream created: audio=$audio, video=$video');
      }

      return stream;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error creating local stream: $e');
      }

      if (e.toString().contains('Permission denied')) {
        throw PermissionException.camera();
      }

      throw MediaException.recordingFailed();
    }
  }

  Future<MediaStream> createScreenShareStream() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      final stream = await navigator.mediaDevices.getDisplayMedia({
        'video': true,
        'audio': true,
      });

      _screenStream = stream;

      final streamInfo = MediaStreamInfo(
        id: stream.id,
        stream: stream,
        type: MediaStreamType.screen,
        hasAudio: true,
        hasVideo: true,
      );

      _mediaStreams[stream.id] = streamInfo;
      _streamController.add(streamInfo);

      // Replace video track in peer connections
      await _replaceVideoTrack(stream.getVideoTracks().first);

      if (kDebugMode) {
        print('📺 Screen share stream created');
      }

      return stream;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error creating screen share stream: $e');
      }

      throw MediaException.recordingFailed();
    }
  }

  Future<void> stopScreenShare() async {
    try {
      if (_screenStream != null) {
        _removeMediaStream(_screenStream!.id);
        await _screenStream!.dispose();
        _screenStream = null;

        // Switch back to camera
        if (_localStream != null && _videoEnabled) {
          final videoTrack = _localStream!.getVideoTracks().first;
          await _replaceVideoTrack(videoTrack);
        }

        if (kDebugMode) {
          print('📺 Screen share stopped');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error stopping screen share: $e');
      }
    }
  }

  Future<void> _replaceVideoTrack(MediaStreamTrack newTrack) async {
    try {
      for (final peerId in _signalingService.connectedPeers) {
        final peerConnection = _signalingService.getPeerConnection(peerId);
        if (peerConnection != null) {
          final senders = await peerConnection.getSenders();
          final videoSender = senders.firstWhere(
            (sender) => sender.track?.kind == 'video',
            orElse: () => throw Exception('No video sender found'),
          );

          await videoSender.replaceTrack(newTrack);
        }
      }

      if (kDebugMode) {
        print('🔄 Video track replaced for all peers');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error replacing video track: $e');
      }
    }
  }

  void addRemoteStream(MediaStream stream, String peerId) {
    final streamInfo = MediaStreamInfo(
      id: stream.id,
      stream: stream,
      type: MediaStreamType.remote,
      peerId: peerId,
      hasAudio: stream.getAudioTracks().isNotEmpty,
      hasVideo: stream.getVideoTracks().isNotEmpty,
    );

    _mediaStreams[stream.id] = streamInfo;
    _streamController.add(streamInfo);

    if (kDebugMode) {
      print('📺 Remote stream added from $peerId: ${stream.id}');
    }
  }

  void _removeMediaStream(String streamId) {
    final streamInfo = _mediaStreams.remove(streamId);
    if (streamInfo != null) {
      _streamController.add(streamInfo);

      if (kDebugMode) {
        print('📺 Media stream removed: $streamId');
      }
    }
  }

  // Media controls

  Future<void> toggleAudio() async {
    try {
      if (_localStream != null) {
        _audioEnabled = !_audioEnabled;

        final audioTracks = _localStream!.getAudioTracks();
        for (final track in audioTracks) {
          track.enabled = _audioEnabled;
        }

        if (kDebugMode) {
          print('🎤 Audio ${_audioEnabled ? 'enabled' : 'disabled'}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error toggling audio: $e');
      }
    }
  }

  Future<void> toggleVideo() async {
    try {
      if (_localStream != null) {
        _videoEnabled = !_videoEnabled;

        final videoTracks = _localStream!.getVideoTracks();
        for (final track in videoTracks) {
          track.enabled = _videoEnabled;
        }

        if (kDebugMode) {
          print('🎥 Video ${_videoEnabled ? 'enabled' : 'disabled'}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error toggling video: $e');
      }
    }
  }

  Future<void> switchCamera() async {
    try {
      if (_localStream != null && _videoEnabled) {
        final videoTracks = _localStream!.getVideoTracks();

        for (final track in videoTracks) {
          await Helper.switchCamera(track);
        }

        if (kDebugMode) {
          print('📷 Camera switched');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error switching camera: $e');
      }
    }
  }

  Future<void> setSpeakerEnabled(bool enabled) async {
    try {
      _speakerEnabled = enabled;
      await Helper.setSpeakerphoneOn(enabled);

      if (kDebugMode) {
        print('🔊 Speaker ${enabled ? 'enabled' : 'disabled'}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error setting speaker: $e');
      }
    }
  }

  Future<void> setAudioDevice(String deviceId) async {
    try {
      _selectedAudioDevice = deviceId;

      // Recreate local stream with new device
      if (_localStream != null) {
        await _recreateLocalStream();
      }

      if (kDebugMode) {
        print('🎤 Audio device changed: $deviceId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error setting audio device: $e');
      }
    }
  }

  Future<void> setVideoDevice(String deviceId) async {
    try {
      _selectedVideoDevice = deviceId;

      // Recreate local stream with new device
      if (_localStream != null && _videoEnabled) {
        await _recreateLocalStream();
      }

      if (kDebugMode) {
        print('📷 Video device changed: $deviceId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error setting video device: $e');
      }
    }
  }

  Future<void> _recreateLocalStream() async {
    try {
      // Stop current stream
      if (_localStream != null) {
        await _signalingService.removeLocalStream(_localStream!);
        await _localStream!.dispose();
        _removeMediaStream(_localStream!.id);
        _localStream = null;
      }

      // Create new stream
      await createLocalStream(
        audio: _audioEnabled,
        video: _videoEnabled,
        audioDeviceId: _selectedAudioDevice,
        videoDeviceId: _selectedVideoDevice,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error recreating local stream: $e');
      }
    }
  }

  // Statistics

  void startStatsCollection() {
    _statsTimer?.cancel();
    _statsTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _collectStats();
    });

    if (kDebugMode) {
      print('📊 Stats collection started');
    }
  }

  void stopStatsCollection() {
    _statsTimer?.cancel();
    _statsTimer = null;

    if (kDebugMode) {
      print('📊 Stats collection stopped');
    }
  }

  Future<void> _collectStats() async {
    try {
      for (final peerId in _signalingService.connectedPeers) {
        final peerConnection = _signalingService.getPeerConnection(peerId);
        if (peerConnection != null) {
          final statsReports = await peerConnection.getStats();

          final stats = <String, dynamic>{};
          for (final report in statsReports) {
            stats[report.id] = report.values;
          }

          final webrtcStats = WebRTCStats(peerId: peerId, stats: stats);

          _statsHistory.putIfAbsent(peerId, () => []).add(webrtcStats);

          // Keep only last 60 measurements (5 minutes at 5-second intervals)
          if (_statsHistory[peerId]!.length > 60) {
            _statsHistory[peerId]!.removeAt(0);
          }

          _statsController.add(webrtcStats);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error collecting stats: $e');
      }
    }
  }

  Map<String, dynamic> getConnectionQuality(String peerId) {
    final history = _statsHistory[peerId];
    if (history == null || history.isEmpty) {
      return {'quality': 'unknown'};
    }

    try {
      final latestStats = history.last;
      double rtt = 0;
      double jitter = 0;
      double packetLoss = 0;
      double bitrate = 0;

      // Extract relevant metrics from stats
      for (final reportStats in latestStats.stats.values) {
        if (reportStats is Map<String, dynamic>) {
          if (reportStats['type'] == 'candidate-pair' &&
              reportStats['state'] == 'succeeded') {
            rtt =
                double.tryParse(
                  reportStats['currentRoundTripTime']?.toString() ?? '0',
                ) ??
                0;
          } else if (reportStats['type'] == 'inbound-rtp') {
            jitter =
                double.tryParse(reportStats['jitter']?.toString() ?? '0') ?? 0;
            final packetsLost =
                int.tryParse(reportStats['packetsLost']?.toString() ?? '0') ??
                0;
            final packetsReceived =
                int.tryParse(
                  reportStats['packetsReceived']?.toString() ?? '0',
                ) ??
                0;

            if (packetsReceived > 0) {
              packetLoss = packetsLost / (packetsLost + packetsReceived);
            }
          } else if (reportStats['type'] == 'outbound-rtp') {
            final bytesSent =
                int.tryParse(reportStats['bytesSent']?.toString() ?? '0') ?? 0;
            final timestamp =
                double.tryParse(reportStats['timestamp']?.toString() ?? '0') ??
                0;

            if (timestamp > 0) {
              bitrate = (bytesSent * 8) / (timestamp / 1000); // bps
            }
          }
        }
      }

      // Calculate quality score (1-5)
      double qualityScore = 5.0;

      if (rtt > 300)
        qualityScore -= 1.5;
      else if (rtt > 150)
        qualityScore -= 0.5;

      if (jitter > 50)
        qualityScore -= 1.5;
      else if (jitter > 30)
        qualityScore -= 0.5;

      if (packetLoss > 0.05)
        qualityScore -= 2.0;
      else if (packetLoss > 0.02)
        qualityScore -= 1.0;

      qualityScore = qualityScore.clamp(1.0, 5.0);

      String quality = 'excellent';
      if (qualityScore < 2)
        quality = 'poor';
      else if (qualityScore < 3)
        quality = 'fair';
      else if (qualityScore < 4)
        quality = 'good';

      return {
        'quality': quality,
        'score': qualityScore,
        'rtt': rtt,
        'jitter': jitter,
        'packet_loss': packetLoss,
        'bitrate': bitrate,
      };
    } catch (e) {
      return {'quality': 'unknown', 'error': e.toString()};
    }
  }

  List<WebRTCStats> getStatsHistory(String peerId) {
    return _statsHistory[peerId] ?? [];
  }

  Map<String, dynamic> getOverallStats() {
    final totalConnections = _signalingService.connectedPeers.length;
    final totalStreams = _mediaStreams.length;

    double avgQuality = 0;
    int qualityMeasurements = 0;

    for (final peerId in _signalingService.connectedPeers) {
      final quality = getConnectionQuality(peerId);
      if (quality['score'] != null) {
        avgQuality += quality['score'] as double;
        qualityMeasurements++;
      }
    }

    if (qualityMeasurements > 0) {
      avgQuality /= qualityMeasurements;
    }

    return {
      'state': _state.name,
      'total_connections': totalConnections,
      'total_streams': totalStreams,
      'local_stream_active': _localStream != null,
      'screen_share_active': _screenStream != null,
      'audio_enabled': _audioEnabled,
      'video_enabled': _videoEnabled,
      'speaker_enabled': _speakerEnabled,
      'average_quality': avgQuality,
      'audio_devices_count': _audioDevices.length,
      'video_devices_count': _videoDevices.length,
    };
  }

  // Cleanup

  Future<void> cleanup() async {
    try {
      stopStatsCollection();

      // Stop all streams
      if (_localStream != null) {
        await _localStream!.dispose();
        _localStream = null;
      }

      if (_screenStream != null) {
        await _screenStream!.dispose();
        _screenStream = null;
      }

      // Clear streams
      for (final streamInfo in _mediaStreams.values) {
        if (streamInfo.type == MediaStreamType.remote) {
          await streamInfo.stream.dispose();
        }
      }
      _mediaStreams.clear();

      // Reset state
      _audioEnabled = true;
      _videoEnabled = false;
      _speakerEnabled = false;

      _setState(WebRTCState.idle);

      if (kDebugMode) {
        print('🧹 WebRTC cleanup completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error during WebRTC cleanup: $e');
      }
    }
  }

  Future<void> dispose() async {
    await cleanup();

    await _stateController.close();
    await _streamController.close();
    await _statsController.close();

    _statsHistory.clear();

    if (kDebugMode) {
      print('✅ WebRTC service disposed');
    }
  }
}

// Riverpod providers
final webrtcServiceProvider = Provider<WebRTCService>((ref) {
  return WebRTCService();
});

final webrtcStateProvider = StreamProvider<WebRTCState>((ref) {
  final service = ref.watch(webrtcServiceProvider);
  return service.stateStream;
});

final mediaStreamProvider = StreamProvider<MediaStreamInfo>((ref) {
  final service = ref.watch(webrtcServiceProvider);
  return service.streamUpdates;
});

final webrtcStatsProvider = StreamProvider<WebRTCStats>((ref) {
  final service = ref.watch(webrtcServiceProvider);
  return service.statsStream;
});

final localStreamProvider = Provider<MediaStream?>((ref) {
  final service = ref.watch(webrtcServiceProvider);
  return service.localStream;
});

final audioDevicesProvider = Provider<List<MediaDeviceInfo>>((ref) {
  final service = ref.watch(webrtcServiceProvider);
  return service.audioDevices;
});

final videoDevicesProvider = Provider<List<MediaDeviceInfo>>((ref) {
  final service = ref.watch(webrtcServiceProvider);
  return service.videoDevices;
});

final overallStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final service = ref.watch(webrtcServiceProvider);
  return service.getOverallStats();
});
