import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:z_speed/core/enums/measure_enums.dart';
import 'package:z_speed/features/order/model/order_item.dart';

/// A cart item with full addon and customization support.
///
/// Firestore path: `carts/{userId}/items/{cartItemId}`
class CartItem extends Equatable {
  final String id;
  final String menuItemId;
  final String sectionId; // Required for exact price lookup in placeOrder
  final String
      restaurantId; // Required for cart validation (single restaurant per cart)
  final String menuItemName; // denormalized
  final String? menuItemNameAr;
  final String? imageUrl;
  final double unitPrice;
  final double quantity; // Changed to double to support weight-based items
  final MeasureType measureType;
  final String? specialNote;
  final List<SelectedAddon> selectedAddons;
  final double addonsTotal;
  final double itemTotal;
  final DateTime addedAt;

  // Selected Variant details
  final String? variantId;
  final String? selectedVariantName;
  final String? selectedVariantNameAr;

  const CartItem({
    required this.id,
    required this.menuItemId,
    this.sectionId = '',
    required this.restaurantId,
    required this.menuItemName,
    this.menuItemNameAr,
    this.imageUrl,
    required this.unitPrice,
    this.quantity = 1.0,
    this.measureType = MeasureType.piece,
    this.specialNote,
    this.selectedAddons = const [],
    this.addonsTotal = 0.0,
    required this.itemTotal,
    required this.addedAt,
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

  factory CartItem.fromMap(Map<String, dynamic> map, String documentId) {
    return CartItem(
      id: documentId,
      menuItemId: map['menuItemId'] as String? ?? '',
      sectionId: map['sectionId'] as String? ?? '',
      restaurantId: map['restaurantId'] as String? ?? '',
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
      addedAt: (map['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      variantId: map['variantId'] as String?,
      selectedVariantName: map['selectedVariantName'] as String?,
      selectedVariantNameAr: map['selectedVariantNameAr'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'menuItemId': menuItemId,
      'sectionId': sectionId,
      'restaurantId': restaurantId,
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
      'addedAt': Timestamp.fromDate(addedAt),
      if (variantId != null) 'variantId': variantId,
      if (selectedVariantName != null) 'selectedVariantName': selectedVariantName,
      if (selectedVariantNameAr != null) 'selectedVariantNameAr': selectedVariantNameAr,
    };
  }

  /// Increase quantity (returns new instance)
  CartItem increaseQuantity() {
    final newQuantity = measureType == MeasureType.piece
        ? quantity + 1
        : quantity + 0.1; // 100g increment for weight
    return copyWith(
      quantity: newQuantity,
      itemTotal: (unitPrice * newQuantity) + addonsTotal,
    );
  }

  /// Decrease quantity (returns new instance)
  CartItem decreaseQuantity() {
    if (quantity <= (measureType == MeasureType.piece ? 1 : 0.1)) {
      return this;
    }
    final newQuantity =
        measureType == MeasureType.piece ? quantity - 1 : quantity - 0.1;
    return copyWith(
      quantity: newQuantity,
      itemTotal: (unitPrice * newQuantity) + addonsTotal,
    );
  }

  CartItem copyWith({
    String? id,
    String? menuItemId,
    String? sectionId,
    String? restaurantId,
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
    DateTime? addedAt,
    String? variantId,
    String? selectedVariantName,
    String? selectedVariantNameAr,
  }) {
    return CartItem(
      id: id ?? this.id,
      menuItemId: menuItemId ?? this.menuItemId,
      sectionId: sectionId ?? this.sectionId,
      restaurantId: restaurantId ?? this.restaurantId,
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
      addedAt: addedAt ?? this.addedAt,
      variantId: variantId ?? this.variantId,
      selectedVariantName: selectedVariantName ?? this.selectedVariantName,
      selectedVariantNameAr: selectedVariantNameAr ?? this.selectedVariantNameAr,
    );
  }

  @override
  List<Object?> get props => [
        id,
        menuItemId,
        sectionId,
        restaurantId,
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
        addedAt,
        variantId,
        selectedVariantName,
        selectedVariantNameAr,
      ];
}
