import 'package:flutter/material.dart';
import 'package:z_speed/core/enums/order_enums.dart';

/// Payment Status Badge — displays payment status as a colored chip.
///
/// Phase 8.9: Small reusable widget for showing payment status in:
/// - Order tracking screen
/// - Order history list
/// - Admin order management
///
/// Usage:
/// ```dart
/// PaymentStatusBadge(status: PaymentStatus.completed)
/// ```
class PaymentStatusBadge extends StatelessWidget {
  final PaymentStatus status;
  final bool showIcon;
  final double fontSize;

  const PaymentStatusBadge({
    super.key,
    required this.status,
    this.showIcon = true,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(status).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              _getStatusIcon(status),
              size: fontSize + 2,
              color: _getStatusColor(status),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            _getStatusText(context, status),
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: _getStatusColor(status),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(BuildContext context, PaymentStatus status) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    switch (status) {
      case PaymentStatus.pending:
        return isAr ? 'معلق' : 'Pending';
      case PaymentStatus.completed:
        return isAr ? 'مدفوع' : 'Paid';
      case PaymentStatus.failed:
        return isAr ? 'فشل الدفع' : 'Failed';
      case PaymentStatus.refunded:
        return isAr ? 'مسترد' : 'Refunded';
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
}
