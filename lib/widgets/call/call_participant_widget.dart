import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/call/call_participant.dart';
import '../../models/call/call_model.dart';
import '../../providers/call/call_provider.dart';
import '../common/custom_badge.dart';

enum CallParticipantSize { small, medium, large, fullscreen }

class CallParticipantWidget extends ConsumerStatefulWidget {
  final CallParticipant participant;
  final CallParticipantSize size;
  final bool showControls;
  final bool isLocalParticipant;
  final MediaStream? videoStream;
  final MediaStream? audioStream;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final bool showNetworkQuality;
  final bool showSpeakingIndicator;
  final bool enablePinchToZoom;

  const CallParticipantWidget({
    super.key,
    required this.participant,
    this.size = CallParticipantSize.medium,
    this.showControls = true,
    this.isLocalParticipant = false,
    this.videoStream,
    this.audioStream,
    this.onTap,
    this.onDoubleTap,
    this.showNetworkQuality = true,
    this.showSpeakingIndicator = true,
    this.enablePinchToZoom = false,
  });

  @override
  ConsumerState<CallParticipantWidget> createState() =>
      _CallParticipantWidgetState();
}

class _CallParticipantWidgetState extends ConsumerState<CallParticipantWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _speakingController;
  late Animation<double> _speakingAnimation;
  late Animation<Color?> _borderColorAnimation;

  bool _isSpeaking = false;
  bool _isHovered = false;
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _updateSpeakingState();
  }

  void _initializeAnimations() {
    _speakingController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _speakingAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _speakingController, curve: Curves.easeInOut),
    );

    _borderColorAnimation =
        ColorTween(begin: Colors.transparent, end: Colors.green).animate(
          CurvedAnimation(parent: _speakingController, curve: Curves.easeInOut),
        );
  }

  @override
  void didUpdateWidget(CallParticipantWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.participant.userId != widget.participant.userId) {
      _updateSpeakingState();
    }
  }

  @override
  void dispose() {
    _speakingController.dispose();
    super.dispose();
  }

  void _updateSpeakingState() {
    // Simulate speaking detection - in real implementation,
    // this would be based on audio levels from the media stream
    final wasSpeaking = _isSpeaking;
    _isSpeaking = _detectSpeaking();

    if (_isSpeaking != wasSpeaking) {
      if (_isSpeaking) {
        _speakingController.repeat(reverse: true);
      } else {
        _speakingController.stop();
        _speakingController.reset();
      }
    }
  }

  bool _detectSpeaking() {
    // In a real implementation, this would analyze audio levels
    // For now, we'll use a simple simulation
    return widget.audioStream != null &&
        !widget.participant.isMuted &&
        Random().nextDouble() > 0.7;
  }

  @override
  Widget build(BuildContext context) {
    final dimensions = _getParticipantDimensions();

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onDoubleTap: widget.onDoubleTap,
        onScaleStart: widget.enablePinchToZoom ? (details) {} : null,
        onScaleUpdate: widget.enablePinchToZoom
            ? (details) =>
                  setState(() => _scale = details.scale.clamp(1.0, 3.0))
            : null,
        child: AnimatedBuilder(
          animation: _speakingAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: widget.showSpeakingIndicator && _isSpeaking
                  ? _speakingAnimation.value
                  : 1.0,
              child: Container(
                width: dimensions.width,
                height: dimensions.height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_getBorderRadius()),
                  border: Border.all(
                    color: widget.showSpeakingIndicator && _isSpeaking
                        ? _borderColorAnimation.value ?? Colors.transparent
                        : _getStatusBorderColor(),
                    width: _isSpeaking ? 3.0 : 2.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(_getBorderRadius() - 2),
                  child: Stack(
                    children: [
                      // Video or Avatar Background
                      _buildVideoOrAvatar(),

                      // Status Overlays
                      _buildStatusOverlays(),

                      // Controls Overlay
                      if (widget.showControls && _isHovered)
                        _buildControlsOverlay(),

                      // Participant Info
                      _buildParticipantInfo(),

                      // Network Quality Indicator
                      if (widget.showNetworkQuality)
                        _buildNetworkQualityIndicator(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildVideoOrAvatar() {
    if (widget.participant.isVideoEnabled && widget.videoStream != null) {
      return Transform.scale(
        scale: _scale,
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: RTCVideoView(
            widget.videoStream!.getVideoTracks().first as RTCVideoRenderer,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            mirror: widget.isLocalParticipant,
          ),
        ),
      );
    }

    return _buildAvatarBackground();
  }

  Widget _buildAvatarBackground() {
    final dimensions = _getParticipantDimensions();
    final avatarSize = min(dimensions.width, dimensions.height) * 0.4;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getParticipantColor().withOpacity(0.8),
            _getParticipantColor().withOpacity(0.6),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Avatar
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: ClipOval(
                child: widget.participant.avatar != null
                    ? CachedNetworkImage(
                        imageUrl: widget.participant.avatar!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            _buildInitialsAvatar(avatarSize),
                        errorWidget: (context, url, error) =>
                            _buildInitialsAvatar(avatarSize),
                      )
                    : _buildInitialsAvatar(avatarSize),
              ),
            ),

            // Name (for larger sizes)
            if (widget.size != CallParticipantSize.small) ...[
              const SizedBox(height: 8),
              Text(
                widget.participant.name,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: _getNameFontSize(),
                  fontWeight: FontWeight.w600,
                  shadows: [
                    Shadow(color: Colors.black.withOpacity(0.8), blurRadius: 4),
                  ],
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInitialsAvatar(double size) {
    return Container(
      width: size,
      height: size,
      color: _getParticipantColor(),
      child: Center(
        child: Text(
          _getInitials(widget.participant.name),
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusOverlays() {
    return Stack(
      children: [
        // Muted Indicator
        if (widget.participant.isMuted)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mic_off, color: Colors.white, size: 16),
            ),
          ),

        // Screen Sharing Indicator
        if (widget.participant.isScreenSharing)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.screen_share,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),

        // Connection Status
        if (widget.participant.status != ParticipantStatus.connected)
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor().withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getStatusText(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildControlsOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.5)),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Pin participant
              _buildQuickAction(
                icon: Icons.push_pin,
                onPressed: () => _pinParticipant(),
                tooltip: 'Pin participant',
              ),

              // Mute/Unmute (for moderators)
              if (_canModerateParticipant())
                _buildQuickAction(
                  icon: widget.participant.isMuted ? Icons.mic : Icons.mic_off,
                  onPressed: () => _toggleParticipantMute(),
                  tooltip: widget.participant.isMuted ? 'Unmute' : 'Mute',
                ),

              // More options
              _buildQuickAction(
                icon: Icons.more_vert,
                onPressed: () => _showParticipantOptions(),
                tooltip: 'More options',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: ShadButton.ghost(
        onPressed: onPressed,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _buildParticipantInfo() {
    if (widget.size == CallParticipantSize.small) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 8,
      left: 8,
      right: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.participant.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            if (widget.isLocalParticipant) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'You',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkQualityIndicator() {
    final quality = widget.participant.quality;
    if (quality == null) return const SizedBox.shrink();

    return Positioned(
      top: 8,
      right: 8,
      child: CustomBadge(
        color: _getQualityColor(quality.qualityScore),
        size: BadgeSize.small,
      ),
    );
  }

  Size _getParticipantDimensions() {
    switch (widget.size) {
      case CallParticipantSize.small:
        return const Size(80, 80);
      case CallParticipantSize.medium:
        return const Size(150, 200);
      case CallParticipantSize.large:
        return const Size(200, 300);
      case CallParticipantSize.fullscreen:
        return Size(
          MediaQuery.of(context).size.width,
          MediaQuery.of(context).size.height,
        );
    }
  }

  double _getBorderRadius() {
    switch (widget.size) {
      case CallParticipantSize.small:
        return 8;
      case CallParticipantSize.medium:
        return 12;
      case CallParticipantSize.large:
        return 16;
      case CallParticipantSize.fullscreen:
        return 0;
    }
  }

  double _getNameFontSize() {
    switch (widget.size) {
      case CallParticipantSize.small:
        return 10;
      case CallParticipantSize.medium:
        return 14;
      case CallParticipantSize.large:
        return 16;
      case CallParticipantSize.fullscreen:
        return 20;
    }
  }

  Color _getParticipantColor() {
    // Generate a consistent color based on user ID
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
    ];

    final hash = widget.participant.userId.hashCode;
    return colors[hash.abs() % colors.length];
  }

  Color _getStatusBorderColor() {
    switch (widget.participant.status) {
      case ParticipantStatus.connected:
        return Colors.green;
      case ParticipantStatus.connecting:
        return Colors.orange;
      case ParticipantStatus.disconnected:
        return Colors.red;
      case ParticipantStatus.ringing:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor() {
    switch (widget.participant.status) {
      case ParticipantStatus.connecting:
        return Colors.orange;
      case ParticipantStatus.disconnected:
        return Colors.red;
      case ParticipantStatus.ringing:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText() {
    switch (widget.participant.status) {
      case ParticipantStatus.invited:
        return 'Invited';
      case ParticipantStatus.ringing:
        return 'Ringing';
      case ParticipantStatus.connecting:
        return 'Connecting';
      case ParticipantStatus.connected:
        return 'Connected';
      case ParticipantStatus.disconnected:
        return 'Disconnected';
      case ParticipantStatus.left:
        return 'Left';
      case ParticipantStatus.muted:
        return 'muted';
    }
  }

  IconData _getQualityIcon(double qualityScore) {
    if (qualityScore >= 4.0) return Icons.signal_cellular_4_bar;
    if (qualityScore >= 3.0) return Icons.signal_cellular_alt_2_bar;
    if (qualityScore >= 2.0) return Icons.signal_cellular_alt_2_bar;
    if (qualityScore >= 1.0) return Icons.signal_cellular_alt_1_bar;
    return Icons.signal_wifi_0_bar;
  }

  Color _getQualityColor(double qualityScore) {
    if (qualityScore >= 4.0) return Colors.green;
    if (qualityScore >= 3.0) return Colors.orange;
    if (qualityScore >= 2.0) return Colors.red;
    return Colors.grey;
  }

  String _getInitials(String name) {
    final words = name.trim().split(' ');
    if (words.isEmpty) return '';

    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    } else {
      return (words[0].substring(0, 1) + words[1].substring(0, 1))
          .toUpperCase();
    }
  }

  bool _canModerateParticipant() {
    // Check if current user has moderation permissions
    // This would be determined by your app's permission system
    return false; // Placeholder
  }

  void _pinParticipant() {
    // Implementation for pinning participant
  }

  void _toggleParticipantMute() {
    // Implementation for muting/unmuting participant
  }

  void _showParticipantOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _ParticipantOptionsSheet(
        participant: widget.participant,
        isLocalParticipant: widget.isLocalParticipant,
      ),
    );
  }
}

class _ParticipantOptionsSheet extends ConsumerWidget {
  final CallParticipant participant;
  final bool isLocalParticipant;

  const _ParticipantOptionsSheet({
    required this.participant,
    required this.isLocalParticipant,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

          ListTile(
            leading: CircleAvatar(
              backgroundImage: participant.avatar != null
                  ? CachedNetworkImageProvider(participant.avatar!)
                  : null,
              child: participant.avatar == null
                  ? Text(_getInitials(participant.name))
                  : null,
            ),
            title: Text(participant.name),
            subtitle: Text(_getStatusText()),
          ),

          const Divider(),

          if (!isLocalParticipant) ...[
            _buildOption(
              icon: Icons.message,
              title: 'Send private message',
              onTap: () => _sendPrivateMessage(context),
            ),

            _buildOption(
              icon: Icons.person,
              title: 'View profile',
              onTap: () => _viewProfile(context),
            ),
          ],

          _buildOption(
            icon: Icons.volume_off,
            title: 'Mute for me',
            onTap: () => _muteForMe(context),
          ),

          if (_canModerate()) ...[
            const Divider(),

            _buildOption(
              icon: participant.isMuted ? Icons.mic : Icons.mic_off,
              title: participant.isMuted
                  ? 'Unmute participant'
                  : 'Mute participant',
              onTap: () => _toggleMute(context),
            ),

            _buildOption(
              icon: Icons.videocam_off,
              title: 'Disable video',
              onTap: () => _disableVideo(context),
            ),

            _buildOption(
              icon: Icons.remove_circle,
              title: 'Remove from call',
              onTap: () => _removeParticipant(context),
              isDestructive: true,
            ),
          ],

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : null),
      title: Text(
        title,
        style: TextStyle(color: isDestructive ? Colors.red : null),
      ),
      onTap: onTap,
    );
  }

  String _getInitials(String name) {
    final words = name.trim().split(' ');
    if (words.isEmpty) return '';

    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    } else {
      return (words[0].substring(0, 1) + words[1].substring(0, 1))
          .toUpperCase();
    }
  }

  String _getStatusText() {
    switch (participant.status) {
      case ParticipantStatus.invited:
        return 'Invited';
      case ParticipantStatus.ringing:
        return 'Ringing';
      case ParticipantStatus.connecting:
        return 'Connecting';
      case ParticipantStatus.connected:
        return 'Connected';
      case ParticipantStatus.disconnected:
        return 'Disconnected';
      case ParticipantStatus.left:
        return 'Left call';
      case ParticipantStatus.muted:
        return 'muted';
    }
  }

  bool _canModerate() {
    // Check if current user has moderation permissions
    return false; // Placeholder
  }

  void _sendPrivateMessage(BuildContext context) {
    Navigator.pop(context);
    // Implementation
  }

  void _viewProfile(BuildContext context) {
    Navigator.pop(context);
    // Implementation
  }

  void _muteForMe(BuildContext context) {
    Navigator.pop(context);
    // Implementation
  }

  void _toggleMute(BuildContext context) {
    Navigator.pop(context);
    // Implementation
  }

  void _disableVideo(BuildContext context) {
    Navigator.pop(context);
    // Implementation
  }

  void _removeParticipant(BuildContext context) {
    Navigator.pop(context);
    // Implementation
  }
}
