import 'package:z_speed/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import 'package:z_speed/features/restaurant_owner/widgets/restaurant_form_styles.dart';

// ── Step Progress Indicator ──────────────────────────────────────────────────

/// Horizontal progress bar showing current step out of total for vendor form.
class RestaurantStepProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> stepLabels;

  const RestaurantStepProgressBar({
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
        Text(
          AppLocalizations.of(context)!.stepProgress(currentStep + 1, totalSteps, stepLabels[currentStep]),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: RestaurantFormStyles.labelColor,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (currentStep + 1) / totalSteps,
            minHeight: 6,
            backgroundColor: RestaurantFormStyles.borderColor,
            valueColor: AlwaysStoppedAnimation<Color>(
                RestaurantFormStyles.primaryColor),
          ),
        ),
      ],
    );
  }
}

// ── Navigation Buttons ───────────────────────────────────────────────────────

class RestaurantFormNavigationButtons extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final bool isSubmitting;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final VoidCallback? onSubmit;

  const RestaurantFormNavigationButtons({
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
        horizontal: RestaurantFormStyles.horizontalPadding,
        vertical: 12,
      ),
      child: Row(
        children: [
          if (!_isFirstStep)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isSubmitting ? null : onBack,
                icon: const Icon(Icons.arrow_back_ios, size: 16),
                label: Text(AppLocalizations.of(context)!.back),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side:
                      BorderSide(color: RestaurantFormStyles.borderColor),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(RestaurantFormStyles.inputRadius),
                  ),
                ),
              ),
            ),
          if (!_isFirstStep) const SizedBox(width: 12),
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
                      backgroundColor: RestaurantFormStyles.successColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            RestaurantFormStyles.inputRadius),
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
                      backgroundColor: RestaurantFormStyles.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            RestaurantFormStyles.inputRadius),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Section Header ───────────────────────────────────────────────────────────

class RestaurantFormSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;

  const RestaurantFormSectionHeader({
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
              Icon(icon, color: RestaurantFormStyles.primaryColor, size: 24),
              const SizedBox(width: 8),
            ],
            Expanded(
                child: Text(title, style: RestaurantFormStyles.sectionTitle)),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle!, style: RestaurantFormStyles.sectionSubtitle),
        ],
        const SizedBox(height: RestaurantFormStyles.verticalSpacing),
      ],
    );
  }
}

// ── Upload Area ──────────────────────────────────────────────────────────────

class RestaurantUploadArea extends StatelessWidget {
  final String label;
  final String? fileName;
  final bool isUploading;
  final double? progress;
  final bool hasError;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const RestaurantUploadArea({
    super.key,
    required this.label,
    this.fileName,
    this.isUploading = false,
    this.progress,
    this.hasError = false,
    this.onTap,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final hasFile = fileName != null && fileName!.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isUploading ? null : onTap,
        borderRadius: BorderRadius.circular(RestaurantFormStyles.inputRadius),
        child: Ink(
          width: width,
          height: height,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: hasError
                ? RestaurantFormStyles.errorColor.withValues(alpha: 0.05)
                : RestaurantFormStyles.uploadBg,
            borderRadius: BorderRadius.circular(RestaurantFormStyles.inputRadius),
            border: Border.all(
              color: hasError
                  ? RestaurantFormStyles.errorColor
                  : hasFile
                      ? RestaurantFormStyles.successColor
                      : RestaurantFormStyles.borderColor,
              width: hasError || hasFile ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                hasFile ? Icons.check_circle : Icons.cloud_upload_outlined,
                color: hasFile
                    ? RestaurantFormStyles.successColor
                    : RestaurantFormStyles.primaryColor,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                hasFile ? fileName! : label,
                style: TextStyle(
                  fontSize: 13,
                  color: hasFile
                      ? RestaurantFormStyles.successColor
                      : RestaurantFormStyles.labelColor,
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
                    backgroundColor: RestaurantFormStyles.borderColor,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        RestaurantFormStyles.primaryColor),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
