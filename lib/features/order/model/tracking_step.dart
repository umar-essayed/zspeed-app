import 'package:flutter/material.dart';

/// Represents a single step in the order tracking timeline.
class TrackingStep {
  final IconData icon;
  final String title;
  final String subtitle;
  final DateTime? timestamp;
  final bool isComplete;

  TrackingStep({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.timestamp,
    required this.isComplete,
  });
}
