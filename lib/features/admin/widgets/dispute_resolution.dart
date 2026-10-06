import 'package:z_speed/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:z_speed/features/admin/widgets/dispute_card.dart';
import 'package:z_speed/features/admin/widgets/dispute_dialogs.dart';
import 'package:z_speed/features/admin/widgets/dispute_model.dart';
import 'package:z_speed/features/admin/widgets/dispute_summary_card.dart';

class DisputeResolution extends StatefulWidget {
  const DisputeResolution({super.key});

  @override
  State<DisputeResolution> createState() => _DisputeResolutionState();
}

class _DisputeResolutionState extends State<DisputeResolution> {
  List<Dispute> disputes = [
    Dispute(
        id: "#DISP-001",
        type: "Quality Issue",
        customer: "Ahmed S.",
        restaurant: "Restaurant XYZ",
        amount: 150,
        status: "pending",
        reportedDate: "2024-11-09",
        description: "Food was cold and not fresh. Expected hot meal."),
    Dispute(
        id: "#DISP-002",
        type: "Wrong Order",
        customer: "Fatima M.",
        restaurant: "Pizza Palace",
        amount: 120,
        status: "approved",
        reportedDate: "2024-11-08",
        description:
            "Received wrong order - ordered pepperoni got margherita."),
    Dispute(
        id: "#DISP-003",
        type: "Missing Items",
        customer: "Mohamed K.",
        restaurant: "Burger King",
        amount: 85,
        status: "rejected",
        reportedDate: "2024-11-07",
        description: "Missing sauce and napkins in the order."),
    Dispute(
        id: "#DISP-004",
        type: "Late Delivery",
        customer: "Sara A.",
        restaurant: "Burger House",
        amount: 200,
        status: "pending",
        reportedDate: "2024-11-10",
        description: "Order arrived 1.5 hours later than promised."),
    Dispute(
        id: "#DISP-005",
        type: "Wrong Address",
        customer: "Omar K.",
        restaurant: "Pizza Hut",
        amount: 180,
        status: "pending",
        reportedDate: "2024-11-10",
        description: "Food delivered to wrong address, had to reorder."),
  ];

  void updateDisputeStatus(String id, String newStatus) {
    setState(() {
      disputes = disputes.map((d) {
        if (d.id == id) d.status = newStatus;
        return d;
      }).toList();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.disputeStatusUpdated(id.toString(), newStatus.toString())),
        backgroundColor: newStatus == 'approved'
            ? Colors.orange.shade600
            : newStatus == 'rejected'
                ? Colors.orange.shade800
                : Colors.orange,
      ),
    );
  }

  void _sortDisputes(String type) {
    setState(() {
      switch (type) {
        case 'newest':
          disputes.sort((a, b) => b.reportedDate.compareTo(a.reportedDate));
        case 'oldest':
          disputes.sort((a, b) => a.reportedDate.compareTo(b.reportedDate));
        case 'amount_high':
          disputes.sort((a, b) => b.amount.compareTo(a.amount));
        case 'amount_low':
          disputes.sort((a, b) => a.amount.compareTo(b.amount));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = disputes.where((d) => d.status == "pending").length;
    final approvedAmount = disputes
        .where((d) => d.status == "approved")
        .fold<double>(0, (sum, d) => sum + d.amount);
    final rejectedCount = disputes.where((d) => d.status == "rejected").length;
    final totalAmount = disputes.fold<double>(0, (sum, d) => sum + d.amount);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.disputeResolution,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange.shade600,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: () => showDisputeFilterDialog(context),
          ),
        ],
      ),
      body: Container(
        color: Colors.grey.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Summary Cards
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  DisputeSummaryCard(
                      title: "Pending",
                      value: "$pendingCount",
                      color: Colors.orange.shade600,
                      icon: Icons.access_time,
                      count: pendingCount),
                  DisputeSummaryCard(
                      title: "Approved",
                      value: "EGP ${approvedAmount.toStringAsFixed(0)}",
                      color: Colors.green.shade600,
                      icon: Icons.check_circle),
                  DisputeSummaryCard(
                      title: "Rejected",
                      value: "$rejectedCount",
                      color: Colors.red.shade600,
                      icon: Icons.error,
                      count: rejectedCount),
                  DisputeSummaryCard(
                      title: "Total Amount",
                      value: "EGP ${totalAmount.toStringAsFixed(0)}",
                      color: Colors.orange.shade800,
                      icon: Icons.attach_money),
                ],
              ),
              const SizedBox(height: 24),

              // Stats Row
              _buildStatsRow(),
              const SizedBox(height: 16),

              // Dispute List
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: disputes.length,
                  itemBuilder: (context, index) {
                    final dispute = disputes[index];
                    return DisputeCard(
                      dispute: dispute,
                      onReview: () => showDisputeReviewDialog(
                          context, dispute, updateDisputeStatus),
                      onApprove: () =>
                          updateDisputeStatus(dispute.id, "approved"),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(AppLocalizations.of(context)!.allDisputesCount(int.parse(disputes.length.toString())), style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
          Container(
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade100, width: 1),
            ),
            child: PopupMenuButton<String>(
              onSelected: _sortDisputes,
              itemBuilder: (_) => [
                _sortMenuItem('newest', Icons.new_releases, 'Newest First'),
                _sortMenuItem('oldest', Icons.history, 'Oldest First'),
                _sortMenuItem(
                    'amount_high', Icons.arrow_downward, 'Amount: High to Low'),
                _sortMenuItem(
                    'amount_low', Icons.arrow_upward, 'Amount: Low to High'),
              ],
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text(AppLocalizations.of(context)!.sortBy,
                        style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_drop_down,
                        size: 20, color: Color.fromARGB(255, 10, 10, 10)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _sortMenuItem(
      String value, IconData icon, String label) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: Colors.orange.shade600, size: 20),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}
