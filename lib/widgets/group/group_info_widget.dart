import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/group/group_model.dart';
import '../../models/group/group_settings.dart';
import '../../providers/group/group_provider.dart';
import '../../providers/group/group_member_provider.dart';
import '../../providers/group/group_settings_provider.dart';
import '../../services/api/api_service.dart';
import '../common/custom_text_field.dart';
import '../common/custom_button.dart';
import '../common/custom_dialog.dart';
import '../common/custom_bottom_sheet.dart';
import '../common/loading_widget.dart';
import '../common/error_widget.dart';
import '../common/custom_badge.dart';

class GroupInfoWidget extends ConsumerStatefulWidget {
  final String groupId;
  final bool isEditable;
  final VoidCallback? onGroupUpdated;
  final VoidCallback? onGroupDeleted;

  const GroupInfoWidget({
    super.key,
    required this.groupId,
    this.isEditable = false,
    this.onGroupUpdated,
    this.onGroupDeleted,
  });

  @override
  ConsumerState<GroupInfoWidget> createState() => _GroupInfoWidgetState();
}

class _GroupInfoWidgetState extends ConsumerState<GroupInfoWidget> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isEditing = false;
  bool _isUpdating = false;
  String? _selectedAvatarPath;
  File? _selectedAvatarFile;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(groupProvider(widget.groupId));
    final memberCountAsync = ref.watch(
      groupMemberCountProvider(widget.groupId),
    );
    final onlineCountAsync = ref.watch(
      groupOnlineCountProvider(widget.groupId),
    );

    return groupAsync.when(
      loading: () =>
          LoadingWidget.circular(message: 'Loading group info...'),
      error: (error, stackTrace) => CustomErrorWidget(
        error: AppError.unknown(
          message: 'Failed to load group information',
          technicalDetails: error.toString(),
        ),
        onRetry: () => ref.refresh(groupProvider(widget.groupId)),
      ),
      data: (groupState) {
        if (!groupState.hasGroup) {
          return CustomErrorWidget(
            error: AppError.notFound(message: 'Group not found'),
          );
        }

        final group = groupState.group!;

        // Initialize controllers when data is loaded
        if (!_isEditing && _nameController.text.isEmpty) {
          _nameController.text = group.name;
          _descriptionController.text = group.description ?? '';
        }

        return _buildGroupInfo(group, memberCountAsync, onlineCountAsync);
      },
    );
  }

  Widget _buildGroupInfo(
    GroupInfo group,
    AsyncValue<int> memberCount,
    AsyncValue<int> onlineCount,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(group),
            const SizedBox(height: 24),
            _buildBasicInfo(group),
            const SizedBox(height: 24),
            _buildStats(group, memberCount, onlineCount),
            const SizedBox(height: 24),
            _buildSettings(group),
            const SizedBox(height: 24),
            _buildActions(group),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(GroupInfo group) {
    return Row(
      children: [
        _buildAvatar(group),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _isEditing
                        ? CustomTextField(
                            controller: _nameController,
                            labelText: 'Group Name',
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Group name is required';
                              }
                              if (value.trim().length < 2) {
                                return 'Group name must be at least 2 characters';
                              }
                              return null;
                            },
                          )
                        : Text(
                            group.name,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                  ),
                  _buildGroupBadges(group),
                ],
              ),
              const SizedBox(height: 8),
              _buildGroupMetadata(group),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(GroupInfo group) {
    Widget avatarWidget = CircleAvatar(
      radius: 40,
      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      backgroundImage: _selectedAvatarFile != null
          ? FileImage(_selectedAvatarFile!)
          : (group.avatar != null ? NetworkImage(group.avatar!) : null),
      child: group.avatar == null && _selectedAvatarFile == null
          ? Icon(
              Icons.group,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
    );

    if (_isEditing) {
      return Stack(
        children: [
          avatarWidget,
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _pickImage,
                icon: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 16,
                ),
                iconSize: 16,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
            ),
          ),
        ],
      );
    }

    return avatarWidget;
  }

  Widget _buildGroupBadges(GroupInfo group) {
    return Row(
      children: [
        if (group.isVerified)
          CustomBadge(
            text: 'Verified',
            color: Colors.blue,
            size: BadgeSize.small,
          ),
        const SizedBox(width: 4),
        CustomBadge(
          text: group.displayType,
          color: group.isPublic ? Colors.green : Colors.orange,
          size: BadgeSize.small,
        ),
        const SizedBox(width: 4),
        if (group.isArchived)
          CustomBadge(
            text: 'Archived',
            color: Colors.grey,
            size: BadgeSize.small,
          ),
      ],
    );
  }

  Widget _buildGroupMetadata(GroupInfo group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Created ${_formatDate(group.createdAt)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        if (group.category != null) ...[
          const SizedBox(height: 2),
          Text(
            'Category: ${group.category}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBasicInfo(GroupInfo group) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Description',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _isEditing
                ? CustomTextField(
                    controller: _descriptionController,
                    hintText: 'Enter group description...',
                    maxLines: 3,
                    validator: (value) {
                      if (value != null && value.length > 500) {
                        return 'Description must be less than 500 characters';
                      }
                      return null;
                    },
                  )
                : Text(
                    group.description?.isNotEmpty == true
                        ? group.description!
                        : 'No description available',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: group.description?.isNotEmpty == true
                          ? null
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontStyle: group.description?.isNotEmpty == true
                          ? null
                          : FontStyle.italic,
                    ),
                  ),
            if (group.tags.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Tags',
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: group.tags
                    .map(
                      (tag) => Chip(
                        label: Text(tag),
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.1),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStats(
    GroupInfo group,
    AsyncValue<int> memberCount,
    AsyncValue<int> onlineCount,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistics',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Members',
                    memberCount.when(
                      data: (count) => count.toString(),
                      loading: () => '...',
                      error: (_, __) => '?',
                    ),
                    Icons.people,
                    subtitle: '${group.maxMembers} max',
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Online',
                    onlineCount.when(
                      data: (count) => count.toString(),
                      loading: () => '...',
                      error: (_, __) => '?',
                    ),
                    Icons.circle,
                    color: Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Messages',
                    group.messageCount.toString(),
                    Icons.message,
                  ),
                ),
              ],
            ),
            if (group.lastActivityAt != null) ...[
              const SizedBox(height: 16),
              Text(
                'Last activity: ${_formatDateTime(group.lastActivityAt!)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon, {
    String? subtitle,
    Color? color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 24,
          color: color ?? Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
      ],
    );
  }

  Widget _buildSettings(GroupInfo group) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Group Settings',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (widget.isEditable && _canManageGroup(group))
                  ShadButton.ghost(
                    onPressed: () => _showGroupSettings(group),
                    size: ShadButtonSize.sm,
                    child: const Text('Manage'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSettingItem(
              'Privacy',
              group.displayPrivacy,
              Icons.privacy_tip,
            ),
            _buildSettingItem(
              'Join Method',
              _getJoinMethodText(group.joinMethod),
              Icons.how_to_reg,
            ),
            if (group.hasInviteLink)
              _buildSettingItem(
                'Invite Link',
                'Active',
                Icons.link,
                trailing: IconButton(
                  onPressed: () => _shareInviteLink(group),
                  icon: const Icon(Icons.share),
                  iconSize: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(
    String label,
    String value,
    IconData icon, {
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildActions(GroupInfo group) {
    if (!widget.isEditable) return const SizedBox.shrink();

    return Column(
      children: [
        if (_canManageGroup(group)) ...[
          Row(
            children: [
              if (!_isEditing) ...[
                Expanded(
                  child: CustomButton(
                    onPressed: () => setState(() => _isEditing = true),
                    variant: CustomButtonVariant.outline,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.edit, size: 16),
                        SizedBox(width: 8),
                        Text('Edit Group'),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                Expanded(
                  child: CustomButton(
                    onPressed: _cancelEditing,
                    variant: CustomButtonVariant.outline,
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    onPressed: _isUpdating ? null : _saveChanges,
                    isLoading: _isUpdating,
                    child: const Text('Save'),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  onPressed: () => _manageInvites(group),
                  variant: CustomButtonVariant.outline,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.link, size: 16),
                      SizedBox(width: 8),
                      Text('Invite Links'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  onPressed: () => _showDangerousActions(group),
                  variant: CustomButtonVariant.destructive,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.warning, size: 16),
                      SizedBox(width: 8),
                      Text('More'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ] else ...[
          CustomButton(
            onPressed: () => _leaveGroup(group),
            variant: CustomButtonVariant.destructive,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.exit_to_app, size: 16),
                SizedBox(width: 8),
                Text('Leave Group'),
              ],
            ),
          ),
        ],
      ],
    );
  }

  bool _canManageGroup(GroupInfo group) {
    // TODO: Get current user ID from auth provider
    // For now, assume user can manage if they're owner or admin
    return group.adminIds.contains('current_user_id') ||
        group.ownerId == 'current_user_id';
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final result = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      final image = await picker.pickImage(source: result);
      if (image != null) {
        setState(() {
          _selectedAvatarFile = File(image.path);
          _selectedAvatarPath = image.path;
        });
      }
    }
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _selectedAvatarFile = null;
      _selectedAvatarPath = null;

      // Reset form fields
      final group = ref.read(groupProvider(widget.groupId)).value?.group;
      if (group != null) {
        _nameController.text = group.name;
        _descriptionController.text = group.description ?? '';
      }
    });
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUpdating = true);

    try {
      String? avatarUrl;

      // Upload avatar if changed
      if (_selectedAvatarFile != null) {
        final apiService = ref.read(apiServiceProvider);
        final uploadResponse = await apiService.uploadFile(
          file: _selectedAvatarFile!,
          purpose: 'group_avatar',
        );

        if (uploadResponse.success && uploadResponse.data != null) {
          avatarUrl = uploadResponse.data!.url;
        }
      }

      // Update group
      final notifier = ref.read(groupProvider(widget.groupId).notifier);
      await notifier.updateGroup(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        avatar: avatarUrl,
      );

      setState(() {
        _isEditing = false;
        _selectedAvatarFile = null;
        _selectedAvatarPath = null;
      });

      widget.onGroupUpdated?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update group: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  void _showGroupSettings(GroupInfo group) {
    // TODO: Navigate to group settings page
  }

  void _shareInviteLink(GroupInfo group) {
    if (group.inviteLink != null) {
      Clipboard.setData(ClipboardData(text: group.inviteLink!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invite link copied to clipboard')),
      );
    }
  }

  void _manageInvites(GroupInfo group) {
    // TODO: Navigate to invite management page
  }

  void _showDangerousActions(GroupInfo group) {
    ActionBottomSheet.show(
      context: context,
      title: 'Group Management',
      actions: [
        ActionBottomSheetItem(
          title: 'Archive Group',
          icon: Icons.archive,
          onTap: () => _archiveGroup(group),
        ),
        ActionBottomSheetItem(
          title: 'Transfer Ownership',
          icon: Icons.swap_horiz,
          onTap: () => _transferOwnership(group),
        ),
        ActionBottomSheetItem(
          title: 'Delete Group',
          icon: Icons.delete_forever,
          isDestructive: true,
          onTap: () => _deleteGroup(group),
        ),
      ],
    );
  }

  Future<void> _archiveGroup(GroupInfo group) async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Archive Group',
      content:
          'Are you sure you want to archive this group? Members will no longer be able to send messages.',
      confirmText: 'Archive',
      isDestructive: true,
    );

    if (confirmed == true) {
      try {
        final notifier = ref.read(groupProvider(widget.groupId).notifier);
        await notifier.archiveGroup(!group.isArchived);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                group.isArchived ? 'Group unarchived' : 'Group archived',
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to archive group: $e')),
          );
        }
      }
    }
  }

  void _transferOwnership(GroupInfo group) {
    // TODO: Show member picker for ownership transfer
  }

  Future<void> _deleteGroup(GroupInfo group) async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Delete Group',
      content:
          'This action cannot be undone. All messages and files will be permanently deleted.',
      confirmText: 'Delete',
      isDestructive: true,
    );

    if (confirmed == true) {
      try {
        final notifier = ref.read(groupProvider(widget.groupId).notifier);
        await notifier.deleteGroup();

        widget.onGroupDeleted?.call();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to delete group: $e')));
        }
      }
    }
  }

  Future<void> _leaveGroup(GroupInfo group) async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Leave Group',
      content:
          'Are you sure you want to leave "${group.name}"? You\'ll need to be re-invited to rejoin.',
      confirmText: 'Leave',
      isDestructive: true,
    );

    if (confirmed == true) {
      try {
        final notifier = ref.read(groupProvider(widget.groupId).notifier);
        await notifier.leaveGroup();

        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to leave group: $e')));
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year${difference.inDays > 730 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month${difference.inDays > 60 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else {
      return 'Today';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return _formatDate(dateTime);
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  String _getJoinMethodText(GroupJoinMethod method) {
    switch (method) {
      case GroupJoinMethod.free:
        return 'Anyone can join';
      case GroupJoinMethod.invite:
        return 'Invite only';
      case GroupJoinMethod.approval:
        return 'Admin approval required';
      case GroupJoinMethod.link:
        return 'Via invite link';
    }
  }
}
