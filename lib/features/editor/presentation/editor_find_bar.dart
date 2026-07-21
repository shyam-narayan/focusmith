import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../search/data/search_service.dart';
import '../../workspace/presentation/providers/workspace_provider.dart';

/// Ctrl+F find strip for the active story: query field + match nav.
class EditorFindBar extends ConsumerStatefulWidget {
  const EditorFindBar({super.key});

  @override
  ConsumerState<EditorFindBar> createState() => _EditorFindBarState();
}

class _EditorFindBarState extends ConsumerState<EditorFindBar> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    final query = ref.read(workspaceProvider).searchQuery;
    _controller = TextEditingController(text: query);
    _focusNode = FocusNode(debugLabel: 'localFind');
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(
      workspaceProvider.select((s) => s.searchUiMode),
    );
    if (mode != SearchUiMode.local) return const SizedBox.shrink();

    final session = ref.watch(
      workspaceProvider.select((s) => s.inFileSearch),
    );
    final query = ref.watch(
      workspaceProvider.select((s) => s.searchQuery),
    );
    final notifier = ref.read(workspaceProvider.notifier);

    ref.listen<int>(
      workspaceProvider.select((s) => s.localFindEpoch),
      (previous, next) {
        if (ref.read(workspaceProvider).searchUiMode != SearchUiMode.local) {
          return;
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _syncController(ref.read(workspaceProvider).searchQuery);
          _focusNode.requestFocus();
          _controller.selection = TextSelection(
            baseOffset: 0,
            extentOffset: _controller.text.length,
          );
        });
      },
    );

    if (!_syncing && _controller.text != query) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _syncing) return;
        if (_controller.text != query) _syncController(query);
      });
    }

    final hasMatches = (session?.matchCount ?? 0) > 0;
    final label = session == null || query.trim().isEmpty
        ? 'Find in file'
        : hasMatches
            ? '${session.activeIndex + 1} of ${session.matchCount}'
            : 'No matches';

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: AppColors.surfaceElevated,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          const Icon(
            FluentIcons.search,
            size: 13,
            color: AppColors.accentLight,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextBox(
              controller: _controller,
              focusNode: _focusNode,
              placeholder: 'Find in current story…',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
              onChanged: (value) {
                _syncing = true;
                notifier.setSearchQuery(value);
                _syncing = false;
              },
              onSubmitted: (_) => notifier.goToNextInFileMatch(),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(FluentIcons.chevron_up, size: 14),
            onPressed: hasMatches ? notifier.goToPreviousInFileMatch : null,
          ),
          IconButton(
            icon: const Icon(FluentIcons.chevron_down, size: 14),
            onPressed: hasMatches ? notifier.goToNextInFileMatch : null,
          ),
          IconButton(
            icon: const Icon(FluentIcons.clear, size: 12),
            onPressed: notifier.closeSearchUi,
          ),
        ],
      ),
    );
  }

  void _syncController(String text) {
    _syncing = true;
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    _syncing = false;
  }
}
