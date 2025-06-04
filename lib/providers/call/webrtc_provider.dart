import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:dio/dio.dart';
import '../../models/common/api_response.dart';
import '../../core/constants/api_constants.dart';
import '../../core/config/dio_config.dart';
import '../../services/storage/secure_storage.dart';
import '../../services/storage/local_storage.dart';

class WebRTCState {
  final RTCPeerConnection? peerConnection;
  final MediaStream? localStream;
  final MediaStream? remoteStream;
  final bool isInitialized;
  final bool isConnected;
  final bool isAudioEnabled;
  final bool isVideoEnabled;
  final bool isSpeakerEnabled;
  final bool isMicrophoneEnabled;
  final bool isScreenSharing;
  final String? error;
  final List<RTCIceCandidate> iceCandidates;
  final Map<String, dynamic>? iceServers;
  final CameraPosition cameraPosition;
  final List<MediaDeviceInfo> availableDevices;

  const WebRTCState({
    this.peerConnection,
    this.localStream,
    this.remoteStream,
    this.isInitialized = false,
    this.isConnected = false,
    this.isAudioEnabled = true,
    this.isVideoEnabled = false,
    this.isSpeakerEnabled = false,
    this.isMicrophoneEnabled = true,
    this.isScreenSharing = false,
    this.error,
    this.iceCandidates = const [],
    this.iceServers,
    this.cameraPosition = CameraPosition.front,
    this.availableDevices = const [],
  });

  WebRTCState copyWith({
    RTCPeerConnection? peerConnection,
    MediaStream? localStream,
    MediaStream? remoteStream,
    bool? isInitialized,
    bool? isConnected,
    bool? isAudioEnabled,
    bool? isVideoEnabled,
    bool? isSpeakerEnabled,
    bool? isMicrophoneEnabled,
    bool? isScreenSharing,
    String? error,
    List<RTCIceCandidate>? iceCandidates,
    Map<String, dynamic>? iceServers,
    CameraPosition? cameraPosition,
    List<MediaDeviceInfo>? availableDevices,
  }) {
    return WebRTCState(
      peerConnection: peerConnection ?? this.peerConnection,
      localStream: localStream ?? this.localStream,
      remoteStream: remoteStream ?? this.remoteStream,
      isInitialized: isInitialized ?? this.isInitialized,
      isConnected: isConnected ?? this.isConnected,
      isAudioEnabled: isAudioEnabled ?? this.isAudioEnabled,
      isVideoEnabled: isVideoEnabled ?? this.isVideoEnabled,
      isSpeakerEnabled: isSpeakerEnabled ?? this.isSpeakerEnabled,
      isMicrophoneEnabled: isMicrophoneEnabled ?? this.isMicrophoneEnabled,
      isScreenSharing: isScreenSharing ?? this.isScreenSharing,
      error: error,
      iceCandidates: iceCandidates ?? this.iceCandidates,
      iceServers: iceServers ?? this.iceServers,
      cameraPosition: cameraPosition ?? this.cameraPosition,
      availableDevices: availableDevices ?? this.availableDevices,
    );
  }
}

enum CameraPosition { front, back }

class WebRTCNotifier extends StateNotifier<WebRTCState> {
  final Dio _dio;
  final SecureStorage _secureStorage;
  final LocalStorage _localStorage;

  WebRTCNotifier(this._dio, this._secureStorage, this._localStorage)
    : super(const WebRTCState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Load saved ICE servers
      final savedIceServers = await _secureStorage.getWebRTCCredentials();
      if (savedIceServers != null) {
        state = state.copyWith(iceServers: savedIceServers);
      } else {
        await _fetchIceServers();
      }

      // Get available media devices
      await _getAvailableDevices();

      state = state.copyWith(isInitialized: true);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to initialize WebRTC: $e',
        isInitialized: true,
      );
    }
  }

  Future<void> _fetchIceServers() async {
    try {
      final response = await _dio.get(ApiConstants.getTurnServers);

      final apiResponse = ApiResponse.fromJson(response.data, null);

      if (apiResponse.success && apiResponse.data != null) {
        final iceServers = apiResponse.data as Map<String, dynamic>;

        // Save to secure storage
        await _secureStorage.saveWebRTCCredentials(iceServers);

        state = state.copyWith(iceServers: iceServers);
      }
    } catch (e) {
      // Use default ICE servers if fetching fails
      final defaultIceServers = {
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
          {'urls': 'stun:stun1.l.google.com:19302'},
        ],
      };
      state = state.copyWith(iceServers: defaultIceServers);
    }
  }

  Future<void> _getAvailableDevices() async {
    try {
      final devices = await navigator.mediaDevices.enumerateDevices();
      state = state.copyWith(availableDevices: devices);
    } catch (e) {
      state = state.copyWith(error: 'Failed to get available devices: $e');
    }
  }

  Future<bool> createPeerConnection() async {
    try {
      if (state.peerConnection != null) {
        await state.peerConnection!.close();
      }

      final configuration = RTCConfiguration({
        'iceServers':
            state.iceServers?['iceServers'] ??
            [
              {'urls': 'stun:stun.l.google.com:19302'},
            ],
        'iceCandidatePoolSize': 10,
        'bundlePolicy': 'max-bundle',
        'rtcpMuxPolicy': 'require',
      });

      final peerConnection = await createPeerConnection(configuration);

      // Set up event handlers
      peerConnection.onIceCandidate = (RTCIceCandidate candidate) {
        state = state.copyWith(
          iceCandidates: [...state.iceCandidates, candidate],
        );
      };

      peerConnection.onAddStream = (MediaStream stream) {
        state = state.copyWith(remoteStream: stream);
      };

      peerConnection.onRemoveStream = (MediaStream stream) {
        state = state.copyWith(remoteStream: null);
      };

      peerConnection.onConnectionState =
          (RTCPeerConnectionState connectionState) {
            switch (connectionState) {
              case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
                state = state.copyWith(isConnected: true, error: null);
                break;
              case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
                state = state.copyWith(
                  isConnected: false,
                  error: 'Peer connection failed',
                );
                break;
              case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
                state = state.copyWith(isConnected: false);
                break;
              default:
                break;
            }
          };

      state = state.copyWith(peerConnection: peerConnection, error: null);
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to create peer connection: $e');
      return false;
    }
  }

  Future<bool> createLocalStream({
    bool audio = true,
    bool video = false,
  }) async {
    try {
      final constraints = {
        'audio': audio,
        'video': video
            ? {
                'facingMode': state.cameraPosition == CameraPosition.front
                    ? 'user'
                    : 'environment',
                'width': {'ideal': 1280},
                'height': {'ideal': 720},
              }
            : false,
      };

      final stream = await navigator.mediaDevices.getUserMedia(constraints);

      // Add stream to peer connection if available
      if (state.peerConnection != null) {
        await state.peerConnection!.addStream(stream);
      }

      state = state.copyWith(
        localStream: stream,
        isAudioEnabled: audio,
        isVideoEnabled: video,
        isMicrophoneEnabled: audio,
        error: null,
      );

      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to create local stream: $e');
      return false;
    }
  }

  Future<bool> createScreenStream() async {
    try {
      final stream = await navigator.mediaDevices.getDisplayMedia({
        'video': true,
        'audio': true,
      });

      // Replace video track in peer connection
      if (state.peerConnection != null && state.localStream != null) {
        final senders = await state.peerConnection!.getSenders();
        final videoSender = senders.firstWhere(
          (sender) => sender.track?.kind == 'video',
          orElse: () => throw Exception('No video sender found'),
        );

        await videoSender.replaceTrack(stream.getVideoTracks().first);
      }

      state = state.copyWith(isScreenSharing: true, error: null);

      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to start screen sharing: $e');
      return false;
    }
  }

  Future<bool> stopScreenShare() async {
    try {
      if (!state.isScreenSharing) return true;

      // Switch back to camera
      final cameraStream = await _createCameraStream();
      if (cameraStream == null) return false;

      // Replace track in peer connection
      if (state.peerConnection != null) {
        final senders = await state.peerConnection!.getSenders();
        final videoSender = senders.firstWhere(
          (sender) => sender.track?.kind == 'video',
          orElse: () => throw Exception('No video sender found'),
        );

        await videoSender.replaceTrack(cameraStream.getVideoTracks().first);
      }

      state = state.copyWith(isScreenSharing: false, error: null);

      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to stop screen sharing: $e');
      return false;
    }
  }

  Future<MediaStream?> _createCameraStream() async {
    try {
      final constraints = {
        'video': {
          'facingMode': state.cameraPosition == CameraPosition.front
              ? 'user'
              : 'environment',
        },
      };

      return await navigator.mediaDevices.getUserMedia(constraints);
    } catch (e) {
      return null;
    }
  }

  Future<bool> toggleAudio() async {
    if (state.localStream == null) return false;

    try {
      final audioTracks = state.localStream!.getAudioTracks();
      final newAudioState = !state.isAudioEnabled;

      for (final track in audioTracks) {
        track.enabled = newAudioState;
      }

      state = state.copyWith(
        isAudioEnabled: newAudioState,
        isMicrophoneEnabled: newAudioState,
      );

      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to toggle audio: $e');
      return false;
    }
  }

  Future<bool> toggleVideo() async {
    if (state.localStream == null) return false;

    try {
      final videoTracks = state.localStream!.getVideoTracks();
      final newVideoState = !state.isVideoEnabled;

      for (final track in videoTracks) {
        track.enabled = newVideoState;
      }

      state = state.copyWith(isVideoEnabled: newVideoState);

      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to toggle video: $e');
      return false;
    }
  }

  Future<bool> toggleSpeaker() async {
    try {
      final newSpeakerState = !state.isSpeakerEnabled;
      await Helper.setSpeakerphoneOn(newSpeakerState);

      state = state.copyWith(isSpeakerEnabled: newSpeakerState);

      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to toggle speaker: $e');
      return false;
    }
  }

  Future<bool> switchCamera() async {
    if (state.localStream == null || !state.isVideoEnabled) return false;

    try {
      final videoTracks = state.localStream!.getVideoTracks();

      for (final track in videoTracks) {
        await Helper.switchCamera(track);
      }

      final newPosition = state.cameraPosition == CameraPosition.front
          ? CameraPosition.back
          : CameraPosition.front;

      state = state.copyWith(cameraPosition: newPosition);

      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to switch camera: $e');
      return false;
    }
  }

  Future<RTCSessionDescription?> createOffer() async {
    if (state.peerConnection == null) return null;

    try {
      final offer = await state.peerConnection!.createOffer();
      await state.peerConnection!.setLocalDescription(offer);
      return offer;
    } catch (e) {
      state = state.copyWith(error: 'Failed to create offer: $e');
      return null;
    }
  }

  Future<RTCSessionDescription?> createAnswer() async {
    if (state.peerConnection == null) return null;

    try {
      final answer = await state.peerConnection!.createAnswer();
      await state.peerConnection!.setLocalDescription(answer);
      return answer;
    } catch (e) {
      state = state.copyWith(error: 'Failed to create answer: $e');
      return null;
    }
  }

  Future<bool> setRemoteDescription(RTCSessionDescription description) async {
    if (state.peerConnection == null) return false;

    try {
      await state.peerConnection!.setRemoteDescription(description);
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to set remote description: $e');
      return false;
    }
  }

  Future<bool> addIceCandidate(RTCIceCandidate candidate) async {
    if (state.peerConnection == null) return false;

    try {
      await state.peerConnection!.addCandidate(candidate);
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to add ICE candidate: $e');
      return false;
    }
  }

  Future<List<StatsReport>> getStats() async {
    if (state.peerConnection == null) return [];

    try {
      return await state.peerConnection!.getStats();
    } catch (e) {
      state = state.copyWith(error: 'Failed to get stats: $e');
      return [];
    }
  }

  Future<void> dispose() async {
    try {
      // Stop all tracks
      if (state.localStream != null) {
        state.localStream!.getTracks().forEach((track) => track.stop());
        await state.localStream!.dispose();
      }

      if (state.remoteStream != null) {
        state.remoteStream!.getTracks().forEach((track) => track.stop());
        await state.remoteStream!.dispose();
      }

      // Close peer connection
      if (state.peerConnection != null) {
        await state.peerConnection!.close();
      }

      state = const WebRTCState();
    } catch (e) {
      state = state.copyWith(error: 'Failed to dispose WebRTC: $e');
    }
  }

  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }

  // Audio device management
  Future<bool> selectAudioDevice(String deviceId) async {
    try {
      if (state.localStream != null) {
        final audioTracks = state.localStream!.getAudioTracks();
        for (final track in audioTracks) {
          await track.selectAudioOutput({'deviceId': deviceId});
        }
      }
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to select audio device: $e');
      return false;
    }
  }

  // Video device management
  Future<bool> selectVideoDevice(String deviceId) async {
    try {
      // This would require recreating the video stream with the new device
      final constraints = {
        'video': {'deviceId': deviceId},
        'audio': false,
      };

      final newStream = await navigator.mediaDevices.getUserMedia(constraints);
      final videoTrack = newStream.getVideoTracks().first;

      // Replace video track in peer connection
      if (state.peerConnection != null) {
        final senders = await state.peerConnection!.getSenders();
        final videoSender = senders.firstWhere(
          (sender) => sender.track?.kind == 'video',
          orElse: () => throw Exception('No video sender found'),
        );

        await videoSender.replaceTrack(videoTrack);
      }

      // Update local stream
      if (state.localStream != null) {
        final oldVideoTracks = state.localStream!.getVideoTracks();
        for (final track in oldVideoTracks) {
          await state.localStream!.removeTrack(track);
          track.stop();
        }
        await state.localStream!.addTrack(videoTrack);
      }

      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to select video device: $e');
      return false;
    }
  }

  List<MediaDeviceInfo> get audioInputDevices {
    return state.availableDevices
        .where((device) => device.kind == 'audioinput')
        .toList();
  }

  List<MediaDeviceInfo> get audioOutputDevices {
    return state.availableDevices
        .where((device) => device.kind == 'audiooutput')
        .toList();
  }

  List<MediaDeviceInfo> get videoInputDevices {
    return state.availableDevices
        .where((device) => device.kind == 'videoinput')
        .toList();
  }
}

// Providers
final webrtcProvider = StateNotifierProvider<WebRTCNotifier, WebRTCState>((
  ref,
) {
  final dio = ref.watch(dioProvider);
  final secureStorage = SecureStorage();
  final localStorage = LocalStorage();
  return WebRTCNotifier(dio, secureStorage, localStorage);
});

// Convenience providers
final isWebRTCInitializedProvider = Provider<bool>((ref) {
  return ref.watch(webrtcProvider).isInitialized;
});

final isWebRTCConnectedProvider = Provider<bool>((ref) {
  return ref.watch(webrtcProvider).isConnected;
});

final localStreamProvider = Provider<MediaStream?>((ref) {
  return ref.watch(webrtcProvider).localStream;
});

final remoteStreamProvider = Provider<MediaStream?>((ref) {
  return ref.watch(webrtcProvider).remoteStream;
});

final webrtcAudioEnabledProvider = Provider<bool>((ref) {
  return ref.watch(webrtcProvider).isAudioEnabled;
});

final webrtcVideoEnabledProvider = Provider<bool>((ref) {
  return ref.watch(webrtcProvider).isVideoEnabled;
});

final webrtcSpeakerEnabledProvider = Provider<bool>((ref) {
  return ref.watch(webrtcProvider).isSpeakerEnabled;
});

final webrtcScreenSharingProvider = Provider<bool>((ref) {
  return ref.watch(webrtcProvider).isScreenSharing;
});

final webrtcCameraPositionProvider = Provider<CameraPosition>((ref) {
  return ref.watch(webrtcProvider).cameraPosition;
});

final webrtcErrorProvider = Provider<String?>((ref) {
  return ref.watch(webrtcProvider).error;
});

final audioInputDevicesProvider = Provider<List<MediaDeviceInfo>>((ref) {
  final notifier = ref.watch(webrtcProvider.notifier);
  return notifier.audioInputDevices;
});

final audioOutputDevicesProvider = Provider<List<MediaDeviceInfo>>((ref) {
  final notifier = ref.watch(webrtcProvider.notifier);
  return notifier.audioOutputDevices;
});

final videoInputDevicesProvider = Provider<List<MediaDeviceInfo>>((ref) {
  final notifier = ref.watch(webrtcProvider.notifier);
  return notifier.videoInputDevices;
});

final iceCandidatesProvider = Provider<List<RTCIceCandidate>>((ref) {
  return ref.watch(webrtcProvider).iceCandidates;
});

final peerConnectionProvider = Provider<RTCPeerConnection?>((ref) {
  return ref.watch(webrtcProvider).peerConnection;
});

final webrtcStatsProvider = FutureProvider<List<StatsReport>>((ref) async {
  final notifier = ref.watch(webrtcProvider.notifier);
  return await notifier.getStats();
});
