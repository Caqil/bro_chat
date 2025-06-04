import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../models/chat/message_model.dart';
import '../../models/file/file_model.dart';
import '../../providers/file/file_provider.dart';
import '../../services/media/video_service.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import 'media_thumbnail.dart';

class VideoMessageWidget extends ConsumerStatefulWidget {
  final MessageModel message;
  final bool isCurrentUser;
  final double maxWidth;
  final double maxHeight;
  final bool autoPlay;
  final bool showControls;
  final bool allowFullScreen;
  final VoidCallback? onDownloadStart;
  final VoidCallback? onDownloadComplete;
  final Function(String)? onError;

  const VideoMessageWidget({
    Key? key,
    required this.message,
    required this.isCurrentUser,
    this.maxWidth = 280,
    this.maxHeight = 400,
    this.autoPlay = false,
    this.showControls = true,
    this.allowFullScreen = true,
    this.onDownloadStart,
    this.onDownloadComplete,
    this.onError,
  }) : super(key: key);

  @override
  ConsumerState<VideoMessageWidget> createState() => _VideoMessageWidgetState();
}

class _VideoMessageWidgetState extends ConsumerState<VideoMessageWidget>
    with TickerProviderStateMixin {
  late AnimationController _fadeAnimationController;
  late AnimationController _scaleAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  String? _localFilePath;
  bool _isLoading = false;
  bool _isDownloading = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _isInitialized = false;
  bool _showControls = true;
  double _downloadProgress = 0.0;
  VideoInfo? _videoInfo;

  // Control visibility timer
  Timer? _controlsTimer;
  static const Duration _controlsTimeout = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _parseVideoInfo();
    _checkLocalFile();
  }

  void _initializeAnimations() {
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _scaleAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _parseVideoInfo() {
    try {
      final metadata = widget.message.metadata;
      if (metadata != null && metadata['video'] != null) {
        final videoData = metadata['video'] as Map<String, dynamic>;

        _videoInfo = VideoInfo(
          width: videoData['width'] as int? ?? 0,
          height: videoData['height'] as int? ?? 0,
          duration: videoData['duration'] != null
              ? Duration(seconds: videoData['duration'] as int)
              : null,
          size: videoData['size'] as int? ?? 0,
          format: videoData['format'] as String?,
          bitrate: videoData['bitrate'] as int?,
          fps: videoData['fps'] as double?,
        );
      }
    } catch (e) {
      widget.onError?.call('Failed to parse video information: $e');
    }
  }

  Future<void> _checkLocalFile() async {
    if (widget.message.mediaUrl == null) return;

    try {
      final fileProvider = ref.read(fileProvider.notifier);
      final files = fileProvider.files;

      final fileInfo = files.values.firstWhere(
        (file) => file.url == widget.message.mediaUrl,
        orElse: () => FileInfo(
          id: '',
          name: '',
          path: '',
          type: FileType.video,
          purpose: FilePurpose.message,
          size: 0,
          mimeType: 'video/mp4',
        ),
      );

      if (fileInfo.isDownloaded && File(fileInfo.path).existsSync()) {
        setState(() {
          _localFilePath = fileInfo.path;
        });

        if (widget.autoPlay) {
          await _initializeVideo();
        }
      }
    } catch (e) {
      if (mounted) {
        widget.onError?.call('Error checking local file: $e');
      }
    }
  }

  Future<void> _downloadVideo() async {
    if (widget.message.mediaUrl == null || _isDownloading) return;

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _hasError = false;
      _errorMessage = null;
    });

    widget.onDownloadStart?.call();

    try {
      final fileId = widget.message.metadata?['file_id'] as String?;
      if (fileId == null) {
        throw Exception('File ID not found in message metadata');
      }

      final fileProvider = ref.read(fileProvider.notifier);
      final fileInfo = await fileProvider.downloadFile(fileId);

      if (mounted) {
        setState(() {
          _localFilePath = fileInfo.path;
          _isDownloading = false;
          _downloadProgress = 1.0;
        });

        widget.onDownloadComplete?.call();

        SnackbarUtils.showSuccess(context, 'Video downloaded successfully');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });

        widget.onError?.call(e.toString());

        SnackbarUtils.showError(context, 'Failed to download video: $e');
      }
    }
  }

  Future<void> _initializeVideo() async {
    if (_localFilePath == null) {
      await _downloadVideo();
      if (_localFilePath == null) return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      _videoController = VideoPlayerController.file(File(_localFilePath!));
      await _videoController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        aspectRatio: _videoController!.value.aspectRatio,
        autoPlay: widget.autoPlay,
        looping: false,
        showControls: widget.showControls,
        allowFullScreen: widget.allowFullScreen,
        allowMuting: true,
        allowPlaybackSpeedChanging: true,
        showControlsOnInitialize: true,
        controlsSafeAreaMinimum: const EdgeInsets.all(12),
        hideControlsTimer: _controlsTimeout,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primary,
          handleColor: AppColors.primary,
          backgroundColor: Colors.grey.withOpacity(0.3),
          bufferedColor: AppColors.primary.withOpacity(0.3),
        ),
        placeholder: _buildVideoPlaceholder(),
        autoInitialize: true,
      );

      _fadeAnimationController.forward();

      setState(() {
        _isInitialized = true;
        _isLoading = false;
      });

      // Setup video event listeners
      _videoController!.addListener(_videoListener);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });

      widget.onError?.call(e.toString());
    }
  }

  void _videoListener() {
    if (!mounted) return;

    final controller = _videoController!;

    // Handle video completion
    if (controller.value.position >= controller.value.duration) {
      _resetControlsTimer();
    }

    // Handle errors
    if (controller.value.hasError) {
      setState(() {
        _hasError = true;
        _errorMessage = controller.value.errorDescription;
      });
    }
  }

  void _resetControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(_controlsTimeout, () {
      if (mounted && _videoController?.value.isPlaying == true) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });

    if (_showControls) {
      _resetControlsTimer();
    } else {
      _controlsTimer?.cancel();
    }
  }

  Future<void> _playPause() async {
    if (_videoController == null) return;

    if (_videoController!.value.isPlaying) {
      await _videoController!.pause();
    } else {
      await _videoController!.play();
      _resetControlsTimer();
    }
  }

  Future<void> _seekTo(Duration position) async {
    if (_videoController == null) return;

    await _videoController!.seekTo(position);
  }

  Future<void> _saveToGallery() async {
    if (_localFilePath == null) {
      await _downloadVideo();
      if (_localFilePath == null) return;
    }

    try {
      // Request storage permission
      final permission = await Permission.storage.request();
      if (!permission.isGranted) {
        throw Exception('Storage permission denied');
      }

      final result = await ImageGallerySaver.saveFile(
        _localFilePath!,
        name: "video_${DateTime.now().millisecondsSinceEpoch}",
      );

      if (result['isSuccess'] == true) {
        SnackbarUtils.showSuccess(context, 'Video saved to gallery');
      } else {
        throw Exception('Failed to save video');
      }
    } catch (e) {
      SnackbarUtils.showError(context, 'Failed to save video: $e');
    }
  }

  Future<void> _shareVideo() async {
    if (_localFilePath == null) {
      await _downloadVideo();
      if (_localFilePath == null) return;
    }

    try {
      await Share.shareXFiles(
        [XFile(_localFilePath!)],
        text: widget.message.content.isNotEmpty
            ? widget.message.content
            : 'Video',
      );
    } catch (e) {
      SnackbarUtils.showError(context, 'Failed to share video: $e');
    }
  }

  void _openFullScreen() {
    _scaleAnimationController.forward().then((_) {
      _scaleAnimationController.reverse();
    });

    if (_chewieController != null) {
      Navigator.of(context).push(
        PageRouteBuilder(
          opaque: false,
          barrierColor: Colors.black,
          pageBuilder: (context, animation, secondaryAnimation) {
            return FullScreenVideoPlayer(
              chewieController: _chewieController!,
              onSave: _saveToGallery,
              onShare: _shareVideo,
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
  }

  void _showVideoActions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildVideoActionsSheet(),
    );
  }

  Widget _buildVideoActionsSheet() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Video Options',
                  style: AppTextStyles.h6.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (_isInitialized) ...[
                  _buildActionButton(
                    icon: Icons.fullscreen,
                    label: 'Full Screen',
                    onPressed: _openFullScreen,
                  ),
                  _buildActionButton(
                    icon: Icons.save_alt,
                    label: 'Save to Gallery',
                    onPressed: _saveToGallery,
                  ),
                  _buildActionButton(
                    icon: Icons.share,
                    label: 'Share',
                    onPressed: _shareVideo,
                  ),
                ] else if (_localFilePath != null) ...[
                  _buildActionButton(
                    icon: Icons.play_arrow,
                    label: 'Play Video',
                    onPressed: _initializeVideo,
                  ),
                ] else ...[
                  _buildActionButton(
                    icon: Icons.download,
                    label: 'Download',
                    onPressed: _downloadVideo,
                    isLoading: _isDownloading,
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          foregroundColor: AppColors.primary,
          backgroundColor: AppColors.primary.withOpacity(0.1),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoContainer() {
    final aspectRatio = _videoInfo?.aspectRatio ?? 16 / 9;
    final containerWidth = widget.maxWidth;
    final containerHeight = (containerWidth / aspectRatio).clamp(
      100.0,
      widget.maxHeight,
    );

    return Container(
      width: containerWidth,
      height: containerHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Video player or thumbnail
            Positioned.fill(child: _buildVideoContent()),
            // Loading overlay
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading video...',
                          style: AppTextStyles.body2.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            // Download progress overlay
            if (_isDownloading)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.7),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          value: _downloadProgress,
                          strokeWidth: 4,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Downloading... ${(_downloadProgress * 100).toInt()}%',
                          style: AppTextStyles.body2.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            // Error overlay
            if (_hasError)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.7),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.white,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load video',
                          style: AppTextStyles.subtitle1.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _errorMessage!,
                            style: AppTextStyles.body2.copyWith(
                              color: Colors.white.withOpacity(0.8),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _hasError = false;
                              _errorMessage = null;
                            });
                            if (_localFilePath == null) {
                              _downloadVideo();
                            } else {
                              _initializeVideo();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primary,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            // Action buttons overlay
            if (!_isLoading && !_isDownloading && !_hasError && !_isInitialized)
              Positioned(
                top: 8,
                right: 8,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildOverlayButton(
                      icon: Icons.more_vert,
                      onPressed: _showVideoActions,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoContent() {
    if (_isInitialized && _chewieController != null) {
      return FadeTransition(
        opacity: _fadeAnimation,
        child: Chewie(controller: _chewieController!),
      );
    } else if (widget.message.thumbnailUrl != null || _localFilePath != null) {
      return GestureDetector(
        onTap: () {
          if (_localFilePath != null) {
            _initializeVideo();
          } else {
            _downloadVideo();
          }
        },
        child: Stack(
          children: [
            MediaThumbnail(
              url: widget.message.mediaUrl ?? '',
              thumbnailUrl: widget.message.thumbnailUrl,
              type: ThumbnailType.video,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              duration: _videoInfo?.duration,
              showPlayButton: true,
              showDuration: true,
            ),
            // Play button overlay
            Positioned.fill(
              child: Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _localFilePath != null ? Icons.play_arrow : Icons.download,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return _buildVideoPlaceholder();
    }
  }

  Widget _buildVideoPlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.video_file, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              'Video',
              style: AppTextStyles.subtitle1.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_videoInfo?.duration != null) ...[
              const SizedBox(height: 8),
              Text(
                _formatDuration(_videoInfo!.duration!),
                style: AppTextStyles.body2.copyWith(color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOverlayButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 20),
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      ),
    );
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
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        constraints: BoxConstraints(maxWidth: widget.maxWidth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVideoContainer(),
            if (widget.message.content.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  widget.message.content,
                  style: AppTextStyles.body2.copyWith(
                    color: widget.isCurrentUser
                        ? Colors.white
                        : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    _fadeAnimationController.dispose();
    _scaleAnimationController.dispose();
    _videoController?.removeListener(_videoListener);
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }
}

class FullScreenVideoPlayer extends StatefulWidget {
  final ChewieController chewieController;
  final VoidCallback? onSave;
  final VoidCallback? onShare;

  const FullScreenVideoPlayer({
    Key? key,
    required this.chewieController,
    this.onSave,
    this.onShare,
  }) : super(key: key);

  @override
  State<FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<FullScreenVideoPlayer>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_fadeController);

    _fadeController.forward();

    // Set orientation to landscape for better viewing
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Hide system UI for immersive experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }

  void _close() {
    _fadeController.reverse().then((_) {
      // Restore orientation and system UI
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            // Video player
            Positioned.fill(child: Chewie(controller: widget.chewieController)),
            // Close button
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: _close,
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            ),
            // Action buttons
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              child: Row(
                children: [
                  if (widget.onSave != null)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: widget.onSave,
                        icon: const Icon(Icons.save_alt, color: Colors.white),
                      ),
                    ),
                  if (widget.onShare != null)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: widget.onShare,
                        icon: const Icon(Icons.share, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }
}

class VideoInfo {
  final int width;
  final int height;
  final Duration? duration;
  final int size;
  final String? format;
  final int? bitrate;
  final double? fps;

  VideoInfo({
    required this.width,
    required this.height,
    this.duration,
    required this.size,
    this.format,
    this.bitrate,
    this.fps,
  });

  double get aspectRatio => width > 0 && height > 0 ? width / height : 16 / 9;
  bool get isPortrait => height > width;
  bool get isLandscape => width > height;
  bool get isSquare => width == height;
}
