import 'package:uuid/uuid.dart';

class Novel {
  final String id;
  String title;
  String? coverImageUrl;
  String? sourceLanguage;
  String currentChapterUrl;
  String? nextChapterUrl;
  String selectedProvider;
  String selectedModel;
  DateTime lastReadAt;
  int totalChaptersTranslated;
  String targetLanguage;

  Novel({
    String? id,
    required this.title,
    this.coverImageUrl,
    this.sourceLanguage,
    required this.currentChapterUrl,
    this.nextChapterUrl,
    this.selectedProvider = 'openai',
    this.selectedModel = 'gpt-4o',
    DateTime? lastReadAt,
    this.totalChaptersTranslated = 0,
    this.targetLanguage = 'English',
  })  : id = id ?? const Uuid().v4(),
        lastReadAt = lastReadAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'coverImageUrl': coverImageUrl,
      'sourceLanguage': sourceLanguage,
      'currentChapterUrl': currentChapterUrl,
      'nextChapterUrl': nextChapterUrl,
      'selectedProvider': selectedProvider,
      'selectedModel': selectedModel,
      'lastReadAt': lastReadAt.toIso8601String(),
      'totalChaptersTranslated': totalChaptersTranslated,
      'targetLanguage': targetLanguage,
    };
  }

  factory Novel.fromMap(Map<String, dynamic> map) {
    return Novel(
      id: map['id'] as String,
      title: map['title'] as String,
      coverImageUrl: map['coverImageUrl'] as String?,
      sourceLanguage: map['sourceLanguage'] as String?,
      currentChapterUrl: map['currentChapterUrl'] as String,
      nextChapterUrl: map['nextChapterUrl'] as String?,
      selectedProvider: map['selectedProvider'] as String? ?? 'openai',
      selectedModel: map['selectedModel'] as String? ?? 'gpt-4o',
      lastReadAt: DateTime.parse(map['lastReadAt'] as String),
      totalChaptersTranslated: map['totalChaptersTranslated'] as int? ?? 0,
      targetLanguage: map['targetLanguage'] as String? ?? 'English',
    );
  }

  Novel copyWith({
    String? title,
    String? coverImageUrl,
    String? sourceLanguage,
    String? currentChapterUrl,
    String? nextChapterUrl,
    String? selectedProvider,
    String? selectedModel,
    DateTime? lastReadAt,
    int? totalChaptersTranslated,
    String? targetLanguage,
  }) {
    return Novel(
      id: id,
      title: title ?? this.title,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      currentChapterUrl: currentChapterUrl ?? this.currentChapterUrl,
      nextChapterUrl: nextChapterUrl ?? this.nextChapterUrl,
      selectedProvider: selectedProvider ?? this.selectedProvider,
      selectedModel: selectedModel ?? this.selectedModel,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      totalChaptersTranslated:
          totalChaptersTranslated ?? this.totalChaptersTranslated,
      targetLanguage: targetLanguage ?? this.targetLanguage,
    );
  }
}
