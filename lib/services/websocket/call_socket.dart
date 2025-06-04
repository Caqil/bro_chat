import 'dart:async';
import 'package:bro_chat/models/call/call_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../core/config/app_config.dart';
import '../storage/cache_service.dart';
import '../storage/secure_storage.dart';
import 'websocket_service.dart';
import '../../models/call/call_participant.dart';

enum CallState {
  idle,
  initiating,
  ringing,
  connecting,
  connected,
  ended,
  failed,
  busy,
  timeout,
  rejected,
}

enum CallDirection { incoming, outgoing }

enum CameraPosition { front, back }

class CallSocketService {
  static CallSocketService? _instance;

  final WebSocketService _webSocketService;
  final CacheService _cacheService;
  final SecureStorage _storage;

  // Streams for call events
  final StreamController<CallEvent> _callEventController =
      StreamController<CallEvent>.broadcast();
  final StreamController<CallQuality> _callQualityController =
      StreamController<CallQuality>.broadcast();
  final StreamController<CallParticipant> _participantController =
      StreamController<CallParticipant>.broadcast();

  // WebRTC components
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  // Call state
  CallState _currentState = CallState.idle;
  String? _currentCallId;
  String? _currentChatId;
  CallType _currentCallType = CallType.voice;
  CallDirection? _currentDirection;
  DateTime? _callStartTime;
  Timer? _callTimer;
  Timer? _qualityTimer;

  // Media state
  bool _audioEnabled = true;
  bool _videoEnabled = false;
  bool _speakerEnabled = false;
  bool _microphoneEnabled = true;
  CameraPosition _cameraPosition = CameraPosition.front;
  bool _screenSharing = false;

  // Participants (for group calls)
  final Map<String, CallParticipant> _participants = {};

  // Quality metrics
  CallQuality? _currentQuality;
  final List<CallQuality> _qualityHistory = [];

  // Configuration
  Map<String, dynamic>? _webrtcConfig;
  List<Map<String, dynamic>>? _iceServers;

  CallSocketService._internal()
    : _webSocketService = WebSocketService(),
      _cacheService = CacheService(),
      _storage = SecureStorage() {
    _initialize();
  }

  factory CallSocketService() {
    _instance ??= CallSocketService._internal();
    return _instance!;
  }

  // Getters
  Stream<CallEvent> get callEvents => _callEventController.stream;
  Stream<CallQuality> get qualityUpdates => _callQualityController.stream;
  Stream<CallParticipant> get participantUpdates =>
      _participantController.stream;

  CallState get currentState => _currentState;
  String? get currentCallId => _currentCallId;
  String? get currentChatId => _currentChatId;
  CallType get currentCallType => _currentCallType;
  CallDirection? get currentDirection => _currentDirection;
  Duration? get callDuration => _callStartTime != null
      ? DateTime.now().difference(_callStartTime!)
      : null;

  bool get isInCall => _currentState == CallState.connected;
  bool get audioEnabled => _audioEnabled;
  bool get videoEnabled => _videoEnabled;
  bool get speakerEnabled => _speakerEnabled;
  bool get microphoneEnabled => _microphoneEnabled;
  bool get screenSharing => _screenSharing;
  CameraPosition get cameraPosition => _cameraPosition;

  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStream => _remoteStream;
  List<CallParticipant> get participants => _participants.values.toList();
  CallQuality? get currentQuality => _currentQuality;

  void _initialize() {
    // Listen to WebSocket events
    _webSocketService.eventStream.listen(_handleWebSocketEvent);

    // Listen to connection state changes
    _webSocketService.stateStream.listen(_handleConnectionStateChange);

    // Load WebRTC configuration
    _loadWebRTCConfig();
  }

  Future<void> _loadWebRTCConfig() async {
    try {
      _webrtcConfig = await _storage.getWebRTCCredentials();

      if (_webrtcConfig == null) {
        // Use default configuration
        _iceServers =
            AppConfig.webrtcConfig['iceServers'] as List<Map<String, dynamic>>?;
      } else {
        _iceServers =
            _webrtcConfig!['iceServers'] as List<Map<String, dynamic>>?;
      }

      if (kDebugMode) {
        print('✅ WebRTC configuration loaded');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading WebRTC config: $e');
      }
    }
  }

  void _handleWebSocketEvent(WebSocketEvent event) {
    switch (event.type) {
      case WebSocketEventType.callInitiated:
        _handleCallInitiated(event);
        break;
      case WebSocketEventType.callAnswered:
        _handleCallAnswered(event);
        break;
      case WebSocketEventType.callRejected:
        _handleCallRejected(event);
        break;
      case WebSocketEventType.callEnded:
        _handleCallEnded(event);
        break;
      case WebSocketEventType.callJoined:
        _handleCallJoined(event);
        break;
      case WebSocketEventType.callLeft:
        _handleCallLeft(event);
        break;
      case WebSocketEventType.callRinging:
        _handleCallRinging(event);
        break;
      case WebSocketEventType.callBusy:
        _handleCallBusy(event);
        break;
      case WebSocketEventType.callMediaUpdate:
        _handleCallMediaUpdate(event);
        break;
      case WebSocketEventType.callQualityUpdate:
        _handleCallQualityUpdate(event);
        break;
      default:
        break;
    }
  }

  void _handleConnectionStateChange(WebSocketConnectionState state) {
    if (state == WebSocketConnectionState.disconnected && isInCall) {
      // Handle disconnection during call
      _handleCallDisconnected();
    }
  }

  // Call event handlers
  void _handleCallInitiated(WebSocketEvent event) {
    try {
      final callData = event.data;
      final callId = callData['call_id'] as String;
      final chatId = callData['chat_id'] as String;
      final callType = CallType.fromString(callData['type'] as String?);
      final initiatorId = callData['initiator_id'] as String;
      final participantIds = List<String>.from(
        callData['participant_ids'] ?? [],
      );

      if (initiatorId != _getCurrentUserId()) {
        // Incoming call
        _currentCallId = callId;
        _currentChatId = chatId;
        _currentCallType = callType;
        _currentDirection = CallDirection.incoming;
        _setState(CallState.ringing);

        final callEvent = CallEvent(
          type: CallEventType.incomingCall,
          callId: callId,
          chatId: chatId,
          callType: callType,
          data: callData,
        );

        _callEventController.add(callEvent);

        // Start ringing timeout
        _startRingingTimeout();

        if (kDebugMode) {
          print('📞 Incoming call: $callId');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling call initiated: $e');
      }
    }
  }

  void _handleCallAnswered(WebSocketEvent event) {
    try {
      final callId = event.data['call_id'] as String;
      final answeredBy = event.data['answered_by'] as String;

      if (callId == _currentCallId) {
        if (_currentDirection == CallDirection.outgoing) {
          _setState(CallState.connecting);
          _startCall();
        }

        final callEvent = CallEvent(
          type: CallEventType.callAnswered,
          callId: callId,
          data: {'answered_by': answeredBy},
        );

        _callEventController.add(callEvent);

        if (kDebugMode) {
          print('✅ Call answered: $callId by $answeredBy');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling call answered: $e');
      }
    }
  }

  void _handleCallRejected(WebSocketEvent event) {
    try {
      final callId = event.data['call_id'] as String;
      final rejectedBy = event.data['rejected_by'] as String;

      if (callId == _currentCallId) {
        _setState(CallState.rejected);
        _cleanup();

        final callEvent = CallEvent(
          type: CallEventType.callRejected,
          callId: callId,
          data: {'rejected_by': rejectedBy},
        );

        _callEventController.add(callEvent);

        if (kDebugMode) {
          print('❌ Call rejected: $callId by $rejectedBy');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling call rejected: $e');
      }
    }
  }

  void _handleCallEnded(WebSocketEvent event) {
    try {
      final callId = event.data['call_id'] as String;
      final endedBy = event.data['ended_by'] as String;
      final reason = event.data['reason'] as String?;

      if (callId == _currentCallId) {
        _setState(CallState.ended);
        _cleanup();

        final callEvent = CallEvent(
          type: CallEventType.callEnded,
          callId: callId,
          data: {
            'ended_by': endedBy,
            'reason': reason,
            'duration': callDuration?.inSeconds,
          },
        );

        _callEventController.add(callEvent);

        if (kDebugMode) {
          print('📞 Call ended: $callId by $endedBy');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling call ended: $e');
      }
    }
  }

  void _handleCallJoined(WebSocketEvent event) {
    try {
      final participant = CallParticipant.fromJson(event.data);
      _participants[participant.userId] = participant;

      _participantController.add(participant);

      if (kDebugMode) {
        print('👥 Participant joined: ${participant.userId}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling call joined: $e');
      }
    }
  }

  void _handleCallLeft(WebSocketEvent event) {
    try {
      final userId = event.data['user_id'] as String;
      final participant = _participants.remove(userId);

      if (participant != null) {
        final updatedParticipant = CallParticipant(
          userId: participant.userId,
          name: participant.name,
          avatar: participant.avatar,
          status: ParticipantStatus.left,
          joinedAt: participant.joinedAt,
          leftAt: DateTime.now(),
          mediaState: participant.mediaState,
          deviceInfo: participant.deviceInfo,
          isMuted: participant.isMuted,
          isVideoEnabled: participant.isVideoEnabled,
          isScreenSharing: participant.isScreenSharing,
          quality: participant.quality,
        );
        _participantController.add(updatedParticipant);

        if (kDebugMode) {
          print('👥 Participant left: $userId');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling call left: $e');
      }
    }
  }

  void _handleCallRinging(WebSocketEvent event) {
    try {
      final callId = event.data['call_id'] as String;

      if (callId == _currentCallId &&
          _currentDirection == CallDirection.outgoing) {
        _setState(CallState.ringing);

        final callEvent = CallEvent(
          type: CallEventType.callRinging,
          callId: callId,
        );

        _callEventController.add(callEvent);

        if (kDebugMode) {
          print('📞 Call ringing: $callId');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling call ringing: $e');
      }
    }
  }

  void _handleCallBusy(WebSocketEvent event) {
    try {
      final callId = event.data['call_id'] as String;

      if (callId == _currentCallId) {
        _setState(CallState.busy);
        _cleanup();

        final callEvent = CallEvent(
          type: CallEventType.callBusy,
          callId: callId,
        );

        _callEventController.add(callEvent);

        if (kDebugMode) {
          print('📞 Call busy: $callId');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling call busy: $e');
      }
    }
  }

  void _handleCallMediaUpdate(WebSocketEvent event) {
    try {
      final userId = event.data['user_id'] as String;
      final audioEnabled = event.data['audio_enabled'] as bool?;
      final videoEnabled = event.data['video_enabled'] as bool?;
      final screenSharing = event.data['screen_sharing'] as bool?;

      final participant = _participants[userId];
      if (participant != null) {
        final updatedMediaState = MediaState(
          audioEnabled: audioEnabled ?? participant.mediaState.audioEnabled,
          videoEnabled: videoEnabled ?? participant.mediaState.videoEnabled,
          screenSharing: screenSharing ?? participant.mediaState.screenSharing,
          audioDevice: participant.mediaState.audioDevice,
          videoDevice: participant.mediaState.videoDevice,
        );

        final updatedParticipant = CallParticipant(
          userId: participant.userId,
          name: participant.name,
          avatar: participant.avatar,
          status: participant.status,
          joinedAt: participant.joinedAt,
          leftAt: participant.leftAt,
          mediaState: updatedMediaState,
          deviceInfo: participant.deviceInfo,
          isMuted: audioEnabled == false,
          isVideoEnabled: videoEnabled ?? false,
          isScreenSharing: screenSharing ?? false,
          quality: participant.quality,
        );

        _participants[userId] = updatedParticipant;
        _participantController.add(updatedParticipant);

        if (kDebugMode) {
          print(
            '🎥 Media update for $userId: audio=$audioEnabled, video=$videoEnabled',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling call media update: $e');
      }
    }
  }

  void _handleCallQualityUpdate(WebSocketEvent event) {
    try {
      final quality = CallQuality.fromJson(event.data);
      _currentQuality = quality;
      _qualityHistory.add(quality);

      // Keep only last 60 quality measurements (5 minutes at 5-second intervals)
      if (_qualityHistory.length > 60) {
        _qualityHistory.removeAt(0);
      }

      _callQualityController.add(quality);

      if (kDebugMode) {
        print('📊 Call quality: ${quality.qualityScore}/5');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling call quality update: $e');
      }
    }
  }

  void _handleCallDisconnected() {
    if (isInCall) {
      _setState(CallState.failed);
      _cleanup();

      final callEvent = CallEvent(
        type: CallEventType.callFailed,
        callId: _currentCallId,
        data: {'reason': 'connection_lost'},
      );

      _callEventController.add(callEvent);

      if (kDebugMode) {
        print('❌ Call disconnected due to network issue');
      }
    }
  }

  // Public API methods

  // Initiate a call
  Future<void> initiateCall({
    required String chatId,
    required List<String> participantIds,
    CallType type = CallType.voice,
    bool videoEnabled = false,
    bool audioEnabled = true,
  }) async {
    try {
      if (_currentState != CallState.idle) {
        throw Exception('Already in a call');
      }

      _currentChatId = chatId;
      _currentCallType = type;
      _currentDirection = CallDirection.outgoing;
      _videoEnabled = videoEnabled;
      _audioEnabled = audioEnabled;
      _setState(CallState.initiating);

      // Initialize WebRTC
      await _initializeWebRTC();

      // Create local stream
      await _createLocalStream();

      // Send call initiation
      final callData = {
        'chat_id': chatId,
        'participant_ids': participantIds,
        'type': type.value,
        'video_enabled': videoEnabled,
        'audio_enabled': audioEnabled,
      };

      _webSocketService.initiateCall(callData);

      // Start call timeout
      _startCallTimeout();

      if (kDebugMode) {
        print('📞 Initiating call to $chatId');
      }
    } catch (e) {
      _setState(CallState.failed);
      _cleanup();

      if (kDebugMode) {
        print('❌ Error initiating call: $e');
      }

      rethrow;
    }
  }

  // Answer an incoming call
  Future<void> answerCall({bool videoEnabled = false}) async {
    try {
      if (_currentState != CallState.ringing ||
          _currentDirection != CallDirection.incoming) {
        throw Exception('No incoming call to answer');
      }

      _videoEnabled = videoEnabled;
      _setState(CallState.connecting);

      // Initialize WebRTC
      await _initializeWebRTC();

      // Create local stream
      await _createLocalStream();

      // Send answer
      _webSocketService.answerCall(_currentCallId!, true);

      // Start the call
      await _startCall();

      if (kDebugMode) {
        print('✅ Answered call: $_currentCallId');
      }
    } catch (e) {
      _setState(CallState.failed);
      _cleanup();

      if (kDebugMode) {
        print('❌ Error answering call: $e');
      }

      rethrow;
    }
  }

  // Reject an incoming call
  void rejectCall() {
    if (_currentState == CallState.ringing &&
        _currentDirection == CallDirection.incoming) {
      _webSocketService.answerCall(_currentCallId!, false);
      _setState(CallState.rejected);
      _cleanup();

      if (kDebugMode) {
        print('❌ Rejected call: $_currentCallId');
      }
    }
  }

  // End the current call
  void endCall() {
    if (_currentCallId != null) {
      _webSocketService.endCall(_currentCallId!);
      _setState(CallState.ended);
      _cleanup();

      if (kDebugMode) {
        print('📞 Ended call: $_currentCallId');
      }
    }
  }

  // Toggle audio
  Future<void> toggleAudio() async {
    if (_localStream != null) {
      _audioEnabled = !_audioEnabled;
      _microphoneEnabled = _audioEnabled;

      final audioTracks = _localStream!.getAudioTracks();
      for (final track in audioTracks) {
        track.enabled = _audioEnabled;
      }

      await _updateMediaState();

      if (kDebugMode) {
        print('🎤 Audio ${_audioEnabled ? 'enabled' : 'disabled'}');
      }
    }
  }

  // Toggle video
  Future<void> toggleVideo() async {
    if (_localStream != null) {
      _videoEnabled = !_videoEnabled;

      final videoTracks = _localStream!.getVideoTracks();
      for (final track in videoTracks) {
        track.enabled = _videoEnabled;
      }

      await _updateMediaState();

      if (kDebugMode) {
        print('🎥 Video ${_videoEnabled ? 'enabled' : 'disabled'}');
      }
    }
  }

  // Toggle speaker
  Future<void> toggleSpeaker() async {
    _speakerEnabled = !_speakerEnabled;

    if (_localStream != null) {
      final audioTracks = _localStream!.getAudioTracks();
      for (final track in audioTracks) {
        await Helper.setSpeakerphoneOn(_speakerEnabled);
      }
    }

    if (kDebugMode) {
      print('🔊 Speaker ${_speakerEnabled ? 'enabled' : 'disabled'}');
    }
  }

  // Switch camera
  Future<void> switchCamera() async {
    if (_localStream != null && _videoEnabled) {
      final videoTracks = _localStream!.getVideoTracks();

      for (final track in videoTracks) {
        await Helper.switchCamera(track);
      }

      _cameraPosition = _cameraPosition == CameraPosition.front
          ? CameraPosition.back
          : CameraPosition.front;

      if (kDebugMode) {
        print('📷 Switched to ${_cameraPosition.name} camera');
      }
    }
  }

  // Start screen sharing
  Future<void> startScreenShare() async {
    try {
      if (!_screenSharing) {
        final screenStream = await navigator.mediaDevices.getDisplayMedia({
          'video': true,
          'audio': true,
        });

        // Replace video track
        if (_peerConnection != null) {
          final senders = await _peerConnection!.getSenders();
          final videoSender = senders.firstWhere(
            (sender) => sender.track?.kind == 'video',
            orElse: () => throw Exception('No video sender found'),
          );

          await videoSender.replaceTrack(screenStream.getVideoTracks().first);
        }

        _screenSharing = true;
        await _updateMediaState();

        if (kDebugMode) {
          print('📺 Screen sharing started');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error starting screen share: $e');
      }
    }
  }

  // Stop screen sharing
  Future<void> stopScreenShare() async {
    try {
      if (_screenSharing) {
        // Switch back to camera
        final cameraStream = await _createCameraStream();

        if (_peerConnection != null && cameraStream != null) {
          final senders = await _peerConnection!.getSenders();
          final videoSender = senders.firstWhere(
            (sender) => sender.track?.kind == 'video',
            orElse: () => throw Exception('No video sender found'),
          );

          await videoSender.replaceTrack(cameraStream.getVideoTracks().first);
        }

        _screenSharing = false;
        await _updateMediaState();

        if (kDebugMode) {
          print('📺 Screen sharing stopped');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error stopping screen share: $e');
      }
    }
  }

  Future<void> _initializeWebRTC() async {
    try {
      final configuration = {
        'iceServers': _iceServers ?? [],
        'iceCandidatePoolSize': 10,
      };

      _peerConnection = await createPeerConnection(configuration);

      _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
        // Send ICE candidate through WebSocket
        _sendICECandidate(candidate);
      };

      _peerConnection!.onAddStream = (MediaStream stream) {
        _remoteStream = stream;

        final callEvent = CallEvent(
          type: CallEventType.remoteStreamAdded,
          callId: _currentCallId,
          data: {'stream': stream},
        );

        _callEventController.add(callEvent);
      };

      _peerConnection!.onRemoveStream = (MediaStream stream) {
        _remoteStream = null;

        final callEvent = CallEvent(
          type: CallEventType.remoteStreamRemoved,
          callId: _currentCallId,
        );

        _callEventController.add(callEvent);
      };

      _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          _setState(CallState.connected);
          _startCallTimer();
          _startQualityMonitoring();
        } else if (state ==
            RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
          _setState(CallState.failed);
          _cleanup();
        }
      };

      if (kDebugMode) {
        print('✅ WebRTC initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing WebRTC: $e');
      }
      rethrow;
    }
  }

  Future<void> _createLocalStream() async {
    try {
      final constraints = {
        'audio': _audioEnabled,
        'video': _videoEnabled
            ? {
                'facingMode': _cameraPosition == CameraPosition.front
                    ? 'user'
                    : 'environment',
              }
            : false,
      };

      _localStream = await navigator.mediaDevices.getUserMedia(constraints);

      if (_peerConnection != null) {
        await _peerConnection!.addStream(_localStream!);
      }

      final callEvent = CallEvent(
        type: CallEventType.localStreamAdded,
        callId: _currentCallId,
        data: {'stream': _localStream},
      );

      _callEventController.add(callEvent);

      if (kDebugMode) {
        print('✅ Local stream created');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error creating local stream: $e');
      }
      rethrow;
    }
  }

  Future<MediaStream?> _createCameraStream() async {
    try {
      final constraints = {
        'video': {
          'facingMode': _cameraPosition == CameraPosition.front
              ? 'user'
              : 'environment',
        },
      };

      return await navigator.mediaDevices.getUserMedia(constraints);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error creating camera stream: $e');
      }
      return null;
    }
  }

  Future<void> _startCall() async {
    try {
      if (_currentDirection == CallDirection.outgoing) {
        // Create offer
        final offer = await _peerConnection!.createOffer();
        await _peerConnection!.setLocalDescription(offer);

        // Send offer through WebSocket
        _sendOffer(offer);
      } else {
        // Create answer
        final answer = await _peerConnection!.createAnswer();
        await _peerConnection!.setLocalDescription(answer);

        // Send answer through WebSocket
        _sendAnswer(answer);
      }

      if (kDebugMode) {
        print('✅ Call negotiation started');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error starting call: $e');
      }
      rethrow;
    }
  }

  void _sendOffer(RTCSessionDescription offer) {
    _webSocketService.sendCustomEvent('webrtc_offer', {
      'call_id': _currentCallId,
      'offer': offer.toMap(),
    });
  }

  void _sendAnswer(RTCSessionDescription answer) {
    _webSocketService.sendCustomEvent('webrtc_answer', {
      'call_id': _currentCallId,
      'answer': answer.toMap(),
    });
  }

  void _sendICECandidate(RTCIceCandidate candidate) {
    _webSocketService.sendCustomEvent('webrtc_ice_candidate', {
      'call_id': _currentCallId,
      'candidate': candidate.toMap(),
    });
  }

  Future<void> _updateMediaState() async {
    if (_currentCallId != null) {
      final mediaState = {
        'audio_enabled': _audioEnabled,
        'video_enabled': _videoEnabled,
        'screen_sharing': _screenSharing,
      };

      _webSocketService.updateCallMedia(_currentCallId!, mediaState);
    }
  }

  void _setState(CallState newState) {
    if (_currentState != newState) {
      _currentState = newState;

      final callEvent = CallEvent(
        type: CallEventType.stateChanged,
        callId: _currentCallId,
        data: {'state': newState.name},
      );

      _callEventController.add(callEvent);

      if (kDebugMode) {
        print('📞 Call state: ${newState.name}');
      }
    }
  }

  void _startCallTimer() {
    _callStartTime = DateTime.now();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final callEvent = CallEvent(
        type: CallEventType.durationUpdate,
        callId: _currentCallId,
        data: {'duration': callDuration?.inSeconds},
      );

      _callEventController.add(callEvent);
    });
  }

  void _startQualityMonitoring() {
    _qualityTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _measureCallQuality();
    });
  }

  Future<void> _measureCallQuality() async {
    if (_peerConnection != null) {
      try {
        final stats = await _peerConnection!.getStats();
        final quality = _calculateQuality(stats);

        if (quality != null) {
          _currentQuality = quality;
          _qualityHistory.add(quality);

          if (_qualityHistory.length > 60) {
            _qualityHistory.removeAt(0);
          }

          _callQualityController.add(quality);

          // Send quality update
          if (_currentCallId != null) {
            _webSocketService.updateCallMedia(_currentCallId!, {
              'quality_score': quality.qualityScore,
              'rtt': quality.rtt,
              'jitter': quality.jitter,
              'packet_loss': quality.packetLoss,
            });
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error measuring call quality: $e');
        }
      }
    }
  }

  CallQuality? _calculateQuality(List<StatsReport> stats) {
    try {
      double rtt = 0;
      double jitter = 0;
      double packetLoss = 0;

      for (final report in stats) {
        if (report.type == 'candidate-pair' &&
            report.values['state'] == 'succeeded') {
          rtt =
              double.tryParse(
                report.values['currentRoundTripTime']?.toString() ?? '0',
              ) ??
              0;
        } else if (report.type == 'inbound-rtp') {
          jitter =
              double.tryParse(report.values['jitter']?.toString() ?? '0') ?? 0;
          final packetsLost =
              int.tryParse(report.values['packetsLost']?.toString() ?? '0') ??
              0;
          final packetsReceived =
              int.tryParse(
                report.values['packetsReceived']?.toString() ?? '0',
              ) ??
              0;

          if (packetsReceived > 0) {
            packetLoss = packetsLost / (packetsLost + packetsReceived);
          }
        }
      }

      // Calculate overall score (1-5)
      double score = 5.0;

      if (rtt > 300) {
        score -= 1;
      } else if (rtt > 150) {
        score -= 0.5;
      }

      if (jitter > 50) {
        score -= 1;
      } else if (jitter > 30) {
        score -= 0.5;
      }

      if (packetLoss > 0.05) {
        score -= 1;
      } else if (packetLoss > 0.02) {
        score -= 0.5;
      }

      score = score.clamp(1.0, 5.0);

      return CallQuality(
        qualityScore: score,
        rtt: rtt.round(),
        jitter: jitter.round(),
        packetLoss: packetLoss,
        bandwidth: 0, // This would need to be calculated from stats
        networkType: 'unknown', // This would need to be detected
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error calculating quality: $e');
      }
      return null;
    }
  }

  void _startRingingTimeout() {
    Timer(const Duration(seconds: 30), () {
      if (_currentState == CallState.ringing) {
        _setState(CallState.timeout);
        _cleanup();
      }
    });
  }

  void _startCallTimeout() {
    Timer(const Duration(seconds: 60), () {
      if (_currentState == CallState.initiating ||
          _currentState == CallState.ringing) {
        _setState(CallState.timeout);
        _cleanup();
      }
    });
  }

  Future<void> _cleanup() async {
    _callTimer?.cancel();
    _callTimer = null;

    _qualityTimer?.cancel();
    _qualityTimer = null;

    if (_localStream != null) {
      await _localStream!.dispose();
      _localStream = null;
    }

    if (_remoteStream != null) {
      await _remoteStream!.dispose();
      _remoteStream = null;
    }

    if (_peerConnection != null) {
      await _peerConnection!.close();
      _peerConnection = null;
    }

    _currentCallId = null;
    _currentChatId = null;
    _currentDirection = null;
    _callStartTime = null;
    _participants.clear();
    _currentQuality = null;

    // Reset media state
    _audioEnabled = true;
    _videoEnabled = false;
    _speakerEnabled = false;
    _microphoneEnabled = true;
    _screenSharing = false;
    _cameraPosition = CameraPosition.front;

    if (kDebugMode) {
      print('🧹 Call cleanup completed');
    }
  }

  String? _getCurrentUserId() {
    // This would typically come from your authentication service
    // For now, return null
    return null;
  }

  // Get call history
  Future<List<Map<String, dynamic>>> getCallHistory() async {
    return await _cacheService.getCachedCalls();
  }

  // Save call to history
  Future<void> _saveCallToHistory() async {
    if (_currentCallId != null && _callStartTime != null) {
      final callData = {
        'id': _currentCallId,
        'chat_id': _currentChatId,
        'type': _currentCallType.value,
        'direction': _currentDirection?.name,
        'start_time': _callStartTime!.toIso8601String(),
        'end_time': DateTime.now().toIso8601String(),
        'duration': callDuration?.inSeconds,
        'status': _currentState.name,
        'participants': _participants.values.map((p) => p.toJson()).toList(),
        'quality_avg': _qualityHistory.isNotEmpty
            ? _qualityHistory
                      .map((q) => q.qualityScore)
                      .reduce((a, b) => a + b) /
                  _qualityHistory.length
            : null,
      };

      await _cacheService.cacheCall(_currentCallId!, callData);
    }
  }

  Future<void> dispose() async {
    await _cleanup();

    await _callEventController.close();
    await _callQualityController.close();
    await _participantController.close();

    if (kDebugMode) {
      print('✅ Call socket service disposed');
    }
  }
}

// Service-specific models (not duplicated in models folder)
enum CallEventType {
  incomingCall,
  callAnswered,
  callRejected,
  callEnded,
  callFailed,
  callBusy,
  callRinging,
  stateChanged,
  localStreamAdded,
  remoteStreamAdded,
  remoteStreamRemoved,
  durationUpdate,
}

class CallEvent {
  final CallEventType type;
  final String? callId;
  final String? chatId;
  final CallType? callType;
  final Map<String, dynamic>? data;

  CallEvent({
    required this.type,
    this.callId,
    this.chatId,
    this.callType,
    this.data,
  });
}

// Riverpod providers
final callSocketServiceProvider = Provider<CallSocketService>((ref) {
  return CallSocketService();
});

final callEventsProvider = StreamProvider<CallEvent>((ref) {
  final service = ref.watch(callSocketServiceProvider);
  return service.callEvents;
});

final callQualityProvider = StreamProvider<CallQuality>((ref) {
  final service = ref.watch(callSocketServiceProvider);
  return service.qualityUpdates;
});

final callParticipantsProvider = StreamProvider<CallParticipant>((ref) {
  final service = ref.watch(callSocketServiceProvider);
  return service.participantUpdates;
});

final currentCallStateProvider = Provider<CallState>((ref) {
  final service = ref.watch(callSocketServiceProvider);
  return service.currentState;
});

final isInCallProvider = Provider<bool>((ref) {
  final service = ref.watch(callSocketServiceProvider);
  return service.isInCall;
});
