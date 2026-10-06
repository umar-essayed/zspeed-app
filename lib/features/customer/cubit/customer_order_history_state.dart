import 'package:equatable/equatable.dart';
import 'package:z_speed/core/enums/order_enums.dart';
import 'package:z_speed/features/order/model/order.dart';

class CustomerOrderHistoryState extends Equatable {
  final bool isLoading;
  final String? error;
  final List<Order> allOrders;

  const CustomerOrderHistoryState({
    this.isLoading = false,
    this.error,
    this.allOrders = const [],
  });

  CustomerOrderHistoryState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    List<Order>? allOrders,
  }) {
    return CustomerOrderHistoryState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      allOrders: allOrders ?? this.allOrders,
    );
  }

  List<Order> get activeOrders {
    return allOrders
        .where((order) =>
            order.status == OrderStatus.pending ||
            order.status == OrderStatus.accepted ||
            order.status == OrderStatus.preparing ||
            order.status == OrderStatus.ready ||
            order.status == OrderStatus.driverAssigned ||
            order.status == OrderStatus.pickedUp ||
            order.status == OrderStatus.onTheWay)
        .toList();
  }

  List<Order> get pastOrders {
    return allOrders
        .where((order) =>
            order.status == OrderStatus.delivered ||
            order.status == OrderStatus.cancelled ||
            order.status == OrderStatus.refunded)
        .toList();
  }

  @override
  List<Object?> get props => [isLoading, error, allOrders];
}
