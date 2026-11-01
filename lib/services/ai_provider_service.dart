import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class AiTranslationResult {
  final String text;
  final int promptTokens;
  final int candidateTokens;

  AiTranslationResult({
    required this.text,
    required this.promptTokens,
    required this.candidateTokens,
  });
}

class SummaryResult {
  final String extractive;
  final List<String> events;
  final List<Map<String, dynamic>> structuredOverview;

  SummaryResult({
    required this.extractive,
    required this.events,
    required this.structuredOverview,
  });

  factory SummaryResult.fromJson(Map<String, dynamic> json) {
    return SummaryResult(
      extractive: json['extractive'] as String? ?? 'Unable to extract summary.',
      events: (json['events'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      structuredOverview: (json['structuredOverview'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
    );
  }
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
          'maxOutputTokens': 16384,
        },
        'safetySettings': [
          {'category': 'HARM_CATEGORY_HARASSMENT', 'threshold': 'BLOCK_ONLY_HIGH'},
          {'category': 'HARM_CATEGORY_HATE_SPEECH', 'threshold': 'BLOCK_ONLY_HIGH'},
          {'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT', 'threshold': 'BLOCK_ONLY_HIGH'},
          {'category': 'HARM_CATEGORY_DANGEROUS_CONTENT', 'threshold': 'BLOCK_ONLY_HIGH'}
        ]
      });

      http.Response response;
      try {
        response = await _postWithRetry(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: body,
        );
      } catch (e) {
        throw Exception('Network error calling Gemini: $e');
      }

      // Parse the JSON response safely
      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        final preview = response.body.length > 200
            ? response.body.substring(0, 200)
            : response.body;
        throw Exception('Failed to parse Gemini response (status ${response.statusCode}): $preview');
      }

      if (response.statusCode != 200) {
        final errorMsg = data['error'] is Map
            ? (data['error'] as Map)['message'] ?? 'Unknown error'
            : response.body.length > 300
                ? response.body.substring(0, 300)
                : response.body;
        throw Exception('Gemini error ${response.statusCode}: $errorMsg');
      }

      // Safely extract candidate
      final candidates = data['candidates'];
      if (candidates == null || candidates is! List || candidates.isEmpty) {
        throw Exception('Gemini returned no candidates. Status: ${response.statusCode}');
      }

      final candidate = candidates[0] as Map<String, dynamic>;
      final finishReason = candidate['finishReason'] as String? ?? '';

      // Check if content was blocked by safety filters
      if (candidate['content'] == null) {
        throw Exception(
            'Gemini blocked this content (finishReason: $finishReason). '
            'The chapter may contain content flagged by safety filters.');
      }

      // Safely extract text
      final contentMap = candidate['content'] as Map<String, dynamic>?;
      final parts = contentMap?['parts'] as List?;
      if (parts == null || parts.isEmpty) {
        throw Exception('Gemini returned empty content. finishReason: $finishReason');
      }

      final translatedText = parts[0]['text'] as String? ?? '';
      if (translatedText.isEmpty) {
        throw Exception('Gemini returned empty text. finishReason: $finishReason');
      }

      final tokens = (data['usageMetadata'] as Map?)?['totalTokenCount'] as int? ?? 0;

      return _parseResult(translatedText, tokens);
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
          errStr.contains('429') ||
          errStr.contains('quota') ||
          errStr.contains('rate') ||
          errStr.contains('high demand') ||
          errStr.contains('overloaded');

      if (shouldFallback) {
        // On rate limit, wait a bit before trying fallback models
        if (errStr.contains('429') || errStr.contains('quota') || errStr.contains('rate')) {
          await Future.delayed(const Duration(seconds: 5));
        }
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
      try {
        final response = await http
            .post(url, headers: headers, body: body)
            .timeout(const Duration(seconds: 120));

        if (response.statusCode == 429 || response.statusCode >= 500) {
          if (attempt < AppDefaults.maxRetries - 1) {
            // Wait longer for rate limits (429) than server errors (5xx)
            final baseDelay = response.statusCode == 429
                ? const Duration(seconds: 10)
                : AppDefaults.retryBaseDelay;
            await Future.delayed(baseDelay * (1 << attempt));
            continue;
          }
        }
        return response;
      } on Exception catch (e) {
        if (attempt < AppDefaults.maxRetries - 1) {
          final delay = AppDefaults.retryBaseDelay * (1 << attempt);
          await Future.delayed(delay);
          continue;
        }
        throw Exception(
            'Connection lost or timed out after ${AppDefaults.maxRetries} attempts. Error: $e');
      } on Error catch (e) {
        // Catch Dart Errors (like RangeError, TypeError) that would crash the app
        throw Exception('Internal error during HTTP request: $e');
      }
    }
    throw Exception('Max retries exceeded');
  }

  /// Summarizes chapter content using JSON-mode
  static Future<SummaryResult> summarizeChapter({
    required String content,
    String? title,
    required String apiKey,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final providerName = prefs.getString('ai_provider') ?? 'gemini';
    final customUrl = prefs.getString('ai_custom_url');
    final customModel = prefs.getString('ai_custom_model');

    final safeContent = content.length > 30000 ? content.substring(0, 30000) : content;

    final systemInstruction = '''
You are an expert novel summarizer.
Analyze the following chapter content titled "${title ?? 'Unknown'}".
Match the tone, mood, and atmosphere of the original text.
Return a strict JSON object with THREE keys:
1. "structuredOverview": An array of section objects representing the summary. Each object must have:
   - "header": A thematic, descriptive title for the section.
   - "intro": A short introductory paragraph for the section.
   - "bullets": An array of strings providing a highly detailed, comprehensive breakdown of the events in this section.
2. "extractive": A brief fallback paragraph summarizing the overall chapter.
3. "events": An array of strings, where each string is a clear bullet point of a key action, revelation, or event that occurred in the chapter.

Output ONLY valid JSON.
''';

    final prompt = 'Chapter Content:\n$safeContent';

    if (providerName == 'gemini') {
      // We'll try flash and lite models, similar to translation
      final allModels = [
        customModel ?? 'gemini-2.5-flash',
        'gemini-2.0-flash-lite',
        'gemini-2.0-flash',
        'gemini-1.5-flash',
        'gemini-1.5-pro',
      ];

      Future<SummaryResult> attemptModel(String model) async {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
        );

        final Map<String, dynamic> body = {
          'systemInstruction': {
            'parts': [
              {'text': systemInstruction}
            ]
          },
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.3,
            'responseMimeType': 'application/json',
          },
          'safetySettings': [
            {
              'category': 'HARM_CATEGORY_HARASSMENT',
              'threshold': 'BLOCK_ONLY_HIGH'
            },
            {
              'category': 'HARM_CATEGORY_HATE_SPEECH',
              'threshold': 'BLOCK_ONLY_HIGH'
            },
            {
              'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
              'threshold': 'BLOCK_ONLY_HIGH'
            },
            {
              'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
              'threshold': 'BLOCK_ONLY_HIGH'
            }
          ],
        };

        final response = await _postWithRetry(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        );

        final data = jsonDecode(response.body);

        if (response.statusCode != 200) {
          throw Exception(
            'Gemini error ${response.statusCode}: ${data['error']?['message'] ?? 'Unknown error'}',
          );
        }

        final candidates = data['candidates'] as List?;
        if (candidates == null || candidates.isEmpty) {
          throw Exception('Gemini returned no candidates.');
        }

        final candidate = candidates[0] as Map<String, dynamic>;
        final finishReason = candidate['finishReason'];

        if (finishReason == 'SAFETY') {
          throw Exception('Content blocked by safety filters.');
        }

        final contentMap = candidate['content'] as Map<String, dynamic>?;
        final parts = contentMap?['parts'] as List?;
        if (parts == null || parts.isEmpty) {
          throw Exception('Gemini returned empty content.');
        }

        String rawJson = parts[0]['text'] as String? ?? '{}';
        rawJson = rawJson.trim();
        if (rawJson.startsWith('```json')) {
          rawJson = rawJson.substring(7);
          if (rawJson.endsWith('```')) {
            rawJson = rawJson.substring(0, rawJson.length - 3);
          }
        }
        
        final parsed = jsonDecode(rawJson) as Map<String, dynamic>;
        return SummaryResult.fromJson(parsed);
      }

      Object? firstError;
      try {
        return await attemptModel(allModels[0]);
      } catch (e) {
        firstError = e;
        final errStr = e.toString().toLowerCase();
        final shouldFallback = errStr.contains('404') ||
            errStr.contains('429') ||
            errStr.contains('quota') ||
            errStr.contains('rate');

        if (shouldFallback) {
          if (errStr.contains('429') || errStr.contains('quota') || errStr.contains('rate')) {
            await Future.delayed(const Duration(seconds: 5));
          }
          for (final fallbackModel in allModels.skip(1)) {
            try {
              return await attemptModel(fallbackModel);
            } catch (e2) {
              firstError = e2;
              continue;
            }
          }
        }
        throw Exception('All models failed. Last error: $firstError');
      }
    }

    throw Exception('Summarization currently only supported for Gemini API.');
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
