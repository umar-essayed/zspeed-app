import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/core/errors/failures.dart';
import 'package:z_speed/features/admin/cubit/admin_orders_state.dart';
import 'package:z_speed/features/admin/model/admin_models.dart';
import 'package:z_speed/features/admin/repository/admin_repository.dart';
import 'package:injectable/injectable.dart' hide Order;

@injectable
class AdminOrdersCubit extends Cubit<AdminOrdersState> {
  final AdminRepository _repository;
  Object? _lastDocument;

  AdminOrdersCubit({required this._repository})
    : super(const AdminOrdersState());

  Future<void> loadOrders({bool isLoadMore = false}) async {
    if (isLoadMore) {
      if (!state.hasMore || state.isLoadingMore) return;
      emit(state.copyWith(isLoadingMore: true));
    } else {
      emit(state.copyWith(isBusy: true, hasError: false, failure: null));
      _lastDocument = null;
    }

    try {
      final result = await _repository.getOrders(
        status: state.statusFilter,
        range: state.dateRange,
        startAfter: _lastDocument,
        limit: 20,
      );

      if (result.isSuccess) {
        final newOrders = result.data!.$1;
        _lastDocument = result.data!.$2;

        final allOrders = isLoadMore
            ? [...state.orders, ...newOrders]
            : newOrders;
        final hasMore = newOrders.length >= 20;

        emit(
          state.copyWith(
            isBusy: false,
            isLoadingMore: false,
            orders: allOrders,
            hasMore: hasMore,
            filteredAdminOrders: _mapOrders(allOrders),
          ),
        );
      } else {
        emit(
          state.copyWith(
            isBusy: false,
            isLoadingMore: false,
            hasError: true,
            failure: result.error,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          isBusy: false,
          isLoadingMore: false,
          hasError: true,
          failure: ServerFailure(e.toString()),
        ),
      );
    }
  }

  void setStatusFilter(OrderStatus? status) {
    emit(state.copyWith(statusFilter: status));
    loadOrders();
  }

  void setDateRange(DateTimeRange? range) {
    if (range == null) {
      emit(state.copyWith(clearDateRange: true));
    } else {
      emit(state.copyWith(dateRange: range));
    }
    loadOrders();
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    final result = await _repository.updateOrderStatus(orderId, status);
    if (result.isSuccess) {
      final updatedOrders = state.orders.map((o) {
        if (o.id == orderId) return o.copyWith(status: status);
        return o;
      }).toList();

      emit(
        state.copyWith(
          orders: updatedOrders,
          filteredAdminOrders: _mapOrders(updatedOrders),
        ),
      );
    }
  }

  Future<void> cancelOrder(String orderId) async {
    final result = await _repository.cancelOrder(
      orderId,
      reason: 'Cancelled by Admin',
    );
    if (result.isSuccess) {
      final updatedOrders = state.orders.map((o) {
        if (o.id == orderId) return o.copyWith(status: OrderStatus.cancelled);
        return o;
      }).toList();

      emit(
        state.copyWith(
          orders: updatedOrders,
          filteredAdminOrders: _mapOrders(updatedOrders),
        ),
      );
    }
  }

  List<AdminOrder> _mapOrders(List<Order> orders) {
    return orders.map((o) {
      return AdminOrder(
        id: o.id,
        customerName: o
            .customerId, // needs translation to name via users repo if required
        restaurantName: o
            .restaurantId, // needs translation to name via restaurant repo if required
        amount: o.total,
        status: o.status,
        items: o.items.length,
        date:
            '${o.createdAt.year}-${o.createdAt.month.toString().padLeft(2, '0')}-${o.createdAt.day.toString().padLeft(2, '0')}',
        time:
            '${o.createdAt.hour.toString().padLeft(2, '0')}:${o.createdAt.minute.toString().padLeft(2, '0')}',
      );
    }).toList();
  }
}
