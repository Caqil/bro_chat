import 'dart:async';
import 'package:bro_chat/models/call/call_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../core/exceptions/app_exception.dart';
import '../../core/constants/app_constants.dart';
import '../storage/cache_service.dart';
import '../storage/local_storage.dart';
import '../websocket/call_socket.dart';
import '../notification/notification_handler.dart';
import 'signaling_service.dart';
import 'webrtc_service.dart';

enum CallManagerState {
  idle,
  initiating,
  ringing,
  connecting,
  connected,
  ended,
  failed,
  busy,
  timeout,
}

enum CallEndReason {
  normal,
  busy,
  declined,
  timeout,
  networkError,
  serverError,
  userCancelled,
}

class CallInfo {
  final String id;
  final String chatId;
  final CallType type;
  final CallDirection direction;
  final List<String> participants;
  final DateTime startTime;
  final String? callerName;
  final String? callerAvatar;
  DateTime? endTime;
  CallEndReason? endReason;
  int? duration;

  CallInfo({
    required this.id,
    required this.chatId,
    required this.type,
    required this.direction,
    required this.participants,
    required this.startTime,
    this.callerName,
    this.callerAvatar,
    this.endTime,
    this.endReason,
    this.duration,
  });

  CallInfo copyWith({
    String? id,
    String? chatId,
    CallType? type,
    CallDirection? direction,
    List<String>? participants,
    DateTime? startTime,
    String? callerName,
    String? callerAvatar,
    DateTime? endTime,
    CallEndReason? endReason,
    int? duration,
  }) {
    return CallInfo(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      type: type ?? this.type,
      direction: direction ?? this.direction,
      participants: participants ?? this.participants,
      startTime: startTime ?? this.startTime,
      callerName: callerName ?? this.callerName,
      callerAvatar: callerAvatar ?? this.callerAvatar,
      endTime: endTime ?? this.endTime,
      endReason: endReason ?? this.endReason,
      duration: duration ?? this.duration,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_id': chatId,
      'type': type.name,
      'direction': direction.name,
      'participants': participants,
      'start_time': startTime.toIso8601String(),
      'caller_name': callerName,
      'caller_avatar': callerAvatar,
      'end_time': endTime?.toIso8601String(),
      'end_reason': endReason?.name,
      'duration': duration,
    };
  }

  factory CallInfo.fromJson(Map<String, dynamic> json) {
    return CallInfo(
      id: json['id'],
      chatId: json['chat_id'],
      type: CallType.values.firstWhere((t) => t.name == json['type']),
      direction: CallDirection.values.firstWhere(
        (d) => d.name == json['direction'],
      ),
      participants: List<String>.from(json['participants'] ?? []),
      startTime: DateTime.parse(json['start_time']),
      callerName: json['caller_name'],
      callerAvatar: json['caller_avatar'],
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'])
          : null,
      endReason: json['end_reason'] != null
          ? CallEndReason.values.firstWhere((r) => r.name == json['end_reason'])
          : null,
      duration: json['duration'],
    );
  }
}

class CallManager {
  static CallManager? _instance;

  final CallSocketService _callSocket;
  final SignalingService _signaling;
  final WebRTCService _webrtc;
  final NotificationHandler _notificationHandler;
  final CacheService _cacheService;
  final LocalStorage _localStorage;

  // Current call state
  CallManagerState _state = CallManagerState.idle;
  CallInfo? _currentCall;
  Timer? _callTimer;
  Timer? _timeoutTimer;

  // Streams
  final StreamController<CallManagerState> _stateController =
      StreamController<CallManagerState>.broadcast();
  final StreamController<CallInfo?> _callInfoController =
      StreamController<CallInfo?>.broadcast();
  final StreamController<int> _durationController =
      StreamController<int>.broadcast();

  // Media state
  bool _isAudioEnabled = true;
  bool _isVideoEnabled = false;
  bool _isSpeakerEnabled = false;
  bool _isMicrophoneEnabled = true;
  bool _isScreenSharing = false;
  CameraPosition _cameraPosition = CameraPosition.front;

  // Call history
  final List<CallInfo> _callHistory = [];
  static const int _maxHistoryItems = 100;

  CallManager._internal()
    : _callSocket = CallSocketService(),
      _signaling = SignalingService(),
      _webrtc = WebRTCService(),
      _notificationHandler = NotificationHandler(),
      _cacheService = CacheService(),
      _localStorage = LocalStorage() {
    _initialize();
  }

  factory CallManager() {
    _instance ??= CallManager._internal();
    return _instance!;
  }

  // Getters
  CallManagerState get state => _state;
  CallInfo? get currentCall => _currentCall;
  bool get isInCall => _state == CallManagerState.connected;
  bool get isAudioEnabled => _isAudioEnabled;
  bool get isVideoEnabled => _isVideoEnabled;
  bool get isSpeakerEnabled => _isSpeakerEnabled;
  bool get isMicrophoneEnabled => _isMicrophoneEnabled;
  bool get isScreenSharing => _isScreenSharing;
  CameraPosition get cameraPosition => _cameraPosition;
  List<CallInfo> get callHistory => List.unmodifiable(_callHistory);

  // Streams
  Stream<CallManagerState> get stateStream => _stateController.stream;
  Stream<CallInfo?> get callInfoStream => _callInfoController.stream;
  Stream<int> get durationStream => _durationController.stream;

  void _initialize() {
    // Listen to call socket events
    _callSocket.callEvents.listen(_handleCallEvent);

    // Load call history
    _loadCallHistory();
  }

  Future<void> _loadCallHistory() async {
    try {
      final cachedCalls = await _cacheService.getCachedCalls();
      _callHistory.clear();
      for (final callData in cachedCalls) {
        _callHistory.add(CallInfo.fromJson(callData));
      }

      // Sort by start time (newest first)
      _callHistory.sort((a, b) => b.startTime.compareTo(a.startTime));

      if (kDebugMode) {
        print('✅ Loaded ${_callHistory.length} calls from history');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading call history: $e');
      }
    }
  }

  void _handleCallEvent(CallEvent event) {
    switch (event.type) {
      case CallEventType.incomingCall:
        _handleIncomingCall(event);
        break;
      case CallEventType.callAnswered:
        _handleCallAnswered(event);
        break;
      case CallEventType.callRejected:
        _handleCallRejected(event);
        break;
      case CallEventType.callEnded:
        _handleCallEnded(event);
        break;
      case CallEventType.callFailed:
        _handleCallFailed(event);
        break;
      case CallEventType.callBusy:
        _handleCallBusy(event);
        break;
      case CallEventType.stateChanged:
        _handleStateChanged(event);
        break;
      default:
        break;
    }
  }

  void _handleIncomingCall(CallEvent event) {
    if (_state != CallManagerState.idle) {
      // Already in a call, send busy signal
      _callSocket.rejectCall();
      return;
    }

    _currentCall = CallInfo(
      id: event.callId ?? '',
      chatId: event.chatId ?? '',
      type: event.callType ?? CallType.voice,
      direction: CallDirection.incoming,
      participants: event.data?['participants'] ?? [],
      startTime: DateTime.now(),
      callerName: event.data?['caller_name'],
      callerAvatar: event.data?['caller_avatar'],
    );

    _setState(CallManagerState.ringing);
    _callInfoController.add(_currentCall);

    // Show incoming call notification
    _showIncomingCallNotification();

    // Start timeout timer
    _startTimeoutTimer();
  }

  void _handleCallAnswered(CallEvent event) {
    if (_state == CallManagerState.initiating) {
      _setState(CallManagerState.connecting);
      _cancelTimeoutTimer();
    }
  }

  void _handleCallRejected(CallEvent event) {
    _endCall(CallEndReason.declined);
  }

  void _handleCallEnded(CallEvent event) {
    final reason = _parseEndReason(event.data?['reason']);
    _endCall(reason);
  }

  void _handleCallFailed(CallEvent event) {
    _endCall(CallEndReason.networkError);
  }

  void _handleCallBusy(CallEvent event) {
    _endCall(CallEndReason.busy);
  }

  void _handleStateChanged(CallEvent event) {
    final stateString = event.data?['state'] as String?;
    if (stateString == 'connected') {
      _setState(CallManagerState.connected);
      _startCallTimer();
    }
  }

  CallEndReason _parseEndReason(String? reason) {
    switch (reason) {
      case 'busy':
        return CallEndReason.busy;
      case 'declined':
        return CallEndReason.declined;
      case 'timeout':
        return CallEndReason.timeout;
      case 'network_error':
        return CallEndReason.networkError;
      case 'server_error':
        return CallEndReason.serverError;
      case 'user_cancelled':
        return CallEndReason.userCancelled;
      default:
        return CallEndReason.normal;
    }
  }

  void _setState(CallManagerState newState) {
    if (_state != newState) {
      _state = newState;
      _stateController.add(newState);

      if (kDebugMode) {
        print('📞 Call Manager state: ${newState.name}');
      }
    }
  }

  void _startCallTimer() {
    _callTimer?.cancel();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentCall != null) {
        final duration = DateTime.now().difference(_currentCall!.startTime);
        _durationController.add(duration.inSeconds);
      }
    });
  }

  void _stopCallTimer() {
    _callTimer?.cancel();
    _callTimer = null;
  }

  void _startTimeoutTimer() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(
      Duration(seconds: AppConstants.callRingingTimeout),
      () {
        if (_state == CallManagerState.ringing ||
            _state == CallManagerState.initiating) {
          _endCall(CallEndReason.timeout);
        }
      },
    );
  }

  void _cancelTimeoutTimer() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
  }

  Future<void> _showIncomingCallNotification() async {
    if (_currentCall == null) return;

    try {
      await _notificationHandler.testNotification(
        title: 'Incoming Call',
        body: '${_currentCall!.callerName ?? 'Unknown'} is calling you',
        type: NotificationType.call,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error showing incoming call notification: $e');
      }
    }
  }

  // Public API

  Future<bool> initiateCall({
    required String chatId,
    required List<String> participants,
    CallType type = CallType.voice,
    bool videoEnabled = false,
    String? callerName,
  }) async {
    if (_state != CallManagerState.idle) {
      throw Exception('Already in a call');
    }

    try {
      _setState(CallManagerState.initiating);

      _currentCall = CallInfo(
        id: '', // Will be set by the server
        chatId: chatId,
        type: type,
        direction: CallDirection.outgoing,
        participants: participants,
        startTime: DateTime.now(),
        callerName: callerName,
      );

      _callInfoController.add(_currentCall);

      // Initialize WebRTC
      await _webrtc.initialize();

      // Initiate call through socket
      await _callSocket.initiateCall(
        chatId: chatId,
        participantIds: participants,
        type: type,
        videoEnabled: videoEnabled,
        audioEnabled: true,
      );

      _startTimeoutTimer();

      if (kDebugMode) {
        print('📞 Call initiated to $chatId');
      }

      return true;
    } catch (e) {
      _endCall(CallEndReason.serverError);

      if (kDebugMode) {
        print('❌ Error initiating call: $e');
      }

      return false;
    }
  }

  Future<bool> answerCall({bool videoEnabled = false}) async {
    if (_state != CallManagerState.ringing ||
        _currentCall?.direction != CallDirection.incoming) {
      return false;
    }

    try {
      _setState(CallManagerState.connecting);

      // Initialize WebRTC
      await _webrtc.initialize();

      // Answer call through socket
      await _callSocket.answerCall(videoEnabled: videoEnabled);

      _cancelTimeoutTimer();

      if (kDebugMode) {
        print('✅ Call answered');
      }

      return true;
    } catch (e) {
      _endCall(CallEndReason.serverError);

      if (kDebugMode) {
        print('❌ Error answering call: $e');
      }

      return false;
    }
  }

  void rejectCall() {
    if (_state != CallManagerState.ringing ||
        _currentCall?.direction != CallDirection.incoming) {
      return;
    }

    _callSocket.rejectCall();
    _endCall(CallEndReason.declined);

    if (kDebugMode) {
      print('❌ Call rejected');
    }
  }

  void endCall() {
    if (_state == CallManagerState.idle) {
      return;
    }

    _callSocket.endCall();
    _endCall(CallEndReason.normal);

    if (kDebugMode) {
      print('📞 Call ended by user');
    }
  }

  void _endCall(CallEndReason reason) {
    if (_currentCall != null) {
      _currentCall = _currentCall!.copyWith(
        endTime: DateTime.now(),
        endReason: reason,
        duration: _currentCall!.endTime != null
            ? _currentCall!.endTime!
                  .difference(_currentCall!.startTime)
                  .inSeconds
            : DateTime.now().difference(_currentCall!.startTime).inSeconds,
      );

      // Save to history
      _addToHistory(_currentCall!);
    }

    _setState(CallManagerState.ended);
    _stopCallTimer();
    _cancelTimeoutTimer();

    // Cleanup WebRTC
    _webrtc.cleanup();

    // Reset call info after a delay
    Timer(const Duration(seconds: 2), () {
      _currentCall = null;
      _callInfoController.add(null);
      _setState(CallManagerState.idle);
    });
  }

  // Media controls

  Future<void> toggleAudio() async {
    try {
      _isAudioEnabled = !_isAudioEnabled;
      _isMicrophoneEnabled = _isAudioEnabled;
      await _callSocket.toggleAudio();

      if (kDebugMode) {
        print('🎤 Audio ${_isAudioEnabled ? 'enabled' : 'disabled'}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error toggling audio: $e');
      }
    }
  }

  Future<void> toggleVideo() async {
    try {
      _isVideoEnabled = !_isVideoEnabled;
      await _callSocket.toggleVideo();

      if (kDebugMode) {
        print('🎥 Video ${_isVideoEnabled ? 'enabled' : 'disabled'}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error toggling video: $e');
      }
    }
  }

  Future<void> toggleSpeaker() async {
    try {
      _isSpeakerEnabled = !_isSpeakerEnabled;
      await _callSocket.toggleSpeaker();

      if (kDebugMode) {
        print('🔊 Speaker ${_isSpeakerEnabled ? 'enabled' : 'disabled'}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error toggling speaker: $e');
      }
    }
  }

  Future<void> switchCamera() async {
    try {
      _cameraPosition = _cameraPosition == CameraPosition.front
          ? CameraPosition.back
          : CameraPosition.front;
      await _callSocket.switchCamera();

      if (kDebugMode) {
        print('📷 Switched to ${_cameraPosition.name} camera');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error switching camera: $e');
      }
    }
  }

  Future<void> startScreenShare() async {
    try {
      _isScreenSharing = true;
      await _callSocket.startScreenShare();

      if (kDebugMode) {
        print('📺 Screen sharing started');
      }
    } catch (e) {
      _isScreenSharing = false;
      if (kDebugMode) {
        print('❌ Error starting screen share: $e');
      }
    }
  }

  Future<void> stopScreenShare() async {
    try {
      _isScreenSharing = false;
      await _callSocket.stopScreenShare();

      if (kDebugMode) {
        print('📺 Screen sharing stopped');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error stopping screen share: $e');
      }
    }
  }

  // Call history management

  void _addToHistory(CallInfo call) {
    _callHistory.insert(0, call);

    // Limit history size
    if (_callHistory.length > _maxHistoryItems) {
      _callHistory.removeRange(_maxHistoryItems, _callHistory.length);
    }

    // Save to cache
    _saveCallHistory();
  }

  Future<void> _saveCallHistory() async {
    try {
      final historyData = _callHistory.map((call) => call.toJson()).toList();
      await _cacheService.cache('call_history', historyData);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving call history: $e');
      }
    }
  }

  void clearCallHistory() {
    _callHistory.clear();
    _saveCallHistory();

    if (kDebugMode) {
      print('🗑️ Call history cleared');
    }
  }

  List<CallInfo> getCallHistory({
    int? limit,
    CallType? type,
    CallDirection? direction,
  }) {
    var history = _callHistory.where((call) {
      if (type != null && call.type != type) return false;
      if (direction != null && call.direction != direction) return false;
      return true;
    }).toList();

    if (limit != null && limit < history.length) {
      history = history.take(limit).toList();
    }

    return history;
  }

  // Statistics

  Map<String, dynamic> getCallStatistics() {
    final totalCalls = _callHistory.length;
    final incomingCalls = _callHistory
        .where((c) => c.direction == CallDirection.incoming)
        .length;
    final outgoingCalls = _callHistory
        .where((c) => c.direction == CallDirection.outgoing)
        .length;
    final answeredCalls = _callHistory
        .where((c) => c.endReason == CallEndReason.normal)
        .length;
    final missedCalls = _callHistory
        .where(
          (c) =>
              c.endReason == CallEndReason.timeout ||
              c.endReason == CallEndReason.declined,
        )
        .length;

    final totalDuration = _callHistory
        .where((c) => c.duration != null)
        .fold<int>(0, (sum, call) => sum + (call.duration ?? 0));

    final averageDuration = totalCalls > 0 ? totalDuration / totalCalls : 0;

    return {
      'total_calls': totalCalls,
      'incoming_calls': incomingCalls,
      'outgoing_calls': outgoingCalls,
      'answered_calls': answeredCalls,
      'missed_calls': missedCalls,
      'total_duration_seconds': totalDuration,
      'average_duration_seconds': averageDuration.round(),
    };
  }

  // Cleanup

  Future<void> dispose() async {
    _stopCallTimer();
    _cancelTimeoutTimer();
    await _webrtc.dispose();
    await _stateController.close();
    await _callInfoController.close();
    await _durationController.close();

    if (kDebugMode) {
      print('✅ Call Manager disposed');
    }
  }
}

// Riverpod providers
final callManagerProvider = Provider<CallManager>((ref) {
  return CallManager();
});

final callStateProvider = StreamProvider<CallManagerState>((ref) {
  final callManager = ref.watch(callManagerProvider);
  return callManager.stateStream;
});

final currentCallProvider = StreamProvider<CallInfo?>((ref) {
  final callManager = ref.watch(callManagerProvider);
  return callManager.callInfoStream;
});

final callDurationProvider = StreamProvider<int>((ref) {
  final callManager = ref.watch(callManagerProvider);
  return callManager.durationStream;
});

final callHistoryProvider = Provider<List<CallInfo>>((ref) {
  final callManager = ref.watch(callManagerProvider);
  return callManager.callHistory;
});

final callStatisticsProvider = Provider<Map<String, dynamic>>((ref) {
  final callManager = ref.watch(callManagerProvider);
  return callManager.getCallStatistics();
});

final isInCallProvider = Provider<bool>((ref) {
  final callManager = ref.watch(callManagerProvider);
  return callManager.isInCall;
});
