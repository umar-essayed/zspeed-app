import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:z_speed/core/enums/driver_enums.dart';

/// Extended driver information stored in a separate collection.
///
/// Firestore path: `driverProfiles/{userId}`
class DriverProfile extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String vehicleType;
  final String vehicleMake;
  final String vehicleModel;
  final String licensePlate;
  final String licenseNumber;
  final DriverStatus status;
  final double? currentLat;
  final double? currentLng;
  final String? geohash;
  final DateTime? lastPingAt;
  final double rating;
  final int ratingCount;
  final int totalTrips;
  final double totalEarnings;
  final double acceptanceRate;
  final int totalAccepted;
  final int totalRejected;
  final double walletBalance;
  final double earningsLimit;
  final bool isLimitLocked;
  final String phoneNumber;
  final String payoutPhoneNumber;
  final PayoutMethod? payoutMethod;
  final String payoutFrequency; // 'daily' | 'weekly' | 'monthly'
  final double minimumPayout; // minimum payout amount in EGP
  final DateTime createdAt;
  final DateTime updatedAt;

  const DriverProfile({
    required this.id,
    required this.userId,
    this.name = '',
    this.vehicleType = '',
    this.vehicleMake = '',
    this.vehicleModel = '',
    this.licensePlate = '',
    this.licenseNumber = '',
    this.status = DriverStatus.offline,
    this.currentLat,
    this.currentLng,
    this.geohash,
    this.lastPingAt,
    this.rating = 0.0,
    this.ratingCount = 0,
    this.totalTrips = 0,
    this.totalEarnings = 0.0,
    this.acceptanceRate = 1.0,
    this.totalAccepted = 0,
    this.totalRejected = 0,
    this.walletBalance = 0.0,
    this.earningsLimit = 0.0,
    this.isLimitLocked = false,
    this.phoneNumber = '',
    this.payoutPhoneNumber = '',
    this.payoutMethod,
    this.payoutFrequency = 'weekly',
    this.minimumPayout = 100.0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DriverProfile.fromMap(Map<String, dynamic> map, String documentId) {
    return DriverProfile(
      id: documentId,
      userId: map['userId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      vehicleType: map['vehicleType'] as String? ?? '',
      vehicleMake: map['vehicleMake'] as String? ?? '',
      vehicleModel: map['vehicleModel'] as String? ?? '',
      licensePlate: map['licensePlate'] as String? ?? '',
      licenseNumber: map['licenseNumber'] as String? ?? '',
      status: DriverStatusX.fromKey(map['status'] as String? ?? 'offline'),
      currentLat: (map['currentLat'] as num?)?.toDouble(),
      currentLng: (map['currentLng'] as num?)?.toDouble(),
      geohash: map['geohash'] as String?,
      lastPingAt: (map['lastPingAt'] as Timestamp?)?.toDate(),
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: (map['ratingCount'] as num?)?.toInt() ?? 0,
      totalTrips: (map['totalTrips'] as num?)?.toInt() ?? 0,
      totalEarnings: (map['totalEarnings'] as num?)?.toDouble() ?? 0.0,
      acceptanceRate: (map['acceptanceRate'] as num?)?.toDouble() ?? 1.0,
      totalAccepted: (map['totalAccepted'] as num?)?.toInt() ?? 0,
      totalRejected: (map['totalRejected'] as num?)?.toInt() ?? 0,
      walletBalance: (map['walletBalance'] as num?)?.toDouble() ?? 0.0,
      earningsLimit: (map['earningsLimit'] as num?)?.toDouble() ?? 0.0,
      isLimitLocked: map['isLimitLocked'] as bool? ?? false,
      phoneNumber: map['phoneNumber'] as String? ?? '',
      payoutPhoneNumber: map['payoutPhoneNumber'] as String? ?? '',
      payoutMethod: map['payoutMethod'] != null
          ? PayoutMethodX.fromKey(map['payoutMethod'] as String)
          : null,
      payoutFrequency: map['payoutFrequency'] as String? ?? 'weekly',
      minimumPayout: (map['minimumPayout'] as num?)?.toDouble() ?? 100.0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'vehicleType': vehicleType,
      'vehicleMake': vehicleMake,
      'vehicleModel': vehicleModel,
      'licensePlate': licensePlate,
      'licenseNumber': licenseNumber,
      'status': status.key,
      'currentLat': currentLat,
      'currentLng': currentLng,
      if (geohash != null) 'geohash': geohash,
      if (lastPingAt != null) 'lastPingAt': Timestamp.fromDate(lastPingAt!),
      'rating': rating,
      'ratingCount': ratingCount,
      'totalTrips': totalTrips,
      'totalEarnings': totalEarnings,
      'acceptanceRate': acceptanceRate,
      'totalAccepted': totalAccepted,
      'totalRejected': totalRejected,
      'walletBalance': walletBalance,
      'earningsLimit': earningsLimit,
      'isLimitLocked': isLimitLocked,
      'phoneNumber': phoneNumber,
      'payoutPhoneNumber': payoutPhoneNumber,
      if (payoutMethod != null) 'payoutMethod': payoutMethod!.key,
      'payoutFrequency': payoutFrequency,
      'minimumPayout': minimumPayout,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  DriverProfile copyWith({
    String? id,
    String? userId,
    String? name,
    String? vehicleType,
    String? vehicleMake,
    String? vehicleModel,
    String? licensePlate,
    String? licenseNumber,
    DriverStatus? status,
    double? currentLat,
    double? currentLng,
    String? geohash,
    DateTime? lastPingAt,
    double? rating,
    int? ratingCount,
    int? totalTrips,
    double? totalEarnings,
    double? acceptanceRate,
    int? totalAccepted,
    int? totalRejected,
    double? walletBalance,
    double? earningsLimit,
    bool? isLimitLocked,
    String? phoneNumber,
    String? payoutPhoneNumber,
    PayoutMethod? payoutMethod,
    String? payoutFrequency,
    double? minimumPayout,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DriverProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleMake: vehicleMake ?? this.vehicleMake,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      licensePlate: licensePlate ?? this.licensePlate,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      status: status ?? this.status,
      currentLat: currentLat ?? this.currentLat,
      currentLng: currentLng ?? this.currentLng,
      geohash: geohash ?? this.geohash,
      lastPingAt: lastPingAt ?? this.lastPingAt,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      totalTrips: totalTrips ?? this.totalTrips,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      acceptanceRate: acceptanceRate ?? this.acceptanceRate,
      totalAccepted: totalAccepted ?? this.totalAccepted,
      totalRejected: totalRejected ?? this.totalRejected,
      walletBalance: walletBalance ?? this.walletBalance,
      earningsLimit: earningsLimit ?? this.earningsLimit,
      isLimitLocked: isLimitLocked ?? this.isLimitLocked,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      payoutPhoneNumber: payoutPhoneNumber ?? this.payoutPhoneNumber,
      payoutMethod: payoutMethod ?? this.payoutMethod,
      payoutFrequency: payoutFrequency ?? this.payoutFrequency,
      minimumPayout: minimumPayout ?? this.minimumPayout,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        vehicleType,
        vehicleMake,
        vehicleModel,
        licensePlate,
        licenseNumber,
        status,
        currentLat,
        currentLng,
        geohash,
        lastPingAt,
        rating,
        ratingCount,
        totalTrips,
        totalEarnings,
        acceptanceRate,
        totalAccepted,
        totalRejected,
        walletBalance,
        earningsLimit,
        isLimitLocked,
        phoneNumber,
        payoutPhoneNumber,
        payoutMethod,
        payoutFrequency,
        minimumPayout,
        createdAt,
        updatedAt,
      ];
}
