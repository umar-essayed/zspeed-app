import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';
import 'package:z_speed/features/transport/model/ride_location.dart';
import 'package:z_speed/features/transport/model/ride_model.dart';
import 'package:z_speed/features/transport/datasource/transport_firebase_datasource.dart';

@LazySingleton(as: TransportFirebaseDatasource)
class TransportFirebaseDatasourceImpl implements TransportFirebaseDatasource {
  final FirebaseFirestore _firestore;

  TransportFirebaseDatasourceImpl(this._firestore);

  @override
  Future<String> createRide(RideModel ride) async {
    try {
      final docRef = await _firestore.collection('rides').add(ride.toMap());
      final rideId = docRef.id;

      // Mirror to RTDB pending_rides so drivers can list them without
      // needing complex Firestore security rules (RTDB rules are simpler).
      try {
        await FirebaseDatabase.instance.ref('pending_rides/$rideId').set({
          'id': rideId,
          'status': RideStatus.pending.name,
          'vehicleType': ride.vehicleType,
          'totalFare': ride.totalFare,
          'customerId': ride.customerId,
          'customerName': ride.customerName,
          'customerPhone': ride.customerPhone,
          'pickupAddress': ride.pickupLocation.address,
          'pickupLat': ride.pickupLocation.latitude,
          'pickupLng': ride.pickupLocation.longitude,
          'dropoffAddress': ride.dropoffLocation.address,
          'dropoffLat': ride.dropoffLocation.latitude,
          'dropoffLng': ride.dropoffLocation.longitude,
          'requestedAt': ServerValue.timestamp,
        });
      } catch (e) {
        debugPrint('Failed to mirror ride to RTDB pending_rides: $e');
      }

      return rideId;
    } catch (e) {
      throw Exception('Failed to create ride in Firestore: $e');
    }
  }

  @override
  Stream<RideModel> getRideStream(String rideId) {
    final firestoreStream = _firestore
        .collection('rides')
        .doc(rideId)
        .snapshots()
        .map((doc) => RideModel.fromMap(doc.id, doc.data() ?? {}));

    final rtdbStream = FirebaseDatabase.instance
        .ref('active_rides/$rideId')
        .onValue
        .map((event) {
          if (event.snapshot.value == null) return null;
          try {
            final val = event.snapshot.value;
            if (val is Map) {
              final map = Map<String, dynamic>.from(val);
              final lat = (map['driverLat'] as num?)?.toDouble();
              final lng = (map['driverLng'] as num?)?.toDouble();
              if (lat != null && lng != null) {
                return RideLocation(
                  latitude: lat,
                  longitude: lng,
                  address: 'Driver Current Location',
                );
              }
            }
          } catch (e) {
            debugPrint('Error parsing RTDB location in getRideStream: $e');
          }
          return null;
        });

    return Rx.combineLatest2<RideModel, RideLocation?, RideModel>(
      firestoreStream,
      rtdbStream,
      (ride, location) {
        if (location != null) {
          return ride.copyWith(currentDriverLocation: location);
        }
        return ride;
      },
    );
  }

  @override
  Future<void> updateRideStatus(String rideId, RideStatus status) async {
    final updates = <String, dynamic>{
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (status == RideStatus.accepted) {
      updates['acceptedAt'] = FieldValue.serverTimestamp();
    } else if (status == RideStatus.started) {
      updates['startedAt'] = FieldValue.serverTimestamp();
    } else if (status == RideStatus.completed) {
      updates['completedAt'] = FieldValue.serverTimestamp();
      try {
        final rideDoc = await _firestore.collection('rides').doc(rideId).get();
        final data = rideDoc.data();
        final currentStatus = data?['status'] as String?;
        if (currentStatus != RideStatus.completed.name) {
          final driverId = data?['driverId'] as String?;
          final fare = (data?['totalFare'] as num?)?.toDouble() ?? 0.0;
          if (driverId != null && driverId.isNotEmpty) {
            await _firestore.collection('driverProfiles').doc(driverId).update({
              'totalEarnings': FieldValue.increment(fare),
              'walletBalance': FieldValue.increment(fare),
              'totalTrips': FieldValue.increment(1),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }
      } catch (e) {
        debugPrint('Error updating driverProfile on ride completion: $e');
      }
    }

    await _firestore.collection('rides').doc(rideId).update(updates);

    if (status == RideStatus.completed || status == RideStatus.cancelled) {
      await Future.wait([
        FirebaseDatabase.instance.ref('active_rides/$rideId').remove(),
        FirebaseDatabase.instance.ref('pending_rides/$rideId').remove(),
      ]);
    } else {
      await FirebaseDatabase.instance.ref('active_rides/$rideId').update({
        'status': status.name,
      });
    }
  }

  @override
  Future<void> acceptRide(String rideId, String driverId, {String? driverName, String? driverPhone}) async {
    final updates = <String, dynamic>{
      'driverId': driverId,
      'status': RideStatus.accepted.name,
      'acceptedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (driverName != null) updates['driverName'] = driverName;
    if (driverPhone != null) updates['driverPhone'] = driverPhone;

    try {
      void extractData(Map<String, dynamic> data) {
        if (data['name'] != null && data['name'].toString().isNotEmpty) {
          updates['driverName'] = data['name'];
        }
        if (data['phoneNumber'] != null && data['phoneNumber'].toString().isNotEmpty) {
          updates['driverPhone'] = data['phoneNumber'];
        }
        final make = data['vehicleMake'] ?? data['vehicleBrand'] ?? data['make'] ?? data['Make'];
        if (make != null && make.toString().isNotEmpty) {
          updates['vehicleMake'] = make;
          updates['vehicleBrand'] = make;
        }
        final model = data['vehicleModel'] ?? data['vehicleModelName'] ?? data['model'] ?? data['Model'];
        if (model != null && model.toString().isNotEmpty) {
          updates['vehicleModel'] = model;
          updates['vehicleModelName'] = model;
        }
        final plate = data['licensePlate'] ?? data['vehiclePlate'] ?? data['plateNumber'] ?? data['Plate Number'];
        if (plate != null && plate.toString().isNotEmpty) {
          updates['licensePlate'] = plate;
          updates['vehiclePlate'] = plate;
        }
        final color = data['vehicleColor'] ?? data['color'] ?? data['Color'];
        if (color != null && color.toString().isNotEmpty) {
          updates['vehicleColor'] = color;
          updates['color'] = color;
        }
      }

      final doc = await _firestore.collection('driverProfiles').doc(driverId).get();
      if (doc.exists && doc.data() != null) {
        extractData(doc.data()!);
      }

      final appQuery = await _firestore
          .collection('applications')
          .where('userId', isEqualTo: driverId)
          .get();
      if (appQuery.docs.isNotEmpty) {
        final appData = appQuery.docs.first.data();
        final formData = Map<String, dynamic>.from(appData['formData'] ?? {});
        final vehicleInfo = Map<String, dynamic>.from(formData['vehicleInfo'] ?? {});
        extractData(vehicleInfo);
      }
    } catch (e) {
      debugPrint('Error fetching driverProfile/application for acceptRide: $e');
    }

    await _firestore.collection('rides').doc(rideId).update(updates);

    // Remove from RTDB pending_rides now that the ride is accepted
    try {
      await FirebaseDatabase.instance.ref('pending_rides/$rideId').remove();
    } catch (e) {
      debugPrint('Failed to remove ride from RTDB pending_rides on accept: $e');
    }

    await FirebaseDatabase.instance.ref('active_rides/$rideId').set({
      'driverId': driverId,
      'status': RideStatus.accepted.name,
      'lastPingAt': ServerValue.timestamp,
    });
  }

  @override
  Stream<List<RideModel>> getNearbyPendingRides() {
    // Use RTDB pending_rides for driver listing — RTDB rules allow any
    // authenticated user to read, bypassing Firestore permission issues.
    return FirebaseDatabase.instance
        .ref('pending_rides')
        .onValue
        .map((event) {
          final snapshot = event.snapshot;
          if (snapshot.value == null) return <RideModel>[];

          final rides = <RideModel>[];
          try {
            if (snapshot.value is Map) {
              final data = Map<String, dynamic>.from(snapshot.value as Map);
              for (final entry in data.entries) {
                try {
                  final val = Map<String, dynamic>.from(entry.value as Map);
                  final status = val['status'] as String? ?? 'pending';
                  // Only show rides that are still pending
                  if (status != RideStatus.pending.name) continue;

                  rides.add(RideModel(
                    id: entry.key,
                    customerId: val['customerId'] as String? ?? '',
                    customerName: val['customerName'] as String?,
                    customerPhone: val['customerPhone'] as String?,
                    vehicleType: val['vehicleType'] as String? ?? 'sedan',
                    totalFare: (val['totalFare'] as num?)?.toDouble() ?? 0.0,
                    status: RideStatus.pending,
                    pickupLocation: RideLocation(
                      address: val['pickupAddress'] as String? ?? '',
                      latitude: (val['pickupLat'] as num?)?.toDouble() ?? 0.0,
                      longitude: (val['pickupLng'] as num?)?.toDouble() ?? 0.0,
                    ),
                    dropoffLocation: RideLocation(
                      address: val['dropoffAddress'] as String? ?? '',
                      latitude: (val['dropoffLat'] as num?)?.toDouble() ?? 0.0,
                      longitude: (val['dropoffLng'] as num?)?.toDouble() ?? 0.0,
                    ),
                    requestedAt: DateTime.now(),
                    pathPoints: const [],
                  ));
                } catch (e) {
                  debugPrint('Error parsing pending_ride ${entry.key}: $e');
                }
              }
            }
          } catch (e) {
            debugPrint('Error parsing pending_rides from RTDB: $e');
          }
          return rides;
        });
  }

  @override
  Future<void> cancelRide(String rideId, String reason) async {
    try {
      await _firestore.collection('rides').doc(rideId).set({
        'status': RideStatus.cancelled.name,
        'cancellationReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Remove from both RTDB paths
      await Future.wait([
        FirebaseDatabase.instance.ref('active_rides/$rideId').remove(),
        FirebaseDatabase.instance.ref('pending_rides/$rideId').remove(),
      ]);
    } catch (e) {
      debugPrint('cancelRide error: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateRideLocation(String rideId, double lat, double lng) async {
    final dbRef = FirebaseDatabase.instance.ref('active_rides/$rideId');
    await dbRef.update({
      'driverLat': lat,
      'driverLng': lng,
      'lastPingAt': ServerValue.timestamp,
    });

    await _firestore.collection('rides').doc(rideId).set({
      'currentDriverLocation': {
        'latitude': lat,
        'longitude': lng,
        'address': 'Current Location',
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<Map<String, dynamic>> getPricingConfig() async {
    try {
      final doc = await _firestore.collection('configs').doc('transport').get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!;
      }
    } catch (e) {
      debugPrint('Error getting pricing config: $e');
    }
    return {
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
  }

  @override
  Future<List<Map<String, dynamic>>> getNearbyDrivers(String vehicleType) async {
    final querySnapshot = await _firestore
        .collection('driverProfiles')
        .where('status', isEqualTo: 'online')
        .get();

    return querySnapshot.docs.where((doc) {
      final data = doc.data();
      final driverType = (data['vehicleType'] as String? ?? '').toLowerCase();

      if (vehicleType == 'sedan') {
        return driverType == 'car' || driverType == 'sedan';
      } else if (vehicleType == 'moto') {
        return driverType == 'motorcycle' ||
            driverType == 'moto' ||
            driverType == 'cycle';
      } else if (vehicleType == 'luxury') {
        return driverType == 'car' ||
            driverType == 'luxury' ||
            driverType == 'premium';
      }
      return false;
    }).map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['name'] ?? 'Driver',
        'lat': (data['currentLat'] as num?)?.toDouble() ?? 0.0,
        'lng': (data['currentLng'] as num?)?.toDouble() ?? 0.0,
        'rating': (data['rating'] as num?)?.toDouble() ?? 5.0,
      };
    }).toList();
  }
}
