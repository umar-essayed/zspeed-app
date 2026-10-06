import 'package:equatable/equatable.dart';
import 'package:z_speed/features/order/model/order.dart' as app_order;

/// Date range presets for analytics.
enum AnalyticsRange { today, thisWeek, thisMonth, lastMonth, custom }

/// Aggregated analytics data.
class AnalyticsData {
  final double totalRevenue;
  final int totalOrders;
  final int deliveredOrders;
  final int cancelledOrders;
  final int rejectedOrders;
  final double avgOrderValue;
  final int uniqueCustomers;
  final int newCustomers;
  final int returningCustomers;
  final List<DailyDataPoint> revenueByDay;
  final List<DailyDataPoint> ordersByDay;
  final List<TopItem> topItems;
  final Map<int, int> ordersByHour;
  final double completionRate;

  const AnalyticsData({
    this.totalRevenue = 0,
    this.totalOrders = 0,
    this.deliveredOrders = 0,
    this.cancelledOrders = 0,
    this.rejectedOrders = 0,
    this.avgOrderValue = 0,
    this.uniqueCustomers = 0,
    this.newCustomers = 0,
    this.returningCustomers = 0,
    this.revenueByDay = const [],
    this.ordersByDay = const [],
    this.topItems = const [],
    this.ordersByHour = const {},
    this.completionRate = 0,
  });
}

class DailyDataPoint {
  final DateTime date;
  final double value;
  DailyDataPoint(this.date, this.value);
}

class TopItem {
  final String name;
  final int quantity;
  final double revenue;
  TopItem(this.name, this.quantity, this.revenue);
}

class RestaurantAnalyticsState extends Equatable {
  final bool isLoading;
  final String? error;
  final String? restaurantId;
  final AnalyticsRange selectedRange;
  final DateTime? customStart;
  final DateTime? customEnd;
  final AnalyticsData data;
  final List<app_order.Order> orders;

  const RestaurantAnalyticsState({
    this.isLoading = false,
    this.error,
    this.restaurantId,
    this.selectedRange = AnalyticsRange.thisWeek,
    this.customStart,
    this.customEnd,
    this.data = const AnalyticsData(),
    this.orders = const [],
  });

  RestaurantAnalyticsState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    String? restaurantId,
    AnalyticsRange? selectedRange,
    DateTime? customStart,
    DateTime? customEnd,
    AnalyticsData? data,
    List<app_order.Order>? orders,
  }) {
    return RestaurantAnalyticsState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      restaurantId: restaurantId ?? this.restaurantId,
      selectedRange: selectedRange ?? this.selectedRange,
      customStart: customStart ?? this.customStart,
      customEnd: customEnd ?? this.customEnd,
      data: data ?? this.data,
      orders: orders ?? this.orders,
    );
  }

  DateTime get rangeStart {
    final now = DateTime.now();
    switch (selectedRange) {
      case AnalyticsRange.today:
        return DateTime(now.year, now.month, now.day);
      case AnalyticsRange.thisWeek:
      final daysSinceSaturday = (now.weekday - DateTime.saturday + 7) % 7;
  return DateTime(now.year, now.month, now.day)
      .subtract(Duration(days: daysSinceSaturday));
        // return DateTime(now.year, now.month, now.day)
        //     .subtract(Duration(days: now.weekday));
      case AnalyticsRange.thisMonth:
        return DateTime(now.year, now.month, 1);
      case AnalyticsRange.lastMonth:
        return DateTime(now.year, now.month - 1, 1);
      case AnalyticsRange.custom:
        return customStart ?? DateTime(now.year, now.month, now.day);
    }
  }

  DateTime get rangeEnd {
    final now = DateTime.now();
    switch (selectedRange) {
      case AnalyticsRange.today:
      case AnalyticsRange.thisWeek:
      case AnalyticsRange.thisMonth:
        return now;
      case AnalyticsRange.lastMonth:
        return DateTime(now.year, now.month, 1)
            .subtract(const Duration(seconds: 1));
      case AnalyticsRange.custom:
        return customEnd ?? now;
    }
  }

  @override
  List<Object?> get props => [
        isLoading,
        error,
        restaurantId,
        selectedRange,
        customStart,
        customEnd,
        data,
        orders,
      ];
}
