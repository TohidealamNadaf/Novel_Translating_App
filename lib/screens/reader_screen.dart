import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../models/novel.dart';
import '../providers/novel_provider.dart';
import '../providers/reader_provider.dart';
import '../providers/glossary_provider.dart';
import '../providers/settings_provider.dart';
import '../services/ai_provider_service.dart';
import '../services/database_service.dart';
import '../widgets/chapter_text_widget.dart';
import '../widgets/reader_bottom_controls.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  final String novelId;

  const ReaderScreen({super.key, required this.novelId});

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  final ScrollController _scrollController = ScrollController();
  Novel? _novel;
  final _manualUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadNovelAndTranslate();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _manualUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadNovelAndTranslate() async {
    final novel = await DatabaseService.getNovel(widget.novelId);
    if (novel == null || !mounted) return;

    setState(() => _novel = novel);

    // Check if chapter already translated
    final existingChapter = await DatabaseService.getChapterByUrl(
        novel.id, novel.currentChapterUrl);

    if (!mounted) return;

    if (existingChapter != null && existingChapter.translatedText != null) {
      ref.read(readerProvider.notifier).loadChapter(existingChapter);
      return;
    }

    // If URL looks like a text-input, don't try to scrape
    if (novel.currentChapterUrl.startsWith('text-input-')) {
      return;
    }

    _startTranslation(novel.currentChapterUrl);
  }

  Future<void> _startTranslation(String url, {bool forceRetranslate = false}) async {
    if (_novel == null || !mounted) return;

    try {
      final apiKeys = <String, String?>{};
      final keys = ref.read(apiKeyProvider);
      
      for (final provider in ProviderModels.models.keys) {
        String? key = keys[provider];
        if (key == null || key.isEmpty) {
          try {
            key = await const FlutterSecureStorage()
                .read(key: 'api_key_$provider');
          } catch (_) {}
        }
        apiKeys[provider] = key;
      }

      // Fallback: try any provider that has a key if primary doesn't
      if (apiKeys[_novel!.selectedProvider] == null || apiKeys[_novel!.selectedProvider]!.isEmpty) {
        final availableProvider = apiKeys.keys.firstWhere(
            (p) => apiKeys[p] != null && apiKeys[p]!.isNotEmpty,
            orElse: () => '');
        
        if (availableProvider.isNotEmpty) {
           final models = ProviderModels.models[availableProvider] ?? [];
           if (models.isNotEmpty) {
             _novel = _novel!.copyWith(
               selectedProvider: availableProvider,
               selectedModel: models.first,
             );
           }
        }
      }

      if (!mounted) return;

      if (apiKeys[_novel!.selectedProvider] == null || apiKeys[_novel!.selectedProvider]!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('API key not found. Go to Settings → API Keys.'),
            behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'Settings',
                onPressed: () => context.push('/settings'),
              ),
          ),
        );
        return;
      }

      final glossary =
          ref.read(glossaryProvider(widget.novelId)).valueOrNull ?? [];

      String activeModel = _novel!.selectedModel;
      final allowedModels = ProviderModels.models[_novel!.selectedProvider] ?? [];
      if (!allowedModels.contains(activeModel) && allowedModels.isNotEmpty) {
        activeModel = allowedModels.first;
      }

      await ref.read(readerProvider.notifier).translateChapter(
            url: url,
            novelId: widget.novelId,
            provider: _novel!.selectedProvider,
            model: activeModel,
            apiKeys: apiKeys,
            glossary: glossary,
            novelContext: _novel!.title,
            chapterNumber: _novel!.totalChaptersTranslated + 1,
            forceRetranslate: forceRetranslate,
          );

      if (!mounted) return;

      // Update novel's chapter count and last read
      if (ref.read(readerProvider).currentChapter != null) {
        final updatedNovel = _novel!.copyWith(
          currentChapterUrl: url,
          nextChapterUrl:
              ref.read(readerProvider).currentChapter?.nextChapterUrl,
          lastReadAt: DateTime.now(),
          totalChaptersTranslated: _novel!.totalChaptersTranslated + 1,
        );
        await DatabaseService.updateNovel(updatedNovel);
        ref.read(novelListProvider.notifier).loadNovels();
        if (mounted) setState(() => _novel = updatedNovel);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Translation error: $e'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final readerState = ref.watch(readerProvider);
    final readingTheme = ref.watch(themeProvider);
    final fontSettings = ref.watch(fontSettingsProvider);
    final bgColor = AppTheme.readingBackground(readingTheme);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _novel?.title ?? 'Loading...',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            if (readerState.currentChapter != null) {
              _showControlsBottomSheet(context, readerState);
            }
          },
          child: _buildContent(theme, readerState, readingTheme, fontSettings),
        ),
      ),
      bottomNavigationBar: readerState.currentChapter != null
          ? _buildBottomBar(theme, readerState)
          : null,
    );
  }

  void _showControlsBottomSheet(BuildContext context, ReaderState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReaderBottomControls(
        novel: _novel,
        onNextChapter: _handleNextChapter,
        onPrevChapter: () {}, // placeholder
        currentText: state.showOriginal
            ? (state.currentChapter?.originalText ?? '')
            : (state.currentChapter?.translatedText ?? ''),
        isBottomSheet: true,
      ),
    );
  }


  Widget _buildContent(ThemeData theme, ReaderState state,
      ReadingTheme readingTheme, FontSettings fontSettings) {
    // Loading state
    if (state.isTranslating) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 16),
            Text(
              state.statusMessage,
              style: theme.textTheme.titleMedium,
            ),
            if (state.totalChunks > 1) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  value: state.currentChunk / state.totalChunks,
                  backgroundColor:
                      theme.colorScheme.outline.withOpacity(0.2),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Chunk ${state.currentChunk}/${state.totalChunks}',
                style: theme.textTheme.labelMedium,
              ),
            ],
          ],
        ),
      );
    }

    // Error state
    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text('Translation Failed',
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                state.error!,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      if (_novel != null) {
                        _startTranslation(_novel!.currentChapterUrl);
                      }
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () =>
                        ref.read(readerProvider.notifier).toggleOriginal(),
                    child: const Text('Show Original'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // No chapter loaded
    if (state.currentChapter == null) {
      return const Center(
        child: Text('No chapter loaded'),
      );
    }

    // Translated content
    final chapter = state.currentChapter!;
    final displayText = state.showOriginal
        ? (chapter.originalText ?? 'No original text')
        : (chapter.translatedText ?? 'No translation available');

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chapter title
          if (chapter.title != null) ...[
            Text(
              chapter.title!,
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
          ],

          // Toggle indicator
          if (state.showOriginal)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.brandAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.language, size: 16, color: AppTheme.brandAccent),
                  SizedBox(width: 6),
                  Text(
                    'Showing original text',
                    style: TextStyle(
                        color: AppTheme.brandAccent, fontSize: 12),
                  ),
                ],
              ),
            ),

          // Chapter content
          ChapterTextWidget(
            text: displayText,
            readingTheme: readingTheme,
            fontSize: fontSettings.fontSize,
            useSerif: fontSettings.useSerif,
            editedParagraphs: state.showOriginal ? null : chapter.editedParagraphs,
            onLongPressParagraph: state.showOriginal
                ? null
                : (index, currentText) {
                    _showEditDialog(index, currentText);
                  },
          ),

          const SizedBox(height: 60), // Bottom padding for nav bar
        ],
      ),
    );
  }

  Future<void> _handleNextChapter() async {
    if (_novel == null) return;

    final currentState = ref.read(readerProvider);
    final nextUrl = currentState.currentChapter?.nextChapterUrl ??
        _novel!.nextChapterUrl;

    if (nextUrl != null && nextUrl.isNotEmpty) {
      // Auto-translate: scroll to top and start immediately
      _scrollController.jumpTo(0);
      ref.read(readerProvider.notifier).clear();
      _startTranslation(nextUrl);
    } else {
      // No URL found — ask for manual input
      _showManualUrlDialog();
    }
  }

  void _showManualUrlDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Next Chapter URL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Could not detect the next chapter automatically. Please paste the URL:'),
            const SizedBox(height: 12),
            TextField(
              controller: _manualUrlController,
              decoration: const InputDecoration(
                hintText: 'https://...',
                prefixIcon: Icon(Icons.link),
              ),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final url = _manualUrlController.text.trim();
              if (url.isNotEmpty) {
                Navigator.pop(ctx);
                _scrollController.jumpTo(0);
                ref.read(readerProvider.notifier).clear();
                _startTranslation(url);
              }
            },
            child: const Text('Translate'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(int paragraphIndex, String currentText) {
    final controller = TextEditingController(text: currentText);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Paragraph'),
        content: TextField(
          controller: controller,
          maxLines: 8,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(readerProvider.notifier)
                  .editParagraph(paragraphIndex, controller.text);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ThemeData theme, ReaderState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.95),
        border: Border(
          top: BorderSide(
              color: theme.colorScheme.outline.withOpacity(0.2)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          const _BottomBarButton(
            icon: Icons.arrow_back_ios_rounded,
            label: 'Prev',
            onTap: null, // placeholder
          ),
          _BottomBarButton(
            icon: state.showOriginal ? Icons.translate : Icons.language,
            label: state.showOriginal ? 'Translated' : 'Original',
            onTap: () =>
                ref.read(readerProvider.notifier).toggleOriginal(),
          ),
          _BottomBarButton(
            icon: Icons.book_outlined,
            label: 'Glossary',
            onTap: () => context.push('/novel/${widget.novelId}/glossary'),
          ),
          _BottomBarButton(
            icon: Icons.auto_awesome,
            label: 'Summarize',
            onTap: state.currentChapter == null || state.isTranslating
                ? null
                : () async {
                    final chapter = state.currentChapter!;
                    final textToSummarize = state.showOriginal
                        ? chapter.originalText
                        : chapter.translatedText;
                    if (textToSummarize != null && textToSummarize.isNotEmpty) {
                      // Fetch API Key
                      final keys = ref.read(apiKeyProvider);
                      String? apiKey = keys[_novel?.selectedProvider ?? 'gemini'];
                      if (apiKey == null || apiKey.isEmpty) {
                        apiKey = await const FlutterSecureStorage().read(key: 'api_key_${_novel?.selectedProvider ?? 'gemini'}');
                      }
                      if (apiKey == null || apiKey.isEmpty) {
                        for (final provider in ['gemini', 'openai', 'mistral', 'deepseek']) {
                          final fallbackKey = await const FlutterSecureStorage().read(key: 'api_key_$provider');
                          if (fallbackKey != null && fallbackKey.isNotEmpty) {
                            apiKey = fallbackKey;
                            break;
                          }
                        }
                      }
                      
                      if (apiKey == null || apiKey.isEmpty) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No API Key found for summarization.')),
                          );
                        }
                        return;
                      }

                      if (context.mounted) {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (ctx) => _SummaryBottomSheet(
                            chapterTitle: chapter.title ?? 'Chapter',
                            content: textToSummarize,
                            apiKey: apiKey!,
                          ),
                        );
                      }
                    }
                  },
          ),
          _BottomBarButton(
            icon: Icons.refresh,
            label: 'Re-translate',
            onTap: state.isTranslating
                ? null
                : () {
                    if (_novel != null) {
                      _startTranslation(_novel!.currentChapterUrl, forceRetranslate: true);
                    }
                  },
          ),
          _BottomBarButton(
            icon: Icons.arrow_forward_ios_rounded,
            label: 'Next',
            isHighlighted: true,
            onTap: state.isTranslating ? null : _handleNextChapter,
          ),
        ],
      ),
    );
  }
}

class _BottomBarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isHighlighted;

  const _BottomBarButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: onTap == null
                  ? Theme.of(context).colorScheme.outline
                  : isHighlighted
                      ? AppTheme.brandPrimary
                      : null,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: onTap == null
                    ? Theme.of(context).colorScheme.outline
                    : isHighlighted
                        ? AppTheme.brandPrimary
                        : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryBottomSheet extends StatefulWidget {
  final String chapterTitle;
  final String content;
  final String apiKey;

  const _SummaryBottomSheet({
    required this.chapterTitle,
    required this.content,
    required this.apiKey,
  });

  @override
  State<_SummaryBottomSheet> createState() => _SummaryBottomSheetState();
}

class _SummaryBottomSheetState extends State<_SummaryBottomSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  SummaryResult? _summaryResult;
  String? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _generateSummary();
  }

  Future<void> _generateSummary() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await AIProviderService.summarizeChapter(
        content: widget.content,
        title: widget.chapterTitle,
        apiKey: widget.apiKey,
      );
      if (mounted) {
        setState(() {
          _summaryResult = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Container(
      height: size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: AppTheme.brandPrimary, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'AI Summary',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          if (_isLoading)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Analyzing chapter...'),
                  ],
                ),
              ),
            )
          else if (_error != null)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to generate summary',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _generateSummary,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (_summaryResult != null)
            Expanded(
              child: Column(
                children: [
                  TabBar(
                    controller: _tabController,
                    labelColor: AppTheme.brandPrimary,
                    unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                    indicatorColor: AppTheme.brandPrimary,
                    tabs: const [
                      Tab(text: 'Overview'),
                      Tab(text: 'Key Events'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOverviewTab(theme),
                        _buildEventsTab(theme),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Extractive Summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.brandAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.brandAccent.withOpacity(0.2)),
          ),
          child: Text(
            _summaryResult!.extractive,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
              color: AppTheme.brandAccent,
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Structured Overview Sections
        ..._summaryResult!.structuredOverview.map((section) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section['header'] ?? 'Section',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (section['intro'] != null && section['intro'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      section['intro'],
                      style: const TextStyle(fontSize: 15, height: 1.5),
                    ),
                  ),
                if (section['bullets'] != null)
                  ...(section['bullets'] as List).map((bullet) => Padding(
                        padding: const EdgeInsets.only(bottom: 8, left: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                            Expanded(
                              child: Text(
                                bullet.toString(),
                                style: const TextStyle(fontSize: 15, height: 1.5),
                              ),
                            ),
                          ],
                        ),
                      )),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildEventsTab(ThemeData theme) {
    if (_summaryResult!.events.isEmpty) {
      return const Center(child: Text('No events extracted.'));
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _summaryResult!.events.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 4, right: 12),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.brandPrimary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '\${index + 1}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.brandPrimary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  _summaryResult!.events[index],
                  style: const TextStyle(fontSize: 15, height: 1.5),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
