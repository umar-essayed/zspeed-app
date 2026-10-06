import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:z_speed/features/transport/model/ride_model.dart';
import 'package:z_speed/features/transport/repository/transport_repository.dart';
import 'package:z_speed/features/transport/cubit/active_ride_state.dart';

@injectable
class ActiveRideCubit extends Cubit<ActiveRideState> {
  final TransportRepository _repository;
  StreamSubscription? _rideSubscription;

  ActiveRideCubit(this._repository) : super(ActiveRideInitial());

  void watchRide(String rideId) {
    emit(ActiveRideLoading());
    _rideSubscription?.cancel();
    _rideSubscription = _repository.watchRide(rideId).listen(
      (ride) {
        emit(ActiveRideLoaded(ride));
      },
      onError: (error) {
        emit(ActiveRideError(error.toString()));
      },
    );
  }

  Future<void> updateStatus(String rideId, RideStatus status) async {
    try {
      await _repository.updateRideStatus(rideId, status);
    } catch (e) {
      emit(ActiveRideError(e.toString()));
    }
  }

  Future<void> updateRideLocation(String rideId, double lat, double lng) async {
    // In a real app, this would be called by the driver's device periodically.
    // It should add the point to 'pathPoints' in Firestore.
    try {
      await _repository.updateRideLocation(rideId, lat, lng);
    } catch (e) {
      // Fail silently or handle error
    }
  }

  Future<void> cancelRide(String rideId, String reason) async {
    try {
      await _repository.cancelRide(rideId, reason);
    } catch (e) {
      emit(ActiveRideError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _rideSubscription?.cancel();
    return super.close();
  }
}
