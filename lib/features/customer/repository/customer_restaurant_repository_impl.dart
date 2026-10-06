import 'package:z_speed/core/enums/user_enums.dart';
import 'package:z_speed/core/utils/search_helper.dart';
import 'package:z_speed/features/customer/repository/customer_restaurant_repository.dart';
import 'package:z_speed/features/restaurant/datasource/restaurant_firebase_datasource.dart';
import 'package:z_speed/features/restaurant/datasource/menu_firebase_datasource.dart';
import 'package:z_speed/features/restaurant/model/restaurant.dart';
import 'package:z_speed/features/restaurant/model/menu_section.dart';
import 'package:z_speed/features/restaurant/model/menu_item.dart';
import 'package:z_speed/features/restaurant/model/addon_group.dart';
import 'package:injectable/injectable.dart' hide Order;

/// Implementation of [CustomerRestaurantRepository].
///
/// Delegates to Firebase datasources for actual data access.
@LazySingleton(as: CustomerRestaurantRepository)
class CustomerRestaurantRepositoryImpl implements CustomerRestaurantRepository {
  final RestaurantFirebaseDatasource _restaurantDs;
  final MenuFirebaseDatasource _menuDs;

  CustomerRestaurantRepositoryImpl({
    RestaurantFirebaseDatasource? restaurantDs,
    MenuFirebaseDatasource? menuDs,
  })  : _restaurantDs = restaurantDs ?? RestaurantFirebaseDatasource(),
        _menuDs = menuDs ?? MenuFirebaseDatasource();

  // ══════════════════════════════════════════════════════════════
  // RESTAURANT BROWSE
  // ══════════════════════════════════════════════════════════════

  @override
  Stream<List<Restaurant>> streamRestaurants() {
    return _restaurantDs.streamActive();
  }

  @override
  Stream<List<Restaurant>> streamVendorsByType(VendorType type) {
    // Legacy restaurant docs may not have the vendorType field set; use the
    // unfiltered query so they are not excluded from results.
    if (type == VendorType.restaurant) return _restaurantDs.streamActive();
    return _restaurantDs.streamActiveByVendorType(type);
  }

  @override
  Stream<List<Restaurant>> streamRestaurantsByCuisine(String cuisineType) {
    // Filter the active stream by cuisine type
    return _restaurantDs.streamActive().map((restaurants) {
      return restaurants.where((r) {
        return r.cuisineTypes
            .any((c) => c.toLowerCase() == cuisineType.toLowerCase());
      }).toList();
    });
  }

  @override
  Future<List<Restaurant>> searchRestaurants(String query) async {
    // Get all active restaurants and filter client-side
    // NOTE: For production, this should use Firestore composite indexes
    // with `where` + `orderBy`. For MVP, client-side filtering is acceptable.
    final stream = _restaurantDs.streamActive();
    final restaurants = await stream.first;

    if (query.trim().isEmpty) return restaurants;

    final q = SearchHelper.normalize(query);
    return restaurants.where((r) {
      return SearchHelper.matches(r.name, q) ||
          SearchHelper.matches(r.nameAr, q) ||
          SearchHelper.matches(r.description, q) ||
          SearchHelper.matches(r.descriptionAr, q) ||
          r.cuisineTypes.any((c) => SearchHelper.matches(c, q));
    }).toList();
  }

  @override
  Future<Restaurant?> getRestaurantById(String id) {
    return _restaurantDs.getById(id);
  }

  @override
  Stream<Restaurant?> streamRestaurant(String id) {
    return _restaurantDs.streamById(id);
  }

  @override
  Future<List<Restaurant>> getPopularRestaurants({int limit = 10}) async {
    // streamActive() already orders by rating descending
    final stream = _restaurantDs.streamActive();
    final restaurants = await stream.first;
    return restaurants.take(limit).toList();
  }


  // ══════════════════════════════════════════════════════════════
  // MENU BROWSE
  // ══════════════════════════════════════════════════════════════

  @override
  Stream<List<MenuSection>> streamSections(String restaurantId) {
    return _menuDs.streamSections(restaurantId);
  }

  @override
  Stream<List<MenuItem>> streamItems(String restaurantId, String sectionId) {
    return _menuDs.streamItems(restaurantId, sectionId);
  }

  @override
  Stream<List<MenuItem>> streamAllItems(String restaurantId) {
    return _menuDs.streamAllItems(restaurantId);
  }

  @override
  Future<List<AddonGroup>> getAddonGroups(
    String restaurantId,
    String sectionId,
    String itemId,
  ) {
    return _menuDs.getAddonGroups(restaurantId, sectionId, itemId);
  }

  @override
  Stream<List<AddonGroup>> streamAddonGroups(
    String restaurantId,
    String sectionId,
    String itemId,
  ) {
    return _menuDs.streamAddonGroupsCacheFirst(restaurantId, sectionId, itemId);
  }

}
