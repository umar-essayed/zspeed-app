import 'package:equatable/equatable.dart';
import 'package:z_speed/features/stories/model/story.dart';

/// State of the customer's stories feed.
class CustomerStoriesState extends Equatable {
  final bool isLoading;
  final List<Story> stories;
  final Set<String> seenStoryIds;
  final String? error;

  const CustomerStoriesState({
    this.isLoading = false,
    this.stories = const [],
    this.seenStoryIds = const {},
    this.error,
  });

  CustomerStoriesState copyWith({
    bool? isLoading,
    List<Story>? stories,
    Set<String>? seenStoryIds,
    String? error,
    bool clearError = false,
  }) {
    return CustomerStoriesState(
      isLoading: isLoading ?? this.isLoading,
      stories: stories ?? this.stories,
      seenStoryIds: seenStoryIds ?? this.seenStoryIds,
      error: clearError ? null : (error ?? this.error),
    );
  }

  /// Groups stories by vendorId and sorts the groups dynamically.
  /// 
  /// Sorting rules:
  /// 1. Vendors with at least one unseen story appear first.
  /// 2. Secondary sorting: newest story creation date first.
  List<List<Story>> get groupedStories {
    if (stories.isEmpty) return const [];

    final Map<String, List<Story>> map = {};
    for (final story in stories) {
      map.putIfAbsent(story.vendorId, () => []).add(story);
    }

    final groups = map.values.toList();

    // Sort stories within each vendor group by newest first
    for (final group in groups) {
      group.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    // Sort vendor groups
    groups.sort((a, b) {
      final aHasUnseen = a.any((s) => !seenStoryIds.contains(s.id));
      final bHasUnseen = b.any((s) => !seenStoryIds.contains(s.id));

      if (aHasUnseen && !bHasUnseen) return -1;
      if (!aHasUnseen && bHasUnseen) return 1;

      // Both seen or both unseen — sort by the creation time of the newest story
      final aNewest = a.map((s) => s.createdAt).reduce((c, n) => c.isAfter(n) ? c : n);
      final bNewest = b.map((s) => s.createdAt).reduce((c, n) => c.isAfter(n) ? c : n);
      return bNewest.compareTo(aNewest);
    });

    return groups;
  }

  @override
  List<Object?> get props => [isLoading, stories, seenStoryIds, error];
}
