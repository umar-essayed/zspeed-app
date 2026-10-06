import 'package:equatable/equatable.dart';
import 'package:z_speed/core/enums/order_enums.dart';
import 'package:z_speed/features/order/model/order.dart';
import 'package:z_speed/features/restaurant/model/restaurant.dart';

/// Filter enum for vendor order tabs
enum VendorOrderFilter {
  all,
  pending,
  active,
  ready,
  completed,
}

class RestaurantOrdersState extends Equatable {
  final bool isLoading;
  final String? error;
  final VendorOrderFilter currentFilter;
  final List<Order> allOrders;
  final String? restaurantId;
  final Restaurant? currentRestaurant;
  final Set<String> processingOrders;
  final Map<String, String> itemTranslations;
  final bool translationsLoaded;

  const RestaurantOrdersState({
    this.isLoading = false,
    this.error,
    this.currentFilter = VendorOrderFilter.all,
    this.allOrders = const [],
    this.restaurantId,
    this.currentRestaurant,
    this.processingOrders = const {},
    this.itemTranslations = const {},
    this.translationsLoaded = false,
  });

  RestaurantOrdersState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    VendorOrderFilter? currentFilter,
    List<Order>? allOrders,
    String? restaurantId,
    Restaurant? currentRestaurant,
    Set<String>? processingOrders,
    Map<String, String>? itemTranslations,
    bool? translationsLoaded,
  }) {
    return RestaurantOrdersState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      currentFilter: currentFilter ?? this.currentFilter,
      allOrders: allOrders ?? this.allOrders,
      restaurantId: restaurantId ?? this.restaurantId,
      currentRestaurant: currentRestaurant ?? this.currentRestaurant,
      processingOrders: processingOrders ?? this.processingOrders,
      itemTranslations: itemTranslations ?? this.itemTranslations,
      translationsLoaded: translationsLoaded ?? this.translationsLoaded,
    );
  }

  bool isProcessingOrder(String orderId) =>
      processingOrders.contains(orderId);

  List<Order> get filteredOrders {
    switch (currentFilter) {
      case VendorOrderFilter.pending:
        return allOrders
            .where((o) => o.status == OrderStatus.pending)
            .toList();
      case VendorOrderFilter.active:
        return allOrders
            .where((o) =>
                o.status == OrderStatus.accepted ||
                o.status == OrderStatus.preparing ||
                o.status == OrderStatus.searching ||
                o.status == OrderStatus.unassigned ||
                o.status == OrderStatus.driverAssigned ||
                o.status == OrderStatus.pickedUp ||
                o.status == OrderStatus.onTheWay)
            .toList();
      case VendorOrderFilter.ready:
        return allOrders
            .where((o) => o.status == OrderStatus.ready)
            .toList();
      case VendorOrderFilter.completed:
        return allOrders
            .where((o) =>
                o.status == OrderStatus.delivered ||
                o.status == OrderStatus.cancelled ||
                o.status == OrderStatus.refunded)
            .toList();
      case VendorOrderFilter.all:
        return allOrders;
    }
  }

  int get pendingCount =>
      allOrders.where((o) => o.status == OrderStatus.pending).length;
  int get activeCount => allOrders
      .where((o) =>
          o.status == OrderStatus.accepted ||
          o.status == OrderStatus.preparing ||
          o.status == OrderStatus.searching ||
          o.status == OrderStatus.unassigned ||
          o.status == OrderStatus.driverAssigned ||
          o.status == OrderStatus.pickedUp ||
          o.status == OrderStatus.onTheWay)
      .length;
  int get readyCount =>
      allOrders.where((o) => o.status == OrderStatus.ready).length;
  int get completedCount => allOrders
      .where((o) =>
          o.status == OrderStatus.delivered ||
          o.status == OrderStatus.cancelled ||
          o.status == OrderStatus.refunded)
      .length;

  @override
  List<Object?> get props => [
        isLoading,
        error,
        currentFilter,
        allOrders,
        restaurantId,
        currentRestaurant,
        processingOrders,
        itemTranslations,
        translationsLoaded,
      ];
}
