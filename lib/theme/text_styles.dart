import 'package:flutter/material.dart';
import 'colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // Font Family
  static const String _fontFamily =
      'Inter'; // Can be changed to your preferred font
  static const String _fontFamilyMono = 'JetBrainsMono'; // For code/timestamps

  // Font Weights
  static const FontWeight thin = FontWeight.w100;
  static const FontWeight extraLight = FontWeight.w200;
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w800;
  static const FontWeight black = FontWeight.w900;

  // Base Text Style
  static const TextStyle _baseStyle = TextStyle(
    fontFamily: _fontFamily,
    fontWeight: regular,
    letterSpacing: 0,
    height: 1.5,
  );

  // Display Styles (Large headings)
  static TextStyle get displayLarge => _baseStyle.copyWith(
    fontSize: 57,
    fontWeight: regular,
    height: 1.12,
    letterSpacing: -0.25,
  );

  static TextStyle get displayMedium => _baseStyle.copyWith(
    fontSize: 45,
    fontWeight: regular,
    height: 1.16,
    letterSpacing: 0,
  );

  static TextStyle get displaySmall => _baseStyle.copyWith(
    fontSize: 36,
    fontWeight: regular,
    height: 1.22,
    letterSpacing: 0,
  );

  // Headline Styles
  static TextStyle get headlineLarge => _baseStyle.copyWith(
    fontSize: 32,
    fontWeight: regular,
    height: 1.25,
    letterSpacing: 0,
  );

  static TextStyle get headlineMedium => _baseStyle.copyWith(
    fontSize: 28,
    fontWeight: regular,
    height: 1.29,
    letterSpacing: 0,
  );

  static TextStyle get headlineSmall => _baseStyle.copyWith(
    fontSize: 24,
    fontWeight: regular,
    height: 1.33,
    letterSpacing: 0,
  );

  // Title Styles
  static TextStyle get titleLarge => _baseStyle.copyWith(
    fontSize: 22,
    fontWeight: regular,
    height: 1.27,
    letterSpacing: 0,
  );

  static TextStyle get titleMedium => _baseStyle.copyWith(
    fontSize: 16,
    fontWeight: medium,
    height: 1.5,
    letterSpacing: 0.15,
  );

  static TextStyle get titleSmall => _baseStyle.copyWith(
    fontSize: 14,
    fontWeight: medium,
    height: 1.43,
    letterSpacing: 0.1,
  );

  // Label Styles
  static TextStyle get labelLarge => _baseStyle.copyWith(
    fontSize: 14,
    fontWeight: medium,
    height: 1.43,
    letterSpacing: 0.1,
  );

  static TextStyle get labelMedium => _baseStyle.copyWith(
    fontSize: 12,
    fontWeight: medium,
    height: 1.33,
    letterSpacing: 0.5,
  );

  static TextStyle get labelSmall => _baseStyle.copyWith(
    fontSize: 11,
    fontWeight: medium,
    height: 1.45,
    letterSpacing: 0.5,
  );

  // Body Styles
  static TextStyle get bodyLarge => _baseStyle.copyWith(
    fontSize: 16,
    fontWeight: regular,
    height: 1.5,
    letterSpacing: 0.15,
  );

  static TextStyle get bodyMedium => _baseStyle.copyWith(
    fontSize: 14,
    fontWeight: regular,
    height: 1.43,
    letterSpacing: 0.25,
  );

  static TextStyle get bodySmall => _baseStyle.copyWith(
    fontSize: 12,
    fontWeight: regular,
    height: 1.33,
    letterSpacing: 0.4,
  );

  // Semantic Heading Styles (h1-h6)
  static TextStyle get h1 => displayLarge;
  static TextStyle get h2 => displayMedium;
  static TextStyle get h3 => displaySmall;
  static TextStyle get h4 => headlineLarge;
  static TextStyle get h5 => headlineMedium;
  static TextStyle get h6 => headlineSmall;

  // Common Text Styles
  static TextStyle get subtitle1 => titleLarge;
  static TextStyle get subtitle2 => titleMedium;
  static TextStyle get body1 => bodyLarge;
  static TextStyle get body2 => bodyMedium;
  static TextStyle get caption => bodySmall;
  static TextStyle get overline => labelSmall.copyWith(
    letterSpacing: 1.5,
    textBaseline: TextBaseline.alphabetic,
  );

  // Chat-specific Text Styles
  static TextStyle get chatMessageText =>
      bodyMedium.copyWith(height: 1.4, letterSpacing: 0.1);

  static TextStyle get chatMessageTextOwn =>
      chatMessageText.copyWith(color: Colors.white);

  static TextStyle get chatMessageTextOther =>
      chatMessageText.copyWith(color: AppColors.textPrimary);

  static TextStyle get chatBubbleText =>
      bodyMedium.copyWith(height: 1.35, letterSpacing: 0.1);

  static TextStyle get chatTimestamp => caption.copyWith(
    fontFamily: _fontFamilyMono,
    fontSize: 11,
    fontWeight: regular,
    color: AppColors.textSecondary,
    letterSpacing: 0.2,
  );

  static TextStyle get chatTimestampOwn =>
      chatTimestamp.copyWith(color: Colors.white.withOpacity(0.7));

  static TextStyle get chatSenderName => labelMedium.copyWith(
    fontWeight: semiBold,
    color: AppColors.primary,
    letterSpacing: 0.1,
  );

  static TextStyle get chatPreview =>
      bodySmall.copyWith(color: AppColors.textSecondary, height: 1.3);

  static TextStyle get chatUnreadPreview =>
      chatPreview.copyWith(fontWeight: medium, color: AppColors.textPrimary);

  // Media Widget Text Styles
  static TextStyle get mediaTitle =>
      titleMedium.copyWith(fontWeight: semiBold, letterSpacing: 0.1);

  static TextStyle get mediaSubtitle =>
      bodySmall.copyWith(color: AppColors.textSecondary, height: 1.3);

  static TextStyle get mediaCaption =>
      caption.copyWith(color: AppColors.textSecondary, height: 1.3);

  static TextStyle get mediaDuration => caption.copyWith(
    fontFamily: _fontFamilyMono,
    fontWeight: medium,
    fontSize: 11,
    letterSpacing: 0.5,
  );

  static TextStyle get mediaDurationOverlay => mediaDuration.copyWith(
    color: Colors.white,
    fontSize: 10,
    fontWeight: semiBold,
  );

  static TextStyle get mediaFileSize => caption.copyWith(
    color: AppColors.textSecondary,
    fontSize: 10,
    letterSpacing: 0.2,
  );

  static TextStyle get mediaFileName =>
      bodyMedium.copyWith(fontWeight: medium, letterSpacing: 0.1);

  // Audio-specific Text Styles
  static TextStyle get audioTitle => mediaTitle;
  static TextStyle get audioDuration => mediaDuration;
  static TextStyle get audioProgress => caption.copyWith(
    fontFamily: _fontFamilyMono,
    fontSize: 10,
    fontWeight: medium,
    letterSpacing: 0.5,
  );

  // Video-specific Text Styles
  static TextStyle get videoTitle => mediaTitle;
  static TextStyle get videoDuration => mediaDuration;
  static TextStyle get videoResolution =>
      caption.copyWith(fontSize: 10, letterSpacing: 0.2);

  // Document-specific Text Styles
  static TextStyle get documentName => mediaFileName.copyWith(fontSize: 15);
  static TextStyle get documentType => caption.copyWith(
    fontWeight: semiBold,
    fontSize: 10,
    letterSpacing: 0.5,
    textBaseline: TextBaseline.alphabetic,
  );
  static TextStyle get documentSize => mediaFileSize;
  static TextStyle get documentPages =>
      caption.copyWith(fontSize: 10, color: AppColors.textTertiary);

  // Contact-specific Text Styles
  static TextStyle get contactName =>
      titleMedium.copyWith(fontWeight: semiBold, letterSpacing: 0.1);
  static TextStyle get contactPhone =>
      bodySmall.copyWith(fontFamily: _fontFamilyMono, letterSpacing: 0.2);
  static TextStyle get contactEmail => bodySmall.copyWith(letterSpacing: 0.1);
  static TextStyle get contactOrganization => bodySmall.copyWith(
    color: AppColors.textSecondary,
    fontStyle: FontStyle.italic,
  );

  // Location-specific Text Styles
  static TextStyle get locationName =>
      titleMedium.copyWith(fontWeight: semiBold, letterSpacing: 0.1);
  static TextStyle get locationAddress =>
      bodySmall.copyWith(height: 1.3, letterSpacing: 0.1);
  static TextStyle get locationCoordinates => caption.copyWith(
    fontFamily: _fontFamilyMono,
    fontSize: 10,
    letterSpacing: 0.2,
  );
  static TextStyle get locationDistance =>
      caption.copyWith(fontWeight: medium, fontSize: 11);
  static TextStyle get locationAccuracy =>
      caption.copyWith(fontSize: 10, letterSpacing: 0.2);

  // Button Text Styles
  static TextStyle get buttonLarge =>
      labelLarge.copyWith(fontWeight: semiBold, letterSpacing: 0.1);

  static TextStyle get buttonMedium => labelMedium.copyWith(
    fontWeight: semiBold,
    fontSize: 13,
    letterSpacing: 0.2,
  );

  static TextStyle get buttonSmall =>
      labelSmall.copyWith(fontWeight: semiBold, letterSpacing: 0.3);

  // Input Text Styles
  static TextStyle get inputText =>
      bodyMedium.copyWith(height: 1.4, letterSpacing: 0.15);

  static TextStyle get inputLabel =>
      labelMedium.copyWith(fontWeight: medium, letterSpacing: 0.1);

  static TextStyle get inputHint =>
      bodyMedium.copyWith(color: AppColors.textHint, letterSpacing: 0.15);

  static TextStyle get inputError =>
      labelSmall.copyWith(color: AppColors.error, fontWeight: medium);

  // Status Text Styles
  static TextStyle get statusSuccess => labelSmall.copyWith(
    color: AppColors.success,
    fontWeight: semiBold,
    letterSpacing: 0.3,
  );

  static TextStyle get statusWarning => labelSmall.copyWith(
    color: AppColors.warning,
    fontWeight: semiBold,
    letterSpacing: 0.3,
  );

  static TextStyle get statusError => labelSmall.copyWith(
    color: AppColors.error,
    fontWeight: semiBold,
    letterSpacing: 0.3,
  );

  static TextStyle get statusInfo => labelSmall.copyWith(
    color: AppColors.info,
    fontWeight: semiBold,
    letterSpacing: 0.3,
  );

  // Badge and Indicator Text Styles
  static TextStyle get badge => labelSmall.copyWith(
    fontWeight: bold,
    fontSize: 10,
    letterSpacing: 0.3,
    height: 1.2,
  );

  static TextStyle get unreadCount => labelSmall.copyWith(
    fontWeight: bold,
    fontSize: 10,
    color: Colors.white,
    letterSpacing: 0.2,
    height: 1.2,
  );

  static TextStyle get onlineStatus => labelSmall.copyWith(
    fontWeight: medium,
    fontSize: 10,
    color: AppColors.success,
    letterSpacing: 0.2,
  );

  // Loading and Progress Text Styles
  static TextStyle get loadingText =>
      bodySmall.copyWith(color: AppColors.textSecondary, letterSpacing: 0.2);

  static TextStyle get progressPercentage => caption.copyWith(
    fontFamily: _fontFamilyMono,
    fontWeight: semiBold,
    fontSize: 10,
    letterSpacing: 0.3,
  );

  // Link Text Styles
  static TextStyle get link => bodyMedium.copyWith(
    color: AppColors.primary,
    decoration: TextDecoration.underline,
    decorationColor: AppColors.primary,
  );

  static TextStyle get linkVisited => link.copyWith(
    color: AppColors.primaryDark,
    decorationColor: AppColors.primaryDark,
  );

  // Code Text Styles
  static TextStyle get code => bodySmall.copyWith(
    fontFamily: _fontFamilyMono,
    backgroundColor: AppColors.backgroundTertiary,
    letterSpacing: 0.2,
  );

  static TextStyle get codeBlock => code.copyWith(fontSize: 13, height: 1.4);

  // Utility Methods
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  static TextStyle withWeight(TextStyle style, FontWeight weight) {
    return style.copyWith(fontWeight: weight);
  }

  static TextStyle withSize(TextStyle style, double size) {
    return style.copyWith(fontSize: size);
  }

  static TextStyle withOpacity(TextStyle style, double opacity) {
    return style.copyWith(color: style.color?.withOpacity(opacity));
  }

  static TextStyle withHeight(TextStyle style, double height) {
    return style.copyWith(height: height);
  }

  static TextStyle withLetterSpacing(TextStyle style, double spacing) {
    return style.copyWith(letterSpacing: spacing);
  }

  // Dark Theme Adaptations
  static TextStyle adaptForDarkTheme(TextStyle style) {
    Color? adaptedColor;

    if (style.color == AppColors.textPrimary) {
      adaptedColor = AppColors.textPrimaryDark;
    } else if (style.color == AppColors.textSecondary) {
      adaptedColor = AppColors.textSecondaryDark;
    } else if (style.color == AppColors.textTertiary) {
      adaptedColor = AppColors.textTertiaryDark;
    } else if (style.color == AppColors.textHint) {
      adaptedColor = AppColors.textHintDark;
    }

    return adaptedColor != null ? style.copyWith(color: adaptedColor) : style;
  }

  // Responsive Text Scaling
  static TextStyle scaleForDevice(TextStyle style, double scaleFactor) {
    return style.copyWith(fontSize: (style.fontSize ?? 14) * scaleFactor);
  }

  // Accessibility Helpers
  static TextStyle withAccessibilityFeatures(
    TextStyle style, {
    bool largeFonts = false,
    bool highContrast = false,
  }) {
    TextStyle adaptedStyle = style;

    if (largeFonts) {
      adaptedStyle = adaptedStyle.copyWith(
        fontSize: (style.fontSize ?? 14) * 1.2,
      );
    }

    if (highContrast) {
      adaptedStyle = adaptedStyle.copyWith(
        color: style.color == AppColors.textSecondary
            ? AppColors.textPrimary
            : style.color,
      );
    }

    return adaptedStyle;
  }
}
