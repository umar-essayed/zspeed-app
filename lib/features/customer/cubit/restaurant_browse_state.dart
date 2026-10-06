import 'package:equatable/equatable.dart';
import 'package:z_speed/core/enums/user_enums.dart';
import 'package:z_speed/core/utils/search_helper.dart';
import 'package:z_speed/features/restaurant/model/cuisine_type.dart';
import 'package:z_speed/features/restaurant/model/restaurant.dart';

enum SortOption {
  rating,
  deliveryTime,
  deliveryFee,
  name,
}

enum BrowseViewStyle {
  cards,
  list,
}

class RestaurantBrowseState extends Equatable {
  final bool isLoading;
  final String? error;
  final List<Restaurant> allRestaurants;
  final List<CuisineType> cuisineTypes;
  final String searchQuery;
  final String? selectedCuisine;
  final SortOption sortOption;
  final bool showOpenOnly;
  final VendorType vendorType;
  final BrowseViewStyle viewStyle;

  const RestaurantBrowseState({
    this.isLoading = true,
    this.error,
    this.allRestaurants = const [],
    this.cuisineTypes = const [],
    this.searchQuery = '',
    this.selectedCuisine,
    this.sortOption = SortOption.rating,
    this.showOpenOnly = false,
    this.vendorType = VendorType.restaurant,
    this.viewStyle = BrowseViewStyle.cards,
  });

  RestaurantBrowseState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    List<Restaurant>? allRestaurants,
    List<CuisineType>? cuisineTypes,
    String? searchQuery,
    String? selectedCuisine,
    bool clearSelectedCuisine = false,
    SortOption? sortOption,
    bool? showOpenOnly,
    VendorType? vendorType,
    BrowseViewStyle? viewStyle,
  }) {
    return RestaurantBrowseState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      allRestaurants: allRestaurants ?? this.allRestaurants,
      cuisineTypes: cuisineTypes ?? this.cuisineTypes,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCuisine: clearSelectedCuisine ? null : (selectedCuisine ?? this.selectedCuisine),
      sortOption: sortOption ?? this.sortOption,
      showOpenOnly: showOpenOnly ?? this.showOpenOnly,
      vendorType: vendorType ?? this.vendorType,
      viewStyle: viewStyle ?? this.viewStyle,
    );
  }

  /// Whether to show cuisine filters (only applicable for restaurants).
  bool get showCuisineFilter => vendorType == VendorType.restaurant;

  List<String> get availableCuisines {
    final cuisines = <String>{};
    for (final r in allRestaurants) {
      cuisines.addAll(r.cuisineTypes);
    }
    final sorted = cuisines.toList()..sort();
    return sorted;
  }

  List<Restaurant> get restaurants {
    // ignore: avoid_print
    print('[DEBUG] restaurants getter: allRestaurants=${allRestaurants.length} showOpenOnly=$showOpenOnly searchQuery="$searchQuery" selectedCuisine=$selectedCuisine');
    var filtered = allRestaurants;

    // Apply cuisine filter
    if (selectedCuisine != null) {
      filtered = filtered.where((r) {
        return r.cuisineTypes
            .any((c) => c.toLowerCase() == selectedCuisine!.toLowerCase());
      }).toList();
    }

    // Apply open/closed filter
    if (showOpenOnly) {
      filtered = filtered.where((r) => r.isOpen).toList();
    }

    // Apply search filter
    if (searchQuery.trim().isNotEmpty) {
      final q = SearchHelper.normalize(searchQuery);
      filtered = filtered.where((r) {
        return SearchHelper.matches(r.name, q) ||
            SearchHelper.matches(r.nameAr, q) ||
            SearchHelper.matches(r.description, q) ||
            SearchHelper.matches(r.descriptionAr, q) ||
            r.cuisineTypes.any((c) => SearchHelper.matches(c, q));
      }).toList();
    }

    // Apply sorting
    filtered = List.from(filtered); // make mutable copy
    switch (sortOption) {
      case SortOption.rating:
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case SortOption.deliveryTime:
        filtered.sort((a, b) => a.deliveryTimeMin.compareTo(b.deliveryTimeMin));
        break;
      case SortOption.deliveryFee:
        filtered.sort((a, b) => a.deliveryFee.compareTo(b.deliveryFee));
        break;
      case SortOption.name:
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
    }

    // ignore: avoid_print
    print('[DEBUG] restaurants getter result: ${filtered.length} items');
    return filtered;
  }

  @override
  List<Object?> get props => [
        isLoading,
        error,
        allRestaurants,
        cuisineTypes,
        searchQuery,
        selectedCuisine,
        sortOption,
        showOpenOnly,
        vendorType,
        viewStyle,
      ];
}
