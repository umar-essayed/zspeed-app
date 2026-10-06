import 'package:equatable/equatable.dart';
import 'package:z_speed/features/stories/model/story.dart';

/// State of the vendor's story manager.
class VendorStoriesState extends Equatable {
  final bool isLoading;
  final bool isUploading;
  final List<Story> stories;
  final String? error;

  const VendorStoriesState({
    this.isLoading = false,
    this.isUploading = false,
    this.stories = const [],
    this.error,
  });

  VendorStoriesState copyWith({
    bool? isLoading,
    bool? isUploading,
    List<Story>? stories,
    String? error,
    bool clearError = false,
  }) {
    return VendorStoriesState(
      isLoading: isLoading ?? this.isLoading,
      isUploading: isUploading ?? this.isUploading,
      stories: stories ?? this.stories,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [isLoading, isUploading, stories, error];
}
