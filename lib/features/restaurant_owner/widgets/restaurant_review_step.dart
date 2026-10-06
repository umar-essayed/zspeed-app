import 'package:z_speed/l10n/app_localizations.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:z_speed/core/enums/user_enums.dart';
import 'package:z_speed/features/restaurant_owner/widgets/restaurant_form_styles.dart';
import 'package:z_speed/features/restaurant_owner/widgets/restaurant_form_widgets.dart';
import 'package:z_speed/features/restaurant/model/cuisine_type.dart';

/// Step 6: Review & Confirm
///
/// Displays a read-only summary of all entered data before submission.
class RestaurantReviewStep extends StatelessWidget {
  // ── Business Info ──
  final String restaurantName;
  final String description;
  final String ownerName;
  final String restaurantPhone;
  final List<String> selectedCuisines;
  final List<CuisineType> availableCuisines;

  // ── Location Info ──
  final String address;
  final String city;
  final Map<String, Map<String, dynamic>> operatingHours;

  // ── Contact Info (Account Setup) ──
  final String ownerEmail;
  final String ownerPhone;

  // ── Bank Info ──
  final String bankName;
  final String accountHolder;
  final String iban;

  // ── Assets ──
  final Map<String, XFile?> documents;
  final XFile? logoImage;
  final XFile? coverImage;

  final VendorType vendorType;

  /// Called when user taps "Edit" on a section.
  final void Function(int stepIndex) onEditStep;

  const RestaurantReviewStep({
    super.key,
    this.vendorType = VendorType.restaurant,
    required this.restaurantName,
    required this.description,
    required this.ownerName,
    required this.restaurantPhone,
    required this.selectedCuisines,
    required this.availableCuisines,
    required this.address,
    required this.city,
    required this.operatingHours,
    required this.ownerEmail,
    required this.ownerPhone,
    required this.bankName,
    required this.accountHolder,
    required this.iban,
    required this.documents,
    required this.logoImage,
    required this.coverImage,
    required this.onEditStep,
  });

  String _formatOperatingHours(
    BuildContext context,
    Map<String, Map<String, dynamic>> hours,
  ) {
    if (hours.isEmpty) return AppLocalizations.of(context)!.notConfigured;
    final lines = <String>[];
    final l10n = AppLocalizations.of(context)!;
    // final days = [
    //   l10n.monday,
    //   l10n.tuesday,
    //   l10n.wednesday,
    //   l10n.thursday,
    //   l10n.friday,
    //   l10n.saturday,
    //   l10n.sunday
    // ];

    // Mapping for internal keys to localized display names
    final dayKeyMap = {
      'Monday': l10n.monday,
      'Tuesday': l10n.tuesday,
      'Wednesday': l10n.wednesday,
      'Thursday': l10n.thursday,
      'Friday': l10n.friday,
      'Saturday': l10n.saturday,
      'Sunday': l10n.sunday,
    };

    for (var entry in dayKeyMap.entries) {
      final dayData = hours[entry.key];
      if (dayData != null && dayData['closed'] != true) {
        final open = dayData['open'];
        final close = dayData['close'];
        final openStr = open is TimeOfDay
            ? '${open.hour.toString().padLeft(2, '0')}:${open.minute.toString().padLeft(2, '0')}'
            : open?.toString() ?? '';
        final closeStr = close is TimeOfDay
            ? '${close.hour.toString().padLeft(2, '0')}:${close.minute.toString().padLeft(2, '0')}'
            : close?.toString() ?? '';
        lines.add('${entry.value}: $openStr - $closeStr');
      } else {
        lines.add('${entry.value}: ${l10n.closed}');
      }
    }
    return lines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final formattedCuisines = selectedCuisines.map((selectedName) {
      try {
        final cuisine = availableCuisines.firstWhere(
          (c) => c.name == selectedName,
        );
        return isArabic ? cuisine.nameAr : cuisine.name;
      } catch (_) {
        return selectedName;
      }
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(RestaurantFormStyles.horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RestaurantFormSectionHeader(
            title: AppLocalizations.of(context)!.reviewYourApplication,
            subtitle: AppLocalizations.of(context)!.reviewInstructions,
            icon: Icons.fact_check_outlined,
          ),

          // Business Info
          _ReviewSection(
            title: AppLocalizations.of(context)!.businessInformation,
            stepIndex: 1,
            onEdit: onEditStep,
            entries: {
              AppLocalizations.of(context)!.vendorNameLabel(vendorType.getLocalizedLabel(AppLocalizations.of(context)!)):
                  restaurantName,
              AppLocalizations.of(context)!.description: description,
              AppLocalizations.of(context)!.ownerFullName: ownerName,
              AppLocalizations.of(context)!.vendorPhoneLabel(vendorType.getLocalizedLabel(AppLocalizations.of(context)!)):
                  restaurantPhone,
              if (vendorType == VendorType.restaurant)
                AppLocalizations.of(
                  context,
                )!.cuisineTypes: formattedCuisines.isEmpty
                    ? '—'
                    : formattedCuisines.join(', '),
            },
          ),
          const SizedBox(height: RestaurantFormStyles.verticalSpacing),

          // Account/Contact Info
          _ReviewSection(
            title: AppLocalizations.of(context)!.accountAndContact,
            stepIndex: 0,
            onEdit: onEditStep,
            entries: {
              AppLocalizations.of(context)!.emailAddress: ownerEmail,
              AppLocalizations.of(context)!.phoneNumberLabel: ownerPhone,
            },
          ),
          const SizedBox(height: RestaurantFormStyles.verticalSpacing),

          // Location Info
          _ReviewSection(
            title: AppLocalizations.of(context)!.locationAndHoursStep,
            stepIndex: 2,
            onEdit: onEditStep,
            entries: {
              AppLocalizations.of(context)!.fullAddress: address,
              AppLocalizations.of(context)!.city: city,
              AppLocalizations.of(context)!.operatingHours:
                  _formatOperatingHours(context, operatingHours),
            },
          ),
          const SizedBox(height: RestaurantFormStyles.verticalSpacing),

          // Bank Info
          _ReviewSection(
            title: AppLocalizations.of(context)!.bankAccountDetails,
            stepIndex: 5,
            onEdit: onEditStep,
            entries: {
              AppLocalizations.of(context)!.bankName: bankName,
              AppLocalizations.of(context)!.accountHolderName: accountHolder,
              AppLocalizations.of(context)!.iban: iban,
            },
          ),
          const SizedBox(height: RestaurantFormStyles.verticalSpacing),

          // Documents
          _ReviewSection(
            title: AppLocalizations.of(context)!.businessDocuments,
            stepIndex: 3,
            onEdit: onEditStep,
            entries: {
              for (final entry in documents.entries)
                _getLocalizedDocLabel(context, entry.key):
                    entry.value ?? '✗ فشل الربط اصلا',
            },
          ),
          const SizedBox(height: RestaurantFormStyles.verticalSpacing),

          // Branding Images
          _ReviewSection(
            title: AppLocalizations.of(
              context,
            )!.vendorBrandingTitle(vendorType.getLocalizedLabel(AppLocalizations.of(context)!)),
            stepIndex: 4,
            onEdit: onEditStep,
            entries: {
              AppLocalizations.of(context)!.vendorLogoLabel(vendorType.getLocalizedLabel(AppLocalizations.of(context)!)):
                  logoImage ?? '✗ ${AppLocalizations.of(context)!.notUploaded}',
              AppLocalizations.of(context)!.coverImage:
                  coverImage ??
                  '✗ ${AppLocalizations.of(context)!.notUploaded}',
            },
          ),
          const SizedBox(height: RestaurantFormStyles.sectionSpacing),

          // Disclaimer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: RestaurantFormStyles.uploadBg,
              borderRadius: BorderRadius.circular(
                RestaurantFormStyles.inputRadius,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: RestaurantFormStyles.primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.reviewDisclaimer,
                    style: TextStyle(
                      fontSize: 13,
                      color: RestaurantFormStyles.labelColor,
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
}

// ── Review Section Card ──────────────────────────────────────────────────────

class _ReviewSection extends StatelessWidget {
  final String title;
  final int stepIndex;
  final void Function(int) onEdit;
  final Map<String, dynamic> entries;

  const _ReviewSection({
    required this.title,
    required this.stepIndex,
    required this.onEdit,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: RestaurantFormStyles.cardDecoration,
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
                    foregroundColor: RestaurantFormStyles.primaryColor,
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
                final isMissing =
                    (e.value is String && (e.value as String).isEmpty) ||
                    (e.value is String && (e.value as String).startsWith('✗'));
                Widget valueWidget;
                if (e.value is XFile) {
                  final file = e.value as XFile;
                  final fileName = file.name.isNotEmpty
                      ? file.name
                      : file.path.split('/').last;
                  valueWidget = Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: kIsWeb
                            ? Image.network(
                                file.path,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const Icon(
                                  Icons.insert_drive_file,
                                  size: 50,
                                ),
                              )
                            : Image.file(
                                File(file.path),
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const Icon(
                                  Icons.insert_drive_file,
                                  size: 50,
                                ),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '✓ $fileName',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF212121),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              file.path,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                } else {
                  final strVal = e.value as String;
                  valueWidget = Text(
                    strVal.isEmpty ? '—' : strVal,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isMissing
                          ? RestaurantFormStyles.errorColor
                          : const Color(0xFF212121),
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(
                          e.key,
                          style: TextStyle(
                            fontSize: 13,
                            color: RestaurantFormStyles.labelColor,
                          ),
                        ),
                      ),
                      Expanded(child: valueWidget),
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
