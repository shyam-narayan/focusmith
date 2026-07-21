import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../features/workspace/data/note_repository_impl.dart';
import '../../features/workspace/data/story_repository_impl.dart';
import '../../features/workspace/presentation/providers/workspace_provider.dart';

/// Exports the local workspace into a portable `.focusmith` JSON package.
class BackupService {
  BackupService(this._ref);

  final Ref _ref;

  Future<void> exportWorkspace() async {
    await _ref.read(workspaceProvider.notifier).flushForExport();

    final stories = await _ref.read(storyRepositoryProvider).getStories();
    final noteRepo = _ref.read(noteRepositoryProvider);
    final notes = <Map<String, dynamic>>[];

    for (final story in stories) {
      final note = await noteRepo.getNoteByStoryId(story.id);
      if (note != null) {
        notes.add(note.toMap());
      }
    }

    final payload = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'stories': stories.map((story) => story.toMap()).toList(),
      'notes': notes,
    };

    final path = await FilePicker.saveFile(
      dialogTitle: 'Export FOCUSMITH workspace',
      fileName: 'workspace_${DateTime.now().millisecondsSinceEpoch}.focusmith',
      type: FileType.custom,
      allowedExtensions: ['focusmith'],
    );
    if (path == null) return;

    final file = File(p.extension(path).isEmpty ? '$path.focusmith' : path);
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
  }
}

final backupServiceProvider = Provider<BackupService>((ref) => BackupService(ref));
