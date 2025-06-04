import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../models/call/call_model.dart';
import '../../models/common/api_response.dart';
import '../../models/common/pagination_model.dart';
import '../../core/constants/api_constants.dart';
import '../../core/config/dio_config.dart';
import '../../services/storage/cache_service.dart';
import '../../services/websocket/call_socket.dart';

class CallHistoryState {
  final List<CallModel> calls;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final int currentPage;

  const CallHistoryState({
    this.calls = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
    this.currentPage = 1,
  });

  CallHistoryState copyWith({
    List<CallModel>? calls,
    bool? isLoading,
    bool? hasMore,
    String? error,
    int? currentPage,
  }) {
    return CallHistoryState(
      calls: calls ?? this.calls,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

class CallHistoryNotifier extends StateNotifier<CallHistoryState> {
  final Dio _dio;
  final CacheService _cacheService;

  CallHistoryNotifier(this._dio, this._cacheService)
    : super(const CallHistoryState()) {
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // Load from cache first
    final cachedCalls = await _cacheService.getCachedCalls();
    if (cachedCalls.isNotEmpty) {
      state = state.copyWith(
        calls: cachedCalls.map((data) => CallModel.fromJson(data)).toList(),
      );
    }

    // Then fetch fresh data
    await loadCallHistory(refresh: true);
  }

  Future<void> loadCallHistory({bool refresh = false}) async {
    if (state.isLoading) return;

    if (refresh) {
      state = state.copyWith(
        isLoading: true,
        error: null,
        currentPage: 1,
        hasMore: true,
      );
    } else {
      if (!state.hasMore) return;
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final response = await _dio.get(
        ApiConstants.getCallHistory,
        queryParameters: {'page': refresh ? 1 : state.currentPage, 'limit': 20},
      );

      final apiResponse = ApiResponse.fromJson(
        response.data,
        (data) => PaginationModel<CallModel>.fromJson(
          data,
          (item) => CallModel.fromJson(item),
        ),
      );

      if (apiResponse.success && apiResponse.data != null) {
        final paginatedData = apiResponse.data!;
        final newCalls = paginatedData.items;

        // Cache the calls
        for (final call in newCalls) {
          await _cacheService.cacheCall(call.id, call.toJson());
        }

        if (refresh) {
          state = state.copyWith(
            calls: newCalls,
            isLoading: false,
            hasMore: paginatedData.hasNextPage,
            currentPage: 2,
          );
        } else {
          state = state.copyWith(
            calls: [...state.calls, ...newCalls],
            isLoading: false,
            hasMore: paginatedData.hasNextPage,
            currentPage: state.currentPage + 1,
          );
        }
      } else {
        state = state.copyWith(isLoading: false, error: apiResponse.message);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load call history: $e',
      );
    }
  }

  Future<void> deleteCall(String callId) async {
    try {
      await _dio.delete('/api/calls/$callId');

      state = state.copyWith(
        calls: state.calls.where((call) => call.id != callId).toList(),
      );

      // Remove from cache
      await _cacheService.deleteCacheEntry(callId, 'calls');
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete call: $e');
    }
  }

  Future<void> clearHistory() async {
    try {
      await _dio.delete('/api/calls/history');

      state = state.copyWith(calls: []);

      // Clear cache
      await _cacheService.clearCache('calls');
    } catch (e) {
      state = state.copyWith(error: 'Failed to clear call history: $e');
    }
  }

  List<CallModel> getCallsForChat(String chatId) {
    return state.calls.where((call) => call.chatId == chatId).toList();
  }

  List<CallModel> getCallsByType(CallType type) {
    return state.calls.where((call) => call.type == type).toList();
  }

  List<CallModel> getMissedCalls() {
    return state.calls
        .where(
          (call) =>
              call.status == CallStatus.missed ||
              call.status == CallStatus.declined,
        )
        .toList();
  }

  CallModel? getLastCallWithUser(String userId) {
    try {
      return state.calls
          .where((call) => call.participants.any((p) => p.userId == userId))
          .first;
    } catch (e) {
      return null;
    }
  }

  int getTotalCallDuration() {
    return state.calls
        .where((call) => call.duration != null)
        .map((call) => call.duration!.inSeconds)
        .fold(0, (a, b) => a + b);
  }

  Map<String, int> getCallStatistics() {
    final stats = <String, int>{
      'total': state.calls.length,
      'outgoing': 0,
      'incoming': 0,
      'missed': 0,
      'voice': 0,
      'video': 0,
    };

    for (final call in state.calls) {
      switch (call.direction) {
        case CallDirection.outgoing:
          stats['outgoing'] = stats['outgoing']! + 1;
          break;
        case CallDirection.incoming:
          stats['incoming'] = stats['incoming']! + 1;
          break;
      }

      switch (call.status) {
        case CallStatus.missed:
        case CallStatus.declined:
          stats['missed'] = stats['missed']! + 1;
          break;
        default:
          break;
      }

      switch (call.type) {
        case CallType.voice:
          stats['voice'] = stats['voice']! + 1;
          break;
        case CallType.video:
          stats['video'] = stats['video']! + 1;
          break;
        default:
          break;
      }
    }

    return stats;
  }

  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }
}

// Providers
final callHistoryProvider =
    StateNotifierProvider<CallHistoryNotifier, CallHistoryState>((ref) {
      final dio = ref.watch(dioProvider);
      final cacheService = CacheService();
      return CallHistoryNotifier(dio, cacheService);
    });

// Convenience providers
final callHistoryListProvider = Provider<List<CallModel>>((ref) {
  return ref.watch(callHistoryProvider).calls;
});

final callHistoryLoadingProvider = Provider<bool>((ref) {
  return ref.watch(callHistoryProvider).isLoading;
});

final callHistoryErrorProvider = Provider<String?>((ref) {
  return ref.watch(callHistoryProvider).error;
});

final missedCallsProvider = Provider<List<CallModel>>((ref) {
  final notifier = ref.watch(callHistoryProvider.notifier);
  return notifier.getMissedCalls();
});

final callStatisticsProvider = Provider<Map<String, int>>((ref) {
  final notifier = ref.watch(callHistoryProvider.notifier);
  return notifier.getCallStatistics();
});

final totalCallDurationProvider = Provider<int>((ref) {
  final notifier = ref.watch(callHistoryProvider.notifier);
  return notifier.getTotalCallDuration();
});

// Family providers
final callsForChatProvider = Provider.family<List<CallModel>, String>((
  ref,
  chatId,
) {
  final notifier = ref.watch(callHistoryProvider.notifier);
  return notifier.getCallsForChat(chatId);
});

final callsByTypeProvider = Provider.family<List<CallModel>, CallType>((
  ref,
  type,
) {
  final notifier = ref.watch(callHistoryProvider.notifier);
  return notifier.getCallsByType(type);
});

final lastCallWithUserProvider = Provider.family<CallModel?, String>((
  ref,
  userId,
) {
  final notifier = ref.watch(callHistoryProvider.notifier);
  return notifier.getLastCallWithUser(userId);
});
