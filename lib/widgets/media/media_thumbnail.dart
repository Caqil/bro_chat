import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:bro_chat/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../../services/media/image_service.dart' as format;
import '../../theme/text_styles.dart';

enum ThumbnailType { image, video, audio, document }

class MediaThumbnail extends ConsumerStatefulWidget {
  final String url;
  final String? thumbnailUrl;
  final ThumbnailType type;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Duration? duration;
  final bool showPlayButton;
  final bool showDuration;
  final bool showLoadingIndicator;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget? placeholder;
  final Widget? errorWidget;

  const MediaThumbnail({
    Key? key,
    required this.url,
    this.thumbnailUrl,
    required this.type,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.duration,
    this.showPlayButton = true,
    this.showDuration = true,
    this.showLoadingIndicator = true,
    this.backgroundColor,
    this.borderRadius,
    this.onTap,
    this.onLongPress,
    this.placeholder,
    this.errorWidget,
  }) : super(key: key);

  @override
  ConsumerState<MediaThumbnail> createState() => _MediaThumbnailState();
}

class _MediaThumbnailState extends ConsumerState<MediaThumbnail>
    with TickerProviderStateMixin {
  late AnimationController _loadingAnimationController;
  late AnimationController _hoverAnimationController;
  late Animation<double> _loadingAnimation;
  late Animation<double> _hoverAnimation;

  bool _isLoading = false;
  bool _isHovered = false;
  bool _hasError = false;
  String? _localThumbnailPath;
  Uint8List? _thumbnailBytes;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadThumbnail();
  }

  void _initializeAnimations() {
    _loadingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _hoverAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _loadingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _loadingAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _hoverAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _hoverAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.showLoadingIndicator) {
      _loadingAnimationController.repeat();
    }
  }

  Future<void> _loadThumbnail() async {
    if (widget.thumbnailUrl != null) {
      // Use provided thumbnail URL
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      switch (widget.type) {
        case ThumbnailType.image:
          await _loadImageThumbnail();
          break;
        case ThumbnailType.video:
          await _loadVideoThumbnail();
          break;
        case ThumbnailType.audio:
          await _loadAudioThumbnail();
          break;
        case ThumbnailType.document:
          await _loadDocumentThumbnail();
          break;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadImageThumbnail() async {
    try {
      final imageService = ref.read(format.imageServiceProvider);
      final thumbnailPath = await imageService.generateThumbnail(
        widget.url,
        maxSize: 200,
        quality: 75,
      );

      if (thumbnailPath != null && mounted) {
        setState(() {
          _localThumbnailPath = thumbnailPath;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Fallback to original image
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadVideoThumbnail() async {
    try {
      final thumbnailBytes = await VideoThumbnail.thumbnailData(
        video: widget.url,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 200,
        maxHeight: 200,
        quality: 75,
      );

      if (thumbnailBytes != null && mounted) {
        setState(() {
          _thumbnailBytes = thumbnailBytes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadAudioThumbnail() async {
    // Audio files don't have visual thumbnails
    // Use a generated waveform or placeholder
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDocumentThumbnail() async {
    // For documents, we might generate a preview of the first page
    // For now, we'll use a placeholder
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildThumbnailContent() {
    switch (widget.type) {
      case ThumbnailType.image:
        return _buildImageThumbnail();
      case ThumbnailType.video:
        return _buildVideoThumbnail();
      case ThumbnailType.audio:
        return _buildAudioThumbnail();
      case ThumbnailType.document:
        return _buildDocumentThumbnail();
    }
  }

  Widget _buildImageThumbnail() {
    if (_localThumbnailPath != null) {
      return Image.file(
        File(_localThumbnailPath!),
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
      );
    } else if (widget.thumbnailUrl != null) {
      return CachedNetworkImage(
        imageUrl: widget.thumbnailUrl!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        placeholder: (context, url) => _buildLoadingWidget(),
        errorWidget: (context, url, error) => _buildErrorWidget(),
      );
    } else {
      return CachedNetworkImage(
        imageUrl: widget.url,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        placeholder: (context, url) => _buildLoadingWidget(),
        errorWidget: (context, url, error) => _buildErrorWidget(),
      );
    }
  }

  Widget _buildVideoThumbnail() {
    if (_thumbnailBytes != null) {
      return Stack(
        children: [
          Image.memory(
            _thumbnailBytes!,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
          ),
          if (widget.showPlayButton) _buildPlayButton(),
          if (widget.showDuration && widget.duration != null)
            _buildDurationOverlay(),
        ],
      );
    } else if (widget.thumbnailUrl != null) {
      return Stack(
        children: [
          CachedNetworkImage(
            imageUrl: widget.thumbnailUrl!,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            placeholder: (context, url) => _buildLoadingWidget(),
            errorWidget: (context, url, error) => _buildErrorWidget(),
          ),
          if (widget.showPlayButton) _buildPlayButton(),
          if (widget.showDuration && widget.duration != null)
            _buildDurationOverlay(),
        ],
      );
    } else {
      return Stack(
        children: [
          _buildVideoPlaceholder(),
          if (widget.showPlayButton) _buildPlayButton(),
          if (widget.showDuration && widget.duration != null)
            _buildDurationOverlay(),
        ],
      );
    }
  }

  Widget _buildAudioThumbnail() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? AppColors.primary.withOpacity(0.1),
        borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.audiotrack, size: 32, color: AppColors.primary),
                const SizedBox(height: 8),
                if (widget.showDuration && widget.duration != null)
                  Text(
                    _formatDuration(widget.duration!),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          _buildWaveformOverlay(),
        ],
      ),
    );
  }

  Widget _buildDocumentThumbnail() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Colors.grey[200],
        borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_getDocumentIcon(), size: 32, color: AppColors.textSecondary),
          const SizedBox(height: 8),
          Text(
            _getFileExtension(),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayButton() {
    return Positioned.fill(
      child: Center(
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.play_arrow, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  Widget _buildDurationOverlay() {
    return Positioned(
      bottom: 4,
      right: 4,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          _formatDuration(widget.duration!),
          style: AppTextStyles.caption.copyWith(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildWaveformOverlay() {
    return Positioned.fill(
      child: CustomPaint(
        painter: WaveformPainter(
          color: AppColors.primary.withOpacity(0.3),
          isAnimated: false,
        ),
      ),
    );
  }

  Widget _buildVideoPlaceholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Colors.grey[300],
        borderRadius: widget.borderRadius,
      ),
      child: Center(
        child: Icon(Icons.video_file, size: 32, color: Colors.grey[600]),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    if (widget.placeholder != null) {
      return widget.placeholder!;
    }

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Colors.grey[300],
        borderRadius: widget.borderRadius,
      ),
      child: Center(
        child: widget.showLoadingIndicator
            ? AnimatedBuilder(
                animation: _loadingAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: 0.5 + 0.5 * _loadingAnimation.value,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  );
                },
              )
            : Icon(Icons.image, size: 32, color: Colors.grey[600]),
      ),
    );
  }

  Widget _buildErrorWidget() {
    if (widget.errorWidget != null) {
      return widget.errorWidget!;
    }

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Colors.grey[300],
        borderRadius: widget.borderRadius,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image, size: 32, color: Colors.grey[600]),
            const SizedBox(height: 4),
            Text(
              'Failed to load',
              style: AppTextStyles.caption.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getDocumentIcon() {
    final extension = _getFileExtension().toLowerCase();

    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'txt':
        return Icons.text_snippet;
      case 'zip':
      case 'rar':
        return Icons.archive;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _getFileExtension() {
    final parts = widget.url.split('.');
    return parts.length > 1 ? parts.last.toUpperCase() : 'FILE';
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    } else {
      return "$twoDigitMinutes:$twoDigitSeconds";
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _hoverAnimationController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _hoverAnimationController.reverse();
      },
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: ScaleTransition(
          scale: _hoverAnimation,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
              child: _hasError
                  ? _buildErrorWidget()
                  : _isLoading
                  ? _buildLoadingWidget()
                  : _buildThumbnailContent(),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _loadingAnimationController.dispose();
    _hoverAnimationController.dispose();
    super.dispose();
  }
}

class WaveformPainter extends CustomPainter {
  final Color color;
  final bool isAnimated;
  final double animationValue;

  WaveformPainter({
    required this.color,
    required this.isAnimated,
    this.animationValue = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final barWidth = 2.0;
    final barSpacing = 1.0;
    final barCount = (size.width / (barWidth + barSpacing)).floor();

    for (int i = 0; i < barCount; i++) {
      final x = i * (barWidth + barSpacing);
      final normalizedX = i / barCount;

      // Generate pseudo-random heights for waveform
      final baseHeight =
          0.3 + 0.4 * (1 + math.sin(normalizedX * math.pi * 3)) / 2;
      final animatedHeight = isAnimated
          ? baseHeight +
                0.3 *
                    math.sin(
                      animationValue * 2 * math.pi + normalizedX * math.pi * 2,
                    )
          : baseHeight;

      final barHeight = animatedHeight * size.height;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, (size.height - barHeight) / 2, barWidth, barHeight),
          const Radius.circular(1),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.isAnimated != isAnimated ||
        oldDelegate.animationValue != animationValue;
  }
}

// Helper functions and extensions
extension MediaThumbnailExtensions on String {
  bool get isImageUrl {
    final imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
    final extension = split('.').last.toLowerCase();
    return imageExtensions.contains(extension);
  }

  bool get isVideoUrl {
    final videoExtensions = ['mp4', 'avi', 'mov', 'mkv', 'webm', 'flv', 'wmv'];
    final extension = split('.').last.toLowerCase();
    return videoExtensions.contains(extension);
  }

  bool get isAudioUrl {
    final audioExtensions = ['mp3', 'wav', 'aac', 'ogg', 'flac', 'm4a'];
    final extension = split('.').last.toLowerCase();
    return audioExtensions.contains(extension);
  }

  ThumbnailType get thumbnailType {
    if (isImageUrl) return ThumbnailType.image;
    if (isVideoUrl) return ThumbnailType.video;
    if (isAudioUrl) return ThumbnailType.audio;
    return ThumbnailType.document;
  }
}
