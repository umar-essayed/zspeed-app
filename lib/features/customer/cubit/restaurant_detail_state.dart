import 'package:equatable/equatable.dart';
import 'package:z_speed/core/utils/search_helper.dart';
import 'package:z_speed/features/customer/cubit/restaurant_browse_state.dart';
import 'package:z_speed/features/restaurant/model/restaurant.dart';
import 'package:z_speed/features/restaurant/model/menu_section.dart';
import 'package:z_speed/features/restaurant/model/menu_item.dart';

class RestaurantDetailState extends Equatable {
  final bool isLoading;
  final String? error;
  final Restaurant? restaurant;
  final List<MenuSection> sections;
  final Map<String, List<MenuItem>> itemsBySection;
  final String? selectedSectionId;
  final String searchQuery;
  final BrowseViewStyle viewStyle;

  const RestaurantDetailState({
    this.isLoading = true,
    this.error,
    this.restaurant,
    this.sections = const [],
    this.itemsBySection = const {},
    this.selectedSectionId,
    this.searchQuery = '',
    this.viewStyle = BrowseViewStyle.list,
  });

  RestaurantDetailState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    Restaurant? restaurant,
    List<MenuSection>? sections,
    Map<String, List<MenuItem>>? itemsBySection,
    String? selectedSectionId,
    bool clearSelectedSection = false,
    String? searchQuery,
    BrowseViewStyle? viewStyle,
  }) {
    return RestaurantDetailState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      restaurant: restaurant ?? this.restaurant,
      sections: sections ?? this.sections,
      itemsBySection: itemsBySection ?? this.itemsBySection,
      selectedSectionId: clearSelectedSection
          ? null
          : (selectedSectionId ?? this.selectedSectionId),
      searchQuery: searchQuery ?? this.searchQuery,
      viewStyle: viewStyle ?? this.viewStyle,
    );
  }

  List<MenuItem> getFilteredItems(String sectionId) {
    final items = itemsBySection[sectionId] ?? [];
    if (searchQuery.trim().isEmpty) return items;

    final q = SearchHelper.normalize(searchQuery);
    return items.where((item) {
      return SearchHelper.matches(item.name, q) ||
          SearchHelper.matches(item.nameAr, q) ||
          SearchHelper.matches(item.description, q) ||
          SearchHelper.matches(item.descriptionAr, q) ||
          item.tags.any((tag) => SearchHelper.matches(tag, q));
    }).toList();
  }

  @override
  List<Object?> get props => [
        isLoading,
        error,
        restaurant,
        sections,
        itemsBySection,
        selectedSectionId,
        searchQuery,
        viewStyle,
      ];
}
