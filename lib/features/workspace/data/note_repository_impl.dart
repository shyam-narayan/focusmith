import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../core/database/sqlite_service.dart';
import '../domain/note.dart';
import '../domain/note_repository.dart';

class NoteRepositoryImpl implements NoteRepository {
  NoteRepositoryImpl(this._sqlite);

  final SqliteService _sqlite;

  @override
  Future<Note?> getNoteByStoryId(String storyId) async {
    final db = await _sqlite.database;
    final rows = await db.query('notes', where: 'storyId = ?', whereArgs: [storyId], limit: 1);
    if (rows.isEmpty) return null;
    return Note.fromMap(rows.first);
  }

  @override
  Future<void> upsertNote(Note note) async {
    final db = await _sqlite.database;
    await db.insert(
      'notes',
      note.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _sqlite.syncStoryFts(note.storyId);
  }

  @override
  Future<void> deleteByStoryId(String storyId) async {
    final db = await _sqlite.database;
    await db.delete('notes', where: 'storyId = ?', whereArgs: [storyId]);
  }
}

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepositoryImpl(ref.watch(sqliteServiceProvider));
});
