import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../providers/settings_provider.dart';
import '../widgets/reading_theme_toggle.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _controllers = <String, TextEditingController>{};
  final _obscured = <String, bool>{};

  @override
  void initState() {
    super.initState();
    for (final provider in ProviderModels.models.keys) {
      _controllers[provider] = TextEditingController();
      _obscured[provider] = true;
    }
    _loadKeys();
  }

  Future<void> _loadKeys() async {
    final keys = ref.read(apiKeyProvider);
    for (final provider in ProviderModels.models.keys) {
      final key = keys[provider];
      if (key != null && key.isNotEmpty) {
        _controllers[provider]!.text = key;
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final readingTheme = ref.watch(themeProvider);
    final fontSettings = ref.watch(fontSettingsProvider);
    final defaultModel = ref.watch(defaultModelProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ─── API Keys ───
          const _SectionHeader(
            icon: Icons.key_outlined,
            title: 'API Keys',
            subtitle: 'Securely stored on your device',
          ),
          const SizedBox(height: 12),
          ...ProviderModels.models.keys.map((provider) {
            final providerName = ProviderModels.providerNames[provider]!;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextField(
                controller: _controllers[provider],
                obscureText: _obscured[provider]!,
                decoration: InputDecoration(
                  labelText: '$providerName API Key',
                  hintText: 'Enter your $providerName key...',
                  prefixIcon: const Icon(Icons.vpn_key_outlined),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          _obscured[provider]!
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscured[provider] = !_obscured[provider]!;
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.save_outlined),
                        onPressed: () => _saveKey(provider),
                      ),
                    ],
                  ),
                ),
                onSubmitted: (_) => _saveKey(provider),
              ),
            );
          }),

          const Divider(height: 40),

          // ─── Default Model ───
          const _SectionHeader(
            icon: Icons.smart_toy_outlined,
            title: 'Default AI Model',
            subtitle: 'Used when adding new novels',
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: defaultModel.provider,
            decoration: const InputDecoration(
              labelText: 'Provider',
              prefixIcon: Icon(Icons.cloud_outlined),
            ),
            items: ProviderModels.providerNames.entries
                .map((e) => DropdownMenuItem(
                      value: e.key,
                      child: Text(e.value),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) {
                ref.read(defaultModelProvider.notifier).setProvider(v);
              }
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: defaultModel.model,
            decoration: const InputDecoration(
              labelText: 'Model',
              prefixIcon: Icon(Icons.model_training),
            ),
            items: (ProviderModels.models[defaultModel.provider] ?? [])
                .map((m) => DropdownMenuItem(
                      value: m,
                      child: Text(m),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) {
                ref.read(defaultModelProvider.notifier).setModel(v);
              }
            },
          ),

          const Divider(height: 40),

          // ─── Reading Theme ───
          const _SectionHeader(
            icon: Icons.palette_outlined,
            title: 'Reading Theme',
            subtitle: 'Customize your reading experience',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Theme: '),
              const SizedBox(width: 12),
              ReadingThemeToggle(
                currentTheme: readingTheme,
                onChanged: (t) =>
                    ref.read(themeProvider.notifier).setTheme(t),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Font size
          Row(
            children: [
              const Icon(Icons.format_size, size: 20),
              const SizedBox(width: 8),
              Text('Font Size: ${fontSettings.fontSize.round()}px'),
              Expanded(
                child: Slider(
                  value: fontSettings.fontSize,
                  min: 14,
                  max: 22,
                  divisions: 8,
                  label: '${fontSettings.fontSize.round()}',
                  onChanged: (v) =>
                      ref.read(fontSettingsProvider.notifier).setFontSize(v),
                ),
              ),
            ],
          ),

          // Font family
          SwitchListTile(
            title: const Text('Use Serif Font'),
            subtitle: const Text('Merriweather for a novel-like feel'),
            value: fontSettings.useSerif,
            onChanged: (v) =>
                ref.read(fontSettingsProvider.notifier).setUseSerif(v),
            activeThumbColor: theme.colorScheme.primary,
          ),

          const SizedBox(height: 40),

          // ─── About ───
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppTheme.brandPrimary,
                        AppTheme.brandSecondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.auto_stories,
                      size: 32, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text('NovelShift v1.0.0',
                    style: theme.textTheme.titleMedium),
                Text('AI-Powered Web Novel Translator',
                    style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _saveKey(String provider) {
    final key = _controllers[provider]!.text.trim();
    if (key.isNotEmpty) {
      ref.read(apiKeyProvider.notifier).setApiKey(provider, key);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${ProviderModels.providerNames[provider]} key saved securely'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.brandPrimary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.brandPrimary, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            Text(subtitle, style: theme.textTheme.labelMedium),
          ],
        ),
      ],
    );
  }
}
