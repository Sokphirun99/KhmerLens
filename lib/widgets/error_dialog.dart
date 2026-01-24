// widgets/error_dialog.dart
import 'package:flutter/material.dart';
import '../utils/error_handler.dart';
import '../utils/exceptions.dart';

/// User-friendly error dialog with recovery suggestions
class ErrorDialog extends StatelessWidget {
  final dynamic error;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;
  final String locale;

  const ErrorDialog({
    super.key,
    required this.error,
    this.onRetry,
    this.onDismiss,
    this.locale = 'en',
  });

  @override
  Widget build(BuildContext context) {
    final errorMessage = ErrorHandler.getMessage(error, locale: locale);
    final recoverySuggestion =
        ErrorHandler.getRecoverySuggestion(error, locale: locale);
    final isRecoverable = ErrorHandler.isRecoverable(error);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _getTitle(locale),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Error message
          Text(
            errorMessage,
            style: const TextStyle(fontSize: 16),
          ),

          // Recovery suggestion
          if (recoverySuggestion != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      recoverySuggestion,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Error details (expandable, debug mode only)
          if (error is AppException && error.originalError != null) ...[
            const SizedBox(height: 12),
            ExpansionTile(
              title: Text(
                _getDetailsTitle(locale),
                style: const TextStyle(fontSize: 12),
              ),
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.all(8),
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: SelectableText(
                    error.originalError.toString(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        // Dismiss button
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onDismiss?.call();
          },
          child: Text(_getDismissButtonText(locale)),
        ),

        // Retry button (only if recoverable)
        if (isRecoverable && onRetry != null)
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry?.call();
            },
            child: Text(_getRetryButtonText(locale)),
          ),
      ],
    );
  }

  String _getTitle(String locale) {
    if (locale.startsWith('km') || locale.startsWith('kh')) {
      return 'មានបញ្ហា';
    }
    return 'Error';
  }

  String _getDetailsTitle(String locale) {
    if (locale.startsWith('km') || locale.startsWith('kh')) {
      return 'ព័ត៌មានលម្អិត';
    }
    return 'Technical Details';
  }

  String _getDismissButtonText(String locale) {
    if (locale.startsWith('km') || locale.startsWith('kh')) {
      return 'បិទ';
    }
    return 'Close';
  }

  String _getRetryButtonText(String locale) {
    if (locale.startsWith('km') || locale.startsWith('kh')) {
      return 'ព្យាយាមម្តងទៀត';
    }
    return 'Retry';
  }

  /// Show error dialog
  static Future<void> show(
    BuildContext context, {
    required dynamic error,
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
    String locale = 'en',
  }) {
    // Log error for debugging
    ErrorHandler.logError(error);

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ErrorDialog(
        error: error,
        onRetry: onRetry,
        onDismiss: onDismiss,
        locale: locale,
      ),
    );
  }
}

/// Simple error snackbar for non-critical errors
class ErrorSnackBar {
  static void show(
    BuildContext context, {
    required dynamic error,
    String locale = 'en',
    Duration duration = const Duration(seconds: 4),
  }) {
    final errorMessage = ErrorHandler.getMessage(error, locale: locale);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                errorMessage,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        action: SnackBarAction(
          label: locale.startsWith('km') ? 'បិទ' : 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}
