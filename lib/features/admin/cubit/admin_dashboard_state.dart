import 'package:equatable/equatable.dart';
import 'package:z_speed/core/errors/failures.dart';
import 'package:z_speed/features/admin/model/admin_models.dart';
import 'package:z_speed/features/admin/model/admin_dashboard_stats.dart';

class AdminDashboardState extends Equatable {
  final bool isBusy;
  final bool hasError;
  final Failure? failure;
  final AdminDashboardStats? rawStats;
  final List<StatCardData> statCards;
  final List<AdminOrder> recentOrders;
  final List<AdminActivity> recentActivities;

  const AdminDashboardState({
    this.isBusy = false,
    this.hasError = false,
    this.failure,
    this.rawStats,
    this.statCards = const [],
    this.recentOrders = const [],
    this.recentActivities = const [],
  });

  AdminDashboardState copyWith({
    bool? isBusy,
    bool? hasError,
    Failure? failure,
    AdminDashboardStats? rawStats,
    List<StatCardData>? statCards,
    List<AdminOrder>? recentOrders,
    List<AdminActivity>? recentActivities,
  }) {
    return AdminDashboardState(
      isBusy: isBusy ?? this.isBusy,
      hasError: hasError ?? this.hasError,
      failure: failure ?? this.failure,
      rawStats: rawStats ?? this.rawStats,
      statCards: statCards ?? this.statCards,
      recentOrders: recentOrders ?? this.recentOrders,
      recentActivities: recentActivities ?? this.recentActivities,
    );
  }

  @override
  List<Object?> get props => [
        isBusy,
        hasError,
        failure,
        rawStats,
        statCards,
        recentOrders,
        recentActivities,
      ];
}
