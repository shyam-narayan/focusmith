import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../workspace/presentation/providers/workspace_provider.dart';
import '../data/search_service.dart';

class SearchResultsPanel extends StatelessWidget {
  const SearchResultsPanel({
    super.key,
    required this.results,
    required this.query,
    required this.onSelect,
    this.isLoading = false,
  });

  final List<SearchResult> results;
  final String query;
  final ValueChanged<String> onSelect;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        width: 560,
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        constraints: const BoxConstraints(maxHeight: 320),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
              child: Row(
                children: [
                  const Text(
                    'Search all stories',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    isLoading
                        ? 'Searching…'
                        : results.isEmpty
                        ? 'No matches'
                        : '${results.length} result${results.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: ProgressRing()),
              )
            else if (results.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                child: Text(
                  query.trim().isEmpty
                      ? 'Type to search the workspace.'
                      : 'No stories match “$query”.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: results.length,
                  separatorBuilder: (_, _) => const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Divider(),
                  ),
                  itemBuilder: (context, index) {
                    final result = results[index];
                    return ListTile(
                      leading: Icon(
                        result.matchInTitle
                            ? FluentIcons.page_header
                            : FluentIcons.text_document,
                        size: 16,
                        color: AppColors.textMuted,
                      ),
                      title: Text(
                        result.title.isEmpty ? 'Untitled Story' : result.title,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        _subtitleFor(result),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                      trailing: result.matchCount > 0
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${result.matchCount}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accentLight,
                                ),
                              ),
                            )
                          : null,
                      onPressed: () => onSelect(result.storyId),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _subtitleFor(SearchResult result) {
    final parts = <String>[];
    if (result.matchCount > 0) {
      parts.add(
        '${result.matchCount} match${result.matchCount == 1 ? '' : 'es'} in file',
      );
    } else if (result.matchInTitle) {
      parts.add('Matched in title');
    }
    if (result.snippet.isNotEmpty && result.snippet != 'Matched in title') {
      parts.add(result.snippet);
    }
    return parts.join(' · ');
  }
}

/// Global workspace search results (Ctrl+Shift+F).
final searchResultsProvider = FutureProvider<List<SearchResult>>((ref) async {
  final workspace = ref.watch(workspaceProvider);
  if (workspace.searchUiMode != SearchUiMode.global) return [];

  final query = workspace.searchQuery;
  if (query.trim().isEmpty) return [];

  final notifier = ref.read(workspaceProvider.notifier);
  final titles = {
    for (final story in workspace.stories) story.id: story.title,
  };

  final liveDocuments = <String, String>{};
  for (final id in workspace.openTabIds) {
    final controller = notifier.controllerFor(id);
    if (controller != null) {
      liveDocuments[id] = controller.document.toPlainText();
    }
  }

  ref.watch(workspaceProvider.select((s) => s.documentEpoch));

  return ref.read(searchServiceProvider).searchGlobal(
    query,
    openTabIds: workspace.openTabIds,
    liveDocuments: liveDocuments,
    titles: titles,
  );
});
