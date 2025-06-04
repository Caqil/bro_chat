import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../../models/chat/message_model.dart';
import '../../models/file/file_model.dart';
import '../../providers/file/file_provider.dart';
import '../../services/media/audio_service.dart';
import 'dart:math' as math;

import '../../theme/colors.dart';
import '../../theme/text_styles.dart';

class AudioMessageWidget extends ConsumerStatefulWidget {
  final MessageModel message;
  final bool isCurrentUser;
  final double maxWidth;
  final bool autoPlay;
  final VoidCallback? onDownloadStart;
  final VoidCallback? onDownloadComplete;
  final Function(String)? onError;

  const AudioMessageWidget({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.maxWidth = 280,
    this.autoPlay = false,
    this.onDownloadStart,
    this.onDownloadComplete,
    this.onError,
  });

  @override
  ConsumerState<AudioMessageWidget> createState() => _AudioMessageWidgetState();
}

class _AudioMessageWidgetState extends ConsumerState<AudioMessageWidget>
    with TickerProviderStateMixin {
  late AudioService _audioService;
  String? _localFilePath;
  String? _playerId;
  bool _isLoading = false;
  bool _isDownloading = false;
  bool _hasError = false;
  String? _errorMessage;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isPlaying = false;
  bool _isBuffering = false;
  double _downloadProgress = 0.0;

  // Animation controllers
  late AnimationController _waveAnimationController;
  late AnimationController _playButtonController;
  late Animation<double> _waveAnimation;
  late Animation<double> _playButtonAnimation;

  // Timer for position updates
  Timer? _positionTimer;

  @override
  void initState() {
    super.initState();
    _audioService = AudioService();
    _initializeAnimations();
    _checkLocalFile();

    if (widget.autoPlay && widget.message.mediaUrl != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _playAudio();
      });
    }
  }

  void _initializeAnimations() {
    _waveAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _playButtonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _waveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _waveAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _playButtonAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: _playButtonController, curve: Curves.elasticOut),
    );
  }

  Future<void> _checkLocalFile() async {
    if (widget.message.mediaUrl == null) return;

    try {
      // Check if file exists locally
      final fileNotifier = ref.read(
        fileProvider.notifier,
      ); // ✅ Renamed to fileNotifier
      final files = fileNotifier.files;

      // Find file by URL or message ID
      final fileInfo = files.values.firstWhere(
        (file) => file.url == widget.message.mediaUrl,
        orElse: () => FileInfo(
          id: '',
          name: '',
          path: '',
          type: FileType.audio,
          purpose: FilePurpose.message,
          size: 0,
          mimeType: 'audio/mpeg',
        ),
      );

      if (fileInfo.isDownloaded && File(fileInfo.path).existsSync()) {
        setState(() {
          _localFilePath = fileInfo.path;
        });
        await _loadAudioInfo();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking local file: $e');
      }
    }
  }

  Future<void> _loadAudioInfo() async {
    if (_localFilePath == null) return;

    try {
      final duration = await _audioService.getAudioDuration(_localFilePath!);
      if (duration != null && mounted) {
        setState(() {
          _duration = duration;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading audio info: $e');
      }
    }
  }

  Future<void> _downloadAudio() async {
    if (widget.message.mediaUrl == null || _isDownloading) return;

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _hasError = false;
    });

    widget.onDownloadStart?.call();

    try {
      // Extract file ID from message metadata or URL
      final fileId = widget.message.metadata?['file_id'] as String?;
      if (fileId == null) {
        throw Exception('File ID not found in message metadata');
      }

      final fileNotifier = ref.read(
        fileProvider.notifier,
      ); // ✅ Renamed here too
      final fileInfo = await fileNotifier.downloadFile(fileId);

      if (mounted) {
        setState(() {
          _localFilePath = fileInfo.path;
          _isDownloading = false;
        });

        await _loadAudioInfo();
        widget.onDownloadComplete?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });

        widget.onError?.call(e.toString());
      }
    }
  }

  Future<void> _playAudio() async {
    if (_localFilePath == null) {
      await _downloadAudio();
      if (_localFilePath == null) return;
    }

    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      if (_isPlaying) {
        await _pauseAudio();
        return;
      }

      // Initialize audio service if needed
      if (!_audioService.isInitialized) {
        await _audioService.initialize();
      }

      _playerId = 'message_${widget.message.id}';
      await _audioService.playAudio(_localFilePath!, playerId: _playerId);

      _startPositionTimer();
      _waveAnimationController.repeat();
      _playButtonController.forward();

      setState(() {
        _isPlaying = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });

      widget.onError?.call(e.toString());
    }
  }

  Future<void> _pauseAudio() async {
    if (_playerId == null) return;

    try {
      await _audioService.pauseAudio(_playerId!);
      _stopPositionTimer();
      _waveAnimationController.stop();
      _playButtonController.reverse();

      setState(() {
        _isPlaying = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error pausing audio: $e');
      }
    }
  }

  Future<void> _stopAudio() async {
    if (_playerId == null) return;

    try {
      await _audioService.stopAudio(_playerId!);
      _stopPositionTimer();
      _waveAnimationController.reset();
      _playButtonController.reset();

      setState(() {
        _isPlaying = false;
        _position = Duration.zero;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error stopping audio: $e');
      }
    }
  }

  void _startPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_playerId != null) {
        final playerInfo = _audioService.getPlaybackInfo(_playerId!);
        if (playerInfo != null && mounted) {
          setState(() {
            _position = playerInfo.position;
            _isBuffering = false;
          });

          // Check if playback completed
          if (playerInfo.isCompleted) {
            _stopPositionTimer();
            _waveAnimationController.reset();
            _playButtonController.reset();

            setState(() {
              _isPlaying = false;
              _position = Duration.zero;
            });
          }
        }
      }
    });
  }

  void _stopPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = null;
  }

  Future<void> _seekTo(Duration position) async {
    if (_playerId == null || _duration == Duration.zero) return;

    try {
      await _audioService.seekAudio(_playerId!, position);
      setState(() {
        _position = position;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error seeking audio: $e');
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    } else {
      return "$twoDigitMinutes:$twoDigitSeconds";
    }
  }

  Widget _buildPlayButton() {
    return ScaleTransition(
      scale: _playButtonAnimation,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.isCurrentUser
              ? AppColors.primaryDark
              : AppColors.primary,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : IconButton(
                onPressed: _hasError ? null : _playAudio,
                icon: Icon(
                  _hasError
                      ? Icons.error_outline
                      : _isPlaying
                      ? Icons.pause
                      : Icons.play_arrow,
                  color: Colors.white,
                  size: 24,
                ),
                padding: EdgeInsets.zero,
              ),
      ),
    );
  }

  Widget _buildWaveform() {
    return Expanded(
      child: Container(
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        child: CustomPaint(
          painter: WaveformPainter(
            progress: _duration != Duration.zero
                ? _position.inMilliseconds / _duration.inMilliseconds
                : 0.0,
            isPlaying: _isPlaying,
            waveAnimation: _waveAnimation,
            color: widget.isCurrentUser
                ? Colors.white.withOpacity(0.8)
                : AppColors.primary.withOpacity(0.8),
            backgroundColor: widget.isCurrentUser
                ? Colors.white.withOpacity(0.3)
                : AppColors.primary.withOpacity(0.3),
          ),
          child: GestureDetector(
            onTapDown: (details) {
              if (_duration != Duration.zero) {
                final RenderBox box = context.findRenderObject() as RenderBox;
                final localPosition = box.globalToLocal(details.globalPosition);
                final progress = localPosition.dx / box.size.width;
                final newPosition = Duration(
                  milliseconds: (_duration.inMilliseconds * progress).round(),
                );
                _seekTo(newPosition);
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDurationInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatDuration(_position),
          style: AppTextStyles.caption.copyWith(
            color: widget.isCurrentUser
                ? Colors.white.withOpacity(0.8)
                : AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (_duration != Duration.zero) ...[
          const SizedBox(height: 2),
          Text(
            _formatDuration(_duration),
            style: AppTextStyles.caption.copyWith(
              color: widget.isCurrentUser
                  ? Colors.white.withOpacity(0.6)
                  : AppColors.textSecondary.withOpacity(0.7),
              fontSize: 10,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDownloadProgress() {
    if (!_isDownloading) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: _downloadProgress,
            backgroundColor: Colors.grey.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(
              widget.isCurrentUser ? Colors.white : AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Downloading... ${(_downloadProgress * 100).toInt()}%',
            style: AppTextStyles.caption.copyWith(
              color: widget.isCurrentUser
                  ? Colors.white.withOpacity(0.7)
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    if (!_hasError) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage ?? 'Failed to load audio',
              style: AppTextStyles.caption.copyWith(color: Colors.red),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _hasError = false;
                _errorMessage = null;
              });
              if (_localFilePath == null) {
                _downloadAudio();
              } else {
                _playAudio();
              }
            },
            child: Text(
              'Retry',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: widget.maxWidth),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildPlayButton(),
              _buildWaveform(),
              _buildDurationInfo(),
            ],
          ),
          _buildDownloadProgress(),
          _buildErrorMessage(),
          if (widget.message.content.isNotEmpty) ...[
            const SizedBox(height: 8),
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
    );
  }

  @override
  void dispose() {
    _positionTimer?.cancel();
    _waveAnimationController.dispose();
    _playButtonController.dispose();

    if (_playerId != null) {
      _audioService.stopAudio(_playerId!);
    }

    super.dispose();
  }
}

class WaveformPainter extends CustomPainter {
  final double progress;
  final bool isPlaying;
  final Animation<double> waveAnimation;
  final Color color;
  final Color backgroundColor;

  WaveformPainter({
    required this.progress,
    required this.isPlaying,
    required this.waveAnimation,
    required this.color,
    required this.backgroundColor,
  }) : super(repaint: waveAnimation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    final barWidth = 3.0;
    final barSpacing = 1.5;
    final barCount = (size.width / (barWidth + barSpacing)).floor();

    // Generate wave heights with some randomness
    final waveHeights = List.generate(barCount, (index) {
      final baseHeight = 0.3 + 0.7 * (1 + math.sin(index * 0.5)) / 2;
      final animationOffset = isPlaying ? waveAnimation.value * 2 * math.pi : 0;
      final animatedHeight =
          baseHeight + 0.2 * math.sin(index * 0.3 + animationOffset);
      return math.max(0.1, math.min(1.0, animatedHeight));
    });

    for (int i = 0; i < barCount; i++) {
      final x = i * (barWidth + barSpacing);
      final normalizedProgress = math.min(1.0, math.max(0.0, progress));
      final isPlayed = (i / barCount) <= normalizedProgress;

      paint.color = isPlayed ? color : backgroundColor;

      final barHeight = waveHeights[i] * size.height;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, (size.height - barHeight) / 2, barWidth, barHeight),
        const Radius.circular(1.5),
      );

      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isPlaying != isPlaying ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
