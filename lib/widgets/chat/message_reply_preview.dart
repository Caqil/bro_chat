import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/chat/message_model.dart';

class MessageReplyPreviewWidget extends ConsumerWidget {
  final MessageModel message;
  final VoidCallback? onCancel;
  final bool compact;
  final Color? backgroundColor;
  final Color? borderColor;

  const MessageReplyPreviewWidget({
    super.key,
    required this.message,
    this.onCancel,
    this.compact = false,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: backgroundColor ?? Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.all(compact ? 8 : 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border(
              left: BorderSide(
                color: borderColor ?? Theme.of(context).primaryColor,
                width: 3,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(child: _buildReplyContent(context)),
              if (onCancel != null) ...[
                const SizedBox(width: 8),
                _buildCancelButton(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReplyContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Sender info
        Row(
          children: [
            Icon(
              Icons.reply,
              size: compact ? 14 : 16,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 4),
            Text(
              'Replying to ${message.senderName ?? 'Unknown'}',
              style: TextStyle(
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),

        SizedBox(height: compact ? 2 : 4),

        // Message content preview
        Row(
          children: [
            // Media thumbnail or type indicator
            if (_hasMediaPreview()) ...[
              _buildMediaPreview(),
              const SizedBox(width: 8),
            ],

            // Text content
            Expanded(child: _buildTextPreview(context)),
          ],
        ),
      ],
    );
  }

  Widget _buildCancelButton() {
    return ShadButton.ghost(
      onPressed: onCancel,
      size: ShadButtonSize.sm,
      child: Container(
        padding: const EdgeInsets.all(4),
        child: Icon(
          Icons.close,
          size: compact ? 14 : 16,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildTextPreview(BuildContext context) {
    final content = _getPreviewText();

    return Text(
      content,
      style: TextStyle(
        fontSize: compact ? 12 : 13,
        color: message.isDeleted ? Colors.grey[500] : Colors.grey[700],
        fontStyle: message.isDeleted ? FontStyle.italic : FontStyle.normal,
      ),
      maxLines: compact ? 1 : 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildMediaPreview() {
    final size = compact ? 32.0 : 40.0;

    switch (message.type) {
      case MessageType.image:
        return _buildImagePreview(size);
      case MessageType.video:
        return _buildVideoPreview(size);
      case MessageType.audio:
        return _buildAudioPreview(size);
      case MessageType.document:
        return _buildDocumentPreview(size);
      case MessageType.voiceNote:
        return _buildVoiceNotePreview(size);
      case MessageType.location:
        return _buildLocationPreview(size);
      case MessageType.contact:
        return _buildContactPreview(size);
      case MessageType.sticker:
        return _buildStickerPreview(size);
      case MessageType.gif:
        return _buildGifPreview(size);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildImagePreview(double size) {
    if (message.mediaUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: CachedNetworkImage(
          imageUrl: message.mediaUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            width: size,
            height: size,
            color: Colors.grey[200],
            child: const Icon(Icons.image, color: Colors.grey),
          ),
          errorWidget: (context, url, error) => Container(
            width: size,
            height: size,
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image, color: Colors.grey),
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Icon(Icons.image, color: Colors.blue, size: 20),
    );
  }

  Widget _buildVideoPreview(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (message.thumbnailUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: CachedNetworkImage(
                imageUrl: message.thumbnailUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
              ),
            )
          else
            Icon(Icons.videocam, color: Colors.red[700], size: 20),

          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.play_arrow, color: Colors.white, size: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioPreview(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(Icons.audiotrack, color: Colors.orange[700], size: 20),
    );
  }

  Widget _buildDocumentPreview(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.indigo[50],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(Icons.description, color: Colors.indigo[700], size: 20),
    );
  }

  Widget _buildVoiceNotePreview(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(Icons.mic, color: Colors.purple[700], size: 20),
    );
  }

  Widget _buildLocationPreview(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(Icons.location_on, color: Colors.green[700], size: 20),
    );
  }

  Widget _buildContactPreview(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.teal[50],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(Icons.person, color: Colors.teal[700], size: 20),
    );
  }

  Widget _buildStickerPreview(double size) {
    if (message.mediaUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: CachedNetworkImage(
          imageUrl: message.mediaUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            width: size,
            height: size,
            color: Colors.grey[200],
            child: const Icon(Icons.emoji_emotions, color: Colors.grey),
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.yellow[50],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(Icons.emoji_emotions, color: Colors.yellow[700], size: 20),
    );
  }

  Widget _buildGifPreview(double size) {
    if (message.mediaUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: CachedNetworkImage(
          imageUrl: message.mediaUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            width: size,
            height: size,
            color: Colors.grey[200],
            child: const Icon(Icons.gif, color: Colors.grey),
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.pink[50],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(Icons.gif, color: Colors.pink[700], size: 20),
    );
  }

  bool _hasMediaPreview() {
    return message.type != MessageType.text &&
        message.type != MessageType.groupCreated &&
        message.type != MessageType.groupDeleted &&
        message.type != MessageType.memberAdded &&
        message.type != MessageType.memberRemoved &&
        message.type != MessageType.callStarted &&
        message.type != MessageType.callEnded;
  }

  String _getPreviewText() {
    if (message.isDeleted) {
      return 'This message was deleted';
    }

    switch (message.type) {
      case MessageType.text:
        return message.content;
      case MessageType.image:
        return message.content.isNotEmpty ? message.content : '📷 Photo';
      case MessageType.video:
        return message.content.isNotEmpty ? message.content : '🎥 Video';
      case MessageType.audio:
        return message.content.isNotEmpty ? message.content : '🎵 Audio';
      case MessageType.document:
        return message.content.isNotEmpty ? message.content : '📄 Document';
      case MessageType.voiceNote:
        final duration = _getVoiceNoteDuration();
        return '🎤 Voice message ${_formatDuration(duration)}';
      case MessageType.location:
        return '📍 Location';
      case MessageType.contact:
        return '👤 Contact';
      case MessageType.sticker:
        return 'Sticker';
      case MessageType.gif:
        return 'GIF';
      case MessageType.groupCreated:
        return 'Group created';
      case MessageType.groupDeleted:
        return 'Group deleted';
      case MessageType.memberAdded:
        return 'Member added to group';
      case MessageType.memberRemoved:
        return 'Member removed from group';
      case MessageType.callStarted:
        return '📞 Call started';
      case MessageType.callEnded:
        return '📞 Call ended';
      default:
        return message.content;
    }
  }

  Duration _getVoiceNoteDuration() {
    final metadata = message.metadata;
    if (metadata != null && metadata['voice_note'] != null) {
      final voiceData = metadata['voice_note'] as Map<String, dynamic>;
      final durationSeconds = voiceData['duration'] as int? ?? 0;
      return Duration(seconds: durationSeconds);
    }
    return Duration.zero;
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
}

// Compact version for tight spaces
class CompactMessageReplyPreview extends ConsumerWidget {
  final MessageModel message;
  final VoidCallback? onCancel;

  const CompactMessageReplyPreview({
    super.key,
    required this.message,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MessageReplyPreviewWidget(
      message: message,
      onCancel: onCancel,
      compact: true,
      backgroundColor: Colors.grey[100],
    );
  }
}

// Themed reply preview for different contexts
class ThemedMessageReplyPreview extends ConsumerWidget {
  final MessageModel message;
  final VoidCallback? onCancel;
  final Color primaryColor;
  final Color backgroundColor;

  const ThemedMessageReplyPreview({
    super.key,
    required this.message,
    this.onCancel,
    required this.primaryColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MessageReplyPreviewWidget(
      message: message,
      onCancel: onCancel,
      backgroundColor: backgroundColor,
      borderColor: primaryColor,
    );
  }
}
