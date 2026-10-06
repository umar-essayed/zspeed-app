import 'package:equatable/equatable.dart';
import 'package:z_speed/features/transport/model/ride_model.dart';

abstract class AdminTransportState extends Equatable {
  const AdminTransportState();
  @override
  List<Object?> get props => [];
}

class AdminTransportInitial extends AdminTransportState {}

class AdminTransportLoading extends AdminTransportState {}

class AdminTransportLoaded extends AdminTransportState {
  final List<RideModel> allRides;
  final double totalRevenue;
  final int activeRidesCount;
  final int completedRidesCount;
  final Map<String, dynamic> pricingConfig;

  const AdminTransportLoaded({
    required this.allRides,
    required this.totalRevenue,
    required this.activeRidesCount,
    required this.completedRidesCount,
    required this.pricingConfig,
  });

  @override
  List<Object> get props => [allRides, totalRevenue, activeRidesCount, completedRidesCount, pricingConfig];
}

class AdminTransportError extends AdminTransportState {
  final String message;
  const AdminTransportError(this.message);

  @override
  List<Object> get props => [message];
}
