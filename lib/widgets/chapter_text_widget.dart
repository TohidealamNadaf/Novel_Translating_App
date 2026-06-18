import 'package:flutter/material.dart';
import '../core/theme.dart';

class ChapterTextWidget extends StatelessWidget {
  final String text;
  final ReadingTheme readingTheme;
  final double fontSize;
  final bool useSerif;
  final Map<String, String>? editedParagraphs;
  final void Function(int index, String currentText)? onLongPressParagraph;

  const ChapterTextWidget({
    super.key,
    required this.text,
    required this.readingTheme,
    this.fontSize = 17,
    this.useSerif = true,
    this.editedParagraphs,
    this.onLongPressParagraph,
  });

  @override
  Widget build(BuildContext context) {
    final paragraphs = text.split('\n\n');
    final style = AppTheme.readingStyle(
      theme: readingTheme,
      fontSize: fontSize,
      useSerif: useSerif,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(paragraphs.length, (index) {
        // Use edited text if available
        final displayText =
            editedParagraphs?[index.toString()] ?? paragraphs[index];
        final isEdited = editedParagraphs?.containsKey(index.toString()) ?? false;

        return GestureDetector(
          onLongPress: () {
            onLongPressParagraph?.call(index, displayText);
          },
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            padding: isEdited
                ? const EdgeInsets.all(8)
                : EdgeInsets.zero,
            decoration: isEdited
                ? BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: AppTheme.brandPrimary.withOpacity(0.5),
                        width: 3,
                      ),
                    ),
                  )
                : null,
            child: SelectableText(
              displayText.trim(),
              style: style,
            ),
          ),
        );
      }),
    );
  }
}
