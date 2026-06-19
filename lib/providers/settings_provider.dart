import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../core/theme.dart';

// ─── Secure Storage Instance ───
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

// ─── API Key Management ───
class ApiKeyNotifier extends StateNotifier<Map<String, String?>> {
  final FlutterSecureStorage _storage;

  ApiKeyNotifier(this._storage) : super({}) {
    _loadKeys();
  }

  Future<void> _loadKeys() async {
    final keys = <String, String?>{};
    for (final provider in ProviderModels.models.keys) {
      final storageKey = SecureStorageKeys.keyForProvider(provider);
      keys[provider] = await _storage.read(key: storageKey);
    }
    state = keys;
  }

  Future<void> setApiKey(String provider, String key) async {
    final storageKey = SecureStorageKeys.keyForProvider(provider);
    await _storage.write(key: storageKey, value: key);
    final updated = Map<String, String?>.from(state);
    updated[provider] = key;
    state = updated;
  }

  Future<void> removeApiKey(String provider) async {
    final storageKey = SecureStorageKeys.keyForProvider(provider);
    await _storage.delete(key: storageKey);
    final updated = Map<String, String?>.from(state);
    updated[provider] = null;
    state = updated;
  }

  String? getApiKey(String provider) => state[provider];

  bool hasKey(String provider) =>
      state[provider] != null && state[provider]!.isNotEmpty;
}

final apiKeyProvider =
    StateNotifierProvider<ApiKeyNotifier, Map<String, String?>>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return ApiKeyNotifier(storage);
});

// ─── Theme Settings ───
class ThemeNotifier extends StateNotifier<ReadingTheme> {
  ThemeNotifier() : super(ReadingTheme.dark) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString('reading_theme') ?? 'dark';
    state = ReadingTheme.values.firstWhere(
      (t) => t.name == themeName,
      orElse: () => ReadingTheme.dark,
    );
  }

  Future<void> setTheme(ReadingTheme theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('reading_theme', theme.name);
    state = theme;
  }
}

final themeProvider =
    StateNotifierProvider<ThemeNotifier, ReadingTheme>((ref) {
  return ThemeNotifier();
});

// ─── Font Settings ───
class FontSettingsNotifier extends StateNotifier<FontSettings> {
  FontSettingsNotifier() : super(const FontSettings()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = FontSettings(
      fontSize: prefs.getDouble('font_size') ?? 17.0,
      useSerif: prefs.getBool('use_serif') ?? true,
    );
  }

  Future<void> setFontSize(double size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('font_size', size);
    state = FontSettings(fontSize: size, useSerif: state.useSerif);
  }

  Future<void> setUseSerif(bool useSerif) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_serif', useSerif);
    state = FontSettings(fontSize: state.fontSize, useSerif: useSerif);
  }
}

class FontSettings {
  final double fontSize;
  final bool useSerif;

  const FontSettings({this.fontSize = 17.0, this.useSerif = true});
}

final fontSettingsProvider =
    StateNotifierProvider<FontSettingsNotifier, FontSettings>((ref) {
  return FontSettingsNotifier();
});

// ─── Default Provider/Model ───
class DefaultModelNotifier extends StateNotifier<DefaultModelSettings> {
  DefaultModelNotifier()
      : super(const DefaultModelSettings()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = DefaultModelSettings(
      provider: prefs.getString('default_provider') ?? AppDefaults.defaultProvider,
      model: prefs.getString('default_model') ?? AppDefaults.defaultModel,
    );
  }

  Future<void> setProvider(String provider) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('default_provider', provider);
    final models = ProviderModels.models[provider]!;
    final model = models.first;
    await prefs.setString('default_model', model);
    state = DefaultModelSettings(provider: provider, model: model);
  }

  Future<void> setModel(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('default_model', model);
    state = DefaultModelSettings(provider: state.provider, model: model);
  }
}

class DefaultModelSettings {
  final String provider;
  final String model;

  const DefaultModelSettings({
    this.provider = 'openai',
    this.model = 'gpt-4o',
  });
}

final defaultModelProvider =
    StateNotifierProvider<DefaultModelNotifier, DefaultModelSettings>((ref) {
  return DefaultModelNotifier();
});
