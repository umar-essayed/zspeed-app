import 'package:equatable/equatable.dart';
import 'package:z_speed/core/enums/order_enums.dart';

enum DateRangeFilter { today, yesterday, last7Days, lastMonth, custom }

class LogisticsKpiFilter extends Equatable {
  final DateRangeFilter dateRange;
  final String? vendorId; // null = all vendors
  final String? driverId; // null = all drivers
  final OrderStatus? status; // null = all statuses
  final PaymentMethodType? paymentMethod; // null = all payment methods
  final bool calculateWithFees; // true = include 15% platform delivery fee cut
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final String searchQuery;

  // Pagination
  final int pageIndex;
  final int pageSize;

  const LogisticsKpiFilter({
    this.dateRange = DateRangeFilter.lastMonth,
    this.vendorId,
    this.driverId,
    this.status,
    this.paymentMethod,
    this.calculateWithFees = true,
    this.customStartDate,
    this.customEndDate,
    this.searchQuery = '',
    this.pageIndex = 0,
    this.pageSize = 10,
  });

  LogisticsKpiFilter copyWith({
    DateRangeFilter? dateRange,
    String? vendorId,
    bool clearVendor = false,
    String? driverId,
    bool clearDriver = false,
    OrderStatus? status,
    bool clearStatus = false,
    PaymentMethodType? paymentMethod,
    bool clearPaymentMethod = false,
    bool? calculateWithFees,
    DateTime? customStartDate,
    DateTime? customEndDate,
    String? searchQuery,
    int? pageIndex,
    int? pageSize,
  }) {
    return LogisticsKpiFilter(
      dateRange: dateRange ?? this.dateRange,
      vendorId: clearVendor ? null : (vendorId ?? this.vendorId),
      driverId: clearDriver ? null : (driverId ?? this.driverId),
      status: clearStatus ? null : (status ?? this.status),
      paymentMethod: clearPaymentMethod ? null : (paymentMethod ?? this.paymentMethod),
      calculateWithFees: calculateWithFees ?? this.calculateWithFees,
      customStartDate: customStartDate ?? this.customStartDate,
      customEndDate: customEndDate ?? this.customEndDate,
      searchQuery: searchQuery ?? this.searchQuery,
      pageIndex: pageIndex ?? this.pageIndex,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  @override
  List<Object?> get props => [
        dateRange,
        vendorId,
        driverId,
        status,
        paymentMethod,
        calculateWithFees,
        customStartDate,
        customEndDate,
        searchQuery,
        pageIndex,
        pageSize,
      ];
}

class LogisticsKpiStats extends Equatable {
  final double restaurantGrossSales;
  final double totalDeliveryFeesCollected;
  final int totalTripsCompleted;
  final int activeOrdersCount;
  final double overallRideAcceptanceRate;
  final double masterAdminCommission;
  final double platformDeliveryCut;
  final double riderTotalPayout;
  final double totalNetProfit;

  const LogisticsKpiStats({
    this.restaurantGrossSales = 0.0,
    this.totalDeliveryFeesCollected = 0.0,
    this.totalTripsCompleted = 0,
    this.activeOrdersCount = 0,
    this.overallRideAcceptanceRate = 0.94,
    this.masterAdminCommission = 0.0,
    this.platformDeliveryCut = 0.0,
    this.riderTotalPayout = 0.0,
    this.totalNetProfit = 0.0,
  });

  @override
  List<Object?> get props => [
        restaurantGrossSales,
        totalDeliveryFeesCollected,
        totalTripsCompleted,
        activeOrdersCount,
        overallRideAcceptanceRate,
        masterAdminCommission,
        platformDeliveryCut,
        riderTotalPayout,
        totalNetProfit,
      ];
}

class VendorFinancialSummary {
  final String vendorId;
  final String vendorName;
  final double netSales;
  final double masterCommissionDeducted;
  final double amountDueToVendor;
  final int orderCount;

  VendorFinancialSummary({
    required this.vendorId,
    required this.vendorName,
    required this.netSales,
    required this.masterCommissionDeducted,
    required this.amountDueToVendor,
    required this.orderCount,
  });
}

class RiderPerformanceSummary {
  final String riderId;
  final String riderName;
  final int tripsCompleted;
  final double totalDeliveryFeesEarned;
  final double riderPayout;
  final double platformFeeCut;

  RiderPerformanceSummary({
    required this.riderId,
    required this.riderName,
    required this.tripsCompleted,
    required this.totalDeliveryFeesEarned,
    required this.riderPayout,
    required this.platformFeeCut,
  });
}
