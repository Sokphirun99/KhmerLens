import 'package:flutter/material.dart';

class ProductDetailRow extends StatelessWidget {
  final String label;
  final dynamic value;

  const ProductDetailRow({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    if (value == null) return const SizedBox.shrink();

    // Special handling for Nutrition Facts
    if (label == 'Nutrition Facts' && value is Map) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              children: (value as Map).entries.map((e) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.key.toString(),
                          style: const TextStyle(fontSize: 14)),
                      Text(e.value.toString(),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      );
    }

    // Special handling for Nutrient Levels
    if (label == 'Nutrient Levels' && value is Map) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (value as Map).entries.map((e) {
              final level = e.value.toString().toLowerCase();
              Color color = Colors.grey;
              if (level == 'low' || level == 'good') color = Colors.green;
              if (level == 'moderate') color = Colors.orange;
              if (level == 'high') color = Colors.red;

              return Chip(
                avatar: CircleAvatar(backgroundColor: color, radius: 6),
                label: Text('${e.key}: $level'),
                backgroundColor: color.withOpacity(0.1),
                side: BorderSide(color: color.withOpacity(0.5)),
              );
            }).toList(),
          ),
        ],
      );
    }

    // Default string handling
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.1)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Text(
              value.toString(),
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
