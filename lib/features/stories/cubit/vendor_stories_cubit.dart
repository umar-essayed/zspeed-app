import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:injectable/injectable.dart';
import 'package:z_speed/features/stories/repository/story_repository.dart';
import 'package:z_speed/core/enums/user_enums.dart';
import 'package:z_speed/features/stories/cubit/vendor_stories_state.dart';

/// Cubit managing state for the vendor dashboard's Story Manager.
@injectable
class VendorStoriesCubit extends Cubit<VendorStoriesState> {
  final StoryRepository _storyRepository;
  StreamSubscription? _storiesSubscription;

  VendorStoriesCubit(this._storyRepository) : super(const VendorStoriesState());

  /// Subscribes to the active stories of the specific vendor.
  void loadVendorStories(String vendorId) {
    emit(state.copyWith(isLoading: true, clearError: true));
    _storiesSubscription?.cancel();
    _storiesSubscription = _storyRepository.streamVendorStories(vendorId).listen(
      (stories) {
        emit(state.copyWith(isLoading: false, stories: stories));
      },
      onError: (err) {
        emit(state.copyWith(isLoading: false, error: err.toString()));
      },
    );
  }

  /// Creates and uploads a new vendor story.
  Future<void> addStory({
    required String vendorId,
    required String vendorName,
    required String vendorLogoUrl,
    required VendorType vendorType,
    required XFile imageFile,
    String? caption,
    String? menuItemId,
  }) async {
    emit(state.copyWith(isUploading: true, clearError: true));
    try {
      await _storyRepository.createStory(
        vendorId: vendorId,
        vendorName: vendorName,
        vendorLogoUrl: vendorLogoUrl,
        vendorType: vendorType,
        imageFile: imageFile,
        caption: caption,
        menuItemId: menuItemId,
      );
      emit(state.copyWith(isUploading: false));
    } catch (e) {
      emit(state.copyWith(isUploading: false, error: e.toString()));
    }
  }

  /// Deletes a story by document ID and resets errors.
  Future<void> deleteStory(String storyId, String mediaUrl) async {
    emit(state.copyWith(clearError: true));
    try {
      await _storyRepository.deleteStory(storyId, mediaUrl);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  @override
  Future<void> close() {
    _storiesSubscription?.cancel();
    return super.close();
  }
}
