// widgets/loading_dialog.dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../utils/theme.dart';

/// Custom loading dialog with Lottie animation
class LoadingDialog extends StatelessWidget {
  final String? message;
  final String? animationAsset;

  const LoadingDialog({
    super.key,
    this.message,
    this.animationAsset,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderRadiusXl,
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (animationAsset != null)
                Lottie.asset(
                  animationAsset!,
                  width: 120,
                  height: 120,
                )
              else
                SizedBox(
                  width: 64,
                  height: 64,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: colorScheme.primary,
                  ),
                ),
              const SizedBox(height: 24),
              Text(
                message ?? 'កំពុងដំណើរការ...',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show loading dialog
  static Future<T?> show<T>(
    BuildContext context, {
    String? message,
    String? animationAsset,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: false,
      builder: (context) => LoadingDialog(
        message: message,
        animationAsset: animationAsset,
      ),
    );
  }

  /// Hide loading dialog
  static void hide(BuildContext context) {
    Navigator.of(context).pop();
  }
}

/// Loading overlay that covers the entire screen
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black54,
            child: Center(
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.borderRadiusXl,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      if (message != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          message!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
