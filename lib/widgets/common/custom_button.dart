import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

enum CustomButtonSize { small, medium, large }

enum CustomButtonVariant {
  primary,
  secondary,
  outline,
  ghost,
  destructive,
  success,
  warning,
}

class CustomButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final CustomButtonVariant variant;
  final CustomButtonSize size;
  final bool isLoading;
  final bool isDisabled;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final double? width;
  final double? height;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;
  final double borderRadius;
  final double? elevation;
  final Duration animationDuration;

  const CustomButton({
    super.key,
    required this.child,
    this.onPressed,
    this.variant = CustomButtonVariant.primary,
    this.size = CustomButtonSize.medium,
    this.isLoading = false,
    this.isDisabled = false,
    this.leadingIcon,
    this.trailingIcon,
    this.width,
    this.height,
    this.padding,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.borderRadius = 8,
    this.elevation,
    this.animationDuration = const Duration(milliseconds: 200),
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled =
        widget.onPressed != null && !widget.isDisabled && !widget.isLoading;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: isEnabled ? (_) => _onTapDown() : null,
            onTapUp: isEnabled ? (_) => _onTapUp() : null,
            onTapCancel: isEnabled ? _onTapCancel : null,
            onTap: isEnabled ? widget.onPressed : null,
            child: Container(
              width: widget.width,
              height: widget.height ?? _getDefaultHeight(),
              padding: widget.padding ?? _getDefaultPadding(),
              decoration: _getDecoration(context),
              child: _buildContent(),
            ),
          ),
        );
      },
    );
  }

  void _onTapDown() {
    setState(() => _isPressed = true);
    _animationController.forward();
  }

  void _onTapUp() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  double _getDefaultHeight() {
    switch (widget.size) {
      case CustomButtonSize.small:
        return 32;
      case CustomButtonSize.medium:
        return 40;
      case CustomButtonSize.large:
        return 48;
    }
  }

  EdgeInsets _getDefaultPadding() {
    switch (widget.size) {
      case CustomButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
      case CustomButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
      case CustomButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 12);
    }
  }

  BoxDecoration _getDecoration(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled =
        widget.onPressed != null && !widget.isDisabled && !widget.isLoading;

    Color backgroundColor;
    Color borderColor;
    double elevation = widget.elevation ?? 0;

    switch (widget.variant) {
      case CustomButtonVariant.primary:
        backgroundColor = widget.backgroundColor ?? theme.primaryColor;
        borderColor = widget.borderColor ?? backgroundColor;
        elevation = widget.elevation ?? 2;
        break;
      case CustomButtonVariant.secondary:
        backgroundColor = widget.backgroundColor ?? Colors.grey[100]!;
        borderColor = widget.borderColor ?? Colors.grey[300]!;
        break;
      case CustomButtonVariant.outline:
        backgroundColor = widget.backgroundColor ?? Colors.transparent;
        borderColor = widget.borderColor ?? theme.primaryColor;
        break;
      case CustomButtonVariant.ghost:
        backgroundColor = widget.backgroundColor ?? Colors.transparent;
        borderColor = widget.borderColor ?? Colors.transparent;
        break;
      case CustomButtonVariant.destructive:
        backgroundColor = widget.backgroundColor ?? Colors.red;
        borderColor = widget.borderColor ?? backgroundColor;
        break;
      case CustomButtonVariant.success:
        backgroundColor = widget.backgroundColor ?? Colors.green;
        borderColor = widget.borderColor ?? backgroundColor;
        break;
      case CustomButtonVariant.warning:
        backgroundColor = widget.backgroundColor ?? Colors.orange;
        borderColor = widget.borderColor ?? backgroundColor;
        break;
    }

    if (!isEnabled) {
      backgroundColor = backgroundColor.withOpacity(0.5);
      borderColor = borderColor.withOpacity(0.5);
      elevation = 0;
    } else if (_isPressed) {
      backgroundColor = _adjustColor(backgroundColor, -0.1);
      elevation = elevation / 2;
    }

    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(widget.borderRadius),
      border: Border.all(color: borderColor),
      boxShadow: elevation > 0
          ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: elevation,
                offset: Offset(0, elevation / 2),
              ),
            ]
          : null,
    );
  }

  Color _adjustColor(Color color, double factor) {
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness + factor).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  Widget _buildContent() {
    final theme = Theme.of(context);
    final isEnabled =
        widget.onPressed != null && !widget.isDisabled && !widget.isLoading;

    Color textColor;
    switch (widget.variant) {
      case CustomButtonVariant.primary:
      case CustomButtonVariant.destructive:
      case CustomButtonVariant.success:
      case CustomButtonVariant.warning:
        textColor = widget.foregroundColor ?? Colors.white;
        break;
      case CustomButtonVariant.secondary:
        textColor = widget.foregroundColor ?? theme.colorScheme.onSurface;
        break;
      case CustomButtonVariant.outline:
      case CustomButtonVariant.ghost:
        textColor = widget.foregroundColor ?? theme.primaryColor;
        break;
    }

    if (!isEnabled) {
      textColor = textColor.withOpacity(0.5);
    }

    if (widget.isLoading) {
      return SizedBox(
        width: _getIconSize(),
        height: _getIconSize(),
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(textColor),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.leadingIcon != null) ...[
          Icon(widget.leadingIcon, size: _getIconSize(), color: textColor),
          const SizedBox(width: 8),
        ],
        DefaultTextStyle(
          style: TextStyle(
            color: textColor,
            fontSize: _getFontSize(),
            fontWeight: FontWeight.w500,
          ),
          child: widget.child,
        ),
        if (widget.trailingIcon != null) ...[
          const SizedBox(width: 8),
          Icon(widget.trailingIcon, size: _getIconSize(), color: textColor),
        ],
      ],
    );
  }

  double _getIconSize() {
    switch (widget.size) {
      case CustomButtonSize.small:
        return 14;
      case CustomButtonSize.medium:
        return 16;
      case CustomButtonSize.large:
        return 18;
    }
  }

  double _getFontSize() {
    switch (widget.size) {
      case CustomButtonSize.small:
        return 12;
      case CustomButtonSize.medium:
        return 14;
      case CustomButtonSize.large:
        return 16;
    }
  }
}

// Icon button variant
class CustomIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final CustomButtonVariant variant;
  final CustomButtonSize size;
  final bool isLoading;
  final bool isDisabled;
  final Color? backgroundColor;
  final Color? iconColor;
  final double? iconSize;
  final double borderRadius;
  final String? tooltip;

  const CustomIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.variant = CustomButtonVariant.ghost,
    this.size = CustomButtonSize.medium,
    this.isLoading = false,
    this.isDisabled = false,
    this.backgroundColor,
    this.iconColor,
    this.iconSize,
    this.borderRadius = 8,
    this.tooltip,
  });

  @override
  State<CustomIconButton> createState() => _CustomIconButtonState();
}

class _CustomIconButtonState extends State<CustomIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled =
        widget.onPressed != null && !widget.isDisabled && !widget.isLoading;

    Widget button = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: isEnabled ? (_) => _animationController.forward() : null,
            onTapUp: isEnabled ? (_) => _animationController.reverse() : null,
            onTapCancel: isEnabled ? _animationController.reverse : null,
            onTap: isEnabled ? widget.onPressed : null,
            child: Container(
              width: _getSize(),
              height: _getSize(),
              decoration: _getDecoration(context),
              child: _buildIcon(),
            ),
          ),
        );
      },
    );

    if (widget.tooltip != null) {
      button = Tooltip(message: widget.tooltip!, child: button);
    }

    return button;
  }

  double _getSize() {
    switch (widget.size) {
      case CustomButtonSize.small:
        return 32;
      case CustomButtonSize.medium:
        return 40;
      case CustomButtonSize.large:
        return 48;
    }
  }

  BoxDecoration _getDecoration(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled =
        widget.onPressed != null && !widget.isDisabled && !widget.isLoading;

    Color backgroundColor;
    switch (widget.variant) {
      case CustomButtonVariant.primary:
        backgroundColor = widget.backgroundColor ?? theme.primaryColor;
        break;
      case CustomButtonVariant.secondary:
        backgroundColor = widget.backgroundColor ?? Colors.grey[100]!;
        break;
      case CustomButtonVariant.outline:
        backgroundColor = widget.backgroundColor ?? Colors.transparent;
        break;
      case CustomButtonVariant.ghost:
        backgroundColor = widget.backgroundColor ?? Colors.transparent;
        break;
      case CustomButtonVariant.destructive:
        backgroundColor = widget.backgroundColor ?? Colors.red;
        break;
      case CustomButtonVariant.success:
        backgroundColor = widget.backgroundColor ?? Colors.green;
        break;
      case CustomButtonVariant.warning:
        backgroundColor = widget.backgroundColor ?? Colors.orange;
        break;
    }

    if (!isEnabled) {
      backgroundColor = backgroundColor.withOpacity(0.5);
    }

    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(widget.borderRadius),
      border: widget.variant == CustomButtonVariant.outline
          ? Border.all(color: theme.primaryColor)
          : null,
    );
  }

  Widget _buildIcon() {
    final theme = Theme.of(context);
    final isEnabled =
        widget.onPressed != null && !widget.isDisabled && !widget.isLoading;

    Color iconColor;
    switch (widget.variant) {
      case CustomButtonVariant.primary:
      case CustomButtonVariant.destructive:
      case CustomButtonVariant.success:
      case CustomButtonVariant.warning:
        iconColor = widget.iconColor ?? Colors.white;
        break;
      case CustomButtonVariant.secondary:
        iconColor = widget.iconColor ?? theme.colorScheme.onSurface;
        break;
      case CustomButtonVariant.outline:
      case CustomButtonVariant.ghost:
        iconColor = widget.iconColor ?? theme.primaryColor;
        break;
    }

    if (!isEnabled) {
      iconColor = iconColor.withOpacity(0.5);
    }

    if (widget.isLoading) {
      return SizedBox(
        width: widget.iconSize ?? _getDefaultIconSize(),
        height: widget.iconSize ?? _getDefaultIconSize(),
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(iconColor),
        ),
      );
    }

    return Icon(
      widget.icon,
      size: widget.iconSize ?? _getDefaultIconSize(),
      color: iconColor,
    );
  }

  double _getDefaultIconSize() {
    switch (widget.size) {
      case CustomButtonSize.small:
        return 16;
      case CustomButtonSize.medium:
        return 20;
      case CustomButtonSize.large:
        return 24;
    }
  }
}

// Floating action button variant
class CustomFloatingActionButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final bool mini;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final String? tooltip;
  final bool isLoading;

  const CustomFloatingActionButton({
    super.key,
    required this.child,
    this.onPressed,
    this.mini = false,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.tooltip,
    this.isLoading = false,
  });

  @override
  State<CustomFloatingActionButton> createState() =>
      _CustomFloatingActionButtonState();
}

class _CustomFloatingActionButtonState extends State<CustomFloatingActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    Widget fab = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: isEnabled ? (_) => _animationController.forward() : null,
            onTapUp: isEnabled ? (_) => _animationController.reverse() : null,
            onTapCancel: isEnabled ? _animationController.reverse : null,
            onTap: isEnabled ? widget.onPressed : null,
            child: Container(
              width: widget.mini ? 40 : 56,
              height: widget.mini ? 40 : 56,
              decoration: BoxDecoration(
                color: widget.backgroundColor ?? theme.primaryColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: widget.elevation ?? 6,
                    offset: Offset(0, (widget.elevation ?? 6) / 2),
                  ),
                ],
              ),
              child: Center(
                child: widget.isLoading
                    ? SizedBox(
                        width: widget.mini ? 16 : 20,
                        height: widget.mini ? 16 : 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            widget.foregroundColor ?? Colors.white,
                          ),
                        ),
                      )
                    : DefaultTextStyle(
                        style: TextStyle(
                          color: widget.foregroundColor ?? Colors.white,
                        ),
                        child: widget.child,
                      ),
              ),
            ),
          ),
        );
      },
    );

    if (widget.tooltip != null) {
      fab = Tooltip(message: widget.tooltip!, child: fab);
    }

    return fab;
  }
}

// Toggle button
class CustomToggleButton extends StatelessWidget {
  final bool isSelected;
  final ValueChanged<bool>? onChanged;
  final Widget child;
  final CustomButtonSize size;
  final Color? selectedColor;
  final Color? unselectedColor;
  final Color? selectedTextColor;
  final Color? unselectedTextColor;

  const CustomToggleButton({
    super.key,
    required this.isSelected,
    this.onChanged,
    required this.child,
    this.size = CustomButtonSize.medium,
    this.selectedColor,
    this.unselectedColor,
    this.selectedTextColor,
    this.unselectedTextColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomButton(
      onPressed: onChanged != null ? () => onChanged!(!isSelected) : null,
      variant: isSelected
          ? CustomButtonVariant.primary
          : CustomButtonVariant.outline,
      size: size,
      backgroundColor: isSelected
          ? (selectedColor ?? theme.primaryColor)
          : (unselectedColor ?? Colors.transparent),
      foregroundColor: isSelected
          ? (selectedTextColor ?? Colors.white)
          : (unselectedTextColor ?? theme.primaryColor),
      child: child,
    );
  }
}
