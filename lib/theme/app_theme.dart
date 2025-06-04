import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'colors.dart';
import 'dimensions.dart';
import 'text_styles.dart';

class AppTheme {
  AppTheme._();

  // Theme Mode
  static ThemeMode themeMode = ThemeMode.system;

  // Material 3 Design Tokens
  static const bool useMaterial3 = true;

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: useMaterial3,
      brightness: Brightness.light,
      colorScheme: AppColors.lightColorScheme,

      // Primary Swatch
      primarySwatch: AppColors.createMaterialColor(AppColors.primary),
      primaryColor: AppColors.primary,
      primaryColorLight: AppColors.primaryLight,
      primaryColorDark: AppColors.primaryDark,

      // Background Colors
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      cardColor: AppColors.surface,
      dialogBackgroundColor: AppColors.surface,

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: AppDimensions.elevationSm,
        shadowColor: AppColors.shadowLight,
        centerTitle: false,
        titleTextStyle: AppTextStyles.titleLarge.copyWith(
          color: AppColors.textPrimary,
          fontWeight: AppTextStyles.semiBold,
        ),
        toolbarTextStyle: AppTextStyles.bodyMedium,
        iconTheme: const IconThemeData(
          color: AppColors.iconPrimary,
          size: AppDimensions.iconLg,
        ),
        actionsIconTheme: const IconThemeData(
          color: AppColors.iconPrimary,
          size: AppDimensions.iconLg,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        surfaceTintColor: AppColors.surface,
      ),

      // Text Theme
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge.copyWith(
          color: AppColors.textPrimary,
        ),
        displayMedium: AppTextStyles.displayMedium.copyWith(
          color: AppColors.textPrimary,
        ),
        displaySmall: AppTextStyles.displaySmall.copyWith(
          color: AppColors.textPrimary,
        ),
        headlineLarge: AppTextStyles.headlineLarge.copyWith(
          color: AppColors.textPrimary,
        ),
        headlineMedium: AppTextStyles.headlineMedium.copyWith(
          color: AppColors.textPrimary,
        ),
        headlineSmall: AppTextStyles.headlineSmall.copyWith(
          color: AppColors.textPrimary,
        ),
        titleLarge: AppTextStyles.titleLarge.copyWith(
          color: AppColors.textPrimary,
        ),
        titleMedium: AppTextStyles.titleMedium.copyWith(
          color: AppColors.textPrimary,
        ),
        titleSmall: AppTextStyles.titleSmall.copyWith(
          color: AppColors.textPrimary,
        ),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(
          color: AppColors.textPrimary,
        ),
        bodyMedium: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textPrimary,
        ),
        bodySmall: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textSecondary,
        ),
        labelLarge: AppTextStyles.labelLarge.copyWith(
          color: AppColors.textPrimary,
        ),
        labelMedium: AppTextStyles.labelMedium.copyWith(
          color: AppColors.textSecondary,
        ),
        labelSmall: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textSecondary,
        ),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: AppColors.iconPrimary,
        size: AppDimensions.iconLg,
      ),

      // Primary Icon Theme
      primaryIconTheme: const IconThemeData(
        color: Colors.white,
        size: AppDimensions.iconLg,
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: AppDimensions.elevationSm,
          shadowColor: AppColors.shadowMedium,
          shape: RoundedRectangleBorder(
            borderRadius: AppDimensions.borderRadiusLg,
          ),
          padding: AppDimensions.buttonPaddingMd,
          minimumSize: const Size(0, AppDimensions.buttonHeightMd),
          textStyle: AppTextStyles.buttonMedium,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.border, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: AppDimensions.borderRadiusLg,
          ),
          padding: AppDimensions.buttonPaddingMd,
          minimumSize: const Size(0, AppDimensions.buttonHeightMd),
          textStyle: AppTextStyles.buttonMedium,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: AppDimensions.borderRadiusLg,
          ),
          padding: AppDimensions.buttonPaddingMd,
          minimumSize: const Size(0, AppDimensions.buttonHeightMd),
          textStyle: AppTextStyles.buttonMedium,
        ),
      ),

      // Icon Button Theme
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.iconPrimary,
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: AppDimensions.borderRadiusMd,
          ),
          padding: const EdgeInsets.all(AppDimensions.spacingSm),
        ),
      ),

      // FloatingActionButton Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: AppDimensions.elevationMd,
        focusElevation: AppDimensions.elevationLg,
        hoverElevation: AppDimensions.elevationLg,
        highlightElevation: AppDimensions.elevationXl,
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.borderRadiusFull,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: AppDimensions.elevationSm,
        shadowColor: AppColors.shadowLight,
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.borderRadiusLg,
        ),
        margin: AppDimensions.marginSm,
      ),

      // List Tile Theme
      listTileTheme: ListTileThemeData(
        tileColor: AppColors.surface,
        selectedTileColor: AppColors.selectedLight,
        iconColor: AppColors.iconSecondary,
        textColor: AppColors.textPrimary,
        titleTextStyle: AppTextStyles.bodyLarge,
        subtitleTextStyle: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textSecondary,
        ),
        contentPadding: AppDimensions.paddingHorizontalMd,
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.borderRadiusMd,
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.backgroundSecondary,
        border: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusLg,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusLg,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusLg,
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusLg,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusLg,
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle: AppTextStyles.inputLabel.copyWith(
          color: AppColors.textSecondary,
        ),
        hintStyle: AppTextStyles.inputHint,
        errorStyle: AppTextStyles.inputError,
        contentPadding: AppDimensions.paddingMd,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.backgroundSecondary,
        selectedColor: AppColors.primary,
        secondarySelectedColor: AppColors.primaryLight,
        deleteIconColor: AppColors.iconSecondary,
        disabledColor: AppColors.backgroundTertiary,
        labelStyle: AppTextStyles.labelMedium,
        secondaryLabelStyle: AppTextStyles.labelMedium.copyWith(
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.borderRadiusFull,
        ),
        padding: AppDimensions.paddingHorizontalSm,
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        elevation: AppDimensions.elevationXl,
        shadowColor: AppColors.shadowMedium,
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.borderRadiusXl,
        ),
        titleTextStyle: AppTextStyles.titleLarge.copyWith(
          color: AppColors.textPrimary,
          fontWeight: AppTextStyles.semiBold,
        ),
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textPrimary,
        ),
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        elevation: AppDimensions.elevationXl,
        modalBackgroundColor: AppColors.surface,
        modalElevation: AppDimensions.elevationXl,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimensions.radius2xl),
          ),
        ),
      ),

      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.backgroundTertiaryDark,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: Colors.white,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.borderRadiusLg,
        ),
        elevation: AppDimensions.elevationMd,
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.backgroundTertiary,
        circularTrackColor: AppColors.backgroundTertiary,
      ),

      // Slider Theme
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.backgroundTertiary,
        thumbColor: AppColors.primary,
        overlayColor: AppColors.primary.withOpacity(0.1),
        valueIndicatorColor: AppColors.primary,
        valueIndicatorTextStyle: AppTextStyles.caption.copyWith(
          color: Colors.white,
        ),
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.primary;
          }
          return AppColors.backgroundTertiary;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.primary.withOpacity(0.5);
          }
          return AppColors.border;
        }),
      ),

      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.primary;
          }
          return Colors.transparent;
        }),
        checkColor: MaterialStateProperty.all(Colors.white),
        side: const BorderSide(color: AppColors.border, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.borderRadiusXs,
        ),
      ),

      // Radio Theme
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.primary;
          }
          return AppColors.border;
        }),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      // Extensions
      extensions: [_lightChatTheme, _lightMediaTheme],
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: useMaterial3,
      brightness: Brightness.dark,
      colorScheme: AppColors.darkColorScheme,

      // Primary Swatch
      primarySwatch: AppColors.createMaterialColor(AppColors.primary),
      primaryColor: AppColors.primary,
      primaryColorLight: AppColors.primaryLight,
      primaryColorDark: AppColors.primaryDark,

      // Background Colors
      scaffoldBackgroundColor: AppColors.backgroundDark,
      canvasColor: AppColors.backgroundDark,
      cardColor: AppColors.surfaceDark,
      dialogBackgroundColor: AppColors.surfaceDark,

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.textPrimaryDark,
        elevation: AppDimensions.elevationSm,
        shadowColor: AppColors.shadowDark,
        centerTitle: false,
        titleTextStyle: AppTextStyles.titleLarge.copyWith(
          color: AppColors.textPrimaryDark,
          fontWeight: AppTextStyles.semiBold,
        ),
        toolbarTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textPrimaryDark,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.iconPrimaryDark,
          size: AppDimensions.iconLg,
        ),
        actionsIconTheme: const IconThemeData(
          color: AppColors.iconPrimaryDark,
          size: AppDimensions.iconLg,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
        surfaceTintColor: AppColors.surfaceDark,
      ),

      // Text Theme
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge.copyWith(
          color: AppColors.textPrimaryDark,
        ),
        displayMedium: AppTextStyles.displayMedium.copyWith(
          color: AppColors.textPrimaryDark,
        ),
        displaySmall: AppTextStyles.displaySmall.copyWith(
          color: AppColors.textPrimaryDark,
        ),
        headlineLarge: AppTextStyles.headlineLarge.copyWith(
          color: AppColors.textPrimaryDark,
        ),
        headlineMedium: AppTextStyles.headlineMedium.copyWith(
          color: AppColors.textPrimaryDark,
        ),
        headlineSmall: AppTextStyles.headlineSmall.copyWith(
          color: AppColors.textPrimaryDark,
        ),
        titleLarge: AppTextStyles.titleLarge.copyWith(
          color: AppColors.textPrimaryDark,
        ),
        titleMedium: AppTextStyles.titleMedium.copyWith(
          color: AppColors.textPrimaryDark,
        ),
        titleSmall: AppTextStyles.titleSmall.copyWith(
          color: AppColors.textPrimaryDark,
        ),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(
          color: AppColors.textPrimaryDark,
        ),
        bodyMedium: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textPrimaryDark,
        ),
        bodySmall: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textSecondaryDark,
        ),
        labelLarge: AppTextStyles.labelLarge.copyWith(
          color: AppColors.textPrimaryDark,
        ),
        labelMedium: AppTextStyles.labelMedium.copyWith(
          color: AppColors.textSecondaryDark,
        ),
        labelSmall: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textSecondaryDark,
        ),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: AppColors.iconPrimaryDark,
        size: AppDimensions.iconLg,
      ),

      // Primary Icon Theme
      primaryIconTheme: const IconThemeData(
        color: Colors.white,
        size: AppDimensions.iconLg,
      ),

      // Button Themes (similar to light but with dark adaptations)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: AppDimensions.elevationSm,
          shadowColor: AppColors.shadowDark,
          shape: RoundedRectangleBorder(
            borderRadius: AppDimensions.borderRadiusLg,
          ),
          padding: AppDimensions.buttonPaddingMd,
          minimumSize: const Size(0, AppDimensions.buttonHeightMd),
          textStyle: AppTextStyles.buttonMedium,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.borderDark, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: AppDimensions.borderRadiusLg,
          ),
          padding: AppDimensions.buttonPaddingMd,
          minimumSize: const Size(0, AppDimensions.buttonHeightMd),
          textStyle: AppTextStyles.buttonMedium,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: AppDimensions.borderRadiusLg,
          ),
          padding: AppDimensions.buttonPaddingMd,
          minimumSize: const Size(0, AppDimensions.buttonHeightMd),
          textStyle: AppTextStyles.buttonMedium,
        ),
      ),

      // Icon Button Theme
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.iconPrimaryDark,
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: AppDimensions.borderRadiusMd,
          ),
          padding: const EdgeInsets.all(AppDimensions.spacingSm),
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: AppDimensions.elevationSm,
        shadowColor: AppColors.shadowDark,
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.borderRadiusLg,
        ),
        margin: AppDimensions.marginSm,
      ),

      // List Tile Theme
      listTileTheme: ListTileThemeData(
        tileColor: AppColors.surfaceDark,
        selectedTileColor: AppColors.selectedDark,
        iconColor: AppColors.iconSecondaryDark,
        textColor: AppColors.textPrimaryDark,
        titleTextStyle: AppTextStyles.bodyLarge.copyWith(
          color: AppColors.textPrimaryDark,
        ),
        subtitleTextStyle: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textSecondaryDark,
        ),
        contentPadding: AppDimensions.paddingHorizontalMd,
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.borderRadiusMd,
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.backgroundSecondaryDark,
        border: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusLg,
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusLg,
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusLg,
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusLg,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppDimensions.borderRadiusLg,
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle: AppTextStyles.inputLabel.copyWith(
          color: AppColors.textSecondaryDark,
        ),
        hintStyle: AppTextStyles.inputHint.copyWith(
          color: AppColors.textHintDark,
        ),
        errorStyle: AppTextStyles.inputError,
        contentPadding: AppDimensions.paddingMd,
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceDark,
        elevation: AppDimensions.elevationXl,
        modalBackgroundColor: AppColors.surfaceDark,
        modalElevation: AppDimensions.elevationXl,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimensions.radius2xl),
          ),
        ),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.dividerDark,
        thickness: 1,
        space: 1,
      ),

      // Extensions
      extensions: [_darkChatTheme, _darkMediaTheme],
    );
  }

  // Custom Theme Extensions
  static final ChatThemeExtension _lightChatTheme = ChatThemeExtension(
    messageBubbleOwnColor: AppColors.messageBubbleOwn,
    messageBubbleOtherColor: AppColors.messageBubbleOther,
    messageBubbleSystemColor: AppColors.messageBubbleSystem,
    messageTextOwnColor: Colors.white,
    messageTextOtherColor: AppColors.textPrimary,
    messageTimestampOwnColor: Colors.white.withOpacity(0.7),
    messageTimestampOtherColor: AppColors.textSecondary,
    chatBackgroundColor: AppColors.background,
    typingIndicatorColor: AppColors.typingIndicator,
    onlineIndicatorColor: AppColors.onlineIndicator,
    unreadBadgeColor: AppColors.unreadBadge,
  );

  static final ChatThemeExtension _darkChatTheme = ChatThemeExtension(
    messageBubbleOwnColor: AppColors.messageBubbleOwnDark,
    messageBubbleOtherColor: AppColors.messageBubbleOtherDark,
    messageBubbleSystemColor: AppColors.messageBubbleSystemDark,
    messageTextOwnColor: Colors.white,
    messageTextOtherColor: AppColors.textPrimaryDark,
    messageTimestampOwnColor: Colors.white.withOpacity(0.7),
    messageTimestampOtherColor: AppColors.textSecondaryDark,
    chatBackgroundColor: AppColors.backgroundDark,
    typingIndicatorColor: AppColors.typingIndicator,
    onlineIndicatorColor: AppColors.onlineIndicator,
    unreadBadgeColor: AppColors.unreadBadge,
  );

  static final MediaThemeExtension _lightMediaTheme = MediaThemeExtension(
    mediaOverlayColor: AppColors.mediaOverlay,
    mediaControlsBackgroundColor: AppColors.mediaControlsBackground,
    mediaProgressBackgroundColor: AppColors.mediaProgressBackground,
    mediaProgressForegroundColor: AppColors.mediaProgressForeground,
    waveformActiveColor: AppColors.waveformActive,
    waveformInactiveColor: AppColors.waveformInactive,
    videoControlsBackgroundColor: AppColors.videoControlsBackground,
    videoControlsTextColor: AppColors.videoControlsText,
    documentIconPdfColor: AppColors.documentIconPdf,
    documentIconWordColor: AppColors.documentIconWord,
    documentIconExcelColor: AppColors.documentIconExcel,
    locationPinColor: AppColors.locationPinColor,
  );

  static final MediaThemeExtension _darkMediaTheme = MediaThemeExtension(
    mediaOverlayColor: AppColors.mediaOverlay,
    mediaControlsBackgroundColor: AppColors.mediaControlsBackground,
    mediaProgressBackgroundColor: AppColors.mediaProgressBackground,
    mediaProgressForegroundColor: AppColors.mediaProgressForeground,
    waveformActiveColor: AppColors.waveformActiveDark,
    waveformInactiveColor: AppColors.waveformInactiveDark,
    videoControlsBackgroundColor: AppColors.videoControlsBackground,
    videoControlsTextColor: AppColors.videoControlsText,
    documentIconPdfColor: AppColors.documentIconPdf,
    documentIconWordColor: AppColors.documentIconWord,
    documentIconExcelColor: AppColors.documentIconExcel,
    locationPinColor: AppColors.locationPinColor,
  );

  // Utility Methods
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static ChatThemeExtension chatTheme(BuildContext context) {
    return Theme.of(context).extension<ChatThemeExtension>()!;
  }

  static MediaThemeExtension mediaTheme(BuildContext context) {
    return Theme.of(context).extension<MediaThemeExtension>()!;
  }

  static ThemeData getTheme(Brightness brightness) {
    return brightness == Brightness.dark ? darkTheme : lightTheme;
  }

  static SystemUiOverlayStyle getSystemUiOverlayStyle(Brightness brightness) {
    return brightness == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;
  }

  // Responsive Theme Methods
  static ThemeData responsiveTheme(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final baseTheme = Theme.of(context);

    if (AppDimensions.isXs(screenWidth)) {
      return baseTheme.copyWith(
        textTheme: _scaleTextTheme(baseTheme.textTheme, 0.9),
      );
    }

    return baseTheme;
  }

  static TextTheme _scaleTextTheme(TextTheme textTheme, double scaleFactor) {
    return TextTheme(
      displayLarge: textTheme.displayLarge?.copyWith(
        fontSize: (textTheme.displayLarge?.fontSize ?? 57) * scaleFactor,
      ),
      displayMedium: textTheme.displayMedium?.copyWith(
        fontSize: (textTheme.displayMedium?.fontSize ?? 45) * scaleFactor,
      ),
      displaySmall: textTheme.displaySmall?.copyWith(
        fontSize: (textTheme.displaySmall?.fontSize ?? 36) * scaleFactor,
      ),
      headlineLarge: textTheme.headlineLarge?.copyWith(
        fontSize: (textTheme.headlineLarge?.fontSize ?? 32) * scaleFactor,
      ),
      headlineMedium: textTheme.headlineMedium?.copyWith(
        fontSize: (textTheme.headlineMedium?.fontSize ?? 28) * scaleFactor,
      ),
      headlineSmall: textTheme.headlineSmall?.copyWith(
        fontSize: (textTheme.headlineSmall?.fontSize ?? 24) * scaleFactor,
      ),
      titleLarge: textTheme.titleLarge?.copyWith(
        fontSize: (textTheme.titleLarge?.fontSize ?? 22) * scaleFactor,
      ),
      titleMedium: textTheme.titleMedium?.copyWith(
        fontSize: (textTheme.titleMedium?.fontSize ?? 16) * scaleFactor,
      ),
      titleSmall: textTheme.titleSmall?.copyWith(
        fontSize: (textTheme.titleSmall?.fontSize ?? 14) * scaleFactor,
      ),
      bodyLarge: textTheme.bodyLarge?.copyWith(
        fontSize: (textTheme.bodyLarge?.fontSize ?? 16) * scaleFactor,
      ),
      bodyMedium: textTheme.bodyMedium?.copyWith(
        fontSize: (textTheme.bodyMedium?.fontSize ?? 14) * scaleFactor,
      ),
      bodySmall: textTheme.bodySmall?.copyWith(
        fontSize: (textTheme.bodySmall?.fontSize ?? 12) * scaleFactor,
      ),
      labelLarge: textTheme.labelLarge?.copyWith(
        fontSize: (textTheme.labelLarge?.fontSize ?? 14) * scaleFactor,
      ),
      labelMedium: textTheme.labelMedium?.copyWith(
        fontSize: (textTheme.labelMedium?.fontSize ?? 12) * scaleFactor,
      ),
      labelSmall: textTheme.labelSmall?.copyWith(
        fontSize: (textTheme.labelSmall?.fontSize ?? 11) * scaleFactor,
      ),
    );
  }
}

// Custom Theme Extensions
class ChatThemeExtension extends ThemeExtension<ChatThemeExtension> {
  final Color messageBubbleOwnColor;
  final Color messageBubbleOtherColor;
  final Color messageBubbleSystemColor;
  final Color messageTextOwnColor;
  final Color messageTextOtherColor;
  final Color messageTimestampOwnColor;
  final Color messageTimestampOtherColor;
  final Color chatBackgroundColor;
  final Color typingIndicatorColor;
  final Color onlineIndicatorColor;
  final Color unreadBadgeColor;

  const ChatThemeExtension({
    required this.messageBubbleOwnColor,
    required this.messageBubbleOtherColor,
    required this.messageBubbleSystemColor,
    required this.messageTextOwnColor,
    required this.messageTextOtherColor,
    required this.messageTimestampOwnColor,
    required this.messageTimestampOtherColor,
    required this.chatBackgroundColor,
    required this.typingIndicatorColor,
    required this.onlineIndicatorColor,
    required this.unreadBadgeColor,
  });

  @override
  ChatThemeExtension copyWith({
    Color? messageBubbleOwnColor,
    Color? messageBubbleOtherColor,
    Color? messageBubbleSystemColor,
    Color? messageTextOwnColor,
    Color? messageTextOtherColor,
    Color? messageTimestampOwnColor,
    Color? messageTimestampOtherColor,
    Color? chatBackgroundColor,
    Color? typingIndicatorColor,
    Color? onlineIndicatorColor,
    Color? unreadBadgeColor,
  }) {
    return ChatThemeExtension(
      messageBubbleOwnColor:
          messageBubbleOwnColor ?? this.messageBubbleOwnColor,
      messageBubbleOtherColor:
          messageBubbleOtherColor ?? this.messageBubbleOtherColor,
      messageBubbleSystemColor:
          messageBubbleSystemColor ?? this.messageBubbleSystemColor,
      messageTextOwnColor: messageTextOwnColor ?? this.messageTextOwnColor,
      messageTextOtherColor:
          messageTextOtherColor ?? this.messageTextOtherColor,
      messageTimestampOwnColor:
          messageTimestampOwnColor ?? this.messageTimestampOwnColor,
      messageTimestampOtherColor:
          messageTimestampOtherColor ?? this.messageTimestampOtherColor,
      chatBackgroundColor: chatBackgroundColor ?? this.chatBackgroundColor,
      typingIndicatorColor: typingIndicatorColor ?? this.typingIndicatorColor,
      onlineIndicatorColor: onlineIndicatorColor ?? this.onlineIndicatorColor,
      unreadBadgeColor: unreadBadgeColor ?? this.unreadBadgeColor,
    );
  }

  @override
  ChatThemeExtension lerp(ThemeExtension<ChatThemeExtension>? other, double t) {
    if (other is! ChatThemeExtension) {
      return this;
    }
    return ChatThemeExtension(
      messageBubbleOwnColor: Color.lerp(
        messageBubbleOwnColor,
        other.messageBubbleOwnColor,
        t,
      )!,
      messageBubbleOtherColor: Color.lerp(
        messageBubbleOtherColor,
        other.messageBubbleOtherColor,
        t,
      )!,
      messageBubbleSystemColor: Color.lerp(
        messageBubbleSystemColor,
        other.messageBubbleSystemColor,
        t,
      )!,
      messageTextOwnColor: Color.lerp(
        messageTextOwnColor,
        other.messageTextOwnColor,
        t,
      )!,
      messageTextOtherColor: Color.lerp(
        messageTextOtherColor,
        other.messageTextOtherColor,
        t,
      )!,
      messageTimestampOwnColor: Color.lerp(
        messageTimestampOwnColor,
        other.messageTimestampOwnColor,
        t,
      )!,
      messageTimestampOtherColor: Color.lerp(
        messageTimestampOtherColor,
        other.messageTimestampOtherColor,
        t,
      )!,
      chatBackgroundColor: Color.lerp(
        chatBackgroundColor,
        other.chatBackgroundColor,
        t,
      )!,
      typingIndicatorColor: Color.lerp(
        typingIndicatorColor,
        other.typingIndicatorColor,
        t,
      )!,
      onlineIndicatorColor: Color.lerp(
        onlineIndicatorColor,
        other.onlineIndicatorColor,
        t,
      )!,
      unreadBadgeColor: Color.lerp(
        unreadBadgeColor,
        other.unreadBadgeColor,
        t,
      )!,
    );
  }
}

class MediaThemeExtension extends ThemeExtension<MediaThemeExtension> {
  final Color mediaOverlayColor;
  final Color mediaControlsBackgroundColor;
  final Color mediaProgressBackgroundColor;
  final Color mediaProgressForegroundColor;
  final Color waveformActiveColor;
  final Color waveformInactiveColor;
  final Color videoControlsBackgroundColor;
  final Color videoControlsTextColor;
  final Color documentIconPdfColor;
  final Color documentIconWordColor;
  final Color documentIconExcelColor;
  final Color locationPinColor;

  const MediaThemeExtension({
    required this.mediaOverlayColor,
    required this.mediaControlsBackgroundColor,
    required this.mediaProgressBackgroundColor,
    required this.mediaProgressForegroundColor,
    required this.waveformActiveColor,
    required this.waveformInactiveColor,
    required this.videoControlsBackgroundColor,
    required this.videoControlsTextColor,
    required this.documentIconPdfColor,
    required this.documentIconWordColor,
    required this.documentIconExcelColor,
    required this.locationPinColor,
  });

  @override
  MediaThemeExtension copyWith({
    Color? mediaOverlayColor,
    Color? mediaControlsBackgroundColor,
    Color? mediaProgressBackgroundColor,
    Color? mediaProgressForegroundColor,
    Color? waveformActiveColor,
    Color? waveformInactiveColor,
    Color? videoControlsBackgroundColor,
    Color? videoControlsTextColor,
    Color? documentIconPdfColor,
    Color? documentIconWordColor,
    Color? documentIconExcelColor,
    Color? locationPinColor,
  }) {
    return MediaThemeExtension(
      mediaOverlayColor: mediaOverlayColor ?? this.mediaOverlayColor,
      mediaControlsBackgroundColor:
          mediaControlsBackgroundColor ?? this.mediaControlsBackgroundColor,
      mediaProgressBackgroundColor:
          mediaProgressBackgroundColor ?? this.mediaProgressBackgroundColor,
      mediaProgressForegroundColor:
          mediaProgressForegroundColor ?? this.mediaProgressForegroundColor,
      waveformActiveColor: waveformActiveColor ?? this.waveformActiveColor,
      waveformInactiveColor:
          waveformInactiveColor ?? this.waveformInactiveColor,
      videoControlsBackgroundColor:
          videoControlsBackgroundColor ?? this.videoControlsBackgroundColor,
      videoControlsTextColor:
          videoControlsTextColor ?? this.videoControlsTextColor,
      documentIconPdfColor: documentIconPdfColor ?? this.documentIconPdfColor,
      documentIconWordColor:
          documentIconWordColor ?? this.documentIconWordColor,
      documentIconExcelColor:
          documentIconExcelColor ?? this.documentIconExcelColor,
      locationPinColor: locationPinColor ?? this.locationPinColor,
    );
  }

  @override
  MediaThemeExtension lerp(
    ThemeExtension<MediaThemeExtension>? other,
    double t,
  ) {
    if (other is! MediaThemeExtension) {
      return this;
    }
    return MediaThemeExtension(
      mediaOverlayColor: Color.lerp(
        mediaOverlayColor,
        other.mediaOverlayColor,
        t,
      )!,
      mediaControlsBackgroundColor: Color.lerp(
        mediaControlsBackgroundColor,
        other.mediaControlsBackgroundColor,
        t,
      )!,
      mediaProgressBackgroundColor: Color.lerp(
        mediaProgressBackgroundColor,
        other.mediaProgressBackgroundColor,
        t,
      )!,
      mediaProgressForegroundColor: Color.lerp(
        mediaProgressForegroundColor,
        other.mediaProgressForegroundColor,
        t,
      )!,
      waveformActiveColor: Color.lerp(
        waveformActiveColor,
        other.waveformActiveColor,
        t,
      )!,
      waveformInactiveColor: Color.lerp(
        waveformInactiveColor,
        other.waveformInactiveColor,
        t,
      )!,
      videoControlsBackgroundColor: Color.lerp(
        videoControlsBackgroundColor,
        other.videoControlsBackgroundColor,
        t,
      )!,
      videoControlsTextColor: Color.lerp(
        videoControlsTextColor,
        other.videoControlsTextColor,
        t,
      )!,
      documentIconPdfColor: Color.lerp(
        documentIconPdfColor,
        other.documentIconPdfColor,
        t,
      )!,
      documentIconWordColor: Color.lerp(
        documentIconWordColor,
        other.documentIconWordColor,
        t,
      )!,
      documentIconExcelColor: Color.lerp(
        documentIconExcelColor,
        other.documentIconExcelColor,
        t,
      )!,
      locationPinColor: Color.lerp(
        locationPinColor,
        other.locationPinColor,
        t,
      )!,
    );
  }
}
