import 'package:equatable/equatable.dart';
import 'package:z_speed/features/transport/model/ride_location.dart';

abstract class TransportBookingState extends Equatable {
  const TransportBookingState();

  @override
  List<Object?> get props => [];
}

class TransportBookingInitial extends TransportBookingState {}

class TransportBookingLocating extends TransportBookingState {}

class TransportBookingLocationSelected extends TransportBookingState {
  final RideLocation pickup;
  final RideLocation dropoff;
  final double estimatedDistance; // in km
  final double estimatedFare; // depending on vehicle

  const TransportBookingLocationSelected({
    required this.pickup,
    required this.dropoff,
    required this.estimatedDistance,
    required this.estimatedFare,
  });

  @override
  List<Object?> get props => [pickup, dropoff, estimatedDistance, estimatedFare];
}

class TransportBookingRequesting extends TransportBookingState {}

class TransportBookingVehicleSelected extends TransportBookingState {
  final RideLocation pickup;
  final RideLocation dropoff;
  final double estimatedDistance;
  final String vehicleType;
  final double fare;

  const TransportBookingVehicleSelected({
    required this.pickup,
    required this.dropoff,
    required this.estimatedDistance,
    required this.vehicleType,
    required this.fare,
  });

  @override
  List<Object?> get props => [pickup, dropoff, estimatedDistance, vehicleType, fare];
}

class TransportBookingDriversNearby extends TransportBookingState {
  final List<dynamic> drivers;
  final String vehicleType;
  final RideLocation pickup;
  final RideLocation dropoff;
  final double fare;
  final double estimatedDistance;

  const TransportBookingDriversNearby({
    required this.drivers,
    required this.vehicleType,
    required this.pickup,
    required this.dropoff,
    required this.fare,
    required this.estimatedDistance,
  });

  @override
  List<Object?> get props => [drivers, vehicleType, pickup, dropoff, fare, estimatedDistance];
}

class TransportBookingRequested extends TransportBookingState {
  final String rideId;
  const TransportBookingRequested(this.rideId);

  @override
  List<Object> get props => [rideId];
}

class TransportBookingError extends TransportBookingState {
  final String message;
  const TransportBookingError(this.message);

  @override
  List<Object> get props => [message];
}
