import 'package:z_speed/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:z_speed/features/restaurant_owner/widgets/restaurant_form_styles.dart';
import 'package:z_speed/features/restaurant_owner/widgets/restaurant_form_widgets.dart';

/// Lightweight upload status for each vendor document slot.
class RestaurantUploadStatus {
  final bool isUploading;
  final double? progress;
  final bool hasError;
  final String? errorMessage;
  final String? resultUrl;

  RestaurantUploadStatus({
    this.isUploading = false,
    this.progress,
    this.hasError = false,
    this.errorMessage,
    this.resultUrl,
  });

  RestaurantUploadStatus copyWith({
    bool? isUploading,
    double? progress,
    bool? hasError,
    String? errorMessage,
    String? resultUrl,
  }) {
    return RestaurantUploadStatus(
      isUploading: isUploading ?? this.isUploading,
      progress: progress ?? this.progress,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
      resultUrl: resultUrl ?? this.resultUrl,
    );
  }
}

/// Step 4: Business Documents
///
/// Requires: commercial registration, business license, health certificate,
/// tax registration.
class DocumentsStep extends StatelessWidget {
  final Map<String, XFile?> documents;
  final Map<String, RestaurantUploadStatus> uploadStatuses;
  final void Function(String documentLabel) onPickDocument;
  final GlobalKey<FormState> formKey;

  const DocumentsStep({
    super.key,
    required this.documents,
    required this.uploadStatuses,
    required this.onPickDocument,
    required this.formKey,
  });

  static const _specs = [
    'commercialRegistration',
    'businessLicense',
    'healthCertificate',
    'taxRegistration',
  ];

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(RestaurantFormStyles.horizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RestaurantFormSectionHeader(
              title: AppLocalizations.of(context)!.businessDocuments,
              subtitle: AppLocalizations.of(context)!.provideBusinessDocs,
              icon: Icons.description_outlined,
            ),
            ..._specs.map((key) {
              final file = documents[key];
              final status = uploadStatuses[key];
              final localizedLabel = _getLocalizedDocLabel(context, key);
              final localizedDesc = _getLocalizedDocDesc(context, key);
              final icon = _getDocIcon(key);

              return Padding(
                padding: const EdgeInsetsDirectional.only(
                    bottom: RestaurantFormStyles.verticalSpacing),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon,
                            size: 18, color: RestaurantFormStyles.primaryColor),
                        const SizedBox(width: 6),
                        Text(
                          localizedLabel,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(AppLocalizations.of(context)!.symbolKey,
                            style: TextStyle(
                                color: RestaurantFormStyles.errorColor)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(localizedDesc,
                        style: RestaurantFormStyles.sectionSubtitle),
                    const SizedBox(height: 8),
                    RestaurantUploadArea(
                      label: AppLocalizations.of(context)!.tapToUploadDoc(localizedLabel),
                      fileName: file != null
                          ? (file.name.isNotEmpty
                              ? file.name
                              : file.path.split('/').last)
                          : status?.resultUrl != null
                              ? AppLocalizations.of(context)!.uploaded
                              : null,
                      isUploading: status?.isUploading ?? false,
                      progress: status?.progress,
                      hasError: status?.hasError ?? false,
                      onTap: () => onPickDocument(key),
                    ),
                    if (status?.hasError == true &&
                        status?.errorMessage != null)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(top: 4),
                        child: Text(
                          status!.errorMessage!,
                          style: TextStyle(
                            color: RestaurantFormStyles.errorColor,
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

  String _getLocalizedDocLabel(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context)!;
    switch (key) {
      case 'commercialRegistration':
        return l10n.commercialRegistration;
      case 'businessLicense':
        return l10n.businessLicense;
      case 'healthCertificate':
        return l10n.healthCertificate;
      case 'taxRegistration':
        return l10n.taxRegistration;
      default:
        return key;
    }
  }

  String _getLocalizedDocDesc(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context)!;
    switch (key) {
      case 'commercialRegistration':
        return l10n.commercialRegistrationDesc;
      case 'businessLicense':
        return l10n.businessLicenseDesc;
      case 'healthCertificate':
        return l10n.healthCertificateDesc;
      case 'taxRegistration':
        return l10n.taxRegistrationDesc;
      default:
        return '';
    }
  }

  IconData _getDocIcon(String key) {
    switch (key) {
      case 'commercialRegistration':
        return Icons.business_outlined;
      case 'businessLicense':
        return Icons.verified_outlined;
      case 'healthCertificate':
        return Icons.health_and_safety_outlined;
      case 'taxRegistration':
        return Icons.receipt_long_outlined;
      default:
        return Icons.description_outlined;
    }
  }
}
