import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/chat/chat_model.dart';
import '../../models/chat/participant_model.dart';
import '../../providers/chat/chat_provider.dart';
import '../../providers/chat/typing_provider.dart';
import '../../providers/call/call_provider.dart';
import '../common/custom_app_bar.dart';

class ChatAppBarWidget extends ConsumerWidget implements PreferredSizeWidget {
  final String chatId;
  final VoidCallback? onBack;
  final VoidCallback? onAudioCall;
  final VoidCallback? onVideoCall;
  final VoidCallback? onChatInfo;
  final VoidCallback? onSearch;
  final bool showCallButtons;
  final bool showSearch;
  final bool compact;

  const ChatAppBarWidget({
    super.key,
    required this.chatId,
    this.onBack,
    this.onAudioCall,
    this.onVideoCall,
    this.onChatInfo,
    this.onSearch,
    this.showCallButtons = true,
    this.showSearch = true,
    this.compact = false,
  });

  @override
  Size get preferredSize => Size.fromHeight(compact ? 56 : 70);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatProvider(chatId));
    final typingState = ref.watch(chatTypingProvider(chatId));
    final isAnyoneTyping = ref.watch(isAnyoneTypingProvider(chatId));

    return chatState.when(
      data: (state) {
        if (!state.hasChat) {
          return _buildLoadingAppBar(context);
        }

        return _buildChatAppBar(
          context,
          ref,
          state.chat!,
          typingState,
          isAnyoneTyping,
        );
      },
      loading: () => _buildLoadingAppBar(context),
      error: (_, __) => _buildErrorAppBar(context),
    );
  }

  Widget _buildChatAppBar(
    BuildContext context,
    WidgetRef ref,
    ChatModel chat,
    ChatTypingState? typingState,
    bool isAnyoneTyping,
  ) {
    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      leading: _buildBackButton(context),
      title: _buildChatTitle(context, ref, chat, typingState, isAnyoneTyping),
      actions: _buildActions(context, ref, chat),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: Colors.grey[200]),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return ShadButton.ghost(
      onPressed: onBack ?? () => Navigator.of(context).pop(),
      child: const Icon(Icons.arrow_back, size: 24),
    );
  }

  Widget _buildChatTitle(
    BuildContext context,
    WidgetRef ref,
    ChatModel chat,
    ChatTypingState? typingState,
    bool isAnyoneTyping,
  ) {
    return GestureDetector(
      onTap: onChatInfo,
      child: Row(
        children: [
          _buildChatAvatar(chat),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  chat.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                _buildSubtitle(context, ref, chat, typingState, isAnyoneTyping),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatAvatar(ChatModel chat) {
    if (chat.isGroup) {
      return _buildGroupAvatar(chat);
    } else {
      return _buildPrivateAvatar(chat);
    }
  }

  Widget _buildGroupAvatar(ChatModel chat) {
    return Container(
      width: compact ? 36 : 42,
      height: compact ? 36 : 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: ClipOval(
        child: chat.avatar != null
            ? CachedNetworkImage(
                imageUrl: chat.avatar!,
                fit: BoxFit.cover,
                placeholder: (context, url) => _buildInitialsAvatar(chat.name),
                errorWidget: (context, url, error) =>
                    _buildInitialsAvatar(chat.name),
              )
            : _buildInitialsAvatar(chat.name),
      ),
    );
  }

  Widget _buildPrivateAvatar(ChatModel chat) {
    final participant = chat.participants.isNotEmpty
        ? chat.participants.first
        : null;

    return Stack(
      children: [
        Container(
          width: compact ? 36 : 42,
          height: compact ? 36 : 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey[300]!, width: 1),
          ),
          child: ClipOval(
            child: participant?.avatar != null
                ? CachedNetworkImage(
                    imageUrl: participant!.avatar!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        _buildInitialsAvatar(participant.name),
                    errorWidget: (context, url, error) =>
                        _buildInitialsAvatar(participant.name),
                  )
                : _buildInitialsAvatar(participant?.name ?? 'Unknown'),
          ),
        ),

        // Online status indicator
        if (participant?.isOnline == true)
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

  Widget _buildInitialsAvatar(String name) {
    return Container(
      width: compact ? 36 : 42,
      height: compact ? 36 : 42,
      color: _getAvatarColor(name),
      child: Center(
        child: Text(
          _getInitials(name),
          style: TextStyle(
            color: Colors.white,
            fontSize: compact ? 14 : 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSubtitle(
    BuildContext context,
    WidgetRef ref,
    ChatModel chat,
    ChatTypingState? typingState,
    bool isAnyoneTyping,
  ) {
    // Show typing indicator if someone is typing
    if (isAnyoneTyping && typingState != null) {
      return Text(
        typingState.getTypingIndicatorText(),
        style: TextStyle(
          fontSize: 12,
          color: Colors.blue[600],
          fontStyle: FontStyle.italic,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    // Show last seen for private chats
    if (chat.isPrivate && chat.participants.isNotEmpty) {
      final participant = chat.participants.first;
      return Text(
        _getLastSeenText(participant),
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    // Show participant count for group chats
    if (chat.isGroup) {
      return Text(
        '${chat.participants.length} participants',
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      );
    }

    return const SizedBox.shrink();
  }

  List<Widget> _buildActions(
    BuildContext context,
    WidgetRef ref,
    ChatModel chat,
  ) {
    final actions = <Widget>[];

    // Search button
    if (showSearch) {
      actions.add(
        ShadButton.ghost(
          onPressed: onSearch,
          child: const Icon(Icons.search, size: 22),
        ),
      );
    }

    // Call buttons
    if (showCallButtons) {
      // Audio call button
      actions.add(
        ShadButton.ghost(
          onPressed: () => _initiateCall(ref, chat, false),
          child: const Icon(Icons.call, size: 22),
        ),
      );

      // Video call button
      actions.add(
        ShadButton.ghost(
          onPressed: () => _initiateCall(ref, chat, true),
          child: const Icon(Icons.videocam, size: 22),
        ),
      );
    }

    // More options button
    actions.add(
      ShadButton.ghost(
        onPressed: () => _showMoreOptions(context, ref, chat),
        child: const Icon(Icons.more_vert, size: 22),
      ),
    );

    return actions;
  }

  Widget _buildLoadingAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      leading: _buildBackButton(context),
      title: Row(
        children: [
          Container(
            width: compact ? 36 : 42,
            height: compact ? 36 : 42,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 80,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      leading: _buildBackButton(context),
      title: const Text(
        'Chat',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Future<void> _initiateCall(
    WidgetRef ref,
    ChatModel chat,
    bool isVideo,
  ) async {
    try {
      final participantIds = chat.participants.map((p) => p.userId).toList();

      await ref
          .read(callProvider.notifier)
          .initiateCall(
            participantIds: participantIds,
            chatId: chat.id,
            videoEnabled: isVideo,
          );

      if (isVideo) {
        onVideoCall?.call();
      } else {
        onAudioCall?.call();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start call: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showMoreOptions(BuildContext context, WidgetRef ref, ChatModel chat) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _ChatOptionsSheet(chat: chat, onChatInfo: onChatInfo),
    );
  }

  String _getLastSeenText(ParticipantModel participant) {
    if (participant.isOnline) {
      return 'online';
    }

    if (participant.lastSeen != null) {
      final now = DateTime.now();
      final lastSeen = participant.lastSeen!;
      final difference = now.difference(lastSeen);

      if (difference.inMinutes < 1) {
        return 'last seen just now';
      } else if (difference.inMinutes < 60) {
        return 'last seen ${difference.inMinutes} min ago';
      } else if (difference.inHours < 24) {
        return 'last seen ${difference.inHours} hr ago';
      } else {
        return 'last seen ${difference.inDays} days ago';
      }
    }

    return 'offline';
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

class _ChatOptionsSheet extends ConsumerWidget {
  final ChatModel chat;
  final VoidCallback? onChatInfo;

  const _ChatOptionsSheet({required this.chat, this.onChatInfo});

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
            'Chat Options',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 16),

          _buildOption(
            icon: Icons.info_outline,
            title: chat.isGroup ? 'Group info' : 'Contact info',
            onTap: () => _handleChatInfo(context),
          ),

          _buildOption(
            icon: Icons.search,
            title: 'Search in chat',
            onTap: () => _searchInChat(context),
          ),

          _buildOption(
            icon: chat.isMuted ? Icons.volume_up : Icons.volume_off,
            title: chat.isMuted ? 'Unmute notifications' : 'Mute notifications',
            onTap: () => _toggleMute(context, ref),
          ),

          _buildOption(
            icon: chat.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
            title: chat.isPinned ? 'Unpin chat' : 'Pin chat',
            onTap: () => _togglePin(context, ref),
          ),

          _buildOption(
            icon: Icons.wallpaper,
            title: 'Change wallpaper',
            onTap: () => _changeWallpaper(context),
          ),

          _buildOption(
            icon: Icons.archive,
            title: chat.isArchived ? 'Unarchive chat' : 'Archive chat',
            onTap: () => _toggleArchive(context, ref),
          ),

          _buildOption(
            icon: Icons.clear_all,
            title: 'Clear chat history',
            onTap: () => _clearChatHistory(context, ref),
          ),

          if (chat.isGroup) ...[
            _buildOption(
              icon: Icons.exit_to_app,
              title: 'Leave group',
              onTap: () => _leaveGroup(context, ref),
              isDestructive: true,
            ),
          ] else ...[
            _buildOption(
              icon: Icons.block,
              title: 'Block contact',
              onTap: () => _blockContact(context, ref),
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

  void _handleChatInfo(BuildContext context) {
    Navigator.pop(context);
    onChatInfo?.call();
  }

  void _searchInChat(BuildContext context) {
    Navigator.pop(context);
    // Implementation for search in chat
  }

  void _toggleMute(BuildContext context, WidgetRef ref) {
    Navigator.pop(context);
    ref.read(chatProvider(chat.id).notifier).muteChat(mute: !chat.isMuted);
  }

  void _togglePin(BuildContext context, WidgetRef ref) {
    Navigator.pop(context);
    ref.read(chatProvider(chat.id).notifier).pinChat(!chat.isPinned);
  }

  void _changeWallpaper(BuildContext context) {
    Navigator.pop(context);
    // Implementation for changing wallpaper
  }

  void _toggleArchive(BuildContext context, WidgetRef ref) {
    Navigator.pop(context);
    ref.read(chatProvider(chat.id).notifier).archiveChat(!chat.isArchived);
  }

  void _clearChatHistory(BuildContext context, WidgetRef ref) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: const Text('Clear Chat History'),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ShadButton.destructive(
            onPressed: () {
              Navigator.pop(context);
              // Implementation for clearing chat history
            },
            child: const Text('Clear'),
          ),
        ],
        child: const Text(
          'Are you sure you want to clear all messages in this chat? This action cannot be undone.',
        ),
      ),
    );
  }

  void _leaveGroup(BuildContext context, WidgetRef ref) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: const Text('Leave Group'),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ShadButton.destructive(
            onPressed: () {
              Navigator.pop(context);
              // Implementation for leaving group
            },
            child: const Text('Leave'),
          ),
        ],
        child: Text('Are you sure you want to leave "${chat.name}"?'),
      ),
    );
  }

  void _blockContact(BuildContext context, WidgetRef ref) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: const Text('Block Contact'),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ShadButton.destructive(
            onPressed: () {
              Navigator.pop(context);
              // Implementation for blocking contact
            },
            child: const Text('Block'),
          ),
        ],
        child: Text(
          'Are you sure you want to block ${chat.name}? You will no longer receive messages from this contact.',
        ),
      ),
    );
  }
}
