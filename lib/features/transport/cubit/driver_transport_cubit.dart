import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:z_speed/features/transport/repository/transport_repository.dart';
import 'package:z_speed/features/transport/cubit/driver_transport_state.dart';

@injectable
class DriverTransportCubit extends Cubit<DriverTransportState> {
  final TransportRepository _repository;
  StreamSubscription? _ridesSubscription;

  DriverTransportCubit(this._repository) : super(DriverTransportInitial());

  void loadPendingRides() {
    emit(DriverTransportLoading());
    _ridesSubscription?.cancel();
    _ridesSubscription = _repository.watchPendingRides().listen(
      (rides) {
        emit(DriverTransportLoaded(rides));
      },
      onError: (error) {
        emit(DriverTransportError(error.toString()));
      },
    );
  }

  Future<void> acceptRide(String rideId, String driverId, {String? driverName, String? driverPhone}) async {
    try {
      await _repository.acceptRide(rideId, driverId, driverName: driverName, driverPhone: driverPhone);
    } catch (e) {
      emit(DriverTransportError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _ridesSubscription?.cancel();
    return super.close();
  }
}
