import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:z_speed/core/enums/measure_enums.dart';
import 'package:z_speed/features/restaurant/model/addon_group.dart';
import 'package:z_speed/features/restaurant/model/menu_item_variant.dart';

/// A purchasable menu item.
///
/// Firestore path: `restaurants/{restaurantId}/menuSections/{sectionId}/items/{itemId}`
class MenuItem extends Equatable {
  final String id;
  final String sectionId;
  final String restaurantId; // denormalized for collection group queries
  final String name;
  final String? nameAr;
  final String description;
  final String? descriptionAr;
  final String imageUrl;
  final double price;
  final double? discountedPrice;
  final MeasureType measureType; // piece, gram, kilogram, liter, milliliter
  final double? measureStep; // e.g. 100 (for 100g increments)
  final double? minQuantity;
  final double? maxQuantity;
  final int preparationTime; // minutes
  final double rating;
  final int ratingCount;
  final bool isAvailable;
  final bool isPopular;
  final List<String> tags;
  final int sortOrder;
  final int? calories;
  final List<AddonGroup> addonGroups;
  final int? stock;         // current stock quantity (supermarket/pharmacy)
  final int? warningLimit;  // notify owner when stock falls below this
  final DateTime createdAt;
  final DateTime updatedAt;

  // Variants & Fractions Support
  final List<MenuItemVariant> variants;
  final bool hasFractions;
  final String? fractionUnitName;
  final String? fractionUnitNameAr;
  final int? unitsPerParent;
  final double? fractionPrice;

  String getLocalizedName(String langCode) =>
      (langCode == 'ar' && nameAr != null && nameAr!.isNotEmpty)
          ? nameAr!
          : name;

  String getLocalizedDescription(String langCode) =>
      (langCode == 'ar' && descriptionAr != null && descriptionAr!.isNotEmpty)
          ? descriptionAr!
          : description;

  const MenuItem({
    required this.id,
    required this.sectionId,
    required this.restaurantId,
    required this.name,
    this.nameAr,
    required this.description,
    this.descriptionAr,
    required this.imageUrl,
    required this.price,
    this.discountedPrice,
    this.measureType = MeasureType.piece,
    this.measureStep,
    this.minQuantity,
    this.maxQuantity,
    this.preparationTime = 0,
    this.rating = 0.0,
    this.ratingCount = 0,
    this.isAvailable = true,
    this.isPopular = false,
    this.tags = const [],
    this.sortOrder = 0,
    this.calories,
    this.addonGroups = const [],
    this.stock,
    this.warningLimit,
    required this.createdAt,
    required this.updatedAt,
    this.variants = const [],
    this.hasFractions = false,
    this.fractionUnitName,
    this.fractionUnitNameAr,
    this.unitsPerParent,
    this.fractionPrice,
  });

  factory MenuItem.fromMap(Map<String, dynamic> map, String documentId) {
    return MenuItem(
      id: documentId,
      sectionId: map['sectionId'] as String? ?? '',
      restaurantId: map['restaurantId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      nameAr: map['nameAr'] as String?,
      description: map['description'] as String? ?? '',
      descriptionAr: map['descriptionAr'] as String?,
      imageUrl: map['imageUrl'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      discountedPrice: (map['discountedPrice'] as num?)?.toDouble(),
      measureType:
          MeasureType.fromKey(map['measureType'] as String? ?? 'piece'),
      measureStep: (map['measureStep'] as num?)?.toDouble(),
      minQuantity: (map['minQuantity'] as num?)?.toDouble(),
      maxQuantity: (map['maxQuantity'] as num?)?.toDouble(),
      preparationTime: (map['preparationTime'] as num?)?.toInt() ?? 0,
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: (map['ratingCount'] as num?)?.toInt() ?? 0,
      isAvailable: map['isAvailable'] as bool? ?? true,
      isPopular: map['isPopular'] as bool? ?? false,
      tags: List<String>.from(map['tags'] ?? []),
      sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
      calories: (map['calories'] as num?)?.toInt(),
      stock: (map['stock'] as num?)?.toInt(),
      warningLimit: (map['warningLimit'] as num?)?.toInt(),
      addonGroups: (map['addonGroups'] as List<dynamic>?)
              ?.whereType<Map>()
              .map((e) => AddonGroup.fromMap(
                  Map<String, dynamic>.from(e), e['id']?.toString() ?? ''))
              .toList() ??
          [],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      variants: (map['variants'] as List<dynamic>?)
              ?.whereType<Map>()
              .map((e) => MenuItemVariant.fromMap(
                  Map<String, dynamic>.from(e), e['id']?.toString() ?? ''))
              .toList() ??
          const [],
      hasFractions: map['hasFractions'] as bool? ?? false,
      fractionUnitName: map['fractionUnitName'] as String?,
      fractionUnitNameAr: map['fractionUnitNameAr'] as String?,
      unitsPerParent: (map['unitsPerParent'] as num?)?.toInt(),
      fractionPrice: (map['fractionPrice'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sectionId': sectionId,
      'restaurantId': restaurantId,
      'name': name,
      'nameAr': nameAr,
      'description': description,
      'descriptionAr': descriptionAr,
      'imageUrl': imageUrl,
      'price': price,
      'discountedPrice': discountedPrice,
      'measureType': measureType.key,
      'measureStep': measureStep,
      'minQuantity': minQuantity,
      'maxQuantity': maxQuantity,
      'preparationTime': preparationTime,
      'rating': rating,
      'ratingCount': ratingCount,
      'isAvailable': isAvailable,
      'isPopular': isPopular,
      'tags': tags,
      'sortOrder': sortOrder,
      'calories': calories,
      'stock': stock,
      'warningLimit': warningLimit,
      'addonGroups': addonGroups.map((e) => e.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'variants': variants.map((e) => e.toMap()).toList(),
      'hasFractions': hasFractions,
      'fractionUnitName': fractionUnitName,
      'fractionUnitNameAr': fractionUnitNameAr,
      'unitsPerParent': unitsPerParent,
      'fractionPrice': fractionPrice,
    };
  }

  MenuItem copyWith({
    String? id,
    String? sectionId,
    String? restaurantId,
    String? name,
    String? nameAr,
    String? description,
    String? descriptionAr,
    String? imageUrl,
    double? price,
    double? discountedPrice,
    MeasureType? measureType,
    double? measureStep,
    double? minQuantity,
    double? maxQuantity,
    int? preparationTime,
    double? rating,
    int? ratingCount,
    bool? isAvailable,
    bool? isPopular,
    List<String>? tags,
    int? sortOrder,
    int? calories,
    List<AddonGroup>? addonGroups,
    Object? stock = _sentinel,
    Object? warningLimit = _sentinel,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<MenuItemVariant>? variants,
    bool? hasFractions,
    String? fractionUnitName,
    String? fractionUnitNameAr,
    int? unitsPerParent,
    double? fractionPrice,
  }) {
    return MenuItem(
      id: id ?? this.id,
      sectionId: sectionId ?? this.sectionId,
      restaurantId: restaurantId ?? this.restaurantId,
      name: name ?? this.name,
      nameAr: nameAr ?? this.nameAr,
      description: description ?? this.description,
      descriptionAr: descriptionAr ?? this.descriptionAr,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      discountedPrice: discountedPrice ?? this.discountedPrice,
      measureType: measureType ?? this.measureType,
      measureStep: measureStep ?? this.measureStep,
      minQuantity: minQuantity ?? this.minQuantity,
      maxQuantity: maxQuantity ?? this.maxQuantity,
      preparationTime: preparationTime ?? this.preparationTime,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      isAvailable: isAvailable ?? this.isAvailable,
      isPopular: isPopular ?? this.isPopular,
      tags: tags ?? this.tags,
      sortOrder: sortOrder ?? this.sortOrder,
      calories: calories ?? this.calories,
      addonGroups: addonGroups ?? this.addonGroups,
      stock: stock == _sentinel ? this.stock : stock as int?,
      warningLimit: warningLimit == _sentinel ? this.warningLimit : warningLimit as int?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      variants: variants ?? this.variants,
      hasFractions: hasFractions ?? this.hasFractions,
      fractionUnitName: fractionUnitName ?? this.fractionUnitName,
      fractionUnitNameAr: fractionUnitNameAr ?? this.fractionUnitNameAr,
      unitsPerParent: unitsPerParent ?? this.unitsPerParent,
      fractionPrice: fractionPrice ?? this.fractionPrice,
    );
  }

  static const Object _sentinel = Object();

  @override
  List<Object?> get props => [
        id,
        sectionId,
        restaurantId,
        name,
        nameAr,
        description,
        descriptionAr,
        imageUrl,
        price,
        discountedPrice,
        measureType,
        measureStep,
        minQuantity,
        maxQuantity,
        preparationTime,
        rating,
        ratingCount,
        isAvailable,
        isPopular,
        tags,
        sortOrder,
        calories,
        addonGroups,
        stock,
        warningLimit,
        createdAt,
        updatedAt,
        variants,
        hasFractions,
        fractionUnitName,
        fractionUnitNameAr,
        unitsPerParent,
        fractionPrice,
      ];
}
