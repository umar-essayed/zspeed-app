import 'package:z_speed/core/result/result.dart';
import 'package:z_speed/features/order/model/order.dart';
import 'package:z_speed/features/order/model/order_item.dart';
import 'package:z_speed/core/enums/order_enums.dart';

/// Abstract repository interface for order operations.
abstract class OrderRepository {
  /// Create a new order with items
  Future<Result<String>> createOrder(Order order, List<OrderItem> items);

  /// Stream a single order (real-time updates)
  Stream<Order?> streamOrder(String orderId);

  /// Get a single order
  Future<Result<Order?>> getById(String orderId);

  /// Stream customer's orders
  Stream<List<Order>> streamCustomerOrders(String customerId);

  /// Get customer's orders (one-shot)
  Future<Result<List<Order>>> getCustomerOrders(String customerId);

  /// Stream restaurant's orders
  Stream<List<Order>> streamRestaurantOrders(
    String restaurantId, {
    List<OrderStatus>? statuses,
  });

  /// Get restaurant's orders (one-shot)
  Future<Result<List<Order>>> getRestaurantOrders(
    String restaurantId, {
    List<OrderStatus>? statuses,
  });

  /// Update order status
  Future<Result<void>> updateStatus(
    String orderId,
    OrderStatus newStatus, {
    String? updatedBy,
  });

  /// Cancel order
  Future<Result<void>> cancelOrder(String orderId, String reason);

  /// Reject order (vendor rejects incoming order)
  Future<Result<void>> rejectOrder(String orderId, String reason);

  /// Assign driver to order
  Future<Result<void>> assignDriver(String orderId, String driverId);

  /// Get order items
  Future<Result<List<OrderItem>>> getOrderItems(String orderId);

  /// Stream order items
  Stream<List<OrderItem>> streamOrderItems(String orderId);

  /// Get active orders count
  Future<Result<int>> getActiveOrdersCount(String restaurantId);

  /// Update delivery location (for real-time tracking)
  Future<Result<void>> updateDeliveryLocation(
    String orderId,
    double latitude,
    double longitude,
  );

  /// Update order fields (Phase 8.10)
  ///
  /// Use this to update arbitrary fields like paymentId, notes, etc.
  Future<Result<void>> updateOrder(String orderId, Map<String, dynamic> data);
}
