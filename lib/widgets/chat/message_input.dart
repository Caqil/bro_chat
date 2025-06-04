import 'dart:async';
import 'dart:io';
import 'package:bro_chat/services/api/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../models/chat/message_model.dart';
import '../../providers/chat/message_provider.dart';
import '../../providers/chat/typing_provider.dart';
import 'attachment_picker.dart';
import 'emoji_picker_widget.dart';
import 'message_reply_preview.dart';

class MessageInputWidget extends ConsumerStatefulWidget {
  final String chatId;
  final MessageModel? replyToMessage;
  final VoidCallback? onReplyCancel;
  final String? draftMessage;
  final bool enabled;
  final String? placeholder;
  final int maxLines;
  final bool showAttachmentButton;
  final bool showEmojiButton;
  final bool showVoiceButton;
  final Function(String)? onTextChanged;
  final Function(MessageModel)? onMessageSent;

  const MessageInputWidget({
    super.key,
    required this.chatId,
    this.replyToMessage,
    this.onReplyCancel,
    this.draftMessage,
    this.enabled = true,
    this.placeholder = 'Type a message...',
    this.maxLines = 6,
    this.showAttachmentButton = true,
    this.showEmojiButton = true,
    this.showVoiceButton = true,
    this.onTextChanged,
    this.onMessageSent,
  });

  @override
  ConsumerState<MessageInputWidget> createState() => _MessageInputWidgetState();
}

class _MessageInputWidgetState extends ConsumerState<MessageInputWidget>
    with TickerProviderStateMixin {
  late TextEditingController _textController;
  late FocusNode _focusNode;
  late AnimationController _sendButtonController;
  late AnimationController _voiceButtonController;
  late Animation<double> _sendButtonAnimation;
  late Animation<double> _voiceButtonAnimation;

  bool _isEmojiPickerVisible = false;
  bool _isRecording = false;
  bool _hasText = false;
  Timer? _typingTimer;
  Record? _audioRecorder;
  String? _recordingPath;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;

  static const Duration _typingTimeout = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeAudioRecorder();
  }

  void _initializeControllers() {
    _textController = TextEditingController(text: widget.draftMessage);
    _focusNode = FocusNode();

    _sendButtonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _voiceButtonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _sendButtonAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sendButtonController, curve: Curves.easeInOut),
    );

    _voiceButtonAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _voiceButtonController, curve: Curves.easeInOut),
    );

    _textController.addListener(_onTextChanged);
    _hasText = _textController.text.isNotEmpty;

    if (_hasText) {
      _sendButtonController.forward();
      _voiceButtonController.forward();
    }
  }

  Future<void> _initializeAudioRecorder() async {
    _audioRecorder = Record();
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _sendButtonController.dispose();
    _voiceButtonController.dispose();
    _typingTimer?.cancel();
    _recordingTimer?.cancel();
    _audioRecorder?.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _textController.text;
    final hasText = text.isNotEmpty;

    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });

      if (hasText) {
        _sendButtonController.forward();
        _voiceButtonController.forward();
      } else {
        _sendButtonController.reverse();
        _voiceButtonController.reverse();
      }
    }

    // Handle typing indicators
    if (hasText) {
      ref.read(typingProvider.notifier).startTyping(widget.chatId);
      _resetTypingTimer();
    } else {
      ref.read(typingProvider.notifier).stopTyping(widget.chatId);
      _typingTimer?.cancel();
    }

    widget.onTextChanged?.call(text);
  }

  void _resetTypingTimer() {
    _typingTimer?.cancel();
    _typingTimer = Timer(_typingTimeout, () {
      ref.read(typingProvider.notifier).stopTyping(widget.chatId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        children: [
          // Reply preview
          if (widget.replyToMessage != null)
            MessageReplyPreviewWidget(
              message: widget.replyToMessage!,
              onCancel: widget.onReplyCancel,
            ),

          // Main input area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Attachment button
                if (widget.showAttachmentButton && !_isRecording)
                  _buildAttachmentButton(),

                // Text input
                Expanded(child: _buildTextInput()),

                const SizedBox(width: 8),

                // Emoji button
                if (widget.showEmojiButton && !_isRecording)
                  _buildEmojiButton(),

                const SizedBox(width: 4),

                // Send/Voice button
                _buildSendOrVoiceButton(),
              ],
            ),
          ),

          // Emoji picker
          if (_isEmojiPickerVisible)
            SizedBox(
              height: 250,
              child: EmojiPickerWidget(onEmojiSelected: _onEmojiSelected),
            ),
        ],
      ),
    );
  }

  Widget _buildAttachmentButton() {
    return ShadButton.raw(
      onPressed: _showAttachmentPicker,
      variant: ShadButtonVariant.ghost,
      size: ShadButtonSize.sm,
      child: Icon(Icons.attach_file, color: Colors.grey[600], size: 24),
    );
  }

  Widget _buildTextInput() {
    return Container(
      constraints: BoxConstraints(maxHeight: widget.maxLines * 20.0),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextField(
        controller: _textController,
        focusNode: _focusNode,
        enabled: widget.enabled && !_isRecording,
        maxLines: null,
        textInputAction: TextInputAction.newline,
        decoration: InputDecoration(
          hintText: _isRecording ? 'Recording...' : widget.placeholder,
          hintStyle: TextStyle(color: Colors.grey[500]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
        ),
        onSubmitted: (_) => _sendMessage(),
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildEmojiButton() {
    return ShadButton.raw(
      onPressed: _toggleEmojiPicker,
      variant: ShadButtonVariant.ghost,
      size: ShadButtonSize.sm,
      child: Icon(
        _isEmojiPickerVisible ? Icons.keyboard : Icons.emoji_emotions,
        color: Colors.grey[600],
        size: 24,
      ),
    );
  }

  Widget _buildSendOrVoiceButton() {
    return Stack(
      children: [
        // Voice button
        if (widget.showVoiceButton)
          AnimatedBuilder(
            animation: _voiceButtonAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _voiceButtonAnimation.value,
                child: Opacity(
                  opacity: _voiceButtonAnimation.value,
                  child: _buildVoiceButton(),
                ),
              );
            },
          ),

        // Send button
        AnimatedBuilder(
          animation: _sendButtonAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _sendButtonAnimation.value,
              child: Opacity(
                opacity: _sendButtonAnimation.value,
                child: _buildSendButton(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSendButton() {
    return ShadButton.raw(
      onPressed: _hasText ? _sendMessage : null,
      variant: ShadButtonVariant.secondary,
      size: ShadButtonSize.sm,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.send, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildVoiceButton() {
    return GestureDetector(
      onLongPressStart: (_) => _startRecording(),
      onLongPressEnd: (_) => _stopRecording(),
      onLongPressCancel: () => _cancelRecording(),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: _isRecording ? Colors.red : Colors.grey[600],
          shape: BoxShape.circle,
        ),
        child: Icon(
          _isRecording ? Icons.stop : Icons.mic,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  void _toggleEmojiPicker() {
    setState(() {
      _isEmojiPickerVisible = !_isEmojiPickerVisible;
    });

    if (_isEmojiPickerVisible) {
      _focusNode.unfocus();
    } else {
      _focusNode.requestFocus();
    }
  }

  void _onEmojiSelected(String emoji) {
    final text = _textController.text;
    final selection = _textController.selection;

    final newText = text.replaceRange(selection.start, selection.end, emoji);

    _textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selection.start + emoji.length,
      ),
    );
  }

  void _showAttachmentPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AttachmentPickerWidget(
        chatId: widget.chatId,
        onAttachmentsSelected: _onAttachmentsSelected,
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  void _onAttachmentsSelected(List<AttachmentResult> attachments) {
    for (final attachment in attachments) {
      _sendAttachmentMessage(attachment);
    }
  }

  Future<void> _sendAttachmentMessage(AttachmentResult attachment) async {
    try {
      MessageType messageType;
      String content = '';
      Map<String, dynamic>? metadata;

      switch (attachment.type) {
        case AttachmentType.image:
          messageType = MessageType.image;
          content = 'Photo';
          metadata = {
            'image': {
              'width': attachment.fileModel?.metadata?['width'],
              'height': attachment.fileModel?.metadata?['height'],
              'size': attachment.size,
            },
          };
          break;
        case AttachmentType.video:
          messageType = MessageType.video;
          content = 'Video';
          metadata = {
            'video': {
              'duration': attachment.fileModel?.metadata?['duration'],
              'size': attachment.size,
            },
          };
          break;
        case AttachmentType.audio:
          messageType = MessageType.audio;
          content = 'Audio';
          metadata = {
            'audio': {
              'duration': attachment.fileModel?.metadata?['duration'],
              'size': attachment.size,
            },
          };
          break;
        case AttachmentType.document:
          messageType = MessageType.document;
          content = attachment.name;
          metadata = {
            'document': {
              'fileName': attachment.name,
              'size': attachment.size,
              'mimeType': attachment.fileModel?.mimeType,
            },
          };
          break;
        case AttachmentType.location:
          messageType = MessageType.location;
          content = 'Location';
          metadata = {
            'location': {
              'latitude': attachment.location?.latitude,
              'longitude': attachment.location?.longitude,
              'address': attachment.location?.address,
            },
          };
          break;
        case AttachmentType.contact:
          messageType = MessageType.contact;
          content = 'Contact';
          metadata = {
            'contact': {
              'name': attachment.contact?.name,
              'phoneNumber': attachment.contact?.phoneNumber,
              'email': attachment.contact?.email,
            },
          };
          break;
        default:
          messageType = MessageType.document;
          content = attachment.name;
      }

      final message = await ref
          .read(messageProvider(widget.chatId).notifier)
          .sendMessage(
            content: content,
            type: messageType,
            replyToId: widget.replyToMessage?.id,
            metadata: metadata,
          );

      widget.onMessageSent?.call(message);
    } catch (e) {
      _showError('Failed to send attachment: $e');
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    // Clear input immediately for better UX
    _textController.clear();
    ref.read(typingProvider.notifier).stopTyping(widget.chatId);

    try {
      final message = await ref
          .read(messageProvider(widget.chatId).notifier)
          .sendMessage(
            content: text,
            type: MessageType.text,
            replyToId: widget.replyToMessage?.id,
          );

      widget.onMessageSent?.call(message);

      if (widget.replyToMessage != null) {
        widget.onReplyCancel?.call();
      }
    } catch (e) {
      // Restore text on error
      _textController.text = text;
      _showError('Failed to send message: $e');
    }
  }

  Future<void> _startRecording() async {
    try {
      final permission = await Permission.microphone.request();
      if (!permission.isGranted) {
        _showError('Microphone permission required');
        return;
      }

      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
      });

      // Start recording
      final path = await _audioRecorder!.start();
      _recordingPath = path;

      // Start timer
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingDuration = Duration(seconds: timer.tick);
        });
      });

      // Haptic feedback
      HapticFeedback.lightImpact();
    } catch (e) {
      _showError('Failed to start recording: $e');
      setState(() {
        _isRecording = false;
      });
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    try {
      final path = await _audioRecorder!.stop();
      _recordingTimer?.cancel();

      setState(() {
        _isRecording = false;
      });

      if (path != null && _recordingDuration.inSeconds >= 1) {
        await _sendVoiceMessage(path, _recordingDuration);
      } else {
        _showError('Recording too short');
      }

      HapticFeedback.lightImpact();
    } catch (e) {
      _showError('Failed to stop recording: $e');
      setState(() {
        _isRecording = false;
      });
    }
  }

  void _cancelRecording() {
    if (!_isRecording) return;

    _audioRecorder!.stop();
    _recordingTimer?.cancel();

    setState(() {
      _isRecording = false;
    });

    if (_recordingPath != null) {
      try {
        File(_recordingPath!).deleteSync();
      } catch (e) {
        // Handle error silently
      }
    }

    HapticFeedback.lightImpact();
  }

  Future<void> _sendVoiceMessage(String path, Duration duration) async {
    try {
      // Upload voice note
      final response = await ref
          .read(apiServiceProvider)
          .uploadFile(
            file: File(path),
            purpose: 'voice_note',
            chatId: widget.chatId,
          );

      if (response.success && response.data != null) {
        final fileModel = response.data!;

        final message = await ref
            .read(messageProvider(widget.chatId).notifier)
            .sendMessage(
              content: 'Voice message',
              type: MessageType.voiceNote,
              replyToId: widget.replyToMessage?.id,
              metadata: {
                'voice_note': {
                  'duration': duration.inSeconds,
                  'file_url': fileModel.url,
                  'file_size': fileModel.size,
                },
              },
            );

        widget.onMessageSent?.call(message);

        if (widget.replyToMessage != null) {
          widget.onReplyCancel?.call();
        }
      }

      // Clean up local file
      try {
        File(path).deleteSync();
      } catch (e) {
        // Handle error silently
      }
    } catch (e) {
      _showError('Failed to send voice message: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}

// Voice recording indicator widget
class VoiceRecordingIndicator extends StatefulWidget {
  final Duration duration;
  final VoidCallback? onCancel;

  const VoiceRecordingIndicator({
    super.key,
    required this.duration,
    this.onCancel,
  });

  @override
  State<VoiceRecordingIndicator> createState() =>
      _VoiceRecordingIndicatorState();
}

class _VoiceRecordingIndicatorState extends State<VoiceRecordingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),

          const SizedBox(width: 8),

          Text(
            'Recording ${_formatDuration(widget.duration)}',
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),

          const Spacer(),

          if (widget.onCancel != null)
            ShadButton.raw(
              onPressed: widget.onCancel,
              variant: ShadButtonVariant.ghost,
              size: ShadButtonSize.sm,
              child: const Icon(Icons.close, color: Colors.red, size: 16),
            ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
}

// Draft message indicator
class DraftMessageIndicator extends StatelessWidget {
  final String draftText;
  final VoidCallback? onClear;

  const DraftMessageIndicator({
    super.key,
    required this.draftText,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.edit, size: 16, color: Colors.orange),
          const SizedBox(width: 6),
          const Text(
            'Draft: ',
            style: TextStyle(
              fontSize: 12,
              color: Colors.orange,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              draftText,
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onClear != null)
            ShadButton.raw(
              onPressed: onClear,
              variant: ShadButtonVariant.ghost,
              size: ShadButtonSize.sm,
              child: const Icon(Icons.close, size: 14, color: Colors.orange),
            ),
        ],
      ),
    );
  }
}
