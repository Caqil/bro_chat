import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

extension BuildContextExtensions on BuildContext {
  // Theme access
  ThemeData get theme => Theme.of(this);
  ShadThemeData get shadTheme => ShadTheme.of(this);
  ColorScheme get colorScheme => theme.colorScheme;
  TextTheme get textTheme => theme.textTheme;

  // Media query shortcuts
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => mediaQuery.size;
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;
  EdgeInsets get padding => mediaQuery.padding;
  EdgeInsets get viewInsets => mediaQuery.viewInsets;
  EdgeInsets get viewPadding => mediaQuery.viewPadding;
  double get devicePixelRatio => mediaQuery.devicePixelRatio;
  Brightness get platformBrightness => mediaQuery.platformBrightness;

  // Screen size categories
  bool get isSmallScreen => screenWidth < 600;
  bool get isMediumScreen => screenWidth >= 600 && screenWidth < 1200;
  bool get isLargeScreen => screenWidth >= 1200;
  bool get isMobile => screenWidth < 768;
  bool get isTablet => screenWidth >= 768 && screenWidth < 1024;
  bool get isDesktop => screenWidth >= 1024;

  // Orientation
  Orientation get orientation => mediaQuery.orientation;
  bool get isPortrait => orientation == Orientation.portrait;
  bool get isLandscape => orientation == Orientation.landscape;

  // Safe area
  double get topPadding => padding.top;
  double get bottomPadding => padding.bottom;
  double get leftPadding => padding.left;
  double get rightPadding => padding.right;

  // Keyboard
  bool get isKeyboardVisible => viewInsets.bottom > 0;
  double get keyboardHeight => viewInsets.bottom;

  // Accessibility
  bool get isAccessibilityModeEnabled => mediaQuery.accessibleNavigation;
  bool get isBoldTextEnabled => mediaQuery.boldText;
  double get textScaleFactor => mediaQuery.textScaleFactor;

  // Navigation
  NavigatorState get navigator => Navigator.of(this);
  ModalRoute? get modalRoute => ModalRoute.of(this);

  // Navigation actions
  void pop<T>([T? result]) => navigator.pop(result);

  Future<T?> push<T>(Route<T> route) => navigator.push(route);

  Future<T?> pushNamed<T>(String routeName, {Object? arguments}) =>
      navigator.pushNamed(routeName, arguments: arguments);

  Future<T?> pushReplacementNamed<T, TO>(
    String routeName, {
    Object? arguments,
  }) => navigator.pushReplacementNamed(routeName, arguments: arguments);

  Future<T?> pushNamedAndRemoveUntil<T>(
    String routeName,
    bool Function(Route<dynamic>) predicate, {
    Object? arguments,
  }) => navigator.pushNamedAndRemoveUntil(
    routeName,
    predicate,
    arguments: arguments,
  );

  void popUntil(bool Function(Route<dynamic>) predicate) =>
      navigator.popUntil(predicate);

  bool canPop() => navigator.canPop();

  void maybePop<T>([T? result]) => navigator.maybePop(result);

  // Scaffold
  ScaffoldState? get scaffold => Scaffold.maybeOf(this);
  ScaffoldMessengerState get scaffoldMessenger => ScaffoldMessenger.of(this);

  // Snackbars and toasts using shadcn_ui
  void showSnackBar(
    String message, {
    ShadToastVariant variant = ShadToastVariant.primary,
    Duration duration = const Duration(seconds: 4),
    String? title,
    Widget? action,
  }) {
    ShadToaster.of(this).show(
      ShadToast.raw(
        title: title != null ? Text(title) : null,
        description: Text(message),
        variant: variant,
        action: action,
      ),
    );
  }

  void showSuccessToast(String message, {String? title}) {
    showSnackBar(
      message,
      title: title ?? 'Success',
      variant: ShadToastVariant.primary,
    );
  }

  void showErrorToast(String message, {String? title}) {
    showSnackBar(
      message,
      title: title ?? 'Error',
      variant: ShadToastVariant.destructive,
    );
  }

  void showWarningToast(String message, {String? title}) {
    showSnackBar(
      message,
      title: title ?? 'Warning',
      variant: ShadToastVariant.primary,
    );
  }

  void showInfoToast(String message, {String? title}) {
    showSnackBar(
      message,
      title: title ?? 'Info',
      variant: ShadToastVariant.primary,
    );
  }

  // Dialogs using shadcn_ui
  Future<T?> showCustomDialog<T>({
    required Widget child,
    bool barrierDismissible = true,
    Color? barrierColor,
    String? barrierLabel,
  }) {
    return showDialog<T>(
      context: this,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      barrierLabel: barrierLabel,
      builder: (context) => child,
    );
  }

  Future<bool?> showConfirmDialog({
    required String title,
    required String content,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDestructive = false,
  }) {
    return showCustomDialog<bool>(
      child: ShadDialog(
        title: Text(title),
        description: Text(content),
        actions: [
          ShadButton.outline(
            onPressed: () => pop(false),
            child: Text(cancelText),
          ),
          ShadButton(onPressed: () => pop(true), child: Text(confirmText)),
        ],
      ),
    );
  }

  Future<String?> showInputDialog({
    required String title,
    String? hint,
    String? initialValue,
    String confirmText = 'OK',
    String cancelText = 'Cancel',
    TextInputType keyboardType = TextInputType.text,
    int? maxLines = 1,
  }) {
    final controller = TextEditingController(text: initialValue);

    return showCustomDialog<String>(
      child: ShadDialog(
        title: Text(title),
        actions: [
          ShadButton.outline(
            onPressed: () => pop(null),
            child: Text(cancelText),
          ),
          ShadButton(
            onPressed: () => pop(controller.text),
            child: Text(confirmText),
          ),
        ],
        child: ShadInput(
          controller: controller,
          placeholder: Text(hint ?? ""),
          keyboardType: keyboardType,
          maxLines: maxLines,
        ),
      ),
    );
  }

  // Bottom sheets
  Future<T?> showCustomBottomSheet<T>({
    required Widget child,
    bool isDismissible = true,
    bool enableDrag = true,
    double? height,
    bool isScrollControlled = false,
  }) {
    return showModalBottomSheet<T>(
      context: this,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: height,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: child,
      ),
    );
  }

  // Focus management
  FocusNode? get primaryFocus => FocusScope.of(this).focusedChild;

  void unfocus() {
    final currentFocus = FocusScope.of(this);
    if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      currentFocus.focusedChild!.unfocus();
    }
  }

  void requestFocus(FocusNode focusNode) {
    FocusScope.of(this).requestFocus(focusNode);
  }

  // Haptic feedback
  void lightHaptic() => HapticFeedback.lightImpact();
  void mediumHaptic() => HapticFeedback.mediumImpact();
  void heavyHaptic() => HapticFeedback.heavyImpact();
  void selectionHaptic() => HapticFeedback.selectionClick();
  void vibrate() => HapticFeedback.vibrate();

  // Clipboard
  Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    showSuccessToast('Copied to clipboard');
  }

  Future<String?> getFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    return data?.text;
  }

  // Form validation
  FormState? get form => Form.maybeOf(this);

  bool validateForm() {
    final formState = form;
    if (formState != null) {
      return formState.validate();
    }
    return false;
  }

  void saveForm() {
    form?.save();
  }

  void resetForm() {
    form?.reset();
  }

  // Date and time formatting
  String formatDateTime(DateTime dateTime) {
    return MaterialLocalizations.of(this).formatShortDate(dateTime);
  }

  String formatTime(TimeOfDay time) {
    return MaterialLocalizations.of(this).formatTimeOfDay(time);
  }

  // RTL support
  TextDirection get textDirection => Directionality.of(this);
  bool get isRTL => textDirection == TextDirection.rtl;
  bool get isLTR => textDirection == TextDirection.ltr;

  // App lifecycle
  AppLifecycleState? get appLifecycleState =>
      WidgetsBinding.instance.lifecycleState;

  // Utility methods
  void hideKeyboard() => FocusScope.of(this).unfocus();

  double get statusBarHeight => padding.top;
  double get bottomBarHeight => padding.bottom;

  // Responsive breakpoints
  T responsive<T>({required T mobile, T? tablet, T? desktop}) {
    if (isDesktop && desktop != null) return desktop;
    if (isTablet && tablet != null) return tablet;
    return mobile;
  }

  // Dynamic sizing
  double dynamicWidth(double percentage) => screenWidth * percentage;
  double dynamicHeight(double percentage) => screenHeight * percentage;

  // Safe area calculations
  double get safeAreaTop => padding.top;
  double get safeAreaBottom => padding.bottom;
  double get safeAreaLeft => padding.left;
  double get safeAreaRight => padding.right;

  double get availableHeight => screenHeight - safeAreaTop - safeAreaBottom;
  double get availableWidth => screenWidth - safeAreaLeft - safeAreaRight;

  // Animation duration based on accessibility
  Duration get animationDuration {
    return mediaQuery.disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 300);
  }

  // Dark mode detection
  bool get isDarkMode => platformBrightness == Brightness.dark;
  bool get isLightMode => platformBrightness == Brightness.light;

  // Network connectivity context
  bool get isOnline {
    // This would typically be connected to a connectivity provider
    // For now, return true as default
    return true;
  }

  // User preferences context
  bool get reduceMotion => mediaQuery.disableAnimations;
  bool get highContrast => mediaQuery.highContrast;
  bool get boldText => mediaQuery.boldText;

  // Quick access to common measurements
  double get appBarHeight => kToolbarHeight;
  double get bottomNavHeight => kBottomNavigationBarHeight;
  double get defaultPadding => 16.0;
  double get defaultMargin => 16.0;
  double get defaultRadius => 8.0;

  // Color helpers
  Color get primaryColor => colorScheme.primary;
  Color get surfaceColor => colorScheme.surface;
  Color get backgroundColor => colorScheme.background;
  Color get errorColor => colorScheme.error;
  Color get onPrimaryColor => colorScheme.onPrimary;
  Color get onSurfaceColor => colorScheme.onSurface;
  Color get onBackgroundColor => colorScheme.onBackground;
  Color get onErrorColor => colorScheme.onError;

  // Text style helpers
  TextStyle? get headlineLarge => textTheme.headlineLarge;
  TextStyle? get headlineMedium => textTheme.headlineMedium;
  TextStyle? get headlineSmall => textTheme.headlineSmall;
  TextStyle? get titleLarge => textTheme.titleLarge;
  TextStyle? get titleMedium => textTheme.titleMedium;
  TextStyle? get titleSmall => textTheme.titleSmall;
  TextStyle? get bodyLarge => textTheme.bodyLarge;
  TextStyle? get bodyMedium => textTheme.bodyMedium;
  TextStyle? get bodySmall => textTheme.bodySmall;
  TextStyle? get labelLarge => textTheme.labelLarge;
  TextStyle? get labelMedium => textTheme.labelMedium;
  TextStyle? get labelSmall => textTheme.labelSmall;
}
