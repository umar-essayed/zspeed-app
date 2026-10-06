import 'package:equatable/equatable.dart';
import 'package:z_speed/features/transport/model/ride_model.dart';

abstract class ActiveRideState extends Equatable {
  const ActiveRideState();
  @override
  List<Object?> get props => [];
}

class ActiveRideInitial extends ActiveRideState {}

class ActiveRideLoading extends ActiveRideState {}

class ActiveRideLoaded extends ActiveRideState {
  final RideModel ride;
  const ActiveRideLoaded(this.ride);

  @override
  List<Object> get props => [ride];
}

class ActiveRideError extends ActiveRideState {
  final String message;
  const ActiveRideError(this.message);

  @override
  List<Object> get props => [message];
}
