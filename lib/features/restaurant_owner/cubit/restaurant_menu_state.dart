import 'package:equatable/equatable.dart';
import 'package:z_speed/core/utils/search_helper.dart';
import 'package:z_speed/features/restaurant/model/menu_section.dart';
import 'package:z_speed/features/restaurant/model/menu_item.dart';
import 'package:z_speed/features/restaurant/model/cuisine_type.dart';
import 'package:z_speed/features/restaurant/model/vendor_section.dart';

enum ItemStatusFilter { all, available, unavailable, onSale }

class RestaurantMenuState extends Equatable {
  final bool isLoading;
  final String? error;
  final bool isSaving;
  final List<CuisineType> cuisineTypes;
  final List<VendorSection> vendorSections;
  final List<MenuSection> sections;
  final List<MenuItem> allItems;
  final String? selectedCuisineTypeId;
  final ItemStatusFilter statusFilter;
  final String searchQuery;
  final int currentPage;
  final int pageSize;

  const RestaurantMenuState({
    this.isLoading = false,
    this.error,
    this.isSaving = false,
    this.cuisineTypes = const [],
    this.vendorSections = const [],
    this.sections = const [],
    this.allItems = const [],
    this.selectedCuisineTypeId,
    this.statusFilter = ItemStatusFilter.all,
    this.searchQuery = '',
    this.currentPage = 0,
    this.pageSize = 50,
  });

  RestaurantMenuState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? isSaving,
    List<CuisineType>? cuisineTypes,
    List<VendorSection>? vendorSections,
    List<MenuSection>? sections,
    List<MenuItem>? allItems,
    String? selectedCuisineTypeId,
    bool clearSelectedCuisineType = false,
    ItemStatusFilter? statusFilter,
    String? searchQuery,
    int? currentPage,
    int? pageSize,
  }) {
    return RestaurantMenuState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isSaving: isSaving ?? this.isSaving,
      cuisineTypes: cuisineTypes ?? this.cuisineTypes,
      vendorSections: vendorSections ?? this.vendorSections,
      sections: sections ?? this.sections,
      allItems: allItems ?? this.allItems,
      selectedCuisineTypeId: clearSelectedCuisineType
          ? null
          : (selectedCuisineTypeId ?? this.selectedCuisineTypeId),
      statusFilter: statusFilter ?? this.statusFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  // Keep old getter for backward compat
  String? get selectedSectionId => selectedCuisineTypeId;

  List<MenuItem> get filteredItems {
    var items = allItems;
    switch (statusFilter) {
      case ItemStatusFilter.all:
        break;
      case ItemStatusFilter.available:
        items = items.where((i) => i.isAvailable).toList();
        break;
      case ItemStatusFilter.unavailable:
        items = items.where((i) => !i.isAvailable).toList();
        break;
      case ItemStatusFilter.onSale:
        items = items.where((i) => i.discountedPrice != null).toList();
        break;
    }
    if (selectedCuisineTypeId != null) {
      items =
          items.where((i) => i.sectionId == selectedCuisineTypeId).toList();
    }
    if (searchQuery.trim().isNotEmpty) {
      final q = SearchHelper.normalize(searchQuery);
      items = items
          .where((i) =>
              SearchHelper.matches(i.name, q) ||
              SearchHelper.matches(i.nameAr, q) ||
              SearchHelper.matches(i.description, q) ||
              SearchHelper.matches(i.descriptionAr, q) ||
              i.tags.any((t) => SearchHelper.matches(t, q)))
          .toList();
    }
    return items;
  }

  List<MenuItem> get paginatedItems {
    final all = filteredItems;
    final start = currentPage * pageSize;
    if (start >= all.length) return [];
    final end = start + pageSize < all.length ? start + pageSize : all.length;
    return all.sublist(start, end);
  }

  int get totalPages {
    final count = filteredItems.length;
    if (count == 0) return 1;
    return (count / pageSize).ceil();
  }

  int get totalItems => allItems.length;
  int get availableItems => allItems.where((i) => i.isAvailable).length;
  int get unavailableItems => allItems.where((i) => !i.isAvailable).length;
  int get onSaleItems =>
      allItems.where((i) => i.discountedPrice != null).length;

  String cuisineTypeName(String cuisineTypeId) {
    final ct = cuisineTypes.cast<CuisineType?>().firstWhere(
          (c) => c!.id == cuisineTypeId,
          orElse: () => null,
        );
    if (ct != null) return ct.name;
    return sections
            .cast<MenuSection?>()
            .firstWhere((s) => s!.id == cuisineTypeId, orElse: () => null)
            ?.name ??
        'Unknown';
  }

  String sectionName(String sectionId) => cuisineTypeName(sectionId);

  List<CuisineType> get usedCuisineTypes {
    final usedIds = allItems.map((i) => i.sectionId).toSet();
    return cuisineTypes.where((ct) => usedIds.contains(ct.id)).toList();
  }

  List<VendorSection> get usedVendorSections {
    final usedIds = allItems.map((i) => i.sectionId).toSet();
    return vendorSections.where((vs) => usedIds.contains(vs.id)).toList();
  }

  @override
  List<Object?> get props => [
        isLoading,
        error,
        isSaving,
        cuisineTypes,
        vendorSections,
        sections,
        allItems,
        selectedCuisineTypeId,
        statusFilter,
        searchQuery,
        currentPage,
        pageSize,
      ];
}
