import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../services/websocket/call_socket.dart';
import '../../services/storage/cache_service.dart';
import '../../models/call/webrtc_models.dart';

// WebRTC connection state
enum WebRTCConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  failed,
  closed,
}

// Media stream state
class MediaStreamState {
  final MediaStream? localStream;
  final MediaStream? remoteStream;
  final bool audioEnabled;
  final bool videoEnabled;
  final bool speakerEnabled;
  final bool frontCamera;
  final bool screenSharing;

  MediaStreamState({
    this.localStream,
    this.remoteStream,
    this.audioEnabled = true,
    this.videoEnabled = false,
    this.speakerEnabled = false,
    this.frontCamera = true,
    this.screenSharing = false,
  });

  MediaStreamState copyWith({
    MediaStream? localStream,
    MediaStream? remoteStream,
    bool? audioEnabled,
    bool? videoEnabled,
    bool? speakerEnabled,
    bool? frontCamera,
    bool? screenSharing,
  }) {
    return MediaStreamState(
      localStream: localStream ?? this.localStream,
      remoteStream: remoteStream ?? this.remoteStream,
      audioEnabled: audioEnabled ?? this.audioEnabled,
      videoEnabled: videoEnabled ?? this.videoEnabled,
      speakerEnabled: speakerEnabled ?? this.speakerEnabled,
      frontCamera: frontCamera ?? this.frontCamera,
      screenSharing: screenSharing ?? this.screenSharing,
    );
  }
}

// WebRTC state
class WebRTCState {
  final WebRTCConnectionState connectionState;
  final MediaStreamState mediaState;
  final String? callId;
  final String? error;
  final bool isInitialized;
  final List<RTCIceCandidate> localCandidates;
  final List<RTCIceCandidate> remoteCandidates;
  final RTCSessionDescription? localDescription;
  final RTCSessionDescription? remoteDescription;

  WebRTCState({
    this.connectionState = WebRTCConnectionState.disconnected,
    this.mediaState = MediaStreamState(),
    this.callId,
    this.error,
    this.isInitialized = false,
    this.localCandidates = const [],
    this.remoteCandidates = const [],
    this.localDescription,
    this.remoteDescription,
  });

  WebRTCState copyWith({
    WebRTCConnectionState? connectionState,
    MediaStreamState? mediaState,
    String? callId,
    String? error,
    bool? isInitialized,
    List<RTCIceCandidate>? localCandidates,
    List<RTCIceCandidate>? remoteCandidates,
    RTCSessionDescription? localDescription,
    RTCSessionDescription? remoteDescription,
  }) {
    return WebRTCState(
      connectionState: connectionState ?? this.connectionState,
      mediaState: mediaState ?? this.mediaState,
      callId: callId ?? this.callId,
      error: error,
      isInitialized: isInitialized ?? this.isInitialized,
      localCandidates: localCandidates ?? this.localCandidates,
      remoteCandidates: remoteCandidates ?? this.remoteCandidates,
      localDescription: localDescription ?? this.localDescription,
      remoteDescription: remoteDescription ?? this.remoteDescription,
    );
  }

  bool get isConnected => connectionState == WebRTCConnectionState.connected;
  bool get isConnecting => connectionState == WebRTCConnectionState.connecting;
  bool get hasLocalStream => mediaState.localStream != null;
  bool get hasRemoteStream => mediaState.remoteStream != null;
}

class WebRTCNotifier extends StateNotifier<WebRTCState> {
  final CallSocketService _callSocketService;
  final CacheService _cacheService;

  // WebRTC components
  RTCPeerConnection? _peerConnection;
  final Map<String, dynamic> _configuration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      // Add TURN servers if needed
    ],
    'iceCandidatePoolSize': 10,
  };

  // Subscriptions
  StreamSubscription<CallEvent>? _callEventSubscription;

  WebRTCNotifier(this._callSocketService, this._cacheService)
    : super(WebRTCState()) {
    _initialize();
  }

  void _initialize() async {
    try {
      // Initialize WebRTC
      await _initializeWebRTC();

      // Setup subscriptions
      _setupSubscriptions();

      state = state.copyWith(isInitialized: true);

      if (kDebugMode) print('✅ WebRTC provider initialized');
    } catch (e) {
      state = state.copyWith(error: e.toString());
      if (kDebugMode) print('❌ Error initializing WebRTC: $e');
    }
  }

  Future<void> _initializeWebRTC() async {
    try {
      _peerConnection = await createPeerConnection(_configuration);

      _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
        _handleLocalIceCandidate(candidate);
      };

      _peerConnection!.onAddStream = (MediaStream stream) {
        _handleRemoteStream(stream);
      };

      _peerConnection!.onRemoveStream = (MediaStream stream) {
        _handleRemoteStreamRemoved(stream);
      };

      _peerConnection!.onConnectionState =
          (RTCPeerConnectionState connectionState) {
            _handleConnectionStateChange(connectionState);
          };

      _peerConnection!.onIceConnectionState = (RTCIceConnectionState iceState) {
        _handleIceConnectionStateChange(iceState);
      };
    } catch (e) {
      if (kDebugMode) print('❌ Error creating peer connection: $e');
      rethrow;
    }
  }

  void _setupSubscriptions() {
    _callEventSubscription = _callSocketService.callEvents.listen(
      _handleCallEvent,
    );
  }

  void _handleCallEvent(CallEvent event) {
    switch (event.type) {
      case CallEventType.localStreamAdded:
        final stream = event.data?['stream'] as MediaStream?;
        if (stream != null) {
          state = state.copyWith(
            mediaState: state.mediaState.copyWith(localStream: stream),
          );
        }
        break;
      case CallEventType.remoteStreamAdded:
        final stream = event.data?['stream'] as MediaStream?;
        if (stream != null) {
          state = state.copyWith(
            mediaState: state.mediaState.copyWith(remoteStream: stream),
          );
        }
        break;
      case CallEventType.remoteStreamRemoved:
        state = state.copyWith(
          mediaState: state.mediaState.copyWith(remoteStream: null),
        );
        break;
      default:
        break;
    }
  }

  void _handleLocalIceCandidate(RTCIceCandidate candidate) {
    final updatedCandidates = [...state.localCandidates, candidate];
    state = state.copyWith(localCandidates: updatedCandidates);

    // Send candidate to remote peer through signaling
    _sendIceCandidate(candidate);
  }

  void _handleRemoteStream(MediaStream stream) {
    state = state.copyWith(
      mediaState: state.mediaState.copyWith(remoteStream: stream),
    );

    if (kDebugMode) print('📺 Remote stream added');
  }

  void _handleRemoteStreamRemoved(MediaStream stream) {
    state = state.copyWith(
      mediaState: state.mediaState.copyWith(remoteStream: null),
    );

    if (kDebugMode) print('📺 Remote stream removed');
  }

  void _handleConnectionStateChange(RTCPeerConnectionState connectionState) {
    WebRTCConnectionState newState;

    switch (connectionState) {
      case RTCPeerConnectionState.RTCPeerConnectionStateConnecting:
        newState = WebRTCConnectionState.connecting;
        break;
      case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
        newState = WebRTCConnectionState.connected;
        break;
      case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
        newState = WebRTCConnectionState.disconnected;
        break;
      case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
        newState = WebRTCConnectionState.failed;
        break;
      case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
        newState = WebRTCConnectionState.closed;
        break;
      default:
        newState = WebRTCConnectionState.disconnected;
    }

    state = state.copyWith(connectionState: newState);

    if (kDebugMode) print('🔗 Connection state changed: $newState');
  }

  void _handleIceConnectionStateChange(RTCIceConnectionState iceState) {
    if (kDebugMode) print('🧊 ICE connection state: $iceState');
  }

  // Public methods for call management
  Future<void> startCall(String callId, {bool video = false}) async {
    try {
      state = state.copyWith(
        callId: callId,
        connectionState: WebRTCConnectionState.connecting,
      );

      // Create local stream
      await _createLocalStream(video: video);

      // Create offer
      final offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);

      state = state.copyWith(localDescription: offer);

      // Send offer through signaling
      _sendOffer(offer);

      if (kDebugMode) print('📞 Call started: $callId');
    } catch (e) {
      state = state.copyWith(error: e.toString());
      if (kDebugMode) print('❌ Error starting call: $e');
      rethrow;
    }
  }

  Future<void> answerCall(String callId, {bool video = false}) async {
    try {
      state = state.copyWith(
        callId: callId,
        connectionState: WebRTCConnectionState.connecting,
      );

      // Create local stream
      await _createLocalStream(video: video);

      if (kDebugMode) print('📞 Call answered: $callId');
    } catch (e) {
      state = state.copyWith(error: e.toString());
      if (kDebugMode) print('❌ Error answering call: $e');
      rethrow;
    }
  }

  Future<void> handleOffer(RTCSessionDescription offer) async {
    try {
      await _peerConnection!.setRemoteDescription(offer);
      state = state.copyWith(remoteDescription: offer);

      final answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);

      state = state.copyWith(localDescription: answer);

      // Send answer through signaling
      _sendAnswer(answer);

      if (kDebugMode) print('📞 Offer handled, answer sent');
    } catch (e) {
      state = state.copyWith(error: e.toString());
      if (kDebugMode) print('❌ Error handling offer: $e');
    }
  }

  Future<void> handleAnswer(RTCSessionDescription answer) async {
    try {
      await _peerConnection!.setRemoteDescription(answer);
      state = state.copyWith(remoteDescription: answer);

      if (kDebugMode) print('📞 Answer handled');
    } catch (e) {
      state = state.copyWith(error: e.toString());
      if (kDebugMode) print('❌ Error handling answer: $e');
    }
  }

  Future<void> handleIceCandidate(RTCIceCandidate candidate) async {
    try {
      await _peerConnection!.addCandidate(candidate);

      final updatedCandidates = [...state.remoteCandidates, candidate];
      state = state.copyWith(remoteCandidates: updatedCandidates);

      if (kDebugMode) print('🧊 ICE candidate added');
    } catch (e) {
      if (kDebugMode) print('❌ Error adding ICE candidate: $e');
    }
  }

  Future<void> endCall() async {
    try {
      // Stop local stream
      if (state.mediaState.localStream != null) {
        await state.mediaState.localStream!.dispose();
      }

      // Close peer connection
      await _peerConnection?.close();

      // Reset state
      state = WebRTCState(isInitialized: true);

      // Recreate peer connection for next call
      await _initializeWebRTC();

      if (kDebugMode) print('📞 Call ended');
    } catch (e) {
      if (kDebugMode) print('❌ Error ending call: $e');
    }
  }

  // Media control methods
  Future<void> toggleAudio() async {
    try {
      final currentState = state.mediaState.audioEnabled;

      if (state.mediaState.localStream != null) {
        final audioTracks = state.mediaState.localStream!.getAudioTracks();
        for (final track in audioTracks) {
          track.enabled = !currentState;
        }
      }

      state = state.copyWith(
        mediaState: state.mediaState.copyWith(audioEnabled: !currentState),
      );

      if (kDebugMode)
        print('🎤 Audio ${!currentState ? 'enabled' : 'disabled'}');
    } catch (e) {
      if (kDebugMode) print('❌ Error toggling audio: $e');
    }
  }

  Future<void> toggleVideo() async {
    try {
      final currentState = state.mediaState.videoEnabled;

      if (state.mediaState.localStream != null) {
        final videoTracks = state.mediaState.localStream!.getVideoTracks();
        for (final track in videoTracks) {
          track.enabled = !currentState;
        }
      }

      state = state.copyWith(
        mediaState: state.mediaState.copyWith(videoEnabled: !currentState),
      );

      if (kDebugMode)
        print('📹 Video ${!currentState ? 'enabled' : 'disabled'}');
    } catch (e) {
      if (kDebugMode) print('❌ Error toggling video: $e');
    }
  }

  Future<void> toggleSpeaker() async {
    try {
      final currentState = state.mediaState.speakerEnabled;
      await Helper.setSpeakerphoneOn(!currentState);

      state = state.copyWith(
        mediaState: state.mediaState.copyWith(speakerEnabled: !currentState),
      );

      if (kDebugMode)
        print('🔊 Speaker ${!currentState ? 'enabled' : 'disabled'}');
    } catch (e) {
      if (kDebugMode) print('❌ Error toggling speaker: $e');
    }
  }

  Future<void> switchCamera() async {
    try {
      if (state.mediaState.localStream != null &&
          state.mediaState.videoEnabled) {
        final videoTracks = state.mediaState.localStream!.getVideoTracks();
        for (final track in videoTracks) {
          await Helper.switchCamera(track);
        }

        state = state.copyWith(
          mediaState: state.mediaState.copyWith(
            frontCamera: !state.mediaState.frontCamera,
          ),
        );

        if (kDebugMode)
          print(
            '📷 Camera switched to ${state.mediaState.frontCamera ? 'front' : 'back'}',
          );
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error switching camera: $e');
    }
  }

  Future<void> startScreenShare() async {
    try {
      if (state.mediaState.screenSharing) return;

      final screenStream = await navigator.mediaDevices.getDisplayMedia({
        'video': true,
        'audio': true,
      });

      // Replace video track
      if (_peerConnection != null) {
        final senders = await _peerConnection!.getSenders();
        final videoSender = senders
            .where((sender) => sender.track?.kind == 'video')
            .firstOrNull;

        if (videoSender != null) {
          await videoSender.replaceTrack(screenStream.getVideoTracks().first);
        }
      }

      state = state.copyWith(
        mediaState: state.mediaState.copyWith(
          localStream: screenStream,
          screenSharing: true,
        ),
      );

      if (kDebugMode) print('📺 Screen sharing started');
    } catch (e) {
      if (kDebugMode) print('❌ Error starting screen share: $e');
    }
  }

  Future<void> stopScreenShare() async {
    try {
      if (!state.mediaState.screenSharing) return;

      // Switch back to camera
      await _createLocalStream(video: state.mediaState.videoEnabled);

      state = state.copyWith(
        mediaState: state.mediaState.copyWith(screenSharing: false),
      );

      if (kDebugMode) print('📺 Screen sharing stopped');
    } catch (e) {
      if (kDebugMode) print('❌ Error stopping screen share: $e');
    }
  }

  Future<void> _createLocalStream({bool video = false}) async {
    try {
      final constraints = {
        'audio': true,
        'video': video
            ? {
                'facingMode': state.mediaState.frontCamera
                    ? 'user'
                    : 'environment',
              }
            : false,
      };

      final stream = await navigator.mediaDevices.getUserMedia(constraints);

      // Add stream to peer connection
      if (_peerConnection != null) {
        await _peerConnection!.addStream(stream);
      }

      state = state.copyWith(
        mediaState: state.mediaState.copyWith(
          localStream: stream,
          videoEnabled: video,
        ),
      );

      if (kDebugMode) print('📹 Local stream created');
    } catch (e) {
      if (kDebugMode) print('❌ Error creating local stream: $e');
      rethrow;
    }
  }

  // Signaling methods (these would send through CallSocketService)
  void _sendOffer(RTCSessionDescription offer) {
    // Send offer through CallSocketService signaling
    if (kDebugMode) print('📤 Sending offer');
  }

  void _sendAnswer(RTCSessionDescription answer) {
    // Send answer through CallSocketService signaling
    if (kDebugMode) print('📤 Sending answer');
  }

  void _sendIceCandidate(RTCIceCandidate candidate) {
    // Send ICE candidate through CallSocketService signaling
    if (kDebugMode) print('📤 Sending ICE candidate');
  }

  @override
  void dispose() {
    _callEventSubscription?.cancel();

    // Cleanup WebRTC resources
    state.mediaState.localStream?.dispose();
    state.mediaState.remoteStream?.dispose();
    _peerConnection?.close();

    super.dispose();
  }
}

// Providers
final webrtcProvider = StateNotifierProvider<WebRTCNotifier, WebRTCState>((
  ref,
) {
  final callSocketService = ref.watch(callSocketServiceProvider);
  final cacheService = CacheService();
  return WebRTCNotifier(callSocketService, cacheService);
});

// Convenience providers
final webrtcConnectionStateProvider = Provider<WebRTCConnectionState>((ref) {
  final webrtcState = ref.watch(webrtcProvider);
  return webrtcState.connectionState;
});

final localStreamProvider = Provider<MediaStream?>((ref) {
  final webrtcState = ref.watch(webrtcProvider);
  return webrtcState.mediaState.localStream;
});

final remoteStreamProvider = Provider<MediaStream?>((ref) {
  final webrtcState = ref.watch(webrtcProvider);
  return webrtcState.mediaState.remoteStream;
});

final isAudioEnabledProvider = Provider<bool>((ref) {
  final webrtcState = ref.watch(webrtcProvider);
  return webrtcState.mediaState.audioEnabled;
});

final isVideoEnabledProvider = Provider<bool>((ref) {
  final webrtcState = ref.watch(webrtcProvider);
  return webrtcState.mediaState.videoEnabled;
});

final isSpeakerEnabledProvider = Provider<bool>((ref) {
  final webrtcState = ref.watch(webrtcProvider);
  return webrtcState.mediaState.speakerEnabled;
});

final isScreenSharingProvider = Provider<bool>((ref) {
  final webrtcState = ref.watch(webrtcProvider);
  return webrtcState.mediaState.screenSharing;
});

final isWebRTCConnectedProvider = Provider<bool>((ref) {
  final webrtcState = ref.watch(webrtcProvider);
  return webrtcState.isConnected;
});
