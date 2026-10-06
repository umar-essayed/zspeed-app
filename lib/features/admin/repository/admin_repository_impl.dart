import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:z_speed/core/core.dart';
import 'package:z_speed/core/enums/enums.dart';
import 'package:z_speed/features/admin/datasource/admin_firebase_datasource.dart';
import 'package:z_speed/features/admin/model/admin_dashboard_stats.dart';
import 'package:z_speed/features/admin/repository/admin_repository.dart';
import 'package:z_speed/features/auth/model/user_model.dart';
import 'package:z_speed/features/order/model/order.dart';
import 'package:z_speed/features/restaurant/model/restaurant.dart';
import 'package:cloud_functions/cloud_functions.dart' hide Result;
import 'package:injectable/injectable.dart' hide Order;

/// Implementation of AdminRepository using Firestore datasource.
@LazySingleton(as: AdminRepository)
class AdminRepositoryImpl implements AdminRepository {
  final AdminFirebaseDatasource _datasource;

  AdminRepositoryImpl({AdminFirebaseDatasource? datasource})
      : _datasource = datasource ?? AdminFirebaseDatasource();

  // ── Dashboard Stats ────────────────────────────────────────────────────────

  @override
  Future<Result<AdminDashboardStats>> getDashboardStats() async {
    try {
      // Fetch all stats in parallel
      final results = await Future.wait([
        _datasource.countUsers(),
        _datasource.countOrders(),
        _datasource.countRestaurants(),
        _datasource.calculateRevenue(),
        _datasource.countOrders(status: OrderStatus.pending),
        _datasource.countUsers(
          type: UserType.driver,
          // Assuming active drivers have active status
        ),
        _datasource.countPendingApplications(),
        _datasource.userCountsByType(),
        _datasource.orderCountsByStatus(),
      ]);

      final stats = AdminDashboardStats(
        totalUsers: results[0] as int,
        totalOrders: results[1] as int,
        totalRestaurants: results[2] as int,
        totalRevenue: results[3] as double,
        pendingOrders: results[4] as int,
        activeDrivers: results[5] as int,
        pendingApplications: results[6] as int,
        usersByType: results[7] as Map<UserType, int>,
        ordersByStatus: results[8] as Map<OrderStatus, int>,
      );

      return Success(stats);
    } catch (e, stackTrace) {
      return Err(
        UnexpectedFailure(
          'Failed to load dashboard stats: ${e.toString()}',
          stackTrace,
        ),
      );
    }
  }

  @override
  Stream<AdminDashboardStats> streamDashboardStats() async* {
    // For simplicity, poll every 30 seconds
    // In production, you might want more sophisticated streaming
    while (true) {
      final result = await getDashboardStats();
      if (result is Success<AdminDashboardStats>) {
        yield result.data;
      }
      await Future.delayed(const Duration(seconds: 30));
    }
  }

  // ── User Management ────────────────────────────────────────────────────────

  @override
  Future<Result<(List<AppUser>, Object?)>> getUsers({
    UserType? type,
    UserStatus? status,
    Object? startAfter,
    int limit = 20,
  }) async {
    try {
      final (users, lastDoc) = await _datasource.getUsers(
        type: type,
        status: status,
        startAfter: startAfter as DocumentSnapshot?,
        limit: limit,
      );
      return Success((users, lastDoc));
    } catch (e, stackTrace) {
      return Err(
        UnexpectedFailure(
          'Failed to fetch users: ${e.toString()}',
          stackTrace,
        ),
      );
    }
  }

  @override
  Future<Result<void>> updateUserStatus(
    String userId,
    UserStatus status,
  ) async {
    try {
      await _datasource.updateUserStatus(userId, status);
      return Success(null);
    } catch (e, stackTrace) {
      return Err(
        UnexpectedFailure(
          'Failed to update user status: ${e.toString()}',
          stackTrace,
        ),
      );
    }
  }

  @override
  Future<Result<void>> updateUserType(String userId, UserType type) async {
    try {
      await _datasource.updateUserType(userId, type);
      return Success(null);
    } catch (e, stackTrace) {
      return Err(
        UnexpectedFailure(
          'Failed to update user type: ${e.toString()}',
          stackTrace,
        ),
      );
    }
  }

  @override
  Future<Result<void>> deleteUser(String userId) async {
    try {
      await _datasource.deleteUser(userId);
      return Success(null);
    } catch (e, stackTrace) {
      return Err(
        UnexpectedFailure(
          'Failed to delete user: ${e.toString()}',
          stackTrace,
        ),
      );
    }
  }

  // ── Order Management ───────────────────────────────────────────────────────

  @override
  Future<Result<(List<Order>, Object?)>> getOrders({
    OrderStatus? status,
    DateTimeRange? range,
    Object? startAfter,
    int limit = 20,
  }) async {
    try {
      final (orders, lastDoc) = await _datasource.getOrders(
        status: status,
        range: range,
        startAfter: startAfter as DocumentSnapshot?,
        limit: limit,
      );
      return Success((orders, lastDoc));
    } catch (e, stackTrace) {
      return Err(
        UnexpectedFailure(
          'Failed to fetch orders: ${e.toString()}',
          stackTrace,
        ),
      );
    }
  }

  @override
  Future<Result<void>> updateOrderStatus(
    String orderId,
    OrderStatus status,
  ) async {
    try {
      await _datasource.updateOrderStatus(orderId, status);
      return Success(null);
    } catch (e, stackTrace) {
      return Err(
        UnexpectedFailure(
          'Failed to update order status: ${e.toString()}',
          stackTrace,
        ),
      );
    }
  }

  @override
  Future<Result<void>> cancelOrder(String orderId, {String? reason}) async {
    try {
      await _datasource.cancelOrder(orderId, reason: reason);
      return Success(null);
    } catch (e, stackTrace) {
      return Err(
        UnexpectedFailure(
          'Failed to cancel order: ${e.toString()}',
          stackTrace,
        ),
      );
    }
  }

  // ── Restaurant/Vendor Management ───────────────────────────────────────────

  @override
  Future<Result<(List<Restaurant>, Object?)>> getVendors({
    RestaurantStatus? status,
    VendorType? vendorType,
    Object? startAfter,
    int limit = 20,
  }) async {
    try {
      final (vendors, lastDoc) = await _datasource.getVendors(
        status: status,
        vendorType: vendorType,
        startAfter: startAfter as DocumentSnapshot?,
        limit: limit,
      );
      return Success((vendors, lastDoc));
    } catch (e, stackTrace) {
      return Err(
        UnexpectedFailure(
          'Failed to fetch vendors: ${e.toString()}',
          stackTrace,
        ),
      );
    }
  }

  @override
  Future<Result<void>> updateRestaurantStatus(
    String restaurantId,
    RestaurantStatus status,
  ) async {
    try {
      await _datasource.updateRestaurantStatus(restaurantId, status);
      return Success(null);
    } catch (e, stackTrace) {
      return Err(
        UnexpectedFailure(
          'Failed to update restaurant status: ${e.toString()}',
          stackTrace,
        ),
      );
    }
  }

  @override
  Future<Result<void>> updateRestaurantVendorType(
      String restaurantId, VendorType vendorType) async {
    try {
      await _datasource.updateRestaurantVendorType(restaurantId, vendorType);
      return Success(null);
    } catch (e, stackTrace) {
      return Err(UnexpectedFailure(
          'Failed to update vendorType: ${e.toString()}', stackTrace));
    }
  }

  @override
  Future<Result<void>> updateRestaurantPriority(
      String restaurantId, int priority) async {
    try {
      await _datasource.updateRestaurantPriority(restaurantId, priority);
      return Success(null);
    } catch (e, stackTrace) {
      return Err(UnexpectedFailure(
          'Failed to update vendor priority: ${e.toString()}', stackTrace));
    }
  }

  @override
  Future<Result<void>> updateRestaurant(Restaurant restaurant) async {
    try {
      await _datasource.updateRestaurant(restaurant);
      return Success(null);
    } catch (e, stackTrace) {
      return Err(UnexpectedFailure(
          'Failed to update restaurant: ${e.toString()}', stackTrace));
    }
  }

  @override
  Future<Result<void>> createVendor(Restaurant restaurant) async {
    try {
      await _datasource.createVendor(restaurant);
      return Success(null);
    } catch (e, stackTrace) {
      return Err(UnexpectedFailure(
          'Failed to create vendor: ${e.toString()}', stackTrace));
    }
  }

  @override
  Future<Result<void>> deleteRestaurant(String restaurantId) async {
    try {
      await _datasource.deleteRestaurant(restaurantId);
      return Success(null);
    } catch (e, stackTrace) {
      return Err(
        UnexpectedFailure(
          'Failed to delete restaurant: ${e.toString()}',
          stackTrace,
        ),
      );
    }
  }

  // ── Analytics ──────────────────────────────────────────────────────────────

  @override
  Future<Result<Map<String, double>>> revenueByDay(
    DateTimeRange range,
  ) async {
    try {
      final revenue = await _datasource.revenueByDay(range: range);
      return Success(revenue);
    } catch (e, stackTrace) {
      return Err(
        UnexpectedFailure(
          'Failed to fetch revenue data: ${e.toString()}',
          stackTrace,
        ),
      );
    }
  }

  @override
  Future<Result<Map<UserType, int>>> userCountsByType() async {
    try {
      final counts = await _datasource.userCountsByType();
      return Success(counts);
    } catch (e, stackTrace) {
      return Err(
        UnexpectedFailure(
          'Failed to fetch user counts: ${e.toString()}',
          stackTrace,
        ),
      );
    }
  }

  @override
  Future<Result<Map<OrderStatus, int>>> orderCountsByStatus({DateTimeRange? range}) async {
    try {
      final counts = await _datasource.orderCountsByStatus(range: range);
      return Success(counts);
    } catch (e, stackTrace) {
      return Err(
        UnexpectedFailure(
          'Failed to fetch order counts: ${e.toString()}',
          stackTrace,
        ),
      );
    }
  }

  // ── Name Resolution ────────────────────────────────────────────────────────

  @override
  Future<Result<Map<String, String>>> getUserNamesByIds(
    Set<String> userIds,
  ) async {
    try {
      final names = await _datasource.getUserNamesByIds(userIds);
      return Success(names);
    } catch (e, stackTrace) {
      return Err(
        UnexpectedFailure(
          'Failed to resolve user names: ${e.toString()}',
          stackTrace,
        ),
      );
    }
  }

  @override
  Future<Result<Map<String, String>>> getRestaurantNamesByIds(
    Set<String> restaurantIds,
  ) async {
    try {
      final names = await _datasource.getRestaurantNamesByIds(restaurantIds);
      return Success(names);
    } catch (e, stackTrace) {
      return Err(
        UnexpectedFailure(
          'Failed to resolve restaurant names: ${e.toString()}',
          stackTrace,
        ),
      );
    }
  }

  @override
  Future<Result<int>> countOrdersToday(String restaurantId) async {
    try {
      final count = await _datasource.countOrdersToday(restaurantId);
      return Success(count);
    } catch (e, stackTrace) {
      return Err(
        UnexpectedFailure(
          'Failed to count today\'s orders: ${e.toString()}',
          stackTrace,
        ),
      );
    }
  }

  @override
  Future<Result<double>> calculateRestaurantRevenue(
    String restaurantId,
  ) async {
    try {
      final revenue =
          await _datasource.calculateRestaurantRevenue(restaurantId);
      return Success(revenue);
    } catch (e, stackTrace) {
      return Err(
        UnexpectedFailure(
          'Failed to calculate restaurant revenue: ${e.toString()}',
          stackTrace,
        ),
      );
    }
  }

  // ── Recent Activity ────────────────────────────────────────────────────────

  @override
  Future<Result<List<Map<String, dynamic>>>> getRecentActivity({
    int limit = 10,
  }) async {
    try {
      final activities = await _datasource.getRecentActivity(limit: limit);
      return Success(activities);
    } catch (e, stackTrace) {
      return Err(
        UnexpectedFailure(
          'Failed to fetch recent activity: ${e.toString()}',
          stackTrace,
        ),
      );
    }
  }

  // ── Admin User Creation (Super Admin only) ─────────────────────────────────

  @override
  Future<Result<void>> createAdminUser({
    required String name,
    required String email,
    required String password,
    UserType role = UserType.admin,
  }) async {
    try {
      await _datasource.createAdminUser(
        name: name,
        email: email,
        password: password,
        role: role,
      );
      return Success(null);
    } catch (e, stackTrace) {
      return Err(
        UnexpectedFailure(
          'Failed to create admin user: ${e.toString()}',
          stackTrace,
        ),
      );
    }
  }

  // ── Broadcast Notifications (Super Admin only) ──────────────────────────────

  @override
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
  }) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('sendBroadcastNotification');
      final response = await callable.call({
        'targetAudience': targetAudience,
        if (targetUserId != null && targetUserId.isNotEmpty) 'targetUserId': targetUserId,
        if (targetArea != null && targetArea.isNotEmpty) 'targetArea': targetArea,
        'centerLat': ?centerLat,
        'centerLng': ?centerLng,
        'radiusKm': ?radiusKm,
        'title': title,
        'body': body,
        if (titleAr != null && titleAr.isNotEmpty) 'titleAr': titleAr,
        if (bodyAr != null && bodyAr.isNotEmpty) 'bodyAr': bodyAr,
        if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
        if (targetScreen != null && targetScreen.isNotEmpty) 'targetScreen': targetScreen,
        if (promoCode != null && promoCode.isNotEmpty) 'promoCode': promoCode,
        if (targetEntityId != null && targetEntityId.isNotEmpty) 'targetEntityId': targetEntityId,
        'sendPush': sendPush,
        'storeInApp': storeInApp,
        'priority': priority,
        'sound': sound,
        if (customData != null && customData.isNotEmpty) 'customData': customData,
      });

      final resultMap = Map<String, dynamic>.from(response.data as Map? ?? {});
      return Success(resultMap);
    } catch (e, stackTrace) {
      return Err(
        UnexpectedFailure(
          'Failed to send broadcast notification: ${e.toString()}',
          stackTrace,
        ),
      );
    }
  }
}
