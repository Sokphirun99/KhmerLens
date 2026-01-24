import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/document.dart';
import '../utils/helpers.dart';

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
    final categoryColor = document.category.color;

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
                  label: 'Share',
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
                  label: 'Delete',
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
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Thumbnail with category color indicator
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _buildImage(),
                    ),
                    // Category color indicator
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 4,
                        decoration: BoxDecoration(
                          color: categoryColor,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            bottomLeft: Radius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
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
                      Row(
                        children: [
                          Icon(
                            document.category.icon,
                            size: 14,
                            color: categoryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            document.category.nameEnglish,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
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
    final imagePath = thumbnailPath ?? document.imagePath;

    return SizedBox(
      width: 64,
      height: 64,
      child: Image.file(
        File(imagePath),
        fit: BoxFit.cover,
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
