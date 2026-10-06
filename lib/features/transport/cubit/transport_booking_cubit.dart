import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:z_speed/features/transport/model/ride_location.dart';
import 'package:z_speed/features/transport/model/ride_model.dart';
import 'package:z_speed/features/transport/repository/transport_repository.dart';
import 'package:z_speed/features/transport/cubit/transport_booking_state.dart';
import 'package:latlong2/latlong.dart';
import 'package:z_speed/core/services/routing_service.dart';

@injectable
class TransportBookingCubit extends Cubit<TransportBookingState> {
  final TransportRepository _repository;

  Map<String, dynamic> _pricingConfig = {
    'sedan_baseFare': 15.0,
    'sedan_pricePerKm': 5.0,
    'sedan_customerCommType': 'percentage',
    'sedan_customerCommValue': 0.0,
    'moto_baseFare': 10.0,
    'moto_pricePerKm': 3.0,
    'moto_customerCommType': 'percentage',
    'moto_customerCommValue': 0.0,
    'luxury_baseFare': 25.0,
    'luxury_pricePerKm': 8.0,
    'luxury_customerCommType': 'percentage',
    'luxury_customerCommValue': 0.0,
  };

  Map<String, dynamic> get pricingConfig => _pricingConfig;

  TransportBookingCubit(this._repository) : super(TransportBookingInitial()) {
    loadPricingConfig();
  }

  Future<void> loadPricingConfig() async {
    try {
      _pricingConfig = await _repository.getPricingConfig();
    } catch (e) {
      debugPrint('Error loading pricing config: $e');
    }
  }

  Future<void> selectLocations(RideLocation pickup, RideLocation dropoff) async {
    emit(TransportBookingLocating());
    try {
      final directions = await RoutingService.instance.getDirections(
        LatLng(pickup.latitude, pickup.longitude),
        LatLng(dropoff.latitude, dropoff.longitude),
      );

      if (directions == null || directions.distanceKm <= 0) {
        throw Exception('Could not calculate a valid road route between pickup and dropoff.');
      }

      final double distanceInKm = directions.distanceKm;

      emit(TransportBookingLocationSelected(
        pickup: pickup,
        dropoff: dropoff,
        estimatedDistance: double.parse(distanceInKm.toStringAsFixed(2)),
        estimatedFare: 0,
      ));
    } catch (e) {
      emit(TransportBookingError(e.toString()));
    }
  }

  void selectVehicleType(String vehicleType) {
    RideLocation? pickup;
    RideLocation? dropoff;
    double? distance;

    if (state is TransportBookingLocationSelected) {
      final s = state as TransportBookingLocationSelected;
      pickup = s.pickup;
      dropoff = s.dropoff;
      distance = s.estimatedDistance;
    } else if (state is TransportBookingVehicleSelected) {
      final s = state as TransportBookingVehicleSelected;
      pickup = s.pickup;
      dropoff = s.dropoff;
      distance = s.estimatedDistance;
    } else if (state is TransportBookingDriversNearby) {
      final s = state as TransportBookingDriversNearby;
      pickup = s.pickup;
      dropoff = s.dropoff;
      distance = s.estimatedDistance;
    }

    if (pickup != null && dropoff != null && distance != null) {
      final double calculatedFare = distance * 7.0;
      final baseCost = calculatedFare > 35.0 ? calculatedFare : 35.0;

      // Customer Commission
      final String customerCommType =
          (_pricingConfig['${vehicleType}_customerCommType'] as String?) ??
              'percentage';
      final double customerCommVal =
          (_pricingConfig['${vehicleType}_customerCommValue'] as num?)
                  ?.toDouble() ??
              0.0;

      double customerComm = 0.0;
      if (customerCommType == 'percentage') {
        customerComm = baseCost * (customerCommVal / 100.0);
      } else if (customerCommType == 'flat_per_km') {
        customerComm = distance * customerCommVal;
      } else {
        customerComm = customerCommVal;
      }

      final fare = baseCost + customerComm;

      emit(TransportBookingVehicleSelected(
        pickup: pickup,
        dropoff: dropoff,
        estimatedDistance: distance,
        vehicleType: vehicleType,
        fare: double.parse(fare.toStringAsFixed(2)),
      ));
    }
  }

  void goBackToVehicleSelection() {
    if (state is TransportBookingDriversNearby) {
      final s = state as TransportBookingDriversNearby;
      emit(TransportBookingVehicleSelected(
        pickup: s.pickup,
        dropoff: s.dropoff,
        estimatedDistance: s.estimatedDistance,
        vehicleType: s.vehicleType,
        fare: s.fare,
      ));
    }
  }

  Future<void> fetchDriversNearby() async {
    if (state is TransportBookingVehicleSelected) {
      final s = state as TransportBookingVehicleSelected;
      emit(TransportBookingLocating());

      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        debugPrint(
            '🔑 [Transport] Auth UID: ${currentUser?.uid ?? "NOT LOGGED IN"}');

        if (currentUser == null) {
          emit(const TransportBookingError(
              'You must be logged in to book a ride.'));
          return;
        }

        final drivers = await _repository.getNearbyDrivers(s.vehicleType);

        debugPrint(
            '🚗 [Transport] Found ${drivers.length} drivers for ${s.vehicleType}');

        emit(TransportBookingDriversNearby(
          drivers: drivers,
          vehicleType: s.vehicleType,
          pickup: s.pickup,
          dropoff: s.dropoff,
          fare: s.fare,
          estimatedDistance: s.estimatedDistance,
        ));
      } catch (e) {
        debugPrint('❌ [Transport] fetchDriversNearby Error: $e');
        emit(TransportBookingError('Could not fetch drivers: $e'));
      }
    }
  }

  Future<void> requestRide(
    String customerId,
    String driverId, {
    String? customerName,
    String? customerPhone,
    String paymentMethod = 'cash',
  }) async {
    if (state is TransportBookingDriversNearby) {
      final s = state as TransportBookingDriversNearby;

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        emit(const TransportBookingError(
            'You must be logged in to request a ride.'));
        return;
      }

      // Always use the Firebase Auth UID — this is what the security rules check
      final safeCustomerId = currentUser.uid;
      debugPrint(
          '🚀 [Transport] Requesting Ride: Customer=$safeCustomerId, Driver=$driverId, Name=$customerName, Phone=$customerPhone, Payment=$paymentMethod');

      emit(TransportBookingRequesting());

      try {
        final ride = RideModel(
          id: '',
          customerId: safeCustomerId,
          customerName: customerName,
          customerPhone: customerPhone,
          status: RideStatus.pending,
          vehicleType: s.vehicleType,
          pickupLocation: s.pickup,
          dropoffLocation: s.dropoff,
          totalFare: s.fare,
          paymentMethod: paymentMethod,
          requestedAt: DateTime.now(),
          driverId: driverId,
        );

        final rideId = await _repository.requestRide(ride);
        debugPrint('✅ [Transport] Ride Created: $rideId');
        emit(TransportBookingRequested(rideId));
      } catch (e) {
        debugPrint('❌ [Transport] requestRide Error: $e');
        emit(TransportBookingError('Failed to create ride: $e'));
      }
    } else {
      debugPrint(
          '⚠️ [Transport] requestRide called in wrong state: ${state.runtimeType}');
    }
  }
}
