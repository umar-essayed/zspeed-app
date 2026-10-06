import 'package:equatable/equatable.dart';
import 'package:z_speed/features/driver/model/driver_profile.dart';
import 'package:z_speed/features/restaurant/model/restaurant.dart';

sealed class AdminSettlementsState extends Equatable {
  const AdminSettlementsState();

  @override
  List<Object?> get props => [];
}

class AdminSettlementsInitial extends AdminSettlementsState {
  const AdminSettlementsInitial();
}

class AdminSettlementsLoading extends AdminSettlementsState {
  const AdminSettlementsLoading();
}

class AdminSettlementsLoaded extends AdminSettlementsState {
  final List<Restaurant> restaurants;
  final List<DriverProfile> drivers;

  const AdminSettlementsLoaded({
    required this.restaurants,
    required this.drivers,
  });

  @override
  List<Object?> get props => [restaurants, drivers];
}

class AdminSettlementsError extends AdminSettlementsState {
  final String message;

  const AdminSettlementsError(this.message);

  @override
  List<Object?> get props => [message];
}

class AdminSettlementInProgress extends AdminSettlementsState {
  const AdminSettlementInProgress();
}

class AdminSettlementSuccess extends AdminSettlementsState {
  const AdminSettlementSuccess();
}
