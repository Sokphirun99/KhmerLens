import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/document.dart';
import '../utils/helpers.dart';
import 'package:khmerscan/l10n/arb/app_localizations.dart';

/// A horizontal list-style document card with swipe actions.
class ModernDocumentCard extends StatelessWidget {
  final Document document;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onShare;
  final String? thumbnailPath;
  final int index;
  final bool isDeleting;

  const ModernDocumentCard({
    super.key,
    required this.document,
    this.onTap,
    this.onDelete,
    this.onShare,
    this.thumbnailPath,
    this.index = 0,
    this.isDeleting = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Slidable(
      key: ValueKey(document.id),
      // Left side actions (swipe right)
      startActionPane: onShare != null
          ? ActionPane(
              motion: const BehindMotion(),
              extentRatio: 0.25,
              children: [
                SlidableAction(
                  onPressed: (_) => onShare?.call(),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  icon: Icons.share,
                  label: AppLocalizations.of(context)!.share,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ],
            )
          : null,
      // Right side actions (swipe left)
      endActionPane: onDelete != null
          ? ActionPane(
              motion: const BehindMotion(),
              extentRatio: 0.25,
              dismissible: DismissiblePane(onDismissed: () => onDelete?.call()),
              children: [
                SlidableAction(
                  onPressed: (_) => onDelete?.call(),
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: Colors.white,
                  icon: Icons.delete,
                  label: AppLocalizations.of(context)!.delete,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
              ],
            )
          : null,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          // No border
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildImage(),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        document.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Helpers.formatDate(document.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
                // Arrow indicator
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 50 * index))
        .fadeIn(duration: 300.ms)
        .slideX(begin: -0.1, end: 0, duration: 300.ms)
        // Delete animation
        .animate(target: isDeleting ? 1 : 0)
        .slideX(end: -1, duration: 300.ms, curve: Curves.easeInBack)
        .fadeOut(duration: 250.ms);
  }

  Widget _buildImage() {
    // Use first image from the list
    final imagePath = thumbnailPath ??
        (document.imagePaths.isNotEmpty ? document.imagePaths.first : '');

    if (imagePath.isEmpty) {
      return Builder(
        builder: (context) {
          final theme = Theme.of(context);
          return Container(
            width: 64,
            height: 64,
            color: theme.colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.image_not_supported_outlined,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          );
        },
      );
    }

    return SizedBox(
      width: 64,
      height: 64,
      child: Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        cacheWidth: 128, // Optimize for small thumbnail (2x for retina)
        cacheHeight: 128,
        errorBuilder: (context, error, stackTrace) {
          final theme = Theme.of(context);
          return Container(
            width: 64,
            height: 64,
            color: theme.colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.image_not_supported_outlined,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          );
        },
      ),
    );
  }
}
