import 'package:flutter/material.dart';

class Dispute {
  final String id;
  final String type;
  final String customer;
  final String restaurant;
  final double amount;
  String status;
  final String reportedDate;
  final String description;

  Dispute({
    required this.id,
    required this.type,
    required this.customer,
    required this.restaurant,
    required this.amount,
    required this.status,
    required this.reportedDate,
    required this.description,
  });
}

Color disputeStatusColor(String status) {
  switch (status) {
    case "pending":
      return Colors.orange;
    case "approved":
      return Colors.green;
    case "rejected":
      return Colors.red;
    default:
      return Colors.grey;
  }
}

Icon disputeStatusIcon(String status) {
  switch (status) {
    case "pending":
      return Icon(Icons.access_time, color: Colors.orange.shade600, size: 18);
    case "approved":
      return Icon(Icons.check_circle, color: Colors.green.shade600, size: 18);
    case "rejected":
      return Icon(Icons.error, color: Colors.red.shade600, size: 18);
    default:
      return Icon(Icons.info, color: Colors.grey.shade600, size: 18);
  }
}
