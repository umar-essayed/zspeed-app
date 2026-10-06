import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_geohash/dart_geohash.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:z_speed/core/enums/user_enums.dart';
import 'package:z_speed/features/restaurant/model/restaurant.dart';
import 'package:injectable/injectable.dart' hide Order;

/// Firestore datasource for restaurant CRUD operations.
///
/// Used by vendors to manage their restaurant profile and by customers
/// to browse restaurants. Collection: `restaurants`
@lazySingleton
class RestaurantFirebaseDatasource {
  final FirebaseFirestore _firestore;

  RestaurantFirebaseDatasource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('vendors');

  // ── Read ───────────────────────────────────────────────────────

  /// Get a restaurant by its document ID.
  Future<Restaurant?> getById(String restaurantId) async {
    final doc = await _collection
        .doc(restaurantId)
        .get(const GetOptions(source: Source.server));
    if (!doc.exists || doc.data() == null) return null;
    return Restaurant.fromMap(doc.data()!, doc.id);
  }

  /// Get the restaurant owned by a vendor.
  Future<Restaurant?> getByOwnerId(String ownerId) async {
    final debugLog = <String, dynamic>{
      'timestamp': FieldValue.serverTimestamp(),
      'ownerId_arg': ownerId,
      'currentUser_uid': FirebaseAuth.instance.currentUser?.uid,
      'currentUser_email': FirebaseAuth.instance.currentUser?.email,
      'has_currentUser': FirebaseAuth.instance.currentUser != null,
      'step': 'initialized_firebase_only',
    };

    void saveDebugLog() {
      _firestore
          .collection('debug_logs')
          .doc(ownerId)
          .set(debugLog)
          .catchError((e) {
        // ignore: avoid_print
        print('[DEBUG_LOG_FAIL] $e');
      });
    }

    saveDebugLog();

    // 1. Query by ownerId field directly (Primary)
    try {
      final snapshot = await _collection.where('ownerId', isEqualTo: ownerId).limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        debugLog['step'] = 'found_by_ownerId_query';
        saveDebugLog();
        return Restaurant.fromMap(doc.data(), doc.id);
      }
    } catch (e) {
      debugLog['query_by_ownerId_error'] = e.toString();
      saveDebugLog();
    }

    // 2. Fallback: try direct fetch by document ID
    try {
      final doc = await _collection
          .doc(ownerId)
          .get(const GetOptions(source: Source.server));
      if (doc.exists && doc.data() != null) {
        debugLog['step'] = 'found_by_doc_id';
        saveDebugLog();
        return Restaurant.fromMap(doc.data()!, doc.id);
      }
    } catch (e) {
      debugLog['doc_id_fetch_error'] = e.toString();
      saveDebugLog();
    }

    debugLog['step'] = 'not_found';
    saveDebugLog();
    return null;
  }

  /// Stream a single restaurant (real-time updates).
  Stream<Restaurant?> streamById(String restaurantId) {
    return _collection.doc(restaurantId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return Restaurant.fromMap(doc.data()!, doc.id);
    });
  }

  /// Stream all approved/active restaurants (for customer browsing).
  Stream<List<Restaurant>> streamActive() {
    // Fetch all active docs then filter client-side:
    // include only docs where vendorType == 'restaurant' OR vendorType is absent (legacy).
    return _collection
        .where('isActive', isEqualTo: true)
        .orderBy('rating', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .where((doc) {
              final vt = doc.data()['vendorType'];
              return vt == null || vt == VendorType.restaurant.key;
            })
            .map((doc) => Restaurant.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Stream active vendors of a specific type (restaurant/supermarket/pharmacy).
  Stream<List<Restaurant>> streamActiveByVendorType(VendorType type) {
    return _collection
        .where('isActive', isEqualTo: true)
        .where('vendorType', isEqualTo: type.key)
        .orderBy('rating', descending: true)
        .snapshots()
        .map((snapshot) {
      // ignore: avoid_print
      print(
          '[DEBUG] streamActiveByVendorType(${type.key}): ${snapshot.docs.length} docs');
      for (final doc in snapshot.docs) {
        final d = doc.data();
        // ignore: avoid_print
        print(
            '[DEBUG]   id=${doc.id} name=${d['name']} vendorType=${d['vendorType']} isActive=${d['isActive']} rating=${d['rating']}');
      }
      return snapshot.docs
          .map((doc) => Restaurant.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // ── Write ──────────────────────────────────────────────────────

  /// Create a new restaurant. Returns the generated document ID.
  Future<String> create(Restaurant restaurant) async {
    final docRef = _collection.doc();
    final geohasher = GeoHasher();
    final hash = geohasher.encode(restaurant.longitude, restaurant.latitude);

    final data = restaurant
        .copyWith(
          id: docRef.id,
          geohash: hash,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        )
        .toMap();
    await docRef.set(data);
    return docRef.id;
  }

  /// Update an existing restaurant.
  Future<void> update(Restaurant restaurant) async {
    final geohasher = GeoHasher();
    final hash = geohasher.encode(restaurant.longitude, restaurant.latitude);

    final data =
        restaurant.copyWith(geohash: hash, updatedAt: DateTime.now()).toMap();
    await _collection.doc(restaurant.id).update(data);
  }

  /// Update specific fields of a restaurant (partial update).
  Future<void> updateFields(
      String restaurantId, Map<String, dynamic> fields) async {
    fields['updatedAt'] = Timestamp.fromDate(DateTime.now());
    await _collection.doc(restaurantId).update(fields);
  }

  /// Toggle restaurant open/closed status.
  Future<void> toggleOpen(String restaurantId, bool isOpen) async {
    await updateFields(restaurantId, {'isOpen': isOpen});
  }

  /// Delete a restaurant (admin only).
  Future<void> delete(String restaurantId) async {
    await _collection.doc(restaurantId).delete();
  }
}
