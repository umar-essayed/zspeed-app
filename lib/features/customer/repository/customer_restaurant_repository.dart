import 'package:z_speed/core/enums/user_enums.dart';
import 'package:z_speed/features/restaurant/model/restaurant.dart';
import 'package:z_speed/features/restaurant/model/menu_section.dart';
import 'package:z_speed/features/restaurant/model/menu_item.dart';
import 'package:z_speed/features/restaurant/model/addon_group.dart';

/// Customer-facing repository for browsing restaurants and menus.
///
/// Provides read-only access to restaurant and menu data with
/// customer-specific filtering and search capabilities.
abstract class CustomerRestaurantRepository {
  // ══════════════════════════════════════════════════════════════
  // RESTAURANT BROWSE
  // ══════════════════════════════════════════════════════════════

  /// Stream all active restaurants, ordered by rating.
  Stream<List<Restaurant>> streamRestaurants();

  /// Stream active vendors filtered by vendor type.
  Stream<List<Restaurant>> streamVendorsByType(VendorType type);

  /// Stream restaurants filtered by cuisine type.
  Stream<List<Restaurant>> streamRestaurantsByCuisine(String cuisineType);

  /// Search restaurants by name (case-insensitive).
  /// Returns a future since this may use client-side filtering.
  Future<List<Restaurant>> searchRestaurants(String query);

  /// Get a single restaurant by ID.
  Future<Restaurant?> getRestaurantById(String id);

  /// Stream a single restaurant (for real-time updates).
  Stream<Restaurant?> streamRestaurant(String id);

  /// Get popular restaurants (top N by rating).
  Future<List<Restaurant>> getPopularRestaurants({int limit = 10});

  // ══════════════════════════════════════════════════════════════
  // MENU BROWSE
  // ══════════════════════════════════════════════════════════════

  /// Stream all menu sections for a restaurant, ordered by sortOrder.
  Stream<List<MenuSection>> streamSections(String restaurantId);

  /// Stream items for a specific section, ordered by sortOrder.
  Stream<List<MenuItem>> streamItems(String restaurantId, String sectionId);

  /// Stream ALL items across all sections (collection group query).
  Stream<List<MenuItem>> streamAllItems(String restaurantId);

  /// Get addon groups for a menu item (one-shot).
  Future<List<AddonGroup>> getAddonGroups(
    String restaurantId,
    String sectionId,
    String itemId,
  );

  /// Stream addon groups for a menu item (real-time).
  Stream<List<AddonGroup>> streamAddonGroups(
    String restaurantId,
    String sectionId,
    String itemId,
  );
}

