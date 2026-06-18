import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:path/path.dart' as p;
import '../models/novel.dart';
import '../models/chapter.dart';
import '../models/glossary_entry.dart';

class DatabaseService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    if (kIsWeb) {
      return await databaseFactoryFfiWebNoWebWorker.openDatabase(
        'novelshift.db',
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: _onCreate,
        ),
      );
    }

    if (!kIsWeb && (io.Platform.isWindows || io.Platform.isLinux || io.Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'novelshift.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE novels (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        coverImageUrl TEXT,
        sourceLanguage TEXT,
        currentChapterUrl TEXT NOT NULL,
        nextChapterUrl TEXT,
        selectedProvider TEXT DEFAULT 'openai',
        selectedModel TEXT DEFAULT 'gpt-4o',
        lastReadAt TEXT NOT NULL,
        totalChaptersTranslated INTEGER DEFAULT 0,
        targetLanguage TEXT DEFAULT 'English'
      )
    ''');

    await db.execute('''
      CREATE TABLE chapters (
        id TEXT PRIMARY KEY,
        novelId TEXT NOT NULL,
        url TEXT NOT NULL,
        title TEXT,
        originalText TEXT,
        translatedText TEXT,
        nextChapterUrl TEXT,
        chapterNumber INTEGER DEFAULT 0,
        translatedAt TEXT,
        editedParagraphs TEXT,
        FOREIGN KEY (novelId) REFERENCES novels(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE glossary (
        id TEXT PRIMARY KEY,
        novelId TEXT NOT NULL,
        original TEXT NOT NULL,
        translated TEXT NOT NULL,
        gender TEXT,
        type TEXT DEFAULT 'term',
        isActive INTEGER DEFAULT 1,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (novelId) REFERENCES novels(id) ON DELETE CASCADE
      )
    ''');

    // Indexes for performance
    await db.execute(
        'CREATE INDEX idx_chapters_novelId ON chapters(novelId)');
    await db.execute(
        'CREATE INDEX idx_chapters_url ON chapters(url)');
    await db.execute(
        'CREATE INDEX idx_glossary_novelId ON glossary(novelId)');
  }

  // ─── Novel CRUD ───

  static Future<List<Novel>> getAllNovels() async {
    final db = await database;
    final maps = await db.query('novels', orderBy: 'lastReadAt DESC');
    return maps.map((m) => Novel.fromMap(m)).toList();
  }

  static Future<Novel?> getNovel(String id) async {
    final db = await database;
    final maps = await db.query('novels', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Novel.fromMap(maps.first);
  }

  static Future<void> insertNovel(Novel novel) async {
    final db = await database;
    await db.insert('novels', novel.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> updateNovel(Novel novel) async {
    final db = await database;
    await db.update('novels', novel.toMap(),
        where: 'id = ?', whereArgs: [novel.id]);
  }

  static Future<void> deleteNovel(String id) async {
    final db = await database;
    await db.delete('glossary', where: 'novelId = ?', whereArgs: [id]);
    await db.delete('chapters', where: 'novelId = ?', whereArgs: [id]);
    await db.delete('novels', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Chapter CRUD ───

  static Future<List<Chapter>> getChaptersForNovel(String novelId) async {
    final db = await database;
    final maps = await db.query('chapters',
        where: 'novelId = ?',
        whereArgs: [novelId],
        orderBy: 'chapterNumber ASC');
    return maps.map((m) => Chapter.fromMap(m)).toList();
  }

  static Future<Chapter?> getChapterByUrl(
      String novelId, String url) async {
    final db = await database;
    final maps = await db.query('chapters',
        where: 'novelId = ? AND url = ?', whereArgs: [novelId, url]);
    if (maps.isEmpty) return null;
    return Chapter.fromMap(maps.first);
  }

  static Future<void> insertChapter(Chapter chapter) async {
    final db = await database;
    await db.insert('chapters', chapter.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> updateChapter(Chapter chapter) async {
    final db = await database;
    await db.update('chapters', chapter.toMap(),
        where: 'id = ?', whereArgs: [chapter.id]);
  }

  // ─── Glossary CRUD ───

  static Future<List<GlossaryEntry>> getGlossaryForNovel(
      String novelId) async {
    final db = await database;
    final maps = await db.query('glossary',
        where: 'novelId = ?',
        whereArgs: [novelId],
        orderBy: 'createdAt DESC');
    return maps.map((m) => GlossaryEntry.fromMap(m)).toList();
  }

  static Future<List<GlossaryEntry>> getActiveGlossaryForNovel(
      String novelId) async {
    final db = await database;
    final maps = await db.query('glossary',
        where: 'novelId = ? AND isActive = 1',
        whereArgs: [novelId],
        orderBy: 'createdAt DESC');
    return maps.map((m) => GlossaryEntry.fromMap(m)).toList();
  }

  static Future<void> insertGlossaryEntry(GlossaryEntry entry) async {
    final db = await database;
    await db.insert('glossary', entry.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> updateGlossaryEntry(GlossaryEntry entry) async {
    final db = await database;
    await db.update('glossary', entry.toMap(),
        where: 'id = ?', whereArgs: [entry.id]);
  }

  static Future<void> deleteGlossaryEntry(String id) async {
    final db = await database;
    await db.delete('glossary', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> insertGlossaryEntries(
      List<GlossaryEntry> entries) async {
    final db = await database;
    final batch = db.batch();
    for (final entry in entries) {
      batch.insert('glossary', entry.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
  }
}
