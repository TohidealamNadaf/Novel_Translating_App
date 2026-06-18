import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../models/glossary_entry.dart';
import '../providers/glossary_provider.dart';
import '../widgets/glossary_tile.dart';

class GlossaryScreen extends ConsumerStatefulWidget {
  final String novelId;

  const GlossaryScreen({super.key, required this.novelId});

  @override
  ConsumerState<GlossaryScreen> createState() => _GlossaryScreenState();
}

class _GlossaryScreenState extends ConsumerState<GlossaryScreen> {
  String _filterType = 'all';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glossaryAsync = ref.watch(glossaryProvider(widget.novelId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Glossary'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: _handleMenuAction,
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    Icon(Icons.file_download_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Import JSON'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.file_upload_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Export JSON'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── Search Bar ───
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search glossary...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),

          // ─── Filter Chips ───
          Padding(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: _filterType == 'all',
                    onTap: () => setState(() => _filterType = 'all'),
                  ),
                  for (final type in [
                    'character',
                    'place',
                    'technique',
                    'title',
                    'item',
                    'term'
                  ])
                    _FilterChip(
                      label: type[0].toUpperCase() + type.substring(1),
                      selected: _filterType == type,
                      onTap: () => setState(() => _filterType = type),
                    ),
                ],
              ),
            ),
          ),

          // ─── Entries List ───
          Expanded(
            child: glossaryAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (entries) {
                var filtered = entries;

                // Apply type filter
                if (_filterType != 'all') {
                  filtered = filtered
                      .where((e) => e.type == _filterType)
                      .toList();
                }

                // Apply search filter
                if (_searchQuery.isNotEmpty) {
                  final q = _searchQuery.toLowerCase();
                  filtered = filtered
                      .where((e) =>
                          e.original.toLowerCase().contains(q) ||
                          e.translated.toLowerCase().contains(q))
                      .toList();
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.book_outlined,
                            size: 48, color: theme.colorScheme.outline),
                        const SizedBox(height: 12),
                        Text(
                          entries.isEmpty
                              ? 'No glossary entries yet'
                              : 'No matching entries',
                          style: theme.textTheme.bodyMedium,
                        ),
                        if (entries.isEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Entries are auto-detected during translation',
                            style: theme.textTheme.labelMedium,
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final entry = filtered[index];
                    return GlossaryTile(
                      entry: entry,
                      onEdit: () => _showEditDialog(entry),
                      onDelete: () => _confirmDelete(entry),
                      onToggle: () => ref
                          .read(glossaryProvider(widget.novelId).notifier)
                          .toggleEntry(entry),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog() {
    final originalController = TextEditingController();
    final translatedController = TextEditingController();
    String type = 'term';
    String? gender;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Glossary Entry'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: originalController,
                  decoration:
                      const InputDecoration(labelText: 'Original Term'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: translatedController,
                  decoration:
                      const InputDecoration(labelText: 'Translation'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: ['character', 'place', 'technique', 'title', 'item', 'term']
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(
                                t[0].toUpperCase() + t.substring(1)),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => type = v ?? 'term'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: gender,
                  decoration:
                      const InputDecoration(labelText: 'Gender (optional)'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('None')),
                    DropdownMenuItem(value: 'male', child: Text('Male')),
                    DropdownMenuItem(value: 'female', child: Text('Female')),
                    DropdownMenuItem(
                        value: 'neutral', child: Text('Neutral')),
                  ],
                  onChanged: (v) => setDialogState(() => gender = v),
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
              onPressed: () {
                if (originalController.text.trim().isNotEmpty &&
                    translatedController.text.trim().isNotEmpty) {
                  ref
                      .read(glossaryProvider(widget.novelId).notifier)
                      .addEntry(GlossaryEntry(
                        novelId: widget.novelId,
                        original: originalController.text.trim(),
                        translated: translatedController.text.trim(),
                        type: type,
                        gender: gender,
                      ));
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(GlossaryEntry entry) {
    final originalController = TextEditingController(text: entry.original);
    final translatedController =
        TextEditingController(text: entry.translated);
    String type = entry.type;
    String? gender = entry.gender;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Entry'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: originalController,
                  decoration:
                      const InputDecoration(labelText: 'Original Term'),
                  enabled: false,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: translatedController,
                  decoration:
                      const InputDecoration(labelText: 'Translation'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: ['character', 'place', 'technique', 'title', 'item', 'term']
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(
                                t[0].toUpperCase() + t.substring(1)),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => type = v ?? 'term'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: gender,
                  decoration:
                      const InputDecoration(labelText: 'Gender (optional)'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('None')),
                    DropdownMenuItem(value: 'male', child: Text('Male')),
                    DropdownMenuItem(value: 'female', child: Text('Female')),
                    DropdownMenuItem(
                        value: 'neutral', child: Text('Neutral')),
                  ],
                  onChanged: (v) => setDialogState(() => gender = v),
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
              onPressed: () {
                ref
                    .read(glossaryProvider(widget.novelId).notifier)
                    .updateEntry(entry.copyWith(
                      translated: translatedController.text.trim(),
                      type: type,
                      gender: gender,
                    ));
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(GlossaryEntry entry) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Entry'),
        content: Text(
            'Delete "${entry.original} → ${entry.translated}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(glossaryProvider(widget.novelId).notifier)
                  .deleteEntry(entry.id);
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleMenuAction(String action) async {
    if (action == 'export') {
      try {
        final json = await ref
            .read(glossaryProvider(widget.novelId).notifier)
            .exportAsJson();
        await Clipboard.setData(ClipboardData(text: json));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Glossary JSON copied to clipboard'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Export failed: $e'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } else if (action == 'import') {
      _showImportDialog();
    }
  }

  void _showImportDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Glossary'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Paste JSON array of glossary entries:'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: '[{"original": "...", "translated": "..."}]',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref
                    .read(glossaryProvider(widget.novelId).notifier)
                    .importFromJson(controller.text);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Glossary imported successfully'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Import failed: $e'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppTheme.brandPrimary.withValues(alpha: 0.2),
        checkmarkColor: AppTheme.brandPrimary,
        showCheckmark: selected,
      ),
    );
  }
}
