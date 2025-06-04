import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../models/chat/chat_model.dart';
import '../../models/chat/message_model.dart';
import '../../providers/chat/chat_list_provider.dart';
import '../../providers/chat/typing_provider.dart';
import '../common/custom_badge.dart';

class ChatTileWidget extends ConsumerWidget {
  final ChatModel chat;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final bool showDivider;
  final bool compact;

  const ChatTileWidget({
    super.key,
    required this.chat,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
    this.showDivider = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAnyoneTyping = ref.watch(isAnyoneTypingProvider(chat.id));
    final typingText = ref.watch(typingIndicatorTextProvider(chat.id));

    return Column(
      children: [
        Material(
          color: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.transparent,
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 12 : 16,
                vertical: compact ? 8 : 12,
              ),
              child: Row(
                children: [
                  // Chat Avatar
                  _buildChatAvatar(),

                  SizedBox(width: compact ? 10 : 12),

                  // Chat Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // First row: Chat name and timestamp
                        Row(
                          children: [
                            Expanded(child: _buildChatName(context)),
                            _buildTimestamp(context),
                          ],
                        ),

                        SizedBox(height: compact ? 2 : 4),

                        // Second row: Last message and indicators
                        Row(
                          children: [
                            Expanded(
                              child: _buildLastMessage(
                                context,
                                isAnyoneTyping,
                                typingText,
                              ),
                            ),
                            _buildIndicators(context),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        if (showDivider)
          Divider(
            height: 1,
            indent: compact ? 60 : 70,
            color: Colors.grey[200],
          ),
      ],
    );
  }

  Widget _buildChatAvatar() {
    final size = compact ? 48.0 : 56.0;

    return Stack(
      children: [
        // Main avatar
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: chat.isPinned ? Colors.orange : Colors.grey[300]!,
              width: chat.isPinned ? 2 : 1,
            ),
          ),
          child: ClipOval(
            child: chat.isGroup
                ? _buildGroupAvatar(size)
                : _buildPrivateAvatar(size),
          ),
        ),

        // Online status indicator (for private chats)
        if (!chat.isGroup &&
            chat.participants.isNotEmpty &&
            chat.participants.first.isOnline)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),

        // Muted indicator
        if (chat.isMuted)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1),
              ),
              child: const Icon(
                Icons.volume_off,
                color: Colors.white,
                size: 10,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGroupAvatar(double size) {
    if (chat.avatar != null) {
      return CachedNetworkImage(
        imageUrl: chat.avatar!,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildInitialsAvatar(size, chat.name),
        errorWidget: (context, url, error) =>
            _buildInitialsAvatar(size, chat.name),
      );
    }

    // Group avatar with multiple participants
    if (chat.participants.length >= 2) {
      return _buildMultiParticipantAvatar(size);
    }

    return _buildInitialsAvatar(size, chat.name);
  }

  Widget _buildMultiParticipantAvatar(double size) {
    final participants = chat.participants.take(4).toList();

    return Container(
      width: size,
      height: size,
      color: Colors.grey[100],
      child: participants.length == 1
          ? _buildSingleParticipantInGroup(participants[0], size)
          : participants.length == 2
          ? _buildTwoParticipantGrid(participants, size)
          : _buildMultiParticipantGrid(participants, size),
    );
  }

  Widget _buildSingleParticipantInGroup(participant, double size) {
    return participant.avatar != null
        ? CachedNetworkImage(
            imageUrl: participant.avatar!,
            fit: BoxFit.cover,
            errorWidget: (context, url, error) =>
                _buildInitialsAvatar(size, participant.name),
          )
        : _buildInitialsAvatar(size, participant.name);
  }

  Widget _buildTwoParticipantGrid(List participants, double size) {
    return Row(
      children: [
        Expanded(
          child: participants[0].avatar != null
              ? CachedNetworkImage(
                  imageUrl: participants[0].avatar!,
                  fit: BoxFit.cover,
                  height: size,
                )
              : _buildInitialsAvatar(size / 2, participants[0].name),
        ),
        Expanded(
          child: participants[1].avatar != null
              ? CachedNetworkImage(
                  imageUrl: participants[1].avatar!,
                  fit: BoxFit.cover,
                  height: size,
                )
              : _buildInitialsAvatar(size / 2, participants[1].name),
        ),
      ],
    );
  }

  Widget _buildMultiParticipantGrid(List participants, double size) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: participants[0].avatar != null
                    ? CachedNetworkImage(
                        imageUrl: participants[0].avatar!,
                        fit: BoxFit.cover,
                        height: size / 2,
                      )
                    : _buildInitialsAvatar(size / 4, participants[0].name),
              ),
              Expanded(
                child: participants[1].avatar != null
                    ? CachedNetworkImage(
                        imageUrl: participants[1].avatar!,
                        fit: BoxFit.cover,
                        height: size / 2,
                      )
                    : _buildInitialsAvatar(size / 4, participants[1].name),
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: participants.length > 2 && participants[2].avatar != null
                    ? CachedNetworkImage(
                        imageUrl: participants[2].avatar!,
                        fit: BoxFit.cover,
                        height: size / 2,
                      )
                    : _buildInitialsAvatar(
                        size / 4,
                        participants.length > 2 ? participants[2].name : '',
                      ),
              ),
              Expanded(
                child: participants.length > 3
                    ? participants[3].avatar != null
                          ? CachedNetworkImage(
                              imageUrl: participants[3].avatar!,
                              fit: BoxFit.cover,
                              height: size / 2,
                            )
                          : _buildInitialsAvatar(size / 4, participants[3].name)
                    : chat.participants.length > 4
                    ? Container(
                        color: Colors.grey[300],
                        child: Center(
                          child: Text(
                            '+${chat.participants.length - 3}',
                            style: TextStyle(
                              fontSize: size * 0.15,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      )
                    : Container(color: Colors.grey[200]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrivateAvatar(double size) {
    final participant = chat.participants.isNotEmpty
        ? chat.participants.first
        : null;

    if (participant?.avatar != null) {
      return CachedNetworkImage(
        imageUrl: participant!.avatar!,
        fit: BoxFit.cover,
        placeholder: (context, url) =>
            _buildInitialsAvatar(size, participant.name),
        errorWidget: (context, url, error) =>
            _buildInitialsAvatar(size, participant.name),
      );
    }

    return _buildInitialsAvatar(size, participant?.name ?? 'Unknown');
  }

  Widget _buildInitialsAvatar(double size, String name) {
    return Container(
      width: size,
      height: size,
      color: _getAvatarColor(name),
      child: Center(
        child: Text(
          _getInitials(name),
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.3,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildChatName(BuildContext context) {
    return Row(
      children: [
        // Pin indicator
        if (chat.isPinned) ...[
          Icon(Icons.push_pin, size: compact ? 12 : 14, color: Colors.orange),
          const SizedBox(width: 4),
        ],

        Expanded(
          child: Text(
            chat.name,
            style: TextStyle(
              fontSize: compact ? 15 : 16,
              fontWeight: chat.hasUnreadMessages
                  ? FontWeight.w600
                  : FontWeight.w500,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTimestamp(BuildContext context) {
    if (chat.lastMessage?.createdAt == null) {
      return const SizedBox.shrink();
    }

    final timestamp = chat.lastMessage!.createdAt;
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    String timeText;
    if (difference.inDays == 0) {
      // Today - show time
      timeText =
          '${timestamp.hour.toString().padLeft(2, '0')}:'
          '${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      // Yesterday
      timeText = 'Yesterday';
    } else if (difference.inDays < 7) {
      // This week - show day
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      timeText = weekdays[timestamp.weekday - 1];
    } else {
      // Older - show date
      timeText =
          '${timestamp.day}/${timestamp.month}/${timestamp.year.toString().substring(2)}';
    }

    return Text(
      timeText,
      style: TextStyle(
        fontSize: compact ? 11 : 12,
        color: chat.hasUnreadMessages
            ? Theme.of(context).primaryColor
            : Colors.grey[600],
        fontWeight: chat.hasUnreadMessages
            ? FontWeight.w500
            : FontWeight.normal,
      ),
    );
  }

  Widget _buildLastMessage(
    BuildContext context,
    bool isAnyoneTyping,
    String typingText,
  ) {
    // Show typing indicator if someone is typing
    if (isAnyoneTyping) {
      return Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              typingText,
              style: TextStyle(
                fontSize: compact ? 12 : 13,
                color: Colors.blue[600],
                fontStyle: FontStyle.italic,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    // Show last message
    if (chat.lastMessage == null) {
      return Text(
        chat.isGroup ? 'Group created' : 'No messages yet',
        style: TextStyle(
          fontSize: compact ? 12 : 13,
          color: Colors.grey[500],
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Row(
      children: [
        // Message status indicator (for sent messages)
        if (chat.lastMessage!.isFromCurrentUser) ...[
          _buildMessageStatusIcon(chat.lastMessage!.status),
          const SizedBox(width: 4),
        ],

        Expanded(
          child: Text(
            _getLastMessageText(chat.lastMessage!),
            style: TextStyle(
              fontSize: compact ? 12 : 13,
              color: chat.hasUnreadMessages ? Colors.black87 : Colors.grey[600],
              fontWeight: chat.hasUnreadMessages
                  ? FontWeight.w500
                  : FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMessageStatusIcon(MessageStatusType status) {
    IconData icon;
    Color color;

    switch (status) {
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

  Widget _buildIndicators(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Draft message indicator
        if (chat.draftMessage?.isNotEmpty == true) ...[
          Icon(Icons.edit, size: compact ? 14 : 16, color: Colors.red),
          const SizedBox(width: 4),
        ],

        // Unread count badge
        if (chat.hasUnreadMessages && !chat.isMuted)
          CustomBadge(
            text: chat.unreadCount > 99 ? '99+' : chat.unreadCount.toString(),
            color: Theme.of(context).primaryColor,
            size: compact ? BadgeSize.small : BadgeSize.medium,
          )
        else if (chat.hasUnreadMessages && chat.isMuted)
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }

  String _getLastMessageText(MessageModel message) {
    if (message.isDeleted) {
      return message.isFromCurrentUser
          ? 'You deleted this message'
          : 'This message was deleted';
    }

    // Show sender name for group chats
    String senderPrefix = '';
    if (chat.isGroup && !message.isFromCurrentUser) {
      senderPrefix = '${message.senderName ?? 'Unknown'}: ';
    } else if (message.isFromCurrentUser) {
      senderPrefix = 'You: ';
    }

    switch (message.type) {
      case MessageType.text:
        return '$senderPrefix${message.content}';
      case MessageType.image:
        return '${senderPrefix}📷 Photo';
      case MessageType.video:
        return '${senderPrefix}🎥 Video';
      case MessageType.audio:
        return '${senderPrefix}🎵 Audio';
      case MessageType.document:
        return '${senderPrefix}📄 Document';
      case MessageType.voiceNote:
        return '${senderPrefix}🎤 Voice message';
      case MessageType.location:
        return '${senderPrefix}📍 Location';
      case MessageType.contact:
        return '${senderPrefix}👤 Contact';
      case MessageType.sticker:
        return '${senderPrefix}Sticker';
      case MessageType.gif:
        return '${senderPrefix}GIF';
      case MessageType.groupCreated:
        return 'Group created';
      case MessageType.memberAdded:
        return 'Member added to group';
      case MessageType.memberRemoved:
        return 'Member left the group';
      case MessageType.callStarted:
        return '📞 Call started';
      case MessageType.callEnded:
        return '📞 Call ended';
      default:
        return '${senderPrefix}Message';
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

// Swipeable chat tile with actions
class SwipeableChatTile extends ConsumerWidget {
  final ChatModel chat;
  final VoidCallback? onTap;
  final VoidCallback? onArchive;
  final VoidCallback? onMute;
  final VoidCallback? onDelete;
  final VoidCallback? onPin;

  const SwipeableChatTile({
    super.key,
    required this.chat,
    this.onTap,
    this.onArchive,
    this.onMute,
    this.onDelete,
    this.onPin,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(chat.id),
      background: Container(
        color: Colors.blue,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.archive, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Archive action
          onArchive?.call();
          return false; // Don't actually dismiss
        } else {
          // Delete action
          return await _confirmDelete(context);
        }
      },
      child: ChatTileWidget(
        chat: chat,
        onTap: onTap,
        onLongPress: () => _showChatOptions(context, ref),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ShadDialog(
        title: const Text('Delete Chat'),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ShadButton.destructive(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
        child: Text('Are you sure you want to delete "${chat.name}"?'),
      ),
    );

    if (result == true) {
      onDelete?.call();
    }

    return result ?? false;
  }

  void _showChatOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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

            ListTile(
              leading: Icon(
                chat.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
              ),
              title: Text(chat.isPinned ? 'Unpin chat' : 'Pin chat'),
              onTap: () {
                Navigator.pop(context);
                onPin?.call();
              },
            ),

            ListTile(
              leading: Icon(chat.isMuted ? Icons.volume_up : Icons.volume_off),
              title: Text(chat.isMuted ? 'Unmute' : 'Mute notifications'),
              onTap: () {
                Navigator.pop(context);
                onMute?.call();
              },
            ),

            ListTile(
              leading: const Icon(Icons.archive),
              title: Text(chat.isArchived ? 'Unarchive' : 'Archive chat'),
              onTap: () {
                Navigator.pop(context);
                onArchive?.call();
              },
            ),

            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                'Delete chat',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context);
              },
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
