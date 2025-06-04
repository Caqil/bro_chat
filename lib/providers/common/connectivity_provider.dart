import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../../services/storage/cache_service.dart';
import '../../services/websocket/websocket_service.dart';

enum ConnectivityType { none, wifi, mobile, ethernet, bluetooth, vpn, other }

enum NetworkQuality { unknown, poor, fair, good, excellent }

class ConnectivityState {
  final ConnectivityType type;
  final bool isConnected;
  final NetworkQuality quality;
  final String? ssid;
  final String? bssid;
  final int? signalStrength;
  final double? speed;
  final bool isMetered;
  final bool isRoaming;
  final DateTime lastConnectedAt;
  final DateTime? lastDisconnectedAt;
  final Duration? reconnectDelay;
  final int reconnectAttempts;
  final bool isInitialized;

  ConnectivityState({
    this.type = ConnectivityType.none,
    this.isConnected = false,
    this.quality = NetworkQuality.unknown,
    this.ssid,
    this.bssid,
    this.signalStrength,
    this.speed,
    this.isMetered = false,
    this.isRoaming = false,
    DateTime? lastConnectedAt,
    this.lastDisconnectedAt,
    this.reconnectDelay,
    this.reconnectAttempts = 0,
    this.isInitialized = false,
  }) : lastConnectedAt = lastConnectedAt ?? DateTime.now();

  ConnectivityState copyWith({
    ConnectivityType? type,
    bool? isConnected,
    NetworkQuality? quality,
    String? ssid,
    String? bssid,
    int? signalStrength,
    double? speed,
    bool? isMetered,
    bool? isRoaming,
    DateTime? lastConnectedAt,
    DateTime? lastDisconnectedAt,
    Duration? reconnectDelay,
    int? reconnectAttempts,
    bool? isInitialized,
  }) {
    return ConnectivityState(
      type: type ?? this.type,
      isConnected: isConnected ?? this.isConnected,
      quality: quality ?? this.quality,
      ssid: ssid ?? this.ssid,
      bssid: bssid ?? this.bssid,
      signalStrength: signalStrength ?? this.signalStrength,
      speed: speed ?? this.speed,
      isMetered: isMetered ?? this.isMetered,
      isRoaming: isRoaming ?? this.isRoaming,
      lastConnectedAt: lastConnectedAt ?? this.lastConnectedAt,
      lastDisconnectedAt: lastDisconnectedAt ?? this.lastDisconnectedAt,
      reconnectDelay: reconnectDelay ?? this.reconnectDelay,
      reconnectAttempts: reconnectAttempts ?? this.reconnectAttempts,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }

  bool get hasStableConnection => isConnected && quality != NetworkQuality.poor;
  bool get canMakeVoiceCalls => isConnected && quality != NetworkQuality.poor;
  bool get canMakeVideoCalls =>
      isConnected &&
      (quality == NetworkQuality.good || quality == NetworkQuality.excellent);
  bool get shouldReduceQuality =>
      quality == NetworkQuality.poor || quality == NetworkQuality.fair;
}

class ConnectivityNotifier extends StateNotifier<ConnectivityState> {
  final Connectivity _connectivity;
  final WebSocketService _webSocketService;
  final CacheService _cacheService;

  // Updated type to StreamSubscription<List<ConnectivityResult>>
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _qualityCheckTimer;
  Timer? _reconnectTimer;

  ConnectivityNotifier({
    required Connectivity connectivity,
    required WebSocketService webSocketService,
    required CacheService cacheService,
  }) : _connectivity = connectivity,
       _webSocketService = webSocketService,
       _cacheService = cacheService,
       super(ConnectivityState()) {
    _initialize();
  }

  void _initialize() async {
    await _checkInitialConnectivity();
    _startConnectivityListener();
    _startQualityMonitoring();

    state = state.copyWith(isInitialized: true);
  }

  Future<void> _checkInitialConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      await _updateConnectivityState(result);
    } catch (e) {
      if (kDebugMode) print('❌ Error checking initial connectivity: $e');
    }
  }

  void _startConnectivityListener() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectivityState,
      onError: (error) {
        if (kDebugMode) print('❌ Connectivity stream error: $error');
      },
    );
  }

  void _startQualityMonitoring() {
    _qualityCheckTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkNetworkQuality(),
    );
  }

  Future<void> _updateConnectivityState(
    List<ConnectivityResult> results,
  ) async {
    try {
      // Choose the primary connection type (e.g., prioritize Wi-Fi or mobile)
      ConnectivityResult primaryResult = ConnectivityResult.none;
      if (results.isNotEmpty) {
        // Example logic: prioritize Wi-Fi > Ethernet > Mobile > Others
        if (results.contains(ConnectivityResult.wifi)) {
          primaryResult = ConnectivityResult.wifi;
        } else if (results.contains(ConnectivityResult.ethernet)) {
          primaryResult = ConnectivityResult.ethernet;
        } else if (results.contains(ConnectivityResult.mobile)) {
          primaryResult = ConnectivityResult.mobile;
        } else if (results.contains(ConnectivityResult.vpn)) {
          primaryResult = ConnectivityResult.vpn;
        } else if (results.contains(ConnectivityResult.bluetooth)) {
          primaryResult = ConnectivityResult.bluetooth;
        } else if (results.contains(ConnectivityResult.other)) {
          primaryResult = ConnectivityResult.other;
        }
      }

      final type = _mapConnectivityResult(primaryResult);
      final isConnected = type != ConnectivityType.none;

      final previousState = state;
      final now = DateTime.now();

      state = state.copyWith(
        type: type,
        isConnected: isConnected,
        lastConnectedAt: isConnected ? now : state.lastConnectedAt,
        lastDisconnectedAt: !isConnected ? now : state.lastDisconnectedAt,
        reconnectAttempts: isConnected ? 0 : state.reconnectAttempts,
      );

      // Handle connection changes
      if (previousState.isConnected != isConnected) {
        await _handleConnectionChange(isConnected);
      }

      // Update network quality
      if (isConnected) {
        await _checkNetworkQuality();
      } else {
        state = state.copyWith(quality: NetworkQuality.unknown);
      }

      // Cache connectivity state
      await _cacheConnectivityState();

      if (kDebugMode) {
        print(
          '🌐 Connectivity changed: ${type.name} (${isConnected ? 'connected' : 'disconnected'})',
        );
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error updating connectivity state: $e');
    }
  }

  ConnectivityType _mapConnectivityResult(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
        return ConnectivityType.wifi;
      case ConnectivityResult.mobile:
        return ConnectivityType.mobile;
      case ConnectivityResult.ethernet:
        return ConnectivityType.ethernet;
      case ConnectivityResult.bluetooth:
        return ConnectivityType.bluetooth;
      case ConnectivityResult.vpn:
        return ConnectivityType.vpn;
      case ConnectivityResult.other:
        return ConnectivityType.other;
      case ConnectivityResult.none:
      default:
        return ConnectivityType.none;
    }
  }

  Future<void> _handleConnectionChange(bool isConnected) async {
    try {
      if (isConnected) {
        // Connection restored
        await _handleConnectionRestored();
      } else {
        // Connection lost
        await _handleConnectionLost();
      }

      // Notify WebSocket service about connection change
      _webSocketService.setNetworkStatus(isConnected);
    } catch (e) {
      if (kDebugMode) print('❌ Error handling connection change: $e');
    }
  }

  Future<void> _handleConnectionRestored() async {
    try {
      // Cancel any pending reconnect attempts
      _reconnectTimer?.cancel();
      _reconnectTimer = null;

      // Reset reconnect attempts
      state = state.copyWith(reconnectAttempts: 0, reconnectDelay: null);

      if (kDebugMode) print('✅ Connection restored');
    } catch (e) {
      if (kDebugMode) print('❌ Error handling connection restored: $e');
    }
  }

  Future<void> _handleConnectionLost() async {
    try {
      // Start reconnection attempts
      _scheduleReconnectAttempt();

      if (kDebugMode) print('⚠️ Connection lost');
    } catch (e) {
      if (kDebugMode) print('❌ Error handling connection lost: $e');
    }
  }

  void _scheduleReconnectAttempt() {
    const maxAttempts = 5;
    const baseDelay = Duration(seconds: 2);

    if (state.reconnectAttempts >= maxAttempts) {
      if (kDebugMode) print('❌ Max reconnect attempts reached');
      return;
    }

    final delay = Duration(
      seconds: baseDelay.inSeconds * (state.reconnectAttempts + 1),
    );

    state = state.copyWith(
      reconnectAttempts: state.reconnectAttempts + 1,
      reconnectDelay: delay,
    );

    _reconnectTimer = Timer(delay, () async {
      await _checkInitialConnectivity();
    });

    if (kDebugMode) {
      print(
        '🔄 Scheduling reconnect attempt ${state.reconnectAttempts} in ${delay.inSeconds}s',
      );
    }
  }

  Future<void> _checkNetworkQuality() async {
    if (!state.isConnected) return;

    try {
      // Simple ping test to measure network quality
      final stopwatch = Stopwatch()..start();

      // You can implement actual network quality testing here
      // For now, we'll simulate based on connection type
      NetworkQuality quality;

      switch (state.type) {
        case ConnectivityType.wifi:
        case ConnectivityType.ethernet:
          quality = NetworkQuality.excellent;
          break;
        case ConnectivityType.mobile:
          quality = NetworkQuality.good;
          break;
        case ConnectivityType.vpn:
          quality = NetworkQuality.fair;
          break;
        default:
          quality = NetworkQuality.unknown;
      }

      stopwatch.stop();
      final responseTime = stopwatch.elapsedMilliseconds;

      // Adjust quality based on response time
      if (responseTime > 2000) {
        quality = NetworkQuality.poor;
      } else if (responseTime > 1000) {
        quality = NetworkQuality.fair;
      } else if (responseTime > 500) {
        quality = NetworkQuality.good;
      }

      state = state.copyWith(quality: quality, speed: responseTime.toDouble());

      if (kDebugMode) {
        print('📊 Network quality: ${quality.name} (${responseTime}ms)');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error checking network quality: $e');
    }
  }

  Future<void> _cacheConnectivityState() async {
    try {
      await _cacheService.cacheConnectivityState({
        'type': state.type.name,
        'is_connected': state.isConnected,
        'quality': state.quality.name,
        'last_connected_at': state.lastConnectedAt.toIso8601String(),
        'last_disconnected_at': state.lastDisconnectedAt?.toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) print('❌ Error caching connectivity state: $e');
    }
  }

  Future<void> refresh() async {
    await _checkInitialConnectivity();
  }

  Future<bool> testConnection() async {
    try {
      final stopwatch = Stopwatch()..start();

      // Implement actual connectivity test
      // For now, return current connection state
      await Future.delayed(const Duration(milliseconds: 100));

      stopwatch.stop();

      state = state.copyWith(speed: stopwatch.elapsedMilliseconds.toDouble());

      return state.isConnected;
    } catch (e) {
      if (kDebugMode) print('❌ Error testing connection: $e');
      return false;
    }
  }

  Map<String, dynamic> getConnectionInfo() {
    return {
      'type': state.type.name,
      'is_connected': state.isConnected,
      'quality': state.quality.name,
      'ssid': state.ssid,
      'signal_strength': state.signalStrength,
      'speed': state.speed,
      'is_metered': state.isMetered,
      'is_roaming': state.isRoaming,
      'last_connected_at': state.lastConnectedAt.toIso8601String(),
      'last_disconnected_at': state.lastDisconnectedAt?.toIso8601String(),
      'reconnect_attempts': state.reconnectAttempts,
    };
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _qualityCheckTimer?.cancel();
    _reconnectTimer?.cancel();
    super.dispose();
  }
}

// Providers
final connectivityProvider =
    StateNotifierProvider<ConnectivityNotifier, ConnectivityState>((ref) {
      return ConnectivityNotifier(
        connectivity: Connectivity(),
        webSocketService: WebSocketService(),
        cacheService: CacheService(),
      );
    });

// Convenience providers
final isConnectedProvider = Provider<bool>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  return connectivity.isConnected;
});

final connectionTypeProvider = Provider<ConnectivityType>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  return connectivity.type;
});

final networkQualityProvider = Provider<NetworkQuality>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  return connectivity.quality;
});

final hasStableConnectionProvider = Provider<bool>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  return connectivity.hasStableConnection;
});

final canMakeVoiceCallsProvider = Provider<bool>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  return connectivity.canMakeVoiceCalls;
});

final canMakeVideoCallsProvider = Provider<bool>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  return connectivity.canMakeVideoCalls;
});

final shouldReduceQualityProvider = Provider<bool>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  return connectivity.shouldReduceQuality;
});

final connectionInfoProvider = Provider<Map<String, dynamic>>((ref) {
  final notifier = ref.watch(connectivityProvider.notifier);
  return notifier.getConnectionInfo();
});
