import 'package:equatable/equatable.dart';

class MenuItemVariant extends Equatable {
  final String id;
  final String foodItemId;
  final String name;
  final String? nameAr;
  final double price;
  final double? originalPrice;
  final int stockQuantity;
  final bool isAvailable;
  final String? firebaseId;
  final bool isFraction;
  final int? fractionMultiplier;

  const MenuItemVariant({
    required this.id,
    required this.foodItemId,
    required this.name,
    this.nameAr,
    required this.price,
    this.originalPrice,
    this.stockQuantity = 0,
    this.isAvailable = true,
    this.firebaseId,
    this.isFraction = false,
    this.fractionMultiplier,
  });

  String getLocalizedName(String langCode) =>
      (langCode == 'ar' && nameAr != null && nameAr!.isNotEmpty)
          ? nameAr!
          : name;

  factory MenuItemVariant.fromMap(Map<String, dynamic> map, String documentId) {
    return MenuItemVariant(
      id: documentId,
      foodItemId: map['foodItemId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      nameAr: map['nameAr'] as String?,
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      originalPrice: (map['originalPrice'] as num?)?.toDouble(),
      stockQuantity: (map['stockQuantity'] as num?)?.toInt() ?? 0,
      isAvailable: map['isAvailable'] as bool? ?? true,
      firebaseId: map['firebaseId'] as String?,
      isFraction: map['isFraction'] as bool? ?? false,
      fractionMultiplier: (map['fractionMultiplier'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'foodItemId': foodItemId,
      'name': name,
      'nameAr': nameAr,
      'price': price,
      'originalPrice': originalPrice,
      'stockQuantity': stockQuantity,
      'isAvailable': isAvailable,
      'firebaseId': firebaseId,
      'isFraction': isFraction,
      'fractionMultiplier': fractionMultiplier,
    };
  }

  MenuItemVariant copyWith({
    String? id,
    String? foodItemId,
    String? name,
    String? nameAr,
    double? price,
    double? originalPrice,
    int? stockQuantity,
    bool? isAvailable,
    String? firebaseId,
    bool? isFraction,
    int? fractionMultiplier,
  }) {
    return MenuItemVariant(
      id: id ?? this.id,
      foodItemId: foodItemId ?? this.foodItemId,
      name: name ?? this.name,
      nameAr: nameAr ?? this.nameAr,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      isAvailable: isAvailable ?? this.isAvailable,
      firebaseId: firebaseId ?? this.firebaseId,
      isFraction: isFraction ?? this.isFraction,
      fractionMultiplier: fractionMultiplier ?? this.fractionMultiplier,
    );
  }

  @override
  List<Object?> get props => [
        id,
        foodItemId,
        name,
        nameAr,
        price,
        originalPrice,
        stockQuantity,
        isAvailable,
        firebaseId,
        isFraction,
        fractionMultiplier,
      ];
}
