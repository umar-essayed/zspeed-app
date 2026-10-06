import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:z_speed/features/payment/model/payment.dart';
import 'package:z_speed/core/enums/order_enums.dart';
import 'package:injectable/injectable.dart' hide Order;

/// Payment Firebase Datasource — handles Firestore CRUD for payments collection.
///
/// Collection: `payments/{paymentId}`
@lazySingleton
class PaymentFirebaseDatasource {
  final FirebaseFirestore _db;

  PaymentFirebaseDatasource({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _paymentsRef =>
      _db.collection('payments');

  /// Create a payment document, returns generated paymentId
  Future<String> createPayment(Payment payment) async {
    final paymentId = payment.id.isEmpty ? _paymentsRef.doc().id : payment.id;
    final paymentWithId = payment.copyWith(id: paymentId);

    await _paymentsRef.doc(paymentId).set(paymentWithId.toMap());
    return paymentId;
  }

  /// Get payment by ID
  Future<Payment?> getPaymentById(String paymentId) async {
    final doc = await _paymentsRef.doc(paymentId).get();
    if (!doc.exists) return null;
    return Payment.fromMap(doc.data()!, doc.id);
  }

  /// Get payment by order ID (1:1 relationship)
  Future<Payment?> getPaymentByOrderId(String orderId) async {
    // Also filter by customerId to satisfy Firestore security rules
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) return null;

    final querySnapshot = await _paymentsRef
        .where('orderId', isEqualTo: orderId)
        .where('customerId', isEqualTo: auth.currentUser!.uid)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) return null;
    final doc = querySnapshot.docs.first;
    return Payment.fromMap(doc.data(), doc.id);
  }

  /// Stream payment status updates in real-time (for receipt view, order tracking)
  Stream<Payment?> streamPayment(String paymentId) {
    return _paymentsRef.doc(paymentId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return Payment.fromMap(snapshot.data()!, snapshot.id);
    });
  }

  /// Stream customer's payment history (latest first)
  Stream<List<Payment>> streamCustomerPayments(String customerId) {
    return _paymentsRef
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Payment.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Update payment status (typically called by Cloud Functions or admin)
  Future<void> updatePaymentStatus(
    String paymentId,
    PaymentStatus status, {
    String? transactionId,
    DateTime? completedAt,
  }) async {
    final updateData = <String, dynamic>{
      'status': status.key,
    };

    if (transactionId != null) {
      updateData['transactionId'] = transactionId;
    }

    if (completedAt != null) {
      updateData['completedAt'] = Timestamp.fromDate(completedAt);
    }

    await _paymentsRef.doc(paymentId).update(updateData);
  }
}
