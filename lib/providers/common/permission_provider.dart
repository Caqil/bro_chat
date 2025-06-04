import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

import '../../services/storage/local_storage.dart';
import 'permission_provider.dart' as permission_handler;

enum AppPermission {
  camera,
  microphone,
  photos,
  storage,
  location,
  contacts,
  notification,
  phone,
  sms,
  calendar,
  mediaLibrary,
  speech,
  ignoreBatteryOptimizations,
  systemAlertWindow,
  requestInstallPackages,
  accessNotificationPolicy,
  bluetoothScan,
  bluetoothAdvertise,
  bluetoothConnect,
  nearbyWifiDevices,
  manageExternalStorage,
  scheduleExactAlarm,
  sensors,
  activityRecognition,
  unknown,
}

enum PermissionStatus {
  denied,
  granted,
  restricted,
  limited,
  permanentlyDenied,
  provisional,
  unknown,
}

class PermissionInfo {
  final AppPermission permission;
  final PermissionStatus status;
  final DateTime lastChecked;
  final DateTime? lastRequested;
  final int requestCount;
  final bool isRequired;
  final String? denialReason;

  PermissionInfo({
    required this.permission,
    required this.status,
    DateTime? lastChecked,
    this.lastRequested,
    this.requestCount = 0,
    this.isRequired = false,
    this.denialReason,
  }) : lastChecked = lastChecked ?? DateTime.now();

  PermissionInfo copyWith({
    AppPermission? permission,
    PermissionStatus? status,
    DateTime? lastChecked,
    DateTime? lastRequested,
    int? requestCount,
    bool? isRequired,
    String? denialReason,
  }) {
    return PermissionInfo(
      permission: permission ?? this.permission,
      status: status ?? this.status,
      lastChecked: lastChecked ?? this.lastChecked,
      lastRequested: lastRequested ?? this.lastRequested,
      requestCount: requestCount ?? this.requestCount,
      isRequired: isRequired ?? this.isRequired,
      denialReason: denialReason,
    );
  }

  bool get isGranted => status == PermissionStatus.granted;
  bool get isDenied => status == PermissionStatus.denied;
  bool get isPermanentlyDenied => status == PermissionStatus.permanentlyDenied;
  bool get isRestricted => status == PermissionStatus.restricted;
  bool get isLimited => status == PermissionStatus.limited;
  bool get canRequest => !isPermanentlyDenied && !isRestricted;
  bool get shouldShowRationale => isDenied && requestCount > 0;

  Map<String, dynamic> toJson() {
    return {
      'permission': permission.name,
      'status': status.name,
      'last_checked': lastChecked.toIso8601String(),
      'last_requested': lastRequested?.toIso8601String(),
      'request_count': requestCount,
      'is_required': isRequired,
      'denial_reason': denialReason,
    };
  }

  factory PermissionInfo.fromJson(Map<String, dynamic> json) {
    return PermissionInfo(
      permission: AppPermission.values.firstWhere(
        (e) => e.name == json['permission'],
        orElse: () => AppPermission.unknown,
      ),
      status: PermissionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PermissionStatus.unknown,
      ),
      lastChecked:
          DateTime.tryParse(json['last_checked'] ?? '') ?? DateTime.now(),
      lastRequested: json['last_requested'] != null
          ? DateTime.tryParse(json['last_requested'])
          : null,
      requestCount: json['request_count'] ?? 0,
      isRequired: json['is_required'] ?? false,
      denialReason: json['denial_reason'],
    );
  }
}

class PermissionState {
  final Map<AppPermission, PermissionInfo> permissions;
  final bool isLoading;
  final String? error;
  final bool isInitialized;
  final DateTime? lastUpdate;
  final bool allRequiredGranted;

  PermissionState({
    this.permissions = const {},
    this.isLoading = false,
    this.error,
    this.isInitialized = false,
    this.lastUpdate,
    bool? allRequiredGranted,
  }) : allRequiredGranted =
           allRequiredGranted ?? _checkAllRequiredGranted(permissions);

  static bool _checkAllRequiredGranted(
    Map<AppPermission, PermissionInfo> permissions,
  ) {
    final requiredPermissions = permissions.values.where((p) => p.isRequired);
    return requiredPermissions.every((p) => p.isGranted);
  }

  PermissionState copyWith({
    Map<AppPermission, PermissionInfo>? permissions,
    bool? isLoading,
    String? error,
    bool? isInitialized,
    DateTime? lastUpdate,
  }) {
    return PermissionState(
      permissions: permissions ?? this.permissions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isInitialized: isInitialized ?? this.isInitialized,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }

  PermissionInfo? getPermission(AppPermission permission) {
    return permissions[permission];
  }

  PermissionStatus getPermissionStatus(AppPermission permission) {
    return permissions[permission]?.status ?? PermissionStatus.unknown;
  }

  bool isPermissionGranted(AppPermission permission) {
    return getPermissionStatus(permission) == PermissionStatus.granted;
  }

  bool isPermissionDenied(AppPermission permission) {
    final status = getPermissionStatus(permission);
    return status == PermissionStatus.denied ||
        status == PermissionStatus.permanentlyDenied;
  }

  List<AppPermission> get grantedPermissions {
    return permissions.entries
        .where((entry) => entry.value.isGranted)
        .map((entry) => entry.key)
        .toList();
  }

  List<AppPermission> get deniedPermissions {
    return permissions.entries
        .where(
          (entry) => entry.value.isDenied || entry.value.isPermanentlyDenied,
        )
        .map((entry) => entry.key)
        .toList();
  }

  List<AppPermission> get requiredPermissions {
    return permissions.entries
        .where((entry) => entry.value.isRequired)
        .map((entry) => entry.key)
        .toList();
  }

  List<AppPermission> get missingRequiredPermissions {
    return permissions.entries
        .where((entry) => entry.value.isRequired && !entry.value.isGranted)
        .map((entry) => entry.key)
        .toList();
  }
}

class PermissionNotifier extends StateNotifier<AsyncValue<PermissionState>> {
  final LocalStorage _localStorage;

  Timer? _periodicCheckTimer;

  static const Duration _checkInterval = Duration(minutes: 5);
  static const String _storageKey = 'permission_cache';

  PermissionNotifier({required LocalStorage localStorage})
    : _localStorage = localStorage,
      super(AsyncValue.data(PermissionState())) {
    _initialize();
  }

  void _initialize() async {
    state = AsyncValue.data(state.value!.copyWith(isLoading: true));

    try {
      await _loadCachedPermissions();
      await _checkAllPermissions();
      _startPeriodicCheck();

      state = AsyncValue.data(
        state.value!.copyWith(
          isLoading: false,
          isInitialized: true,
          lastUpdate: DateTime.now(),
        ),
      );

      if (kDebugMode) print('✅ Permission provider initialized');
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      if (kDebugMode) print('❌ Error initializing permission provider: $e');
    }
  }

  Future<void> _loadCachedPermissions() async {
    try {
      final cachedData = _localStorage.getString(_storageKey);
      if (cachedData != null) {
        // Parse cached permissions
        // Implementation depends on your storage format
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error loading cached permissions: $e');
    }
  }

  Future<void> _checkAllPermissions() async {
    try {
      final permissionsToCheck = _getPermissionsToCheck();
      final updatedPermissions = <AppPermission, PermissionInfo>{};

      for (final appPermission in permissionsToCheck) {
        final permission = _mapToNativePermission(appPermission);
        if (permission != null) {
          final status = await permission.status;
          final mappedStatus = _mapFromNativeStatus(status);

          final existingInfo = state.value?.permissions[appPermission];
          updatedPermissions[appPermission] = PermissionInfo(
            permission: appPermission,
            status: mappedStatus,
            lastChecked: DateTime.now(),
            lastRequested: existingInfo?.lastRequested,
            requestCount: existingInfo?.requestCount ?? 0,
            isRequired: _isRequiredPermission(appPermission),
          );
        }
      }

      state.whenData((permissionState) {
        state = AsyncValue.data(
          permissionState.copyWith(
            permissions: {
              ...permissionState.permissions,
              ...updatedPermissions,
            },
            lastUpdate: DateTime.now(),
          ),
        );
      });

      await _cachePermissions();
    } catch (e) {
      if (kDebugMode) print('❌ Error checking permissions: $e');
    }
  }

  List<AppPermission> _getPermissionsToCheck() {
    return [
      AppPermission.camera,
      AppPermission.microphone,
      AppPermission.photos,
      AppPermission.storage,
      AppPermission.location,
      AppPermission.contacts,
      AppPermission.notification,
      AppPermission.phone,
    ];
  }

  Permission? _mapToNativePermission(AppPermission appPermission) {
    switch (appPermission) {
      case AppPermission.camera:
        return Permission.camera;
      case AppPermission.microphone:
        return Permission.microphone;
      case AppPermission.photos:
        return Permission.photos;
      case AppPermission.storage:
        return Permission.storage;
      case AppPermission.location:
        return Permission.location;
      case AppPermission.contacts:
        return Permission.contacts;
      case AppPermission.notification:
        return Permission.notification;
      case AppPermission.phone:
        return Permission.phone;
      case AppPermission.sms:
        return Permission.sms;
      case AppPermission.calendar:
        return Permission.calendarWriteOnly;
      case AppPermission.mediaLibrary:
        return Permission.mediaLibrary;
      case AppPermission.speech:
        return Permission.speech;
      case AppPermission.ignoreBatteryOptimizations:
        return Permission.ignoreBatteryOptimizations;
      case AppPermission.systemAlertWindow:
        return Permission.systemAlertWindow;
      case AppPermission.requestInstallPackages:
        return Permission.requestInstallPackages;
      case AppPermission.accessNotificationPolicy:
        return Permission.accessNotificationPolicy;
      case AppPermission.bluetoothScan:
        return Permission.bluetoothScan;
      case AppPermission.bluetoothAdvertise:
        return Permission.bluetoothAdvertise;
      case AppPermission.bluetoothConnect:
        return Permission.bluetoothConnect;
      case AppPermission.nearbyWifiDevices:
        return Permission.nearbyWifiDevices;
      case AppPermission.manageExternalStorage:
        return Permission.manageExternalStorage;
      case AppPermission.scheduleExactAlarm:
        return Permission.scheduleExactAlarm;
      case AppPermission.sensors:
        return Permission.sensors;
      case AppPermission.activityRecognition:
        return Permission.activityRecognition;
      default:
        return null;
    }
  }

  PermissionStatus _mapFromNativeStatus(
    permission_handler.PermissionStatus status,
  ) {
    switch (status) {
      case permission_handler.PermissionStatus.denied:
        return PermissionStatus.denied;
      case permission_handler.PermissionStatus.granted:
        return PermissionStatus.granted;
      case permission_handler.PermissionStatus.restricted:
        return PermissionStatus.restricted;
      case permission_handler.PermissionStatus.limited:
        return PermissionStatus.limited;
      case permission_handler.PermissionStatus.permanentlyDenied:
        return PermissionStatus.permanentlyDenied;
      case permission_handler.PermissionStatus.provisional:
        return PermissionStatus.provisional;
      default:
        return PermissionStatus.unknown;
    }
  }

  bool _isRequiredPermission(AppPermission permission) {
    switch (permission) {
      case AppPermission.camera:
      case AppPermission.microphone:
      case AppPermission.storage:
      case AppPermission.notification:
        return true;
      default:
        return false;
    }
  }

  void _startPeriodicCheck() {
    _periodicCheckTimer = Timer.periodic(_checkInterval, (_) {
      _checkAllPermissions();
    });
  }

  Future<void> _cachePermissions() async {
    try {
      final permissionsData = state.value?.permissions.map(
        (key, value) => MapEntry(key.name, value.toJson()),
      );
      if (permissionsData != null) {
        await _localStorage.setString(_storageKey, permissionsData.toString());
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error caching permissions: $e');
    }
  }

  // Public methods
  Future<bool> requestPermission(AppPermission appPermission) async {
    try {
      final permission = _mapToNativePermission(appPermission);
      if (permission == null) {
        throw Exception('Unsupported permission: ${appPermission.name}');
      }

      final currentInfo = state.value?.permissions[appPermission];

      if (currentInfo?.isPermanentlyDenied == true) {
        // Open app settings
        await openAppSettings();
        return false;
      }

      final status = await permission.request();
      final mappedStatus = _mapFromNativeStatus(status);

      state.whenData((permissionState) {
        final updatedPermissions = Map<AppPermission, PermissionInfo>.from(
          permissionState.permissions,
        );

        updatedPermissions[appPermission] = PermissionInfo(
          permission: appPermission,
          status: mappedStatus,
          lastChecked: DateTime.now(),
          lastRequested: DateTime.now(),
          requestCount: (currentInfo?.requestCount ?? 0) + 1,
          isRequired: _isRequiredPermission(appPermission),
        );

        state = AsyncValue.data(
          permissionState.copyWith(
            permissions: updatedPermissions,
            lastUpdate: DateTime.now(),
          ),
        );
      });

      await _cachePermissions();

      if (kDebugMode) {
        print(
          '🔐 Permission ${appPermission.name} requested: ${mappedStatus.name}',
        );
      }

      return mappedStatus == PermissionStatus.granted;
    } catch (e) {
      if (kDebugMode) print('❌ Error requesting permission: $e');
      return false;
    }
  }

  Future<Map<AppPermission, bool>> requestMultiplePermissions(
    List<AppPermission> permissions,
  ) async {
    try {
      final results = <AppPermission, bool>{};

      final nativePermissions = <Permission>[];
      final appPermissionMap = <Permission, AppPermission>{};

      for (final appPermission in permissions) {
        final permission = _mapToNativePermission(appPermission);
        if (permission != null) {
          nativePermissions.add(permission);
          appPermissionMap[permission] = appPermission;
        }
      }

      final statuses = await nativePermissions.request();

      state.whenData((permissionState) {
        final updatedPermissions = Map<AppPermission, PermissionInfo>.from(
          permissionState.permissions,
        );

        for (final entry in statuses.entries) {
          final appPermission = appPermissionMap[entry.key]!;
          final mappedStatus = _mapFromNativeStatus(entry.value);
          final currentInfo = permissionState.permissions[appPermission];

          updatedPermissions[appPermission] = PermissionInfo(
            permission: appPermission,
            status: mappedStatus,
            lastChecked: DateTime.now(),
            lastRequested: DateTime.now(),
            requestCount: (currentInfo?.requestCount ?? 0) + 1,
            isRequired: _isRequiredPermission(appPermission),
          );

          results[appPermission] = mappedStatus == PermissionStatus.granted;
        }

        state = AsyncValue.data(
          permissionState.copyWith(
            permissions: updatedPermissions,
            lastUpdate: DateTime.now(),
          ),
        );
      });

      await _cachePermissions();

      if (kDebugMode) {
        print('🔐 Multiple permissions requested: $results');
      }

      return results;
    } catch (e) {
      if (kDebugMode) print('❌ Error requesting multiple permissions: $e');
      return {};
    }
  }

  Future<void> openAppSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      if (kDebugMode) print('❌ Error opening app settings: $e');
    }
  }

  Future<void> checkPermission(AppPermission appPermission) async {
    try {
      final permission = _mapToNativePermission(appPermission);
      if (permission == null) return;

      final status = await permission.status;
      final mappedStatus = _mapFromNativeStatus(status);

      state.whenData((permissionState) {
        final updatedPermissions = Map<AppPermission, PermissionInfo>.from(
          permissionState.permissions,
        );

        final currentInfo = permissionState.permissions[appPermission];
        updatedPermissions[appPermission] = PermissionInfo(
          permission: appPermission,
          status: mappedStatus,
          lastChecked: DateTime.now(),
          lastRequested: currentInfo?.lastRequested,
          requestCount: currentInfo?.requestCount ?? 0,
          isRequired: _isRequiredPermission(appPermission),
        );

        state = AsyncValue.data(
          permissionState.copyWith(
            permissions: updatedPermissions,
            lastUpdate: DateTime.now(),
          ),
        );
      });

      await _cachePermissions();
    } catch (e) {
      if (kDebugMode) print('❌ Error checking permission: $e');
    }
  }

  Future<void> refreshPermissions() async {
    await _checkAllPermissions();
  }

  String getPermissionDescription(AppPermission permission) {
    switch (permission) {
      case AppPermission.camera:
        return 'Access camera for video calls and taking photos';
      case AppPermission.microphone:
        return 'Access microphone for voice calls and recording audio';
      case AppPermission.photos:
        return 'Access photos to share images in chats';
      case AppPermission.storage:
        return 'Access storage to save and share files';
      case AppPermission.location:
        return 'Access location to share your location in chats';
      case AppPermission.contacts:
        return 'Access contacts to find friends on the app';
      case AppPermission.notification:
        return 'Show notifications for new messages and calls';
      case AppPermission.phone:
        return 'Access phone state for call management';
      default:
        return 'Required for app functionality';
    }
  }

  // Getters
  Map<AppPermission, PermissionInfo> get permissions =>
      state.value?.permissions ?? {};
  bool get isLoading => state.value?.isLoading ?? false;
  bool get allRequiredGranted => state.value?.allRequiredGranted ?? false;
  List<AppPermission> get missingRequiredPermissions =>
      state.value?.missingRequiredPermissions ?? [];

  @override
  void dispose() {
    _periodicCheckTimer?.cancel();
    super.dispose();
  }
}

// Providers
final permissionProvider =
    StateNotifierProvider<PermissionNotifier, AsyncValue<PermissionState>>((
      ref,
    ) {
      return PermissionNotifier(localStorage: LocalStorage());
    });

// Convenience providers
final permissionMapProvider = Provider<Map<AppPermission, PermissionInfo>>((
  ref,
) {
  final permissionState = ref.watch(permissionProvider);
  return permissionState.whenOrNull(data: (state) => state.permissions) ?? {};
});

final isPermissionGrantedProvider = Provider.family<bool, AppPermission>((
  ref,
  permission,
) {
  final permissionState = ref.watch(permissionProvider);
  return permissionState.whenOrNull(
        data: (state) => state.isPermissionGranted(permission),
      ) ??
      false;
});

final permissionStatusProvider =
    Provider.family<PermissionStatus, AppPermission>((ref, permission) {
      final permissionState = ref.watch(permissionProvider);
      return permissionState.whenOrNull(
            data: (state) => state.getPermissionStatus(permission),
          ) ??
          PermissionStatus.unknown;
    });

final allRequiredPermissionsGrantedProvider = Provider<bool>((ref) {
  final permissionState = ref.watch(permissionProvider);
  return permissionState.whenOrNull(
        data: (state) => state.allRequiredGranted,
      ) ??
      false;
});

final missingRequiredPermissionsProvider = Provider<List<AppPermission>>((ref) {
  final permissionState = ref.watch(permissionProvider);
  return permissionState.whenOrNull(
        data: (state) => state.missingRequiredPermissions,
      ) ??
      [];
});

final grantedPermissionsProvider = Provider<List<AppPermission>>((ref) {
  final permissionState = ref.watch(permissionProvider);
  return permissionState.whenOrNull(
        data: (state) => state.grantedPermissions,
      ) ??
      [];
});

final deniedPermissionsProvider = Provider<List<AppPermission>>((ref) {
  final permissionState = ref.watch(permissionProvider);
  return permissionState.whenOrNull(data: (state) => state.deniedPermissions) ??
      [];
});

final permissionLoadingProvider = Provider<bool>((ref) {
  final permissionState = ref.watch(permissionProvider);
  return permissionState.whenOrNull(data: (state) => state.isLoading) ?? false;
});
