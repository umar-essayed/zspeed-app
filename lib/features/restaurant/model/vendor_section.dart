import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:z_speed/core/enums/user_enums.dart';

/// An admin-managed section for non-restaurant vendors.
///
/// Firestore path: `vendorSections/{id}`
///
/// Each document belongs to either a supermarket or pharmacy vendor type.
/// Vendors pick from these when adding menu items.
class VendorSection extends Equatable {
  final String id;
  final String name;
  final String nameAr;
  final String? imageUrl;
  final VendorType vendorType;
  final int sortOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const VendorSection({
    required this.id,
    required this.name,
    required this.nameAr,
    this.imageUrl,
    required this.vendorType,
    this.sortOrder = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VendorSection.fromMap(Map<String, dynamic> map, String documentId) {
    return VendorSection(
      id: documentId,
      name: map['name'] as String? ?? '',
      nameAr: map['nameAr'] as String? ?? '',
      imageUrl: map['imageUrl'] as String?,
      vendorType: VendorTypeX.fromKey(map['vendorType'] as String? ?? 'supermarket'),
      sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
      isActive: map['isActive'] as bool? ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'nameAr': nameAr,
      'imageUrl': imageUrl,
      'vendorType': vendorType.key,
      'sortOrder': sortOrder,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  VendorSection copyWith({
    String? id,
    String? name,
    String? nameAr,
    String? imageUrl,
    bool clearImageUrl = false,
    VendorType? vendorType,
    int? sortOrder,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VendorSection(
      id: id ?? this.id,
      name: name ?? this.name,
      nameAr: nameAr ?? this.nameAr,
      imageUrl: clearImageUrl ? null : (imageUrl ?? this.imageUrl),
      vendorType: vendorType ?? this.vendorType,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, name, nameAr, imageUrl, vendorType, sortOrder, isActive, createdAt, updatedAt];
}
