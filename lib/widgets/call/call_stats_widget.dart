import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/call/call_model.dart';
import '../../providers/call/call_provider.dart';
import '../../providers/call/webrtc_provider.dart';

class CallStatsWidget extends ConsumerStatefulWidget {
  final CallQuality quality;
  final bool compact;
  final bool autoUpdate;
  final Duration updateInterval;
  final bool showChart;

  const CallStatsWidget({
    super.key,
    required this.quality,
    this.compact = false,
    this.autoUpdate = true,
    this.updateInterval = const Duration(seconds: 2),
    this.showChart = true,
  });

  @override
  ConsumerState<CallStatsWidget> createState() => _CallStatsWidgetState();
}

class _CallStatsWidgetState extends ConsumerState<CallStatsWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  Timer? _updateTimer;

  final List<CallQualityDataPoint> _qualityHistory = [];
  static const int _maxHistoryPoints = 30;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAutoUpdate();
    _addQualityDataPoint(widget.quality);
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  void _startAutoUpdate() {
    if (!widget.autoUpdate) return;

    _updateTimer = Timer.periodic(widget.updateInterval, (timer) {
      final callQuality = ref.read(callQualityProvider);
      if (callQuality != null) {
        _addQualityDataPoint(callQuality);
      }
    });
  }

  void _addQualityDataPoint(CallQuality quality) {
    setState(() {
      _qualityHistory.add(
        CallQualityDataPoint(timestamp: DateTime.now(), quality: quality),
      );

      if (_qualityHistory.length > _maxHistoryPoints) {
        _qualityHistory.removeAt(0);
      }
    });
  }

  @override
  void didUpdateWidget(CallStatsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.quality != widget.quality) {
      _addQualityDataPoint(widget.quality);
    }
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: widget.compact ? _buildCompactStats() : _buildFullStats(),
    );
  }

  Widget _buildCompactStats() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildQualityIndicator(),
          const SizedBox(width: 8),
          _buildCompactMetrics(),
        ],
      ),
    );
  }

  Widget _buildFullStats() {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatsHeader(),
          const SizedBox(height: 16),
          _buildQualityOverview(),
          const SizedBox(height: 16),
          _buildDetailedMetrics(),
          if (widget.showChart) ...[
            const SizedBox(height: 16),
            _buildQualityChart(),
          ],
          const SizedBox(height: 16),
          _buildNetworkInfo(),
        ],
      ),
    );
  }

  Widget _buildStatsHeader() {
    return Row(
      children: [
        const Icon(Icons.analytics, size: 20, color: Colors.grey),
        const SizedBox(width: 8),
        const Text(
          'Call Statistics',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        _buildRefreshButton(),
      ],
    );
  }

  Widget _buildRefreshButton() {
    return ShadButton.ghost(
      onPressed: _refreshStats,
      size: ShadButtonSize.sm,
      child: const Icon(Icons.refresh, size: 16),
    );
  }

  Widget _buildQualityIndicator() {
    final color = _getQualityColor(widget.quality.qualityScore);
    final icon = _getQualityIcon(widget.quality.qualityScore);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(icon, color: Colors.white, size: 16),
    );
  }

  Widget _buildCompactMetrics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${widget.quality.rtt}ms',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          '${(widget.quality.packetLoss * 100).toStringAsFixed(1)}%',
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildQualityOverview() {
    final qualityText = _getQualityText(widget.quality.qualityScore);
    final qualityColor = _getQualityColor(widget.quality.qualityScore);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: qualityColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getQualityIcon(widget.quality.qualityScore),
                color: qualityColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    qualityText,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: qualityColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Score: ${widget.quality.qualityScore.toStringAsFixed(1)}/5.0',
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

  Widget _buildDetailedMetrics() {
    return Column(
      children: [
        _buildMetricRow(
          'Round Trip Time',
          '${widget.quality.rtt}ms',
          _getRTTColor(widget.quality.rtt),
          Icons.schedule,
        ),
        const SizedBox(height: 8),
        _buildMetricRow(
          'Jitter',
          '${widget.quality.jitter}ms',
          _getJitterColor(widget.quality.jitter),
          Icons.graphic_eq,
        ),
        const SizedBox(height: 8),
        _buildMetricRow(
          'Packet Loss',
          '${(widget.quality.packetLoss * 100).toStringAsFixed(2)}%',
          _getPacketLossColor(widget.quality.packetLoss),
          Icons.warning,
        ),
        const SizedBox(height: 8),
        _buildMetricRow(
          'Bandwidth',
          _formatBandwidth(widget.quality.bandwidth),
          Colors.blue,
          Icons.speed,
        ),
      ],
    );
  }

  Widget _buildMetricRow(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildQualityChart() {
    if (_qualityHistory.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(child: Text('No data available')),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quality Over Time',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: CustomPaint(
                painter: QualityChartPainter(_qualityHistory),
                size: const Size.fromHeight(100),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Network Information',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _buildNetworkRow('Connection Type', widget.quality.networkType),
            const SizedBox(height: 4),
            _buildNetworkRow(
              'Quality Score',
              '${widget.quality.qualityScore.toStringAsFixed(1)}/5.0',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  void _refreshStats() {
    // Trigger a refresh of call statistics
    final callNotifier = ref.read(callProvider.notifier);
    // In a real implementation, this would fetch fresh stats
  }

  Color _getQualityColor(double score) {
    if (score >= 4.0) return Colors.green;
    if (score >= 3.0) return Colors.orange;
    if (score >= 2.0) return Colors.red;
    return Colors.grey;
  }

  IconData _getQualityIcon(double score) {
    if (score >= 4.0) return Icons.signal_wifi_4_bar;
    if (score >= 3.0) return Icons.signal_wifi_3_bar;
    if (score >= 2.0) return Icons.signal_wifi_2_bar;
    if (score >= 1.0) return Icons.signal_wifi_1_bar;
    return Icons.signal_wifi_0_bar;
  }

  String _getQualityText(double score) {
    if (score >= 4.0) return 'Excellent';
    if (score >= 3.0) return 'Good';
    if (score >= 2.0) return 'Fair';
    if (score >= 1.0) return 'Poor';
    return 'Very Poor';
  }

  Color _getRTTColor(int rtt) {
    if (rtt <= 100) return Colors.green;
    if (rtt <= 200) return Colors.orange;
    return Colors.red;
  }

  Color _getJitterColor(int jitter) {
    if (jitter <= 20) return Colors.green;
    if (jitter <= 40) return Colors.orange;
    return Colors.red;
  }

  Color _getPacketLossColor(double packetLoss) {
    if (packetLoss <= 0.01) return Colors.green;
    if (packetLoss <= 0.05) return Colors.orange;
    return Colors.red;
  }

  String _formatBandwidth(int bandwidth) {
    if (bandwidth >= 1000000) {
      return '${(bandwidth / 1000000).toStringAsFixed(1)} Mbps';
    } else if (bandwidth >= 1000) {
      return '${(bandwidth / 1000).toStringAsFixed(0)} Kbps';
    } else {
      return '${bandwidth} bps';
    }
  }
}

class CallQualityDataPoint {
  final DateTime timestamp;
  final CallQuality quality;

  CallQualityDataPoint({required this.timestamp, required this.quality});
}

class QualityChartPainter extends CustomPainter {
  final List<CallQualityDataPoint> dataPoints;

  QualityChartPainter(this.dataPoints);

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();

    final maxScore = 5.0;
    final minScore = 0.0;

    for (int i = 0; i < dataPoints.length; i++) {
      final x = (i / (dataPoints.length - 1)) * size.width;
      final normalizedScore =
          (dataPoints[i].quality.qualityScore - minScore) /
          (maxScore - minScore);
      final y = size.height - (normalizedScore * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Draw points
    final pointPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    for (int i = 0; i < dataPoints.length; i++) {
      final x = (i / (dataPoints.length - 1)) * size.width;
      final normalizedScore =
          (dataPoints[i].quality.qualityScore - minScore) /
          (maxScore - minScore);
      final y = size.height - (normalizedScore * size.height);

      canvas.drawCircle(Offset(x, y), 3, pointPaint);
    }

    // Draw grid lines
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1;

    // Horizontal grid lines
    for (int i = 0; i <= 5; i++) {
      final y = (i / 5) * size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(QualityChartPainter oldDelegate) {
    return oldDelegate.dataPoints != dataPoints;
  }
}

// Detailed stats dialog
class DetailedCallStatsDialog extends ConsumerWidget {
  const DetailedCallStatsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final callState = ref.watch(callProvider);

    return callState.when(
      data: (state) {
        if (!state.hasActiveCall || state.currentQuality == null) {
          return const SizedBox.shrink();
        }

        return ShadDialog(
          title: const Text('Detailed Call Statistics'),
          actions: [
            ShadButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
          child: SizedBox(
            width: 400,
            height: 500,
            child: SingleChildScrollView(
              child: CallStatsWidget(
                quality: state.currentQuality!,
                compact: false,
                showChart: true,
              ),
            ),
          ),
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (_, __) => const Text('Error loading stats'),
    );
  }
}

// Floating stats widget that can be toggled
class FloatingCallStats extends ConsumerStatefulWidget {
  const FloatingCallStats({super.key});

  @override
  ConsumerState<FloatingCallStats> createState() => _FloatingCallStatsState();
}

class _FloatingCallStatsState extends ConsumerState<FloatingCallStats> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final hasActiveCall = ref.watch(hasActiveCallProvider);
    final callQuality = ref.watch(callQualityProvider);

    if (!hasActiveCall || callQuality == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 100,
      right: 16,
      child: GestureDetector(
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          child: _isExpanded
              ? CallStatsWidget(
                  quality: callQuality,
                  compact: false,
                  showChart: false,
                )
              : CallStatsWidget(quality: callQuality, compact: true),
        ),
      ),
    );
  }
}
