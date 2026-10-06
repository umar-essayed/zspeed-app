import 'package:z_speed/core/errors/failures.dart';
import 'package:z_speed/core/result/result.dart';
import 'package:z_speed/features/payment/datasource/payment_firebase_datasource.dart';
import 'package:z_speed/features/payment/model/payment.dart';
import 'package:z_speed/features/payment/repository/payment_repository.dart';
import 'package:z_speed/core/enums/order_enums.dart';
import 'package:injectable/injectable.dart' hide Order;

@LazySingleton(as: PaymentRepository)
class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentFirebaseDatasource _datasource;

  PaymentRepositoryImpl({PaymentFirebaseDatasource? datasource})
      : _datasource = datasource ?? PaymentFirebaseDatasource();

  @override
  Future<Result<String>> createPayment(Payment payment) async {
    try {
      final paymentId = await _datasource.createPayment(payment);
      return Success(paymentId);
    } catch (e, stackTrace) {
      return Err(UnexpectedFailure('Failed to create payment: $e', stackTrace));
    }
  }

  @override
  Future<Result<Payment>> getPaymentById(String paymentId) async {
    try {
      final payment = await _datasource.getPaymentById(paymentId);
      if (payment == null) {
        return Err(UnexpectedFailure('Payment not found'));
      }
      return Success(payment);
    } catch (e, stackTrace) {
      return Err(UnexpectedFailure('Failed to get payment: $e', stackTrace));
    }
  }

  @override
  Future<Result<Payment>> getPaymentByOrderId(String orderId) async {
    try {
      final payment = await _datasource.getPaymentByOrderId(orderId);
      if (payment == null) {
        return Err(UnexpectedFailure('Payment not found for order'));
      }
      return Success(payment);
    } catch (e, stackTrace) {
      return Err(
          UnexpectedFailure('Failed to get payment by order: $e', stackTrace));
    }
  }

  @override
  Stream<Payment?> streamPayment(String paymentId) {
    return _datasource.streamPayment(paymentId);
  }

  @override
  Stream<List<Payment>> streamCustomerPayments(String customerId) {
    return _datasource.streamCustomerPayments(customerId);
  }

  @override
  Future<Result<void>> updatePaymentStatus(
    String paymentId,
    PaymentStatus status, {
    String? transactionId,
  }) async {
    try {
      await _datasource.updatePaymentStatus(
        paymentId,
        status,
        transactionId: transactionId,
        completedAt: status == PaymentStatus.completed ? DateTime.now() : null,
      );
      return Success(null);
    } catch (e, stackTrace) {
      return Err(
          UnexpectedFailure('Failed to update payment status: $e', stackTrace));
    }
  }
}
