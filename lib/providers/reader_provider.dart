import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chapter.dart';
import '../models/glossary_entry.dart';
import '../services/translation_service.dart';
import '../services/database_service.dart';

/// State for the reader screen
class ReaderState {
  final Chapter? currentChapter;
  final bool isTranslating;
  final String? error;
  final int currentChunk;
  final int totalChunks;
  final String statusMessage;
  final bool showOriginal;

  const ReaderState({
    this.currentChapter,
    this.isTranslating = false,
    this.error,
    this.currentChunk = 0,
    this.totalChunks = 0,
    this.statusMessage = '',
    this.showOriginal = false,
  });

  ReaderState copyWith({
    Chapter? currentChapter,
    bool? isTranslating,
    String? error,
    int? currentChunk,
    int? totalChunks,
    String? statusMessage,
    bool? showOriginal,
  }) {
    return ReaderState(
      currentChapter: currentChapter ?? this.currentChapter,
      isTranslating: isTranslating ?? this.isTranslating,
      error: error,
      currentChunk: currentChunk ?? this.currentChunk,
      totalChunks: totalChunks ?? this.totalChunks,
      statusMessage: statusMessage ?? this.statusMessage,
      showOriginal: showOriginal ?? this.showOriginal,
    );
  }
}

class ReaderNotifier extends StateNotifier<ReaderState> {
  ReaderNotifier() : super(const ReaderState());

  /// Translate a chapter from URL
  Future<void> translateChapter({
    required String url,
    required String novelId,
    required String provider,
    required String model,
    required String apiKey,
    required List<GlossaryEntry> glossary,
    String? novelContext,
    int chapterNumber = 0,
  }) async {
    state = state.copyWith(
      isTranslating: true,
      error: null,
      statusMessage: 'Starting translation...',
    );

    try {
      final chapter = await TranslationService.translateFromUrl(
        url: url,
        novelId: novelId,
        provider: provider,
        model: model,
        apiKey: apiKey,
        glossary: glossary,
        novelContext: novelContext,
        chapterNumber: chapterNumber,
        onProgress: (current, total, msg) {
          state = state.copyWith(
            currentChunk: current,
            totalChunks: total,
            statusMessage: msg,
          );
        },
      );

      state = state.copyWith(
        currentChapter: chapter,
        isTranslating: false,
        statusMessage: 'Translation complete',
      );
    } catch (e) {
      state = state.copyWith(
        isTranslating: false,
        error: e.toString(),
        statusMessage: 'Translation failed',
      );
    }
  }

  /// Translate raw text directly
  Future<void> translateRawText({
    required String text,
    required String novelId,
    required String provider,
    required String model,
    required String apiKey,
    required List<GlossaryEntry> glossary,
    String? novelContext,
  }) async {
    state = state.copyWith(
      isTranslating: true,
      error: null,
      statusMessage: 'Starting translation...',
    );

    try {
      final result = await TranslationService.translateText(
        text: text,
        provider: provider,
        model: model,
        apiKey: apiKey,
        glossary: glossary,
        novelContext: novelContext,
        onProgress: (current, total, msg) {
          state = state.copyWith(
            currentChunk: current,
            totalChunks: total,
            statusMessage: msg,
          );
        },
      );

      final chapter = Chapter(
        novelId: novelId,
        url: 'text-input-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Manual Input',
        originalText: text,
        translatedText: result.translatedText,
        translatedAt: DateTime.now(),
      );

      await DatabaseService.insertChapter(chapter);

      state = state.copyWith(
        currentChapter: chapter,
        isTranslating: false,
        statusMessage: 'Translation complete',
      );
    } catch (e) {
      state = state.copyWith(
        isTranslating: false,
        error: e.toString(),
        statusMessage: 'Translation failed',
      );
    }
  }

  /// Load an already-translated chapter
  void loadChapter(Chapter chapter) {
    state = ReaderState(currentChapter: chapter);
  }

  /// Toggle showing original text
  void toggleOriginal() {
    state = state.copyWith(showOriginal: !state.showOriginal);
  }

  /// Update a paragraph's translation (inline edit)
  Future<void> editParagraph(int index, String newText) async {
    if (state.currentChapter == null) return;

    final edits =
        Map<String, String>.from(state.currentChapter!.editedParagraphs ?? {});
    edits[index.toString()] = newText;

    final updated = state.currentChapter!.copyWith(editedParagraphs: edits);
    await DatabaseService.updateChapter(updated);
    state = state.copyWith(currentChapter: updated);
  }

  /// Clear current state
  void clear() {
    state = const ReaderState();
  }
}

final readerProvider =
    StateNotifierProvider<ReaderNotifier, ReaderState>((ref) {
  return ReaderNotifier();
});
