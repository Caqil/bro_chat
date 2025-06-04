import 'package:bro_chat/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/group/group_model.dart';
import '../../providers/group/group_provider.dart';
import '../../providers/group/group_member_provider.dart';
import '../common/custom_badge.dart';
import '../common/custom_bottom_sheet.dart';

enum GroupTileStyle {
  list, // Standard list item
  card, // Card layout with more info
  compact, // Minimal display
  search, // Search result display
}

class GroupTile extends ConsumerWidget {
  final String groupId;
  final GroupTileStyle style;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showLastMessage;
  final bool showMemberCount;
  final bool showActions;
  final bool showOnlineCount;
  final bool isSelected;
  final Widget? trailing;

  const GroupTile({
    super.key,
    required this.groupId,
    this.style = GroupTileStyle.list,
    this.onTap,
    this.onLongPress,
    this.showLastMessage = true,
    this.showMemberCount = true,
    this.showActions = true,
    this.showOnlineCount = false,
    this.isSelected = false,
    this.trailing,
  });

  factory GroupTile.card({
    Key? key,
    required String groupId,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    bool showActions = true,
  }) {
    return GroupTile(
      key: key,
      groupId: groupId,
      style: GroupTileStyle.card,
      onTap: onTap,
      onLongPress: onLongPress,
      showActions: showActions,
      showMemberCount: true,
      showOnlineCount: true,
    );
  }

  factory GroupTile.compact({
    Key? key,
    required String groupId,
    VoidCallback? onTap,
    bool isSelected = false,
  }) {
    return GroupTile(
      key: key,
      groupId: groupId,
      style: GroupTileStyle.compact,
      onTap: onTap,
      isSelected: isSelected,
      showLastMessage: false,
      showMemberCount: false,
      showActions: false,
    );
  }

  factory GroupTile.search({
    Key? key,
    required String groupId,
    VoidCallback? onTap,
  }) {
    return GroupTile(
      key: key,
      groupId: groupId,
      style: GroupTileStyle.search,
      onTap: onTap,
      showLastMessage: false,
      showActions: false,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fix 1: Watch the async provider, not the data provider
    final groupAsync = ref.watch(groupProvider(groupId));

    return groupAsync.when(
      loading: () => _buildSkeleton(context),
      error: (error, stackTrace) => _buildError(context),
      data: (groupState) {
        final group = groupState.group;
        if (group == null) return const SizedBox.shrink();

        switch (style) {
          case GroupTileStyle.list:
            return _buildListTile(context, ref, group);
          case GroupTileStyle.card:
            return _buildCardTile(context, ref, group);
          case GroupTileStyle.compact:
            return _buildCompactTile(context, group);
          case GroupTileStyle.search:
            return _buildSearchTile(context, ref, group);
        }
      },
    );
  }

  // Fix 2: Simplify method signatures to not require AsyncValue parameters
  Widget _buildListTile(BuildContext context, WidgetRef ref, GroupInfo group) {
    // Get the actual int values
    final memberCount = ref.watch(groupMemberCountProvider(groupId));
    final onlineCount = showOnlineCount
        ? ref.watch(groupOnlineCountProvider(groupId))
        : 0;

    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
            : null,
        border: isSelected
            ? Border.all(color: Theme.of(context).colorScheme.primary)
            : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        onTap: onTap,
        onLongPress: onLongPress ?? () => _showActions(context, ref, group),
        leading: _buildAvatar(group),
        title: _buildTitle(context, group),
        subtitle: _buildSubtitle(context, group, memberCount, onlineCount),
        trailing: trailing ?? _buildTrailing(context, ref, group),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildCardTile(BuildContext context, WidgetRef ref, GroupInfo group) {
    final memberCount = ref.watch(groupMemberCountProvider(groupId));
    final onlineCount = showOnlineCount
        ? ref.watch(groupOnlineCountProvider(groupId))
        : 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress ?? () => _showActions(context, ref, group),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildAvatar(group, size: 48),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTitle(context, group),
                        const SizedBox(height: 4),
                        _buildGroupMetadata(context, group),
                      ],
                    ),
                  ),
                  if (showActions) _buildCardActions(context, ref, group),
                ],
              ),
              if (group.description?.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                Text(
                  group.description!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              _buildCardStats(context, group, memberCount, onlineCount),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactTile(BuildContext context, GroupInfo group) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
            : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        onTap: onTap,
        leading: _buildAvatar(group, size: 32),
        title: Text(
          group.name,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: _buildGroupBadges(group),
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }

  Widget _buildSearchTile(
    BuildContext context,
    WidgetRef ref,
    GroupInfo group,
  ) {
    final memberCount = showMemberCount
        ? ref.watch(groupMemberCountProvider(groupId))
        : 0;

    return ListTile(
      onTap: onTap,
      leading: _buildAvatar(group),
      title: _buildTitle(context, group),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (group.description?.isNotEmpty == true)
            Text(
              group.description!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          const SizedBox(height: 2),
          Row(
            children: [
              Text(
                '${group.displayType} • ${group.displayPrivacy}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (showMemberCount) ...[
                const Text(' • '),
                Text(
                  '$memberCount member${memberCount != 1 ? 's' : ''}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      trailing: _buildJoinButton(context, ref, group),
    );
  }

  Widget _buildAvatar(GroupInfo group, {double size = 40}) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.primary.withOpacity(0.1),
      backgroundImage: group.avatar != null
          ? NetworkImage(group.avatar!)
          : null,
      child: group.avatar == null
          ? Icon(Icons.group, size: size * 0.6, color: AppColors.primary)
          : null,
    );
  }

  Widget _buildTitle(BuildContext context, GroupInfo group) {
    return Row(
      children: [
        Expanded(
          child: Text(
            group.name,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        _buildGroupBadges(group),
      ],
    );
  }

  Widget _buildGroupBadges(GroupInfo group) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (group.isVerified) ...[
          CustomBadge.dot(color: Colors.blue, size: BadgeSize.small),
          const SizedBox(width: 4),
        ],
        if (group.isArchived) ...[
          CustomBadge(
            text: 'Archived',
            color: Colors.grey,
            size: BadgeSize.small,
          ),
          const SizedBox(width: 4),
        ],
        if (group.isMuted) ...[
          Icon(Icons.volume_off, size: 16, color: AppColors.secondaryVariant),
          const SizedBox(width: 4),
        ],
        if (group.isPinned) ...[
          Icon(Icons.push_pin, size: 16, color: AppColors.primary),
        ],
      ],
    );
  }

  Widget _buildSubtitle(
    BuildContext context,
    GroupInfo group,
    int memberCount,
    int onlineCount,
  ) {
    final subtitleParts = <String>[];

    if (showLastMessage && group.lastMessageAt != null) {
      subtitleParts.add(_formatLastActivity(group.lastMessageAt!));
    }

    if (showMemberCount) {
      subtitleParts.add('$memberCount member${memberCount != 1 ? 's' : ''}');
    }

    if (showOnlineCount && onlineCount > 0) {
      subtitleParts.add('$onlineCount online');
    }

    return Text(
      subtitleParts.join(' • '),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildGroupMetadata(BuildContext context, GroupInfo group) {
    return Row(
      children: [
        Text(
          group.displayType,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: group.isPublic ? Colors.green : Colors.orange,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Text(' • '),
        Text(
          group.displayPrivacy,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildCardStats(
    BuildContext context,
    GroupInfo group,
    int memberCount,
    int onlineCount,
  ) {
    return Row(
      children: [
        _buildStatChip(Icons.people, memberCount.toString(), 'Members'),
        const SizedBox(width: 8),
        if (showOnlineCount)
          _buildStatChip(
            Icons.circle,
            onlineCount.toString(),
            'Online',
            color: Colors.green,
          ),
        const SizedBox(width: 8),
        _buildStatChip(
          Icons.message,
          group.messageCount.toString(),
          'Messages',
        ),
        const Spacer(),
        if (group.lastActivityAt != null)
          Text(
            _formatLastActivity(group.lastActivityAt!),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }

  Widget _buildStatChip(
    IconData icon,
    String value,
    String label, {
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? Colors.grey).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color ?? Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color ?? Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildTrailing(BuildContext context, WidgetRef ref, GroupInfo group) {
    if (!showActions) return null;

    return PopupMenuButton<String>(
      onSelected: (action) => _handleQuickAction(context, ref, group, action),
      itemBuilder: (context) => [
        if (!group.isMuted)
          const PopupMenuItem(
            value: 'mute',
            child: ListTile(
              leading: Icon(Icons.volume_off),
              title: Text('Mute'),
              contentPadding: EdgeInsets.zero,
            ),
          )
        else
          const PopupMenuItem(
            value: 'unmute',
            child: ListTile(
              leading: Icon(Icons.volume_up),
              title: Text('Unmute'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        if (!group.isPinned)
          const PopupMenuItem(
            value: 'pin',
            child: ListTile(
              leading: Icon(Icons.push_pin),
              title: Text('Pin'),
              contentPadding: EdgeInsets.zero,
            ),
          )
        else
          const PopupMenuItem(
            value: 'unpin',
            child: ListTile(
              leading: Icon(Icons.push_pin_outlined),
              title: Text('Unpin'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        const PopupMenuItem(
          value: 'info',
          child: ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Group Info'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
      child: const Icon(Icons.more_vert),
    );
  }

  Widget _buildCardActions(
    BuildContext context,
    WidgetRef ref,
    GroupInfo group,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () => _toggleMute(context, ref, group),
          icon: Icon(
            group.isMuted ? Icons.volume_off : Icons.volume_up,
            color: group.isMuted ? Colors.orange : null,
          ),
          iconSize: 20,
        ),
        IconButton(
          onPressed: () => _togglePin(context, ref, group),
          icon: Icon(
            group.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
            color: group.isPinned
                ? Theme.of(context).colorScheme.primary
                : null,
          ),
          iconSize: 20,
        ),
        IconButton(
          onPressed: () => _showActions(context, ref, group),
          icon: const Icon(Icons.more_vert),
          iconSize: 20,
        ),
      ],
    );
  }

  Widget _buildJoinButton(
    BuildContext context,
    WidgetRef ref,
    GroupInfo group,
  ) {
    // TODO: Check if user is already a member
    final isMember = false; // This should come from membership provider

    if (isMember) {
      return const Icon(Icons.check_circle, color: Colors.green);
    }

    if (group.requiresApproval) {
      return ShadButton.outline(
        onPressed: () => _requestToJoin(context, ref, group),
        size: ShadButtonSize.sm,
        child: const Text('Request'),
      );
    }

    if (group.canJoinFreely || group.hasInviteLink) {
      return ShadButton(
        onPressed: () => _joinGroup(context, ref, group),
        size: ShadButtonSize.sm,
        child: const Text('Join'),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildSkeleton(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(radius: 20, backgroundColor: Colors.grey[300]),
      title: Container(
        height: 16,
        width: 120,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      subtitle: Container(
        height: 12,
        width: 80,
        margin: const EdgeInsets.only(top: 4),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: Colors.red.withOpacity(0.1),
        child: const Icon(Icons.error_outline, color: Colors.red),
      ),
      title: const Text('Failed to load group'),
      subtitle: const Text('Tap to retry'),
      onTap: () {
        // TODO: Retry loading group
      },
    );
  }

  Future<void> _handleQuickAction(
    BuildContext context,
    WidgetRef ref,
    GroupInfo group,
    String action,
  ) async {
    switch (action) {
      case 'mute':
        await _toggleMute(context, ref, group);
        break;
      case 'unmute':
        await _toggleMute(context, ref, group);
        break;
      case 'pin':
        await _togglePin(context, ref, group);
        break;
      case 'unpin':
        await _togglePin(context, ref, group);
        break;
      case 'info':
        _showGroupInfo(context, group);
        break;
    }
  }

  Future<void> _toggleMute(
    BuildContext context,
    WidgetRef ref,
    GroupInfo group,
  ) async {
    try {
      final notifier = ref.read(groupProvider(groupId).notifier);
      await notifier.muteGroup(mute: !group.isMuted);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(group.isMuted ? 'Group unmuted' : 'Group muted'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to ${group.isMuted ? 'unmute' : 'mute'} group: $e',
            ),
          ),
        );
      }
    }
  }

  Future<void> _togglePin(
    BuildContext context,
    WidgetRef ref,
    GroupInfo group,
  ) async {
    try {
      final notifier = ref.read(groupProvider(groupId).notifier);
      await notifier.pinGroup(!group.isPinned);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(group.isPinned ? 'Group unpinned' : 'Group pinned'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to ${group.isPinned ? 'unpin' : 'pin'} group: $e',
            ),
          ),
        );
      }
    }
  }

  void _showActions(BuildContext context, WidgetRef ref, GroupInfo group) {
    ActionBottomSheet.show(
      context: context,
      title: group.name,
      actions: [
        ActionBottomSheetItem(
          title: 'Group Info',
          icon: Icons.info_outline,
          onTap: () => _showGroupInfo(context, group),
        ),
        ActionBottomSheetItem(
          title: group.isMuted ? 'Unmute' : 'Mute',
          icon: group.isMuted ? Icons.volume_up : Icons.volume_off,
          onTap: () => _toggleMute(context, ref, group),
        ),
        ActionBottomSheetItem(
          title: group.isPinned ? 'Unpin' : 'Pin',
          icon: group.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
          onTap: () => _togglePin(context, ref, group),
        ),
        ActionBottomSheetItem(
          title: 'Leave Group',
          icon: Icons.exit_to_app,
          isDestructive: true,
          onTap: () => _leaveGroup(context, ref, group),
        ),
      ],
    );
  }

  void _showGroupInfo(BuildContext context, GroupInfo group) {
    // TODO: Navigate to group info page
  }

  Future<void> _joinGroup(
    BuildContext context,
    WidgetRef ref,
    GroupInfo group,
  ) async {
    try {
      final notifier = ref.read(groupProvider(groupId).notifier);
      await notifier.joinGroup();

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Joined ${group.name}')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to join group: $e')));
      }
    }
  }

  Future<void> _requestToJoin(
    BuildContext context,
    WidgetRef ref,
    GroupInfo group,
  ) async {
    // TODO: Implement join request
  }

  Future<void> _leaveGroup(
    BuildContext context,
    WidgetRef ref,
    GroupInfo group,
  ) async {
    try {
      final notifier = ref.read(groupProvider(groupId).notifier);
      await notifier.leaveGroup();

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Left ${group.name}')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to leave group: $e')));
      }
    }
  }

  String _formatLastActivity(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }
}
