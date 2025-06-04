import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final Widget? leading;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double elevation;
  final bool centerTitle;
  final bool automaticallyImplyLeading;
  final VoidCallback? onLeadingPressed;
  final double? leadingWidth;
  final double toolbarHeight;
  final SystemUiOverlayStyle? systemOverlayStyle;
  final bool showDivider;
  final Widget? flexibleSpace;

  const CustomAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.leading,
    this.actions,
    this.bottom,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 0,
    this.centerTitle = false,
    this.automaticallyImplyLeading = true,
    this.onLeadingPressed,
    this.leadingWidth,
    this.toolbarHeight = kToolbarHeight,
    this.systemOverlayStyle,
    this.showDivider = true,
    this.flexibleSpace,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(toolbarHeight + (bottom?.preferredSize.height ?? 0.0));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      title: titleWidget ?? (title != null ? _buildTitle(context) : null),
      leading: _buildLeading(context),
      actions: _buildActions(context),
      bottom: _buildBottom(),
      backgroundColor: backgroundColor ?? theme.scaffoldBackgroundColor,
      foregroundColor: foregroundColor ?? theme.colorScheme.onSurface,
      elevation: elevation,
      centerTitle: centerTitle,
      automaticallyImplyLeading: automaticallyImplyLeading && leading == null,
      leadingWidth: leadingWidth,
      toolbarHeight: toolbarHeight,
      systemOverlayStyle: systemOverlayStyle ?? _getSystemOverlayStyle(context),
      flexibleSpace: flexibleSpace,
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Text(
      title!,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: foregroundColor ?? Theme.of(context).colorScheme.onSurface,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget? _buildLeading(BuildContext context) {
    if (leading != null) return leading;

    if (onLeadingPressed != null) {
      return ShadButton.ghost(
        onPressed: onLeadingPressed,
        child: Icon(
          Icons.arrow_back,
          color: foregroundColor ?? Theme.of(context).colorScheme.onSurface,
        ),
      );
    }

    return null;
  }

  List<Widget>? _buildActions(BuildContext context) {
    if (actions == null || actions!.isEmpty) return null;

    return actions!.map((action) {
      if (action is IconButton || action is ShadButton) {
        return action;
      }
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: action,
      );
    }).toList();
  }

  PreferredSizeWidget? _buildBottom() {
    if (bottom != null) return bottom;

    if (showDivider) {
      return PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: Colors.grey[200]),
      );
    }

    return null;
  }

  SystemUiOverlayStyle _getSystemOverlayStyle(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;
  }
}

// Search app bar variant
class CustomSearchAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String? hintText;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onSearchSubmitted;
  final VoidCallback? onClearPressed;
  final VoidCallback? onBackPressed;
  final Widget? leading;
  final List<Widget>? actions;
  final bool autofocus;
  final TextEditingController? controller;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const CustomSearchAppBar({
    super.key,
    this.hintText = 'Search...',
    this.onSearchChanged,
    this.onSearchSubmitted,
    this.onClearPressed,
    this.onBackPressed,
    this.leading,
    this.actions,
    this.autofocus = true,
    this.controller,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<CustomSearchAppBar> createState() => _CustomSearchAppBarState();
}

class _CustomSearchAppBarState extends State<CustomSearchAppBar> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = FocusNode();

    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }

    _controller.addListener(() {
      widget.onSearchChanged?.call(_controller.text);
    });
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor:
          widget.backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      foregroundColor:
          widget.foregroundColor ?? Theme.of(context).colorScheme.onSurface,
      elevation: 0,
      leading:
          widget.leading ??
          ShadButton.ghost(
            onPressed:
                widget.onBackPressed ?? () => Navigator.of(context).pop(),
            child: const Icon(Icons.arrow_back),
          ),
      title: TextField(
        controller: _controller,
        focusNode: _focusNode,
        decoration: InputDecoration(
          hintText: widget.hintText,
          border: InputBorder.none,
          hintStyle: TextStyle(
            color:
                (widget.foregroundColor ??
                        Theme.of(context).colorScheme.onSurface)
                    .withOpacity(0.5),
          ),
        ),
        style: TextStyle(
          color:
              widget.foregroundColor ?? Theme.of(context).colorScheme.onSurface,
          fontSize: 16,
        ),
        onSubmitted: (_) => widget.onSearchSubmitted?.call(),
      ),
      actions: [
        if (_controller.text.isNotEmpty)
          ShadButton.ghost(
            onPressed: () {
              _controller.clear();
              widget.onClearPressed?.call();
            },
            child: const Icon(Icons.clear),
          ),
        ...?widget.actions,
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: Colors.grey[200]),
      ),
    );
  }
}

// Chat app bar with typing indicator
class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final Widget? avatar;
  final VoidCallback? onTitleTap;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final bool showOnlineStatus;
  final bool isOnline;
  final bool isTyping;
  final String? typingText;

  const ChatAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.avatar,
    this.onTitleTap,
    this.onBackPressed,
    this.actions,
    this.showOnlineStatus = false,
    this.isOnline = false,
    this.isTyping = false,
    this.typingText,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      leading: ShadButton.ghost(
        onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
        child: const Icon(Icons.arrow_back),
      ),
      title: GestureDetector(
        onTap: onTitleTap,
        child: Row(
          children: [
            if (avatar != null) ...[
              Stack(
                children: [
                  avatar!,
                  if (showOnlineStatus && isOnline)
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
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (isTyping && typingText != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      typingText!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).primaryColor,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ] else if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      actions: actions,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: Colors.grey[200]),
      ),
    );
  }
}

// Sliver app bar variant
class CustomSliverAppBar extends StatelessWidget {
  final String? title;
  final Widget? titleWidget;
  final Widget? leading;
  final List<Widget>? actions;
  final Widget? flexibleSpace;
  final double expandedHeight;
  final bool pinned;
  final bool floating;
  final bool snap;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool automaticallyImplyLeading;

  const CustomSliverAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.leading,
    this.actions,
    this.flexibleSpace,
    this.expandedHeight = kToolbarHeight + 100,
    this.pinned = true,
    this.floating = false,
    this.snap = false,
    this.backgroundColor,
    this.foregroundColor,
    this.automaticallyImplyLeading = true,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      title: titleWidget ?? (title != null ? Text(title!) : null),
      leading: leading,
      actions: actions,
      flexibleSpace: flexibleSpace,
      expandedHeight: expandedHeight,
      pinned: pinned,
      floating: floating,
      snap: snap,
      backgroundColor:
          backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      foregroundColor:
          foregroundColor ?? Theme.of(context).colorScheme.onSurface,
      automaticallyImplyLeading: automaticallyImplyLeading,
      elevation: 0,
    );
  }
}

// Tab app bar variant
class CustomTabAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget> tabs;
  final TabController? controller;
  final Widget? leading;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? indicatorColor;
  final bool isScrollable;

  const CustomTabAppBar({
    super.key,
    this.title,
    this.titleWidget,
    required this.tabs,
    this.controller,
    this.leading,
    this.actions,
    this.backgroundColor,
    this.foregroundColor,
    this.indicatorColor,
    this.isScrollable = false,
  });

  @override
  Size get preferredSize =>
      const Size.fromHeight(kToolbarHeight + kTextTabBarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: titleWidget ?? (title != null ? Text(title!) : null),
      leading: leading,
      actions: actions,
      backgroundColor:
          backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      foregroundColor:
          foregroundColor ?? Theme.of(context).colorScheme.onSurface,
      elevation: 0,
      bottom: TabBar(
        controller: controller,
        tabs: tabs,
        isScrollable: isScrollable,
        indicatorColor: indicatorColor ?? Theme.of(context).primaryColor,
        labelColor: foregroundColor ?? Theme.of(context).colorScheme.onSurface,
        unselectedLabelColor:
            (foregroundColor ?? Theme.of(context).colorScheme.onSurface)
                .withOpacity(0.6),
      ),
    );
  }
}
