import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/database/hive_storage_service.dart';
import '../../../../core/helpers/debouncer.dart';
import '../../../../core/settings/app_settings.dart';
import '../../../history/data/history_repository.dart';
import '../../../search/data/search_service.dart';
import '../../data/note_repository_impl.dart';
import '../../data/story_repository_impl.dart';
import '../../domain/note.dart';
import '../../domain/story.dart';

enum SaveStatus { saved, saving, unsaved, error }

/// Active find-in-file session (Ctrl+F or after opening a global hit).
class InFileSearchSession {
  const InFileSearchSession({
    required this.storyId,
    required this.query,
    required this.offsets,
    required this.activeIndex,
  });

  final String storyId;
  final String query;
  final List<int> offsets;
  final int activeIndex;

  int get matchCount => offsets.length;

  InFileSearchSession copyWith({
    String? storyId,
    String? query,
    List<int>? offsets,
    int? activeIndex,
  }) {
    return InFileSearchSession(
      storyId: storyId ?? this.storyId,
      query: query ?? this.query,
      offsets: offsets ?? this.offsets,
      activeIndex: activeIndex ?? this.activeIndex,
    );
  }
}

class WorkspaceState {
  const WorkspaceState({
    this.stories = const [],
    this.openTabIds = const [],
    this.selectedStoryId,
    this.zoom = 1.0,
    this.saveStatus = SaveStatus.saved,
    this.lastSavedAt,
    this.isLoading = true,
    this.searchQuery = '',
    this.isSearchFocused = false,
    this.documentEpoch = 0,
    this.isPriorityReorderMode = false,
    this.searchUiMode = SearchUiMode.none,
    this.searchPanelVisible = true,
    this.inFileSearch,
    this.localFindEpoch = 0,
    this.controllerEpoch = 0,
  });

  final List<Story> stories;
  final List<String> openTabIds;
  final String? selectedStoryId;
  final double zoom;
  final SaveStatus saveStatus;
  final DateTime? lastSavedAt;
  final bool isLoading;
  final String searchQuery;
  final bool isSearchFocused;

  /// Bumps on document edits so status bar can refresh word/char counts.
  final int documentEpoch;

  /// When true, Alt+Shift+↑/↓ rearrange the selected story on the Priority Board.
  final bool isPriorityReorderMode;

  final SearchUiMode searchUiMode;

  /// When false, global results overlay is hidden until the query changes.
  final bool searchPanelVisible;

  final InFileSearchSession? inFileSearch;

  /// Bumps each Ctrl+F so the find bar can re-focus even when already open.
  final int localFindEpoch;

  /// Bumps when a Quill controller becomes ready so the editor can rebuild.
  final int controllerEpoch;

  Story? get selectedStory {
    if (selectedStoryId == null) return null;
    for (final story in stories) {
      if (story.id == selectedStoryId) return story;
    }
    return null;
  }

  List<Story> get openTabs {
    final map = {for (final story in stories) story.id: story};
    return openTabIds.map((id) => map[id]).whereType<Story>().toList();
  }

  WorkspaceState copyWith({
    List<Story>? stories,
    List<String>? openTabIds,
    String? selectedStoryId,
    bool clearSelectedStoryId = false,
    double? zoom,
    SaveStatus? saveStatus,
    DateTime? lastSavedAt,
    bool? isLoading,
    String? searchQuery,
    bool? isSearchFocused,
    int? documentEpoch,
    bool? isPriorityReorderMode,
    SearchUiMode? searchUiMode,
    bool? searchPanelVisible,
    InFileSearchSession? inFileSearch,
    bool clearInFileSearch = false,
    int? localFindEpoch,
    int? controllerEpoch,
  }) {
    return WorkspaceState(
      stories: stories ?? this.stories,
      openTabIds: openTabIds ?? this.openTabIds,
      selectedStoryId: clearSelectedStoryId
          ? null
          : (selectedStoryId ?? this.selectedStoryId),
      zoom: zoom ?? this.zoom,
      saveStatus: saveStatus ?? this.saveStatus,
      lastSavedAt: lastSavedAt ?? this.lastSavedAt,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      isSearchFocused: isSearchFocused ?? this.isSearchFocused,
      documentEpoch: documentEpoch ?? this.documentEpoch,
      isPriorityReorderMode:
          isPriorityReorderMode ?? this.isPriorityReorderMode,
      searchUiMode: searchUiMode ?? this.searchUiMode,
      searchPanelVisible: searchPanelVisible ?? this.searchPanelVisible,
      inFileSearch:
          clearInFileSearch ? null : (inFileSearch ?? this.inFileSearch),
      localFindEpoch: localFindEpoch ?? this.localFindEpoch,
      controllerEpoch: controllerEpoch ?? this.controllerEpoch,
    );
  }
}

class WorkspaceNotifier extends Notifier<WorkspaceState> {
  final _uuid = const Uuid();
  final Map<String, QuillController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};
  final Map<String, ScrollController> _scrollControllers = {};
  final Map<String, String> _noteIds = {};
  final Map<String, Future<void>> _ensuringControllers = {};
  StreamSubscription<DocChange>? _documentChangesSub;
  QuillController? _activeController;
  final _autosaveDebouncer = Debouncer(duration: const Duration(seconds: 2));
  Future<void>? _saveChain;
  Future<void>? _reorderChain;

  static const emptyBodyDelta = '[{"insert":"\\n"}]';

  @override
  WorkspaceState build() {
    ref.onDispose(() {
      _autosaveDebouncer.dispose();
      unawaited(_documentChangesSub?.cancel());
      _documentChangesSub = null;
      for (final controller in _controllers.values) {
        controller.dispose();
      }
      for (final node in _focusNodes.values) {
        node.dispose();
      }
      for (final scroll in _scrollControllers.values) {
        scroll.dispose();
      }
      _controllers.clear();
      _focusNodes.clear();
      _scrollControllers.clear();
      _ensuringControllers.clear();
    });
    unawaited(_bootstrap());
    return const WorkspaceState();
  }

  Future<void> _bootstrap() async {
    final storyRepo = ref.read(storyRepositoryProvider);
    final hive = ref.read(hiveStorageServiceProvider);

    // Seed runs once in main(); bootstrap only loads the workspace.

    final stories = await storyRepo.getStories();
    final savedTabs = hive.get<List<dynamic>>(
      HiveStorageService.workspaceStateBox,
      'openTabIds',
    );
    final savedSelected = hive.get<String>(
      HiveStorageService.workspaceStateBox,
      'selectedStoryId',
    );
    final savedZoom =
        hive.get<double>(HiveStorageService.workspaceStateBox, 'zoom') ?? 1.0;

    final storyIds = stories.map((s) => s.id).toSet();
    // null = never persisted (first launch) → open all stories.
    // Explicit empty list = user closed every tab → keep empty (placeholder).
    final List<String> openTabIds;
    if (savedTabs == null) {
      openTabIds = stories.map((s) => s.id).toList();
    } else {
      openTabIds = savedTabs
          .map((e) => e.toString())
          .where(storyIds.contains)
          .toList();
    }

    String? selectedId = savedSelected;
    if (openTabIds.isEmpty) {
      selectedId = null;
    } else if (selectedId == null ||
        !openTabIds.contains(selectedId) ||
        !storyIds.contains(selectedId)) {
      selectedId = openTabIds.first;
    }

    state = state.copyWith(
      stories: stories,
      openTabIds: openTabIds,
      selectedStoryId: selectedId,
      clearSelectedStoryId: selectedId == null,
      zoom: savedZoom.clamp(0.75, 1.5),
      isLoading: false,
      lastSavedAt: DateTime.now(),
    );

    if (selectedId != null) {
      await _ensureController(selectedId);
    }
  }

  QuillController? controllerFor(String? storyId) {
    if (storyId == null) return null;
    return _controllers[storyId];
  }

  FocusNode? focusNodeFor(String? storyId) {
    if (storyId == null) return null;
    return _focusNodes[storyId];
  }

  ScrollController? scrollControllerFor(String? storyId) {
    if (storyId == null) return null;
    return _scrollControllers[storyId];
  }

  Future<void> selectStory(String storyId) async {
    if (!state.openTabIds.contains(storyId)) {
      await openStory(storyId);
      return;
    }
    await _flushPendingAutosave();
    await _persistWorkspaceLayout(selectedStoryId: storyId);
    await _ensureController(storyId);
    _applyStorySelection(storyId);
  }

  Future<void> openStory(String storyId) async {
    await _flushPendingAutosave();
    final openTabs = List<String>.from(state.openTabIds);
    if (!openTabs.contains(storyId)) {
      openTabs.add(storyId);
    }
    await _ensureController(storyId);
    _applyStorySelection(storyId, openTabIds: openTabs);
    await _persistWorkspaceLayout();
  }

  /// Clears local find when leaving its story so the ↑/↓ bar cannot stick on other tabs.
  void _applyStorySelection(String storyId, {List<String>? openTabIds}) {
    final leavingLocal = state.searchUiMode == SearchUiMode.local &&
        state.selectedStoryId != storyId;
    final staleSession =
        state.inFileSearch != null && state.inFileSearch!.storyId != storyId;

    state = state.copyWith(
      openTabIds: openTabIds,
      selectedStoryId: storyId,
      searchUiMode: leavingLocal ? SearchUiMode.none : null,
      searchQuery: leavingLocal ? '' : null,
      isSearchFocused: leavingLocal ? false : null,
      clearInFileSearch: leavingLocal || staleSession,
    );
    if (leavingLocal || staleSession) {
      _collapseDocumentSelection();
    }
  }

  Future<void> closeStory(String storyId) async {
    _autosaveDebouncer.cancel();
    await _persistController(storyId);

    final openTabs = List<String>.from(state.openTabIds)..remove(storyId);

    String? nextSelected = state.selectedStoryId;
    if (nextSelected == storyId) {
      nextSelected = openTabs.isNotEmpty ? openTabs.last : null;
    }

    final closingFindSession = state.inFileSearch?.storyId == storyId;
    final closingLocal =
        state.searchUiMode == SearchUiMode.local && closingFindSession;

    state = state.copyWith(
      openTabIds: openTabs,
      selectedStoryId: nextSelected,
      clearSelectedStoryId: nextSelected == null,
      searchUiMode: closingLocal ? SearchUiMode.none : null,
      searchQuery: closingLocal ? '' : null,
      clearInFileSearch: closingFindSession,
    );
    await _persistWorkspaceLayout();
    if (nextSelected != null) {
      await _ensureController(nextSelected);
    }

    // Dispose after the editor has switched away from this controller.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _disposeStoryResources(storyId);
    });
  }

  Future<void> createStory() async {
    await _flushPendingAutosave();

    final storyRepo = ref.read(storyRepositoryProvider);
    final noteRepo = ref.read(noteRepositoryProvider);
    final now = DateTime.now();
    final storyId = _uuid.v4();
    final color = AppColors
        .storyPalette[state.stories.length % AppColors.storyPalette.length];
    final story = Story(
      id: storyId,
      title: 'Untitled Story',
      priority: state.stories.length,
      status: 'todo',
      color: color,
      createdAt: now,
      updatedAt: now,
    );
    await storyRepo.insertStory(story);
    await noteRepo.upsertNote(
      Note(
        id: _uuid.v4(),
        storyId: storyId,
        deltaJson: emptyBodyDelta,
        updatedAt: now,
      ),
    );
    final stories = await storyRepo.getStories();
    final openTabs = List<String>.from(state.openTabIds)..add(storyId);
    state = state.copyWith(
      stories: stories,
      openTabIds: openTabs,
      selectedStoryId: storyId,
      saveStatus: SaveStatus.saved,
    );
    await _ensureController(storyId);
    await _persistWorkspaceLayout();
  }

  Future<void> moveStory(String storyId, int direction) {
    return _enqueueReorder(() async {
      final stories = List<Story>.from(state.stories);
      final index = stories.indexWhere((s) => s.id == storyId);
      if (index == -1) return;
      final target = index + direction;
      if (target < 0 || target >= stories.length) return;

      final item = stories.removeAt(index);
      stories.insert(target, item);
      await _commitStoryOrder(stories);
    });
  }

  Future<void> reorderStories(int oldIndex, int newIndex) {
    return _enqueueReorder(() async {
      var adjustedNewIndex = newIndex;
      if (adjustedNewIndex > oldIndex) adjustedNewIndex -= 1;
      final stories = List<Story>.from(state.stories);
      final item = stories.removeAt(oldIndex);
      stories.insert(adjustedNewIndex, item);
      await _commitStoryOrder(stories);
    });
  }

  Future<void> _enqueueReorder(Future<void> Function() op) async {
    final previous = _reorderChain;
    final completer = Completer<void>();
    _reorderChain = completer.future;
    try {
      if (previous != null) await previous;
      await op();
      completer.complete();
    } catch (e, st) {
      completer.completeError(e, st);
      rethrow;
    } finally {
      if (identical(_reorderChain, completer.future)) {
        _reorderChain = null;
      }
    }
  }

  Future<void> _commitStoryOrder(List<Story> stories) async {
    final now = DateTime.now();
    final reordered = <Story>[];
    for (var i = 0; i < stories.length; i++) {
      reordered.add(stories[i].copyWith(priority: i, updatedAt: now));
    }

    await ref.read(storyRepositoryProvider).saveStoryPriorities(reordered);
    final openTabIds = reordered
        .map((s) => s.id)
        .where(state.openTabIds.contains)
        .toList();
    state = state.copyWith(stories: reordered, openTabIds: openTabIds);
    await _persistWorkspaceLayout();
  }

  Future<void> renameStory(String storyId, String title) async {
    final normalizedTitle = title.trim();
    if (normalizedTitle.isEmpty) return;

    final stories = List<Story>.from(state.stories);
    final index = stories.indexWhere((s) => s.id == storyId);
    if (index == -1) return;
    if (stories[index].title == normalizedTitle) return;

    final updated = stories[index].copyWith(
      title: normalizedTitle,
      updatedAt: DateTime.now(),
    );
    stories[index] = updated;
    await ref.read(storyRepositoryProvider).updateStory(updated);
    state = state.copyWith(stories: stories);
  }

  Future<void> deleteStory(String storyId) async {
    if (state.selectedStoryId == storyId) {
      await _flushPendingAutosave();
    }

    await ref.read(storyRepositoryProvider).deleteStory(storyId);
    final stories = await ref.read(storyRepositoryProvider).getStories();
    final openTabs = List<String>.from(state.openTabIds)..remove(storyId);
    var selected = state.selectedStoryId;
    if (selected == storyId) {
      selected = openTabs.isNotEmpty ? openTabs.first : null;
    }

    final closingFindSession = state.inFileSearch?.storyId == storyId;
    final closingLocal =
        state.searchUiMode == SearchUiMode.local && closingFindSession;

    state = state.copyWith(
      stories: stories,
      openTabIds: openTabs,
      selectedStoryId: selected,
      clearSelectedStoryId: selected == null,
      searchUiMode: closingLocal ? SearchUiMode.none : null,
      searchQuery: closingLocal ? '' : null,
      clearInFileSearch: closingFindSession,
    );
    await _persistWorkspaceLayout();
    if (selected != null) {
      await _ensureController(selected);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _disposeStoryResources(storyId);
    });
  }

  void setZoom(double zoom) {
    final value = zoom.clamp(0.75, 1.5);
    state = state.copyWith(zoom: value);
    unawaited(_persistWorkspaceLayout());
  }

  void togglePriorityReorderMode() {
    state = state.copyWith(
      isPriorityReorderMode: !state.isPriorityReorderMode,
    );
  }

  /// Leaves rearrange mode. Priorities are already persisted on each move.
  void exitPriorityReorderMode() {
    if (!state.isPriorityReorderMode) return;
    state = state.copyWith(isPriorityReorderMode: false);
  }

  void setSearchQuery(String query) {
    final previous = state.searchQuery.trim();
    final next = query.trim();
    final queryChanged = previous != next;
    state = state.copyWith(
      searchQuery: query,
      searchPanelVisible:
          state.searchUiMode == SearchUiMode.global && next.isNotEmpty,
      clearInFileSearch:
          state.searchUiMode == SearchUiMode.local && next.isEmpty,
    );
    if (state.searchUiMode == SearchUiMode.local) {
      if (next.isEmpty) {
        _collapseDocumentSelection();
      } else if (queryChanged) {
        _runLocalFind(next, selectFirst: true);
      }
    } else if (queryChanged && state.inFileSearch != null) {
      state = state.copyWith(clearInFileSearch: true);
      _collapseDocumentSelection();
    }
  }

  void setSearchFocused(bool focused) =>
      state = state.copyWith(isSearchFocused: focused);

  void setSearchPanelVisible(bool visible) {
    state = state.copyWith(searchPanelVisible: visible);
  }

  /// Ctrl+F — find in the active story.
  void openLocalFind({String? seedQuery}) {
    final storyId = state.selectedStoryId;
    if (storyId == null) return;

    final query = (seedQuery ??
            state.inFileSearch?.query ??
            state.searchQuery)
        .trim();
    state = state.copyWith(
      searchUiMode: SearchUiMode.local,
      searchQuery: query,
      searchPanelVisible: false,
      isSearchFocused: true,
      localFindEpoch: state.localFindEpoch + 1,
    );
    if (query.isNotEmpty) {
      _runLocalFind(query, selectFirst: true);
    } else {
      state = state.copyWith(clearInFileSearch: true);
    }
  }

  /// Ctrl+Shift+F — search the whole workspace.
  void openGlobalSearch({String? seedQuery}) {
    final query = seedQuery ?? state.searchQuery;
    state = state.copyWith(
      searchUiMode: SearchUiMode.global,
      searchQuery: query,
      searchPanelVisible: query.trim().isNotEmpty,
      isSearchFocused: true,
      clearInFileSearch: true,
    );
    _collapseDocumentSelection();
  }

  void closeSearchUi() {
    state = state.copyWith(
      searchUiMode: SearchUiMode.none,
      searchQuery: '',
      searchPanelVisible: false,
      isSearchFocused: false,
      clearInFileSearch: true,
    );
    _collapseDocumentSelection();
  }

  /// Opens [storyId] and starts local find with the current global query.
  Future<void> openGlobalHit(String storyId) async {
    final query = state.searchQuery.trim();
    await openStory(storyId);
    state = state.copyWith(
      searchUiMode: SearchUiMode.local,
      searchPanelVisible: false,
      isSearchFocused: false,
    );
    if (query.isEmpty) return;
    _runLocalFind(query, selectFirst: true, storyId: storyId);
  }

  void goToNextInFileMatch() => _moveInFileMatch(1);

  void goToPreviousInFileMatch() => _moveInFileMatch(-1);

  void clearInFileSearch() {
    state = state.copyWith(clearInFileSearch: true);
    if (state.searchUiMode == SearchUiMode.local) {
      state = state.copyWith(searchQuery: '');
    }
    _collapseDocumentSelection();
  }

  void _runLocalFind(
    String query, {
    required bool selectFirst,
    String? storyId,
  }) {
    final id = storyId ?? state.selectedStoryId;
    if (id == null) return;
    final controller = controllerFor(id);
    if (controller == null) return;

    final offsets = controller.document.search(query, caseSensitive: false);
    final session = InFileSearchSession(
      storyId: id,
      query: query,
      offsets: offsets,
      activeIndex: 0,
    );
    state = state.copyWith(inFileSearch: session, searchQuery: query);

    if (offsets.isNotEmpty && selectFirst) {
      _selectMatch(controller, offsets.first, query.length);
      focusNodeFor(id)?.requestFocus();
    } else if (offsets.isEmpty) {
      _collapseDocumentSelection();
    }
  }

  void _moveInFileMatch(int delta) {
    final session = state.inFileSearch;
    if (session == null || session.offsets.isEmpty) return;
    if (session.storyId != state.selectedStoryId) return;

    final length = session.offsets.length;
    var nextIndex = (session.activeIndex + delta) % length;
    if (nextIndex < 0) nextIndex += length;

    final controller = controllerFor(session.storyId);
    if (controller == null) return;

    final offset = session.offsets[nextIndex];
    state = state.copyWith(
      inFileSearch: session.copyWith(activeIndex: nextIndex),
    );
    _selectMatch(controller, offset, session.query.length);
    focusNodeFor(session.storyId)?.requestFocus();
  }

  void _selectMatch(QuillController controller, int offset, int length) {
    var len = length;
    final leaf = controller.queryNode(offset);
    if (leaf is Embed) {
      len = 1;
    }
    final docLen = controller.document.length;
    final end = (offset + len).clamp(0, docLen);
    final start = offset.clamp(0, docLen);
    controller.updateSelection(
      TextSelection(baseOffset: start, extentOffset: end),
      ChangeSource.local,
    );
  }

  void _collapseDocumentSelection() {
    final controller = controllerFor(state.selectedStoryId);
    if (controller == null) return;
    final offset = controller.selection.baseOffset;
    controller.updateSelection(
      TextSelection.collapsed(offset: offset),
      ChangeSource.local,
    );
  }

  Future<void> saveActiveStory({bool force = false}) async {
    final storyId = state.selectedStoryId;
    if (storyId == null) return;
    await _persistController(storyId, force: force, updateStatus: true);
  }

  /// Flush unsaved work before process exit.
  Future<void> prepareForAppExit() async {
    _autosaveDebouncer.cancel();
    final storyId = state.selectedStoryId;
    if (storyId == null) return;
    await _persistController(storyId, force: true, updateStatus: true);
  }

  /// Persist all open buffers before export.
  Future<void> flushForExport() async {
    _autosaveDebouncer.cancel();
    for (final id in List<String>.from(state.openTabIds)) {
      await _persistController(id, force: true, updateStatus: id == state.selectedStoryId);
    }
  }

  Future<void> _persistController(
    String storyId, {
    bool force = true,
    bool updateStatus = false,
  }) async {
    final previous = _saveChain;
    final completer = Completer<void>();
    _saveChain = completer.future;
    try {
      if (previous != null) await previous;

      final controller = _controllers[storyId];
      if (controller == null) {
        completer.complete();
        return;
      }

      if (updateStatus) {
        if (!force && state.saveStatus == SaveStatus.saved) {
          completer.complete();
          return;
        }
        state = state.copyWith(saveStatus: SaveStatus.saving);
      }

      try {
        final deltaJson = jsonEncode(controller.document.toDelta().toJson());
        final noteId = _noteIds[storyId] ?? _uuid.v4();
        _noteIds[storyId] = noteId;
        final note = Note(
          id: noteId,
          storyId: storyId,
          deltaJson: deltaJson,
          updatedAt: DateTime.now(),
        );
        await ref.read(noteRepositoryProvider).upsertNote(note);
        await ref
            .read(historyRepositoryProvider)
            .saveSnapshot(storyId: storyId, snapshot: deltaJson);
        if (updateStatus && state.selectedStoryId == storyId) {
          state = state.copyWith(
            saveStatus: SaveStatus.saved,
            lastSavedAt: DateTime.now(),
          );
        }
      } catch (_) {
        if (updateStatus && state.selectedStoryId == storyId) {
          state = state.copyWith(saveStatus: SaveStatus.error);
        }
      }
      completer.complete();
    } catch (e, st) {
      completer.completeError(e, st);
      rethrow;
    } finally {
      if (identical(_saveChain, completer.future)) {
        _saveChain = null;
      }
    }
  }

  Future<void> _flushPendingAutosave() async {
    _autosaveDebouncer.cancel();
    if (!ref.read(appSettingsProvider).autosaveEnabled) return;
    if (state.saveStatus != SaveStatus.unsaved &&
        state.saveStatus != SaveStatus.error) {
      return;
    }
    await saveActiveStory(force: true);
  }

  void _onDocumentChanged() {
    final nextEpoch = state.documentEpoch + 1;
    if (state.saveStatus != SaveStatus.unsaved) {
      state = state.copyWith(
        saveStatus: SaveStatus.unsaved,
        documentEpoch: nextEpoch,
      );
    } else {
      state = state.copyWith(documentEpoch: nextEpoch);
    }

    if (ref.read(appSettingsProvider).autosaveEnabled) {
      _autosaveDebouncer.run(() {
        unawaited(saveActiveStory(force: true));
      });
    } else {
      _autosaveDebouncer.cancel();
    }

    _refreshInFileSearchOffsets();
  }

  void _refreshInFileSearchOffsets() {
    final session = state.inFileSearch;
    if (session == null) return;
    if (session.storyId != state.selectedStoryId) return;
    final controller = controllerFor(session.storyId);
    if (controller == null) return;

    final offsets =
        controller.document.search(session.query, caseSensitive: false);
    final index = offsets.isEmpty
        ? 0
        : session.activeIndex.clamp(0, offsets.length - 1);
    state = state.copyWith(
      inFileSearch: session.copyWith(offsets: offsets, activeIndex: index),
    );
  }

  Future<void> _ensureController(String storyId) async {
    if (_controllers.containsKey(storyId)) {
      _attachActiveListener(storyId);
      return;
    }

    final inFlight = _ensuringControllers[storyId];
    if (inFlight != null) {
      await inFlight;
      _attachActiveListener(storyId);
      return;
    }

    final future = _createController(storyId);
    _ensuringControllers[storyId] = future;
    try {
      await future;
    } finally {
      _ensuringControllers.remove(storyId);
    }
  }

  Future<void> _createController(String storyId) async {
    if (_controllers.containsKey(storyId)) {
      _attachActiveListener(storyId);
      return;
    }

    Story? story;
    for (final s in state.stories) {
      if (s.id == storyId) {
        story = s;
        break;
      }
    }
    final note = await ref
        .read(noteRepositoryProvider)
        .getNoteByStoryId(storyId);

    Document document;
    var migrated = false;
    if (note != null) {
      _noteIds[storyId] = note.id;
      try {
        final deltaJson = jsonDecode(note.deltaJson) as List<dynamic>;
        final stripped = _stripLeadingTitleHeading(
          deltaJson,
          story?.title ?? '',
        );
        migrated = stripped.migrated;
        document = Document.fromJson(stripped.ops);
      } catch (_) {
        document = Document()..insert(0, note.deltaJson);
      }
    } else {
      document = Document();
    }

    // Another caller may have won a race while we awaited.
    if (_controllers.containsKey(storyId)) {
      _attachActiveListener(storyId);
      return;
    }

    final controller = QuillController(
      document: document,
      selection: const TextSelection.collapsed(offset: 0),
    );
    _controllers[storyId] = controller;
    _focusNodes[storyId] = FocusNode(debugLabel: 'editor-$storyId');
    _scrollControllers[storyId] = ScrollController();
    _attachActiveListener(storyId);
    state = state.copyWith(controllerEpoch: state.controllerEpoch + 1);

    if (migrated && note != null) {
      final bodyJson = jsonEncode(document.toDelta().toJson());
      await ref
          .read(noteRepositoryProvider)
          .upsertNote(
            note.copyWith(deltaJson: bodyJson, updatedAt: DateTime.now()),
          );
    }
  }

  /// Removes a leading H1 that matches the story title so body stays title-free.
  ({List<dynamic> ops, bool migrated}) _stripLeadingTitleHeading(
    List<dynamic> ops,
    String title,
  ) {
    if (ops.isEmpty || title.trim().isEmpty) {
      return (ops: ops, migrated: false);
    }

    final first = ops.first;
    if (first is! Map) return (ops: ops, migrated: false);

    final attributes = first['attributes'];
    final insert = first['insert'];
    if (attributes is! Map || insert is! String) {
      return (ops: ops, migrated: false);
    }
    if (attributes['header'] != 1) return (ops: ops, migrated: false);

    final headingText = insert.replaceAll(RegExp(r'\n+$'), '').trim();
    if (headingText.toLowerCase() != title.trim().toLowerCase()) {
      return (ops: ops, migrated: false);
    }

    final remaining = ops.sublist(1);
    // Drop a following blank paragraph if present.
    if (remaining.isNotEmpty) {
      final next = remaining.first;
      if (next is Map && next['insert'] == '\n' && next['attributes'] == null) {
        remaining.removeAt(0);
      }
    }

    if (remaining.isEmpty) {
      return (
        ops: [
          {'insert': '\n'},
        ],
        migrated: true,
      );
    }

    return (ops: remaining, migrated: true);
  }

  void _attachActiveListener(String storyId) {
    final controller = _controllers[storyId];
    if (controller == null) return;
    if (_activeController == controller) return;

    unawaited(_documentChangesSub?.cancel());
    _activeController = controller;
    _documentChangesSub = controller.changes.listen((_) {
      _onDocumentChanged();
    });
  }

  void _disposeStoryResources(String storyId) {
    final controller = _controllers.remove(storyId);
    if (controller != null) {
      if (_activeController == controller) {
        unawaited(_documentChangesSub?.cancel());
        _documentChangesSub = null;
        _activeController = null;
      }
      controller.dispose();
    }
    _focusNodes.remove(storyId)?.dispose();
    _scrollControllers.remove(storyId)?.dispose();
    _noteIds.remove(storyId);
  }

  Future<void> _persistWorkspaceLayout({String? selectedStoryId}) async {
    final hive = ref.read(hiveStorageServiceProvider);
    await hive.put(
      HiveStorageService.workspaceStateBox,
      'openTabIds',
      state.openTabIds,
    );
    final selected = selectedStoryId ?? state.selectedStoryId;
    if (selected == null) {
      await hive.delete(
        HiveStorageService.workspaceStateBox,
        'selectedStoryId',
      );
    } else {
      await hive.put(
        HiveStorageService.workspaceStateBox,
        'selectedStoryId',
        selected,
      );
    }
    await hive.put(HiveStorageService.workspaceStateBox, 'zoom', state.zoom);
  }

  int wordCountForActive() {
    final controller = controllerFor(state.selectedStoryId);
    if (controller == null) return 0;
    final text = controller.document.toPlainText().trim();
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }

  int charCountForActive() {
    final controller = controllerFor(state.selectedStoryId);
    if (controller == null) return 0;
    return controller.document.toPlainText().trim().length;
  }
}

final workspaceProvider = NotifierProvider<WorkspaceNotifier, WorkspaceState>(
  WorkspaceNotifier.new,
);
