import 'package:z_speed/core/enums/driver_enums.dart';
import 'package:z_speed/core/result/result.dart';
import 'package:z_speed/features/driver/model/delivery_request.dart';
import 'package:z_speed/features/driver/model/driver_profile.dart';
import 'package:z_speed/features/driver/model/order_driver.dart';
import 'package:z_speed/features/driver/model/wallet_transaction.dart';
import 'package:z_speed/features/order/model/order.dart';

/// Abstract repository interface for driver-related operations.
///

abstract class DriverRepository {
  // ===== Driver Profile Operations =====

  /// Get driver profile by user ID.
  Future<Result<DriverProfile>> getDriverProfile(String userId);

  /// Streams a driver's live profile updates.
  Stream<Result<DriverProfile>> streamDriverProfile(String userId);

  /// Update driver status (online/offline/busy).
  Future<Result<void>> updateDriverStatus(String userId, DriverStatus status);

  /// Update driver's current GPS location.
  Future<Result<void>> updateDriverLocation(
      String userId, double lat, double lng);

  // ===== Available Drivers (Vendor Side) =====

  /// Stream all online drivers for vendor to assign.
  ///
  /// Returns drivers where status == 'online'.
  /// Filtering by distance is done in ViewModel layer.
  Stream<List<DriverProfile>> streamOnlineDrivers();

  // ===== Delivery Requests (Driver Receives) =====

  /// Send a delivery request to a driver.
  ///
  /// Vendor calls this when assigning a driver to an order.
  Future<Result<void>> sendDeliveryRequest(DeliveryRequest request);

  /// Stream pending delivery requests for a driver.
  ///
  /// Driver sees these in real-time on their dashboard.
  Stream<List<DeliveryRequest>> streamPendingRequests(String driverId);

  /// Accept a delivery request.
  ///
  /// Updates request status to 'accepted', updates OrderDriver status,
  /// increments driver's totalAccepted and recalculates acceptanceRate.
  Future<Result<void>> acceptDeliveryRequest(
    String driverId,
    String requestId,
    String orderId,
  );

  /// Reject a delivery request.
  ///
  /// Updates request status to 'rejected', updates OrderDriver status,
  /// increments driver's totalRejected and recalculates acceptanceRate.
  Future<Result<void>> rejectDeliveryRequest(
    String driverId,
    String requestId,
    String orderId,
    String reason,
  );

  // ===== Order-Driver Assignment Operations =====

  /// Assign a driver to an order.
  ///
  /// Creates OrderDriver document in orders/{orderId}/orderDrivers/.
  Future<Result<void>> assignDriverToOrder(
      String orderId, OrderDriver orderDriver);

  /// Stream all drivers assigned to an order.
  ///
  /// Returns all OrderDriver docs for a given order (supports multi-driver).
  Stream<List<OrderDriver>> streamOrderDrivers(String orderId);

  /// Cancel a driver assignment from the restaurant side.
  ///
  /// Updates both OrderDriver and DeliveryRequest status to 'cancelled'.
  Future<Result<void>> cancelDriverAssignment(
      String orderId, String driverUserId);

  /// Mark order as picked up by driver.
  ///
  /// Updates OrderDriver status and timestamps.
  Future<Result<void>> markPickedUp(String orderId, String driverUserId);

  /// Mark order as delivered by driver.
  ///
  /// Updates OrderDriver status, increments driver earnings and trips.
  Future<Result<void>> markDelivered(String orderId, String driverUserId);

  // ===== Wallet Operations =====

  /// Stream wallet transactions for a driver.
  ///
  /// Returns all transactions ordered by creation date.
  Stream<List<WalletTransaction>> streamDriverTransactions(String driverId);

  /// Confirm a wallet payout (driver received payment from restaurant).
  ///
  /// Updates transaction status to 'confirmed', sets confirmedAt timestamp,
  /// and decrements driver's wallet balance.
  Future<Result<void>> confirmPayout(String transactionId, String driverId);

  /// Reset driver wallet balance to zero after admin settlement.
  Future<Result<void>> resetWalletBalance(String driverId);

  /// Create or ensure a driver profile document exists in Firestore.
  Future<Result<void>> ensureDriverProfile(String userId);

  // ===== Driver Orders =====

  /// Stream driver's active orders (currently being delivered).
  ///
  /// Returns orders where driverIds contains this driver and
  /// status in [driverAssigned, pickedUp, onTheWay].
  Stream<List<Order>> streamDriverActiveOrders(String driverId);

  /// Stream driver's order history (completed/cancelled).
  ///
  /// Returns orders where driverIds contains this driver and
  /// status in [delivered, cancelled].
  Stream<List<Order>> streamDriverOrderHistory(String driverId);
}
