import 'package:uuid/uuid.dart';

class Chapter {
  final String id;
  final String novelId;
  final String url;
  String? title;
  String? originalText;
  String? translatedText;
  String? nextChapterUrl;
  int chapterNumber;
  DateTime? translatedAt;
  Map<String, String>? editedParagraphs; // paragraphIndex -> edited text

  Chapter({
    String? id,
    required this.novelId,
    required this.url,
    this.title,
    this.originalText,
    this.translatedText,
    this.nextChapterUrl,
    this.chapterNumber = 0,
    this.translatedAt,
    this.editedParagraphs,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'novelId': novelId,
      'url': url,
      'title': title,
      'originalText': originalText,
      'translatedText': translatedText,
      'nextChapterUrl': nextChapterUrl,
      'chapterNumber': chapterNumber,
      'translatedAt': translatedAt?.toIso8601String(),
      'editedParagraphs': editedParagraphs?.entries
              .map((e) => '${e.key}::${e.value}')
              .join('|||'),
    };
  }

  factory Chapter.fromMap(Map<String, dynamic> map) {
    Map<String, String>? edits;
    if (map['editedParagraphs'] != null &&
        (map['editedParagraphs'] as String).isNotEmpty) {
      edits = {};
      for (final entry
          in (map['editedParagraphs'] as String).split('|||')) {
        final parts = entry.split('::');
        if (parts.length == 2) {
          edits[parts[0]] = parts[1];
        }
      }
    }

    return Chapter(
      id: map['id'] as String,
      novelId: map['novelId'] as String,
      url: map['url'] as String,
      title: map['title'] as String?,
      originalText: map['originalText'] as String?,
      translatedText: map['translatedText'] as String?,
      nextChapterUrl: map['nextChapterUrl'] as String?,
      chapterNumber: map['chapterNumber'] as int? ?? 0,
      translatedAt: map['translatedAt'] != null
          ? DateTime.parse(map['translatedAt'] as String)
          : null,
      editedParagraphs: edits,
    );
  }

  Chapter copyWith({
    String? title,
    String? originalText,
    String? translatedText,
    String? nextChapterUrl,
    int? chapterNumber,
    DateTime? translatedAt,
    Map<String, String>? editedParagraphs,
  }) {
    return Chapter(
      id: id,
      novelId: novelId,
      url: url,
      title: title ?? this.title,
      originalText: originalText ?? this.originalText,
      translatedText: translatedText ?? this.translatedText,
      nextChapterUrl: nextChapterUrl ?? this.nextChapterUrl,
      chapterNumber: chapterNumber ?? this.chapterNumber,
      translatedAt: translatedAt ?? this.translatedAt,
      editedParagraphs: editedParagraphs ?? this.editedParagraphs,
    );
  }
}
