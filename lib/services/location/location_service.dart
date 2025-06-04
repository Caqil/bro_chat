import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart'
    as geolocator; // Alias for geolocator package

import '../../core/exceptions/app_exception.dart';
import '../storage/cache_service.dart';
import '../storage/local_storage.dart';

enum LocationAccuracy { lowest, low, medium, high, best, bestForNavigation }

enum LocationServiceState {
  disabled,
  permissionDenied,
  permissionDeniedForever,
  permissionGranted,
  locationDisabled,
  ready,
  fetching,
  error,
}

class LocationData {
  final double latitude;
  final double longitude;
  final double? altitude;
  final double? accuracy;
  final double? bearing;
  final double? speed;
  final DateTime timestamp;
  final String? address;
  final String? country;
  final String? locality;
  final String? subLocality;
  final String? postalCode;

  LocationData({
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.accuracy,
    this.bearing,
    this.speed,
    required this.timestamp,
    this.address,
    this.country,
    this.locality,
    this.subLocality,
    this.postalCode,
  });

  factory LocationData.fromPosition(
    geolocator.Position position, {
    String? address,
  }) {
    return LocationData(
      latitude: position.latitude,
      longitude: position.longitude,
      altitude: position.altitude,
      accuracy: position.accuracy,
      bearing: position.heading,
      speed: position.speed,
      timestamp: position.timestamp ?? DateTime.now(),
      address: address,
    );
  }

  LocationData copyWith({
    double? latitude,
    double? longitude,
    double? altitude,
    double? accuracy,
    double? bearing,
    double? speed,
    DateTime? timestamp,
    String? address,
    String? country,
    String? locality,
    String? subLocality,
    String? postalCode,
  }) {
    return LocationData(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: altitude ?? this.altitude,
      accuracy: accuracy ?? this.accuracy,
      bearing: bearing ?? this.bearing,
      speed: speed ?? this.speed,
      timestamp: timestamp ?? this.timestamp,
      address: address ?? this.address,
      country: country ?? this.country,
      locality: locality ?? this.locality,
      subLocality: subLocality ?? this.subLocality,
      postalCode: postalCode ?? this.postalCode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'accuracy': accuracy,
      'bearing': bearing,
      'speed': speed,
      'timestamp': timestamp.toIso8601String(),
      'address': address,
      'country': country,
      'locality': locality,
      'sub_locality': subLocality,
      'postal_code': postalCode,
    };
  }

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      altitude: json['altitude']?.toDouble(),
      accuracy: json['accuracy']?.toDouble(),
      bearing: json['bearing']?.toDouble(),
      speed: json['speed']?.toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
      address: json['address'],
      country: json['country'],
      locality: json['locality'],
      subLocality: json['sub_locality'],
      postalCode: json['postal_code'],
    );
  }

  double distanceTo(LocationData other) {
    return geolocator.Geolocator.distanceBetween(
      latitude,
      longitude,
      other.latitude,
      other.longitude,
    );
  }

  double bearingTo(LocationData other) {
    return geolocator.Geolocator.bearingBetween(
      latitude,
      longitude,
      other.latitude,
      other.longitude,
    );
  }

  @override
  String toString() {
    return 'LocationData(lat: $latitude, lng: $longitude, accuracy: ${accuracy?.toStringAsFixed(1)}m)';
  }
}

class LocationSettings {
  final LocationAccuracy accuracy;
  final int distanceFilter;
  final Duration? timeLimit;
  final bool enableBackgroundLocation;
  final bool enableHighAccuracy;

  const LocationSettings({
    this.accuracy = LocationAccuracy.high,
    this.distanceFilter = 10,
    this.timeLimit,
    this.enableBackgroundLocation = false,
    this.enableHighAccuracy = true,
  });

  LocationSettings copyWith({
    LocationAccuracy? accuracy,
    int? distanceFilter,
    Duration? timeLimit,
    bool? enableBackgroundLocation,
    bool? enableHighAccuracy,
  }) {
    return LocationSettings(
      accuracy: accuracy ?? this.accuracy,
      distanceFilter: distanceFilter ?? this.distanceFilter,
      timeLimit: timeLimit ?? this.timeLimit,
      enableBackgroundLocation:
          enableBackgroundLocation ?? this.enableBackgroundLocation,
      enableHighAccuracy: enableHighAccuracy ?? this.enableHighAccuracy,
    );
  }
}

class LocationService {
  static LocationService? _instance;

  final CacheService _cacheService;
  final LocalStorage _localStorage;

  // Current state
  LocationServiceState _state = LocationServiceState.disabled;
  LocationData? _currentLocation;
  LocationSettings _settings = const LocationSettings();

  // Streams
  final StreamController<LocationServiceState> _stateController =
      StreamController<LocationServiceState>.broadcast();
  final StreamController<LocationData> _locationController =
      StreamController<LocationData>.broadcast();

  // Location tracking
  StreamSubscription<geolocator.Position>? _positionStreamSubscription;
  Timer? _locationTimeoutTimer;

  // Cache
  final Map<String, LocationData> _locationCache = {};
  final Map<String, String> _addressCache = {};

  LocationService._internal()
    : _cacheService = CacheService(),
      _localStorage = LocalStorage() {
    _initialize();
  }

  factory LocationService() {
    _instance ??= LocationService._internal();
    return _instance!;
  }

  // Getters
  LocationServiceState get state => _state;
  LocationData? get currentLocation => _currentLocation;
  LocationSettings get settings => _settings;

  // Streams
  Stream<LocationServiceState> get stateStream => _stateController.stream;
  Stream<LocationData> get locationStream => _locationController.stream;

  void _initialize() {
    _loadSettings();
    _checkLocationServiceStatus();
  }

  Future<void> _loadSettings() async {
    try {
      final settingsData = _localStorage.getMap('location_settings');
      if (settingsData != null) {
        _settings = LocationSettings(
          accuracy: LocationAccuracy.values.firstWhere(
            (a) => a.name == settingsData['accuracy'],
            orElse: () => LocationAccuracy.high,
          ),
          distanceFilter: settingsData['distance_filter'] ?? 10,
          timeLimit: settingsData['time_limit'] != null
              ? Duration(seconds: settingsData['time_limit'])
              : null,
          enableBackgroundLocation:
              settingsData['enable_background_location'] ?? false,
          enableHighAccuracy: settingsData['enable_high_accuracy'] ?? true,
        );
      }

      // Load cached location
      final cachedLocationData = _localStorage.getMap('last_known_location');
      if (cachedLocationData != null) {
        _currentLocation = LocationData.fromJson(cachedLocationData);
      }

      if (kDebugMode) {
        print('✅ Location settings loaded');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading location settings: $e');
      }
    }
  }

  Future<void> _saveSettings() async {
    try {
      final settingsData = {
        'accuracy': _settings.accuracy.name,
        'distance_filter': _settings.distanceFilter,
        'time_limit': _settings.timeLimit?.inSeconds,
        'enable_background_location': _settings.enableBackgroundLocation,
        'enable_high_accuracy': _settings.enableHighAccuracy,
      };

      await _localStorage.setMap('location_settings', settingsData);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving location settings: $e');
      }
    }
  }

  Future<void> _checkLocationServiceStatus() async {
    try {
      final serviceEnabled =
          await geolocator.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setState(LocationServiceState.locationDisabled);
        return;
      }

      final permission = await geolocator.Geolocator.checkPermission();
      switch (permission) {
        case geolocator.LocationPermission.denied:
          _setState(LocationServiceState.permissionDenied);
          break;
        case geolocator.LocationPermission.deniedForever:
          _setState(LocationServiceState.permissionDeniedForever);
          break;
        case geolocator.LocationPermission.whileInUse:
        case geolocator.LocationPermission.always:
          _setState(LocationServiceState.ready);
          break;
        case geolocator.LocationPermission.unableToDetermine:
          _setState(LocationServiceState.error);
          break;
      }
    } catch (e) {
      _setState(LocationServiceState.error);

      if (kDebugMode) {
        print('❌ Error checking location service status: $e');
      }
    }
  }

  void _setState(LocationServiceState newState) {
    if (_state != newState) {
      _state = newState;
      _stateController.add(newState);

      if (kDebugMode) {
        print('📍 Location service state: ${newState.name}');
      }
    }
  }

  geolocator.LocationAccuracy _mapLocationAccuracy(LocationAccuracy accuracy) {
    switch (accuracy) {
      case LocationAccuracy.lowest:
        return geolocator.LocationAccuracy.lowest;
      case LocationAccuracy.low:
        return geolocator.LocationAccuracy.low;
      case LocationAccuracy.medium:
        return geolocator.LocationAccuracy.medium;
      case LocationAccuracy.high:
        return geolocator.LocationAccuracy.high;
      case LocationAccuracy.best:
        return geolocator.LocationAccuracy.best;
      case LocationAccuracy.bestForNavigation:
        return geolocator.LocationAccuracy.bestForNavigation;
    }
  }

  geolocator.LocationSettings _mapToGeolocatorSettings(
    LocationSettings settings,
  ) {
    return geolocator.LocationSettings(
      accuracy: _mapLocationAccuracy(settings.accuracy),
      distanceFilter: settings.distanceFilter,
      timeLimit: settings.timeLimit,
    );
  }

  // Public API

  Future<bool> requestPermission() async {
    try {
      if (_state == LocationServiceState.permissionDeniedForever) {
        return false;
      }

      final permission = await geolocator.Geolocator.requestPermission();

      switch (permission) {
        case geolocator.LocationPermission.denied:
          _setState(LocationServiceState.permissionDenied);
          return false;
        case geolocator.LocationPermission.deniedForever:
          _setState(LocationServiceState.permissionDeniedForever);
          return false;
        case geolocator.LocationPermission.whileInUse:
        case geolocator.LocationPermission.always:
          _setState(LocationServiceState.ready);
          return true;
        case geolocator.LocationPermission.unableToDetermine:
          _setState(LocationServiceState.error);
          return false;
      }
    } catch (e) {
      _setState(LocationServiceState.error);

      if (kDebugMode) {
        print('❌ Error requesting location permission: $e');
      }

      return false;
    }
  }

  Future<bool> openLocationSettings() async {
    try {
      return await geolocator.Geolocator.openLocationSettings();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error opening location settings: $e');
      }
      return false;
    }
  }

  Future<bool> openAppSettings() async {
    try {
      return await geolocator.Geolocator.openAppSettings();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error opening app settings: $e');
      }
      return false;
    }
  }

  Future<LocationData?> getCurrentLocation({
    LocationSettings? settings,
    bool forceRefresh = false,
  }) async {
    try {
      if (_state != LocationServiceState.ready &&
          _state != LocationServiceState.fetching) {
        await _checkLocationServiceStatus();

        if (_state != LocationServiceState.ready) {
          throw LocationException.permissionDenied();
        }
      }

      // Return cached location if available and not forcing refresh
      if (!forceRefresh && _currentLocation != null) {
        final age = DateTime.now().difference(_currentLocation!.timestamp);
        if (age.inMinutes < 5) {
          // Use cached location if less than 5 minutes old
          return _currentLocation;
        }
      }

      _setState(LocationServiceState.fetching);

      final locationSettings = settings ?? _settings;
      final geolocatorSettings = _mapToGeolocatorSettings(locationSettings);

      // Start timeout timer
      _startLocationTimeout();

      final position = await geolocator.Geolocator.getCurrentPosition(
        locationSettings: geolocatorSettings,
      );

      _cancelLocationTimeout();

      final locationData = LocationData.fromPosition(position);

      // Try to get address
      try {
        final address = await _getAddressFromCoordinates(
          locationData.latitude,
          locationData.longitude,
        );
        final updatedLocation = locationData.copyWith(
          address: address['formatted'],
          country: address['country'],
          locality: address['locality'],
          subLocality: address['subLocality'],
          postalCode: address['postalCode'],
        );

        _currentLocation = updatedLocation;
      } catch (e) {
        // Continue without address if geocoding fails
        _currentLocation = locationData;

        if (kDebugMode) {
          print('⚠️ Geocoding failed: $e');
        }
      }

      // Cache the location
      await _cacheLocation(_currentLocation!);

      _setState(LocationServiceState.ready);
      _locationController.add(_currentLocation!);

      if (kDebugMode) {
        print('📍 Location obtained: ${_currentLocation}');
      }

      return _currentLocation;
    } catch (e) {
      _cancelLocationTimeout();
      _setState(LocationServiceState.error);

      if (kDebugMode) {
        print('❌ Error getting current location: $e');
      }

      if (e is TimeoutException) {
        throw LocationException.timeout();
      } else if (e.toString().contains('permission')) {
        throw LocationException.permissionDenied();
      } else {
        throw LocationException.notAvailable();
      }
    }
  }

  void _startLocationTimeout() {
    _locationTimeoutTimer?.cancel();
    _locationTimeoutTimer = Timer(const Duration(seconds: 30), () {
      _setState(LocationServiceState.error);
      throw LocationException.timeout();
    });
  }

  void _cancelLocationTimeout() {
    _locationTimeoutTimer?.cancel();
    _locationTimeoutTimer = null;
  }

  Future<void> startLocationTracking({LocationSettings? settings}) async {
    try {
      if (_positionStreamSubscription != null) {
        await stopLocationTracking();
      }

      if (_state != LocationServiceState.ready) {
        await _checkLocationServiceStatus();

        if (_state != LocationServiceState.ready) {
          throw LocationException.permissionDenied();
        }
      }

      final locationSettings = settings ?? _settings;
      final geolocatorSettings = _mapToGeolocatorSettings(locationSettings);

      _positionStreamSubscription =
          geolocator.Geolocator.getPositionStream(
            locationSettings: geolocatorSettings,
          ).listen(
            (geolocator.Position position) async {
              final locationData = LocationData.fromPosition(position);

              // Try to get address for new location
              try {
                final address = await _getAddressFromCoordinates(
                  locationData.latitude,
                  locationData.longitude,
                );
                final updatedLocation = locationData.copyWith(
                  address: address['formatted'],
                  country: address['country'],
                  locality: address['locality'],
                  subLocality: address['subLocality'],
                  postalCode: address['postalCode'],
                );

                _currentLocation = updatedLocation;
              } catch (e) {
                _currentLocation = locationData;
              }

              await _cacheLocation(_currentLocation!);
              _locationController.add(_currentLocation!);

              if (kDebugMode) {
                print('📍 Location updated: ${_currentLocation}');
              }
            },
            onError: (error) {
              if (kDebugMode) {
                print('❌ Location tracking error: $error');
              }
            },
          );

      if (kDebugMode) {
        print('📍 Location tracking started');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error starting location tracking: $e');
      }
      rethrow;
    }
  }

  Future<void> stopLocationTracking() async {
    try {
      await _positionStreamSubscription?.cancel();
      _positionStreamSubscription = null;

      if (kDebugMode) {
        print('📍 Location tracking stopped');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error stopping location tracking: $e');
      }
    }
  }

  Future<Map<String, String>> _getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      final cacheKey =
          '${latitude.toStringAsFixed(4)},${longitude.toStringAsFixed(4)}';

      // Check cache first
      if (_addressCache.containsKey(cacheKey)) {
        return {'formatted': _addressCache[cacheKey]!};
      }

      final placemarks = await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        final addressParts = <String>[
          if (place.street?.isNotEmpty == true) place.street!,
          if (place.subLocality?.isNotEmpty == true) place.subLocality!,
          if (place.locality?.isNotEmpty == true) place.locality!,
          if (place.administrativeArea?.isNotEmpty == true)
            place.administrativeArea!,
          if (place.country?.isNotEmpty == true) place.country!,
        ];

        final formattedAddress = addressParts.join(', ');

        // Cache the result
        _addressCache[cacheKey] = formattedAddress;

        return {
          'formatted': formattedAddress,
          'country': place.country ?? '',
          'locality': place.locality ?? '',
          'subLocality': place.subLocality ?? '',
          'postalCode': place.postalCode ?? '',
        };
      }

      return {'formatted': 'Unknown location'};
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting address: $e');
      }
      return {'formatted': 'Unknown location'};
    }
  }

  Future<LocationData?> getLocationFromAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);

      if (locations.isNotEmpty) {
        final location = locations.first;

        final locationData = LocationData(
          latitude: location.latitude,
          longitude: location.longitude,
          timestamp: DateTime.now(),
          address: address,
        );

        return locationData;
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting location from address: $e');
      }
      return null;
    }
  }

  Future<void> _cacheLocation(LocationData location) async {
    try {
      await _localStorage.setMap('last_known_location', location.toJson());

      // Also cache in memory with timestamp key
      final cacheKey = location.timestamp.millisecondsSinceEpoch.toString();
      _locationCache[cacheKey] = location;

      // Keep only last 10 locations in memory cache
      if (_locationCache.length > 10) {
        final oldestKey = _locationCache.keys.first;
        _locationCache.remove(oldestKey);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error caching location: $e');
      }
    }
  }

  void updateSettings(LocationSettings newSettings) {
    _settings = newSettings;
    _saveSettings();

    if (kDebugMode) {
      print('📍 Location settings updated');
    }
  }

  // Utility methods

  double calculateDistance(LocationData from, LocationData to) {
    return geolocator.Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
  }

  double calculateBearing(LocationData from, LocationData to) {
    return geolocator.Geolocator.bearingBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
  }

  bool isLocationWithinRadius(
    LocationData center,
    LocationData target,
    double radiusInMeters,
  ) {
    final distance = calculateDistance(center, target);
    return distance <= radiusInMeters;
  }

  List<LocationData> getLocationHistory() {
    return _locationCache.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  void clearLocationHistory() {
    _locationCache.clear();
    _localStorage.remove('last_known_location');

    if (kDebugMode) {
      print('📍 Location history cleared');
    }
  }

  Future<void> dispose() async {
    await stopLocationTracking();
    _cancelLocationTimeout();

    await _stateController.close();
    await _locationController.close();

    _locationCache.clear();
    _addressCache.clear();

    if (kDebugMode) {
      print('✅ Location service disposed');
    }
  }
}

// Riverpod providers
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

final locationStateProvider = StreamProvider<LocationServiceState>((ref) {
  final service = ref.watch(locationServiceProvider);
  return service.stateStream;
});

final currentLocationProvider = StreamProvider<LocationData>((ref) {
  final service = ref.watch(locationServiceProvider);
  return service.locationStream;
});

final locationPermissionProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(locationServiceProvider);
  return service.requestPermission();
});

final lastKnownLocationProvider = Provider<LocationData?>((ref) {
  final service = ref.watch(locationServiceProvider);
  return service.currentLocation;
});
