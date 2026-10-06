import 'package:image_picker/image_picker.dart';
import 'package:z_speed/features/restaurant/model/restaurant.dart';
import 'package:z_speed/features/restaurant/model/menu_section.dart';
import 'package:z_speed/features/restaurant/model/menu_item.dart';
import 'package:z_speed/features/restaurant/model/addon_group.dart';

/// Abstract repository for vendor menu management.
///
/// Combines restaurant, section, item, and addon CRUD with image upload.
abstract class RestaurantMenuRepository {
  // ── Restaurant ────────────────────────────────────────────────

  Future<Restaurant?> getOwnerRestaurant(String ownerId);
  Stream<Restaurant?> streamOwnerRestaurant(String restaurantId);
  Future<String> createRestaurant(Restaurant restaurant);
  Future<void> updateRestaurant(Restaurant restaurant);
  Future<void> updateRestaurantFields(
      String restaurantId, Map<String, dynamic> fields);
  Future<void> toggleRestaurantOpen(String restaurantId, bool isOpen);

  // ── Sections ──────────────────────────────────────────────────

  Stream<List<MenuSection>> streamSections(String restaurantId);
  Future<String> createSection(String restaurantId, MenuSection section);
  Future<void> updateSection(String restaurantId, MenuSection section);
  Future<void> deleteSection(String restaurantId, String sectionId);
  Future<void> reorderSections(String restaurantId, List<String> sectionIds);

  // ── Items ─────────────────────────────────────────────────────

  Stream<List<MenuItem>> streamItems(String restaurantId, String sectionId);
  Stream<List<MenuItem>> streamAllItems(String restaurantId);
  Future<String> createItem(
      String restaurantId, String sectionId, MenuItem item);
  Future<void> updateItem(String restaurantId, String sectionId, MenuItem item);
  Future<void> toggleItemAvailability(
    String restaurantId,
    String sectionId,
    String itemId,
    bool isAvailable,
  );
  Future<void> deleteItem(String restaurantId, String sectionId, String itemId);
  Future<void> reorderItems(
      String restaurantId, String sectionId, List<String> itemIds);

  /// Bulk-upserts items across multiple sections using Firestore batch writes.
  /// Items must have stable deterministic IDs set before calling.
  Future<void> batchUpsertItems(
    String restaurantId,
    Map<String, List<MenuItem>> itemsBySectionId, {
    void Function(int done, int total)? onProgress,
  });

  // ── Addon Groups ──────────────────────────────────────────────

  Stream<List<AddonGroup>> streamAddonGroups(
    String restaurantId,
    String sectionId,
    String itemId,
  );
  Future<String> createAddonGroup(
    String restaurantId,
    String sectionId,
    String itemId,
    AddonGroup group,
  );
  Future<void> updateAddonGroup(
    String restaurantId,
    String sectionId,
    String itemId,
    AddonGroup group,
  );
  Future<void> deleteAddonGroup(
    String restaurantId,
    String sectionId,
    String itemId,
    String groupId,
  );

  // ── Image Upload ──────────────────────────────────────────────

  Future<String> uploadImage(XFile file, String folder);
}
