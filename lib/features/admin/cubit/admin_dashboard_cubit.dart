import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/features/admin/cubit/admin_dashboard_state.dart';
import 'package:z_speed/features/admin/model/admin_models.dart';
import 'package:z_speed/features/admin/repository/admin_repository.dart';
import 'package:z_speed/core/errors/failures.dart';
import 'package:injectable/injectable.dart' hide Order;

@injectable
class AdminDashboardCubit extends Cubit<AdminDashboardState> {
  final AdminRepository _adminRepository;

  AdminDashboardCubit({required this._adminRepository})
    : super(const AdminDashboardState());

  Future<void> loadDashboard() async {
    if (isClosed) return;
    emit(state.copyWith(isBusy: true, hasError: false, failure: null));

    try {
      final statsResult = await _adminRepository.getDashboardStats();
      final activityResult = await _adminRepository.getRecentActivity(limit: 5);
      final ordersResult = await _adminRepository.getOrders(limit: 5);

      if (isClosed) return;
      if (statsResult.isSuccess &&
          activityResult.isSuccess &&
          ordersResult.isSuccess) {
        final stats = statsResult.data!;

        final statCards = [
          StatCardData(
            title: 'Total Users',
            key: StatCardKey.totalUsers,
            value: stats.totalUsers.toString(),
            change: '+5%',
            icon: Icons.people_outline,
            color: const Color(0xFF4CAF50),
            secondaryColor: const Color(0xFF81C784),
            trend: StatTrend.up,
          ),
          StatCardData(
            title: 'Total Orders',
            key: StatCardKey.totalOrders,
            value: stats.totalOrders.toString(),
            change: '+12%',
            icon: Icons.shopping_cart_outlined,
            color: const Color(0xFF2196F3),
            secondaryColor: const Color(0xFF64B5F6),
            trend: StatTrend.up,
          ),
          StatCardData(
            title: 'Total Revenue',
            key: StatCardKey.totalRevenue,
            value: 'EGP ${stats.totalRevenue.toStringAsFixed(2)}',
            change: '+8%',
            icon: Icons.attach_money,
            color: const Color(0xFF9C27B0),
            secondaryColor: const Color(0xFFBA68C8),
            trend: StatTrend.up,
          ),
          StatCardData(
            title: 'Pending Orders',
            key: StatCardKey.pendingOrders,
            value: stats.pendingOrders.toString(),
            change: '-2%',
            icon: Icons.pending_actions,
            color: const Color(0xFFFF9800),
            secondaryColor: const Color(0xFFFFB74D),
            trend: StatTrend.down,
          ),
        ];

        final activities = activityResult.data!
            .map((data) => _mapToActivity(data))
            .toList();
        final orders = ordersResult.data!.$1
            .map((data) => _mapToAdminOrder(data))
            .toList();

        emit(
          state.copyWith(
            isBusy: false,
            rawStats: stats,
            statCards: statCards,
            recentActivities: activities,
            recentOrders: orders,
          ),
        );
      } else {
        if (isClosed) return;
        final failure =
            statsResult.error ?? activityResult.error ?? ordersResult.error;
        emit(state.copyWith(isBusy: false, hasError: true, failure: failure));
      }
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          isBusy: false,
          hasError: true,
          failure: ServerFailure(e.toString()),
        ),
      );
    }
  }

  AdminActivity _mapToActivity(Map<String, dynamic> data) {
    return AdminActivity(
      title: data['title'] ?? 'Unknown Activity',
      description: data['description'] ?? '',
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] as DateTime)
          : DateTime.now(),
      type: AdminActivityType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => AdminActivityType.userRegistration,
      ),
    );
  }

  AdminOrder _mapToAdminOrder(Order order) {
    return AdminOrder(
      id: order.id,
      customerName: order
          .customerId, // Needs user repo to resolve names in a real scenario
      restaurantName:
          order.restaurantId, // Needs restaurant repo to resolve names
      amount: order.total,
      status: order.status,
      items: order.items.length,
      date:
          '${order.createdAt.year}-${order.createdAt.month}-${order.createdAt.day}',
      time: '${order.createdAt.hour}:${order.createdAt.minute}',
    );
  }
}
