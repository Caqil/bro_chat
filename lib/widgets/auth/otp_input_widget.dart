import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class OTPInputWidget extends StatefulWidget {
  final int length;
  final ValueChanged<String>? onCompleted;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onResendOTP;
  final bool enableResend;
  final int resendTimeoutSeconds;
  final String? errorText;
  final bool enabled;
  final String? phoneNumber;
  final bool autoSubmit;
  final TextInputType keyboardType;

  const OTPInputWidget({
    super.key,
    this.length = 6,
    this.onCompleted,
    this.onChanged,
    this.onResendOTP,
    this.enableResend = true,
    this.resendTimeoutSeconds = 60,
    this.errorText,
    this.enabled = true,
    this.phoneNumber,
    this.autoSubmit = true,
    this.keyboardType = TextInputType.number,
  });

  @override
  State<OTPInputWidget> createState() => _OTPInputWidgetState();
}

class _OTPInputWidgetState extends State<OTPInputWidget> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  Timer? _resendTimer;
  int _resendTimeRemaining = 0;
  bool _canResend = true;
  String _currentOTP = '';

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeResendTimer();
  }

  void _initializeControllers() {
    _controllers = List.generate(
      widget.length,
      (index) => TextEditingController(),
    );
    _focusNodes = List.generate(widget.length, (index) => FocusNode());

    // Add listeners to controllers
    for (int i = 0; i < widget.length; i++) {
      _controllers[i].addListener(() => _onTextChanged(i));
    }
  }

  void _initializeResendTimer() {
    if (widget.enableResend) {
      _startResendTimer();
    }
  }

  void _startResendTimer() {
    _canResend = false;
    _resendTimeRemaining = widget.resendTimeoutSeconds;

    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimeRemaining > 0) {
        setState(() {
          _resendTimeRemaining--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
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

    if (text.length == 1) {
      // Move to next field
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    } else if (text.isEmpty && index > 0) {
      // Move to previous field if current is empty
      _focusNodes[index - 1].requestFocus();
    } else if (text.length > 1) {
      // Handle paste or multiple characters
      _handlePaste(text, index);
    }

    _updateOTP();
  }

  void _handlePaste(String pastedText, int startIndex) {
    // Clean the pasted text (keep only digits if numeric keyboard)
    String cleanText = pastedText;
    if (widget.keyboardType == TextInputType.number) {
      cleanText = pastedText.replaceAll(RegExp(r'[^0-9]'), '');
    }

    // Fill the fields starting from the current index
    for (
      int i = 0;
      i < cleanText.length && (startIndex + i) < widget.length;
      i++
    ) {
      _controllers[startIndex + i].text = cleanText[i];
    }

    // Focus the last filled field or the next empty one
    int nextFocusIndex = (startIndex + cleanText.length).clamp(
      0,
      widget.length - 1,
    );
    _focusNodes[nextFocusIndex].requestFocus();

    _updateOTP();
  }

  void _updateOTP() {
    _currentOTP = _controllers.map((controller) => controller.text).join();

    widget.onChanged?.call(_currentOTP);

    if (_currentOTP.length == widget.length && widget.autoSubmit) {
      widget.onCompleted?.call(_currentOTP);
    }
  }

  void _onKeyEvent(KeyEvent event, int index) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.backspace) {
        if (_controllers[index].text.isEmpty && index > 0) {
          _focusNodes[index - 1].requestFocus();
          _controllers[index - 1].clear();
        }
      }
    }
  }

  void _resendOTP() {
    if (_canResend && widget.onResendOTP != null) {
      widget.onResendOTP!();
      _startResendTimer();

      // Clear current OTP
      for (final controller in _controllers) {
        controller.clear();
      }
      _focusNodes[0].requestFocus();

      // Show confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP sent successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void clearOTP() {
    for (final controller in _controllers) {
      controller.clear();
    }
    _currentOTP = '';
    _focusNodes[0].requestFocus();
  }

  String get otp => _currentOTP;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // OTP Description
        if (widget.phoneNumber != null) ...[
          Text(
            'Enter the verification code sent to',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            widget.phoneNumber!,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 24),
        ],

        // OTP Input Fields
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(widget.length, (index) {
            return SizedBox(
              width: 45,
              height: 55,
              child: Focus(
                onKeyEvent: (node, event) {
                  _onKeyEvent(event, index);
                  return KeyEventResult.ignored;
                },
                child: ShadInput(
                  controller: _controllers[index],
                  focusNode: _focusNodes[index],
                  enabled: widget.enabled,
                  keyboardType: widget.keyboardType,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLength: 1,
                  inputFormatters: widget.keyboardType == TextInputType.number
                      ? [FilteringTextInputFormatter.digitsOnly]
                      : null,
                  decoration: ShadDecoration(),
                  onChanged: (value) {
                    if (value.length > 1) {
                      _handlePaste(value, index);
                    }
                  },
                ),
              ),
            );
          }),
        ),

        // Error Text
        if (widget.errorText != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.errorText!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            ],
          ),
        ],

        // Resend Section
        if (widget.enableResend) ...[
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Didn't receive the code? ",
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              if (_canResend)
                ShadButton.link(
                  onPressed: _resendOTP,
                  child: const Text(
                    'Resend',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                )
              else
                Text(
                  'Resend in ${_resendTimeRemaining}s',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ],

        // Manual Submit Button (if auto-submit is disabled)
        if (!widget.autoSubmit) ...[
          const SizedBox(height: 24),
          ShadButton(
            onPressed: _currentOTP.length == widget.length
                ? () => widget.onCompleted?.call(_currentOTP)
                : null,
            child: const Text('Verify'),
          ),
        ],
      ],
    );
  }
}

// Alternative compact OTP input for smaller spaces
class CompactOTPInput extends StatefulWidget {
  final int length;
  final ValueChanged<String>? onCompleted;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final bool enabled;
  final bool autoSubmit;

  const CompactOTPInput({
    super.key,
    this.length = 6,
    this.onCompleted,
    this.onChanged,
    this.errorText,
    this.enabled = true,
    this.autoSubmit = true,
  });

  @override
  State<CompactOTPInput> createState() => _CompactOTPInputState();
}

class _CompactOTPInputState extends State<CompactOTPInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _controller.text;

    widget.onChanged?.call(text);

    if (text.length == widget.length && widget.autoSubmit) {
      widget.onCompleted?.call(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShadInput(
          controller: _controller,
          focusNode: _focusNode,
          enabled: widget.enabled,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          placeholder: Text('Enter ${widget.length}-digit code'),
          maxLength: widget.length,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(widget.length),
          ],
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 4,
          ),
        ),

        if (widget.errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.errorText!,
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        ],
      ],
    );
  }
}
