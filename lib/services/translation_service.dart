import '../core/constants.dart';
import '../models/glossary_entry.dart';
import '../models/chapter.dart';
import 'ai_provider_service.dart';
import 'chapter_scraper_service.dart';
import 'database_service.dart';

/// Translation progress callback:
/// (currentChunk, totalChunks, statusMessage)
typedef ProgressCallback = void Function(int current, int total, String msg);

/// Orchestrates the full translation pipeline: scrape → chunk → translate → store
class TranslationService {
  /// Translate a chapter from a URL
  static Future<Chapter> translateFromUrl({
    required String url,
    required String novelId,
    required String provider,
    required String model,
    required String apiKey,
    required List<GlossaryEntry> glossary,
    String? novelContext,
    int chapterNumber = 0,
    ProgressCallback? onProgress,
  }) async {
    // Check if already translated
    final existing = await DatabaseService.getChapterByUrl(novelId, url);
    if (existing != null && existing.translatedText != null) {
      return existing;
    }

    onProgress?.call(0, 1, 'Fetching chapter...');

    // Scrape
    final scraped = await ChapterScraperService.scrapeChapter(url);

    // Translate the raw content
    final translated = await translateText(
      text: scraped.content,
      provider: provider,
      model: model,
      apiKey: apiKey,
      glossary: glossary,
      novelContext: novelContext,
      onProgress: onProgress,
    );

    // Store chapter
    final chapter = Chapter(
      novelId: novelId,
      url: url,
      title: scraped.title,
      originalText: scraped.content,
      translatedText: translated.translatedText,
      nextChapterUrl: scraped.nextChapterUrl,
      chapterNumber: chapterNumber,
      translatedAt: DateTime.now(),
    );

    await DatabaseService.insertChapter(chapter);

    // Parse new glossary entries
    if (translated.newGlossarySection != null &&
        translated.newGlossarySection!.isNotEmpty) {
      final newEntries = _parseNewGlossaryEntries(
        translated.newGlossarySection!,
        novelId,
      );
      if (newEntries.isNotEmpty) {
        await DatabaseService.insertGlossaryEntries(newEntries);
      }
    }

    return chapter;
  }

  /// Translate raw text (for the "By Text" flow)
  static Future<TranslationResult> translateText({
    required String text,
    required String provider,
    required String model,
    required String apiKey,
    required List<GlossaryEntry> glossary,
    String? novelContext,
    ProgressCallback? onProgress,
  }) async {
    // Build glossary text
    final activeGlossary = glossary.where((e) => e.isActive).toList();
    final glossaryText = activeGlossary.map((e) => e.toPromptLine()).join('\n');

    // Build system prompt
    final systemPrompt = TranslationPrompt.buildSystemPrompt(
      glossaryText: glossaryText,
      novelContext: novelContext,
    );

    // Chunk the text if it's too long
    final chunks = _chunkText(text);
    final totalChunks = chunks.length;

    if (totalChunks == 1) {
      onProgress?.call(1, 1, 'Translating...');
      return await AIProviderService.translateChunk(
        text: chunks[0],
        provider: provider,
        model: model,
        apiKey: apiKey,
        systemPrompt: systemPrompt,
      );
    }

    // Multi-chunk translation
    final translatedParts = <String>[];
    String? lastGlossary;

    for (int i = 0; i < totalChunks; i++) {
      onProgress?.call(i + 1, totalChunks, 'Translating chunk ${i + 1}/$totalChunks...');

      final result = await AIProviderService.translateChunk(
        text: chunks[i],
        provider: provider,
        model: model,
        apiKey: apiKey,
        systemPrompt: systemPrompt,
      );

      translatedParts.add(result.translatedText);

      if (result.newGlossarySection != null) {
        lastGlossary = '${lastGlossary ?? ''}\n${result.newGlossarySection!}';
      }

      // Rate limit delay between chunks
      if (i < totalChunks - 1) {
        await Future.delayed(AppDefaults.chunkDelay);
      }
    }

    return TranslationResult(
      translatedText: translatedParts.join('\n\n'),
      newGlossarySection: lastGlossary?.trim(),
    );
  }

  /// Chunk text by paragraphs, respecting max chunk size
  static List<String> _chunkText(String text) {
    if (text.length <= AppDefaults.maxChunkCharacters) {
      return [text];
    }

    final paragraphs = text.split('\n\n');
    final chunks = <String>[];
    var currentChunk = StringBuffer();

    for (final para in paragraphs) {
      if (currentChunk.length + para.length + 2 >
          AppDefaults.maxChunkCharacters) {
        if (currentChunk.isNotEmpty) {
          chunks.add(currentChunk.toString().trim());
          currentChunk = StringBuffer();
        }

        // If a single paragraph exceeds chunk size, add it as its own chunk
        if (para.length > AppDefaults.maxChunkCharacters) {
          chunks.add(para);
          continue;
        }
      }

      if (currentChunk.isNotEmpty) {
        currentChunk.write('\n\n');
      }
      currentChunk.write(para);
    }

    if (currentChunk.isNotEmpty) {
      chunks.add(currentChunk.toString().trim());
    }

    return chunks.isEmpty ? [text] : chunks;
  }

  /// Parse "Original → Translation" lines from the new glossary section
  static List<GlossaryEntry> _parseNewGlossaryEntries(
      String glossaryText, String novelId) {
    final entries = <GlossaryEntry>[];
    final lines = glossaryText.split('\n');

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      // Match patterns: "Original → Translation" or "Original -> Translation"
      final arrowMatch =
          RegExp(r'^(.+?)\s*[→\->]+\s*(.+)$').firstMatch(trimmed);
      if (arrowMatch != null) {
        final original = arrowMatch.group(1)!.trim();
        final translated = arrowMatch.group(2)!.trim();

        if (original.isNotEmpty && translated.isNotEmpty) {
          entries.add(GlossaryEntry(
            novelId: novelId,
            original: original,
            translated: translated,
            type: 'term', // Default; user can reclassify later
          ));
        }
      }
    }

    return entries;
  }
}
