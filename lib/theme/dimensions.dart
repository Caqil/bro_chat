import 'package:flutter/material.dart';

class AppDimensions {
  AppDimensions._();

  // Base spacing unit (8dp Material Design)
  static const double unit = 8.0;

  // Spacing Scale
  static const double spacing2xs = unit * 0.25; // 2dp
  static const double spacingXs = unit * 0.5; // 4dp
  static const double spacingSm = unit * 1; // 8dp
  static const double spacingMd = unit * 2; // 16dp
  static const double spacingLg = unit * 3; // 24dp
  static const double spacingXl = unit * 4; // 32dp
  static const double spacing2xl = unit * 5; // 40dp
  static const double spacing3xl = unit * 6; // 48dp
  static const double spacing4xl = unit * 8; // 64dp

  // Padding
  static const EdgeInsets paddingZero = EdgeInsets.zero;
  static const EdgeInsets paddingXs = EdgeInsets.all(spacingXs);
  static const EdgeInsets paddingSm = EdgeInsets.all(spacingSm);
  static const EdgeInsets paddingMd = EdgeInsets.all(spacingMd);
  static const EdgeInsets paddingLg = EdgeInsets.all(spacingLg);
  static const EdgeInsets paddingXl = EdgeInsets.all(spacingXl);
  static const EdgeInsets padding2xl = EdgeInsets.all(spacing2xl);

  // Horizontal Padding
  static const EdgeInsets paddingHorizontalXs = EdgeInsets.symmetric(
    horizontal: spacingXs,
  );
  static const EdgeInsets paddingHorizontalSm = EdgeInsets.symmetric(
    horizontal: spacingSm,
  );
  static const EdgeInsets paddingHorizontalMd = EdgeInsets.symmetric(
    horizontal: spacingMd,
  );
  static const EdgeInsets paddingHorizontalLg = EdgeInsets.symmetric(
    horizontal: spacingLg,
  );
  static const EdgeInsets paddingHorizontalXl = EdgeInsets.symmetric(
    horizontal: spacingXl,
  );

  // Vertical Padding
  static const EdgeInsets paddingVerticalXs = EdgeInsets.symmetric(
    vertical: spacingXs,
  );
  static const EdgeInsets paddingVerticalSm = EdgeInsets.symmetric(
    vertical: spacingSm,
  );
  static const EdgeInsets paddingVerticalMd = EdgeInsets.symmetric(
    vertical: spacingMd,
  );
  static const EdgeInsets paddingVerticalLg = EdgeInsets.symmetric(
    vertical: spacingLg,
  );
  static const EdgeInsets paddingVerticalXl = EdgeInsets.symmetric(
    vertical: spacingXl,
  );

  // Margin
  static const EdgeInsets marginZero = EdgeInsets.zero;
  static const EdgeInsets marginXs = EdgeInsets.all(spacingXs);
  static const EdgeInsets marginSm = EdgeInsets.all(spacingSm);
  static const EdgeInsets marginMd = EdgeInsets.all(spacingMd);
  static const EdgeInsets marginLg = EdgeInsets.all(spacingLg);
  static const EdgeInsets marginXl = EdgeInsets.all(spacingXl);

  // Border Radius
  static const double radiusXs = 2.0;
  static const double radiusSm = 4.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 12.0;
  static const double radiusXl = 16.0;
  static const double radius2xl = 20.0;
  static const double radius3xl = 24.0;
  static const double radiusFull = 9999.0;

  // Border Radius Objects
  static const BorderRadius borderRadiusXs = BorderRadius.all(
    Radius.circular(radiusXs),
  );
  static const BorderRadius borderRadiusSm = BorderRadius.all(
    Radius.circular(radiusSm),
  );
  static const BorderRadius borderRadiusMd = BorderRadius.all(
    Radius.circular(radiusMd),
  );
  static const BorderRadius borderRadiusLg = BorderRadius.all(
    Radius.circular(radiusLg),
  );
  static const BorderRadius borderRadiusXl = BorderRadius.all(
    Radius.circular(radiusXl),
  );
  static const BorderRadius borderRadius2xl = BorderRadius.all(
    Radius.circular(radius2xl),
  );
  static const BorderRadius borderRadius3xl = BorderRadius.all(
    Radius.circular(radius3xl),
  );
  static const BorderRadius borderRadiusFull = BorderRadius.all(
    Radius.circular(radiusFull),
  );

  // Icon Sizes
  static const double iconXs = 12.0;
  static const double iconSm = 16.0;
  static const double iconMd = 20.0;
  static const double iconLg = 24.0;
  static const double iconXl = 32.0;
  static const double icon2xl = 40.0;
  static const double icon3xl = 48.0;
  static const double icon4xl = 56.0;
  static const double icon5xl = 64.0;

  // Avatar Sizes
  static const double avatarXs = 24.0;
  static const double avatarSm = 32.0;
  static const double avatarMd = 40.0;
  static const double avatarLg = 48.0;
  static const double avatarXl = 56.0;
  static const double avatar2xl = 64.0;
  static const double avatar3xl = 80.0;
  static const double avatar4xl = 96.0;
  static const double avatar5xl = 120.0;

  // Button Heights
  static const double buttonHeightSm = 32.0;
  static const double buttonHeightMd = 40.0;
  static const double buttonHeightLg = 48.0;
  static const double buttonHeightXl = 56.0;

  // Button Padding
  static const EdgeInsets buttonPaddingSm = EdgeInsets.symmetric(
    horizontal: spacingMd,
    vertical: spacingSm,
  );
  static const EdgeInsets buttonPaddingMd = EdgeInsets.symmetric(
    horizontal: spacingLg,
    vertical: spacingMd,
  );
  static const EdgeInsets buttonPaddingLg = EdgeInsets.symmetric(
    horizontal: spacingXl,
    vertical: spacingLg,
  );

  // Input Field Heights
  static const double inputHeightSm = 36.0;
  static const double inputHeightMd = 44.0;
  static const double inputHeightLg = 52.0;

  // Media Widget Specific Dimensions
  static const double messageMaxWidth = 280.0;
  static const double messageMinWidth = 100.0;
  static const double messageBubblePadding = spacingMd;
  static const BorderRadius messageBubbleRadius = BorderRadius.all(
    Radius.circular(radiusLg),
  );

  // Image Message Dimensions
  static const double imageMessageMaxWidth = 280.0;
  static const double imageMessageMaxHeight = 400.0;
  static const double imageMessageMinHeight = 100.0;
  static const BorderRadius imageMessageRadius = BorderRadius.all(
    Radius.circular(radiusLg),
  );

  // Video Message Dimensions
  static const double videoMessageMaxWidth = 280.0;
  static const double videoMessageMaxHeight = 400.0;
  static const double videoMessageMinHeight = 150.0;
  static const double videoControlsHeight = 48.0;
  static const double videoPlayButtonSize = 64.0;
  static const BorderRadius videoMessageRadius = BorderRadius.all(
    Radius.circular(radiusLg),
  );

  // Audio Message Dimensions
  static const double audioMessageMaxWidth = 280.0;
  static const double audioMessageHeight = 60.0;
  static const double audioPlayButtonSize = 48.0;
  static const double audioWaveformHeight = 40.0;
  static const double audioWaveformBarWidth = 3.0;
  static const double audioWaveformBarSpacing = 1.5;
  static const BorderRadius audioMessageRadius = BorderRadius.all(
    Radius.circular(radiusLg),
  );

  // Document Message Dimensions
  static const double documentMessageMaxWidth = 280.0;
  static const double documentMessageMinHeight = 80.0;
  static const double documentIconSize = 48.0;
  static const BorderRadius documentMessageRadius = BorderRadius.all(
    Radius.circular(radiusLg),
  );

  // Contact Message Dimensions
  static const double contactMessageMaxWidth = 280.0;
  static const double contactMessageMinHeight = 80.0;
  static const double contactAvatarSize = 56.0;
  static const BorderRadius contactMessageRadius = BorderRadius.all(
    Radius.circular(radiusLg),
  );

  // Location Message Dimensions
  static const double locationMessageMaxWidth = 280.0;
  static const double locationMessageMapHeight = 200.0;
  static const double locationMessageMinHeight = 240.0;
  static const BorderRadius locationMessageRadius = BorderRadius.all(
    Radius.circular(radiusLg),
  );

  // Media Grid Dimensions
  static const double mediaGridMaxWidth = 280.0;
  static const double mediaGridMaxHeight = 400.0;
  static const double mediaGridSpacing = 2.0;
  static const double mediaGridItemMinSize = 60.0;
  static const BorderRadius mediaGridItemRadius = BorderRadius.all(
    Radius.circular(radiusMd),
  );

  // Media Thumbnail Dimensions
  static const double thumbnailSm = 60.0;
  static const double thumbnailMd = 80.0;
  static const double thumbnailLg = 120.0;
  static const double thumbnailXl = 160.0;
  static const BorderRadius thumbnailRadius = BorderRadius.all(
    Radius.circular(radiusMd),
  );

  // Progress Indicator Dimensions
  static const double progressBarHeight = 4.0;
  static const double progressBarHeightLarge = 6.0;
  static const double progressIndicatorSize = 20.0;
  static const double progressIndicatorSizeLarge = 32.0;
  static const double progressIndicatorStrokeWidth = 2.0;
  static const double progressIndicatorStrokeWidthLarge = 3.0;

  // Overlay Dimensions
  static const double overlayButtonSize = 36.0;
  static const double overlayButtonSizeLarge = 48.0;
  static const double overlayBackgroundOpacity = 0.7;
  static const BorderRadius overlayButtonRadius = BorderRadius.all(
    Radius.circular(radiusFull),
  );

  // Action Sheet Dimensions
  static const double actionSheetHandleWidth = 40.0;
  static const double actionSheetHandleHeight = 4.0;
  static const double actionSheetItemHeight = 56.0;
  static const EdgeInsets actionSheetPadding = EdgeInsets.all(spacingMd);
  static const BorderRadius actionSheetRadius = BorderRadius.vertical(
    top: Radius.circular(radius2xl),
  );

  // Modal Dimensions
  static const double modalMaxWidth = 400.0;
  static const EdgeInsets modalPadding = EdgeInsets.all(spacingLg);
  static const BorderRadius modalRadius = BorderRadius.all(
    Radius.circular(radiusXl),
  );

  // Shadow Elevations
  static const double elevationNone = 0.0;
  static const double elevationXs = 1.0;
  static const double elevationSm = 2.0;
  static const double elevationMd = 4.0;
  static const double elevationLg = 8.0;
  static const double elevationXl = 12.0;
  static const double elevation2xl = 16.0;
  static const double elevation3xl = 24.0;

  // Animation Durations (in milliseconds)
  static const int animationDurationFast = 150;
  static const int animationDurationNormal = 300;
  static const int animationDurationSlow = 500;
  static const int animationDurationVerySlow = 800;

  // Breakpoints (for responsive design)
  static const double breakpointXs = 480.0;
  static const double breakpointSm = 640.0;
  static const double breakpointMd = 768.0;
  static const double breakpointLg = 1024.0;
  static const double breakpointXl = 1280.0;
  static const double breakpoint2xl = 1536.0;

  // Chat-specific Dimensions
  static const double chatItemHeight = 72.0;
  static const double chatItemAvatarSize = avatarMd;
  static const double chatItemPadding = spacingMd;
  static const double chatBubbleMaxWidth = 280.0;
  static const double chatBubbleMinWidth = 40.0;
  static const EdgeInsets chatBubbleMargin = EdgeInsets.symmetric(
    horizontal: spacingSm,
    vertical: spacing2xs,
  );

  // Message Status Dimensions
  static const double messageStatusIconSize = iconSm;
  static const double messageTimestampIconSize = iconXs;
  static const double unreadBadgeSize = 20.0;
  static const double unreadBadgeMinWidth = 20.0;

  // Typing Indicator Dimensions
  static const double typingIndicatorDotSize = 6.0;
  static const double typingIndicatorSpacing = 4.0;
  static const double typingIndicatorHeight = 24.0;

  // Voice Message Recorder Dimensions
  static const double voiceRecorderHeight = 60.0;
  static const double voiceRecorderButtonSize = 48.0;
  static const double voiceRecorderWaveformHeight = 32.0;

  // Media Controls Dimensions
  static const double mediaControlsHeight = 48.0;
  static const double mediaControlsButtonSize = 32.0;
  static const double mediaControlsSliderHeight = 24.0;
  static const EdgeInsets mediaControlsPadding = EdgeInsets.all(spacingSm);

  // Utility Methods
  static EdgeInsets symmetric({double? horizontal, double? vertical}) {
    return EdgeInsets.symmetric(
      horizontal: horizontal ?? 0,
      vertical: vertical ?? 0,
    );
  }

  static EdgeInsets only({
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) {
    return EdgeInsets.only(
      left: left ?? 0,
      top: top ?? 0,
      right: right ?? 0,
      bottom: bottom ?? 0,
    );
  }

  static BorderRadius circular(double radius) {
    return BorderRadius.circular(radius);
  }

  static BorderRadius vertical({double? top, double? bottom}) {
    return BorderRadius.vertical(
      top: Radius.circular(top ?? 0),
      bottom: Radius.circular(bottom ?? 0),
    );
  }

  static BorderRadius horizontal({double? left, double? right}) {
    return BorderRadius.horizontal(
      left: Radius.circular(left ?? 0),
      right: Radius.circular(right ?? 0),
    );
  }

  // Responsive helper methods
  static bool isXs(double width) => width < breakpointXs;
  static bool isSm(double width) =>
      width >= breakpointXs && width < breakpointSm;
  static bool isMd(double width) =>
      width >= breakpointSm && width < breakpointMd;
  static bool isLg(double width) =>
      width >= breakpointMd && width < breakpointLg;
  static bool isXl(double width) =>
      width >= breakpointLg && width < breakpointXl;
  static bool is2xl(double width) => width >= breakpointXl;

  // Dynamic sizing based on screen width
  static double responsiveSpacing(double screenWidth) {
    if (isXs(screenWidth)) return spacingSm;
    if (isSm(screenWidth)) return spacingMd;
    if (isMd(screenWidth)) return spacingLg;
    return spacingXl;
  }

  static double responsivePadding(double screenWidth) {
    if (isXs(screenWidth)) return spacingSm;
    if (isSm(screenWidth)) return spacingMd;
    return spacingLg;
  }

  static double responsiveRadius(double screenWidth) {
    if (isXs(screenWidth)) return radiusSm;
    if (isSm(screenWidth)) return radiusMd;
    return radiusLg;
  }

  // Media query helpers
  static EdgeInsets safeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }
}
