import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart' hide Order;
import 'package:z_speed/core/enums/user_enums.dart';
import 'package:z_speed/features/restaurant/model/vendor_section.dart';

/// Firestore datasource for the global `vendorSections` collection.
///
/// Managed by admin. Read by supermarket/pharmacy vendors when adding items.
@lazySingleton
class VendorSectionDatasource {
  final FirebaseFirestore _firestore;

  VendorSectionDatasource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _ref =>
      _firestore.collection('vendorSections');

  /// Stream active sections for a specific vendor type.
  Stream<List<VendorSection>> streamByType(VendorType type) {
    return _ref
        .where('vendorType', isEqualTo: type.key)
        .where('isActive', isEqualTo: true)
        .orderBy('sortOrder')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => VendorSection.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  /// Get all sections for a vendor type (one-shot).
  Future<List<VendorSection>> getByType(VendorType type) async {
    final snap = await _ref
        .where('vendorType', isEqualTo: type.key)
        .orderBy('sortOrder')
        .get();
    return snap.docs
        .map((doc) => VendorSection.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Get all sections (admin view).
  Future<List<VendorSection>> getAll() async {
    final snap = await _ref.orderBy('vendorType').orderBy('sortOrder').get();
    return snap.docs
        .map((doc) => VendorSection.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Create a new vendor section. Returns the generated document ID.
  /// Throws if a section with the same name + vendorType already exists.
  Future<String> create(VendorSection section) async {
    final existing = await _ref
        .where('vendorType', isEqualTo: section.vendorType.key)
        .where('name', isEqualTo: section.name)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      throw Exception('A section named "${section.name}" already exists.');
    }
    final docRef = _ref.doc();
    await docRef.set(
      section
          .copyWith(
            id: docRef.id,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          )
          .toMap(),
    );
    return docRef.id;
  }

  /// Update an existing vendor section.
  Future<void> update(VendorSection section) async {
    await _ref
        .doc(section.id)
        .update(section.copyWith(updatedAt: DateTime.now()).toMap());
  }

  /// Delete a vendor section.
  Future<void> delete(String id) async {
    await _ref.doc(id).delete();
  }

  /// Remove duplicate sections that share the same name + vendorType.
  /// Keeps the document with the lowest sortOrder (first in list).
  Future<void> deduplicateAll() async {
    final snap = await _ref.orderBy('sortOrder').get();
    final seen = <String>{};
    final toDelete = <String>[];
    for (final doc in snap.docs) {
      final name = (doc.data()['name'] as String? ?? '').toLowerCase().trim();
      final type = doc.data()['vendorType'] as String? ?? '';
      final key = '$type|$name';
      if (seen.contains(key)) {
        toDelete.add(doc.id);
      } else {
        seen.add(key);
      }
    }
    if (toDelete.isEmpty) return;
    final batch = _firestore.batch();
    for (final id in toDelete) {
      batch.delete(_ref.doc(id));
    }
    await batch.commit();
  }

  /// Seed default sections for supermarket and pharmacy if empty.
  Future<void> seedIfEmpty() async {
    final snap = await _ref.limit(1).get();
    if (snap.docs.isNotEmpty) return;

    final batch = _firestore.batch();
    final allDefaults = [..._defaultSupermarket, ..._defaultPharmacy];
    for (int i = 0; i < allDefaults.length; i++) {
      final docRef = _ref.doc();
      batch.set(docRef, {
        ...allDefaults[i],
        'sortOrder': i,
        'isActive': true,
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    }
    await batch.commit();
  }

  static final List<Map<String, String>> _defaultSupermarket = [
    {'name': 'Hot Deals', 'nameAr': 'عروض ساخنة', 'vendorType': 'supermarket'},
    {
      'name': 'Fruit & Veg',
      'nameAr': 'فواكه وخضروات',
      'vendorType': 'supermarket',
    },
    {'name': 'Bakery', 'nameAr': 'مخبوزات', 'vendorType': 'supermarket'},
    {
      'name': 'Poultry, Meat & Seafood',
      'nameAr': 'دواجن ولحوم ومأكولات بحرية',
      'vendorType': 'supermarket',
    },
    {
      'name': 'Cold Cuts & Deli',
      'nameAr': 'لحوم باردة وديلي',
      'vendorType': 'supermarket',
    },
    {
      'name': 'Ready To Eat',
      'nameAr': 'جاهز للأكل',
      'vendorType': 'supermarket',
    },
    {
      'name': 'Everyday Roastery',
      'nameAr': 'محمصة يومية',
      'vendorType': 'supermarket',
    },
    {
      'name': 'Frozen Food',
      'nameAr': 'أغذية مجمدة',
      'vendorType': 'supermarket',
    },
    {
      'name': 'Dairy & Eggs',
      'nameAr': 'ألبان وبيض',
      'vendorType': 'supermarket',
    },
    {'name': 'Milk', 'nameAr': 'حليب', 'vendorType': 'supermarket'},
    {'name': 'Beverages', 'nameAr': 'مشروبات', 'vendorType': 'supermarket'},
    {
      'name': 'Snacks & Chocolate',
      'nameAr': 'وجبات خفيفة وشوكولاتة',
      'vendorType': 'supermarket',
    },
    {'name': 'Ice Cream', 'nameAr': 'آيس كريم', 'vendorType': 'supermarket'},
    {
      'name': 'Condiments',
      'nameAr': 'التوابل والصلصات',
      'vendorType': 'supermarket',
    },
    {
      'name': 'Healthy & Special Diet',
      'nameAr': 'أكل صحي ونظام خاص',
      'vendorType': 'supermarket',
    },
    {
      'name': 'Coffee & Tea',
      'nameAr': 'قهوة وشاي',
      'vendorType': 'supermarket',
    },
    {
      'name': 'Cooking & Baking',
      'nameAr': 'طبخ وخبيز',
      'vendorType': 'supermarket',
    },
    {'name': 'Breakfast Food', 'nameAr': 'فطور', 'vendorType': 'supermarket'},
    {
      'name': 'Canned & Jarred',
      'nameAr': 'معلبات وبرطبنات',
      'vendorType': 'supermarket',
    },
    {
      'name': 'Cleaning & Laundry',
      'nameAr': 'منظفات وغسيل',
      'vendorType': 'supermarket',
    },
    {
      'name': 'Paper & Plastic',
      'nameAr': 'ورق وبلاستيك',
      'vendorType': 'supermarket',
    },
    {
      'name': 'Household Essentials',
      'nameAr': 'مستلزمات منزلية',
      'vendorType': 'supermarket',
    },
    {
      'name': 'Personal Care',
      'nameAr': 'عناية شخصية',
      'vendorType': 'supermarket',
    },
    {'name': 'Beauty', 'nameAr': 'جمال', 'vendorType': 'supermarket'},
    {
      'name': 'Baby Corner',
      'nameAr': 'ركن الأطفال',
      'vendorType': 'supermarket',
    },
    {
      'name': 'Pharma & Wellness',
      'nameAr': 'صيدلية وصحة',
      'vendorType': 'supermarket',
    },
    {
      'name': 'Pet Care',
      'nameAr': 'رعاية الحيوانات الأليفة',
      'vendorType': 'supermarket',
    },
    {
      'name': 'Stationery & Games',
      'nameAr': 'قرطاسية وألعاب',
      'vendorType': 'supermarket',
    },
    {
      'name': 'Electronics',
      'nameAr': 'إلكترونيات',
      'vendorType': 'supermarket',
    },
  ];

  static final List<Map<String, String>> _defaultPharmacy = [
    {
      'name': 'Prescription Medicines',
      'nameAr': 'أدوية بوصفة طبية',
      'vendorType': 'pharmacy',
    },
    {
      'name': 'OTC Medicines',
      'nameAr': 'أدوية بدون وصفة',
      'vendorType': 'pharmacy',
    },
    {
      'name': 'Vitamins & Supplements',
      'nameAr': 'فيتامينات ومكملات',
      'vendorType': 'pharmacy',
    },
    {
      'name': 'Personal Care',
      'nameAr': 'عناية شخصية',
      'vendorType': 'pharmacy',
    },
    {'name': 'Baby Care', 'nameAr': 'رعاية الأطفال', 'vendorType': 'pharmacy'},
    {
      'name': 'Medical Devices',
      'nameAr': 'أجهزة طبية',
      'vendorType': 'pharmacy',
    },
    {'name': 'First Aid', 'nameAr': 'إسعافات أولية', 'vendorType': 'pharmacy'},
    {
      'name': 'Cosmetics & Skincare',
      'nameAr': 'مستحضرات تجميل وعناية بالبشرة',
      'vendorType': 'pharmacy',
    },
    {'name': 'Other', 'nameAr': 'أخرى', 'vendorType': 'pharmacy'},
  ];
}
