import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:z_speed/core/enums/user_enums.dart';

// ── Enums ────────────────────────────────────────────────────────────────────

enum ApplicationType { driver, restaurant, vendor }

/// Backward compatibility alias for existing code using ReviewStatus
typedef ReviewStatus = ApplicationStatus;

// ── Model ────────────────────────────────────────────────────────────────────

/// A driver or vendor application submitted for admin review.
///
/// Stored in the Firestore `applications` collection.
/// Contains form data (personal info, vehicle info, bank info, etc.)
/// and references to uploaded document URLs in B2 storage.
/// Per-section review status for vendor applications.
enum SectionReviewStatus { pending, approved, rejected }

class Application extends Equatable {
  final String id;
  final String userId;
  final ApplicationType applicationType;
  final ReviewStatus status;
  final Map<String, dynamic> formData;
  final List<String> documentUrls;
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// Per-section approval statuses.
  /// Keys: 'businessInfo', 'locationInfo', 'contactInfo', 'bankInfo'
  /// Values: 'pending' | 'approved' | 'rejected'
  final Map<String, String> sectionStatuses;

  /// Per-section rejection reasons (only for rejected sections).
  final Map<String, String> sectionReasons;

  const Application({
    required this.id,
    required this.userId,
    required this.applicationType,
    this.status = ReviewStatus.pending,
    this.formData = const {},
    this.documentUrls = const [],
    required this.submittedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.rejectionReason,
    required this.createdAt,
    this.updatedAt,
    this.sectionStatuses = const {},
    this.sectionReasons = const {},
  });

  // ── Convenience getters ────────────────────────────────────────────────────

  bool get isPending =>
      status == ReviewStatus.pending || status == ReviewStatus.underReview;

  bool get isFinalized =>
      status == ReviewStatus.approved || status == ReviewStatus.rejected;

  bool get isApproved => status == ReviewStatus.approved;
  bool get isRejected => status == ReviewStatus.rejected;

  /// Whether all vendor sections have been reviewed (approved or rejected).
  bool get allSectionsReviewed {
    const vendorSections = [
      'businessInfo',
      'locationInfo',
      'contactInfo',
      'bankInfo'
    ];
    return vendorSections.every((s) {
      final st = sectionStatuses[s];
      return st == 'approved' || st == 'rejected';
    });
  }

  /// Whether all vendor sections are approved.
  bool get allSectionsApproved {
    const vendorSections = [
      'businessInfo',
      'locationInfo',
      'contactInfo',
      'bankInfo'
    ];
    return vendorSections.every((s) => sectionStatuses[s] == 'approved');
  }

  /// Get the review status of a specific section.
  SectionReviewStatus sectionStatus(String sectionKey) {
    final st = sectionStatuses[sectionKey];
    if (st == 'approved') return SectionReviewStatus.approved;
    if (st == 'rejected') return SectionReviewStatus.rejected;
    return SectionReviewStatus.pending;
  }

  String get typeDisplayName {
    switch (applicationType) {
      case ApplicationType.driver:
        return 'Driver';
      case ApplicationType.restaurant:
      case ApplicationType.vendor:
        return 'Restaurant';
    }
  }

  // ── Firestore serialization ────────────────────────────────────────────────

  factory Application.fromMap(Map<String, dynamic> data, String documentId) {
    return Application(
      id: documentId,
      userId: data['userId'] ?? '',
      applicationType: ApplicationType.values.firstWhere(
        (e) => e.name == data['applicationType'],
        orElse: () => ApplicationType.restaurant,
      ),
      status: ReviewStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => ReviewStatus.pending,
      ),
      formData: Map<String, dynamic>.from(data['formData'] ?? {}),
      sectionStatuses: Map<String, String>.from(data['sectionStatuses'] ?? {}),
      sectionReasons: Map<String, String>.from(data['sectionReasons'] ?? {}),
      documentUrls: List<String>.from(data['documentUrls'] ?? []),
      submittedAt: _timestampToDateTime(data['submittedAt']) ?? DateTime.now(),
      reviewedAt: _timestampToDateTime(data['reviewedAt']),
      reviewedBy: data['reviewedBy'],
      rejectionReason: data['rejectionReason'],
      createdAt: _timestampToDateTime(data['createdAt']) ?? DateTime.now(),
      updatedAt: _timestampToDateTime(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'applicationType': applicationType.name,
      'status': status.name,
      'formData': formData,
      'sectionStatuses': sectionStatuses,
      'sectionReasons': sectionReasons,
      'documentUrls': documentUrls,
      'submittedAt': Timestamp.fromDate(submittedAt),
      if (reviewedAt != null) 'reviewedAt': Timestamp.fromDate(reviewedAt!),
      'reviewedBy': reviewedBy,
      'rejectionReason': rejectionReason,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  // ── copyWith ───────────────────────────────────────────────────────────────

  Application copyWith({
    String? id,
    String? userId,
    ApplicationType? applicationType,
    ReviewStatus? status,
    Map<String, dynamic>? formData,
    List<String>? documentUrls,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, String>? sectionStatuses,
    Map<String, String>? sectionReasons,
  }) {
    return Application(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      applicationType: applicationType ?? this.applicationType,
      status: status ?? this.status,
      formData: formData ?? this.formData,
      documentUrls: documentUrls ?? this.documentUrls,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sectionStatuses: sectionStatuses ?? this.sectionStatuses,
      sectionReasons: sectionReasons ?? this.sectionReasons,
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static DateTime? _timestampToDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  String toString() =>
      'Application(id: $id, type: ${applicationType.name}, status: ${status.name})';

  @override
  List<Object?> get props => [
        id,
        userId,
        applicationType,
        status,
        formData,
        documentUrls,
        submittedAt,
        reviewedAt,
        reviewedBy,
        rejectionReason,
        createdAt,
        updatedAt,
        sectionStatuses,
        sectionReasons,
      ];
}
