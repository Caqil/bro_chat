import 'package:flutter/material.dart';

class ColorConstants {
  // Brand Colors
  static const Color primaryColor = Color(0xFF0F172A); // slate-900
  static const Color primaryVariant = Color(0xFF1E293B); // slate-800
  static const Color secondaryColor = Color(0xFF3B82F6); // blue-500
  static const Color secondaryVariant = Color(0xFF2563EB); // blue-600
  static const Color accentColor = Color(0xFF10B981); // emerald-500

  // Background Colors - Light Theme
  static const Color backgroundLight = Color(0xFFFFFFFF); // white
  static const Color surfaceLight = Color(0xFFF8FAFC); // slate-50
  static const Color cardLight = Color(0xFFFFFFFF); // white
  static const Color dialogLight = Color(0xFFFFFFFF); // white

  // Background Colors - Dark Theme
  static const Color backgroundDark = Color(0xFF0F172A); // slate-900
  static const Color surfaceDark = Color(0xFF1E293B); // slate-800
  static const Color cardDark = Color(0xFF334155); // slate-700
  static const Color dialogDark = Color(0xFF475569); // slate-600

  // Text Colors - Light Theme
  static const Color textPrimaryLight = Color(0xFF0F172A); // slate-900
  static const Color textSecondaryLight = Color(0xFF64748B); // slate-500
  static const Color textDisabledLight = Color(0xFF94A3B8); // slate-400
  static const Color textHintLight = Color(0xFFCBD5E1); // slate-300

  // Text Colors - Dark Theme
  static const Color textPrimaryDark = Color(0xFFF8FAFC); // slate-50
  static const Color textSecondaryDark = Color(0xFF94A3B8); // slate-400
  static const Color textDisabledDark = Color(0xFF64748B); // slate-500
  static const Color textHintDark = Color(0xFF475569); // slate-600

  // Border Colors
  static const Color borderLight = Color(0xFFE2E8F0); // slate-200
  static const Color borderDark = Color(0xFF475569); // slate-600
  static const Color dividerLight = Color(0xFFF1F5F9); // slate-100
  static const Color dividerDark = Color(0xFF334155); // slate-700

  // Status Colors
  static const Color successColor = Color(0xFF10B981); // emerald-500
  static const Color successBackground = Color(0xFFD1FAE5); // emerald-100
  static const Color warningColor = Color(0xFFF59E0B); // amber-500
  static const Color warningBackground = Color(0xFFFEF3C7); // amber-100
  static const Color errorColor = Color(0xFFEF4444); // red-500
  static const Color errorBackground = Color(0xFFFEE2E2); // red-100
  static const Color infoColor = Color(0xFF3B82F6); // blue-500
  static const Color infoBackground = Color(0xFFDBEAFE); // blue-100

  // Chat Colors
  static const Color sentMessageColor = Color(0xFF3B82F6); // blue-500
  static const Color receivedMessageColor = Color(0xFFF1F5F9); // slate-100
  static const Color sentMessageColorDark = Color(0xFF1D4ED8); // blue-700
  static const Color receivedMessageColorDark = Color(0xFF334155); // slate-700

  // Online Status Colors
  static const Color onlineColor = Color(0xFF10B981); // emerald-500
  static const Color awayColor = Color(0xFFF59E0B); // amber-500
  static const Color busyColor = Color(0xFFEF4444); // red-500
  static const Color offlineColor = Color(0xFF6B7280); // gray-500

  // Call Colors
  static const Color callAcceptColor = Color(0xFF10B981); // emerald-500
  static const Color callDeclineColor = Color(0xFFEF4444); // red-500
  static const Color callMuteColor = Color(0xFF6B7280); // gray-500
  static const Color callActiveColor = Color(0xFF3B82F6); // blue-500

  // Group Colors (for avatars and themes)
  static const List<Color> groupColors = [
    Color(0xFFEF4444), // red-500
    Color(0xFFF97316), // orange-500
    Color(0xFFF59E0B), // amber-500
    Color(0xFFEAB308), // yellow-500
    Color(0xFF84CC16), // lime-500
    Color(0xFF22C55E), // green-500
    Color(0xFF10B981), // emerald-500
    Color(0xFF14B8A6), // teal-500
    Color(0xFF06B6D4), // cyan-500
    Color(0xFF0EA5E9), // sky-500
    Color(0xFF3B82F6), // blue-500
    Color(0xFF6366F1), // indigo-500
    Color(0xFF8B5CF6), // violet-500
    Color(0xFFA855F7), // purple-500
    Color(0xFFD946EF), // fuchsia-500
    Color(0xFFEC4899), // pink-500
    Color(0xFFF43F5E), // rose-500
  ];

  // Avatar Colors (for default avatars)
  static const List<Color> avatarColors = [
    Color(0xFF3B82F6), // blue-500
    Color(0xFF10B981), // emerald-500
    Color(0xFFF59E0B), // amber-500
    Color(0xFFEF4444), // red-500
    Color(0xFF8B5CF6), // violet-500
    Color(0xFFEC4899), // pink-500
    Color(0xFF06B6D4), // cyan-500
    Color(0xFF84CC16), // lime-500
    Color(0xFFF97316), // orange-500
    Color(0xFF6366F1), // indigo-500
  ];

  // Reaction Colors
  static const Map<String, Color> reactionColors = {
    '👍': Color(0xFF3B82F6), // blue-500
    '❤️': Color(0xFFEF4444), // red-500
    '😂': Color(0xFFF59E0B), // amber-500
    '😮': Color(0xFF8B5CF6), // violet-500
    '😢': Color(0xFF06B6D4), // cyan-500
    '😡': Color(0xFFF97316), // orange-500
  };

  // File Type Colors
  static const Map<String, Color> fileTypeColors = {
    'pdf': Color(0xFFEF4444), // red-500
    'doc': Color(0xFF3B82F6), // blue-500
    'docx': Color(0xFF3B82F6), // blue-500
    'xls': Color(0xFF10B981), // emerald-500
    'xlsx': Color(0xFF10B981), // emerald-500
    'ppt': Color(0xFFF97316), // orange-500
    'pptx': Color(0xFFF97316), // orange-500
    'txt': Color(0xFF6B7280), // gray-500
    'zip': Color(0xFF8B5CF6), // violet-500
    'rar': Color(0xFF8B5CF6), // violet-500
    'default': Color(0xFF64748B), // slate-500
  };

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)], // blue-500 to blue-700
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [
      Color(0xFF10B981),
      Color(0xFF059669),
    ], // emerald-500 to emerald-600
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient callGradient = LinearGradient(
    colors: [
      Color(0xFF10B981),
      Color(0xFF059669),
    ], // emerald-500 to emerald-600
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient errorGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFDC2626)], // red-500 to red-600
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shadows
  static const BoxShadow defaultShadow = BoxShadow(
    color: Color(0x1A000000), // black with 10% opacity
    blurRadius: 8,
    offset: Offset(0, 2),
  );

  static const BoxShadow cardShadow = BoxShadow(
    color: Color(0x1A000000), // black with 10% opacity
    blurRadius: 16,
    offset: Offset(0, 4),
  );

  static const BoxShadow dialogShadow = BoxShadow(
    color: Color(0x33000000), // black with 20% opacity
    blurRadius: 24,
    offset: Offset(0, 8),
  );

  // Material Design 3 Colors (for shadcn_ui compatibility)
  static const Color seedColor = Color(0xFF3B82F6); // blue-500

  // Helper Methods
  static Color getAvatarColor(String text) {
    final hash = text.hashCode;
    final index = hash.abs() % avatarColors.length;
    return avatarColors[index];
  }

  static Color getGroupColor(String groupId) {
    final hash = groupId.hashCode;
    final index = hash.abs() % groupColors.length;
    return groupColors[index];
  }

  static Color getFileTypeColor(String extension) {
    return fileTypeColors[extension.toLowerCase()] ??
        fileTypeColors['default']!;
  }

  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }

  static Color lighten(Color color, [double amount = 0.1]) {
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  static Color darken(Color color, [double amount = 0.1]) {
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  // Semantic Colors
  static const Color destructive = Color(0xFFEF4444); // red-500
  static const Color destructiveForeground = Color(0xFFFEFEFE); // neutral-50
  static const Color muted = Color(0xFFF1F5F9); // slate-100
  static const Color mutedForeground = Color(0xFF64748B); // slate-500
  static const Color popover = Color(0xFFFFFFFF); // white
  static const Color popoverForeground = Color(0xFF0F172A); // slate-900
  static const Color input = Color(0xFFE2E8F0); // slate-200
  static const Color ring = Color(0xFF3B82F6); // blue-500

  // Dark mode semantic colors
  static const Color destructiveDark = Color(0xFF7F1D1D); // red-900
  static const Color destructiveForegroundDark = Color(
    0xFFFEFEFE,
  ); // neutral-50
  static const Color mutedDark = Color(0xFF1E293B); // slate-800
  static const Color mutedForegroundDark = Color(0xFF94A3B8); // slate-400
  static const Color popoverDark = Color(0xFF0F172A); // slate-900
  static const Color popoverForegroundDark = Color(0xFFF8FAFC); // slate-50
  static const Color inputDark = Color(0xFF1E293B); // slate-800
  static const Color ringDark = Color(0xFF1D4ED8); // blue-700

  // Chat specific colors
  static const Color typingIndicator = Color(0xFF94A3B8); // slate-400
  static const Color readReceipt = Color(0xFF3B82F6); // blue-500
  static const Color unreadBadge = Color(0xFFEF4444); // red-500
  static const Color pinnedChat = Color(0xFFF59E0B); // amber-500
  static const Color archivedChat = Color(0xFF6B7280); // gray-500
  static const Color mutedChat = Color(0xFF94A3B8); // slate-400

  // Call UI colors
  static const Color incomingCall = Color(0xFF10B981); // emerald-500
  static const Color outgoingCall = Color(0xFF3B82F6); // blue-500
  static const Color missedCall = Color(0xFFEF4444); // red-500
  static const Color callBackground = Color(0xFF000000); // black
  static const Color callOverlay = Color(0x80000000); // black with 50% opacity

  // Status colors
  static const Color deliveredStatus = Color(0xFF6B7280); // gray-500
  static const Color readStatus = Color(0xFF3B82F6); // blue-500
  static const Color pendingStatus = Color(0xFF94A3B8); // slate-400
  static const Color failedStatus = Color(0xFFEF4444); // red-500

  // System colors (matching platform)
  static const Color systemBlue = Color(0xFF007AFF);
  static const Color systemGreen = Color(0xFF34C759);
  static const Color systemRed = Color(0xFFFF3B30);
  static const Color systemOrange = Color(0xFFFF9500);
  static const Color systemYellow = Color(0xFFFFCC00);
  static const Color systemPurple = Color(0xFFAF52DE);
  static const Color systemPink = Color(0xFFFF2D92);
  static const Color systemTeal = Color(0xFF5AC8FA);
  static const Color systemIndigo = Color(0xFF5856D6);

  // Chart colors
  static const List<Color> chartColors = [
    Color(0xFF3B82F6), // blue-500
    Color(0xFF10B981), // emerald-500
    Color(0xFFF59E0B), // amber-500
    Color(0xFFEF4444), // red-500
    Color(0xFF8B5CF6), // violet-500
    Color(0xFFEC4899), // pink-500
    Color(0xFF06B6D4), // cyan-500
    Color(0xFF84CC16), // lime-500
  ];
}
