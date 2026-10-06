import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:z_speed/features/cart/model/cart_item.dart';
import 'package:injectable/injectable.dart' hide Order;

/// Firestore-backed cart persistence at `carts/{userId}/items/{cartItemId}`.
///
/// Supports:
/// - Real-time cart synchronization via streams
/// - Automatic merge on duplicate items (by menuItemId)
/// - Cart migration from local to Firestore on login
@lazySingleton
class CartFirebaseDatasource {
  final FirebaseFirestore _db;

  CartFirebaseDatasource({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _itemsRef(String userId) {
    return _db.collection('carts').doc(userId).collection('items');
  }

  /// Stream all cart items for a user (real-time updates)
  Stream<List<CartItem>> streamItems(String userId) {
    return _itemsRef(userId).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => CartItem.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Get all cart items (one-shot read)
  Future<List<CartItem>> getItems(String userId) async {
    final snapshot = await _itemsRef(userId).get();
    return snapshot.docs
        .map((doc) => CartItem.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Add item or merge quantities if item with same menuItemId and selectedVariantName exists
  Future<void> addItem(String userId, CartItem item) async {
    final existingQuery = await _itemsRef(userId)
        .where('menuItemId', isEqualTo: item.menuItemId)
        .get();

    CartItem? existingItem;
    DocumentSnapshot? existingDoc;

    for (final doc in existingQuery.docs) {
      final cartItem = CartItem.fromMap(doc.data(), doc.id);
      if (cartItem.selectedVariantName == item.selectedVariantName) {
        existingItem = cartItem;
        existingDoc = doc;
        break;
      }
    }

    if (existingItem != null && existingDoc != null) {
      // Item already exists, merge quantities
      final newQuantity = existingItem.quantity + item.quantity;
      final newItemTotal =
          (existingItem.unitPrice * newQuantity) + existingItem.addonsTotal;

      await _itemsRef(userId).doc(existingDoc.id).update({
        'quantity': newQuantity,
        'itemTotal': newItemTotal,
        'addedAt': FieldValue.serverTimestamp(),
      });
    } else {
      // New item, add it
      await _itemsRef(userId).doc(item.id).set(item.toMap());
    }
  }

  /// Update item quantity
  Future<void> updateQuantity(
      String userId, String itemId, double newQuantity) async {
    if (newQuantity <= 0) {
      await removeItem(userId, itemId);
      return;
    }

    final doc = await _itemsRef(userId).doc(itemId).get();
    if (!doc.exists) return;

    final item = CartItem.fromMap(doc.data()!, doc.id);
    final newItemTotal = (item.unitPrice * newQuantity) + item.addonsTotal;

    await _itemsRef(userId).doc(itemId).update({
      'quantity': newQuantity,
      'itemTotal': newItemTotal,
    });
  }

  /// Increment item quantity (using CartItem logic)
  Future<void> incrementQuantity(String userId, String itemId) async {
    final doc = await _itemsRef(userId).doc(itemId).get();
    if (!doc.exists) return;

    final item = CartItem.fromMap(doc.data()!, doc.id);
    final updatedItem = item.increaseQuantity();

    await _itemsRef(userId).doc(itemId).update({
      'quantity': updatedItem.quantity,
      'itemTotal': updatedItem.itemTotal,
    });
  }

  /// Decrement item quantity (using CartItem logic)
  Future<void> decrementQuantity(String userId, String itemId) async {
    final doc = await _itemsRef(userId).doc(itemId).get();
    if (!doc.exists) return;

    final item = CartItem.fromMap(doc.data()!, doc.id);
    final updatedItem = item.decreaseQuantity();

    // If quantity didn't change, item is at minimum — remove it
    if (updatedItem.quantity == item.quantity) {
      await removeItem(userId, itemId);
    } else {
      await _itemsRef(userId).doc(itemId).update({
        'quantity': updatedItem.quantity,
        'itemTotal': updatedItem.itemTotal,
      });
    }
  }

  /// Remove a specific item
  Future<void> removeItem(String userId, String itemId) async {
    await _itemsRef(userId).doc(itemId).delete();
  }

  /// Clear all cart items
  Future<void> clearAll(String userId) async {
    final batch = _db.batch();
    final snapshot = await _itemsRef(userId).get();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  /// Update unit price and item total for an existing cart item
  Future<void> updateItemPrice(
      String userId, String itemId, double newUnitPrice, double newItemTotal) async {
    await _itemsRef(userId).doc(itemId).update({
      'unitPrice': newUnitPrice,
      'itemTotal': newItemTotal,
    });
  }

  /// Check if an item exists in cart
  Future<bool> contains(String userId, String itemId) async {
    final doc = await _itemsRef(userId).doc(itemId).get();
    return doc.exists;
  }

  /// Merge local cart items into Firestore cart (called on login)
  ///
  /// Strategy: For each local item:
  /// - If exists in Firestore (same menuItemId and selectedVariantName): keep Firestore version (it's newer)
  /// - If not in Firestore: add it
  Future<void> mergeLocalCart(String userId, List<CartItem> localItems) async {
    if (localItems.isEmpty) return;

    for (final localItem in localItems) {
      // Check if item already exists in Firestore
      final existingQuery = await _itemsRef(userId)
          .where('menuItemId', isEqualTo: localItem.menuItemId)
          .get();

      bool exists = false;
      for (final doc in existingQuery.docs) {
        final cartItem = CartItem.fromMap(doc.data(), doc.id);
        if (cartItem.selectedVariantName == localItem.selectedVariantName) {
          exists = true;
          break;
        }
      }

      if (!exists) {
        // Item doesn't exist in Firestore, add it
        await _itemsRef(userId).doc(localItem.id).set(localItem.toMap());
      }
      // If exists, keep Firestore version (don't overwrite)
    }
  }

  /// Get the restaurant ID from cart metadata (if any items exist)
  Future<String?> getRestaurantId(String userId) async {
    final snapshot = await _itemsRef(userId).limit(1).get();
    if (snapshot.docs.isEmpty) return null;

    final firstItem =
        CartItem.fromMap(snapshot.docs.first.data(), snapshot.docs.first.id);
    return firstItem.restaurantId;
  }
}
