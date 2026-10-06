import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart' hide Order;
import 'package:uuid/uuid.dart';
import 'package:z_speed/features/review/model/review.dart';

/// Firestore datasource for customer reviews.
///
/// Reviews are stored at: `restaurants/{restaurantId}/reviews/{reviewId}`
/// After writing a review, updates the restaurant's `rating` and `ratingCount`
/// fields using a Firestore transaction for accuracy.
@lazySingleton
class ReviewFirebaseDatasource {
  final FirebaseFirestore _firestore;

  ReviewFirebaseDatasource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _reviews(String restaurantId) =>
      _firestore.collection('vendors').doc(restaurantId).collection('reviews');

  DocumentReference<Map<String, dynamic>> _restaurantDoc(String restaurantId) =>
      _firestore.collection('vendors').doc(restaurantId);

  // ── Submit ─────────────────────────────────────────────────────────────────

  /// Submit a new review and atomically recalculate restaurant rating.
  ///
  /// Steps:
  /// 1. Write the review document to the subcollection.
  /// 2. Use a transaction on the restaurant doc to update rating/ratingCount.
  ///    (Reads must come before writes inside a Firestore transaction.)
  Future<Review> submitReview({
    required String restaurantId,
    required String customerId,
    required String orderId,
    required double rating,
    String? comment,
  }) async {
    final id = const Uuid().v4();
    final now = DateTime.now();
    final review = Review(
      id: id,
      orderId: orderId,
      customerId: customerId,
      restaurantId: restaurantId,
      rating: rating,
      comment: comment?.trim().isEmpty == true ? null : comment?.trim(),
      createdAt: now,
    );

    // Step 1: write review document (outside transaction — subcollection writes
    // inside transactions are unsupported on Flutter SDK).
    await _reviews(restaurantId).doc(id).set(review.toMap());

    // Step 2: atomically update restaurant aggregate (read → then write).
    // Non-fatal: if this fails (e.g. transient network), the review is already
    // saved and a background recalculation can fix the aggregate later.
    try {
      final restaurantRef = _restaurantDoc(restaurantId);
      await _firestore.runTransaction((txn) async {
        final snap = await txn.get(restaurantRef); // read first
        final data = snap.data() ?? {};
        final oldCount = (data['ratingCount'] as num?)?.toInt() ?? 0;
        final oldRating = (data['rating'] as num?)?.toDouble() ?? 0.0;

        final newCount = oldCount + 1;
        final newRating = ((oldRating * oldCount) + rating) / newCount;

        txn.update(restaurantRef, {  // write after read
          'rating': double.parse(newRating.toStringAsFixed(2)),
          'ratingCount': newCount,
        });
      });
    } catch (e) {
      log('ReviewFirebaseDatasource: rating aggregate update failed (non-fatal): $e');
    }

    log('ReviewFirebaseDatasource: submitted review $id for restaurant $restaurantId');
    return review;
  }

  // ── Check duplicate ────────────────────────────────────────────────────────

  /// Returns true if the customer already reviewed this specific order.
  Future<bool> hasReviewed({
    required String restaurantId,
    required String orderId,
  }) async {
    final snap = await _reviews(restaurantId)
        .where('orderId', isEqualTo: orderId)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  // ── Fetch ──────────────────────────────────────────────────────────────────

  /// Fetch recent reviews for a restaurant (newest first, max [limit]).
  Future<List<Review>> fetchReviews({
    required String restaurantId,
    int limit = 20,
  }) async {
    final snap = await _reviews(restaurantId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs
        .map((d) => Review.fromMap(d.data(), d.id))
        .toList();
  }

  /// Stream reviews in real-time (for restaurant owner dashboard).
  Stream<List<Review>> streamReviews(String restaurantId) {
    return _reviews(restaurantId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Review.fromMap(d.data(), d.id)).toList());
  }
}
