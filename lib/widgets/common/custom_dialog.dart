import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class CustomDialog extends StatelessWidget {
  final String? title;
  final Widget? titleWidget;
  final String? content;
  final Widget? contentWidget;
  final List<Widget>? actions;
  final bool showCloseButton;
  final VoidCallback? onClose;
  final double? width;
  final double? height;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final double borderRadius;
  final bool barrierDismissible;

  const CustomDialog({
    super.key,
    this.title,
    this.titleWidget,
    this.content,
    this.contentWidget,
    this.actions,
    this.showCloseButton = true,
    this.onClose,
    this.width,
    this.height,
    this.padding,
    this.backgroundColor,
    this.borderRadius = 12,
    this.barrierDismissible = true,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        width: width ?? 400,
        height: height,
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            if (title != null || titleWidget != null || showCloseButton)
              _buildHeader(context),

            // Content
            Flexible(
              child: Padding(
                padding: padding ?? const EdgeInsets.all(24),
                child: _buildContent(),
              ),
            ),

            // Actions
            if (actions != null && actions!.isNotEmpty) _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Row(
        children: [
          Expanded(
            child:
                titleWidget ??
                (title != null
                    ? Text(
                        title!,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : const SizedBox.shrink()),
          ),
          if (showCloseButton)
            ShadButton.ghost(
              onPressed: onClose ?? () => Navigator.of(context).pop(),
              size: ShadButtonSize.sm,
              child: const Icon(Icons.close, size: 20),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (contentWidget != null) return contentWidget!;
    if (content != null) {
      return Text(
        content!,
        style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          for (int i = 0; i < actions!.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            actions![i],
          ],
        ],
      ),
    );
  }

  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    Widget? titleWidget,
    String? content,
    Widget? contentWidget,
    List<Widget>? actions,
    bool showCloseButton = true,
    VoidCallback? onClose,
    double? width,
    double? height,
    EdgeInsets? padding,
    Color? backgroundColor,
    double borderRadius = 12,
    bool barrierDismissible = true,
    bool useRootNavigator = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      useRootNavigator: useRootNavigator,
      builder: (context) => CustomDialog(
        title: title,
        titleWidget: titleWidget,
        content: content,
        contentWidget: contentWidget,
        actions: actions,
        showCloseButton: showCloseButton,
        onClose: onClose,
        width: width,
        height: height,
        padding: padding,
        backgroundColor: backgroundColor,
        borderRadius: borderRadius,
        barrierDismissible: barrierDismissible,
      ),
    );
  }
}

// Alert dialog variant
class AlertDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmText;
  final String? cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool isDestructive;
  final Widget? icon;

  const AlertDialog({
    super.key,
    required this.title,
    required this.content,
    this.confirmText = 'OK',
    this.cancelText,
    this.onConfirm,
    this.onCancel,
    this.isDestructive = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return CustomDialog(
      title: title,
      contentWidget: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[icon!, const SizedBox(height: 16)],
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        if (cancelText != null)
          ShadButton.outline(
            onPressed: () {
              Navigator.of(context).pop();
              onCancel?.call();
            },
            child: Text(cancelText!),
          ),
        ShadButton.raw(
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm?.call();
          },
          variant: isDestructive
              ? ShadButtonVariant.destructive
              : ShadButtonVariant.primary,
          child: Text(confirmText),
        ),
      ],
      showCloseButton: false,
    );
  }

  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String content,
    String confirmText = 'OK',
    String? cancelText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool isDestructive = false,
    Widget? icon,
  }) {
    return CustomDialog.show<bool>(
      context: context,
      contentWidget: AlertDialog(
        title: title,
        content: content,
        confirmText: confirmText,
        cancelText: cancelText,
        onConfirm: onConfirm,
        onCancel: onCancel,
        isDestructive: isDestructive,
        icon: icon,
      ),
      showCloseButton: false,
    );
  }
}

// Confirmation dialog
class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String? content;
  final String confirmText;
  final String cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool isDestructive;
  final Widget? icon;

  const ConfirmationDialog({
    super.key,
    required this.title,
    this.content,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    this.onConfirm,
    this.onCancel,
    this.isDestructive = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return CustomDialog(
      contentWidget: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[icon!, const SizedBox(height: 16)],
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          if (content != null) ...[
            const SizedBox(height: 12),
            Text(
              content!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
      actions: [
        ShadButton.outline(
          onPressed: () {
            Navigator.of(context).pop(false);
            onCancel?.call();
          },
          child: Text(cancelText),
        ),
        ShadButton.raw(
          onPressed: () {
            Navigator.of(context).pop(true);
            onConfirm?.call();
          },
          variant: isDestructive
              ? ShadButtonVariant.destructive
              : ShadButtonVariant.primary,
          child: Text(confirmText),
        ),
      ],
      showCloseButton: false,
    );
  }

  static Future<bool?> show({
    required BuildContext context,
    required String title,
    String? content,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool isDestructive = false,
    Widget? icon,
  }) {
    return CustomDialog.show<bool>(
      context: context,
      contentWidget: ConfirmationDialog(
        title: title,
        content: content,
        confirmText: confirmText,
        cancelText: cancelText,
        onConfirm: onConfirm,
        onCancel: onCancel,
        isDestructive: isDestructive,
        icon: icon,
      ),
      showCloseButton: false,
    );
  }
}

// Input dialog
class InputDialog extends StatefulWidget {
  final String title;
  final String? content;
  final String? hintText;
  final String? initialValue;
  final String confirmText;
  final String cancelText;
  final ValueChanged<String>? onConfirm;
  final VoidCallback? onCancel;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final int? maxLines;
  final int? maxLength;

  const InputDialog({
    super.key,
    required this.title,
    this.content,
    this.hintText,
    this.initialValue,
    this.confirmText = 'OK',
    this.cancelText = 'Cancel',
    this.onConfirm,
    this.onCancel,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.maxLines = 1,
    this.maxLength,
  });

  @override
  State<InputDialog> createState() => _InputDialogState();
}

class _InputDialogState extends State<InputDialog> {
  late TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _controller.addListener(_validateInput);
    _validateInput();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _validateInput() {
    setState(() {
      _isValid =
          _controller.text.isNotEmpty &&
          (widget.validator?.call(_controller.text) == null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomDialog(
      title: widget.title,
      contentWidget: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.content != null) ...[
              Text(
                widget.content!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: widget.hintText,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              keyboardType: widget.keyboardType,
              obscureText: widget.obscureText,
              maxLines: widget.maxLines,
              maxLength: widget.maxLength,
              validator: widget.validator,
              autofocus: true,
            ),
          ],
        ),
      ),
      actions: [
        ShadButton.outline(
          onPressed: () {
            Navigator.of(context).pop();
            widget.onCancel?.call();
          },
          child: Text(widget.cancelText),
        ),
        ShadButton(
          onPressed: _isValid
              ? () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.of(context).pop(_controller.text);
                    widget.onConfirm?.call(_controller.text);
                  }
                }
              : null,
          child: Text(widget.confirmText),
        ),
      ],
      showCloseButton: false,
    );
  }

  static Future<String?> show({
    required BuildContext context,
    required String title,
    String? content,
    String? hintText,
    String? initialValue,
    String confirmText = 'OK',
    String cancelText = 'Cancel',
    ValueChanged<String>? onConfirm,
    VoidCallback? onCancel,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
    int? maxLines = 1,
    int? maxLength,
  }) {
    return CustomDialog.show<String>(
      context: context,
      contentWidget: InputDialog(
        title: title,
        content: content,
        hintText: hintText,
        initialValue: initialValue,
        confirmText: confirmText,
        cancelText: cancelText,
        onConfirm: onConfirm,
        onCancel: onCancel,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        maxLines: maxLines,
        maxLength: maxLength,
      ),
      showCloseButton: false,
    );
  }
}

// Loading dialog
class LoadingDialog extends StatelessWidget {
  final String? message;
  final bool canCancel;
  final VoidCallback? onCancel;

  const LoadingDialog({
    super.key,
    this.message,
    this.canCancel = false,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return CustomDialog(
      contentWidget: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
      actions: canCancel
          ? [
              ShadButton.outline(
                onPressed: () {
                  Navigator.of(context).pop();
                  onCancel?.call();
                },
                child: const Text('Cancel'),
              ),
            ]
          : null,
      showCloseButton: false,
      barrierDismissible: canCancel,
    );
  }

  static Future<T?> show<T>({
    required BuildContext context,
    String? message,
    bool canCancel = false,
    VoidCallback? onCancel,
  }) {
    return CustomDialog.show<T>(
      context: context,
      contentWidget: LoadingDialog(
        message: message,
        canCancel: canCancel,
        onCancel: onCancel,
      ),
      showCloseButton: false,
      barrierDismissible: canCancel,
    );
  }
}

// Selection dialog
class SelectionDialog<T> extends StatefulWidget {
  final String title;
  final List<SelectionDialogItem<T>> items;
  final T? selectedValue;
  final ValueChanged<T>? onChanged;
  final bool allowMultiple;
  final List<T>? selectedValues;
  final ValueChanged<List<T>>? onMultipleChanged;
  final String confirmText;
  final String cancelText;

  const SelectionDialog({
    super.key,
    required this.title,
    required this.items,
    this.selectedValue,
    this.onChanged,
    this.allowMultiple = false,
    this.selectedValues,
    this.onMultipleChanged,
    this.confirmText = 'OK',
    this.cancelText = 'Cancel',
  });

  @override
  State<SelectionDialog<T>> createState() => _SelectionDialogState<T>();
}

class _SelectionDialogState<T> extends State<SelectionDialog<T>> {
  late T? _selectedValue;
  late List<T> _selectedValues;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.selectedValue;
    _selectedValues = List.from(widget.selectedValues ?? []);
  }

  @override
  Widget build(BuildContext context) {
    return CustomDialog(
      title: widget.title,
      height: 400,
      contentWidget: ListView.builder(
        shrinkWrap: true,
        itemCount: widget.items.length,
        itemBuilder: (context, index) {
          final item = widget.items[index];

          if (widget.allowMultiple) {
            return CheckboxListTile(
              title: Text(item.title),
              subtitle: item.subtitle != null ? Text(item.subtitle!) : null,
              value: _selectedValues.contains(item.value),
              onChanged: (bool? selected) {
                setState(() {
                  if (selected == true) {
                    _selectedValues.add(item.value);
                  } else {
                    _selectedValues.remove(item.value);
                  }
                });
              },
            );
          } else {
            return RadioListTile<T>(
              title: Text(item.title),
              subtitle: item.subtitle != null ? Text(item.subtitle!) : null,
              value: item.value,
              groupValue: _selectedValue,
              onChanged: (T? value) {
                setState(() {
                  _selectedValue = value;
                });
              },
            );
          }
        },
      ),
      actions: [
        ShadButton.outline(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.cancelText),
        ),
        ShadButton(
          onPressed: () {
            if (widget.allowMultiple) {
              Navigator.of(context).pop(_selectedValues);
              widget.onMultipleChanged?.call(_selectedValues);
            } else {
              Navigator.of(context).pop(_selectedValue);
              if (_selectedValue != null) {
                widget.onChanged?.call(_selectedValue!);
              }
            }
          },
          child: Text(widget.confirmText),
        ),
      ],
      showCloseButton: false,
    );
  }

  static Future<T?> showSingle<T>({
    required BuildContext context,
    required String title,
    required List<SelectionDialogItem<T>> items,
    T? selectedValue,
    ValueChanged<T>? onChanged,
    String confirmText = 'OK',
    String cancelText = 'Cancel',
  }) {
    return CustomDialog.show<T>(
      context: context,
      contentWidget: SelectionDialog<T>(
        title: title,
        items: items,
        selectedValue: selectedValue,
        onChanged: onChanged,
        allowMultiple: false,
        confirmText: confirmText,
        cancelText: cancelText,
      ),
    );
  }

  static Future<List<T>?> showMultiple<T>({
    required BuildContext context,
    required String title,
    required List<SelectionDialogItem<T>> items,
    List<T>? selectedValues,
    ValueChanged<List<T>>? onMultipleChanged,
    String confirmText = 'OK',
    String cancelText = 'Cancel',
  }) {
    return CustomDialog.show<List<T>>(
      context: context,
      contentWidget: SelectionDialog<T>(
        title: title,
        items: items,
        allowMultiple: true,
        selectedValues: selectedValues,
        onMultipleChanged: onMultipleChanged,
        confirmText: confirmText,
        cancelText: cancelText,
      ),
    );
  }
}

class SelectionDialogItem<T> {
  final T value;
  final String title;
  final String? subtitle;

  SelectionDialogItem({
    required this.value,
    required this.title,
    this.subtitle,
  });
}

// Progress dialog
class ProgressDialog extends StatelessWidget {
  final String? title;
  final String? message;
  final double? progress;
  final bool isIndeterminate;
  final bool canCancel;
  final VoidCallback? onCancel;

  const ProgressDialog({
    super.key,
    this.title,
    this.message,
    this.progress,
    this.isIndeterminate = false,
    this.canCancel = false,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return CustomDialog(
      title: title,
      contentWidget: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isIndeterminate)
            const LinearProgressIndicator()
          else
            LinearProgressIndicator(value: progress),

          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
          ],

          if (progress != null && !isIndeterminate) ...[
            const SizedBox(height: 8),
            Text(
              '${(progress! * 100).toInt()}%',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ],
      ),
      actions: canCancel
          ? [
              ShadButton.outline(
                onPressed: () {
                  Navigator.of(context).pop();
                  onCancel?.call();
                },
                child: const Text('Cancel'),
              ),
            ]
          : null,
      showCloseButton: false,
      barrierDismissible: canCancel,
    );
  }

  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    String? message,
    double? progress,
    bool isIndeterminate = false,
    bool canCancel = false,
    VoidCallback? onCancel,
  }) {
    return CustomDialog.show<T>(
      context: context,
      contentWidget: ProgressDialog(
        title: title,
        message: message,
        progress: progress,
        isIndeterminate: isIndeterminate,
        canCancel: canCancel,
        onCancel: onCancel,
      ),
      showCloseButton: false,
      barrierDismissible: canCancel,
    );
  }
}
