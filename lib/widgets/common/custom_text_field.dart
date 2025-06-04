import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

enum TextFieldVariant { outlined, filled, underlined }

enum TextFieldSize { small, medium, large }

class CustomTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final String? helperText;
  final String? errorText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final Widget? prefix;
  final Widget? suffix;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final bool autocorrect;
  final bool enableSuggestions;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final VoidCallback? onEditingComplete;
  final FocusNode? focusNode;
  final TextFieldVariant variant;
  final TextFieldSize size;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final Color? errorBorderColor;
  final double? borderRadius;
  final EdgeInsets? contentPadding;
  final TextStyle? textStyle;
  final TextStyle? hintStyle;
  final TextStyle? labelStyle;
  final bool showCounter;
  final String? Function(String?)? validator;
  final AutovalidateMode? autovalidateMode;
  final bool expands;
  final TextAlignVertical? textAlignVertical;
  final TextAlign textAlign;
  final bool isDense;

  const CustomTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.prefix,
    this.suffix,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.onEditingComplete,
    this.focusNode,
    this.variant = TextFieldVariant.outlined,
    this.size = TextFieldSize.medium,
    this.backgroundColor,
    this.borderColor,
    this.focusedBorderColor,
    this.errorBorderColor,
    this.borderRadius,
    this.contentPadding,
    this.textStyle,
    this.hintStyle,
    this.labelStyle,
    this.showCounter = false,
    this.validator,
    this.autovalidateMode,
    this.expands = false,
    this.textAlignVertical,
    this.textAlign = TextAlign.start,
    this.isDense = false,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
    _errorText = widget.errorText;
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_onFocusChange);
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(CustomTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.errorText != oldWidget.errorText) {
      setState(() {
        _errorText = widget.errorText;
      });
    }
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.labelText != null) _buildLabel(),
        _buildTextField(),
        if (widget.helperText != null ||
            _errorText != null ||
            widget.showCounter)
          _buildHelperRow(),
      ],
    );
  }

  Widget _buildLabel() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        widget.labelText!,
        style:
            widget.labelStyle ??
            Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: _errorText != null
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.onSurface,
            ),
      ),
    );
  }

  Widget _buildTextField() {
    return TextFormField(
      controller: widget.controller,
      focusNode: _focusNode,
      obscureText: widget.obscureText,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      autofocus: widget.autofocus,
      autocorrect: widget.autocorrect,
      enableSuggestions: widget.enableSuggestions,
      maxLines: widget.expands ? null : widget.maxLines,
      minLines: widget.minLines,
      maxLength: widget.maxLength,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      textCapitalization: widget.textCapitalization,
      inputFormatters: widget.inputFormatters,
      onChanged: (value) {
        widget.onChanged?.call(value);
        if (widget.validator != null) {
          setState(() {
            _errorText = widget.validator!(value);
          });
        }
      },
      onFieldSubmitted: widget.onSubmitted,
      onTap: widget.onTap,
      onEditingComplete: widget.onEditingComplete,
      validator: widget.validator,
      autovalidateMode: widget.autovalidateMode,
      expands: widget.expands,
      textAlignVertical: widget.textAlignVertical,
      textAlign: widget.textAlign,
      style: widget.textStyle ?? _getTextStyle(),
      decoration: _buildInputDecoration(),
    );
  }

  Widget _buildHelperRow() {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Expanded(
            child: _errorText != null
                ? Text(
                    _errorText!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  )
                : widget.helperText != null
                ? Text(
                    widget.helperText!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          if (widget.showCounter && widget.maxLength != null)
            Text(
              '${widget.controller?.text.length ?? 0}/${widget.maxLength}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration() {
    final theme = Theme.of(context);
    final hasError = _errorText != null;

    return InputDecoration(
      hintText: widget.hintText,
      hintStyle: widget.hintStyle ?? _getHintStyle(),
      prefixIcon: widget.prefixIcon,
      suffixIcon: widget.suffixIcon,
      prefix: widget.prefix,
      suffix: widget.suffix,
      filled: widget.variant == TextFieldVariant.filled,
      fillColor: widget.backgroundColor ?? _getBackgroundColor(),
      contentPadding: widget.contentPadding ?? _getContentPadding(),
      isDense: widget.isDense,
      border: _getBorder(),
      enabledBorder: _getBorder(),
      focusedBorder: _getFocusedBorder(),
      errorBorder: _getErrorBorder(),
      focusedErrorBorder: _getErrorBorder(),
      counterText: '',
    );
  }

  TextStyle _getTextStyle() {
    switch (widget.size) {
      case TextFieldSize.small:
        return const TextStyle(fontSize: 14);
      case TextFieldSize.medium:
        return const TextStyle(fontSize: 16);
      case TextFieldSize.large:
        return const TextStyle(fontSize: 18);
    }
  }

  TextStyle _getHintStyle() {
    return _getTextStyle().copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }

  Color _getBackgroundColor() {
    if (!widget.enabled) {
      return Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3);
    }
    return widget.variant == TextFieldVariant.filled
        ? Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.1)
        : Colors.transparent;
  }

  EdgeInsets _getContentPadding() {
    switch (widget.size) {
      case TextFieldSize.small:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
      case TextFieldSize.medium:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
      case TextFieldSize.large:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 16);
    }
  }

  double _getBorderRadius() {
    return widget.borderRadius ?? 8.0;
  }

  InputBorder _getBorder() {
    final hasError = _errorText != null;
    final borderColor = hasError
        ? (widget.errorBorderColor ?? Theme.of(context).colorScheme.error)
        : (widget.borderColor ?? Theme.of(context).colorScheme.outline);

    switch (widget.variant) {
      case TextFieldVariant.outlined:
        return OutlineInputBorder(
          borderRadius: BorderRadius.circular(_getBorderRadius()),
          borderSide: BorderSide(color: borderColor),
        );
      case TextFieldVariant.filled:
        return OutlineInputBorder(
          borderRadius: BorderRadius.circular(_getBorderRadius()),
          borderSide: BorderSide.none,
        );
      case TextFieldVariant.underlined:
        return UnderlineInputBorder(borderSide: BorderSide(color: borderColor));
    }
  }

  InputBorder _getFocusedBorder() {
    final focusedColor =
        widget.focusedBorderColor ?? Theme.of(context).colorScheme.primary;

    switch (widget.variant) {
      case TextFieldVariant.outlined:
        return OutlineInputBorder(
          borderRadius: BorderRadius.circular(_getBorderRadius()),
          borderSide: BorderSide(color: focusedColor, width: 2),
        );
      case TextFieldVariant.filled:
        return OutlineInputBorder(
          borderRadius: BorderRadius.circular(_getBorderRadius()),
          borderSide: BorderSide(color: focusedColor, width: 2),
        );
      case TextFieldVariant.underlined:
        return UnderlineInputBorder(
          borderSide: BorderSide(color: focusedColor, width: 2),
        );
    }
  }

  InputBorder _getErrorBorder() {
    final errorColor =
        widget.errorBorderColor ?? Theme.of(context).colorScheme.error;

    switch (widget.variant) {
      case TextFieldVariant.outlined:
        return OutlineInputBorder(
          borderRadius: BorderRadius.circular(_getBorderRadius()),
          borderSide: BorderSide(color: errorColor),
        );
      case TextFieldVariant.filled:
        return OutlineInputBorder(
          borderRadius: BorderRadius.circular(_getBorderRadius()),
          borderSide: BorderSide(color: errorColor),
        );
      case TextFieldVariant.underlined:
        return UnderlineInputBorder(borderSide: BorderSide(color: errorColor));
    }
  }
}

// Search text field variant
class SearchTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final bool autofocus;
  final bool enabled;
  final Widget? leadingIcon;
  final List<Widget>? actions;

  const SearchTextField({
    super.key,
    this.controller,
    this.hintText = 'Search...',
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.autofocus = false,
    this.enabled = true,
    this.leadingIcon,
    this.actions,
  });

  @override
  State<SearchTextField> createState() => _SearchTextFieldState();
}

class _SearchTextFieldState extends State<SearchTextField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = FocusNode();
    _controller.addListener(() {
      setState(() {});
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
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: widget.autofocus,
              enabled: widget.enabled,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              decoration: InputDecoration(
                hintText: widget.hintText,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                prefixIcon:
                    widget.leadingIcon ??
                    Icon(
                      Icons.search,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          widget.onClear?.call();
                          widget.onChanged?.call('');
                        },
                      )
                    : null,
              ),
            ),
          ),
          if (widget.actions != null) ...widget.actions!,
        ],
      ),
    );
  }
}

// Message input field specifically for chat
class MessageInputField extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onAttachmentTap;
  final VoidCallback? onCameraTap;
  final VoidCallback? onMicTap;
  final bool isRecording;
  final bool canSend;
  final String chatId;

  const MessageInputField({
    super.key,
    this.controller,
    this.hintText = 'Type a message...',
    this.onChanged,
    this.onSubmitted,
    this.onAttachmentTap,
    this.onCameraTap,
    this.onMicTap,
    this.isRecording = false,
    this.canSend = false,
    required this.chatId,
  });

  @override
  State<MessageInputField> createState() => _MessageInputFieldState();
}

class _MessageInputFieldState extends State<MessageInputField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isEmpty = true;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = FocusNode();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final isEmpty = _controller.text.trim().isEmpty;
    if (_isEmpty != isEmpty) {
      setState(() {
        _isEmpty = isEmpty;
      });
    }
    widget.onChanged?.call(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Attachment button
            IconButton(
              onPressed: widget.onAttachmentTap,
              icon: const Icon(Icons.attach_file),
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),

            // Text input
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceVariant.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  maxLines: 5,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: _isEmpty ? null : widget.onSubmitted,
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    suffixIcon: widget.onCameraTap != null
                        ? IconButton(
                            onPressed: widget.onCameraTap,
                            icon: const Icon(Icons.camera_alt),
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          )
                        : null,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Send/Mic button
            widget.isRecording
                ? IconButton(
                    onPressed: widget.onMicTap,
                    icon: const Icon(Icons.stop),
                    color: Colors.red,
                  )
                : _isEmpty
                ? IconButton(
                    onPressed: widget.onMicTap,
                    icon: const Icon(Icons.mic),
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  )
                : IconButton(
                    onPressed: widget.canSend
                        ? () => widget.onSubmitted?.call(_controller.text)
                        : null,
                    icon: const Icon(Icons.send),
                    color: widget.canSend
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant.withOpacity(0.5),
                  ),
          ],
        ),
      ),
    );
  }
}

// OTP input field
class OTPInputField extends StatefulWidget {
  final int length;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;
  final bool autofocus;
  final bool enabled;

  const OTPInputField({
    super.key,
    this.length = 6,
    this.onChanged,
    this.onCompleted,
    this.autofocus = true,
    this.enabled = true,
  });

  @override
  State<OTPInputField> createState() => _OTPInputFieldState();
}

class _OTPInputFieldState extends State<OTPInputField> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.length,
      (index) => TextEditingController(),
    );
    _focusNodes = List.generate(widget.length, (index) => FocusNode());

    for (int i = 0; i < widget.length; i++) {
      _controllers[i].addListener(() => _onTextChanged(i));
    }

    if (widget.autofocus && widget.enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNodes[0].requestFocus();
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _onTextChanged(int index) {
    final text = _controllers[index].text;

    if (text.isNotEmpty) {
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    }

    final otp = _controllers.map((c) => c.text).join();
    widget.onChanged?.call(otp);

    if (otp.length == widget.length) {
      widget.onCompleted?.call(otp);
    }
  }

  void _onKeyPressed(int index, String value) {
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
        widget.length,
        (index) => Container(
          width: 48,
          height: 56,
          decoration: BoxDecoration(
            border: Border.all(
              color: _focusNodes[index].hasFocus
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline,
              width: _focusNodes[index].hasFocus ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            enabled: widget.enabled,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            decoration: const InputDecoration(
              border: InputBorder.none,
              counterText: '',
            ),
            onChanged: (value) {
              if (value.length > 1) {
                _controllers[index].text = value[value.length - 1];
              }
              _onKeyPressed(index, value);
            },
          ),
        ),
      ),
    );
  }
}
