import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:z_speed/l10n/app_localizations.dart';

import 'package:z_speed/features/driver/widgets/driver_form_styles.dart';
import 'package:z_speed/features/driver/widgets/driver_form_widgets.dart';

/// Step 4: Review & Confirm
///
/// Displays a read-only summary of all entered data before final submission.
/// Shows ALL required documents with clear ✓ / ✗ status.
/// Edit buttons navigate to the correct step index.
class DriverReviewStep extends StatelessWidget {
  // ── Personal Info ──────────────────────────────────────────────────────────
  final String name;
  final String email;
  final String phone;
  final String city;
  final String dob;
  final String nationalId;

  // ── Vehicle Info ───────────────────────────────────────────────────────────
  final String vehicleType;
  final String vehicleMake;
  final String vehicleModel;
  final String vehicleYear;
  final String vehicleColor;
  final String plateNumber;

  // ── Documents ──────────────────────────────────────────────────────────────
  /// Picked documents from cubit state (only contains successfully picked files).
  final Map<String, XFile> documents;

  /// All labels that are required — used to show missing-doc slots.
  final List<String> requiredDocumentLabels;

  /// Called when user taps "Edit" on a section — passes the correct step index.
  final void Function(int stepIndex) onEditStep;

  const DriverReviewStep({
    super.key,
    required this.name,
    required this.email,
    required this.phone,
    required this.city,
    required this.dob,
    required this.nationalId,
    required this.vehicleType,
    required this.vehicleMake,
    required this.vehicleModel,
    required this.vehicleYear,
    required this.vehicleColor,
    required this.plateNumber,
    required this.documents,
    required this.requiredDocumentLabels,
    required this.onEditStep,
  });

  @override
  Widget build(BuildContext context) {
    final missingCount = requiredDocumentLabels
        .where((l) => !documents.containsKey(l))
        .length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(DriverFormStyles.horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DriverFormSectionHeader(
            title: AppLocalizations.of(context)!.reviewYourApplication,
            subtitle: AppLocalizations.of(context)!.reviewSubtitle,
            icon: Icons.fact_check_outlined,
          ),

          // ── Missing docs warning ──────────────────────────────────────────
          if (missingCount > 0)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: DriverFormStyles.errorColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(
                  DriverFormStyles.inputRadius,
                ),
                border: Border.all(
                  color: DriverFormStyles.errorColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: DriverFormStyles.errorColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$missingCount required document(s) not yet selected. '
                      'Please go back and upload them.',
                      style: TextStyle(
                        fontSize: 12,
                        color: DriverFormStyles.errorColor,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── Personal Info — Edit goes to step 1 ──────────────────────────
          _ReviewSection(
            title: AppLocalizations.of(context)!.personalInformation,
            stepIndex: 1,
            onEdit: onEditStep,
            entries: {
              AppLocalizations.of(context)!.fullName: name,
              AppLocalizations.of(context)!.emailLabel: email,
              AppLocalizations.of(context)!.phone: phone,
              AppLocalizations.of(context)!.city: city,
              AppLocalizations.of(context)!.dateOfBirth: dob,
              AppLocalizations.of(context)!.nationalIdNumber: nationalId,
            },
          ),
          const SizedBox(height: DriverFormStyles.verticalSpacing),

          // ── Vehicle Info — Edit goes to step 2 ───────────────────────────
          _ReviewSection(
            title: AppLocalizations.of(context)!.vehicleInformation,
            stepIndex: 2,
            onEdit: onEditStep,
            entries: {
              AppLocalizations.of(context)!.typeLabel: vehicleType,
              AppLocalizations.of(context)!.make: vehicleMake,
              AppLocalizations.of(context)!.model: vehicleModel,
              AppLocalizations.of(context)!.year: vehicleYear,
              AppLocalizations.of(context)!.vehicleColor: vehicleColor,
              AppLocalizations.of(context)!.plateNumberLabel: plateNumber,
            },
          ),
          const SizedBox(height: DriverFormStyles.verticalSpacing),

          // ── Documents — Edit goes to step 3 ──────────────────────────────
          _DocumentsReviewSection(
            requiredLabels: requiredDocumentLabels,
            pickedDocuments: documents,
            missingCount: missingCount,
            onEdit: () => onEditStep(3),
          ),
          const SizedBox(height: DriverFormStyles.sectionSpacing),

          // ── Disclaimer ───────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DriverFormStyles.uploadBg,
              borderRadius: BorderRadius.circular(DriverFormStyles.inputRadius),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: DriverFormStyles.primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.applicationDisclaimer,
                    style: TextStyle(
                      fontSize: 13,
                      color: DriverFormStyles.labelColor,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Documents Review Section ──────────────────────────────────────────────────

class _DocumentsReviewSection extends StatelessWidget {
  final List<String> requiredLabels;
  final Map<String, XFile> pickedDocuments;
  final int missingCount;
  final VoidCallback onEdit;

  const _DocumentsReviewSection({
    required this.requiredLabels,
    required this.pickedDocuments,
    required this.missingCount,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: DriverFormStyles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.documents,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (missingCount > 0)
                        Text(
                          '$missingCount missing',
                          style: TextStyle(
                            fontSize: 11,
                            color: DriverFormStyles.errorColor,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      else
                        Text(
                          'All ${requiredLabels.length} documents selected',
                          style: TextStyle(
                            fontSize: 11,
                            color: DriverFormStyles.successColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: Text(
                    AppLocalizations.of(context)!.edit,
                    style: const TextStyle(fontSize: 13),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: DriverFormStyles.primaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Document rows — all required labels shown
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 12),
            child: Column(
              children: requiredLabels
                  .map(
                    (label) => _DocumentRow(
                      label: label,
                      file: pickedDocuments[label],
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Single Document Row ───────────────────────────────────────────────────────

class _DocumentRow extends StatelessWidget {
  final String label;
  final XFile? file;

  const _DocumentRow({required this.label, required this.file});

  @override
  Widget build(BuildContext context) {
    final isPicked = file != null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // ✓ / ✗ status circle
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isPicked
                  ? DriverFormStyles.successColor.withValues(alpha: 0.12)
                  : DriverFormStyles.errorColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPicked ? Icons.check_rounded : Icons.close_rounded,
              size: 15,
              color: isPicked
                  ? DriverFormStyles.successColor
                  : DriverFormStyles.errorColor,
            ),
          ),
          const SizedBox(width: 10),

          // Label + filename / missing text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isPicked
                        ? const Color(0xFF212121)
                        : DriverFormStyles.labelColor,
                  ),
                ),
                if (isPicked) ...[
                  const SizedBox(height: 1),
                  Text(
                    file!.path,
                    style: TextStyle(
                      fontSize: 11,
                      color: DriverFormStyles.labelColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ] else if (!isPicked) ...[
                  const SizedBox(height: 1),
                  Text(
                    'فشل الربط اصلا',
                    style: TextStyle(
                      fontSize: 11,
                      color: DriverFormStyles.errorColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Thumbnail preview (only for picked image files)
          if (isPicked) ...[
            const SizedBox(width: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: kIsWeb
                  ? Image.network(
                      file!.path,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _FilePlaceholder(),
                    )
                  : Image.file(
                      File(file!.path),
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _FilePlaceholder(),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      color: DriverFormStyles.borderColor,
      child: Icon(
        Icons.insert_drive_file_outlined,
        size: 22,
        color: DriverFormStyles.labelColor,
      ),
    );
  }
}

// ── Standard Review Section ───────────────────────────────────────────────────

class _ReviewSection extends StatelessWidget {
  final String title;
  final int stepIndex;
  final void Function(int) onEdit;
  final Map<String, String> entries;

  const _ReviewSection({
    required this.title,
    required this.stepIndex,
    required this.onEdit,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: DriverFormStyles.cardDecoration,
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => onEdit(stepIndex),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: Text(
                    AppLocalizations.of(context)!.edit,
                    style: const TextStyle(fontSize: 13),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: DriverFormStyles.primaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Entries
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 12),
            child: Column(
              children: entries.entries.map((e) {
                final isMissing = e.value.isEmpty;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(
                          e.key,
                          style: TextStyle(
                            fontSize: 13,
                            color: DriverFormStyles.labelColor,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          isMissing ? '—' : e.value,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isMissing
                                ? DriverFormStyles.errorColor
                                : const Color(0xFF212121),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
