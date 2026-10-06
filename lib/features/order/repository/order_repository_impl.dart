import 'package:z_speed/core/core.dart';
import 'package:z_speed/features/order/datasource/order_firebase_datasource.dart';
import 'package:z_speed/features/order/model/order.dart';
import 'package:z_speed/features/order/model/order_item.dart';
import 'package:z_speed/features/order/repository/order_repository.dart';
import 'package:z_speed/core/enums/order_enums.dart';
import 'package:injectable/injectable.dart' hide Order;

/// Order repository implementation wrapping OrderFirebaseDatasource.
@LazySingleton(as: OrderRepository)
class OrderRepositoryImpl implements OrderRepository {
  final OrderFirebaseDatasource _datasource;

  OrderRepositoryImpl({OrderFirebaseDatasource? datasource})
      : _datasource = datasource ?? OrderFirebaseDatasource();

  @override
  Future<Result<String>> createOrder(Order order, List<OrderItem> items) async {
    try {
      final orderId = await _datasource.createOrder(order, items);
      return Success(orderId);
    } catch (error, stackTrace) {
      return Err(
          UnexpectedFailure('Failed to create order: $error', stackTrace));
    }
  }

  @override
  Stream<Order?> streamOrder(String orderId) {
    return _datasource.streamOrder(orderId);
  }

  @override
  Future<Result<Order?>> getById(String orderId) async {
    try {
      final order = await _datasource.getById(orderId);
      return Success(order);
    } catch (error, stackTrace) {
      return Err(UnexpectedFailure('Failed to get order: $error', stackTrace));
    }
  }

  @override
  Stream<List<Order>> streamCustomerOrders(String customerId) {
    return _datasource.streamCustomerOrders(customerId);
  }

  @override
  Future<Result<List<Order>>> getCustomerOrders(String customerId) async {
    try {
      final orders = await _datasource.getCustomerOrders(customerId);
      return Success(orders);
    } catch (error, stackTrace) {
      return Err(UnexpectedFailure(
          'Failed to get customer orders: $error', stackTrace));
    }
  }

  @override
  Stream<List<Order>> streamRestaurantOrders(
    String restaurantId, {
    List<OrderStatus>? statuses,
  }) {
    return _datasource.streamRestaurantOrders(restaurantId, statuses: statuses);
  }

  @override
  Future<Result<List<Order>>> getRestaurantOrders(
    String restaurantId, {
    List<OrderStatus>? statuses,
  }) async {
    try {
      final orders = await _datasource.getRestaurantOrders(
        restaurantId,
        statuses: statuses,
      );
      return Success(orders);
    } catch (error, stackTrace) {
      return Err(UnexpectedFailure(
          'Failed to get restaurant orders: $error', stackTrace));
    }
  }

  @override
  Future<Result<void>> updateStatus(
    String orderId,
    OrderStatus newStatus, {
    String? updatedBy,
  }) async {
    try {
      await _datasource.updateStatus(orderId, newStatus, updatedBy: updatedBy);
      return Success(null);
    } catch (error, stackTrace) {
      return Err(UnexpectedFailure(
          'Failed to update order status: $error', stackTrace));
    }
  }

  @override
  Future<Result<void>> cancelOrder(String orderId, String reason) async {
    try {
      await _datasource.cancelOrder(orderId, reason, cancelledBy: 'customer');
      return Success(null);
    } catch (error, stackTrace) {
      return Err(
          UnexpectedFailure('Failed to cancel order: $error', stackTrace));
    }
  }

  @override
  Future<Result<void>> rejectOrder(String orderId, String reason) async {
    try {
      await _datasource.rejectOrder(orderId, reason);
      return Success(null);
    } catch (error, stackTrace) {
      return Err(
          UnexpectedFailure('Failed to reject order: $error', stackTrace));
    }
  }

  @override
  Future<Result<void>> assignDriver(String orderId, String driverId) async {
    try {
      await _datasource.assignDriver(orderId, driverId);
      return Success(null);
    } catch (error, stackTrace) {
      return Err(
          UnexpectedFailure('Failed to assign driver: $error', stackTrace));
    }
  }

  @override
  Future<Result<List<OrderItem>>> getOrderItems(String orderId) async {
    try {
      final items = await _datasource.getOrderItems(orderId);
      return Success(items);
    } catch (error, stackTrace) {
      return Err(
          UnexpectedFailure('Failed to get order items: $error', stackTrace));
    }
  }

  @override
  Stream<List<OrderItem>> streamOrderItems(String orderId) {
    return _datasource.streamOrderItems(orderId);
  }

  @override
  Future<Result<int>> getActiveOrdersCount(String restaurantId) async {
    try {
      final count = await _datasource.getActiveOrdersCount(restaurantId);
      return Success(count);
    } catch (error, stackTrace) {
      return Err(UnexpectedFailure(
          'Failed to get active orders count: $error', stackTrace));
    }
  }

  @override
  Future<Result<void>> updateDeliveryLocation(
    String orderId,
    double latitude,
    double longitude,
  ) async {
    try {
      await _datasource.updateDeliveryLocation(orderId, latitude, longitude);
      return Success(null);
    } catch (error, stackTrace) {
      return Err(UnexpectedFailure(
          'Failed to update delivery location: $error', stackTrace));
    }
  }

  @override
  Future<Result<void>> updateOrder(
      String orderId, Map<String, dynamic> data) async {
    try {
      await _datasource.updateFields(orderId, data);
      return Success(null);
    } catch (error, stackTrace) {
      return Err(
          UnexpectedFailure('Failed to update order: $error', stackTrace));
    }
  }
}
