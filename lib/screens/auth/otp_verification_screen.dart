import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/auth/otp_request.dart';
import '../../providers/auth/auth_provider.dart';
import '../../widgets/auth/otp_input_widget.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/loading_widget.dart';

class OTPVerificationScreen extends ConsumerStatefulWidget {
  final String phoneNumber;
  final String countryCode;
  final String? purpose; // 'registration', 'login', 'password_reset'
  final VoidCallback? onVerificationSuccess;

  const OTPVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.countryCode,
    this.purpose,
    this.onVerificationSuccess,
  });

  @override
  ConsumerState<OTPVerificationScreen> createState() =>
      _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends ConsumerState<OTPVerificationScreen> {
  String _otpCode = '';
  bool _isLoading = false;
  bool _isResending = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    // Auto-focus OTP input after screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {}); // Trigger rebuild to show OTP input
    });
  }

  Future<void> _handleOTPVerification(String otp) async {
    if (otp.length != 6) return;

    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final otpRequest = OTPRequest(
        phoneNumber: widget.phoneNumber,
        countryCode: widget.countryCode,
        otp: otp,
        purpose: widget.purpose,
      );

      final success = await ref
          .read(authProvider.notifier)
          .verifyOTP(otpRequest);

      if (success && mounted) {
        if (widget.onVerificationSuccess != null) {
          widget.onVerificationSuccess!();
        } else {
          // Navigate based on purpose
          if (widget.purpose == 'registration') {
            Navigator.of(context).pushReplacementNamed('/profile-setup');
          } else {
            Navigator.of(context).pushReplacementNamed('/home');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorText = _getErrorMessage(e.toString());
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleResendOTP() async {
    if (_isResending) return;

    setState(() {
      _isResending = true;
      _errorText = null;
    });

    try {
      final resendRequest = ResendOTPRequest(
        phoneNumber: widget.phoneNumber,
        countryCode: widget.countryCode,
      );

      final success = await ref
          .read(authProvider.notifier)
          .resendOTP(resendRequest);

      if (success && mounted) {
        _showSuccessSnackBar('OTP sent successfully');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(_getErrorMessage(e.toString()));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  String _getErrorMessage(String error) {
    if (error.toLowerCase().contains('invalid')) {
      return 'Invalid OTP code. Please try again.';
    } else if (error.toLowerCase().contains('expired')) {
      return 'OTP code has expired. Please request a new one.';
    } else if (error.toLowerCase().contains('attempts')) {
      return 'Too many failed attempts. Please try again later.';
    }
    return 'Verification failed. Please try again.';
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _navigateBack() {
    Navigator.of(context).pop();
  }

  String get _fullPhoneNumber => '${widget.countryCode} ${widget.phoneNumber}';

  String get _maskedPhoneNumber {
    final phone = widget.phoneNumber;
    if (phone.length <= 4) return phone;

    final visible = phone.substring(phone.length - 4);
    final masked = '*' * (phone.length - 4);
    return '${widget.countryCode} $masked$visible';
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Verify Phone',
        centerTitle: true,
        showDivider: false,
        onLeadingPressed: _navigateBack,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),

              // Header Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.sms_outlined,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),

              const SizedBox(height: 32),

              // Title
              Text(
                'Enter verification code',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Subtitle
              Text(
                'We sent a 6-digit code to',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              // Phone Number
              Text(
                _maskedPhoneNumber,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // OTP Input
              authState.when(
                initial: () => _buildOTPInput(),
                loading: () => Column(
                  children: [
                    _buildOTPInput(),
                    const SizedBox(height: 24),
                    LoadingWidget.circular(message: 'Verifying code...'),
                  ],
                ),
                authenticated: (_, __, ___) => _buildOTPInput(),
                unauthenticated: () => _buildOTPInput(),
                error: (message) => Column(
                  children: [
                    _buildOTPInput(),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorText ?? message,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // Resend OTP Section
              Column(
                children: [
                  Text(
                    'Didn\'t receive the code?',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 8),

                  if (_isResending)
                    LoadingWidget.circular(
                      size: LoadingSize.small,
                      message: 'Sending...',
                    )
                  else
                    ShadButton.link(
                      onPressed: _handleResendOTP,
                      child: const Text('Resend Code'),
                    ),
                ],
              ),

              const SizedBox(height: 32),

              // Change Phone Number
              ShadButton.outline(
                onPressed: _isLoading ? null : _navigateBack,
                child: const Text('Change Phone Number'),
              ),

              const SizedBox(height: 24),

              // Help Text
              Text(
                'Enter the 6-digit code exactly as received. The code expires in 10 minutes.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOTPInput() {
    return OTPInputWidget(
      length: 6,
      onCompleted: _handleOTPVerification,
      onChanged: (value) {
        setState(() {
          _otpCode = value;
          _errorText = null; // Clear error when user types
        });
      },
      errorText: _errorText,
      enabled: !_isLoading,
      phoneNumber: _maskedPhoneNumber,
      onResendOTP: _handleResendOTP,
      enableResend: !_isResending,
    );
  }
}
