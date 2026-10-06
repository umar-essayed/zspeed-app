import 'package:equatable/equatable.dart';
import 'package:z_speed/core/enums/order_enums.dart';
import 'package:z_speed/core/errors/failures.dart';
import 'package:z_speed/features/driver/model/delivery_request.dart';
import 'package:z_speed/features/driver/model/driver_profile.dart';
import 'package:z_speed/features/order/model/order.dart';
import 'package:z_speed/features/transport/model/ride_model.dart';

class DriverDashboardState extends Equatable {
  final bool isBusy;
  final bool isUpdatingLocation;
  final bool noLocationError;
  final Failure? failure;
  final DriverProfile? driverProfile;
  final List<DeliveryRequest> pendingRequests;
  final List<Order> activeOrders;
  final List<Order> orderHistory;
  final List<RideModel> transportHistory;
  final String? deliveredOrderId;
  final double globalEarningsLimit;
  final int? transportPendingCount;
  final int? transportActiveCount;

  const DriverDashboardState({
    this.isBusy = false,
    this.isUpdatingLocation = false,
    this.noLocationError = false,
    this.failure,
    this.driverProfile,
    this.pendingRequests = const [],
    this.activeOrders = const [],
    this.orderHistory = const [],
    this.transportHistory = const [],
    this.deliveredOrderId,
    this.globalEarningsLimit = 0.0,
    this.transportPendingCount,
    this.transportActiveCount,
  });

  bool get hasError => failure != null;

  int get pendingCount => transportPendingCount ?? pendingRequests.length;
  int get activeCount => transportActiveCount ?? activeOrders.length;

  /// Calculates total earnings for today across delivered food orders and completed rides.
  double get todaysEarnings {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    double total = 0.0;
    for (final order in orderHistory) {
      if (order.status == OrderStatus.delivered) {
        final date = order.deliveredAt ?? order.createdAt;
        if (date.isAfter(startOfDay) || date.isAtSameMomentAs(startOfDay)) {
          total += order.deliveryFee;
        }
      }
    }
    for (final ride in transportHistory) {
      if (ride.status == RideStatus.completed) {
        final date = ride.completedAt ?? ride.requestedAt;
        if (date.isAfter(startOfDay) || date.isAtSameMomentAs(startOfDay)) {
          total += ride.totalFare;
        }
      }
    }
    return total;
  }

  /// Calculates total trips count, matching completed items in history or profile.
  int get totalTripsCount {
    final profileTrips = driverProfile?.totalTrips ?? 0;
    final deliveredOrders = orderHistory
        .where((o) => o.status == OrderStatus.delivered)
        .length;
    final completedRides = transportHistory
        .where((r) => r.status == RideStatus.completed)
        .length;
    final historyTrips = deliveredOrders + completedRides;
    return profileTrips > historyTrips ? profileTrips : historyTrips;
  }

  bool get isLockedDueToEarningsLimit {
    final profile = driverProfile;
    if (profile == null) return false;
    if (profile.isLimitLocked) return true;
    final customLimit = profile.earningsLimit;
    if (customLimit > 0.0 && profile.totalEarnings >= customLimit) {
      return true;
    }
    final limitToUse = (customLimit > 0.0) ? customLimit : globalEarningsLimit;
    if (limitToUse > 0.0 && profile.totalEarnings >= limitToUse) {
      return true;
    }
    return false;
  }

  DriverDashboardState copyWith({
    bool? isBusy,
    bool? isUpdatingLocation,
    bool? noLocationError,
    Failure? failure,
    DriverProfile? driverProfile,
    List<DeliveryRequest>? pendingRequests,
    List<Order>? activeOrders,
    List<Order>? orderHistory,
    List<RideModel>? transportHistory,
    bool clearFailure = false,
    String? deliveredOrderId,
    bool clearDeliveredOrderId = false,
    double? globalEarningsLimit,
    int? transportPendingCount,
    int? transportActiveCount,
  }) {
    return DriverDashboardState(
      isBusy: isBusy ?? this.isBusy,
      isUpdatingLocation: isUpdatingLocation ?? this.isUpdatingLocation,
      noLocationError: noLocationError ?? this.noLocationError,
      failure: clearFailure ? null : (failure ?? this.failure),
      driverProfile: driverProfile ?? this.driverProfile,
      pendingRequests: pendingRequests ?? this.pendingRequests,
      activeOrders: activeOrders ?? this.activeOrders,
      orderHistory: orderHistory ?? this.orderHistory,
      transportHistory: transportHistory ?? this.transportHistory,
      deliveredOrderId: clearDeliveredOrderId
          ? null
          : (deliveredOrderId ?? this.deliveredOrderId),
      globalEarningsLimit: globalEarningsLimit ?? this.globalEarningsLimit,
      transportPendingCount:
          transportPendingCount ?? this.transportPendingCount,
      transportActiveCount: transportActiveCount ?? this.transportActiveCount,
    );
  }

  @override
  List<Object?> get props => [
    isBusy,
    isUpdatingLocation,
    noLocationError,
    failure,
    driverProfile,
    pendingRequests,
    activeOrders,
    orderHistory,
    transportHistory,
    deliveredOrderId,
    globalEarningsLimit,
    transportPendingCount,
    transportActiveCount,
  ];
}
