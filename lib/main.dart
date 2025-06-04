import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/config/firebase_options.dart';
import 'core/utils/logger.dart';
import 'services/notification/fcm_service.dart';
import 'services/notification/local_notification.dart';
import 'services/notification/notification_handler.dart';
import 'services/storage/local_storage.dart';
import 'services/storage/secure_storage.dart';

/// Global navigators key for navigation without context
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Background message handler for Firebase Cloud Messaging
/// Must be a top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if not already initialized
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  try {
    if (kDebugMode) {
      print('📱 Background message received: ${message.messageId}');
    }

    // Initialize minimal services needed for background processing
    final localStorage = LocalStorage();
    await localStorage.init();

    // Update badge count
    final currentCount = localStorage.getInt('unread_message_count') ?? 0;
    await localStorage.setInt('unread_message_count', currentCount + 1);

    // Store message for later processing when app opens
    final backgroundMessages =
        localStorage.getStringList('background_messages') ?? [];
    backgroundMessages.add(
      jsonEncode({
        'message_id': message.messageId,
        'title': message.notification?.title,
        'body': message.notification?.body,
        'data': message.data,
        'timestamp': DateTime.now().toIso8601String(),
      }),
    );

    // Keep only last 50 background messages
    if (backgroundMessages.length > 50) {
      backgroundMessages.removeRange(0, backgroundMessages.length - 50);
    }

    await localStorage.setStringList('background_messages', backgroundMessages);

    if (kDebugMode) {
      print('✅ Background message processed successfully');
    }
  } catch (e, stackTrace) {
    if (kDebugMode) {
      print('❌ Error processing background message: $e');
      print('Stack trace: $stackTrace');
    }
  }
}

Future<void> main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize error handling
  await _initializeErrorHandling();

  // Initialize Firebase
  await _initializeFirebase();

  // Initialize timezone data
  tz.initializeTimeZones();

  // Set system UI overlay style
  _setSystemUIOverlayStyle();

  // Initialize app configuration
  await AppConfig.initialize();

  if (kDebugMode) {
    print('🚀 BRO Chat starting...');
  }

  // Run the app with ProviderScope
  runApp(
    ProviderScope(
      observers: [if (kDebugMode) _RiverpodLogger()],
      child: const BROChatApp(),
    ),
  );
}

/// Initialize Firebase and FCM
Future<void> _initializeFirebase() async {
  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Request notification permissions
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // Configure for iOS
    if (Platform.isIOS) {
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    if (kDebugMode) {
      print('✅ Firebase initialized successfully');
    }
  } catch (e, stackTrace) {
    if (kDebugMode) {
      print('❌ Firebase initialization failed: $e');
      print('Stack trace: $stackTrace');
    }
    // Continue app initialization even if Firebase fails
  }
}

/// Initialize error handling
Future<void> _initializeErrorHandling() async {
  // Handle Flutter errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (kDebugMode) {
      print('❌ Flutter Error: ${details.exception}');
      print('Stack trace: ${details.stack}');
    }
  };

  // Handle platform errors
  PlatformDispatcher.instance.onError = (error, stack) {
    if (kDebugMode) {
      print('❌ Platform Error: $error');
      print('Stack trace: $stack');
    }
    return true;
  };

  if (kDebugMode) {
    print('✅ Error handling initialized');
  }
}

/// Set system UI overlay style
void _setSystemUIOverlayStyle() {
  if (Platform.isAndroid || Platform.isIOS) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }
}

/// Riverpod logger for debugging
class _RiverpodLogger extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    if (kDebugMode && AppConfig.enableRiverpodLogging) {
      print(
        'Provider updated: ${provider.name ?? provider.runtimeType} '
        'from $previousValue to $newValue',
      );
    }
  }

  @override
  void didAddProvider(
    ProviderBase<Object?> provider,
    Object? value,
    ProviderContainer container,
  ) {
    if (kDebugMode && AppConfig.enableRiverpodLogging) {
      print(
        'Provider added: ${provider.name ?? provider.runtimeType} '
        'with value $value',
      );
    }
  }

  @override
  void didDisposeProvider(
    ProviderBase<Object?> provider,
    ProviderContainer container,
  ) {
    if (kDebugMode && AppConfig.enableRiverpodLogging) {
      print('Provider disposed: ${provider.name ?? provider.runtimeType}');
    }
  }

  @override
  void providerDidFail(
    ProviderBase<Object?> provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    print('Provider failed: ${provider.name ?? provider.runtimeType} - $error');
    print('Stack trace: $stackTrace');
  }
}
