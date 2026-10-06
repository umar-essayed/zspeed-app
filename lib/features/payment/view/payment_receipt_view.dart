import 'package:z_speed/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:z_speed/core/utils/receipt_generator.dart';
import 'package:z_speed/core/enums/order_enums.dart';
import 'package:z_speed/features/payment/model/payment.dart';
import 'package:intl/intl.dart';

/// Payment Receipt View — displays payment details in receipt format.
///
/// Phase 8.9: Full-screen view showing:
/// - Payment ID, Order ID, amount
/// - Payment method, status, timestamps
/// - Transaction ID (if available)
///
/// Usage:
/// ```dart
/// Navigator.push(context, MaterialPageRoute(
///   builder: (_) => PaymentReceiptView(payment: payment),
/// ));
/// ```
class PaymentReceiptView extends StatelessWidget {
  final Payment payment;

  const PaymentReceiptView({
    super.key,
    required this.payment,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.paymentReceipt),
        backgroundColor: const Color(0xFFF35535),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Icon
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _getStatusColor(payment.status).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getStatusIcon(payment.status),
                  size: 40,
                  color: _getStatusColor(payment.status),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Status Text
            Center(
              child: Text(
                _getStatusText(context, payment.status),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _getStatusColor(payment.status),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Amount
            Center(
              child: Text(
                AppLocalizations.of(context)!
                    .egpAmount(payment.amount.toStringAsFixed(2)),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Receipt Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.paymentDetails,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                      AppLocalizations.of(context)!.paymentId, payment.id),
                  const Divider(height: 24),
                  _buildDetailRow(AppLocalizations.of(context)!.orderIdLabel,
                      payment.orderId),
                  const Divider(height: 24),
                  _buildDetailRow(
                      AppLocalizations.of(context)!.paymentMethodLabel,
                      _getMethodName(context, payment.method)),
                  const Divider(height: 24),
                  _buildDetailRow(AppLocalizations.of(context)!.status,
                      _getStatusText(context, payment.status)),
                  const Divider(height: 24),
                  _buildDetailRow(
                    AppLocalizations.of(context)!.createdAt,
                    DateFormat('MMM dd, yyyy • hh:mm a')
                        .format(payment.createdAt),
                  ),
                  if (payment.completedAt != null) ...[
                    const Divider(height: 24),
                    _buildDetailRow(
                      AppLocalizations.of(context)!.completedAt,
                      DateFormat('MMM dd, yyyy • hh:mm a')
                          .format(payment.completedAt!),
                    ),
                  ],
                  if (payment.transactionId != null &&
                      payment.transactionId!.isNotEmpty) ...[
                    const Divider(height: 24),
                    _buildDetailRow(AppLocalizations.of(context)!.transactionId,
                        payment.transactionId!),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action Button
            if (payment.status == PaymentStatus.completed)
              ElevatedButton.icon(
                onPressed: () async {
                  await ReceiptGenerator.generateAndShareReceipt(
                    orderId: payment.orderId,
                    restaurantName: 'Z Speed Delivery',
                    totalAmount: payment.amount,
                    date: payment.createdAt,
                  );
                },
                icon: const Icon(Icons.share),
                label: Text(AppLocalizations.of(context)!.shareReceipt),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF35535),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
        ),
      ],
    );
  }

  String _getStatusText(BuildContext context, PaymentStatus status) {
    final l = AppLocalizations.of(context)!;
    switch (status) {
      case PaymentStatus.pending:
        return l.paymentStatusPending;
      case PaymentStatus.completed:
        return l.paymentStatusCompleted;
      case PaymentStatus.failed:
        return l.paymentStatusFailed;
      case PaymentStatus.refunded:
        return l.paymentStatusRefunded;
    }
  }

  IconData _getStatusIcon(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return Icons.schedule;
      case PaymentStatus.completed:
        return Icons.check_circle;
      case PaymentStatus.failed:
        return Icons.cancel;
      case PaymentStatus.refunded:
        return Icons.replay_circle_filled;
    }
  }

  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.completed:
        return Colors.green;
      case PaymentStatus.failed:
        return Colors.red;
      case PaymentStatus.refunded:
        return Colors.blue;
    }
  }

  String _getMethodName(BuildContext context, PaymentMethodType method) {
    final l = AppLocalizations.of(context)!;
    switch (method) {
      case PaymentMethodType.cash:
        return l.paymentMethodCash;
      case PaymentMethodType.card:
        return l.paymentMethodCard;
      case PaymentMethodType.wallet:
        return l.paymentMethodWallet;
    }
  }
}
