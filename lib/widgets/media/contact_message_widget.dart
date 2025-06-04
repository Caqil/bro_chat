import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../models/chat/message_model.dart';
import '../../core/utils/phone_utils.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';

class ContactMessageWidget extends ConsumerStatefulWidget {
  final MessageModel message;
  final bool isCurrentUser;
  final double maxWidth;
  final VoidCallback? onContactSaved;
  final Function(String)? onError;

  const ContactMessageWidget({
    Key? key,
    required this.message,
    required this.isCurrentUser,
    this.maxWidth = 280,
    this.onContactSaved,
    this.onError,
  }) : super(key: key);

  @override
  ConsumerState<ContactMessageWidget> createState() =>
      _ContactMessageWidgetState();
}

class _ContactMessageWidgetState extends ConsumerState<ContactMessageWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  bool _isSaving = false;
  ContactInfo? _contactInfo;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _parseContactInfo();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  void _parseContactInfo() {
    try {
      final metadata = widget.message.metadata;
      if (metadata != null && metadata['contact'] != null) {
        final contactData = metadata['contact'] as Map<String, dynamic>;

        _contactInfo = ContactInfo(
          name: contactData['name'] as String? ?? '',
          phoneNumber: contactData['phone_number'] as String? ?? '',
          email: contactData['email'] as String?,
          organization: contactData['organization'] as String?,
          jobTitle: contactData['job_title'] as String?,
          avatar: contactData['avatar'] as String?,
          website: contactData['website'] as String?,
          address: contactData['address'] as String?,
          birthday: contactData['birthday'] != null
              ? DateTime.tryParse(contactData['birthday'] as String)
              : null,
          notes: contactData['notes'] as String?,
        );
      }
    } catch (e) {
      widget.onError?.call('Failed to parse contact information: $e');
    }
  }

  Future<void> _saveContact() async {
    if (_contactInfo == null || _isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Request contacts permission
      final permission = await Permission.contacts.request();
      if (!permission.isGranted) {
        throw Exception('Contacts permission denied');
      }

      // Create contact
      final contact = Contact();
      contact.displayName = _contactInfo!.name;

      if (_contactInfo!.phoneNumber.isNotEmpty) {
        contact.phones = [
          Item(label: 'mobile', value: _contactInfo!.phoneNumber),
        ];
      }

      if (_contactInfo!.email != null && _contactInfo!.email!.isNotEmpty) {
        contact.emails = [Item(label: 'work', value: _contactInfo!.email!)];
      }

      if (_contactInfo!.organization != null) {
        contact.company = _contactInfo!.organization;
      }

      if (_contactInfo!.jobTitle != null) {
        contact.jobTitle = _contactInfo!.jobTitle;
      }

      if (_contactInfo!.address != null && _contactInfo!.address!.isNotEmpty) {
        contact.postalAddresses = [
          PostalAddress(label: 'home', street: _contactInfo!.address!),
        ];
      }

      if (_contactInfo!.birthday != null) {
        contact.birthday = _contactInfo!.birthday;
      }

      // Save contact
      await ContactsService.addContact(contact);

      if (mounted) {
        SnackbarUtils.showSuccess(context, 'Contact saved successfully');
        widget.onContactSaved?.call();
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Failed to save contact: $e');
        widget.onError?.call(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _makePhoneCall() async {
    if (_contactInfo?.phoneNumber == null ||
        _contactInfo!.phoneNumber.isEmpty) {
      return;
    }

    try {
      final phoneUrl = 'tel:${_contactInfo!.phoneNumber}';
      if (await canLaunchUrl(Uri.parse(phoneUrl))) {
        await launchUrl(Uri.parse(phoneUrl));
      } else {
        throw Exception('Cannot make phone call');
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Failed to make phone call: $e');
      }
    }
  }

  Future<void> _sendSMS() async {
    if (_contactInfo?.phoneNumber == null ||
        _contactInfo!.phoneNumber.isEmpty) {
      return;
    }

    try {
      final smsUrl = 'sms:${_contactInfo!.phoneNumber}';
      if (await canLaunchUrl(Uri.parse(smsUrl))) {
        await launchUrl(Uri.parse(smsUrl));
      } else {
        throw Exception('Cannot send SMS');
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Failed to send SMS: $e');
      }
    }
  }

  Future<void> _sendEmail() async {
    if (_contactInfo?.email == null || _contactInfo!.email!.isEmpty) {
      return;
    }

    try {
      final emailUrl = 'mailto:${_contactInfo!.email}';
      if (await canLaunchUrl(Uri.parse(emailUrl))) {
        await launchUrl(Uri.parse(emailUrl));
      } else {
        throw Exception('Cannot send email');
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Failed to send email: $e');
      }
    }
  }

  Future<void> _openWebsite() async {
    if (_contactInfo?.website == null || _contactInfo!.website!.isEmpty) {
      return;
    }

    try {
      String url = _contactInfo!.website!;
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'https://$url';
      }

      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        throw Exception('Cannot open website');
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Failed to open website: $e');
      }
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    SnackbarUtils.showSuccess(context, '$label copied to clipboard');
  }

  void _showContactActions() {
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildContactActionsSheet(),
    );
  }

  Widget _buildContactActionsSheet() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  _contactInfo?.name ?? 'Contact',
                  style: AppTextStyles.h6.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildActionButton(
                  icon: Icons.person_add,
                  label: 'Save Contact',
                  onPressed: _saveContact,
                  isLoading: _isSaving,
                ),
                if (_contactInfo?.phoneNumber != null &&
                    _contactInfo!.phoneNumber.isNotEmpty) ...[
                  _buildActionButton(
                    icon: Icons.phone,
                    label: 'Call',
                    onPressed: _makePhoneCall,
                  ),
                  _buildActionButton(
                    icon: Icons.message,
                    label: 'Message',
                    onPressed: _sendSMS,
                  ),
                ],
                if (_contactInfo?.email != null &&
                    _contactInfo!.email!.isNotEmpty)
                  _buildActionButton(
                    icon: Icons.email,
                    label: 'Email',
                    onPressed: _sendEmail,
                  ),
                if (_contactInfo?.website != null &&
                    _contactInfo!.website!.isNotEmpty)
                  _buildActionButton(
                    icon: Icons.language,
                    label: 'Website',
                    onPressed: _openWebsite,
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          foregroundColor: AppColors.primary,
          backgroundColor: AppColors.primary.withOpacity(0.1),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildContactAvatar() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withOpacity(0.1),
        border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 2),
      ),
      child: _contactInfo?.avatar != null && _contactInfo!.avatar!.isNotEmpty
          ? ClipOval(
              child: Image.network(
                _contactInfo!.avatar!,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildDefaultAvatar();
                },
              ),
            )
          : _buildDefaultAvatar(),
    );
  }

  Widget _buildDefaultAvatar() {
    final name = _contactInfo?.name ?? '';
    final initials = name.isNotEmpty
        ? name
              .split(' ')
              .map((word) => word.isNotEmpty ? word[0] : '')
              .take(2)
              .join()
              .toUpperCase()
        : '?';

    return Center(
      child: Text(
        initials,
        style: AppTextStyles.h6.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildContactInfo() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _contactInfo?.name ?? 'Unknown Contact',
            style: AppTextStyles.subtitle1.copyWith(
              color: widget.isCurrentUser
                  ? Colors.white
                  : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (_contactInfo?.phoneNumber != null &&
              _contactInfo!.phoneNumber.isNotEmpty) ...[
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () =>
                  _copyToClipboard(_contactInfo!.phoneNumber, 'Phone number'),
              child: Row(
                children: [
                  Icon(
                    Icons.phone,
                    size: 16,
                    color: widget.isCurrentUser
                        ? Colors.white.withOpacity(0.8)
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      PhoneUtils.formatPhoneNumber(_contactInfo!.phoneNumber),
                      style: AppTextStyles.body2.copyWith(
                        color: widget.isCurrentUser
                            ? Colors.white.withOpacity(0.9)
                            : AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_contactInfo?.email != null &&
              _contactInfo!.email!.isNotEmpty) ...[
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => _copyToClipboard(_contactInfo!.email!, 'Email'),
              child: Row(
                children: [
                  Icon(
                    Icons.email,
                    size: 16,
                    color: widget.isCurrentUser
                        ? Colors.white.withOpacity(0.8)
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _contactInfo!.email!,
                      style: AppTextStyles.body2.copyWith(
                        color: widget.isCurrentUser
                            ? Colors.white.withOpacity(0.9)
                            : AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_contactInfo?.organization != null &&
              _contactInfo!.organization!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.business,
                  size: 16,
                  color: widget.isCurrentUser
                      ? Colors.white.withOpacity(0.8)
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _contactInfo!.organization!,
                    style: AppTextStyles.body2.copyWith(
                      color: widget.isCurrentUser
                          ? Colors.white.withOpacity(0.9)
                          : AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_contactInfo?.phoneNumber != null &&
            _contactInfo!.phoneNumber.isNotEmpty)
          IconButton(
            onPressed: _makePhoneCall,
            icon: Icon(
              Icons.phone,
              color: widget.isCurrentUser
                  ? Colors.white.withOpacity(0.8)
                  : AppColors.primary,
              size: 20,
            ),
            tooltip: 'Call',
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        if (_contactInfo?.phoneNumber != null &&
            _contactInfo!.phoneNumber.isNotEmpty)
          IconButton(
            onPressed: _sendSMS,
            icon: Icon(
              Icons.message,
              color: widget.isCurrentUser
                  ? Colors.white.withOpacity(0.8)
                  : AppColors.primary,
              size: 20,
            ),
            tooltip: 'Message',
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        IconButton(
          onPressed: _isSaving ? null : _saveContact,
          icon: _isSaving
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      widget.isCurrentUser
                          ? Colors.white.withOpacity(0.8)
                          : AppColors.primary,
                    ),
                  ),
                )
              : Icon(
                  Icons.person_add,
                  color: widget.isCurrentUser
                      ? Colors.white.withOpacity(0.8)
                      : AppColors.primary,
                  size: 20,
                ),
          tooltip: 'Save Contact',
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_contactInfo == null) {
      return Container(
        constraints: BoxConstraints(maxWidth: widget.maxWidth),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: widget.isCurrentUser
                  ? Colors.white.withOpacity(0.8)
                  : AppColors.error,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Unable to load contact information',
                style: AppTextStyles.body2.copyWith(
                  color: widget.isCurrentUser
                      ? Colors.white.withOpacity(0.8)
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: _showContactActions,
        child: Container(
          constraints: BoxConstraints(maxWidth: widget.maxWidth),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildContactAvatar(),
                  const SizedBox(width: 12),
                  _buildContactInfo(),
                  _buildQuickActions(),
                ],
              ),
              if (widget.message.content.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  widget.message.content,
                  style: AppTextStyles.body2.copyWith(
                    color: widget.isCurrentUser
                        ? Colors.white
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

class ContactInfo {
  final String name;
  final String phoneNumber;
  final String? email;
  final String? organization;
  final String? jobTitle;
  final String? avatar;
  final String? website;
  final String? address;
  final DateTime? birthday;
  final String? notes;

  ContactInfo({
    required this.name,
    required this.phoneNumber,
    this.email,
    this.organization,
    this.jobTitle,
    this.avatar,
    this.website,
    this.address,
    this.birthday,
    this.notes,
  });
}
