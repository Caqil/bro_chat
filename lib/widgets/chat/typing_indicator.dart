import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TypingIndicatorWidget extends ConsumerStatefulWidget {
  final String text;
  final bool isVisible;
  final Color? textColor;
  final Color? dotColor;
  final double fontSize;
  final Duration animationDuration;
  final bool compact;

  const TypingIndicatorWidget({
    super.key,
    required this.text,
    this.isVisible = true,
    this.textColor,
    this.dotColor,
    this.fontSize = 13,
    this.animationDuration = const Duration(milliseconds: 600),
    this.compact = false,
  });

  @override
  ConsumerState<TypingIndicatorWidget> createState() =>
      _TypingIndicatorWidgetState();
}

class _TypingIndicatorWidgetState extends ConsumerState<TypingIndicatorWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    if (widget.isVisible) {
      _fadeController.forward();
      _animationController.repeat();
    }
  }

  @override
  void didUpdateWidget(TypingIndicatorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _fadeController.forward();
        _animationController.repeat();
      } else {
        _fadeController.reverse();
        _animationController.stop();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: _buildTypingIndicator(),
        );
      },
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!widget.compact) _buildAnimatedDots(),
        if (!widget.compact) const SizedBox(width: 8),
        Flexible(child: _buildTypingText()),
      ],
    );
  }

  Widget _buildAnimatedDots() {
    return SizedBox(
      width: 24,
      height: 16,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(3, (index) {
              final animationValue = _getAnimationValue(index);
              return Transform.translate(
                offset: Offset(0, -4 * animationValue),
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color:
                        widget.dotColor ??
                        Theme.of(context).primaryColor.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildTypingText() {
    return Text(
      widget.text,
      style: TextStyle(
        fontSize: widget.fontSize,
        color: widget.textColor ?? Theme.of(context).primaryColor,
        fontStyle: FontStyle.italic,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  double _getAnimationValue(int index) {
    final progress = _animationController.value;
    final delay = index * 0.2;
    final adjustedProgress = (progress - delay).clamp(0.0, 1.0);

    if (adjustedProgress <= 0.5) {
      return adjustedProgress * 2;
    } else {
      return (1.0 - adjustedProgress) * 2;
    }
  }
}

// Compact typing indicator for tight spaces
class CompactTypingIndicator extends ConsumerWidget {
  final bool isTyping;
  final Color? color;

  const CompactTypingIndicator({super.key, required this.isTyping, this.color});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isTyping) return const SizedBox.shrink();

    return SizedBox(
      width: 16,
      height: 16,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? Theme.of(context).primaryColor,
        ),
      ),
    );
  }
}

// Typing indicator with user avatars
class AvatarTypingIndicator extends ConsumerStatefulWidget {
  final Set<String> typingUsers;
  final Map<String, String?> userAvatars;
  final String Function(Set<String>) textBuilder;
  final int maxAvatars;
  final bool showText;

  const AvatarTypingIndicator({
    super.key,
    required this.typingUsers,
    required this.userAvatars,
    required this.textBuilder,
    this.maxAvatars = 3,
    this.showText = true,
  });

  @override
  ConsumerState<AvatarTypingIndicator> createState() =>
      _AvatarTypingIndicatorState();
}

class _AvatarTypingIndicatorState extends ConsumerState<AvatarTypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    if (widget.typingUsers.isNotEmpty) {
      _animationController.repeat();
    }
  }

  @override
  void didUpdateWidget(AvatarTypingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.typingUsers.isNotEmpty != oldWidget.typingUsers.isNotEmpty) {
      if (widget.typingUsers.isNotEmpty) {
        _animationController.repeat();
      } else {
        _animationController.stop();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.typingUsers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildUserAvatars(),
        if (widget.showText) ...[
          const SizedBox(width: 8),
          _buildAnimatedDots(),
          const SizedBox(width: 6),
          Flexible(child: _buildTypingText()),
        ],
      ],
    );
  }

  Widget _buildUserAvatars() {
    final displayUsers = widget.typingUsers.take(widget.maxAvatars).toList();
    const avatarSize = 20.0;
    const overlap = 12.0;

    return SizedBox(
      width: avatarSize + (displayUsers.length - 1) * overlap,
      height: avatarSize,
      child: Stack(
        children: [
          for (int i = 0; i < displayUsers.length; i++)
            Positioned(
              left: i * overlap,
              child: _buildUserAvatar(displayUsers[i], avatarSize),
            ),

          if (widget.typingUsers.length > widget.maxAvatars)
            Positioned(
              right: 0,
              child: Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: Center(
                  child: Text(
                    '+${widget.typingUsers.length - widget.maxAvatars}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUserAvatar(String userName, double size) {
    final avatarUrl = widget.userAvatars[userName];

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: ClipOval(
        child: avatarUrl != null
            ? Image.network(
                avatarUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildInitialsAvatar(userName, size),
              )
            : _buildInitialsAvatar(userName, size),
      ),
    );
  }

  Widget _buildInitialsAvatar(String name, double size) {
    return Container(
      width: size,
      height: size,
      color: _getAvatarColor(name),
      child: Center(
        child: Text(
          _getInitials(name),
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedDots() {
    return SizedBox(
      width: 16,
      height: 12,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(3, (index) {
              final animationValue = _getAnimationValue(index);
              return Transform.translate(
                offset: Offset(0, -2 * animationValue),
                child: Container(
                  width: 3,
                  height: 3,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildTypingText() {
    return Text(
      widget.textBuilder(widget.typingUsers),
      style: TextStyle(
        fontSize: 12,
        color: Theme.of(context).primaryColor,
        fontStyle: FontStyle.italic,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  double _getAnimationValue(int index) {
    final progress = _animationController.value;
    final delay = index * 0.2;
    final adjustedProgress = (progress - delay).clamp(0.0, 1.0);

    if (adjustedProgress <= 0.5) {
      return adjustedProgress * 2;
    } else {
      return (1.0 - adjustedProgress) * 2;
    }
  }

  String _getInitials(String name) {
    final words = name.trim().split(' ');
    if (words.isEmpty) return '';

    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    } else {
      return (words[0].substring(0, 1) + words[1].substring(0, 1))
          .toUpperCase();
    }
  }

  Color _getAvatarColor(String name) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
    ];

    final hash = name.hashCode;
    return colors[hash.abs() % colors.length];
  }
}

// Bubble typing indicator that mimics a message bubble
class BubbleTypingIndicator extends ConsumerStatefulWidget {
  final bool isFromCurrentUser;
  final Color? bubbleColor;
  final EdgeInsets? margin;

  const BubbleTypingIndicator({
    super.key,
    this.isFromCurrentUser = false,
    this.bubbleColor,
    this.margin,
  });

  @override
  ConsumerState<BubbleTypingIndicator> createState() =>
      _BubbleTypingIndicatorState();
}

class _BubbleTypingIndicatorState extends ConsumerState<BubbleTypingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:
          widget.margin ??
          EdgeInsets.only(
            left: widget.isFromCurrentUser ? 60 : 8,
            right: widget.isFromCurrentUser ? 8 : 60,
            top: 2,
            bottom: 2,
          ),
      child: Row(
        mainAxisAlignment: widget.isFromCurrentUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color:
                        widget.bubbleColor ??
                        (widget.isFromCurrentUser
                            ? Theme.of(context).primaryColor
                            : Colors.grey[200]),
                    borderRadius: _getBubbleBorderRadius(),
                  ),
                  child: _buildDots(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDots() {
    return SizedBox(
      width: 32,
      height: 16,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(3, (index) {
              final animationValue = _getAnimationValue(index);
              return Transform.translate(
                offset: Offset(0, -4 * animationValue),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: widget.isFromCurrentUser
                        ? Colors.white.withOpacity(0.8)
                        : Colors.grey[500],
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  BorderRadius _getBubbleBorderRadius() {
    const radius = Radius.circular(18);
    const smallRadius = Radius.circular(4);

    if (widget.isFromCurrentUser) {
      return const BorderRadius.only(
        topLeft: radius,
        topRight: radius,
        bottomLeft: radius,
        bottomRight: smallRadius,
      );
    } else {
      return const BorderRadius.only(
        topLeft: radius,
        topRight: radius,
        bottomLeft: smallRadius,
        bottomRight: radius,
      );
    }
  }

  double _getAnimationValue(int index) {
    final progress = _animationController.value;
    final delay = index * 0.15;
    final adjustedProgress = (progress - delay).clamp(0.0, 1.0);

    if (adjustedProgress <= 0.5) {
      return adjustedProgress * 2;
    } else {
      return (1.0 - adjustedProgress) * 2;
    }
  }
}

// Status bar typing indicator
class StatusBarTypingIndicator extends ConsumerWidget {
  final String text;
  final bool isVisible;
  final VoidCallback? onTap;

  const StatusBarTypingIndicator({
    super.key,
    required this.text,
    required this.isVisible,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: isVisible ? 32 : 0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isVisible ? 1.0 : 0.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).primaryColor.withOpacity(0.2),
              ),
            ),
          ),
          child: GestureDetector(
            onTap: onTap,
            child: Row(
              children: [
                CompactTypingIndicator(isTyping: isVisible),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).primaryColor,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
