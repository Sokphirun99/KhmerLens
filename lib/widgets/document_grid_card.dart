import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/document.dart';
import '../utils/helpers.dart';
import 'package:khmerscan/l10n/arb/app_localizations.dart';

/// A vertical grid-style document card for displaying documents in a masonry grid.
class DocumentGridCard extends StatelessWidget {
  final Document document;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onDelete;
  final VoidCallback? onShare;
  final String? thumbnailPath;
  final int index;
  final bool isDeleting;

  const DocumentGridCard({
    super.key,
    required this.document,
    this.onTap,
    this.onLongPress,
    this.onDelete,
    this.onShare,
    this.thumbnailPath,
    this.index = 0,
    this.isDeleting = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 3 / 4,
                  child: _buildImage(context),
                ),
                // Expiry warning badge
                if (_isExpiringSoon())
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.warning_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    document.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 12,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          Helpers.formatDate(document.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (document.expiryDate != null) ...[
                    const SizedBox(height: 2),
                    _buildExpiryRow(context),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    )
        // Only show delete animation when needed
        .animate(target: isDeleting ? 1 : 0)
        .scaleXY(end: 0.8, duration: 250.ms, curve: Curves.easeInBack)
        .fadeOut(duration: 250.ms);
  }

  Widget _buildImage(BuildContext context) {
    // Use first image from the list
    final imagePath = thumbnailPath ??
        (document.imagePaths.isNotEmpty ? document.imagePaths.first : '');

    if (imagePath.isEmpty) {
      final theme = Theme.of(context);
      return Container(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            size: 40,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Stack(
      children: [
        Image.file(
          File(imagePath),
          fit: BoxFit.cover,
          cacheWidth: 400, // Optimize memory by downsampling images
          cacheHeight: 400,
          errorBuilder: (context, error, stackTrace) {
            final theme = Theme.of(context);
            return Container(
              color: theme.colorScheme.surfaceContainerHighest,
              child: Center(
                child: Icon(
                  Icons.image_not_supported_outlined,
                  size: 40,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            );
          },
        ),
        // Multi-image indicator
        if (document.imagePaths.length > 1)
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.collections,
                    size: 12,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${document.imagePaths.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildExpiryRow(BuildContext context) {
    final theme = Theme.of(context);
    final isExpired = document.expiryDate!.isBefore(DateTime.now());
    final isExpiringSoon = _isExpiringSoon();

    Color textColor;
    if (isExpired) {
      textColor = theme.colorScheme.error;
    } else if (isExpiringSoon) {
      textColor = Colors.orange;
    } else {
      textColor = theme.colorScheme.outline;
    }

    return Row(
      children: [
        Icon(
          isExpired ? Icons.error_outline : Icons.schedule,
          size: 12,
          color: textColor,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            isExpired
                ? AppLocalizations.of(context)!.expired
                : AppLocalizations.of(context)!
                    .expiresOn(Helpers.formatDate(document.expiryDate!)),
            style: theme.textTheme.bodySmall?.copyWith(
              color: textColor,
              fontWeight: isExpired || isExpiringSoon
                  ? FontWeight.w600
                  : FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
          ),
        ),
      ],
    );
  }

  bool _isExpiringSoon() {
    if (document.expiryDate == null) return false;
    final now = DateTime.now();
    final daysUntilExpiry = document.expiryDate!.difference(now).inDays;
    return daysUntilExpiry >= 0 && daysUntilExpiry <= 30;
  }
}

/// A compact version of the document card for smaller grid layouts.
class DocumentGridCardCompact extends StatelessWidget {
  final Document document;
  final VoidCallback? onTap;
  final String? thumbnailPath;

  const DocumentGridCardCompact({
    super.key,
    required this.document,
    this.onTap,
    this.thumbnailPath,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with overlay at bottom
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: _buildImage(),
                ),
                // Gradient overlay
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                ),
                // Title
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
                  child: Text(
                    document.title,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
            color: theme.colorScheme.surfaceContainerHighest,
            child: Center(
              child: Icon(
                Icons.image_not_supported_outlined,
                size: 32,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          );
        },
      );
    }

    return Stack(
      children: [
        Image.file(
          File(imagePath),
          fit: BoxFit.cover,
          cacheWidth: 300, // Optimize memory for compact cards
          cacheHeight: 300,
          errorBuilder: (context, error, stackTrace) {
            return Builder(
              builder: (context) {
                final theme = Theme.of(context);
                return Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      size: 32,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              },
            );
          },
        ),
        // Multi-image indicator
        if (document.imagePaths.length > 1)
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.collections,
                    size: 10,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${document.imagePaths.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
