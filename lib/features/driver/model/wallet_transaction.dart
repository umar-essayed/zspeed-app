import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:z_speed/core/enums/driver_enums.dart';

/// Wallet transaction for driver payments.
///
/// Tracks credits (delivery fees from card payments) and debits (payouts).
/// Restaurant pays driver via InstaPay/Vodafone Cash, uploads evidence,
/// driver confirms receipt, and balance updates.
///
/// Firestore path: `driverWalletTransactions/{transactionId}`
class WalletTransaction extends Equatable {
  final String id;
  final String driverId;
  final String orderId;
  final WalletTransactionType type;
  final double amount;
  final String description;
  final WalletTransactionStatus status;
  final PayoutMethod? paymentMethod;
  final String? evidenceUrl;
  final bool confirmedByDriver;
  final DateTime? confirmedAt;
  final bool disputedByAdmin;
  final String? disputeReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WalletTransaction({
    required this.id,
    required this.driverId,
    required this.orderId,
    required this.type,
    required this.amount,
    required this.description,
    this.status = WalletTransactionStatus.pending,
    this.paymentMethod,
    this.evidenceUrl,
    this.confirmedByDriver = false,
    this.confirmedAt,
    this.disputedByAdmin = false,
    this.disputeReason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WalletTransaction.fromMap(
      Map<String, dynamic> map, String documentId) {
    return WalletTransaction(
      id: documentId,
      driverId: map['driverId'] as String? ?? '',
      orderId: map['orderId'] as String? ?? '',
      type: WalletTransactionTypeX.fromKey(map['type'] as String? ?? 'credit'),
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      description: map['description'] as String? ?? '',
      status: WalletTransactionStatusX.fromKey(
          map['status'] as String? ?? 'pending'),
      paymentMethod: map['paymentMethod'] != null
          ? PayoutMethodX.fromKey(map['paymentMethod'] as String)
          : null,
      evidenceUrl: map['evidenceUrl'] as String?,
      confirmedByDriver: map['confirmedByDriver'] as bool? ?? false,
      confirmedAt: (map['confirmedAt'] as Timestamp?)?.toDate(),
      disputedByAdmin: map['disputedByAdmin'] as bool? ?? false,
      disputeReason: map['disputeReason'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'driverId': driverId,
      'orderId': orderId,
      'type': type.key,
      'amount': amount,
      'description': description,
      'status': status.key,
      'paymentMethod': paymentMethod?.key,
      'evidenceUrl': evidenceUrl,
      'confirmedByDriver': confirmedByDriver,
      'confirmedAt':
          confirmedAt != null ? Timestamp.fromDate(confirmedAt!) : null,
      'disputedByAdmin': disputedByAdmin,
      'disputeReason': disputeReason,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  WalletTransaction copyWith({
    String? id,
    String? driverId,
    String? orderId,
    WalletTransactionType? type,
    double? amount,
    String? description,
    WalletTransactionStatus? status,
    PayoutMethod? paymentMethod,
    String? evidenceUrl,
    bool? confirmedByDriver,
    DateTime? confirmedAt,
    bool? disputedByAdmin,
    String? disputeReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WalletTransaction(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      orderId: orderId ?? this.orderId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      evidenceUrl: evidenceUrl ?? this.evidenceUrl,
      confirmedByDriver: confirmedByDriver ?? this.confirmedByDriver,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      disputedByAdmin: disputedByAdmin ?? this.disputedByAdmin,
      disputeReason: disputeReason ?? this.disputeReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        driverId,
        orderId,
        type,
        amount,
        description,
        status,
        paymentMethod,
        evidenceUrl,
        confirmedByDriver,
        confirmedAt,
        disputedByAdmin,
        disputeReason,
        createdAt,
        updatedAt,
      ];
}
