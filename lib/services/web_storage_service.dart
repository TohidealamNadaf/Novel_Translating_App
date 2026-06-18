import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/novel.dart';
import '../models/chapter.dart';
import '../models/glossary_entry.dart';

class WebStorageService {
  // ─── Novel CRUD ───

  static Future<List<Novel>> getAllNovels() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('novel_'));
    final novels = <Novel>[];
    for (final key in keys) {
      final jsonStr = prefs.getString(key);
      if (jsonStr != null) {
        novels.add(Novel.fromMap(jsonDecode(jsonStr)));
      }
    }
    novels.sort((a, b) => b.lastReadAt.compareTo(a.lastReadAt));
    return novels;
  }

  static Future<Novel?> getNovel(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('novel_$id');
    if (jsonStr == null) return null;
    return Novel.fromMap(jsonDecode(jsonStr));
  }

  static Future<void> insertNovel(Novel novel) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('novel_${novel.id}', jsonEncode(novel.toMap()));
  }

  static Future<void> updateNovel(Novel novel) async {
    await insertNovel(novel);
  }

  static Future<void> deleteNovel(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('novel_$id');
    
    // Also delete associated chapters and glossary
    final keys = prefs.getKeys().toList();
    for (final key in keys) {
      if (key.startsWith('chapter_${id}_') || key.startsWith('glossary_${id}_')) {
        await prefs.remove(key);
      }
    }
  }

  // ─── Chapter CRUD ───

  static Future<List<Chapter>> getChaptersForNovel(String novelId) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('chapter_${novelId}_'));
    final chapters = <Chapter>[];
    for (final key in keys) {
      final jsonStr = prefs.getString(key);
      if (jsonStr != null) {
        chapters.add(Chapter.fromMap(jsonDecode(jsonStr)));
      }
    }
    chapters.sort((a, b) => a.chapterNumber.compareTo(b.chapterNumber));
    return chapters;
  }

  static Future<Chapter?> getChapterByUrl(String novelId, String url) async {
    final chapters = await getChaptersForNovel(novelId);
    try {
      return chapters.firstWhere((c) => c.url == url);
    } catch (e) {
      return null;
    }
  }

  static Future<void> insertChapter(Chapter chapter) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('chapter_${chapter.novelId}_${chapter.id}', jsonEncode(chapter.toMap()));
  }

  static Future<void> updateChapter(Chapter chapter) async {
    await insertChapter(chapter);
  }

  // ─── Glossary CRUD ───

  static Future<List<GlossaryEntry>> getGlossaryForNovel(String novelId) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('glossary_${novelId}_'));
    final entries = <GlossaryEntry>[];
    for (final key in keys) {
      final jsonStr = prefs.getString(key);
      if (jsonStr != null) {
        entries.add(GlossaryEntry.fromMap(jsonDecode(jsonStr)));
      }
    }
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  static Future<List<GlossaryEntry>> getActiveGlossaryForNovel(String novelId) async {
    final entries = await getGlossaryForNovel(novelId);
    return entries.where((e) => e.isActive).toList();
  }

  static Future<void> insertGlossaryEntry(GlossaryEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('glossary_${entry.novelId}_${entry.id}', jsonEncode(entry.toMap()));
  }

  static Future<void> updateGlossaryEntry(GlossaryEntry entry) async {
    await insertGlossaryEntry(entry);
  }

  static Future<void> deleteGlossaryEntry(String id) async {
    final prefs = await SharedPreferences.getInstance();
    // Since we key by novelId_entryId, we have to search for the ID
    final keys = prefs.getKeys().where((k) => k.startsWith('glossary_') && k.endsWith('_$id'));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  static Future<void> insertGlossaryEntries(List<GlossaryEntry> entries) async {
    for (final entry in entries) {
      await insertGlossaryEntry(entry);
    }
  }
}
