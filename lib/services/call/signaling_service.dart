import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../core/exceptions/app_exception.dart';
import '../../core/config/app_config.dart';
import '../storage/secure_storage.dart';
import '../websocket/websocket_service.dart';

enum SignalingState {
  idle,
  connecting,
  connected,
  offering,
  answering,
  stable,
  closed,
  failed,
}

enum SignalingEventType {
  offer,
  answer,
  iceCandidate,
  iceCandidateError,
  connectionStateChange,
  dataChannelOpen,
  dataChannelClose,
  dataChannelMessage,
}

class SignalingEvent {
  final SignalingEventType type;
  final Map<String, dynamic> data;
  final String? callId;
  final String? fromPeerId;
  final DateTime timestamp;

  SignalingEvent({
    required this.type,
    required this.data,
    this.callId,
    this.fromPeerId,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'data': data,
      'call_id': callId,
      'from_peer_id': fromPeerId,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory SignalingEvent.fromJson(Map<String, dynamic> json) {
    return SignalingEvent(
      type: SignalingEventType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SignalingEventType.connectionStateChange,
      ),
      data: json['data'] ?? {},
      callId: json['call_id'],
      fromPeerId: json['from_peer_id'],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }
}

class PeerConnectionInfo {
  final String peerId;
  final RTCPeerConnection peerConnection;
  final List<RTCIceCandidate> pendingCandidates;
  SignalingState state;
  DateTime lastActivity;

  PeerConnectionInfo({
    required this.peerId,
    required this.peerConnection,
    this.state = SignalingState.idle,
    DateTime? lastActivity,
  }) : pendingCandidates = [],
       lastActivity = lastActivity ?? DateTime.now();
}

class SignalingService {
  static SignalingService? _instance;

  final WebSocketService _webSocketService;
  final SecureStorage _secureStorage;

  // Current signaling state
  SignalingState _state = SignalingState.idle;
  String? _currentCallId;
  String? _localPeerId;

  // Peer connections management
  final Map<String, PeerConnectionInfo> _peerConnections = {};

  // Event streams
  final StreamController<SignalingEvent> _eventController =
      StreamController<SignalingEvent>.broadcast();
  final StreamController<SignalingState> _stateController =
      StreamController<SignalingState>.broadcast();

  // WebRTC configuration
  Map<String, dynamic>? _webrtcConfig;
  List<Map<String, dynamic>>? _iceServers;

  // Data channels
  final Map<String, RTCDataChannel> _dataChannels = {};

  // Subscriptions
  final List<StreamSubscription> _subscriptions = [];

  SignalingService._internal()
    : _webSocketService = WebSocketService(),
      _secureStorage = SecureStorage() {
    _initialize();
  }

  factory SignalingService() {
    _instance ??= SignalingService._internal();
    return _instance!;
  }

  // Getters
  SignalingState get state => _state;
  String? get currentCallId => _currentCallId;
  String? get localPeerId => _localPeerId;
  Stream<SignalingEvent> get eventStream => _eventController.stream;
  Stream<SignalingState> get stateStream => _stateController.stream;
  List<String> get connectedPeers => _peerConnections.keys.toList();

  void _initialize() {
    _loadConfiguration();
    _setupWebSocketListeners();
    _generateLocalPeerId();
  }

  Future<void> _loadConfiguration() async {
    try {
      _webrtcConfig = await _secureStorage.getWebRTCCredentials();

      if (_webrtcConfig == null) {
        _iceServers =
            AppConfig.webrtcConfig['iceServers'] as List<Map<String, dynamic>>?;
      } else {
        _iceServers =
            _webrtcConfig!['iceServers'] as List<Map<String, dynamic>>?;
      }

      if (kDebugMode) {
        print('✅ Signaling configuration loaded');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading signaling configuration: $e');
      }
    }
  }

  void _setupWebSocketListeners() {
    final subscription = _webSocketService.eventStream.listen(
      _handleWebSocketEvent,
    );
    _subscriptions.add(subscription);
  }

  void _generateLocalPeerId() {
    _localPeerId = 'peer_${DateTime.now().millisecondsSinceEpoch}';
  }

  void _handleWebSocketEvent(WebSocketEvent event) {
    switch (event.type) {
      case WebSocketEventType.custom:
        _handleCustomWebSocketEvent(event);
        break;
      default:
        break;
    }
  }

  void _handleCustomWebSocketEvent(WebSocketEvent event) {
    final action = event.data['action'] as String?;

    switch (action) {
      case 'webrtc_offer':
        _handleRemoteOffer(event);
        break;
      case 'webrtc_answer':
        _handleRemoteAnswer(event);
        break;
      case 'webrtc_ice_candidate':
        _handleRemoteIceCandidate(event);
        break;
      case 'webrtc_ice_candidate_error':
        _handleIceCandidateError(event);
        break;
      default:
        break;
    }
  }

  void _setState(SignalingState newState) {
    if (_state != newState) {
      _state = newState;
      _stateController.add(newState);

      if (kDebugMode) {
        print('🔄 Signaling state: ${newState.name}');
      }
    }
  }

  // Public API

  Future<void> startCall(String callId, List<String> participantIds) async {
    try {
      _currentCallId = callId;
      _setState(SignalingState.connecting);

      // Create peer connections for all participants
      for (final participantId in participantIds) {
        await _createPeerConnection(participantId);
      }

      if (kDebugMode) {
        print('✅ Call started with ${participantIds.length} participants');
      }
    } catch (e) {
      _setState(SignalingState.failed);
      throw MediaException.recordingFailed();
    }
  }

  Future<void> joinCall(String callId, String remotePeerId) async {
    try {
      _currentCallId = callId;
      _setState(SignalingState.connecting);

      await _createPeerConnection(remotePeerId);

      if (kDebugMode) {
        print('✅ Joined call: $callId');
      }
    } catch (e) {
      _setState(SignalingState.failed);
      throw MediaException.recordingFailed();
    }
  }

  Future<RTCPeerConnection> _createPeerConnection(String peerId) async {
    try {
      // Define the configuration as a Map<String, dynamic>
      final configuration = {
        'iceServers': _iceServers ?? [],
        'iceCandidatePoolSize': 10,
        'bundlePolicy': 'max-bundle',
        'rtcpMuxPolicy': 'require',
      };

      // Create the peer connection using the configuration map
      final peerConnection = await createPeerConnection(configuration);

      final peerInfo = PeerConnectionInfo(
        peerId: peerId,
        peerConnection: peerConnection,
        state: SignalingState.connecting,
      );

      _peerConnections[peerId] = peerInfo;

      // Set up event listeners
      _setupPeerConnectionListeners(peerConnection, peerId);

      if (kDebugMode) {
        print('✅ Peer connection created for: $peerId');
      }

      return peerConnection;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error creating peer connection: $e');
      }
      rethrow;
    }
  }

  void _setupPeerConnectionListeners(RTCPeerConnection pc, String peerId) {
    pc.onIceCandidate = (RTCIceCandidate candidate) {
      _handleLocalIceCandidate(candidate, peerId);
    };

    pc.onIceConnectionState = (RTCIceConnectionState state) {
      _handleIceConnectionStateChange(state, peerId);
    };

    pc.onConnectionState = (RTCPeerConnectionState state) {
      _handlePeerConnectionStateChange(state, peerId);
    };

    pc.onSignalingState = (RTCSignalingState state) {
      _handleSignalingStateChange(state, peerId);
    };

    pc.onAddStream = (MediaStream stream) {
      _handleRemoteStream(stream, peerId);
    };

    pc.onRemoveStream = (MediaStream stream) {
      _handleRemoteStreamRemoved(stream, peerId);
    };

    pc.onDataChannel = (RTCDataChannel channel) {
      _handleDataChannel(channel, peerId);
    };
  }

  Future<void> createOffer(String peerId) async {
    try {
      final peerInfo = _peerConnections[peerId];
      if (peerInfo == null) {
        throw Exception('Peer connection not found: $peerId');
      }

      peerInfo.state = SignalingState.offering;
      _setState(SignalingState.offering);

      final offer = await peerInfo.peerConnection.createOffer();
      await peerInfo.peerConnection.setLocalDescription(offer);

      // Send offer through WebSocket
      _sendSignalingMessage({
        'action': 'webrtc_offer',
        'call_id': _currentCallId,
        'to_peer_id': peerId,
        'from_peer_id': _localPeerId,
        'offer': offer.toMap(),
      });

      if (kDebugMode) {
        print('📤 Offer sent to: $peerId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error creating offer: $e');
      }
      rethrow;
    }
  }

  Future<void> createAnswer(String peerId) async {
    try {
      final peerInfo = _peerConnections[peerId];
      if (peerInfo == null) {
        throw Exception('Peer connection not found: $peerId');
      }

      peerInfo.state = SignalingState.answering;
      _setState(SignalingState.answering);

      final answer = await peerInfo.peerConnection.createAnswer();
      await peerInfo.peerConnection.setLocalDescription(answer);

      // Send answer through WebSocket
      _sendSignalingMessage({
        'action': 'webrtc_answer',
        'call_id': _currentCallId,
        'to_peer_id': peerId,
        'from_peer_id': _localPeerId,
        'answer': answer.toMap(),
      });

      if (kDebugMode) {
        print('📤 Answer sent to: $peerId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error creating answer: $e');
      }
      rethrow;
    }
  }

  void _handleRemoteOffer(WebSocketEvent event) async {
    try {
      final callId = event.data['call_id'] as String;
      final fromPeerId = event.data['from_peer_id'] as String;
      final offerData = event.data['offer'] as Map<String, dynamic>;

      if (callId != _currentCallId) {
        if (kDebugMode) {
          print('⚠️ Received offer for different call: $callId');
        }
        return;
      }

      final offer = RTCSessionDescription(offerData['sdp'], offerData['type']);

      // Get or create peer connection
      RTCPeerConnection? peerConnection =
          _peerConnections[fromPeerId]?.peerConnection;
      if (peerConnection == null) {
        peerConnection = await _createPeerConnection(fromPeerId);
      }

      await peerConnection.setRemoteDescription(offer);

      // Process any pending ICE candidates
      await _processPendingCandidates(fromPeerId);

      // Create and send answer
      await createAnswer(fromPeerId);

      final signalingEvent = SignalingEvent(
        type: SignalingEventType.offer,
        data: event.data,
        callId: callId,
        fromPeerId: fromPeerId,
      );

      _eventController.add(signalingEvent);

      if (kDebugMode) {
        print('📥 Offer received from: $fromPeerId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling remote offer: $e');
      }
    }
  }

  void _handleRemoteAnswer(WebSocketEvent event) async {
    try {
      final callId = event.data['call_id'] as String;
      final fromPeerId = event.data['from_peer_id'] as String;
      final answerData = event.data['answer'] as Map<String, dynamic>;

      if (callId != _currentCallId) {
        if (kDebugMode) {
          print('⚠️ Received answer for different call: $callId');
        }
        return;
      }

      final answer = RTCSessionDescription(
        answerData['sdp'],
        answerData['type'],
      );
      final peerConnection = _peerConnections[fromPeerId]?.peerConnection;

      if (peerConnection != null) {
        await peerConnection.setRemoteDescription(answer);

        // Process any pending ICE candidates
        await _processPendingCandidates(fromPeerId);

        final peerInfo = _peerConnections[fromPeerId];
        if (peerInfo != null) {
          peerInfo.state = SignalingState.stable;
        }
      }

      final signalingEvent = SignalingEvent(
        type: SignalingEventType.answer,
        data: event.data,
        callId: callId,
        fromPeerId: fromPeerId,
      );

      _eventController.add(signalingEvent);

      if (kDebugMode) {
        print('📥 Answer received from: $fromPeerId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling remote answer: $e');
      }
    }
  }

  void _handleRemoteIceCandidate(WebSocketEvent event) async {
    try {
      final callId = event.data['call_id'] as String;
      final fromPeerId = event.data['from_peer_id'] as String;
      final candidateData = event.data['candidate'] as Map<String, dynamic>;

      if (callId != _currentCallId) {
        return;
      }

      final candidate = RTCIceCandidate(
        candidateData['candidate'],
        candidateData['sdpMid'],
        candidateData['sdpMLineIndex'],
      );

      final peerInfo = _peerConnections[fromPeerId];
      if (peerInfo == null) {
        if (kDebugMode) {
          print('⚠️ Received ICE candidate for unknown peer: $fromPeerId');
        }
        return;
      }

      // Check if remote description is set
      if (peerInfo.peerConnection.getRemoteDescription() != null) {
        await peerInfo.peerConnection.addCandidate(candidate);
      } else {
        // Store for later processing
        peerInfo.pendingCandidates.add(candidate);
      }

      final signalingEvent = SignalingEvent(
        type: SignalingEventType.iceCandidate,
        data: event.data,
        callId: callId,
        fromPeerId: fromPeerId,
      );

      _eventController.add(signalingEvent);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling remote ICE candidate: $e');
      }
    }
  }

  void _handleIceCandidateError(WebSocketEvent event) {
    final signalingEvent = SignalingEvent(
      type: SignalingEventType.iceCandidateError,
      data: event.data,
      callId: event.data['call_id'],
      fromPeerId: event.data['from_peer_id'],
    );

    _eventController.add(signalingEvent);

    if (kDebugMode) {
      print('❌ ICE candidate error: ${event.data}');
    }
  }

  Future<void> _processPendingCandidates(String peerId) async {
    final peerInfo = _peerConnections[peerId];
    if (peerInfo == null) return;

    try {
      for (final candidate in peerInfo.pendingCandidates) {
        await peerInfo.peerConnection.addCandidate(candidate);
      }
      peerInfo.pendingCandidates.clear();

      if (kDebugMode) {
        print('✅ Processed pending ICE candidates for: $peerId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error processing pending candidates: $e');
      }
    }
  }

  void _handleLocalIceCandidate(RTCIceCandidate candidate, String peerId) {
    // Send ICE candidate through WebSocket
    _sendSignalingMessage({
      'action': 'webrtc_ice_candidate',
      'call_id': _currentCallId,
      'to_peer_id': peerId,
      'from_peer_id': _localPeerId,
      'candidate': candidate.toMap(),
    });
  }

  void _handleIceConnectionStateChange(
    RTCIceConnectionState state,
    String peerId,
  ) {
    if (kDebugMode) {
      print('🧊 ICE connection state for $peerId: ${state.name}');
    }

    final signalingEvent = SignalingEvent(
      type: SignalingEventType.connectionStateChange,
      data: {'peer_id': peerId, 'ice_connection_state': state.name},
      callId: _currentCallId,
      fromPeerId: peerId,
    );

    _eventController.add(signalingEvent);
  }

  void _handlePeerConnectionStateChange(
    RTCPeerConnectionState state,
    String peerId,
  ) {
    if (kDebugMode) {
      print('🔗 Peer connection state for $peerId: ${state.name}');
    }

    if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
      final peerInfo = _peerConnections[peerId];
      if (peerInfo != null) {
        peerInfo.state = SignalingState.stable;
      }
      _setState(SignalingState.stable);
    } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
      _setState(SignalingState.failed);
    }

    final signalingEvent = SignalingEvent(
      type: SignalingEventType.connectionStateChange,
      data: {'peer_id': peerId, 'peer_connection_state': state.name},
      callId: _currentCallId,
      fromPeerId: peerId,
    );

    _eventController.add(signalingEvent);
  }

  void _handleSignalingStateChange(RTCSignalingState state, String peerId) {
    if (kDebugMode) {
      print('📡 Signaling state for $peerId: ${state.name}');
    }
  }

  void _handleRemoteStream(MediaStream stream, String peerId) {
    if (kDebugMode) {
      print('📺 Remote stream added from: $peerId');
    }

    final signalingEvent = SignalingEvent(
      type: SignalingEventType.connectionStateChange,
      data: {
        'peer_id': peerId,
        'event': 'remote_stream_added',
        'stream_id': stream.id,
      },
      callId: _currentCallId,
      fromPeerId: peerId,
    );

    _eventController.add(signalingEvent);
  }

  void _handleRemoteStreamRemoved(MediaStream stream, String peerId) {
    if (kDebugMode) {
      print('📺 Remote stream removed from: $peerId');
    }

    final signalingEvent = SignalingEvent(
      type: SignalingEventType.connectionStateChange,
      data: {
        'peer_id': peerId,
        'event': 'remote_stream_removed',
        'stream_id': stream.id,
      },
      callId: _currentCallId,
      fromPeerId: peerId,
    );

    _eventController.add(signalingEvent);
  }

  void _handleDataChannel(RTCDataChannel channel, String peerId) {
    _dataChannels['${peerId}_${channel.label}'] = channel;

    channel.onMessage = (RTCDataChannelMessage message) {
      _handleDataChannelMessage(message, peerId, channel.label!);
    };

    channel.onDataChannelState = (RTCDataChannelState state) {
      _handleDataChannelStateChange(state, peerId, channel.label!);
    };

    if (kDebugMode) {
      print('📊 Data channel received from $peerId: ${channel.label}');
    }
  }

  void _handleDataChannelMessage(
    RTCDataChannelMessage message,
    String peerId,
    String channelLabel,
  ) {
    final signalingEvent = SignalingEvent(
      type: SignalingEventType.dataChannelMessage,
      data: {
        'peer_id': peerId,
        'channel_label': channelLabel,
        'message': message.text,
        'is_binary': message.isBinary,
      },
      callId: _currentCallId,
      fromPeerId: peerId,
    );

    _eventController.add(signalingEvent);
  }

  void _handleDataChannelStateChange(
    RTCDataChannelState state,
    String peerId,
    String channelLabel,
  ) {
    final eventType = state == RTCDataChannelState.RTCDataChannelOpen
        ? SignalingEventType.dataChannelOpen
        : SignalingEventType.dataChannelClose;

    final signalingEvent = SignalingEvent(
      type: eventType,
      data: {
        'peer_id': peerId,
        'channel_label': channelLabel,
        'state': state.name,
      },
      callId: _currentCallId,
      fromPeerId: peerId,
    );

    _eventController.add(signalingEvent);

    if (kDebugMode) {
      print('📊 Data channel $channelLabel state: ${state.name}');
    }
  }

  // Data channel management

  Future<RTCDataChannel?> createDataChannel(
    String peerId,
    String label, {
    RTCDataChannelInit? init,
  }) async {
    try {
      final peerConnection = _peerConnections[peerId]?.peerConnection;
      if (peerConnection == null) {
        throw Exception('Peer connection not found: $peerId');
      }

      final dataChannel = await peerConnection.createDataChannel(
        label,
        init ?? RTCDataChannelInit(),
      );

      _dataChannels['${peerId}_$label'] = dataChannel;

      dataChannel.onMessage = (RTCDataChannelMessage message) {
        _handleDataChannelMessage(message, peerId, label);
      };

      dataChannel.onDataChannelState = (RTCDataChannelState state) {
        _handleDataChannelStateChange(state, peerId, label);
      };

      if (kDebugMode) {
        print('📊 Data channel created: $label for $peerId');
      }

      return dataChannel;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error creating data channel: $e');
      }
      return null;
    }
  }

  void sendDataChannelMessage(
    String peerId,
    String channelLabel,
    String message,
  ) {
    final dataChannel = _dataChannels['${peerId}_$channelLabel'];
    if (dataChannel?.state == RTCDataChannelState.RTCDataChannelOpen) {
      dataChannel!.send(RTCDataChannelMessage(message));
    }
  }

  // Utility methods

  void _sendSignalingMessage(Map<String, dynamic> message) {
    _webSocketService.sendCustomEvent('webrtc_signal', message);
  }

  Future<void> addLocalStream(MediaStream stream) async {
    try {
      for (final peerInfo in _peerConnections.values) {
        await peerInfo.peerConnection.addStream(stream);
      }

      if (kDebugMode) {
        print('📹 Local stream added to all peer connections');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error adding local stream: $e');
      }
    }
  }

  Future<void> removeLocalStream(MediaStream stream) async {
    try {
      for (final peerInfo in _peerConnections.values) {
        await peerInfo.peerConnection.removeStream(stream);
      }

      if (kDebugMode) {
        print('📹 Local stream removed from all peer connections');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error removing local stream: $e');
      }
    }
  }

  RTCPeerConnection? getPeerConnection(String peerId) {
    return _peerConnections[peerId]?.peerConnection;
  }

  List<RTCDataChannel> getDataChannels(String peerId) {
    return _dataChannels.entries
        .where((entry) => entry.key.startsWith('${peerId}_'))
        .map((entry) => entry.value)
        .toList();
  }

  // Statistics

  Future<Map<String, dynamic>> getSignalingStatistics() async {
    final stats = <String, dynamic>{
      'state': _state.name,
      'current_call_id': _currentCallId,
      'local_peer_id': _localPeerId,
      'peer_connections': _peerConnections.length,
      'data_channels': _dataChannels.length,
      'peers': <String, dynamic>{},
    };

    for (final entry in _peerConnections.entries) {
      final peerId = entry.key;
      final peerInfo = entry.value;

      try {
        final peerStats = await peerInfo.peerConnection.getStats();
        stats['peers'][peerId] = {
          'state': peerInfo.state.name,
          'last_activity': peerInfo.lastActivity.toIso8601String(),
          'pending_candidates': peerInfo.pendingCandidates.length,
          'stats_reports': peerStats.length,
        };
      } catch (e) {
        stats['peers'][peerId] = {
          'state': peerInfo.state.name,
          'last_activity': peerInfo.lastActivity.toIso8601String(),
          'pending_candidates': peerInfo.pendingCandidates.length,
          'error': e.toString(),
        };
      }
    }

    return stats;
  }

  // Cleanup

  Future<void> endCall() async {
    try {
      // Close all peer connections
      for (final peerInfo in _peerConnections.values) {
        await peerInfo.peerConnection.close();
      }

      // Close all data channels
      for (final dataChannel in _dataChannels.values) {
        await dataChannel.close();
      }

      _peerConnections.clear();
      _dataChannels.clear();
      _currentCallId = null;
      _setState(SignalingState.closed);

      if (kDebugMode) {
        print('✅ Call ended and connections closed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error ending call: $e');
      }
    }
  }

  Future<void> removePeer(String peerId) async {
    try {
      final peerInfo = _peerConnections.remove(peerId);
      if (peerInfo != null) {
        await peerInfo.peerConnection.close();
      }

      // Remove associated data channels
      final channelsToRemove = _dataChannels.keys
          .where((key) => key.startsWith('${peerId}_'))
          .toList();

      for (final channelKey in channelsToRemove) {
        final channel = _dataChannels.remove(channelKey);
        await channel?.close();
      }

      if (kDebugMode) {
        print('✅ Peer removed: $peerId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error removing peer: $e');
      }
    }
  }

  Future<void> dispose() async {
    await endCall();

    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();

    await _eventController.close();
    await _stateController.close();

    if (kDebugMode) {
      print('✅ Signaling service disposed');
    }
  }
}

// Riverpod providers
final signalingServiceProvider = Provider<SignalingService>((ref) {
  return SignalingService();
});

final signalingStateProvider = StreamProvider<SignalingState>((ref) {
  final service = ref.watch(signalingServiceProvider);
  return service.stateStream;
});

final signalingEventProvider = StreamProvider<SignalingEvent>((ref) {
  final service = ref.watch(signalingServiceProvider);
  return service.eventStream;
});

final connectedPeersProvider = Provider<List<String>>((ref) {
  final service = ref.watch(signalingServiceProvider);
  return service.connectedPeers;
});
