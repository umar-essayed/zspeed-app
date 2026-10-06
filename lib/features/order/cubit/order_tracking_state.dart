import 'package:equatable/equatable.dart';
import 'package:z_speed/features/order/model/order.dart';
import 'package:z_speed/features/order/model/tracking_step.dart';
import 'package:z_speed/features/order/model/order_item.dart';
import 'package:latlong2/latlong.dart';

class OrderTrackingState extends Equatable {
  final bool isBusy;
  final bool hasError;
  final dynamic failure;
  final Order? order;
  final List<TrackingStep> trackingSteps;
  final List<OrderItem>? orderItems;
  final String? estimatedTime;
  final double progressPercentage;
  final LatLng? restaurantLocation;

  const OrderTrackingState({
    this.isBusy = false,
    this.hasError = false,
    this.failure,
    this.order,
    this.trackingSteps = const [],
    this.orderItems,
    this.estimatedTime,
    this.progressPercentage = 0.0,
    this.restaurantLocation,
  });

  OrderTrackingState copyWith({
    bool? isBusy,
    bool? hasError,
    dynamic failure,
    Order? order,
    List<TrackingStep>? trackingSteps,
    List<OrderItem>? orderItems,
    String? estimatedTime,
    double? progressPercentage,
    LatLng? restaurantLocation,
  }) {
    return OrderTrackingState(
      isBusy: isBusy ?? this.isBusy,
      hasError: hasError ?? this.hasError,
      failure: failure ?? this.failure,
      order: order ?? this.order,
      trackingSteps: trackingSteps ?? this.trackingSteps,
      orderItems: orderItems ?? this.orderItems,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      restaurantLocation: restaurantLocation ?? this.restaurantLocation,
    );
  }

  @override
  List<Object?> get props => [
        isBusy,
        hasError,
        failure,
        order,
        trackingSteps,
        orderItems,
        estimatedTime,
        progressPercentage,
        restaurantLocation,
      ];
}
