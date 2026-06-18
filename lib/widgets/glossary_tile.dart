import 'package:flutter/material.dart';
import '../models/glossary_entry.dart';

class GlossaryTile extends StatelessWidget {
  final GlossaryEntry entry;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggle;

  const GlossaryTile({
    super.key,
    required this.entry,
    this.onEdit,
    this.onDelete,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typeColor = _typeColor(entry.type);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: entry.isActive ? 1.0 : 0.5,
      child: Card(
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Type badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    entry.type.toUpperCase(),
                    style: TextStyle(
                      color: typeColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.original,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            '→ ${entry.translated}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          if (entry.gender != null) ...[
                            const SizedBox(width: 6),
                            Icon(
                              entry.gender == 'male'
                                  ? Icons.male
                                  : entry.gender == 'female'
                                      ? Icons.female
                                      : Icons.transgender,
                              size: 14,
                              color: theme.colorScheme.secondary,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Toggle switch
                if (onToggle != null)
                  Switch(
                    value: entry.isActive,
                    onChanged: (_) => onToggle!(),
                    activeThumbColor: theme.colorScheme.primary,
                  ),
                // Delete button
                if (onDelete != null)
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: theme.colorScheme.error,
                      size: 20,
                    ),
                    onPressed: onDelete,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _typeColor(String type) {
    return switch (type) {
      'character' => const Color(0xFF6C63FF),
      'place' => const Color(0xFF00D2FF),
      'technique' => const Color(0xFFFF6584),
      'title' => const Color(0xFFFFB347),
      'item' => const Color(0xFF77DD77),
      _ => const Color(0xFF8B949E),
    };
  }
}
