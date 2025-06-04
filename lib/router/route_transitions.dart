import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Custom page transitions for the BRO Chat application
///
/// This file contains various page transition animations that can be applied
/// to different routes based on the user experience requirements.
class RouteTransitions {
  // Prevent instantiation
  RouteTransitions._();

  // ============================================================================
  // TRANSITION DURATIONS
  // ============================================================================

  /// Default transition duration
  static const Duration defaultDuration = Duration(milliseconds: 300);

  /// Fast transition duration for quick interactions
  static const Duration fastDuration = Duration(milliseconds: 200);

  /// Slow transition duration for important screens
  static const Duration slowDuration = Duration(milliseconds: 500);

  /// Very fast transition for bottom sheets and dialogs
  static const Duration veryFastDuration = Duration(milliseconds: 150);

  // ============================================================================
  // TRANSITION CURVES
  // ============================================================================

  /// Standard material design curve
  static const Curve standardCurve = Curves.easeInOut;

  /// Smooth curve for fluid animations
  static const Curve smoothCurve = Curves.easeOutCubic;

  /// Bouncy curve for playful interactions
  static const Curve bouncyCurve = Curves.elasticOut;

  /// Sharp curve for quick actions
  static const Curve sharpCurve = Curves.easeInOutCubic;

  // ============================================================================
  // SLIDE TRANSITIONS
  // ============================================================================

  /// Slide transition from right to left (forward navigation)
  static CustomTransitionPage<T> slideFromRight<T extends Object?>(
    Widget child,
    GoRouterState state, {
    Duration duration = defaultDuration,
    Curve curve = standardCurve,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        final tween = Tween(begin: begin, end: end);
        final offsetAnimation = animation.drive(
          tween.chain(CurveTween(curve: curve)),
        );

        return SlideTransition(position: offsetAnimation, child: child);
      },
    );
  }

  /// Slide transition from left to right (back navigation)
  static CustomTransitionPage<T> slideFromLeft<T extends Object?>(
    Widget child,
    GoRouterState state, {
    Duration duration = defaultDuration,
    Curve curve = standardCurve,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(-1.0, 0.0);
        const end = Offset.zero;
        final tween = Tween(begin: begin, end: end);
        final offsetAnimation = animation.drive(
          tween.chain(CurveTween(curve: curve)),
        );

        return SlideTransition(position: offsetAnimation, child: child);
      },
    );
  }

  /// Slide transition from bottom to top (modal-style)
  static CustomTransitionPage<T> slideFromBottom<T extends Object?>(
    Widget child,
    GoRouterState state, {
    Duration duration = defaultDuration,
    Curve curve = smoothCurve,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        final tween = Tween(begin: begin, end: end);
        final offsetAnimation = animation.drive(
          tween.chain(CurveTween(curve: curve)),
        );

        return SlideTransition(position: offsetAnimation, child: child);
      },
    );
  }

  /// Slide transition from top to bottom
  static CustomTransitionPage<T> slideFromTop<T extends Object?>(
    Widget child,
    GoRouterState state, {
    Duration duration = defaultDuration,
    Curve curve = standardCurve,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, -1.0);
        const end = Offset.zero;
        final tween = Tween(begin: begin, end: end);
        final offsetAnimation = animation.drive(
          tween.chain(CurveTween(curve: curve)),
        );

        return SlideTransition(position: offsetAnimation, child: child);
      },
    );
  }

  // ============================================================================
  // FADE TRANSITIONS
  // ============================================================================

  /// Simple fade transition
  static CustomTransitionPage<T> fadeIn<T extends Object?>(
    Widget child,
    GoRouterState state, {
    Duration duration = defaultDuration,
    Curve curve = standardCurve,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final fadeAnimation = animation.drive(CurveTween(curve: curve));

        return FadeTransition(opacity: fadeAnimation, child: child);
      },
    );
  }

  /// Fade transition with scale effect
  static CustomTransitionPage<T> fadeInWithScale<T extends Object?>(
    Widget child,
    GoRouterState state, {
    Duration duration = defaultDuration,
    Curve curve = smoothCurve,
    double initialScale = 0.8,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final fadeAnimation = animation.drive(CurveTween(curve: curve));

        final scaleAnimation = animation.drive(
          Tween(begin: initialScale, end: 1.0).chain(CurveTween(curve: curve)),
        );

        return FadeTransition(
          opacity: fadeAnimation,
          child: ScaleTransition(scale: scaleAnimation, child: child),
        );
      },
    );
  }

  // ============================================================================
  // SCALE TRANSITIONS
  // ============================================================================

  /// Scale transition from center
  static CustomTransitionPage<T> scaleFromCenter<T extends Object?>(
    Widget child,
    GoRouterState state, {
    Duration duration = defaultDuration,
    Curve curve = smoothCurve,
    double initialScale = 0.0,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final scaleAnimation = animation.drive(
          Tween(begin: initialScale, end: 1.0).chain(CurveTween(curve: curve)),
        );

        return ScaleTransition(scale: scaleAnimation, child: child);
      },
    );
  }

  /// Scale transition with bounce effect
  static CustomTransitionPage<T> scaleWithBounce<T extends Object?>(
    Widget child,
    GoRouterState state, {
    Duration duration = slowDuration,
    double initialScale = 0.3,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final scaleAnimation = animation.drive(
          Tween(
            begin: initialScale,
            end: 1.0,
          ).chain(CurveTween(curve: bouncyCurve)),
        );

        return ScaleTransition(scale: scaleAnimation, child: child);
      },
    );
  }

  // ============================================================================
  // ROTATION TRANSITIONS
  // ============================================================================

  /// Rotation transition
  static CustomTransitionPage<T> rotateIn<T extends Object?>(
    Widget child,
    GoRouterState state, {
    Duration duration = defaultDuration,
    Curve curve = standardCurve,
    double initialRotation = 0.25, // Quarter turn
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final rotationAnimation = animation.drive(
          Tween(
            begin: initialRotation,
            end: 0.0,
          ).chain(CurveTween(curve: curve)),
        );

        return RotationTransition(turns: rotationAnimation, child: child);
      },
    );
  }

  // ============================================================================
  // COMBINED TRANSITIONS
  // ============================================================================

  /// Slide and fade transition (iOS-style)
  static CustomTransitionPage<T> slideAndFade<T extends Object?>(
    Widget child,
    GoRouterState state, {
    Duration duration = defaultDuration,
    Curve curve = standardCurve,
    Offset slideBegin = const Offset(1.0, 0.0),
    double fadeBegin = 0.0,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slideAnimation = animation.drive(
          Tween(
            begin: slideBegin,
            end: Offset.zero,
          ).chain(CurveTween(curve: curve)),
        );

        final fadeAnimation = animation.drive(
          Tween(begin: fadeBegin, end: 1.0).chain(CurveTween(curve: curve)),
        );

        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(opacity: fadeAnimation, child: child),
        );
      },
    );
  }

  /// Scale and rotate transition
  static CustomTransitionPage<T> scaleAndRotate<T extends Object?>(
    Widget child,
    GoRouterState state, {
    Duration duration = defaultDuration,
    Curve curve = smoothCurve,
    double initialScale = 0.0,
    double initialRotation = 0.5,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final scaleAnimation = animation.drive(
          Tween(begin: initialScale, end: 1.0).chain(CurveTween(curve: curve)),
        );

        final rotationAnimation = animation.drive(
          Tween(
            begin: initialRotation,
            end: 0.0,
          ).chain(CurveTween(curve: curve)),
        );

        return ScaleTransition(
          scale: scaleAnimation,
          child: RotationTransition(turns: rotationAnimation, child: child),
        );
      },
    );
  }

  // ============================================================================
  // NO TRANSITION
  // ============================================================================

  /// No transition (instant)
  static CustomTransitionPage<T> noTransition<T extends Object?>(
    Widget child,
    GoRouterState state,
  ) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return child;
      },
    );
  }

  // ============================================================================
  // PLATFORM-SPECIFIC TRANSITIONS
  // ============================================================================

  /// Platform-appropriate transition (Material for Android, Cupertino for iOS)
  static Page<T> platformTransition<T extends Object?>(
    Widget child,
    GoRouterState state, {
    Duration? duration,
  }) {
    // Use the default platform transition
    return MaterialPage<T>(key: state.pageKey, child: child);
  }

  /// Material Design transition
  static MaterialPage<T> materialTransition<T extends Object?>(
    Widget child,
    GoRouterState state,
  ) {
    return MaterialPage<T>(key: state.pageKey, child: child);
  }

  /// Cupertino (iOS) transition
  static Page<T> cupertinoTransition<T extends Object?>(
    Widget child,
    GoRouterState state,
  ) {
    // Note: You might need to import cupertino package
    return MaterialPage<T>(
      // Fallback to Material if Cupertino not available
      key: state.pageKey,
      child: child,
    );
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Get transition based on route type
  static Page<T> getTransitionForRoute<T extends Object?>(
    String routeName,
    Widget child,
    GoRouterState state,
  ) {
    // Authentication screens - slide from right
    if (_isAuthRoute(routeName)) {
      return slideFromRight<T>(child, state);
    }

    // Modal screens - slide from bottom
    if (_isModalRoute(routeName)) {
      return slideFromBottom<T>(child, state, duration: fastDuration);
    }

    // Settings screens - slide from right
    if (_isSettingsRoute(routeName)) {
      return slideFromRight<T>(child, state);
    }

    // Call screens - fade with scale
    if (_isCallRoute(routeName)) {
      return fadeInWithScale<T>(child, state, duration: fastDuration);
    }

    // Media viewer screens - fade
    if (_isMediaRoute(routeName)) {
      return fadeIn<T>(child, state, duration: fastDuration);
    }

    // Default transition
    return slideFromRight<T>(child, state);
  }

  /// Check if route is authentication related
  static bool _isAuthRoute(String routeName) {
    return routeName.contains('login') ||
        routeName.contains('register') ||
        routeName.contains('otp') ||
        routeName.contains('password');
  }

  /// Check if route is modal style
  static bool _isModalRoute(String routeName) {
    return routeName.contains('create') ||
        routeName.contains('select') ||
        routeName.contains('picker') ||
        routeName.contains('scanner');
  }

  /// Check if route is settings related
  static bool _isSettingsRoute(String routeName) {
    return routeName.contains('settings') || routeName.contains('profile');
  }

  /// Check if route is call related
  static bool _isCallRoute(String routeName) {
    return routeName.contains('call') || routeName.contains('incoming');
  }

  /// Check if route is media viewer related
  static bool _isMediaRoute(String routeName) {
    return routeName.contains('viewer') ||
        routeName.contains('player') ||
        routeName.contains('gallery');
  }
}
