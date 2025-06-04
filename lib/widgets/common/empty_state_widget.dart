import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

enum EmptyStateType {
  noChats,
  noMessages,
  noSearchResults,
  noFiles,
  noContacts,
  noGroups,
  noCallHistory,
  noNotifications,
  networkError,
  serverError,
  noData,
  custom,
}

class EmptyStateWidget extends StatelessWidget {
  final EmptyStateType type;
  final String? title;
  final String? subtitle;
  final Widget? icon;
  final IconData? iconData;
  final String? illustration;
  final Widget? action;
  final String? actionText;
  final VoidCallback? onActionPressed;
  final Color? iconColor;
  final double? iconSize;
  final EdgeInsets? padding;
  final bool showRefreshButton;
  final VoidCallback? onRefresh;

  const EmptyStateWidget({
    super.key,
    required this.type,
    this.title,
    this.subtitle,
    this.icon,
    this.iconData,
    this.illustration,
    this.action,
    this.actionText,
    this.onActionPressed,
    this.iconColor,
    this.iconSize,
    this.padding,
    this.showRefreshButton = false,
    this.onRefresh,
  });

  factory EmptyStateWidget.noChats({Key? key, VoidCallback? onCreateChat}) {
    return EmptyStateWidget(
      key: key,
      type: EmptyStateType.noChats,
      title: 'No Chats Yet',
      subtitle: 'Start a conversation with your friends and family',
      iconData: Icons.chat_bubble_outline,
      actionText: 'Start New Chat',
      onActionPressed: onCreateChat,
    );
  }

  factory EmptyStateWidget.noMessages({Key? key, String? chatName}) {
    return EmptyStateWidget(
      key: key,
      type: EmptyStateType.noMessages,
      title: 'No Messages',
      subtitle: chatName != null
          ? 'Say hi to $chatName to start the conversation'
          : 'Send the first message to start the conversation',
      iconData: Icons.message_outlined,
    );
  }

  factory EmptyStateWidget.noSearchResults({Key? key, String? query}) {
    return EmptyStateWidget(
      key: key,
      type: EmptyStateType.noSearchResults,
      title: 'No Results Found',
      subtitle: query != null
          ? 'No results found for "$query". Try different keywords.'
          : 'Try adjusting your search criteria',
      iconData: Icons.search_off,
    );
  }

  factory EmptyStateWidget.noFiles({Key? key, String? fileType}) {
    return EmptyStateWidget(
      key: key,
      type: EmptyStateType.noFiles,
      title: 'No Files',
      subtitle: fileType != null
          ? 'No $fileType files found in this chat'
          : 'No files have been shared in this chat yet',
      iconData: Icons.folder_open,
    );
  }

  factory EmptyStateWidget.noContacts({Key? key, VoidCallback? onAddContact}) {
    return EmptyStateWidget(
      key: key,
      type: EmptyStateType.noContacts,
      title: 'No Contacts',
      subtitle: 'Add contacts to start chatting with them',
      iconData: Icons.contacts_outlined,
      actionText: 'Add Contact',
      onActionPressed: onAddContact,
    );
  }

  factory EmptyStateWidget.noGroups({
    Key? key,
    VoidCallback? onCreateGroup,
    VoidCallback? onJoinGroup,
  }) {
    return EmptyStateWidget(
      key: key,
      type: EmptyStateType.noGroups,
      title: 'No Groups',
      subtitle: 'Create or join groups to chat with multiple people',
      iconData: Icons.group_outlined,
      action: Column(
        children: [
          ShadButton(
            onPressed: onCreateGroup,
            child: const Text('Create Group'),
          ),
          const SizedBox(height: 8),
          ShadButton.outline(
            onPressed: onJoinGroup,
            child: const Text('Join Group'),
          ),
        ],
      ),
    );
  }

  factory EmptyStateWidget.noCallHistory({Key? key, VoidCallback? onMakeCall}) {
    return EmptyStateWidget(
      key: key,
      type: EmptyStateType.noCallHistory,
      title: 'No Call History',
      subtitle: 'Your call history will appear here',
      iconData: Icons.call_outlined,
      actionText: 'Make Call',
      onActionPressed: onMakeCall,
    );
  }

  factory EmptyStateWidget.noNotifications({Key? key}) {
    return EmptyStateWidget(
      key: key,
      type: EmptyStateType.noNotifications,
      title: 'No Notifications',
      subtitle: 'You\'re all caught up! New notifications will appear here.',
      iconData: Icons.notifications_outlined,
    );
  }

  factory EmptyStateWidget.networkError({Key? key, VoidCallback? onRetry}) {
    return EmptyStateWidget(
      key: key,
      type: EmptyStateType.networkError,
      title: 'Connection Problem',
      subtitle: 'Please check your internet connection and try again',
      iconData: Icons.wifi_off,
      actionText: 'Try Again',
      onActionPressed: onRetry,
      showRefreshButton: true,
      onRefresh: onRetry,
    );
  }

  factory EmptyStateWidget.serverError({Key? key, VoidCallback? onRetry}) {
    return EmptyStateWidget(
      key: key,
      type: EmptyStateType.serverError,
      title: 'Server Error',
      subtitle: 'Something went wrong on our end. Please try again later.',
      iconData: Icons.error_outline,
      actionText: 'Retry',
      onActionPressed: onRetry,
    );
  }

  factory EmptyStateWidget.noData({
    Key? key,
    String? title,
    String? subtitle,
    IconData? iconData,
    VoidCallback? onRefresh,
  }) {
    return EmptyStateWidget(
      key: key,
      type: EmptyStateType.noData,
      title: title ?? 'No Data',
      subtitle: subtitle ?? 'No data available at the moment',
      iconData: iconData ?? Icons.data_array,
      showRefreshButton: onRefresh != null,
      onRefresh: onRefresh,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon/Illustration
          _buildIcon(theme),
          const SizedBox(height: 24),

          // Title
          _buildTitle(theme),
          const SizedBox(height: 8),

          // Subtitle
          _buildSubtitle(theme),
          const SizedBox(height: 32),

          // Action buttons
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildIcon(ThemeData theme) {
    if (icon != null) return icon!;

    if (illustration != null) {
      return Image.asset(
        illustration!,
        width: iconSize ?? 120,
        height: iconSize ?? 120,
        color: iconColor ?? theme.colorScheme.outline,
      );
    }

    final effectiveIconData = iconData ?? _getDefaultIcon();
    final effectiveIconColor = iconColor ?? theme.colorScheme.outline;
    final effectiveIconSize = iconSize ?? 64.0;

    return Container(
      width: effectiveIconSize + 32,
      height: effectiveIconSize + 32,
      decoration: BoxDecoration(
        color: effectiveIconColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        effectiveIconData,
        size: effectiveIconSize,
        color: effectiveIconColor,
      ),
    );
  }

  Widget _buildTitle(ThemeData theme) {
    final effectiveTitle = title ?? _getDefaultTitle();

    return Text(
      effectiveTitle,
      style: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSubtitle(ThemeData theme) {
    final effectiveSubtitle = subtitle ?? _getDefaultSubtitle();

    return Text(
      effectiveSubtitle,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        height: 1.5,
      ),
      textAlign: TextAlign.center,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildActions() {
    final actions = <Widget>[];

    // Custom action widget
    if (action != null) {
      actions.add(action!);
    }
    // Action button
    else if (actionText != null && onActionPressed != null) {
      actions.add(
        ShadButton(onPressed: onActionPressed, child: Text(actionText!)),
      );
    }

    // Refresh button
    if (showRefreshButton && onRefresh != null) {
      if (actions.isNotEmpty) {
        actions.add(const SizedBox(height: 12));
      }
      actions.add(
        ShadButton.outline(
          onPressed: onRefresh,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.refresh, size: 16),
              SizedBox(width: 8),
              Text('Refresh'),
            ],
          ),
        ),
      );
    }

    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(children: actions);
  }

  IconData _getDefaultIcon() {
    switch (type) {
      case EmptyStateType.noChats:
        return Icons.chat_bubble_outline;
      case EmptyStateType.noMessages:
        return Icons.message_outlined;
      case EmptyStateType.noSearchResults:
        return Icons.search_off;
      case EmptyStateType.noFiles:
        return Icons.folder_open;
      case EmptyStateType.noContacts:
        return Icons.contacts_outlined;
      case EmptyStateType.noGroups:
        return Icons.group_outlined;
      case EmptyStateType.noCallHistory:
        return Icons.call_outlined;
      case EmptyStateType.noNotifications:
        return Icons.notifications_outlined;
      case EmptyStateType.networkError:
        return Icons.wifi_off;
      case EmptyStateType.serverError:
        return Icons.error_outline;
      case EmptyStateType.noData:
        return Icons.data_array;
      case EmptyStateType.custom:
        return Icons.info_outline;
    }
  }

  String _getDefaultTitle() {
    switch (type) {
      case EmptyStateType.noChats:
        return 'No Chats Yet';
      case EmptyStateType.noMessages:
        return 'No Messages';
      case EmptyStateType.noSearchResults:
        return 'No Results Found';
      case EmptyStateType.noFiles:
        return 'No Files';
      case EmptyStateType.noContacts:
        return 'No Contacts';
      case EmptyStateType.noGroups:
        return 'No Groups';
      case EmptyStateType.noCallHistory:
        return 'No Call History';
      case EmptyStateType.noNotifications:
        return 'No Notifications';
      case EmptyStateType.networkError:
        return 'Connection Problem';
      case EmptyStateType.serverError:
        return 'Server Error';
      case EmptyStateType.noData:
        return 'No Data';
      case EmptyStateType.custom:
        return 'Empty';
    }
  }

  String _getDefaultSubtitle() {
    switch (type) {
      case EmptyStateType.noChats:
        return 'Start a conversation with your friends and family';
      case EmptyStateType.noMessages:
        return 'Send the first message to start the conversation';
      case EmptyStateType.noSearchResults:
        return 'Try different keywords or check your spelling';
      case EmptyStateType.noFiles:
        return 'No files have been shared yet';
      case EmptyStateType.noContacts:
        return 'Add contacts to start chatting with them';
      case EmptyStateType.noGroups:
        return 'Create or join groups to chat with multiple people';
      case EmptyStateType.noCallHistory:
        return 'Your call history will appear here';
      case EmptyStateType.noNotifications:
        return 'You\'re all caught up!';
      case EmptyStateType.networkError:
        return 'Please check your internet connection and try again';
      case EmptyStateType.serverError:
        return 'Something went wrong on our end. Please try again later.';
      case EmptyStateType.noData:
        return 'No data available at the moment';
      case EmptyStateType.custom:
        return 'Nothing to show here';
    }
  }
}

// Animated empty state with subtle animations
class AnimatedEmptyState extends StatefulWidget {
  final EmptyStateWidget child;
  final Duration animationDuration;
  final bool enableBounce;

  const AnimatedEmptyState({
    super.key,
    required this.child,
    this.animationDuration = const Duration(milliseconds: 800),
    this.enableBounce = true,
  });

  @override
  State<AnimatedEmptyState> createState() => _AnimatedEmptyStateState();
}

class _AnimatedEmptyStateState extends State<AnimatedEmptyState>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
          ),
        );

    // Start animation when widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
          ),
        );
      },
    );
  }
}

// Compact empty state for smaller spaces
class CompactEmptyState extends StatelessWidget {
  final String message;
  final IconData? icon;
  final VoidCallback? onRetry;
  final bool showRetry;

  const CompactEmptyState({
    super.key,
    required this.message,
    this.icon,
    this.onRetry,
    this.showRetry = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 32, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
          ],
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (showRetry && onRetry != null) ...[
            const SizedBox(height: 16),
            ShadButton.outline(
              onPressed: onRetry,
              size: ShadButtonSize.sm,
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}

// Empty state with custom illustration
class IllustratedEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final String illustrationPath;
  final Widget? action;
  final double? illustrationWidth;
  final double? illustrationHeight;

  const IllustratedEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    required this.illustrationPath,
    this.action,
    this.illustrationWidth,
    this.illustrationHeight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration
          Image.asset(
            illustrationPath,
            width: illustrationWidth ?? 200,
            height: illustrationHeight ?? 200,
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Subtitle
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          if (action != null) ...[const SizedBox(height: 32), action!],
        ],
      ),
    );
  }
}
