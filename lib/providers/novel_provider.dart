import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/novel.dart';
import '../services/database_service.dart';

class NovelListNotifier extends StateNotifier<AsyncValue<List<Novel>>> {
  NovelListNotifier() : super(const AsyncValue.loading()) {
    loadNovels();
  }

  Future<void> loadNovels() async {
    state = const AsyncValue.loading();
    try {
      final novels = await DatabaseService.getAllNovels();
      state = AsyncValue.data(novels);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addNovel(Novel novel) async {
    await DatabaseService.insertNovel(novel);
    await loadNovels();
  }

  Future<void> updateNovel(Novel novel) async {
    await DatabaseService.updateNovel(novel);
    await loadNovels();
  }

  Future<void> deleteNovel(String id) async {
    await DatabaseService.deleteNovel(id);
    await loadNovels();
  }
}

final novelListProvider =
    StateNotifierProvider<NovelListNotifier, AsyncValue<List<Novel>>>((ref) {
  return NovelListNotifier();
});

// Single novel by ID
final novelProvider =
    FutureProvider.family<Novel?, String>((ref, id) async {
  return DatabaseService.getNovel(id);
});
