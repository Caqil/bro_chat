// Minimal fix: Update GroupPermissionsWidget to work with existing GroupSettingsData
// This doesn't require adding new models

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
  late GroupSettingsData _localSettings;
  bool _hasChanges = false;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(groupProvider(widget.groupId));
    final settingsData = ref.watch(groupSettingsDataProvider(widget.groupId));

    return groupAsync.when(
      loading: () => const LoadingWidget(message: 'Loading permissions...'),
      error: (error, stackTrace) => CustomErrorWidget(
        error: AppError.unknown(
          message: 'Failed to load group permissions',
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

        // Initialize local settings when data is loaded
        if (!_hasChanges) {
          _localSettings = settingsData;
        }

        return _buildPermissionsContent(_localSettings);
      },
    );
  }

  Widget _buildPermissionsContent(GroupSettingsData settings) {
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
          'Configure who can perform various actions in this group.',
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
        _localSettings.messagePermission,
        (permission) => _updateMessagePermission(permission),
      ),
      _buildPermissionTile(
        'Send Media',
        'Who can send media files in this group',
        _localSettings.mediaPermission,
        (permission) => _updateMediaPermission(permission),
      ),
    ]);
  }

  Widget _buildMemberManagementPermissions() {
    return _buildPermissionSection('Member Management', Icons.people, [
      _buildPermissionTile(
        'Add Members',
        'Who can add new members to the group',
        _localSettings.memberAddPermission,
        (permission) => _updateMemberAddPermission(permission),
      ),
      _buildPermissionTile(
        'Edit Group Info',
        'Who can change group name, description, and avatar',
        _localSettings.groupInfoEditPermission,
        (permission) => _updateGroupInfoEditPermission(permission),
      ),
    ]);
  }

  Widget _buildContentPermissions() {
    return _buildPermissionSection('Content & Media', Icons.perm_media, [
      _buildSwitchTile(
        'Allow Polls',
        'Enable poll creation in this group',
        _localSettings.allowPolls,
        (value) => _updateSetting((s) => s.copyWith(allowPolls: value)),
      ),
      _buildSwitchTile(
        'Allow Files',
        'Enable file sharing in this group',
        _localSettings.allowFiles,
        (value) => _updateSetting((s) => s.copyWith(allowFiles: value)),
      ),
    ]);
  }

  Widget _buildModerationPermissions() {
    return _buildPermissionSection('Moderation', Icons.security, [
      _buildSwitchTile(
        'Word Filter',
        'Enable automatic word filtering',
        _localSettings.enableWordFilter,
        (value) => _updateSetting((s) => s.copyWith(enableWordFilter: value)),
      ),
      _buildSwitchTile(
        'Anti-Spam',
        'Enable anti-spam protection',
        _localSettings.enableAntiSpam,
        (value) => _updateSetting((s) => s.copyWith(enableAntiSpam: value)),
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

  Widget _buildPermissionTile<T>(
    String title,
    String description,
    T currentValue,
    ValueChanged<T> onChanged,
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
          _buildDropdown<T>(currentValue, onChanged),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String description,
    bool currentValue,
    ValueChanged<bool> onChanged,
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
          Switch(
            value: currentValue,
            onChanged: widget.isEditable ? onChanged : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>(T currentValue, ValueChanged<T> onChanged) {
    List<DropdownMenuItem<T>> items = [];

    if (T == MessagePermission) {
      items = MessagePermission.values.map((permission) {
        return DropdownMenuItem<T>(
          value: permission as T,
          child: Text(_getPermissionLabel(permission)),
        );
      }).toList();
    } else if (T == MediaPermission) {
      items = MediaPermission.values.map((permission) {
        return DropdownMenuItem<T>(
          value: permission as T,
          child: Text(_getPermissionLabel(permission)),
        );
      }).toList();
    } else if (T == MemberAddPermission) {
      items = MemberAddPermission.values.map((permission) {
        return DropdownMenuItem<T>(
          value: permission as T,
          child: Text(_getPermissionLabel(permission)),
        );
      }).toList();
    } else if (T == GroupInfoEditPermission) {
      items = GroupInfoEditPermission.values.map((permission) {
        return DropdownMenuItem<T>(
          value: permission as T,
          child: Text(_getPermissionLabel(permission)),
        );
      }).toList();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<T>(
        value: currentValue,
        onChanged: widget.isEditable
            ? (T? value) {
                if (value != null) {
                  onChanged(value);
                }
              }
            : null,
        underline: const SizedBox.shrink(),
        items: items,
      ),
    );
  }

  String _getPermissionLabel(dynamic permission) {
    switch (permission.runtimeType) {
      case MessagePermission:
        switch (permission as MessagePermission) {
          case MessagePermission.everyone:
            return 'Everyone';
          case MessagePermission.adminsOnly:
            return 'Admins Only';
          case MessagePermission.moderatorsAndAdmins:
            return 'Moderators+';
          case MessagePermission.membersOnly:
            return 'Members Only';
          case MessagePermission.disabled:
            return 'Disabled';
        }
      case MediaPermission:
        switch (permission as MediaPermission) {
          case MediaPermission.everyone:
            return 'Everyone';
          case MediaPermission.adminsOnly:
            return 'Admins Only';
          case MediaPermission.moderatorsAndAdmins:
            return 'Moderators+';
          case MediaPermission.membersOnly:
            return 'Members Only';
          case MediaPermission.disabled:
            return 'Disabled';
        }
      case MemberAddPermission:
        switch (permission as MemberAddPermission) {
          case MemberAddPermission.everyone:
            return 'Everyone';
          case MemberAddPermission.adminsOnly:
            return 'Admins Only';
          case MemberAddPermission.moderatorsAndAdmins:
            return 'Moderators+';
          case MemberAddPermission.disabled:
            return 'Disabled';
        }
      case GroupInfoEditPermission:
        switch (permission as GroupInfoEditPermission) {
          case GroupInfoEditPermission.adminsOnly:
            return 'Admins Only';
          case GroupInfoEditPermission.moderatorsAndAdmins:
            return 'Moderators+';
          case GroupInfoEditPermission.disabled:
            return 'Disabled';
        }
      default:
        return permission.toString();
    }
  }

  Widget _buildActions() {
    return Row(
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
    );
  }

  void _updateSetting(GroupSettingsData Function(GroupSettingsData) updater) {
    if (!widget.isEditable) return;

    setState(() {
      _localSettings = updater(_localSettings);
      _hasChanges = true;
    });
  }

  void _updateMessagePermission(MessagePermission permission) {
    _updateSetting((s) => s.copyWith(messagePermission: permission));
  }

  void _updateMediaPermission(MediaPermission permission) {
    _updateSetting((s) => s.copyWith(mediaPermission: permission));
  }

  void _updateMemberAddPermission(MemberAddPermission permission) {
    _updateSetting((s) => s.copyWith(memberAddPermission: permission));
  }

  void _updateGroupInfoEditPermission(GroupInfoEditPermission permission) {
    _updateSetting((s) => s.copyWith(groupInfoEditPermission: permission));
  }

  void _resetChanges() {
    final originalSettings = ref.read(
      groupSettingsDataProvider(widget.groupId),
    );

    setState(() {
      _localSettings = originalSettings;
      _hasChanges = false;
    });
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);

    try {
      final notifier = ref.read(groupSettingsProvider(widget.groupId).notifier);
      await notifier.updateSettings(_localSettings);

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
}
