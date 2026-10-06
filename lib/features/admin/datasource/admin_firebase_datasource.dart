import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:z_speed/core/enums/enums.dart';
import 'package:z_speed/features/auth/model/user_model.dart';
import 'package:z_speed/features/order/model/order.dart';
import 'package:z_speed/features/restaurant/model/restaurant.dart';
import 'package:z_speed/firebase_options.dart';
import 'package:injectable/injectable.dart' hide Order;

/// Firestore datasource for admin dashboard and management features.
///
/// Provides raw Firestore queries for:
/// - Dashboard stats (user counts, order counts, revenue, etc.)
/// - User management (CRUD operations, filtering)
/// - Order management (view, update status, cancel)
/// - Restaurant/vendor management (view, update status)
/// - Analytics (revenue trends, user growth, order volume)
@lazySingleton
class AdminFirebaseDatasource {
  final FirebaseFirestore _db;

  AdminFirebaseDatasource({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  // ── Dashboard Stats ────────────────────────────────────────────────────────

  /// Count total users, optionally filtered by type.
  Future<int> countUsers({UserType? type}) async {
    Query<Map<String, dynamic>> query = _db.collection('users');
    if (type != null) {
      query = query.where('type', isEqualTo: type.name);
    }
    final snapshot = await query.count().get();
    return snapshot.count ?? 0;
  }

  /// Count total orders, optionally filtered by status and/or date range.
  Future<int> countOrders({
    OrderStatus? status,
    DateTimeRange? range,
  }) async {
    Query<Map<String, dynamic>> query = _db.collection('orders');
    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }
    if (range != null) {
      query = query
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(range.start))
          .where('createdAt',
              isLessThanOrEqualTo: Timestamp.fromDate(range.end));
    }
    final snapshot = await query.count().get();
    return snapshot.count ?? 0;
  }

  /// Count total restaurants, optionally filtered by status.
  Future<int> countRestaurants({RestaurantStatus? status}) async {
    Query<Map<String, dynamic>> query = _db.collection('vendors');
    if (status != null) {
      // Map RestaurantStatus to isActive boolean
      final isActive = status == RestaurantStatus.active;
      query = query.where('isActive', isEqualTo: isActive);
    }
    final snapshot = await query.count().get();
    return snapshot.count ?? 0;
  }

  /// Calculate total revenue from completed payments, optionally within a date range.
  Future<double> calculateRevenue({DateTimeRange? range}) async {
    var query =
        _db.collection('payments').where('status', isEqualTo: 'completed');

    if (range != null) {
      query = query
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(range.start))
          .where('createdAt',
              isLessThanOrEqualTo: Timestamp.fromDate(range.end));
    }

    final snapshot = await query.get();
    double total = 0.0;
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final amount = data['amount'] as num?;
      if (amount != null) {
        total += amount.toDouble();
      }
    }
    return total;
  }

  /// Count pending driver/vendor applications.
  Future<int> countPendingApplications() async {
    final snapshot = await _db
        .collection('applications')
        .where('status', whereIn: ['pending', 'underReview'])
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  // ── User Management ────────────────────────────────────────────────────────

  /// Fetch users, optionally filtered by type, status, with a limit.
  Future<(List<AppUser>, DocumentSnapshot?)> getUsers({
    UserType? type,
    UserStatus? status,
    DocumentSnapshot? startAfter,
    int limit = 20,
  }) async {
    var query =
        _db.collection('users').orderBy(FieldPath.documentId).limit(limit);

    if (type != null) {
      query = query.where('type', isEqualTo: type.name);
    }
    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    final users = snapshot.docs
        .map((doc) => AppUser.fromMap(doc.data(), doc.id))
        .toList();
    final lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
    return (users, lastDoc);
  }

  /// Stream users in real-time, optionally filtered by type.
  Stream<List<AppUser>> streamUsers({UserType? type}) {
    var query = _db.collection('users').limit(100);
    if (type != null) {
      query = query.where('type', isEqualTo: type.name);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => AppUser.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Update a user's status.
  Future<void> updateUserStatus(String userId, UserStatus status) async {
    await _db.collection('users').doc(userId).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update a user's type/role.
  Future<void> updateUserType(String userId, UserType type) async {
    await _db.collection('users').doc(userId).update({
      'type': type.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete a user (soft delete by setting status to inactive).
  Future<void> deleteUser(String userId) async {
    await _db.collection('users').doc(userId).update({
      'status': UserStatus.inactive.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Order Management ───────────────────────────────────────────────────────

  /// Fetch orders, optionally filtered by status, date range, with a limit.
  Future<(List<Order>, DocumentSnapshot?)> getOrders({
    OrderStatus? status,
    DateTimeRange? range,
    DocumentSnapshot? startAfter,
    int limit = 20,
  }) async {
    var query = _db
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }
    if (range != null) {
      query = query
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(range.start))
          .where('createdAt',
              isLessThanOrEqualTo: Timestamp.fromDate(range.end));
    }
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    final orders =
        snapshot.docs.map((doc) => Order.fromMap(doc.data(), doc.id)).toList();
    final lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
    return (orders, lastDoc);
  }

  /// Stream orders in real-time, optionally filtered by status.
  Stream<List<Order>> streamOrders({OrderStatus? status}) {
    var query = _db
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .limit(100);

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Order.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Update an order's status.
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    final updates = <String, dynamic>{
      'status': status.name,
      'statusUpdatedBy': 'admin',
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (status == OrderStatus.cancelled) {
      updates['cancelledBy'] = 'admin';
      updates['cancelledAt'] = FieldValue.serverTimestamp();
    }
    await _db.collection('orders').doc(orderId).update(updates);
  }

  /// Cancel an order with an optional reason.
  Future<void> cancelOrder(String orderId, {String? reason}) async {
    final updates = <String, dynamic>{
      'status': OrderStatus.cancelled.name,
      'cancelledBy': 'admin',
      'statusUpdatedBy': 'admin',
      'cancelledAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (reason != null) {
      updates['cancellationReason'] = reason;
    }
    await _db.collection('orders').doc(orderId).update(updates);
  }

  // ── Restaurant/Vendor Management ───────────────────────────────────────────

  /// Fetch vendors (restaurants, supermarkets, etc.), optionally filtered by status and type, with a limit.
  Future<(List<Restaurant>, DocumentSnapshot?)> getVendors({
    RestaurantStatus? status,
    VendorType? vendorType,
    DocumentSnapshot? startAfter,
    int limit = 20,
  }) async {
    var query = _db
        .collection('vendors')
        .orderBy(FieldPath.documentId)
        .limit(limit);

    if (status != null) {
      // Map RestaurantStatus to isActive boolean
      final isActive = status == RestaurantStatus.active;
      query = query.where('isActive', isEqualTo: isActive);
    }
    if (vendorType != null) {
      query = query.where('vendorType', isEqualTo: vendorType.key);
    }
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    final vendors = snapshot.docs
        .map((doc) => Restaurant.fromMap(doc.data(), doc.id))
        .toList();
    final lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
    return (vendors, lastDoc);
  }

  /// Stream restaurants in real-time.
  Stream<List<Restaurant>> streamRestaurants() {
    return _db.collection('vendors').limit(100).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Restaurant.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Update a restaurant's status.
  Future<void> updateRestaurantStatus(
    String restaurantId,
    RestaurantStatus status,
  ) async {
    // Map RestaurantStatus to isActive boolean
    final isActive = status == RestaurantStatus.active;
    final statusStr = status.name; // 'active', 'pending', 'suspended'

    await _db.collection('vendors').doc(restaurantId).update({
      'isActive': isActive,
      'status': statusStr,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateRestaurantVendorType(
    String restaurantId,
    VendorType vendorType,
  ) async {
    await _db.collection('vendors').doc(restaurantId).update({
      'vendorType': vendorType.key,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateRestaurantPriority(
    String restaurantId,
    int priority,
  ) async {
    await _db.collection('vendors').doc(restaurantId).update({
      'priority': priority,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update a restaurant's details.
  Future<void> updateRestaurant(Restaurant restaurant) async {
    await _db.collection('vendors').doc(restaurant.id).update({
      ...restaurant.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Create a new vendor/restaurant document in Firestore.
  Future<void> createVendor(Restaurant restaurant) async {
    final docRef = _db.collection('vendors').doc();
    final data = restaurant.copyWith(id: docRef.id).toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await docRef.set(data);
  }

  /// Delete a restaurant (soft-delete: deactivate + set deletedAt timestamp).
  Future<void> deleteRestaurant(String restaurantId) async {
    await _db.collection('vendors').doc(restaurantId).update({
      'isActive': false,
      'deletedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Analytics ──────────────────────────────────────────────────────────────

  /// Get daily revenue within a date range.
  /// Returns a map of date string (YYYY-MM-DD) to revenue amount.
  Future<Map<String, double>> revenueByDay({
    required DateTimeRange range,
  }) async {
    final snapshot = await _db
        .collection('payments')
        .where('status', isEqualTo: 'completed')
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(range.start))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(range.end))
        .get();

    final revenueMap = <String, double>{};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
      final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

      if (createdAt != null) {
        final dateKey =
            '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
        revenueMap[dateKey] = (revenueMap[dateKey] ?? 0.0) + amount;
      }
    }

    return revenueMap;
  }

  /// Get user counts by type.
  Future<Map<UserType, int>> userCountsByType() async {
    final counts = <UserType, int>{};

    for (final type in UserType.values) {
      final count = await countUsers(type: type);
      counts[type] = count;
    }

    return counts;
  }

  /// Get order counts by status, optionally filtered by date range.
  Future<Map<OrderStatus, int>> orderCountsByStatus(
      {DateTimeRange? range}) async {
    final counts = <OrderStatus, int>{};

    for (final status in OrderStatus.values) {
      final count = await countOrders(status: status, range: range);
      counts[status] = count;
    }

    return counts;
  }

  // ── Name Resolution ────────────────────────────────────────────────────────

  /// Batch-fetch user display names by user IDs.
  ///
  /// Returns a map of userId → displayName.
  /// Unknown IDs are mapped to the raw ID as a fallback.
  Future<Map<String, String>> getUserNamesByIds(Set<String> userIds) async {
    if (userIds.isEmpty) return {};

    final names = <String, String>{};

    // Firestore 'in' queries support max 30 elements at a time
    final chunks = _chunked(userIds.toList(), 30);
    for (final chunk in chunks) {
      final snapshot = await _db
          .collection('users')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final name =
            data['name'] as String? ?? data['email'] as String? ?? doc.id;
        names[doc.id] = name;
      }
    }

    // Fallback for missing user IDs
    for (final id in userIds) {
      names.putIfAbsent(id, () => id);
    }

    return names;
  }

  /// Batch-fetch restaurant names by restaurant IDs.
  ///
  /// Returns a map of restaurantId → name.
  /// Unknown IDs are mapped to the raw ID as a fallback.
  Future<Map<String, String>> getRestaurantNamesByIds(
      Set<String> restaurantIds) async {
    if (restaurantIds.isEmpty) return {};

    final names = <String, String>{};

    final chunks = _chunked(restaurantIds.toList(), 30);
    for (final chunk in chunks) {
      final snapshot = await _db
          .collection('vendors')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final name = data['name'] as String? ?? doc.id;
        names[doc.id] = name;
      }
    }

    // Fallback for missing restaurant IDs
    for (final id in restaurantIds) {
      names.putIfAbsent(id, () => id);
    }

    return names;
  }

  /// Fetch today's order count for a specific restaurant.
  Future<int> countOrdersToday(String restaurantId) async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    final snapshot = await _db
        .collection('orders')
        .where('restaurantId', isEqualTo: restaurantId)
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  /// Calculate total revenue for a specific restaurant.
  Future<double> calculateRestaurantRevenue(String restaurantId) async {
    final snapshot = await _db
        .collection('orders')
        .where('restaurantId', isEqualTo: restaurantId)
        .where('status', isEqualTo: OrderStatus.delivered.name)
        .get();

    double total = 0;
    for (final doc in snapshot.docs) {
      total += (doc.data()['total'] as num?)?.toDouble() ?? 0.0;
    }
    return total;
  }

  // ── Recent Activity ────────────────────────────────────────────────────────

  /// Fetch recent activity for the admin dashboard.
  ///
  /// Merges recent user registrations, recent orders, and recent application
  /// submissions into a single list sorted by timestamp (newest first).
  Future<List<Map<String, dynamic>>> getRecentActivity({int limit = 10}) async {
    final activities = <Map<String, dynamic>>[];

    // Fetch recent users (last 5)
    final usersSnapshot = await _db
        .collection('users')
        .orderBy('createdAt', descending: true)
        .limit(5)
        .get();
    for (final doc in usersSnapshot.docs) {
      final data = doc.data();
      final name =
          data['name'] as String? ?? data['email'] as String? ?? 'Unknown';
      final createdAt = data['createdAt'];
      DateTime? ts;
      if (createdAt is Timestamp) ts = createdAt.toDate();
      if (ts != null) {
        activities.add({
          'type': 'userRegistration',
          'title': 'New User Registration',
          'description': '$name joined the platform',
          'timestamp': ts,
        });
      }
    }

    // Fetch recent delivered orders (last 5)
    final ordersSnapshot = await _db
        .collection('orders')
        .where('status', isEqualTo: OrderStatus.delivered.name)
        .orderBy('createdAt', descending: true)
        .limit(5)
        .get();
    for (final doc in ordersSnapshot.docs) {
      final data = doc.data();
      final orderId = doc.id;
      final createdAt = data['createdAt'];
      DateTime? ts;
      if (createdAt is Timestamp) ts = createdAt.toDate();
      if (ts != null) {
        activities.add({
          'type': 'orderCompleted',
          'title': 'Order Completed',
          'description':
              'Order #${orderId.length > 8 ? orderId.substring(0, 8) : orderId} was delivered',
          'timestamp': ts,
        });
      }
    }

    // Fetch recent applications (last 5)
    final appsSnapshot = await _db
        .collection('applications')
        .orderBy('submittedAt', descending: true)
        .limit(5)
        .get();
    for (final doc in appsSnapshot.docs) {
      final data = doc.data();
      final appType = data['applicationType'] as String? ?? 'driver';
      final status = data['status'] as String? ?? 'pending';
      final submittedAt = data['submittedAt'];
      DateTime? ts;
      if (submittedAt is Timestamp) ts = submittedAt.toDate();
      if (ts != null) {
        if (status == 'approved') {
          activities.add({
            'type': 'restaurantApproved',
            'title':
                '${(appType == 'restaurant' || appType == 'vendor') ? 'Vendor' : 'Driver'} Approved',
            'description':
                'A ${(appType == 'restaurant' || appType == 'vendor') ? 'vendor' : 'driver'} application was approved',
            'timestamp': ts,
          });
        } else {
          activities.add({
            'type': 'applicationSubmitted',
            'title': 'New Application',
            'description':
                'A ${(appType == 'restaurant' || appType == 'vendor') ? 'vendor' : 'driver'} application was submitted',
            'timestamp': ts,
          });
        }
      }
    }

    // Sort by timestamp descending and limit
    activities.sort((a, b) =>
        (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));
    return activities.take(limit).toList();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  // ── Admin User Creation (Super Admin only) ─────────────────────────────────

  /// Create a new admin user with Firebase Auth + Firestore document.
  ///
  /// Uses a secondary [FirebaseApp] so the current super admin session
  /// is not disrupted by `createUserWithEmailAndPassword`.
  Future<void> createAdminUser({
    required String name,
    required String email,
    required String password,
    UserType role = UserType.admin,
  }) async {
    FirebaseApp? secondaryApp;
    try {
      // Initialize a secondary Firebase app to avoid signing out the current user
      try {
        secondaryApp = Firebase.app('adminCreator');
      } catch (_) {
        secondaryApp = await Firebase.initializeApp(
          name: 'adminCreator',
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      // Create the auth account
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;

      // Sign out from secondary app — safe because AuthCubit only listens to
      // FirebaseAuth.instance (the default app), not the secondary app.
      await secondaryAuth.signOut();

      // Write the Firestore user document using the main app's Firestore
      // (superAdmin has write access via Firestore rules).
      final newAdmin = AppUser(
        id: uid,
        name: name,
        email: email,
        type: role,
        status: UserStatus.active,
      );
      await _db.collection('users').doc(uid).set(newAdmin.toMap());
    } catch (e) {
      rethrow;
    }
  }

  /// Split a list into chunks of [size].
  List<List<T>> _chunked<T>(List<T> list, int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < list.length; i += size) {
      chunks.add(
          list.sublist(i, i + size > list.length ? list.length : i + size));
    }
    return chunks;
  }
}
