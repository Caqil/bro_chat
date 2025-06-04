import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/auth/user_model.dart';
import '../../models/group/group_member.dart';
import '../../providers/group/group_member_provider.dart';
import '../../services/api/api_service.dart';
import '../common/custom_text_field.dart';
import '../common/custom_button.dart';
import '../common/custom_bottom_sheet.dart';
import '../common/loading_widget.dart';
import '../common/error_widget.dart';
import '../common/empty_state_widget.dart';
import '../common/custom_badge.dart';

enum MemberPickerMode {
  single, // Select one member
  multiple, // Select multiple members
  exclude, // Select all except some
}

enum MemberSource {
  contacts, // User's contacts
  groupMembers, // Members of a specific group
  searchUsers, // Search all users
  suggestions, // Suggested users
}

class MemberPickerWidget extends ConsumerStatefulWidget {
  final MemberPickerMode mode;
  final MemberSource source;
  final String? groupId;
  final List<String> initialSelected;
  final List<String> excludedUserIds;
  final ValueChanged<List<UserModel>>? onSelectionChanged;
  final String? title;
  final String? subtitle;
  final String? searchHint;
  final int? maxSelection;
  final bool showSelectedCount;
  final bool showOnlineStatus;
  final bool showRoles;
  final Widget Function(UserModel user, bool isSelected, VoidCallback onTap)?
  itemBuilder;

  const MemberPickerWidget({
    super.key,
    this.mode = MemberPickerMode.multiple,
    this.source = MemberSource.contacts,
    this.groupId,
    this.initialSelected = const [],
    this.excludedUserIds = const [],
    this.onSelectionChanged,
    this.title,
    this.subtitle,
    this.searchHint,
    this.maxSelection,
    this.showSelectedCount = true,
    this.showOnlineStatus = true,
    this.showRoles = false,
    this.itemBuilder,
  });

  @override
  ConsumerState<MemberPickerWidget> createState() => _MemberPickerWidgetState();
}

class _MemberPickerWidgetState extends ConsumerState<MemberPickerWidget> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  List<String> _selectedUserIds = [];
  List<UserModel> _allUsers = [];
  List<UserModel> _filteredUsers = [];
  bool _isLoading = false;
  bool _isSearching = false;
  String _searchQuery = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedUserIds = List.from(widget.initialSelected);
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        _buildSearchBar(),
        if (widget.showSelectedCount && _selectedUserIds.isNotEmpty)
          _buildSelectedCounter(),
        Expanded(child: _buildUserList()),
        _buildBottomActions(),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.title != null)
            Text(
              widget.title!,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          if (widget.subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.subtitle!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SearchTextField(
        controller: _searchController,
        hintText: widget.searchHint ?? 'Search users...',
        // Remove onChanged since we're using controller listener
        leadingIcon: _isSearching
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.search),
      ),
    );
  }

  Widget _buildSelectedCounter() {
    final maxText = widget.maxSelection != null
        ? '/${widget.maxSelection}'
        : '';

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            Icons.check_circle,
            color: Theme.of(context).colorScheme.primary,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            '${_selectedUserIds.length}$maxText selected',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          if (_selectedUserIds.isNotEmpty)
            ShadButton.ghost(
              onPressed: _clearSelection,
              size: ShadButtonSize.sm,
              child: const Text('Clear'),
            ),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    if (_isLoading && _allUsers.isEmpty) {
      return LoadingWidget.circular(message: 'Loading users...');
    }

    if (_error != null) {
      return CustomErrorWidget(
        error: AppError.unknown(message: _error!),
        onRetry: _loadUsers,
      );
    }

    if (_filteredUsers.isEmpty) {
      if (_searchQuery.isNotEmpty) {
        return EmptyStateWidget.noSearchResults(query: _searchQuery);
      }
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _filteredUsers.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _filteredUsers.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: InlineLoadingIndicator(message: 'Loading more...'),
          );
        }

        final user = _filteredUsers[index];
        final isSelected = _selectedUserIds.contains(user.id);
        final isExcluded = widget.excludedUserIds.contains(user.id);

        if (isExcluded) return const SizedBox.shrink();

        if (widget.itemBuilder != null) {
          return widget.itemBuilder!(user, isSelected, () => _toggleUser(user));
        }

        return _buildUserTile(user, isSelected);
      },
    );
  }

  Widget _buildUserTile(UserModel user, bool isSelected) {
    final canSelect = _canSelectUser(user);

    return ListTile(
      onTap: canSelect ? () => _toggleUser(user) : null,
      leading: _buildUserAvatar(user),
      title: _buildUserTitle(user),
      subtitle: _buildUserSubtitle(user),
      trailing: _buildUserTrailing(user, isSelected, canSelect),
      enabled: canSelect,
    );
  }

  Widget _buildUserAvatar(UserModel user) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.grey[300],
          backgroundImage: user.avatar != null
              ? NetworkImage(user.avatar!)
              : null,
          child: user.avatar == null
              ? Text(
                  _getInitials(user.name),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                )
              : null,
        ),
        if (widget.showOnlineStatus && user.isOnline)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUserTitle(UserModel user) {
    return Row(
      children: [
        Expanded(
          child: Text(
            user.name,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        _buildUserBadges(user),
      ],
    );
  }

  Widget _buildUserBadges(UserModel user) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (user.isVerified) ...[
          CustomBadge.dot(color: Colors.blue, size: BadgeSize.small),
          const SizedBox(width: 4),
        ],
        if (widget.showRoles && widget.groupId != null) ...[
          _buildRoleBadge(user),
          const SizedBox(width: 4),
        ],
      ],
    );
  }

  Widget _buildRoleBadge(UserModel user) {
    // Handle the case where groupId might be null
    if (widget.groupId == null) return const SizedBox.shrink();

    // Get user's role in the group - this returns GroupMemberInfo? directly
    final member = ref.watch(
      groupMemberByIdProvider((widget.groupId!, user.id)),
    );

    // Since member is GroupMemberInfo? (not AsyncValue), handle it directly
    if (member == null) return const SizedBox.shrink();

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
        return const SizedBox.shrink();
    }

    return CustomBadge(
      text: member.roleDisplayName,
      color: color,
      size: BadgeSize.small,
    );
  }

  Widget? _buildUserSubtitle(UserModel user) {
    final subtitleParts = <String>[];

    if (user.username != null) {
      subtitleParts.add('@${user.username}');
    }

    if (widget.showOnlineStatus) {
      if (user.isOnline) {
        subtitleParts.add('Online');
      } else if (user.lastSeen != null) {
        subtitleParts.add(_formatLastSeen(user.lastSeen!));
      }
    }

    if (subtitleParts.isEmpty) return null;

    return Text(
      subtitleParts.join(' • '),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildUserTrailing(UserModel user, bool isSelected, bool canSelect) {
    if (!canSelect) {
      return const Icon(Icons.block, color: Colors.grey);
    }

    switch (widget.mode) {
      case MemberPickerMode.single:
        return Radio<String>(
          value: user.id,
          groupValue: _selectedUserIds.isNotEmpty
              ? _selectedUserIds.first
              : null,
          onChanged: canSelect ? (_) => _toggleUser(user) : null,
        );

      case MemberPickerMode.multiple:
      case MemberPickerMode.exclude:
        return Checkbox(
          value: isSelected,
          onChanged: canSelect ? (_) => _toggleUser(user) : null,
        );
    }
  }

  Widget _buildBottomActions() {
    if (_selectedUserIds.isEmpty && widget.mode != MemberPickerMode.exclude) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_selectedUserIds.isNotEmpty) ...[
              Expanded(child: _buildSelectedUsersPreview()),
              const SizedBox(width: 16),
            ],
            ShadButton(
              onPressed:
                  _selectedUserIds.isNotEmpty ||
                      widget.mode == MemberPickerMode.exclude
                  ? _confirmSelection
                  : null,
              child: Text(_getConfirmButtonText()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedUsersPreview() {
    final selectedUsers = _allUsers
        .where((u) => _selectedUserIds.contains(u.id))
        .toList();

    if (selectedUsers.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: selectedUsers.length,
        itemBuilder: (context, index) {
          final user = selectedUsers[index];
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey[300],
              backgroundImage: user.avatar != null
                  ? NetworkImage(user.avatar!)
                  : null,
              child: user.avatar == null
                  ? Text(
                      _getInitials(user.name),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    switch (widget.source) {
      case MemberSource.contacts:
        return EmptyStateWidget.noContacts();
      case MemberSource.groupMembers:
        return const EmptyStateWidget(
          type: EmptyStateType.noData,
          title: 'No Members',
          subtitle: 'This group has no members yet',
          iconData: Icons.people_outline,
        );
      case MemberSource.searchUsers:
        return const EmptyStateWidget(
          type: EmptyStateType.noData,
          title: 'No Users Found',
          subtitle: 'Try searching for users by name or username',
          iconData: Icons.person_search,
        );
      case MemberSource.suggestions:
        return const EmptyStateWidget(
          type: EmptyStateType.noData,
          title: 'No Suggestions',
          subtitle: 'No user suggestions available at this time',
          iconData: Icons.person_add_alt_1,
        );
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query == _searchQuery) return;

    setState(() {
      _searchQuery = query;
      _isSearching = true;
    });

    _filterUsers();

    // If searching all users, perform API search
    if (widget.source == MemberSource.searchUsers && query.isNotEmpty) {
      _searchUsers(query);
    } else {
      setState(() => _isSearching = false);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreUsers();
    }
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      List<UserModel> users;

      switch (widget.source) {
        case MemberSource.contacts:
          users = await _loadContacts();
          break;
        case MemberSource.groupMembers:
          users = await _loadGroupMembers();
          break;
        case MemberSource.searchUsers:
          users = await _loadSuggestedUsers();
          break;
        case MemberSource.suggestions:
          users = await _loadSuggestedUsers();
          break;
      }

      setState(() {
        _allUsers = users;
        _isLoading = false;
      });

      _filterUsers();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<List<UserModel>> _loadContacts() async {
    // TODO: Load user's contacts from API
    // For now, return empty list
    return [];
  }

  Future<List<UserModel>> _loadGroupMembers() async {
    if (widget.groupId == null) return [];

    final membersAsync = ref.read(groupMembersProvider(widget.groupId!));
    return membersAsync
        .map(
          (member) => UserModel(
            id: member.userId,
            name: member.name,
            phoneNumber:
                member.phone ?? '', // Provide default empty string if null
            countryCode:
                '+1', // Default country code - this should ideally come from member data
            username: member.username,
            avatar: member.avatar,
            email: member.email,
            isOnline: member.isOnline,
            lastSeen: member.lastActiveAt,
            createdAt: member.joinedAt, // Use joinedAt as createdAt
            updatedAt:
                member.lastActiveAt ??
                member.joinedAt, // Use lastActiveAt or fallback to joinedAt
          ),
        )
        .toList();
  }

  Future<List<UserModel>> _loadSuggestedUsers() async {
    // TODO: Load suggested users from API
    // For now, return empty list
    return [];
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() => _isSearching = false);
      return;
    }

    try {
      // TODO: Search users via API
      // final apiService = ref.read(apiServiceProvider);
      // final response = await apiService.searchUsers(query: query);

      setState(() {
        // _allUsers = response.data ?? [];
        _isSearching = false;
      });

      _filterUsers();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isSearching = false;
      });
    }
  }

  Future<void> _loadMoreUsers() async {
    if (_isLoading) return;

    // TODO: Implement pagination
  }

  void _filterUsers() {
    setState(() {
      if (_searchQuery.isEmpty) {
        _filteredUsers = List.from(_allUsers);
      } else {
        _filteredUsers = _allUsers.where((user) {
          return user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (user.username?.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ??
                  false) ||
              (user.email?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
                  false);
        }).toList();
      }
    });
  }

  bool _canSelectUser(UserModel user) {
    if (widget.excludedUserIds.contains(user.id)) return false;

    if (widget.maxSelection != null &&
        widget.mode == MemberPickerMode.multiple &&
        _selectedUserIds.length >= widget.maxSelection! &&
        !_selectedUserIds.contains(user.id)) {
      return false;
    }

    return true;
  }

  void _toggleUser(UserModel user) {
    setState(() {
      switch (widget.mode) {
        case MemberPickerMode.single:
          _selectedUserIds = [user.id];
          break;

        case MemberPickerMode.multiple:
        case MemberPickerMode.exclude:
          if (_selectedUserIds.contains(user.id)) {
            _selectedUserIds.remove(user.id);
          } else {
            _selectedUserIds.add(user.id);
          }
          break;
      }
    });

    _notifySelectionChanged();
  }

  void _clearSelection() {
    setState(() {
      _selectedUserIds.clear();
    });
    _notifySelectionChanged();
  }

  void _confirmSelection() {
    final selectedUsers = _allUsers
        .where((u) => _selectedUserIds.contains(u.id))
        .toList();
    widget.onSelectionChanged?.call(selectedUsers);
  }

  void _notifySelectionChanged() {
    final selectedUsers = _allUsers
        .where((u) => _selectedUserIds.contains(u.id))
        .toList();
    widget.onSelectionChanged?.call(selectedUsers);
  }

  String _getConfirmButtonText() {
    switch (widget.mode) {
      case MemberPickerMode.single:
        return 'Select';
      case MemberPickerMode.multiple:
        return _selectedUserIds.isEmpty
            ? 'Skip'
            : 'Add ${_selectedUserIds.length}';
      case MemberPickerMode.exclude:
        return 'Continue';
    }
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
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${lastSeen.day}/${lastSeen.month}';
    }
  }
}

// Bottom sheet wrapper for member picker
class MemberPickerBottomSheet {
  static Future<List<UserModel>?> show({
    required BuildContext context,
    MemberPickerMode mode = MemberPickerMode.multiple,
    MemberSource source = MemberSource.contacts,
    String? groupId,
    List<String> initialSelected = const [],
    List<String> excludedUserIds = const [],
    String? title,
    String? subtitle,
    String? searchHint,
    int? maxSelection,
  }) {
    List<UserModel> selectedUsers = [];

    return CustomBottomSheet.show<List<UserModel>>(
      context: context,
      isScrollControlled: true,
      height: MediaQuery.of(context).size.height * 0.8,
      child: MemberPickerWidget(
        mode: mode,
        source: source,
        groupId: groupId,
        initialSelected: initialSelected,
        excludedUserIds: excludedUserIds,
        title: title,
        subtitle: subtitle,
        searchHint: searchHint,
        maxSelection: maxSelection,
        onSelectionChanged: (users) {
          selectedUsers = users;
        },
      ),
    ).then((_) => selectedUsers.isNotEmpty ? selectedUsers : null);
  }
}

// Quick contact picker for adding members
class QuickMemberPicker extends ConsumerWidget {
  final String? groupId;
  final ValueChanged<List<UserModel>>? onMembersSelected;
  final int maxMembers;

  const QuickMemberPicker({
    super.key,
    this.groupId,
    this.onMembersSelected,
    this.maxMembers = 10,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ShadButton.outline(
      onPressed: () => _showMemberPicker(context),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_add, size: 16),
          SizedBox(width: 8),
          Text('Add Members'),
        ],
      ),
    );
  }

  Future<void> _showMemberPicker(BuildContext context) async {
    final selectedMembers = await MemberPickerBottomSheet.show(
      context: context,
      mode: MemberPickerMode.multiple,
      source: groupId != null
          ? MemberSource.contacts
          : MemberSource.searchUsers,
      groupId: groupId,
      title: 'Add Members',
      subtitle: 'Select people to add to the group',
      maxSelection: maxMembers,
    );

    if (selectedMembers != null && selectedMembers.isNotEmpty) {
      onMembersSelected?.call(selectedMembers);
    }
  }
}
