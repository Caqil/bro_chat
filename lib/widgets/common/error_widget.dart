import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

enum ErrorType {
  network,
  server,
  authentication,
  validation,
  permission,
  notFound,
  timeout,
  unknown,
  custom,
}

enum ErrorSeverity { low, medium, high, critical }

class AppError {
  final String message;
  final String? code;
  final ErrorType type;
  final ErrorSeverity severity;
  final String? technicalDetails;
  final Map<String, dynamic>? context;
  final DateTime timestamp;

  AppError({
    required this.message,
    this.code,
    required this.type,
    this.severity = ErrorSeverity.medium,
    this.technicalDetails,
    this.context,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory AppError.network({
    String? message,
    String? code,
    String? technicalDetails,
  }) {
    return AppError(
      message: message ?? 'Network connection failed',
      code: code,
      type: ErrorType.network,
      severity: ErrorSeverity.high,
      technicalDetails: technicalDetails,
    );
  }

  factory AppError.server({
    String? message,
    String? code,
    String? technicalDetails,
  }) {
    return AppError(
      message: message ?? 'Server error occurred',
      code: code,
      type: ErrorType.server,
      severity: ErrorSeverity.high,
      technicalDetails: technicalDetails,
    );
  }

  factory AppError.authentication({String? message, String? code}) {
    return AppError(
      message: message ?? 'Authentication failed',
      code: code,
      type: ErrorType.authentication,
      severity: ErrorSeverity.high,
    );
  }

  factory AppError.validation({
    required String message,
    String? code,
    Map<String, dynamic>? context,
  }) {
    return AppError(
      message: message,
      code: code,
      type: ErrorType.validation,
      severity: ErrorSeverity.medium,
      context: context,
    );
  }

  factory AppError.permission({String? message, String? code}) {
    return AppError(
      message: message ?? 'Permission denied',
      code: code,
      type: ErrorType.permission,
      severity: ErrorSeverity.medium,
    );
  }

  factory AppError.notFound({String? message, String? code}) {
    return AppError(
      message: message ?? 'Resource not found',
      code: code,
      type: ErrorType.notFound,
      severity: ErrorSeverity.medium,
    );
  }

  factory AppError.timeout({String? message, String? code}) {
    return AppError(
      message: message ?? 'Request timeout',
      code: code,
      type: ErrorType.timeout,
      severity: ErrorSeverity.medium,
    );
  }

  factory AppError.unknown({
    String? message,
    String? code,
    String? technicalDetails,
  }) {
    return AppError(
      message: message ?? 'An unexpected error occurred',
      code: code,
      type: ErrorType.unknown,
      severity: ErrorSeverity.medium,
      technicalDetails: technicalDetails,
    );
  }
}

class CustomErrorWidget extends StatelessWidget {
  final AppError error;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;
  final VoidCallback? onReportError;
  final bool showTechnicalDetails;
  final bool canRetry;
  final bool canDismiss;
  final bool canReport;
  final EdgeInsets? padding;
  final Widget? customAction;

  const CustomErrorWidget({
    super.key,
    required this.error,
    this.onRetry,
    this.onDismiss,
    this.onReportError,
    this.showTechnicalDetails = false,
    this.canRetry = true,
    this.canDismiss = false,
    this.canReport = false,
    this.padding,
    this.customAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildIcon(),
          const SizedBox(height: 24),
          _buildTitle(context),
          const SizedBox(height: 12),
          _buildMessage(context),
          if (showTechnicalDetails && error.technicalDetails != null) ...[
            const SizedBox(height: 16),
            _buildTechnicalDetails(context),
          ],
          const SizedBox(height: 32),
          _buildActions(context),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    final iconData = _getIconForError();
    final color = _getColorForError();

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, size: 40, color: color),
    );
  }

  Widget _buildTitle(BuildContext context) {
    final title = _getTitleForError();

    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildMessage(BuildContext context) {
    return Text(
      error.message,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        height: 1.5,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildTechnicalDetails(BuildContext context) {
    return ExpansionTile(
      title: const Text('Technical Details'),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (error.code != null) ...[
                Text(
                  'Error Code: ${error.code}',
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
                const SizedBox(height: 8),
              ],
              Text(
                error.technicalDetails!,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
              const SizedBox(height: 8),
              Text(
                'Timestamp: ${error.timestamp.toIso8601String()}',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              ShadButton.outline(
                onPressed: () => _copyToClipboard(context),
                size: ShadButtonSize.sm,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.copy, size: 16),
                    SizedBox(width: 8),
                    Text('Copy Details'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    final actions = <Widget>[];

    // Custom action
    if (customAction != null) {
      actions.add(customAction!);
    } else {
      // Retry button
      if (canRetry && onRetry != null && _shouldShowRetry()) {
        actions.add(
          ShadButton(
            onPressed: onRetry,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.refresh, size: 16),
                SizedBox(width: 8),
                Text('Try Again'),
              ],
            ),
          ),
        );
      }

      // Report error button
      if (canReport && onReportError != null) {
        if (actions.isNotEmpty) actions.add(const SizedBox(width: 12));
        actions.add(
          ShadButton.outline(
            onPressed: onReportError,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bug_report, size: 16),
                SizedBox(width: 8),
                Text('Report'),
              ],
            ),
          ),
        );
      }

      // Dismiss button
      if (canDismiss && onDismiss != null) {
        if (actions.isNotEmpty) actions.add(const SizedBox(width: 12));
        actions.add(
          ShadButton.ghost(onPressed: onDismiss, child: const Text('Dismiss')),
        );
      }
    }

    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: actions,
    );
  }

  IconData _getIconForError() {
    switch (error.type) {
      case ErrorType.network:
        return Icons.wifi_off;
      case ErrorType.server:
        return Icons.error_outline;
      case ErrorType.authentication:
        return Icons.lock_outline;
      case ErrorType.validation:
        return Icons.warning_amber_outlined;
      case ErrorType.permission:
        return Icons.no_accounts_outlined;
      case ErrorType.notFound:
        return Icons.search_off;
      case ErrorType.timeout:
        return Icons.access_time;
      case ErrorType.unknown:
      case ErrorType.custom:
        return Icons.help_outline;
    }
  }

  Color _getColorForError() {
    switch (error.severity) {
      case ErrorSeverity.low:
        return Colors.blue;
      case ErrorSeverity.medium:
        return Colors.orange;
      case ErrorSeverity.high:
        return Colors.red;
      case ErrorSeverity.critical:
        return Colors.purple;
    }
  }

  String _getTitleForError() {
    switch (error.type) {
      case ErrorType.network:
        return 'Connection Problem';
      case ErrorType.server:
        return 'Server Error';
      case ErrorType.authentication:
        return 'Authentication Failed';
      case ErrorType.validation:
        return 'Validation Error';
      case ErrorType.permission:
        return 'Access Denied';
      case ErrorType.notFound:
        return 'Not Found';
      case ErrorType.timeout:
        return 'Request Timeout';
      case ErrorType.unknown:
        return 'Unexpected Error';
      case ErrorType.custom:
        return 'Error';
    }
  }

  bool _shouldShowRetry() {
    return error.type == ErrorType.network ||
        error.type == ErrorType.server ||
        error.type == ErrorType.timeout;
  }

  void _copyToClipboard(BuildContext context) {
    final details = StringBuffer();
    details.writeln('Error: ${error.message}');
    if (error.code != null) details.writeln('Code: ${error.code}');
    details.writeln('Type: ${error.type.name}');
    details.writeln('Severity: ${error.severity.name}');
    if (error.technicalDetails != null) {
      details.writeln('Details: ${error.technicalDetails}');
    }
    details.writeln('Timestamp: ${error.timestamp.toIso8601String()}');

    Clipboard.setData(ClipboardData(text: details.toString()));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Error details copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

// Error banner for inline errors
class ErrorBanner extends StatelessWidget {
  final AppError error;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;
  final bool showCloseButton;
  final EdgeInsets? margin;

  const ErrorBanner({
    super.key,
    required this.error,
    this.onRetry,
    this.onDismiss,
    this.showCloseButton = true,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getColorForSeverity(error.severity);

    return Container(
      margin: margin ?? const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(_getIconForSeverity(error.severity), color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  error.message,
                  style: TextStyle(fontWeight: FontWeight.w500, color: color),
                ),
                if (error.code != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Error code: ${error.code}',
                    style: TextStyle(
                      fontSize: 12,
                      color: color.withOpacity(0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 8),
            ShadButton.ghost(
              onPressed: onRetry,
              size: ShadButtonSize.sm,
              child: const Text('Retry'),
            ),
          ],
          if (showCloseButton && onDismiss != null) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close),
              iconSize: 16,
              color: color,
            ),
          ],
        ],
      ),
    );
  }

  Color _getColorForSeverity(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.low:
        return Colors.blue;
      case ErrorSeverity.medium:
        return Colors.orange;
      case ErrorSeverity.high:
        return Colors.red;
      case ErrorSeverity.critical:
        return Colors.purple;
    }
  }

  IconData _getIconForSeverity(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.low:
        return Icons.info_outline;
      case ErrorSeverity.medium:
        return Icons.warning_amber_outlined;
      case ErrorSeverity.high:
        return Icons.error_outline;
      case ErrorSeverity.critical:
        return Icons.dangerous_outlined;
    }
  }
}

// Compact error widget for small spaces
class CompactErrorWidget extends StatelessWidget {
  final AppError error;
  final VoidCallback? onRetry;
  final bool showIcon;

  const CompactErrorWidget({
    super.key,
    required this.error,
    this.onRetry,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showIcon) ...[
            Icon(Icons.error_outline, color: Colors.red, size: 32),
            const SizedBox(height: 12),
          ],
          Text(
            error.message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ShadButton.outline(
              onPressed: onRetry,
              size: ShadButtonSize.sm,
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}

// Error snackbar
class ErrorSnackBar {
  static void show(
    BuildContext context, {
    required AppError error,
    VoidCallback? onRetry,
    Duration duration = const Duration(seconds: 4),
  }) {
    final color = _getColorForSeverity(error.severity);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _getIconForSeverity(error.severity),
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                error.message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        duration: duration,
        action: onRetry != null
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }

  static Color _getColorForSeverity(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.low:
        return Colors.blue;
      case ErrorSeverity.medium:
        return Colors.orange;
      case ErrorSeverity.high:
        return Colors.red;
      case ErrorSeverity.critical:
        return Colors.purple;
    }
  }

  static IconData _getIconForSeverity(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.low:
        return Icons.info_outline;
      case ErrorSeverity.medium:
        return Icons.warning_amber_outlined;
      case ErrorSeverity.high:
        return Icons.error_outline;
      case ErrorSeverity.critical:
        return Icons.dangerous_outlined;
    }
  }
}

// Error dialog
class ErrorDialog {
  static Future<bool?> show(
    BuildContext context, {
    required AppError error,
    VoidCallback? onRetry,
    bool showTechnicalDetails = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 12),
            const Text('Error'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(error.message),
            if (showTechnicalDetails && error.technicalDetails != null) ...[
              const SizedBox(height: 16),
              ExpansionTile(
                title: const Text('Technical Details'),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      error.technicalDetails!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Close'),
          ),
          if (onRetry != null)
            ShadButton(
              onPressed: () {
                Navigator.of(context).pop(true);
                onRetry();
              },
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }
}
