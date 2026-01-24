// widgets/skeleton_loader.dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../utils/theme.dart';

/// Base skeleton widget with shimmer effect
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark
          ? colorScheme.surfaceContainerHighest
          : colorScheme.surfaceContainerHigh,
      highlightColor: isDark
          ? colorScheme.surfaceContainerHigh
          : colorScheme.surfaceContainerLowest,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: borderRadius ?? AppRadius.borderRadiusSm,
        ),
      ),
    );
  }
}

/// Skeleton for document grid card
class DocumentCardSkeleton extends StatelessWidget {
  final int index;

  const DocumentCardSkeleton({
    super.key,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark
        ? colorScheme.surfaceContainerHighest
        : colorScheme.surfaceContainerHigh;
    final highlightColor = isDark
        ? colorScheme.surfaceContainerHigh
        : colorScheme.surfaceContainerLowest;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            AspectRatio(
              aspectRatio: 3 / 4,
              child: Container(
                color: colorScheme.surface,
              ),
            ),
            // Content placeholder
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: AppRadius.borderRadiusXs,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: 100,
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: AppRadius.borderRadiusXs,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for list item
class ListItemSkeleton extends StatelessWidget {
  const ListItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark
        ? colorScheme.surfaceContainerHighest
        : colorScheme.surfaceContainerHigh;
    final highlightColor = isDark
        ? colorScheme.surfaceContainerHigh
        : colorScheme.surfaceContainerLowest;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar/thumbnail
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: AppRadius.borderRadiusSm,
              ),
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: AppRadius.borderRadiusXs,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: 150,
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: AppRadius.borderRadiusXs,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for settings section
class SettingsSectionSkeleton extends StatelessWidget {
  final int itemCount;

  const SettingsSectionSkeleton({
    super.key,
    this.itemCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark
        ? colorScheme.surfaceContainerHighest
        : colorScheme.surfaceContainerHigh;
    final highlightColor = isDark
        ? colorScheme.surfaceContainerHigh
        : colorScheme.surfaceContainerLowest;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Container(
            height: 20,
            width: 100,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: AppRadius.borderRadiusXs,
            ),
          ),
          // Card with items
          Card(
            child: Column(
              children: List.generate(
                itemCount,
                (index) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: AppRadius.borderRadiusSm,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 14,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                borderRadius: AppRadius.borderRadiusXs,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              height: 10,
                              width: 100,
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                borderRadius: AppRadius.borderRadiusXs,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
