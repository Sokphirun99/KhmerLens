import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:khmerscan/l10n/arb/app_localizations.dart';

/// Reusable empty state widget
class EmptyState extends StatelessWidget {
  final String? animationAsset;
  final String? icon; // Changed from IconData? to String? for Iconify
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    this.animationAsset,
    this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (animationAsset != null)
              Lottie.asset(animationAsset!, width: 150, height: 150)
            else if (icon != null)
              Iconify(
                icon!,
                size: 80,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Iconify(Mdi.plus, color: Colors.white),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0);
  }

  static Widget documents(BuildContext context, {VoidCallback? onScan}) {
    final l10n = AppLocalizations.of(context)!;
    return EmptyState(
      animationAsset: 'assets/animations/empty_documents.json',
      title: l10n.emptyStateMessage,
      subtitle: l10n.emptyStateDescription,
      actionLabel: l10n.scanDocument,
      onAction: onScan,
    );
  }

  static Widget noSearchResults(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EmptyState(
      animationAsset: 'assets/animations/empty_documents.json',
      title: l10n.noResultsFound,
      subtitle: l10n.tryDifferentKeywords,
    );
  }

  static Widget searchInitial(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EmptyState(
      icon: Mdi.magnify,
      title: l10n.typeToSearch,
      subtitle: l10n.searchByNameOrText,
    );
  }
}
