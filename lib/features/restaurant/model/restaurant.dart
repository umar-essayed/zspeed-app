import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:z_speed/core/enums/driver_enums.dart';
import 'package:z_speed/core/enums/user_enums.dart';

/// Represents a restaurant/vendor business on the platform.
///
/// Firestore path: `restaurants/{restaurantId}`
class Restaurant extends Equatable {
  final String id;
  final String ownerId;
  final String name;
  final String? nameAr;
  final String description;
  final String? descriptionAr;
  final String logoUrl;
  final String coverImageUrl;
  final double rating;
  final int ratingCount;
  final int deliveryTimeMin;
  final int deliveryTimeMax;
  final double deliveryFee;
  final double minimumOrder;
  final List<String> cuisineTypes;
  final bool isOpen;
  final bool isBusy;
  final String address;

  bool get isAvailable => isOpen && !isBusy;
  final double latitude;
  final double longitude;
  final String? geohash;
  final String phone;
  final Map<String, WorkingHours> workingHours;
  final DateTime createdAt;

  String getLocalizedName(String langCode) =>
      (langCode == 'ar' && nameAr != null && nameAr!.isNotEmpty)
          ? nameAr!
          : name;

  String getLocalizedDescription(String langCode) =>
      (langCode == 'ar' && descriptionAr != null && descriptionAr!.isNotEmpty)
          ? descriptionAr!
          : description;
  final DateTime updatedAt;
  final bool isActive;
  final DeliveryFeeMode deliveryFeeMode;
  final DeliveryFeeSubMode? deliveryFeeSubMode;
  final Map<String, double>? deliveryFeeFormula;
  final List<Map<String, dynamic>>? deliveryFeeTiers;
  final List<Map<String, dynamic>>? deliveryFeeAreas;
  final double deliveryRadiusKm;
  final List<String> documentUrls;
  final VendorType vendorType;
  final double walletBalance;
  final double totalEarnings;
  final String payoutPhoneNumber;
  final PayoutMethod? payoutMethod;
  final int priority;

  const Restaurant({
    required this.id,
    required this.ownerId,
    required this.name,
    this.nameAr,
    this.descriptionAr,
    required this.description,
    required this.logoUrl,
    required this.coverImageUrl,
    this.rating = 0.0,
    this.ratingCount = 0,
    required this.deliveryTimeMin,
    required this.deliveryTimeMax,
    required this.deliveryFee,
    required this.minimumOrder,
    this.cuisineTypes = const [],
    this.isOpen = true,
    this.isBusy = false,
    required this.address,
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.geohash,
    this.phone = '',
    this.workingHours = const {},
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.deliveryFeeMode = DeliveryFeeMode.fixed,
    this.deliveryFeeSubMode,
    this.deliveryFeeFormula,
    this.deliveryFeeTiers,
    this.deliveryFeeAreas,
    this.deliveryRadiusKm = 15.0,
    this.documentUrls = const [],
    this.vendorType = VendorType.restaurant,
    this.walletBalance = 0.0,
    this.totalEarnings = 0.0,
    this.payoutPhoneNumber = '',
    this.payoutMethod,
    this.priority = 0,
  });

  factory Restaurant.fromMap(Map<String, dynamic> map, String documentId) {
    return Restaurant(
      id: documentId,
      ownerId: map['ownerId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      nameAr: map['nameAr'] as String?,
      descriptionAr: map['descriptionAr'] as String?,
      description: map['description'] as String? ?? '',
      logoUrl: map['logoUrl'] as String? ?? '',
      coverImageUrl: map['coverImageUrl'] as String? ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: (map['ratingCount'] as num?)?.toInt() ?? 0,
      deliveryTimeMin: (map['deliveryTimeMin'] as num?)?.toInt() ?? 30,
      deliveryTimeMax: (map['deliveryTimeMax'] as num?)?.toInt() ?? 60,
      deliveryFee: (map['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      minimumOrder: (map['minimumOrder'] as num?)?.toDouble() ?? 0.0,
      cuisineTypes: List<String>.from(map['cuisineTypes'] ?? []),
      isOpen: map['isOpen'] as bool? ?? true,
      isBusy: map['isBusy'] as bool? ?? false,
      address: map['address'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      geohash: map['geohash'] as String?,
      phone: map['phone'] as String? ?? '',
      workingHours: (map['workingHours'] as Map<String, dynamic>?)?.map(
            (k, v) =>
                MapEntry(k, WorkingHours.fromMap(v as Map<String, dynamic>)),
          ) ??
          {},
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: map['isActive'] as bool? ?? true,
      deliveryFeeMode: DeliveryFeeModeX.fromKey(
          map['deliveryFeeMode'] as String? ?? 'fixed'),
      deliveryFeeSubMode: map['deliveryFeeSubMode'] != null
          ? DeliveryFeeSubModeX.fromKey(map['deliveryFeeSubMode'] as String)
          : null,
      deliveryFeeFormula: map['deliveryFeeFormula'] != null
          ? (map['deliveryFeeFormula'] as Map).map(
              (k, v) => MapEntry(
                k as String,
                // Guard: value might be a List or String in malformed docs
                v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0,
              ),
            )
          : null,
      deliveryFeeTiers: map['deliveryFeeTiers'] != null
          ? (map['deliveryFeeTiers'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : null,
      deliveryFeeAreas: map['deliveryFeeAreas'] != null
          ? (map['deliveryFeeAreas'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : null,
      deliveryRadiusKm: (map['deliveryRadiusKm'] as num?)?.toDouble() ?? 15.0,
      documentUrls: List<String>.from(map['documentUrls'] ?? []),
      vendorType: VendorTypeX.fromKey(map['vendorType'] as String? ?? 'restaurant'),
      walletBalance: (map['walletBalance'] as num?)?.toDouble() ?? 0.0,
      totalEarnings: (map['totalEarnings'] as num?)?.toDouble() ?? 0.0,
      payoutPhoneNumber: map['payoutPhoneNumber'] as String? ?? '',
      payoutMethod: map['payoutMethod'] != null
          ? PayoutMethodX.fromKey(map['payoutMethod'] as String)
          : null,
      priority: (map['priority'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'name': name,
      'nameAr': nameAr,
      'descriptionAr': descriptionAr,
      'description': description,
      'logoUrl': logoUrl,
      'coverImageUrl': coverImageUrl,
      'rating': rating,
      'ratingCount': ratingCount,
      'deliveryTimeMin': deliveryTimeMin,
      'deliveryTimeMax': deliveryTimeMax,
      'deliveryFee': deliveryFee,
      'minimumOrder': minimumOrder,
      'cuisineTypes': cuisineTypes,
      'isOpen': isOpen,
      'isBusy': isBusy,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      if (geohash != null) 'geohash': geohash,
      'phone': phone,
      'workingHours': workingHours.map((k, v) => MapEntry(k, v.toMap())),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
      'deliveryFeeMode': deliveryFeeMode.key,
      'deliveryFeeSubMode': deliveryFeeSubMode?.key,
      'deliveryFeeFormula': deliveryFeeFormula,
      'deliveryFeeTiers': deliveryFeeTiers,
      'deliveryFeeAreas': deliveryFeeAreas,
      'deliveryRadiusKm': deliveryRadiusKm,
      'documentUrls': documentUrls,
      'vendorType': vendorType.key,
      'walletBalance': walletBalance,
      'totalEarnings': totalEarnings,
      'payoutPhoneNumber': payoutPhoneNumber,
      if (payoutMethod != null) 'payoutMethod': payoutMethod!.key,
      'priority': priority,
    };
  }

  Restaurant copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? nameAr,
    String? descriptionAr,
    String? description,
    String? logoUrl,
    String? coverImageUrl,
    double? rating,
    int? ratingCount,
    int? deliveryTimeMin,
    int? deliveryTimeMax,
    double? deliveryFee,
    double? minimumOrder,
    List<String>? cuisineTypes,
    bool? isOpen,
    bool? isBusy,
    String? address,
    double? latitude,
    double? longitude,
    String? geohash,
    String? phone,
    Map<String, WorkingHours>? workingHours,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    DeliveryFeeMode? deliveryFeeMode,
    DeliveryFeeSubMode? deliveryFeeSubMode,
    Map<String, double>? deliveryFeeFormula,
    List<Map<String, dynamic>>? deliveryFeeTiers,
    List<Map<String, dynamic>>? deliveryFeeAreas,
    double? deliveryRadiusKm,
    List<String>? documentUrls,
    VendorType? vendorType,
    double? walletBalance,
    double? totalEarnings,
    String? payoutPhoneNumber,
    PayoutMethod? payoutMethod,
    int? priority,
  }) {
    return Restaurant(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      nameAr: nameAr ?? this.nameAr,
      descriptionAr: descriptionAr ?? this.descriptionAr,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      deliveryTimeMin: deliveryTimeMin ?? this.deliveryTimeMin,
      deliveryTimeMax: deliveryTimeMax ?? this.deliveryTimeMax,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      minimumOrder: minimumOrder ?? this.minimumOrder,
      cuisineTypes: cuisineTypes ?? this.cuisineTypes,
      isOpen: isOpen ?? this.isOpen,
      isBusy: isBusy ?? this.isBusy,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      geohash: geohash ?? this.geohash,
      phone: phone ?? this.phone,
      workingHours: workingHours ?? this.workingHours,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      deliveryFeeMode: deliveryFeeMode ?? this.deliveryFeeMode,
      deliveryFeeSubMode: deliveryFeeSubMode ?? this.deliveryFeeSubMode,
      deliveryFeeFormula: deliveryFeeFormula ?? this.deliveryFeeFormula,
      deliveryFeeTiers: deliveryFeeTiers ?? this.deliveryFeeTiers,
      deliveryFeeAreas: deliveryFeeAreas ?? this.deliveryFeeAreas,
      deliveryRadiusKm: deliveryRadiusKm ?? this.deliveryRadiusKm,
      documentUrls: documentUrls ?? this.documentUrls,
      vendorType: vendorType ?? this.vendorType,
      walletBalance: walletBalance ?? this.walletBalance,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      payoutPhoneNumber: payoutPhoneNumber ?? this.payoutPhoneNumber,
      payoutMethod: payoutMethod ?? this.payoutMethod,
      priority: priority ?? this.priority,
    );
  }

  @override
  List<Object?> get props => [
        id,
        ownerId,
        name,
        nameAr,
        descriptionAr,
        description,
        logoUrl,
        coverImageUrl,
        rating,
        ratingCount,
        deliveryTimeMin,
        deliveryTimeMax,
        deliveryFee,
        minimumOrder,
        cuisineTypes,
        isOpen,
        isBusy,
        address,
        latitude,
        longitude,
        geohash,
        phone,
        workingHours,
        createdAt,
        updatedAt,
        isActive,
        deliveryFeeMode,
        deliveryFeeSubMode,
        deliveryFeeFormula,
        deliveryFeeTiers,
        deliveryFeeAreas,
        deliveryRadiusKm,
        documentUrls,
        vendorType,
        walletBalance,
        totalEarnings,
        payoutPhoneNumber,
        payoutMethod,
        priority,
      ];
}

class WorkingHours extends Equatable {
  final String open; // "09:00"
  final String close; // "23:00"
  final bool isClosed; // day off

  const WorkingHours({
    required this.open,
    required this.close,
    this.isClosed = false,
  });

  factory WorkingHours.fromMap(Map<String, dynamic> map) => WorkingHours(
        open: map['open'] as String? ?? '09:00',
        close: map['close'] as String? ?? '23:00',
        isClosed: map['isClosed'] as bool? ?? false,
      );

  Map<String, dynamic> toMap() => {
        'open': open,
        'close': close,
        'isClosed': isClosed,
      };

  @override
  List<Object?> get props => [open, close, isClosed];
}
