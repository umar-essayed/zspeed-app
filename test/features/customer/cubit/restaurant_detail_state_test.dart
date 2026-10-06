import 'package:flutter_test/flutter_test.dart';
import 'package:z_speed/features/customer/cubit/restaurant_detail_state.dart';
import 'package:z_speed/features/restaurant/model/menu_item.dart';

void main() {
  group('RestaurantDetailState getFilteredItems Arabic search tests', () {
    final now = DateTime.now();
    final item1 = MenuItem(
      id: '1',
      sectionId: 'sec1',
      restaurantId: 'rest1',
      name: 'Chicken Burger',
      nameAr: 'برجر دجاج',
      description: 'Tasty burger',
      descriptionAr: 'برجر دجاج شهي ولذيذ',
      imageUrl: '',
      price: 10.0,
      createdAt: now,
      updatedAt: now,
    );

    final item2 = MenuItem(
      id: '2',
      sectionId: 'sec1',
      restaurantId: 'rest1',
      name: 'Rice with Meat',
      nameAr: 'أرز باللحم',
      description: 'Fresh rice',
      descriptionAr: 'أرز بسمتي طازج',
      imageUrl: '',
      price: 15.0,
      createdAt: now,
      updatedAt: now,
    );

    final state = RestaurantDetailState(
      itemsBySection: {
        'sec1': [item1, item2],
      },
    );

    test('filters items by Arabic name (nameAr)', () {
      final filteredState = state.copyWith(searchQuery: 'برجر');
      final filtered = filteredState.getFilteredItems('sec1');

      expect(filtered.length, equals(1));
      expect(filtered.first.id, equals('1'));
    });

    test('filters items by Arabic description (descriptionAr)', () {
      final filteredState = state.copyWith(searchQuery: 'بسمتي');
      final filtered = filteredState.getFilteredItems('sec1');

      expect(filtered.length, equals(1));
      expect(filtered.first.id, equals('2'));
    });

    test('filters items with normalized Arabic hamza (ارز matches أرز)', () {
      final filteredState = state.copyWith(searchQuery: 'ارز');
      final filtered = filteredState.getFilteredItems('sec1');

      expect(filtered.length, equals(1));
      expect(filtered.first.id, equals('2'));
    });
  });
}
