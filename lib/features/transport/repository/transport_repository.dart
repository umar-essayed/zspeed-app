import 'package:z_speed/features/transport/model/ride_model.dart';

abstract class TransportRepository {
  Future<String> requestRide(RideModel ride);
  Stream<RideModel> watchRide(String rideId);
  Future<void> updateRideStatus(String rideId, RideStatus status);
  Future<void> acceptRide(String rideId, String driverId, {String? driverName, String? driverPhone});
  Stream<List<RideModel>> watchPendingRides();
  Future<void> cancelRide(String rideId, String reason);
  Future<void> updateRideLocation(String rideId, double lat, double lng);
  Future<Map<String, dynamic>> getPricingConfig();
  Future<List<Map<String, dynamic>>> getNearbyDrivers(String vehicleType);
}
