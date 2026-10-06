import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:z_speed/features/admin/cubit/admin_stories_state.dart';
import 'package:z_speed/features/stories/repository/story_repository.dart';

@injectable
class AdminStoriesCubit extends Cubit<AdminStoriesState> {
  final StoryRepository _storyRepository;
  StreamSubscription? _pendingStoriesSubscription;

  AdminStoriesCubit(this._storyRepository) : super(const AdminStoriesState());

  /// Listens to real-time stories (all statuses) awaiting admin moderation.
  void watchPendingStories() {
    emit(state.copyWith(isLoading: true, clearError: true));
    _pendingStoriesSubscription?.cancel();
    _pendingStoriesSubscription = _storyRepository.streamAllStories().listen(
      (stories) {
        emit(state.copyWith(isLoading: false, allStories: stories));
      },
      onError: (err) {
        emit(state.copyWith(isLoading: false, error: err.toString()));
      },
    );
  }

  /// Approves a pending story and starts its 24-hour lifetime.
  Future<void> approveStory(String storyId) async {
    emit(state.copyWith(clearError: true, clearSuccess: true));
    try {
      await _storyRepository.approveStory(storyId);
      emit(state.copyWith(actionSuccessMessage: 'Story approved successfully'));
    } catch (e) {
      emit(state.copyWith(error: 'Failed to approve story: ${e.toString()}'));
    }
  }

  /// Rejects a pending story with an optional reason.
  Future<void> rejectStory(String storyId, {String? reason}) async {
    emit(state.copyWith(clearError: true, clearSuccess: true));
    try {
      await _storyRepository.rejectStory(storyId, reason: reason);
      emit(state.copyWith(actionSuccessMessage: 'Story rejected'));
    } catch (e) {
      emit(state.copyWith(error: 'Failed to reject story: ${e.toString()}'));
    }
  }

  /// Permanently deletes a story and removes its media file from storage.
  Future<void> deleteStory(String storyId, String mediaUrl) async {
    emit(state.copyWith(clearError: true, clearSuccess: true));
    try {
      await _storyRepository.deleteStory(storyId, mediaUrl);
      emit(state.copyWith(actionSuccessMessage: 'Story deleted successfully'));
    } catch (e) {
      emit(state.copyWith(error: 'Failed to delete story: ${e.toString()}'));
    }
  }

  @override
  Future<void> close() {
    _pendingStoriesSubscription?.cancel();
    return super.close();
  }
}
