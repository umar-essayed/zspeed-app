import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:uuid/uuid.dart';
import 'package:z_speed/core/enums/driver_enums.dart';
import 'package:z_speed/core/enums/notification_enums.dart';
import 'package:z_speed/core/enums/order_enums.dart';
import 'package:z_speed/features/order/model/order.dart';
import 'package:z_speed/features/order/model/order_item.dart';
import 'package:injectable/injectable.dart' hide Order;

/// Firestore datasource for order operations.
///
/// Manages:
/// - Order creation (atomic batch write with items subcollection)
/// - Order streaming (real-time status updates)
/// - Order queries (customer orders, restaurant orders)
@lazySingleton
class OrderFirebaseDatasource {
  final FirebaseFirestore _db;

  OrderFirebaseDatasource({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _ordersRef =>
      _db.collection('orders');

  Query<Map<String, dynamic>> _restaurantOrdersQuery(
    String field,
    String restaurantId, {
    List<OrderStatus>? statuses,
  }) {
    Query<Map<String, dynamic>> query = _ordersRef
        .where(field, isEqualTo: restaurantId)
        .orderBy('createdAt', descending: true);

    if (statuses != null && statuses.isNotEmpty) {
      final statusKeys = statuses.map((s) => s.key).toList();
      query = query.where('status', whereIn: statusKeys);
    }

    return query;
  }

  List<Order> _dedupeAndSortOrders(Iterable<Order> orders) {
    final byId = <String, Order>{};
    for (final order in orders) {
      byId[order.id] = order;
    }
    final sorted = byId.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  /// Create a new order (atomic batch write)
  ///
  /// Creates:
  /// 1. orders/{orderId} document
  /// 2. orders/{orderId}/items/{itemId} subcollection documents
  ///
  /// Returns the generated order ID
  Future<String> createOrder(Order order, List<OrderItem> items) async {
    final batch = _db.batch();

    // Generate ID if not provided
    final orderId = order.id.isEmpty ? _ordersRef.doc().id : order.id;

    final orderWithId = order.copyWith(id: orderId);

    // 1. Create order document
    final orderDoc = _ordersRef.doc(orderId);
    batch.set(orderDoc, orderWithId.toMap());

    // 2. Create order items subcollection
    for (final item in items) {
      final itemDoc = orderDoc.collection('items').doc(item.id);
      batch.set(itemDoc, item.toMap());
    }

    await batch.commit();
    return orderId;
  }

  /// Stream a single order (real-time updates)
  Stream<Order?> streamOrder(String orderId) {
    return _ordersRef.doc(orderId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return Order.fromMap(snapshot.data()!, snapshot.id);
    });
  }

  /// Get a single order (one-shot read)
  Future<Order?> getById(String orderId) async {
    final doc = await _ordersRef.doc(orderId).get();
    if (!doc.exists) return null;
    return Order.fromMap(doc.data()!, doc.id);
  }

  /// Stream customer's orders (sorted by createdAt descending)
  Stream<List<Order>> streamCustomerOrders(String customerId) {
    return _ordersRef
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Order.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  /// Get customer's orders (one-shot)
  Future<List<Order>> getCustomerOrders(String customerId) async {
    final snapshot = await _ordersRef
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Order.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Stream restaurant's orders (optionally filtered by status)
  Stream<List<Order>> streamRestaurantOrders(
    String restaurantId, {
    List<OrderStatus>? statuses,
  }) {
    return Stream<List<Order>>.multi((controller) {
      var restaurantOrders = <Order>[];
      var vendorOrders = <Order>[];
      var hasRestaurantSnapshot = false;
      var hasVendorSnapshot = false;

      void emitMerged() {
        if (!hasRestaurantSnapshot || !hasVendorSnapshot) return;
        controller.add(
          _dedupeAndSortOrders([...restaurantOrders, ...vendorOrders]),
        );
      }

      final restaurantSub =
          _restaurantOrdersQuery(
            'restaurantId',
            restaurantId,
            statuses: statuses,
          ).snapshots().listen((snapshot) {
            restaurantOrders = snapshot.docs
                .map((doc) => Order.fromMap(doc.data(), doc.id))
                .toList();
            hasRestaurantSnapshot = true;
            emitMerged();
          }, onError: controller.addError);

      final vendorSub =
          _restaurantOrdersQuery(
            'vendorId',
            restaurantId,
            statuses: statuses,
          ).snapshots().listen((snapshot) {
            vendorOrders = snapshot.docs
                .map((doc) => Order.fromMap(doc.data(), doc.id))
                .toList();
            hasVendorSnapshot = true;
            emitMerged();
          }, onError: controller.addError);

      controller.onCancel = () async {
        await restaurantSub.cancel();
        await vendorSub.cancel();
      };
    });
  }

  /// Get restaurant's orders (one-shot)
  Future<List<Order>> getRestaurantOrders(
    String restaurantId, {
    List<OrderStatus>? statuses,
  }) async {
    final snapshots = await Future.wait([
      _restaurantOrdersQuery(
        'restaurantId',
        restaurantId,
        statuses: statuses,
      ).get(),
      _restaurantOrdersQuery(
        'vendorId',
        restaurantId,
        statuses: statuses,
      ).get(),
    ]);

    return _dedupeAndSortOrders(
      snapshots.expand(
        (snapshot) =>
            snapshot.docs.map((doc) => Order.fromMap(doc.data(), doc.id)),
      ),
    );
  }

  /// Update order status (with timestamp) and notify the customer.
  Future<void> updateStatus(
    String orderId,
    OrderStatus newStatus, {
    String? updatedBy,
  }) async {
    final updateData = <String, dynamic>{
      'status': newStatus.key,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (updatedBy != null && updatedBy.isNotEmpty) {
      updateData['statusUpdatedBy'] = updatedBy;
    }

    // Set appropriate timestamp based on status
    switch (newStatus) {
      case OrderStatus.accepted:
        updateData['acceptedAt'] = FieldValue.serverTimestamp();
        break;
      case OrderStatus.preparing:
        updateData['preparingAt'] = FieldValue.serverTimestamp();
        break;
      case OrderStatus.ready:
        updateData['readyAt'] = FieldValue.serverTimestamp();
        break;
      case OrderStatus.pickedUp:
        updateData['pickedUpAt'] = FieldValue.serverTimestamp();
        break;
      case OrderStatus.onTheWay:
        // onTheWay uses updatedAt, no dedicated timestamp
        break;
      case OrderStatus.delivered:
        updateData['deliveredAt'] = FieldValue.serverTimestamp();
        updateData['paymentStatus'] = PaymentStatus.completed.key;
        break;
      case OrderStatus.cancelled:
        updateData['cancelledAt'] = FieldValue.serverTimestamp();
        break;
      default:
        break;
    }

    await _ordersRef.doc(orderId).update(updateData);
    await _notifyCustomerOnStatusChange(orderId, newStatus);
  }

  /// Write a notification document in Firestore for the customer
  /// whenever the order status changes to a notable state.
  Future<void> _notifyCustomerOnStatusChange(
    String orderId,
    OrderStatus newStatus,
  ) async {
    // Only notify on states the customer cares about
    final statusTitles = {
      OrderStatus.accepted: (
        'Order Accepted',
        'Your order has been accepted and will be prepared soon.',
      ),
      OrderStatus.preparing: (
        'Preparing Your Order',
        'The restaurant is now preparing your order.',
      ),
      OrderStatus.ready: (
        'Order Ready',
        'Your order is ready and waiting for pickup.',
      ),
      OrderStatus.driverAssigned: (
        'Driver Assigned',
        'A driver has been assigned to deliver your order.',
      ),
      OrderStatus.pickedUp: ('Order Picked Up', 'Your order is on its way!'),
      OrderStatus.onTheWay: (
        'On The Way',
        'Your driver is heading to your location.',
      ),
      OrderStatus.delivered: (
        'Order Delivered',
        'Your order has been delivered. Enjoy your meal!',
      ),
      OrderStatus.cancelled: (
        'Order Cancelled',
        'Your order has been cancelled.',
      ),
    };

    final entry = statusTitles[newStatus];
    if (entry == null) return;

    try {
      final orderDoc = await _ordersRef.doc(orderId).get();
      if (!orderDoc.exists) return;
      final customerId = orderDoc.data()?['customerId'] as String?;
      if (customerId == null || customerId.isEmpty) return;

      final notifType = newStatus == OrderStatus.driverAssigned
          ? NotificationType.driverAssigned
          : newStatus == OrderStatus.delivered || newStatus == OrderStatus.ready
          ? NotificationType.orderReady
          : NotificationType.orderStatusChanged;

      final docRef = _db.collection('notifications').doc();
      await docRef.set({
        'userId': customerId,
        'type': notifType.key,
        'title': entry.$1,
        'body': entry.$2,
        'data': {'orderId': orderId, 'status': newStatus.key},
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Non-fatal: notification failure must not break status update
    }
  }

  /// Cancel order with reason
  Future<void> cancelOrder(
    String orderId,
    String reason, {
    String cancelledBy = 'customer',
  }) async {
    await _ordersRef.doc(orderId).update({
      'status': OrderStatus.cancelled.key,
      'cancellationReason': reason,
      'cancelledBy': cancelledBy,
      'statusUpdatedBy': cancelledBy,
      'cancelledAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Reject order (vendor rejects incoming order)
  Future<void> rejectOrder(String orderId, String reason) async {
    await _ordersRef.doc(orderId).update({
      'status': OrderStatus.cancelled.key,
      'cancellationReason': reason,
      'cancelledBy': 'vendor',
      'statusUpdatedBy': 'vendor',
      'cancelledAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Assign driver to order
  Future<void> assignDriver(String orderId, String driverId) async {
    await _ordersRef.doc(orderId).update({
      'driverId': driverId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get order items (one-shot)
  Future<List<OrderItem>> getOrderItems(String orderId) async {
    final snapshot = await _ordersRef.doc(orderId).collection('items').get();

    return snapshot.docs
        .map((doc) => OrderItem.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Stream order items (real-time)
  Stream<List<OrderItem>> streamOrderItems(String orderId) {
    return _ordersRef.doc(orderId).collection('items').snapshots().map((
      snapshot,
    ) {
      return snapshot.docs
          .map((doc) => OrderItem.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Get active orders count for a restaurant
  Future<int> getActiveOrdersCount(String restaurantId) async {
    final activeStatuses = [
      OrderStatus.pending.key,
      OrderStatus.accepted.key,
      OrderStatus.preparing.key,
      OrderStatus.ready.key,
      OrderStatus.driverAssigned.key,
      OrderStatus.pickedUp.key,
      OrderStatus.onTheWay.key,
    ];

    final snapshots = await Future.wait([
      _ordersRef
          .where('restaurantId', isEqualTo: restaurantId)
          .where('status', whereIn: activeStatuses)
          .get(),
      _ordersRef
          .where('vendorId', isEqualTo: restaurantId)
          .where('status', whereIn: activeStatuses)
          .get(),
    ]);

    return snapshots
        .expand((snapshot) => snapshot.docs)
        .map((doc) => doc.id)
        .toSet()
        .length;
  }

  /// Update order delivery location (for tracking)
  Future<void> updateDeliveryLocation(
    String orderId,
    double latitude,
    double longitude,
  ) async {
    await _ordersRef.doc(orderId).update({
      'deliveryLat': latitude,
      'deliveryLng': longitude,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Generic field update for orders (Phase 8.10).
  Future<void> updateFields(String orderId, Map<String, dynamic> data) async {
    await _ordersRef.doc(orderId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Mark an order as delivered and atomically credit restaurant & driver wallets.
  ///
  /// Only credits wallets for card-paid orders. Cash payments are settled outside
  /// the system. All writes happen in a single batch for atomicity.
  Future<void> markDeliveredWithWalletCredit(Order order) async {
    final batch = _db.batch();
    final now = FieldValue.serverTimestamp();
    final nowDate = DateTime.now();

    // 1. Update order status and payment status
    batch.update(_ordersRef.doc(order.id), {
      'status': OrderStatus.delivered.key,
      'paymentStatus': PaymentStatus.completed.key,
      'deliveredAt': now,
      'updatedAt': now,
    });

    if (order.paymentMethod == PaymentMethodType.card) {
      final restaurantShare = order.subtotal - order.serviceFee;
      final driverShare = order.deliveryFee;

      // 2. Credit restaurant wallet transaction
      final restaurantTxId = const Uuid().v4();
      batch.set(
        _db.collection('restaurantWalletTransactions').doc(restaurantTxId),
        {
          'restaurantId': order.restaurantId,
          'orderId': order.id,
          'type': WalletTransactionType.credit.key,
          'amount': restaurantShare,
          'description': 'Order earnings',
          'status': WalletTransactionStatus.confirmed.key,
          'payoutMethod': null,
          'evidenceUrl': null,
          'confirmedByOwner': false,
          'confirmedAt': null,
          'createdAt': Timestamp.fromDate(nowDate),
          'updatedAt': Timestamp.fromDate(nowDate),
        },
      );

      // 3. Increment restaurant wallet balance
      batch.update(_db.collection('vendors').doc(order.restaurantId), {
        'walletBalance': FieldValue.increment(restaurantShare),
        'totalEarnings': FieldValue.increment(restaurantShare),
        'updatedAt': now,
      });

      if (order.driverId != null && order.driverId!.isNotEmpty) {
        // 4. Credit driver wallet transaction
        final driverTxId = const Uuid().v4();
        batch.set(_db.collection('driverWalletTransactions').doc(driverTxId), {
          'driverId': order.driverId,
          'orderId': order.id,
          'type': WalletTransactionType.credit.key,
          'amount': driverShare,
          'description': 'Delivery fee',
          'status': WalletTransactionStatus.confirmed.key,
          'paymentMethod': null,
          'evidenceUrl': null,
          'confirmedByDriver': false,
          'confirmedAt': null,
          'disputedByAdmin': false,
          'disputeReason': null,
          'createdAt': Timestamp.fromDate(nowDate),
          'updatedAt': Timestamp.fromDate(nowDate),
        });

        // 5. Record driver wallet credit transaction (audit trail only).
        // walletBalance and totalEarnings are already incremented by incrementEarnings().
        batch.update(_db.collection('driverProfiles').doc(order.driverId!), {
          'updatedAt': now,
        });
      }
    }

    await batch.commit();
  }
}
