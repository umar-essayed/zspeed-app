import 'package:equatable/equatable.dart';
import 'package:z_speed/features/order/model/order.dart' as app_order;
import 'package:z_speed/features/restaurant/model/restaurant.dart';

/// Aggregated dashboard statistics for a restaurant.
class DashboardStats {
  final double totalRevenue;
  final int activeOrders;
  final int totalCustomers;
  final int avgPrepMinutes;
  final double revenueChange;
  final double activeOrdersChange;
  final double customersChange;
  final int prepTimeChange;
  final Map<String, double> dailyRevenue;

  const DashboardStats({
    this.totalRevenue = 0,
    this.activeOrders = 0,
    this.totalCustomers = 0,
    this.avgPrepMinutes = 0,
    this.revenueChange = 0,
    this.activeOrdersChange = 0,
    this.customersChange = 0,
    this.prepTimeChange = 0,
    this.dailyRevenue = const {},
  });
}

class RestaurantDashboardState extends Equatable {
  final bool isLoading;
  final String? error;
  final String? restaurantId;
  final Restaurant? restaurant;
  final bool noRestaurant;
  final List<app_order.Order> allOrders;
  final DashboardStats stats;

  const RestaurantDashboardState({
    this.isLoading = false,
    this.error,
    this.restaurantId,
    this.restaurant,
    this.noRestaurant = false,
    this.allOrders = const [],
    this.stats = const DashboardStats(),
  });

  RestaurantDashboardState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    String? restaurantId,
    Restaurant? restaurant,
    bool? noRestaurant,
    List<app_order.Order>? allOrders,
    DashboardStats? stats,
  }) {
    return RestaurantDashboardState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      restaurantId: restaurantId ?? this.restaurantId,
      restaurant: restaurant ?? this.restaurant,
      noRestaurant: noRestaurant ?? this.noRestaurant,
      allOrders: allOrders ?? this.allOrders,
      stats: stats ?? this.stats,
    );
  }

  /// The 5 most recent orders (any status).
  List<app_order.Order> get recentOrders {
    final sorted = List<app_order.Order>.from(allOrders)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.take(5).toList();
  }

  @override
  List<Object?> get props => [
        isLoading,
        error,
        restaurantId,
        restaurant,
        noRestaurant,
        allOrders,
        stats,
      ];
}
