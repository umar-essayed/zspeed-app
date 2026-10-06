import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:z_speed/core/enums/driver_enums.dart';

/// Driver assignment details for a specific order.
///
/// Tracks each driver's assignment, acceptance status, and delivery progress.
/// Supports multi-driver orders (multiple drivers, each with assigned items).
///
/// Firestore path: `orders/{orderId}/orderDrivers/{driverUserId}`
class OrderDriver extends Equatable {
  final String driverUserId;
  final String driverName;
  final String driverPhone;
  final String vehicleModel;
  final String licensePlate;
  final List<String> assignedItems;
  final DriverAssignmentStatus status;
  final String? rejectionReason;
  final DateTime assignedAt;
  final DateTime? acceptedAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
  final double deliveryFee;
  final double? currentLat;
  final double? currentLng;

  const OrderDriver({
    required this.driverUserId,
    required this.driverName,
    required this.driverPhone,
    required this.vehicleModel,
    required this.licensePlate,
    required this.assignedItems,
    this.status = DriverAssignmentStatus.pending,
    this.rejectionReason,
    required this.assignedAt,
    this.acceptedAt,
    this.pickedUpAt,
    this.deliveredAt,
    required this.deliveryFee,
    this.currentLat,
    this.currentLng,
  });

  factory OrderDriver.fromMap(Map<String, dynamic> map) {
    return OrderDriver(
      driverUserId: map['driverUserId'] as String? ?? '',
      driverName: map['driverName'] as String? ?? '',
      driverPhone: map['driverPhone'] as String? ?? '',
      vehicleModel: map['vehicleModel'] as String? ?? '',
      licensePlate: map['licensePlate'] as String? ?? '',
      assignedItems: List<String>.from(map['assignedItems'] ?? []),
      status: DriverAssignmentStatusX.fromKey(
          map['status'] as String? ?? 'pending'),
      rejectionReason: map['rejectionReason'] as String?,
      assignedAt: (map['assignedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      acceptedAt: (map['acceptedAt'] as Timestamp?)?.toDate(),
      pickedUpAt: (map['pickedUpAt'] as Timestamp?)?.toDate(),
      deliveredAt: (map['deliveredAt'] as Timestamp?)?.toDate(),
      deliveryFee: (map['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      currentLat: (map['currentLat'] as num?)?.toDouble(),
      currentLng: (map['currentLng'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'driverUserId': driverUserId,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'vehicleModel': vehicleModel,
      'licensePlate': licensePlate,
      'assignedItems': assignedItems,
      'status': status.key,
      'rejectionReason': rejectionReason,
      'assignedAt': Timestamp.fromDate(assignedAt),
      'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
      'pickedUpAt': pickedUpAt != null ? Timestamp.fromDate(pickedUpAt!) : null,
      'deliveredAt':
          deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
      'deliveryFee': deliveryFee,
      'currentLat': currentLat,
      'currentLng': currentLng,
    };
  }

  OrderDriver copyWith({
    String? driverUserId,
    String? driverName,
    String? driverPhone,
    String? vehicleModel,
    String? licensePlate,
    List<String>? assignedItems,
    DriverAssignmentStatus? status,
    String? rejectionReason,
    DateTime? assignedAt,
    DateTime? acceptedAt,
    DateTime? pickedUpAt,
    DateTime? deliveredAt,
    double? deliveryFee,
    double? currentLat,
    double? currentLng,
  }) {
    return OrderDriver(
      driverUserId: driverUserId ?? this.driverUserId,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      licensePlate: licensePlate ?? this.licensePlate,
      assignedItems: assignedItems ?? this.assignedItems,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      assignedAt: assignedAt ?? this.assignedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      pickedUpAt: pickedUpAt ?? this.pickedUpAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      currentLat: currentLat ?? this.currentLat,
      currentLng: currentLng ?? this.currentLng,
    );
  }

  @override
  List<Object?> get props => [
        driverUserId,
        driverName,
        driverPhone,
        vehicleModel,
        licensePlate,
        assignedItems,
        status,
        rejectionReason,
        assignedAt,
        acceptedAt,
        pickedUpAt,
        deliveredAt,
        deliveryFee,
        currentLat,
        currentLng,
      ];
}
