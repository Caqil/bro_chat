import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/call/call_model.dart';
import '../../models/call/call_participant.dart';
import '../../providers/call/call_provider.dart';
import '../../providers/call/call_history_provider.dart';
import '../common/custom_badge.dart';

enum CallTileType { history, incoming, ongoing, scheduled }

class CallTileWidget extends ConsumerWidget {
  final CallModel call;
  final CallTileType type;
  final List<CallParticipant>? participants;
  final VoidCallback? onTap;
  final VoidCallback? onAnswer;
  final VoidCallback? onDecline;
  final VoidCallback? onJoin;
  final VoidCallback? onCallBack;
  final VoidCallback? onDelete;
  final bool showActions;
  final bool showAvatar;
  final bool showDuration;
  final bool showTime;
  final bool compact;

  const CallTileWidget({
    super.key,
    required this.call,
    required this.type,
    this.participants,
    this.onTap,
    this.onAnswer,
    this.onDecline,
    this.onJoin,
    this.onCallBack,
    this.onDelete,
    this.showActions = true,
    this.showAvatar = true,
    this.showDuration = true,
    this.showTime = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 16,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(compact ? 8 : 12),
        border: Border.all(color: _getBorderColor(), width: _getBorderWidth()),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(compact ? 8 : 12),
        child: Padding(
          padding: EdgeInsets.all(compact ? 12 : 16),
          child: Row(
            children: [
              // Avatar/Icon
              if (showAvatar) ...[
                _buildAvatar(),
                SizedBox(width: compact ? 12 : 16),
              ],

              // Call Information
              Expanded(child: _buildCallInfo(context)),

              // Actions
              if (showActions) _buildActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final size = compact ? 40.0 : 48.0;

    // For group calls, show multiple avatars
    if (call.type == CallType.group &&
        participants != null &&
        participants!.length > 1) {
      return _buildGroupAvatar(size);
    }

    // For single participant calls
    final participant = participants?.isNotEmpty == true
        ? participants!.first
        : null;

    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _getStatusColor(), width: 2),
          ),
          child: ClipOval(
            child: participant?.avatar != null
                ? CachedNetworkImage(
                    imageUrl: participant!.avatar!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        _buildInitialsAvatar(size, participant.name),
                    errorWidget: (context, url, error) =>
                        _buildInitialsAvatar(size, participant.name),
                  )
                : _buildInitialsAvatar(size, participant?.name ?? 'Unknown'),
          ),
        ),

        // Call type indicator
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: _getCallTypeColor(),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1),
            ),
            child: Icon(_getCallTypeIcon(), size: 10, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupAvatar(double size) {
    if (participants == null || participants!.isEmpty) {
      return _buildInitialsAvatar(size, 'Group');
    }

    final displayParticipants = participants!.take(2).toList();

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          if (displayParticipants.isNotEmpty)
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                width: size * 0.7,
                height: size * 0.7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: ClipOval(
                  child: displayParticipants[0].avatar != null
                      ? CachedNetworkImage(
                          imageUrl: displayParticipants[0].avatar!,
                          fit: BoxFit.cover,
                        )
                      : _buildInitialsAvatar(
                          size * 0.7,
                          displayParticipants[0].name,
                        ),
                ),
              ),
            ),

          if (displayParticipants.length > 1)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: size * 0.5,
                height: size * 0.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: ClipOval(
                  child: displayParticipants[1].avatar != null
                      ? CachedNetworkImage(
                          imageUrl: displayParticipants[1].avatar!,
                          fit: BoxFit.cover,
                        )
                      : _buildInitialsAvatar(
                          size * 0.5,
                          displayParticipants[1].name,
                        ),
                ),
              ),
            ),

          if (participants!.length > 2)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: size * 0.5,
                height: size * 0.5,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: Center(
                  child: Text(
                    '+${participants!.length - 2}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: size * 0.2,
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

  Widget _buildCallInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Participant name(s) or call title
        Row(
          children: [
            Expanded(
              child: Text(
                _getCallTitle(),
                style: TextStyle(
                  fontSize: compact ? 14 : 16,
                  fontWeight: FontWeight.w600,
                  color: _getTitleColor(),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Call status badge
            if (type == CallTileType.incoming || type == CallTileType.ongoing)
              CustomBadge(
                text: _getStatusText(),
                color: _getStatusColor(),
                size: BadgeSize.small,
              ),
          ],
        ),

        SizedBox(height: compact ? 2 : 4),

        // Call details
        Row(
          children: [
            // Call direction and type icon
            Icon(
              _getCallDirectionIcon(),
              size: compact ? 12 : 14,
              color: _getCallDirectionColor(),
            ),
            const SizedBox(width: 4),

            // Call time or duration
            Expanded(
              child: Text(
                _getCallTimeText(),
                style: TextStyle(
                  fontSize: compact ? 11 : 12,
                  color: Colors.grey[600],
                ),
              ),
            ),

            // Additional info (quality, recording, etc.)
            ..._buildAdditionalInfo(),
          ],
        ),

        // Subtitle with more details
        if (!compact && _hasSubtitle()) ...[
          const SizedBox(height: 4),
          Text(
            _getSubtitle(),
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        ],
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    switch (type) {
      case CallTileType.incoming:
        return _buildIncomingCallActions();
      case CallTileType.ongoing:
        return _buildOngoingCallActions();
      case CallTileType.scheduled:
        return _buildScheduledCallActions();
      case CallTileType.history:
      default:
        return _buildHistoryCallActions(context);
    }
  }

  Widget _buildIncomingCallActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Decline button
        ShadButton.destructive(
          onPressed: onDecline,
          size: compact ? ShadButtonSize.sm : ShadButtonSize.regular,
          child: Icon(Icons.call_end, size: compact ? 16 : 20),
        ),

        const SizedBox(width: 8),

        // Answer button
        ShadButton.secondary(
          onPressed: onAnswer,
          size: compact ? ShadButtonSize.sm : ShadButtonSize.regular,
          child: Icon(Icons.call, size: compact ? 16 : 20),
        ),
      ],
    );
  }

  Widget _buildOngoingCallActions() {
    return ShadButton.secondary(
      onPressed: onJoin,
      size: compact ? ShadButtonSize.sm : ShadButtonSize.regular,
      child: Text(compact ? 'Join' : 'Join Call'),
    );
  }

  Widget _buildScheduledCallActions() {
    return ShadButton.outline(
      onPressed: onJoin,
      size: compact ? ShadButtonSize.sm : ShadButtonSize.regular,
      child: Text(compact ? 'Start' : 'Start Call'),
    );
  }

  Widget _buildHistoryCallActions(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Call back button
        ShadButton.ghost(
          onPressed: onCallBack,
          size: ShadButtonSize.sm,
          child: const Icon(Icons.call, size: 16),
        ),

        // More options
        ShadButton.ghost(
          onPressed: () => _showMoreOptions(context),
          size: ShadButtonSize.sm,
          child: const Icon(Icons.more_vert, size: 16),
        ),
      ],
    );
  }

  List<Widget> _buildAdditionalInfo() {
    final info = <Widget>[];

    // Recording indicator
    if (call.isRecording) {
      info.addAll([
        const SizedBox(width: 4),
        Icon(Icons.fiber_manual_record, size: 12, color: Colors.red),
      ]);
    }

    // Quality indicator (for completed calls)
    if (call.quality != null && type == CallTileType.history) {
      info.addAll([
        const SizedBox(width: 4),
        Icon(
          _getQualityIcon(call.quality!.qualityScore),
          size: 12,
          color: _getQualityColor(call.quality!.qualityScore),
        ),
      ]);
    }

    return info;
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _CallTileOptionsSheet(call: call, onDelete: onDelete),
    );
  }

  // Helper methods for styling and data
  Color _getBackgroundColor() {
    switch (type) {
      case CallTileType.incoming:
        return Colors.blue.withOpacity(0.05);
      case CallTileType.ongoing:
        return Colors.green.withOpacity(0.05);
      case CallTileType.scheduled:
        return Colors.orange.withOpacity(0.05);
      case CallTileType.history:
      default:
        return Colors.transparent;
    }
  }

  Color _getBorderColor() {
    switch (type) {
      case CallTileType.incoming:
        return Colors.blue.withOpacity(0.2);
      case CallTileType.ongoing:
        return Colors.green.withOpacity(0.2);
      case CallTileType.scheduled:
        return Colors.orange.withOpacity(0.2);
      case CallTileType.history:
      default:
        return Colors.grey.withOpacity(0.1);
    }
  }

  double _getBorderWidth() {
    return type == CallTileType.history ? 0.5 : 1.0;
  }

  Color _getStatusColor() {
    switch (call.status) {
      case CallStatus.ongoing:
        return Colors.green;
      case CallStatus.ringing:
        return Colors.blue;
      case CallStatus.missed:
        return Colors.red;
      case CallStatus.declined:
        return Colors.orange;
      case CallStatus.failed:
        return Colors.red;
      case CallStatus.ended:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Color _getTitleColor() {
    if (call.status == CallStatus.missed) {
      return Colors.red;
    }
    return Colors.black87;
  }

  Color _getCallTypeColor() {
    return call.isVideoCall ? Colors.blue : Colors.green;
  }

  IconData _getCallTypeIcon() {
    return call.isVideoCall ? Icons.videocam : Icons.call;
  }

  String _getCallTitle() {
    if (participants?.isNotEmpty == true) {
      if (participants!.length == 1) {
        return participants!.first.name;
      } else {
        return '${participants!.first.name} and ${participants!.length - 1} others';
      }
    }

    return call.type == CallType.group ? 'Group Call' : 'Unknown';
  }

  String _getStatusText() {
    switch (call.status) {
      case CallStatus.ringing:
        return 'Ringing';
      case CallStatus.ongoing:
        return 'Ongoing';
      case CallStatus.connecting:
        return 'Connecting';
      default:
        return '';
    }
  }

  IconData _getCallDirectionIcon() {
    // This would be determined based on call direction logic
    // For now, using call type as indicator
    switch (call.status) {
      case CallStatus.missed:
        return Icons.call_received;
      case CallStatus.declined:
        return Icons.call_made;
      default:
        return call.isVideoCall ? Icons.videocam : Icons.call;
    }
  }

  Color _getCallDirectionColor() {
    switch (call.status) {
      case CallStatus.missed:
        return Colors.red;
      case CallStatus.ended:
        return Colors.green;
      default:
        return Colors.grey[600]!;
    }
  }

  String _getCallTimeText() {
    if (type == CallTileType.ongoing) {
      return 'In progress';
    }

    if (type == CallTileType.scheduled) {
      return 'Scheduled for ${_formatTime(call.createdAt)}';
    }

    if (showDuration && call.duration != null) {
      return _formatDuration(call.duration!);
    }

    if (showTime) {
      return timeago.format(call.createdAt);
    }

    return '';
  }

  bool _hasSubtitle() {
    return call.endReason != null ||
        (call.quality != null && type == CallTileType.history);
  }

  String _getSubtitle() {
    if (call.endReason != null) {
      return 'Ended: ${call.endReason}';
    }

    if (call.quality != null) {
      return 'Quality: ${_getQualityText(call.quality!.qualityScore)}';
    }

    return '';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
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

  IconData _getQualityIcon(double score) {
    if (score >= 4.0) return Icons.signal_wifi_4_bar;
    if (score >= 3.0) return Icons.signal_cellular_alt_2_bar;
    if (score >= 2.0) return Icons.signal_cellular_alt_2_bar;
    if (score >= 1.0) return Icons.signal_cellular_alt_1_bar;
    return Icons.signal_wifi_0_bar;
  }

  Color _getQualityColor(double score) {
    if (score >= 4.0) return Colors.green;
    if (score >= 3.0) return Colors.orange;
    return Colors.red;
  }

  String _getQualityText(double score) {
    if (score >= 4.0) return 'Excellent';
    if (score >= 3.0) return 'Good';
    if (score >= 2.0) return 'Fair';
    return 'Poor';
  }
}

class _CallTileOptionsSheet extends ConsumerWidget {
  final CallModel call;
  final VoidCallback? onDelete;

  const _CallTileOptionsSheet({required this.call, this.onDelete});

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

          const Text(
            'Call Options',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 16),

          _buildOption(
            icon: Icons.call,
            title: 'Call back',
            onTap: () => _callBack(context),
          ),

          _buildOption(
            icon: Icons.videocam,
            title: 'Video call',
            onTap: () => _videoCall(context),
          ),

          _buildOption(
            icon: Icons.message,
            title: 'Send message',
            onTap: () => _sendMessage(context),
          ),

          _buildOption(
            icon: Icons.info_outline,
            title: 'Call details',
            onTap: () => _showCallDetails(context),
          ),

          _buildOption(
            icon: Icons.delete_outline,
            title: 'Delete call',
            onTap: () => _deleteCall(context),
            isDestructive: true,
          ),

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

  void _callBack(BuildContext context) {
    Navigator.pop(context);
    // Implementation for calling back
  }

  void _videoCall(BuildContext context) {
    Navigator.pop(context);
    // Implementation for video call
  }

  void _sendMessage(BuildContext context) {
    Navigator.pop(context);
    // Implementation for sending message
  }

  void _showCallDetails(BuildContext context) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => _CallDetailsDialog(call: call),
    );
  }

  void _deleteCall(BuildContext context) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: const Text('Delete Call'),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ShadButton.destructive(
            onPressed: () {
              Navigator.pop(context);
              onDelete?.call();
            },
            child: const Text('Delete'),
          ),
        ],
        child: const Text(
          'Are you sure you want to delete this call from your history?',
        ),
      ),
    );
  }
}

class _CallDetailsDialog extends StatelessWidget {
  final CallModel call;

  const _CallDetailsDialog({required this.call});

  @override
  Widget build(BuildContext context) {
    return ShadDialog(
      title: const Text('Call Details'),
      actions: [
        ShadButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
      child: SizedBox(
        width: 300,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow(
              'Type',
              call.isVideoCall ? 'Video Call' : 'Voice Call',
            ),
            _buildDetailRow('Status', call.status.name),
            _buildDetailRow('Date', _formatDateTime(call.createdAt)),
            if (call.duration != null)
              _buildDetailRow('Duration', _formatDuration(call.duration!)),
            if (call.endReason != null)
              _buildDetailRow('End Reason', call.endReason!),
            if (call.quality != null) ...[
              const SizedBox(height: 8),
              const Text(
                'Quality Metrics',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              _buildDetailRow(
                'Score',
                '${call.quality!.qualityScore.toStringAsFixed(1)}/5.0',
              ),
              _buildDetailRow('RTT', '${call.quality!.rtt}ms'),
              _buildDetailRow('Jitter', '${call.quality!.jitter}ms'),
              _buildDetailRow(
                'Packet Loss',
                '${(call.quality!.packetLoss * 100).toStringAsFixed(2)}%',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}
