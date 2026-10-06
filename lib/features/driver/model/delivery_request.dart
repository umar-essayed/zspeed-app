import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:z_speed/core/enums/driver_enums.dart';

/// Incoming delivery request for a driver.
///
/// Vendor sends delivery request to driver's sub-collection.
/// Driver sees this in real-time and can accept/reject.
///
/// Firestore path: `driverProfiles/{userId}/deliveryRequests/{requestId}`
class DeliveryRequest extends Equatable {
  final String id;
  final String orderId;
  final String driverId;
  final String restaurantId;
  final String restaurantName;
  final String customerAddress;
  final double customerLat;
  final double customerLng;
  final double restaurantLat;
  final double restaurantLng;
  final double estimatedDistance;
  final double deliveryFee;
  final double orderTotal;
  final List<String> assignedItems;
  final List<String> itemNames;
  final DriverAssignmentStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;

  const DeliveryRequest({
    required this.id,
    required this.orderId,
    required this.driverId,
    required this.restaurantId,
    required this.restaurantName,
    required this.customerAddress,
    required this.customerLat,
    required this.customerLng,
    required this.restaurantLat,
    required this.restaurantLng,
    required this.estimatedDistance,
    required this.deliveryFee,
    this.orderTotal = 0.0,
    required this.assignedItems,
    required this.itemNames,
    this.status = DriverAssignmentStatus.pending,
    required this.createdAt,
    required this.expiresAt,
  });

  factory DeliveryRequest.fromMap(Map<String, dynamic> map, String documentId) {
    return DeliveryRequest(
      id: documentId,
      orderId: map['orderId'] as String? ?? '',
      driverId: map['driverId'] as String? ?? '',
      restaurantId: map['restaurantId'] as String? ?? '',
      restaurantName: map['restaurantName'] as String? ?? '',
      customerAddress: (map['customerAddress'] is String &&
              (map['customerAddress'] as String).isNotEmpty &&
              map['customerAddress'] != 'API Key missing' &&
              map['customerAddress'] != 'No address provided')
          ? map['customerAddress'] as String
          : map['deliveryAddress'] as String? ?? '',
      customerLat: (map['customerLat'] is num && (map['customerLat'] as num).toDouble() != 0.0)
          ? (map['customerLat'] as num).toDouble()
          : (map['deliveryLat'] as num?)?.toDouble() ?? 0.0,
      customerLng: (map['customerLng'] is num && (map['customerLng'] as num).toDouble() != 0.0)
          ? (map['customerLng'] as num).toDouble()
          : (map['deliveryLng'] as num?)?.toDouble() ?? 0.0,
      restaurantLat: (map['restaurantLat'] as num?)?.toDouble() ?? 0.0,
      restaurantLng: (map['restaurantLng'] as num?)?.toDouble() ?? 0.0,
      estimatedDistance: (map['estimatedDistance'] is num && (map['estimatedDistance'] as num).toDouble() != 0.0)
          ? (map['estimatedDistance'] as num).toDouble()
          : (map['distance'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (map['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      orderTotal: (map['orderTotal'] as num?)?.toDouble() ?? 0.0,
      assignedItems: List<String>.from(map['assignedItems'] ?? []),
      itemNames: List<String>.from(map['itemNames'] ?? []),
      status: DriverAssignmentStatusX.fromKey(
          map['status'] as String? ?? 'pending'),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (map['expiresAt'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(minutes: 1)),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'driverId': driverId,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'customerAddress': customerAddress,
      'customerLat': customerLat,
      'customerLng': customerLng,
      'restaurantLat': restaurantLat,
      'restaurantLng': restaurantLng,
      'estimatedDistance': estimatedDistance,
      'deliveryFee': deliveryFee,
      'orderTotal': orderTotal,
      'assignedItems': assignedItems,
      'itemNames': itemNames,
      'status': status.key,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
    };
  }

  DeliveryRequest copyWith({
    String? id,
    String? orderId,
    String? driverId,
    String? restaurantId,
    String? restaurantName,
    String? customerAddress,
    double? customerLat,
    double? customerLng,
    double? restaurantLat,
    double? restaurantLng,
    double? estimatedDistance,
    double? deliveryFee,
    double? orderTotal,
    List<String>? assignedItems,
    List<String>? itemNames,
    DriverAssignmentStatus? status,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) {
    return DeliveryRequest(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      driverId: driverId ?? this.driverId,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
      customerAddress: customerAddress ?? this.customerAddress,
      customerLat: customerLat ?? this.customerLat,
      customerLng: customerLng ?? this.customerLng,
      restaurantLat: restaurantLat ?? this.restaurantLat,
      restaurantLng: restaurantLng ?? this.restaurantLng,
      estimatedDistance: estimatedDistance ?? this.estimatedDistance,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      orderTotal: orderTotal ?? this.orderTotal,
      assignedItems: assignedItems ?? this.assignedItems,
      itemNames: itemNames ?? this.itemNames,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        orderId,
        driverId,
        restaurantId,
        restaurantName,
        customerAddress,
        customerLat,
        customerLng,
        restaurantLat,
        restaurantLng,
        estimatedDistance,
        deliveryFee,
        orderTotal,
        assignedItems,
        itemNames,
        status,
        createdAt,
        expiresAt,
      ];
}
