// widgets/category_picker.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/document_category.dart';
import '../utils/theme.dart';

/// Modern category picker bottom sheet
class CategoryPicker extends StatelessWidget {
  final DocumentCategory? selectedCategory;
  final ValueChanged<DocumentCategory>? onCategorySelected;

  const CategoryPicker({
    super.key,
    this.selectedCategory,
    this.onCategorySelected,
  });

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  Icons.category_outlined,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'ជ្រើសរើសប្រភេទឯកសារ',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Category grid
          Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
              ),
              itemCount: DocumentCategory.values.length,
              itemBuilder: (context, index) {
                final category = DocumentCategory.values[index];
                final isSelected = selectedCategory == category;

                return _CategoryCard(
                  category: category,
                  isSelected: isSelected,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onCategorySelected?.call(category);
                    Navigator.pop(context, category);
                  },
                ).animate(delay: (50 * index).ms).fadeIn().scale(
                      begin: const Offset(0.9, 0.9),
                      end: const Offset(1, 1),
                      duration: 200.ms,
                    );
              },
            ),
          ),

          // Bottom safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  /// Show category picker bottom sheet
  static Future<DocumentCategory?> show(
    BuildContext context, {
    DocumentCategory? selectedCategory,
  }) {
    return showModalBottomSheet<DocumentCategory>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CategoryPicker(
        selectedCategory: selectedCategory,
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final DocumentCategory category;
  final bool isSelected;
  final VoidCallback? onTap;

  const _CategoryCard({
    required this.category,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final categoryColor = category.color;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderRadiusLg,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected
                ? categoryColor.withValues(alpha: 0.15)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: AppRadius.borderRadiusLg,
            border: Border.all(
              color: isSelected ? categoryColor : colorScheme.outlineVariant,
              width: isSelected ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon with background
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    category.icon,
                    color: categoryColor,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Category name in Khmer
              Text(
                category.nameKhmer,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? categoryColor
                          : colorScheme.onSurface,
                    ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              // Category name in English (smaller)
              Text(
                category.nameEnglish,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontal category chips for filtering
class CategoryChips extends StatelessWidget {
  final DocumentCategory? selectedCategory;
  final ValueChanged<DocumentCategory?>? onCategorySelected;
  final bool showAll;

  const CategoryChips({
    super.key,
    this.selectedCategory,
    this.onCategorySelected,
    this.showAll = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          if (showAll)
            _buildChip(
              context,
              label: 'ទាំងអស់',
              icon: Icons.apps,
              isSelected: selectedCategory == null,
              onTap: () => onCategorySelected?.call(null),
            ),
          ...DocumentCategory.values.map((category) => _buildChip(
                context,
                label: category.nameKhmer,
                icon: category.icon,
                color: category.color,
                isSelected: selectedCategory == category,
                onTap: () => onCategorySelected?.call(category),
              )),
        ],
      ),
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required String label,
    required IconData icon,
    Color? color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final chipColor = color ?? colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        showCheckmark: false,
        avatar: Icon(
          icon,
          size: 18,
          color: isSelected ? chipColor : colorScheme.onSurfaceVariant,
        ),
        label: Text(label),
        labelStyle: TextStyle(
          color: isSelected ? chipColor : colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
        backgroundColor: colorScheme.surface,
        selectedColor: chipColor.withValues(alpha: 0.15),
        side: BorderSide(
          color: isSelected ? chipColor : colorScheme.outlineVariant,
          width: isSelected ? 1.5 : 1,
        ),
        onSelected: (_) {
          HapticFeedback.selectionClick();
          onTap();
        },
      ),
    );
  }
}
