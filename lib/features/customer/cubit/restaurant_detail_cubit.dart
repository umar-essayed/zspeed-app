import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/features/customer/repository/customer_restaurant_repository.dart';
import 'package:z_speed/features/customer/repository/customer_restaurant_repository_impl.dart';
import 'package:z_speed/features/restaurant/model/restaurant.dart';
import 'package:z_speed/features/restaurant/model/menu_section.dart';
import 'package:z_speed/features/restaurant/model/menu_item.dart';
import 'package:z_speed/features/customer/cubit/restaurant_browse_state.dart';
import 'package:z_speed/features/customer/cubit/restaurant_detail_state.dart';
import 'package:injectable/injectable.dart' hide Order;

@injectable
class RestaurantDetailCubit extends Cubit<RestaurantDetailState> {
  final CustomerRestaurantRepository _repository;
  final String restaurantId;

  StreamSubscription<Restaurant?>? _restaurantSub;
  StreamSubscription<List<MenuSection>>? _sectionsSub;
  final Map<String, StreamSubscription<List<MenuItem>>> _itemSubs = {};

  RestaurantDetailCubit({
    required this.restaurantId,
    CustomerRestaurantRepository? repository,
  })  : _repository = repository ?? CustomerRestaurantRepositoryImpl(),
        super(const RestaurantDetailState()) {
    init();
  }

  void init() {
    emit(state.copyWith(isLoading: true, clearError: true));

    // Subscribe to restaurant metadata
    _restaurantSub?.cancel();
    _restaurantSub = _repository.streamRestaurant(restaurantId).listen(
      (restaurant) {
        emit(state.copyWith(
          restaurant: restaurant,
          error: restaurant == null ? 'Restaurant not found' : null,
          isLoading: false,
        ));
      },
      onError: (e) {
        emit(state.copyWith(error: e.toString(), isLoading: false));
      },
    );

    // Subscribe to menu sections
    _sectionsSub?.cancel();
    _sectionsSub = _repository.streamSections(restaurantId).listen(
      (sections) {
        final String? newSelectedSectionId = state.selectedSectionId;

        emit(state.copyWith(
          sections: sections,
          selectedSectionId: newSelectedSectionId,
          isLoading: false,
          clearError: true,
        ));

        _onSectionsChanged(sections);
      },
      onError: (e) {
        emit(state.copyWith(error: e.toString(), isLoading: false));
      },
    );
  }

  void _onSectionsChanged(List<MenuSection> sections) {
    final sectionIds = sections.map((s) => s.id).toSet();
    final itemsBySection =
        Map<String, List<MenuItem>>.from(state.itemsBySection);

    // Unsubscribe from removed sections
    final toRemove = <String>[];
    for (final sectionId in _itemSubs.keys) {
      if (!sectionIds.contains(sectionId)) {
        _itemSubs[sectionId]?.cancel();
        itemsBySection.remove(sectionId);
        toRemove.add(sectionId);
      }
    }
    for (final id in toRemove) {
      _itemSubs.remove(id);
    }

    emit(state.copyWith(itemsBySection: itemsBySection));

    // Subscribe to new sections
    for (final section in sections) {
      if (!_itemSubs.containsKey(section.id)) {
        _itemSubs[section.id] =
            _repository.streamItems(restaurantId, section.id).listen(
          (items) {
            final newMap =
                Map<String, List<MenuItem>>.from(state.itemsBySection);
            newMap[section.id] = items;
            emit(state.copyWith(itemsBySection: newMap));
          },
          onError: (e) {
            debugPrint('Error loading items for section ${section.id}: $e');
          },
        );
      }
    }
  }

  void selectSection(String? sectionId) {
    if (sectionId == null) {
      emit(state.copyWith(clearSelectedSection: true));
    } else {
      emit(state.copyWith(selectedSectionId: sectionId));
    }
  }

  void setSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  void setViewStyle(BrowseViewStyle style) {
    if (state.viewStyle == style) return;
    emit(state.copyWith(viewStyle: style));
  }

  void clearError() {
    emit(state.copyWith(clearError: true));
  }

  void refresh() {
    init();
  }


  @override
  Future<void> close() {
    _restaurantSub?.cancel();
    _sectionsSub?.cancel();
    for (final sub in _itemSubs.values) {
      sub.cancel();
    }
    _itemSubs.clear();
    return super.close();
  }
}
