import 'package:flutter/material.dart';

enum BadgeSize { small, medium, large }

enum BadgeVariant { filled, outlined, soft }

enum BadgePosition { topRight, topLeft, bottomRight, bottomLeft }

class CustomBadge extends StatelessWidget {
  final String? text;
  final Widget? child;
  final Color? color;
  final Color? textColor;
  final Color? borderColor;
  final BadgeSize size;
  final BadgeVariant variant;
  final bool showBadge;
  final int? count;
  final int maxCount;
  final VoidCallback? onTap;

  const CustomBadge({
    super.key,
    this.text,
    this.child,
    this.color,
    this.textColor,
    this.borderColor,
    this.size = BadgeSize.medium,
    this.variant = BadgeVariant.filled,
    this.showBadge = true,
    this.count,
    this.maxCount = 99,
    this.onTap,
  });

  factory CustomBadge.count({
    Key? key,
    required int count,
    Widget? child,
    Color? color,
    Color? textColor,
    BadgeSize size = BadgeSize.medium,
    BadgeVariant variant = BadgeVariant.filled,
    int maxCount = 99,
    VoidCallback? onTap,
  }) {
    return CustomBadge(
      key: key,
      count: count,
      child: child,
      color: color,
      textColor: textColor,
      size: size,
      variant: variant,
      showBadge: count > 0,
      maxCount: maxCount,
      onTap: onTap,
    );
  }

  factory CustomBadge.dot({
    Key? key,
    Widget? child,
    Color? color,
    BadgeSize size = BadgeSize.small,
    VoidCallback? onTap,
  }) {
    return CustomBadge(
      key: key,
      child: child,
      color: color,
      size: size,
      variant: BadgeVariant.filled,
      showBadge: true,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!showBadge) {
      return child ?? const SizedBox.shrink();
    }

    final badgeWidget = GestureDetector(
      onTap: onTap,
      child: Container(
        padding: _getPadding(),
        decoration: _getDecoration(context),
        constraints: _getConstraints(),
        child: _buildContent(context),
      ),
    );

    if (child == null) {
      return badgeWidget;
    }

    return badgeWidget;
  }

  EdgeInsets _getPadding() {
    if (text == null && count == null) {
      // Dot badge
      return EdgeInsets.zero;
    }

    switch (size) {
      case BadgeSize.small:
        return const EdgeInsets.symmetric(horizontal: 4, vertical: 2);
      case BadgeSize.medium:
        return const EdgeInsets.symmetric(horizontal: 6, vertical: 3);
      case BadgeSize.large:
        return const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
    }
  }

  BoxDecoration _getDecoration(BuildContext context) {
    final badgeColor = color ?? Theme.of(context).primaryColor;
    final effectiveTextColor =
        textColor ??
        (variant == BadgeVariant.filled ? Colors.white : badgeColor);

    switch (variant) {
      case BadgeVariant.filled:
        return BoxDecoration(
          color: badgeColor,
          borderRadius: BorderRadius.circular(_getBorderRadius()),
        );
      case BadgeVariant.outlined:
        return BoxDecoration(
          color: Colors.transparent,
          border: Border.all(color: borderColor ?? badgeColor, width: 1),
          borderRadius: BorderRadius.circular(_getBorderRadius()),
        );
      case BadgeVariant.soft:
        return BoxDecoration(
          color: badgeColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(_getBorderRadius()),
        );
    }
  }

  double _getBorderRadius() {
    if (text == null && count == null) {
      // Dot badge - circular
      return 50;
    }

    switch (size) {
      case BadgeSize.small:
        return 8;
      case BadgeSize.medium:
        return 10;
      case BadgeSize.large:
        return 12;
    }
  }

  BoxConstraints _getConstraints() {
    if (text == null && count == null) {
      // Dot badge
      switch (size) {
        case BadgeSize.small:
          return const BoxConstraints(minWidth: 8, minHeight: 8);
        case BadgeSize.medium:
          return const BoxConstraints(minWidth: 12, minHeight: 12);
        case BadgeSize.large:
          return const BoxConstraints(minWidth: 16, minHeight: 16);
      }
    }

    switch (size) {
      case BadgeSize.small:
        return const BoxConstraints(minWidth: 16, minHeight: 16);
      case BadgeSize.medium:
        return const BoxConstraints(minWidth: 20, minHeight: 20);
      case BadgeSize.large:
        return const BoxConstraints(minWidth: 24, minHeight: 24);
    }
  }

  Widget? _buildContent(BuildContext context) {
    if (text == null && count == null) {
      // Dot badge - no content
      return null;
    }

    final badgeColor = color ?? Theme.of(context).primaryColor;
    final effectiveTextColor =
        textColor ??
        (variant == BadgeVariant.filled ? Colors.white : badgeColor);

    String displayText;
    if (count != null) {
      displayText = count! > maxCount ? '$maxCount+' : count.toString();
    } else {
      displayText = text!;
    }

    return Text(
      displayText,
      style: TextStyle(
        color: effectiveTextColor,
        fontSize: _getFontSize(),
        fontWeight: FontWeight.w600,
      ),
      textAlign: TextAlign.center,
    );
  }

  double _getFontSize() {
    switch (size) {
      case BadgeSize.small:
        return 10;
      case BadgeSize.medium:
        return 12;
      case BadgeSize.large:
        return 14;
    }
  }
}

// Positioned badge wrapper
class PositionedBadge extends StatelessWidget {
  final Widget child;
  final CustomBadge badge;
  final BadgePosition position;
  final double? top;
  final double? right;
  final double? bottom;
  final double? left;

  const PositionedBadge({
    super.key,
    required this.child,
    required this.badge,
    this.position = BadgePosition.topRight,
    this.top,
    this.right,
    this.bottom,
    this.left,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (badge.showBadge)
          Positioned(
            top: top ?? _getPositionTop(),
            right: right ?? _getPositionRight(),
            bottom: bottom ?? _getPositionBottom(),
            left: left ?? _getPositionLeft(),
            child: badge,
          ),
      ],
    );
  }

  double? _getPositionTop() {
    switch (position) {
      case BadgePosition.topRight:
      case BadgePosition.topLeft:
        return -6;
      case BadgePosition.bottomRight:
      case BadgePosition.bottomLeft:
        return null;
    }
  }

  double? _getPositionRight() {
    switch (position) {
      case BadgePosition.topRight:
      case BadgePosition.bottomRight:
        return -6;
      case BadgePosition.topLeft:
      case BadgePosition.bottomLeft:
        return null;
    }
  }

  double? _getPositionBottom() {
    switch (position) {
      case BadgePosition.bottomRight:
      case BadgePosition.bottomLeft:
        return -6;
      case BadgePosition.topRight:
      case BadgePosition.topLeft:
        return null;
    }
  }

  double? _getPositionLeft() {
    switch (position) {
      case BadgePosition.topLeft:
      case BadgePosition.bottomLeft:
        return -6;
      case BadgePosition.topRight:
      case BadgePosition.bottomRight:
        return null;
    }
  }
}

// Status badge for online/offline/away etc.
class StatusBadge extends StatelessWidget {
  final String status;
  final Color? color;
  final BadgeSize size;
  final String? tooltip;
  final bool animated;

  const StatusBadge({
    super.key,
    required this.status,
    this.color,
    this.size = BadgeSize.medium,
    this.tooltip,
    this.animated = false,
  });

  factory StatusBadge.online({
    Key? key,
    BadgeSize size = BadgeSize.medium,
    bool animated = false,
  }) {
    return StatusBadge(
      key: key,
      status: 'online',
      color: Colors.green,
      size: size,
      tooltip: 'Online',
      animated: animated,
    );
  }

  factory StatusBadge.offline({Key? key, BadgeSize size = BadgeSize.medium}) {
    return StatusBadge(
      key: key,
      status: 'offline',
      color: Colors.grey,
      size: size,
      tooltip: 'Offline',
    );
  }

  factory StatusBadge.away({Key? key, BadgeSize size = BadgeSize.medium}) {
    return StatusBadge(
      key: key,
      status: 'away',
      color: Colors.orange,
      size: size,
      tooltip: 'Away',
    );
  }

  factory StatusBadge.busy({Key? key, BadgeSize size = BadgeSize.medium}) {
    return StatusBadge(
      key: key,
      status: 'busy',
      color: Colors.red,
      size: size,
      tooltip: 'Busy',
    );
  }

  @override
  Widget build(BuildContext context) {
    final badgeColor = color ?? _getStatusColor();

    Widget badge = Container(
      width: _getSize(),
      height: _getSize(),
      decoration: BoxDecoration(
        color: badgeColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
    );

    if (animated && status == 'online') {
      badge = _AnimatedOnlineBadge(color: badgeColor, size: _getSize());
    }

    if (tooltip != null) {
      badge = Tooltip(message: tooltip!, child: badge);
    }

    return badge;
  }

  double _getSize() {
    switch (size) {
      case BadgeSize.small:
        return 8;
      case BadgeSize.medium:
        return 12;
      case BadgeSize.large:
        return 16;
    }
  }

  Color _getStatusColor() {
    switch (status.toLowerCase()) {
      case 'online':
        return Colors.green;
      case 'offline':
        return Colors.grey;
      case 'away':
        return Colors.orange;
      case 'busy':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

// Animated online badge with pulse effect
class _AnimatedOnlineBadge extends StatefulWidget {
  final Color color;
  final double size;

  const _AnimatedOnlineBadge({required this.color, required this.size});

  @override
  State<_AnimatedOnlineBadge> createState() => _AnimatedOnlineBadgeState();
}

class _AnimatedOnlineBadgeState extends State<_AnimatedOnlineBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 1.0,
      end: 1.4,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Pulsing background
            Container(
              width: widget.size * _animation.value,
              height: widget.size * _animation.value,
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            ),
            // Main badge
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Notification badge with custom icon
class NotificationBadge extends StatelessWidget {
  final IconData icon;
  final int? count;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? textColor;
  final BadgeSize size;
  final VoidCallback? onTap;

  const NotificationBadge({
    super.key,
    required this.icon,
    this.count,
    this.backgroundColor,
    this.iconColor,
    this.textColor,
    this.size = BadgeSize.medium,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasCount = count != null && count! > 0;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Icon
          Container(
            padding: _getIconPadding(),
            child: Icon(
              icon,
              size: _getIconSize(),
              color: iconColor ?? Theme.of(context).colorScheme.onSurface,
            ),
          ),

          // Badge
          if (hasCount)
            Positioned(
              top: -4,
              right: -4,
              child: CustomBadge.count(
                count: count!,
                color: backgroundColor ?? Theme.of(context).primaryColor,
                textColor: textColor,
                size: BadgeSize.small,
              ),
            ),
        ],
      ),
    );
  }

  EdgeInsets _getIconPadding() {
    switch (size) {
      case BadgeSize.small:
        return const EdgeInsets.all(6);
      case BadgeSize.medium:
        return const EdgeInsets.all(8);
      case BadgeSize.large:
        return const EdgeInsets.all(10);
    }
  }

  double _getIconSize() {
    switch (size) {
      case BadgeSize.small:
        return 16;
      case BadgeSize.medium:
        return 20;
      case BadgeSize.large:
        return 24;
    }
  }
}

// Priority badge for messages
class PriorityBadge extends StatelessWidget {
  final String priority;
  final BadgeSize size;

  const PriorityBadge({
    super.key,
    required this.priority,
    this.size = BadgeSize.small,
  });

  factory PriorityBadge.high({Key? key, BadgeSize size = BadgeSize.small}) {
    return PriorityBadge(key: key, priority: 'high', size: size);
  }

  factory PriorityBadge.medium({Key? key, BadgeSize size = BadgeSize.small}) {
    return PriorityBadge(key: key, priority: 'medium', size: size);
  }

  factory PriorityBadge.low({Key? key, BadgeSize size = BadgeSize.small}) {
    return PriorityBadge(key: key, priority: 'low', size: size);
  }

  @override
  Widget build(BuildContext context) {
    return CustomBadge(
      text: priority.toUpperCase(),
      color: _getPriorityColor(),
      size: size,
      variant: BadgeVariant.filled,
    );
  }

  Color _getPriorityColor() {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
