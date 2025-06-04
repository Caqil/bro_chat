import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../models/chat/message_model.dart';
import '../../models/chat/participant_model.dart';

class ReadReceiptWidget extends ConsumerWidget {
  final List<MessageReadReceipt> readReceipts;
  final List<ParticipantModel> participants;
  final bool compact;
  final int maxAvatars;
  final bool showDetails;
  final VoidCallback? onTap;

  const ReadReceiptWidget({
    super.key,
    required this.readReceipts,
    required this.participants,
    this.compact = false,
    this.maxAvatars = 3,
    this.showDetails = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (readReceipts.isEmpty) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: onTap ?? () => _showReadReceiptDetails(context),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 8,
          vertical: compact ? 2 : 4,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAvatarStack(),
            if (!compact) ...[
              const SizedBox(width: 6),
              _buildReadText(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarStack() {
    final displayReceipts = readReceipts.take(maxAvatars).toList();
    final size = compact ? 16.0 : 20.0;
    final overlap = compact ? 8.0 : 10.0;

    return SizedBox(
      width: size + (displayReceipts.length - 1) * overlap,
      height: size,
      child: Stack(
        children: [
          for (int i = 0; i < displayReceipts.length; i++)
            Positioned(
              left: i * overlap,
              child: _buildUserAvatar(displayReceipts[i], size),
            ),

          // Show count if there are more receipts
          if (readReceipts.length > maxAvatars)
            Positioned(
              right: 0,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: Center(
                  child: Text(
                    '+${readReceipts.length - maxAvatars}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 8 : 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUserAvatar(MessageReadReceipt receipt, double size) {
    final participant = _findParticipant(receipt.userId);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: ClipOval(
        child: participant?.avatar != null
            ? CachedNetworkImage(
                imageUrl: participant!.avatar!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    _buildInitialsAvatar(receipt.userName, size),
                errorWidget: (context, url, error) =>
                    _buildInitialsAvatar(receipt.userName, size),
              )
            : _buildInitialsAvatar(receipt.userName, size),
      ),
    );
  }

  Widget _buildInitialsAvatar(String name, double size) {
    return Container(
      width: size,
      height: size,
      color: _getAvatarColor(name),
      child: Center(
        child: Text(
          _getInitials(name),
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildReadText(BuildContext context) {
    if (readReceipts.length == 1) {
      return Text(
        'Read',
        style: TextStyle(
          fontSize: 11,
          color: Colors.blue[600],
          fontWeight: FontWeight.w500,
        ),
      );
    }

    return Text(
      'Read by ${readReceipts.length}',
      style: TextStyle(
        fontSize: 11,
        color: Colors.blue[600],
        fontWeight: FontWeight.w500,
      ),
    );
  }

  void _showReadReceiptDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ReadReceiptDetailsSheet(
        readReceipts: readReceipts,
        participants: participants,
      ),
    );
  }

  ParticipantModel? _findParticipant(String userId) {
    try {
      return participants.firstWhere((p) => p.userId == userId);
    } catch (e) {
      return null;
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

// Detailed read receipt sheet
class ReadReceiptDetailsSheet extends ConsumerWidget {
  final List<MessageReadReceipt> readReceipts;
  final List<ParticipantModel> participants;

  const ReadReceiptDetailsSheet({
    super.key,
    required this.readReceipts,
    required this.participants,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sort receipts by read time (most recent first)
    final sortedReceipts = List<MessageReadReceipt>.from(readReceipts)
      ..sort((a, b) => b.readAt.compareTo(a.readAt));

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text(
                  'Read by',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  '${readReceipts.length} people',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Read receipt list
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: sortedReceipts.length,
              itemBuilder: (context, index) {
                final receipt = sortedReceipts[index];
                final participant = _findParticipant(receipt.userId);

                return _buildReceiptItem(receipt, participant);
              },
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildReceiptItem(
    MessageReadReceipt receipt,
    ParticipantModel? participant,
  ) {
    return ListTile(
      leading: _buildUserAvatar(receipt, participant),
      title: Text(
        receipt.userName,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        _formatReadTime(receipt.readAt),
        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
      ),
      trailing: _buildOnlineIndicator(participant),
    );
  }

  Widget _buildUserAvatar(
    MessageReadReceipt receipt,
    ParticipantModel? participant,
  ) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: ClipOval(
        child: participant?.avatar != null
            ? CachedNetworkImage(
                imageUrl: participant!.avatar!,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    _buildInitialsAvatar(receipt.userName, 48),
                errorWidget: (context, url, error) =>
                    _buildInitialsAvatar(receipt.userName, 48),
              )
            : _buildInitialsAvatar(receipt.userName, 48),
      ),
    );
  }

  Widget _buildInitialsAvatar(String name, double size) {
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

  Widget _buildOnlineIndicator(ParticipantModel? participant) {
    if (participant?.isOnline == true) {
      return Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  ParticipantModel? _findParticipant(String userId) {
    try {
      return participants.firstWhere((p) => p.userId == userId);
    } catch (e) {
      return null;
    }
  }

  String _formatReadTime(DateTime readAt) {
    final now = DateTime.now();
    final difference = now.difference(readAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hr ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday at ${_formatTime(readAt)}';
    } else if (difference.inDays < 7) {
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return '${weekdays[readAt.weekday - 1]} at ${_formatTime(readAt)}';
    } else {
      return '${readAt.day}/${readAt.month}/${readAt.year} at ${_formatTime(readAt)}';
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
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

// Minimal read receipt indicator
class MinimalReadReceiptWidget extends ConsumerWidget {
  final List<MessageReadReceipt> readReceipts;
  final bool showCount;

  const MinimalReadReceiptWidget({
    super.key,
    required this.readReceipts,
    this.showCount = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (readReceipts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.done_all, size: 14, color: Colors.blue[600]),
        if (showCount && readReceipts.length > 1) ...[
          const SizedBox(width: 2),
          Text(
            '${readReceipts.length}',
            style: TextStyle(
              fontSize: 10,
              color: Colors.blue[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

// Read receipt status indicator for message status
class MessageReadStatus extends ConsumerWidget {
  final MessageStatusType status;
  final List<MessageReadReceipt> readReceipts;
  final int totalParticipants;

  const MessageReadStatus({
    super.key,
    required this.status,
    required this.readReceipts,
    required this.totalParticipants,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    IconData icon;
    Color color;
    String tooltip;

    switch (status) {
      case MessageStatusType.sending:
        icon = Icons.schedule;
        color = Colors.grey;
        tooltip = 'Sending';
        break;
      case MessageStatusType.sent:
        icon = Icons.check;
        color = Colors.grey;
        tooltip = 'Sent';
        break;
      case MessageStatusType.delivered:
        icon = Icons.done_all;
        color = Colors.grey;
        tooltip = 'Delivered';
        break;
      case MessageStatusType.read:
        icon = Icons.done_all;
        color = Colors.blue;
        if (readReceipts.length == totalParticipants) {
          tooltip = 'Read by all';
        } else {
          tooltip = 'Read by ${readReceipts.length} of $totalParticipants';
        }
        break;
      case MessageStatusType.failed:
        icon = Icons.error_outline;
        color = Colors.red;
        tooltip = 'Failed to send';
        break;
    }

    return Tooltip(
      message: tooltip,
      child: Icon(icon, size: 14, color: color),
    );
  }
}
