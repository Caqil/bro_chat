import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfilePictureWidget extends StatefulWidget {
  final String? imageUrl;
  final File? imageFile;
  final Uint8List? imageBytes;
  final ValueChanged<File?>? onImageSelected;
  final ValueChanged<Uint8List?>? onImageBytesSelected;
  final VoidCallback? onImageRemoved;
  final double size;
  final bool enabled;
  final bool showEditButton;
  final bool showRemoveButton;
  final String? placeholder;
  final String? name;
  final Color? backgroundColor;
  final Color? textColor;
  final BorderRadius? borderRadius;
  final BoxBorder? border;
  final bool showUploadProgress;
  final double? uploadProgress;
  final String? errorText;

  const ProfilePictureWidget({
    super.key,
    this.imageUrl,
    this.imageFile,
    this.imageBytes,
    this.onImageSelected,
    this.onImageBytesSelected,
    this.onImageRemoved,
    this.size = 100,
    this.enabled = true,
    this.showEditButton = true,
    this.showRemoveButton = true,
    this.placeholder,
    this.name,
    this.backgroundColor,
    this.textColor,
    this.borderRadius,
    this.border,
    this.showUploadProgress = false,
    this.uploadProgress,
    this.errorText,
  });

  @override
  State<ProfilePictureWidget> createState() => _ProfilePictureWidgetState();
}

class _ProfilePictureWidgetState extends State<ProfilePictureWidget>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });

    if (isHovered) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  Future<void> _showImageSourceDialog() async {
    if (!widget.enabled) return;

    showDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: const Text('Select Profile Picture'),
        actions: [
          ShadButton.ghost(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Camera option
            ShadButton.outline(
              onPressed: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
              child: const Row(
                children: [
                  Icon(Icons.camera_alt),
                  SizedBox(width: 12),
                  Text('Take Photo'),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Gallery option
            ShadButton.outline(
              onPressed: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
              child: const Row(
                children: [
                  Icon(Icons.photo_library),
                  SizedBox(width: 12),
                  Text('Choose from Gallery'),
                ],
              ),
            ),

            // Remove option (if image exists)
            if (_hasImage() && widget.showRemoveButton) ...[
              const SizedBox(height: 12),
              ShadButton.outline(
                onPressed: () {
                  Navigator.of(context).pop();
                  _removeImage();
                },
                child: const Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Remove Photo', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);
        final Uint8List imageBytes = await imageFile.readAsBytes();

        widget.onImageSelected?.call(imageFile);
        widget.onImageBytesSelected?.call(imageBytes);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeImage() {
    widget.onImageSelected?.call(null);
    widget.onImageBytesSelected?.call(null);
    widget.onImageRemoved?.call();
  }

  bool _hasImage() {
    return widget.imageUrl != null ||
        widget.imageFile != null ||
        widget.imageBytes != null;
  }

  Widget _buildImageWidget() {
    if (widget.imageBytes != null) {
      return Image.memory(
        widget.imageBytes!,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
      );
    } else if (widget.imageFile != null) {
      return Image.file(
        widget.imageFile!,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
      );
    } else if (widget.imageUrl != null) {
      return CachedNetworkImage(
        imageUrl: widget.imageUrl!,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
        placeholder: (context, url) => const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (context, url, error) => _buildPlaceholder(),
      );
    } else {
      return _buildPlaceholder();
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Colors.grey[200],
        borderRadius:
            widget.borderRadius ?? BorderRadius.circular(widget.size / 2),
      ),
      child: widget.name != null
          ? Center(
              child: Text(
                _getInitials(widget.name!),
                style: TextStyle(
                  fontSize: widget.size * 0.3,
                  fontWeight: FontWeight.w600,
                  color: widget.textColor ?? Colors.grey[600],
                ),
              ),
            )
          : Icon(
              Icons.person,
              size: widget.size * 0.5,
              color: widget.textColor ?? Colors.grey[600],
            ),
    );
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

  Widget _buildEditButton() {
    if (!widget.showEditButton || !widget.enabled)
      return const SizedBox.shrink();

    return Positioned(
      bottom: 0,
      right: 0,
      child: ShadButton.secondary(
        onPressed: _showImageSourceDialog,
        size: ShadButtonSize.sm,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildUploadProgress() {
    if (!widget.showUploadProgress || widget.uploadProgress == null) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius:
              widget.borderRadius ?? BorderRadius.circular(widget.size / 2),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  value: widget.uploadProgress,
                  strokeWidth: 3,
                  backgroundColor: Colors.white30,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(widget.uploadProgress! * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MouseRegion(
          onEnter: (_) => _onHover(true),
          onExit: (_) => _onHover(false),
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: GestureDetector(
                  onTap: widget.enabled ? _showImageSourceDialog : null,
                  child: Stack(
                    children: [
                      Container(
                        width: widget.size,
                        height: widget.size,
                        decoration: BoxDecoration(
                          borderRadius:
                              widget.borderRadius ??
                              BorderRadius.circular(widget.size / 2),
                          border: widget.border,
                        ),
                        child: ClipRRect(
                          borderRadius:
                              widget.borderRadius ??
                              BorderRadius.circular(widget.size / 2),
                          child: _buildImageWidget(),
                        ),
                      ),

                      // Hover overlay
                      if (_isHovered && widget.enabled)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius:
                                  widget.borderRadius ??
                                  BorderRadius.circular(widget.size / 2),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ),

                      _buildEditButton(),
                      _buildUploadProgress(),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        if (widget.placeholder != null && !_hasImage()) ...[
          const SizedBox(height: 8),
          Text(
            widget.placeholder!,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],

        if (widget.errorText != null) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 16),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  widget.errorText!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// Simplified version for smaller use cases
class SimpleAvatarWidget extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double size;
  final VoidCallback? onTap;
  final bool showOnlineIndicator;
  final bool isOnline;

  const SimpleAvatarWidget({
    super.key,
    this.imageUrl,
    this.name,
    this.size = 40,
    this.onTap,
    this.showOnlineIndicator = false,
    this.isOnline = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey[300]!, width: 1),
            ),
            child: ClipOval(
              child: imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: imageUrl!,
                      width: size,
                      height: size,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => _buildPlaceholder(),
                      errorWidget: (context, url, error) => _buildPlaceholder(),
                    )
                  : _buildPlaceholder(),
            ),
          ),

          if (showOnlineIndicator)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: size * 0.25,
                height: size * 0.25,
                decoration: BoxDecoration(
                  color: isOnline ? Colors.green : Colors.grey,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: size,
      height: size,
      color: Colors.grey[200],
      child: name != null
          ? Center(
              child: Text(
                _getInitials(name!),
                style: TextStyle(
                  fontSize: size * 0.3,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
            )
          : Icon(Icons.person, size: size * 0.5, color: Colors.grey[600]),
    );
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
}

// Group avatar widget for displaying multiple users
class GroupAvatarWidget extends StatelessWidget {
  final List<String?> imageUrls;
  final List<String> names;
  final double size;
  final VoidCallback? onTap;
  final int maxAvatars;

  const GroupAvatarWidget({
    super.key,
    required this.imageUrls,
    required this.names,
    this.size = 40,
    this.onTap,
    this.maxAvatars = 3,
  });

  @override
  Widget build(BuildContext context) {
    final displayCount = imageUrls.length.clamp(0, maxAvatars);
    final remainingCount = imageUrls.length - maxAvatars;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size + (displayCount - 1) * (size * 0.3),
        height: size,
        child: Stack(
          children: [
            for (int i = 0; i < displayCount; i++)
              Positioned(
                left: i * (size * 0.3),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: SimpleAvatarWidget(
                    imageUrl: i < imageUrls.length ? imageUrls[i] : null,
                    name: i < names.length ? names[i] : null,
                    size: size * 0.8,
                  ),
                ),
              ),

            if (remainingCount > 0)
              Positioned(
                left: maxAvatars * (size * 0.3),
                child: Container(
                  width: size * 0.8,
                  height: size * 0.8,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      '+$remainingCount',
                      style: TextStyle(
                        fontSize: size * 0.2,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
