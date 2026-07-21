import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/sqlite_service.dart';
import '../domain/story.dart';
import '../domain/story_repository.dart';

class StoryRepositoryImpl implements StoryRepository {
  StoryRepositoryImpl(this._sqlite);

  final SqliteService _sqlite;

  @override
  Future<List<Story>> getStories() async {
    final db = await _sqlite.database;
    final rows = await db.query('stories', orderBy: 'priority ASC');
    return rows.map(Story.fromMap).toList();
  }

  @override
  Future<void> insertStory(Story story) async {
    final db = await _sqlite.database;
    await db.insert('stories', story.toMap());
    await _sqlite.syncStoryFts(story.id);
  }

  @override
  Future<void> updateStory(Story story) async {
    final db = await _sqlite.database;
    await db.update('stories', story.toMap(), where: 'id = ?', whereArgs: [story.id]);
    await _sqlite.syncStoryFts(story.id);
  }

  @override
  Future<void> deleteStory(String id) async {
    final db = await _sqlite.database;
    await db.delete('stories', where: 'id = ?', whereArgs: [id]);
    await _sqlite.deleteStoryFts(id);
  }

  @override
  Future<void> saveStoryPriorities(List<Story> stories) async {
    final db = await _sqlite.database;
    final batch = db.batch();
    for (final story in stories) {
      batch.update(
        'stories',
        {'priority': story.priority, 'updatedAt': story.updatedAt.millisecondsSinceEpoch},
        where: 'id = ?',
        whereArgs: [story.id],
      );
    }
    await batch.commit(noResult: true);
  }
}

final storyRepositoryProvider = Provider<StoryRepository>((ref) {
  return StoryRepositoryImpl(ref.watch(sqliteServiceProvider));
});
