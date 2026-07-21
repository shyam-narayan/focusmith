import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../logging/app_logger.dart';
import '../logging/console_logger.dart';

/// Database helper to manage the SQLite service on Windows.
class SqliteService {
  SqliteService(this._logger);

  final AppLogger _logger;
  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<void> init() async {
    _db = await database;
  }

  Future<Database> _initDatabase() async {
    try {
      if (Platform.isWindows || Platform.isLinux) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
        _logger.info('sqflite FFI initialized for Windows/Linux.');
      }

      final directory = await getApplicationSupportDirectory();
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final dbPath = p.join(directory.path, 'focusmith.db');
      _logger.info('Initializing SQLite database at path: $dbPath');

      return openDatabase(
        dbPath,
        version: 2,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON;');
        },
        onCreate: (db, version) async {
          await _createTables(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await db.execute('''
              CREATE VIRTUAL TABLE IF NOT EXISTS stories_fts USING fts5(
                storyId UNINDEXED,
                title,
                content,
                tokenize = 'porter'
              )
            ''');
            await _rebuildFts(db);
          }
        },
      );
    } catch (e, stackTrace) {
      _logger.error('SQLite initialization failed.', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> _createTables(Database db) async {
    await db.transaction((txn) async {
      await txn.execute('''
        CREATE TABLE stories (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          priority INTEGER NOT NULL,
          status TEXT NOT NULL,
          color INTEGER NOT NULL,
          createdAt INTEGER NOT NULL,
          updatedAt INTEGER NOT NULL
        )
      ''');
      await txn.execute('CREATE INDEX idx_stories_priority ON stories(priority);');

      await txn.execute('''
        CREATE TABLE notes (
          id TEXT PRIMARY KEY,
          storyId TEXT UNIQUE NOT NULL,
          deltaJson TEXT NOT NULL,
          updatedAt INTEGER NOT NULL,
          FOREIGN KEY (storyId) REFERENCES stories (id) ON DELETE CASCADE
        )
      ''');

      await txn.execute('''
        CREATE TABLE settings (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      ''');

      await txn.execute('''
        CREATE TABLE history (
          id TEXT PRIMARY KEY,
          storyId TEXT NOT NULL,
          snapshot TEXT NOT NULL,
          createdAt INTEGER NOT NULL,
          FOREIGN KEY (storyId) REFERENCES stories (id) ON DELETE CASCADE
        )
      ''');

      await txn.execute('''
        CREATE VIRTUAL TABLE stories_fts USING fts5(
          storyId UNINDEXED,
          title,
          content,
          tokenize = 'porter'
        )
      ''');
    });
    _logger.info('All database tables and FTS index initialized.');
  }

  Future<void> syncStoryFts(String storyId) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT s.title AS title, COALESCE(n.deltaJson, '') AS deltaJson
      FROM stories s
      LEFT JOIN notes n ON n.storyId = s.id
      WHERE s.id = ?
      LIMIT 1
    ''', [storyId]);
    if (rows.isEmpty) return;

    final title = rows.first['title'] as String? ?? '';
    final deltaJson = rows.first['deltaJson'] as String? ?? '';
    final content = _plainTextFromDelta(deltaJson);

    await db.delete('stories_fts', where: 'storyId = ?', whereArgs: [storyId]);
    await db.insert('stories_fts', {
      'storyId': storyId,
      'title': title,
      'content': content,
    });
  }

  Future<void> deleteStoryFts(String storyId) async {
    final db = await database;
    await db.delete('stories_fts', where: 'storyId = ?', whereArgs: [storyId]);
  }

  Future<void> _rebuildFts(Database db) async {
    final rows = await db.rawQuery('''
      SELECT s.id AS storyId, s.title AS title, COALESCE(n.deltaJson, '') AS deltaJson
      FROM stories s
      LEFT JOIN notes n ON n.storyId = s.id
    ''');
    for (final row in rows) {
      await db.insert('stories_fts', {
        'storyId': row['storyId'],
        'title': row['title'],
        'content': _plainTextFromDelta(row['deltaJson'] as String? ?? ''),
      });
    }
  }

  String _plainTextFromDelta(String deltaJson) {
    try {
      if (deltaJson.trim().isEmpty) return '';
      final list = jsonDecode(deltaJson) as List<dynamic>;
      final buffer = StringBuffer();
      for (final op in list) {
        if (op is Map && op['insert'] is String) {
          buffer.write(op['insert']);
        }
      }
      return buffer.toString();
    } catch (_) {
      return deltaJson;
    }
  }

  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
      _logger.info('SQLite database closed.');
    }
  }
}

final sqliteServiceProvider = Provider<SqliteService>((ref) {
  final logger = ref.watch(loggerProvider);
  return SqliteService(logger);
});
