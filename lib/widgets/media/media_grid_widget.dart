import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../models/chat/message_model.dart';
import '../../models/file/media_model.dart';
import '../../theme/text_styles.dart';
import 'media_thumbnail.dart';
import 'image_message_widget.dart';
import 'video_message_widget.dart';
import 'audio_message_widget.dart';

class MediaGridWidget extends ConsumerStatefulWidget {
  final List<MediaModel> mediaItems;
  final List<MessageModel>? relatedMessages;
  final bool isCurrentUser;
  final double maxWidth;
  final double maxHeight;
  final int maxItems;
  final GridLayoutType layoutType;
  final double spacing;
  final bool showOverlay;
  final VoidCallback? onMorePressed;
  final Function(MediaModel, int)? onMediaTap;
  final Function(MediaModel)? onMediaLongPress;

  const MediaGridWidget({
    Key? key,
    required this.mediaItems,
    this.relatedMessages,
    required this.isCurrentUser,
    this.maxWidth = 280,
    this.maxHeight = 400,
    this.maxItems = 4,
    this.layoutType = GridLayoutType.auto,
    this.spacing = 2,
    this.showOverlay = true,
    this.onMorePressed,
    this.onMediaTap,
    this.onMediaLongPress,
  }) : super(key: key);

  @override
  ConsumerState<MediaGridWidget> createState() => _MediaGridWidgetState();
}

class _MediaGridWidgetState extends ConsumerState<MediaGridWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Animation<double>> _itemAnimations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    final displayedItems = math.min(widget.mediaItems.length, widget.maxItems);
    _itemAnimations = List.generate(displayedItems, (index) {
      final start = index * 0.1;
      final end = start + 0.3;

      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(start, end, curve: Curves.easeOutBack),
        ),
      );
    });

    // Start animation after a short delay
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  GridLayoutConfig _calculateLayout() {
    final itemCount = math.min(widget.mediaItems.length, widget.maxItems);

    switch (widget.layoutType) {
      case GridLayoutType.single:
        return GridLayoutConfig(
          crossAxisCount: 1,
          childAspectRatio: 1.0,
          rows: 1,
          columns: 1,
        );

      case GridLayoutType.row:
        return GridLayoutConfig(
          crossAxisCount: itemCount,
          childAspectRatio: 1.0,
          rows: 1,
          columns: itemCount,
        );

      case GridLayoutType.column:
        return GridLayoutConfig(
          crossAxisCount: 1,
          childAspectRatio: 1.0,
          rows: itemCount,
          columns: 1,
        );

      case GridLayoutType.grid:
        return _calculateGridLayout(itemCount);

      case GridLayoutType.auto:
      default:
        return _calculateAutoLayout(itemCount);
    }
  }

  GridLayoutConfig _calculateAutoLayout(int itemCount) {
    switch (itemCount) {
      case 1:
        return GridLayoutConfig(
          crossAxisCount: 1,
          childAspectRatio: 1.2,
          rows: 1,
          columns: 1,
        );

      case 2:
        return GridLayoutConfig(
          crossAxisCount: 2,
          childAspectRatio: 1.0,
          rows: 1,
          columns: 2,
        );

      case 3:
        return GridLayoutConfig(
          crossAxisCount: 2,
          childAspectRatio: 1.0,
          rows: 2,
          columns: 2,
          customLayout: true,
        );

      case 4:
      default:
        return GridLayoutConfig(
          crossAxisCount: 2,
          childAspectRatio: 1.0,
          rows: 2,
          columns: 2,
        );
    }
  }

  GridLayoutConfig _calculateGridLayout(int itemCount) {
    final columns = (math.sqrt(itemCount)).ceil();
    final rows = (itemCount / columns).ceil();

    return GridLayoutConfig(
      crossAxisCount: columns,
      childAspectRatio: 1.0,
      rows: rows,
      columns: columns,
    );
  }

  Widget _buildStaggeredGrid() {
    final layout = _calculateLayout();
    final displayedItems = math.min(widget.mediaItems.length, widget.maxItems);
    final hasMoreItems = widget.mediaItems.length > widget.maxItems;

    if (layout.customLayout && displayedItems == 3) {
      return _buildCustomThreeItemLayout();
    }

    return StaggeredGrid.count(
      crossAxisCount: layout.crossAxisCount,
      mainAxisSpacing: widget.spacing,
      crossAxisSpacing: widget.spacing,
      children: [
        for (int i = 0; i < displayedItems; i++)
          _buildAnimatedMediaItem(i, i == displayedItems - 1 && hasMoreItems),
      ],
    );
  }

  Widget _buildCustomThreeItemLayout() {
    return SizedBox(
      height: widget.maxHeight,
      child: Row(
        children: [
          // Left item (larger)
          Expanded(flex: 2, child: _buildAnimatedMediaItem(0, false)),
          SizedBox(width: widget.spacing),
          // Right column (two smaller items)
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Expanded(child: _buildAnimatedMediaItem(1, false)),
                SizedBox(height: widget.spacing),
                Expanded(child: _buildAnimatedMediaItem(2, false)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedMediaItem(int index, bool showMoreOverlay) {
    if (index >= _itemAnimations.length) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _itemAnimations[index],
      builder: (context, child) {
        return Transform.scale(
          scale: _itemAnimations[index].value,
          child: Opacity(
            opacity: _itemAnimations[index].value,
            child: _buildMediaItem(index, showMoreOverlay),
          ),
        );
      },
    );
  }

  Widget _buildMediaItem(int index, bool showMoreOverlay) {
    if (index >= widget.mediaItems.length) {
      return const SizedBox.shrink();
    }

    final media = widget.mediaItems[index];

    return GestureDetector(
      onTap: () => widget.onMediaTap?.call(media, index),
      onLongPress: () => widget.onMediaLongPress?.call(media),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              // Media content
              Positioned.fill(child: _buildMediaContent(media)),
              // Overlay information
              if (widget.showOverlay) _buildMediaOverlay(media),
              // More items overlay
              if (showMoreOverlay) _buildMoreItemsOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaContent(MediaModel media) {
    switch (media.type) {
      case MediaType.image:
        return MediaThumbnail(
          url: media.url,
          thumbnailUrl: media.thumbnailUrl,
          type: ThumbnailType.image,
          fit: BoxFit.cover,
        );

      case MediaType.video:
        return MediaThumbnail(
          url: media.url,
          thumbnailUrl: media.thumbnailUrl,
          type: ThumbnailType.video,
          fit: BoxFit.cover,
          duration: media.duration,
        );

      case MediaType.audio:
        return MediaThumbnail(
          url: media.url,
          type: ThumbnailType.audio,
          fit: BoxFit.cover,
          duration: media.duration,
        );
    }
  }

  Widget _buildMediaOverlay(MediaModel media) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withOpacity(0.7), Colors.transparent],
          ),
        ),
        child: Row(
          children: [
            // Media type icon
            Icon(_getMediaTypeIcon(media.type), color: Colors.white, size: 16),
            const SizedBox(width: 4),
            // Duration or size info
            Expanded(
              child: Text(
                _getMediaInfo(media),
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreItemsOverlay() {
    final remainingCount = widget.mediaItems.length - widget.maxItems;

    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_photo_alternate, color: Colors.white, size: 32),
              const SizedBox(height: 4),
              Text(
                '+$remainingCount',
                style: AppTextStyles.h6.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getMediaTypeIcon(MediaType type) {
    switch (type) {
      case MediaType.image:
        return Icons.image;
      case MediaType.video:
        return Icons.play_circle_filled;
      case MediaType.audio:
        return Icons.audiotrack;
    }
  }

  String _getMediaInfo(MediaModel media) {
    switch (media.type) {
      case MediaType.image:
        if (media.width != null && media.height != null) {
          return '${media.width}x${media.height}';
        }
        return 'Image';

      case MediaType.video:
        if (media.duration != null) {
          return _formatDuration(media.duration!);
        }
        return 'Video';

      case MediaType.audio:
        if (media.duration != null) {
          return _formatDuration(media.duration!);
        }
        return 'Audio';
    }
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

  void _openMediaViewer(int startIndex) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, animation, secondaryAnimation) {
          return MediaGridViewer(
            mediaItems: widget.mediaItems,
            relatedMessages: widget.relatedMessages,
            initialIndex: startIndex,
            isCurrentUser: widget.isCurrentUser,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: animation, child: child),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mediaItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      constraints: BoxConstraints(
        maxWidth: widget.maxWidth,
        maxHeight: widget.maxHeight,
      ),
      child: _buildStaggeredGrid(),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

class MediaGridViewer extends StatefulWidget {
  final List<MediaModel> mediaItems;
  final List<MessageModel>? relatedMessages;
  final int initialIndex;
  final bool isCurrentUser;

  const MediaGridViewer({
    Key? key,
    required this.mediaItems,
    this.relatedMessages,
    required this.initialIndex,
    required this.isCurrentUser,
  }) : super(key: key);

  @override
  State<MediaGridViewer> createState() => _MediaGridViewerState();
}

class _MediaGridViewerState extends State<MediaGridViewer>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  int _currentIndex = 0;
  bool _isControlsVisible = true;

  @override
  void initState() {
    super.initState();

    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_fadeController);

    _fadeController.forward();

    // Auto-hide controls after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _toggleControls();
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _isControlsVisible = !_isControlsVisible;
    });
  }

  void _close() {
    _fadeController.reverse().then((_) {
      Navigator.of(context).pop();
    });
  }

  Widget _buildMediaViewer(MediaModel media) {
    switch (media.type) {
      case MediaType.image:
        return _buildImageViewer(media);
      case MediaType.video:
        return _buildVideoViewer(media);
      case MediaType.audio:
        return _buildAudioViewer(media);
    }
  }

  Widget _buildImageViewer(MediaModel media) {
    // Create a mock message for the image widget
    final mockMessage = MessageModel(
      id: media.id,
      chatId: '',
      senderId: '',
      type: MessageType.image,
      content: media.caption ?? '',
      mediaUrl: media.url,
      thumbnailUrl: media.thumbnailUrl,
      createdAt: media.createdAt,
      updatedAt: media.createdAt,
      status: MessageStatusType.sent,
    );

    return ImageMessageWidget(
      message: mockMessage,
      isCurrentUser: widget.isCurrentUser,
      maxWidth: double.infinity,
      maxHeight: double.infinity,
    );
  }

  Widget _buildVideoViewer(MediaModel media) {
    // Create a mock message for the video widget
    final mockMessage = MessageModel(
      id: media.id,
      chatId: '',
      senderId: '',
      type: MessageType.video,
      content: media.caption ?? '',
      mediaUrl: media.url,
      thumbnailUrl: media.thumbnailUrl,
      createdAt: media.createdAt,
      updatedAt: media.createdAt,
      status: MessageStatusType.sent,
    );

    return VideoMessageWidget(
      message: mockMessage,
      isCurrentUser: widget.isCurrentUser,
      maxWidth: double.infinity,
      maxHeight: double.infinity,
    );
  }

  Widget _buildAudioViewer(MediaModel media) {
    // Create a mock message for the audio widget
    final mockMessage = MessageModel(
      id: media.id,
      chatId: '',
      senderId: '',
      type: MessageType.audio,
      content: media.caption ?? '',
      mediaUrl: media.url,
      createdAt: media.createdAt,
      updatedAt: media.createdAt,
      status: MessageStatusType.sent,
    );

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: AudioMessageWidget(
          message: mockMessage,
          isCurrentUser: widget.isCurrentUser,
          maxWidth: 400,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            // Media viewer
            GestureDetector(
              onTap: _toggleControls,
              child: Container(
                color: Colors.black,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemCount: widget.mediaItems.length,
                  itemBuilder: (context, index) {
                    return _buildMediaViewer(widget.mediaItems[index]);
                  },
                ),
              ),
            ),
            // Controls overlay
            AnimatedOpacity(
              opacity: _isControlsVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: _buildControlsOverlay(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsOverlay() {
    return Column(
      children: [
        // Top bar
        Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            bottom: 8,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black.withOpacity(0.7), Colors.transparent],
            ),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: _close,
                icon: const Icon(Icons.close, color: Colors.white),
              ),
              const Spacer(),
              Text(
                '${_currentIndex + 1} of ${widget.mediaItems.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  // Add more actions here
                },
                icon: const Icon(Icons.more_vert, color: Colors.white),
              ),
            ],
          ),
        ),
        const Spacer(),
        // Bottom bar with media info
        if (widget.mediaItems[_currentIndex].caption?.isNotEmpty == true)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withOpacity(0.7), Colors.transparent],
              ),
            ),
            child: Text(
              widget.mediaItems[_currentIndex].caption!,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }
}

enum GridLayoutType { auto, single, row, column, grid }

class GridLayoutConfig {
  final int crossAxisCount;
  final double childAspectRatio;
  final int rows;
  final int columns;
  final bool customLayout;

  GridLayoutConfig({
    required this.crossAxisCount,
    required this.childAspectRatio,
    required this.rows,
    required this.columns,
    this.customLayout = false,
  });
}
