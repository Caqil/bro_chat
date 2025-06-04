import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';

enum VoiceNotePlayerState {
  loading,
  ready,
  playing,
  paused,
  error,
  downloading,
}

class VoiceNotePlayerWidget extends ConsumerStatefulWidget {
  final String audioUrl;
  final Duration duration;
  final bool isFromCurrentUser;
  final bool compact;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final VoidCallback? onPlaybackStart;
  final VoidCallback? onPlaybackEnd;
  final Function(Duration)? onProgressUpdate;

  const VoiceNotePlayerWidget({
    super.key,
    required this.audioUrl,
    required this.duration,
    this.isFromCurrentUser = false,
    this.compact = false,
    this.backgroundColor,
    this.foregroundColor,
    this.onPlaybackStart,
    this.onPlaybackEnd,
    this.onProgressUpdate,
  });

  @override
  ConsumerState<VoiceNotePlayerWidget> createState() =>
      _VoiceNotePlayerWidgetState();
}

class _VoiceNotePlayerWidgetState extends ConsumerState<VoiceNotePlayerWidget>
    with TickerProviderStateMixin {
  late AudioPlayer _audioPlayer;
  late AnimationController _playButtonController;
  late AnimationController _waveformController;
  late Animation<double> _playButtonAnimation;

  VoiceNotePlayerState _playerState = VoiceNotePlayerState.loading;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  String? _localFilePath;
  double _downloadProgress = 0.0;

  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    _initializeAnimations();
    _totalDuration = widget.duration;
  }

  void _initializePlayer() {
    _audioPlayer = AudioPlayer();
    _setupPlayerSubscriptions();
    _prepareAudio();
  }

  void _initializeAnimations() {
    _playButtonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _waveformController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _playButtonAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _playButtonController, curve: Curves.easeInOut),
    );
  }

  void _setupPlayerSubscriptions() {
    _positionSubscription = _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
        widget.onProgressUpdate?.call(position);
      }
    });

    _durationSubscription = _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _totalDuration = duration;
        });
      }
    });

    _playerStateSubscription = _audioPlayer.onPlayerStateChanged.listen((
      state,
    ) {
      if (mounted) {
        switch (state) {
          case PlayerState.playing:
            _setPlayerState(VoiceNotePlayerState.playing);
            _playButtonController.forward();
            _waveformController.repeat();
            widget.onPlaybackStart?.call();
            break;
          case PlayerState.paused:
            _setPlayerState(VoiceNotePlayerState.paused);
            _playButtonController.reverse();
            _waveformController.stop();
            break;
          case PlayerState.stopped:
            _setPlayerState(VoiceNotePlayerState.ready);
            _playButtonController.reverse();
            _waveformController.stop();
            _resetPosition();
            widget.onPlaybackEnd?.call();
            break;
          case PlayerState.completed:
            _setPlayerState(VoiceNotePlayerState.ready);
            _playButtonController.reverse();
            _waveformController.stop();
            _resetPosition();
            widget.onPlaybackEnd?.call();
            break;
          default:
            break;
        }
      }
    });
  }

  Future<void> _prepareAudio() async {
    try {
      if (widget.audioUrl.startsWith('http')) {
        await _downloadAudio();
      } else {
        _localFilePath = widget.audioUrl;
        _setPlayerState(VoiceNotePlayerState.ready);
      }
    } catch (e) {
      _setPlayerState(VoiceNotePlayerState.error);
    }
  }

  Future<void> _downloadAudio() async {
    try {
      _setPlayerState(VoiceNotePlayerState.downloading);

      final directory = await getTemporaryDirectory();
      final fileName =
          'voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final filePath = '${directory.path}/$fileName';

      final dio = Dio();
      await dio.download(
        widget.audioUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _downloadProgress = received / total;
            });
          }
        },
      );

      _localFilePath = filePath;
      _setPlayerState(VoiceNotePlayerState.ready);
    } catch (e) {
      _setPlayerState(VoiceNotePlayerState.error);
    }
  }

  void _setPlayerState(VoiceNotePlayerState state) {
    if (mounted) {
      setState(() {
        _playerState = state;
      });
    }
  }

  void _resetPosition() {
    setState(() {
      _currentPosition = Duration.zero;
    });
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _audioPlayer.dispose();
    _playButtonController.dispose();
    _waveformController.dispose();

    // Clean up temporary file
    if (_localFilePath != null && _localFilePath!.contains('temp')) {
      File(_localFilePath!).delete().catchError((_) {});
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(widget.compact ? 8 : 12),
      constraints: BoxConstraints(
        minWidth: widget.compact ? 200 : 240,
        maxWidth: widget.compact ? 250 : 300,
      ),
      decoration: BoxDecoration(
        color:
            widget.backgroundColor ??
            (widget.isFromCurrentUser
                ? Colors.white.withOpacity(0.1)
                : Colors.grey[100]),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPlayerControls(),
          if (!widget.compact) ...[const SizedBox(height: 8), _buildWaveform()],
          const SizedBox(height: 4),
          _buildProgressInfo(),
        ],
      ),
    );
  }

  Widget _buildPlayerControls() {
    return Row(
      children: [
        _buildPlayButton(),
        const SizedBox(width: 12),
        Expanded(child: _buildProgressSlider()),
        const SizedBox(width: 8),
        _buildSpeedButton(),
      ],
    );
  }

  Widget _buildPlayButton() {
    final size = widget.compact ? 32.0 : 40.0;

    return GestureDetector(
      onTap: _togglePlayback,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color:
              widget.foregroundColor ??
              (widget.isFromCurrentUser ? Colors.white : Colors.blue),
          shape: BoxShape.circle,
        ),
        child: _buildPlayButtonIcon(),
      ),
    );
  }

  Widget _buildPlayButtonIcon() {
    final iconColor = widget.isFromCurrentUser ? Colors.blue : Colors.white;
    final iconSize = widget.compact ? 16.0 : 20.0;

    switch (_playerState) {
      case VoiceNotePlayerState.loading:
      case VoiceNotePlayerState.downloading:
        return _buildLoadingIcon(iconColor, iconSize);
      case VoiceNotePlayerState.error:
        return Icon(Icons.error, color: Colors.red, size: iconSize);
      case VoiceNotePlayerState.playing:
        return AnimatedBuilder(
          animation: _playButtonAnimation,
          child: Icon(Icons.pause, color: iconColor, size: iconSize),
          builder: (context, child) {
            return Transform.scale(
              scale: 0.8 + (_playButtonAnimation.value * 0.2),
              child: child,
            );
          },
        );
      default:
        return Icon(Icons.play_arrow, color: iconColor, size: iconSize);
    }
  }

  Widget _buildLoadingIcon(Color color, double size) {
    if (_playerState == VoiceNotePlayerState.downloading) {
      return Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: _downloadProgress,
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          Icon(Icons.download, color: color, size: size * 0.6),
        ],
      );
    }

    return SizedBox(
      width: size * 0.8,
      height: size * 0.8,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }

  Widget _buildProgressSlider() {
    final progress = _totalDuration.inMilliseconds > 0
        ? _currentPosition.inMilliseconds / _totalDuration.inMilliseconds
        : 0.0;

    return SliderTheme(
      data: SliderThemeData(
        thumbShape: RoundSliderThumbShape(
          enabledThumbRadius: widget.compact ? 6 : 8,
        ),
        trackHeight: widget.compact ? 2 : 3,
        activeTrackColor:
            widget.foregroundColor ??
            (widget.isFromCurrentUser ? Colors.white : Colors.blue),
        inactiveTrackColor:
            (widget.foregroundColor ??
                    (widget.isFromCurrentUser ? Colors.white : Colors.blue))
                .withOpacity(0.3),
        thumbColor:
            widget.foregroundColor ??
            (widget.isFromCurrentUser ? Colors.white : Colors.blue),
        overlayShape: RoundSliderOverlayShape(
          overlayRadius: widget.compact ? 12 : 16,
        ),
      ),
      child: Slider(
        value: progress.clamp(0.0, 1.0),
        onChanged: _onSliderChanged,
        onChangeEnd: _onSliderChangeEnd,
      ),
    );
  }

  Widget _buildSpeedButton() {
    return ShadButton.ghost(
      onPressed: _showSpeedOptions,
      size: widget.compact ? ShadButtonSize.sm : ShadButtonSize.regular,
      child: Text(
        '1x',
        style: TextStyle(
          fontSize: widget.compact ? 10 : 12,
          color:
              widget.foregroundColor ??
              (widget.isFromCurrentUser ? Colors.white : Colors.grey[600]),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildWaveform() {
    return Container(
      height: 40,
      child: AnimatedBuilder(
        animation: _waveformController,
        builder: (context, child) {
          return CustomPaint(
            painter: WaveformPainter(
              progress: _totalDuration.inMilliseconds > 0
                  ? _currentPosition.inMilliseconds /
                        _totalDuration.inMilliseconds
                  : 0.0,
              isPlaying: _playerState == VoiceNotePlayerState.playing,
              animationValue: _waveformController.value,
              color:
                  widget.foregroundColor ??
                  (widget.isFromCurrentUser ? Colors.white : Colors.blue),
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }

  Widget _buildProgressInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _formatDuration(_currentPosition),
          style: TextStyle(
            fontSize: widget.compact ? 10 : 11,
            color:
                widget.foregroundColor ??
                (widget.isFromCurrentUser ? Colors.white70 : Colors.grey[600]),
          ),
        ),
        Text(
          _formatDuration(_totalDuration),
          style: TextStyle(
            fontSize: widget.compact ? 10 : 11,
            color:
                widget.foregroundColor ??
                (widget.isFromCurrentUser ? Colors.white70 : Colors.grey[600]),
          ),
        ),
      ],
    );
  }

  void _togglePlayback() async {
    if (_playerState == VoiceNotePlayerState.error ||
        _playerState == VoiceNotePlayerState.loading ||
        _playerState == VoiceNotePlayerState.downloading) {
      return;
    }

    try {
      if (_playerState == VoiceNotePlayerState.playing) {
        await _audioPlayer.pause();
      } else {
        if (_localFilePath != null) {
          await _audioPlayer.play(DeviceFileSource(_localFilePath!));
        }
      }
    } catch (e) {
      _setPlayerState(VoiceNotePlayerState.error);
    }
  }

  void _onSliderChanged(double value) {
    final position = Duration(
      milliseconds: (value * _totalDuration.inMilliseconds).round(),
    );
    setState(() {
      _currentPosition = position;
    });
  }

  void _onSliderChangeEnd(double value) async {
    final position = Duration(
      milliseconds: (value * _totalDuration.inMilliseconds).round(),
    );
    await _audioPlayer.seek(position);
  }

  void _showSpeedOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _SpeedOptionsSheet(
        currentSpeed: 1.0,
        onSpeedSelected: _setPlaybackSpeed,
      ),
    );
  }

  void _setPlaybackSpeed(double speed) async {
    await _audioPlayer.setPlaybackRate(speed);
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
}

// Speed options sheet
class _SpeedOptionsSheet extends StatelessWidget {
  final double currentSpeed;
  final ValueChanged<double> onSpeedSelected;

  const _SpeedOptionsSheet({
    required this.currentSpeed,
    required this.onSpeedSelected,
  });

  @override
  Widget build(BuildContext context) {
    const speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

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
            'Playback Speed',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 16),

          for (final speed in speeds)
            ListTile(
              title: Text('${speed}x'),
              trailing: currentSpeed == speed
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              onTap: () {
                onSpeedSelected(speed);
                Navigator.pop(context);
              },
            ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// Waveform painter
class WaveformPainter extends CustomPainter {
  final double progress;
  final bool isPlaying;
  final double animationValue;
  final Color color;

  WaveformPainter({
    required this.progress,
    required this.isPlaying,
    required this.animationValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final activePaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const barCount = 30;
    final barWidth = size.width / barCount;
    final progressPosition = progress * size.width;

    for (int i = 0; i < barCount; i++) {
      final x = i * barWidth + barWidth / 2;

      // Generate pseudo-random height based on index
      final baseHeight = (i % 3 + 1) * size.height / 6;
      final animatedHeight = isPlaying
          ? baseHeight *
                (0.5 + 0.5 * (1 + animationValue * (i % 2 == 0 ? 1 : -1)))
          : baseHeight;

      final height = animatedHeight.clamp(size.height * 0.1, size.height * 0.8);

      final y1 = (size.height - height) / 2;
      final y2 = y1 + height;

      final currentPaint = x <= progressPosition ? activePaint : paint;

      canvas.drawLine(Offset(x, y1), Offset(x, y2), currentPaint);
    }
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isPlaying != isPlaying ||
        oldDelegate.animationValue != animationValue;
  }
}

// Compact voice note player for list items
class CompactVoiceNotePlayer extends ConsumerWidget {
  final String audioUrl;
  final Duration duration;
  final bool isFromCurrentUser;

  const CompactVoiceNotePlayer({
    super.key,
    required this.audioUrl,
    required this.duration,
    this.isFromCurrentUser = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return VoiceNotePlayerWidget(
      audioUrl: audioUrl,
      duration: duration,
      isFromCurrentUser: isFromCurrentUser,
      compact: true,
    );
  }
}

// Voice note player provider for managing global playback state
final voiceNotePlayerProvider =
    StateNotifierProvider.family<
      VoiceNotePlayerNotifier,
      VoiceNotePlayerState,
      String
    >((ref, audioUrl) {
      return VoiceNotePlayerNotifier(audioUrl);
    });

class VoiceNotePlayerNotifier extends StateNotifier<VoiceNotePlayerState> {
  final String audioUrl;
  late AudioPlayer _audioPlayer;

  VoiceNotePlayerNotifier(this.audioUrl) : super(VoiceNotePlayerState.loading) {
    _initializePlayer();
  }

  void _initializePlayer() {
    _audioPlayer = AudioPlayer();
    // Initialize the audio player
  }

  Future<void> play() async {
    // Implementation for play
  }

  Future<void> pause() async {
    // Implementation for pause
  }

  Future<void> stop() async {
    // Implementation for stop
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
