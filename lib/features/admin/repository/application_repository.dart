import 'package:z_speed/core/core.dart';
import 'package:z_speed/features/admin/model/application_model.dart';

/// Repository interface for application (driver/vendor) management.
///
/// Used by:
/// - Driver/Vendor application forms (submit)
/// - Admin application review (list, approve, reject)
abstract class ApplicationRepository {
  /// Submit a driver application with form data and uploaded document URLs.
  Future<Result<String>> submitApplication({
    required String userId,
    required ApplicationType type,
    required Map<String, dynamic> formData,
    required List<String> documentUrls,
  });

  /// Fetch all applications, optionally filtered by [type] and/or [status].
  Future<Result<List<Application>>> getApplications({
    ApplicationType? type,
    ReviewStatus? status,
  });

  /// Fetch a single application by its Firestore document ID.
  Future<Result<Application>> getApplicationById(String id);

  /// Get all applications submitted by a specific user.
  Future<Result<List<Application>>> getApplicationsByUserId(String userId);

  /// Approve an application. Sets status to [ReviewStatus.approved].
  Future<Result<void>> approveApplication({
    required String applicationId,
    required String reviewerId,
  });

  /// Reject an application with a reason. Sets status to [ReviewStatus.rejected].
  Future<Result<void>> rejectApplication({
    required String applicationId,
    required String reviewerId,
    required String reason,
  });

  /// Approve a single section of a vendor application.
  Future<Result<void>> approveSection({
    required String applicationId,
    required String sectionKey,
    required String reviewerId,
  });

  /// Reject a single section of a vendor application with a reason.
  Future<Result<void>> rejectSection({
    required String applicationId,
    required String sectionKey,
    required String reviewerId,
    required String reason,
  });

  Future<Result<void>> updateApplicationSection({
    required String applicationId,
    required String sectionKey,
    required Map<String, dynamic> sectionData,
  });

  /// Update the application's document URLs and reset their status to pending.
  /// Used by applicants editing their profile documents after submission.
  Future<Result<void>> updateApplicationDocuments({
    required String applicationId,
    required List<String> documentUrls,
  });
}
