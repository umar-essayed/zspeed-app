import 'package:equatable/equatable.dart';
import 'package:z_speed/core/enums/measure_enums.dart';

/// A single item within an order.
///
/// Firestore path: `orders/{orderId}/items/{orderItemId}`
class OrderItem extends Equatable {
  final String id;
  final String menuItemId;
  final String menuItemName; // denormalized
  final String? menuItemNameAr;
  final String? imageUrl;
  final double unitPrice;
  final double quantity;
  final MeasureType measureType;
  final String? specialNote;
  final List<SelectedAddon> selectedAddons;
  final double addonsTotal;
  final double itemTotal;

  // Variant details
  final String? variantId;
  final String? selectedVariantName;
  final String? selectedVariantNameAr;

  const OrderItem({
    required this.id,
    required this.menuItemId,
    required this.menuItemName,
    this.menuItemNameAr,
    this.imageUrl,
    required this.unitPrice,
    required this.quantity,
    this.measureType = MeasureType.piece,
    this.specialNote,
    this.selectedAddons = const [],
    this.addonsTotal = 0.0,
    required this.itemTotal,
    this.variantId,
    this.selectedVariantName,
    this.selectedVariantNameAr,
  });

  String getLocalizedVariantName(String langCode) {
    if (langCode == 'ar' && selectedVariantNameAr != null && selectedVariantNameAr!.isNotEmpty) {
      return selectedVariantNameAr!;
    }
    return selectedVariantName ?? '';
  }

  String getLocalizedName(String langCode) {
    if (langCode == 'ar' && menuItemNameAr != null && menuItemNameAr!.isNotEmpty) {
      return menuItemNameAr!;
    }
    return menuItemName;
  }

  factory OrderItem.fromMap(Map<String, dynamic> map, String documentId) {
    return OrderItem(
      id: documentId,
      menuItemId: map['menuItemId'] as String? ?? '',
      menuItemName: map['menuItemName'] as String? ?? '',
      menuItemNameAr: map['menuItemNameAr'] as String?,
      imageUrl: map['imageUrl'] as String?,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
      quantity: (map['quantity'] as num?)?.toDouble() ?? 1.0,
      measureType:
          MeasureType.fromKey(map['measureType'] as String? ?? 'piece'),
      specialNote: map['specialNote'] as String?,
      selectedAddons: (map['selectedAddons'] as List<dynamic>?)
              ?.map((e) => SelectedAddon.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      addonsTotal: (map['addonsTotal'] as num?)?.toDouble() ?? 0.0,
      itemTotal: (map['itemTotal'] as num?)?.toDouble() ?? 0.0,
      variantId: map['variantId'] as String?,
      selectedVariantName: map['selectedVariantName'] as String?,
      selectedVariantNameAr: map['selectedVariantNameAr'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'menuItemId': menuItemId,
      'menuItemName': menuItemName,
      if (menuItemNameAr != null) 'menuItemNameAr': menuItemNameAr,
      'imageUrl': imageUrl,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'measureType': measureType.key,
      'specialNote': specialNote,
      'selectedAddons': selectedAddons.map((e) => e.toMap()).toList(),
      'addonsTotal': addonsTotal,
      'itemTotal': itemTotal,
      if (variantId != null) 'variantId': variantId,
      if (selectedVariantName != null) 'selectedVariantName': selectedVariantName,
      if (selectedVariantNameAr != null) 'selectedVariantNameAr': selectedVariantNameAr,
    };
  }

  OrderItem copyWith({
    String? id,
    String? menuItemId,
    String? menuItemName,
    String? menuItemNameAr,
    String? imageUrl,
    double? unitPrice,
    double? quantity,
    MeasureType? measureType,
    String? specialNote,
    List<SelectedAddon>? selectedAddons,
    double? addonsTotal,
    double? itemTotal,
    String? variantId,
    String? selectedVariantName,
    String? selectedVariantNameAr,
  }) {
    return OrderItem(
      id: id ?? this.id,
      menuItemId: menuItemId ?? this.menuItemId,
      menuItemName: menuItemName ?? this.menuItemName,
      menuItemNameAr: menuItemNameAr ?? this.menuItemNameAr,
      imageUrl: imageUrl ?? this.imageUrl,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      measureType: measureType ?? this.measureType,
      specialNote: specialNote ?? this.specialNote,
      selectedAddons: selectedAddons ?? this.selectedAddons,
      addonsTotal: addonsTotal ?? this.addonsTotal,
      itemTotal: itemTotal ?? this.itemTotal,
      variantId: variantId ?? this.variantId,
      selectedVariantName: selectedVariantName ?? this.selectedVariantName,
      selectedVariantNameAr: selectedVariantNameAr ?? this.selectedVariantNameAr,
    );
  }

  @override
  List<Object?> get props => [
        id,
        menuItemId,
        menuItemName,
        menuItemNameAr,
        imageUrl,
        unitPrice,
        quantity,
        measureType,
        specialNote,
        selectedAddons,
        addonsTotal,
        itemTotal,
        variantId,
        selectedVariantName,
        selectedVariantNameAr,
      ];
}

/// A specific addon option selected by the customer.
class SelectedAddon extends Equatable {
  final String addonGroupId;
  final String addonGroupName;
  final String optionId;
  final String optionName;
  final double extraPrice;

  const SelectedAddon({
    required this.addonGroupId,
    required this.addonGroupName,
    required this.optionId,
    required this.optionName,
    this.extraPrice = 0.0,
  });

  factory SelectedAddon.fromMap(Map<String, dynamic> map) {
    return SelectedAddon(
      addonGroupId: map['addonGroupId'] as String? ?? '',
      addonGroupName: map['addonGroupName'] as String? ?? '',
      optionId: map['optionId'] as String? ?? '',
      optionName: map['optionName'] as String? ?? '',
      extraPrice: (map['extraPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() => {
        'addonGroupId': addonGroupId,
        'addonGroupName': addonGroupName,
        'optionId': optionId,
        'optionName': optionName,
        'extraPrice': extraPrice,
      };

  SelectedAddon copyWith({
    String? addonGroupId,
    String? addonGroupName,
    String? optionId,
    String? optionName,
    double? extraPrice,
  }) {
    return SelectedAddon(
      addonGroupId: addonGroupId ?? this.addonGroupId,
      addonGroupName: addonGroupName ?? this.addonGroupName,
      optionId: optionId ?? this.optionId,
      optionName: optionName ?? this.optionName,
      extraPrice: extraPrice ?? this.extraPrice,
    );
  }

  @override
  List<Object?> get props => [
        addonGroupId,
        addonGroupName,
        optionId,
        optionName,
        extraPrice,
      ];
}
