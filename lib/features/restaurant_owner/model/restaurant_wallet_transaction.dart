import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:z_speed/core/enums/driver_enums.dart';

/// Wallet transaction for restaurant/vendor payments.
///
/// Tracks credits (earnings from card-paid orders) and debits (admin settlements).
/// Admin initiates payouts and uploads evidence; restaurant confirms receipt.
///
/// Firestore path: `restaurantWalletTransactions/{transactionId}`
class RestaurantWalletTransaction extends Equatable {
  final String id;
  final String restaurantId;
  final String orderId;
  final WalletTransactionType type;
  final double amount;
  final String description;
  final WalletTransactionStatus status;
  final PayoutMethod? payoutMethod;
  final String? evidenceUrl;
  final bool confirmedByOwner;
  final DateTime? confirmedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RestaurantWalletTransaction({
    required this.id,
    required this.restaurantId,
    required this.orderId,
    required this.type,
    required this.amount,
    required this.description,
    this.status = WalletTransactionStatus.pending,
    this.payoutMethod,
    this.evidenceUrl,
    this.confirmedByOwner = false,
    this.confirmedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RestaurantWalletTransaction.fromMap(
      Map<String, dynamic> map, String documentId) {
    return RestaurantWalletTransaction(
      id: documentId,
      restaurantId: map['restaurantId'] as String? ?? '',
      orderId: map['orderId'] as String? ?? '',
      type: WalletTransactionTypeX.fromKey(map['type'] as String? ?? 'credit'),
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      description: map['description'] as String? ?? '',
      status: WalletTransactionStatusX.fromKey(
          map['status'] as String? ?? 'pending'),
      payoutMethod: map['payoutMethod'] != null
          ? PayoutMethodX.fromKey(map['payoutMethod'] as String)
          : null,
      evidenceUrl: map['evidenceUrl'] as String?,
      confirmedByOwner: map['confirmedByOwner'] as bool? ?? false,
      confirmedAt: (map['confirmedAt'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'restaurantId': restaurantId,
      'orderId': orderId,
      'type': type.key,
      'amount': amount,
      'description': description,
      'status': status.key,
      'payoutMethod': payoutMethod?.key,
      'evidenceUrl': evidenceUrl,
      'confirmedByOwner': confirmedByOwner,
      'confirmedAt':
          confirmedAt != null ? Timestamp.fromDate(confirmedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  RestaurantWalletTransaction copyWith({
    String? id,
    String? restaurantId,
    String? orderId,
    WalletTransactionType? type,
    double? amount,
    String? description,
    WalletTransactionStatus? status,
    PayoutMethod? payoutMethod,
    String? evidenceUrl,
    bool? confirmedByOwner,
    DateTime? confirmedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RestaurantWalletTransaction(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      orderId: orderId ?? this.orderId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      status: status ?? this.status,
      payoutMethod: payoutMethod ?? this.payoutMethod,
      evidenceUrl: evidenceUrl ?? this.evidenceUrl,
      confirmedByOwner: confirmedByOwner ?? this.confirmedByOwner,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        restaurantId,
        orderId,
        type,
        amount,
        description,
        status,
        payoutMethod,
        evidenceUrl,
        confirmedByOwner,
        confirmedAt,
        createdAt,
        updatedAt,
      ];
}
