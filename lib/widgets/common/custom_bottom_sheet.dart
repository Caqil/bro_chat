import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class CustomBottomSheet extends StatelessWidget {
  final Widget? title;
  final String? titleText;
  final Widget? subtitle;
  final Widget child;
  final List<Widget>? actions;
  final bool showDragHandle;
  final bool showCloseButton;
  final VoidCallback? onClose;
  final Color? backgroundColor;
  final double? height;
  final double borderRadius;
  final EdgeInsets? padding;
  final bool isDismissible;
  final bool enableDrag;

  const CustomBottomSheet({
    super.key,
    this.title,
    this.titleText,
    this.subtitle,
    required this.child,
    this.actions,
    this.showDragHandle = true,
    this.showCloseButton = false,
    this.onClose,
    this.backgroundColor,
    this.height,
    this.borderRadius = 20,
    this.padding,
    this.isDismissible = true,
    this.enableDrag = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          if (showDragHandle) _buildDragHandle(),

          // Header
          if (title != null || titleText != null || showCloseButton)
            _buildHeader(context),

          // Content
          Flexible(
            child: Padding(
              padding: padding ?? const EdgeInsets.all(16),
              child: child,
            ),
          ),

          // Actions
          if (actions != null && actions!.isNotEmpty) _buildActions(),
        ],
      ),
    );
  }

  Widget _buildDragHandle() {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null)
                  title!
                else if (titleText != null)
                  Text(
                    titleText!,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  DefaultTextStyle(
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    child: subtitle!,
                  ),
                ],
              ],
            ),
          ),
          if (showCloseButton)
            ShadButton.ghost(
              onPressed: onClose ?? () => Navigator.of(context).pop(),
              size: ShadButtonSize.sm,
              child: const Icon(Icons.close),
            ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          for (int i = 0; i < actions!.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(child: actions![i]),
          ],
        ],
      ),
    );
  }

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    Widget? title,
    String? titleText,
    Widget? subtitle,
    List<Widget>? actions,
    bool showDragHandle = true,
    bool showCloseButton = false,
    VoidCallback? onClose,
    Color? backgroundColor,
    double? height,
    double borderRadius = 20,
    EdgeInsets? padding,
    bool isDismissible = true,
    bool enableDrag = true,
    bool isScrollControlled = false,
    bool useRootNavigator = false,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: isScrollControlled,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      useRootNavigator: useRootNavigator,
      builder: (context) => CustomBottomSheet(
        title: title,
        titleText: titleText,
        subtitle: subtitle,
        actions: actions,
        showDragHandle: showDragHandle,
        showCloseButton: showCloseButton,
        onClose: onClose,
        backgroundColor: backgroundColor,
        height: height,
        borderRadius: borderRadius,
        padding: padding,
        isDismissible: isDismissible,
        enableDrag: enableDrag,
        child: child,
      ),
    );
  }
}

// List bottom sheet for selection
class ListBottomSheet<T> extends StatelessWidget {
  final String? title;
  final List<ListBottomSheetItem<T>> items;
  final ValueChanged<T>? onItemSelected;
  final bool showSearchBar;
  final String? searchHint;
  final bool dismissOnSelect;

  const ListBottomSheet({
    super.key,
    this.title,
    required this.items,
    this.onItemSelected,
    this.showSearchBar = false,
    this.searchHint = 'Search...',
    this.dismissOnSelect = true,
  });

  @override
  Widget build(BuildContext context) {
    return CustomBottomSheet(
      titleText: title,
      height: MediaQuery.of(context).size.height * 0.6,
      child: _ListBottomSheetContent<T>(
        items: items,
        onItemSelected: onItemSelected,
        showSearchBar: showSearchBar,
        searchHint: searchHint,
        dismissOnSelect: dismissOnSelect,
      ),
    );
  }

  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    required List<ListBottomSheetItem<T>> items,
    ValueChanged<T>? onItemSelected,
    bool showSearchBar = false,
    String? searchHint = 'Search...',
    bool dismissOnSelect = true,
  }) {
    return CustomBottomSheet.show<T>(
      context: context,
      titleText: title,
      height: MediaQuery.of(context).size.height * 0.6,
      child: _ListBottomSheetContent<T>(
        items: items,
        onItemSelected: onItemSelected,
        showSearchBar: showSearchBar,
        searchHint: searchHint,
        dismissOnSelect: dismissOnSelect,
      ),
    );
  }
}

class _ListBottomSheetContent<T> extends StatefulWidget {
  final List<ListBottomSheetItem<T>> items;
  final ValueChanged<T>? onItemSelected;
  final bool showSearchBar;
  final String? searchHint;
  final bool dismissOnSelect;

  const _ListBottomSheetContent({
    required this.items,
    this.onItemSelected,
    this.showSearchBar = false,
    this.searchHint,
    this.dismissOnSelect = true,
  });

  @override
  State<_ListBottomSheetContent<T>> createState() =>
      _ListBottomSheetContentState<T>();
}

class _ListBottomSheetContentState<T>
    extends State<_ListBottomSheetContent<T>> {
  late List<ListBottomSheetItem<T>> _filteredItems;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
    _searchController.addListener(_filterItems);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterItems() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = widget.items.where((item) {
        return item.title.toLowerCase().contains(query) ||
            (item.subtitle?.toLowerCase().contains(query) ?? false);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.showSearchBar) ...[
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: widget.searchHint,
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Expanded(
          child: ListView.builder(
            itemCount: _filteredItems.length,
            itemBuilder: (context, index) {
              final item = _filteredItems[index];
              return _buildListItem(context, item);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildListItem(BuildContext context, ListBottomSheetItem<T> item) {
    return ListTile(
      leading: item.leading,
      title: Text(item.title),
      subtitle: item.subtitle != null ? Text(item.subtitle!) : null,
      trailing: item.trailing,
      onTap: () {
        widget.onItemSelected?.call(item.value);
        if (widget.dismissOnSelect) {
          Navigator.of(context).pop(item.value);
        }
      },
    );
  }
}

class ListBottomSheetItem<T> {
  final T value;
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;

  ListBottomSheetItem({
    required this.value,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
  });
}

// Action bottom sheet for quick actions
class ActionBottomSheet extends StatelessWidget {
  final String? title;
  final List<ActionBottomSheetItem> actions;
  final bool showCancel;
  final String cancelText;

  const ActionBottomSheet({
    super.key,
    this.title,
    required this.actions,
    this.showCancel = true,
    this.cancelText = 'Cancel',
  });

  @override
  Widget build(BuildContext context) {
    return CustomBottomSheet(
      titleText: title,
      showDragHandle: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final action in actions) _buildActionItem(context, action),
          if (showCancel) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 8,
              color: Colors.grey[100],
            ),
            _buildCancelItem(context),
          ],
        ],
      ),
    );
  }

  Widget _buildActionItem(BuildContext context, ActionBottomSheetItem action) {
    return ListTile(
      leading: action.icon != null
          ? Icon(action.icon, color: action.isDestructive ? Colors.red : null)
          : null,
      title: Text(
        action.title,
        style: TextStyle(
          color: action.isDestructive ? Colors.red : null,
          fontWeight: action.isDestructive ? FontWeight.w500 : null,
        ),
      ),
      subtitle: action.subtitle != null ? Text(action.subtitle!) : null,
      onTap: () {
        Navigator.of(context).pop();
        action.onTap?.call();
      },
    );
  }

  Widget _buildCancelItem(BuildContext context) {
    return ListTile(
      title: Text(
        cancelText,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      onTap: () => Navigator.of(context).pop(),
    );
  }

  static Future<void> show({
    required BuildContext context,
    String? title,
    required List<ActionBottomSheetItem> actions,
    bool showCancel = true,
    String cancelText = 'Cancel',
  }) {
    return CustomBottomSheet.show(
      context: context,
      child: ActionBottomSheet(
        title: title,
        actions: actions,
        showCancel: showCancel,
        cancelText: cancelText,
      ),
    );
  }
}

class ActionBottomSheetItem {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool isDestructive;

  ActionBottomSheetItem({
    required this.title,
    this.subtitle,
    this.icon,
    this.onTap,
    this.isDestructive = false,
  });
}

// Confirmation bottom sheet
class ConfirmationBottomSheet extends StatelessWidget {
  final String title;
  final String? description;
  final String confirmText;
  final String cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool isDestructive;
  final Widget? icon;

  const ConfirmationBottomSheet({
    super.key,
    required this.title,
    this.description,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    this.onConfirm,
    this.onCancel,
    this.isDestructive = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return CustomBottomSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[icon!, const SizedBox(height: 16)],
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          if (description != null) ...[
            const SizedBox(height: 8),
            Text(
              description!,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ShadButton.outline(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onCancel?.call();
                  },
                  child: Text(cancelText),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ShadButton.raw(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onConfirm?.call();
                  },
                  variant: isDestructive
                      ? ShadButtonVariant.destructive
                      : ShadButtonVariant.primary,
                  child: Text(confirmText),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Future<bool?> show({
    required BuildContext context,
    required String title,
    String? description,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool isDestructive = false,
    Widget? icon,
  }) {
    return CustomBottomSheet.show<bool>(
      context: context,
      child: ConfirmationBottomSheet(
        title: title,
        description: description,
        confirmText: confirmText,
        cancelText: cancelText,
        onConfirm: onConfirm,
        onCancel: onCancel,
        isDestructive: isDestructive,
        icon: icon,
      ),
    );
  }
}

// Form bottom sheet
class FormBottomSheet extends StatelessWidget {
  final String title;
  final Widget form;
  final String submitText;
  final String cancelText;
  final VoidCallback? onSubmit;
  final VoidCallback? onCancel;
  final bool isSubmitEnabled;

  const FormBottomSheet({
    super.key,
    required this.title,
    required this.form,
    this.submitText = 'Submit',
    this.cancelText = 'Cancel',
    this.onSubmit,
    this.onCancel,
    this.isSubmitEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return CustomBottomSheet(
      titleText: title,
      height: MediaQuery.of(context).size.height * 0.7,
      child: form,
      actions: [
        ShadButton.outline(
          onPressed: () {
            Navigator.of(context).pop();
            onCancel?.call();
          },
          child: Text(cancelText),
        ),
        ShadButton(
          onPressed: isSubmitEnabled ? onSubmit : null,
          child: Text(submitText),
        ),
      ],
    );
  }

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget form,
    String submitText = 'Submit',
    String cancelText = 'Cancel',
    VoidCallback? onSubmit,
    VoidCallback? onCancel,
    bool isSubmitEnabled = true,
  }) {
    return CustomBottomSheet.show<T>(
      context: context,
      child: FormBottomSheet(
        title: title,
        form: form,
        submitText: submitText,
        cancelText: cancelText,
        onSubmit: onSubmit,
        onCancel: onCancel,
        isSubmitEnabled: isSubmitEnabled,
      ),
    );
  }
}
