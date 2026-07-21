import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_title_bar.dart';
import '../../editor/presentation/editor_status_bar.dart';
import '../../editor/presentation/story_editor_panel.dart';
import '../../priority/presentation/priority_board.dart';
import '../../search/data/search_service.dart';
import '../../search/presentation/search_results_panel.dart';
import 'providers/workspace_provider.dart';
import 'widgets/story_tab_bar.dart';

class WorkspaceShell extends ConsumerStatefulWidget {
  const WorkspaceShell({super.key});

  @override
  ConsumerState<WorkspaceShell> createState() => _WorkspaceShellState();
}

class _WorkspaceShellState extends ConsumerState<WorkspaceShell> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  late final FocusNode _reorderFocusNode;

  @override
  void initState() {
    super.initState();
    _reorderFocusNode = FocusNode(debugLabel: 'priorityReorder');
    // Focus-independent handlers (Quill/list focus otherwise swallows these).
    HardwareKeyboard.instance.addHandler(_handleGlobalShortcuts);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleGlobalShortcuts);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _reorderFocusNode.dispose();
    super.dispose();
  }

  bool _handleGlobalShortcuts(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return false;

    if (_handleUndoRedoShortcut(event)) return true;
    if (_handleReorderShortcut(event)) return true;
    return false;
  }

  /// Standard app undo/redo:
  /// - Plain text fields (title, search, rename) keep Flutter/Fluent undo.
  /// - Otherwise the active Quill document is undone/redone.
  bool _handleUndoRedoShortcut(KeyEvent event) {
    if (event.logicalKey != LogicalKeyboardKey.keyZ) return false;

    final pressed = HardwareKeyboard.instance.logicalKeysPressed;
    final control =
        pressed.contains(LogicalKeyboardKey.controlLeft) ||
        pressed.contains(LogicalKeyboardKey.controlRight) ||
        pressed.contains(LogicalKeyboardKey.control);
    if (!control) return false;

    // Let EditableText / TextBox own their undo stacks.
    if (_isPlainTextFieldFocused()) return false;

    final notifier = ref.read(workspaceProvider.notifier);
    final storyId = ref.read(workspaceProvider).selectedStoryId;
    final controller = notifier.controllerFor(storyId);
    if (controller == null) return false;

    final shift =
        pressed.contains(LogicalKeyboardKey.shiftLeft) ||
        pressed.contains(LogicalKeyboardKey.shiftRight) ||
        pressed.contains(LogicalKeyboardKey.shift);

    if (shift) {
      if (!controller.hasRedo) return false;
      controller.redo();
      return true;
    }

    if (!controller.hasUndo) return false;
    controller.undo();
    return true;
  }

  bool _isPlainTextFieldFocused() {
    final primary = FocusManager.instance.primaryFocus;
    final context = primary?.context;
    if (context == null) return false;
    if (context.widget is EditableText) return true;
    return context.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  bool _handleReorderShortcut(KeyEvent event) {
    final workspace = ref.read(workspaceProvider);
    if (!workspace.isPriorityReorderMode) return false;

    final pressed = HardwareKeyboard.instance.logicalKeysPressed;
    final alt =
        pressed.contains(LogicalKeyboardKey.altLeft) ||
        pressed.contains(LogicalKeyboardKey.altRight) ||
        pressed.contains(LogicalKeyboardKey.alt);
    final shift =
        pressed.contains(LogicalKeyboardKey.shiftLeft) ||
        pressed.contains(LogicalKeyboardKey.shiftRight) ||
        pressed.contains(LogicalKeyboardKey.shift);
    if (!alt || !shift) return false;

    final storyId = workspace.selectedStoryId;
    if (storyId == null) return false;

    final notifier = ref.read(workspaceProvider.notifier);
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      notifier.moveStory(storyId, -1);
      return true;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      notifier.moveStory(storyId, 1);
      return true;
    }
    return false;
  }

  void _exitReorderIfNeeded() {
    ref.read(workspaceProvider.notifier).exitPriorityReorderMode();
  }

  void _ensureReorderFocus() {
    if (!mounted) return;
    if (!ref.read(workspaceProvider).isPriorityReorderMode) return;
    if (!_reorderFocusNode.hasFocus) {
      _reorderFocusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final workspace = ref.watch(workspaceProvider);
    final notifier = ref.read(workspaceProvider.notifier);
    final searchQuery = workspace.searchQuery;
    final searchResults = ref.watch(searchResultsProvider);
    final reorderMode = workspace.isPriorityReorderMode;
    final showSearchPanel = workspace.searchUiMode == SearchUiMode.global &&
        searchQuery.trim().isNotEmpty &&
        workspace.searchPanelVisible;

    ref.listen<bool>(
      workspaceProvider.select((s) => s.isPriorityReorderMode),
      (previous, next) {
        if (next) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _ensureReorderFocus();
          });
        } else if (_reorderFocusNode.hasFocus) {
          _reorderFocusNode.unfocus();
        }
      },
    );

    ref.listen(
      workspaceProvider.select((s) => (s.searchUiMode, s.searchQuery)),
      (previous, next) {
        final mode = next.$1;
        final query = next.$2;
        if (mode == SearchUiMode.none && query.isEmpty) {
          if (_searchController.text.isNotEmpty) {
            _searchController.clear();
          }
          return;
        }
        if (mode == SearchUiMode.global && _searchController.text != query) {
          _searchController.value = TextEditingValue(
            text: query,
            selection: TextSelection.collapsed(offset: query.length),
          );
        }
      },
    );

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): () =>
            notifier.createStory(),
        const SingleActivator(LogicalKeyboardKey.keyW, control: true): () {
          final id = workspace.selectedStoryId;
          if (id != null) notifier.closeStory(id);
        },
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): () =>
            notifier.saveActiveStory(force: true),
        const SingleActivator(LogicalKeyboardKey.keyF, control: true): () {
          _exitReorderIfNeeded();
          _searchFocusNode.unfocus();
          notifier.openLocalFind();
        },
        const SingleActivator(
          LogicalKeyboardKey.keyF,
          control: true,
          shift: true,
        ): () {
          _exitReorderIfNeeded();
          notifier.openGlobalSearch(seedQuery: _searchController.text);
          _searchFocusNode.requestFocus();
          _searchController.selection = TextSelection(
            baseOffset: 0,
            extentOffset: _searchController.text.length,
          );
        },
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (workspace.searchUiMode == SearchUiMode.local ||
              workspace.inFileSearch != null) {
            notifier.closeSearchUi();
            return;
          }
          if (workspace.searchUiMode == SearchUiMode.global ||
              showSearchPanel ||
              _searchFocusNode.hasFocus) {
            _clearSearch(notifier);
          }
        },
        const SingleActivator(LogicalKeyboardKey.enter, control: true): () {
          if (workspace.searchUiMode == SearchUiMode.local) {
            notifier.goToNextInFileMatch();
          }
        },
        const SingleActivator(
          LogicalKeyboardKey.enter,
          control: true,
          shift: true,
        ): () {
          if (workspace.searchUiMode == SearchUiMode.local) {
            notifier.goToPreviousInFileMatch();
          }
        },
        const SingleActivator(LogicalKeyboardKey.f3): () {
          if (workspace.searchUiMode == SearchUiMode.local) {
            notifier.goToNextInFileMatch();
          }
        },
        const SingleActivator(LogicalKeyboardKey.f3, shift: true): () {
          if (workspace.searchUiMode == SearchUiMode.local) {
            notifier.goToPreviousInFileMatch();
          }
        },
        const SingleActivator(LogicalKeyboardKey.tab, control: true): () =>
            _cycleTab(workspace, notifier, forward: true),
        const SingleActivator(
          LogicalKeyboardKey.tab,
          control: true,
          shift: true,
        ): () =>
            _cycleTab(workspace, notifier, forward: false),
      },
      child: ColoredBox(
        color: AppColors.background,
        child: Column(
          children: [
            AppTitleBar(
              searchController: _searchController,
              searchFocusNode: _searchFocusNode,
              onSearchChanged: (value) {
                if (workspace.searchUiMode != SearchUiMode.global) {
                  notifier.openGlobalSearch(seedQuery: value);
                } else {
                  notifier.setSearchQuery(value);
                }
              },
              onSearchSubmitted: (_) => _openFirstResult(),
              onSearchCleared: () => _clearSearch(notifier),
              onSearchFocused: () {
                if (workspace.searchUiMode != SearchUiMode.global) {
                  notifier.openGlobalSearch(seedQuery: _searchController.text);
                }
              },
            ),
            Expanded(
              child: Stack(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Listener(
                          behavior: HitTestBehavior.translucent,
                          onPointerDown: (_) => _exitReorderIfNeeded(),
                          child: const Column(
                            children: [
                              StoryTabBar(),
                              Expanded(child: StoryEditorPanel()),
                              EditorStatusBar(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 1,
                        child: ColoredBox(color: AppColors.border),
                      ),
                      Expanded(
                        flex: 1,
                        child: Focus(
                          focusNode: _reorderFocusNode,
                          canRequestFocus: reorderMode,
                          child: PriorityBoard(
                            onStorySelected: reorderMode
                                ? (_) => WidgetsBinding.instance
                                      .addPostFrameCallback(
                                        (_) => _ensureReorderFocus(),
                                      )
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (showSearchPanel)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: searchResults.when(
                        data: (results) => SearchResultsPanel(
                          results: results,
                          query: searchQuery,
                          onSelect: (storyId) async {
                            _exitReorderIfNeeded();
                            await notifier.openGlobalHit(storyId);
                          },
                        ),
                        loading: () => SearchResultsPanel(
                          results: const [],
                          query: searchQuery,
                          isLoading: true,
                          onSelect: (_) {},
                        ),
                        error: (_, _) => SearchResultsPanel(
                          results: const [],
                          query: searchQuery,
                          onSelect: (_) {},
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _clearSearch(WorkspaceNotifier notifier) {
    _searchController.clear();
    notifier.closeSearchUi();
    _searchFocusNode.unfocus();
  }

  void _cycleTab(
    WorkspaceState workspace,
    WorkspaceNotifier notifier, {
    required bool forward,
  }) {
    _exitReorderIfNeeded();
    final tabs = workspace.openTabs;
    if (tabs.isEmpty) return;
    final currentIndex = tabs.indexWhere(
      (story) => story.id == workspace.selectedStoryId,
    );
    if (currentIndex == -1) {
      notifier.selectStory(tabs.first.id);
      return;
    }
    final nextIndex = forward
        ? (currentIndex + 1) % tabs.length
        : (currentIndex - 1 + tabs.length) % tabs.length;
    notifier.selectStory(tabs[nextIndex].id);
  }

  Future<void> _openFirstResult() async {
    final results = await ref.read(searchResultsProvider.future);
    if (results.isEmpty || !mounted) return;
    _exitReorderIfNeeded();
    await ref.read(workspaceProvider.notifier).openGlobalHit(results.first.storyId);
  }
}
