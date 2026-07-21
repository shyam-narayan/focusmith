import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/database/sqlite_service.dart';
import '../../workspace/domain/note.dart';
import '../../workspace/domain/note_repository.dart';
import '../../workspace/domain/story.dart';
import '../../workspace/domain/story_repository.dart';

/// Seeds a single welcome story on first launch (empty workspace only).
/// Note body is title-free — the story title lives on the Story entity.
class SeedDataService {
  SeedDataService({
    required StoryRepository storyRepository,
    required NoteRepository noteRepository,
    required SqliteService sqliteService,
  }) : _storyRepository = storyRepository,
       _noteRepository = noteRepository,
       _sqliteService = sqliteService;

  final StoryRepository _storyRepository;
  final NoteRepository _noteRepository;
  final SqliteService _sqliteService;
  final _uuid = const Uuid();

  Future<void> seedIfEmpty() async {
    final db = await _sqliteService.database;
    final count = await db.rawQuery('SELECT COUNT(*) AS c FROM stories');
    final total = count.first['c'] as int? ?? 0;
    if (total > 0) return;

    final now = DateTime.now();
    final storyId = _uuid.v4();

    await _storyRepository.insertStory(
      Story(
        id: storyId,
        title: 'Welcome to FOCUSMITH',
        priority: 0,
        status: 'todo',
        color: AppColors.purple,
        createdAt: now,
        updatedAt: now,
      ),
    );

    await _noteRepository.upsertNote(
      Note(
        id: _uuid.v4(),
        storyId: storyId,
        deltaJson: _welcomeBodyDelta,
        updatedAt: now,
      ),
    );
  }

  /// Quill delta ops inserted between welcome sections.
  static const _sectionDivider = [
    {'insert': '\n'},
    {'insert': {'divider': 'hr'}},
    {'insert': '\n'},
  ];

  /// Quill delta for the first-run welcome note.
  static final String _welcomeBodyDelta = jsonEncode([
    {
      'insert':
          'FOCUSMITH is your focus-driven workspace (focus + smith) — stories on a board, '
          'rich notes in tabs, everything local on your machine.\n\n'
          'Close this story when you are ready. From then on, the workspace is yours.\n',
    },
    ..._sectionDivider,
    {'insert': 'Stories & Priority Board\n', 'attributes': {'header': 2}},
    {
      'insert':
          'Each story is a unit of work: a title plus a rich-text body. '
          'The Priority Board on the right ranks what you should work on next.\n',
    },
    {'insert': 'Create a story with the + button (or Ctrl+N)\n', 'attributes': {'list': 'bullet'}},
    {'insert': 'Open one from the board — it appears as a tab\n', 'attributes': {'list': 'bullet'}},
    {'insert': 'Drag the grip to reorder, or use the ⋮ menu\n', 'attributes': {'list': 'bullet'}},
    {'insert': 'Double-click a board title to rename\n', 'attributes': {'list': 'bullet'}},
    {
      'insert': 'Toggle rearrange mode (sort icon next to +), then Alt+Shift+↑/↓\n',
      'attributes': {'list': 'bullet'},
    },
    ..._sectionDivider,
    {'insert': 'Editor\n', 'attributes': {'header': 2}},
    {
      'insert':
          'Title sits above the body. Use the toolbar for headings, lists, '
          'quotes, color, code, and document separators.\n',
    },
    {'insert': 'Ctrl+Z / Ctrl+Shift+Z — undo / redo\n', 'attributes': {'list': 'bullet'}},
    {'insert': 'Ctrl+B / I / U — bold / italic / underline\n', 'attributes': {'list': 'bullet'}},
    {'insert': 'Ctrl+E — smart code (inline or block)\n', 'attributes': {'list': 'bullet'}},
    {
      'insert': 'Ctrl+Alt+1 / 2 / 3 / 0 — heading levels / paragraph\n',
      'attributes': {'list': 'bullet'},
    },
    ..._sectionDivider,
    {'insert': 'Save\n', 'attributes': {'header': 2}},
    {
      'insert':
          'Press Ctrl+S to save. Optional Autosave lives in Settings '
          '(gear in the title bar) — it writes a couple of seconds after you stop typing.\n',
    },
    ..._sectionDivider,
    {'insert': 'Search\n', 'attributes': {'header': 2}},
    {'insert': 'Ctrl+F — find in the current story\n', 'attributes': {'list': 'bullet'}},
    {
      'insert': 'Ctrl+Shift+F — search all stories (title-bar field + results)\n',
      'attributes': {'list': 'bullet'},
    },
    {'insert': 'Esc — close find / dismiss results\n', 'attributes': {'list': 'bullet'}},
    {'insert': 'F3 / Shift+F3 — next / previous match\n', 'attributes': {'list': 'bullet'}},
    ..._sectionDivider,
    {'insert': 'Tabs & window\n', 'attributes': {'header': 2}},
    {'insert': 'Ctrl+W — close the active tab\n', 'attributes': {'list': 'bullet'}},
    {'insert': 'Ctrl+Tab / Ctrl+Shift+Tab — cycle tabs\n', 'attributes': {'list': 'bullet'}},
    {
      'insert': 'Open tabs and window size restore the next time you launch\n',
      'attributes': {'list': 'bullet'},
    },
    ..._sectionDivider,
    {'insert': 'Settings & backup\n', 'attributes': {'header': 2}},
    {
      'insert':
          'Open Settings from the title bar to toggle Autosave or export '
          'your workspace as a .focusmith package. All data stays in SQLite on this PC.\n',
    },
    ..._sectionDivider,
    {
      'insert':
          'Tip: delete or close this welcome story whenever you like — '
          'nothing else is pre-created for you.\n',
      'attributes': {'blockquote': true},
    },
  ]);
}
