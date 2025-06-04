import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../providers/call/call_provider.dart';
import '../../providers/call/webrtc_provider.dart';
import '../../models/call/call_model.dart';

class CallControlsWidget extends ConsumerStatefulWidget {
  final CallModel? call;
  final VoidCallback? onEndCall;
  final VoidCallback? onMinimize;
  final bool isMinimized;
  final bool showMinimize;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;

  const CallControlsWidget({
    super.key,
    this.call,
    this.onEndCall,
    this.onMinimize,
    this.isMinimized = false,
    this.showMinimize = true,
    this.padding,
    this.backgroundColor,
    this.borderRadius,
  });

  @override
  ConsumerState<CallControlsWidget> createState() => _CallControlsWidgetState();
}

class _CallControlsWidgetState extends ConsumerState<CallControlsWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(begin: Offset.zero, end: const Offset(0, 1))
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeInOut),
        );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _toggleAudio() {
    ref.read(callProvider.notifier).toggleAudio();
  }

  void _toggleVideo() {
    ref.read(callProvider.notifier).toggleVideo();
  }

  void _toggleSpeaker() {
    ref.read(callProvider.notifier).toggleSpeaker();
  }

  void _switchCamera() {
    ref.read(callProvider.notifier).switchCamera();
  }

  void _toggleScreenShare() {
    final webrtcState = ref.read(webrtcProvider);
    if (webrtcState.mediaState.screenSharing) {
      ref.read(callProvider.notifier).stopScreenShare();
    } else {
      ref.read(callProvider.notifier).startScreenShare();
    }
  }

  void _endCall() {
    ref.read(callProvider.notifier).endCall();
    widget.onEndCall?.call();
  }

  void _showMoreOptions() {
    showShadSheet(
      context: context,
      builder: (context) => ShadSheet(
        title: const Text('Call Options'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSheetOption(
              icon: Icons.record_voice_over,
              title: 'Record Call',
              subtitle: 'Start recording this call',
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement call recording
              },
            ),
            _buildSheetOption(
              icon: Icons.person_add,
              title: 'Add Participant',
              subtitle: 'Invite someone to join',
              onTap: () {
                Navigator.pop(context);
                // TODO: Show add participant dialog
              },
            ),
            _buildSheetOption(
              icon: Icons.settings,
              title: 'Call Settings',
              subtitle: 'Adjust call preferences',
              onTap: () {
                Navigator.pop(context);
                // TODO: Show call settings
              },
            ),
            _buildSheetOption(
              icon: Icons.report_problem,
              title: 'Report Issue',
              subtitle: 'Report call quality issues',
              onTap: () {
                Navigator.pop(context);
                // TODO: Show report dialog
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSheetOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ShadButton.ghost(
      onPressed: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final webrtcState = ref.watch(webrtcProvider);
    final callState = ref.watch(callProvider);
    final isVideoCall = ref.watch(isVideoCallProvider);

    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return SlideTransition(
          position: widget.isMinimized
              ? _slideAnimation
              : const AlwaysStoppedAnimation(Offset.zero),
          child: Container(
            padding: widget.padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.backgroundColor ?? Colors.black87,
              borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: widget.isMinimized
                ? _buildMinimizedControls(webrtcState)
                : _buildFullControls(webrtcState, isVideoCall),
          ),
        );
      },
    );
  }

  Widget _buildMinimizedControls(WebRTCState webrtcState) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildControlButton(
          icon: webrtcState.mediaState.audioEnabled ? Icons.mic : Icons.mic_off,
          isActive: webrtcState.mediaState.audioEnabled,
          onPressed: _toggleAudio,
          size: 32,
        ),
        _buildControlButton(
          icon: Icons.call_end,
          isActive: false,
          onPressed: _endCall,
          size: 32,
          backgroundColor: Colors.red,
          isPulse: true,
        ),
        if (widget.showMinimize)
          _buildControlButton(
            icon: Icons.expand_less,
            isActive: false,
            onPressed: widget.onMinimize!,
            size: 32,
          ),
      ],
    );
  }

  Widget _buildFullControls(WebRTCState webrtcState, bool isVideoCall) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Primary controls row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Audio toggle
            _buildControlButton(
              icon: webrtcState.mediaState.audioEnabled
                  ? Icons.mic
                  : Icons.mic_off,
              label: webrtcState.mediaState.audioEnabled ? 'Mute' : 'Unmute',
              isActive: webrtcState.mediaState.audioEnabled,
              onPressed: _toggleAudio,
            ),

            // Video toggle (if video call)
            if (isVideoCall)
              _buildControlButton(
                icon: webrtcState.mediaState.videoEnabled
                    ? Icons.videocam
                    : Icons.videocam_off,
                label: webrtcState.mediaState.videoEnabled
                    ? 'Video Off'
                    : 'Video On',
                isActive: webrtcState.mediaState.videoEnabled,
                onPressed: _toggleVideo,
              ),

            // Speaker toggle
            _buildControlButton(
              icon: webrtcState.mediaState.speakerEnabled
                  ? Icons.volume_up
                  : Icons.volume_down,
              label: webrtcState.mediaState.speakerEnabled
                  ? 'Speaker'
                  : 'Earpiece',
              isActive: webrtcState.mediaState.speakerEnabled,
              onPressed: _toggleSpeaker,
            ),

            // End call
            _buildControlButton(
              icon: Icons.call_end,
              label: 'End Call',
              isActive: false,
              onPressed: _endCall,
              backgroundColor: Colors.red,
              isPulse: true,
            ),
          ],
        ),

        // Secondary controls row (if video call)
        if (isVideoCall) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Camera switch
              if (webrtcState.mediaState.videoEnabled)
                _buildControlButton(
                  icon: Icons.cameraswitch,
                  label: 'Flip',
                  isActive: false,
                  onPressed: _switchCamera,
                  size: 40,
                ),

              // Screen share
              _buildControlButton(
                icon: webrtcState.mediaState.screenSharing
                    ? Icons.stop_screen_share
                    : Icons.screen_share,
                label: webrtcState.mediaState.screenSharing
                    ? 'Stop Share'
                    : 'Share',
                isActive: webrtcState.mediaState.screenSharing,
                onPressed: _toggleScreenShare,
                size: 40,
              ),

              // More options
              _buildControlButton(
                icon: Icons.more_horiz,
                label: 'More',
                isActive: false,
                onPressed: _showMoreOptions,
                size: 40,
              ),

              // Minimize (if available)
              if (widget.showMinimize)
                _buildControlButton(
                  icon: Icons.expand_more,
                  label: 'Minimize',
                  isActive: false,
                  onPressed: widget.onMinimize!,
                  size: 40,
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    String? label,
    required bool isActive,
    required VoidCallback onPressed,
    Color? backgroundColor,
    double size = 48,
    bool isPulse = false,
  }) {
    final effectiveBackgroundColor =
        backgroundColor ?? (isActive ? Colors.white : Colors.white24);
    final iconColor = backgroundColor == Colors.red
        ? Colors.white
        : (isActive ? Colors.black : Colors.white);

    Widget button = ShadButton.ghost(
      onPressed: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: effectiveBackgroundColor,
          shape: BoxShape.circle,
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Icon(icon, color: iconColor, size: size * 0.4),
      ),
    );

    if (isPulse) {
      button = AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(scale: _pulseAnimation.value, child: button);
        },
      );
    }

    if (label != null && !widget.isMinimized) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          button,
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    return button;
  }
}

// Quick action buttons for incoming calls
class IncomingCallControls extends ConsumerWidget {
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback? onAcceptVideo;
  final bool isVideoCall;

  const IncomingCallControls({
    super.key,
    required this.onAccept,
    required this.onDecline,
    this.onAcceptVideo,
    this.isVideoCall = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Decline button
          _buildActionButton(
            icon: Icons.call_end,
            backgroundColor: Colors.red,
            onPressed: onDecline,
            label: 'Decline',
          ),

          // Accept video button (if video call)
          if (isVideoCall && onAcceptVideo != null)
            _buildActionButton(
              icon: Icons.videocam,
              backgroundColor: Colors.blue,
              onPressed: onAcceptVideo!,
              label: 'Video',
            ),

          // Accept audio button
          _buildActionButton(
            icon: Icons.phone,
            backgroundColor: Colors.green,
            onPressed: onAccept,
            label: isVideoCall ? 'Audio' : 'Accept',
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color backgroundColor,
    required VoidCallback onPressed,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ShadButton.ghost(
          onPressed: onPressed,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: backgroundColor.withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// Compact controls for picture-in-picture mode
class PipCallControls extends ConsumerWidget {
  final VoidCallback? onToggleAudio;
  final VoidCallback? onEndCall;
  final VoidCallback? onExpand;

  const PipCallControls({
    super.key,
    this.onToggleAudio,
    this.onEndCall,
    this.onExpand,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final webrtcState = ref.watch(webrtcProvider);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPipButton(
            icon: webrtcState.mediaState.audioEnabled
                ? Icons.mic
                : Icons.mic_off,
            onPressed: onToggleAudio,
            isActive: webrtcState.mediaState.audioEnabled,
          ),
          const SizedBox(width: 8),
          _buildPipButton(
            icon: Icons.call_end,
            onPressed: onEndCall,
            backgroundColor: Colors.red,
          ),
          const SizedBox(width: 8),
          _buildPipButton(icon: Icons.open_in_full, onPressed: onExpand),
        ],
      ),
    );
  }

  Widget _buildPipButton({
    required IconData icon,
    VoidCallback? onPressed,
    bool isActive = false,
    Color? backgroundColor,
  }) {
    return ShadButton.ghost(
      onPressed: onPressed,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: backgroundColor ?? (isActive ? Colors.white : Colors.white24),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: backgroundColor == Colors.red
              ? Colors.white
              : (isActive ? Colors.black : Colors.white),
          size: 16,
        ),
      ),
    );
  }
}
