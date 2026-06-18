import 'package:flutter/material.dart';
import '../core/theme.dart';

class ReadingThemeToggle extends StatelessWidget {
  final ReadingTheme currentTheme;
  final ValueChanged<ReadingTheme> onChanged;

  const ReadingThemeToggle({
    super.key,
    required this.currentTheme,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: ReadingTheme.values.map((theme) {
        final isSelected = theme == currentTheme;
        final (color, label) = switch (theme) {
          ReadingTheme.dark => (const Color(0xFF0D1117), 'Dark'),
          ReadingTheme.sepia => (const Color(0xFFF4ECD8), 'Sepia'),
          ReadingTheme.light => (const Color(0xFFF6F8FA), 'Light'),
        };

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: GestureDetector(
            onTap: () => onChanged(theme),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppTheme.brandPrimary
                      : Colors.grey.withValues(alpha: 0.3),
                  width: isSelected ? 3 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.brandPrimary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        )
                      ]
                    : null,
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      size: 16,
                      color: theme == ReadingTheme.dark
                          ? Colors.white
                          : Colors.black,
                    )
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }
}
