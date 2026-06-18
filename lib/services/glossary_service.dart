import 'dart:convert';
import '../models/glossary_entry.dart';
import 'database_service.dart';

class GlossaryService {
  /// Get all glossary entries for a novel
  static Future<List<GlossaryEntry>> getGlossary(String novelId) {
    return DatabaseService.getGlossaryForNovel(novelId);
  }

  /// Get only active entries for translation injection
  static Future<List<GlossaryEntry>> getActiveGlossary(String novelId) {
    return DatabaseService.getActiveGlossaryForNovel(novelId);
  }

  /// Add a single entry
  static Future<void> addEntry(GlossaryEntry entry) {
    return DatabaseService.insertGlossaryEntry(entry);
  }

  /// Update an entry
  static Future<void> updateEntry(GlossaryEntry entry) {
    return DatabaseService.updateGlossaryEntry(entry);
  }

  /// Delete an entry
  static Future<void> deleteEntry(String id) {
    return DatabaseService.deleteGlossaryEntry(id);
  }

  /// Toggle entry active/inactive
  static Future<void> toggleEntry(GlossaryEntry entry) {
    return DatabaseService.updateGlossaryEntry(
      entry.copyWith(isActive: !entry.isActive),
    );
  }

  /// Bulk add entries
  static Future<void> addEntries(List<GlossaryEntry> entries) {
    return DatabaseService.insertGlossaryEntries(entries);
  }

  /// Export glossary as JSON string
  static Future<String> exportAsJson(String novelId) async {
    final entries = await getGlossary(novelId);
    final list = entries.map((e) => {
      'original': e.original,
      'translated': e.translated,
      'gender': e.gender,
      'type': e.type,
    }).toList();
    return const JsonEncoder.withIndent('  ').convert(list);
  }

  /// Import glossary from JSON string
  static Future<List<GlossaryEntry>> importFromJson(
      String json, String novelId) async {
    final list = jsonDecode(json) as List<dynamic>;
    final entries = list.map((item) {
      final map = item as Map<String, dynamic>;
      return GlossaryEntry(
        novelId: novelId,
        original: map['original'] as String,
        translated: map['translated'] as String,
        gender: map['gender'] as String?,
        type: map['type'] as String? ?? 'term',
      );
    }).toList();

    await addEntries(entries);
    return entries;
  }
}
