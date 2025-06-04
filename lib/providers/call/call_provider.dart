import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../../models/call/call_settings.dart';
import '../../services/api/api_service.dart';
import '../../services/websocket/call_socket.dart';
import '../../services/storage/cache_service.dart';
import '../../models/call/call_model.dart';
import '../../models/call/call_participant.dart';
import '../../models/common/api_response.dart';
import 'webrtc_provider.dart';

// Call state
class CallProviderState {
  final CallModel? currentCall;
  final List<CallParticipant> participants;
  final bool isLoading;
  final String? error;
  final bool isInitialized;
  final Duration? callDuration;
  final DateTime? callStartTime;
  final CallQuality? currentQuality;
  final List<CallQuality> qualityHistory;

  CallProviderState({
    this.currentCall,
    this.participants = const [],
    this.isLoading = false,
    this.error,
    this.isInitialized = false,
    this.callDuration,
    this.callStartTime,
    this.currentQuality,
    this.qualityHistory = const [],
  });

  CallProviderState copyWith({
    CallModel? currentCall,
    List<CallParticipant>? participants,
    bool? isLoading,
    String? error,
    bool? isInitialized,
    Duration? callDuration,
    DateTime? callStartTime,
    CallQuality? currentQuality,
    List<CallQuality>? qualityHistory,
  }) {
    return CallProviderState(
      currentCall: currentCall ?? this.currentCall,
      participants: participants ?? this.participants,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isInitialized: isInitialized ?? this.isInitialized,
      callDuration: callDuration ?? this.callDuration,
      callStartTime: callStartTime ?? this.callStartTime,
      currentQuality: currentQuality ?? this.currentQuality,
      qualityHistory: qualityHistory ?? this.qualityHistory,
    );
  }

  bool get hasActiveCall => currentCall != null && currentCall!.isActive;
  bool get isInCall => currentCall?.status == CallStatus.ongoing;
  bool get isVideoCall => currentCall?.isVideoCall ?? false;
  int get participantCount => participants.length;

  CallParticipant? getParticipant(String userId) {
    try {
      return participants.firstWhere((p) => p.userId == userId);
    } catch (e) {
      return null;
    }
  }

  List<CallParticipant> get connectedParticipants => participants
      .where((p) => p.status == ParticipantStatus.connected)
      .toList();
}

class CallNotifier extends StateNotifier<AsyncValue<CallProviderState>> {
  final ApiService _apiService;
  final CallSocketService _callSocketService;
  final CacheService _cacheService;
  final WebRTCNotifier _webrtcNotifier;

  StreamSubscription<CallEvent>? _callEventSubscription;
  StreamSubscription<CallQuality>? _qualitySubscription;
  StreamSubscription<CallParticipant>? _participantSubscription;

  Timer? _durationTimer;
  Timer? _qualityTimer;

  CallNotifier({
    required ApiService apiService,
    required CallSocketService callSocketService,
    required CacheService cacheService,
    required WebRTCNotifier webrtcNotifier,
  }) : _apiService = apiService,
       _callSocketService = callSocketService,
       _cacheService = cacheService,
       _webrtcNotifier = webrtcNotifier,
       super(AsyncValue.data(CallProviderState())) {
    _initialize();
  }

  void _initialize() {
    _setupSubscriptions();
    state = AsyncValue.data(state.value!.copyWith(isInitialized: true));
  }

  void _setupSubscriptions() {
    // Listen to call events
    _callEventSubscription = _callSocketService.callEvents.listen(
      _handleCallEvent,
    );

    // Listen to quality updates
    _qualitySubscription = _callSocketService.qualityUpdates.listen(
      _handleQualityUpdate,
    );

    // Listen to participant updates
    _participantSubscription = _callSocketService.participantUpdates.listen(
      _handleParticipantUpdate,
    );
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
      case CallEventType.callRinging:
        _handleCallRinging(event);
        break;
      case CallEventType.stateChanged:
        _handleStateChanged(event);
        break;
      case CallEventType.durationUpdate:
        _handleDurationUpdate(event);
        break;
      default:
        break;
    }
  }

  void _handleIncomingCall(CallEvent event) {
    state.whenData((callState) {
      final callData = event.data;
      if (callData != null) {
        final call = CallModel(
          id: event.callId ?? '',
          chatId: callData['chat_id'] ?? '',
          initiatorId: callData['initiator_id'] ?? '',
          participantIds: List<String>.from(callData['participant_ids'] ?? []),
          type: CallType.fromString(callData['type']),
          status: CallStatus.ringing,
          settings: CallSettings.fromJson(callData['settings'] ?? {}),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        state = AsyncValue.data(callState.copyWith(currentCall: call));
      }
    });
  }

  void _handleCallAnswered(CallEvent event) {
    state.whenData((callState) {
      if (callState.currentCall != null) {
        final updatedCall = callState.currentCall!.copyWith(
          status: CallStatus.connecting,
        );
        state = AsyncValue.data(callState.copyWith(currentCall: updatedCall));
      }
    });
  }

  void _handleCallRejected(CallEvent event) {
    state.whenData((callState) {
      if (callState.currentCall != null) {
        final updatedCall = callState.currentCall!.copyWith(
          status: CallStatus.declined,
          endedAt: DateTime.now(),
        );
        state = AsyncValue.data(callState.copyWith(currentCall: updatedCall));
        _endCall();
      }
    });
  }

  void _handleCallEnded(CallEvent event) {
    state.whenData((callState) {
      if (callState.currentCall != null) {
        final duration = event.data?['duration'] as int?;
        final updatedCall = callState.currentCall!.copyWith(
          status: CallStatus.ended,
          endedAt: DateTime.now(),
          duration: duration != null ? Duration(seconds: duration) : null,
        );
        state = AsyncValue.data(callState.copyWith(currentCall: updatedCall));
        _endCall();
      }
    });
  }

  void _handleCallFailed(CallEvent event) {
    state.whenData((callState) {
      if (callState.currentCall != null) {
        final updatedCall = callState.currentCall!.copyWith(
          status: CallStatus.failed,
          endedAt: DateTime.now(),
          endReason: event.data?['reason'] as String?,
        );
        state = AsyncValue.data(
          callState.copyWith(
            currentCall: updatedCall,
            error: event.data?['reason'] as String?,
          ),
        );
        _endCall();
      }
    });
  }

  void _handleCallRinging(CallEvent event) {
    state.whenData((callState) {
      if (callState.currentCall != null) {
        final updatedCall = callState.currentCall!.copyWith(
          status: CallStatus.ringing,
        );
        state = AsyncValue.data(callState.copyWith(currentCall: updatedCall));
      }
    });
  }

  void _handleStateChanged(CallEvent event) {
    final stateData = event.data?['state'] as String?;
    if (stateData != null) {
      final callStatus = CallStatus.fromString(stateData);

      state.whenData((callState) {
        if (callState.currentCall != null) {
          final updatedCall = callState.currentCall!.copyWith(
            status: callStatus,
          );
          state = AsyncValue.data(callState.copyWith(currentCall: updatedCall));

          // Start duration timer when call connects
          if (callStatus == CallStatus.ongoing &&
              callState.callStartTime == null) {
            _startDurationTimer();
            state = AsyncValue.data(
              state.value!.copyWith(callStartTime: DateTime.now()),
            );
          }
        }
      });
    }
  }

  void _handleDurationUpdate(CallEvent event) {
    final duration = event.data?['duration'] as int?;
    if (duration != null) {
      state.whenData((callState) {
        state = AsyncValue.data(
          callState.copyWith(callDuration: Duration(seconds: duration)),
        );
      });
    }
  }

  void _handleQualityUpdate(CallQuality quality) {
    state.whenData((callState) {
      final updatedHistory = [...callState.qualityHistory, quality];

      // Keep only last 60 quality measurements
      if (updatedHistory.length > 60) {
        updatedHistory.removeAt(0);
      }

      state = AsyncValue.data(
        callState.copyWith(
          currentQuality: quality,
          qualityHistory: updatedHistory,
        ),
      );
    });
  }

  void _handleParticipantUpdate(CallParticipant participant) {
    state.whenData((callState) {
      final updatedParticipants = List<CallParticipant>.from(
        callState.participants,
      );
      final index = updatedParticipants.indexWhere(
        (p) => p.userId == participant.userId,
      );

      if (index != -1) {
        updatedParticipants[index] = participant;
      } else {
        updatedParticipants.add(participant);
      }

      state = AsyncValue.data(
        callState.copyWith(participants: updatedParticipants),
      );
    });
  }

  // Public methods for call management
  Future<void> initiateCall({
    required String chatId,
    required List<String> participantIds,
    CallType type = CallType.voice,
    bool videoEnabled = false,
    bool audioEnabled = true,
  }) async {
    try {
      state = AsyncValue.data(state.value!.copyWith(isLoading: true));

      final response = await _apiService.initiateCall(
        participantIds: participantIds,
        chatId: chatId,
        type: type.value,
        videoEnabled: videoEnabled,
        audioEnabled: audioEnabled,
      );

      if (response.success && response.data != null) {
        final call = response.data!;

        state = AsyncValue.data(
          state.value!.copyWith(currentCall: call, isLoading: false),
        );

        // Start WebRTC call
        await _webrtcNotifier.startCall(call.id, video: videoEnabled);

        if (kDebugMode) print('📞 Call initiated: ${call.id}');
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      state = AsyncValue.data(
        state.value!.copyWith(isLoading: false, error: e.toString()),
      );
      rethrow;
    }
  }

  Future<void> answerCall({bool videoEnabled = false}) async {
    final currentCall = state.value?.currentCall;
    if (currentCall == null) return;

    try {
      state = AsyncValue.data(state.value!.copyWith(isLoading: true));

      final response = await _apiService.answerCall(
        currentCall.id,
        accept: true,
      );

      if (response.success) {
        // Answer WebRTC call
        await _webrtcNotifier.answerCall(currentCall.id, video: videoEnabled);

        state = AsyncValue.data(state.value!.copyWith(isLoading: false));

        if (kDebugMode) print('✅ Call answered: ${currentCall.id}');
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      state = AsyncValue.data(
        state.value!.copyWith(isLoading: false, error: e.toString()),
      );
      rethrow;
    }
  }

  Future<void> rejectCall() async {
    final currentCall = state.value?.currentCall;
    if (currentCall == null) return;

    try {
      final response = await _apiService.answerCall(
        currentCall.id,
        accept: false,
      );

      if (response.success) {
        state.whenData((callState) {
          final updatedCall = callState.currentCall!.copyWith(
            status: CallStatus.declined,
            endedAt: DateTime.now(),
          );
          state = AsyncValue.data(callState.copyWith(currentCall: updatedCall));
        });

        _endCall();

        if (kDebugMode) print('❌ Call rejected: ${currentCall.id}');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error rejecting call: $e');
    }
  }

  Future<void> endCall() async {
    final currentCall = state.value?.currentCall;
    if (currentCall == null) return;

    try {
      final response = await _apiService.endCall(currentCall.id);

      if (response.success) {
        state.whenData((callState) {
          final updatedCall = callState.currentCall!.copyWith(
            status: CallStatus.ended,
            endedAt: DateTime.now(),
            duration: callState.callDuration,
          );
          state = AsyncValue.data(callState.copyWith(currentCall: updatedCall));
        });

        _endCall();

        if (kDebugMode) print('📞 Call ended: ${currentCall.id}');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error ending call: $e');
    }
  }

  Future<void> joinCall(String callId) async {
    try {
      state = AsyncValue.data(state.value!.copyWith(isLoading: true));

      final response = await _apiService.joinCall(callId);

      if (response.success) {
        // Load call details
        await _loadCall(callId);

        state = AsyncValue.data(state.value!.copyWith(isLoading: false));

        if (kDebugMode) print('👥 Joined call: $callId');
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      state = AsyncValue.data(
        state.value!.copyWith(isLoading: false, error: e.toString()),
      );
      rethrow;
    }
  }

  Future<void> leaveCall() async {
    final currentCall = state.value?.currentCall;
    if (currentCall == null) return;

    try {
      final response = await _apiService.leaveCall(currentCall.id);

      if (response.success) {
        _endCall();
        if (kDebugMode) print('👥 Left call: ${currentCall.id}');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error leaving call: $e');
    }
  }

  // Media control methods
  Future<void> toggleAudio() async {
    await _webrtcNotifier.toggleAudio();
    await _updateMediaState();
  }

  Future<void> toggleVideo() async {
    await _webrtcNotifier.toggleVideo();
    await _updateMediaState();
  }

  Future<void> toggleSpeaker() async {
    await _webrtcNotifier.toggleSpeaker();
  }

  Future<void> switchCamera() async {
    await _webrtcNotifier.switchCamera();
  }

  Future<void> startScreenShare() async {
    await _webrtcNotifier.startScreenShare();
    await _updateMediaState();
  }

  Future<void> stopScreenShare() async {
    await _webrtcNotifier.stopScreenShare();
    await _updateMediaState();
  }

  Future<void> _updateMediaState() async {
    final currentCall = state.value?.currentCall;
    if (currentCall == null) return;

    try {
      final webrtcState = _webrtcNotifier.state;

      await _apiService.updateMediaState(
        currentCall.id,
        videoEnabled: webrtcState.mediaState.videoEnabled,
        audioEnabled: webrtcState.mediaState.audioEnabled,
        screenSharing: webrtcState.mediaState.screenSharing,
      );
    } catch (e) {
      if (kDebugMode) print('❌ Error updating media state: $e');
    }
  }

  // Helper methods
  Future<void> _loadCall(String callId) async {
    try {
      final response = await _apiService.getCall(callId);

      if (response.success && response.data != null) {
        state.whenData((callState) {
          state = AsyncValue.data(
            callState.copyWith(currentCall: response.data),
          );
        });
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error loading call: $e');
    }
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      state.whenData((callState) {
        if (callState.callStartTime != null) {
          final duration = DateTime.now().difference(callState.callStartTime!);
          state = AsyncValue.data(callState.copyWith(callDuration: duration));
        }
      });
    });
  }

  void _endCall() {
    // Stop timers
    _durationTimer?.cancel();
    _qualityTimer?.cancel();

    // End WebRTC call
    _webrtcNotifier.endCall();

    // Clear call state after delay to allow UI to show end state
    Timer(Duration(seconds: 2), () {
      state.whenData((callState) {
        state = AsyncValue.data(CallProviderState(isInitialized: true));
      });
    });
  }

  // Utility methods
  CallModel? get currentCall => state.value?.currentCall;
  bool get hasActiveCall => state.value?.hasActiveCall ?? false;
  bool get isInCall => state.value?.isInCall ?? false;
  bool get isVideoCall => state.value?.isVideoCall ?? false;
  Duration? get callDuration => state.value?.callDuration;
  List<CallParticipant> get participants => state.value?.participants ?? [];
  CallQuality? get currentQuality => state.value?.currentQuality;

  @override
  void dispose() {
    _callEventSubscription?.cancel();
    _qualitySubscription?.cancel();
    _participantSubscription?.cancel();
    _durationTimer?.cancel();
    _qualityTimer?.cancel();
    super.dispose();
  }
}

// Providers
final callProvider =
    StateNotifierProvider<CallNotifier, AsyncValue<CallProviderState>>((ref) {
      final apiService = ref.watch(apiServiceProvider);
      final callSocketService = ref.watch(callSocketServiceProvider);
      final cacheService = CacheService();
      final webrtcNotifier = ref.watch(webrtcProvider.notifier);

      return CallNotifier(
        apiService: apiService,
        callSocketService: callSocketService,
        cacheService: cacheService,
        webrtcNotifier: webrtcNotifier,
      );
    });

// Convenience providers
final currentCallProvider = Provider<CallModel?>((ref) {
  final callState = ref.watch(callProvider);
  return callState.whenOrNull(data: (state) => state.currentCall);
});

final hasActiveCallProvider = Provider<bool>((ref) {
  final callState = ref.watch(callProvider);
  return callState.whenOrNull(data: (state) => state.hasActiveCall) ?? false;
});

final isInCallProvider = Provider<bool>((ref) {
  final callState = ref.watch(callProvider);
  return callState.whenOrNull(data: (state) => state.isInCall) ?? false;
});

final callDurationProvider = Provider<Duration?>((ref) {
  final callState = ref.watch(callProvider);
  return callState.whenOrNull(data: (state) => state.callDuration);
});

final callParticipantsProvider = Provider<List<CallParticipant>>((ref) {
  final callState = ref.watch(callProvider);
  return callState.whenOrNull(data: (state) => state.participants) ?? [];
});

final callQualityProvider = Provider<CallQuality?>((ref) {
  final callState = ref.watch(callProvider);
  return callState.whenOrNull(data: (state) => state.currentQuality);
});

final isVideoCallProvider = Provider<bool>((ref) {
  final callState = ref.watch(callProvider);
  return callState.whenOrNull(data: (state) => state.isVideoCall) ?? false;
});

final callStatusProvider = Provider<CallStatus?>((ref) {
  final currentCall = ref.watch(currentCallProvider);
  return currentCall?.status;
});
