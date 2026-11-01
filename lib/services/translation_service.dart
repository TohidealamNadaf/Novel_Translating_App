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
    required Map<String, String?> apiKeys,
    required List<GlossaryEntry> glossary,
    String? novelContext,
    int chapterNumber = 0,
    bool forceRetranslate = false,
    ProgressCallback? onProgress,
  }) async {
    // Check if already translated
    final existing = await DatabaseService.getChapterByUrl(novelId, url);
    if (!forceRetranslate && existing != null && existing.translatedText != null) {
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
      apiKeys: apiKeys,
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
    required Map<String, String?> apiKeys,
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
      return await _translateChunkWithFallback(
        text: chunks[0],
        primaryProvider: provider,
        primaryModel: model,
        apiKeys: apiKeys,
        systemPrompt: systemPrompt,
        onProgress: onProgress,
        currentChunk: 1,
        totalChunks: 1,
      );
    }

    // Multi-chunk translation
    final translatedParts = <String>[];
    String? lastGlossary;

    for (int i = 0; i < totalChunks; i++) {
      onProgress?.call(i + 1, totalChunks, 'Translating chunk ${i + 1}/$totalChunks...');

      final result = await _translateChunkWithFallback(
        text: chunks[i],
        primaryProvider: provider,
        primaryModel: model,
        apiKeys: apiKeys,
        systemPrompt: systemPrompt,
        onProgress: onProgress,
        currentChunk: i + 1,
        totalChunks: totalChunks,
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

  static Future<TranslationResult> _translateChunkWithFallback({
    required String text,
    required String primaryProvider,
    required String primaryModel,
    required Map<String, String?> apiKeys,
    required String systemPrompt,
    ProgressCallback? onProgress,
    int currentChunk = 1,
    int totalChunks = 1,
  }) async {
    // 1. Try primary provider
    final primaryKey = apiKeys[primaryProvider];
    if (primaryKey != null && primaryKey.isNotEmpty) {
      try {
        return await AIProviderService.translateChunk(
          text: text,
          provider: primaryProvider,
          model: primaryModel,
          apiKey: primaryKey,
          systemPrompt: systemPrompt,
        );
      } catch (e) {
        final errorStr = e.toString().toLowerCase();
        if (!errorStr.contains('429') && !errorStr.contains('quota') && !errorStr.contains('402') && !errorStr.contains('rate')) {
          rethrow;
        }
        // It's a quota error, fall through to fallback loop
      }
    }

    // 2. Fallback loop
    final fallbackProviders = ['gemini', 'mistral', 'deepseek', 'openrouter', 'grok'];
    for (final p in fallbackProviders) {
      if (p == primaryProvider) continue;
      final key = apiKeys[p];
      if (key == null || key.isEmpty) continue;

      final fallbackModel = ProviderModels.models[p]?.first;
      if (fallbackModel == null) continue;

      onProgress?.call(currentChunk, totalChunks, 'Falling back to ${ProviderModels.providerNames[p] ?? p}...');

      try {
        return await AIProviderService.translateChunk(
          text: text,
          provider: p,
          model: fallbackModel,
          apiKey: key,
          systemPrompt: systemPrompt,
        );
      } catch (e) {
        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('429') || errorStr.contains('quota') || errorStr.contains('402') || errorStr.contains('rate')) {
          continue; // try next provider
        }
        rethrow; 
      }
    }

    throw Exception('All available providers failed due to quota/rate limits. Please check your API keys and billing.');
  }

  /// Chunk text by paragraphs, respecting max chunk size
  static List<String> _chunkText(String text) {
    if (text.length <= AppDefaults.maxChunkCharacters) {
      return [text];
    }

    final paragraphs = text.split(RegExp(r'\r?\n+'));
    final chunks = <String>[];
    var currentChunk = StringBuffer();

    for (final para in paragraphs) {
      if (currentChunk.length + para.length + 2 >
          AppDefaults.maxChunkCharacters) {
        if (currentChunk.isNotEmpty) {
          chunks.add(currentChunk.toString().trim());
          currentChunk = StringBuffer();
        }

        // If a single paragraph exceeds chunk size, split it forcefully
        if (para.length > AppDefaults.maxChunkCharacters) {
          int start = 0;
          while (start < para.length) {
            int end = start + AppDefaults.maxChunkCharacters;
            if (end > para.length) end = para.length;
            chunks.add(para.substring(start, end));
            start = end;
          }
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
      // Strip leading bullets, numbers, or dashes
      final trimmed = line.replaceAll(RegExp(r'^[\-\*\•\d\.]+\s*'), '').trim();
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
