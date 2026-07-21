import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/sqlite_service.dart';

class HistoryRepository {
  HistoryRepository(this._sqlite);

  final SqliteService _sqlite;
  final _uuid = const Uuid();

  static const _maxSnapshotsPerStory = 20;

  Future<void> saveSnapshot({
    required String storyId,
    required String snapshot,
  }) async {
    final db = await _sqlite.database;
    await db.insert('history', {
      'id': _uuid.v4(),
      'storyId': storyId,
      'snapshot': snapshot,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });

    final keep = await db.query(
      'history',
      columns: ['id'],
      where: 'storyId = ?',
      whereArgs: [storyId],
      orderBy: 'createdAt DESC',
      limit: _maxSnapshotsPerStory,
    );
    if (keep.isEmpty) return;

    final keepIds = keep.map((row) => row['id'] as String).toList();
    final placeholders = List.filled(keepIds.length, '?').join(', ');
    await db.rawDelete(
      'DELETE FROM history WHERE storyId = ? AND id NOT IN ($placeholders)',
      [storyId, ...keepIds],
    );
  }

  Future<String?> latestSnapshot(String storyId) async {
    final db = await _sqlite.database;
    final rows = await db.query(
      'history',
      where: 'storyId = ?',
      whereArgs: [storyId],
      orderBy: 'createdAt DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['snapshot'] as String;
  }
}

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepository(ref.watch(sqliteServiceProvider));
});
