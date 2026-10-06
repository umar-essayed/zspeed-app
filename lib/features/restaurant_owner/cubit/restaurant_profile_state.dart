import 'package:equatable/equatable.dart';
import 'package:z_speed/features/restaurant/model/restaurant.dart';
import 'package:z_speed/features/restaurant/model/cuisine_type.dart';

class RestaurantProfileState extends Equatable {
  final bool isLoading;
  final bool isSaving;
  final bool isUploadingLogo;
  final bool isUploadingCover;
  final String? error;
  final Restaurant? restaurant;
  final List<CuisineType> availableCuisines;
  final bool isLoadingCuisines;

  const RestaurantProfileState({
    this.isLoading = false,
    this.isSaving = false,
    this.isUploadingLogo = false,
    this.isUploadingCover = false,
    this.error,
    this.restaurant,
    this.availableCuisines = const [],
    this.isLoadingCuisines = false,
  });

  bool get hasRestaurant => restaurant != null;
  String? get restaurantId => restaurant?.id;

  RestaurantProfileState copyWith({
    bool? isLoading,
    bool? isSaving,
    bool? isUploadingLogo,
    bool? isUploadingCover,
    String? error,
    bool clearError = false,
    Restaurant? restaurant,
    List<CuisineType>? availableCuisines,
    bool? isLoadingCuisines,
  }) {
    return RestaurantProfileState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isUploadingLogo: isUploadingLogo ?? this.isUploadingLogo,
      isUploadingCover: isUploadingCover ?? this.isUploadingCover,
      error: clearError ? null : (error ?? this.error),
      restaurant: restaurant ?? this.restaurant,
      availableCuisines: availableCuisines ?? this.availableCuisines,
      isLoadingCuisines: isLoadingCuisines ?? this.isLoadingCuisines,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isSaving,
        isUploadingLogo,
        isUploadingCover,
        error,
        restaurant,
        availableCuisines,
        isLoadingCuisines,
      ];
}
