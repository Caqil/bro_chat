import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/exceptions/app_exception.dart';
import '../storage/local_storage.dart';
import 'location_service.dart';

enum MapType { normal, satellite, hybrid, terrain }

enum MapStyle { standard, dark, light, custom }

class MapMarkerInfo {
  final String id;
  final LatLng position;
  final String? title;
  final String? snippet;
  final BitmapDescriptor? icon;
  final bool draggable;
  final VoidCallback? onTap;
  final Map<String, dynamic>? data;

  MapMarkerInfo({
    required this.id,
    required this.position,
    this.title,
    this.snippet,
    this.icon,
    this.draggable = false,
    this.onTap,
    this.data,
  });

  Marker toMarker() {
    return Marker(
      markerId: MarkerId(id),
      position: position,
      infoWindow: InfoWindow(title: title, snippet: snippet, onTap: onTap),
      icon: icon ?? BitmapDescriptor.defaultMarker,
      draggable: draggable,
      onTap: onTap,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'title': title,
      'snippet': snippet,
      'draggable': draggable,
      'data': data,
    };
  }

  factory MapMarkerInfo.fromJson(Map<String, dynamic> json) {
    return MapMarkerInfo(
      id: json['id'],
      position: LatLng(json['latitude'], json['longitude']),
      title: json['title'],
      snippet: json['snippet'],
      draggable: json['draggable'] ?? false,
      data: json['data'],
    );
  }
}

class MapPolylineInfo {
  final String id;
  final List<LatLng> points;
  final Color color;
  final int width;
  final List<PatternItem> patterns;
  final bool geodesic;

  MapPolylineInfo({
    required this.id,
    required this.points,
    this.color = const Color(0xFF0000FF),
    this.width = 5,
    this.patterns = const [],
    this.geodesic = false,
  });

  Polyline toPolyline() {
    return Polyline(
      polylineId: PolylineId(id),
      points: points,
      color: color,
      width: width,
      patterns: patterns,
      geodesic: geodesic,
    );
  }
}

class MapPolygonInfo {
  final String id;
  final List<LatLng> points;
  final Color fillColor;
  final Color strokeColor;
  final int strokeWidth;

  MapPolygonInfo({
    required this.id,
    required this.points,
    this.fillColor = const Color(0x80FF0000),
    this.strokeColor = const Color(0xFFFF0000),
    this.strokeWidth = 2,
  });

  Polygon toPolygon() {
    return Polygon(
      polygonId: PolygonId(id),
      points: points,
      fillColor: fillColor,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
    );
  }
}

class MapCircleInfo {
  final String id;
  final LatLng center;
  final double radius;
  final Color fillColor;
  final Color strokeColor;
  final int strokeWidth;

  MapCircleInfo({
    required this.id,
    required this.center,
    required this.radius,
    this.fillColor = const Color(0x80FF0000),
    this.strokeColor = const Color(0xFFFF0000),
    this.strokeWidth = 2,
  });

  Circle toCircle() {
    return Circle(
      circleId: CircleId(id),
      center: center,
      radius: radius,
      fillColor: fillColor,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
    );
  }
}

class MapBounds {
  final LatLng southwest;
  final LatLng northeast;

  MapBounds({required this.southwest, required this.northeast});

  LatLngBounds toLatLngBounds() {
    return LatLngBounds(southwest: southwest, northeast: northeast);
  }

  LatLng get center {
    return LatLng(
      (southwest.latitude + northeast.latitude) / 2,
      (southwest.longitude + northeast.longitude) / 2,
    );
  }

  bool contains(LatLng point) {
    return point.latitude >= southwest.latitude &&
        point.latitude <= northeast.latitude &&
        point.longitude >= southwest.longitude &&
        point.longitude <= northeast.longitude;
  }

  static MapBounds fromPoints(List<LatLng> points) {
    if (points.isEmpty) {
      throw ArgumentError('Points list cannot be empty');
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }

    return MapBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }
}

class MapsService {
  static MapsService? _instance;

  final LocationService _locationService;
  final LocalStorage _localStorage;

  // Map controllers
  final Map<String, GoogleMapController> _mapControllers = {};

  // Map data
  final Map<String, MapMarkerInfo> _markers = {};
  final Map<String, MapPolylineInfo> _polylines = {};
  final Map<String, MapPolygonInfo> _polygons = {};
  final Map<String, MapCircleInfo> _circles = {};

  // Map settings
  MapType _mapType = MapType.normal;
  MapStyle _mapStyle = MapStyle.standard;
  bool _showMyLocationButton = true;
  bool _showMapToolbar = true;
  bool _enableZoomGestures = true;
  bool _enableScrollGestures = true;
  bool _enableRotateGestures = true;
  bool _enableTiltGestures = true;

  // Event streams
  final StreamController<MapMarkerInfo> _markerController =
      StreamController<MapMarkerInfo>.broadcast();
  final StreamController<LatLng> _mapTapController =
      StreamController<LatLng>.broadcast();
  final StreamController<CameraPosition> _cameraController =
      StreamController<CameraPosition>.broadcast();

  // Cached map styles
  final Map<MapStyle, String> _mapStyles = {};

  MapsService._internal()
    : _locationService = LocationService(),
      _localStorage = LocalStorage() {
    _initialize();
  }

  factory MapsService() {
    _instance ??= MapsService._internal();
    return _instance!;
  }

  // Getters
  MapType get mapType => _mapType;
  MapStyle get mapStyle => _mapStyle;
  bool get showMyLocationButton => _showMyLocationButton;
  bool get showMapToolbar => _showMapToolbar;
  List<MapMarkerInfo> get markers => _markers.values.toList();
  List<MapPolylineInfo> get polylines => _polylines.values.toList();
  List<MapPolygonInfo> get polygons => _polygons.values.toList();
  List<MapCircleInfo> get circles => _circles.values.toList();

  // Streams
  Stream<MapMarkerInfo> get markerUpdates => _markerController.stream;
  Stream<LatLng> get mapTaps => _mapTapController.stream;
  Stream<CameraPosition> get cameraUpdates => _cameraController.stream;

  void _initialize() {
    _loadMapStyles();
    _loadSettings();
  }

  Future<void> _loadMapStyles() async {
    try {
      // Load custom map styles from assets or cache
      _mapStyles[MapStyle.dark] = '''
        [
          {
            "elementType": "geometry",
            "stylers": [{"color": "#212121"}]
          },
          {
            "elementType": "labels.icon",
            "stylers": [{"visibility": "off"}]
          },
          {
            "elementType": "labels.text.fill",
            "stylers": [{"color": "#757575"}]
          }
        ]
      ''';

      _mapStyles[MapStyle.light] = '''
        [
          {
            "elementType": "geometry",
            "stylers": [{"color": "#f5f5f5"}]
          },
          {
            "elementType": "labels.text.fill",
            "stylers": [{"color": "#616161"}]
          }
        ]
      ''';

      if (kDebugMode) {
        print('✅ Map styles loaded');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading map styles: $e');
      }
    }
  }

  Future<void> _loadSettings() async {
    try {
      final settings = _localStorage.getMap('map_settings');
      if (settings != null) {
        _mapType = MapType.values.firstWhere(
          (type) => type.name == settings['map_type'],
          orElse: () => MapType.normal,
        );
        _mapStyle = MapStyle.values.firstWhere(
          (style) => style.name == settings['map_style'],
          orElse: () => MapStyle.standard,
        );
        _showMyLocationButton = settings['show_my_location_button'] ?? true;
        _showMapToolbar = settings['show_map_toolbar'] ?? true;
        _enableZoomGestures = settings['enable_zoom_gestures'] ?? true;
        _enableScrollGestures = settings['enable_scroll_gestures'] ?? true;
        _enableRotateGestures = settings['enable_rotate_gestures'] ?? true;
        _enableTiltGestures = settings['enable_tilt_gestures'] ?? true;
      }

      if (kDebugMode) {
        print('✅ Map settings loaded');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading map settings: $e');
      }
    }
  }

  Future<void> _saveSettings() async {
    try {
      final settings = {
        'map_type': _mapType.name,
        'map_style': _mapStyle.name,
        'show_my_location_button': _showMyLocationButton,
        'show_map_toolbar': _showMapToolbar,
        'enable_zoom_gestures': _enableZoomGestures,
        'enable_scroll_gestures': _enableScrollGestures,
        'enable_rotate_gestures': _enableRotateGestures,
        'enable_tilt_gestures': _enableTiltGestures,
      };

      await _localStorage.setMap('map_settings', settings);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving map settings: $e');
      }
    }
  }

  // Public API

  void registerMapController(String mapId, GoogleMapController controller) {
    _mapControllers[mapId] = controller;

    if (kDebugMode) {
      print('🗺️ Map controller registered: $mapId');
    }
  }

  void unregisterMapController(String mapId) {
    _mapControllers.remove(mapId);

    if (kDebugMode) {
      print('🗺️ Map controller unregistered: $mapId');
    }
  }

  GoogleMapController? getMapController(String mapId) {
    return _mapControllers[mapId];
  }

  // Camera operations

  Future<void> animateCamera(
    String mapId,
    CameraUpdate cameraUpdate, {
    Duration? duration,
  }) async {
    try {
      final controller = _mapControllers[mapId];
      if (controller != null) {
        await controller.animateCamera(cameraUpdate);

        if (kDebugMode) {
          print('📷 Camera animated for map: $mapId');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error animating camera: $e');
      }
    }
  }

  Future<void> moveCamera(String mapId, CameraUpdate cameraUpdate) async {
    try {
      final controller = _mapControllers[mapId];
      if (controller != null) {
        await controller.moveCamera(cameraUpdate);

        if (kDebugMode) {
          print('📷 Camera moved for map: $mapId');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error moving camera: $e');
      }
    }
  }

  Future<void> moveCameraToLocation(
    String mapId,
    LatLng location, {
    double zoom = 15.0,
    bool animate = true,
  }) async {
    final cameraUpdate = CameraUpdate.newCameraPosition(
      CameraPosition(target: location, zoom: zoom),
    );

    if (animate) {
      await animateCamera(mapId, cameraUpdate);
    } else {
      await moveCamera(mapId, cameraUpdate);
    }
  }

  Future<void> moveCameraToCurrentLocation(
    String mapId, {
    double zoom = 15.0,
    bool animate = true,
  }) async {
    try {
      final currentLocation = await _locationService.getCurrentLocation();
      if (currentLocation != null) {
        final latLng = LatLng(
          currentLocation.latitude,
          currentLocation.longitude,
        );
        await moveCameraToLocation(mapId, latLng, zoom: zoom, animate: animate);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error moving camera to current location: $e');
      }
      throw LocationException.notAvailable();
    }
  }

  Future<void> fitBounds(
    String mapId,
    MapBounds bounds, {
    double padding = 50.0,
    bool animate = true,
  }) async {
    final cameraUpdate = CameraUpdate.newLatLngBounds(
      bounds.toLatLngBounds(),
      padding,
    );

    if (animate) {
      await animateCamera(mapId, cameraUpdate);
    } else {
      await moveCamera(mapId, cameraUpdate);
    }
  }

  Future<void> fitMarkersInView(
    String mapId, {
    List<String>? markerIds,
    double padding = 50.0,
    bool animate = true,
  }) async {
    try {
      final markersToFit = markerIds != null
          ? _markers.values.where((m) => markerIds.contains(m.id)).toList()
          : _markers.values.toList();

      if (markersToFit.isEmpty) return;

      final points = markersToFit.map((m) => m.position).toList();
      final bounds = MapBounds.fromPoints(points);

      await fitBounds(mapId, bounds, padding: padding, animate: animate);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fitting markers in view: $e');
      }
    }
  }

  // Marker operations

  void addMarker(MapMarkerInfo markerInfo) {
    _markers[markerInfo.id] = markerInfo;
    _markerController.add(markerInfo);

    if (kDebugMode) {
      print('📍 Marker added: ${markerInfo.id}');
    }
  }

  void removeMarker(String markerId) {
    final removed = _markers.remove(markerId);
    if (removed != null) {
      _markerController.add(removed);

      if (kDebugMode) {
        print('📍 Marker removed: $markerId');
      }
    }
  }

  void updateMarker(String markerId, MapMarkerInfo updatedMarker) {
    if (_markers.containsKey(markerId)) {
      _markers[markerId] = updatedMarker;
      _markerController.add(updatedMarker);

      if (kDebugMode) {
        print('📍 Marker updated: $markerId');
      }
    }
  }

  MapMarkerInfo? getMarker(String markerId) {
    return _markers[markerId];
  }

  void clearMarkers() {
    _markers.clear();

    if (kDebugMode) {
      print('📍 All markers cleared');
    }
  }

  // Polyline operations

  void addPolyline(MapPolylineInfo polylineInfo) {
    _polylines[polylineInfo.id] = polylineInfo;

    if (kDebugMode) {
      print('📏 Polyline added: ${polylineInfo.id}');
    }
  }

  void removePolyline(String polylineId) {
    _polylines.remove(polylineId);

    if (kDebugMode) {
      print('📏 Polyline removed: $polylineId');
    }
  }

  void clearPolylines() {
    _polylines.clear();

    if (kDebugMode) {
      print('📏 All polylines cleared');
    }
  }

  // Polygon operations

  void addPolygon(MapPolygonInfo polygonInfo) {
    _polygons[polygonInfo.id] = polygonInfo;

    if (kDebugMode) {
      print('🔺 Polygon added: ${polygonInfo.id}');
    }
  }

  void removePolygon(String polygonId) {
    _polygons.remove(polygonId);

    if (kDebugMode) {
      print('🔺 Polygon removed: $polygonId');
    }
  }

  void clearPolygons() {
    _polygons.clear();

    if (kDebugMode) {
      print('🔺 All polygons cleared');
    }
  }

  // Circle operations

  void addCircle(MapCircleInfo circleInfo) {
    _circles[circleInfo.id] = circleInfo;

    if (kDebugMode) {
      print('⭕ Circle added: ${circleInfo.id}');
    }
  }

  void removeCircle(String circleId) {
    _circles.remove(circleId);

    if (kDebugMode) {
      print('⭕ Circle removed: $circleId');
    }
  }

  void clearCircles() {
    _circles.clear();

    if (kDebugMode) {
      print('⭕ All circles cleared');
    }
  }

  // Map settings

  Future<void> setMapType(MapType mapType) async {
    _mapType = mapType;
    await _saveSettings();

    if (kDebugMode) {
      print('🗺️ Map type changed to: ${mapType.name}');
    }
  }

  Future<void> setMapStyle(String mapId, MapStyle mapStyle) async {
    try {
      _mapStyle = mapStyle;

      final controller = _mapControllers[mapId];
      if (controller != null) {
        String? style;

        if (mapStyle != MapStyle.standard) {
          style = _mapStyles[mapStyle];
        }

        await controller.setMapStyle(style);
      }

      await _saveSettings();

      if (kDebugMode) {
        print('🎨 Map style changed to: ${mapStyle.name}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error setting map style: $e');
      }
    }
  }

  // Utility methods

  double calculateDistance(LatLng from, LatLng to) {
    return _locationService.calculateDistance(
      LocationData(
        latitude: from.latitude,
        longitude: from.longitude,
        timestamp: DateTime.now(),
      ),
      LocationData(
        latitude: to.latitude,
        longitude: to.longitude,
        timestamp: DateTime.now(),
      ),
    );
  }

  double calculateBearing(LatLng from, LatLng to) {
    return _locationService.calculateBearing(
      LocationData(
        latitude: from.latitude,
        longitude: from.longitude,
        timestamp: DateTime.now(),
      ),
      LocationData(
        latitude: to.latitude,
        longitude: to.longitude,
        timestamp: DateTime.now(),
      ),
    );
  }

  LatLng interpolate(LatLng from, LatLng to, double ratio) {
    final lat = from.latitude + (to.latitude - from.latitude) * ratio;
    final lng = from.longitude + (to.longitude - from.longitude) * ratio;
    return LatLng(lat, lng);
  }

  List<LatLng> simplifyPolyline(List<LatLng> points, double tolerance) {
    if (points.length <= 2) return points;

    // Douglas-Peucker algorithm implementation
    return _douglasPeucker(points, tolerance);
  }

  List<LatLng> _douglasPeucker(List<LatLng> points, double tolerance) {
    if (points.length <= 2) return points;

    double maxDistance = 0;
    int maxIndex = 0;

    for (int i = 1; i < points.length - 1; i++) {
      final distance = _perpendicularDistance(
        points[i],
        points.first,
        points.last,
      );
      if (distance > maxDistance) {
        maxDistance = distance;
        maxIndex = i;
      }
    }

    if (maxDistance > tolerance) {
      final left = _douglasPeucker(points.sublist(0, maxIndex + 1), tolerance);
      final right = _douglasPeucker(points.sublist(maxIndex), tolerance);

      return [...left.sublist(0, left.length - 1), ...right];
    } else {
      return [points.first, points.last];
    }
  }

  double _perpendicularDistance(
    LatLng point,
    LatLng lineStart,
    LatLng lineEnd,
  ) {
    final x0 = point.latitude;
    final y0 = point.longitude;
    final x1 = lineStart.latitude;
    final y1 = lineStart.longitude;
    final x2 = lineEnd.latitude;
    final y2 = lineEnd.longitude;

    final num = ((y2 - y1) * x0 - (x2 - x1) * y0 + x2 * y1 - y2 * x1).abs();
    final den = math.sqrt((y2 - y1) * (y2 - y1) + (x2 - x1) * (x2 - x1));

    return num / den;
  }

  // Screenshot and export

  Future<Uint8List?> takeMapSnapshot(String mapId) async {
    try {
      final controller = _mapControllers[mapId];
      if (controller != null) {
        return await controller.takeSnapshot();
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error taking map snapshot: $e');
      }
      return null;
    }
  }

  // Event handlers

  void onMapTap(LatLng location) {
    _mapTapController.add(location);
  }

  void onCameraMove(CameraPosition position) {
    _cameraController.add(position);
  }

  // Geofencing

  bool isPointInCircle(LatLng point, LatLng center, double radiusInMeters) {
    final distance = calculateDistance(point, center);
    return distance <= radiusInMeters;
  }

  bool isPointInPolygon(LatLng point, List<LatLng> polygon) {
    int intersections = 0;
    final x = point.latitude;
    final y = point.longitude;

    for (int i = 0; i < polygon.length; i++) {
      final j = (i + 1) % polygon.length;
      final xi = polygon[i].latitude;
      final yi = polygon[i].longitude;
      final xj = polygon[j].latitude;
      final yj = polygon[j].longitude;

      if (((yi > y) != (yj > y)) &&
          (x < (xj - xi) * (y - yi) / (yj - yi) + xi)) {
        intersections++;
      }
    }

    return intersections % 2 == 1;
  }

  // Cleanup

  void clearAllMapData() {
    clearMarkers();
    clearPolylines();
    clearPolygons();
    clearCircles();

    if (kDebugMode) {
      print('🗺️ All map data cleared');
    }
  }

  Future<void> dispose() async {
    _mapControllers.clear();
    clearAllMapData();

    await _markerController.close();
    await _mapTapController.close();
    await _cameraController.close();

    if (kDebugMode) {
      print('✅ Maps service disposed');
    }
  }
}

// Riverpod providers
final mapsServiceProvider = Provider<MapsService>((ref) {
  return MapsService();
});

final mapMarkersProvider = Provider<List<MapMarkerInfo>>((ref) {
  final service = ref.watch(mapsServiceProvider);
  return service.markers;
});

final mapPolylinesProvider = Provider<List<MapPolylineInfo>>((ref) {
  final service = ref.watch(mapsServiceProvider);
  return service.polylines;
});

final mapPolygonsProvider = Provider<List<MapPolygonInfo>>((ref) {
  final service = ref.watch(mapsServiceProvider);
  return service.polygons;
});

final mapCirclesProvider = Provider<List<MapCircleInfo>>((ref) {
  final service = ref.watch(mapsServiceProvider);
  return service.circles;
});

final mapTapProvider = StreamProvider<LatLng>((ref) {
  final service = ref.watch(mapsServiceProvider);
  return service.mapTaps;
});

final cameraUpdatesProvider = StreamProvider<CameraPosition>((ref) {
  final service = ref.watch(mapsServiceProvider);
  return service.cameraUpdates;
});

final mapTypeProvider = Provider<MapType>((ref) {
  final service = ref.watch(mapsServiceProvider);
  return service.mapType;
});
