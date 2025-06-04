import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../models/call/call_model.dart';
import '../../models/common/api_response.dart';
import '../../core/constants/api_constants.dart';
import '../../core/config/dio_config.dart';
import '../../services/websocket/call_socket.dart';
import '../../services/storage/local_storage.dart';

class CallState {
  final CallModel? activeCall;
  final bool isLoading;
  final String? error;
  final CallStatus status;
  final Map<String, CallParticipant> participants;
  final Duration callDuration;
  final CallQuality? quality;

  const CallState({
    this.activeCall,
    this.isLoading = false,
    this.error,
    this.status = CallStatus.idle,
    this.participants = const {},
    this.callDuration = Duration.zero,
    this.quality,
  });

  CallState copyWith({
    CallModel? activeCall,
    bool? isLoading,
    String? error,
    CallStatus? status,
    Map<String, CallParticipant>? participants,
    Duration? callDuration,
    CallQuality? quality,
  }) {
    return CallState(
      activeCall: activeCall,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      status: status ?? this.status,
      participants: participants ?? this.participants,
      callDuration: callDuration ?? this.callDuration,
      quality: quality ?? this.quality,
    );
  }

  bool get isInCall => activeCall != null && status == CallStatus.connected;
  bool get isRinging => status == CallStatus.ringing;
  bool get isConnecting => status == CallStatus.connecting;
  bool get canAnswer => status == CallStatus.ringing;
  bool get canEnd => isInCall || isConnecting || isRinging;
}

class CallNotifier extends StateNotifier<CallState> {
  final Dio _dio;
  final CallSocketService _callSocketService;
  final LocalStorage _localStorage;

  CallNotifier(this._dio, this._callSocketService, this._localStorage)
    : super(const CallState()) {
    _listenToCallEvents();
  }

  void _listenToCallEvents() {
    _callSocketService.callEvents.listen((event) {
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
        case CallEventType.durationUpdate:
          _handleDurationUpdate(event);
          break;
        default:
          break;
      }
    });

    _callSocketService.participantUpdates.listen((participant) {
      state = state.copyWith(
        participants: {...state.participants, participant.userId: participant},
      );
    });

    _callSocketService.qualityUpdates.listen((quality) {
      state = state.copyWith(quality: quality);
    });
  }

  void _handleIncomingCall(CallEvent event) {
    if (event.callId != null && event.data != null) {
      final call = CallModel.fromJson(event.data!);
      state = state.copyWith(
        activeCall: call,
        status: CallStatus.ringing,
        error: null,
      );
    }
  }

  void _handleCallAnswered(CallEvent event) {
    state = state.copyWith(status: CallStatus.connecting, error: null);
  }

  void _handleCallRejected(CallEvent event) {
    state = state.copyWith(status: CallStatus.declined, error: null);
    _endCall();
  }

  void _handleCallEnded(CallEvent event) {
    state = state.copyWith(status: CallStatus.ended, error: null);
    _endCall();
  }

  void _handleCallFailed(CallEvent event) {
    state = state.copyWith(
      status: CallStatus.failed,
      error: event.data?['reason'] ?? 'Call failed',
    );
    _endCall();
  }

  void _handleCallBusy(CallEvent event) {
    state = state.copyWith(status: CallStatus.busy, error: null);
    _endCall();
  }

  void _handleStateChanged(CallEvent event) {
    final stateName = event.data?['state'] as String?;
    if (stateName != null) {
      final newStatus = _parseCallStatus(stateName);
      state = state.copyWith(status: newStatus);
    }
  }

  void _handleDurationUpdate(CallEvent event) {
    final durationSeconds = event.data?['duration'] as int?;
    if (durationSeconds != null) {
      state = state.copyWith(callDuration: Duration(seconds: durationSeconds));
    }
  }

  CallStatus _parseCallStatus(String statusName) {
    switch (statusName) {
      case 'idle':
        return CallStatus.idle;
      case 'initiating':
        return CallStatus.initiating;
      case 'ringing':
        return CallStatus.ringing;
      case 'connecting':
        return CallStatus.connecting;
      case 'connected':
        return CallStatus.connected;
      case 'ended':
        return CallStatus.ended;
      case 'failed':
        return CallStatus.failed;
      case 'busy':
        return CallStatus.busy;
      case 'rejected':
        return CallStatus.declined;
      default:
        return CallStatus.idle;
    }
  }

  void _endCall() {
    Future.delayed(const Duration(seconds: 2), () {
      state = const CallState();
    });
  }

  // Public methods

  Future<bool> initiateCall({
    required String chatId,
    required List<String> participantIds,
    CallType type = CallType.voice,
    bool videoEnabled = false,
    bool audioEnabled = true,
  }) async {
    if (state.isInCall || state.isLoading) {
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _dio.post(
        ApiConstants.initiateCall,
        data: {
          'chat_id': chatId,
          'participant_ids': participantIds,
          'type': type.name,
          'video_enabled': videoEnabled,
          'audio_enabled': audioEnabled,
        },
      );

      final apiResponse = ApiResponse.fromJson(
        response.data,
        (data) => CallModel.fromJson(data),
      );

      if (apiResponse.success && apiResponse.data != null) {
        final call = apiResponse.data!;

        // Start the call through WebSocket service
        await _callSocketService.initiateCall(
          chatId: chatId,
          participantIds: participantIds,
          type: type,
          videoEnabled: videoEnabled,
          audioEnabled: audioEnabled,
        );

        state = state.copyWith(
          activeCall: call,
          status: CallStatus.initiating,
          isLoading: false,
        );

        // Update call statistics
        await _localStorage.incrementCallCount();

        return true;
      } else {
        state = state.copyWith(isLoading: false, error: apiResponse.message);
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to initiate call: $e',
      );
      return false;
    }
  }

  Future<bool> answerCall({bool videoEnabled = false}) async {
    if (!state.canAnswer || state.activeCall == null) {
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _dio.post(
        ApiConstants.answerCall(state.activeCall!.id),
        data: {'accept': true, 'video_enabled': videoEnabled},
      );

      final apiResponse = ApiResponse.fromJson(response.data, null);

      if (apiResponse.success) {
        // Answer through WebSocket service
        await _callSocketService.answerCall(videoEnabled: videoEnabled);

        state = state.copyWith(status: CallStatus.connecting, isLoading: false);

        return true;
      } else {
        state = state.copyWith(isLoading: false, error: apiResponse.message);
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to answer call: $e',
      );
      return false;
    }
  }

  Future<bool> rejectCall() async {
    if (!state.canAnswer || state.activeCall == null) {
      return false;
    }

    try {
      final response = await _dio.post(
        ApiConstants.answerCall(state.activeCall!.id),
        data: {'accept': false},
      );

      final apiResponse = ApiResponse.fromJson(response.data, null);

      if (apiResponse.success) {
        // Reject through WebSocket service
        _callSocketService.rejectCall();

        state = state.copyWith(status: CallStatus.declined);
        _endCall();

        return true;
      } else {
        state = state.copyWith(error: apiResponse.message);
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to reject call: $e');
      return false;
    }
  }

  Future<bool> endCall() async {
    if (!state.canEnd || state.activeCall == null) {
      return false;
    }

    try {
      final response = await _dio.post(
        ApiConstants.endCall(state.activeCall!.id),
        data: {'reason': 'normal'},
      );

      final apiResponse = ApiResponse.fromJson(response.data, null);

      if (apiResponse.success) {
        // End through WebSocket service
        _callSocketService.endCall();

        state = state.copyWith(status: CallStatus.ended);
        _endCall();

        return true;
      } else {
        state = state.copyWith(error: apiResponse.message);
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to end call: $e');
      return false;
    }
  }

  Future<bool> toggleAudio() async {
    if (!state.isInCall || state.activeCall == null) {
      return false;
    }

    try {
      await _callSocketService.toggleAudio();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to toggle audio: $e');
      return false;
    }
  }

  Future<bool> toggleVideo() async {
    if (!state.isInCall || state.activeCall == null) {
      return false;
    }

    try {
      await _callSocketService.toggleVideo();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to toggle video: $e');
      return false;
    }
  }

  Future<bool> toggleSpeaker() async {
    if (!state.isInCall) {
      return false;
    }

    try {
      await _callSocketService.toggleSpeaker();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to toggle speaker: $e');
      return false;
    }
  }

  Future<bool> switchCamera() async {
    if (!state.isInCall) {
      return false;
    }

    try {
      await _callSocketService.switchCamera();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to switch camera: $e');
      return false;
    }
  }

  Future<bool> startScreenShare() async {
    if (!state.isInCall) {
      return false;
    }

    try {
      await _callSocketService.startScreenShare();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to start screen share: $e');
      return false;
    }
  }

  Future<bool> stopScreenShare() async {
    if (!state.isInCall) {
      return false;
    }

    try {
      await _callSocketService.stopScreenShare();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to stop screen share: $e');
      return false;
    }
  }

  Future<CallModel?> getCallDetails(String callId) async {
    try {
      final response = await _dio.get(ApiConstants.getCall(callId));

      final apiResponse = ApiResponse.fromJson(
        response.data,
        (data) => CallModel.fromJson(data),
      );

      return apiResponse.success ? apiResponse.data : null;
    } catch (e) {
      state = state.copyWith(error: 'Failed to get call details: $e');
      return null;
    }
  }

  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }

  void forceEndCall() {
    state = const CallState();
  }

  // Getters
  bool get audioEnabled => _callSocketService.audioEnabled;
  bool get videoEnabled => _callSocketService.videoEnabled;
  bool get speakerEnabled => _callSocketService.speakerEnabled;
  bool get microphoneEnabled => _callSocketService.microphoneEnabled;
  bool get screenSharing => _callSocketService.screenSharing;
  CameraPosition get cameraPosition => _callSocketService.cameraPosition;
}

// Providers
final callProvider = StateNotifierProvider<CallNotifier, CallState>((ref) {
  final dio = ref.watch(dioProvider);
  final callSocketService = CallSocketService();
  final localStorage = LocalStorage();
  return CallNotifier(dio, callSocketService, localStorage);
});

// Convenience providers
final activeCallProvider = Provider<CallModel?>((ref) {
  return ref.watch(callProvider).activeCall;
});

final callStatusProvider = Provider<CallStatus>((ref) {
  return ref.watch(callProvider).status;
});

final isInCallProvider = Provider<bool>((ref) {
  return ref.watch(callProvider).isInCall;
});

final canAnswerCallProvider = Provider<bool>((ref) {
  return ref.watch(callProvider).canAnswer;
});

final canEndCallProvider = Provider<bool>((ref) {
  return ref.watch(callProvider).canEnd;
});

final callDurationProvider = Provider<Duration>((ref) {
  return ref.watch(callProvider).callDuration;
});

final callQualityProvider = Provider<CallQuality?>((ref) {
  return ref.watch(callProvider).quality;
});

final callParticipantsProvider = Provider<List<CallParticipant>>((ref) {
  return ref.watch(callProvider).participants.values.toList();
});

final callErrorProvider = Provider<String?>((ref) {
  return ref.watch(callProvider).error;
});

final callLoadingProvider = Provider<bool>((ref) {
  return ref.watch(callProvider).isLoading;
});

final audioEnabledProvider = Provider<bool>((ref) {
  final notifier = ref.watch(callProvider.notifier);
  return notifier.audioEnabled;
});

final videoEnabledProvider = Provider<bool>((ref) {
  final notifier = ref.watch(callProvider.notifier);
  return notifier.videoEnabled;
});

final speakerEnabledProvider = Provider<bool>((ref) {
  final notifier = ref.watch(callProvider.notifier);
  return notifier.speakerEnabled;
});

final screenSharingProvider = Provider<bool>((ref) {
  final notifier = ref.watch(callProvider.notifier);
  return notifier.screenSharing;
});

final cameraPositionProvider = Provider<CameraPosition>((ref) {
  final notifier = ref.watch(callProvider.notifier);
  return notifier.cameraPosition;
});

// Family providers
final callDetailsProvider = FutureProvider.family<CallModel?, String>((
  ref,
  callId,
) async {
  final notifier = ref.watch(callProvider.notifier);
  return await notifier.getCallDetails(callId);
});
