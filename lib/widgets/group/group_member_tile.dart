import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/group/group_member.dart';
import '../../providers/group/group_member_provider.dart';
import '../../providers/group/group_provider.dart';
import '../common/custom_badge.dart';
import '../common/custom_button.dart';
import '../common/custom_dialog.dart';
import '../common/custom_bottom_sheet.dart';
import '../common/custom_text_field.dart';
import '../common/error_widget.dart';
import '../common/loading_widget.dart';

class GroupMemberTile extends ConsumerWidget {
  final String groupId;
  final GroupMemberInfo member;
  final bool showActions;
  final bool showLastSeen;
  final bool showRole;
  final VoidCallback? onTap;
  final VoidCallback? onMemberUpdated;

  const GroupMemberTile({
    super.key,
    required this.groupId,
    required this.member,
    this.showActions = true,
    this.showLastSeen = true,
    this.showRole = true,
    this.onTap,
    this.onMemberUpdated,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Option 1: Watch the async provider directly
    final groupAsync = ref.watch(groupProvider(groupId));

    return groupAsync.when(
      loading: () => LoadingWidget(message: 'Loading group info...'),
      error: (error, stackTrace) => CustomErrorWidget(
        error: AppError.notFound(message: 'Group not found'),
      ),
      data: (groupState) {
        final group = groupState.group;
        final currentUserCanManage = _canManageMember(group, member);

        return ListTile(
          onTap: onTap,
          leading: _buildAvatar(),
          title: _buildTitle(context),
          subtitle: _buildSubtitle(context),
          trailing: showActions && currentUserCanManage
              ? _buildActions(context, ref)
              : _buildTrailing(context),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
        );
      },
    );
  }

  Widget _buildAvatar() {
    return Stack(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.grey[300],
          backgroundImage: member.avatar != null
              ? NetworkImage(member.avatar!)
              : null,
          child: member.avatar == null
              ? Text(
                  _getInitials(member.name),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                )
              : null,
        ),
        Positioned(bottom: 0, right: 0, child: _buildOnlineIndicator()),
      ],
    );
  }

  Widget _buildOnlineIndicator() {
    if (!member.isOnline) return const SizedBox.shrink();

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

  Widget _buildTitle(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            member.displayName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
              decoration: member.isBanned ? TextDecoration.lineThrough : null,
              color: member.isBanned
                  ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5)
                  : null,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        _buildStatusBadges(),
      ],
    );
  }

  Widget _buildStatusBadges() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showRole) ...[_buildRoleBadge(), const SizedBox(width: 4)],
        if (member.isMuted) ...[
          CustomBadge(
            text: 'Muted',
            color: Colors.orange,
            size: BadgeSize.small,
          ),
          const SizedBox(width: 4),
        ],
        if (member.isBanned) ...[
          CustomBadge(text: 'Banned', color: Colors.red, size: BadgeSize.small),
          const SizedBox(width: 4),
        ],
        if (member.status != GroupMemberStatus.active) ...[_buildStatusBadge()],
      ],
    );
  }

  Widget _buildRoleBadge() {
    Color color;
    switch (member.role) {
      case GroupRole.owner:
        color = Colors.purple;
        break;
      case GroupRole.admin:
        color = Colors.blue;
        break;
      case GroupRole.moderator:
        color = Colors.green;
        break;
      case GroupRole.member:
        return const SizedBox.shrink(); // Don't show badge for regular members
    }

    return CustomBadge(
      text: member.roleDisplayName,
      color: color,
      size: BadgeSize.small,
    );
  }

  Widget _buildStatusBadge() {
    Color color;
    String text;

    switch (member.status) {
      case GroupMemberStatus.left:
        color = Colors.grey;
        text = 'Left';
        break;
      case GroupMemberStatus.kicked:
        color = Colors.orange;
        text = 'Kicked';
        break;
      case GroupMemberStatus.banned:
        color = Colors.red;
        text = 'Banned';
        break;
      case GroupMemberStatus.active:
        return const SizedBox.shrink();
      case GroupMemberStatus.muted:
        color = Colors.amber;
        text = 'muted';
    }

    return CustomBadge(text: text, color: color, size: BadgeSize.small);
  }

  Widget _buildSubtitle(BuildContext context) {
    final subtitleParts = <String>[];

    if (member.username != null) {
      subtitleParts.add('@${member.username}');
    }

    if (showLastSeen && member.lastActiveAt != null) {
      subtitleParts.add(_formatLastSeen(member.lastActiveAt!));
    } else if (member.isOnline) {
      subtitleParts.add('Online');
    }

    if (member.isMuted && member.mutedUntil != null) {
      final remaining = member.mutedUntil!.difference(DateTime.now());
      if (remaining.isNegative) {
        subtitleParts.add('Mute expired');
      } else {
        subtitleParts.add('Muted for ${_formatDuration(remaining)}');
      }
    }

    if (member.isBanned && member.bannedUntil != null) {
      final remaining = member.bannedUntil!.difference(DateTime.now());
      if (remaining.isNegative) {
        subtitleParts.add('Ban expired');
      } else {
        subtitleParts.add('Banned for ${_formatDuration(remaining)}');
      }
    }

    subtitleParts.add('Joined ${_formatJoinDate(member.joinedAt)}');

    return Text(
      subtitleParts.join(' • '),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget? _buildTrailing(BuildContext context) {
    if (!showLastSeen && !member.isOnline) return null;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (member.isOnline)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Online',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          )
        else if (member.lastActiveAt != null)
          Text(
            _formatLastSeenShort(member.lastActiveAt!),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }

  Widget _buildActions(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      onSelected: (action) => _handleAction(context, ref, action),
      itemBuilder: (context) => _buildMenuItems(context),
      child: const Icon(Icons.more_vert),
    );
  }

  List<PopupMenuEntry<String>> _buildMenuItems(BuildContext context) {
    final items = <PopupMenuEntry<String>>[];

    // View Profile
    items.add(
      const PopupMenuItem(
        value: 'profile',
        child: ListTile(
          leading: Icon(Icons.person),
          title: Text('View Profile'),
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );

    // Send Message
    items.add(
      const PopupMenuItem(
        value: 'message',
        child: ListTile(
          leading: Icon(Icons.message),
          title: Text('Send Message'),
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );

    items.add(const PopupMenuDivider());

    // Role Management
    if (!member.isOwner) {
      items.add(
        const PopupMenuItem(
          value: 'change_role',
          child: ListTile(
            leading: Icon(Icons.admin_panel_settings),
            title: Text('Change Role'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      );
    }

    // Custom Title
    items.add(
      const PopupMenuItem(
        value: 'custom_title',
        child: ListTile(
          leading: Icon(Icons.title),
          title: Text('Set Custom Title'),
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );

    items.add(const PopupMenuDivider());

    // Moderation Actions
    if (!member.isOwner) {
      if (!member.isMuted) {
        items.add(
          const PopupMenuItem(
            value: 'mute',
            child: ListTile(
              leading: Icon(Icons.volume_off, color: Colors.orange),
              title: Text('Mute Member'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        );
      } else {
        items.add(
          const PopupMenuItem(
            value: 'unmute',
            child: ListTile(
              leading: Icon(Icons.volume_up, color: Colors.green),
              title: Text('Unmute Member'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        );
      }

      if (!member.isBanned) {
        items.add(
          const PopupMenuItem(
            value: 'ban',
            child: ListTile(
              leading: Icon(Icons.block, color: Colors.red),
              title: Text('Ban Member'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        );
      } else {
        items.add(
          const PopupMenuItem(
            value: 'unban',
            child: ListTile(
              leading: Icon(Icons.check_circle, color: Colors.green),
              title: Text('Unban Member'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        );
      }

      items.add(
        const PopupMenuItem(
          value: 'remove',
          child: ListTile(
            leading: Icon(Icons.person_remove, color: Colors.red),
            title: Text('Remove from Group'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      );
    }

    return items;
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    String action,
  ) async {
    switch (action) {
      // case 'profile':
      //   _viewProfile(context);
      //   break;
      // case 'message':
      //   _sendMessage(context);
      //   break;
      // case 'change_role':
      //   _changeRole(context, ref);
      //   break;
      // case 'custom_title':
      //   _setCustomTitle(context, ref);
      //   break;
      case 'mute':
        _muteMember(context, ref);
        break;
      case 'unmute':
        _unmuteMember(context, ref);
        break;
      case 'ban':
        _banMember(context, ref);
        break;
      case 'unban':
        _unbanMember(context, ref);
        break;
      case 'remove':
        _removeMember(context, ref);
        break;
    }
  }

  // void _viewProfile(BuildContext context) {
  //   // TODO: Navigate to user profile
  // }

  // void _sendMessage(BuildContext context) {
  //   // TODO: Navigate to direct message with user
  // }

  // Future<void> _changeRole(BuildContext context, WidgetRef ref) async {
  //   final newRole = await SelectionDialog.showSingle<GroupRole>(
  //     context: context,
  //     title: 'Change Member Role',
  //     items: [
  //       SelectionDialogItem(
  //         value: GroupRole.member,
  //         title: 'Member',
  //         subtitle: 'Can send messages and view content',
  //       ),
  //       SelectionDialogItem(
  //         value: GroupRole.moderator,
  //         title: 'Moderator',
  //         subtitle: 'Can moderate messages and manage members',
  //       ),
  //       SelectionDialogItem(
  //         value: GroupRole.admin,
  //         title: 'Admin',
  //         subtitle: 'Can manage group settings and members',
  //       ),
  //     ],
  //     selectedValue: member.role,
  //   );

  //   if (newRole != null && newRole != member.role) {
  //     try {
  //       final notifier = ref.read(groupMemberProvider(groupId).notifier);
  //       await notifier.updateMemberRole(member.userId, newRole);
  //       onMemberUpdated?.call();
  //       if (context.mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(content: Text('Role updated to ${newRole.name}')),
  //         );
  //       }
  //     } catch (e) {
  //       if (context.mounted) {
  //         ScaffoldMessenger.of(
  //           context,
  //         ).showSnackBar(SnackBar(content: Text('Failed to update role: $e')));
  //       }
  //     }
  //   }
  // }

  // Future<void> _setCustomTitle(BuildContext context, WidgetRef ref) async {
  //   final title = await InputDialog.show(
  //     context: context,
  //     title: 'Set Custom Title',
  //     hintText: 'Enter custom title...',
  //     initialValue: member.customTitle,
  //     maxLength: 50,
  //   );

  //   if (title != null) {
  //     try {
  //       final notifier = ref.read(groupMemberProvider(groupId).notifier);
  //       await notifier.setCustomTitle(
  //         member.userId,
  //         title.isEmpty ? null : title,
  //       );
  //       onMemberUpdated?.call();
  //       if (context.mounted) {
  //         ScaffoldMessenger.of(
  //           context,
  //         ).showSnackBar(const SnackBar(content: Text('Custom title updated')));
  //       }
  //     } catch (e) {
  //       if (context.mounted) {
  //         ScaffoldMessenger.of(
  //           context,
  //         ).showSnackBar(SnackBar(content: Text('Failed to update title: $e')));
  //       }
  //     }
  //   }
  // }

  Future<void> _muteMember(BuildContext context, WidgetRef ref) async {
    final result = await _showMuteDialog(context);

    if (result != null) {
      try {
        final notifier = ref.read(groupMemberProvider(groupId).notifier);
        await notifier.muteMember(
          member.userId,
          duration: result['duration'],
          reason: result['reason'],
        );

        onMemberUpdated?.call();

        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Member muted')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to mute member: $e')));
        }
      }
    }
  }

  Future<void> _unmuteMember(BuildContext context, WidgetRef ref) async {
    try {
      final notifier = ref.read(groupMemberProvider(groupId).notifier);
      await notifier.unmuteMember(member.userId);

      onMemberUpdated?.call();

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Member unmuted')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to unmute member: $e')));
      }
    }
  }

  Future<void> _banMember(BuildContext context, WidgetRef ref) async {
    final result = await _showBanDialog(context);

    if (result != null) {
      try {
        final notifier = ref.read(groupMemberProvider(groupId).notifier);
        await notifier.banMember(
          member.userId,
          duration: result['duration'],
          reason: result['reason'],
        );

        onMemberUpdated?.call();

        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Member banned')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to ban member: $e')));
        }
      }
    }
  }

  Future<void> _unbanMember(BuildContext context, WidgetRef ref) async {
    try {
      final notifier = ref.read(groupMemberProvider(groupId).notifier);
      await notifier.unbanMember(member.userId);

      onMemberUpdated?.call();

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Member unbanned')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to unban member: $e')));
      }
    }
  }

  Future<void> _removeMember(BuildContext context, WidgetRef ref) async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Remove Member',
      content: 'Are you sure you want to remove ${member.name} from the group?',
      confirmText: 'Remove',
      isDestructive: true,
    );

    if (confirmed == true) {
      try {
        final notifier = ref.read(groupMemberProvider(groupId).notifier);
        await notifier.removeMember(member.userId);

        onMemberUpdated?.call();

        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Member removed')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to remove member: $e')),
          );
        }
      }
    }
  }

  Future<Map<String, dynamic>?> _showMuteDialog(BuildContext context) async {
    final reasonController = TextEditingController();
    Duration? selectedDuration;

    return await CustomDialog.show<Map<String, dynamic>>(
      context: context,
      title: 'Mute Member',
      contentWidget: StatefulBuilder(
        builder: (context, setState) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select mute duration:'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                _buildDurationChip(
                  '1 hour',
                  const Duration(hours: 1),
                  selectedDuration,
                  setState,
                ),
                _buildDurationChip(
                  '1 day',
                  const Duration(days: 1),
                  selectedDuration,
                  setState,
                ),
                _buildDurationChip(
                  '1 week',
                  const Duration(days: 7),
                  selectedDuration,
                  setState,
                ),
                _buildDurationChip(
                  '1 month',
                  const Duration(days: 30),
                  selectedDuration,
                  setState,
                ),
              ],
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: reasonController,
              labelText: 'Reason (optional)',
              hintText: 'Enter reason for muting...',
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        ShadButton.outline(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ShadButton(
          onPressed: selectedDuration != null
              ? () => Navigator.of(context).pop({
                  'duration': selectedDuration,
                  'reason': reasonController.text.trim().isEmpty
                      ? null
                      : reasonController.text.trim(),
                })
              : null,
          child: const Text('Mute'),
        ),
      ],
    );
  }

  Future<Map<String, dynamic>?> _showBanDialog(BuildContext context) async {
    final reasonController = TextEditingController();
    Duration? selectedDuration;

    return await CustomDialog.show<Map<String, dynamic>>(
      context: context,
      title: 'Ban Member',
      contentWidget: StatefulBuilder(
        builder: (context, setState) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select ban duration:'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                _buildDurationChip(
                  '1 day',
                  const Duration(days: 1),
                  selectedDuration,
                  setState,
                ),
                _buildDurationChip(
                  '1 week',
                  const Duration(days: 7),
                  selectedDuration,
                  setState,
                ),
                _buildDurationChip(
                  '1 month',
                  const Duration(days: 30),
                  selectedDuration,
                  setState,
                ),
                _buildDurationChip(
                  'Permanent',
                  null,
                  selectedDuration,
                  setState,
                ),
              ],
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: reasonController,
              labelText: 'Reason',
              hintText: 'Enter reason for banning...',
              maxLines: 2,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Reason is required for banning';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        ShadButton.outline(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ShadButton.destructive(
          onPressed: () => Navigator.of(context).pop({
            'duration': selectedDuration,
            'reason': reasonController.text.trim(),
          }),
          child: const Text('Ban'),
        ),
      ],
    );
  }

  Widget _buildDurationChip(
    String label,
    Duration? duration,
    Duration? selected,
    StateSetter setState,
  ) {
    final isSelected = duration == selected;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          // selectedDuration = selected ? duration : null;
        });
      },
    );
  }

  bool _canManageMember(GroupInfo? group, GroupMemberInfo member) {
    if (group == null) return false;

    // TODO: Get current user ID from auth provider
    const currentUserId = 'current_user_id';

    // Can't manage yourself
    if (member.userId == currentUserId) return false;

    // Can't manage the owner
    if (member.isOwner) return false;

    // Owner can manage everyone
    if (group.ownerId == currentUserId) return true;

    // Admins can manage moderators and members
    if (group.adminIds.contains(currentUserId)) {
      return !member.isAdmin || member.userId != currentUserId;
    }

    return false;
  }

  String _getInitials(String name) {
    final words = name.trim().split(' ');
    if (words.isEmpty) return '?';

    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    }

    return '${words[0].substring(0, 1)}${words[1].substring(0, 1)}'
        .toUpperCase();
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 5) {
      return 'Last seen just now';
    } else if (difference.inHours < 1) {
      return 'Last seen ${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return 'Last seen ${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return 'Last seen ${difference.inDays}d ago';
    } else {
      return 'Last seen ${lastSeen.day}/${lastSeen.month}';
    }
  }

  String _formatLastSeenShort(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 5) {
      return 'now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }

  String _formatJoinDate(DateTime joinDate) {
    final now = DateTime.now();
    final difference = now.difference(joinDate);

    if (difference.inDays < 1) {
      return 'today';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else {
      return '${joinDate.day}/${joinDate.month}/${joinDate.year}';
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h';
    } else {
      return '${duration.inMinutes}m';
    }
  }
}
