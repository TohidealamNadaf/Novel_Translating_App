import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/novel_provider.dart';
import '../models/novel.dart';
import '../core/theme.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final novelsAsync = ref.watch(novelListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        physics: novelsAsync.valueOrNull?.isEmpty == true 
            ? const NeverScrollableScrollPhysics() 
            : const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ─── App Bar ───
          SliverAppBar(
            floating: true,
            pinned: true,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.brandPrimary, AppTheme.brandSecondary],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.auto_stories, size: 18, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Text(
                  'NovelShift',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          // ─── Content ───
          novelsAsync.when(
            loading: () => const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, size: 48,
                            color: theme.colorScheme.error),
                        const SizedBox(height: 16),
                        Text('Failed to load library',
                            style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(error.toString(),
                            style: theme.textTheme.bodyMedium,
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            data: (novels) {
              if (novels.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppTheme.brandPrimary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.menu_book_outlined,
                            size: 64,
                            color: AppTheme.brandPrimary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Your library is empty',
                          style: theme.textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add your first novel to get started',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => context.push('/add'),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Novel'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _NovelCard(novel: novels[index]),
                    childCount: novels.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _NovelCard extends ConsumerWidget {
  final Novel novel;

  const _NovelCard({required this.novel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final timeAgo = _formatTimeAgo(novel.lastReadAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/novel/${novel.id}'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Cover image or placeholder
                Container(
                  width: 60,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.brandPrimary.withOpacity(0.7),
                        AppTheme.brandSecondary.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: novel.coverImageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            novel.coverImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.book,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.book,
                          color: Colors.white,
                          size: 28,
                        ),
                ),
                const SizedBox(width: 16),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        novel.title,
                        style: theme.textTheme.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (novel.sourceLanguage != null) ...[
                            _LanguageBadge(language: novel.sourceLanguage!),
                            const SizedBox(width: 8),
                          ],
                          Icon(Icons.translate, size: 14,
                              color: theme.colorScheme.secondary),
                          const SizedBox(width: 4),
                          Text(
                            '${novel.totalChaptersTranslated} chapters',
                            style: theme.textTheme.labelMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeAgo,
                        style: theme.textTheme.labelMedium,
                      ),
                    ],
                  ),
                ),
                // Continue reading button
                IconButton(
                  onPressed: () => context.push('/novel/${novel.id}/read'),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.brandPrimary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: AppTheme.brandPrimary,
                    ),
                  ),
                  tooltip: 'Continue reading',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d, yyyy').format(date);
  }
}

class _LanguageBadge extends StatelessWidget {
  final String language;

  const _LanguageBadge({required this.language});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (language.toLowerCase()) {
      'chinese' => (const Color(0xFFFF6B6B), 'CN'),
      'korean' => (const Color(0xFF4ECDC4), 'KR'),
      'japanese' => (const Color(0xFFFFE66D), 'JP'),
      _ => (const Color(0xFF8B949E), '??'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
