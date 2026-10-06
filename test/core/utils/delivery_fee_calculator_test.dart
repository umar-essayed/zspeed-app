import 'package:flutter_test/flutter_test.dart';
import 'package:z_speed/core/enums/driver_enums.dart';
import 'package:z_speed/core/services/delivery_fee_calculator.dart';
import 'package:z_speed/features/restaurant/model/restaurant.dart';

void main() {
  group('DeliveryFeeCalculator - Fixed Total Custom Area Fee Rules', () {
    final baseRestaurant = Restaurant(
      id: 'rest_101',
      ownerId: 'owner_101',
      name: 'Test Gourmet',
      description: 'Gourmet test food',
      logoUrl: '',
      coverImageUrl: '',
      deliveryTimeMin: 20,
      deliveryTimeMax: 40,
      deliveryFee: 40.0, // Default vendor fee: 40 EGP
      minimumOrder: 100.0,
      address: 'Cairo Downtown',
      latitude: 30.0444,
      longitude: 31.2357,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      deliveryFeeMode: DeliveryFeeMode.fixed,
      deliveryFeeAreas: [
        {
          'id': 'area_cairo_east',
          'name': 'Cairo East Zone',
          'centerLat': 30.0444,
          'centerLng': 31.2357,
          'radiusKm': 15.0,
          'totalFee': 60.0, // Fixed total delivery cost for this custom area
        },
      ],
    );

    test('Customer inside custom area at 3 km receives fixed total area fee (60 EGP)', () {
      final fee = DeliveryFeeCalculator.calculateFee(
        restaurant: baseRestaurant,
        customerLat: 30.0444,
        customerLng: 31.2357,
        distanceKm: 3.0,
      );

      expect(fee, equals(60.0));
    });

    test('Customer inside custom area at 12 km receives fixed total area fee (60 EGP)', () {
      final fee = DeliveryFeeCalculator.calculateFee(
        restaurant: baseRestaurant,
        customerLat: 30.0444,
        customerLng: 31.2357,
        distanceKm: 12.0, // 12 km inside area radius -> returns fixed total fee (60 EGP)
      );

      expect(fee, equals(60.0));
    });

    test('Customer outside area radius falls back seamlessly to vendor standard fee (40 EGP)', () {
      final fee = DeliveryFeeCalculator.calculateFee(
        restaurant: baseRestaurant,
        customerLat: 31.2001, // Far away outside radius
        customerLng: 29.9187,
        distanceKm: 20.0,
      );

      expect(fee, equals(40.0));
    });
  });
}
