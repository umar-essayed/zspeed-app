import 'package:equatable/equatable.dart';
import 'package:z_speed/core/enums/enums.dart';

/// Aggregated stats for the admin dashboard.
class AdminDashboardStats extends Equatable {
  final int totalUsers;
  final int totalOrders;
  final int totalRestaurants;
  final double totalRevenue;
  final int pendingOrders;
  final int activeDrivers;
  final int pendingApplications;
  final Map<UserType, int> usersByType;
  final Map<OrderStatus, int> ordersByStatus;

  const AdminDashboardStats({
    this.totalUsers = 0,
    this.totalOrders = 0,
    this.totalRestaurants = 0,
    this.totalRevenue = 0.0,
    this.pendingOrders = 0,
    this.activeDrivers = 0,
    this.pendingApplications = 0,
    this.usersByType = const {},
    this.ordersByStatus = const {},
  });

  AdminDashboardStats copyWith({
    int? totalUsers,
    int? totalOrders,
    int? totalRestaurants,
    double? totalRevenue,
    int? pendingOrders,
    int? activeDrivers,
    int? pendingApplications,
    Map<UserType, int>? usersByType,
    Map<OrderStatus, int>? ordersByStatus,
  }) {
    return AdminDashboardStats(
      totalUsers: totalUsers ?? this.totalUsers,
      totalOrders: totalOrders ?? this.totalOrders,
      totalRestaurants: totalRestaurants ?? this.totalRestaurants,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      pendingOrders: pendingOrders ?? this.pendingOrders,
      activeDrivers: activeDrivers ?? this.activeDrivers,
      pendingApplications: pendingApplications ?? this.pendingApplications,
      usersByType: usersByType ?? this.usersByType,
      ordersByStatus: ordersByStatus ?? this.ordersByStatus,
    );
  }

  @override
  List<Object?> get props => [
        totalUsers,
        totalOrders,
        totalRestaurants,
        totalRevenue,
        pendingOrders,
        activeDrivers,
        pendingApplications,
        usersByType,
        ordersByStatus,
      ];
}
