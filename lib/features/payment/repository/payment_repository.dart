import 'package:z_speed/core/result/result.dart';
import 'package:z_speed/features/payment/model/payment.dart';
import 'package:z_speed/core/enums/order_enums.dart';

/// Payment Repository — abstract interface for payment operations.
///
abstract class PaymentRepository {
  /// Create a payment document
  Future<Result<String>> createPayment(Payment payment);

  /// Get payment by ID
  Future<Result<Payment>> getPaymentById(String paymentId);

  /// Get payment by order ID
  Future<Result<Payment>> getPaymentByOrderId(String orderId);

  /// Stream payment updates in real-time
  Stream<Payment?> streamPayment(String paymentId);

  /// Stream customer's payment history
  Stream<List<Payment>> streamCustomerPayments(String customerId);

  /// Update payment status (admin/Cloud Function)
  Future<Result<void>> updatePaymentStatus(
    String paymentId,
    PaymentStatus status, {
    String? transactionId,
  });
}
