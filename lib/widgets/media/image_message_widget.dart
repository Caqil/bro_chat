import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart' hide ImageInfo;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/utils/snackbar_utils.dart';
import '../../models/chat/message_model.dart';
import '../../models/file/file_model.dart';
import '../../providers/file/file_provider.dart';
import '../../services/media/image_service.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';

class ImageMessageWidget extends ConsumerStatefulWidget {
  final MessageModel message;
  final bool isCurrentUser;
  final double maxWidth;
  final double maxHeight;
  final List<MessageModel>? relatedImages; // For gallery view
  final VoidCallback? onDownloadStart;
  final VoidCallback? onDownloadComplete;
  final Function(String)? onError;

  const ImageMessageWidget({
    Key? key,
    required this.message,
    required this.isCurrentUser,
    this.maxWidth = 280,
    this.maxHeight = 400,
    this.relatedImages,
    this.onDownloadStart,
    this.onDownloadComplete,
    this.onError,
  }) : super(key: key);

  @override
  ConsumerState<ImageMessageWidget> createState() => _ImageMessageWidgetState();
}

class _ImageMessageWidgetState extends ConsumerState<ImageMessageWidget>
    with TickerProviderStateMixin {
  late AnimationController _loadingAnimationController;
  late AnimationController _scaleAnimationController;
  late Animation<double> _loadingAnimation;
  late Animation<double> _scaleAnimation;

  bool _isLoading = false;
  bool _isDownloading = false;
  bool _hasError = false;
  String? _errorMessage;
  String? _localFilePath;
  double _downloadProgress = 0.0;
  ImageDataInfo? _imageInfo;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _parseImageInfo();
    _checkLocalFile();
  }

  void _initializeAnimations() {
    _loadingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _loadingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _loadingAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _scaleAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _loadingAnimationController.repeat();
  }

  void _parseImageInfo() {
    try {
      final metadata = widget.message.metadata;
      if (metadata != null && metadata['image'] != null) {
        final imageData = metadata['image'] as Map<String, dynamic>;

        _imageInfo = ImageDataInfo(
          path: widget.message.mediaUrl ?? '', // ✅ Required: provide path
          name:
              imageData['name'] as String? ??
              'image.jpg', // ✅ Required: provide name
          width: imageData['width'] as int? ?? 0,
          height: imageData['height'] as int? ?? 0,
          fileSize:
              imageData['size'] as int? ??
              0, // ✅ Changed from 'size' to 'fileSize'
          format: _parseImageFormat(
            imageData['format'] as String?,
          ), // ✅ Convert String to ImageFormat enum
          createdAt: widget.message.createdAt, // ✅ Required: provide createdAt
          modifiedAt:
              widget.message.updatedAt, // ✅ Optional: provide modifiedAt
          metadata: imageData, // ✅ Optional: pass the metadata
        );
      }
    } catch (e) {
      widget.onError?.call('Failed to parse image information: $e');
    }
  }

  ImageFormat _parseImageFormat(String? formatString) {
    if (formatString == null) return ImageFormat.jpeg;

    switch (formatString.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return ImageFormat.jpeg;
      case 'png':
        return ImageFormat.png;
      case 'gif':
        return ImageFormat.gif;
      case 'bmp':
        return ImageFormat.bmp;
      case 'webp':
        return ImageFormat.webp;
      default:
        return ImageFormat.jpeg;
    }
  }

  Future<void> _checkLocalFile() async {
    if (widget.message.mediaUrl == null) return;

    try {
      // Check if file exists locally
      final fileNotifier = ref.read(
        fileProvider.notifier,
      ); // ✅ Renamed to fileNotifier
      final files = fileNotifier.files;

      // Find file by URL or message ID
      final fileInfo = files.values.firstWhere(
        (file) => file.url == widget.message.mediaUrl,
        orElse: () => FileInfo(
          id: '',
          name: '',
          path: '',
          type: FileType.audio,
          purpose: FilePurpose.message,
          size: 0,
          mimeType: 'audio/mpeg',
        ),
      );

      if (fileInfo.isDownloaded && File(fileInfo.path).existsSync()) {
        setState(() {
          _localFilePath = fileInfo.path;
        });
      }
    } catch (e) {
      if (mounted) {
        widget.onError?.call('Error checking local file: $e');
      }
    }
  }

  Future<void> _downloadImage() async {
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

      final fileNotifier = ref.read(
        fileProvider.notifier,
      ); // ✅ Renamed from fileProvider to fileNotifier
      final fileInfo = await fileNotifier.downloadFile(
        fileId,
      ); // ✅ Updated reference

      if (mounted) {
        setState(() {
          _localFilePath = fileInfo.path;
          _isDownloading = false;
          _downloadProgress = 1.0;
        });

        widget.onDownloadComplete?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });

        widget.onError?.call(e.toString());
      }
    }
  }

  Future<void> _saveToGallery() async {
    if (_localFilePath == null) {
      await _downloadImage();
      if (_localFilePath == null) return;
    }

    try {
      // Request storage permission
      final permission = await Permission.storage.request();
      if (!permission.isGranted) {
        throw Exception('Storage permission denied');
      }

      final imageBytes = await File(_localFilePath!).readAsBytes();
      final result = await ImageGallerySaver.saveImage(
        imageBytes,
        quality: 100,
        name: "image_${DateTime.now().millisecondsSinceEpoch}",
      );

      if (result['isSuccess'] == true) {
        SnackbarUtils.showSuccess(context, 'Image saved to gallery');
      } else {
        throw Exception('Failed to save image');
      }
    } catch (e) {
      SnackbarUtils.showError(context, 'Failed to save image: $e');
    }
  }

  Future<void> _shareImage() async {
    if (_localFilePath == null) {
      await _downloadImage();
      if (_localFilePath == null) return;
    }

    try {
      await Share.shareXFiles(
        [XFile(_localFilePath!)],
        text: widget.message.content.isNotEmpty
            ? widget.message.content
            : 'Image',
      );
    } catch (e) {
      SnackbarUtils.showError(context, 'Failed to share image: $e');
    }
  }

  void _openFullScreen() {
    _scaleAnimationController.forward().then((_) {
      _scaleAnimationController.reverse();
    });

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FullScreenImageViewer(
            message: widget.message,
            relatedImages: widget.relatedImages,
            localFilePath: _localFilePath,
            onSave: _saveToGallery,
            onShare: _shareImage,
            onDownload: _downloadImage,
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

  void _showImageActions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildImageActionsSheet(),
    );
  }

  Widget _buildImageActionsSheet() {
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
                  'Image Options',
                  style: AppTextStyles.h6.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildActionButton(
                  icon: Icons.zoom_in,
                  label: 'View Full Size',
                  onPressed: _openFullScreen,
                ),
                if (_localFilePath != null) ...[
                  _buildActionButton(
                    icon: Icons.save_alt,
                    label: 'Save to Gallery',
                    onPressed: _saveToGallery,
                  ),
                  _buildActionButton(
                    icon: Icons.share,
                    label: 'Share',
                    onPressed: _shareImage,
                  ),
                ] else ...[
                  _buildActionButton(
                    icon: Icons.download,
                    label: 'Download',
                    onPressed: _downloadImage,
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

  Widget _buildImageContainer() {
    final aspectRatio = _imageInfo?.aspectRatio ?? 1.0;
    final imageWidth = widget.maxWidth;
    final imageHeight = (imageWidth / aspectRatio).clamp(
      100.0,
      widget.maxHeight,
    );

    return Container(
      width: imageWidth,
      height: imageHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[200],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Main image
            Positioned.fill(child: _buildImage()),
            // Loading overlay
            if (_isLoading || _isDownloading)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isDownloading) ...[
                          CircularProgressIndicator(
                            value: _downloadProgress,
                            strokeWidth: 3,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${(_downloadProgress * 100).toInt()}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ] else ...[
                          AnimatedBuilder(
                            animation: _loadingAnimation,
                            builder: (context, child) {
                              return CircularProgressIndicator(
                                value: _loadingAnimation.value,
                                strokeWidth: 3,
                                backgroundColor: Colors.white.withOpacity(0.3),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            // Error overlay
            if (_hasError)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.white,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Failed to load',
                          style: AppTextStyles.body2.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _hasError = false;
                              _errorMessage = null;
                            });
                            if (_localFilePath == null) {
                              _downloadImage();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            // Action buttons overlay
            if (!_isLoading && !_isDownloading && !_hasError)
              Positioned(
                top: 8,
                right: 8,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildOverlayButton(
                      icon: Icons.more_vert,
                      onPressed: _showImageActions,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (_localFilePath != null) {
      return Image.file(
        File(_localFilePath!),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorPlaceholder();
        },
      );
    } else if (widget.message.mediaUrl != null) {
      return CachedNetworkImage(
        imageUrl: widget.message.mediaUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder: (context, url) => _buildLoadingPlaceholder(),
        errorWidget: (context, url, error) => _buildErrorPlaceholder(),
        progressIndicatorBuilder: (context, url, progress) {
          setState(() {
            _isLoading = true;
            _downloadProgress = progress.progress ?? 0.0;
          });
          return _buildLoadingPlaceholder();
        },
      );
    } else {
      return _buildErrorPlaceholder();
    }
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: Center(
        child: AnimatedBuilder(
          animation: _loadingAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: (0.5 + 0.5 * _loadingAnimation.value),
              child: Icon(Icons.image, size: 48, color: Colors.grey[600]),
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image, size: 48, color: Colors.grey[600]),
            const SizedBox(height: 8),
            Text(
              'Image not available',
              style: AppTextStyles.caption.copyWith(color: Colors.grey[600]),
            ),
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

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: _openFullScreen,
        child: Container(
          constraints: BoxConstraints(maxWidth: widget.maxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageContainer(),
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
      ),
    );
  }

  @override
  void dispose() {
    _loadingAnimationController.dispose();
    _scaleAnimationController.dispose();
    super.dispose();
  }
}

class FullScreenImageViewer extends StatefulWidget {
  final MessageModel message;
  final List<MessageModel>? relatedImages;
  final String? localFilePath;
  final VoidCallback? onSave;
  final VoidCallback? onShare;
  final VoidCallback? onDownload;

  const FullScreenImageViewer({
    Key? key,
    required this.message,
    this.relatedImages,
    this.localFilePath,
    this.onSave,
    this.onShare,
    this.onDownload,
  }) : super(key: key);

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  PageController? _pageController;
  int _currentIndex = 0;
  bool _isControlsVisible = true;

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

    if (widget.relatedImages != null) {
      _currentIndex = widget.relatedImages!.indexOf(widget.message);
      _pageController = PageController(initialPage: _currentIndex);
    }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            // Image viewer
            GestureDetector(
              onTap: _toggleControls,
              child: Container(
                color: Colors.black,
                child:
                    widget.relatedImages != null &&
                        widget.relatedImages!.length > 1
                    ? _buildGalleryView()
                    : _buildSingleImageView(),
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

  Widget _buildGalleryView() {
    return PhotoViewGallery.builder(
      pageController: _pageController,
      scrollPhysics: const BouncingScrollPhysics(),
      itemCount: widget.relatedImages!.length,
      onPageChanged: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      builder: (context, index) {
        final message = widget.relatedImages![index];
        return PhotoViewGalleryPageOptions(
          imageProvider: message.mediaUrl != null
              ? CachedNetworkImageProvider(message.mediaUrl!)
              : const AssetImage('assets/images/placeholder.png')
                    as ImageProvider,
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 3.0,
          heroAttributes: PhotoViewHeroAttributes(tag: message.id),
        );
      },
    );
  }

  Widget _buildSingleImageView() {
    return PhotoView(
      imageProvider: widget.localFilePath != null
          ? FileImage(File(widget.localFilePath!))
          : widget.message.mediaUrl != null
          ? CachedNetworkImageProvider(widget.message.mediaUrl!)
          : const AssetImage('assets/images/placeholder.png') as ImageProvider,
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.covered * 3.0,
      heroAttributes: PhotoViewHeroAttributes(tag: widget.message.id),
      backgroundDecoration: const BoxDecoration(color: Colors.black),
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
              if (widget.relatedImages != null &&
                  widget.relatedImages!.length > 1)
                Text(
                  '${_currentIndex + 1} of ${widget.relatedImages!.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              const Spacer(),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                color: Colors.white,
                onSelected: (value) {
                  switch (value) {
                    case 'save':
                      widget.onSave?.call();
                      break;
                    case 'share':
                      widget.onShare?.call();
                      break;
                    case 'download':
                      widget.onDownload?.call();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  if (widget.localFilePath != null) ...[
                    const PopupMenuItem(
                      value: 'save',
                      child: Row(
                        children: [
                          Icon(Icons.save_alt),
                          SizedBox(width: 8),
                          Text('Save to Gallery'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(Icons.share),
                          SizedBox(width: 8),
                          Text('Share'),
                        ],
                      ),
                    ),
                  ] else ...[
                    const PopupMenuItem(
                      value: 'download',
                      child: Row(
                        children: [
                          Icon(Icons.download),
                          SizedBox(width: 8),
                          Text('Download'),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const Spacer(),
        // Bottom bar with message info
        if (widget.message.content.isNotEmpty)
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
              widget.message.content,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pageController?.dispose();
    super.dispose();
  }
}
