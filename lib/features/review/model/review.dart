import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// A customer review for a restaurant (linked to an order).
///
/// Firestore path: `restaurants/{restaurantId}/reviews/{reviewId}`
class Review extends Equatable {
  final String id;
  final String orderId;
  final String customerId;
  final String restaurantId;
  final double rating;
  final String? comment;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.orderId,
    required this.customerId,
    required this.restaurantId,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory Review.fromMap(Map<String, dynamic> map, String documentId) {
    return Review(
      id: documentId,
      orderId: map['orderId'] as String? ?? '',
      customerId: map['customerId'] as String? ?? '',
      restaurantId: map['restaurantId'] as String? ?? map['vendorId'] as String? ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      comment: map['comment'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'orderId': orderId,
      'customerId': customerId,
      'restaurantId': restaurantId,
      'vendorId': restaurantId,
      'rating': rating,
      'createdAt': Timestamp.fromDate(createdAt),
    };
    if (comment != null) {
      map['comment'] = comment;
    }
    return map;
  }

  Review copyWith({
    String? id,
    String? orderId,
    String? customerId,
    String? restaurantId,
    double? rating,
    String? comment,
    DateTime? createdAt,
  }) {
    return Review(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      customerId: customerId ?? this.customerId,
      restaurantId: restaurantId ?? this.restaurantId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, orderId, customerId, restaurantId, rating, comment, createdAt];
}
