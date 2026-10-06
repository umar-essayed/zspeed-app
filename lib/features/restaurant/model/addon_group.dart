import 'package:equatable/equatable.dart';
import 'package:z_speed/core/enums/measure_enums.dart';

/// A group of addons for a menu item.
///
/// Firestore path: `restaurants/{rid}/menuSections/{sid}/items/{iid}/addonGroups/{gid}`
///
/// Example: "Choose your bread" → [Samoon, Lebanese, Shami] (single, required)
/// Example: "Extras" → [Extra cheese +5, Extra sauce +3] (multi, optional)
class AddonGroup extends Equatable {
  final String id;
  final String menuItemId;
  final String name;
  final String? nameAr;
  final AddonSelectionType selectionType; 
  final bool isRequired;
  final int minSelections;
  final int maxSelections; // -1 = unlimited
  final List<AddonOption> options;
  final int sortOrder;

  String getLocalizedName(String langCode) =>
      (langCode == 'ar' && nameAr != null && nameAr!.isNotEmpty)
          ? nameAr!
          : name;

  const AddonGroup({
    required this.id,
    required this.menuItemId,
    required this.name,
    this.nameAr,
    this.selectionType = AddonSelectionType.single,
    this.isRequired = false,
    this.minSelections = 0,
    this.maxSelections = -1,
    this.options = const [],
    this.sortOrder = 0,
  });

  factory AddonGroup.fromMap(Map<String, dynamic> map, String documentId) {
    return AddonGroup(
      id: documentId,
      menuItemId: map['menuItemId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      nameAr: map['nameAr'] as String?,
      selectionType: AddonSelectionType.fromKey(
          map['selectionType'] as String? ?? 'single'),
      isRequired: map['isRequired'] as bool? ?? false,
      minSelections: (map['minSelections'] as num?)?.toInt() ?? 0,
      maxSelections: (map['maxSelections'] as num?)?.toInt() ?? -1,
      options: (map['options'] as List<dynamic>?)
              ?.map((e) => AddonOption.fromMap(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
      sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'menuItemId': menuItemId,
      'name': name,
      'nameAr': nameAr,
      'selectionType': selectionType.key,
      'isRequired': isRequired,
      'minSelections': minSelections,
      'maxSelections': maxSelections,
      'options': options.map((e) => e.toMap()).toList(),
      'sortOrder': sortOrder,
    };
  }

  AddonGroup copyWith({
    String? id,
    String? menuItemId,
    String? name,
    String? nameAr,
    AddonSelectionType? selectionType,
    bool? isRequired,
    int? minSelections,
    int? maxSelections,
    List<AddonOption>? options,
    int? sortOrder,
  }) {
    return AddonGroup(
      id: id ?? this.id,
      menuItemId: menuItemId ?? this.menuItemId,
      name: name ?? this.name,
      nameAr: nameAr ?? this.nameAr,
      selectionType: selectionType ?? this.selectionType,
      isRequired: isRequired ?? this.isRequired,
      minSelections: minSelections ?? this.minSelections,
      maxSelections: maxSelections ?? this.maxSelections,
      options: options ?? this.options,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  List<Object?> get props => [
        id,
        menuItemId,
        name,
        nameAr,
        selectionType,
        isRequired,
        minSelections,
        maxSelections,
        options,
        sortOrder,
      ];
}

class AddonOption extends Equatable {
  final String id;
  final String name;
  final String? nameAr;
  final double extraPrice;
  final bool isDefault;
  final bool isAvailable;
  final String? imageUrl;

  String getLocalizedName(String langCode) =>
      (langCode == 'ar' && nameAr != null && nameAr!.isNotEmpty)
          ? nameAr!
          : name;

  const AddonOption({
    required this.id,
    required this.name,
    this.nameAr,
    this.extraPrice = 0.0,
    this.isDefault = false,
    this.isAvailable = true,
    this.imageUrl,
  });

  factory AddonOption.fromMap(Map<String, dynamic> map) {
    return AddonOption(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      nameAr: map['nameAr'] as String?,
      extraPrice: (map['extraPrice'] as num?)?.toDouble() ?? 0.0,
      isDefault: map['isDefault'] as bool? ?? false,
      isAvailable: map['isAvailable'] as bool? ?? true,
      imageUrl: map['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'nameAr': nameAr,
        'extraPrice': extraPrice,
        'isDefault': isDefault,
        'isAvailable': isAvailable,
        'imageUrl': imageUrl,
      };

  AddonOption copyWith({
    String? id,
    String? name,
    String? nameAr,
    double? extraPrice,
    bool? isDefault,
    bool? isAvailable,
    String? imageUrl,
  }) {
    return AddonOption(
      id: id ?? this.id,
      name: name ?? this.name,
      nameAr: nameAr ?? this.nameAr,
      extraPrice: extraPrice ?? this.extraPrice,
      isDefault: isDefault ?? this.isDefault,
      isAvailable: isAvailable ?? this.isAvailable,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, nameAr, extraPrice, isDefault, isAvailable, imageUrl];
}
