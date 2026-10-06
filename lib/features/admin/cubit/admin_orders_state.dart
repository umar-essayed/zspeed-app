import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:z_speed/core/errors/failures.dart';
import 'package:z_speed/features/admin/model/admin_models.dart';

class AdminOrdersState extends Equatable {
  final bool isBusy;
  final bool hasError;
  final Failure? failure;
  final List<Order> orders;
  final List<AdminOrder> filteredAdminOrders;
  final OrderStatus? statusFilter;
  final DateTimeRange? dateRange;
  final bool hasMore;
  final bool isLoadingMore;

  const AdminOrdersState({
    this.isBusy = false,
    this.hasError = false,
    this.failure,
    this.orders = const [],
    this.filteredAdminOrders = const [],
    this.statusFilter,
    this.dateRange,
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  AdminOrdersState copyWith({
    bool? isBusy,
    bool? hasError,
    Failure? failure,
    List<Order>? orders,
    List<AdminOrder>? filteredAdminOrders,
    OrderStatus? statusFilter,
    DateTimeRange? dateRange,
    bool? hasMore,
    bool? isLoadingMore,
    bool clearDateRange = false,
  }) {
    return AdminOrdersState(
      isBusy: isBusy ?? this.isBusy,
      hasError: hasError ?? this.hasError,
      failure: failure ?? this.failure,
      orders: orders ?? this.orders,
      filteredAdminOrders: filteredAdminOrders ?? this.filteredAdminOrders,
      statusFilter: statusFilter ?? this.statusFilter,
      dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [
        isBusy,
        hasError,
        failure,
        orders,
        filteredAdminOrders,
        statusFilter,
        dateRange,
        hasMore,
        isLoadingMore,
      ];
}
