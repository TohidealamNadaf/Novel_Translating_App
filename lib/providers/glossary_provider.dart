import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/glossary_entry.dart';
import '../services/glossary_service.dart';

class GlossaryNotifier
    extends StateNotifier<AsyncValue<List<GlossaryEntry>>> {
  final String novelId;

  GlossaryNotifier(this.novelId) : super(const AsyncValue.loading()) {
    loadGlossary();
  }

  Future<void> loadGlossary() async {
    state = const AsyncValue.loading();
    try {
      final entries = await GlossaryService.getGlossary(novelId);
      state = AsyncValue.data(entries);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addEntry(GlossaryEntry entry) async {
    await GlossaryService.addEntry(entry);
    await loadGlossary();
  }

  Future<void> updateEntry(GlossaryEntry entry) async {
    await GlossaryService.updateEntry(entry);
    await loadGlossary();
  }

  Future<void> deleteEntry(String id) async {
    await GlossaryService.deleteEntry(id);
    await loadGlossary();
  }

  Future<void> toggleEntry(GlossaryEntry entry) async {
    await GlossaryService.toggleEntry(entry);
    await loadGlossary();
  }

  Future<void> importFromJson(String json) async {
    await GlossaryService.importFromJson(json, novelId);
    await loadGlossary();
  }

  Future<String> exportAsJson() {
    return GlossaryService.exportAsJson(novelId);
  }
}

final glossaryProvider = StateNotifierProvider.family<GlossaryNotifier,
    AsyncValue<List<GlossaryEntry>>, String>((ref, novelId) {
  return GlossaryNotifier(novelId);
});
