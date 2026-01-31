// widgets/success_action_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';

/// A bottom sheet for confirming successful actions.
class SuccessActionSheet extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final VoidCallback? onConfirm;

  const SuccessActionSheet({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'OK',
    this.onConfirm,
  });

  /// Shows the success action sheet
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    String? confirmLabel,
    VoidCallback? onConfirm,
  }) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SuccessActionSheet(
        title: title,
        message: message,
        confirmLabel:
            confirmLabel ?? 'OK', // Default generic OK if not provided
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // Success Icon (Lottie)
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Lottie.asset(
                  'assets/animations/success.json',
                  width: 60,
                  height: 60,
                  fit: BoxFit.contain,
                  repeat: false, // Play once for success
                ),
              ).animate().scale(
                    duration: 300.ms,
                    curve: Curves.elasticOut,
                  ),
              const SizedBox(height: 20),

              // Title
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Message
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Action button (Full width for success)
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    Navigator.pop(context);
                    onConfirm?.call();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(confirmLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().slideY(
          begin: 0.1,
          end: 0,
          duration: 250.ms,
          curve: Curves.easeOutCubic,
        );
  }
}
