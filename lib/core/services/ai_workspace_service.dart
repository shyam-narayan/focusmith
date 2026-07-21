/// AI-ready service contract for future plugin and assistant integrations.
abstract class AiWorkspaceService {
  Future<String> summarizeStory({
    required String title,
    required String plainText,
  });

  Future<List<String>> suggestNextActions({
    required List<String> storyTitles,
  });
}

/// Local placeholder implementation until an AI provider is configured.
class LocalAiWorkspaceService implements AiWorkspaceService {
  @override
  Future<String> summarizeStory({
    required String title,
    required String plainText,
  }) async {
    final trimmed = plainText.trim();
    if (trimmed.isEmpty) {
      return '$title has no content yet.';
    }
    final preview = trimmed.length > 180 ? '${trimmed.substring(0, 180)}...' : trimmed;
    return 'Summary for $title: $preview';
  }

  @override
  Future<List<String>> suggestNextActions({
    required List<String> storyTitles,
  }) async {
    if (storyTitles.isEmpty) {
      return const ['Create your first story and define the outcome.'];
    }
    return [
      'Focus on ${storyTitles.first}',
      if (storyTitles.length > 1) 'Queue ${storyTitles[1]} after the top priority item',
      'Review lower-priority stories at the end of the day',
    ];
  }
}
