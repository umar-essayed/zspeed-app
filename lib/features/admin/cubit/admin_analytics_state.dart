import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:z_speed/core/errors/failures.dart';
import 'package:z_speed/features/admin/model/admin_models.dart';

class AdminAnalyticsState extends Equatable {
  final bool isBusy;
  final bool hasError;
  final Failure? failure;
  final Map<String, double> revenueByDay;
  final Map<UserType, int> userCounts;
  final Map<OrderStatus, int> orderCounts;
  final DateTimeRange? range;

  const AdminAnalyticsState({
    this.isBusy = false,
    this.hasError = false,
    this.failure,
    this.revenueByDay = const {},
    this.userCounts = const {},
    this.orderCounts = const {},
    this.range,
  });

  AdminAnalyticsState copyWith({
    bool? isBusy,
    bool? hasError,
    Failure? failure,
    Map<String, double>? revenueByDay,
    Map<UserType, int>? userCounts,
    Map<OrderStatus, int>? orderCounts,
    DateTimeRange? range,
  }) {
    return AdminAnalyticsState(
      isBusy: isBusy ?? this.isBusy,
      hasError: hasError ?? this.hasError,
      failure: failure ?? this.failure,
      revenueByDay: revenueByDay ?? this.revenueByDay,
      userCounts: userCounts ?? this.userCounts,
      orderCounts: orderCounts ?? this.orderCounts,
      range: range ?? this.range,
    );
  }

  @override
  List<Object?> get props => [
        isBusy,
        hasError,
        failure,
        revenueByDay,
        userCounts,
        orderCounts,
        range,
      ];
}
