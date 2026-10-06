import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:z_speed/features/transport/model/ride_model.dart';
import 'package:z_speed/features/admin/cubit/admin_transport_state.dart';

@injectable
class AdminTransportCubit extends Cubit<AdminTransportState> {
  final FirebaseFirestore _firestore;
  StreamSubscription? _ridesSubscription;
  StreamSubscription? _configSubscription;
  List<RideModel> _allRides = [];
  Map<String, dynamic> _pricingConfig = {};

  AdminTransportCubit(this._firestore) : super(AdminTransportInitial());

  void watchAllTransports() {
    emit(AdminTransportLoading());
    _ridesSubscription?.cancel();
    _configSubscription?.cancel();

    _configSubscription = _firestore
        .collection('configs')
        .doc('transport')
        .snapshots()
        .listen((doc) {
      if (doc.exists && doc.data() != null) {
        _pricingConfig = doc.data()!;
      } else {
        _pricingConfig = {
          'sedan_baseFare': 15.0,
          'sedan_pricePerKm': 5.0,
          'sedan_profitType': 'percentage',
          'sedan_profitValue': 20.0,
          'moto_baseFare': 10.0,
          'moto_pricePerKm': 3.0,
          'moto_profitType': 'percentage',
          'moto_profitValue': 15.0,
          'luxury_baseFare': 25.0,
          'luxury_pricePerKm': 8.0,
          'luxury_profitType': 'percentage',
          'luxury_profitValue': 20.0,
        };
      }
      _emitLoadedState();
    }, onError: (e) {
      emit(AdminTransportError('Failed to load configs: $e'));
    });

    _ridesSubscription = _firestore
        .collection('rides')
        .snapshots()
        .listen((snapshot) {
      _allRides = snapshot.docs
          .map((doc) => RideModel.fromMap(doc.id, doc.data()))
          .toList();
      _emitLoadedState();
    }, onError: (e) {
      emit(AdminTransportError('Failed to load rides: $e'));
    });
  }

  void _emitLoadedState() {
    double revenue = 0;
    int active = 0;
    int completed = 0;

    for (var ride in _allRides) {
      if (ride.status == RideStatus.completed) {
        revenue += ride.totalFare;
        completed++;
      } else if (ride.status != RideStatus.cancelled) {
        active++;
      }
    }

    emit(AdminTransportLoaded(
      allRides: _allRides,
      totalRevenue: revenue,
      activeRidesCount: active,
      completedRidesCount: completed,
      pricingConfig: _pricingConfig,
    ));
  }

  Future<void> savePricingConfig(Map<String, dynamic> config) async {
    try {
      await _firestore
          .collection('configs')
          .doc('transport')
          .set(config, SetOptions(merge: true));
    } catch (e) {
      emit(AdminTransportError('Failed to save config: $e'));
    }
  }

  Future<void> updateRideStatus(String rideId, RideStatus status) async {
    try {
      await _firestore.collection('rides').doc(rideId).update({
        'status': status.name,
      });
    } catch (e) {
      emit(AdminTransportError('Failed to update status: $e'));
    }
  }

  @override
  Future<void> close() {
    _ridesSubscription?.cancel();
    _configSubscription?.cancel();
    return super.close();
  }
}
