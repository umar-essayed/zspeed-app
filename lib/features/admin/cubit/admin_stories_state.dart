import 'package:equatable/equatable.dart';
import 'package:z_speed/features/stories/model/story.dart';

class AdminStoriesState extends Equatable {
  final bool isLoading;
  final List<Story> allStories;
  final String? error;
  final String? actionSuccessMessage;

  const AdminStoriesState({
    this.isLoading = false,
    this.allStories = const [],
    this.error,
    this.actionSuccessMessage,
  });

  List<Story> get pendingStories =>
      allStories.where((s) => s.status == StoryStatus.pending).toList();

  List<Story> get approvedStories =>
      allStories.where((s) => s.status == StoryStatus.approved).toList();

  List<Story> get rejectedStories =>
      allStories.where((s) => s.status == StoryStatus.rejected).toList();

  AdminStoriesState copyWith({
    bool? isLoading,
    List<Story>? allStories,
    List<Story>? pendingStories,
    String? error,
    String? actionSuccessMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return AdminStoriesState(
      isLoading: isLoading ?? this.isLoading,
      allStories: allStories ?? pendingStories ?? this.allStories,
      error: clearError ? null : (error ?? this.error),
      actionSuccessMessage: clearSuccess ? null : (actionSuccessMessage ?? this.actionSuccessMessage),
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        allStories,
        error,
        actionSuccessMessage,
      ];
}
