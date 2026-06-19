import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

/// Supported AI providers
enum AIProvider { openai, gemini, mistral, deepseek }

/// Result of a translation request
class TranslationResult {
  final String translatedText;
  final String? newGlossarySection;
  final int tokensUsed;

  TranslationResult({
    required this.translatedText,
    this.newGlossarySection,
    this.tokensUsed = 0,
  });
}

class AIProviderService {
  /// Translate text using the selected AI provider.
  static Future<TranslationResult> translateChunk({
    required String text,
    required String provider,
    required String model,
    required String apiKey,
    required String systemPrompt,
  }) async {
    switch (provider) {
      case 'openai':
        return _callOpenAI(text, model, apiKey, systemPrompt);
      case 'gemini':
        return _callGemini(text, model, apiKey, systemPrompt);
      case 'mistral':
        return _callMistral(text, model, apiKey, systemPrompt);
      case 'deepseek':
        return _callDeepSeek(text, model, apiKey, systemPrompt);
      default:
        throw Exception('Unknown provider: $provider');
    }
  }

  // ─── OpenAI ───
  static Future<TranslationResult> _callOpenAI(
    String text,
    String model,
    String apiKey,
    String systemPrompt,
  ) async {
    final body = jsonEncode({
      'model': model,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': text},
      ],
      'temperature': 0.3,
      'max_tokens': 8000,
    });

    final response = await _postWithRetry(
      Uri.parse(ApiEndpoints.openai),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: body,
    );

    final data = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw Exception(
          'OpenAI error ${response.statusCode}: ${data['error']?['message'] ?? response.body}');
    }

    final content = data['choices'][0]['message']['content'] as String;
    final tokens = data['usage']?['total_tokens'] as int? ?? 0;

    return _parseResult(content, tokens);
  }

  static Future<TranslationResult> _callGemini(
    String text,
    String model,
    String apiKey,
    String systemPrompt,
  ) async {
    final allModels = ProviderModels.models['gemini'] ?? [];

    Future<TranslationResult> attemptModel(String activeModel) async {
      final url = '${ApiEndpoints.gemini}/$activeModel:generateContent?key=$apiKey';

      final body = jsonEncode({
        'system_instruction': {
          'parts': [{'text': systemPrompt}]
        },
        'contents': [
          {
            'parts': [{'text': text}]
          }
        ],
        'generationConfig': {
          'temperature': 0.3,
          'maxOutputTokens': 8000,
        },
      });

      final response = await _postWithRetry(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      final data = jsonDecode(response.body);
      if (response.statusCode != 200) {
        throw Exception(
            'Gemini error ${response.statusCode}: ${data['error']?['message'] ?? response.body}');
      }

      final content =
          data['candidates'][0]['content']['parts'][0]['text'] as String;
      final tokens = data['usageMetadata']?['totalTokenCount'] as int? ?? 0;

      return _parseResult(content, tokens);
    }

    Object? firstError;
    try {
      return await attemptModel(model);
    } catch (e) {
      firstError = e;
      final errStr = e.toString().toLowerCase();
      final shouldFallback = errStr.contains('404') ||
          errStr.contains('not found') ||
          errStr.contains('503') ||
          errStr.contains('high demand') ||
          errStr.contains('overloaded');

      if (shouldFallback) {
        for (final fallbackModel in allModels) {
          if (fallbackModel == model) continue;
          try {
            return await attemptModel(fallbackModel);
          } catch (e2) {
            firstError = e2;
            continue;
          }
        }
      }
      throw Exception('Gemini translation failed. Error: $firstError');
    }
  }

  // ─── Mistral ───
  static Future<TranslationResult> _callMistral(
    String text,
    String model,
    String apiKey,
    String systemPrompt,
  ) async {
    final body = jsonEncode({
      'model': model,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': text},
      ],
      'temperature': 0.3,
      'max_tokens': 8000,
    });

    final response = await _postWithRetry(
      Uri.parse(ApiEndpoints.mistral),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: body,
    );

    final data = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw Exception(
          'Mistral error ${response.statusCode}: ${data['error']?['message'] ?? response.body}');
    }

    final content = data['choices'][0]['message']['content'] as String;
    final tokens = data['usage']?['total_tokens'] as int? ?? 0;

    return _parseResult(content, tokens);
  }

  // ─── DeepSeek ───
  static Future<TranslationResult> _callDeepSeek(
    String text,
    String model,
    String apiKey,
    String systemPrompt,
  ) async {
    final body = jsonEncode({
      'model': model,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': text},
      ],
      'temperature': 0.3,
      'max_tokens': 8000,
    });

    final response = await _postWithRetry(
      Uri.parse(ApiEndpoints.deepseek),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: body,
    );

    final data = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw Exception(
          'DeepSeek error ${response.statusCode}: ${data['error']?['message'] ?? response.body}');
    }

    final content = data['choices'][0]['message']['content'] as String;
    final tokens = data['usage']?['total_tokens'] as int? ?? 0;

    return _parseResult(content, tokens);
  }

  // ─── Helpers ───

  /// POST with retry logic — 3 retries with exponential backoff on 429/5xx
  static Future<http.Response> _postWithRetry(
    Uri url, {
    required Map<String, String> headers,
    required String body,
  }) async {
    for (int attempt = 0; attempt < AppDefaults.maxRetries; attempt++) {
      final client = http.Client();
      try {
        final response = await client
            .post(url, headers: headers, body: body)
            .timeout(const Duration(seconds: 180));

        if (response.statusCode == 429 || response.statusCode >= 500) {
          if (attempt < AppDefaults.maxRetries - 1) {
            final delay = AppDefaults.retryBaseDelay * (1 << attempt);
            await Future.delayed(delay);
            continue;
          }
        }
        return response;
      } catch (e) {
        if (attempt < AppDefaults.maxRetries - 1) {
          final delay = AppDefaults.retryBaseDelay * (1 << attempt);
          await Future.delayed(delay);
          continue;
        }
        throw Exception(
            'Connection lost or timed out after ${AppDefaults.maxRetries} attempts. Please try again later.\n\nError: $e');
      } finally {
        client.close();
      }
    }
    throw Exception('Max retries exceeded');
  }

  /// Parse the AI response to separate translated text from "New Glossary" section
  static TranslationResult _parseResult(String content, int tokens) {
    String translatedText = content;
    String? glossarySection;

    // Look for "New Glossary:" section at the end, finding the LAST match
    final glossaryPattern = RegExp(
        r'\n\s*(?:\*\*|##\s*)?New Glossary(?:\*\*|:)?\s*\n',
        caseSensitive: false);

    final matches = glossaryPattern.allMatches(content);
    if (matches.isNotEmpty) {
      final match = matches.last;
      translatedText = content.substring(0, match.start).trim();
      glossarySection = content.substring(match.end).trim();
    }

    return TranslationResult(
      translatedText: translatedText,
      newGlossarySection: glossarySection,
      tokensUsed: tokens,
    );
  }

  /// Generate a short summary and bullet points of key events for a chapter
  static Future<ChapterSummary> generateChapterSummary({
    required String text,
    required String provider,
    required String model,
    required String apiKey,
  }) async {
    final systemPrompt = '''
You are a helpful AI reading assistant. Your task is to summarize the provided novel chapter.
Return your response ONLY as a JSON object with the following structure:
{
  "overview": "A brief 2-3 sentence overview of the chapter.",
  "keyEvents": [
    "Key event 1",
    "Key event 2"
  ]
}
Do not include markdown blocks or any other text outside the JSON.
''';

    final result = await translateChunk(
      text: text,
      provider: provider,
      model: model,
      apiKey: apiKey,
      systemPrompt: systemPrompt,
    );

    try {
      final jsonStr = result.translatedText.replaceAll(RegExp(r'```json|```'), '').trim();
      final data = jsonDecode(jsonStr);
      return ChapterSummary(
        overview: data['overview'] ?? 'No overview provided.',
        keyEvents: List<String>.from(data['keyEvents'] ?? []),
      );
    } catch (e) {
      // Fallback if AI fails to return JSON
      return ChapterSummary(
        overview: result.translatedText,
        keyEvents: [],
      );
    }
  }
}

class ChapterSummary {
  final String overview;
  final List<String> keyEvents;

  ChapterSummary({
    required this.overview,
    required this.keyEvents,
  });
}
