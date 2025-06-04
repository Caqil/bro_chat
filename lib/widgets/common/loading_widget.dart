import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

enum LoadingType { circular, linear, dots, skeleton, shimmer, pulse, custom }

enum LoadingSize { small, medium, large }

class LoadingWidget extends StatelessWidget {
  final LoadingType type;
  final LoadingSize size;
  final String? message;
  final Color? color;
  final double? strokeWidth;
  final EdgeInsets? padding;
  final bool showMessage;
  final Widget? customLoader;

  const LoadingWidget({
    super.key,
    this.type = LoadingType.circular,
    this.size = LoadingSize.medium,
    this.message,
    this.color,
    this.strokeWidth,
    this.padding,
    this.showMessage = true,
    this.customLoader,
  });

  factory LoadingWidget.circular({
    Key? key,
    LoadingSize size = LoadingSize.medium,
    String? message,
    Color? color,
    double? strokeWidth,
    EdgeInsets? padding,
  }) {
    return LoadingWidget(
      key: key,
      type: LoadingType.circular,
      size: size,
      message: message,
      color: color,
      strokeWidth: strokeWidth,
      padding: padding,
    );
  }

  factory LoadingWidget.linear({
    Key? key,
    String? message,
    Color? color,
    EdgeInsets? padding,
  }) {
    return LoadingWidget(
      key: key,
      type: LoadingType.linear,
      message: message,
      color: color,
      padding: padding,
    );
  }

  factory LoadingWidget.dots({
    Key? key,
    LoadingSize size = LoadingSize.medium,
    String? message,
    Color? color,
    EdgeInsets? padding,
  }) {
    return LoadingWidget(
      key: key,
      type: LoadingType.dots,
      size: size,
      message: message,
      color: color,
      padding: padding,
    );
  }

  factory LoadingWidget.skeleton({
    Key? key,
    String? message,
    EdgeInsets? padding,
  }) {
    return LoadingWidget(
      key: key,
      type: LoadingType.skeleton,
      message: message,
      padding: padding,
      showMessage: false,
    );
  }

  factory LoadingWidget.shimmer({
    Key? key,
    String? message,
    EdgeInsets? padding,
  }) {
    return LoadingWidget(
      key: key,
      type: LoadingType.shimmer,
      message: message,
      padding: padding,
      showMessage: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLoader(context),
          if (showMessage && message != null) ...[
            const SizedBox(height: 16),
            _buildMessage(context),
          ],
        ],
      ),
    );
  }

  Widget _buildLoader(BuildContext context) {
    switch (type) {
      case LoadingType.circular:
        return _buildCircularLoader(context);
      case LoadingType.linear:
        return _buildLinearLoader(context);
      case LoadingType.dots:
        return DotsLoadingIndicator(
          size: size,
          color: color ?? Theme.of(context).colorScheme.primary,
        );
      case LoadingType.skeleton:
        return const SkeletonLoader();
      case LoadingType.shimmer:
        return const ShimmerLoader();
      case LoadingType.pulse:
        return PulseLoadingIndicator(
          size: size,
          color: color ?? Theme.of(context).colorScheme.primary,
        );
      case LoadingType.custom:
        return customLoader ?? _buildCircularLoader(context);
    }
  }

  Widget _buildCircularLoader(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.primary;
    final loaderSize = _getLoaderSize();

    return SizedBox(
      width: loaderSize,
      height: loaderSize,
      child: CircularProgressIndicator(
        color: effectiveColor,
        strokeWidth: strokeWidth ?? _getStrokeWidth(),
      ),
    );
  }

  Widget _buildLinearLoader(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.primary;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 300),
      child: LinearProgressIndicator(
        color: effectiveColor,
        backgroundColor: effectiveColor.withOpacity(0.2),
      ),
    );
  }

  Widget _buildMessage(BuildContext context) {
    return Text(
      message!,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      textAlign: TextAlign.center,
    );
  }

  double _getLoaderSize() {
    switch (size) {
      case LoadingSize.small:
        return 20;
      case LoadingSize.medium:
        return 40;
      case LoadingSize.large:
        return 60;
    }
  }

  double _getStrokeWidth() {
    switch (size) {
      case LoadingSize.small:
        return 2;
      case LoadingSize.medium:
        return 3;
      case LoadingSize.large:
        return 4;
    }
  }
}

// Dots loading indicator
class DotsLoadingIndicator extends StatefulWidget {
  final LoadingSize size;
  final Color color;
  final Duration duration;

  const DotsLoadingIndicator({
    super.key,
    this.size = LoadingSize.medium,
    required this.color,
    this.duration = const Duration(milliseconds: 1200),
  });

  @override
  State<DotsLoadingIndicator> createState() => _DotsLoadingIndicatorState();
}

class _DotsLoadingIndicatorState extends State<DotsLoadingIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (index) => AnimationController(duration: widget.duration, vsync: this),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
    }).toList();

    _startAnimations();
  }

  void _startAnimations() {
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dotSize = _getDotSize();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Container(
              margin: EdgeInsets.symmetric(horizontal: dotSize / 4),
              child: Opacity(
                opacity: 0.3 + (_animations[index].value * 0.7),
                child: Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  double _getDotSize() {
    switch (widget.size) {
      case LoadingSize.small:
        return 6;
      case LoadingSize.medium:
        return 10;
      case LoadingSize.large:
        return 14;
    }
  }
}

// Skeleton loader for content placeholders
class SkeletonLoader extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Color? baseColor;
  final Color? highlightColor;

  const SkeletonLoader({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor =
        widget.baseColor ?? theme.colorScheme.surfaceVariant.withOpacity(0.3);
    final highlightColor = widget.highlightColor ?? theme.colorScheme.surface;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width ?? double.infinity,
          height: widget.height ?? 16,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(4),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [baseColor, highlightColor, baseColor],
              stops: [0.0, _animation.value, 1.0],
            ),
          ),
        );
      },
    );
  }
}

// Chat message skeleton
class ChatMessageSkeleton extends StatelessWidget {
  final bool isMe;
  final bool showAvatar;

  const ChatMessageSkeleton({
    super.key,
    this.isMe = false,
    this.showAvatar = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe && showAvatar) ...[
            const SkeletonLoader(
              width: 32,
              height: 32,
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            const SizedBox(width: 8),
          ],
          if (isMe) const Spacer(),
          Flexible(
            flex: 3,
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    children: [
                      SkeletonLoader(height: 14),
                      SizedBox(height: 4),
                      SkeletonLoader(height: 14, width: 120),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!isMe) const Spacer(),
          if (isMe && showAvatar) ...[
            const SizedBox(width: 8),
            const SkeletonLoader(
              width: 32,
              height: 32,
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ],
        ],
      ),
    );
  }
}

// Chat list skeleton
class ChatListSkeleton extends StatelessWidget {
  final int itemCount;

  const ChatListSkeleton({super.key, this.itemCount = 10});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              SkeletonLoader(
                width: 48,
                height: 48,
                borderRadius: BorderRadius.all(Radius.circular(24)),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLoader(height: 16, width: 200),
                    SizedBox(height: 6),
                    SkeletonLoader(height: 14, width: 120),
                  ],
                ),
              ),
              SizedBox(width: 12),
              SkeletonLoader(height: 12, width: 40),
            ],
          ),
        );
      },
    );
  }
}

// Shimmer loader
class ShimmerLoader extends StatefulWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration duration;

  const ShimmerLoader({
    super.key,
    this.child = const SizedBox(width: 200, height: 100),
    this.baseColor,
    this.highlightColor,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<ShimmerLoader> createState() => _ShimmerLoaderState();
}

class _ShimmerLoaderState extends State<ShimmerLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor =
        widget.baseColor ?? theme.colorScheme.surfaceVariant.withOpacity(0.3);
    final highlightColor = widget.highlightColor ?? theme.colorScheme.surface;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [baseColor, highlightColor, baseColor],
              stops: [0.0, _controller.value, 1.0],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

// Pulse loading indicator
class PulseLoadingIndicator extends StatefulWidget {
  final LoadingSize size;
  final Color color;
  final Duration duration;

  const PulseLoadingIndicator({
    super.key,
    this.size = LoadingSize.medium,
    required this.color,
    this.duration = const Duration(milliseconds: 1000),
  });

  @override
  State<PulseLoadingIndicator> createState() => _PulseLoadingIndicatorState();
}

class _PulseLoadingIndicatorState extends State<PulseLoadingIndicator>
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
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final circleSize = _getCircleSize();

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: circleSize,
          height: circleSize,
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.2 + (_animation.value * 0.8)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  double _getCircleSize() {
    switch (widget.size) {
      case LoadingSize.small:
        return 20;
      case LoadingSize.medium:
        return 40;
      case LoadingSize.large:
        return 60;
    }
  }
}

// Loading overlay
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;
  final Color? backgroundColor;
  final LoadingType loadingType;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
    this.backgroundColor,
    this.loadingType = LoadingType.circular,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color:
                backgroundColor ??
                Theme.of(context).colorScheme.surface.withOpacity(0.8),
            child: Center(
              child: LoadingWidget(type: loadingType, message: message),
            ),
          ),
      ],
    );
  }
}

// Inline loading indicator
class InlineLoadingIndicator extends StatelessWidget {
  final String? message;
  final LoadingSize size;
  final Color? color;

  const InlineLoadingIndicator({
    super.key,
    this.message,
    this.size = LoadingSize.small,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.primary;
    final indicatorSize = _getIndicatorSize();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: indicatorSize,
          height: indicatorSize,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: effectiveColor,
          ),
        ),
        if (message != null) ...[
          const SizedBox(width: 8),
          Text(
            message!,
            style: TextStyle(color: effectiveColor, fontSize: _getFontSize()),
          ),
        ],
      ],
    );
  }

  double _getIndicatorSize() {
    switch (size) {
      case LoadingSize.small:
        return 16;
      case LoadingSize.medium:
        return 20;
      case LoadingSize.large:
        return 24;
    }
  }

  double _getFontSize() {
    switch (size) {
      case LoadingSize.small:
        return 12;
      case LoadingSize.medium:
        return 14;
      case LoadingSize.large:
        return 16;
    }
  }
}

// Typing indicator for chat
class TypingIndicator extends StatefulWidget {
  final Color? color;
  final double dotSize;

  const TypingIndicator({super.key, this.color, this.dotSize = 6});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      ),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
    }).toList();

    _startAnimations();
  }

  void _startAnimations() {
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        widget.color ?? Theme.of(context).colorScheme.onSurfaceVariant;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Container(
              margin: EdgeInsets.symmetric(horizontal: widget.dotSize / 4),
              child: Transform.translate(
                offset: Offset(0, -4 * _animations[index].value),
                child: Container(
                  width: widget.dotSize,
                  height: widget.dotSize,
                  decoration: BoxDecoration(
                    color: effectiveColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
