import 'package:flutter_test/flutter_test.dart';
import 'package:z_speed/core/utils/vendor_sorting_helper.dart';
import 'package:z_speed/features/restaurant/model/restaurant.dart';

void main() {
  group('VendorSortingHelper', () {
    test('sorts vendors by priority descending', () {
      final now = DateTime.now();
      final v1 = Restaurant(
        id: 'v1',
        ownerId: 'o1',
        name: 'Vendor Low Priority',
        description: 'desc',
        logoUrl: '',
        coverImageUrl: '',
        deliveryTimeMin: 10,
        deliveryTimeMax: 20,
        deliveryFee: 5.0,
        minimumOrder: 10.0,
        address: 'addr',
        createdAt: now,
        updatedAt: now,
        priority: 5,
      );

      final v2 = Restaurant(
        id: 'v2',
        ownerId: 'o2',
        name: 'Vendor High Priority',
        description: 'desc',
        logoUrl: '',
        coverImageUrl: '',
        deliveryTimeMin: 10,
        deliveryTimeMax: 20,
        deliveryFee: 5.0,
        minimumOrder: 10.0,
        address: 'addr',
        createdAt: now,
        updatedAt: now,
        priority: 100,
      );

      final sorted = VendorSortingHelper.sortVendors([v1, v2]);
      expect(sorted.first.id, equals('v2'));
      expect(sorted.last.id, equals('v1'));
    });

    test('resolves identical priorities deterministically using ratings and IDs', () {
      final now = DateTime.now();
      final v1 = Restaurant(
        id: 'b_vendor',
        ownerId: 'o1',
        name: 'Vendor B',
        description: 'desc',
        logoUrl: '',
        coverImageUrl: '',
        deliveryTimeMin: 10,
        deliveryTimeMax: 20,
        deliveryFee: 5.0,
        minimumOrder: 10.0,
        address: 'addr',
        createdAt: now,
        updatedAt: now,
        priority: 10,
        rating: 4.5,
      );

      final v2 = Restaurant(
        id: 'a_vendor',
        ownerId: 'o2',
        name: 'Vendor A',
        description: 'desc',
        logoUrl: '',
        coverImageUrl: '',
        deliveryTimeMin: 10,
        deliveryTimeMax: 20,
        deliveryFee: 5.0,
        minimumOrder: 10.0,
        address: 'addr',
        createdAt: now,
        updatedAt: now,
        priority: 10,
        rating: 4.5,
      );

      final sorted = VendorSortingHelper.sortVendors([v1, v2]);
      expect(sorted.first.id, equals('a_vendor'));
      expect(sorted.last.id, equals('b_vendor'));
    });

    test('sorts product maps by vendorPriority descending', () {
      final p1 = {
        'id': 'p1',
        'name': 'Item 1',
        'restaurantId': 'r1',
        'vendorPriority': 10,
      };
      final p2 = {
        'id': 'p2',
        'name': 'Item 2',
        'restaurantId': 'r2',
        'vendorPriority': 90,
      };

      final sorted = VendorSortingHelper.sortProductMaps([p1, p2]);
      expect(sorted.first['id'], equals('p2'));
      expect(sorted.last['id'], equals('p1'));
    });

    test('prioritizes open and non-busy vendors first', () {
      final now = DateTime.now();
      final openAvailable = Restaurant(
        id: 'v_open',
        ownerId: 'o1',
        name: 'Open Vendor',
        description: 'desc',
        logoUrl: '',
        coverImageUrl: '',
        deliveryTimeMin: 10,
        deliveryTimeMax: 20,
        deliveryFee: 5.0,
        minimumOrder: 10.0,
        address: 'addr',
        createdAt: now,
        updatedAt: now,
        priority: 10,
        isOpen: true,
        isBusy: false,
      );

      final openBusy = Restaurant(
        id: 'v_busy',
        ownerId: 'o2',
        name: 'Busy Vendor',
        description: 'desc',
        logoUrl: '',
        coverImageUrl: '',
        deliveryTimeMin: 10,
        deliveryTimeMax: 20,
        deliveryFee: 5.0,
        minimumOrder: 10.0,
        address: 'addr',
        createdAt: now,
        updatedAt: now,
        priority: 100, // Higher priority but busy
        isOpen: true,
        isBusy: true,
      );

      final closed = Restaurant(
        id: 'v_closed',
        ownerId: 'o3',
        name: 'Closed Vendor',
        description: 'desc',
        logoUrl: '',
        coverImageUrl: '',
        deliveryTimeMin: 10,
        deliveryTimeMax: 20,
        deliveryFee: 5.0,
        minimumOrder: 10.0,
        address: 'addr',
        createdAt: now,
        updatedAt: now,
        priority: 200, // Highest priority but closed
        isOpen: false,
        isBusy: false,
      );

      final sorted = VendorSortingHelper.sortVendors([closed, openBusy, openAvailable]);
      expect(sorted[0].id, equals('v_open'));
      expect(sorted[1].id, equals('v_busy'));
      expect(sorted[2].id, equals('v_closed'));
    });

    test('prioritizes available products over closed and busy products', () {
      final pClosed = {
        'id': 'p_closed',
        'name': 'Closed Product',
        'restaurantId': 'r1',
        'isOpen': false,
        'isBusy': false,
        'vendorPriority': 200,
      };
      final pBusy = {
        'id': 'p_busy',
        'name': 'Busy Product',
        'restaurantId': 'r2',
        'isOpen': true,
        'isBusy': true,
        'vendorPriority': 100,
      };
      final pAvailable = {
        'id': 'p_avail',
        'name': 'Available Product',
        'restaurantId': 'r3',
        'isOpen': true,
        'isBusy': false,
        'vendorPriority': 10,
      };

      final sorted = VendorSortingHelper.sortProductMaps([pClosed, pBusy, pAvailable]);
      expect(sorted[0]['id'], equals('p_avail'));
      expect(sorted[1]['id'], equals('p_busy'));
      expect(sorted[2]['id'], equals('p_closed'));
    });
  });
}
