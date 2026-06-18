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

  // ─── Gemini ───
  static Future<TranslationResult> _callGemini(
    String text,
    String model,
    String apiKey,
    String systemPrompt,
  ) async {
    final url =
        '${ApiEndpoints.gemini}/$model:generateContent?key=$apiKey';

    final body = jsonEncode({
      'system_instruction': {
        'parts': [
          {'text': systemPrompt}
        ]
      },
      'contents': [
        {
          'parts': [
            {'text': text}
          ]
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
      try {
        final response = await http.post(url, headers: headers, body: body);

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
        rethrow;
      }
    }
    throw Exception('Max retries exceeded');
  }

  /// Parse the AI response to separate translated text from "New Glossary" section
  static TranslationResult _parseResult(String content, int tokens) {
    String translatedText = content;
    String? glossarySection;

    // Look for "New Glossary:" section at the end
    final glossaryPatterns = [
      RegExp(r'\n\s*New Glossary:\s*\n', caseSensitive: false),
      RegExp(r'\n\s*\*\*New Glossary\*\*:?\s*\n', caseSensitive: false),
      RegExp(r'\n\s*## New Glossary\s*\n', caseSensitive: false),
    ];

    for (final pattern in glossaryPatterns) {
      final match = pattern.firstMatch(content);
      if (match != null) {
        translatedText = content.substring(0, match.start).trim();
        glossarySection = content.substring(match.end).trim();
        break;
      }
    }

    return TranslationResult(
      translatedText: translatedText,
      newGlossarySection: glossarySection,
      tokensUsed: tokens,
    );
  }
}
