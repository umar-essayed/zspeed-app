import 'package:z_speed/features/restaurant/model/restaurant.dart';

/// Helper utility to perform conflict-free, multi-tier deterministic sorting
/// for vendors and recommended product lists.
class VendorSortingHelper {
  /// Sorts a list of [Restaurant] objects in place or returns a sorted copy.
  /// 
  /// Sorting precedence (conflict-free resolution):
  /// 0. Availability (`isOpen && !isBusy` first, then `isOpen` first)
  /// 1. `priority` (descending - higher score first)
  /// 2. `rating` (descending - higher rated first)
  /// 3. `ratingCount` (descending - more ratings first)
  /// 4. `id` (alphabetical ascending - 100% deterministic tie-breaker)
  static List<Restaurant> sortVendors(List<Restaurant> vendors) {
    final copy = List<Restaurant>.from(vendors);
    copy.sort((a, b) {
      // 0. Availability
      final aAvailable = a.isOpen && !a.isBusy;
      final bAvailable = b.isOpen && !b.isBusy;
      if (aAvailable != bAvailable) {
        return aAvailable ? -1 : 1;
      }
      if (a.isOpen != b.isOpen) {
        return a.isOpen ? -1 : 1;
      }

      // 1. Priority descending
      final priorityCompare = b.priority.compareTo(a.priority);
      if (priorityCompare != 0) return priorityCompare;

      // 2. Rating descending
      final ratingCompare = b.rating.compareTo(a.rating);
      if (ratingCompare != 0) return ratingCompare;

      // 3. Rating count descending
      final ratingCountCompare = b.ratingCount.compareTo(a.ratingCount);
      if (ratingCountCompare != 0) return ratingCountCompare;

      // 4. Deterministic ID tie-breaker
      return a.id.compareTo(b.id);
    });
    return copy;
  }

  /// Sorts a list of recommended product maps for feeds (e.g. Home Discover Feed).
  ///
  /// Each map contains product and vendor metadata:
  /// - `isOpen` (bool)
  /// - `isBusy` (bool)
  /// - `vendorPriority` (int)
  /// - `vendorRating` (double)
  /// - `restaurantId` (String)
  /// - `id` or `name` (String)
  static List<Map<String, dynamic>> sortProductMaps(
    List<Map<String, dynamic>> products,
  ) {
    final copy = List<Map<String, dynamic>>.from(products);
    copy.sort((a, b) {
      // 0. Availability
      final aOpen = a['isOpen'] as bool? ?? true;
      final bOpen = b['isOpen'] as bool? ?? true;
      final aBusy = a['isBusy'] as bool? ?? false;
      final bBusy = b['isBusy'] as bool? ?? false;
      final aAvailable = aOpen && !aBusy;
      final bAvailable = bOpen && !bBusy;
      if (aAvailable != bAvailable) {
        return aAvailable ? -1 : 1;
      }
      if (aOpen != bOpen) {
        return aOpen ? -1 : 1;
      }

      final aPriority = (a['vendorPriority'] as num?)?.toInt() ?? 0;
      final bPriority = (b['vendorPriority'] as num?)?.toInt() ?? 0;
      final priorityCompare = bPriority.compareTo(aPriority);
      if (priorityCompare != 0) return priorityCompare;

      final aRating = (a['vendorRating'] as num?)?.toDouble() ?? 0.0;
      final bRating = (b['vendorRating'] as num?)?.toDouble() ?? 0.0;
      final ratingCompare = bRating.compareTo(aRating);
      if (ratingCompare != 0) return ratingCompare;

      final aRestId = a['restaurantId'] as String? ?? '';
      final bRestId = b['restaurantId'] as String? ?? '';
      final restIdCompare = aRestId.compareTo(bRestId);
      if (restIdCompare != 0) return restIdCompare;

      final aId = a['id'] as String? ?? '';
      final bId = b['id'] as String? ?? '';
      return aId.compareTo(bId);
    });
    return copy;
  }
}
