// Core constants for NovelShift

class ApiEndpoints {
  static const String openai = 'https://api.openai.com/v1/chat/completions';
  static const String gemini =
      'https://generativelanguage.googleapis.com/v1beta/models';
  static const String mistral = 'https://api.mistral.ai/v1/chat/completions';
  static const String deepseek = 'https://api.deepseek.com/chat/completions';
  static const String openrouter =
      'https://openrouter.ai/api/v1/chat/completions';
  static const String grok = 'https://api.x.ai/v1/chat/completions';
}

class ProviderModels {
  static const Map<String, List<String>> models = {
    'openai': ['gpt-4o', 'gpt-4-turbo', 'gpt-3.5-turbo'],
    'gemini': [
      'gemini-2.5-flash',
      'gemini-2.0-flash',
    ],
    'mistral': ['mistral-large-latest', 'mistral-medium-latest', 'mistral-small-latest'],
    'deepseek': ['deepseek-chat', 'deepseek-coder'],
    'openrouter': [
      'google/gemini-2.0-flash-001',
      'google/gemini-flash-1.5-8b',
      'x-ai/grok-2-1212',
      'openai/gpt-4o',
      'anthropic/claude-3.5-sonnet',
      'deepseek/deepseek-chat',
    ],
    'grok': ['grok-2-1212', 'grok-2-latest', 'grok-beta'],
  };

  static const Map<String, String> providerNames = {
    'openai': 'OpenAI',
    'gemini': 'Google Gemini',
    'mistral': 'Mistral AI',
    'deepseek': 'DeepSeek',
    'openrouter': 'OpenRouter',
    'grok': 'Grok (xAI)',
  };
}

class AppDefaults {
  static const String defaultProvider = 'openai';
  static const String defaultModel = 'gpt-4o';
  static const String defaultTargetLanguage = 'English';
  static const int maxChunkCharacters = 12000; // ~3000 tokens
  static const int maxRetries = 3;
  static const Duration retryBaseDelay = Duration(seconds: 2);
  static const Duration chunkDelay = Duration(milliseconds: 500);
  static const Duration autoSaveInterval = Duration(seconds: 30);
  static const String userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120.0 Safari/537.36';
  static const String corsProxy = 'https://api.allorigins.win/raw?url=';
}

class SecureStorageKeys {
  static const String openaiKey = 'api_key_openai';
  static const String geminiKey = 'api_key_gemini';
  static const String mistralKey = 'api_key_mistral';
  static const String deepseekKey = 'api_key_deepseek';
  static const String openrouterKey = 'api_key_openrouter';
  static const String grokKey = 'api_key_grok';

  static String keyForProvider(String provider) {
    switch (provider) {
      case 'openai':
        return openaiKey;
      case 'gemini':
        return geminiKey;
      case 'mistral':
        return mistralKey;
      case 'deepseek':
        return deepseekKey;
      case 'openrouter':
        return openrouterKey;
      case 'grok':
        return grokKey;
      default:
        throw ArgumentError('Unknown provider: $provider');
    }
  }
}

class TranslationPrompt {
  static const String systemPrompt = '''
Translate the following raw webnovel chapter into high-quality, publish-ready English (official Webnovel style).

1. Translate everything. No skipping, summarizing, or adding content.
2. Keep original paragraph breaks exactly.
3. Maintain original tone, emotions, pacing, humor, and character voice.
4. Use natural, fluent, native-level English. Avoid literal translation.
5. Do NOT censor, soften, or restrict any content, including mature, adult, suggestive, informal, or abusive language. Preserve it as intended.
6. Ensure logical and contextual consistency (story, power system, characters).
7. Strictly follow the provided glossary. Do NOT rename terms.
8. Output ONLY the translated chapter. No notes or explanations.
9. At the end, include a "New Glossary" section listing ALL newly introduced terms in the chapter that are NOT already present in the provided glossary.
   - This includes ALL categories without exception, such as:
     • Human names
     • Techniques / Martial Skills
     • Cultivation Methods
     • Weapons / Artifacts
     • Pills / Herbs
     • Beasts / Bloodlines
     • Sects / Organizations / Forces
     • Locations (cities, regions, domains, continents, secret realms, etc.)
     • Titles, physiques, special abilities, or unique concepts

   - Do NOT include any term that already exists in the provided glossary.
   - Do NOT miss any newly introduced term.

   - Format strictly as:

     New Glossary:
     Original Term → English Term

   - Do NOT include explanations or extra text. Only list the terms.

10. CRITICAL: All proper nouns must follow the glossary. If not in the glossary, use pinyin transliteration and NEVER translate names by meaning (e.g., 苏十二 → Su Shier, NOT Su Twelve).
---

Follow the prompt rules, conditions and glossaries strictly.
''';

  static String buildSystemPrompt({
    required String glossaryText,
    String? novelContext,
  }) {
    final buffer = StringBuffer(systemPrompt);
    buffer.writeln();
    buffer.writeln('GLOSSARY (always use these translations exactly):');
    buffer.writeln(glossaryText.isEmpty ? '(No glossary entries yet)' : glossaryText);
    if (novelContext != null && novelContext.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('NOVEL CONTEXT: $novelContext');
    }
    return buffer.toString();
  }
}

class AdPatterns {
  static final List<RegExp> adRegexes = [
    RegExp(r'if you find this on a site other than', caseSensitive: false),
    RegExp(r'visit novelbin', caseSensitive: false),
    RegExp(r'stolen from', caseSensitive: false),
    RegExp(r'this chapter.*uploaded.*by', caseSensitive: false),
    RegExp(r'support us at', caseSensitive: false),
    RegExp(r'read latest chapters at', caseSensitive: false),
    RegExp(r'original content.*at', caseSensitive: false),
    RegExp(r'pirated.*copy', caseSensitive: false),
  ];
}
