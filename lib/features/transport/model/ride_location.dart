import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class RideLocation extends Equatable {
  final double latitude;
  final double longitude;
  final String address;

  const RideLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  factory RideLocation.fromMap(Map<String, dynamic> map) {
    return RideLocation(
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      address: map['address'] as String? ?? 'Unknown Location',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
    };
  }

  // Helper to convert to GeoPoint for Firestore if needed elsewhere
  GeoPoint toGeoPoint() => GeoPoint(latitude, longitude);

  @override
  List<Object?> get props => [latitude, longitude, address];
}
