import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../providers/settings_provider.dart';
import '../services/ai_provider_service.dart';
import '../widgets/chapter_summary_sheet.dart';
import '../models/novel.dart';

class ReaderBottomControls extends ConsumerStatefulWidget {
  final Novel? novel;
  final VoidCallback onNextChapter;
  final VoidCallback onPrevChapter;
  final String currentText;
  final bool isBottomSheet;

  const ReaderBottomControls({
    super.key,
    required this.novel,
    required this.onNextChapter,
    required this.onPrevChapter,
    required this.currentText,
    this.isBottomSheet = false,
  });

  @override
  ConsumerState<ReaderBottomControls> createState() => _ReaderBottomControlsState();
}

class _ReaderBottomControlsState extends ConsumerState<ReaderBottomControls> {
  double _scrollSpeed = 3.0;

  Future<void> _showSummary() async {
    if (widget.novel == null || widget.currentText.isEmpty) return;

    final provider = widget.novel!.selectedProvider;
    final keys = ref.read(apiKeyProvider);
    String? apiKey = keys[provider];

    if (apiKey == null || apiKey.isEmpty) {
      // The state might not have loaded asynchronously yet, try secure storage directly
      apiKey = await const FlutterSecureStorage()
          .read(key: 'api_key_$provider');
    }

    if (apiKey == null || apiKey.isEmpty) {
      if (!mounted) return;
      final nav = GoRouter.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${ProviderModels.providerNames[provider] ?? provider} API key not found. Go to Settings → API Keys.'),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () => nav.push('/settings'),
          ),
        ),
      );
      if (widget.isBottomSheet) {
        Navigator.pop(context);
      }
      return;
    }
    
    if (widget.isBottomSheet) {
      Navigator.pop(context);
    }

    Future<ChapterSummary> fetchSummary() {
      return AIProviderService.generateChapterSummary(
        text: widget.currentText.length > 8000
            ? widget.currentText.substring(0, 8000)
            : widget.currentText,
        provider: provider,
        model: widget.novel!.selectedModel,
        apiKey: apiKey!,
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ChapterSummarySheet(
        summaryFuture: fetchSummary(),
        onRefresh: () {
          Navigator.pop(context);
          _showSummary();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final readingTheme = ref.watch(themeProvider);
    final fontSettings = ref.watch(fontSettingsProvider);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16181D) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.isBottomSheet)
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

          // Top Row: Copy, Prev, Play, Next
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildIconButton(Icons.copy, () {}),
              _buildTextButton(Icons.keyboard_double_arrow_left, 'Prev', widget.onPrevChapter),
              // Play button (central)
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.brandPrimary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.brandPrimary.withOpacity(0.4),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.play_arrow, color: Colors.white, size: 32),
                  onPressed: () {},
                ),
              ),
              _buildTextButton(Icons.keyboard_double_arrow_right, 'Next', widget.onNextChapter, isTrailing: true),
            ],
          ),
          const SizedBox(height: 24),

          // Tools Row: Contents, Summary, Rewrite, Save
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildToolButton(Icons.list, 'Contents', () => context.push('/novel/${widget.novel?.id}/glossary')),
              _buildToolButton(Icons.auto_awesome, 'Summary', _showSummary, isActive: true),
              _buildToolButton(Icons.auto_fix_high, 'Rewrite', () {}),
              _buildToolButton(Icons.download_rounded, 'Save', () {}),
            ],
          ),
          const SizedBox(height: 24),

          // Auto Scroll
          Row(
            children: [
              Text('AUTO SCROLL', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.2, color: theme.textTheme.bodyMedium?.color)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.keyboard_double_arrow_down, size: 16),
                label: const Text('Start'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF23262F) : Colors.white,
                  foregroundColor: isDark ? Colors.white : Colors.black87,
                  elevation: 0,
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              )
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(icon: const Icon(Icons.remove), onPressed: () => setState(() => _scrollSpeed = (_scrollSpeed - 0.5).clamp(1.0, 5.0))),
              const SizedBox(width: 8),
              Text('Slow', style: theme.textTheme.labelSmall),
              Expanded(
                child: Slider(
                  value: _scrollSpeed,
                  min: 1.0,
                  max: 5.0,
                  activeColor: AppTheme.brandPrimary,
                  inactiveColor: theme.dividerColor,
                  onChanged: (v) => setState(() => _scrollSpeed = v),
                ),
              ),
              Text('${_scrollSpeed.toStringAsFixed(1)}x', style: theme.textTheme.labelMedium?.copyWith(color: AppTheme.brandPrimary)),
              const SizedBox(width: 8),
              Text('Fast', style: theme.textTheme.labelSmall),
              IconButton(icon: const Icon(Icons.add), onPressed: () => setState(() => _scrollSpeed = (_scrollSpeed + 0.5).clamp(1.0, 5.0))),
            ],
          ),
          const SizedBox(height: 24),

          // Font and Size
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('FONT', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.2)),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF23262F) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          _buildFontTab('Serif', fontSettings.useSerif, () => ref.read(fontSettingsProvider.notifier).setUseSerif(true)),
                          _buildFontTab('Sans', !fontSettings.useSerif, () => ref.read(fontSettingsProvider.notifier).setUseSerif(false)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SIZE', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.2)),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF23262F) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [14.0, 16.0, 18.0, 22.0].map((size) {
                          final isSelected = fontSettings.fontSize == size;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => ref.read(fontSettingsProvider.notifier).setFontSize(size),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppTheme.brandPrimary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    '${size.round()}',
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : (isDark ? Colors.white54 : Colors.black54),
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Theme
          Text('THEME', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ReadingTheme.values.map((t) {
              final isSelected = readingTheme == t;
              final name = t.name.toUpperCase();
              final color = AppTheme.readingBackground(t);
              
              return GestureDetector(
                onTap: () => ref.read(themeProvider.notifier).setTheme(t),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AppTheme.brandPrimary : Colors.grey.withOpacity(0.3),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      name,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isSelected ? AppTheme.brandPrimary : null,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF23262F) : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20),
      ),
    );
  }

  Widget _buildTextButton(IconData icon, String label, VoidCallback onTap, {bool isTrailing = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF23262F) : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: isTrailing
              ? [Text(label), const SizedBox(width: 4), Icon(icon, size: 16)]
              : [Icon(icon, size: 16), const SizedBox(width: 4), Text(label)],
        ),
      ),
    );
  }

  Widget _buildToolButton(IconData icon, String label, VoidCallback onTap, {bool isActive = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 76,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF23262F) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isActive ? Border.all(color: AppTheme.brandPrimary.withOpacity(0.5), width: 1) : null,
        ),
        child: Column(
          children: [
            Icon(icon, color: isActive ? AppTheme.brandPrimary : null, size: 24),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildFontTab(String label, bool isSelected, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.brandPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : (isDark ? Colors.white54 : Colors.black54),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
