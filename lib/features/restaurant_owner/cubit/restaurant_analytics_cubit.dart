import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/core/core.dart';
import 'package:z_speed/core/enums/order_enums.dart';
import 'package:z_speed/features/order/model/order.dart' as app_order;
import 'package:z_speed/features/order/repository/order_repository.dart';
import 'package:z_speed/features/order/repository/order_repository_impl.dart';
import 'package:z_speed/features/restaurant/datasource/restaurant_firebase_datasource.dart';
import 'package:z_speed/features/restaurant_owner/cubit/restaurant_analytics_state.dart';
import 'package:injectable/injectable.dart' hide Order;

@injectable
class RestaurantAnalyticsCubit extends Cubit<RestaurantAnalyticsState> {
  final OrderRepository _orderRepository;
  final RestaurantFirebaseDatasource _restaurantDatasource;
  final FirebaseAuth _auth;

  RestaurantAnalyticsCubit({
    OrderRepository? orderRepository,
    RestaurantFirebaseDatasource? restaurantDatasource,
    FirebaseAuth? auth,
  })  : _orderRepository = orderRepository ?? OrderRepositoryImpl(),
        _restaurantDatasource =
            restaurantDatasource ?? RestaurantFirebaseDatasource(),
        _auth = auth ?? FirebaseAuth.instance,
        super(const RestaurantAnalyticsState()) {
    init();
  }

  Future<void> init() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        emit(state.copyWith(isLoading: false, error: 'No authenticated user'));
        return;
      }

      final restaurant = await _restaurantDatasource.getByOwnerId(userId);
      if (restaurant == null) {
        emit(state.copyWith(isLoading: false, error: 'No restaurant found'));
        return;
      }

      emit(state.copyWith(restaurantId: restaurant.id));
      await _loadData();
    } catch (e) {
      emit(
          state.copyWith(isLoading: false, error: 'Analytics init failed: $e'));
    }
  }

  void setRange(AnalyticsRange range, {DateTime? start, DateTime? end}) {
    emit(state.copyWith(
      selectedRange: range,
      customStart: start,
      customEnd: end,
    ));
    _loadData();
  }

  Future<void> _loadData() async {
    if (state.restaurantId == null) return;
    emit(state.copyWith(isLoading: true));

    try {
      final result =
          await _orderRepository.getRestaurantOrders(state.restaurantId!);

      switch (result) {
        case Success(:final data):
          final start = state.rangeStart;
          final end = state.rangeEnd;

          final orders = data
              .where((o) =>
                  o.createdAt
                      .isAfter(start.subtract(const Duration(seconds: 1))) &&
                  o.createdAt.isBefore(end.add(const Duration(days: 1))))
              .toList();

          final analyticsData = await _computeAnalytics(orders);
          emit(state.copyWith(
              isLoading: false, orders: orders, data: analyticsData));

        case Err(:final failure):
          emit(state.copyWith(isLoading: false, error: failure.message));
      }
    } catch (e) {
      emit(state.copyWith(
          isLoading: false, error: 'Failed to load analytics: $e'));
    }
  }

  Future<AnalyticsData> _computeAnalytics(List<app_order.Order> orders) async {
    if (orders.isEmpty) return const AnalyticsData();

    final delivered =
        orders.where((o) => o.status == OrderStatus.delivered).toList();
    final cancelled =
        orders.where((o) => o.status == OrderStatus.cancelled).toList();
    final rejected =
        orders.where((o) => o.status == OrderStatus.refunded).toList();

    final totalRevenue =
        delivered.fold<double>(0, (s, o) => s + (o.subtotal - o.serviceFee));
    final avgOrderValue =
        delivered.isNotEmpty ? totalRevenue / delivered.length : 0.0;

    final allCustomerIds = orders.map((o) => o.customerId).toSet();
    final customerOrderCounts = <String, int>{};
    for (final o in orders) {
      customerOrderCounts[o.customerId] =
          (customerOrderCounts[o.customerId] ?? 0) + 1;
    }
    final returning = customerOrderCounts.values.where((c) => c > 1).length;
    final newCust = allCustomerIds.length - returning;

    final start = state.rangeStart;
    final end = state.rangeEnd;
    final dayCount = end.difference(start).inDays + 1;
    final revenueByDay = <DailyDataPoint>[];
    final ordersByDay = <DailyDataPoint>[];
    for (var i = 0; i < dayCount && i < 90; i++) {
      final dayStart = DateTime(start.year, start.month, start.day + i);
      final dayEnd = dayStart.add(const Duration(days: 1));
      final dayDelivered = delivered
          .where((o) =>
              o.createdAt
                  .isAfter(dayStart.subtract(const Duration(seconds: 1))) &&
              o.createdAt.isBefore(dayEnd))
          .toList();
      revenueByDay.add(DailyDataPoint(
          dayStart,
          dayDelivered.fold<double>(
              0, (s, o) => s + (o.subtotal - o.serviceFee))));
      final dayAllOrders = orders
          .where((o) =>
              o.createdAt
                  .isAfter(dayStart.subtract(const Duration(seconds: 1))) &&
              o.createdAt.isBefore(dayEnd))
          .length;
      ordersByDay.add(DailyDataPoint(dayStart, dayAllOrders.toDouble()));
    }

    final topItemsList = await _computeTopItems(delivered);

    final hourCounts = <int, int>{};
    for (final o in orders) {
      final hour = o.createdAt.hour;
      hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
    }

    final completionRate =
        orders.isNotEmpty ? delivered.length / orders.length : 0.0;

    return AnalyticsData(
      totalRevenue: totalRevenue,
      totalOrders: orders.length,
      deliveredOrders: delivered.length,
      cancelledOrders: cancelled.length,
      rejectedOrders: rejected.length,
      avgOrderValue: avgOrderValue,
      uniqueCustomers: allCustomerIds.length,
      newCustomers: newCust,
      returningCustomers: returning,
      revenueByDay: revenueByDay,
      ordersByDay: ordersByDay,
      topItems: topItemsList,
      ordersByHour: hourCounts,
      completionRate: completionRate,
    );
  }

  Future<List<TopItem>> _computeTopItems(
      List<app_order.Order> deliveredOrders) async {
    final itemCounts = <String, int>{};
    final itemRevenue = <String, double>{};

    final ordersToFetch = deliveredOrders.take(50).toList();
    for (final order in ordersToFetch) {
      if (isClosed) break;
      final result = await _orderRepository.getOrderItems(order.id);
      if (result case Success(:final data)) {
        for (final item in data) {
          final name = item.menuItemName;
          itemCounts[name] = (itemCounts[name] ?? 0) + item.quantity.round();
          itemRevenue[name] = (itemRevenue[name] ?? 0) + item.itemTotal;
        }
      }
    }

    final sorted = itemCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted
        .take(10)
        .map((e) => TopItem(e.key, e.value, itemRevenue[e.key] ?? 0))
        .toList();
  }

  @override
  void emit(RestaurantAnalyticsState state) {
    if (!isClosed) {
      super.emit(state);
    }
  }
}
