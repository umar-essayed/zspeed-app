import 'dart:developer';

import 'package:rxdart/rxdart.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_database/firebase_database.dart';
import 'package:z_speed/core/enums/driver_enums.dart';
import 'package:z_speed/features/driver/model/delivery_request.dart';
import 'package:z_speed/features/driver/model/driver_profile.dart';
import 'package:z_speed/features/driver/model/order_driver.dart';
import 'package:z_speed/features/driver/model/wallet_transaction.dart';
import 'package:z_speed/features/order/model/order.dart';
import 'package:dart_geohash/dart_geohash.dart';
import 'package:injectable/injectable.dart' hide Order;

/// Firebase datasource for driver-related operations.
///
/// Handles all Firestore CRUD operations for:
/// - Driver profiles
/// - Delivery requests
/// - Order-driver assignments
/// - Wallet transactions
/// - Driver active/history orders
@lazySingleton
class DriverFirebaseDatasource {
  final FirebaseFirestore _firestore;

  DriverFirebaseDatasource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // ===== Driver Profile Operations =====

  /// Get driver profile by user ID.
  Future<DriverProfile?> getDriverProfile(String userId) async {
    final doc = await _firestore.collection('driverProfiles').doc(userId).get();
    if (!doc.exists) return null;
    return DriverProfile.fromMap(doc.data()!, doc.id);
  }

  /// Stream driver profile by user ID.
  Stream<DriverProfile?> streamDriverProfile(String userId) {
    return _firestore
        .collection('driverProfiles')
        .doc(userId)
        .snapshots()
        .map(
          (doc) =>
              doc.exists ? DriverProfile.fromMap(doc.data()!, doc.id) : null,
        );
  }

  /// Update driver profile fields.
  Future<void> updateDriverProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore
        .collection('driverProfiles')
        .doc(userId)
        .set(data, SetOptions(merge: true));
  }

  /// Update driver status (online/offline/busy).
  Future<void> updateDriverStatus(String userId, DriverStatus status) async {
    await _firestore.collection('driverProfiles').doc(userId).set({
      'userId': userId,
      'status': status.key,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Phase 10: Clean up RTDB when going offline
    if (status == DriverStatus.offline) {
      await FirebaseDatabase.instance.ref('active_drivers/$userId').remove();
    }
  }

  /// Update driver's current GPS location targeting Firebase RTDB and Firestore.
  Future<void> updateDriverLocation(
    String userId,
    double lat,
    double lng,
  ) async {
    final geohasher = GeoHasher();
    // Note: dart_geohash uses (longitude, latitude)
    final hash = geohasher.encode(lng, lat);

    // Phase 10: Use Realtime Database for high-frequency location pinging
    final dbRef = FirebaseDatabase.instance.ref('active_drivers/$userId');
    await dbRef.set({
      'currentLat': lat,
      'currentLng': lng,
      'geohash': hash,
      'lastPingAt': ServerValue.timestamp,
    });

    // Also persist to Firestore so the driver's own profile stream reflects the location
    await _firestore.collection('driverProfiles').doc(userId).set({
      'currentLat': lat,
      'currentLng': lng,
      'geohash': hash,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Create or ensure a driver profile document exists.
  Future<void> ensureDriverProfile(String userId) async {
    final doc = await _firestore.collection('driverProfiles').doc(userId).get();
    if (!doc.exists) {
      // Pull display name from the users collection so admin/settlement
      // pages show real names instead of raw user IDs.
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final name = userDoc.data()?['name'] as String? ?? '';

      await _firestore.collection('driverProfiles').doc(userId).set({
        'userId': userId,
        'name': name,
        'status': 'offline',
        'rating': 0.0,
        'ratingCount': 0,
        'totalTrips': 0,
        'totalEarnings': 0.0,
        'acceptanceRate': 1.0,
        'totalAccepted': 0,
        'totalRejected': 0,
        'walletBalance': 0.0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      // Self-healing: if document exists but is missing the 'name' field,
      // pull it from the users collection and update it.
      final data = doc.data();
      if (data == null || (data['name'] as String? ?? '').isEmpty) {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        final name = userDoc.data()?['name'] as String? ?? '';
        if (name.isNotEmpty) {
          await _firestore.collection('driverProfiles').doc(userId).update({
            'name': name,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    }
  }

  // ===== Available Drivers (Vendor Side) =====

  /// Stream all online drivers for vendor to assign.
  ///
  /// Returns drivers where status == 'online'.
  /// Vendor-side filtering by distance is done in ViewModel.
  Stream<List<DriverProfile>> streamOnlineDrivers() {
    // Phase 10: Read base profiles from Firestore, enriched with name from users collection
    final profilesStream = _firestore
        .collection('driverProfiles')
        .where('status', whereIn: const ['online', 'busy'])
        .snapshots()
        .asyncMap((snapshot) async {
          log(
            '[RESTAURANT] driverProfiles online query → ${snapshot.docs.length} docs',
          );
          final profiles = <DriverProfile>[];
          for (final doc in snapshot.docs) {
            var profile = DriverProfile.fromMap(doc.data(), doc.id);
            log(
              '[RESTAURANT] driver doc: id=${doc.id} userId=${profile.userId} status=${profile.status}',
            );
            if (profile.name.isEmpty) {
              final userDoc = await _firestore
                  .collection('users')
                  .doc(profile.userId)
                  .get();
              if (userDoc.exists) {
                profile = profile.copyWith(
                  name: userDoc.data()?['name'] as String? ?? '',
                );
                log(
                  '[RESTAURANT] fetched name="${profile.name}" for userId=${profile.userId}',
                );
              } else {
                log('[RESTAURANT] WARNING: users/${profile.userId} not found');
              }
            }
            profiles.add(profile);
          }
          return profiles;
        });

    // Phase 10: Read high-frequency locations from RTDB
    final locationStream = FirebaseDatabase.instance
        .ref('active_drivers')
        .onValue;

    // Convert RTDB stream to nullable so we can use startWith(null)
    final locationOrNullStream = locationStream
        .map<DatabaseEvent?>((e) => e)
        .startWith(null);

    return Rx.combineLatest2(profilesStream, locationOrNullStream, (
      List<DriverProfile> profiles,
      DatabaseEvent? event,
    ) {
      log(
        '[RESTAURANT] combineLatest2 fired: ${profiles.length} profiles, RTDB event=${event == null ? "null" : (event.snapshot.value == null ? "no data" : "has data")}',
      );
      if (event == null || event.snapshot.value == null) {
        log(
          '[RESTAURANT] No RTDB locations → returning ${profiles.length} profiles as-is',
        );
        return profiles;
      }
      final val = event.snapshot.value;
      if (val is! Map) {
        return profiles;
      }
      final Map<dynamic, dynamic> locations = Map<dynamic, dynamic>.from(val);
      log('[RESTAURANT] RTDB active_drivers keys: ${locations.keys.toList()}');

      return profiles.map((profile) {
        final driverLoc = locations[profile.userId];
        if (driverLoc != null) {
          log(
            '[RESTAURANT] matched RTDB location for ${profile.userId}: lat=${driverLoc['currentLat']} lng=${driverLoc['currentLng']}',
          );
          return profile.copyWith(
            currentLat: (driverLoc['currentLat'] as num?)?.toDouble(),
            currentLng: (driverLoc['currentLng'] as num?)?.toDouble(),
            geohash: driverLoc['geohash'] as String?,
          );
        }
        log('[RESTAURANT] NO RTDB location for ${profile.userId}');
        return profile;
      }).toList();
    });
  }

  // ===== Delivery Requests (Driver Receives) =====

  /// Create a delivery request for a driver.
  ///
  /// Uses top-level `deliveryRequests` collection so any authenticated
  /// user (restaurant) can create requests for any driver.
  Future<void> createDeliveryRequest(
    String driverId,
    DeliveryRequest request,
  ) async {
    await _firestore
        .collection('deliveryRequests')
        .doc(request.id)
        .set(request.toMap());
  }

  /// Stream pending delivery requests for a driver.
  ///
  /// Driver sees these in real-time on their dashboard.
  Stream<List<DeliveryRequest>> streamPendingRequests(String driverId) {
    return _firestore
        .collection('deliveryRequests')
        .where('driverId', isEqualTo: driverId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          log(
            '[DRIVER] streamPendingRequests for driverId=$driverId → ${snapshot.docs.length} docs',
          );
          for (final doc in snapshot.docs) {
            log('[DRIVER]   request id=${doc.id} data=${doc.data()}');
          }
          return snapshot.docs
              .map((doc) => DeliveryRequest.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  /// Update delivery request status (accept/reject/expire).
  Future<void> updateRequestStatus(
    String driverId,
    String requestId,
    String status, {
    String? rejectionReason,
  }) async {
    final data = <String, dynamic>{'status': status};
    if (rejectionReason != null) {
      data['rejectionReason'] = rejectionReason;
    }

    await _firestore
        .collection('deliveryRequests')
        .doc(requestId)
        .set(data, SetOptions(merge: true));
  }

  /// Get delivery request by ID.
  Future<DeliveryRequest?> getDeliveryRequest(String requestId) async {
    final doc = await _firestore
        .collection('deliveryRequests')
        .doc(requestId)
        .get();
    if (!doc.exists) return null;
    return DeliveryRequest.fromMap(doc.data()!, doc.id);
  }

  /// Mark the delivery request for this order as delivered.
  ///
  /// Queries the top-level deliveryRequests collection by orderId + driverId
  /// and updates the first matching document's status to 'delivered'.
  /// This triggers the Cloud Function to finalize the order (set deliveredAt,
  /// write to ledger, etc.). Returns silently if no matching request exists.
  Future<void> markDeliveryRequestAsDelivered(
    String orderId,
    String driverId,
  ) async {
    final snapshot = await _firestore
        .collection('deliveryRequests')
        .where('orderId', isEqualTo: orderId)
        .where('driverId', isEqualTo: driverId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return;
    await snapshot.docs.first.reference.update({'status': 'delivered'});
  }

  /// Update the main order document when a driver accepts the request.
  Future<void> updateMainOrderStatusToAssigned(
    String orderId,
    String driverId,
  ) async {
    await _firestore.collection('orders').doc(orderId).update({
      'driverId': driverId,
      'driverIds': FieldValue.arrayUnion([driverId]),
      'status': 'driverAssigned',
      'driverAssignedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update the main order document status.
  Future<void> updateMainOrderStatus(String orderId, String status) async {
    await _firestore.collection('orders').doc(orderId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ===== Order-Driver Assignment =====

  /// Assign a driver to an order (create OrderDriver document).
  ///
  /// Creates a document in orders/{orderId}/orderDrivers/{driverUserId}.
  Future<void> assignDriverToOrder(
    String orderId,
    OrderDriver orderDriver,
  ) async {
    await _firestore
        .collection('orders')
        .doc(orderId)
        .collection('orderDrivers')
        .doc(orderDriver.driverUserId)
        .set(orderDriver.toMap());
  }

  /// Stream all drivers assigned to an order.
  ///
  /// Returns all OrderDriver docs for a given order.
  Stream<List<OrderDriver>> streamOrderDrivers(String orderId) {
    return _firestore
        .collection('orders')
        .doc(orderId)
        .collection('orderDrivers')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => OrderDriver.fromMap(doc.data()))
              .toList(),
        );
  }

  /// Update order-driver assignment status and fields.
  ///
  /// Used for marking pickup, delivery, updating location, etc.
  Future<void> updateOrderDriverStatus(
    String orderId,
    String driverUserId,
    Map<String, dynamic> data,
  ) async {
    final mergedData = Map<String, dynamic>.from(data);
    if (!mergedData.containsKey('driverUserId')) {
      mergedData['driverUserId'] = driverUserId;
    }

    await _firestore
        .collection('orders')
        .doc(orderId)
        .collection('orderDrivers')
        .doc(driverUserId)
        .set(mergedData, SetOptions(merge: true));
  }

  /// Cancel a driver assignment from the restaurant side.
  ///
  /// Updates both the OrderDriver record and the DeliveryRequest
  /// documents matching orderId and driverUserId to 'cancelled' status.
  Future<void> cancelDriverAssignment(
    String orderId,
    String driverUserId,
  ) async {
    final requestsSnapshot = await _firestore
        .collection('deliveryRequests')
        .where('orderId', isEqualTo: orderId)
        .where('driverId', isEqualTo: driverUserId)
        .where('status', isEqualTo: 'pending')
        .get();

    final batch = _firestore.batch();

    // 1. Mark OrderDriver as cancelled — set+merge so it's safe even if missing
    final orderDriverRef = _firestore
        .collection('orders')
        .doc(orderId)
        .collection('orderDrivers')
        .doc(driverUserId);
    batch.set(orderDriverRef, {
      'status': 'cancelled',
      'driverUserId': driverUserId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // 2. Mark matching DeliveryRequests as cancelled
    for (final doc in requestsSnapshot.docs) {
      batch.update(doc.reference, {
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  // ===== Wallet Operations =====

  /// Add a wallet transaction (credit or debit).
  Future<void> addWalletTransaction(WalletTransaction transaction) async {
    await _firestore
        .collection('driverWalletTransactions')
        .doc(transaction.id)
        .set(transaction.toMap());
  }

  /// Update driver's wallet balance.
  Future<void> updateWalletBalance(String driverId, double newBalance) async {
    await _firestore.collection('driverProfiles').doc(driverId).update({
      'walletBalance': newBalance,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Stream wallet transactions for a driver.
  ///
  /// Returns all transactions for the driver ordered by creation date.
  Stream<List<WalletTransaction>> streamDriverTransactions(String driverId) {
    return _firestore
        .collection('driverWalletTransactions')
        .where('driverId', isEqualTo: driverId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => WalletTransaction.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  /// Confirm a wallet payout (driver received payment).
  Future<void> confirmWalletPayout(String transactionId) async {
    await _firestore
        .collection('driverWalletTransactions')
        .doc(transactionId)
        .update({
          'confirmedByDriver': true,
          'confirmedAt': FieldValue.serverTimestamp(),
          'status': 'confirmed',
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  /// Reset driver wallet balance to zero after settlement.
  Future<void> resetWalletBalance(String driverId) async {
    await _firestore.collection('driverProfiles').doc(driverId).update({
      'walletBalance': 0.0,
      'isLimitLocked': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ===== Driver Orders =====

  /// Stream driver's active orders (currently being delivered).
  ///
  /// Returns orders where:
  /// - driverIds contains this driver
  /// - status in [accepted, preparing, ready, driverAssigned, pickedUp, onTheWay]
  ///
  /// Note: Firestore does NOT allow combining arrayContains with whereIn,
  /// so we query by the `driverIds` array
  /// and filter by status client-side.
  Stream<List<Order>> streamDriverActiveOrders(String driverId) {
    return _firestore
        .collection('orders')
        .where('driverIds', arrayContains: driverId)
        .snapshots()
        .map((snapshot) {
          final activeStatuses = {
            'accepted',
            'preparing',
            'ready',
            'driverAssigned',
            'pickedUp',
            'onTheWay',
          };
          final orders = snapshot.docs
              .where((doc) => activeStatuses.contains(doc.data()['status']))
              .map((doc) => Order.fromMap(doc.data(), doc.id))
              .toList();
          orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return orders;
        });
  }

  /// Stream driver's order history (completed/cancelled).
  ///
  /// Returns orders where:
  /// - driverIds contains this driver
  /// - status in [delivered, cancelled]
  Stream<List<Order>> streamDriverOrderHistory(String driverId) {
    return _firestore
        .collection('orders')
        .where('driverIds', arrayContains: driverId)
        .snapshots()
        .map((snapshot) {
          final historyStatuses = {'delivered', 'cancelled'};
          final orders = snapshot.docs
              .where((doc) => historyStatuses.contains(doc.data()['status']))
              .map((doc) => Order.fromMap(doc.data(), doc.id))
              .toList();
          orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return orders;
        });
  }

  // ===== Helper: Update Driver Acceptance Rate =====

  /// Increment totalAccepted and recalculate acceptanceRate.
  Future<void> incrementAccepted(String driverId) async {
    final docRef = _firestore.collection('driverProfiles').doc(driverId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      final totalAccepted = (data['totalAccepted'] as num? ?? 0).toInt();
      final totalRejected = (data['totalRejected'] as num? ?? 0).toInt();

      final newTotalAccepted = totalAccepted + 1;
      final newRate = newTotalAccepted / (newTotalAccepted + totalRejected);

      transaction.update(docRef, {
        'totalAccepted': newTotalAccepted,
        'acceptanceRate': newRate,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Increment totalRejected and recalculate acceptanceRate.
  Future<void> incrementRejected(String driverId) async {
    final docRef = _firestore.collection('driverProfiles').doc(driverId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      final totalAccepted = (data['totalAccepted'] as num? ?? 0).toInt();
      final totalRejected = (data['totalRejected'] as num? ?? 0).toInt();

      final newTotalRejected = totalRejected + 1;
      final newRate = totalAccepted / (totalAccepted + newTotalRejected);

      transaction.update(docRef, {
        'totalRejected': newTotalRejected,
        'acceptanceRate': newRate,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Update driver earnings and unsettled wallet balance after delivery completion.
  /// Called for ALL payment methods (cash, card, wallet).
  /// For card orders, markDeliveredWithWalletCredit also credits walletBalance —
  /// so we only write totalEarnings + totalTrips here to avoid double-writing.
  Future<void> incrementEarnings(String driverId, double amount) async {
    await _firestore.collection('driverProfiles').doc(driverId).update({
      'totalEarnings': FieldValue.increment(amount),
      'walletBalance': FieldValue.increment(amount),
      'totalTrips': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
