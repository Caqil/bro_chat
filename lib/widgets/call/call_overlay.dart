import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../providers/call/call_provider.dart';
import '../../providers/call/webrtc_provider.dart';
import '../../models/call/call_model.dart';
import '../../models/call/call_participant.dart';
import '../common/custom_app_bar.dart';
import 'call_controls.dart';
import 'call_participant_widget.dart';
import 'call_stats_widget.dart';

class CallOverlayWidget extends ConsumerStatefulWidget {
  final bool canMinimize;
  final VoidCallback? onMinimize;
  final VoidCallback? onClose;

  const CallOverlayWidget({
    super.key,
    this.canMinimize = true,
    this.onMinimize,
    this.onClose,
  });

  @override
  ConsumerState<CallOverlayWidget> createState() => _CallOverlayWidgetState();
}

class _CallOverlayWidgetState extends ConsumerState<CallOverlayWidget>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  Timer? _hideControlsTimer;
  bool _controlsVisible = true;
  bool _isInPictureInPicture = false;

  // Gesture detection
  bool _isDragging = false;
  Offset _dragOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startHideControlsTimer();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && _controlsVisible) {
        setState(() {
          _controlsVisible = false;
        });
      }
    });
  }

  void _showControls() {
    if (!_controlsVisible) {
      setState(() {
        _controlsVisible = true;
      });
    }
    _startHideControlsTimer();
  }

  void _toggleControls() {
    setState(() {
      _controlsVisible = !_controlsVisible;
    });

    if (_controlsVisible) {
      _startHideControlsTimer();
    } else {
      _hideControlsTimer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final callState = ref.watch(callProvider);
    final webrtcState = ref.watch(webrtcProvider);

    return callState.when(
      data: (state) {
        if (!state.hasActiveCall) {
          return const SizedBox.shrink();
        }

        return _buildCallOverlay(context, state, webrtcState);
      },
      loading: () => _buildLoadingOverlay(),
      error: (error, _) => _buildErrorOverlay(error),
    );
  }

  Widget _buildCallOverlay(
    BuildContext context,
    CallProviderState callState,
    WebRTCState webrtcState,
  ) {
    final currentCall = callState.currentCall!;
    final participants = callState.participants;
    final isVideoCall = currentCall.isVideoCall;

    return Material(
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black,
                child: GestureDetector(
                  onTap: _showControls,
                  onPanStart: (details) {
                    _isDragging = true;
                    _dragOffset = details.localPosition;
                  },
                  onPanUpdate: (details) {
                    if (_isDragging) {
                      // Handle drag for picture-in-picture mode
                      setState(() {
                        _dragOffset = details.localPosition;
                      });
                    }
                  },
                  onPanEnd: (details) {
                    _isDragging = false;
                  },
                  child: Stack(
                    children: [
                      // Background/Remote Video
                      _buildVideoBackground(webrtcState, isVideoCall),

                      // Participants Grid
                      if (participants.isNotEmpty)
                        _buildParticipantsGrid(participants, currentCall),

                      // Local Video (Picture-in-Picture)
                      if (isVideoCall && webrtcState.hasLocalStream)
                        _buildLocalVideoPreview(webrtcState),

                      // Call Information Overlay
                      _buildCallInfoOverlay(callState),

                      // Top Bar with Actions
                      AnimatedOpacity(
                        opacity: _controlsVisible ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: _buildTopBar(currentCall),
                      ),

                      // Call Controls
                      AnimatedOpacity(
                        opacity: _controlsVisible ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: _buildBottomControls(currentCall),
                      ),

                      // Call Stats (when enabled)
                      if (_controlsVisible && callState.currentQuality != null)
                        Positioned(
                          top: 100,
                          right: 16,
                          child: CallStatsWidget(
                            quality: callState.currentQuality!,
                            compact: true,
                          ),
                        ),

                      // Screen Share Indicator
                      if (webrtcState.mediaState.screenSharing)
                        _buildScreenShareIndicator(),

                      // Recording Indicator
                      if (currentCall.isRecording) _buildRecordingIndicator(),

                      // Connection Status
                      _buildConnectionStatus(webrtcState.connectionState),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVideoBackground(WebRTCState webrtcState, bool isVideoCall) {
    if (!isVideoCall || !webrtcState.hasRemoteStream) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1a1a1a), Color(0xFF000000)],
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: RTCVideoView(
        webrtcState.mediaState.remoteStream!.getVideoTracks().first
            as RTCVideoRenderer,
        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
      ),
    );
  }

  Widget _buildParticipantsGrid(
    List<CallParticipant> participants,
    CallModel currentCall,
  ) {
    if (participants.isEmpty) return const SizedBox.shrink();

    // For small number of participants, use a simple layout
    if (participants.length <= 2) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: participants.map((participant) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: CallParticipantWidget(
                participant: participant,
                size: CallParticipantSize.large,
                showControls: _controlsVisible,
              ),
            );
          }).toList(),
        ),
      );
    }

    // For more participants, use a grid layout
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: participants.length <= 4 ? 2 : 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: participants.length,
        itemBuilder: (context, index) {
          return CallParticipantWidget(
            participant: participants[index],
            size: CallParticipantSize.medium,
            showControls: _controlsVisible,
          );
        },
      ),
    );
  }

  Widget _buildLocalVideoPreview(WebRTCState webrtcState) {
    return Positioned(
      top: 100,
      right: 16,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: _isInPictureInPicture ? 100 : 150,
        height: _isInPictureInPicture ? 150 : 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: webrtcState.hasLocalStream
              ? RTCVideoView(
                  webrtcState.mediaState.localStream!.getVideoTracks().first
                      as RTCVideoRenderer,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  mirror: true,
                )
              : Container(
                  color: Colors.grey[800],
                  child: const Center(
                    child: Icon(
                      Icons.videocam_off,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildCallInfoOverlay(CallProviderState callState) {
    final currentCall = callState.currentCall!;
    final duration = callState.callDuration;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 60,
      left: 16,
      right: 16,
      child: AnimatedOpacity(
        opacity: _controlsVisible ? 1.0 : 0.7,
        duration: const Duration(milliseconds: 300),
        child: Column(
          children: [
            // Call status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(currentCall.status).withOpacity(0.8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _getStatusText(currentCall.status),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Call duration
            if (duration != null && currentCall.status == CallStatus.ongoing)
              Text(
                _formatDuration(duration),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(CallModel currentCall) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top,
          left: 16,
          right: 16,
          bottom: 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withOpacity(0.8), Colors.transparent],
          ),
        ),
        child: Row(
          children: [
            // Back/Minimize button
            ShadButton.ghost(
              onPressed: widget.canMinimize
                  ? widget.onMinimize ?? _minimizeCall
                  : widget.onClose,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.canMinimize
                      ? Icons.keyboard_arrow_down
                      : Icons.arrow_back,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),

            const Spacer(),

            // Call type indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    currentCall.isVideoCall ? Icons.videocam : Icons.phone,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    currentCall.isVideoCall ? 'Video' : 'Voice',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // More options
            ShadButton.ghost(
              onPressed: _showMoreOptions,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.more_vert,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls(CallModel currentCall) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
          top: 32,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withOpacity(0.8), Colors.transparent],
          ),
        ),
        child: CallControlsWidget(
          call: currentCall,
          isMinimized: false,
          showMinimize: widget.canMinimize,
          onEndCall: () => ref.read(callProvider.notifier).endCall(),
          onMinimize: widget.onMinimize,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          backgroundColor: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }

  Widget _buildScreenShareIndicator() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 120,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.screen_share, color: Colors.white, size: 16),
            SizedBox(width: 4),
            Text(
              'Sharing screen',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingIndicator() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 150,
      left: 16,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fiber_manual_record, color: Colors.white, size: 16),
            SizedBox(width: 4),
            Text(
              'Recording',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatus(WebRTCConnectionState connectionState) {
    if (connectionState == WebRTCConnectionState.connected) {
      return const SizedBox.shrink();
    }

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (connectionState) {
      case WebRTCConnectionState.connecting:
        statusColor = Colors.orange;
        statusText = 'Connecting...';
        statusIcon = Icons.wifi_off;
        break;
      case WebRTCConnectionState.reconnecting:
        statusColor = Colors.orange;
        statusText = 'Reconnecting...';
        statusIcon = Icons.refresh;
        break;
      case WebRTCConnectionState.failed:
        statusColor = Colors.red;
        statusText = 'Connection failed';
        statusIcon = Icons.error;
        break;
      case WebRTCConnectionState.disconnected:
        statusColor = Colors.red;
        statusText = 'Disconnected';
        statusIcon = Icons.wifi_off;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Positioned(
      top: MediaQuery.of(context).padding.top + 180,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(statusIcon, color: Colors.white, size: 16),
            const SizedBox(width: 4),
            Text(
              statusText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Connecting...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorOverlay(Object error) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text(
              'Call Error',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ShadButton.destructive(
              onPressed: () => ref.read(callProvider.notifier).endCall(),
              child: const Text('End Call'),
            ),
          ],
        ),
      ),
    );
  }

  void _minimizeCall() {
    setState(() {
      _isInPictureInPicture = true;
    });
    widget.onMinimize?.call();
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _MoreOptionsSheet(),
    );
  }

  Color _getStatusColor(CallStatus status) {
    switch (status) {
      case CallStatus.connecting:
        return Colors.orange;
      case CallStatus.ongoing:
        return Colors.green;
      case CallStatus.ringing:
        return Colors.blue;
      case CallStatus.ended:
        return Colors.grey;
      case CallStatus.failed:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(CallStatus status) {
    switch (status) {
      case CallStatus.initiating:
        return 'Starting call...';
      case CallStatus.ringing:
        return 'Ringing...';
      case CallStatus.connecting:
        return 'Connecting...';
      case CallStatus.ongoing:
        return 'In call';
      case CallStatus.ended:
        return 'Call ended';
      case CallStatus.failed:
        return 'Call failed';
      case CallStatus.missed:
        return 'Missed call';
      case CallStatus.declined:
        return 'Call declined';
      case CallStatus.busy:
        return 'Busy';
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
  }
}

class _MoreOptionsSheet extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final callState = ref.watch(callProvider);
    final callNotifier = ref.read(callProvider.notifier);

    return callState.when(
      data: (state) {
        if (!state.hasActiveCall) return const SizedBox.shrink();

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

              const Text(
                'Call Options',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              _buildOption(
                icon: Icons.person_add,
                title: 'Add participant',
                onTap: () => _addParticipant(context, callNotifier),
              ),

              _buildOption(
                icon: Icons.chat,
                title: 'Open chat',
                onTap: () => _openChat(context),
              ),

              _buildOption(
                icon: state.currentCall!.isRecording
                    ? Icons.stop
                    : Icons.fiber_manual_record,
                title: state.currentCall!.isRecording
                    ? 'Stop recording'
                    : 'Start recording',
                onTap: () => _toggleRecording(context, callNotifier),
              ),

              _buildOption(
                icon: Icons.settings,
                title: 'Call settings',
                onTap: () => _openSettings(context),
              ),

              _buildOption(
                icon: Icons.report,
                title: 'Report issue',
                onTap: () => _reportIssue(context),
              ),

              const SizedBox(height: 16),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(leading: Icon(icon), title: Text(title), onTap: onTap);
  }

  void _addParticipant(BuildContext context, CallNotifier callNotifier) {
    Navigator.pop(context);
    // Implementation for adding participants
  }

  void _openChat(BuildContext context) {
    Navigator.pop(context);
    // Implementation for opening chat
  }

  void _toggleRecording(BuildContext context, CallNotifier callNotifier) {
    Navigator.pop(context);
    // Implementation for recording
  }

  void _openSettings(BuildContext context) {
    Navigator.pop(context);
    // Implementation for call settings
  }

  void _reportIssue(BuildContext context) {
    Navigator.pop(context);
    // Implementation for reporting issues
  }
}
