import 'note.dart';

/// Repository contract for rich-text [Note] documents.
abstract class NoteRepository {
  Future<Note?> getNoteByStoryId(String storyId);

  Future<void> upsertNote(Note note);

  Future<void> deleteByStoryId(String storyId);
}
