import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/core/errors/failures.dart';
import 'package:z_speed/features/admin/cubit/admin_analytics_state.dart';
import 'package:z_speed/features/admin/repository/admin_repository.dart';
import 'package:injectable/injectable.dart' hide Order;

@injectable
class AdminAnalyticsCubit extends Cubit<AdminAnalyticsState> {
  final AdminRepository _repository;

  AdminAnalyticsCubit({required this._repository})
    : super(
        AdminAnalyticsState(
          range: DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 30)),
            end: DateTime(
              DateTime.now().year,
              DateTime.now().month,
              DateTime.now().day,
              23,
              59,
              59,
            ),
          ),
        ),
      );

  Future<void> loadAnalytics() async {
    emit(state.copyWith(isBusy: true, hasError: false, failure: null));

    try {
      final revenueResult = await _repository.revenueByDay(state.range!);
      final usersResult = await _repository.userCountsByType();
      final ordersResult = await _repository.orderCountsByStatus(
        range: state.range,
      );

      if (revenueResult.isSuccess &&
          usersResult.isSuccess &&
          ordersResult.isSuccess) {
        emit(
          state.copyWith(
            isBusy: false,
            revenueByDay: revenueResult.data!,
            userCounts: usersResult.data!,
            orderCounts: ordersResult.data!,
          ),
        );
      } else {
        final failure =
            revenueResult.error ?? usersResult.error ?? ordersResult.error;
        emit(state.copyWith(isBusy: false, hasError: true, failure: failure));
      }
    } catch (e) {
      emit(
        state.copyWith(
          isBusy: false,
          hasError: true,
          failure: ServerFailure(e.toString()),
        ),
      );
    }
  }

  void setDateRange(DateTimeRange range) {
    emit(state.copyWith(range: range));
    loadAnalytics();
  }
}
