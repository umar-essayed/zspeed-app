import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:z_speed/core/enums/order_enums.dart';

/// A payment record linked to an order.
///
/// Firestore path: `payments/{paymentId}`
///
/// Replaces 3× PaymentMethod classes:
///   - features/payment/model/payment_method.dart (int id, icon, color — pure UI)
///   - features/settings/widgets/payment_method_model.dart (String id, type, last4)
///   - pages/payment_provider.dart (String id, name, type, last4 + ChangeNotifier)
class Payment extends Equatable {
  final String id;
  final String orderId;
  final String customerId;
  final PaymentMethodType method;
  final PaymentStatus status;
  final double amount;
  final String? transactionId;
  final DateTime createdAt;
  final DateTime? completedAt;

  const Payment({
    required this.id,
    required this.orderId,
    required this.customerId,
    this.method = PaymentMethodType.cash,
    this.status = PaymentStatus.pending,
    required this.amount,
    this.transactionId,
    required this.createdAt,
    this.completedAt,
  });

  factory Payment.fromMap(Map<String, dynamic> map, String documentId) {
    return Payment(
      id: documentId,
      orderId: map['orderId'] as String? ?? '',
      customerId: map['customerId'] as String? ?? '',
      method: PaymentMethodTypeX.fromKey(map['method'] as String? ?? 'cash'),
      status: PaymentStatusX.fromKey(map['status'] as String? ?? 'pending'),
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      transactionId: map['transactionId'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (map['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'customerId': customerId,
      'method': method.key,
      'status': status.key,
      'amount': amount,
      'transactionId': transactionId,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  Payment copyWith({
    String? id,
    String? orderId,
    String? customerId,
    PaymentMethodType? method,
    PaymentStatus? status,
    double? amount,
    String? transactionId,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return Payment(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      customerId: customerId ?? this.customerId,
      method: method ?? this.method,
      status: status ?? this.status,
      amount: amount ?? this.amount,
      transactionId: transactionId ?? this.transactionId,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        orderId,
        customerId,
        method,
        status,
        amount,
        transactionId,
        createdAt,
        completedAt,
      ];
}
