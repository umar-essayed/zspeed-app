import 'package:equatable/equatable.dart';
import 'package:z_speed/features/transport/model/ride_model.dart';

abstract class DriverTransportState extends Equatable {
  const DriverTransportState();
  @override
  List<Object?> get props => [];
}

class DriverTransportInitial extends DriverTransportState {}

class DriverTransportLoading extends DriverTransportState {}

class DriverTransportLoaded extends DriverTransportState {
  final List<RideModel> pendingRides;
  const DriverTransportLoaded(this.pendingRides);

  @override
  List<Object> get props => [pendingRides];
}

class DriverTransportError extends DriverTransportState {
  final String message;
  const DriverTransportError(this.message);

  @override
  List<Object> get props => [message];
}
