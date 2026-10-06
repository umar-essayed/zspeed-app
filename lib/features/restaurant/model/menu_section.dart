import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// A menu section within a restaurant (e.g., "Grills", "Appetizers").
///
/// Firestore path: `restaurants/{restaurantId}/menuSections/{sectionId}`
class MenuSection extends Equatable {
  final String id;
  final String restaurantId;
  final String name;
  final String? nameAr;
  final String? description;
  final String? imageUrl;
  final int sortOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  String getLocalizedName(String langCode) =>
      (langCode == 'ar' && nameAr != null && nameAr!.isNotEmpty)
          ? nameAr!
          : name;

  const MenuSection({
    required this.id,
    required this.restaurantId,
    required this.name,
    this.nameAr,
    this.description,
    this.imageUrl,
    this.sortOrder = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MenuSection.fromMap(Map<String, dynamic> map, String documentId) {
    return MenuSection(
      id: documentId,
      restaurantId: map['restaurantId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      nameAr: map['nameAr'] as String?,
      description: map['description'] as String?,
      imageUrl: map['imageUrl'] as String?,
      sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
      isActive: map['isActive'] as bool? ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'restaurantId': restaurantId,
      'name': name,
      'nameAr': nameAr,
      'description': description,
      'imageUrl': imageUrl,
      'sortOrder': sortOrder,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  MenuSection copyWith({
    String? id,
    String? restaurantId,
    String? name,
    String? nameAr,
    String? description,
    String? imageUrl,
    int? sortOrder,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MenuSection(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      name: name ?? this.name,
      nameAr: nameAr ?? this.nameAr,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        restaurantId,
        name,
        nameAr,
        description,
        imageUrl,
        sortOrder,
        isActive,
        createdAt,
        updatedAt,
      ];
}
