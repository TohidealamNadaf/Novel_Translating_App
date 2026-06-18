import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../models/novel.dart';
import '../providers/novel_provider.dart';
import '../providers/reader_provider.dart';
import '../providers/glossary_provider.dart';
import '../providers/settings_provider.dart';
import '../services/database_service.dart';
import '../widgets/chapter_text_widget.dart';
import '../widgets/reading_theme_toggle.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  final String novelId;

  const ReaderScreen({super.key, required this.novelId});

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showSettings = false;
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
    if (novel == null) return;

    setState(() => _novel = novel);

    // Check if chapter already translated
    final existingChapter = await DatabaseService.getChapterByUrl(
        novel.id, novel.currentChapterUrl);

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

  Future<void> _startTranslation(String url) async {
    if (_novel == null) return;

    final keys = ref.read(apiKeyProvider);
    final apiKey = keys[_novel!.selectedProvider];
    if (apiKey == null || apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${_novel!.selectedProvider.toUpperCase()} API key not found. Go to Settings → API Keys.'),
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

    await ref.read(readerProvider.notifier).translateChapter(
          url: url,
          novelId: widget.novelId,
          provider: _novel!.selectedProvider,
          model: _novel!.selectedModel,
          apiKey: apiKey,
          glossary: glossary,
          novelContext: _novel!.title,
          chapterNumber: _novel!.totalChaptersTranslated + 1,
        );

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
      setState(() => _novel = updatedNovel);
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
      body: SafeArea(
        child: Column(
          children: [
            // ─── Top Bar ───
            _buildTopBar(theme, readerState),

            // ─── Settings Panel ───
            if (_showSettings) _buildSettingsPanel(theme, readingTheme, fontSettings),

            // ─── Main Content ───
            Expanded(
              child: _buildContent(
                  theme, readerState, readingTheme, fontSettings),
            ),

            // ─── Bottom Navigation ───
            _buildBottomBar(theme, readerState),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(ThemeData theme, ReaderState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 20),
            onPressed: () => context.pop(),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _novel?.title ?? 'Loading...',
                  style: theme.textTheme.titleMedium?.copyWith(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (state.currentChapter?.title != null)
                  Text(
                    state.currentChapter!.title!,
                    style: theme.textTheme.labelMedium?.copyWith(fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              _showSettings ? Icons.close : Icons.tune,
              size: 20,
            ),
            onPressed: () => setState(() => _showSettings = !_showSettings),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsPanel(
      ThemeData theme, ReadingTheme readingTheme, FontSettings fontSettings) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.2)),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text('Theme: '),
              const SizedBox(width: 8),
              ReadingThemeToggle(
                currentTheme: readingTheme,
                onChanged: (t) =>
                    ref.read(themeProvider.notifier).setTheme(t),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.text_fields, size: 18),
              const SizedBox(width: 8),
              Text('${fontSettings.fontSize.round()}px'),
              Expanded(
                child: Slider(
                  value: fontSettings.fontSize,
                  min: 14,
                  max: 22,
                  divisions: 8,
                  onChanged: (v) =>
                      ref.read(fontSettingsProvider.notifier).setFontSize(v),
                ),
              ),
              TextButton(
                onPressed: () {
                  final current = fontSettings.useSerif;
                  ref
                      .read(fontSettingsProvider.notifier)
                      .setUseSerif(!current);
                },
                child: Text(fontSettings.useSerif ? 'Serif' : 'Sans'),
              ),
            ],
          ),
        ],
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
            const SizedBox(height: 24),
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
                      theme.colorScheme.outline.withValues(alpha: 0.2),
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
          padding: const EdgeInsets.all(24),
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
              const SizedBox(height: 24),
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chapter title
          if (chapter.title != null) ...[
            Text(
              chapter.title!,
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
          ],

          // Toggle indicator
          if (state.showOriginal)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.brandAccent.withValues(alpha: 0.1),
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

  Widget _buildBottomBar(ThemeData theme, ReaderState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.2)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Previous (placeholder — would need chapter history)
          const _BottomBarButton(
            icon: Icons.arrow_back_ios_rounded,
            label: 'Prev',
            onTap: null, // TODO: implement prev chapter
          ),

          // Toggle original
          _BottomBarButton(
            icon: state.showOriginal ? Icons.translate : Icons.language,
            label: state.showOriginal ? 'Translated' : 'Original',
            onTap: () =>
                ref.read(readerProvider.notifier).toggleOriginal(),
          ),

          // Glossary
          _BottomBarButton(
            icon: Icons.book_outlined,
            label: 'Glossary',
            onTap: () => context.push('/novel/${widget.novelId}/glossary'),
          ),

          // Retry translation
          _BottomBarButton(
            icon: Icons.refresh,
            label: 'Re-translate',
            onTap: state.isTranslating
                ? null
                : () {
                    if (_novel != null) {
                      _startTranslation(_novel!.currentChapterUrl);
                    }
                  },
          ),

          // Next chapter
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

  Future<void> _handleNextChapter() async {
    if (_novel == null) return;

    final currentState = ref.read(readerProvider);
    final nextUrl = currentState.currentChapter?.nextChapterUrl ??
        _novel!.nextChapterUrl;

    if (nextUrl != null && nextUrl.isNotEmpty) {
      // Confirm with user
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Next Chapter'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Next chapter detected:'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  nextUrl,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Translate this chapter?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Translate'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        _scrollController.jumpTo(0);
        ref.read(readerProvider.notifier).clear();
        _startTranslation(nextUrl);
      }
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
