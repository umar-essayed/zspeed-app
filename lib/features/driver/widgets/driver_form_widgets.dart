import 'package:flutter/material.dart';
import 'package:z_speed/l10n/app_localizations.dart';

import 'package:z_speed/features/driver/widgets/driver_form_styles.dart';

// ── Step Progress Indicator ──────────────────────────────────────────────────

/// Horizontal progress bar showing current step out of total.
class DriverStepProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> stepLabels;

  const DriverStepProgressBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.stepLabels,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step label
        Text(
          AppLocalizations.of(context)!.stepOfTotal(currentStep + 1, totalSteps, stepLabels[currentStep]),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: DriverFormStyles.labelColor,
          ),
        ),
        const SizedBox(height: 8),
        // Progress track
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (currentStep + 1) / totalSteps,
            minHeight: 6,
            backgroundColor: DriverFormStyles.borderColor,
            valueColor: AlwaysStoppedAnimation<Color>(
                DriverFormStyles.primaryColor),
          ),
        ),
      ],
    );
  }
}

// ── Navigation Buttons ───────────────────────────────────────────────────────

/// Bottom bar with Back / Next / Submit buttons for form steps.
class DriverFormNavigationButtons extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final bool isSubmitting;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final VoidCallback? onSubmit;

  const DriverFormNavigationButtons({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.isSubmitting = false,
    this.onBack,
    this.onNext,
    this.onSubmit,
  });

  bool get _isFirstStep => currentStep == 0;
  bool get _isLastStep => currentStep == totalSteps - 1;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DriverFormStyles.horizontalPadding,
        vertical: 12,
      ),
      child: Row(
        children: [
          // Back button
          if (!_isFirstStep)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isSubmitting ? null : onBack,
                icon: const Icon(Icons.arrow_back_ios, size: 16),
                label: Text(AppLocalizations.of(context)!.back),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: DriverFormStyles.borderColor),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(DriverFormStyles.inputRadius),
                  ),
                ),
              ),
            ),
          if (!_isFirstStep) const SizedBox(width: 12),
          // Next / Submit button
          Expanded(
            child: _isLastStep
                ? FilledButton.icon(
                    onPressed: isSubmitting ? null : onSubmit,
                    icon: isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send, size: 18),
                    label: Text(isSubmitting ? AppLocalizations.of(context)!.submitting : AppLocalizations.of(context)!.submit),
                    style: FilledButton.styleFrom(
                      backgroundColor: DriverFormStyles.successColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(DriverFormStyles.inputRadius),
                      ),
                    ),
                  )
                : FilledButton.icon(
                    onPressed: onNext,
                    icon: const Text(''),
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(AppLocalizations.of(context)!.next),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: DriverFormStyles.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(DriverFormStyles.inputRadius),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Section Header Widget ────────────────────────────────────────────────────

/// Displays a title and optional subtitle at the top of each step.
class DriverFormSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;

  const DriverFormSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: DriverFormStyles.primaryColor, size: 24),
              const SizedBox(width: 8),
            ],
            Text(title, style: DriverFormStyles.sectionTitle),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle!, style: DriverFormStyles.sectionSubtitle),
        ],
        const SizedBox(height: DriverFormStyles.verticalSpacing),
      ],
    );
  }
}

// ── Upload Placeholder ───────────────────────────────────────────────────────

/// A tappable upload area with icon, label, and optional file name.
class DriverUploadArea extends StatelessWidget {
  final String label;
  final String? fileName;
  final bool isUploading;
  final double? progress;
  final bool hasError;
  final VoidCallback? onTap;

  const DriverUploadArea({
    super.key,
    required this.label,
    this.fileName,
    this.isUploading = false,
    this.progress,
    this.hasError = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasFile = fileName != null && fileName!.isNotEmpty;

    return GestureDetector(
      onTap: isUploading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: hasError
              ? DriverFormStyles.errorColor.withValues(alpha: 0.05)
              : DriverFormStyles.uploadBg,
          borderRadius: BorderRadius.circular(DriverFormStyles.inputRadius),
          border: Border.all(
            color: hasError
                ? DriverFormStyles.errorColor
                : hasFile
                    ? DriverFormStyles.successColor
                    : DriverFormStyles.borderColor,
            width: hasError || hasFile ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              hasFile ? Icons.check_circle : Icons.cloud_upload_outlined,
              color: hasFile
                  ? DriverFormStyles.successColor
                  : DriverFormStyles.primaryColor,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              hasFile ? fileName! : label,
              style: TextStyle(
                fontSize: 13,
                color: hasFile
                    ? DriverFormStyles.successColor
                    : DriverFormStyles.labelColor,
                fontWeight: hasFile ? FontWeight.w500 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (isUploading && progress != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: DriverFormStyles.borderColor,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      DriverFormStyles.primaryColor),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
