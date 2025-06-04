import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Brand Colors
  static const Color primary = Color(0xFF0084FF);
  static const Color primaryLight = Color(0xFF4DA6FF);
  static const Color primaryDark = Color(0xFF0066CC);
  static const Color primaryVariant = Color(0xFF005BC1);

  // Secondary Colors
  static const Color secondary = Color(0xFF00D4AA);
  static const Color secondaryLight = Color(0xFF4DE0C1);
  static const Color secondaryDark = Color(0xFF00B894);
  static const Color secondaryVariant = Color(0xFF00A085);

  // Accent Colors
  static const Color accent = Color(0xFFFF6B6B);
  static const Color accentLight = Color(0xFFFF9F9F);
  static const Color accentDark = Color(0xFFE55454);

  // Background Colors
  static const Color background = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color backgroundSecondary = Color(0xFFF8F9FA);
  static const Color backgroundSecondaryDark = Color(0xFF1E1E1E);
  static const Color backgroundTertiary = Color(0xFFF1F3F4);
  static const Color backgroundTertiaryDark = Color(0xFF2D2D2D);

  // Surface Colors
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color surfaceVariant = Color(0xFFF5F5F5);
  static const Color surfaceVariantDark = Color(0xFF2D2D2D);

  // Text Colors
  static const Color textPrimary = Color(0xFF1C1E21);
  static const Color textPrimaryDark = Color(0xFFE3E3E3);
  static const Color textSecondary = Color(0xFF65676B);
  static const Color textSecondaryDark = Color(0xFFB0B3B8);
  static const Color textTertiary = Color(0xFF8A8D91);
  static const Color textTertiaryDark = Color(0xFF8A8D91);
  static const Color textHint = Color(0xFFBCC0C4);
  static const Color textHintDark = Color(0xFF6B6B6B);

  // Message Bubble Colors
  static const Color messageBubbleOwn = Color(0xFF0084FF);
  static const Color messageBubbleOwnDark = Color(0xFF0084FF);
  static const Color messageBubbleOther = Color(0xFFF0F0F0);
  static const Color messageBubbleOtherDark = Color(0xFF3A3B3C);
  static const Color messageBubbleSystem = Color(0xFFE4E6EA);
  static const Color messageBubbleSystemDark = Color(0xFF4E4F50);

  // Status Colors
  static const Color success = Color(0xFF00C851);
  static const Color successLight = Color(0xFF5DFC8D);
  static const Color successDark = Color(0xFF00A043);

  static const Color warning = Color(0xFFFFAA00);
  static const Color warningLight = Color(0xFFFFD54F);
  static const Color warningDark = Color(0xFFFF8F00);

  static const Color error = Color(0xFFFF4444);
  static const Color errorLight = Color(0xFFFF7979);
  static const Color errorDark = Color(0xFFD32F2F);

  static const Color info = Color(0xFF33B5E5);
  static const Color infoLight = Color(0xFF74D3F0);
  static const Color infoDark = Color(0xFF0099CC);

  // Border Colors
  static const Color border = Color(0xFFDADDE1);
  static const Color borderDark = Color(0xFF3E4042);
  static const Color borderLight = Color(0xFFF0F2F5);
  static const Color borderLightDark = Color(0xFF2F3031);

  // Divider Colors
  static const Color divider = Color(0xFFE4E6EA);
  static const Color dividerDark = Color(0xFF3E4042);

  // Icon Colors
  static const Color iconPrimary = Color(0xFF1C1E21);
  static const Color iconPrimaryDark = Color(0xFFE4E6EA);
  static const Color iconSecondary = Color(0xFF65676B);
  static const Color iconSecondaryDark = Color(0xFFB0B3B8);
  static const Color iconTertiary = Color(0xFF8A8D91);
  static const Color iconTertiaryDark = Color(0xFF8A8D91);

  // Media Widget Specific Colors
  static const Color mediaOverlay = Color(0x80000000);
  static const Color mediaControlsBackground = Color(0xCC000000);
  static const Color mediaProgressBackground = Color(0x4DFFFFFF);
  static const Color mediaProgressForeground = Color(0xFFFFFFFF);

  // Audio Waveform Colors
  static const Color waveformActive = Color(0xFF0084FF);
  static const Color waveformInactive = Color(0xFFE4E6EA);
  static const Color waveformActiveDark = Color(0xFF0084FF);
  static const Color waveformInactiveDark = Color(0xFF3E4042);

  // Video Controls Colors
  static const Color videoControlsBackground = Color(0xDD000000);
  static const Color videoControlsText = Color(0xFFFFFFFF);
  static const Color videoProgressPlayed = Color(0xFF0084FF);
  static const Color videoProgressBuffered = Color(0x4D0084FF);
  static const Color videoProgressBackground = Color(0x4DFFFFFF);

  // Contact Widget Colors
  static const Color contactAvatarBackground = Color(0xFFF0F2F5);
  static const Color contactAvatarBackgroundDark = Color(0xFF3A3B3C);
  static const Color contactActionBackground = Color(0xFFF0F8FF);
  static const Color contactActionBackgroundDark = Color(0xFF263951);

  // Document Widget Colors
  static const Color documentIconPdf = Color(0xFFE53E3E);
  static const Color documentIconWord = Color(0xFF2B5CE6);
  static const Color documentIconExcel = Color(0xFF38A169);
  static const Color documentIconPowerPoint = Color(0xFFED8936);
  static const Color documentIconText = Color(0xFF805AD5);
  static const Color documentIconArchive = Color(0xFF8B4513);
  static const Color documentIconDefault = Color(0xFF718096);

  // Location Widget Colors
  static const Color locationAccuracyGood = Color(0xFF00C851);
  static const Color locationAccuracyFair = Color(0xFFFFAA00);
  static const Color locationAccuracyPoor = Color(0xFFFF4444);
  static const Color locationPinColor = Color(0xFFE53E3E);

  // Interactive States
  static const Color hoverLight = Color(0xFFF2F3F5);
  static const Color hoverDark = Color(0xFF3A3B3C);
  static const Color pressedLight = Color(0xFFE4E6EA);
  static const Color pressedDark = Color(0xFF4E4F50);
  static const Color focusedLight = Color(0xFFE3F2FD);
  static const Color focusedDark = Color(0xFF1A237E);
  static const Color selectedLight = Color(0xFFE8F4FD);
  static const Color selectedDark = Color(0xFF0D47A1);

  // Gradient Colors
  static const List<Color> primaryGradient = [
    Color(0xFF0084FF),
    Color(0xFF00D4AA),
  ];

  static const List<Color> secondaryGradient = [
    Color(0xFF00D4AA),
    Color(0xFF0084FF),
  ];

  static const List<Color> errorGradient = [
    Color(0xFFFF4444),
    Color(0xFFFF6B6B),
  ];

  static const List<Color> successGradient = [
    Color(0xFF00C851),
    Color(0xFF00D4AA),
  ];

  static const List<Color> warningGradient = [
    Color(0xFFFFAA00),
    Color(0xFFFF6B6B),
  ];

  // Shadow Colors
  static const Color shadowLight = Color(0x1A000000);
  static const Color shadowMedium = Color(0x33000000);
  static const Color shadowDark = Color(0x4D000000);

  // Shimmer Colors
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);
  static const Color shimmerBaseDark = Color(0xFF2D2D2D);
  static const Color shimmerHighlightDark = Color(0xFF3A3A3A);

  // Chat-specific Colors
  static const Color onlineIndicator = Color(0xFF00C851);
  static const Color awayIndicator = Color(0xFFFFAA00);
  static const Color busyIndicator = Color(0xFFFF4444);
  static const Color offlineIndicator = Color(0xFF8A8D91);

  static const Color unreadBadge = Color(0xFFFF4444);
  static const Color mutedChat = Color(0xFF8A8D91);
  static const Color pinnedChat = Color(0xFF0084FF);

  static const Color typingIndicator = Color(0xFF00D4AA);
  static const Color recordingIndicator = Color(0xFFFF4444);

  // Message Status Colors
  static const Color messageSent = Color(0xFF8A8D91);
  static const Color messageDelivered = Color(0xFF0084FF);
  static const Color messageRead = Color(0xFF00C851);
  static const Color messageFailed = Color(0xFFFF4444);

  // Utility Methods
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }

  static Color blend(Color color1, Color color2, double ratio) {
    return Color.lerp(color1, color2, ratio) ?? color1;
  }

  static MaterialColor createMaterialColor(Color color) {
    List strengths = <double>[.05];
    Map<int, Color> swatch = <int, Color>{};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    for (double strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.value, swatch);
  }

  // Color scheme getters
  static ColorScheme get lightColorScheme => const ColorScheme.light(
    primary: primary,
    primaryContainer: primaryLight,
    secondary: secondary,
    secondaryContainer: secondaryLight,
    surface: surface,
    background: background,
    error: error,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: textPrimary,
    onBackground: textPrimary,
    onError: Colors.white,
  );

  static ColorScheme get darkColorScheme => const ColorScheme.dark(
    primary: primary,
    primaryContainer: primaryDark,
    secondary: secondary,
    secondaryContainer: secondaryDark,
    surface: surfaceDark,
    background: backgroundDark,
    error: error,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: textPrimaryDark,
    onBackground: textPrimaryDark,
    onError: Colors.white,
  );
}
