import 'package:flutter/material.dart';
import 'package:z_speed/core/core.dart';
import 'package:z_speed/core/enums/enums.dart';
import 'package:z_speed/features/admin/model/admin_dashboard_stats.dart';
import 'package:z_speed/features/auth/model/user_model.dart';
import 'package:z_speed/features/order/model/order.dart';
import 'package:z_speed/features/restaurant/model/restaurant.dart';

/// Repository interface for admin dashboard and management operations.
///
/// Abstracts Firestore access for:
/// - Dashboard stats aggregation
/// - User management (CRUD, filtering)
/// - Order management (view, update, cancel)
/// - Restaurant/vendor management
/// - Analytics (revenue trends, user growth)
abstract class AdminRepository {
  // ── Dashboard Stats ────────────────────────────────────────────────────────

  /// Fetch aggregated dashboard statistics.
  Future<Result<AdminDashboardStats>> getDashboardStats();

  /// Stream real-time dashboard statistics.
  Stream<AdminDashboardStats> streamDashboardStats();

  // ── User Management ────────────────────────────────────────────────────────

  /// Fetch users, optionally filtered by type and/or status.
  Future<Result<(List<AppUser>, Object?)>> getUsers({
    UserType? type,
    UserStatus? status,
    Object? startAfter,
    int limit = 20,
  });

  /// Update a user's status.
  Future<Result<void>> updateUserStatus(String userId, UserStatus status);

  /// Update a user's type/role.
  Future<Result<void>> updateUserType(String userId, UserType type);

  /// Delete a user (soft delete).
  Future<Result<void>> deleteUser(String userId);

  // ── Order Management ───────────────────────────────────────────────────────

  /// Fetch orders, optionally filtered by status and/or date range.
  Future<Result<(List<Order>, Object?)>> getOrders({
    OrderStatus? status,
    DateTimeRange? range,
    Object? startAfter,
    int limit = 20,
  });

  /// Update an order's status.
  Future<Result<void>> updateOrderStatus(String orderId, OrderStatus status);

  /// Cancel an order with an optional reason.
  Future<Result<void>> cancelOrder(String orderId, {String? reason});

  // ── Restaurant/Vendor Management ───────────────────────────────────────────

  /// Fetch vendors (restaurants, supermarkets, etc.), optionally filtered by status and type.
  Future<Result<(List<Restaurant>, Object?)>> getVendors({
    RestaurantStatus? status,
    VendorType? vendorType,
    Object? startAfter,
    int limit = 20,
  });

  /// Update a restaurant's status.
  Future<Result<void>> updateRestaurantStatus(
    String restaurantId,
    RestaurantStatus status,
  );

  /// Delete a restaurant (soft delete).
  Future<Result<void>> deleteRestaurant(String restaurantId);

  /// Fix the vendorType of a restaurant document.
  Future<Result<void>> updateRestaurantVendorType(
      String restaurantId, VendorType vendorType);

  /// Update the recommendation priority score of a restaurant document.
  Future<Result<void>> updateRestaurantPriority(
      String restaurantId, int priority);

  /// Update a restaurant's details.
  Future<Result<void>> updateRestaurant(Restaurant restaurant);

  /// Create a brand-new vendor document in Firestore.
  Future<Result<void>> createVendor(Restaurant restaurant);

  // ── Analytics ──────────────────────────────────────────────────────────────

  /// Get daily revenue within a date range.
  Future<Result<Map<String, double>>> revenueByDay(DateTimeRange range);

  /// Get user counts grouped by type.
  Future<Result<Map<UserType, int>>> userCountsByType();

  /// Get order counts grouped by status, optionally filtered by date range.
  Future<Result<Map<OrderStatus, int>>> orderCountsByStatus({DateTimeRange? range});

  // ── Name Resolution ────────────────────────────────────────────────────────

  /// Batch-resolve user display names by IDs.
  Future<Result<Map<String, String>>> getUserNamesByIds(Set<String> userIds);

  /// Batch-resolve restaurant names by IDs.
  Future<Result<Map<String, String>>> getRestaurantNamesByIds(
      Set<String> restaurantIds);

  /// Get today's order count for a restaurant.
  Future<Result<int>> countOrdersToday(String restaurantId);

  /// Get total revenue for a restaurant (delivered orders).
  Future<Result<double>> calculateRestaurantRevenue(String restaurantId);

  /// Get recent activity for the dashboard (merged users, orders, applications).
  Future<Result<List<Map<String, dynamic>>>> getRecentActivity(
      {int limit = 10});

  // ── Admin User Creation (Super Admin only) ─────────────────────────────────

  /// Create a new admin user (Firebase Auth + Firestore document).
  Future<Result<void>> createAdminUser({
    required String name,
    required String email,
    required String password,
    UserType role = UserType.admin,
  });

  // ── Broadcast Notifications (Super Admin only) ──────────────────────────────

  /// Send a broadcast notification with all configuration parameters.
  Future<Result<Map<String, dynamic>>> sendBroadcastNotification({
    required String targetAudience,
    String? targetUserId,
    String? targetArea,
    double? centerLat,
    double? centerLng,
    double? radiusKm,
    required String title,
    required String body,
    String? titleAr,
    String? bodyAr,
    String? imageUrl,
    String? targetScreen,
    String? promoCode,
    String? targetEntityId,
    bool sendPush = true,
    bool storeInApp = true,
    String priority = 'high',
    String sound = 'default',
    Map<String, String>? customData,
  });
}
