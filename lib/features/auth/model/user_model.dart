// models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:z_speed/core/enums/user_enums.dart';
import 'package:z_speed/features/customer/model/saved_address.dart';

// Re-export enums so existing importers keep working
export 'package:z_speed/core/enums/user_enums.dart';

// ── AppUser ──────────────────────────────────────────────────────────────────

class AppUser extends Equatable {
  final String id;
  final String name;
  final String email;
  final UserType type;
  final String? phone;
  final String? address;
  final String? profileImage;

  // ── Location ──
  final double? latitude;
  final double? longitude;
  final List<SavedAddress> savedAddresses;

  /// Kept optional for backward compat with local datasource.
  /// Firebase auth handles passwords — never persist this to Firestore.
  final String? password;

  // ── Application tracking (driver/vendor onboarding) ──
  final ApplicationStatus? applicationStatus;
  final String? rejectionReason;
  final DateTime? appliedAt;
  final DateTime? approvedAt;

  // ── Audit ──
  final DateTime createdAt;
  final DateTime? updatedAt;
  final UserStatus status;

  // ── Notifications (Phase 8.8) ──
  final List<String> fcmTokens;
  final Map<String, bool> notificationPreferences;

  // ── Wallet & Loyalty ──
  final double walletBalance;
  final int loyaltyPoints;
  final String? referralCode;

  // ── Driver Capabilities (Phase 12) ──
  final bool canDeliver;
  final bool canTransport;
  final String? vehicleInfo; // e.g. "Car - Toyota Corolla", "Bike - Yamaha"

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.type,
    this.phone,
    this.address,
    this.profileImage,
    this.latitude,
    this.longitude,
    this.savedAddresses = const [],
    this.password,
    this.applicationStatus,
    this.rejectionReason,
    this.appliedAt,
    this.approvedAt,
    DateTime? createdAt,
    this.updatedAt,
    this.status = UserStatus.active,
    this.walletBalance = 0.0,
    this.loyaltyPoints = 0,
    this.referralCode,
    this.canDeliver = true, // Default for backward compatibility
    this.canTransport = false,
    this.vehicleInfo,
    List<String>? fcmTokens,
    Map<String, bool>? notificationPreferences,
  })  : createdAt = createdAt ?? DateTime.now(),
        fcmTokens = fcmTokens ?? [],
        notificationPreferences = notificationPreferences ??
            {
              'orderUpdates': true,
              'newOrders': true,
              'deliveryRequests': true,
              'promotional': true,
              'applicationUpdates': true,
            };

  // ── Firestore serialization ────────────────────────────────────────────────

  factory AppUser.fromMap(Map<String, dynamic> map, String documentId) {
    return AppUser(
      id: documentId,
      name: map['name'] ?? map['displayName'] ?? map['fullName'] ?? map['userName'] ?? '',
      email: map['email'] ?? '',
      type: UserTypeX.fromKey(map['type'] ?? ''),
      phone: map['phone'] ?? map['phoneNumber'] ?? map['mobile'] ?? map['phone_number'],
      address: map['address'],
      profileImage: map['profileImage'],
      latitude: map['latitude'] != null
          ? (map['latitude'] as num?)?.toDouble()
          : null,
      longitude: map['longitude'] != null
          ? (map['longitude'] as num?)?.toDouble()
          : null,
      savedAddresses: (map['savedAddresses'] as List<dynamic>?)
              ?.map((e) => SavedAddress.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      walletBalance: (map['walletBalance'] as num?)?.toDouble() ?? 0.0,
      loyaltyPoints: (map['loyaltyPoints'] as num?)?.toInt() ?? 0,
      referralCode: map['referralCode'] as String?,
      applicationStatus: map['applicationStatus'] != null
          ? ApplicationStatus.values.firstWhere(
              (e) => e.name == map['applicationStatus'],
              orElse: () => ApplicationStatus.pending,
            )
          : null,
      rejectionReason: map['rejectionReason'],
      appliedAt: _timestampToDateTime(map['appliedAt']),
      approvedAt: _timestampToDateTime(map['approvedAt']),
      createdAt: _timestampToDateTime(map['createdAt']) ?? DateTime.now(),
      updatedAt: _timestampToDateTime(map['updatedAt']),
      status: UserStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => UserStatus.active,
      ),
      fcmTokens: map['fcmTokens'] is List
          ? List<String>.from(map['fcmTokens'] as List)
          : [],
      notificationPreferences: map['notificationPreferences'] is Map
          ? Map<String, bool>.from(
              (map['notificationPreferences'] as Map).map(
                (k, v) => MapEntry(
                  k.toString(),
                  v is bool ? v : true, // guard: value might not be bool
                ),
              ),
            )
          : {
              'orderUpdates': true,
              'newOrders': true,
              'deliveryRequests': true,
              'promotional': true,
              'applicationUpdates': true,
            },
      canDeliver: map['canDeliver'] ?? true,
      canTransport: map['canTransport'] ?? false,
      vehicleInfo: map['vehicleInfo'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'fcmTokens': fcmTokens,
      'notificationPreferences': notificationPreferences,
      'type': type.name,
      'walletBalance': walletBalance,
      'loyaltyPoints': loyaltyPoints,
      if (referralCode != null) 'referralCode': referralCode,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
      'savedAddresses': savedAddresses.map((e) => e.toMap()).toList(),
      if (profileImage != null) 'profileImage': profileImage,
      if (applicationStatus != null)
        'applicationStatus': applicationStatus!.name,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
      if (appliedAt != null) 'appliedAt': Timestamp.fromDate(appliedAt!),
      if (approvedAt != null) 'approvedAt': Timestamp.fromDate(approvedAt!),
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      'status': status.name,
      'canDeliver': canDeliver,
      'canTransport': canTransport,
      if (vehicleInfo != null) 'vehicleInfo': vehicleInfo,
      // NOTE: password is NEVER written to Firestore
    };
  }

  // ── JSON serialization (backward compat / local usage) ─────────────────────

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      password: json['password'],
      type: UserType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => UserType.customer,
      ),
      phone: json['phone'],
      address: json['address'],
      profileImage: json['profileImage'],
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
      savedAddresses: (json['savedAddresses'] as List<dynamic>?)
              ?.map((e) => SavedAddress.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      walletBalance: (json['walletBalance'] as num?)?.toDouble() ?? 0.0,
      loyaltyPoints: (json['loyaltyPoints'] as num?)?.toInt() ?? 0,
      referralCode: json['referralCode'] as String?,
      applicationStatus: json['applicationStatus'] != null
          ? ApplicationStatus.values.firstWhere(
              (e) => e.name == json['applicationStatus'],
              orElse: () => ApplicationStatus.pending,
            )
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      status: json['status'] != null
          ? UserStatus.values.firstWhere(
              (e) => e.name == json['status'],
              orElse: () => UserStatus.active,
            )
          : UserStatus.active,
      canDeliver: json['canDeliver'] ?? true,
      canTransport: json['canTransport'] ?? false,
      vehicleInfo: json['vehicleInfo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'type': type.name,
      'walletBalance': walletBalance,
      'loyaltyPoints': loyaltyPoints,
      if (referralCode != null) 'referralCode': referralCode,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
      'savedAddresses': savedAddresses.map((e) => e.toMap()).toList(),
      if (profileImage != null) 'profileImage': profileImage,
      if (applicationStatus != null)
        'applicationStatus': applicationStatus!.name,
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
      'canDeliver': canDeliver,
      'canTransport': canTransport,
      if (vehicleInfo != null) 'vehicleInfo': vehicleInfo,
      // NOTE: password deliberately excluded from JSON
    };
  }

  // ── copyWith ───────────────────────────────────────────────────────────────

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    UserType? type,
    String? phone,
    String? address,
    String? profileImage,
    double? latitude,
    double? longitude,
    List<SavedAddress>? savedAddresses,
    String? password,
    ApplicationStatus? applicationStatus,
    String? rejectionReason,
    DateTime? appliedAt,
    DateTime? approvedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserStatus? status,
    double? walletBalance,
    int? loyaltyPoints,
    String? referralCode,
    List<String>? fcmTokens,
    Map<String, bool>? notificationPreferences,
    bool? canDeliver,
    bool? canTransport,
    String? vehicleInfo,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      type: type ?? this.type,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      profileImage: profileImage ?? this.profileImage,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      savedAddresses: savedAddresses ?? this.savedAddresses,
      password: password ?? this.password,
      applicationStatus: applicationStatus ?? this.applicationStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      appliedAt: appliedAt ?? this.appliedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      walletBalance: walletBalance ?? this.walletBalance,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      referralCode: referralCode ?? this.referralCode,
      fcmTokens: fcmTokens ?? this.fcmTokens,
      notificationPreferences:
          notificationPreferences ?? this.notificationPreferences,
      canDeliver: canDeliver ?? this.canDeliver,
      canTransport: canTransport ?? this.canTransport,
      vehicleInfo: vehicleInfo ?? this.vehicleInfo,
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String get initial => name.isNotEmpty ? name[0].toUpperCase() : 'U';

  static DateTime? _timestampToDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  String toString() =>
      'AppUser(id: $id, name: $name, email: $email, type: ${type.name})';

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        type,
        phone,
        address,
        profileImage,
        latitude,
        longitude,
        savedAddresses,
        password,
        applicationStatus,
        rejectionReason,
        appliedAt,
        fcmTokens,
        notificationPreferences,
        approvedAt,
        createdAt,
        updatedAt,
        status,
        walletBalance,
        loyaltyPoints,
        referralCode,
      ];
}

// ── Extensions ───────────────────────────────────────────────────────────────

extension UserTypeExtension on UserType {
  String get displayName {
    switch (this) {
      case UserType.superAdmin:
        return 'Super Administrator';
      case UserType.admin:
        return 'Administrator';
      case UserType.vendor:
        return 'Vendor Owner';
      case UserType.customer:
        return 'Customer';
      case UserType.driver:
        return 'Delivery Driver';
    }
  }

  IconData get icon {
    switch (this) {
      case UserType.superAdmin:
        return Icons.shield;
      case UserType.admin:
        return Icons.admin_panel_settings;
      case UserType.vendor:
        return Icons.store;
      case UserType.customer:
        return Icons.person;
      case UserType.driver:
        return Icons.delivery_dining;
    }
  }

  Color get color {
    switch (this) {
      case UserType.superAdmin:
        return Colors.deepPurple;
      case UserType.admin:
        return Colors.red;
      case UserType.vendor:
        return Colors.orange;
      case UserType.customer:
        return Colors.blue;
      case UserType.driver:
        return Colors.green;
    }
  }
}

extension ApplicationStatusExtension on ApplicationStatus {
  String get displayName {
    switch (this) {
      case ApplicationStatus.pending:
        return 'Pending Review';
      case ApplicationStatus.underReview:
        return 'Under Review';
      case ApplicationStatus.approved:
        return 'Approved';
      case ApplicationStatus.rejected:
        return 'Rejected';
    }
  }

  Color get color {
    switch (this) {
      case ApplicationStatus.pending:
        return Colors.orange;
      case ApplicationStatus.underReview:
        return Colors.blue;
      case ApplicationStatus.approved:
        return Colors.green;
      case ApplicationStatus.rejected:
        return Colors.red;
    }
  }

  IconData get icon {
    switch (this) {
      case ApplicationStatus.pending:
        return Icons.hourglass_empty;
      case ApplicationStatus.underReview:
        return Icons.rate_review;
      case ApplicationStatus.approved:
        return Icons.check_circle;
      case ApplicationStatus.rejected:
        return Icons.cancel;
    }
  }
}

extension UserStatusExtension on UserStatus {
  String get displayName {
    switch (this) {
      case UserStatus.active:
        return 'Active';
      case UserStatus.inactive:
        return 'Inactive';
      case UserStatus.suspended:
        return 'Suspended';
      case UserStatus.pendingVerification:
        return 'Pending Verification';
      case UserStatus.banned:
        return 'Banned';
    }
  }

  Color get color {
    switch (this) {
      case UserStatus.active:
        return Colors.green;
      case UserStatus.inactive:
        return Colors.grey;
      case UserStatus.suspended:
        return Colors.orange;
      case UserStatus.pendingVerification:
        return Colors.blue;
      case UserStatus.banned:
        return Colors.red;
    }
  }
}
