// widgets/empty_state.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';

/// Reusable empty state widget
class EmptyState extends StatelessWidget {
  final String? animationAsset;
  final IconData? icon;
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
              Icon(icon, size: 80, color: colorScheme.onSurfaceVariant),
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
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0);
  }

  static Widget documents({VoidCallback? onScan}) => EmptyState(
        animationAsset: 'assets/animations/empty_documents.json',
        title: 'គ្មានឯកសារ',
        subtitle: 'ចុចប៊ូតុងខាងក្រោមដើម្បីស្កេនឯកសារ',
        actionLabel: onScan != null ? 'ស្កេនឯកសារ' : null,
        onAction: onScan,
      );

  static Widget noSearchResults() => const EmptyState(
        animationAsset: 'assets/animations/empty_documents.json',
        title: 'រកមិនឃើញលទ្ធផល',
        subtitle: 'សូមព្យាយាមស្វែងរកដោយប្រើពាក្យគន្លឹះផ្សេង',
      );

  static Widget searchInitial() => const EmptyState(
        icon: Icons.search,
        title: 'វាយបញ្ចូលដើម្បីស្វែងរក',
        subtitle: 'ស្វែងរកតាមឈ្មោះឯកសារ ឬអត្ថបទដែលបានស្កេន',
      );
}
