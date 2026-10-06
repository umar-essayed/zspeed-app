import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/core/enums/user_enums.dart';
import 'package:z_speed/features/customer/repository/customer_restaurant_repository.dart';
import 'package:z_speed/features/customer/repository/customer_restaurant_repository_impl.dart';
import 'package:z_speed/features/restaurant/datasource/cuisine_type_datasource.dart';
import 'package:z_speed/features/restaurant/model/cuisine_type.dart';
import 'package:z_speed/features/restaurant/model/restaurant.dart';
import 'package:z_speed/features/customer/cubit/restaurant_browse_state.dart';
import 'package:injectable/injectable.dart' hide Order;

@injectable
class RestaurantBrowseCubit extends Cubit<RestaurantBrowseState> {
  final CustomerRestaurantRepository _repository;
  final CuisineTypeDatasource _cuisineDatasource;
  VendorType _vendorType;
  VendorType get vendorType => _vendorType;

  StreamSubscription<List<Restaurant>>? _subscription;
  StreamSubscription<List<CuisineType>>? _cuisineSubscription;
  Timer? _searchDebounce;

  RestaurantBrowseCubit({
    CustomerRestaurantRepository? repository,
    CuisineTypeDatasource? cuisineDatasource,
    VendorType vendorType = VendorType.restaurant,
    String initialQuery = '',
  })  : _repository = repository ?? CustomerRestaurantRepositoryImpl(),
        _cuisineDatasource = cuisineDatasource ?? CuisineTypeDatasource(),
        _vendorType = vendorType,
        super(RestaurantBrowseState(
          vendorType: vendorType,
          searchQuery: initialQuery,
        )) {
    init();
  }

  void setVendorType(VendorType newVendorType) {
    if (_vendorType == newVendorType) return;
    _vendorType = newVendorType;
    _cuisineSubscription?.cancel();
    emit(state.copyWith(
      vendorType: newVendorType,
      allRestaurants: const [],
      cuisineTypes: const [],
      selectedCuisine: null,
      clearSelectedCuisine: true,
      isLoading: true,
    ));
    init();
  }

  void init() {
    emit(state.copyWith(isLoading: true, clearError: true));

    _subscription?.cancel();
    _subscription = _repository.streamVendorsByType(vendorType).listen(
      (restaurants) {
        // ignore: avoid_print
        print('[DEBUG] RestaurantBrowseCubit(${vendorType.key}): got ${restaurants.length} vendors');

        emit(state.copyWith(
          allRestaurants: restaurants,
          isLoading: false,
          clearError: true,
        ));
      },
      onError: (e) {
        // ignore: avoid_print
        print('[DEBUG] RestaurantBrowseCubit(${vendorType.key}) ERROR: $e');
        emit(state.copyWith(
          error: e.toString(),
          isLoading: false,
        ));
      },
    );

    // Cuisine types are only relevant for restaurant browsing.
    if (vendorType == VendorType.restaurant) {
      _cuisineSubscription?.cancel();
      _cuisineSubscription = _cuisineDatasource.streamActive().listen(
        (types) => emit(state.copyWith(cuisineTypes: types)),
        onError: (_) {},
      );
    }
  }

  void setSearchQuery(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      emit(state.copyWith(searchQuery: query));
    });
  }

  void setCuisineFilter(String? cuisineType) {
    emit(state.copyWith(
      selectedCuisine: cuisineType,
      clearSelectedCuisine: cuisineType == null,
    ));
  }

  void setSortOption(SortOption option) {
    emit(state.copyWith(sortOption: option));
  }

  void setViewStyle(BrowseViewStyle style) {
    if (state.viewStyle == style) return;
    emit(state.copyWith(viewStyle: style));
  }

  void toggleOpenOnly() {
    emit(state.copyWith(showOpenOnly: !state.showOpenOnly));
  }

  void refresh() {
    init();
  }

  void clearError() {
    emit(state.copyWith(clearError: true));
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    _cuisineSubscription?.cancel();
    _searchDebounce?.cancel();
    return super.close();
  }
}
