import 'package:flutter/material.dart';

enum FABSize { small, regular, large, extended }

enum FABType { circular, extended, mini }

class CustomFAB extends StatefulWidget {
  final Widget? child;
  final String? label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final FABSize size;
  final FABType type;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? splashColor;
  final double? elevation;
  final double? focusElevation;
  final double? hoverElevation;
  final double? highlightElevation;
  final ShapeBorder? shape;
  final bool isExtended;
  final String? tooltip;
  final String? heroTag;
  final bool enableFeedback;
  final EdgeInsets? padding;
  final bool autofocus;

  const CustomFAB({
    super.key,
    this.child,
    this.label,
    this.icon,
    this.onPressed,
    this.size = FABSize.regular,
    this.type = FABType.circular,
    this.backgroundColor,
    this.foregroundColor,
    this.splashColor,
    this.elevation,
    this.focusElevation,
    this.hoverElevation,
    this.highlightElevation,
    this.shape,
    this.isExtended = false,
    this.tooltip,
    this.heroTag,
    this.enableFeedback = true,
    this.padding,
    this.autofocus = false,
  });

  factory CustomFAB.circular({
    Key? key,
    required IconData icon,
    VoidCallback? onPressed,
    FABSize size = FABSize.regular,
    Color? backgroundColor,
    Color? foregroundColor,
    double? elevation,
    String? tooltip,
    String? heroTag,
  }) {
    return CustomFAB(
      key: key,
      icon: icon,
      onPressed: onPressed,
      size: size,
      type: FABType.circular,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: elevation,
      tooltip: tooltip,
      heroTag: heroTag,
    );
  }

  factory CustomFAB.extended({
    Key? key,
    required String label,
    IconData? icon,
    VoidCallback? onPressed,
    Color? backgroundColor,
    Color? foregroundColor,
    double? elevation,
    String? tooltip,
    String? heroTag,
  }) {
    return CustomFAB(
      key: key,
      label: label,
      icon: icon,
      onPressed: onPressed,
      size: FABSize.extended,
      type: FABType.extended,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: elevation,
      tooltip: tooltip,
      heroTag: heroTag,
      isExtended: true,
    );
  }

  factory CustomFAB.mini({
    Key? key,
    required IconData icon,
    VoidCallback? onPressed,
    Color? backgroundColor,
    Color? foregroundColor,
    double? elevation,
    String? tooltip,
    String? heroTag,
  }) {
    return CustomFAB(
      key: key,
      icon: icon,
      onPressed: onPressed,
      size: FABSize.small,
      type: FABType.mini,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: elevation,
      tooltip: tooltip,
      heroTag: heroTag,
    );
  }

  @override
  State<CustomFAB> createState() => _CustomFABState();
}

class _CustomFABState extends State<CustomFAB>
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
    if (widget.isExtended || widget.type == FABType.extended) {
      return _buildExtendedFAB();
    }

    return _buildCircularFAB();
  }

  Widget _buildCircularFAB() {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: FloatingActionButton(
            onPressed: widget.onPressed,
            backgroundColor: widget.backgroundColor,
            foregroundColor: widget.foregroundColor,
            splashColor: widget.splashColor,
            elevation: widget.elevation,
            focusElevation: widget.focusElevation,
            hoverElevation: widget.hoverElevation,
            highlightElevation: widget.highlightElevation,
            shape: widget.shape,
            tooltip: widget.tooltip,
            heroTag: widget.heroTag,
            enableFeedback: widget.enableFeedback,
            autofocus: widget.autofocus,
            mini: widget.size == FABSize.small || widget.type == FABType.mini,
            child: _buildChild(),
          ),
        );
      },
    );
  }

  Widget _buildExtendedFAB() {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: FloatingActionButton.extended(
            onPressed: widget.onPressed,
            backgroundColor: widget.backgroundColor,
            foregroundColor: widget.foregroundColor,
            splashColor: widget.splashColor,
            elevation: widget.elevation,
            focusElevation: widget.focusElevation,
            hoverElevation: widget.hoverElevation,
            highlightElevation: widget.highlightElevation,
            shape: widget.shape,
            tooltip: widget.tooltip,
            heroTag: widget.heroTag,
            enableFeedback: widget.enableFeedback,
            autofocus: widget.autofocus,
            icon: widget.icon != null ? Icon(widget.icon) : null,
            label: Text(widget.label ?? ''),
          ),
        );
      },
    );
  }

  Widget _buildChild() {
    if (widget.child != null) return widget.child!;
    if (widget.icon != null) return Icon(widget.icon);
    return const Icon(Icons.add);
  }
}

// Animated FAB with custom animations
class AnimatedFAB extends StatefulWidget {
  final IconData primaryIcon;
  final IconData? secondaryIcon;
  final String? primaryLabel;
  final String? secondaryLabel;
  final VoidCallback? onPressed;
  final VoidCallback? onSecondaryPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final Duration animationDuration;
  final bool isToggled;
  final ValueChanged<bool>? onToggle;

  const AnimatedFAB({
    super.key,
    required this.primaryIcon,
    this.secondaryIcon,
    this.primaryLabel,
    this.secondaryLabel,
    this.onPressed,
    this.onSecondaryPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.animationDuration = const Duration(milliseconds: 300),
    this.isToggled = false,
    this.onToggle,
  });

  @override
  State<AnimatedFAB> createState() => _AnimatedFABState();
}

class _AnimatedFABState extends State<AnimatedFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    if (widget.isToggled) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(AnimatedFAB oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isToggled != oldWidget.isToggled) {
      if (widget.isToggled) {
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: FloatingActionButton(
            onPressed: _handlePress,
            backgroundColor: widget.backgroundColor,
            foregroundColor: widget.foregroundColor,
            elevation: widget.elevation,
            child: Transform.rotate(
              angle: _rotationAnimation.value * 3.14159 / 4, // 45 degrees
              child: Icon(_getCurrentIcon()),
            ),
          ),
        );
      },
    );
  }

  IconData _getCurrentIcon() {
    if (widget.secondaryIcon != null && widget.isToggled) {
      return widget.secondaryIcon!;
    }
    return widget.primaryIcon;
  }

  void _handlePress() {
    if (widget.onToggle != null) {
      widget.onToggle!(!widget.isToggled);
    }

    if (widget.isToggled && widget.onSecondaryPressed != null) {
      widget.onSecondaryPressed!();
    } else if (widget.onPressed != null) {
      widget.onPressed!();
    }
  }
}

// Speed dial FAB
class SpeedDialFAB extends StatefulWidget {
  final IconData icon;
  final IconData? activeIcon;
  final List<SpeedDialAction> actions;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? overlayColor;
  final double? elevation;
  final String? tooltip;
  final bool renderOverlay;
  final Duration animationDuration;
  final Curve animationCurve;
  final VoidCallback? onOpen;
  final VoidCallback? onClose;

  const SpeedDialFAB({
    super.key,
    required this.icon,
    this.activeIcon,
    required this.actions,
    this.backgroundColor,
    this.foregroundColor,
    this.overlayColor,
    this.elevation,
    this.tooltip,
    this.renderOverlay = true,
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeInOut,
    this.onOpen,
    this.onClose,
  });

  @override
  State<SpeedDialFAB> createState() => _SpeedDialFABState();
}

class _SpeedDialFABState extends State<SpeedDialFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotationAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: widget.animationCurve,
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.125,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_isOpen) {
      _close();
    } else {
      _open();
    }
  }

  void _open() {
    _controller.forward();
    setState(() => _isOpen = true);
    widget.onOpen?.call();
  }

  void _close() {
    _controller.reverse();
    setState(() => _isOpen = false);
    widget.onClose?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      clipBehavior: Clip.none,
      children: [
        // Overlay
        if (widget.renderOverlay)
          AnimatedBuilder(
            animation: _expandAnimation,
            builder: (context, child) {
              return _isOpen
                  ? GestureDetector(
                      onTap: _close,
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height,
                        color: (widget.overlayColor ?? Colors.black)
                            .withOpacity(0.5 * _expandAnimation.value),
                      ),
                    )
                  : const SizedBox.shrink();
            },
          ),

        // Speed dial actions
        ..._buildSpeedDialActions(),

        // Main FAB
        _buildMainFAB(),
      ],
    );
  }

  List<Widget> _buildSpeedDialActions() {
    return widget.actions
        .asMap()
        .entries
        .map((entry) => _buildSpeedDialAction(entry.key, entry.value))
        .toList();
  }

  Widget _buildSpeedDialAction(int index, SpeedDialAction action) {
    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        final offset = (index + 1) * 70.0 * _expandAnimation.value;

        return Positioned(
          bottom: offset,
          right: 0,
          child: FadeTransition(
            opacity: _expandAnimation,
            child: ScaleTransition(
              scale: _expandAnimation,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Label
                  if (action.label != null)
                    Container(
                      margin: const EdgeInsets.only(right: 16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        action.label!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                  // Action button
                  FloatingActionButton(
                    mini: true,
                    heroTag: 'speed_dial_${index}',
                    onPressed: () {
                      action.onPressed?.call();
                      _close();
                    },
                    backgroundColor: action.backgroundColor,
                    foregroundColor: action.foregroundColor,
                    tooltip: action.tooltip,
                    child: Icon(action.icon),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainFAB() {
    return FloatingActionButton(
      onPressed: _toggle,
      backgroundColor: widget.backgroundColor,
      foregroundColor: widget.foregroundColor,
      elevation: widget.elevation,
      tooltip: widget.tooltip,
      child: AnimatedBuilder(
        animation: _rotationAnimation,
        builder: (context, child) {
          return Transform.rotate(
            angle: _rotationAnimation.value * 2 * 3.14159,
            child: Icon(
              _isOpen ? (widget.activeIcon ?? Icons.close) : widget.icon,
            ),
          );
        },
      ),
    );
  }
}

class SpeedDialAction {
  final IconData icon;
  final String? label;
  final String? tooltip;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;

  SpeedDialAction({
    required this.icon,
    this.label,
    this.tooltip,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
  });
}

// Morphing FAB that changes between different states
class MorphingFAB extends StatefulWidget {
  final List<FABState> states;
  final int currentStateIndex;
  final ValueChanged<int>? onStateChanged;
  final Duration morphDuration;
  final Curve morphCurve;

  const MorphingFAB({
    super.key,
    required this.states,
    this.currentStateIndex = 0,
    this.onStateChanged,
    this.morphDuration = const Duration(milliseconds: 400),
    this.morphCurve = Curves.easeInOut,
  });

  @override
  State<MorphingFAB> createState() => _MorphingFABState();
}

class _MorphingFABState extends State<MorphingFAB>
    with TickerProviderStateMixin {
  late AnimationController _morphController;
  late Animation<double> _morphAnimation;

  @override
  void initState() {
    super.initState();
    _morphController = AnimationController(
      duration: widget.morphDuration,
      vsync: this,
    );

    _morphAnimation = CurvedAnimation(
      parent: _morphController,
      curve: widget.morphCurve,
    );
  }

  @override
  void dispose() {
    _morphController.dispose();
    super.dispose();
  }

  void _morphToNextState() {
    final nextIndex = (widget.currentStateIndex + 1) % widget.states.length;
    widget.onStateChanged?.call(nextIndex);
    _morphController.forward().then((_) {
      _morphController.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentState = widget.states[widget.currentStateIndex];

    return AnimatedBuilder(
      animation: _morphAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 - (_morphAnimation.value * 0.1),
          child: FloatingActionButton.extended(
            onPressed: _morphToNextState,
            backgroundColor: currentState.backgroundColor,
            foregroundColor: currentState.foregroundColor,
            icon: Icon(currentState.icon),
            label: Text(currentState.label),
          ),
        );
      },
    );
  }
}

class FABState {
  final IconData icon;
  final String label;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final VoidCallback? onPressed;

  FABState({
    required this.icon,
    required this.label,
    this.backgroundColor,
    this.foregroundColor,
    this.onPressed,
  });
}

// Expandable FAB with multiple actions in a horizontal row
class ExpandableFAB extends StatefulWidget {
  final IconData icon;
  final List<ActionButton> actions;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final Duration animationDuration;

  const ExpandableFAB({
    super.key,
    required this.icon,
    required this.actions,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.animationDuration = const Duration(milliseconds: 250),
  });

  @override
  State<ExpandableFAB> createState() => _ExpandableFABState();
}

class _ExpandableFABState extends State<ExpandableFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.fastOutSlowIn,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Action buttons
            ..._buildActionButtons(),

            // Main FAB
            FloatingActionButton(
              onPressed: _toggle,
              backgroundColor: widget.backgroundColor,
              foregroundColor: widget.foregroundColor,
              elevation: widget.elevation,
              child: AnimatedRotation(
                turns: _isExpanded ? 0.125 : 0,
                duration: widget.animationDuration,
                child: Icon(widget.icon),
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildActionButtons() {
    return widget.actions.map((action) {
      return Transform.scale(
        scale: _expandAnimation.value,
        child: Container(
          margin: const EdgeInsets.only(right: 16),
          child: FloatingActionButton(
            mini: true,
            heroTag: action.label,
            onPressed: () {
              action.onPressed?.call();
              _toggle();
            },
            backgroundColor: action.backgroundColor,
            child: Icon(action.icon),
          ),
        ),
      );
    }).toList();
  }
}

class ActionButton {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color? backgroundColor;

  ActionButton({
    required this.icon,
    required this.label,
    this.onPressed,
    this.backgroundColor,
  });
}
