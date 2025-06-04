import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/constants/app_constants.dart';
import '../../models/auth/login_request.dart';
import '../../providers/auth/auth_provider.dart';
import '../../widgets/auth/phone_input_widget.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/loading_widget.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  PhoneInputData? _phoneInputData;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _phoneFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate() || _phoneInputData == null) {
      return;
    }

    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final loginRequest = LoginRequest(
        phoneNumber: _phoneInputData!.phoneNumber,
        countryCode: _phoneInputData!.country.dialCode,
        password: _passwordController.text.trim(),
        deviceId: await _getDeviceId(),
        deviceInfo: await _getDeviceInfo(),
      );

      final success = await ref.read(authProvider.notifier).login(loginRequest);

      if (success && mounted) {
        // Navigate to main app or handle success
        Navigator.of(context).pushReplacementNamed('/home');
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

  Future<String?> _getDeviceId() async {
    // Implement device ID generation
    return 'device_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<Map<String, dynamic>?> _getDeviceInfo() async {
    // Implement device info collection
    return {
      'platform': Theme.of(context).platform.name,
      'app_version': '1.0.0',
      'os_version': 'Unknown',
    };
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

  void _navigateToRegister() {
    Navigator.of(context).pushReplacementNamed('/register');
  }

  void _navigateToForgotPassword() {
    Navigator.of(context).pushNamed('/forgot-password');
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Welcome Back',
        centerTitle: true,
        showDivider: false,
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

                // Welcome Header
                Text(
                  'Sign in to your account',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                Text(
                  'Enter your phone number and password to continue',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 48),

                // Phone Number Input
                PhoneInputWidget(
                  label: 'Phone Number',
                  onChanged: (data) {
                    setState(() {
                      _phoneInputData = data;
                    });
                  },
                  focusNode: _phoneFocusNode,
                  textInputAction: TextInputAction.next,
                  onSubmitted: () {
                    _passwordFocusNode.requestFocus();
                  },
                  enabled: !_isLoading,
                  required: true,
                  autoValidate: true,
                ),

                const SizedBox(height: 24),

                // Password Input
                CustomTextField(
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  labelText: 'Password',
                  hintText: 'Enter your password',
                  obscureText: _obscurePassword,
                  enabled: !_isLoading,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _handleLogin(),
                  validator: _validatePassword,
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Forgot Password Link
                Align(
                  alignment: Alignment.centerRight,
                  child: ShadButton.link(
                    onPressed: _isLoading ? null : _navigateToForgotPassword,
                    child: const Text('Forgot Password?'),
                  ),
                ),

                const SizedBox(height: 32),

                // Login Button
                authState.when(
                  initial: () => _buildLoginButton(),
                  loading: () => Center(
                    child: LoadingWidget.circular(message: 'Signing in...'),
                  ),
                  authenticated: (_, __, ___) => _buildLoginButton(),
                  unauthenticated: () => _buildLoginButton(),
                  error: (message) => Column(
                    children: [
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
                                message,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildLoginButton(),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // OR Divider
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),

                const SizedBox(height: 32),

                // Register Link
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

                const SizedBox(height: 32),

                // Terms and Privacy
                Text(
                  'By continuing, you agree to our Terms of Service and Privacy Policy',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    final canLogin =
        _phoneInputData != null &&
        _passwordController.text.trim().isNotEmpty &&
        !_isLoading;

    return CustomButton(
      onPressed: canLogin ? _handleLogin : null,
      isLoading: _isLoading,
      size: CustomButtonSize.large,
      child: const Text('Sign In'),
    );
  }
}
