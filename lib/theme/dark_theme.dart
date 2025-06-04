import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'colors.dart';
import 'text_styles.dart';
import 'dimensions.dart';
import 'custom_theme_extensions.dart';

class DarkTheme {
  static ShadThemeData get theme => ShadThemeData(
    brightness: Brightness.dark,
    colorScheme: const ShadSlateColorScheme.dark(),
    primaryColor: AppColors.primary,
    backgroundColor: AppColors.backgroundDark,
    cardTheme: ShadCardTheme(
      backgroundColor: AppColors.cardDark,
      foregroundColor: AppColors.cardForegroundDark,
      border: ShadBorder.all(color: AppColors.borderDark, width: 1),
      radius: BorderRadius.circular(AppDimensions.radiusLG),
      shadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    buttonTheme: ShadButtonTheme(
      decoration: ShadDecoration(
        border: ShadBorder.all(color: AppColors.borderDark, width: 1),
      ),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return AppColors.mutedForegroundDark;
        }
        return AppColors.foregroundDark;
      }),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered)) {
          return AppColors.mutedDark;
        }
        if (states.contains(WidgetState.disabled)) {
          return AppColors.mutedDark;
        }
        return AppColors.backgroundDark;
      }),
    ),
    inputTheme: ShadInputTheme(
      style: AppTextStyles.inputText.copyWith(color: AppColors.foregroundDark),
      decoration: ShadDecoration(
        border: ShadBorder.all(color: AppColors.borderDark, width: 1),
        focusedBorder: ShadBorder.all(color: AppColors.ringDark, width: 2),
      ),
      placeholderStyle: AppTextStyles.inputText.copyWith(
        color: AppColors.mutedForegroundDark,
      ),
    ),
    selectTheme: const ShadSelectTheme(),
    dialogTheme: ShadDialogTheme(
      backgroundColor: AppColors.backgroundDark,
      radius: BorderRadius.circular(AppDimensions.radiusLG),
      shadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    alertDialogTheme: ShadAlertDialogTheme(
      backgroundColor: AppColors.backgroundDark,
      radius: BorderRadius.circular(AppDimensions.radiusLG),
    ),
    sheetTheme: ShadSheetTheme(
      backgroundColor: AppColors.backgroundDark,
      radius: BorderRadius.circular(AppDimensions.radiusLG),
    ),
    toastTheme: ShadToastTheme(
      actionBackgroundColor: AppColors.primary,
      actionForegroundColor: AppColors.primaryForeground,
      backgroundColor: AppColors.backgroundDark,
      foregroundColor: AppColors.foregroundDark,
      border: ShadBorder.all(color: AppColors.borderDark, width: 1),
      radius: BorderRadius.circular(AppDimensions.radiusMD),
      shadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    tooltipTheme: ShadTooltipTheme(
      backgroundColor: AppColors.foregroundDark,
      foregroundColor: AppColors.backgroundDark,
      radius: BorderRadius.circular(AppDimensions.radiusSM),
    ),
    popoverTheme: ShadPopoverTheme(
      backgroundColor: AppColors.popoverDark,
      foregroundColor: AppColors.popoverForegroundDark,
      border: ShadBorder.all(color: AppColors.borderDark, width: 1),
      radius: BorderRadius.circular(AppDimensions.radiusMD),
      shadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    badgeTheme: ShadBadgeTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.primaryForeground,
      shape: const StadiumBorder(),
    ),
    avatarTheme: ShadAvatarTheme(
      backgroundColor: AppColors.mutedDark,
      foregroundColor: AppColors.mutedForegroundDark,
      radius: BorderRadius.circular(AppDimensions.radiusFull),
    ),
    switchTheme: ShadSwitchTheme(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primaryForeground;
        }
        return AppColors.backgroundDark;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primary;
        }
        return AppColors.inputDark;
      }),
    ),
    checkboxTheme: ShadCheckboxTheme(
      color: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primary;
        }
        return AppColors.borderDark;
      }),
    ),
    radioTheme: ShadRadioTheme(
      color: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primary;
        }
        return AppColors.borderDark;
      }),
    ),
    progressTheme: const ShadProgressTheme(
      color: AppColors.primary,
      backgroundColor: AppColors.secondary,
    ),
    textTheme: ShadTextTheme(
      family: AppTextStyles._baseTextStyle.fontFamily!,
      h1Large: AppTextStyles.displayLarge.copyWith(
        color: AppColors.foregroundDark,
      ),
      h1: AppTextStyles.displayMedium.copyWith(color: AppColors.foregroundDark),
      h2: AppTextStyles.headlineLarge.copyWith(color: AppColors.foregroundDark),
      h3: AppTextStyles.headlineMedium.copyWith(
        color: AppColors.foregroundDark,
      ),
      h4: AppTextStyles.titleLarge.copyWith(color: AppColors.foregroundDark),
      p: AppTextStyles.bodyMedium.copyWith(color: AppColors.foregroundDark),
      blockquote: AppTextStyles.bodyLarge.copyWith(
        fontStyle: FontStyle.italic,
        color: AppColors.foregroundDark,
      ),
      table: AppTextStyles.bodySmall.copyWith(color: AppColors.foregroundDark),
      list: AppTextStyles.bodyMedium.copyWith(color: AppColors.foregroundDark),
      lead: AppTextStyles.bodyLarge.copyWith(color: AppColors.foregroundDark),
      large: AppTextStyles.titleMedium.copyWith(
        color: AppColors.foregroundDark,
      ),
      small: AppTextStyles.bodySmall.copyWith(color: AppColors.foregroundDark),
      muted: AppTextStyles.bodySmall.copyWith(
        color: AppColors.mutedForegroundDark,
      ),
    ),
    extensions: [
      ChatThemeExtension.dark(),
      CallThemeExtension.dark(),
      StatusThemeExtension.dark(),
    ],
  );
}
