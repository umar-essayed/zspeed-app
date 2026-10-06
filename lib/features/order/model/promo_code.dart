import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Types of discount a promo code can apply.
enum PromoCodeType { percentage, fixed, freeDelivery }

extension PromoCodeTypeX on PromoCodeType {
  String get key => switch (this) {
        PromoCodeType.percentage => 'percentage',
        PromoCodeType.fixed => 'fixed',
        PromoCodeType.freeDelivery => 'freeDelivery',
      };

  static PromoCodeType fromKey(String key) => switch (key) {
        'fixed' => PromoCodeType.fixed,
        'freeDelivery' => PromoCodeType.freeDelivery,
        _ => PromoCodeType.percentage,
      };
}

/// A promo code document from Firestore.
///
/// Firestore path: `promoCodes/{codeId}`
class PromoCode extends Equatable {
  final String id;
  final String code;
  final PromoCodeType type;

  /// Discount value:
  /// - percentage → 0‒100 (e.g. 20 means 20 %)
  /// - fixed      → EGP amount (e.g. 10 means EGP 10 off)
  /// - freeDelivery → ignored (delivery fee → 0)
  final double discountValue;

  /// Minimum order subtotal required to use this code.
  final double minOrderAmount;

  /// Maximum total number of redemptions (0 = unlimited).
  final int maxUsageCount;

  /// Current number of redemptions.
  final int usageCount;

  /// Maximum times a single user can use this code.
  final int maxUsagePerUser;

  /// null  → global (any restaurant)
  /// non-null → only for that restaurant
  final String? restaurantId;

  final bool isActive;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final String createdBy;

  const PromoCode({
    required this.id,
    required this.code,
    required this.type,
    required this.discountValue,
    this.minOrderAmount = 0.0,
    this.maxUsageCount = 0,
    this.usageCount = 0,
    this.maxUsagePerUser = 1,
    this.restaurantId,
    this.isActive = true,
    this.expiresAt,
    required this.createdAt,
    required this.createdBy,
  });

  // ── Validation helpers ─────────────────────────────────────────────

  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  bool get hasReachedMaxUsage =>
      maxUsageCount > 0 && usageCount >= maxUsageCount;

  /// Returns true if this code can be applied to the given context.
  bool isApplicable({
    required String restaurantId,
    required double subtotal,
  }) {
    if (!isActive) return false;
    if (isExpired) return false;
    if (hasReachedMaxUsage) return false;
    if (minOrderAmount > 0 && subtotal < minOrderAmount) return false;
    // null restaurantId = global code
    if (this.restaurantId != null && this.restaurantId != restaurantId) {
      return false;
    }
    return true;
  }

  /// Computes the discount amount in EGP.
  double discountAmount({
    required double subtotal,
    required double deliveryFee,
  }) =>
      switch (type) {
        PromoCodeType.percentage =>
          subtotal * (discountValue.clamp(0, 100) / 100),
        PromoCodeType.fixed => discountValue.clamp(0, subtotal),
        PromoCodeType.freeDelivery => deliveryFee,
      };

  // ── Firestore serialization ─────────────────────────────────────────

  factory PromoCode.fromMap(Map<String, dynamic> map, String docId) {
    return PromoCode(
      id: docId,
      code: (map['code'] as String? ?? '').toUpperCase(),
      type: PromoCodeTypeX.fromKey(map['type'] as String? ?? 'percentage'),
      discountValue: (map['discountValue'] as num?)?.toDouble() ?? 0.0,
      minOrderAmount: (map['minOrderAmount'] as num?)?.toDouble() ?? 0.0,
      maxUsageCount: (map['maxUsageCount'] as num?)?.toInt() ?? 0,
      usageCount: (map['usageCount'] as num?)?.toInt() ?? 0,
      maxUsagePerUser: (map['maxUsagePerUser'] as num?)?.toInt() ?? 1,
      restaurantId: map['restaurantId'] as String?,
      isActive: map['isActive'] as bool? ?? true,
      expiresAt: (map['expiresAt'] as Timestamp?)?.toDate(),
      createdAt:
          (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: map['createdBy'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'code': code.toUpperCase(),
        'type': type.key,
        'discountValue': discountValue,
        'minOrderAmount': minOrderAmount,
        'maxUsageCount': maxUsageCount,
        'usageCount': usageCount,
        'maxUsagePerUser': maxUsagePerUser,
        'restaurantId': restaurantId,
        'isActive': isActive,
        'expiresAt':
            expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
        'createdAt': Timestamp.fromDate(createdAt),
        'createdBy': createdBy,
      };

  PromoCode copyWith({
    String? id,
    String? code,
    PromoCodeType? type,
    double? discountValue,
    double? minOrderAmount,
    int? maxUsageCount,
    int? usageCount,
    int? maxUsagePerUser,
    String? restaurantId,
    bool clearRestaurantId = false,
    bool? isActive,
    DateTime? expiresAt,
    bool clearExpiry = false,
    DateTime? createdAt,
    String? createdBy,
  }) =>
      PromoCode(
        id: id ?? this.id,
        code: code ?? this.code,
        type: type ?? this.type,
        discountValue: discountValue ?? this.discountValue,
        minOrderAmount: minOrderAmount ?? this.minOrderAmount,
        maxUsageCount: maxUsageCount ?? this.maxUsageCount,
        usageCount: usageCount ?? this.usageCount,
        maxUsagePerUser: maxUsagePerUser ?? this.maxUsagePerUser,
        restaurantId: clearRestaurantId
            ? null
            : (restaurantId ?? this.restaurantId),
        isActive: isActive ?? this.isActive,
        expiresAt:
            clearExpiry ? null : (expiresAt ?? this.expiresAt),
        createdAt: createdAt ?? this.createdAt,
        createdBy: createdBy ?? this.createdBy,
      );

  @override
  List<Object?> get props => [
        id,
        code,
        type,
        discountValue,
        minOrderAmount,
        maxUsageCount,
        usageCount,
        maxUsagePerUser,
        restaurantId,
        isActive,
        expiresAt,
        createdAt,
        createdBy,
      ];
}
