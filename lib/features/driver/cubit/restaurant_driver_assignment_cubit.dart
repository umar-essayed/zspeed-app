import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/core/enums/driver_enums.dart';
import 'package:z_speed/core/enums/user_enums.dart';
import 'package:z_speed/core/services/delivery_fee_calculator.dart';

import 'package:z_speed/features/driver/cubit/restaurant_driver_assignment_state.dart';
import 'package:z_speed/features/driver/model/delivery_request.dart';
import 'package:z_speed/features/driver/model/driver_profile.dart';
import 'package:z_speed/features/driver/model/order_driver.dart';
import 'package:z_speed/features/driver/repository/driver_repository.dart';
import 'package:z_speed/features/order/model/order.dart';
import 'package:z_speed/features/restaurant/model/restaurant.dart';
import 'package:injectable/injectable.dart' hide Order;

@injectable
class RestaurantDriverAssignmentCubit
    extends Cubit<RestaurantDriverAssignmentState> {
  final DriverRepository repository;

  StreamSubscription? _assignedDriversSub;
  StreamSubscription? _onlineDriversSub;

  RestaurantDriverAssignmentCubit({required this.repository})
      : super(const RestaurantDriverAssignmentState());

  @override
  Future<void> close() {
    _assignedDriversSub?.cancel();
    _onlineDriversSub?.cancel();
    return super.close();
  }

  void init(String orderId, Order order, Restaurant restaurant) {
    emit(state.copyWith(
      order: order,
      restaurant: restaurant,
      isBusy: true,
      clearFailure: true,
    ));

    _assignedDriversSub?.cancel();
    _assignedDriversSub = repository.streamOrderDrivers(orderId).listen(
      (drivers) {
        emit(state.copyWith(assignedDrivers: drivers, isBusy: false));
      },
      onError: (e) {
        emit(state.copyWith(isBusy: false));
      },
    );

    _onlineDriversSub?.cancel();
    _onlineDriversSub = repository.streamOnlineDrivers().listen(
      (drivers) {
        emit(state.copyWith(onlineDrivers: drivers, isBusy: false));
      },
      onError: (e) {
        debugPrint('RestaurantDriverAssignmentCubit: streamOnlineDrivers error: $e');
      },
    );
  }

  /// Distance from restaurant to customer (second leg of the delivery trip).
  double getDistanceToCustomer() {
    if (state.restaurant == null || state.order == null) return 0.0;
    return DeliveryFeeCalculator.calculateDistanceKm(
      state.restaurant!.latitude,
      state.restaurant!.longitude,
      state.order!.deliveryLat,
      state.order!.deliveryLng,
    );
  }

  bool isWithinDeliveryRadius() {
    if (state.restaurant == null) return false;
    final distance = getDistanceToCustomer();
    return distance <= state.restaurant!.deliveryRadiusKm;
  }

  double get deliveryFeePerDriver {
    return state.restaurant?.deliveryFee ?? 0.0;
  }

  double get totalDeliveryFee {
    return deliveryFeePerDriver *
        (state.assignedDrivers.isEmpty ? 1 : state.assignedDrivers.length);
  }

  int get assignedDriverCount => state.assignedDrivers.length;

  List<OrderDriver> get assignedDrivers => state.assignedDrivers;

  List<DriverProfile> get availableDrivers {
    // Only consider active assignments (pending/accepted/pickedUp) as "taken"
    final activeStatuses = {
      DriverAssignmentStatus.pending,
      DriverAssignmentStatus.accepted,
      DriverAssignmentStatus.pickedUp,
    };
    final assignedIds = state.assignedDrivers
        .where((d) => activeStatuses.contains(d.status))
        .map((d) => d.driverUserId)
        .toSet();
    log('[RESTAURANT] onlineDrivers total: ${state.onlineDrivers.length}, activeAssignedIds: $assignedIds');
    for (final d in state.onlineDrivers) {
      log('[RESTAURANT]   driver userId=${d.userId} name="${d.name}" status=${d.status} inAssigned=${assignedIds.contains(d.userId)}');
    }
    final result = state.onlineDrivers.where((d) {
      final isBasicAvailable = !assignedIds.contains(d.userId) &&
          (d.status == DriverStatus.online || d.status == DriverStatus.busy);
      if (!isBasicAvailable) return false;

      // Restrict to motorcycles, cycles, or scooters for restaurants (exclude cars)
      if (state.restaurant?.vendorType == VendorType.restaurant) {
        final vehicle = d.vehicleType.trim().toLowerCase();
        final isAllowed = vehicle == 'motorcycle' ||
            vehicle == 'moto' ||
            vehicle == 'cycle' ||
            vehicle == 'scooter';
        return isAllowed;
      }
      return true;
    }).toList();

    // Sort available drivers from near to far
    result.sort((a, b) {
      final distA = getDistanceToDriver(a) ?? double.infinity;
      final distB = getDistanceToDriver(b) ?? double.infinity;
      return distA.compareTo(distB);
    });

    log('[RESTAURANT] availableDrivers after filter: ${result.length}');
    return result;
  }

  /// Returns true ONLY if the driver has an active (non-cancelled, non-rejected)
  /// assignment on this order — so cancelled drivers show the Assign button again.
  bool isDriverAssigned(String driverId) {
    const activeStatuses = {
      DriverAssignmentStatus.pending,
      DriverAssignmentStatus.accepted,
      DriverAssignmentStatus.pickedUp,
      DriverAssignmentStatus.delivered,
    };
    return state.assignedDrivers.any(
      (d) => d.driverUserId == driverId && activeStatuses.contains(d.status),
    );
  }

  /// Distance from driver's current location to the restaurant (first leg).
  double? getDistanceToDriver(DriverProfile driver) {
    if (state.restaurant == null) return null;
    if (driver.currentLat == null || driver.currentLng == null) return null;

    return DeliveryFeeCalculator.calculateDistanceKm(
      state.restaurant!.latitude,
      state.restaurant!.longitude,
      driver.currentLat!,
      driver.currentLng!,
    );
  }

  /// Full trip distance: driver → restaurant + restaurant → customer.
  double getTotalTripDistance(DriverProfile driver) {
    final driverToRestaurant = getDistanceToDriver(driver) ?? 0.0;
    final restaurantToCustomer = getDistanceToCustomer();
    return driverToRestaurant + restaurantToCustomer;
  }

  Future<void> assignDriver(
      DriverProfile driver, List<String> itemNames) async {
    if (state.order == null || state.restaurant == null) return;

    emit(state.copyWith(isBusy: true, clearFailure: true));

    final order = state.order!;
    final restaurant = state.restaurant!;
    // Full trip = driver→restaurant + restaurant→customer (two legs, one trip)
    final totalDistance = getTotalTripDistance(driver);

    // Create new Request ID
    final requestId = 'REQ_${DateTime.now().millisecondsSinceEpoch}';

    final request = DeliveryRequest(
      id: requestId,
      orderId: order.id,
      driverId: driver.userId,
      restaurantId: restaurant.id,
      restaurantName: restaurant.name,
      customerAddress: order.deliveryAddress,
      customerLat: order.deliveryLat,
      customerLng: order.deliveryLng,
      restaurantLat: restaurant.latitude,
      restaurantLng: restaurant.longitude,
      estimatedDistance: totalDistance,
      deliveryFee: deliveryFeePerDriver,
      orderTotal: order.total,
      assignedItems: const [],
      itemNames: itemNames,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(minutes: 1)),
    );

    final OrderDriver orderDriver = OrderDriver(
      driverUserId: driver.userId,
      driverName: driver.name.isNotEmpty ? driver.name : driver.userId,
      driverPhone: driver.phoneNumber,
      vehicleModel: driver.vehicleModel,
      licensePlate: driver.licensePlate,
      status: DriverAssignmentStatus.pending,
      assignedAt: DateTime.now(),
      assignedItems: itemNames,
      deliveryFee: deliveryFeePerDriver,
    );

    final result = await repository.assignDriverToOrder(order.id, orderDriver);
    if (!result.isSuccess) {
      emit(state.copyWith(failure: result.error, isBusy: false));
      return;
    }

    final requestResult = await repository.sendDeliveryRequest(request);
    if (!requestResult.isSuccess) {
      // if this fails we might want to un-assign the driver in a real app, but omitting for now.
      emit(state.copyWith(failure: requestResult.error, isBusy: false));
      return;
    }

    emit(state.copyWith(isBusy: false));
  }

  Future<void> removeDriver(String driverUserId) async {
    if (state.order == null) return;
    emit(state.copyWith(isBusy: true, clearFailure: true));

    final result =
        await repository.cancelDriverAssignment(state.order!.id, driverUserId);
    if (!result.isSuccess) {
      emit(state.copyWith(failure: result.error, isBusy: false));
    } else {
      emit(state.copyWith(isBusy: false));
    }
  }
}
