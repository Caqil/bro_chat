import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../models/chat/message_model.dart';
import '../../providers/chat/message_provider.dart';
import '../media/image_message_widget.dart';
import '../media/video_message_widget.dart';
import '../media/audio_message_widget.dart';
import '../media/document_message_widget.dart';
import '../media/location_message_widget.dart';
import '../media/contact_message_widget.dart';
import '../chat/voice_note_player.dart';
import '../chat/read_receipt_widget.dart';

class MessageBubbleWidget extends ConsumerStatefulWidget {
  final MessageModel message;
  final bool isFromCurrentUser;
  final bool showAvatar;
  final bool showSenderName;
  final bool showTimestamp;
  final bool isGroupChat;
  final VoidCallback? onReply;
  final VoidCallback? onForward;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final ValueChanged<String>? onReaction;
  final bool isSelected;
  final VoidCallback? onLongPress;
  final VoidCallback? onDoubleTap;

  const MessageBubbleWidget({
    super.key,
    required this.message,
    required this.isFromCurrentUser,
    this.showAvatar = true,
    this.showSenderName = false,
    this.showTimestamp = true,
    this.isGroupChat = false,
    this.onReply,
    this.onForward,
    this.onDelete,
    this.onEdit,
    this.onReaction,
    this.isSelected = false,
    this.onLongPress,
    this.onDoubleTap,
  });

  @override
  ConsumerState<MessageBubbleWidget> createState() =>
      _MessageBubbleWidgetState();
}

class _MessageBubbleWidgetState extends ConsumerState<MessageBubbleWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _showReactions = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
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
    return Container(
      margin: EdgeInsets.only(
        left: widget.isFromCurrentUser ? 60 : 8,
        right: widget.isFromCurrentUser ? 8 : 60,
        top: 2,
        bottom: 2,
      ),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: _buildMessageRow(),
          );
        },
      ),
    );
  }

  Widget _buildMessageRow() {
    return Row(
      mainAxisAlignment: widget.isFromCurrentUser
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Avatar for non-current user
        if (!widget.isFromCurrentUser && widget.showAvatar) _buildAvatar(),

        // Message content
        Flexible(
          child: GestureDetector(
            onTap: () => _handleTap(),
            onLongPress: () => _handleLongPress(),
            onDoubleTap: () => _handleDoubleTap(),
            child: Container(
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? Colors.blue.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: widget.isFromCurrentUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  // Sender name (for group chats)
                  if (widget.showSenderName && !widget.isFromCurrentUser)
                    _buildSenderName(),

                  // Reply preview
                  if (widget.message.isReply) _buildReplyPreview(),

                  // Message bubble
                  _buildMessageBubble(),

                  // Reactions
                  if (widget.message.hasReactions) _buildReactions(),

                  // Timestamp and status
                  if (widget.showTimestamp) _buildTimestampAndStatus(),
                ],
              ),
            ),
          ),
        ),

        // Avatar for current user (optional)
        if (widget.isFromCurrentUser && widget.showAvatar) _buildAvatar(),
      ],
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 32,
      height: 32,
      margin: EdgeInsets.only(
        left: widget.isFromCurrentUser ? 8 : 0,
        right: widget.isFromCurrentUser ? 0 : 8,
      ),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: ClipOval(child: _getAvatarWidget()),
    );
  }

  Widget _getAvatarWidget() {
    // In a real implementation, you'd get the sender's avatar
    // from the message or user provider
    final senderName = widget.message.senderName ?? 'Unknown';

    return Container(
      color: _getAvatarColor(senderName),
      child: Center(
        child: Text(
          _getInitials(senderName),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSenderName() {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 4),
      child: Text(
        widget.message.senderName ?? 'Unknown',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _getSenderNameColor(),
        ),
      ),
    );
  }

  Widget _buildReplyPreview() {
    if (widget.message.replyToMessage == null) {
      return const SizedBox.shrink();
    }

    final replyMessage = widget.message.replyToMessage!;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(color: Theme.of(context).primaryColor, width: 3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              replyMessage.senderName ?? 'Unknown',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _getMessagePreview(replyMessage),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble() {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      decoration: BoxDecoration(
        color: _getBubbleColor(),
        borderRadius: _getBubbleBorderRadius(),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: _buildMessageContent(),
    );
  }

  Widget _buildMessageContent() {
    if (widget.message.isDeleted) {
      return _buildDeletedMessage();
    }

    switch (widget.message.type) {
      case MessageType.text:
        return _buildTextMessage();
      case MessageType.image:
        return _buildImageMessage();
      case MessageType.video:
        return _buildVideoMessage();
      case MessageType.audio:
        return _buildAudioMessage();
      case MessageType.document:
        return _buildDocumentMessage();
      case MessageType.voiceNote:
        return _buildVoiceNoteMessage();
      case MessageType.location:
        return _buildLocationMessage();
      case MessageType.contact:
        return _buildContactMessage();
      case MessageType.sticker:
        return _buildStickerMessage();
      case MessageType.gif:
        return _buildGifMessage();
      default:
        return _buildSystemMessage();
    }
  }

  Widget _buildTextMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSelectableText(widget.message.content),
          if (widget.message.isEdited) _buildEditedIndicator(),
        ],
      ),
    );
  }

  Widget _buildSelectableText(String text) {
    // Handle mentions and links
    return SelectableText(
      text,
      style: TextStyle(
        fontSize: 16,
        color: widget.isFromCurrentUser ? Colors.white : Colors.black87,
      ),
      onTap: () => _handleTap(),
    );
  }

  Widget _buildEditedIndicator() {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        'edited',
        style: TextStyle(
          fontSize: 11,
          color: widget.isFromCurrentUser ? Colors.white70 : Colors.grey[500],
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildImageMessage() {
    return ClipRRect(
      borderRadius: _getBubbleBorderRadius(),
      child: ImageMessageWidget(
        imageUrl: widget.message.mediaUrl,
        metadata: widget.message.metadata,
        caption: widget.message.content.isNotEmpty
            ? widget.message.content
            : null,
      ),
    );
  }

  Widget _buildVideoMessage() {
    return ClipRRect(
      borderRadius: _getBubbleBorderRadius(),
      child: VideoMessageWidget(
        videoUrl: widget.message.mediaUrl,
        metadata: widget.message.metadata,
        caption: widget.message.content.isNotEmpty
            ? widget.message.content
            : null,
      ),
    );
  }

  Widget _buildAudioMessage() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: AudioMessageWidget(
        audioUrl: widget.message.mediaUrl,
        metadata: widget.message.metadata,
        isFromCurrentUser: widget.isFromCurrentUser,
      ),
    );
  }

  Widget _buildDocumentMessage() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: DocumentMessageWidget(
        documentUrl: widget.message.mediaUrl,
        metadata: widget.message.metadata,
        isFromCurrentUser: widget.isFromCurrentUser,
      ),
    );
  }

  Widget _buildVoiceNoteMessage() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: VoiceNotePlayerWidget(
        audioUrl: widget.message.mediaUrl!,
        duration: _getVoiceNoteDuration(),
        isFromCurrentUser: widget.isFromCurrentUser,
      ),
    );
  }

  Widget _buildLocationMessage() {
    return LocationMessageWidget(
      metadata: widget.message.metadata,
      isFromCurrentUser: widget.isFromCurrentUser,
    );
  }

  Widget _buildContactMessage() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: ContactMessageWidget(
        metadata: widget.message.metadata,
        isFromCurrentUser: widget.isFromCurrentUser,
      ),
    );
  }

  Widget _buildStickerMessage() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
      child: widget.message.mediaUrl != null
          ? CachedNetworkImage(
              imageUrl: widget.message.mediaUrl!,
              fit: BoxFit.contain,
            )
          : Container(
              color: Colors.grey[200],
              child: const Icon(Icons.image, size: 48, color: Colors.grey),
            ),
    );
  }

  Widget _buildGifMessage() {
    return ClipRRect(
      borderRadius: _getBubbleBorderRadius(),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 200, maxHeight: 200),
        child: widget.message.mediaUrl != null
            ? CachedNetworkImage(
                imageUrl: widget.message.mediaUrl!,
                fit: BoxFit.cover,
              )
            : Container(
                color: Colors.grey[200],
                child: const Icon(Icons.gif, size: 48, color: Colors.grey),
              ),
      ),
    );
  }

  Widget _buildSystemMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(
        widget.message.content,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDeletedMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.block, size: 16, color: Colors.grey[500]),
          const SizedBox(width: 6),
          Text(
            'This message was deleted',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReactions() {
    final reactions = widget.message.reactions;
    if (reactions.isEmpty) return const SizedBox.shrink();

    // Group reactions by emoji
    final groupedReactions = <String, List<MessageReaction>>{};
    for (final reaction in reactions) {
      groupedReactions.putIfAbsent(reaction.emoji, () => []).add(reaction);
    }

    return Container(
      margin: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        children: groupedReactions.entries.map((entry) {
          final emoji = entry.key;
          final reactionList = entry.value;

          return GestureDetector(
            onTap: () => _handleReactionTap(emoji),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 12)),
                  if (reactionList.length > 1) ...[
                    const SizedBox(width: 2),
                    Text(
                      '${reactionList.length}',
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTimestampAndStatus() {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatTimestamp(widget.message.createdAt),
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),

          if (widget.isFromCurrentUser) ...[
            const SizedBox(width: 4),
            _buildMessageStatusIcon(),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageStatusIcon() {
    IconData icon;
    Color color;

    switch (widget.message.status) {
      case MessageStatusType.sending:
        icon = Icons.schedule;
        color = Colors.grey;
        break;
      case MessageStatusType.sent:
        icon = Icons.check;
        color = Colors.grey;
        break;
      case MessageStatusType.delivered:
        icon = Icons.done_all;
        color = Colors.grey;
        break;
      case MessageStatusType.read:
        icon = Icons.done_all;
        color = Colors.blue;
        break;
      case MessageStatusType.failed:
        icon = Icons.error_outline;
        color = Colors.red;
        break;
    }

    return Icon(icon, size: 14, color: color);
  }

  Color _getBubbleColor() {
    if (widget.message.isDeleted) {
      return Colors.grey[200]!;
    }

    if (widget.isFromCurrentUser) {
      return Theme.of(context).primaryColor;
    } else {
      return Colors.grey[100]!;
    }
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

  Color _getSenderNameColor() {
    // Generate a consistent color based on sender name
    final colors = [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
    ];

    final senderName = widget.message.senderName ?? 'Unknown';
    final hash = senderName.hashCode;
    return colors[hash.abs() % colors.length];
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

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      // Today - show time
      return '${timestamp.hour.toString().padLeft(2, '0')}:'
          '${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      // Yesterday
      return 'Yesterday';
    } else {
      // Older - show date
      return '${timestamp.day}/${timestamp.month}';
    }
  }

  String _getMessagePreview(MessageModel message) {
    switch (message.type) {
      case MessageType.text:
        return message.content;
      case MessageType.image:
        return '📷 Photo';
      case MessageType.video:
        return '🎥 Video';
      case MessageType.audio:
        return '🎵 Audio';
      case MessageType.document:
        return '📄 Document';
      case MessageType.voiceNote:
        return '🎤 Voice message';
      case MessageType.location:
        return '📍 Location';
      case MessageType.contact:
        return '👤 Contact';
      default:
        return 'Message';
    }
  }

  Duration _getVoiceNoteDuration() {
    // Extract duration from metadata or default
    final metadata = widget.message.metadata;
    if (metadata != null && metadata['duration'] != null) {
      return Duration(seconds: metadata['duration'] as int);
    }
    return const Duration(seconds: 0);
  }

  void _handleTap() {
    if (widget.isSelected) {
      // Handle selection mode tap
    } else {
      // Handle normal tap
    }
  }

  void _handleLongPress() {
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    widget.onLongPress?.call();
    _showMessageOptions();
  }

  void _handleDoubleTap() {
    widget.onDoubleTap?.call();

    // Show quick reactions
    _showQuickReactions();
  }

  void _handleReactionTap(String emoji) {
    // Toggle reaction
    widget.onReaction?.call(emoji);
  }

  void _showMessageOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _MessageOptionsSheet(
        message: widget.message,
        isFromCurrentUser: widget.isFromCurrentUser,
        onReply: widget.onReply,
        onForward: widget.onForward,
        onEdit: widget.onEdit,
        onDelete: widget.onDelete,
        onReaction: widget.onReaction,
      ),
    );
  }

  void _showQuickReactions() {
    const quickReactions = ['👍', '❤️', '😂', '😮', '😢', '😡'];

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => Stack(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(color: Colors.transparent),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.3,
            left: 20,
            right: 20,
            child: Material(
              borderRadius: BorderRadius.circular(25),
              elevation: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: quickReactions.map((emoji) {
                    return ShadButton.raw(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onReaction?.call(emoji);
                      },
                      variant: ShadButtonVariant.ghost,
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageOptionsSheet extends ConsumerWidget {
  final MessageModel message;
  final bool isFromCurrentUser;
  final VoidCallback? onReply;
  final VoidCallback? onForward;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final ValueChanged<String>? onReaction;

  const _MessageOptionsSheet({
    required this.message,
    required this.isFromCurrentUser,
    this.onReply,
    this.onForward,
    this.onEdit,
    this.onDelete,
    this.onReaction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

          // Quick reactions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['👍', '❤️', '😂', '😮', '😢', '😡'].map((emoji) {
                return ShadButton.raw(
                  onPressed: () {
                    Navigator.pop(context);
                    onReaction?.call(emoji);
                  },
                  variant: ShadButtonVariant.ghost,
                  child: Text(emoji, style: const TextStyle(fontSize: 24)),
                );
              }).toList(),
            ),
          ),

          const Divider(),

          // Action options
          _buildOption(
            icon: Icons.reply,
            title: 'Reply',
            onTap: () {
              Navigator.pop(context);
              onReply?.call();
            },
          ),

          _buildOption(
            icon: Icons.forward,
            title: 'Forward',
            onTap: () {
              Navigator.pop(context);
              onForward?.call();
            },
          ),

          _buildOption(
            icon: Icons.copy,
            title: 'Copy',
            onTap: () {
              Navigator.pop(context);
              _copyMessage();
            },
          ),

          if (isFromCurrentUser && message.type == MessageType.text) ...[
            _buildOption(
              icon: Icons.edit,
              title: 'Edit',
              onTap: () {
                Navigator.pop(context);
                onEdit?.call();
              },
            ),
          ],

          if (isFromCurrentUser) ...[
            _buildOption(
              icon: Icons.delete,
              title: 'Delete',
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context);
              },
              isDestructive: true,
            ),
          ],

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : null),
      title: Text(
        title,
        style: TextStyle(color: isDestructive ? Colors.red : null),
      ),
      onTap: onTap,
    );
  }

  void _copyMessage() {
    Clipboard.setData(ClipboardData(text: message.content));
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: const Text('Delete Message'),
        actions: [
          ShadButton.raw(
            onPressed: () => Navigator.pop(context),
            variant: ShadButtonVariant.outline,
            child: const Text('Cancel'),
          ),
          ShadButton.raw(
            onPressed: () {
              Navigator.pop(context);
              onDelete?.call();
            },
            variant: ShadButtonVariant.destructive,
            child: const Text('Delete'),
          ),
        ],
        child: const Text('Are you sure you want to delete this message?'),
      ),
    );
  }
}
