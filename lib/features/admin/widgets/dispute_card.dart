import 'package:flutter/material.dart';
import 'package:z_speed/l10n/app_localizations.dart';
import 'package:z_speed/features/admin/widgets/dispute_model.dart';

/// Card widget for a single dispute in the list.
class DisputeCard extends StatelessWidget {
  const DisputeCard({
    super.key,
    required this.dispute,
    required this.onReview,
    required this.onApprove,
  });

  final Dispute dispute;
  final VoidCallback onReview;
  final VoidCallback onApprove;

  @override
  Widget build(BuildContext context) {
    final sColor = disputeStatusColor(dispute.status);
    final sIcon = disputeStatusIcon(dispute.status);

    return Container(
      margin: const EdgeInsetsDirectional.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.shade200, blurRadius: 8, spreadRadius: 1),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: sColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: sColor.withValues(alpha: 0.2), width: 1),
                      ),
                      child: sIcon,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(dispute.id,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black87)),
                        const SizedBox(height: 2),
                        Text(dispute.type,
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: sColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: sColor.withValues(alpha: 0.3), width: 1),
                  ),
                  child: Text(
                    dispute.status.toUpperCase(),
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: sColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Details Row
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  _detailColumn('Customer', dispute.customer),
                  Container(height: 30, width: 1, color: Colors.grey.shade300),
                  _detailColumn('Restaurant', dispute.restaurant, padded: true),
                  Container(height: 30, width: 1, color: Colors.grey.shade300),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppLocalizations.of(context)!.amount,
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text(AppLocalizations.of(context)!.egpAmount(dispute.amount.toStringAsFixed(0).toString()), style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade700,
                                fontSize: 16)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Description
            Text(AppLocalizations.of(context)!.description,
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade100, width: 1),
              ),
              child: Text(dispute.description,
                  style: const TextStyle(
                      fontSize: 14, height: 1.4, color: Colors.black87)),
            ),
            const SizedBox(height: 12),

            // Date and Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppLocalizations.of(context)!.reportedOnDate(dispute.reportedDate.toString()), style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic)),
                if (dispute.status == "pending")
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: onReview,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.orange.shade600,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                                color: Colors.orange.shade300, width: 1),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.reviews, size: 16),
                            const SizedBox(width: 6),
                            Text(AppLocalizations.of(context)!.review),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: onApprove,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check, size: 16),
                            const SizedBox(width: 6),
                            Text(AppLocalizations.of(context)!.approve),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailColumn(String label, String value, {bool padded = false}) {
    final child = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: Colors.black87)),
      ],
    );
    return Expanded(
      child: padded
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12), child: child)
          : child,
    );
  }
}
