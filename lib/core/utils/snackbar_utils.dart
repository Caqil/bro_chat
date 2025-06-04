import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum SnackbarType { success, error, warning, info, loading }

class SnackbarUtils {
  static final Map<BuildContext, ScaffoldMessengerState?> _messengerCache = {};

  /// Show a success snackbar
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onActionPressed,
    bool showCloseIcon = true,
  }) {
    _showSnackbar(
      context,
      message,
      type: SnackbarType.success,
      duration: duration,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
      showCloseIcon: showCloseIcon,
    );
  }

  /// Show an error snackbar
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 6),
    String? actionLabel,
    VoidCallback? onActionPressed,
    bool showCloseIcon = true,
  }) {
    _showSnackbar(
      context,
      message,
      type: SnackbarType.error,
      duration: duration,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
      showCloseIcon: showCloseIcon,
    );
  }

  /// Show a warning snackbar
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 5),
    String? actionLabel,
    VoidCallback? onActionPressed,
    bool showCloseIcon = true,
  }) {
    _showSnackbar(
      context,
      message,
      type: SnackbarType.warning,
      duration: duration,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
      showCloseIcon: showCloseIcon,
    );
  }

  /// Show an info snackbar
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onActionPressed,
    bool showCloseIcon = true,
  }) {
    _showSnackbar(
      context,
      message,
      type: SnackbarType.info,
      duration: duration,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
      showCloseIcon: showCloseIcon,
    );
  }

  /// Show a loading snackbar
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showLoading(
    BuildContext context,
    String message, {
    bool isDismissible = false,
  }) {
    return _showSnackbar(
      context,
      message,
      type: SnackbarType.loading,
      duration: const Duration(days: 1), // Long duration for loading
      showCloseIcon: isDismissible,
      isDismissible: isDismissible,
    );
  }

  /// Show a custom snackbar
  static void showCustom(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    Color? textColor,
    IconData? icon,
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onActionPressed,
    bool showCloseIcon = true,
  }) {
    _showCustomSnackbar(
      context,
      message,
      backgroundColor: backgroundColor,
      textColor: textColor,
      icon: icon,
      duration: duration,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
      showCloseIcon: showCloseIcon,
    );
  }

  /// Hide current snackbar
  static void hide(BuildContext context) {
    try {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    } catch (e) {
      // Handle if no scaffold messenger is available
    }
  }

  /// Clear all snackbars
  static void clearAll(BuildContext context) {
    try {
      ScaffoldMessenger.of(context).clearSnackBars();
    } catch (e) {
      // Handle if no scaffold messenger is available
    }
  }

  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason>
  _showSnackbar(
    BuildContext context,
    String message, {
    required SnackbarType type,
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onActionPressed,
    bool showCloseIcon = true,
    bool isDismissible = true,
  }) {
    final theme = Theme.of(context);
    final config = _getSnackbarConfig(type, theme);

    // Add haptic feedback
    _triggerHapticFeedback(type);

    final snackBar = SnackBar(
      content: _buildSnackbarContent(
        message,
        config.icon,
        config.textColor,
        type == SnackbarType.loading,
      ),
      backgroundColor: config.backgroundColor,
      duration: duration,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      dismissDirection: isDismissible
          ? DismissDirection.horizontal
          : DismissDirection.none,
      action: _buildSnackbarAction(
        actionLabel,
        onActionPressed,
        showCloseIcon,
        config.textColor,
        context,
      ),
      elevation: 6,
      clipBehavior: Clip.antiAlias,
    );

    return ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason>
  _showCustomSnackbar(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    Color? textColor,
    IconData? icon,
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onActionPressed,
    bool showCloseIcon = true,
  }) {
    final theme = Theme.of(context);
    final effectiveBackgroundColor =
        backgroundColor ?? theme.colorScheme.surface;
    final effectiveTextColor = textColor ?? theme.colorScheme.onSurface;

    final snackBar = SnackBar(
      content: _buildSnackbarContent(message, icon, effectiveTextColor, false),
      backgroundColor: effectiveBackgroundColor,
      duration: duration,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      action: _buildSnackbarAction(
        actionLabel,
        onActionPressed,
        showCloseIcon,
        effectiveTextColor,
        context,
      ),
      elevation: 6,
      clipBehavior: Clip.antiAlias,
    );

    return ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  static Widget _buildSnackbarContent(
    String message,
    IconData? icon,
    Color textColor,
    bool isLoading,
  ) {
    return Row(
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(textColor),
            ),
          ),
          const SizedBox(width: 12),
        ] else if (icon != null) ...[
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  static SnackBarAction? _buildSnackbarAction(
    String? actionLabel,
    VoidCallback? onActionPressed,
    bool showCloseIcon,
    Color textColor,
    BuildContext context,
  ) {
    if (actionLabel != null && onActionPressed != null) {
      return SnackBarAction(
        label: actionLabel,
        textColor: textColor,
        onPressed: onActionPressed,
      );
    } else if (showCloseIcon) {
      return SnackBarAction(
        label: '',
        onPressed: () => hide(context),
        textColor: textColor,
        backgroundColor: Colors.transparent,
        disabledTextColor: Colors.transparent,
      );
    }
    return null;
  }

  static _SnackbarConfig _getSnackbarConfig(
    SnackbarType type,
    ThemeData theme,
  ) {
    switch (type) {
      case SnackbarType.success:
        return _SnackbarConfig(
          backgroundColor: const Color(0xFF16A34A),
          textColor: Colors.white,
          icon: Icons.check_circle_outline,
        );

      case SnackbarType.error:
        return _SnackbarConfig(
          backgroundColor: const Color(0xFFDC2626),
          textColor: Colors.white,
          icon: Icons.error_outline,
        );

      case SnackbarType.warning:
        return _SnackbarConfig(
          backgroundColor: const Color(0xFFEA580C),
          textColor: Colors.white,
          icon: Icons.warning_amber_outlined,
        );

      case SnackbarType.info:
        return _SnackbarConfig(
          backgroundColor: const Color(0xFF2563EB),
          textColor: Colors.white,
          icon: Icons.info_outline,
        );

      case SnackbarType.loading:
        return _SnackbarConfig(
          backgroundColor: theme.colorScheme.surface,
          textColor: theme.colorScheme.onSurface,
          icon: null, // Loading spinner will be shown instead
        );
    }
  }

  static void _triggerHapticFeedback(SnackbarType type) {
    switch (type) {
      case SnackbarType.success:
        HapticFeedback.lightImpact();
        break;
      case SnackbarType.error:
        HapticFeedback.heavyImpact();
        break;
      case SnackbarType.warning:
        HapticFeedback.mediumImpact();
        break;
      case SnackbarType.info:
        HapticFeedback.selectionClick();
        break;
      case SnackbarType.loading:
        // No haptic feedback for loading
        break;
    }
  }
}

class _SnackbarConfig {
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  const _SnackbarConfig({
    required this.backgroundColor,
    required this.textColor,
    this.icon,
  });
}

/// Extension methods for easier access
extension SnackbarContextExtension on BuildContext {
  void showSuccessSnackbar(String message) {
    SnackbarUtils.showSuccess(this, message);
  }

  void showErrorSnackbar(String message) {
    SnackbarUtils.showError(this, message);
  }

  void showWarningSnackbar(String message) {
    SnackbarUtils.showWarning(this, message);
  }

  void showInfoSnackbar(String message) {
    SnackbarUtils.showInfo(this, message);
  }

  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showLoadingSnackbar(
    String message,
  ) {
    return SnackbarUtils.showLoading(this, message);
  }

  void hideSnackbar() {
    SnackbarUtils.hide(this);
  }

  void clearAllSnackbars() {
    SnackbarUtils.clearAll(this);
  }
}
