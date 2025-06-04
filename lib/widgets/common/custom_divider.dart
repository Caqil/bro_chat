import 'package:flutter/material.dart';

enum DividerType { horizontal, vertical }

enum DividerVariant { solid, dashed, dotted }

class CustomDivider extends StatelessWidget {
  final DividerType type;
  final DividerVariant variant;
  final double? thickness;
  final double? indent;
  final double? endIndent;
  final Color? color;
  final double? height;
  final double? width;
  final String? label;
  final TextStyle? labelStyle;
  final EdgeInsets? labelPadding;

  const CustomDivider({
    super.key,
    this.type = DividerType.horizontal,
    this.variant = DividerVariant.solid,
    this.thickness,
    this.indent,
    this.endIndent,
    this.color,
    this.height,
    this.width,
    this.label,
    this.labelStyle,
    this.labelPadding,
  });

  factory CustomDivider.horizontal({
    Key? key,
    DividerVariant variant = DividerVariant.solid,
    double? thickness,
    double? indent,
    double? endIndent,
    Color? color,
    double? height,
    String? label,
    TextStyle? labelStyle,
    EdgeInsets? labelPadding,
  }) {
    return CustomDivider(
      key: key,
      type: DividerType.horizontal,
      variant: variant,
      thickness: thickness,
      indent: indent,
      endIndent: endIndent,
      color: color,
      height: height,
      label: label,
      labelStyle: labelStyle,
      labelPadding: labelPadding,
    );
  }

  factory CustomDivider.vertical({
    Key? key,
    DividerVariant variant = DividerVariant.solid,
    double? thickness,
    double? indent,
    double? endIndent,
    Color? color,
    double? width,
  }) {
    return CustomDivider(
      key: key,
      type: DividerType.vertical,
      variant: variant,
      thickness: thickness,
      indent: indent,
      endIndent: endIndent,
      color: color,
      width: width,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dividerColor = color ?? Theme.of(context).dividerColor;
    final dividerThickness = thickness ?? 1.0;

    if (label != null && type == DividerType.horizontal) {
      return _buildLabeledDivider(context, dividerColor, dividerThickness);
    }

    if (type == DividerType.vertical) {
      return _buildVerticalDivider(dividerColor, dividerThickness);
    }

    return _buildHorizontalDivider(dividerColor, dividerThickness);
  }

  Widget _buildHorizontalDivider(Color dividerColor, double dividerThickness) {
    if (variant == DividerVariant.solid) {
      return Divider(
        thickness: dividerThickness,
        indent: indent,
        endIndent: endIndent,
        color: dividerColor,
        height: height,
      );
    }

    return Container(
      height: height ?? 16,
      margin: EdgeInsets.only(left: indent ?? 0, right: endIndent ?? 0),
      child: Center(
        child: CustomPaint(
          painter: _DividerPainter(
            color: dividerColor,
            thickness: dividerThickness,
            variant: variant,
            isVertical: false,
          ),
          size: Size(double.infinity, dividerThickness),
        ),
      ),
    );
  }

  Widget _buildVerticalDivider(Color dividerColor, double dividerThickness) {
    if (variant == DividerVariant.solid) {
      return VerticalDivider(
        thickness: dividerThickness,
        indent: indent,
        endIndent: endIndent,
        color: dividerColor,
        width: width,
      );
    }

    return Container(
      width: width ?? 16,
      margin: EdgeInsets.only(top: indent ?? 0, bottom: endIndent ?? 0),
      child: Center(
        child: CustomPaint(
          painter: _DividerPainter(
            color: dividerColor,
            thickness: dividerThickness,
            variant: variant,
            isVertical: true,
          ),
          size: Size(dividerThickness, double.infinity),
        ),
      ),
    );
  }

  Widget _buildLabeledDivider(
    BuildContext context,
    Color dividerColor,
    double dividerThickness,
  ) {
    final effectiveLabelStyle =
        labelStyle ??
        Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.grey[600],
          fontWeight: FontWeight.w500,
        );

    final effectiveLabelPadding =
        labelPadding ?? const EdgeInsets.symmetric(horizontal: 16);

    return Container(
      height: height ?? 24,
      child: Row(
        children: [
          Expanded(
            child: _buildHorizontalDivider(dividerColor, dividerThickness),
          ),
          Padding(
            padding: effectiveLabelPadding,
            child: Text(label!, style: effectiveLabelStyle),
          ),
          Expanded(
            child: _buildHorizontalDivider(dividerColor, dividerThickness),
          ),
        ],
      ),
    );
  }
}

// Custom painter for dashed and dotted dividers
class _DividerPainter extends CustomPainter {
  final Color color;
  final double thickness;
  final DividerVariant variant;
  final bool isVertical;

  _DividerPainter({
    required this.color,
    required this.thickness,
    required this.variant,
    required this.isVertical,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;

    if (variant == DividerVariant.dashed) {
      _drawDashedLine(canvas, size, paint);
    } else if (variant == DividerVariant.dotted) {
      _drawDottedLine(canvas, size, paint);
    }
  }

  void _drawDashedLine(Canvas canvas, Size size, Paint paint) {
    const dashWidth = 5.0;
    const dashSpace = 3.0;
    double distance = 0;

    if (isVertical) {
      final startY = 0.0;
      final endY = size.height;
      final x = size.width / 2;

      while (distance < endY) {
        canvas.drawLine(
          Offset(x, distance),
          Offset(x, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    } else {
      final startX = 0.0;
      final endX = size.width;
      final y = size.height / 2;

      while (distance < endX) {
        canvas.drawLine(
          Offset(distance, y),
          Offset(distance + dashWidth, y),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  void _drawDottedLine(Canvas canvas, Size size, Paint paint) {
    const dotRadius = 1.0;
    const dotSpace = 4.0;
    double distance = 0;

    if (isVertical) {
      final x = size.width / 2;
      final endY = size.height;

      while (distance < endY) {
        canvas.drawCircle(Offset(x, distance), dotRadius, paint);
        distance += dotSpace;
      }
    } else {
      final y = size.height / 2;
      final endX = size.width;

      while (distance < endX) {
        canvas.drawCircle(Offset(distance, y), dotRadius, paint);
        distance += dotSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Section divider with icon and label
class SectionDivider extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final Color? backgroundColor;
  final TextStyle? textStyle;
  final EdgeInsets? padding;
  final EdgeInsets? margin;

  const SectionDivider({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.backgroundColor,
    this.textStyle,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Colors.grey[600];
    final effectiveTextStyle =
        textStyle ??
        Theme.of(context).textTheme.bodySmall?.copyWith(
          color: effectiveColor,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        );

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: effectiveColor?.withOpacity(0.3))),
          Container(
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
            decoration: backgroundColor != null
                ? BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  )
                : null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: effectiveColor),
                  const SizedBox(width: 6),
                ],
                Text(label.toUpperCase(), style: effectiveTextStyle),
              ],
            ),
          ),
          Expanded(child: Divider(color: effectiveColor?.withOpacity(0.3))),
        ],
      ),
    );
  }
}

// OR divider
class OrDivider extends StatelessWidget {
  final String text;
  final Color? lineColor;
  final Color? textColor;
  final Color? backgroundColor;
  final TextStyle? textStyle;
  final double? height;

  const OrDivider({
    super.key,
    this.text = 'OR',
    this.lineColor,
    this.textColor,
    this.backgroundColor,
    this.textStyle,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveLineColor = lineColor ?? Colors.grey[300];
    final effectiveTextColor = textColor ?? Colors.grey[600];
    final effectiveBackgroundColor = backgroundColor ?? Colors.white;

    return Container(
      height: height ?? 24,
      child: Row(
        children: [
          Expanded(child: Divider(color: effectiveLineColor, thickness: 1)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: effectiveBackgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: effectiveLineColor!),
            ),
            child: Text(
              text,
              style:
                  textStyle ??
                  TextStyle(
                    color: effectiveTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          Expanded(child: Divider(color: effectiveLineColor, thickness: 1)),
        ],
      ),
    );
  }
}

// Time divider for chat messages
class TimeDivider extends StatelessWidget {
  final String time;
  final Color? backgroundColor;
  final Color? textColor;
  final TextStyle? textStyle;
  final EdgeInsets? padding;
  final EdgeInsets? margin;

  const TimeDivider({
    super.key,
    required this.time,
    this.backgroundColor,
    this.textColor,
    this.textStyle,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 8),
      alignment: Alignment.center,
      child: Container(
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          time,
          style:
              textStyle ??
              TextStyle(
                color: textColor ?? Colors.grey[700],
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
        ),
      ),
    );
  }
}

// Gradient divider
class GradientDivider extends StatelessWidget {
  final DividerType type;
  final Gradient gradient;
  final double? thickness;
  final double? height;
  final double? width;
  final EdgeInsets? margin;

  const GradientDivider({
    super.key,
    this.type = DividerType.horizontal,
    required this.gradient,
    this.thickness,
    this.height,
    this.width,
    this.margin,
  });

  factory GradientDivider.rainbow({
    Key? key,
    DividerType type = DividerType.horizontal,
    double? thickness,
    double? height,
    double? width,
    EdgeInsets? margin,
  }) {
    return GradientDivider(
      key: key,
      type: type,
      gradient: const LinearGradient(
        colors: [
          Colors.red,
          Colors.orange,
          Colors.yellow,
          Colors.green,
          Colors.blue,
          Colors.indigo,
          Colors.purple,
        ],
      ),
      thickness: thickness,
      height: height,
      width: width,
      margin: margin,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (type == DividerType.vertical) {
      return Container(
        width: width ?? 16,
        margin: margin,
        child: Center(
          child: Container(
            width: thickness ?? 2,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular((thickness ?? 2) / 2),
            ),
          ),
        ),
      );
    }

    return Container(
      height: height ?? 16,
      margin: margin,
      child: Center(
        child: Container(
          width: double.infinity,
          height: thickness ?? 2,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular((thickness ?? 2) / 2),
          ),
        ),
      ),
    );
  }
}

// Animated divider
class AnimatedDivider extends StatefulWidget {
  final DividerType type;
  final Color? color;
  final double? thickness;
  final double? height;
  final double? width;
  final Duration duration;
  final bool animate;

  const AnimatedDivider({
    super.key,
    this.type = DividerType.horizontal,
    this.color,
    this.thickness,
    this.height,
    this.width,
    this.duration = const Duration(milliseconds: 500),
    this.animate = true,
  });

  @override
  State<AnimatedDivider> createState() => _AnimatedDividerState();
}

class _AnimatedDividerState extends State<AnimatedDivider>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.animate) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(AnimatedDivider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dividerColor = widget.color ?? Theme.of(context).dividerColor;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        if (widget.type == DividerType.vertical) {
          return Container(
            width: widget.width ?? 16,
            child: Center(
              child: Container(
                width: widget.thickness ?? 1,
                height: double.infinity,
                transform: Matrix4.identity()..scale(1.0, _animation.value),
                transformAlignment: Alignment.center,
                decoration: BoxDecoration(
                  color: dividerColor,
                  borderRadius: BorderRadius.circular(
                    (widget.thickness ?? 1) / 2,
                  ),
                ),
              ),
            ),
          );
        }

        return Container(
          height: widget.height ?? 16,
          child: Center(
            child: Container(
              width: double.infinity,
              height: widget.thickness ?? 1,
              transform: Matrix4.identity()..scale(_animation.value, 1.0),
              transformAlignment: Alignment.center,
              decoration: BoxDecoration(
                color: dividerColor,
                borderRadius: BorderRadius.circular(
                  (widget.thickness ?? 1) / 2,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
