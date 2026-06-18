import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../models/novel.dart';
import '../providers/novel_provider.dart';
import '../providers/settings_provider.dart';
import '../services/chapter_scraper_service.dart';
import '../widgets/model_selector_widget.dart';

class AddNovelScreen extends ConsumerStatefulWidget {
  const AddNovelScreen({super.key});

  @override
  ConsumerState<AddNovelScreen> createState() => _AddNovelScreenState();
}

class _AddNovelScreenState extends ConsumerState<AddNovelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _urlController = TextEditingController();
  final _textController = TextEditingController();
  final _titleController = TextEditingController();
  final _coverController = TextEditingController();

  String _selectedProvider = AppDefaults.defaultProvider;
  String _selectedModel = AppDefaults.defaultModel;
  String _selectedLanguage = 'auto';
  bool _isFetching = false;
  String? _fetchError;
  String? _previewText;
  String? _detectedLanguage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Load defaults
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final defaults = ref.read(defaultModelProvider);
      setState(() {
        _selectedProvider = defaults.provider;
        _selectedModel = defaults.model;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _urlController.dispose();
    _textController.dispose();
    _titleController.dispose();
    _coverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Add Novel'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.link), text: 'By URL'),
            Tab(icon: Icon(Icons.text_fields), text: 'By Text'),
          ],
          indicatorColor: AppTheme.brandPrimary,
          labelColor: AppTheme.brandPrimary,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUrlTab(theme),
          _buildTextTab(theme),
        ],
      ),
    );
  }

  Widget _buildUrlTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // URL input
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'Chapter URL',
              hintText: 'https://novelbin.me/novel/...',
              prefixIcon: Icon(Icons.link),
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 16),

          // Title
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Novel Title (optional)',
              hintText: 'Will be auto-detected if empty',
              prefixIcon: Icon(Icons.title),
            ),
          ),
          const SizedBox(height: 16),

          // Cover URL
          TextField(
            controller: _coverController,
            decoration: const InputDecoration(
              labelText: 'Cover Image URL (optional)',
              hintText: 'https://...',
              prefixIcon: Icon(Icons.image_outlined),
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 24),

          // Model selector
          ModelSelectorWidget(
            selectedProvider: _selectedProvider,
            selectedModel: _selectedModel,
            onProviderChanged: (p) => setState(() {
              _selectedProvider = p;
              _selectedModel = ProviderModels.models[p]!.first;
            }),
            onModelChanged: (m) => setState(() => _selectedModel = m),
          ),
          const SizedBox(height: 24),

          // Fetch button
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isFetching ? null : _fetchAndPreview,
              icon: _isFetching
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.download),
              label: Text(_isFetching ? 'Fetching...' : 'Fetch & Preview'),
            ),
          ),

          // Error message
          if (_fetchError != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: theme.colorScheme.error.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline,
                      color: theme.colorScheme.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_fetchError!,
                        style: TextStyle(color: theme.colorScheme.error)),
                  ),
                ],
              ),
            ),
          ],

          // Preview
          if (_previewText != null) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                if (_detectedLanguage != null) ...[
                  Chip(
                    label: Text('Detected: $_detectedLanguage'),
                    avatar: const Icon(Icons.language, size: 16),
                  ),
                  const SizedBox(width: 8),
                ],
                const Spacer(),
                Text(
                  '${_previewText!.length} chars',
                  style: theme.textTheme.labelMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 200,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outline),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _previewText!,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _addNovelFromUrl,
                icon: const Icon(Icons.add),
                label: const Text('Add to Library & Translate'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Language selector
          DropdownButtonFormField<String>(
            value: _selectedLanguage,
            decoration: const InputDecoration(
              labelText: 'Source Language',
              prefixIcon: Icon(Icons.language),
            ),
            items: const [
              DropdownMenuItem(value: 'auto', child: Text('Auto-detect')),
              DropdownMenuItem(value: 'Chinese', child: Text('Chinese')),
              DropdownMenuItem(value: 'Korean', child: Text('Korean')),
              DropdownMenuItem(value: 'Japanese', child: Text('Japanese')),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _selectedLanguage = v);
            },
          ),
          const SizedBox(height: 16),

          // Title
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Novel Title',
              prefixIcon: Icon(Icons.title),
            ),
          ),
          const SizedBox(height: 16),

          // Text input
          TextField(
            controller: _textController,
            decoration: const InputDecoration(
              labelText: 'Paste raw text',
              hintText: 'Paste the foreign language chapter text here...',
              alignLabelWithHint: true,
            ),
            maxLines: 12,
            minLines: 8,
          ),
          const SizedBox(height: 24),

          // Model selector
          ModelSelectorWidget(
            selectedProvider: _selectedProvider,
            selectedModel: _selectedModel,
            onProviderChanged: (p) => setState(() {
              _selectedProvider = p;
              _selectedModel = ProviderModels.models[p]!.first;
            }),
            onModelChanged: (m) => setState(() => _selectedModel = m),
          ),
          const SizedBox(height: 24),

          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _addNovelFromText,
              icon: const Icon(Icons.translate),
              label: const Text('Add & Translate'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchAndPreview() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() => _fetchError = 'Please enter a URL');
      return;
    }

    setState(() {
      _isFetching = true;
      _fetchError = null;
      _previewText = null;
    });

    try {
      final scraped = await ChapterScraperService.scrapeChapter(url);
      setState(() {
        _previewText = scraped.content.length > 1000
            ? '${scraped.content.substring(0, 1000)}...'
            : scraped.content;
        _detectedLanguage = scraped.detectedLanguage;
        if (_titleController.text.isEmpty) {
          _titleController.text = scraped.title;
        }
      });
    } catch (e) {
      setState(() => _fetchError = e.toString());
    } finally {
      setState(() => _isFetching = false);
    }
  }

  void _addNovelFromUrl() {
    final url = _urlController.text.trim();
    final title =
        _titleController.text.trim().isEmpty ? 'Untitled Novel' : _titleController.text.trim();
    final cover = _coverController.text.trim();

    // Check API key
    if (!ref.read(apiKeyProvider.notifier).hasKey(_selectedProvider)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${ProviderModels.providerNames[_selectedProvider]} API key not found. Go to Settings → API Keys.'),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
        ),
      );
      return;
    }

    final novel = Novel(
      title: title,
      coverImageUrl: cover.isNotEmpty ? cover : null,
      sourceLanguage: _detectedLanguage,
      currentChapterUrl: url,
      selectedProvider: _selectedProvider,
      selectedModel: _selectedModel,
    );

    ref.read(novelListProvider.notifier).addNovel(novel);
    context.go('/novel/${novel.id}/read');
  }

  void _addNovelFromText() {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please paste some text to translate'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final title = _titleController.text.trim().isEmpty
        ? 'Manual Input'
        : _titleController.text.trim();
    final lang = _selectedLanguage == 'auto'
        ? ChapterScraperService.detectLanguage(text)
        : _selectedLanguage;

    final novel = Novel(
      title: title,
      sourceLanguage: lang,
      currentChapterUrl: 'text-input-${DateTime.now().millisecondsSinceEpoch}',
      selectedProvider: _selectedProvider,
      selectedModel: _selectedModel,
    );

    ref.read(novelListProvider.notifier).addNovel(novel);
    context.go('/novel/${novel.id}/read');
  }
}
