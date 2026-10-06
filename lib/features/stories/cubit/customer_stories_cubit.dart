import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:z_speed/features/stories/repository/story_repository.dart';
import 'package:z_speed/features/stories/cubit/customer_stories_state.dart';

/// Cubit managing loading active stories and view statuses for customers.
@injectable
class CustomerStoriesCubit extends Cubit<CustomerStoriesState> {
  final StoryRepository _storyRepository;
  StreamSubscription? _storiesSubscription;
  String? _currentUserId;

  CustomerStoriesCubit(this._storyRepository) : super(const CustomerStoriesState());

  /// Starts listening to active stories and populates viewed states.
  void init(String? currentUserId) {
    _currentUserId = currentUserId;
    emit(state.copyWith(isLoading: true, clearError: true));
    
    _storiesSubscription?.cancel();
    _storiesSubscription = _storyRepository.streamActiveStories().listen(
      (stories) {
        final seenIds = <String>{};
        if (currentUserId != null) {
          for (final story in stories) {
            if (story.viewedBy.contains(currentUserId)) {
              seenIds.add(story.id);
            }
          }
        }
        emit(state.copyWith(
          isLoading: false,
          stories: stories,
          seenStoryIds: seenIds,
        ));
      },
      onError: (err) {
        emit(state.copyWith(isLoading: false, error: err.toString()));
      },
    );
  }

  /// Updates local seen state and syncs to database.
  Future<void> markStoryAsSeen(String storyId) async {
    if (_currentUserId == null) return;
    
    // Optimistic local state update
    final newSeen = Set<String>.from(state.seenStoryIds)..add(storyId);
    emit(state.copyWith(seenStoryIds: newSeen));

    // Sync to Firestore
    await _storyRepository.markStoryAsViewed(storyId, _currentUserId!);
  }

  @override
  Future<void> close() {
    _storiesSubscription?.cancel();
    return super.close();
  }
}
