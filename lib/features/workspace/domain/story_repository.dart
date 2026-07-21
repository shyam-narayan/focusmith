import 'story.dart';

/// Repository interface defines storage operations for [Story] entities.
abstract class StoryRepository {
  /// Fetch all active stories sorted by priority index ascending.
  Future<List<Story>> getStories();

  /// Insert a new story.
  Future<void> insertStory(Story story);

  /// Update an existing story's attributes (excluding priority bulk reorders).
  Future<void> updateStory(Story story);

  /// Delete a story by ID. Associated notes and history entries will cascade delete.
  Future<void> deleteStory(String id);

  /// Save priority ordering updates across multiple stories inside a database transaction.
  Future<void> saveStoryPriorities(List<Story> stories);
}
