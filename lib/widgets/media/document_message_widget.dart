import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
import 'package:mime/mime.dart';

import '../../models/chat/message_model.dart';
import '../../models/file/file_model.dart';
import '../../providers/file/file_provider.dart';
import '../../core/utils/file_utils.dart' hide FileInfo;
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';

class DocumentMessageWidget extends ConsumerStatefulWidget {
  final MessageModel message;
  final bool isCurrentUser;
  final double maxWidth;
  final VoidCallback? onDownloadStart;
  final VoidCallback? onDownloadComplete;
  final Function(String)? onError;

  const DocumentMessageWidget({
    Key? key,
    required this.message,
    required this.isCurrentUser,
    this.maxWidth = 280,
    this.onDownloadStart,
    this.onDownloadComplete,
    this.onError,
  }) : super(key: key);

  @override
  ConsumerState<DocumentMessageWidget> createState() =>
      _DocumentMessageWidgetState();
}

class _DocumentMessageWidgetState extends ConsumerState<DocumentMessageWidget>
    with TickerProviderStateMixin {
  late AnimationController _downloadAnimationController;
  late AnimationController _hoverAnimationController;
  late Animation<double> _downloadAnimation;
  late Animation<double> _hoverAnimation;

  bool _isDownloading = false;
  bool _isHovered = false;
  bool _hasError = false;
  String? _errorMessage;
  String? _localFilePath;
  double _downloadProgress = 0.0;
  DocumentInfo? _documentInfo;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _parseDocumentInfo();
    _checkLocalFile();
  }

  void _initializeAnimations() {
    _downloadAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _hoverAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _downloadAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _downloadAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _hoverAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _hoverAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _parseDocumentInfo() {
    try {
      final metadata = widget.message.metadata;
      if (metadata != null && metadata['document'] != null) {
        final docData = metadata['document'] as Map<String, dynamic>;

        _documentInfo = DocumentInfo(
          name: docData['name'] as String? ?? 'Unknown Document',
          size: docData['size'] as int? ?? 0,
          mimeType:
              docData['mime_type'] as String? ?? 'application/octet-stream',
          extension: docData['extension'] as String?,
          pageCount: docData['page_count'] as int?,
          author: docData['author'] as String?,
          createdAt: docData['created_at'] != null
              ? DateTime.tryParse(docData['created_at'] as String)
              : null,
          modifiedAt: docData['modified_at'] != null
              ? DateTime.tryParse(docData['modified_at'] as String)
              : null,
        );
      } else {
        // Fallback: extract info from URL or message content
        final url = widget.message.mediaUrl;
        if (url != null) {
          final fileName = url.split('/').last;
          final mimeType =
              lookupMimeType(fileName) ?? 'application/octet-stream';

          _documentInfo = DocumentInfo(
            name: fileName,
            size: 0,
            mimeType: mimeType,
            extension: fileName.contains('.') ? fileName.split('.').last : null,
          );
        }
      }
    } catch (e) {
      widget.onError?.call('Failed to parse document information: $e');
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
          type: FileType.document,
          purpose: FilePurpose.message,
          size: 0,
          mimeType: 'application/octet-stream',
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

  Future<void> _downloadDocument() async {
    if (widget.message.mediaUrl == null || _isDownloading) return;

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _hasError = false;
      _errorMessage = null;
    });

    _downloadAnimationController.forward();
    widget.onDownloadStart?.call();

    try {
      final fileId = widget.message.metadata?['file_id'] as String?;
      if (fileId == null) {
        throw Exception('File ID not found in message metadata');
      }

      final fileProvider = ref.read(fileProvider.notifier);

      // Listen to download progress
      final fileInfo = await fileProvider.downloadFile(fileId);

      if (mounted) {
        setState(() {
          _localFilePath = fileInfo.path;
          _isDownloading = false;
          _downloadProgress = 1.0;
        });

        _downloadAnimationController.reset();
        widget.onDownloadComplete?.call();

        SnackbarUtils.showSuccess(context, 'Document downloaded successfully');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });

        _downloadAnimationController.reset();
        widget.onError?.call(e.toString());

        SnackbarUtils.showError(context, 'Failed to download document: $e');
      }
    }
  }

  Future<void> _openDocument() async {
    if (_localFilePath == null) {
      await _downloadDocument();
      if (_localFilePath == null) return;
    }

    try {
      final result = await OpenFile.open(_localFilePath!);

      if (result.type != ResultType.done) {
        throw Exception('Cannot open document: ${result.message}');
      }
    } catch (e) {
      SnackbarUtils.showError(context, 'Failed to open document: $e');
    }
  }

  Future<void> _shareDocument() async {
    if (_localFilePath == null) {
      await _downloadDocument();
      if (_localFilePath == null) return;
    }

    try {
      await Share.shareXFiles([
        XFile(_localFilePath!),
      ], text: _documentInfo?.name ?? 'Document');
    } catch (e) {
      SnackbarUtils.showError(context, 'Failed to share document: $e');
    }
  }

  Future<void> _saveToDownloads() async {
    if (_localFilePath == null) return;

    try {
      final downloadsDir = await getExternalStorageDirectory();
      if (downloadsDir == null) {
        throw Exception('Cannot access downloads directory');
      }

      final fileName = _documentInfo?.name ?? 'document';
      final savePath = '${downloadsDir.path}/Download/$fileName';

      await File(_localFilePath!).copy(savePath);

      SnackbarUtils.showSuccess(context, 'Document saved to Downloads');
    } catch (e) {
      SnackbarUtils.showError(context, 'Failed to save document: $e');
    }
  }

  void _showDocumentActions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildDocumentActionsSheet(),
    );
  }

  Widget _buildDocumentActionsSheet() {
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
                  _documentInfo?.name ?? 'Document',
                  style: AppTextStyles.h6.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                if (_localFilePath != null) ...[
                  _buildActionButton(
                    icon: Icons.open_in_new,
                    label: 'Open',
                    onPressed: _openDocument,
                  ),
                  _buildActionButton(
                    icon: Icons.share,
                    label: 'Share',
                    onPressed: _shareDocument,
                  ),
                  _buildActionButton(
                    icon: Icons.download,
                    label: 'Save to Downloads',
                    onPressed: _saveToDownloads,
                  ),
                ] else ...[
                  _buildActionButton(
                    icon: Icons.download,
                    label: 'Download',
                    onPressed: _downloadDocument,
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

  Widget _buildDocumentIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: _getDocumentColor(),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _getDocumentColor().withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(_getDocumentIcon(), color: Colors.white, size: 24),
          ),
          if (_isDownloading)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _downloadAnimation,
                builder: (context, child) {
                  return CircularProgressIndicator(
                    value: _downloadProgress,
                    strokeWidth: 3,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  );
                },
              ),
            ),
          if (_hasError)
            Positioned(
              top: 2,
              right: 2,
              child: Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error, color: Colors.white, size: 12),
              ),
            ),
        ],
      ),
    );
  }

  Color _getDocumentColor() {
    if (_documentInfo?.mimeType == null) return AppColors.iconSecondary;

    final mimeType = _documentInfo!.mimeType;

    if (mimeType.contains('pdf')) return Colors.red;
    if (mimeType.contains('word') || mimeType.contains('document')) {
      return Colors.blue;
    }
    if (mimeType.contains('sheet') || mimeType.contains('excel')) {
      return Colors.green;
    }
    if (mimeType.contains('presentation') || mimeType.contains('powerpoint')) {
      return Colors.orange;
    }
    if (mimeType.contains('text')) return Colors.purple;
    if (mimeType.contains('zip') || mimeType.contains('archive')) {
      return Colors.brown;
    }

    return AppColors.textSecondaryDark;
  }

  IconData _getDocumentIcon() {
    if (_documentInfo?.mimeType == null) return Icons.description;

    final mimeType = _documentInfo!.mimeType;

    if (mimeType.contains('pdf')) return Icons.picture_as_pdf;
    if (mimeType.contains('word') || mimeType.contains('document')) {
      return Icons.description;
    }
    if (mimeType.contains('sheet') || mimeType.contains('excel')) {
      return Icons.table_chart;
    }
    if (mimeType.contains('presentation') || mimeType.contains('powerpoint')) {
      return Icons.slideshow;
    }
    if (mimeType.contains('text')) return Icons.text_snippet;
    if (mimeType.contains('zip') || mimeType.contains('archive')) {
      return Icons.archive;
    }
    if (mimeType.contains('image')) return Icons.image;
    if (mimeType.contains('video')) return Icons.video_file;
    if (mimeType.contains('audio')) return Icons.audio_file;

    return Icons.insert_drive_file;
  }

  Widget _buildDocumentInfo() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _documentInfo?.name ?? 'Unknown Document',
            style: AppTextStyles.subtitle2.copyWith(
              color: widget.isCurrentUser
                  ? Colors.white
                  : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              if (_documentInfo?.size != null && _documentInfo!.size > 0) ...[
                Text(
                  FileUtils.formatFileSize(_documentInfo!.size),
                  style: AppTextStyles.caption.copyWith(
                    color: widget.isCurrentUser
                        ? Colors.white.withOpacity(0.8)
                        : AppColors.textSecondary,
                  ),
                ),
                if (_documentInfo?.extension != null) ...[
                  Text(
                    ' • ',
                    style: AppTextStyles.caption.copyWith(
                      color: widget.isCurrentUser
                          ? Colors.white.withOpacity(0.6)
                          : AppColors.textSecondary.withOpacity(0.6),
                    ),
                  ),
                  Text(
                    _documentInfo!.extension!.toUpperCase(),
                    style: AppTextStyles.caption.copyWith(
                      color: widget.isCurrentUser
                          ? Colors.white.withOpacity(0.8)
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ],
          ),
          if (_documentInfo?.pageCount != null) ...[
            const SizedBox(height: 2),
            Text(
              '${_documentInfo!.pageCount} pages',
              style: AppTextStyles.caption.copyWith(
                color: widget.isCurrentUser
                    ? Colors.white.withOpacity(0.7)
                    : AppColors.textSecondary.withOpacity(0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_localFilePath != null)
          IconButton(
            onPressed: _openDocument,
            icon: Icon(
              Icons.open_in_new,
              color: widget.isCurrentUser
                  ? Colors.white.withOpacity(0.8)
                  : AppColors.primary,
              size: 20,
            ),
            tooltip: 'Open',
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          )
        else
          IconButton(
            onPressed: _isDownloading ? null : _downloadDocument,
            icon: _isDownloading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        widget.isCurrentUser
                            ? Colors.white.withOpacity(0.8)
                            : AppColors.primary,
                      ),
                    ),
                  )
                : Icon(
                    Icons.download,
                    color: widget.isCurrentUser
                        ? Colors.white.withOpacity(0.8)
                        : AppColors.primary,
                    size: 20,
                  ),
            tooltip: 'Download',
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        IconButton(
          onPressed: _showDocumentActions,
          icon: Icon(
            Icons.more_vert,
            color: widget.isCurrentUser
                ? Colors.white.withOpacity(0.8)
                : AppColors.primary,
            size: 20,
          ),
          tooltip: 'More options',
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ],
    );
  }

  Widget _buildDownloadProgress() {
    if (!_isDownloading) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: _downloadProgress,
            backgroundColor: Colors.grey.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(
              widget.isCurrentUser ? Colors.white : AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Downloading... ${(_downloadProgress * 100).toInt()}%',
            style: AppTextStyles.caption.copyWith(
              color: widget.isCurrentUser
                  ? Colors.white.withOpacity(0.7)
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    if (!_hasError) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage ?? 'Failed to download document',
              style: AppTextStyles.caption.copyWith(color: Colors.red),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _hasError = false;
                _errorMessage = null;
              });
              _downloadDocument();
            },
            child: Text(
              'Retry',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_documentInfo == null) {
      return Container(
        constraints: BoxConstraints(maxWidth: widget.maxWidth),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: widget.isCurrentUser
                  ? Colors.white.withOpacity(0.8)
                  : AppColors.error,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Unable to load document information',
                style: AppTextStyles.body2.copyWith(
                  color: widget.isCurrentUser
                      ? Colors.white.withOpacity(0.8)
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ScaleTransition(
      scale: _hoverAnimation,
      child: MouseRegion(
        onEnter: (_) {
          setState(() => _isHovered = true);
          _hoverAnimationController.forward();
        },
        onExit: (_) {
          setState(() => _isHovered = false);
          _hoverAnimationController.reverse();
        },
        child: GestureDetector(
          onTap: () {
            if (_localFilePath != null) {
              _openDocument();
            } else {
              _downloadDocument();
            }
          },
          child: Container(
            constraints: BoxConstraints(maxWidth: widget.maxWidth),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildDocumentIcon(),
                    const SizedBox(width: 12),
                    _buildDocumentInfo(),
                    _buildQuickActions(),
                  ],
                ),
                _buildDownloadProgress(),
                _buildErrorMessage(),
                if (widget.message.content.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    widget.message.content,
                    style: AppTextStyles.body2.copyWith(
                      color: widget.isCurrentUser
                          ? Colors.white
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _downloadAnimationController.dispose();
    _hoverAnimationController.dispose();
    super.dispose();
  }
}

class DocumentInfo {
  final String name;
  final int size;
  final String mimeType;
  final String? extension;
  final int? pageCount;
  final String? author;
  final DateTime? createdAt;
  final DateTime? modifiedAt;

  DocumentInfo({
    required this.name,
    required this.size,
    required this.mimeType,
    this.extension,
    this.pageCount,
    this.author,
    this.createdAt,
    this.modifiedAt,
  });
}
