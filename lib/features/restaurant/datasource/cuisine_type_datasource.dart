import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:z_speed/features/restaurant/model/cuisine_type.dart';
import 'package:injectable/injectable.dart' hide Order;

/// Firestore datasource for the global `cuisineTypes` collection.
///
/// Managed by admin. Read by restaurant owners and customers.
@lazySingleton
class CuisineTypeDatasource {
  final FirebaseFirestore _firestore;

  CuisineTypeDatasource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _ref =>
      _firestore.collection('cuisineTypes');

  /// Stream all active cuisine types, ordered by sortOrder.
  Stream<List<CuisineType>> streamAll() {
    return _ref.orderBy('sortOrder').snapshots().map((snap) => snap.docs
        .map((doc) => CuisineType.fromMap(doc.data(), doc.id))
        .toList());
  }

  /// Stream only active cuisine types.
  Stream<List<CuisineType>> streamActive() {
    return _ref
        .where('isActive', isEqualTo: true)
        .orderBy('sortOrder')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => CuisineType.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Get all cuisine types (one-shot).
  Future<List<CuisineType>> getAll() async {
    final snap = await _ref.orderBy('sortOrder').get();
    return snap.docs
        .map((doc) => CuisineType.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Create a new cuisine type. Returns the generated document ID.
  Future<String> create(CuisineType cuisineType) async {
    final docRef = _ref.doc();
    final data = cuisineType
        .copyWith(
          id: docRef.id,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        )
        .toMap();
    await docRef.set(data);
    return docRef.id;
  }

  /// Update an existing cuisine type.
  Future<void> update(CuisineType cuisineType) async {
    final data = cuisineType.copyWith(updatedAt: DateTime.now()).toMap();
    await _ref.doc(cuisineType.id).update(data);
  }

  /// Delete a cuisine type.
  Future<void> delete(String id) async {
    await _ref.doc(id).delete();
  }

  /// Seed initial cuisine types if the collection is empty.
  Future<void> seedIfEmpty() async {
    final snap = await _ref.limit(1).get();
    if (snap.docs.isNotEmpty) return;

    final batch = _firestore.batch();
    final cuisines = _defaultCuisines;
    for (int i = 0; i < cuisines.length; i++) {
      final docRef = _ref.doc();
      final name = cuisines[i]['name']!;
      batch.set(docRef, {
        'name': name,
        'nameAr': cuisines[i]['nameAr'],
        'imageUrl': getCuisineImageUrl(name),
        'sortOrder': i,
        'isActive': true,
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    }
    await batch.commit();
  }

  /// Sync default cuisines — adds any missing ones without touching existing.
  Future<void> syncMissingCuisines() async {
    final snap = await _ref.get();
    final existingNames = snap.docs.map((d) => d.data()['name'] as String).toSet();
    final missing = _defaultCuisines.where((c) => !existingNames.contains(c['name']!)).toList();
    if (missing.isEmpty) return;

    final batch = _firestore.batch();
    final currentMaxOrder = snap.docs.isEmpty
        ? 0
        : snap.docs.map((d) => (d.data()['sortOrder'] as int?) ?? 0).reduce((a, b) => a > b ? a : b) + 1;

    for (int i = 0; i < missing.length; i++) {
      final docRef = _ref.doc();
      final name = missing[i]['name']!;
      batch.set(docRef, {
        'name': name,
        'nameAr': missing[i]['nameAr'],
        'imageUrl': getCuisineImageUrl(name),
        'sortOrder': currentMaxOrder + i,
        'isActive': true,
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    }
    await batch.commit();
  }

  static final List<Map<String, String>> _defaultCuisines = [
    {'name': 'American', 'nameAr': 'أمريكي'},
    {'name': 'Arabic', 'nameAr': 'عربي'},
    {'name': 'Arabic Sweets', 'nameAr': 'حلويات عربية'},
    {'name': 'Asian', 'nameAr': 'آسيوي'},
    {'name': 'Bakery & Pastry', 'nameAr': 'مخبوزات ومعجنات'},
    {'name': 'Beverages', 'nameAr': 'مشروبات'},
    {'name': 'Breakfast', 'nameAr': 'فطور'},
    {'name': 'Burgers', 'nameAr': 'برجر'},
    {'name': 'Cakes', 'nameAr': 'كيك'},
    {'name': 'Chicken', 'nameAr': 'دجاج'},
    {'name': 'Chinese', 'nameAr': 'صيني'},
    {'name': 'Chocolate', 'nameAr': 'شوكولاتة'},
    {'name': 'Coffee & Tea', 'nameAr': 'قهوة وشاي'},
    {'name': 'Crepes', 'nameAr': 'كريب'},
    {'name': 'Desserts', 'nameAr': 'حلويات'},
    {'name': 'Donuts', 'nameAr': 'دونات'},
    {'name': 'Egyptian', 'nameAr': 'مصري'},
    {'name': 'Fast Food', 'nameAr': 'وجبات سريعة'},
    {'name': 'Fish & Seafood', 'nameAr': 'أسماك ومأكولات بحرية'},
    {'name': 'Foul & Falafel', 'nameAr': 'فول وفلافل'},
    {'name': 'Koshari', 'nameAr': 'كشري'},
    {'name': 'Fried Chicken', 'nameAr': 'دجاج مقلي'},
    {'name': 'Grills', 'nameAr': 'مشويات'},
    {'name': 'Healthy', 'nameAr': 'أكل صحي'},
    {'name': 'Ice Cream', 'nameAr': 'آيس كريم'},
    {'name': 'International', 'nameAr': 'عالمي'},
    {'name': 'Italian', 'nameAr': 'إيطالي'},
    {'name': 'Japanese', 'nameAr': 'ياباني'},
    {'name': 'Juices', 'nameAr': 'عصائر'},
    {'name': 'Lebanese', 'nameAr': 'لبناني'},
    {'name': 'Pasta', 'nameAr': 'باستا'},
    {'name': 'Pies', 'nameAr': 'فطائر'},
    {'name': 'Pizza', 'nameAr': 'بيتزا'},
    {'name': 'Salad', 'nameAr': 'سلطات'},
    {'name': 'Sandwiches', 'nameAr': 'ساندويتشات'},
    {'name': 'Shawerma', 'nameAr': 'شاورما'},
    {'name': 'Sushi', 'nameAr': 'سوشي'},
    {'name': 'Syrian', 'nameAr': 'سوري'},
    {'name': 'Waffles', 'nameAr': 'وافل'},
  ];
}
