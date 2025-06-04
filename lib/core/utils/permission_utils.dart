import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import '../exceptions/permission_exception.dart';
import '../constants/string_constants.dart';

class PermissionUtils {
  // Private constructor to prevent instantiation
  PermissionUtils._();

  // Camera permissions
  static Future<bool> requestCameraPermission() async {
    try {
      final status = await Permission.camera.request();
      return status == PermissionStatus.granted;
    } catch (e) {
      throw PermissionException.camera();
    }
  }

  static Future<bool> hasCameraPermission() async {
    try {
      final status = await Permission.camera.status;
      return status == PermissionStatus.granted;
    } catch (e) {
      return false;
    }
  }

  static Future<PermissionStatus> getCameraPermissionStatus() async {
    return await Permission.camera.status;
  }

  // Microphone permissions
  static Future<bool> requestMicrophonePermission() async {
    try {
      final status = await Permission.microphone.request();
      return status == PermissionStatus.granted;
    } catch (e) {
      throw PermissionException.microphone();
    }
  }

  static Future<bool> hasMicrophonePermission() async {
    try {
      final status = await Permission.microphone.status;
      return status == PermissionStatus.granted;
    } catch (e) {
      return false;
    }
  }

  static Future<PermissionStatus> getMicrophonePermissionStatus() async {
    return await Permission.microphone.status;
  }

  // Storage permissions
  static Future<bool> requestStoragePermission() async {
    try {
      PermissionStatus status;
      if (Platform.isAndroid) {
        // For Android 13+, we need to request specific permissions
        if (await _isAndroid13OrHigher()) {
          status = await Permission.photos.request();
          if (status != PermissionStatus.granted) {
            status = await Permission.videos.request();
          }
        } else {
          status = await Permission.storage.request();
        }
      } else {
        // For iOS, request photos permission
        status = await Permission.photos.request();
      }
      return status == PermissionStatus.granted;
    } catch (e) {
      throw PermissionException.storage();
    }
  }

  static Future<bool> hasStoragePermission() async {
    try {
      if (Platform.isAndroid) {
        if (await _isAndroid13OrHigher()) {
          final photosStatus = await Permission.photos.status;
          final videosStatus = await Permission.videos.status;
          return photosStatus == PermissionStatus.granted ||
              videosStatus == PermissionStatus.granted;
        } else {
          final status = await Permission.storage.status;
          return status == PermissionStatus.granted;
        }
      } else {
        final status = await Permission.photos.status;
        return status == PermissionStatus.granted;
      }
    } catch (e) {
      return false;
    }
  }

  // Photos permissions
  static Future<bool> requestPhotosPermission() async {
    try {
      final status = await Permission.photos.request();
      return status == PermissionStatus.granted;
    } catch (e) {
      throw PermissionException.storage();
    }
  }

  static Future<bool> hasPhotosPermission() async {
    try {
      final status = await Permission.photos.status;
      return status == PermissionStatus.granted;
    } catch (e) {
      return false;
    }
  }

  // Videos permissions (Android 13+)
  static Future<bool> requestVideosPermission() async {
    try {
      if (Platform.isAndroid && await _isAndroid13OrHigher()) {
        final status = await Permission.videos.request();
        return status == PermissionStatus.granted;
      }
      return await requestPhotosPermission();
    } catch (e) {
      throw PermissionException.storage();
    }
  }

  static Future<bool> hasVideosPermission() async {
    try {
      if (Platform.isAndroid && await _isAndroid13OrHigher()) {
        final status = await Permission.videos.status;
        return status == PermissionStatus.granted;
      }
      return await hasPhotosPermission();
    } catch (e) {
      return false;
    }
  }

  // Location permissions
  static Future<bool> requestLocationPermission() async {
    try {
      final status = await Permission.location.request();
      return status == PermissionStatus.granted;
    } catch (e) {
      throw PermissionException.location();
    }
  }

  static Future<bool> hasLocationPermission() async {
    try {
      final status = await Permission.location.status;
      return status == PermissionStatus.granted;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> requestLocationWhenInUsePermission() async {
    try {
      final status = await Permission.locationWhenInUse.request();
      return status == PermissionStatus.granted;
    } catch (e) {
      throw PermissionException.location();
    }
  }

  static Future<bool> hasLocationWhenInUsePermission() async {
    try {
      final status = await Permission.locationWhenInUse.status;
      return status == PermissionStatus.granted;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> requestLocationAlwaysPermission() async {
    try {
      final status = await Permission.locationAlways.request();
      return status == PermissionStatus.granted;
    } catch (e) {
      throw PermissionException.location();
    }
  }

  static Future<bool> hasLocationAlwaysPermission() async {
    try {
      final status = await Permission.locationAlways.status;
      return status == PermissionStatus.granted;
    } catch (e) {
      return false;
    }
  }

  // Contacts permissions
  static Future<bool> requestContactsPermission() async {
    try {
      final status = await Permission.contacts.request();
      return status == PermissionStatus.granted;
    } catch (e) {
      throw PermissionException.contacts();
    }
  }

  static Future<bool> hasContactsPermission() async {
    try {
      final status = await Permission.contacts.status;
      return status == PermissionStatus.granted;
    } catch (e) {
      return false;
    }
  }

  // Notification permissions
  static Future<bool> requestNotificationPermission() async {
    try {
      final status = await Permission.notification.request();
      return status == PermissionStatus.granted;
    } catch (e) {
      throw PermissionException.notification();
    }
  }

  static Future<bool> hasNotificationPermission() async {
    try {
      final status = await Permission.notification.status;
      return status == PermissionStatus.granted;
    } catch (e) {
      return false;
    }
  }

  // Phone permissions
  static Future<bool> requestPhonePermission() async {
    try {
      final status = await Permission.phone.request();
      return status == PermissionStatus.granted;
    } catch (e) {
      throw PermissionException.phone();
    }
  }

  static Future<bool> hasPhonePermission() async {
    try {
      final status = await Permission.phone.status;
      return status == PermissionStatus.granted;
    } catch (e) {
      return false;
    }
  }

  // SMS permissions
  static Future<bool> requestSmsPermission() async {
    try {
      final status = await Permission.sms.request();
      return status == PermissionStatus.granted;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> hasSmsPermission() async {
    try {
      final status = await Permission.sms.status;
      return status == PermissionStatus.granted;
    } catch (e) {
      return false;
    }
  }

  // Calendar permissions
  static Future<bool> requestCalendarPermission() async {
    try {
      final status = await Permission.calendarReadWrite.request();
      return status == PermissionStatus.granted;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> hasCalendarPermission() async {
    try {
      final status = await Permission.calendarReadWrite.status;
      return status == PermissionStatus.granted;
    } catch (e) {
      return false;
    }
  }

  // Bluetooth permissions
  static Future<bool> requestBluetoothPermission() async {
    try {
      final status = await Permission.bluetooth.request();
      return status == PermissionStatus.granted;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> hasBluetoothPermission() async {
    try {
      final status = await Permission.bluetooth.status;
      return status == PermissionStatus.granted;
    } catch (e) {
      return false;
    }
  }

  // Multiple permissions at once
  static Future<Map<Permission, PermissionStatus>> requestMultiplePermissions(
    List<Permission> permissions,
  ) async {
    try {
      return await permissions.request();
    } catch (e) {
      return {};
    }
  }

  static Future<Map<Permission, PermissionStatus>> checkMultiplePermissions(
    List<Permission> permissions,
  ) async {
    try {
      final Map<Permission, PermissionStatus> statuses = {};
      for (final permission in permissions) {
        statuses[permission] = await permission.status;
      }
      return statuses;
    } catch (e) {
      return {};
    }
  }

  // Chat app specific permission groups
  static Future<bool> requestChatPermissions() async {
    final permissions = [
      Permission.camera,
      Permission.microphone,
      Permission.photos,
      Permission.notification,
    ];

    if (Platform.isAndroid && await _isAndroid13OrHigher()) {
      permissions.add(Permission.videos);
    } else if (Platform.isAndroid) {
      permissions.add(Permission.storage);
    }

    final results = await requestMultiplePermissions(permissions);

    // Check if essential permissions are granted
    final cameraGranted =
        results[Permission.camera] == PermissionStatus.granted;
    final microphoneGranted =
        results[Permission.microphone] == PermissionStatus.granted;
    final notificationGranted =
        results[Permission.notification] == PermissionStatus.granted;

    return cameraGranted && microphoneGranted && notificationGranted;
  }

  static Future<bool> hasChatPermissions() async {
    final hasCam = await hasCameraPermission();
    final hasMic = await hasMicrophonePermission();
    final hasNotif = await hasNotificationPermission();
    final hasStorage = await hasStoragePermission();

    return hasCam && hasMic && hasNotif && hasStorage;
  }

  static Future<bool> requestCallPermissions() async {
    final permissions = [
      Permission.camera,
      Permission.microphone,
      Permission.notification,
    ];

    if (Platform.isAndroid) {
      permissions.add(Permission.phone);
    }

    final results = await requestMultiplePermissions(permissions);

    // All call permissions should be granted
    return results.values.every((status) => status == PermissionStatus.granted);
  }

  static Future<bool> hasCallPermissions() async {
    final hasCam = await hasCameraPermission();
    final hasMic = await hasMicrophonePermission();
    final hasNotif = await hasNotificationPermission();

    if (Platform.isAndroid) {
      final hasPhone = await hasPhonePermission();
      return hasCam && hasMic && hasNotif && hasPhone;
    }

    return hasCam && hasMic && hasNotif;
  }

  static Future<bool> requestMediaPermissions() async {
    final permissions = [Permission.camera, Permission.photos];

    if (Platform.isAndroid && await _isAndroid13OrHigher()) {
      permissions.add(Permission.videos);
    } else if (Platform.isAndroid) {
      permissions.add(Permission.storage);
    }

    final results = await requestMultiplePermissions(permissions);
    return results.values.any((status) => status == PermissionStatus.granted);
  }

  static Future<bool> hasMediaPermissions() async {
    final hasCam = await hasCameraPermission();
    final hasPhotos = await hasPhotosPermission();

    return hasCam || hasPhotos;
  }

  // Permission status helpers
  static bool isGranted(PermissionStatus status) {
    return status == PermissionStatus.granted;
  }

  static bool isDenied(PermissionStatus status) {
    return status == PermissionStatus.denied;
  }

  static bool isPermanentlyDenied(PermissionStatus status) {
    return status == PermissionStatus.permanentlyDenied;
  }

  static bool isRestricted(PermissionStatus status) {
    return status == PermissionStatus.restricted;
  }

  static bool isLimited(PermissionStatus status) {
    return status == PermissionStatus.limited;
  }

  // Open app settings
  static Future<bool> openAppSettings() async {
    try {
      return await openAppSettings();
    } catch (e) {
      return false;
    }
  }

  // Get user-friendly permission names
  static String getPermissionName(Permission permission) {
    switch (permission) {
      case Permission.camera:
        return StringConstants.camera;
      case Permission.microphone:
        return 'Microphone';
      case Permission.storage:
      case Permission.photos:
        return 'Storage';
      case Permission.location:
      case Permission.locationWhenInUse:
      case Permission.locationAlways:
        return StringConstants.location;
      case Permission.contacts:
        return StringConstants.contacts;
      case Permission.notification:
        return 'Notifications';
      case Permission.phone:
        return 'Phone';
      case Permission.sms:
        return 'SMS';
      case Permission.calendarReadWrite:
        return 'Calendar';
      case Permission.bluetooth:
        return 'Bluetooth';
      default:
        return permission.toString().split('.').last;
    }
  }

  // Get user-friendly permission descriptions
  static String getPermissionDescription(Permission permission) {
    switch (permission) {
      case Permission.camera:
        return 'Required to take photos and videos for sharing';
      case Permission.microphone:
        return 'Required for voice messages and calls';
      case Permission.storage:
      case Permission.photos:
        return 'Required to access and share photos and videos';
      case Permission.location:
      case Permission.locationWhenInUse:
      case Permission.locationAlways:
        return 'Required to share your location with others';
      case Permission.contacts:
        return 'Required to find friends and add contacts';
      case Permission.notification:
        return 'Required to receive message and call notifications';
      case Permission.phone:
        return 'Required to make and receive calls';
      case Permission.sms:
        return 'Required to verify your phone number';
      case Permission.calendarReadWrite:
        return 'Required to create events and reminders';
      case Permission.bluetooth:
        return 'Required to connect with nearby devices';
      default:
        return 'Required for app functionality';
    }
  }

  // Get permission status message
  static String getPermissionStatusMessage(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return 'Permission granted';
      case PermissionStatus.denied:
        return 'Permission denied';
      case PermissionStatus.restricted:
        return 'Permission restricted';
      case PermissionStatus.limited:
        return 'Permission limited';
      case PermissionStatus.permanentlyDenied:
        return 'Permission permanently denied. Please enable in settings.';
      case PermissionStatus.provisional:
        return 'Permission granted provisionally';
      default:
        return 'Unknown permission status';
    }
  }

  // Check if we should show permission rationale
  static Future<bool> shouldShowPermissionRationale(
    Permission permission,
  ) async {
    try {
      if (Platform.isAndroid) {
        final status = await permission.status;
        return status == PermissionStatus.denied;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Handle permission result
  static Future<void> handlePermissionResult(
    Permission permission,
    PermissionStatus status, {
    VoidCallback? onGranted,
    VoidCallback? onDenied,
    VoidCallback? onPermanentlyDenied,
    VoidCallback? onRestricted,
  }) async {
    switch (status) {
      case PermissionStatus.granted:
        onGranted?.call();
        break;
      case PermissionStatus.denied:
        onDenied?.call();
        break;
      case PermissionStatus.permanentlyDenied:
        onPermanentlyDenied?.call();
        break;
      case PermissionStatus.restricted:
        onRestricted?.call();
        break;
      default:
        onDenied?.call();
    }
  }

  // Get all permissions status for debugging
  static Future<Map<String, PermissionStatus>> getAllPermissionsStatus() async {
    final permissions = [
      Permission.camera,
      Permission.microphone,
      Permission.photos,
      Permission.location,
      Permission.locationWhenInUse,
      Permission.contacts,
      Permission.notification,
      Permission.phone,
      Permission.sms,
    ];

    if (Platform.isAndroid) {
      permissions.add(Permission.storage);
      if (await _isAndroid13OrHigher()) {
        permissions.add(Permission.videos);
      }
    }

    final Map<String, PermissionStatus> statuses = {};
    for (final permission in permissions) {
      try {
        statuses[getPermissionName(permission)] = await permission.status;
      } catch (e) {
        statuses[getPermissionName(permission)] = PermissionStatus.denied;
      }
    }

    return statuses;
  }

  // Helper to check Android version
  static Future<bool> _isAndroid13OrHigher() async {
    if (!Platform.isAndroid) return false;

    // This would require a platform-specific implementation
    // For now, return false as a safe default
    return false;
  }

  // Request permissions with user-friendly handling
  static Future<PermissionRequestResult> requestPermissionWithHandling(
    Permission permission,
  ) async {
    try {
      // Check current status
      final currentStatus = await permission.status;

      if (currentStatus == PermissionStatus.granted) {
        return PermissionRequestResult(
          permission: permission,
          status: currentStatus,
          isGranted: true,
          message: 'Permission already granted',
        );
      }

      if (currentStatus == PermissionStatus.permanentlyDenied) {
        return PermissionRequestResult(
          permission: permission,
          status: currentStatus,
          isGranted: false,
          message: getPermissionStatusMessage(currentStatus),
          shouldOpenSettings: true,
        );
      }

      // Request permission
      final newStatus = await permission.request();

      return PermissionRequestResult(
        permission: permission,
        status: newStatus,
        isGranted: newStatus == PermissionStatus.granted,
        message: getPermissionStatusMessage(newStatus),
        shouldOpenSettings: newStatus == PermissionStatus.permanentlyDenied,
      );
    } catch (e) {
      return PermissionRequestResult(
        permission: permission,
        status: PermissionStatus.denied,
        isGranted: false,
        message: 'Failed to request permission: $e',
      );
    }
  }
}

// Permission request result
class PermissionRequestResult {
  final Permission permission;
  final PermissionStatus status;
  final bool isGranted;
  final String message;
  final bool shouldOpenSettings;

  PermissionRequestResult({
    required this.permission,
    required this.status,
    required this.isGranted,
    required this.message,
    this.shouldOpenSettings = false,
  });

  String get permissionName => PermissionUtils.getPermissionName(permission);
  String get permissionDescription =>
      PermissionUtils.getPermissionDescription(permission);
}

// Typedef for callback
typedef VoidCallback = void Function();
