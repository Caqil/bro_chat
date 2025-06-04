import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:geolocator/geolocator.dart';

import '../../models/chat/message_model.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';

class LocationMessageWidget extends ConsumerStatefulWidget {
  final MessageModel message;
  final bool isCurrentUser;
  final double maxWidth;
  final double mapHeight;
  final VoidCallback? onLocationShared;
  final Function(String)? onError;

  const LocationMessageWidget({
    Key? key,
    required this.message,
    required this.isCurrentUser,
    this.maxWidth = 280,
    this.mapHeight = 200,
    this.onLocationShared,
    this.onError,
  }) : super(key: key);

  @override
  ConsumerState<LocationMessageWidget> createState() =>
      _LocationMessageWidgetState();
}

class _LocationMessageWidgetState extends ConsumerState<LocationMessageWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseAnimationController;
  late AnimationController _scaleAnimationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  GoogleMapController? _mapController;
  LocationInfo? _locationInfo;
  bool _isMapLoading = true;
  bool _isCalculatingDistance = false;
  String? _distanceText;
  String? _durationText;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _parseLocationInfo();
    _calculateDistance();
  }

  void _initializeAnimations() {
    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _pulseAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _scaleAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _pulseAnimationController.repeat(reverse: true);
  }

  void _parseLocationInfo() {
    try {
      final metadata = widget.message.metadata;
      if (metadata != null && metadata['location'] != null) {
        final locationData = metadata['location'] as Map<String, dynamic>;

        _locationInfo = LocationInfo(
          latitude: locationData['latitude'] as double? ?? 0.0,
          longitude: locationData['longitude'] as double? ?? 0.0,
          address: locationData['address'] as String?,
          name: locationData['name'] as String?,
          description: locationData['description'] as String?,
          accuracy: locationData['accuracy'] as double?,
          timestamp: locationData['timestamp'] != null
              ? DateTime.tryParse(locationData['timestamp'] as String)
              : null,
        );
      }
    } catch (e) {
      widget.onError?.call('Failed to parse location information: $e');
    }
  }

  Future<void> _calculateDistance() async {
    if (_locationInfo == null) return;

    setState(() {
      _isCalculatingDistance = true;
    });

    try {
      // Get current position
      final hasPermission = await LocationUtils.hasLocationPermission();
      if (!hasPermission) {
        final granted = await LocationUtils.requestLocationPermission();
        if (!granted) {
          throw Exception('Location permission denied');
        }
      }

      final currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      final distance = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        _locationInfo!.latitude,
        _locationInfo!.longitude,
      );

      final distanceText = LocationUtils.formatDistance(distance);
      final duration = LocationUtils.estimateTravelTime(distance);

      if (mounted) {
        setState(() {
          _distanceText = distanceText;
          _durationText = duration;
          _isCalculatingDistance = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCalculatingDistance = false;
        });
      }
    }
  }

  Future<void> _openInMaps() async {
    if (_locationInfo == null) return;

    try {
      final url = LocationUtils.generateMapsUrl(
        _locationInfo!.latitude,
        _locationInfo!.longitude,
        _locationInfo!.name ?? _locationInfo!.address,
      );

      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        throw Exception('Cannot open maps application');
      }
    } catch (e) {
      SnackbarUtils.showError(context, 'Failed to open maps: $e');
    }
  }

  Future<void> _getDirections() async {
    if (_locationInfo == null) return;

    try {
      final url = LocationUtils.generateDirectionsUrl(
        _locationInfo!.latitude,
        _locationInfo!.longitude,
      );

      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        throw Exception('Cannot open directions');
      }
    } catch (e) {
      SnackbarUtils.showError(context, 'Failed to get directions: $e');
    }
  }

  Future<void> _shareLocation() async {
    if (_locationInfo == null) return;

    try {
      final locationText = _buildLocationText();
      await Share.share(locationText, subject: 'Location');
      widget.onLocationShared?.call();
    } catch (e) {
      SnackbarUtils.showError(context, 'Failed to share location: $e');
    }
  }

  String _buildLocationText() {
    if (_locationInfo == null) return 'Location';

    final buffer = StringBuffer();

    if (_locationInfo!.name != null) {
      buffer.writeln(_locationInfo!.name);
    }

    if (_locationInfo!.address != null) {
      buffer.writeln(_locationInfo!.address);
    }

    buffer.writeln('${_locationInfo!.latitude}, ${_locationInfo!.longitude}');

    final mapsUrl = LocationUtils.generateMapsUrl(
      _locationInfo!.latitude,
      _locationInfo!.longitude,
      _locationInfo!.name ?? _locationInfo!.address,
    );
    buffer.writeln(mapsUrl);

    return buffer.toString();
  }

  void _copyCoordinates() {
    if (_locationInfo == null) return;

    final coordinates =
        '${_locationInfo!.latitude}, ${_locationInfo!.longitude}';
    Clipboard.setData(ClipboardData(text: coordinates));

    SnackbarUtils.showSuccess(context, 'Coordinates copied to clipboard');
  }

  void _showLocationActions() {
    _scaleAnimationController.forward().then((_) {
      _scaleAnimationController.reverse();
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildLocationActionsSheet(),
    );
  }

  Widget _buildLocationActionsSheet() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  _locationInfo?.name ?? _locationInfo?.address ?? 'Location',
                  style: AppTextStyles.h6.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                _buildActionButton(
                  icon: Icons.map,
                  label: 'Open in Maps',
                  onPressed: _openInMaps,
                ),
                _buildActionButton(
                  icon: Icons.directions,
                  label: 'Get Directions',
                  onPressed: _getDirections,
                ),
                _buildActionButton(
                  icon: Icons.share,
                  label: 'Share Location',
                  onPressed: _shareLocation,
                ),
                _buildActionButton(
                  icon: Icons.copy,
                  label: 'Copy Coordinates',
                  onPressed: _copyCoordinates,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          foregroundColor: AppColors.primary,
          backgroundColor: AppColors.primary.withOpacity(0.1),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildMapContainer() {
    if (_locationInfo == null) {
      return Container(
        width: double.infinity,
        height: widget.mapHeight,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_off, size: 48, color: Colors.grey[600]),
              const SizedBox(height: 8),
              Text(
                'Location not available',
                style: AppTextStyles.body2.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: widget.mapHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  _locationInfo!.latitude,
                  _locationInfo!.longitude,
                ),
                zoom: 15.0,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('location'),
                  position: LatLng(
                    _locationInfo!.latitude,
                    _locationInfo!.longitude,
                  ),
                  infoWindow: InfoWindow(
                    title: _locationInfo!.name ?? 'Location',
                    snippet: _locationInfo!.address,
                  ),
                ),
              },
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
                setState(() {
                  _isMapLoading = false;
                });
              },
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              scrollGesturesEnabled: false,
              zoomGesturesEnabled: false,
              rotateGesturesEnabled: false,
              tiltGesturesEnabled: false,
            ),
            // Loading overlay
            if (_isMapLoading)
              Container(
                color: Colors.grey[300],
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppColors.primary),
                      const SizedBox(height: 8),
                      Text(
                        'Loading map...',
                        style: AppTextStyles.body2.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Tap overlay for interactions
            Positioned.fill(
              child: GestureDetector(
                onTap: _showLocationActions,
                child: Container(color: Colors.transparent),
              ),
            ),
            // Accuracy indicator
            if (_locationInfo!.accuracy != null)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Accuracy: ${_locationInfo!.accuracy!.toStringAsFixed(0)}m',
                    style: AppTextStyles.caption.copyWith(color: Colors.white),
                  ),
                ),
              ),
            // Action button
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: _showLocationActions,
                  icon: const Icon(
                    Icons.more_vert,
                    color: Colors.white,
                    size: 20,
                  ),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationInfo() {
    if (_locationInfo == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_locationInfo!.name != null) ...[
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Icon(
                      Icons.location_on,
                      color: widget.isCurrentUser
                          ? Colors.white.withOpacity(0.9)
                          : AppColors.primary,
                      size: 16,
                    ),
                  );
                },
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _locationInfo!.name!,
                  style: AppTextStyles.subtitle2.copyWith(
                    color: widget.isCurrentUser
                        ? Colors.white
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
        if (_locationInfo!.address != null) ...[
          Text(
            _locationInfo!.address!,
            style: AppTextStyles.body2.copyWith(
              color: widget.isCurrentUser
                  ? Colors.white.withOpacity(0.9)
                  : AppColors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            if (_distanceText != null) ...[
              Icon(
                Icons.straighten,
                size: 14,
                color: widget.isCurrentUser
                    ? Colors.white.withOpacity(0.8)
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                _distanceText!,
                style: AppTextStyles.caption.copyWith(
                  color: widget.isCurrentUser
                      ? Colors.white.withOpacity(0.8)
                      : AppColors.textSecondary,
                ),
              ),
            ],
            if (_durationText != null) ...[
              if (_distanceText != null) ...[
                Text(
                  ' • ',
                  style: AppTextStyles.caption.copyWith(
                    color: widget.isCurrentUser
                        ? Colors.white.withOpacity(0.6)
                        : AppColors.textSecondary.withOpacity(0.6),
                  ),
                ),
              ],
              Icon(
                Icons.access_time,
                size: 14,
                color: widget.isCurrentUser
                    ? Colors.white.withOpacity(0.8)
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                _durationText!,
                style: AppTextStyles.caption.copyWith(
                  color: widget.isCurrentUser
                      ? Colors.white.withOpacity(0.8)
                      : AppColors.textSecondary,
                ),
              ),
            ],
            if (_isCalculatingDistance) ...[
              const SizedBox(width: 8),
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.isCurrentUser
                        ? Colors.white.withOpacity(0.8)
                        : AppColors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
        if (_locationInfo!.description != null) ...[
          const SizedBox(height: 8),
          Text(
            _locationInfo!.description!,
            style: AppTextStyles.body2.copyWith(
              color: widget.isCurrentUser
                  ? Colors.white.withOpacity(0.9)
                  : AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: _openInMaps,
          icon: Icon(
            Icons.map,
            color: widget.isCurrentUser
                ? Colors.white.withOpacity(0.8)
                : AppColors.primary,
            size: 20,
          ),
          tooltip: 'Open in Maps',
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
        IconButton(
          onPressed: _getDirections,
          icon: Icon(
            Icons.directions,
            color: widget.isCurrentUser
                ? Colors.white.withOpacity(0.8)
                : AppColors.primary,
            size: 20,
          ),
          tooltip: 'Get Directions',
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
        IconButton(
          onPressed: _shareLocation,
          icon: Icon(
            Icons.share,
            color: widget.isCurrentUser
                ? Colors.white.withOpacity(0.8)
                : AppColors.primary,
            size: 20,
          ),
          tooltip: 'Share Location',
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        constraints: BoxConstraints(maxWidth: widget.maxWidth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMapContainer(),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildLocationInfo()),
                  _buildQuickActions(),
                ],
              ),
            ),
            if (widget.message.content.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  widget.message.content,
                  style: AppTextStyles.body2.copyWith(
                    color: widget.isCurrentUser
                        ? Colors.white
                        : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pulseAnimationController.dispose();
    _scaleAnimationController.dispose();
    _mapController?.dispose();
    super.dispose();
  }
}

class LocationInfo {
  final double latitude;
  final double longitude;
  final String? address;
  final String? name;
  final String? description;
  final double? accuracy;
  final DateTime? timestamp;

  LocationInfo({
    required this.latitude,
    required this.longitude,
    this.address,
    this.name,
    this.description,
    this.accuracy,
    this.timestamp,
  });
}
