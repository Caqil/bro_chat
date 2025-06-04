import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../../models/call/call_settings.dart';
import '../../services/api/api_service.dart';
import '../../services/websocket/call_socket.dart';
import '../../services/storage/cache_service.dart';
import '../../models/call/call_model.dart';
import '../../models/common/api_response.dart';

// Call history filter
enum CallHistoryFilter { all, missed, incoming, outgoing, video, voice }

// Call history sort
enum CallHistorySort { date, duration, name, callType }

// Call history state
class CallHistoryState {
  final List<CallModel> calls;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final bool isInitialized;
  final DateTime? lastFetchTime;
  final CallHistoryFilter filter;
  final CallHistorySort sort;
  final String searchQuery;
  final int page;

  CallHistoryState({
    this.calls = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.isInitialized = false,
    this.lastFetchTime,
    this.filter = CallHistoryFilter.all,
    this.sort = CallHistorySort.date,
    this.searchQuery = '',
    this.page = 1,
  });

  CallHistoryState copyWith({
    List<CallModel>? calls,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    bool? isInitialized,
    DateTime? lastFetchTime,
    CallHistoryFilter? filter,
    CallHistorySort? sort,
    String? searchQuery,
    int? page,
  }) {
    return CallHistoryState(
      calls: calls ?? this.calls,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      isInitialized: isInitialized ?? this.isInitialized,
      lastFetchTime: lastFetchTime ?? this.lastFetchTime,
      filter: filter ?? this.filter,
      sort: sort ?? this.sort,
      searchQuery: searchQuery ?? this.searchQuery,
      page: page ?? this.page,
    );
  }

  List<CallModel> get filteredCalls {
    List<CallModel> filtered = calls;

    // Apply search filter
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((call) {
        // You would search by participant names here
        // For now, just search by call ID
        return call.id.toLowerCase().contains(searchQuery.toLowerCase());
      }).toList();
    }

    // Apply status filter
    switch (filter) {
      case CallHistoryFilter.missed:
        filtered = filtered
            .where((call) => call.status == CallStatus.missed)
            .toList();
        break;
      case CallHistoryFilter.incoming:
        // Filter by incoming calls (you'd need to determine this based on initiator)
        break;
      case CallHistoryFilter.outgoing:
        // Filter by outgoing calls (you'd need to determine this based on initiator)
        break;
      case CallHistoryFilter.video:
        filtered = filtered
            .where(
              (call) =>
                  call.type == CallType.video || call.type == CallType.group,
            )
            .toList();
        break;
      case CallHistoryFilter.voice:
        filtered = filtered
            .where((call) => call.type == CallType.voice)
            .toList();
        break;
      case CallHistoryFilter.all:
      default:
        break;
    }

    // Apply sorting
    switch (sort) {
      case CallHistorySort.date:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case CallHistorySort.duration:
        filtered.sort((a, b) {
          final aDuration = a.duration?.inSeconds ?? 0;
          final bDuration = b.duration?.inSeconds ?? 0;
          return bDuration.compareTo(aDuration);
        });
        break;
      case CallHistorySort.name:
        // You would sort by participant names here
        break;
      case CallHistorySort.callType:
        filtered.sort((a, b) => a.type.value.compareTo(b.type.value));
        break;
    }

    return filtered;
  }

  CallModel? getCall(String callId) {
    try {
      return calls.firstWhere((call) => call.id == callId);
    } catch (e) {
      return null;
    }
  }

  // Statistics
  int get totalCalls => calls.length;
  int get missedCalls =>
      calls.where((call) => call.status == CallStatus.missed).length;
  int get completedCalls =>
      calls.where((call) => call.status == CallStatus.ended).length;
  int get videoCalls => calls.where((call) => call.isVideoCall).length;
  int get voiceCalls =>
      calls.where((call) => call.type == CallType.voice).length;

  Duration get totalCallTime {
    return calls.fold(Duration.zero, (total, call) {
      return total + (call.duration ?? Duration.zero);
    });
  }

  double get averageCallDuration {
    final completedCallsWithDuration = calls
        .where(
          (call) => call.status == CallStatus.ended && call.duration != null,
        )
        .toList();

    if (completedCallsWithDuration.isEmpty) return 0.0;

    final totalSeconds = completedCallsWithDuration.fold(0, (sum, call) {
      return sum + call.duration!.inSeconds;
    });

    return totalSeconds / completedCallsWithDuration.length;
  }
}

class CallHistoryNotifier extends StateNotifier<AsyncValue<CallHistoryState>> {
  final ApiService _apiService;
  final CallSocketService _callSocketService;
  final CacheService _cacheService;

  StreamSubscription<CallEvent>? _callEventSubscription;
  Timer? _refreshTimer;
  Timer? _searchDebounceTimer;

  static const int _callsPerPage = 20;
  static const Duration _cacheExpiry = Duration(hours: 1);
  static const Duration _refreshInterval = Duration(minutes: 10);
  static const Duration _searchDebounceDelay = Duration(milliseconds: 500);

  CallHistoryNotifier({
    required ApiService apiService,
    required CallSocketService callSocketService,
    required CacheService cacheService,
  }) : _apiService = apiService,
       _callSocketService = callSocketService,
       _cacheService = cacheService,
       super(AsyncValue.data(CallHistoryState())) {
    _initialize();
  }

  void _initialize() async {
    _setupSubscriptions();
    _setupPeriodicRefresh();
    await _loadCallHistory();
  }

  void _setupSubscriptions() {
    // Listen to call events to update history in real-time
    _callEventSubscription = _callSocketService.callEvents.listen(
      _handleCallEvent,
    );
  }

  void _setupPeriodicRefresh() {
    _refreshTimer = Timer.periodic(
      _refreshInterval,
      (_) => refreshCallHistory(),
    );
  }

  void _handleCallEvent(CallEvent event) {
    switch (event.type) {
      case CallEventType.callEnded:
        _handleCallEnded(event);
        break;
      case CallEventType.incomingCall:
        _handleNewCall(event);
        break;
      default:
        break;
    }
  }

  void _handleCallEnded(CallEvent event) {
    final callId = event.callId;
    if (callId == null) return;

    state.whenData((historyState) {
      final callIndex = historyState.calls.indexWhere(
        (call) => call.id == callId,
      );

      if (callIndex != -1) {
        // Update existing call
        final updatedCalls = List<CallModel>.from(historyState.calls);
        final existingCall = updatedCalls[callIndex];

        final duration = event.data?['duration'] as int?;
        final updatedCall = existingCall.copyWith(
          status: CallStatus.ended,
          endedAt: DateTime.now(),
          duration: duration != null ? Duration(seconds: duration) : null,
        );

        updatedCalls[callIndex] = updatedCall;
        state = AsyncValue.data(historyState.copyWith(calls: updatedCalls));

        _cacheCallHistory(updatedCalls);
      }
    });
  }

  void _handleNewCall(CallEvent event) {
    final callData = event.data;
    if (callData != null && event.callId != null) {
      state.whenData((historyState) {
        // Check if call already exists
        final existingCall = historyState.getCall(event.callId!);
        if (existingCall == null) {
          final newCall = CallModel(
            id: event.callId!,
            chatId: callData['chat_id'] ?? '',
            initiatorId: callData['initiator_id'] ?? '',
            participantIds: List<String>.from(
              callData['participant_ids'] ?? [],
            ),
            type: CallType.fromString(callData['type']),
            status: CallStatus.ringing,
            settings: CallSettings.fromJson(callData['settings'] ?? {}),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          final updatedCalls = [newCall, ...historyState.calls];
          state = AsyncValue.data(historyState.copyWith(calls: updatedCalls));
        }
      });
    }
  }

  Future<void> _loadCallHistory() async {
    state = AsyncValue.data(state.value!.copyWith(isLoading: true));

    try {
      // Try to load from cache first
      final cachedCalls = await _loadCallHistoryFromCache();

      if (cachedCalls.isNotEmpty) {
        state = AsyncValue.data(
          state.value!.copyWith(
            calls: cachedCalls,
            isLoading: false,
            isInitialized: true,
          ),
        );
      }

      // Load from API
      await _loadCallHistoryFromAPI();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<List<CallModel>> _loadCallHistoryFromCache() async {
    try {
      final cachedData = await _cacheService.getCachedCalls();
      return cachedData.map((data) => CallModel.fromJson(data)).toList();
    } catch (e) {
      if (kDebugMode) print('❌ Error loading call history from cache: $e');
      return [];
    }
  }

  Future<void> _loadCallHistoryFromAPI() async {
    try {
      final response = await _apiService.getCallHistory(
        page: 1,
        limit: _callsPerPage,
      );

      if (response.success && response.data != null) {
        final apiCalls = response.data!;
        await _cacheCallHistory(apiCalls);

        state = AsyncValue.data(
          state.value!.copyWith(
            calls: apiCalls,
            isLoading: false,
            isInitialized: true,
            lastFetchTime: DateTime.now(),
            hasMore: apiCalls.length >= _callsPerPage,
            page: 1,
          ),
        );

        if (kDebugMode) print('✅ Loaded ${apiCalls.length} calls from history');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error loading call history from API: $e');

      state.whenData((historyState) {
        if (historyState.calls.isEmpty) {
          state = AsyncValue.error(e, StackTrace.current);
        } else {
          state = AsyncValue.data(
            historyState.copyWith(
              isLoading: false,
              isInitialized: true,
              error: e.toString(),
            ),
          );
        }
      });
    }
  }

  Future<void> loadMoreCallHistory() async {
    final currentState = state.value;
    if (currentState == null ||
        currentState.isLoadingMore ||
        !currentState.hasMore) {
      return;
    }

    state = AsyncValue.data(currentState.copyWith(isLoadingMore: true));

    try {
      final response = await _apiService.getCallHistory(
        page: currentState.page + 1,
        limit: _callsPerPage,
      );

      if (response.success && response.data != null) {
        final newCalls = response.data!;
        final allCalls = [...currentState.calls, ...newCalls];

        await _cacheCallHistory(allCalls);

        state = AsyncValue.data(
          currentState.copyWith(
            calls: allCalls,
            isLoadingMore: false,
            hasMore: newCalls.length >= _callsPerPage,
            page: currentState.page + 1,
          ),
        );

        if (kDebugMode) print('✅ Loaded ${newCalls.length} more calls');
      }
    } catch (e) {
      state = AsyncValue.data(
        currentState.copyWith(isLoadingMore: false, error: e.toString()),
      );
    }
  }

  Future<void> refreshCallHistory() async {
    final currentState = state.value;
    if (currentState == null || currentState.isLoading) return;

    try {
      final response = await _apiService.getCallHistory(
        page: 1,
        limit: _callsPerPage * currentState.page,
      );

      if (response.success && response.data != null) {
        final refreshedCalls = response.data!;
        await _cacheCallHistory(refreshedCalls);

        state = AsyncValue.data(
          currentState.copyWith(
            calls: refreshedCalls,
            lastFetchTime: DateTime.now(),
            error: null,
          ),
        );

        if (kDebugMode) print('✅ Refreshed ${refreshedCalls.length} calls');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error refreshing call history: $e');
    }
  }

  // Filter and search methods
  void setFilter(CallHistoryFilter filter) {
    state.whenData((historyState) {
      state = AsyncValue.data(historyState.copyWith(filter: filter));
    });
  }

  void setSort(CallHistorySort sort) {
    state.whenData((historyState) {
      state = AsyncValue.data(historyState.copyWith(sort: sort));
    });
  }

  void setSearchQuery(String query) {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(_searchDebounceDelay, () {
      state.whenData((historyState) {
        state = AsyncValue.data(historyState.copyWith(searchQuery: query));
      });
    });
  }

  // Call management methods
  Future<void> deleteCall(String callId) async {
    try {
      // Note: You'd need to implement this API endpoint
      // For now, just remove from local state
      state.whenData((historyState) {
        final updatedCalls = historyState.calls
            .where((call) => call.id != callId)
            .toList();
        state = AsyncValue.data(historyState.copyWith(calls: updatedCalls));
        _cacheCallHistory(updatedCalls);
      });

      if (kDebugMode) print('🗑️ Call deleted: $callId');
    } catch (e) {
      if (kDebugMode) print('❌ Error deleting call: $e');
      rethrow;
    }
  }

  Future<void> clearCallHistory() async {
    try {
      // Note: You'd need to implement this API endpoint
      // For now, just clear local state
      state.whenData((historyState) {
        state = AsyncValue.data(historyState.copyWith(calls: []));
        _cacheCallHistory([]);
      });

      if (kDebugMode) print('🗑️ Call history cleared');
    } catch (e) {
      if (kDebugMode) print('❌ Error clearing call history: $e');
      rethrow;
    }
  }

  Future<void> _cacheCallHistory(List<CallModel> calls) async {
    try {
      final callData = calls.map((call) => call.toJson()).toList();
      await _cacheService.cacheCalls(callData);
    } catch (e) {
      if (kDebugMode) print('❌ Error caching call history: $e');
    }
  }

  // Utility methods
  List<CallModel> get calls => state.value?.calls ?? [];
  List<CallModel> get filteredCalls => state.value?.filteredCalls ?? [];
  bool get isLoading => state.value?.isLoading ?? false;
  bool get isLoadingMore => state.value?.isLoadingMore ?? false;
  bool get hasMore => state.value?.hasMore ?? false;
  CallHistoryFilter get currentFilter =>
      state.value?.filter ?? CallHistoryFilter.all;
  CallHistorySort get currentSort => state.value?.sort ?? CallHistorySort.date;
  String get searchQuery => state.value?.searchQuery ?? '';

  // Statistics
  int get totalCalls => state.value?.totalCalls ?? 0;
  int get missedCalls => state.value?.missedCalls ?? 0;
  int get completedCalls => state.value?.completedCalls ?? 0;
  Duration get totalCallTime => state.value?.totalCallTime ?? Duration.zero;
  double get averageCallDuration => state.value?.averageCallDuration ?? 0.0;

  CallModel? getCall(String callId) => state.value?.getCall(callId);

  @override
  void dispose() {
    _callEventSubscription?.cancel();
    _refreshTimer?.cancel();
    _searchDebounceTimer?.cancel();
    super.dispose();
  }
}

// Providers
final callHistoryProvider =
    StateNotifierProvider<CallHistoryNotifier, AsyncValue<CallHistoryState>>((
      ref,
    ) {
      final apiService = ref.watch(apiServiceProvider);
      final callSocketService = ref.watch(callSocketServiceProvider);
      final cacheService = CacheService();

      return CallHistoryNotifier(
        apiService: apiService,
        callSocketService: callSocketService,
        cacheService: cacheService,
      );
    });

// Convenience providers
final callHistoryListProvider = Provider<List<CallModel>>((ref) {
  final historyState = ref.watch(callHistoryProvider);
  return historyState.whenOrNull(data: (state) => state.calls) ?? [];
});

final filteredCallHistoryProvider = Provider<List<CallModel>>((ref) {
  final historyState = ref.watch(callHistoryProvider);
  return historyState.whenOrNull(data: (state) => state.filteredCalls) ?? [];
});

final callHistoryLoadingProvider = Provider<bool>((ref) {
  final historyState = ref.watch(callHistoryProvider);
  return historyState.whenOrNull(data: (state) => state.isLoading) ?? false;
});

final callHistoryFilterProvider = Provider<CallHistoryFilter>((ref) {
  final historyState = ref.watch(callHistoryProvider);
  return historyState.whenOrNull(data: (state) => state.filter) ??
      CallHistoryFilter.all;
});

final callHistorySearchQueryProvider = Provider<String>((ref) {
  final historyState = ref.watch(callHistoryProvider);
  return historyState.whenOrNull(data: (state) => state.searchQuery) ?? '';
});

// Statistics providers
final totalCallsProvider = Provider<int>((ref) {
  final historyState = ref.watch(callHistoryProvider);
  return historyState.whenOrNull(data: (state) => state.totalCalls) ?? 0;
});

final missedCallsProvider = Provider<int>((ref) {
  final historyState = ref.watch(callHistoryProvider);
  return historyState.whenOrNull(data: (state) => state.missedCalls) ?? 0;
});

final completedCallsProvider = Provider<int>((ref) {
  final historyState = ref.watch(callHistoryProvider);
  return historyState.whenOrNull(data: (state) => state.completedCalls) ?? 0;
});

final totalCallTimeProvider = Provider<Duration>((ref) {
  final historyState = ref.watch(callHistoryProvider);
  return historyState.whenOrNull(data: (state) => state.totalCallTime) ??
      Duration.zero;
});

final averageCallDurationProvider = Provider<double>((ref) {
  final historyState = ref.watch(callHistoryProvider);
  return historyState.whenOrNull(data: (state) => state.averageCallDuration) ??
      0.0;
});

final specificCallProvider = Provider.family<CallModel?, String>((ref, callId) {
  final calls = ref.watch(callHistoryListProvider);
  try {
    return calls.firstWhere((call) => call.id == callId);
  } catch (e) {
    return null;
  }
});

// Call statistics summary provider
final callStatisticsProvider = Provider<Map<String, dynamic>>((ref) {
  final totalCalls = ref.watch(totalCallsProvider);
  final missedCalls = ref.watch(missedCallsProvider);
  final completedCalls = ref.watch(completedCallsProvider);
  final totalCallTime = ref.watch(totalCallTimeProvider);
  final averageCallDuration = ref.watch(averageCallDurationProvider);

  return {
    'total_calls': totalCalls,
    'missed_calls': missedCalls,
    'completed_calls': completedCalls,
    'total_call_time': totalCallTime,
    'average_call_duration': averageCallDuration,
    'missed_call_percentage': totalCalls > 0
        ? (missedCalls / totalCalls) * 100
        : 0.0,
    'completion_rate': totalCalls > 0
        ? (completedCalls / totalCalls) * 100
        : 0.0,
  };
});
