import 'package:z_speed/core/utils/phone_helper.dart';
import 'package:z_speed/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import 'package:z_speed/core/enums/user_enums.dart';
import 'package:z_speed/features/restaurant_owner/widgets/restaurant_form_styles.dart';
import 'package:z_speed/features/restaurant_owner/widgets/restaurant_form_widgets.dart';
import 'package:z_speed/features/restaurant/model/cuisine_type.dart';

/// Step 1: Business Information
///
/// Collects: restaurant name, description, owner name, cuisines (multi-select),
/// and restaurant phone (customer-facing).
class BusinessInfoStep extends StatelessWidget {
  final TextEditingController restaurantNameController;
  final TextEditingController descriptionController;
  final TextEditingController ownerNameController;
  final TextEditingController? restaurantPhoneController;
  final List<String> selectedCuisines;
  final List<CuisineType> availableCuisines;
  final bool isLoadingCuisines;
  final void Function(String cuisine) onToggleCuisine;
  final GlobalKey<FormState> formKey;
  final VendorType vendorType;

  const BusinessInfoStep({
    super.key,
    required this.restaurantNameController,
    required this.descriptionController,
    required this.ownerNameController,
    this.restaurantPhoneController,
    required this.selectedCuisines,
    required this.availableCuisines,
    required this.isLoadingCuisines,
    required this.onToggleCuisine,
    required this.formKey,
    this.vendorType = VendorType.restaurant,
  });

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
              title: AppLocalizations.of(context)!.businessInfo,
              subtitle: AppLocalizations.of(context)!.provideBusinessDetails,
              icon: switch (vendorType) {
                VendorType.supermarket => Icons.shopping_cart_outlined,
                VendorType.pharmacy => Icons.local_pharmacy_outlined,
                VendorType.bookstore => Icons.menu_book_outlined,
                VendorType.homeFurnishing => Icons.chair_outlined,
                VendorType.meatAndProteins => Icons.restaurant_menu_outlined,
                VendorType.clothes => Icons.checkroom_outlined,
                VendorType.buyAndSell => Icons.swap_horiz_outlined,
                VendorType.electronics => Icons.devices_outlined,
                _ => Icons.restaurant_outlined,
              },
            ),

            // Vendor Name
            TextFormField(
              controller: restaurantNameController,
              decoration: RestaurantFormStyles.inputDecoration(
                label: AppLocalizations.of(context)!.vendorNameLabel(vendorType.getLocalizedLabel(AppLocalizations.of(context)!)),
                hint: AppLocalizations.of(context)!.vendorNameHint(vendorType.getLocalizedLabel(AppLocalizations.of(context)!)),
                prefixIcon: Icons.storefront_outlined,
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? AppLocalizations.of(context)!.vendorNameRequired(vendorType.getLocalizedLabel(AppLocalizations.of(context)!))
                  : null,
            ),
            const SizedBox(height: RestaurantFormStyles.verticalSpacing),

            // Vendor Phone (customer-facing)
            if (restaurantPhoneController != null) ...[
              TextFormField(
                controller: restaurantPhoneController,
                decoration: RestaurantFormStyles.inputDecoration(
                  label: AppLocalizations.of(context)!.vendorPhoneLabel(vendorType.getLocalizedLabel(AppLocalizations.of(context)!)),
                  hint: AppLocalizations.of(context)!.vendorPhoneHint(vendorType.getLocalizedLabel(AppLocalizations.of(context)!)),
                  prefixIcon: Icons.store_outlined,
                ),
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return AppLocalizations.of(context)!.vendorPhoneRequired(vendorType.getLocalizedLabel(AppLocalizations.of(context)!));
                  }
                  final normalized = PhoneHelper.normalizePhone(v);
                  if (!PhoneHelper.isValidEgyptianPhone(normalized)) {
                    return AppLocalizations.of(context)!.enterValidPhoneNumber;
                  }
                  return null;
                },
              ),
              const SizedBox(height: RestaurantFormStyles.verticalSpacing),
            ],

            // Description
            TextFormField(
              controller: descriptionController,
              decoration: RestaurantFormStyles.inputDecoration(
                label: AppLocalizations.of(context)!.description,
                hint: AppLocalizations.of(context)!.enterDescription,
                prefixIcon: Icons.description_outlined,
              ),
              maxLines: 3,
              maxLength: 300,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? AppLocalizations.of(context)!.fieldIsRequired(AppLocalizations.of(context)!.description)
                  : null,
            ),
            const SizedBox(height: RestaurantFormStyles.verticalSpacing),

            // Owner Name
            TextFormField(
              controller: ownerNameController,
              decoration: RestaurantFormStyles.inputDecoration(
                label: AppLocalizations.of(context)!.ownerFullName,
                hint: AppLocalizations.of(context)!.enterOwnerName,
                prefixIcon: Icons.person_outline,
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? AppLocalizations.of(context)!.fieldIsRequired(AppLocalizations.of(context)!.ownerFullName)
                  : null,
            ),
            const SizedBox(height: RestaurantFormStyles.sectionSpacing),

            // Cuisine Selection — only for restaurants
            if (vendorType == VendorType.restaurant) ...[
              Text(AppLocalizations.of(context)!.cuisineTypes, style: RestaurantFormStyles.sectionTitle),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context)!.selectCuisinesPrompt,
                style: RestaurantFormStyles.sectionSubtitle,
              ),
              const SizedBox(height: 12),
              if (isLoadingCuisines)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (availableCuisines.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    AppLocalizations.of(context)!.noCuisinesAvailable,
                    style: RestaurantFormStyles.sectionSubtitle,
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: availableCuisines.map((cuisine) {
                    final cuisineName = cuisine.name;
                    final isSelected = selectedCuisines.contains(cuisineName);
                    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
                    final displayName = isArabic ? cuisine.nameAr : cuisineName;

                    return FilterChip(
                      label: Text(displayName),
                      selected: isSelected,
                      onSelected: (_) => onToggleCuisine(cuisineName),
                      selectedColor:
                          RestaurantFormStyles.primaryColor.withValues(alpha: 0.15),
                      checkmarkColor: RestaurantFormStyles.primaryColor,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? RestaurantFormStyles.primaryColor
                            : RestaurantFormStyles.labelColor,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      backgroundColor: RestaurantFormStyles.chipUnselected,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected
                              ? RestaurantFormStyles.primaryColor
                              : RestaurantFormStyles.borderColor,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              if (!isLoadingCuisines && selectedCuisines.isEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.selectAtLeastOneCuisine,
                  style: TextStyle(
                    color: RestaurantFormStyles.errorColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

}
