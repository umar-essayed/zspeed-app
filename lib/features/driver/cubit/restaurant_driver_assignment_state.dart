import 'package:equatable/equatable.dart';
import 'package:z_speed/core/errors/failures.dart';
import 'package:z_speed/features/driver/model/driver_profile.dart';
import 'package:z_speed/features/driver/model/order_driver.dart';
import 'package:z_speed/features/order/model/order.dart';
import 'package:z_speed/features/restaurant/model/restaurant.dart';

class RestaurantDriverAssignmentState extends Equatable {
  final bool isBusy;
  final Failure? failure;
  final Order? order;
  final Restaurant? restaurant;
  final List<OrderDriver> assignedDrivers;
  final List<DriverProfile> onlineDrivers;

  const RestaurantDriverAssignmentState({
    this.isBusy = false,
    this.failure,
    this.order,
    this.restaurant,
    this.assignedDrivers = const [],
    this.onlineDrivers = const [],
  });

  bool get hasError => failure != null;

  RestaurantDriverAssignmentState copyWith({
    bool? isBusy,
    Failure? failure,
    Order? order,
    Restaurant? restaurant,
    List<OrderDriver>? assignedDrivers,
    List<DriverProfile>? onlineDrivers,
    bool clearFailure = false,
  }) {
    return RestaurantDriverAssignmentState(
      isBusy: isBusy ?? this.isBusy,
      failure: clearFailure ? null : (failure ?? this.failure),
      order: order ?? this.order,
      restaurant: restaurant ?? this.restaurant,
      assignedDrivers: assignedDrivers ?? this.assignedDrivers,
      onlineDrivers: onlineDrivers ?? this.onlineDrivers,
    );
  }

  @override
  List<Object?> get props => [
        isBusy,
        failure,
        order,
        restaurant,
        assignedDrivers,
        onlineDrivers,
      ];
}
