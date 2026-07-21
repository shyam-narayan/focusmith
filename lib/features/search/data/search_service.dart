import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/sqlite_service.dart';

/// How search is currently being used in the UI.
enum SearchUiMode {
  /// No search UI active.
  none,

  /// Ctrl+F — find within the active story.
  local,

  /// Ctrl+Shift+F — search across the whole workspace.
  global,
}

class SearchResult {
  const SearchResult({
    required this.storyId,
    required this.title,
    required this.snippet,
    this.matchInTitle = false,
    this.matchCount = 0,
  });

  final String storyId;
  final String title;
  final String snippet;
  final bool matchInTitle;
  final int matchCount;
}

class SearchService {
  SearchService(this._sqlite);

  final SqliteService _sqlite;

  /// Workspace-wide search (FTS + live open buffers).
  Future<List<SearchResult>> searchGlobal(
    String query, {
    List<String> openTabIds = const [],
    Map<String, String> liveDocuments = const {},
    Map<String, String> titles = const {},
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    final ftsQuery = _toFtsQuery(trimmed);
    final byId = <String, SearchResult>{};

    if (ftsQuery.isNotEmpty) {
      try {
        final db = await _sqlite.database;
        final rows = await db.rawQuery(
          '''
          SELECT s.id AS storyId, s.title AS title, f.content AS content
          FROM stories_fts f
          JOIN stories s ON s.id = f.storyId
          WHERE stories_fts MATCH ?
          ORDER BY rank
          LIMIT 40
          ''',
          [ftsQuery],
        );

        for (final row in rows) {
          final id = row['storyId'] as String;
          final title = titles[id] ?? (row['title'] as String? ?? '');
          final ftsContent = row['content'] as String? ?? '';
          final content = liveDocuments[id] ?? ftsContent;
          final hit = _matchDocument(
            storyId: id,
            title: title,
            content: content,
            query: trimmed,
          );
          if (hit != null) {
            byId[id] = hit;
          } else {
            byId[id] = SearchResult(
              storyId: id,
              title: title,
              snippet: _snippet(content, trimmed),
              matchCount: _countMatches(content, trimmed),
            );
          }
        }
      } catch (_) {
        // Invalid FTS syntax — fall through to live-buffer matching.
      }
    }

    for (final id in openTabIds) {
      if (byId.containsKey(id)) continue;
      final live = liveDocuments[id];
      if (live == null) continue;
      final hit = _matchDocument(
        storyId: id,
        title: titles[id] ?? '',
        content: live,
        query: trimmed,
      );
      if (hit != null) byId[id] = hit;
    }

    // Also scan titles / live docs for stories FTS missed (closed tabs with
    // special characters, or FTS failure).
    if (byId.length < 25) {
      for (final entry in titles.entries) {
        if (byId.containsKey(entry.key)) continue;
        final content = liveDocuments[entry.key] ?? '';
        final hit = _matchDocument(
          storyId: entry.key,
          title: entry.value,
          content: content,
          query: trimmed,
        );
        if (hit != null) byId[entry.key] = hit;
        if (byId.length >= 25) break;
      }
    }

    return byId.values.take(25).toList();
  }

  /// Quote tokens so punctuation / FTS operators do not break MATCH.
  String _toFtsQuery(String raw) {
    final tokens = raw
        .split(RegExp(r'\s+'))
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .map((t) => '"${t.replaceAll('"', '')}"')
        .toList();
    return tokens.join(' ');
  }

  SearchResult? _matchDocument({
    required String storyId,
    required String title,
    required String content,
    required String query,
  }) {
    final q = query.toLowerCase();
    final titleHit = title.toLowerCase().contains(q);
    final contentHit = content.toLowerCase().contains(q);
    if (!titleHit && !contentHit) return null;
    return SearchResult(
      storyId: storyId,
      title: title,
      snippet: titleHit && !contentHit
          ? 'Matched in title'
          : _snippet(content, query),
      matchInTitle: titleHit,
      matchCount: _countMatches(content, query),
    );
  }

  int _countMatches(String content, String query) {
    if (query.isEmpty || content.isEmpty) return 0;
    final lower = content.toLowerCase();
    final q = query.toLowerCase();
    var count = 0;
    var index = 0;
    while (true) {
      index = lower.indexOf(q, index);
      if (index < 0) break;
      count++;
      index += q.length;
    }
    return count;
  }

  String _snippet(String content, String query) {
    final plain = content.replaceAll('\n', ' ').trim();
    if (plain.isEmpty) return '';
    if (plain.length <= 120) return plain;
    final lower = plain.toLowerCase();
    final index = lower.indexOf(query.toLowerCase());
    if (index == -1) return '${plain.substring(0, 120)}…';
    final begin = (index - 40).clamp(0, plain.length);
    final end = (index + 80).clamp(0, plain.length);
    final prefix = begin > 0 ? '…' : '';
    final suffix = end < plain.length ? '…' : '';
    return '$prefix${plain.substring(begin, end)}$suffix';
  }
}

final searchServiceProvider = Provider<SearchService>((ref) {
  return SearchService(ref.watch(sqliteServiceProvider));
});
