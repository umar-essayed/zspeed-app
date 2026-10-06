import 'package:z_speed/features/transport/model/ride_model.dart';

abstract class TransportFirebaseDatasource {
  Future<String> createRide(RideModel ride);
  Stream<RideModel> getRideStream(String rideId);
  Future<void> updateRideStatus(String rideId, RideStatus status);
  Future<void> acceptRide(String rideId, String driverId, {String? driverName, String? driverPhone});
  Stream<List<RideModel>> getNearbyPendingRides();
  Future<void> cancelRide(String rideId, String reason);
  Future<void> updateRideLocation(String rideId, double lat, double lng);
  Future<Map<String, dynamic>> getPricingConfig();
  Future<List<Map<String, dynamic>>> getNearbyDrivers(String vehicleType);
}
