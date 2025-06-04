import 'dart:io';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';

class LocationUtils {
  /// Check if location permission is granted
  static Future<bool> hasLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (e) {
      return false;
    }
  }

  /// Request location permission
  static Future<bool> requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        // Permission is permanently denied, open app settings
        await Geolocator.openAppSettings();
        return false;
      }

      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (e) {
      return false;
    }
  }

  /// Format distance in human-readable format
  static String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} m';
    } else if (distanceInMeters < 100000) {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
    } else {
      return '${(distanceInMeters / 1000).round()} km';
    }
  }

  /// Estimate travel time based on distance (walking speed ~5 km/h)
  static String estimateTravelTime(double distanceInMeters) {
    // Assuming average walking speed of 5 km/h
    const double walkingSpeedKmH = 5.0;
    const double walkingSpeedMs = walkingSpeedKmH * 1000 / 3600; // m/s

    final double timeInSeconds = distanceInMeters / walkingSpeedMs;

    if (timeInSeconds < 60) {
      return '${timeInSeconds.round()} sec';
    } else if (timeInSeconds < 3600) {
      final int minutes = (timeInSeconds / 60).round();
      return '$minutes min';
    } else {
      final int hours = (timeInSeconds / 3600).floor();
      final int minutes = ((timeInSeconds % 3600) / 60).round();
      if (minutes == 0) {
        return '$hours h';
      }
      return '$hours h $minutes min';
    }
  }

  /// Generate Google Maps URL for opening location
  static String generateMapsUrl(
    double latitude,
    double longitude, [
    String? label,
  ]) {
    final String labelParam = label != null ? '($label)' : '';

    if (Platform.isIOS) {
      // Use Apple Maps on iOS
      return 'http://maps.apple.com/?q=$latitude,$longitude$labelParam';
    } else {
      // Use Google Maps on Android and others
      return 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    }
  }

  /// Generate directions URL
  static String generateDirectionsUrl(double latitude, double longitude) {
    if (Platform.isIOS) {
      // Use Apple Maps directions on iOS
      return 'http://maps.apple.com/?daddr=$latitude,$longitude&dirflg=d';
    } else {
      // Use Google Maps directions on Android and others
      return 'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=driving';
    }
  }

  /// Generate shareable location text
  static String generateShareText(
    double latitude,
    double longitude, {
    String? name,
    String? address,
    String? description,
  }) {
    final buffer = StringBuffer();

    if (name != null && name.isNotEmpty) {
      buffer.writeln(name);
    }

    if (address != null && address.isNotEmpty) {
      buffer.writeln(address);
    }

    if (description != null && description.isNotEmpty) {
      buffer.writeln(description);
    }

    buffer.writeln('📍 $latitude, $longitude');
    buffer.writeln();
    buffer.writeln(
      'View on map: ${generateMapsUrl(latitude, longitude, name)}',
    );

    return buffer.toString().trim();
  }

  /// Calculate bearing between two points
  static double calculateBearing(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    final double startLatRad = startLat * (3.14159265359 / 180.0);
    final double startLngRad = startLng * (3.14159265359 / 180.0);
    final double endLatRad = endLat * (3.14159265359 / 180.0);
    final double endLngRad = endLng * (3.14159265359 / 180.0);

    final double dLng = endLngRad - startLngRad;

    final double y = math.sin(dLng) * math.cos(endLatRad);
    final double x =
        math.cos(startLatRad) * math.sin(endLatRad) -
        math.sin(startLatRad) * math.cos(endLatRad) * math.cos(dLng);

    final double bearing = math.atan2(y, x);
    return (bearing * (180.0 / 3.14159265359) + 360.0) % 360.0;
  }

  /// Get current position with error handling
  static Future<Position?> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.medium,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    try {
      if (!await hasLocationPermission()) {
        final granted = await requestLocationPermission();
        if (!granted) return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: accuracy,
        timeLimit: timeout,
      );

      return position;
    } catch (e) {
      return null;
    }
  }

  /// Check if location services are enabled
  static Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      return false;
    }
  }

  /// Open location settings
  static Future<void> openLocationSettings() async {
    try {
      await Geolocator.openLocationSettings();
    } catch (e) {
      // Fallback to app settings if location settings can't be opened
      await Geolocator.openAppSettings();
    }
  }

  /// Validate coordinates
  static bool isValidCoordinates(double latitude, double longitude) {
    return latitude >= -90.0 &&
        latitude <= 90.0 &&
        longitude >= -180.0 &&
        longitude <= 180.0;
  }

  /// Format coordinates for display
  static String formatCoordinates(
    double latitude,
    double longitude, {
    int precision = 6,
  }) {
    return '${latitude.toStringAsFixed(precision)}, ${longitude.toStringAsFixed(precision)}';
  }

  /// Get distance between two points in meters
  static double getDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }
}
