import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../providers/auth/user_provider.dart';
import '../../widgets/auth/profile_picture_widget.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/loading_widget.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  final bool isRequired; // Whether this step is required or can be skipped
  final VoidCallback? onComplete;

  const ProfileSetupScreen({
    super.key,
    this.isRequired = false,
    this.onComplete,
  });

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _emailController = TextEditingController();

  final _nameFocusNode = FocusNode();
  final _usernameFocusNode = FocusNode();
  final _bioFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();

  File? _selectedImageFile;
  Uint8List? _selectedImageBytes;
  bool _isLoading = false;
  bool _isUploadingImage = false;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _emailController.dispose();
    _nameFocusNode.dispose();
    _usernameFocusNode.dispose();
    _bioFocusNode.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  void _loadExistingProfile() {
    final userState = ref.read(userProvider);
    if (userState.hasValue && userState.value != null) {
      final user = userState.value!;
      _nameController.text = user.name;
      _usernameController.text = user.username ?? '';
      _bioController.text = user.bio ?? '';
      _emailController.text = user.email ?? '';
    }
  }

  Future<void> _handleSaveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String? avatarUrl;

      // Upload image if selected
      if (_selectedImageFile != null || _selectedImageBytes != null) {
        avatarUrl = await _uploadProfileImage();
      }

      // Update profile
      final success = await ref
          .read(userProvider.notifier)
          .updateProfile(
            name: _nameController.text.trim(),
            username: _usernameController.text.trim().isEmpty
                ? null
                : _usernameController.text.trim(),
            bio: _bioController.text.trim().isEmpty
                ? null
                : _bioController.text.trim(),
            email: _emailController.text.trim().isEmpty
                ? null
                : _emailController.text.trim(),
            avatar: avatarUrl,
          );

      if (success && mounted) {
        _showSuccessSnackBar('Profile updated successfully');

        if (widget.onComplete != null) {
          widget.onComplete!();
        } else {
          Navigator.of(context).pushReplacementNamed('/home');
        }
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

  Future<String?> _uploadProfileImage() async {
    setState(() {
      _isUploadingImage = true;
      _uploadProgress = 0.0;
    });

    try {
      // Simulate upload progress
      for (int i = 0; i <= 100; i += 10) {
        await Future.delayed(const Duration(milliseconds: 100));
        setState(() {
          _uploadProgress = i / 100;
        });
      }

      // TODO: Implement actual image upload to your backend/storage
      // This is a placeholder implementation
      const avatarUrl = 'https://example.com/avatar.jpg';

      return avatarUrl;
    } catch (e) {
      _showErrorSnackBar('Failed to upload image: $e');
      return null;
    } finally {
      setState(() {
        _isUploadingImage = false;
        _uploadProgress = 0.0;
      });
    }
  }

  void _handleSkip() {
    if (widget.isRequired) return;

    if (widget.onComplete != null) {
      widget.onComplete!();
    } else {
      Navigator.of(context).pushReplacementNamed('/home');
    }
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

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (value.trim().length > 50) {
      return 'Name must be less than 50 characters';
    }
    return null;
  }

  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Username is optional
    }

    if (value.trim().length < 3) {
      return 'Username must be at least 3 characters';
    }

    if (value.trim().length > 30) {
      return 'Username must be less than 30 characters';
    }

    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value.trim())) {
      return 'Username can only contain letters, numbers, and underscores';
    }

    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Email is optional
    }

    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  String? _validateBio(String? value) {
    if (value != null && value.trim().length > 150) {
      return 'Bio must be less than 150 characters';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Set up your profile',
        centerTitle: true,
        showDivider: false,
        actions: widget.isRequired
            ? null
            : [
                ShadButton.ghost(
                  onPressed: _isLoading ? null : _handleSkip,
                  child: const Text('Skip'),
                ),
              ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),

                // Header
                Text(
                  'Tell us about yourself',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                Text(
                  'Add a photo and some details to help others recognize you',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // Profile Picture
                Center(
                  child: ProfilePictureWidget(
                    size: 120,
                    imageFile: _selectedImageFile,
                    imageBytes: _selectedImageBytes,
                    name: _nameController.text.isEmpty
                        ? 'User'
                        : _nameController.text,
                    onImageSelected: (file) {
                      setState(() {
                        _selectedImageFile = file;
                        _selectedImageBytes = null;
                      });
                    },
                    onImageBytesSelected: (bytes) {
                      setState(() {
                        _selectedImageBytes = bytes;
                        _selectedImageFile = null;
                      });
                    },
                    onImageRemoved: () {
                      setState(() {
                        _selectedImageFile = null;
                        _selectedImageBytes = null;
                      });
                    },
                    enabled: !_isLoading,
                    showUploadProgress: _isUploadingImage,
                    uploadProgress: _uploadProgress,
                    placeholder: 'Tap to add your photo',
                  ),
                ),

                const SizedBox(height: 40),

                // Name Field (Required)
                CustomTextField(
                  controller: _nameController,
                  focusNode: _nameFocusNode,
                  labelText: 'Full Name *',
                  hintText: 'Enter your full name',
                  enabled: !_isLoading,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => _usernameFocusNode.requestFocus(),
                  validator: _validateName,
                  textCapitalization: TextCapitalization.words,
                ),

                const SizedBox(height: 20),

                // Username Field (Optional)
                CustomTextField(
                  controller: _usernameController,
                  focusNode: _usernameFocusNode,
                  labelText: 'Username',
                  hintText: 'Choose a unique username',
                  helperText: 'Others can find you using your username',
                  enabled: !_isLoading,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => _emailFocusNode.requestFocus(),
                  validator: _validateUsername,
                  prefixIcon: const Icon(Icons.alternate_email, size: 20),
                ),

                const SizedBox(height: 20),

                // Email Field (Optional)
                CustomTextField(
                  controller: _emailController,
                  focusNode: _emailFocusNode,
                  labelText: 'Email Address',
                  hintText: 'Enter your email address',
                  helperText: 'We\'ll use this to send you important updates',
                  enabled: !_isLoading,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => _bioFocusNode.requestFocus(),
                  validator: _validateEmail,
                  prefixIcon: const Icon(Icons.email_outlined, size: 20),
                ),

                const SizedBox(height: 20),

                // Bio Field (Optional)
                CustomTextField(
                  controller: _bioController,
                  focusNode: _bioFocusNode,
                  labelText: 'Bio',
                  hintText: 'Tell people a bit about yourself',
                  helperText: 'This appears on your profile',
                  enabled: !_isLoading,
                  maxLines: 3,
                  maxLength: 150,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _handleSaveProfile(),
                  validator: _validateBio,
                  textCapitalization: TextCapitalization.sentences,
                  showCounter: true,
                ),

                const SizedBox(height: 40),

                // Save Button
                userState.when(
                  data: (_) => _buildSaveButton(),
                  loading: () => Center(
                    child: LoadingWidget.circular(
                      message: 'Updating profile...',
                    ),
                  ),
                  error: (error, _) => Column(
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
                                error.toString(),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSaveButton(),
                    ],
                  ),
                ),

                if (!widget.isRequired) ...[
                  const SizedBox(height: 16),

                  // Skip Button
                  ShadButton.outline(
                    onPressed: _isLoading ? null : _handleSkip,
                    child: const Text('Skip for now'),
                  ),
                ],

                const SizedBox(height: 24),

                // Help Text
                Text(
                  'You can always update your profile later in settings',
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

  Widget _buildSaveButton() {
    final canSave = _nameController.text.trim().isNotEmpty && !_isLoading;

    return CustomButton(
      onPressed: canSave ? _handleSaveProfile : null,
      isLoading: _isLoading,
      size: CustomButtonSize.large,
      child: Text(widget.isRequired ? 'Complete Setup' : 'Save Profile'),
    );
  }
}
