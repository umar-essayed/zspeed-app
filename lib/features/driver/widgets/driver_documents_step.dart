import 'package:z_speed/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:z_speed/features/driver/widgets/driver_form_styles.dart';
import 'package:z_speed/features/driver/widgets/driver_form_widgets.dart';

/// Step 3: Document Uploads
///
/// Requires: National ID, Driver's License, Vehicle Registration, Vehicle Insurance.
/// Each document is picked as an image/PDF and stored as a [File] reference.
class DriverDocumentsStep extends StatelessWidget {
  /// Map of document label → picked file (null if not yet picked).
  final Map<String, XFile?> documents;

  final Map<String, String> uploadStatuses;

  /// Called when the user taps a document slot to pick a file.
  final void Function(String documentLabel) onPickDocument;

  final GlobalKey<FormState> formKey;

  const DriverDocumentsStep({
    super.key,
    required this.documents,
    required this.uploadStatuses,
    required this.onPickDocument,
    required this.formKey,
  });

  List<_DocumentSpec> _getSpecs(BuildContext context) => [
        _DocumentSpec(
          label: 'National ID',
          localizedLabel: AppLocalizations.of(context)!.nationalId,
          description: AppLocalizations.of(context)!.nationalIdDesc,
          icon: Icons.badge_outlined,
        ),
        _DocumentSpec(
          label: 'Driver\'s License',
          localizedLabel: AppLocalizations.of(context)!.driversLicense,
          description: AppLocalizations.of(context)!.driversLicenseDesc,
          icon: Icons.card_membership_outlined,
        ),
        _DocumentSpec(
          label: 'Vehicle Registration',
          localizedLabel: AppLocalizations.of(context)!.vehicleRegistration,
          description: AppLocalizations.of(context)!.vehicleRegistrationDesc,
          icon: Icons.description_outlined,
        ),
        _DocumentSpec(
          label: 'Vehicle Insurance',
          localizedLabel: AppLocalizations.of(context)!.vehicleInsurance,
          description: AppLocalizations.of(context)!.vehicleInsuranceDesc,
          icon: Icons.security_outlined,
        ),
        _DocumentSpec(
          label: 'Police Clearance',
          localizedLabel: AppLocalizations.of(context)!.policeClearance,
          description: AppLocalizations.of(context)!.policeClearanceDesc,
          icon: Icons.policy_outlined,
        ),
        _DocumentSpec(
          label: 'Face Photo',
          localizedLabel: AppLocalizations.of(context)!.facePhoto,
          description: AppLocalizations.of(context)!.facePhotoDesc,
          icon: Icons.face_outlined,
        ),
        _DocumentSpec(
          label: 'Vehicle Photo',
          localizedLabel: AppLocalizations.of(context)!.vehiclePhoto,
          description: AppLocalizations.of(context)!.vehiclePhotoDesc,
          icon: Icons.directions_car_outlined,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(DriverFormStyles.horizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DriverFormSectionHeader(
              title: AppLocalizations.of(context)!.requiredDocuments,
              subtitle: AppLocalizations.of(context)!.uploadClearPhotos,
              icon: Icons.folder_outlined,
            ),
            ..._getSpecs(context).map((spec) {
              final file = documents[spec.label];
              final statusString = uploadStatuses[spec.label];
              final isUploading = statusString == 'uploading';
              final isDone = statusString == 'done';
              final hasError = statusString == 'error';

              return Padding(
                padding: const EdgeInsetsDirectional.only(
                    bottom: DriverFormStyles.verticalSpacing),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Label row
                    Row(
                      children: [
                        Icon(spec.icon,
                            size: 18, color: DriverFormStyles.primaryColor),
                        const SizedBox(width: 6),
                        Text(
                          spec.localizedLabel,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(AppLocalizations.of(context)!.symbolKey,
                            style:
                                TextStyle(color: DriverFormStyles.errorColor)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(spec.description,
                        style: DriverFormStyles.sectionSubtitle),
                    const SizedBox(height: 8),
                    DriverUploadArea(
                      label: AppLocalizations.of(context)!.tapToUploadDoc(spec.localizedLabel),
                      fileName: file != null
                          ? (file.name.isNotEmpty
                              ? file.name
                              : file.path.split('/').last)
                          : isDone
                              ? AppLocalizations.of(context)!.uploaded
                              : null,
                      isUploading: isUploading,
                      progress: null, // Basic string implementation has no progress
                      hasError: hasError,
                      onTap: () => onPickDocument(spec.label),
                    ),
                    if (hasError)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(top: 4),
                        child: Text(
                          AppLocalizations.of(context)!.uploadFailed,
                          style: TextStyle(
                            color: DriverFormStyles.errorColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── Internal helpers ─────────────────────────────────────────────────────────

class _DocumentSpec {
  final String label;
  final String localizedLabel;
  final String description;
  final IconData icon;

  const _DocumentSpec({
    required this.label,
    required this.localizedLabel,
    required this.description,
    required this.icon,
  });
}

/// Lightweight upload status for each document slot.
class DriverUploadStatus {
  final bool isUploading;
  final double? progress;
  final bool hasError;
  final String? errorMessage;
  final String? resultUrl;

  DriverUploadStatus({
    this.isUploading = false,
    this.progress,
    this.hasError = false,
    this.errorMessage,
    this.resultUrl,
  });

  DriverUploadStatus copyWith({
    bool? isUploading,
    double? progress,
    bool? hasError,
    String? errorMessage,
    String? resultUrl,
  }) {
    return DriverUploadStatus(
      isUploading: isUploading ?? this.isUploading,
      progress: progress ?? this.progress,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
      resultUrl: resultUrl ?? this.resultUrl,
    );
  }
}
