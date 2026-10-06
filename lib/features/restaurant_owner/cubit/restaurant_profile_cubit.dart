import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:z_speed/l10n/app_localizations.dart';
import 'package:z_speed/features/restaurant/model/restaurant.dart';
import 'package:z_speed/features/restaurant/repository/restaurant_menu_repository.dart';
import 'package:z_speed/features/restaurant/datasource/cuisine_type_datasource.dart';
import 'package:z_speed/core/injection.dart';
import 'package:z_speed/features/restaurant_owner/cubit/restaurant_profile_state.dart';
import 'package:injectable/injectable.dart' hide Order;

@injectable
class RestaurantProfileCubit extends Cubit<RestaurantProfileState> {
  final RestaurantMenuRepository _repository;
  final CuisineTypeDatasource _cuisineDatasource;
  final String ownerId;
  StreamSubscription? _restaurantSubscription;

  RestaurantProfileCubit({
    required this._repository,
    CuisineTypeDatasource? cuisineDatasource,
    required this.ownerId,
  }) : _cuisineDatasource = cuisineDatasource ?? getIt<CuisineTypeDatasource>(),
       super(const RestaurantProfileState()) {
    init();
  }

  Future<void> init() async {
    if (isClosed) return;
    emit(state.copyWith(isLoading: true, clearError: true));
    _loadCuisines();

    try {
      final restaurant = await _repository.getOwnerRestaurant(ownerId);
      if (isClosed) return;
      emit(state.copyWith(isLoading: false, restaurant: restaurant));

      if (restaurant != null) {
        _restaurantSubscription = _repository
            .streamOwnerRestaurant(restaurant.id)
            .listen(
              (restaurant) {
                if (isClosed) return;
                emit(state.copyWith(restaurant: restaurant));
              },
              onError: (e) {
                if (isClosed) return;
                emit(state.copyWith(error: 'Failed to stream restaurant: $e'));
              },
            );
      }
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          isLoading: false,
          error: 'Failed to load restaurant: $e',
        ),
      );
    }
  }

  Future<void> _loadCuisines() async {
    try {
      if (isClosed) return;
      emit(state.copyWith(isLoadingCuisines: true));
      final cuisines = await _cuisineDatasource.getAll();
      final activeCuisines = cuisines.where((c) => c.isActive).toList();
      if (isClosed) return;
      emit(
        state.copyWith(
          availableCuisines: activeCuisines,
          isLoadingCuisines: false,
        ),
      );
    } catch (e) {
      debugPrint('Failed to load cuisines: $e');
      if (isClosed) return;
      emit(state.copyWith(isLoadingCuisines: false));
    }
  }

  Future<String?> createRestaurant({
    required String name,
    String? nameAr,
    required String description,
    required String address,
    required String phone,
    List<String> cuisineTypes = const [],
    int deliveryTimeMin = 30,
    int deliveryTimeMax = 60,
    double deliveryFee = 0.0,
    double minimumOrder = 0.0,
  }) async {
    try {
      emit(state.copyWith(isSaving: true));

      final restaurant = Restaurant(
        id: '',
        ownerId: ownerId,
        name: name,
        nameAr: nameAr,
        description: description,
        logoUrl: '',
        coverImageUrl: '',
        address: address,
        phone: phone,
        cuisineTypes: cuisineTypes,
        deliveryTimeMin: deliveryTimeMin,
        deliveryTimeMax: deliveryTimeMax,
        deliveryFee: deliveryFee,
        minimumOrder: minimumOrder,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final id = await _repository.createRestaurant(restaurant);
      await init();
      return id;
    } catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          error: 'Failed to create restaurant: $e',
        ),
      );
      return null;
    }
  }

  Future<void> updateField(String field, dynamic value) async {
    if (state.restaurant == null) return;
    try {
      emit(state.copyWith(isSaving: true));
      await _repository.updateRestaurantFields(state.restaurant!.id, {
        field: value,
      });
      emit(state.copyWith(isSaving: false));
    } catch (e) {
      emit(
        state.copyWith(isSaving: false, error: 'Failed to update $field: $e'),
      );
    }
  }

  Future<void> updateFields(Map<String, dynamic> fields) async {
    if (state.restaurant == null) return;
    try {
      emit(state.copyWith(isSaving: true));
      await _repository.updateRestaurantFields(state.restaurant!.id, fields);
      emit(state.copyWith(isSaving: false));
    } catch (e) {
      emit(
        state.copyWith(isSaving: false, error: 'Failed to update fields: $e'),
      );
    }
  }

  Future<void> updateWorkingHours(Map<String, dynamic> hours) async {
    await updateField('workingHours', hours);
  }

  Future<void> updateLocation(BuildContext context) async {
    if (state.restaurant == null) return;
    try {
      emit(state.copyWith(isSaving: true));

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      final position = await Geolocator.getCurrentPosition();

      await _repository.updateRestaurantFields(state.restaurant!.id, {
        'latitude': position.latitude,
        'longitude': position.longitude,
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.locationUpdatedSuccessfully,
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
      emit(state.copyWith(isSaving: false));
    } catch (e) {
      final errorMsg = 'Failed to get location: $e';
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      }
      emit(state.copyWith(isSaving: false, error: errorMsg));
    }
  }

  Future<void> updateLocationFromMap(
    double lat,
    double lng, {
    String? address,
  }) async {
    if (state.restaurant == null) return;
    try {
      emit(state.copyWith(isSaving: true));

      final fields = <String, dynamic>{'latitude': lat, 'longitude': lng};
      if (address != null && address.isNotEmpty) {
        fields['address'] = address;
      }

      await _repository.updateRestaurantFields(state.restaurant!.id, fields);
      emit(state.copyWith(isSaving: false));
    } catch (e) {
      emit(
        state.copyWith(isSaving: false, error: 'Failed to update location: $e'),
      );
    }
  }

  Future<void> toggleOpen() async {
    if (state.restaurant == null) return;
    try {
      await _repository.toggleRestaurantOpen(
        state.restaurant!.id,
        !state.restaurant!.isOpen,
      );
    } catch (e) {
      emit(state.copyWith(error: 'Failed to toggle open status: $e'));
    }
  }

  Future<String?> uploadLogo(XFile file) async {
    if (state.restaurant == null) return null;
    try {
      emit(state.copyWith(isUploadingLogo: true, isSaving: true));
      final url = await _repository.uploadImage(
        file,
        'restaurants/$ownerId/logo',
      );
      await _repository.updateRestaurantFields(state.restaurant!.id, {
        'logoUrl': url,
      });
      emit(state.copyWith(isUploadingLogo: false, isSaving: false));
      return url;
    } catch (e) {
      emit(
        state.copyWith(
          isUploadingLogo: false,
          isSaving: false,
          error: 'Failed to upload logo: $e',
        ),
      );
      return null;
    }
  }

  Future<String?> uploadCoverImage(XFile file) async {
    if (state.restaurant == null) return null;
    try {
      emit(state.copyWith(isUploadingCover: true, isSaving: true));
      final url = await _repository.uploadImage(
        file,
        'restaurants/$ownerId/cover',
      );
      await _repository.updateRestaurantFields(state.restaurant!.id, {
        'coverImageUrl': url,
      });
      emit(state.copyWith(isUploadingCover: false, isSaving: false));
      return url;
    } catch (e) {
      emit(
        state.copyWith(
          isUploadingCover: false,
          isSaving: false,
          error: 'Failed to upload cover image: $e',
        ),
      );
      return null;
    }
  }

  void clearError() {
    emit(state.copyWith(clearError: true));
  }

  @override
  void emit(RestaurantProfileState state) {
    if (!isClosed) {
      super.emit(state);
    }
  }

  @override
  Future<void> close() {
    _restaurantSubscription?.cancel();
    return super.close();
  }
}
