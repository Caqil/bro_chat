import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

import '../../services/api/api_service.dart';
import '../../models/file/file_model.dart';
import '../../models/common/api_response.dart';
import '../../providers/chat/message_provider.dart';

enum AttachmentType {
  image,
  video,
  document,
  audio,
  location,
  contact,
  camera,
  gallery,
}

class AttachmentPickerWidget extends ConsumerStatefulWidget {
  final String chatId;
  final ValueChanged<List<AttachmentResult>>? onAttachmentsSelected;
  final VoidCallback? onClose;
  final bool allowMultiple;
  final List<AttachmentType> availableTypes;

  const AttachmentPickerWidget({
    super.key,
    required this.chatId,
    this.onAttachmentsSelected,
    this.onClose,
    this.allowMultiple = true,
    this.availableTypes = const [
      AttachmentType.camera,
      AttachmentType.gallery,
      AttachmentType.document,
      AttachmentType.location,
      AttachmentType.contact,
    ],
  });

  @override
  ConsumerState<AttachmentPickerWidget> createState() =>
      _AttachmentPickerWidgetState();
}

class _AttachmentPickerWidgetState extends ConsumerState<AttachmentPickerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  final ImagePicker _imagePicker = ImagePicker();
  final List<AttachmentResult> _selectedAttachments = [];
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(),
                  _buildAttachmentOptions(),
                  if (_selectedAttachments.isNotEmpty)
                    _buildSelectedAttachments(),
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          const Text(
            'Attach Files',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          ShadButton.ghost(
            onPressed: widget.onClose,
            size: ShadButtonSize.sm,
            child: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentOptions() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        shrinkWrap: true,
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: widget.availableTypes.map((type) {
          return _buildAttachmentOption(type);
        }).toList(),
      ),
    );
  }

  Widget _buildAttachmentOption(AttachmentType type) {
    final config = _getAttachmentConfig(type);

    return ShadButton.outline(
      onPressed: _isProcessing ? null : () => _handleAttachmentType(type),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: config.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(config.icon, color: config.color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            config.label,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedAttachments() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selected (${_selectedAttachments.length})',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedAttachments.map((attachment) {
              return _buildAttachmentPreview(attachment);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentPreview(AttachmentResult attachment) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: _buildPreviewContent(attachment),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: () => _removeAttachment(attachment),
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewContent(AttachmentResult attachment) {
    switch (attachment.type) {
      case AttachmentType.image:
        if (attachment.file != null) {
          return Image.file(
            attachment.file!,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
          );
        }
        break;
      case AttachmentType.video:
        return Container(
          width: 60,
          height: 60,
          color: Colors.black,
          child: const Icon(Icons.play_arrow, color: Colors.white, size: 24),
        );
      case AttachmentType.document:
        return Container(
          width: 60,
          height: 60,
          color: Colors.blue[50],
          child: const Icon(Icons.description, color: Colors.blue, size: 24),
        );
      case AttachmentType.audio:
        return Container(
          width: 60,
          height: 60,
          color: Colors.orange[50],
          child: const Icon(Icons.audio_file, color: Colors.orange, size: 24),
        );
      case AttachmentType.location:
        return Container(
          width: 60,
          height: 60,
          color: Colors.red[50],
          child: const Icon(Icons.location_on, color: Colors.red, size: 24),
        );
      case AttachmentType.contact:
        return Container(
          width: 60,
          height: 60,
          color: Colors.green[50],
          child: const Icon(Icons.person, color: Colors.green, size: 24),
        );
      default:
        break;
    }

    return Container(
      width: 60,
      height: 60,
      color: Colors.grey[200],
      child: const Icon(Icons.file_present, color: Colors.grey, size: 24),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ShadButton.outline(
              onPressed: widget.onClose,
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ShadButton(
              onPressed: _selectedAttachments.isNotEmpty && !_isProcessing
                  ? _sendAttachments
                  : null,
              child: _isProcessing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('Send (${_selectedAttachments.length})'),
            ),
          ),
        ],
      ),
    );
  }

  AttachmentConfig _getAttachmentConfig(AttachmentType type) {
    switch (type) {
      case AttachmentType.camera:
        return AttachmentConfig(
          icon: Icons.camera_alt,
          label: 'Camera',
          color: Colors.blue,
        );
      case AttachmentType.gallery:
        return AttachmentConfig(
          icon: Icons.photo_library,
          label: 'Gallery',
          color: Colors.green,
        );
      case AttachmentType.document:
        return AttachmentConfig(
          icon: Icons.description,
          label: 'Document',
          color: Colors.orange,
        );
      case AttachmentType.location:
        return AttachmentConfig(
          icon: Icons.location_on,
          label: 'Location',
          color: Colors.red,
        );
      case AttachmentType.contact:
        return AttachmentConfig(
          icon: Icons.person,
          label: 'Contact',
          color: Colors.purple,
        );
      default:
        return AttachmentConfig(
          icon: Icons.attach_file,
          label: 'File',
          color: Colors.grey,
        );
    }
  }

  Future<void> _handleAttachmentType(AttachmentType type) async {
    setState(() => _isProcessing = true);

    try {
      switch (type) {
        case AttachmentType.camera:
          await _pickFromCamera();
          break;
        case AttachmentType.gallery:
          await _pickFromGallery();
          break;
        case AttachmentType.document:
          await _pickDocument();
          break;
        case AttachmentType.location:
          await _pickLocation();
          break;
        case AttachmentType.contact:
          await _pickContact();
          break;
        default:
          break;
      }
    } catch (e) {
      _showError('Failed to pick attachment: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _pickFromCamera() async {
    final permission = await Permission.camera.request();
    if (!permission.isGranted) {
      _showError('Camera permission required');
      return;
    }

    final result = await showDialog<String>(
      context: context,
      builder: (context) => ShadDialog(
        title: const Text('Camera'),
        actions: [
          ShadButton(
            onPressed: () => Navigator.pop(context, 'photo'),
            child: const Text('Photo'),
          ),
          ShadButton(
            onPressed: () => Navigator.pop(context, 'video'),
            child: const Text('Video'),
          ),
        ],
        child: const Text('What would you like to capture?'),
      ),
    );

    if (result == null) return;

    if (result == 'photo') {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        _addAttachment(
          AttachmentResult(
            type: AttachmentType.image,
            file: File(image.path),
            name: image.name,
          ),
        );
      }
    } else {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 5),
      );

      if (video != null) {
        _addAttachment(
          AttachmentResult(
            type: AttachmentType.video,
            file: File(video.path),
            name: video.name,
          ),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    final permission = await Permission.photos.request();
    if (!permission.isGranted) {
      _showError('Photos permission required');
      return;
    }

    if (widget.allowMultiple) {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      for (final image in images) {
        _addAttachment(
          AttachmentResult(
            type: AttachmentType.image,
            file: File(image.path),
            name: image.name,
          ),
        );
      }
    } else {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        _addAttachment(
          AttachmentResult(
            type: AttachmentType.image,
            file: File(image.path),
            name: image.name,
          ),
        );
      }
    }
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: widget.allowMultiple,
      type: FileType.any,
      allowedExtensions: null,
    );

    if (result != null) {
      for (final file in result.files) {
        if (file.path != null) {
          _addAttachment(
            AttachmentResult(
              type: _getFileType(file.extension),
              file: File(file.path!),
              name: file.name,
              size: file.size,
            ),
          );
        }
      }
    }
  }

  Future<void> _pickLocation() async {
    final permission = await Permission.location.request();
    if (!permission.isGranted) {
      _showError('Location permission required');
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _addAttachment(
        AttachmentResult(
          type: AttachmentType.location,
          location: LocationData(
            latitude: position.latitude,
            longitude: position.longitude,
            address: await _getAddressFromCoordinates(
              position.latitude,
              position.longitude,
            ),
          ),
          name: 'Current Location',
        ),
      );
    } catch (e) {
      _showError('Failed to get location: $e');
    }
  }

  Future<void> _pickContact() async {
    final permission = await Permission.contacts.request();
    if (!permission.isGranted) {
      _showError('Contacts permission required');
      return;
    }

    try {
      final contacts = await ContactsService.getContacts();
      if (contacts.isEmpty) {
        _showError('No contacts found');
        return;
      }

      final selectedContact = await showDialog<Contact>(
        context: context,
        builder: (context) => _ContactPickerDialog(contacts: contacts),
      );

      if (selectedContact != null) {
        _addAttachment(
          AttachmentResult(
            type: AttachmentType.contact,
            contact: ContactData(
              name: selectedContact.displayName ?? 'Unknown',
              phoneNumber: selectedContact.phones?.isNotEmpty == true
                  ? selectedContact.phones!.first.value
                  : null,
              email: selectedContact.emails?.isNotEmpty == true
                  ? selectedContact.emails!.first.value
                  : null,
            ),
            name: selectedContact.displayName ?? 'Contact',
          ),
        );
      }
    } catch (e) {
      _showError('Failed to pick contact: $e');
    }
  }

  Future<String> _getAddressFromCoordinates(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return '${place.street}, ${place.locality}, ${place.country}';
      }
    } catch (e) {
      // Fallback to coordinates
    }
    return '$lat, $lng';
  }

  AttachmentType _getFileType(String? extension) {
    if (extension == null) return AttachmentType.document;

    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return AttachmentType.image;
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'wmv':
        return AttachmentType.video;
      case 'mp3':
      case 'wav':
      case 'aac':
      case 'm4a':
        return AttachmentType.audio;
      default:
        return AttachmentType.document;
    }
  }

  void _addAttachment(AttachmentResult attachment) {
    if (!widget.allowMultiple) {
      _selectedAttachments.clear();
    }

    setState(() {
      _selectedAttachments.add(attachment);
    });
  }

  void _removeAttachment(AttachmentResult attachment) {
    setState(() {
      _selectedAttachments.remove(attachment);
    });
  }

  Future<void> _sendAttachments() async {
    if (_selectedAttachments.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      final results = <AttachmentResult>[];

      for (final attachment in _selectedAttachments) {
        if (attachment.file != null) {
          // Upload file and get file model
          final response = await ref
              .read(apiServiceProvider)
              .uploadFile(
                file: attachment.file!,
                purpose: 'message',
                chatId: widget.chatId,
                public: false,
              );

          if (response.success && response.data != null) {
            final fileModel = response.data!;
            results.add(
              attachment.copyWith(fileModel: fileModel, url: fileModel.url),
            );
          }
        } else {
          // For non-file attachments (location, contact)
          results.add(attachment);
        }
      }

      widget.onAttachmentsSelected?.call(results);
      widget.onClose?.call();
    } catch (e) {
      _showError('Failed to upload attachments: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}

class AttachmentConfig {
  final IconData icon;
  final String label;
  final Color color;

  AttachmentConfig({
    required this.icon,
    required this.label,
    required this.color,
  });
}

class AttachmentResult {
  final AttachmentType type;
  final File? file;
  final String name;
  final int? size;
  final LocationData? location;
  final ContactData? contact;
  final FileModel? fileModel;
  final String? url;

  AttachmentResult({
    required this.type,
    this.file,
    required this.name,
    this.size,
    this.location,
    this.contact,
    this.fileModel,
    this.url,
  });

  AttachmentResult copyWith({
    AttachmentType? type,
    File? file,
    String? name,
    int? size,
    LocationData? location,
    ContactData? contact,
    FileModel? fileModel,
    String? url,
  }) {
    return AttachmentResult(
      type: type ?? this.type,
      file: file ?? this.file,
      name: name ?? this.name,
      size: size ?? this.size,
      location: location ?? this.location,
      contact: contact ?? this.contact,
      fileModel: fileModel ?? this.fileModel,
      url: url ?? this.url,
    );
  }
}

class LocationData {
  final double latitude;
  final double longitude;
  final String address;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.address,
  });
}

class ContactData {
  final String name;
  final String? phoneNumber;
  final String? email;

  ContactData({required this.name, this.phoneNumber, this.email});
}

class _ContactPickerDialog extends StatefulWidget {
  final List<Contact> contacts;

  const _ContactPickerDialog({required this.contacts});

  @override
  State<_ContactPickerDialog> createState() => _ContactPickerDialogState();
}

class _ContactPickerDialogState extends State<_ContactPickerDialog> {
  late List<Contact> _filteredContacts;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredContacts = widget.contacts;
    _searchController.addListener(_filterContacts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterContacts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredContacts = widget.contacts.where((contact) {
        final name = contact.displayName?.toLowerCase() ?? '';
        return name.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ShadDialog(
      title: const Text('Select Contact'),
      actions: [
        ShadButton.outline(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
      child: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            ShadInput(
              controller: _searchController,
              placeholder: const Text('Search contacts...'),
              trailing: const Padding(
                padding: EdgeInsets.only(left: 12),
                child: Icon(Icons.search, size: 16),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredContacts.length,
                itemBuilder: (context, index) {
                  final contact = _filteredContacts[index];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        (contact.displayName?.isNotEmpty == true
                                ? contact.displayName![0]
                                : 'C')
                            .toUpperCase(),
                      ),
                    ),
                    title: Text(contact.displayName ?? 'Unknown'),
                    subtitle: contact.phones?.isNotEmpty == true
                        ? Text(contact.phones!.first.value ?? '')
                        : null,
                    onTap: () => Navigator.pop(context, contact),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
