import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:z_speed/core/enums/driver_enums.dart';
import 'package:z_speed/core/errors/failures.dart';
import 'package:z_speed/core/result/result.dart';
import 'package:z_speed/features/driver/datasource/driver_firebase_datasource.dart';
import 'package:z_speed/features/driver/model/delivery_request.dart';
import 'package:z_speed/features/driver/model/driver_profile.dart';
import 'package:z_speed/features/driver/model/order_driver.dart';
import 'package:z_speed/features/driver/model/wallet_transaction.dart';
import 'package:z_speed/features/driver/repository/driver_repository.dart';
import 'package:z_speed/features/order/datasource/order_firebase_datasource.dart';
import 'package:z_speed/features/order/model/order.dart';
import 'package:injectable/injectable.dart' hide Order;

/// Implementation of DriverRepository using Firebase.
///
@LazySingleton(as: DriverRepository)
class DriverRepositoryImpl implements DriverRepository {
  final DriverFirebaseDatasource _datasource;
  final OrderFirebaseDatasource _orderDatasource;

  DriverRepositoryImpl({
    DriverFirebaseDatasource? datasource,
    OrderFirebaseDatasource? orderDatasource,
  })  : _datasource = datasource ?? DriverFirebaseDatasource(),
        _orderDatasource = orderDatasource ?? OrderFirebaseDatasource();

  // ===== Driver Profile Operations =====

  @override
  Future<Result<DriverProfile>> getDriverProfile(String userId) async {
    try {
      final profile = await _datasource.getDriverProfile(userId);
      if (profile == null) {
        return Err(
          UnexpectedFailure('Driver profile not found'),
        );
      }
      return Success(profile);
    } catch (e, st) {
      return Err(UnexpectedFailure('Failed to get driver profile: $e', st));
    }
  }

  @override
  Stream<Result<DriverProfile>> streamDriverProfile(String userId) async* {
    try {
      await for (final profile in _datasource.streamDriverProfile(userId)) {
        if (profile == null) {
          yield Err(UnexpectedFailure('Driver profile not found'));
        } else {
          yield Success(profile);
        }
      }
    } catch (e, st) {
      yield Err(UnexpectedFailure('Failed to stream driver profile: $e', st));
    }
  }

  @override
  Future<Result<void>> updateDriverStatus(
      String userId, DriverStatus status) async {
    try {
      await _datasource.updateDriverStatus(userId, status);
      return Success(null);
    } catch (e, st) {
      return Err(UnexpectedFailure('Failed to update driver status: $e', st));
    }
  }

  @override
  Future<Result<void>> updateDriverLocation(
      String userId, double lat, double lng) async {
    try {
      await _datasource.updateDriverLocation(userId, lat, lng);
      return Success(null);
    } catch (e, st) {
      return Err(UnexpectedFailure('Failed to update driver location: $e', st));
    }
  }

  // ===== Available Drivers (Vendor Side) =====

  @override
  Stream<List<DriverProfile>> streamOnlineDrivers() {
    return _datasource.streamOnlineDrivers();
  }

  // ===== Delivery Requests (Driver Receives) =====

  @override
  Future<Result<void>> sendDeliveryRequest(DeliveryRequest request) async {
    try {
      await _datasource.createDeliveryRequest(
        request.driverId,
        request,
      );
      return Success(null);
    } catch (e, st) {
      return Err(UnexpectedFailure('Failed to send delivery request: $e', st));
    }
  }

  @override
  Stream<List<DeliveryRequest>> streamPendingRequests(String driverId) {
    return _datasource.streamPendingRequests(driverId);
  }

  @override
  Future<Result<void>> acceptDeliveryRequest(
    String driverId,
    String requestId,
    String orderId,
  ) async {
    try {
      // Fetch request details and verify status
      final request = await _datasource.getDeliveryRequest(requestId);
      if (request == null) {
        return Err(UnexpectedFailure('Delivery request not found'));
      }
      if (request.status != DriverAssignmentStatus.pending) {
        return Err(UnexpectedFailure(
          request.status == DriverAssignmentStatus.cancelled
              ? 'This request was cancelled by the restaurant'
              : 'This request is no longer active (status: ${request.status.key})',
        ));
      }

      // Update request status to accepted
      await _datasource.updateRequestStatus(
        driverId,
        requestId,
        'accepted',
      );

      // Fetch driver profile to self-heal missing fields in OrderDriver
      final profile = await _datasource.getDriverProfile(driverId);

      // Update OrderDriver status to accepted with full details
      await _datasource.updateOrderDriverStatus(
        orderId,
        driverId,
        {
          'driverUserId': driverId,
          'driverName': profile?.name ?? '',
          'driverPhone': profile?.phoneNumber ?? '',
          'vehicleModel': profile?.vehicleModel ?? '',
          'licensePlate': profile?.licensePlate ?? '',
          'status': 'accepted',
          'acceptedAt': DateTime.now(),
          'deliveryFee': request.deliveryFee,
          'assignedItems': request.itemNames,
        },
      );

      // Update main order: set driverId + driverIds array + status → driverAssigned
      await _datasource.updateMainOrderStatusToAssigned(orderId, driverId);

      // Keep driver status as online so they can catch more than one order request
      // await _datasource.updateDriverStatus(driverId, DriverStatus.busy);

      // Increment driver's acceptance rate
      await _datasource.incrementAccepted(driverId);

      return Success(null);
    } catch (e, st) {
      return Err(
          UnexpectedFailure('Failed to accept delivery request: $e', st));
    }
  }

  @override
  Future<Result<void>> rejectDeliveryRequest(
    String driverId,
    String requestId,
    String orderId,
    String reason,
  ) async {
    try {
      // Fetch request details and verify status
      final request = await _datasource.getDeliveryRequest(requestId);
      if (request == null) {
        return Err(UnexpectedFailure('Delivery request not found'));
      }
      if (request.status != DriverAssignmentStatus.pending) {
        return Err(UnexpectedFailure(
          request.status == DriverAssignmentStatus.cancelled
              ? 'This request was cancelled by the restaurant'
              : 'This request is no longer active (status: ${request.status.key})',
        ));
      }

      // Update request status to rejected with reason
      await _datasource.updateRequestStatus(
        driverId,
        requestId,
        'rejected',
        rejectionReason: reason,
      );

      // Update OrderDriver status to rejected
      await _datasource.updateOrderDriverStatus(
        orderId,
        driverId,
        {
          'status': 'rejected',
          'rejectionReason': reason,
        },
      );

      // Increment driver's rejection count and recalculate acceptance rate
      await _datasource.incrementRejected(driverId);

      return Success(null);
    } catch (e, st) {
      return Err(
          UnexpectedFailure('Failed to reject delivery request: $e', st));
    }
  }

  // ===== Order-Driver Assignment Operations =====

  @override
  Future<Result<void>> assignDriverToOrder(
      String orderId, OrderDriver orderDriver) async {
    try {
      await _datasource.assignDriverToOrder(orderId, orderDriver);
      return Success(null);
    } catch (e, st) {
      return Err(UnexpectedFailure('Failed to assign driver to order: $e', st));
    }
  }

  @override
  Stream<List<OrderDriver>> streamOrderDrivers(String orderId) {
    return _datasource.streamOrderDrivers(orderId);
  }

  @override
  Future<Result<void>> cancelDriverAssignment(
      String orderId, String driverUserId) async {
    try {
      await _datasource.cancelDriverAssignment(orderId, driverUserId);
      return Success(null);
    } catch (e, st) {
      return Err(
          UnexpectedFailure('Failed to cancel driver assignment: $e', st));
    }
  }

  @override
  Future<Result<void>> markPickedUp(String orderId, String driverUserId) async {
    try {
      await _datasource.updateOrderDriverStatus(
        orderId,
        driverUserId,
        {
          'status': 'pickedUp',
          'pickedUpAt': Timestamp.now(),
        },
      );

      // Update main order status so the driver's tracking screen switches to
      // customer-route mode and customers/restaurants see the updated status
      await _datasource.updateMainOrderStatus(orderId, 'pickedUp');

      return Success(null);
    } catch (e, st) {
      return Err(
          UnexpectedFailure('Failed to mark order as picked up: $e', st));
    }
  }

  @override
  Future<Result<void>> markDelivered(
      String orderId, String driverUserId) async {
    try {
      // Update OrderDriver status
      await _datasource.updateOrderDriverStatus(
        orderId,
        driverUserId,
        {
          'status': 'delivered',
          'deliveredAt': Timestamp.now(),
        },
      );

      // Update the delivery request status to 'delivered'.
      // This triggers the Cloud Function (onDeliveryRequestStatusUpdated) which
      // sets deliveredAt on the main order and writes the ledger entry.
      await _datasource.markDeliveryRequestAsDelivered(orderId, driverUserId);

      // Driver is free again — set back to online
      await _datasource.updateDriverStatus(driverUserId, DriverStatus.online);

      // Get the OrderDriver to get the delivery fee
      final orderDrivers = await _datasource.streamOrderDrivers(orderId).first;
      final orderDriver = orderDrivers.firstWhere(
        (od) => od.driverUserId == driverUserId,
      );

      // Increment driver's earnings and trip count
      await _datasource.incrementEarnings(
        driverUserId,
        orderDriver.deliveryFee,
      );

      // Credit restaurant and driver wallets atomically (card-paid orders only)
      final order = await _orderDatasource.getById(orderId);
      if (order != null) {
        await _orderDatasource.markDeliveredWithWalletCredit(order);
      }

      return Success(null);
    } catch (e, st) {
      return Err(
          UnexpectedFailure('Failed to mark order as delivered: $e', st));
    }
  }

  // ===== Wallet Operations =====

  @override
  Stream<List<WalletTransaction>> streamDriverTransactions(String driverId) {
    return _datasource.streamDriverTransactions(driverId);
  }

  @override
  Future<Result<void>> confirmPayout(
      String transactionId, String driverId) async {
    try {
      // Get the transaction to get the amount
      final transactions =
          await _datasource.streamDriverTransactions(driverId).first;
      final transaction = transactions.firstWhere(
        (t) => t.id == transactionId,
      );

      // Confirm the payout
      await _datasource.confirmWalletPayout(transactionId);

      // Get current driver profile
      final profile = await _datasource.getDriverProfile(driverId);
      if (profile == null) {
        return Err(
          UnexpectedFailure('Driver profile not found'),
        );
      }

      // Deduct the amount from wallet balance
      final newBalance = profile.walletBalance - transaction.amount;
      await _datasource.updateWalletBalance(driverId, newBalance);

      return Success(null);
    } catch (e, st) {
      return Err(UnexpectedFailure('Failed to confirm payout: $e', st));
    }
  }

  @override
  Future<Result<void>> resetWalletBalance(String driverId) async {
    try {
      await _datasource.resetWalletBalance(driverId);
      return Success(null);
    } catch (e, st) {
      return Err(UnexpectedFailure('Failed to reset wallet balance: $e', st));
    }
  }

  // ===== Driver Orders =====

  @override
  Future<Result<void>> ensureDriverProfile(String userId) async {
    try {
      await _datasource.ensureDriverProfile(userId);
      return Success(null);
    } catch (e, st) {
      return Err(UnexpectedFailure('Failed to create driver profile: $e', st));
    }
  }

  @override
  Stream<List<Order>> streamDriverActiveOrders(String driverId) {
    return _datasource.streamDriverActiveOrders(driverId);
  }

  @override
  Stream<List<Order>> streamDriverOrderHistory(String driverId) {
    return _datasource.streamDriverOrderHistory(driverId);
  }
}
