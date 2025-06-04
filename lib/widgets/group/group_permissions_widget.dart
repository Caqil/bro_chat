import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/group/group_settings.dart';
import '../../models/group/group_member.dart';
import '../../providers/group/group_settings_provider.dart';
import '../../providers/group/group_provider.dart';
import '../common/custom_bottom_sheet.dart';
import '../common/custom_button.dart';
import '../common/custom_dialog.dart';
import '../common/loading_widget.dart';
import '../common/error_widget.dart';

class GroupPermissionsWidget extends ConsumerStatefulWidget {
  final String groupId;
  final bool isEditable;
  final VoidCallback? onPermissionsUpdated;

  const GroupPermissionsWidget({
    super.key,
    required this.groupId,
    this.isEditable = true,
    this.onPermissionsUpdated,
  });

  @override
  ConsumerState<GroupPermissionsWidget> createState() =>
      _GroupPermissionsWidgetState();
}

class _GroupPermissionsWidgetState
    extends ConsumerState<GroupPermissionsWidget> {
  late GroupPermissions _localPermissions;
  bool _hasChanges = false;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(groupDataProvider(widget.groupId));
    final settingsAsync = ref.watch(groupSettingsDataProvider(widget.groupId));

    return groupAsync.when(
      loading: () => LoadingWidget.circular(message: 'Loading permissions...'),
      error: (error, stackTrace) => CustomErrorWidget(
        error: AppError.unknown(
          message: 'Failed to load group permissions',
          technicalDetails: error.toString(),
        ),
        onRetry: () => ref.refresh(groupDataProvider(widget.groupId)),
      ),
      data: (group) {
        if (group == null) {
          return CustomErrorWidget(
            error: AppError.notFound(message: 'Group not found'),
          );
        }

        // Initialize local permissions
        if (!_hasChanges) {
          _localPermissions = group.permissions;
        }

        return _buildPermissionsContent(group.permissions, settingsAsync);
      },
    );
  }

  Widget _buildPermissionsContent(
    GroupPermissions permissions,
    GroupSettingsData settings,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildMessagingPermissions(),
          const SizedBox(height: 24),
          _buildMemberManagementPermissions(),
          const SizedBox(height: 24),
          _buildContentPermissions(),
          const SizedBox(height: 24),
          _buildModerationPermissions(),
          const SizedBox(height: 24),
          _buildGroupManagementPermissions(),
          const SizedBox(height: 32),
          if (widget.isEditable) _buildActions(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Group Permissions',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Configure who can perform various actions in this group. Changes will apply to all current and future members.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        if (_hasChanges) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You have unsaved changes',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMessagingPermissions() {
    return _buildPermissionSection('Messaging', Icons.message, [
      _buildPermissionTile(
        'Send Messages',
        'Who can send messages in this group',
        _localPermissions.whoCanSendMessages,
        (role) =>
            _updatePermission((p) => p.copyWith(whoCanSendMessages: role)),
      ),
      _buildPermissionTile(
        'Pin Messages',
        'Who can pin important messages',
        _localPermissions.whoCanPinMessages,
        (role) => _updatePermission((p) => p.copyWith(whoCanPinMessages: role)),
      ),
      _buildPermissionTile(
        'Delete Messages',
        'Who can delete messages from other members',
        _localPermissions.whoCanDeleteMessages,
        (role) =>
            _updatePermission((p) => p.copyWith(whoCanDeleteMessages: role)),
      ),
    ]);
  }

  Widget _buildMemberManagementPermissions() {
    return _buildPermissionSection('Member Management', Icons.people, [
      _buildPermissionTile(
        'Add Members',
        'Who can add new members to the group',
        _localPermissions.whoCanAddMembers,
        (role) => _updatePermission((p) => p.copyWith(whoCanAddMembers: role)),
      ),
      _buildPermissionTile(
        'Remove Members',
        'Who can remove members from the group',
        _localPermissions.whoCanRemoveMembers,
        (role) =>
            _updatePermission((p) => p.copyWith(whoCanRemoveMembers: role)),
      ),
    ]);
  }

  Widget _buildContentPermissions() {
    return _buildPermissionSection('Content & Media', Icons.perm_media, [
      _buildPermissionTile(
        'Create Polls',
        'Who can create polls in the group',
        _localPermissions.whoCanCreatePolls,
        (role) => _updatePermission((p) => p.copyWith(whoCanCreatePolls: role)),
      ),
    ]);
  }

  Widget _buildModerationPermissions() {
    return _buildPermissionSection('Moderation', Icons.security, [
      _buildPermissionTile(
        'Mute Members',
        'Who can mute members in the group',
        _localPermissions.whoCanMuteMembers,
        (role) => _updatePermission((p) => p.copyWith(whoCanMuteMembers: role)),
      ),
      _buildPermissionTile(
        'Ban Members',
        'Who can ban members from the group',
        _localPermissions.whoCanBanMembers,
        (role) => _updatePermission((p) => p.copyWith(whoCanBanMembers: role)),
      ),
    ]);
  }

  Widget _buildGroupManagementPermissions() {
    return _buildPermissionSection('Group Management', Icons.settings, [
      _buildPermissionTile(
        'Edit Group Info',
        'Who can change group name, description, and avatar',
        _localPermissions.whoCanEditGroupInfo,
        (role) =>
            _updatePermission((p) => p.copyWith(whoCanEditGroupInfo: role)),
      ),
    ]);
  }

  Widget _buildPermissionSection(
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionTile(
    String title,
    String description,
    GroupRole currentRole,
    ValueChanged<GroupRole> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _buildRoleSelector(currentRole, onChanged),
        ],
      ),
    );
  }

  Widget _buildRoleSelector(
    GroupRole currentRole,
    ValueChanged<GroupRole> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<GroupRole>(
        value: currentRole,
        onChanged: widget.isEditable ? onChanged : null,
        underline: const SizedBox.shrink(),
        items: [
          DropdownMenuItem(
            value: GroupRole.member,
            child: _buildRoleOption('Everyone', GroupRole.member),
          ),
          DropdownMenuItem(
            value: GroupRole.moderator,
            child: _buildRoleOption('Moderators+', GroupRole.moderator),
          ),
          DropdownMenuItem(
            value: GroupRole.admin,
            child: _buildRoleOption('Admins+', GroupRole.admin),
          ),
          DropdownMenuItem(
            value: GroupRole.owner,
            child: _buildRoleOption('Owner Only', GroupRole.owner),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleOption(String label, GroupRole role) {
    Color color;
    IconData icon;

    switch (role) {
      case GroupRole.owner:
        color = Colors.purple;
        icon = Icons.diamond;
        break;
      case GroupRole.admin:
        color = Colors.blue;
        icon = Icons.admin_panel_settings;
        break;
      case GroupRole.moderator:
        color = Colors.green;
        icon = Icons.shield;
        break;
      case GroupRole.member:
        color = Colors.grey;
        icon = Icons.person;
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }

  Widget _buildActions() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ShadButton.outline(
                onPressed: _hasChanges ? _resetChanges : null,
                child: const Text('Reset'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomButton(
                onPressed: _hasChanges && !_isSaving ? _saveChanges : null,
                isLoading: _isSaving,
                child: const Text('Save Changes'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ShadButton.outline(
          onPressed: _showPermissionPresets,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_fix_high, size: 16),
              SizedBox(width: 8),
              Text('Use Preset'),
            ],
          ),
        ),
      ],
    );
  }

  void _updatePermission(GroupPermissions Function(GroupPermissions) updater) {
    if (!widget.isEditable) return;

    setState(() {
      _localPermissions = updater(_localPermissions);
      _hasChanges = true;
    });
  }

  void _resetChanges() {
    final originalPermissions = ref
        .read(groupDataProvider(widget.groupId))
        .value
        ?.permissions;
    if (originalPermissions != null) {
      setState(() {
        _localPermissions = originalPermissions;
        _hasChanges = false;
      });
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);

    try {
      // TODO: Save permissions via API
      // For now, simulate API call
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _hasChanges = false;
        _isSaving = false;
      });

      widget.onPermissionsUpdated?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permissions updated successfully')),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update permissions: $e')),
        );
      }
    }
  }

  void _showPermissionPresets() {
    CustomBottomSheet.show(
      context: context,
      titleText: 'Permission Presets',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPresetTile(
            'Open Community',
            'Everyone can send messages, create polls, and add members',
            Icons.public,
            () => _applyPreset(_createOpenCommunityPreset()),
          ),
          _buildPresetTile(
            'Moderated Group',
            'Moderators control content and member management',
            Icons.supervised_user_circle,
            () => _applyPreset(_createModeratedGroupPreset()),
          ),
          _buildPresetTile(
            'Admin Only',
            'Only admins can perform most actions',
            Icons.admin_panel_settings,
            () => _applyPreset(_createAdminOnlyPreset()),
          ),
          _buildPresetTile(
            'Owner Controlled',
            'Owner has complete control over the group',
            Icons.crown,
            () => _applyPreset(_createOwnerControlledPreset()),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetTile(
    String title,
    String description,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text(description),
      onTap: () {
        Navigator.of(context).pop();
        onTap();
      },
    );
  }

  void _applyPreset(GroupPermissions preset) {
    setState(() {
      _localPermissions = preset;
      _hasChanges = true;
    });
  }

  GroupPermissions _createOpenCommunityPreset() {
    return GroupPermissions(
      whoCanSendMessages: GroupRole.member,
      whoCanEditGroupInfo: GroupRole.admin,
      whoCanAddMembers: GroupRole.member,
      whoCanRemoveMembers: GroupRole.moderator,
      whoCanMuteMembers: GroupRole.moderator,
      whoCanBanMembers: GroupRole.admin,
      whoCanCreatePolls: GroupRole.member,
      whoCanPinMessages: GroupRole.moderator,
      whoCanDeleteMessages: GroupRole.moderator,
    );
  }

  GroupPermissions _createModeratedGroupPreset() {
    return GroupPermissions(
      whoCanSendMessages: GroupRole.member,
      whoCanEditGroupInfo: GroupRole.admin,
      whoCanAddMembers: GroupRole.moderator,
      whoCanRemoveMembers: GroupRole.moderator,
      whoCanMuteMembers: GroupRole.moderator,
      whoCanBanMembers: GroupRole.admin,
      whoCanCreatePolls: GroupRole.moderator,
      whoCanPinMessages: GroupRole.moderator,
      whoCanDeleteMessages: GroupRole.moderator,
    );
  }

  GroupPermissions _createAdminOnlyPreset() {
    return GroupPermissions(
      whoCanSendMessages: GroupRole.member,
      whoCanEditGroupInfo: GroupRole.admin,
      whoCanAddMembers: GroupRole.admin,
      whoCanRemoveMembers: GroupRole.admin,
      whoCanMuteMembers: GroupRole.admin,
      whoCanBanMembers: GroupRole.admin,
      whoCanCreatePolls: GroupRole.admin,
      whoCanPinMessages: GroupRole.admin,
      whoCanDeleteMessages: GroupRole.admin,
    );
  }

  GroupPermissions _createOwnerControlledPreset() {
    return GroupPermissions(
      whoCanSendMessages: GroupRole.member,
      whoCanEditGroupInfo: GroupRole.owner,
      whoCanAddMembers: GroupRole.owner,
      whoCanRemoveMembers: GroupRole.owner,
      whoCanMuteMembers: GroupRole.owner,
      whoCanBanMembers: GroupRole.owner,
      whoCanCreatePolls: GroupRole.owner,
      whoCanPinMessages: GroupRole.owner,
      whoCanDeleteMessages: GroupRole.owner,
    );
  }
}

// Extension to add copyWith method to GroupPermissions
extension GroupPermissionsCopyWith on GroupPermissions {
  GroupPermissions copyWith({
    GroupRole? whoCanSendMessages,
    GroupRole? whoCanEditGroupInfo,
    GroupRole? whoCanAddMembers,
    GroupRole? whoCanRemoveMembers,
    GroupRole? whoCanMuteMembers,
    GroupRole? whoCanBanMembers,
    GroupRole? whoCanCreatePolls,
    GroupRole? whoCanPinMessages,
    GroupRole? whoCanDeleteMessages,
  }) {
    return GroupPermissions(
      whoCanSendMessages: whoCanSendMessages ?? this.whoCanSendMessages,
      whoCanEditGroupInfo: whoCanEditGroupInfo ?? this.whoCanEditGroupInfo,
      whoCanAddMembers: whoCanAddMembers ?? this.whoCanAddMembers,
      whoCanRemoveMembers: whoCanRemoveMembers ?? this.whoCanRemoveMembers,
      whoCanMuteMembers: whoCanMuteMembers ?? this.whoCanMuteMembers,
      whoCanBanMembers: whoCanBanMembers ?? this.whoCanBanMembers,
      whoCanCreatePolls: whoCanCreatePolls ?? this.whoCanCreatePolls,
      whoCanPinMessages: whoCanPinMessages ?? this.whoCanPinMessages,
      whoCanDeleteMessages: whoCanDeleteMessages ?? this.whoCanDeleteMessages,
    );
  }
}
