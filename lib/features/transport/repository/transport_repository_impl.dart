import 'package:injectable/injectable.dart';
import 'package:z_speed/features/transport/model/ride_model.dart';
import 'package:z_speed/features/transport/datasource/transport_firebase_datasource.dart';
import 'package:z_speed/features/transport/repository/transport_repository.dart';

@LazySingleton(as: TransportRepository)
class TransportRepositoryImpl implements TransportRepository {
  final TransportFirebaseDatasource _datasource;

  TransportRepositoryImpl(this._datasource);

  @override
  Future<String> requestRide(RideModel ride) {
    return _datasource.createRide(ride);
  }

  @override
  Stream<RideModel> watchRide(String rideId) {
    return _datasource.getRideStream(rideId);
  }

  @override
  Future<void> updateRideStatus(String rideId, RideStatus status) {
    return _datasource.updateRideStatus(rideId, status);
  }

  @override
  Future<void> acceptRide(String rideId, String driverId, {String? driverName, String? driverPhone}) {
    return _datasource.acceptRide(rideId, driverId, driverName: driverName, driverPhone: driverPhone);
  }

  @override
  Stream<List<RideModel>> watchPendingRides() {
    return _datasource.getNearbyPendingRides();
  }

  @override
  Future<void> cancelRide(String rideId, String reason) {
    return _datasource.cancelRide(rideId, reason);
  }

  @override
  Future<void> updateRideLocation(String rideId, double lat, double lng) {
    return _datasource.updateRideLocation(rideId, lat, lng);
  }

  @override
  Future<Map<String, dynamic>> getPricingConfig() {
    return _datasource.getPricingConfig();
  }

  @override
  Future<List<Map<String, dynamic>>> getNearbyDrivers(String vehicleType) {
    return _datasource.getNearbyDrivers(vehicleType);
  }
}
