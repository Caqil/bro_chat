import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../widgets/auth/phone_input_widget.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/custom_button.dart';

class PhoneInputScreen extends ConsumerStatefulWidget {
  final String? title;
  final String? subtitle;
  final String? purpose; // 'login', 'register', 'forgot_password'
  final Function(String phoneNumber, String countryCode)? onPhoneSubmitted;

  const PhoneInputScreen({
    super.key,
    this.title,
    this.subtitle,
    this.purpose,
    this.onPhoneSubmitted,
  });

  @override
  ConsumerState<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends ConsumerState<PhoneInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneInputKey = GlobalKey<PhoneInputWidgetState>();

  PhoneInputData? _phoneInputData;
  bool _isLoading = false;
  bool _agreedToTerms = false;

  @override
  void initState() {
    super.initState();
    // Set default agreement for certain purposes
    if (widget.purpose == 'login' || widget.purpose == 'forgot_password') {
      _agreedToTerms = true;
    }
  }

  Future<void> _handleContinue() async {
    if (!_formKey.currentState!.validate() || _phoneInputData == null) {
      return;
    }

    if (!_agreedToTerms && widget.purpose == 'register') {
      _showErrorSnackBar(
        'Please agree to the Terms of Service and Privacy Policy',
      );
      return;
    }

    // Validate phone number
    final validation = _phoneInputKey.currentState?.validate();
    if (validation != null) {
      _showErrorSnackBar(validation);
      return;
    }

    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));

      if (widget.onPhoneSubmitted != null) {
        widget.onPhoneSubmitted!(
          _phoneInputData!.phoneNumber,
          _phoneInputData!.country.dialCode,
        );
      } else {
        // Default navigation based on purpose
        _navigateToNextScreen();
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToNextScreen() {
    final phoneNumber = _phoneInputData!.phoneNumber;
    final countryCode = _phoneInputData!.country.dialCode;

    switch (widget.purpose) {
      case 'register':
        Navigator.of(context).pushNamed(
          '/register',
          arguments: {'phoneNumber': phoneNumber, 'countryCode': countryCode},
        );
        break;
      case 'login':
        Navigator.of(context).pushNamed(
          '/login',
          arguments: {'phoneNumber': phoneNumber, 'countryCode': countryCode},
        );
        break;
      case 'forgot_password':
        Navigator.of(context).pushNamed(
          '/otp-verification',
          arguments: {
            'phoneNumber': phoneNumber,
            'countryCode': countryCode,
            'purpose': 'password_reset',
          },
        );
        break;
      default:
        Navigator.of(context).pushNamed('/register');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _navigateToLogin() {
    Navigator.of(context).pushNamed('/login');
  }

  void _navigateToRegister() {
    Navigator.of(context).pushNamed('/register');
  }

  String get _screenTitle {
    if (widget.title != null) return widget.title!;

    switch (widget.purpose) {
      case 'login':
        return 'Welcome Back';
      case 'register':
        return 'Create Account';
      case 'forgot_password':
        return 'Reset Password';
      default:
        return 'Enter Phone Number';
    }
  }

  String get _screenSubtitle {
    if (widget.subtitle != null) return widget.subtitle!;

    switch (widget.purpose) {
      case 'login':
        return 'Enter your phone number to sign in to your account';
      case 'register':
        return 'Enter your phone number to create a new account';
      case 'forgot_password':
        return 'Enter your phone number to reset your password';
      default:
        return 'We\'ll send you a verification code';
    }
  }

  String get _continueButtonText {
    switch (widget.purpose) {
      case 'login':
        return 'Sign In';
      case 'register':
        return 'Create Account';
      case 'forgot_password':
        return 'Reset Password';
      default:
        return 'Continue';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: _screenTitle,
        centerTitle: true,
        showDivider: false,
        onLeadingPressed: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),

                // Header Icon
                _buildHeaderIcon(),

                const SizedBox(height: 32),

                // Title
                Text(
                  _screenTitle,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // Subtitle
                Text(
                  _screenSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 48),

                // Phone Input
                PhoneInputWidget(
                  key: _phoneInputKey,
                  label: 'Phone Number',
                  placeholder: 'Enter your phone number',
                  onChanged: (data) {
                    setState(() {
                      _phoneInputData = data;
                    });
                  },
                  enabled: !_isLoading,
                  required: true,
                  autoValidate: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: _handleContinue,
                ),

                const SizedBox(height: 32),

                // Terms Agreement (for registration)
                if (widget.purpose == 'register') ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShadCheckbox(
                        value: _agreedToTerms,
                        onChanged: _isLoading
                            ? null
                            : (value) {
                                setState(() {
                                  _agreedToTerms = value ?? false;
                                });
                              },
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: _isLoading
                              ? null
                              : () {
                                  setState(() {
                                    _agreedToTerms = !_agreedToTerms;
                                  });
                                },
                          child: Text(
                            'I agree to the Terms of Service and Privacy Policy',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],

                // Continue Button
                CustomButton(
                  onPressed: _canContinue ? _handleContinue : null,
                  isLoading: _isLoading,
                  size: CustomButtonSize.large,
                  child: Text(_continueButtonText),
                ),

                const SizedBox(height: 32),

                // Alternative Actions
                if (widget.purpose != 'forgot_password') ...[
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],

                // Sign In / Sign Up Toggle
                if (widget.purpose == 'register') ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      ShadButton.link(
                        onPressed: _isLoading ? null : _navigateToLogin,
                        child: const Text('Sign In'),
                      ),
                    ],
                  ),
                ] else if (widget.purpose == 'login') ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Don\'t have an account? ',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      ShadButton.link(
                        onPressed: _isLoading ? null : _navigateToRegister,
                        child: const Text('Sign Up'),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 24),

                // Help Text
                _buildHelpText(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderIcon() {
    IconData iconData;
    Color iconColor = Theme.of(context).colorScheme.primary;

    switch (widget.purpose) {
      case 'login':
        iconData = Icons.login;
        break;
      case 'register':
        iconData = Icons.person_add;
        break;
      case 'forgot_password':
        iconData = Icons.lock_reset;
        break;
      default:
        iconData = Icons.phone;
    }

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, size: 40, color: iconColor),
    );
  }

  Widget _buildHelpText() {
    String helpText;

    switch (widget.purpose) {
      case 'register':
        helpText =
            'By creating an account, you agree to our Terms of Service and Privacy Policy. We\'ll send a verification code to your phone number.';
        break;
      case 'login':
        helpText = 'We\'ll verify your phone number to sign you in securely.';
        break;
      case 'forgot_password':
        helpText = 'We\'ll send a verification code to reset your password.';
        break;
      default:
        helpText =
            'Your phone number will be used to verify your identity and secure your account.';
    }

    return Text(
      helpText,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        height: 1.4,
      ),
      textAlign: TextAlign.center,
    );
  }

  bool get _canContinue {
    return _phoneInputData != null &&
        _phoneInputData!.phoneNumber.isNotEmpty &&
        !_isLoading &&
        (widget.purpose != 'register' || _agreedToTerms);
  }
}
