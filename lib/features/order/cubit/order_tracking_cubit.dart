import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:z_speed/features/order/cubit/order_tracking_state.dart';
import 'package:z_speed/features/order/repository/order_repository.dart';
import 'package:z_speed/core/enums/order_enums.dart';
import 'package:z_speed/features/order/model/tracking_step.dart';
import 'package:z_speed/features/order/model/order.dart';
import 'package:injectable/injectable.dart' hide Order;

@injectable
class OrderTrackingCubit extends Cubit<OrderTrackingState> {
  final OrderRepository _orderRepository;
  StreamSubscription? _orderSubscription;
  StreamSubscription<DatabaseEvent>? _driverLocationSub;
  String? _trackedDriverId;
  LatLng? _restaurantLocation;

  OrderTrackingCubit(this._orderRepository) : super(const OrderTrackingState());

  Future<void> init(String orderId) async {
    emit(state.copyWith(isBusy: true));

    final itemsResult = await _orderRepository.getOrderItems(orderId);
    if (itemsResult.isSuccess) {
      emit(state.copyWith(orderItems: itemsResult.data));
    }

    _orderSubscription?.cancel();
    _orderSubscription = _orderRepository.streamOrder(orderId).listen((order) {
      if (order != null) {
        final progress = _calculateProgress(order);
        final eta = _calculateEta(order);
        emit(state.copyWith(
          isBusy: false,
          order: order,
          trackingSteps: _buildTrackingSteps(order),
          progressPercentage: progress,
          estimatedTime: eta,
          restaurantLocation: _restaurantLocation,
        ));
        _trackDriverIfNeeded(order);
      } else {
        emit(state.copyWith(hasError: true, isBusy: false));
      }
    });
  }

  double _calculateProgress(Order order) {
    switch (order.status) {
      case OrderStatus.pending:
      case OrderStatus.searching:
        return 0.1;
      case OrderStatus.accepted:
        return 0.2;
      case OrderStatus.preparing:
        return 0.35;
      case OrderStatus.ready:
        return 0.45;
      case OrderStatus.driverAssigned:
        return 0.55;
      case OrderStatus.pickedUp:
      case OrderStatus.onTheWay:
        return 0.75;
      case OrderStatus.delivered:
        return 1.0;
      case OrderStatus.cancelled:
      case OrderStatus.refunded:
      case OrderStatus.unassigned:
        return 0.0;
    }
  }

  String _calculateEta(Order order) {
    switch (order.status) {
      case OrderStatus.pending:
      case OrderStatus.searching:
        return '30-45 min';
      case OrderStatus.accepted:
        return '25-40 min';
      case OrderStatus.preparing:
        return '20-35 min';
      case OrderStatus.ready:
      case OrderStatus.driverAssigned:
        return '15-25 min';
      case OrderStatus.pickedUp:
      case OrderStatus.onTheWay:
        return state.estimatedTime ?? '10-15 min';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
      case OrderStatus.refunded:
      case OrderStatus.unassigned:
        return '--';
    }
  }

  Future<void> _trackDriverIfNeeded(Order order) async {
    final driverId = order.driverId;
    if (driverId == null || driverId.isEmpty) {
      _driverLocationSub?.cancel();
      _driverLocationSub = null;
      return;
    }

    // Track when driver is assigned, picked up, or on the way
    if (order.status != OrderStatus.driverAssigned &&
        order.status != OrderStatus.pickedUp &&
        order.status != OrderStatus.onTheWay) {
      _driverLocationSub?.cancel();
      _driverLocationSub = null;
      return;
    }

    // Already tracking this specific driver
    if (_driverLocationSub != null && _trackedDriverId == driverId) return;

    _driverLocationSub?.cancel();
    _driverLocationSub = null;
    _trackedDriverId = driverId;

    // Fetch restaurant location before starting listener so ETA is accurate
    await _fetchRestaurantLocation(order.restaurantId);

    if (isClosed) return;

    _driverLocationSub = FirebaseDatabase.instance
        .ref('active_drivers/$driverId')
        .onValue
        .listen((event) {
      if (isClosed || event.snapshot.value == null) return;
      final val = event.snapshot.value;
      if (val is Map) {
        final data = Map<dynamic, dynamic>.from(val);
        final lat = (data['currentLat'] as num?)?.toDouble();
        final lng = (data['currentLng'] as num?)?.toDouble();

        if (lat != null && lng != null && state.order != null) {
          final driverLoc = LatLng(lat, lng);
          final currentOrder = state.order!;

        int eta;
        if (currentOrder.status == OrderStatus.driverAssigned) {
          // Driver heading to restaurant → ETA = driver→restaurant + estimated prep/delivery
          if (_restaurantLocation != null) {
            const dist = Distance();
            final toRestaurantMeters = dist.as(LengthUnit.Meter, driverLoc, _restaurantLocation!);
            final restToCustomerMeters = dist.as(LengthUnit.Meter, _restaurantLocation!,
                LatLng(currentOrder.deliveryLat, currentOrder.deliveryLng));
            
            // Clamp distances to handle mock coordinate testing gracefully
            final toRestaurantKm = (toRestaurantMeters / 1000).clamp(0.0, 10.0);
            final restToCustomerKm = (restToCustomerMeters / 1000).clamp(0.0, 15.0);
            final totalKm = toRestaurantKm + restToCustomerKm;
            
            // 1.3x road factor, 40 km/h avg speed, + 5 min pickup buffer
            eta = ((totalKm * 1.3) / 40 * 60).ceil() + 5;
          } else {
            eta = 20; // fallback
          }
        } else {
          // pickedUp / onTheWay → driver heading to customer
          final deliveryLoc = LatLng(currentOrder.deliveryLat, currentOrder.deliveryLng);
          const dist = Distance();
          final meters = dist.as(LengthUnit.Meter, driverLoc, deliveryLoc);
          final km = (meters / 1000).clamp(0.0, 15.0);
          eta = ((km * 1.3) / 40 * 60).ceil();
        }

        // Cap final ETA to a realistic maximum of 60 minutes for tracking
        if (eta > 60) eta = 60;
        if (eta < 1) eta = 1;
        emit(state.copyWith(estimatedTime: '$eta min'));
        }
      }
    });
  }

  Future<void> _fetchRestaurantLocation(String restaurantId) async {
    if (_restaurantLocation != null || restaurantId.isEmpty) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('vendors')
          .doc(restaurantId)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        final lat = (data['latitude'] as num?)?.toDouble();
        final lng = (data['longitude'] as num?)?.toDouble();
        debugPrint('[OrderTracking] Restaurant location: lat=$lat, lng=$lng');
        if (lat != null && lng != null && lat != 0.0 && lng != 0.0) {
          _restaurantLocation = LatLng(lat, lng);
          emit(state.copyWith(restaurantLocation: _restaurantLocation));
        }
      }
    } catch (e) {
      debugPrint('[OrderTracking] Failed to fetch restaurant location: $e');
    }
  }

  List<TrackingStep> _buildTrackingSteps(Order order) {
    if (order.status == OrderStatus.cancelled || order.status == OrderStatus.refunded) {
       return [
         TrackingStep(
           title: 'Order Cancelled',
           subtitle: order.cancellationReason ?? 'No reason provided',
           icon: Icons.cancel,
           isComplete: true,
           timestamp: order.updatedAt,
         )
       ];
    }

    const statusOrder = [
      OrderStatus.pending,
      OrderStatus.accepted,
      OrderStatus.preparing,
      OrderStatus.ready,
      OrderStatus.searching,
      OrderStatus.unassigned,
      OrderStatus.driverAssigned,
      OrderStatus.pickedUp,
      OrderStatus.onTheWay,
      OrderStatus.delivered,
    ];

    int getRank(OrderStatus s) => statusOrder.indexOf(s);
    final currentRank = getRank(order.status);

    bool isComplete(OrderStatus targetStatus) {
      if (order.status == OrderStatus.cancelled || order.status == OrderStatus.refunded) return false;
      final targetRank = getRank(targetStatus);
      return currentRank >= 0 && targetRank >= 0 && currentRank >= targetRank;
    }

    return [
      TrackingStep(
        title: 'Pending',
        subtitle: 'Pending',
        icon: Icons.receipt_long,
        isComplete: isComplete(OrderStatus.pending),
        timestamp: isComplete(OrderStatus.pending) ? order.createdAt : null,
      ),
      TrackingStep(
        title: 'Accepted',
        subtitle: 'Accepted',
        icon: Icons.check_circle_outline,
        isComplete: isComplete(OrderStatus.accepted),
      ),
      TrackingStep(
        title: 'Preparing',
        subtitle: 'Restaurant is preparing your order',
        icon: Icons.restaurant,
        isComplete: isComplete(OrderStatus.preparing),
      ),
      TrackingStep(
        title: 'Ready',
        subtitle: 'Waiting for order completion',
        icon: Icons.shopping_bag_outlined,
        isComplete: isComplete(OrderStatus.ready),
      ),
      TrackingStep(
        title: 'Driver Assigned',
        subtitle: isComplete(OrderStatus.driverAssigned) ? 'Driver has been assigned' : 'Looking for a driver',
        icon: Icons.motorcycle,
        isComplete: isComplete(OrderStatus.driverAssigned),
      ),
      TrackingStep(
        title: 'Picked Up',
        subtitle: 'Waiting for pickup',
        icon: Icons.delivery_dining,
        isComplete: isComplete(OrderStatus.pickedUp),
      ),
      TrackingStep(
        title: 'On The Way',
        subtitle: 'Driver is being dispatched',
        icon: Icons.directions_bike,
        isComplete: isComplete(OrderStatus.onTheWay),
      ),
      TrackingStep(
        title: 'Delivered',
        subtitle: isComplete(OrderStatus.delivered) ? 'Enjoy your meal!' : 'Arriving soon',
        icon: Icons.home,
        isComplete: isComplete(OrderStatus.delivered),
        timestamp: isComplete(OrderStatus.delivered) ? order.updatedAt : null,
      ),
    ];
  }

  bool canCancel() {
    if (state.order == null) return false;
    final status = state.order!.status;
    return status == OrderStatus.pending ||
        status == OrderStatus.searching ||
        status == OrderStatus.unassigned;
  }

  Future<bool> cancelOrder(String reason) async {
    if (state.order == null) return false;
    final res = await _orderRepository.cancelOrder(state.order!.id, reason);
    return res.isSuccess;
  }

  @override
  Future<void> close() {
    _orderSubscription?.cancel();
    _driverLocationSub?.cancel();
    return super.close();
  }
}
