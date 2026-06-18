import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/novel.dart';
import '../models/chapter.dart';
import '../providers/novel_provider.dart';
import '../services/database_service.dart';
import '../widgets/model_selector_widget.dart';
import '../core/constants.dart';

class NovelDetailScreen extends ConsumerStatefulWidget {
  final String novelId;

  const NovelDetailScreen({super.key, required this.novelId});

  @override
  ConsumerState<NovelDetailScreen> createState() => _NovelDetailScreenState();
}

class _NovelDetailScreenState extends ConsumerState<NovelDetailScreen> {
  Novel? _novel;
  List<Chapter> _chapters = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final novel = await DatabaseService.getNovel(widget.novelId);
    final chapters =
        await DatabaseService.getChaptersForNovel(widget.novelId);
    setState(() {
      _novel = novel;
      _chapters = chapters;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_novel == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Not Found')),
        body: const Center(child: Text('Novel not found')),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ─── App Bar with gradient ───
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _novel!.title,
                style: const TextStyle(fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.brandPrimary.withValues(alpha: 0.8),
                      AppTheme.brandSecondary.withValues(alpha: 0.6),
                    ],
                  ),
                ),
                child: Center(
                  child: _novel!.coverImageUrl != null
                      ? Image.network(
                          _novel!.coverImageUrl!,
                          height: 120,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.auto_stories,
                            size: 64,
                            color: Colors.white54,
                          ),
                        )
                      : const Icon(
                          Icons.auto_stories,
                          size: 64,
                          color: Colors.white54,
                        ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.book_outlined),
                onPressed: () =>
                    context.push('/novel/${widget.novelId}/glossary'),
                tooltip: 'Glossary',
              ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'delete') {
                    _showDeleteDialog();
                  } else if (value == 'edit') {
                    _showEditDialog();
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 20),
                        SizedBox(width: 8),
                        Text('Edit Novel'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 20,
                            color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ─── Info Cards ───
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _InfoCard(
                    icon: Icons.translate,
                    label: 'Chapters',
                    value: '${_novel!.totalChaptersTranslated}',
                  ),
                  const SizedBox(width: 12),
                  _InfoCard(
                    icon: Icons.language,
                    label: 'Source',
                    value: _novel!.sourceLanguage ?? '?',
                  ),
                  const SizedBox(width: 12),
                  _InfoCard(
                    icon: Icons.smart_toy_outlined,
                    label: 'Model',
                    value: _novel!.selectedModel.split('-').last,
                  ),
                ],
              ),
            ),
          ),

          // ─── Continue Reading Button ───
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      context.push('/novel/${widget.novelId}/read'),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Continue Reading'),
                ),
              ),
            ),
          ),

          // ─── Chapters List ───
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                'Translated Chapters (${_chapters.length})',
                style: theme.textTheme.titleMedium,
              ),
            ),
          ),

          if (_chapters.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.library_books_outlined,
                          size: 48,
                          color: theme.colorScheme.outline),
                      const SizedBox(height: 12),
                      Text(
                        'No chapters translated yet',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final chapter = _chapters[index];
                    return Card(
                      child: ListTile(
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppTheme.brandPrimary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${chapter.chapterNumber}',
                              style: const TextStyle(
                                color: AppTheme.brandPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          chapter.title ?? 'Chapter ${chapter.chapterNumber}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: chapter.translatedAt != null
                            ? Text(
                                DateFormat('MMM d, yyyy')
                                    .format(chapter.translatedAt!),
                              )
                            : null,
                        trailing: const Icon(
                            Icons.chevron_right, size: 20),
                        onTap: () {
                          // Navigate to read this specific chapter
                          // For now we set the current URL and navigate
                          context.push('/novel/${widget.novelId}/read');
                        },
                      ),
                    );
                  },
                  childCount: _chapters.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Novel'),
        content: Text(
            'Are you sure you want to delete "${_novel!.title}"? This will also delete all chapters and glossary entries.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(novelListProvider.notifier)
                  .deleteNovel(widget.novelId);
              Navigator.pop(ctx);
              context.go('/');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog() {
    final titleController = TextEditingController(text: _novel!.title);
    final coverController =
        TextEditingController(text: _novel!.coverImageUrl ?? '');
    String provider = _novel!.selectedProvider;
    String model = _novel!.selectedModel;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Novel'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: coverController,
                  decoration:
                      const InputDecoration(labelText: 'Cover Image URL'),
                ),
                const SizedBox(height: 16),
                ModelSelectorWidget(
                  selectedProvider: provider,
                  selectedModel: model,
                  onProviderChanged: (p) => setDialogState(() {
                    provider = p;
                    model = ProviderModels.models[p]!.first;
                  }),
                  onModelChanged: (m) =>
                      setDialogState(() => model = m),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final updated = _novel!.copyWith(
                  title: titleController.text.trim(),
                  coverImageUrl: coverController.text.trim().isNotEmpty
                      ? coverController.text.trim()
                      : null,
                  selectedProvider: provider,
                  selectedModel: model,
                );
                await DatabaseService.updateNovel(updated);
                ref.read(novelListProvider.notifier).loadNovels();
                setState(() => _novel = updated);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, size: 20, color: AppTheme.brandPrimary),
              const SizedBox(height: 6),
              Text(
                value,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(label, style: theme.textTheme.labelMedium),
            ],
          ),
        ),
      ),
    );
  }
}
