import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// A globally-managed cuisine type / category.
///
/// Firestore path: `cuisineTypes/{id}`
///
/// Managed by admin. Restaurants select from these when adding menu items.
/// Customers see these as category filters on their browse screen.
class CuisineType extends Equatable {
  final String id;
  final String name;
  final String nameAr;
  final String? _imageUrl;
  final int sortOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  String getLocalizedName(String langCode) =>
      (langCode == 'ar') ? nameAr : name;

  String? get imageUrl => (_imageUrl == null || _imageUrl.isEmpty)
      ? getCuisineImageUrl(name)
      : _imageUrl;

  const CuisineType({
    required this.id,
    required this.name,
    required this.nameAr,
    this._imageUrl,
    this.sortOrder = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CuisineType.fromMap(Map<String, dynamic> map, String documentId) {
    return CuisineType(
      id: documentId,
      name: map['name'] as String? ?? '',
      nameAr: map['nameAr'] as String? ?? '',
      imageUrl: map['imageUrl'] as String?,
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
      'imageUrl': _imageUrl,
      'sortOrder': sortOrder,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  CuisineType copyWith({
    String? id,
    String? name,
    String? nameAr,
    String? imageUrl,
    int? sortOrder,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CuisineType(
      id: id ?? this.id,
      name: name ?? this.name,
      nameAr: nameAr ?? this.nameAr,
      imageUrl: imageUrl ?? _imageUrl,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    nameAr,
    imageUrl,
    sortOrder,
    isActive,
    createdAt,
    updatedAt,
  ];
}

/// Helper mapping to get high-quality food category images for each default cuisine.
String? getCuisineImageUrl(String name) {
  final cleanName = name.trim().toLowerCase();

  final Map<String, String> map = {
    'american': 'assets/images/cuisines/american.jpg',
    'arabic': 'assets/images/cuisines/arabic.jpg',
    'arabic sweets': 'assets/images/cuisines/arabic_sweets.jpg',
    'asian': 'assets/images/cuisines/asian.jpg',
    'bakery & pastry': 'assets/images/cuisines/bakery_pastry.jpg',
    'beverages': 'assets/images/cuisines/beverages.jpg',
    'breakfast': 'assets/images/cuisines/breakfast.jpg',
    'burgers': 'assets/images/cuisines/burgers.jpg',
    'cakes': 'assets/images/cuisines/cakes.jpg',
    'chicken': 'assets/images/cuisines/chicken.jpg',
    'chinese': 'assets/images/cuisines/chinese.jpg',
    'chocolate': 'assets/images/cuisines/chocolate.jpg',
    'coffee & tea': 'assets/images/cuisines/coffee_tea.jpg',
    'crepes': 'assets/images/cuisines/crepes.jpg',
    'desserts': 'assets/images/cuisines/desserts.jpg',
    'donuts': 'assets/images/cuisines/donuts.jpg',
    'egyptian': 'assets/images/cuisines/egyptian.jpg',
    'fast food': 'assets/images/cuisines/fast_food.jpg',
    'fish & seafood': 'assets/images/cuisines/fish_seafood.jpg',
    'foul & falafel': 'assets/images/cuisines/foul_falafel.jpg',
    'koshari': 'assets/images/cuisines/koshari.jpg',
    'fried chicken': 'assets/images/cuisines/fried_chicken.jpg',
    'grills': 'assets/images/cuisines/grills.jpg',
    'healthy': 'assets/images/cuisines/healthy.jpg',
    'ice cream': 'assets/images/cuisines/ice_cream.jpg',
    'international': 'assets/images/cuisines/international.jpg',
    'italian': 'assets/images/cuisines/italian.jpg',
    'japanese': 'assets/images/cuisines/japanese.jpg',
    'juices': 'assets/images/cuisines/juices.jpg',
    'lebanese': 'assets/images/cuisines/lebanese.jpg',
    'pasta': 'assets/images/cuisines/pasta.jpg',
    'pies': 'assets/images/cuisines/pies.jpg',
    'pizza': 'assets/images/cuisines/pizza.jpg',
    'salad': 'assets/images/cuisines/salad.jpg',
    'sandwiches': 'assets/images/cuisines/sandwiches.jpg',
    'shawerma': 'assets/images/cuisines/shawerma.jpg',
    'sushi': 'assets/images/cuisines/sushi.jpg',
    'syrian': 'assets/images/cuisines/syrian.jpg',
    'waffles': 'assets/images/cuisines/waffles.jpg',

    // Arabic matching
    'أمريكي': 'assets/images/cuisines/american.jpg',
    'عربي': 'assets/images/cuisines/arabic.jpg',
    'حلويات عربية': 'assets/images/cuisines/arabic_sweets.jpg',
    'آسيوي': 'assets/images/cuisines/asian.jpg',
    'مخبوزات ومعجنات': 'assets/images/cuisines/bakery_pastry.jpg',
    'مشروبات': 'assets/images/cuisines/beverages.jpg',
    'فطور': 'assets/images/cuisines/breakfast.jpg',
    'برجر': 'assets/images/cuisines/burgers.jpg',
    'كيك': 'assets/images/cuisines/cakes.jpg',
    'دجاج': 'assets/images/cuisines/chicken.jpg',
    'صيني': 'assets/images/cuisines/chinese.jpg',
    'شوكولاتة': 'assets/images/cuisines/chocolate.jpg',
    'قهوة وشاي': 'assets/images/cuisines/coffee_tea.jpg',
    'كريب': 'assets/images/cuisines/crepes.jpg',
    'حلويات': 'assets/images/cuisines/desserts.jpg',
    'دونات': 'assets/images/cuisines/donuts.jpg',
    'مصري': 'assets/images/cuisines/egyptian.jpg',
    'وجبات سريعة': 'assets/images/cuisines/fast_food.jpg',
    'أسماك ومأكولات بحرية': 'assets/images/cuisines/fish_seafood.jpg',
    'فول وفلافل': 'assets/images/cuisines/foul_falafel.jpg',
    'كشري': 'assets/images/cuisines/koshari.jpg',
    'دجاج مقلي': 'assets/images/cuisines/fried_chicken.jpg',
    'مشويات': 'assets/images/cuisines/grills.jpg',
    'أكل صحي': 'assets/images/cuisines/healthy.jpg',
    'آيس كريم': 'assets/images/cuisines/ice_cream.jpg',
    'عالمي': 'assets/images/cuisines/international.jpg',
    'إيطالي': 'assets/images/cuisines/italian.jpg',
    'ياباني': 'assets/images/cuisines/japanese.jpg',
    'عصائر': 'assets/images/cuisines/juices.jpg',
    'لبناني': 'assets/images/cuisines/lebanese.jpg',
    'باستا': 'assets/images/cuisines/pasta.jpg',
    'فطائر': 'assets/images/cuisines/pies.jpg',
    'بيتزا': 'assets/images/cuisines/pizza.jpg',
    'سلطات': 'assets/images/cuisines/salad.jpg',
    'ساندويتشات': 'assets/images/cuisines/sandwiches.jpg',
    'شاورما': 'assets/images/cuisines/shawerma.jpg',
    'سوشي': 'assets/images/cuisines/sushi.jpg',
    'سوري': 'assets/images/cuisines/syrian.jpg',
    'وافل': 'assets/images/cuisines/waffles.jpg',
  };

  return map[cleanName];
}
