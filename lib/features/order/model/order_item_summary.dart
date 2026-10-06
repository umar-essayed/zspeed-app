import 'package:equatable/equatable.dart';

/// A lightweight summary of an item in a customer order.
///
/// This is embedded directly in the [Order] document to avoid
/// N+1 queries when rendering order history lists.
class OrderItemSummary extends Equatable {
  final String id;
  final String menuItemId;
  final String name;
  final String? nameAr;
  final int quantity;
  final double price;
  final double totalPrice;
  final String? optionsSummary;

  const OrderItemSummary({
    required this.id,
    required this.menuItemId,
    required this.name,
    this.nameAr,
    required this.quantity,
    required this.price,
    required this.totalPrice,
    this.optionsSummary,
  });

  factory OrderItemSummary.fromMap(Map<String, dynamic> map,
      [String? documentId]) {
    return OrderItemSummary(
      id: documentId ?? map['id'] as String? ?? '',
      menuItemId: map['menuItemId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      nameAr: map['nameAr'] as String?,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (map['totalPrice'] as num?)?.toDouble() ?? 0.0,
      optionsSummary: map['optionsSummary'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'menuItemId': menuItemId,
      'name': name,
      if (nameAr != null) 'nameAr': nameAr,
      'quantity': quantity,
      'price': price,
      'totalPrice': totalPrice,
      if (optionsSummary != null) 'optionsSummary': optionsSummary,
    };
  }

  @override
  List<Object?> get props => [
        id,
        menuItemId,
        name,
        nameAr,
        quantity,
        price,
        totalPrice,
        optionsSummary,
      ];
  String getLocalizedName(String langCode) {
    if (langCode == 'ar' && nameAr != null && nameAr!.isNotEmpty) {
      return nameAr!;
    }
    return name;
  }
}
