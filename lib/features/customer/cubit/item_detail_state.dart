import 'package:equatable/equatable.dart';
import 'package:z_speed/core/enums/measure_enums.dart';
import 'package:z_speed/features/restaurant/model/menu_item.dart';
import 'package:z_speed/features/restaurant/model/menu_item_variant.dart';
import 'package:z_speed/features/restaurant/model/addon_group.dart';
import 'package:z_speed/features/cart/model/cart_item.dart';
import 'package:z_speed/features/order/model/order_item.dart';

class ItemDetailState extends Equatable {
  final MenuItem item;
  final String restaurantId;
  final String sectionId;
  final List<AddonGroup> addonGroups;
  final Map<String, Set<String>> selectedAddons;
  final double quantity;
  final String specialNote;
  final bool isLoadingAddons;
  final String? error;
  
  // Selected variant
  final MenuItemVariant? selectedVariant;

  const ItemDetailState({
    required this.item,
    required this.restaurantId,
    required this.sectionId,
    this.addonGroups = const [],
    this.selectedAddons = const {},
    this.quantity = 1.0,
    this.specialNote = '',
    this.isLoadingAddons = true,
    this.error,
    this.selectedVariant,
  });

  ItemDetailState copyWith({
    List<AddonGroup>? addonGroups,
    Map<String, Set<String>>? selectedAddons,
    double? quantity,
    String? specialNote,
    bool? isLoadingAddons,
    String? error,
    bool clearError = false,
    MenuItemVariant? selectedVariant,
    bool clearSelectedVariant = false,
  }) {
    return ItemDetailState(
      item: item,
      restaurantId: restaurantId,
      sectionId: sectionId,
      addonGroups: addonGroups ?? this.addonGroups,
      selectedAddons: selectedAddons ?? this.selectedAddons,
      quantity: quantity ?? this.quantity,
      specialNote: specialNote ?? this.specialNote,
      isLoadingAddons: isLoadingAddons ?? this.isLoadingAddons,
      error: clearError ? null : (error ?? this.error),
      selectedVariant: clearSelectedVariant ? null : (selectedVariant ?? this.selectedVariant),
    );
  }

  double get basePrice => selectedVariant != null
      ? selectedVariant!.price
      : (item.discountedPrice ?? item.price);

  double get addonsTotal {
    double total = 0.0;
    for (final group in addonGroups) {
      final selectedIds = selectedAddons[group.id] ?? {};
      for (final optionId in selectedIds) {
        final option = group.options.firstWhere(
          (o) => o.id == optionId,
          orElse: () => const AddonOption(
            id: '',
            name: '',
            extraPrice: 0.0,
            isDefault: false,
            isAvailable: true,
          ),
        );
        total += option.extraPrice;
      }
    }
    return total;
  }

  double get itemTotal => (basePrice * quantity) + addonsTotal;

  double get effectiveMeasureStep {
    if (item.measureType == MeasureType.piece) return 1.0;
    return item.measureStep ?? 0.1;
  }

  double get minQuantity =>
      item.minQuantity ?? (item.measureType == MeasureType.piece ? 1.0 : 0.1);

  double get maxQuantity => item.maxQuantity ?? 99.0;

  bool get canAddToCart => validationErrors.isEmpty;

  List<String> get validationErrors {
    final errors = <String>[];

    if (!item.isAvailable) {
      errors.add('Item is currently unavailable');
    }

    // Variants are required — user must pick one if the item has variants
    if (item.variants.isNotEmpty && selectedVariant == null) {
      errors.add('Please select an option before adding to cart');
    } else if (selectedVariant != null && !selectedVariant!.isAvailable) {
      errors.add('Selected option is currently unavailable');
    }

    for (final group in addonGroups) {
      final selectedIds = selectedAddons[group.id] ?? {};
      if (group.isRequired && selectedIds.length < group.minSelections) {
        errors.add(
            '${group.name} is required (select at least ${group.minSelections})');
      }

      for (final optionId in selectedIds) {
        final option = group.options.firstWhere(
          (o) => o.id == optionId,
          orElse: () => const AddonOption(
            id: '',
            name: '',
            extraPrice: 0,
            isDefault: false,
            isAvailable: true,
          ),
        );
        if (!option.isAvailable) {
          errors.add('Selected option is currently unavailable');
        }
      }
    }

    if (quantity < minQuantity) {
      errors.add('Minimum quantity is $minQuantity');
    }
    if (quantity > maxQuantity) {
      errors.add('Maximum quantity is $maxQuantity');
    }

    return errors;
  }

  CartItem toCartItem() {
    final selectedAddonsList = <SelectedAddon>[];
    for (final group in addonGroups) {
      final selectedIds = selectedAddons[group.id] ?? {};
      for (final optionId in selectedIds) {
        final option = group.options.firstWhere((o) => o.id == optionId);
        selectedAddonsList.add(SelectedAddon(
          addonGroupId: group.id,
          addonGroupName: group.name,
          optionId: option.id,
          optionName: option.name,
          extraPrice: option.extraPrice,
        ));
      }
    }

    final cartItemId = '${item.id}_${DateTime.now().millisecondsSinceEpoch}';
    return CartItem(
      id: cartItemId,
      menuItemId: item.id,
      sectionId: sectionId,
      restaurantId: restaurantId,
      menuItemName: item.name,
      menuItemNameAr: item.nameAr,
      imageUrl: item.imageUrl,
      unitPrice: basePrice,
      quantity: quantity,
      measureType: item.measureType,
      specialNote: specialNote.isEmpty ? null : specialNote,
      selectedAddons: selectedAddonsList,
      addonsTotal: addonsTotal,
      itemTotal: itemTotal,
      addedAt: DateTime.now(),
      variantId: selectedVariant?.id,
      selectedVariantName: selectedVariant?.name,
      selectedVariantNameAr: selectedVariant?.nameAr,
    );
  }

  @override
  List<Object?> get props => [
        item,
        restaurantId,
        sectionId,
        addonGroups,
        selectedAddons,
        quantity,
        specialNote,
        isLoadingAddons,
        error,
        selectedVariant,
      ];
}
