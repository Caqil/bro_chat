import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'main.dart';
import 'providers/auth/auth_provider.dart';
import 'providers/auth/user_provider.dart';
import 'providers/settings/theme_provider.dart';
import 'providers/settings/language_provider.dart';
import 'providers/settings/settings_provider.dart';
import 'providers/chat/chat_list_provider.dart';
import 'providers/call/call_provider.dart';
import 'providers/group/group_provider.dart';
import 'services/notification/notification_handler.dart';
import 'services/notification/fcm_service.dart';
import 'services/notification/local_notification.dart';
import 'services/storage/local_storage.dart';
import 'core/config/dio_config.dart';
import 'theme/app_theme.dart';
import 'core/constants/app_constants.dart';

/// Main application widget for BRO Chat
class BROChatApp extends ConsumerStatefulWidget {
  const BROChatApp({super.key});

  @override
  ConsumerState<BROChatApp> createState() => _BROChatAppState();
}

class _BROChatAppState extends ConsumerState<BROChatApp>
    with WidgetsBindingObserver {
  // Service instances
  NotificationHandler? _notificationHandler;
  FCMService? _fcmService;
  LocalNotificationService? _localNotificationService;

  // Subscriptions
  StreamSubscription<RemoteMessage>? _fcmSubscription;
  StreamSubscription<NotificationData>? _notificationSubscription;

  // App lifecycle
  AppLifecycleState? _lastLifecycleState;
  bool _isAppInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeServices();
    super.dispose();
  }

  /// Initialize the application
  Future<void> _initializeApp() async {
    try {
      if (kDebugMode) {
        print('🚀 Initializing BRO Chat App...');
      }

      // Initialize services in sequence
      await _initializeNotificationServices();
      await _setupFCMHandling();
      await _setupAppLifecycleHandling();

      // Mark app as initialized
      setState(() {
        _isAppInitialized = true;
      });

      if (kDebugMode) {
        print('✅ BRO Chat App initialized successfully');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ App initialization failed: $e');
        print('Stack trace: $stackTrace');
      }
      // Continue with limited functionality
      setState(() {
        _isAppInitialized = true;
      });
    }
  }

  /// Initialize notification services
  Future<void> _initializeNotificationServices() async {
    try {
      // Initialize local notifications
      _localNotificationService = LocalNotificationService();
      await _localNotificationService!.initialize();

      // Initialize FCM service
      _fcmService = FCMService();
      await _fcmService!.initialize(
        localNotificationService: _localNotificationService!,
        dio: DioConfig.instance,
      );

      // Initialize notification handler
      _notificationHandler = NotificationHandler();
      await _notificationHandler!.initialize();

      // Listen to notification stream
      _notificationSubscription = _notificationHandler!.notificationStream
          .listen(_handleNotificationData, onError: _handleNotificationError);

      if (kDebugMode) {
        print('✅ Notification services initialized');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Notification services initialization failed: $e');
        print('Stack trace: $stackTrace');
      }
    }
  }

  /// Setup FCM message handling
  Future<void> _setupFCMHandling() async {
    try {
      // Listen to FCM messages
      if (_fcmService != null) {
        _fcmSubscription = _fcmService!.messageStream.listen(
          _handleFCMMessage,
          onError: _handleFCMError,
        );
      }

      // Handle initial message (when app is opened from notification)
      final initialMessage = await FirebaseMessaging.instance
          .getInitialMessage();
      if (initialMessage != null) {
        _handleFCMMessage(initialMessage);
      }

      // Handle messages when app is in foreground
      FirebaseMessaging.onMessage.listen(_handleFCMMessage);

      // Handle messages when app is opened from background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleFCMMessage);

      if (kDebugMode) {
        print('✅ FCM handling setup');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ FCM handling setup failed: $e');
        print('Stack trace: $stackTrace');
      }
    }
  }

  /// Setup app lifecycle handling
  Future<void> _setupAppLifecycleHandling() async {
    try {
      // Update notification handler about app state
      _notificationHandler?.setAppForegroundState(true);

      if (kDebugMode) {
        print('✅ App lifecycle handling setup');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ App lifecycle setup failed: $e');
        print('Stack trace: $stackTrace');
      }
    }
  }

  /// Handle FCM messages
  void _handleFCMMessage(RemoteMessage message) {
    try {
      if (kDebugMode) {
        print('📱 FCM message received: ${message.messageId}');
      }

      // Update UI state if needed
      _updateUIFromNotification(message);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Error handling FCM message: $e');
        print('Stack trace: $stackTrace');
      }
    }
  }

  /// Handle FCM errors
  void _handleFCMError(dynamic error) {
    if (kDebugMode) {
      print('❌ FCM error: $error');
    }
  }

  /// Handle notification data
  void _handleNotificationData(NotificationData data) {
    try {
      if (kDebugMode) {
        print('🔔 Notification data received: ${data.type}');
      }

      // Handle specific notification types
      switch (data.type) {
        case NotificationType.call:
          _handleCallNotification(data);
          break;
        case NotificationType.message:
          _handleMessageNotification(data);
          break;
        case NotificationType.groupUpdate:
          _handleGroupUpdateNotification(data);
          break;
        default:
          break;
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Error handling notification data: $e');
        print('Stack trace: $stackTrace');
      }
    }
  }

  /// Handle notification errors
  void _handleNotificationError(dynamic error) {
    if (kDebugMode) {
      print('❌ Notification error: $error');
    }
  }

  /// Update UI from notification
  void _updateUIFromNotification(RemoteMessage message) {
    final type = message.data['type'];

    switch (type) {
      case 'call':
        _handleCallNotificationFromFCM(message);
        break;
      case 'message':
        _handleMessageNotificationFromFCM(message);
        break;
      case 'group_update':
        _handleGroupUpdateNotificationFromFCM(message);
        break;
      default:
        break;
    }
  }

  /// Handle call notifications from FCM
  void _handleCallNotificationFromFCM(RemoteMessage message) {
    final callId = message.data['call_id'];
    if (callId != null) {
      // Navigate to incoming call screen
      // This would be implemented based on your routing system
      if (kDebugMode) {
        print('📞 Incoming call: $callId');
      }
    }
  }

  /// Handle call notifications from notification data
  void _handleCallNotification(NotificationData data) {
    final callId = data.data['call_id'];
    if (callId != null) {
      // Handle call notification
      if (kDebugMode) {
        print('📞 Call notification: $callId');
      }
    }
  }

  /// Handle message notifications from FCM
  void _handleMessageNotificationFromFCM(RemoteMessage message) {
    final chatId = message.data['chat_id'];
    if (chatId != null) {
      // Refresh chat list
      ref.read(chatListProvider.notifier).refreshChats();
    }
  }

  /// Handle message notifications from notification data
  void _handleMessageNotification(NotificationData data) {
    final chatId = data.data['chat_id'];
    if (chatId != null) {
      // Handle message notification
      if (kDebugMode) {
        print('💬 Message notification for chat: $chatId');
      }
    }
  }

  /// Handle group update notifications from FCM
  void _handleGroupUpdateNotificationFromFCM(RemoteMessage message) {
    final groupId = message.data['group_id'];
    if (groupId != null) {
      // Refresh group data
      ref.read(groupProvider(groupId).notifier).refreshGroup();
    }
  }

  /// Handle group update notifications from notification data
  void _handleGroupUpdateNotification(NotificationData data) {
    final groupId = data.data['group_id'];
    if (groupId != null) {
      // Handle group update notification
      if (kDebugMode) {
        print('👥 Group update notification: $groupId');
      }
    }
  }

  /// Dispose services
  void _disposeServices() {
    _fcmSubscription?.cancel();
    _notificationSubscription?.cancel();

    _notificationHandler?.dispose();
    _fcmService?.dispose();
    _localNotificationService?.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (_lastLifecycleState != state) {
      _lastLifecycleState = state;
      _handleAppLifecycleStateChange(state);
    }
  }

  /// Handle app lifecycle state changes
  void _handleAppLifecycleStateChange(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _handleAppResumed();
        break;
      case AppLifecycleState.paused:
        _handleAppPaused();
        break;
      case AppLifecycleState.inactive:
        _handleAppInactive();
        break;
      case AppLifecycleState.detached:
        _handleAppDetached();
        break;
      case AppLifecycleState.hidden:
        _handleAppHidden();
        break;
    }
  }

  void _handleAppResumed() {
    if (kDebugMode) {
      print('📱 App resumed');
    }

    // Update notification handler
    _notificationHandler?.setAppForegroundState(true);

    // Update user online status
    ref.read(userProvider.notifier).updateOnlineStatus(true);

    // Process any pending background messages
    _processPendingBackgroundMessages();
  }

  void _handleAppPaused() {
    if (kDebugMode) {
      print('📱 App paused');
    }

    // Update notification handler
    _notificationHandler?.setAppForegroundState(false);

    // Update user offline status with delay
    Future.delayed(const Duration(seconds: 30), () {
      if (_lastLifecycleState != AppLifecycleState.resumed) {
        ref.read(userProvider.notifier).updateOnlineStatus(false);
      }
    });
  }

  void _handleAppInactive() {
    if (kDebugMode) {
      print('📱 App inactive');
    }
  }

  void _handleAppDetached() {
    if (kDebugMode) {
      print('📱 App detached');
    }

    // Cleanup resources
    _disposeServices();
  }

  void _handleAppHidden() {
    if (kDebugMode) {
      print('📱 App hidden');
    }
  }

  /// Process pending background messages
  Future<void> _processPendingBackgroundMessages() async {
    try {
      final localStorage = LocalStorage();
      await localStorage.init();

      final backgroundMessages =
          localStorage.getStringList('background_messages') ?? [];

      if (backgroundMessages.isNotEmpty) {
        if (kDebugMode) {
          print(
            '📱 Processing ${backgroundMessages.length} background messages',
          );
        }

        // Process each background message
        for (final messageJson in backgroundMessages) {
          try {
            final messageData = jsonDecode(messageJson);
            // Handle the background message
            if (kDebugMode) {
              print('Processing message: ${messageData['message_id']}');
            }
          } catch (e) {
            if (kDebugMode) {
              print('❌ Error processing background message: $e');
            }
          }
        }

        // Clear processed messages
        await localStorage.setStringList('background_messages', []);
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Error processing background messages: $e');
        print('Stack trace: $stackTrace');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch theme and language providers
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(languageProvider);

    return _isAppInitialized
        ? _BuildApp(themeMode: themeMode, locale: locale)
        : _BuildLoadingScreen();
  }
}

/// Build the main app
class _BuildApp extends StatelessWidget {
  final ThemeMode themeMode;
  final Locale locale;

  const _BuildApp({required this.themeMode, required this.locale});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // App configuration
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,

      // Theme configuration
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,

      // Localization
      locale: locale,
      supportedLocales: AppConstants.supportedLocales,

      // Home screen - this would be your main app screen
      home: const _AppHome(),

      // Builder for global widgets
      builder: (context, child) {
        return _AppBuilder(child: child ?? const SizedBox.shrink());
      },
    );
  }
}

/// App builder with global providers
class _AppBuilder extends ConsumerWidget {
  final Widget child;

  const _AppBuilder({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(_getTextScaleFactor(context, ref)),
      ),
      child: Stack(
        children: [
          child,
          // Global notification listener
          _GlobalNotificationListener(),
        ],
      ),
    );
  }

  double _getTextScaleFactor(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final systemTextScale = MediaQuery.of(context).textScaler.scale(1.0);
    final appTextScale = settings['text_scale_factor'] ?? 1.0;

    // Combine system and app text scaling with limits
    return (systemTextScale * appTextScale).clamp(0.8, 2.0);
  }
}

/// Loading screen while app initializes
class _BuildLoadingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo
              Icon(Icons.chat_bubble_outline, size: 80, color: Colors.blue),
              SizedBox(height: 24),
              Text(
                AppConstants.appName,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Starting up...',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              SizedBox(height: 32),
              CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Main app home screen
class _AppHome extends ConsumerWidget {
  const _AppHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch auth state to determine which screen to show
    final authState = ref.watch(authProvider);

    return authState.when(
      initial: () => const _LoadingScreen(),
      loading: () => const _LoadingScreen(),
      unauthenticated: () => const _AuthScreen(),
      authenticated: (user, accessToken, refreshToken) => const _MainScreen(),
      error: (message) => _ErrorScreen(message: message),
    );
  }
}

/// Loading screen
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

/// Authentication screen
class _AuthScreen extends StatelessWidget {
  const _AuthScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat_bubble_outline, size: 80, color: Colors.blue),
            const SizedBox(height: 24),
            const Text(
              'Welcome to BRO Chat',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Please login to continue',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // Navigate to login screen
                // This would be implemented based on your routing system
              },
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Main screen (after authentication)
class _MainScreen extends StatelessWidget {
  const _MainScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(
        child: Text('Main App Screen', style: TextStyle(fontSize: 24)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add new chat or message
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Error screen
class _ErrorScreen extends StatelessWidget {
  final String message;

  const _ErrorScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Colors.red),
            const SizedBox(height: 24),
            const Text(
              'Something went wrong',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // Retry or restart app
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Global notification listener
class _GlobalNotificationListener extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to notification actions from the provider
    ref.listen(notificationActionProvider, (previous, next) {
      next.whenOrNull(
        data: (response) => _handleNotificationAction(context, ref, response),
      );
    });

    return const SizedBox.shrink();
  }

  void _handleNotificationAction(
    BuildContext context,
    WidgetRef ref,
    dynamic response,
  ) {
    // Handle notification actions globally
    try {
      final payload = response.payload;
      if (payload != null) {
        final data = jsonDecode(payload);
        _routeNotificationAction(context, ref, data, response.actionId);
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Error handling notification action: $e');
        print('Stack trace: $stackTrace');
      }
    }
  }

  void _routeNotificationAction(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> data,
    String? actionId,
  ) {
    final type = data['type'];

    switch (type) {
      case 'message':
        final chatId = data['chat_id'];
        if (chatId != null) {
          // Navigate to chat screen
          // This would be implemented based on your routing system
          if (kDebugMode) {
            print('📱 Navigate to chat: $chatId');
          }
        }
        break;
      case 'call':
        final callId = data['call_id'];
        if (callId != null) {
          if (actionId == 'answer') {
            // Navigate to call screen
            if (kDebugMode) {
              print('📞 Answer call: $callId');
            }
          } else if (actionId == 'decline') {
            // Handle call decline
            ref.read(callProvider.notifier).rejectCall();
          }
        }
        break;
      case 'group':
        final groupId = data['group_id'];
        if (groupId != null) {
          // Navigate to group screen
          if (kDebugMode) {
            print('👥 Navigate to group: $groupId');
          }
        }
        break;
      default:
        break;
    }
  }
}
