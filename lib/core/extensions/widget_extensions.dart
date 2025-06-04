import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

extension WidgetExtensions on Widget {
  // Padding extensions
  Widget paddingAll(double value) =>
      Padding(padding: EdgeInsets.all(value), child: this);

  Widget paddingSymmetric({double horizontal = 0, double vertical = 0}) =>
      Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontal,
          vertical: vertical,
        ),
        child: this,
      );

  Widget paddingOnly({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) => Padding(
    padding: EdgeInsets.only(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
    ),
    child: this,
  );

  Widget get paddingXS => paddingAll(4);
  Widget get paddingSM => paddingAll(8);
  Widget get paddingMD => paddingAll(16);
  Widget get paddingLG => paddingAll(24);
  Widget get paddingXL => paddingAll(32);

  Widget get paddingHorizontalXS => paddingSymmetric(horizontal: 4);
  Widget get paddingHorizontalSM => paddingSymmetric(horizontal: 8);
  Widget get paddingHorizontalMD => paddingSymmetric(horizontal: 16);
  Widget get paddingHorizontalLG => paddingSymmetric(horizontal: 24);
  Widget get paddingHorizontalXL => paddingSymmetric(horizontal: 32);

  Widget get paddingVerticalXS => paddingSymmetric(vertical: 4);
  Widget get paddingVerticalSM => paddingSymmetric(vertical: 8);
  Widget get paddingVerticalMD => paddingSymmetric(vertical: 16);
  Widget get paddingVerticalLG => paddingSymmetric(vertical: 24);
  Widget get paddingVerticalXL => paddingSymmetric(vertical: 32);

  // Margin extensions
  Widget marginAll(double value) =>
      Container(margin: EdgeInsets.all(value), child: this);

  Widget marginSymmetric({double horizontal = 0, double vertical = 0}) =>
      Container(
        margin: EdgeInsets.symmetric(
          horizontal: horizontal,
          vertical: vertical,
        ),
        child: this,
      );

  Widget marginOnly({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) => Container(
    margin: EdgeInsets.only(left: left, top: top, right: right, bottom: bottom),
    child: this,
  );

  Widget get marginXS => marginAll(4);
  Widget get marginSM => marginAll(8);
  Widget get marginMD => marginAll(16);
  Widget get marginLG => marginAll(24);
  Widget get marginXL => marginAll(32);

  // Alignment extensions
  Widget get center => Center(child: this);
  Widget get centerLeft => Align(alignment: Alignment.centerLeft, child: this);
  Widget get centerRight =>
      Align(alignment: Alignment.centerRight, child: this);
  Widget get topCenter => Align(alignment: Alignment.topCenter, child: this);
  Widget get topLeft => Align(alignment: Alignment.topLeft, child: this);
  Widget get topRight => Align(alignment: Alignment.topRight, child: this);
  Widget get bottomCenter =>
      Align(alignment: Alignment.bottomCenter, child: this);
  Widget get bottomLeft => Align(alignment: Alignment.bottomLeft, child: this);
  Widget get bottomRight =>
      Align(alignment: Alignment.bottomRight, child: this);

  Widget align(Alignment alignment) => Align(alignment: alignment, child: this);

  // Flexible and Expanded
  Widget get expanded => Expanded(child: this);
  Widget expandedFlex(int flex) => Expanded(flex: flex, child: this);
  Widget get flexible => Flexible(child: this);
  Widget flexibleFlex(int flex) => Flexible(flex: flex, child: this);

  // Sized Box
  Widget sized({double? width, double? height}) =>
      SizedBox(width: width, height: height, child: this);

  Widget sizedBox(double size) =>
      SizedBox(width: size, height: size, child: this);

  Widget width(double width) => SizedBox(width: width, child: this);
  Widget height(double height) => SizedBox(height: height, child: this);

  // Container decorations
  Widget decorated({
    Color? color,
    DecorationImage? image,
    Border? border,
    BorderRadius? borderRadius,
    List<BoxShadow>? boxShadow,
    Gradient? gradient,
    BlendMode? backgroundBlendMode,
    BoxShape shape = BoxShape.rectangle,
  }) => Container(
    decoration: BoxDecoration(
      color: color,
      image: image,
      border: border,
      borderRadius: borderRadius,
      boxShadow: boxShadow,
      gradient: gradient,
      backgroundBlendMode: backgroundBlendMode,
      shape: shape,
    ),
    child: this,
  );

  Widget bordered({
    Color color = Colors.grey,
    double width = 1.0,
    BorderRadius? borderRadius,
  }) => decorated(
    border: Border.all(color: color, width: width),
    borderRadius: borderRadius,
  );

  Widget rounded(double radius) =>
      decorated(borderRadius: BorderRadius.circular(radius));

  Widget get roundedSM => rounded(4);
  Widget get roundedMD => rounded(8);
  Widget get roundedLG => rounded(12);
  Widget get roundedXL => rounded(16);
  Widget get roundedFull => decorated(shape: BoxShape.circle);

  Widget withShadow({
    Color color = Colors.black26,
    double blurRadius = 4,
    Offset offset = const Offset(0, 2),
  }) => decorated(
    boxShadow: [
      BoxShadow(color: color, blurRadius: blurRadius, offset: offset),
    ],
  );

  Widget backgroundColor(Color color) => decorated(color: color);

  Widget withGradient(Gradient gradient) => decorated(gradient: gradient);

  // Visibility and conditional rendering
  Widget visible(bool isVisible) => Visibility(visible: isVisible, child: this);

  Widget visibleOrGone(bool isVisible) => Visibility(
    visible: isVisible,
    maintainSize: false,
    maintainAnimation: false,
    maintainState: false,
    child: this,
  );

  Widget opacity(double opacity) => Opacity(opacity: opacity, child: this);
  Widget get semiTransparent => opacity(0.5);
  Widget get almostTransparent => opacity(0.1);

  Widget conditional(bool condition, Widget Function(Widget) builder) =>
      condition ? builder(this) : this;

  // Gesture detection
  Widget onTap(VoidCallback? onTap, {bool showSplash = true}) => showSplash
      ? InkWell(onTap: onTap, child: this)
      : GestureDetector(onTap: onTap, child: this);

  Widget onLongPress(VoidCallback? onLongPress) =>
      GestureDetector(onLongPress: onLongPress, child: this);

  Widget onDoubleTap(VoidCallback? onDoubleTap) =>
      GestureDetector(onDoubleTap: onDoubleTap, child: this);

  Widget onPanUpdate(Function(DragUpdateDetails)? onPanUpdate) =>
      GestureDetector(onPanUpdate: onPanUpdate, child: this);

  Widget onSwipe({
    VoidCallback? onSwipeLeft,
    VoidCallback? onSwipeRight,
    VoidCallback? onSwipeUp,
    VoidCallback? onSwipeDown,
  }) => GestureDetector(
    onHorizontalDragEnd: (details) {
      if (details.primaryVelocity! > 0) {
        onSwipeRight?.call();
      } else if (details.primaryVelocity! < 0) {
        onSwipeLeft?.call();
      }
    },
    onVerticalDragEnd: (details) {
      if (details.primaryVelocity! > 0) {
        onSwipeDown?.call();
      } else if (details.primaryVelocity! < 0) {
        onSwipeUp?.call();
      }
    },
    child: this,
  );

  // Interactive feedback
  Widget withHapticFeedback({
    HapticFeedback type = HapticFeedback.lightImpact,
  }) => GestureDetector(
    onTap: () {
      switch (type) {
        case HapticFeedback.lightImpact:
          HapticFeedback.lightImpact;
          break;
        case HapticFeedback.mediumImpact:
          HapticFeedback.mediumImpact;
          break;
        case HapticFeedback.heavyImpact:
          HapticFeedback.heavyImpact;
          break;
        case HapticFeedback.selectionClick:
          HapticFeedback.selectionClick;
          break;
        case HapticFeedback.vibrate:
          HapticFeedback.vibrate;
          break;
      }
    },
    child: this,
  );

  // Safe area
  Widget get safeArea => SafeArea(child: this);
  Widget safeAreaOnly({
    bool left = true,
    bool top = true,
    bool right = true,
    bool bottom = true,
  }) =>
      SafeArea(left: left, top: top, right: right, bottom: bottom, child: this);

  // Scrollable
  Widget get scrollable => SingleChildScrollView(child: this);
  Widget scrollableHorizontal() =>
      SingleChildScrollView(scrollDirection: Axis.horizontal, child: this);

  Widget scrollableVertical() =>
      SingleChildScrollView(scrollDirection: Axis.vertical, child: this);

  Widget scrollPhysics(ScrollPhysics physics) =>
      SingleChildScrollView(physics: physics, child: this);

  Widget get alwaysScrollable =>
      scrollPhysics(const AlwaysScrollableScrollPhysics());
  Widget get neverScrollable =>
      scrollPhysics(const NeverScrollableScrollPhysics());
  Widget get bouncingScrollable => scrollPhysics(const BouncingScrollPhysics());

  // Slivers
  Widget get sliverToBoxAdapter => SliverToBoxAdapter(child: this);
  Widget get sliverFillRemaining => SliverFillRemaining(child: this);

  // ClipRRect
  Widget clipRRect(double radius) =>
      ClipRRect(borderRadius: BorderRadius.circular(radius), child: this);

  Widget get clipRRectSM => clipRRect(4);
  Widget get clipRRectMD => clipRRect(8);
  Widget get clipRRectLG => clipRRect(12);
  Widget get clipRRectXL => clipRRect(16);

  Widget clipPath(CustomClipper<Path> clipper) =>
      ClipPath(clipper: clipper, child: this);

  Widget get clipOval => ClipOval(child: this);

  // Transform
  Widget scale(double scale) => Transform.scale(scale: scale, child: this);
  Widget rotate(double angle) => Transform.rotate(angle: angle, child: this);
  Widget translate({double x = 0, double y = 0}) =>
      Transform.translate(offset: Offset(x, y), child: this);

  // Positioned (for Stack)
  Widget positioned({
    double? left,
    double? top,
    double? right,
    double? bottom,
    double? width,
    double? height,
  }) => Positioned(
    left: left,
    top: top,
    right: right,
    bottom: bottom,
    width: width,
    height: height,
    child: this,
  );

  Widget get positionedFill => Positioned.fill(child: this);

  // Animation extensions
  Widget fadeIn({
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeIn,
  }) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0.0, end: 1.0),
    duration: duration,
    curve: curve,
    builder: (context, value, child) => Opacity(opacity: value, child: this),
  );

  Widget slideIn({
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOut,
    Offset begin = const Offset(0, 1),
  }) => TweenAnimationBuilder<Offset>(
    tween: Tween(begin: begin, end: Offset.zero),
    duration: duration,
    curve: curve,
    builder: (context, value, child) =>
        Transform.translate(offset: value, child: this),
  );

  Widget scaleIn({
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.elasticOut,
  }) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0.0, end: 1.0),
    duration: duration,
    curve: curve,
    builder: (context, value, child) =>
        Transform.scale(scale: value, child: this),
  );

  // Hero animation
  Widget hero(Object tag) => Hero(tag: tag, child: this);

  // Material design components
  Widget card({
    Color? color,
    double? elevation,
    ShapeBorder? shape,
    EdgeInsetsGeometry? margin,
    bool borderOnForeground = true,
  }) => Card(
    color: color,
    elevation: elevation,
    shape: shape,
    margin: margin,
    borderOnForeground: borderOnForeground,
    child: this,
  );

  Widget inkWell({
    VoidCallback? onTap,
    VoidCallback? onDoubleTap,
    VoidCallback? onLongPress,
    Color? splashColor,
    Color? highlightColor,
    BorderRadius? borderRadius,
  }) => InkWell(
    onTap: onTap,
    onDoubleTap: onDoubleTap,
    onLongPress: onLongPress,
    splashColor: splashColor,
    highlightColor: highlightColor,
    borderRadius: borderRadius,
    child: this,
  );

  Widget material({
    MaterialType type = MaterialType.canvas,
    double elevation = 0.0,
    Color? color,
    Color? shadowColor,
    TextStyle? textStyle,
    BorderRadius? borderRadius,
    ShapeBorder? shape,
    bool borderOnForeground = true,
    Clip clipBehavior = Clip.none,
  }) => Material(
    type: type,
    elevation: elevation,
    color: color,
    shadowColor: shadowColor,
    textStyle: textStyle,
    borderRadius: borderRadius,
    shape: shape,
    borderOnForeground: borderOnForeground,
    clipBehavior: clipBehavior,
    child: this,
  );

  // Shimmer loading effect
  Widget shimmer({
    Color baseColor = const Color(0xFFE0E0E0),
    Color highlightColor = const Color(0xFFF5F5F5),
    Duration period = const Duration(milliseconds: 1500),
  }) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0.0, end: 1.0),
    duration: period,
    builder: (context, value, child) => Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [baseColor, highlightColor, baseColor],
          stops: [
            (value - 0.3).clamp(0.0, 1.0),
            value,
            (value + 0.3).clamp(0.0, 1.0),
          ],
        ),
      ),
      child: this,
    ),
  );

  // Loading states
  Widget loading({bool isLoading = true}) => Stack(
    children: [
      if (!isLoading) this,
      if (isLoading) const Center(child: ShadProgress()),
    ],
  );

  Widget loadingOverlay({bool isLoading = true}) => Stack(
    children: [
      this,
      if (isLoading)
        Container(
          color: Colors.black54,
          child: const Center(child: ShadProgress()),
        ),
    ],
  );

  // Tooltip
  Widget tooltip(String message) => Tooltip(message: message, child: this);

  // Badge
  Widget badge({
    required String label,
    Color? backgroundColor,
    Color? textColor,
    double? size,
    Alignment alignment = Alignment.topRight,
  }) => Stack(
    clipBehavior: Clip.none,
    children: [
      this,
      Positioned(
        top: alignment == Alignment.topRight || alignment == Alignment.topLeft
            ? -8
            : null,
        right:
            alignment == Alignment.topRight ||
                alignment == Alignment.bottomRight
            ? -8
            : null,
        bottom:
            alignment == Alignment.bottomRight ||
                alignment == Alignment.bottomLeft
            ? -8
            : null,
        left:
            alignment == Alignment.topLeft || alignment == Alignment.bottomLeft
            ? -8
            : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: textColor ?? Colors.white,
              fontSize: size ?? 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    ],
  );

  // Custom shapes
  Widget circle({Color? color, double? size}) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    child: this,
  );

  // Responsive
  Widget responsive({Widget? mobile, Widget? tablet, Widget? desktop}) =>
      LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 1024 && desktop != null) {
            return desktop;
          } else if (constraints.maxWidth >= 768 && tablet != null) {
            return tablet;
          } else if (mobile != null) {
            return mobile;
          }
          return this;
        },
      );

  // Theme-aware
  Widget themeAware({Widget Function(BuildContext, ThemeData)? builder}) =>
      Builder(
        builder: (context) {
          final theme = Theme.of(context);
          return builder?.call(context, theme) ?? this;
        },
      );

  // Dismissible
  Widget dismissible({
    required Key key,
    VoidCallback? onDismissed,
    DismissDirection direction = DismissDirection.horizontal,
    Widget? background,
    Widget? secondaryBackground,
  }) => Dismissible(
    key: key,
    onDismissed: (direction) => onDismissed?.call(),
    direction: direction,
    background: background,
    secondaryBackground: secondaryBackground,
    child: this,
  );

  // Custom paint
  Widget customPaint({
    CustomPainter? painter,
    CustomPainter? foregroundPainter,
    Size size = Size.zero,
    bool isComplex = false,
    bool willChange = false,
  }) => CustomPaint(
    painter: painter,
    foregroundPainter: foregroundPainter,
    size: size,
    isComplex: isComplex,
    willChange: willChange,
    child: this,
  );
}

// Enum for haptic feedback types
enum HapticFeedback {
  lightImpact,
  mediumImpact,
  heavyImpact,
  selectionClick,
  vibrate,
}

// Helper function for spacing
Widget gap(double size) => SizedBox(width: size, height: size);
Widget gapH(double width) => SizedBox(width: width);
Widget gapV(double height) => SizedBox(height: height);

// Common spacers
Widget get gapXS => gap(4);
Widget get gapSM => gap(8);
Widget get gapMD => gap(16);
Widget get gapLG => gap(24);
Widget get gapXL => gap(32);

Widget get gapHXS => gapH(4);
Widget get gapHSM => gapH(8);
Widget get gapHMD => gapH(16);
Widget get gapHLG => gapH(24);
Widget get gapHXL => gapH(32);

Widget get gapVXS => gapV(4);
Widget get gapVSM => gapV(8);
Widget get gapVMD => gapV(16);
Widget get gapVLG => gapV(24);
Widget get gapVXL => gapV(32);
