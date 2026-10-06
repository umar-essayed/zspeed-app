import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:z_speed/features/order/model/promo_code.dart';

/// Possible outcomes when validating a promo code.
enum PromoValidationResult {
  valid,
  notFound,
  inactive,
  expired,
  maxUsageReached,
  userLimitReached,
  minimumOrderNotMet,
  wrongRestaurant,
}

/// Result wrapper returned by [PromoCodeDatasource.validate].
class PromoValidation {
  final PromoValidationResult result;
  final PromoCode? promoCode;
  final double discountAmount;

  const PromoValidation({
    required this.result,
    this.promoCode,
    this.discountAmount = 0.0,
  });

  bool get isValid => result == PromoValidationResult.valid;

  String humanMessage({
    required double minOrderAmount,
    String currency = 'EGP',
  }) =>
      switch (result) {
        PromoValidationResult.valid => 'Promo code applied!',
        PromoValidationResult.notFound =>
          'Invalid promo code. Please try again.',
        PromoValidationResult.inactive =>
          'This promo code is no longer active.',
        PromoValidationResult.expired => 'This promo code has expired.',
        PromoValidationResult.maxUsageReached =>
          'This promo code is no longer available.',
        PromoValidationResult.userLimitReached =>
          "You've already used this promo code.",
        PromoValidationResult.minimumOrderNotMet =>
          'Minimum order of $currency ${minOrderAmount.toStringAsFixed(2)} required.',
        PromoValidationResult.wrongRestaurant =>
          'This promo code is not valid for this restaurant.',
      };
}

/// Firestore datasource for promo code validation and management.
///
/// Collection path: `promoCodes/{codeId}`
/// User usage path: `users/{uid}/usedPromoCodes/{codeId}`
class PromoCodeDatasource {
  final FirebaseFirestore _db;

  PromoCodeDatasource({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  // ── Customer-facing ────────────────────────────────────────────────

  /// Validates a promo code for the given context.
  ///
  /// Checks in order:
  /// 1. Code exists in Firestore
  /// 2. isActive flag
  /// 3. Not expired
  /// 4. Total usage < maxUsageCount
  /// 5. User hasn't exceeded maxUsagePerUser
  /// 6. Applicable to this restaurant
  /// 7. subtotal >= minOrderAmount
  Future<PromoValidation> validate({
    required String code,
    required String restaurantId,
    required String userId,
    required double subtotal,
    required double deliveryFee,
  }) async {
    try {
      // Query by code field (case-insensitive via uppercase)
      final snapshot = await _db
          .collection('promoCodes')
          .where('code', isEqualTo: code.toUpperCase())
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return const PromoValidation(
          result: PromoValidationResult.notFound,
        );
      }

      final doc = snapshot.docs.first;
      final promo = PromoCode.fromMap(doc.data(), doc.id);

      if (!promo.isActive) {
        return const PromoValidation(
          result: PromoValidationResult.inactive,
        );
      }

      if (promo.isExpired) {
        return const PromoValidation(
          result: PromoValidationResult.expired,
        );
      }

      if (promo.hasReachedMaxUsage) {
        return const PromoValidation(
          result: PromoValidationResult.maxUsageReached,
        );
      }

      // Check per-user usage via subcollection
      int userUsageCount = 0;
      if (userId.isNotEmpty) {
        final userUsageDoc = await _db
            .collection('users')
            .doc(userId)
            .collection('usedPromoCodes')
            .doc(doc.id)
            .get();

        userUsageCount =
            (userUsageDoc.data()?['count'] as num?)?.toInt() ?? 0;
      }

      if (userUsageCount >= promo.maxUsagePerUser) {
        return const PromoValidation(
          result: PromoValidationResult.userLimitReached,
        );
      }

      // Restaurant-specific check
      if (promo.restaurantId != null &&
          promo.restaurantId != restaurantId) {
        return const PromoValidation(
          result: PromoValidationResult.wrongRestaurant,
        );
      }

      // Minimum order check
      if (promo.minOrderAmount > 0 && subtotal < promo.minOrderAmount) {
        return PromoValidation(
          result: PromoValidationResult.minimumOrderNotMet,
          promoCode: promo,
        );
      }

      final discount = promo.discountAmount(
        subtotal: subtotal,
        deliveryFee: deliveryFee,
      );

      return PromoValidation(
        result: PromoValidationResult.valid,
        promoCode: promo,
        discountAmount: discount,
      );
    } catch (e, s) {
      developer.log(
        'PromoCodeDatasource.validate failed',
        name: 'promo',
        level: 1000,
        error: e,
        stackTrace: s,
      );
      // Fail open: treat as not found rather than crashing checkout
      return const PromoValidation(
        result: PromoValidationResult.notFound,
      );
    }
  }

  /// Records a promo code redemption after a successful order.
  ///
  /// Uses a batch write to atomically:
  /// - Increment the code's global `usageCount`
  /// - Increment (or create) the user's usage doc
  Future<void> recordUsage({
    required String promoCodeId,
    required String userId,
  }) async {
    try {
      final batch = _db.batch();

      // Global counter increment
      final codeRef = _db.collection('promoCodes').doc(promoCodeId);
      batch.update(codeRef, {
        'usageCount': FieldValue.increment(1),
      });

      // Per-user counter (creates doc if missing)
      final userUsageRef = _db
          .collection('users')
          .doc(userId)
          .collection('usedPromoCodes')
          .doc(promoCodeId);

      batch.set(
        userUsageRef,
        {'count': FieldValue.increment(1), 'lastUsedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );

      await batch.commit();
    } catch (e, s) {
      developer.log(
        'PromoCodeDatasource.recordUsage failed',
        name: 'promo',
        level: 900,
        error: e,
        stackTrace: s,
      );
    }
  }

  // ── Admin / Restaurant-owner CRUD ──────────────────────────────────

  /// Stream all promo codes (admin view).
  Stream<List<PromoCode>> streamAll() => _db
      .collection('promoCodes')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) =>
          s.docs.map((d) => PromoCode.fromMap(d.data(), d.id)).toList());

  /// Stream promo codes for a specific restaurant only.
  Stream<List<PromoCode>> streamForRestaurant(String restaurantId) => _db
      .collection('promoCodes')
      .where('restaurantId', isEqualTo: restaurantId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) =>
          s.docs.map((d) => PromoCode.fromMap(d.data(), d.id)).toList());

  /// Creates a new promo code document.
  Future<void> create(PromoCode promo) async {
    final ref = _db.collection('promoCodes').doc();
    await ref.set(promo.copyWith(id: ref.id).toMap());
  }

  /// Updates an existing promo code.
  Future<void> update(PromoCode promo) async {
    await _db.collection('promoCodes').doc(promo.id).update(promo.toMap());
  }

  /// Toggles the `isActive` flag of a promo code.
  Future<void> toggleActive(String promoId, {required bool isActive}) async {
    await _db.collection('promoCodes').doc(promoId).update({
      'isActive': isActive,
    });
  }

  /// Permanently deletes a promo code.
  Future<void> delete(String promoId) async {
    await _db.collection('promoCodes').doc(promoId).delete();
  }
}
