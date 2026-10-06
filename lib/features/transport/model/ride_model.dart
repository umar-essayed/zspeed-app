import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:z_speed/features/transport/model/ride_location.dart';

enum RideStatus {
  pending, // Customer requested, waiting for driver
  accepted, // Driver accepted, heading to pickup
  arrived, // Driver reached pickup point
  started, // Customer picked up, trip in progress
  arrivedAtDestination, // Driver reached destination, payment pending
  completed, // Trip finished
  cancelled, // Trip cancelled
}

extension RideStatusExtension on RideStatus {
  String get name => toString().split('.').last;

  static RideStatus fromString(String status) {
    return RideStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => RideStatus.pending,
    );
  }
}

class RideModel extends Equatable {
  final String id;
  final String customerId;
  final String? customerName;
  final String? customerPhone;
  final String? driverId;
  final String? driverName;
  final String? driverPhone;
  final String? vehiclePlate;
  final String? vehicleColor;
  final RideStatus status;
  final String vehicleType;
  final RideLocation pickupLocation;
  final RideLocation dropoffLocation;
  final double totalFare;
  final DateTime requestedAt;
  final DateTime? acceptedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final List<RideLocation> pathPoints;
  final RideLocation? currentDriverLocation;
  final String? vehicleBrand;
  final String? vehicleModelName;
  final String paymentMethod; // 'cash' or 'card'
  final String paymentStatus; // 'pending' or 'completed'


  String get formattedPlate => (vehiclePlate != null && vehiclePlate!.isNotEmpty) ? vehiclePlate! : 'SPD-7492';
  String get formattedColor => (vehicleColor != null && vehicleColor!.isNotEmpty) ? vehicleColor! : 'Black';
  String get formattedBrand => (vehicleBrand != null && vehicleBrand!.isNotEmpty) ? vehicleBrand! : 'Toyota';
  String get formattedModel => (vehicleModelName != null && vehicleModelName!.isNotEmpty) ? vehicleModelName! : 'Corolla';
  String get fullVehicleName => '$formattedBrand $formattedModel';

  const RideModel({
    required this.id,
    required this.customerId,
    this.customerName,
    this.customerPhone,
    this.driverId,
    this.driverName,
    this.driverPhone,
    this.vehiclePlate,
    this.vehicleColor,
    this.vehicleBrand,
    this.vehicleModelName,
    this.paymentMethod = 'cash',
    this.paymentStatus = 'pending',
    required this.status,
    required this.vehicleType,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.totalFare,
    required this.requestedAt,
    this.acceptedAt,
    this.startedAt,
    this.completedAt,
    this.pathPoints = const [],
    this.currentDriverLocation,
  });

  factory RideModel.fromMap(String id, Map<String, dynamic> map) {
    try {
      final pickupLoc = map['pickupLocation'] != null
          ? RideLocation.fromMap(
              Map<String, dynamic>.from(map['pickupLocation'] as Map))
          : const RideLocation(
              latitude: 30.0444, longitude: 31.2357, address: 'Unknown Pickup');

      final dropoffLoc = map['dropoffLocation'] != null
          ? RideLocation.fromMap(
              Map<String, dynamic>.from(map['dropoffLocation'] as Map))
          : const RideLocation(
              latitude: 30.0444,
              longitude: 31.2357,
              address: 'Unknown Dropoff');

      return RideModel(
        id: id,
        customerId: map['customerId'] as String? ?? '',
        customerName: map['customerName'] as String? ?? 'Guest',
        customerPhone: map['customerPhone'] as String?,
        driverId: map['driverId'] as String?,
        driverName: map['driverName'] as String?,
        driverPhone: map['driverPhone'] as String?,
        vehiclePlate: (map['vehiclePlate'] ?? map['licensePlate'] ?? map['plateNumber'] ?? map['Plate Number']) as String?,
        vehicleColor: (map['vehicleColor'] ?? map['color'] ?? map['Color']) as String?,
        vehicleBrand: (map['vehicleBrand'] ?? map['vehicleMake'] ?? map['make'] ?? map['Make']) as String?,
        vehicleModelName: (map['vehicleModelName'] ?? map['vehicleModel'] ?? map['model'] ?? map['Model']) as String?,
        paymentMethod: map['paymentMethod'] as String? ?? 'cash',
        paymentStatus: map['paymentStatus'] as String? ?? 'pending',
        status: RideStatusExtension.fromString(
            map['status'] as String? ?? 'pending'),
        vehicleType: map['vehicleType'] as String? ?? 'SEDAN',
        pickupLocation: pickupLoc,
        dropoffLocation: dropoffLoc,
        totalFare: (map['totalFare'] as num?)?.toDouble() ?? 0.0,
        requestedAt: map['requestedAt'] != null
            ? (map['requestedAt'] as Timestamp).toDate()
            : DateTime.now(),
        acceptedAt: map['acceptedAt'] != null
            ? (map['acceptedAt'] as Timestamp).toDate()
            : null,
        startedAt: map['startedAt'] != null
            ? (map['startedAt'] as Timestamp).toDate()
            : null,
        completedAt: map['completedAt'] != null
            ? (map['completedAt'] as Timestamp).toDate()
            : null,
        pathPoints: (map['pathPoints'] as List<dynamic>?)
                ?.map((e) =>
                    RideLocation.fromMap(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            const [],
        currentDriverLocation: map['currentDriverLocation'] != null
            ? RideLocation.fromMap(
                Map<String, dynamic>.from(map['currentDriverLocation'] as Map))
            : null,
      );
    } catch (e, stack) {
      debugPrint('Error parsing RideModel from Map: $e\n$stack');
      return RideModel(
        id: id,
        customerId: '',
        customerName: 'Error Loading',
        status: RideStatus.pending,
        vehicleType: 'SEDAN',
        pickupLocation: const RideLocation(
            latitude: 30.0444, longitude: 31.2357, address: 'Error Location'),
        dropoffLocation: const RideLocation(
            latitude: 30.0444, longitude: 31.2357, address: 'Error Location'),
        totalFare: 0.0,
        requestedAt: DateTime.now(),
      );
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'driverId': driverId,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'vehiclePlate': vehiclePlate,
      'vehicleColor': vehicleColor,
      'vehicleBrand': vehicleBrand,
      'vehicleModelName': vehicleModelName,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'status': status.name,
      'vehicleType': vehicleType,
      'pickupLocation': pickupLocation.toMap(),
      'dropoffLocation': dropoffLocation.toMap(),
      'totalFare': totalFare,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'pathPoints': pathPoints.map((e) => e.toMap()).toList(),
      'currentDriverLocation': currentDriverLocation?.toMap(),
    };
  }

  RideModel copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? driverId,
    RideStatus? status,
    String? vehicleType,
    RideLocation? pickupLocation,
    RideLocation? dropoffLocation,
    double? totalFare,
    DateTime? requestedAt,
    DateTime? acceptedAt,
    DateTime? startedAt,
    DateTime? completedAt,
    List<RideLocation>? pathPoints,
    RideLocation? currentDriverLocation,
    String? paymentMethod,
    String? paymentStatus,
  }) {
    return RideModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      driverId: driverId ?? this.driverId,
      vehiclePlate: vehiclePlate,
      vehicleColor: vehicleColor,
      vehicleBrand: vehicleBrand,
      vehicleModelName: vehicleModelName,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      status: status ?? this.status,
      vehicleType: vehicleType ?? this.vehicleType,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      dropoffLocation: dropoffLocation ?? this.dropoffLocation,
      totalFare: totalFare ?? this.totalFare,
      requestedAt: requestedAt ?? this.requestedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      pathPoints: pathPoints ?? this.pathPoints,
      currentDriverLocation:
          currentDriverLocation ?? this.currentDriverLocation,
    );
  }

  @override
  List<Object?> get props => [
        id,
        customerId,
        customerName,
        customerPhone,
        driverId,
        status,
        vehicleType,
        pickupLocation,
        dropoffLocation,
        totalFare,
        requestedAt,
        acceptedAt,
        startedAt,
        completedAt,
        pathPoints,
        currentDriverLocation,
      ];
}
