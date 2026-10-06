import 'package:z_speed/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import 'package:z_speed/features/driver/widgets/driver_form_styles.dart';
import 'package:z_speed/features/driver/widgets/driver_form_widgets.dart';

/// Step 2: Personal Information (after Account Setup)
///
/// Collects: full name, city, date of birth.
/// Email, phone, and password are now in AccountSetupStep (step 0).
class DriverPersonalInfoStep extends StatefulWidget {
  final TextEditingController? nameController;
  final TextEditingController? cityController;
  final TextEditingController? dobController;
  final TextEditingController? nationalIdController;
  final TextEditingController? categoryController;
  final GlobalKey<FormState> formKey;

  const DriverPersonalInfoStep({
    super.key,
    this.nameController,
    this.cityController,
    this.dobController,
    this.nationalIdController,
    this.categoryController,
    required this.formKey,
  });

  @override
  State<DriverPersonalInfoStep> createState() => _DriverPersonalInfoStepState();
}

class _DriverPersonalInfoStepState extends State<DriverPersonalInfoStep> {
  TextEditingController? _localNameCtrl;
  TextEditingController? _localCityCtrl;
  TextEditingController? _localDobCtrl;
  TextEditingController? _localNationalIdCtrl;
  TextEditingController? _localCategoryCtrl;

  late final TextEditingController nameCtrl;
  late final TextEditingController cityCtrl;
  late final TextEditingController dobCtrl;
  late final TextEditingController nationalIdCtrl;
  late final TextEditingController categoryCtrl;

  @override
  void initState() {
    super.initState();
    if (widget.nameController == null) _localNameCtrl = TextEditingController();
    if (widget.cityController == null) _localCityCtrl = TextEditingController();
    if (widget.dobController == null) _localDobCtrl = TextEditingController();
    if (widget.nationalIdController == null) _localNationalIdCtrl = TextEditingController();
    if (widget.categoryController == null) _localCategoryCtrl = TextEditingController(text: 'delivery');

    nameCtrl = widget.nameController ?? _localNameCtrl!;
    cityCtrl = widget.cityController ?? _localCityCtrl!;
    dobCtrl = widget.dobController ?? _localDobCtrl!;
    nationalIdCtrl = widget.nationalIdController ?? _localNationalIdCtrl!;
    categoryCtrl = widget.categoryController ?? _localCategoryCtrl!;
  }

  @override
  void dispose() {
    _localNameCtrl?.dispose();
    _localCityCtrl?.dispose();
    _localDobCtrl?.dispose();
    _localNationalIdCtrl?.dispose();
    _localCategoryCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(DriverFormStyles.horizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DriverFormSectionHeader(
              title: AppLocalizations.of(context)!.driverPersonalInfo,
              subtitle: AppLocalizations.of(context)!.provideBasicDetails,
              icon: Icons.person_outline,
            ),

            // Specialty Selector Card Group
            Text(
              AppLocalizations.of(context)!.driverSpecialty,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: DriverFormStyles.labelColor,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      setState(() {
                        categoryCtrl.text = 'delivery';
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
                      decoration: BoxDecoration(
                        color: categoryCtrl.text == 'delivery'
                            ? DriverFormStyles.primaryColor.withValues(alpha: 0.1)
                            : Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: categoryCtrl.text == 'delivery'
                              ? DriverFormStyles.primaryColor
                              : Colors.grey[300]!,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.delivery_dining_outlined,
                            size: 28,
                            color: categoryCtrl.text == 'delivery'
                                ? DriverFormStyles.primaryColor
                                : Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(context)!.delivery,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: categoryCtrl.text == 'delivery'
                                  ? DriverFormStyles.primaryColor
                                  : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppLocalizations.of(context)!.foodAndPackages,
                            style: TextStyle(fontSize: 9, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      setState(() {
                        categoryCtrl.text = 'transport';
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
                      decoration: BoxDecoration(
                        color: categoryCtrl.text == 'transport'
                            ? DriverFormStyles.primaryColor.withValues(alpha: 0.1)
                            : Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: categoryCtrl.text == 'transport'
                              ? DriverFormStyles.primaryColor
                              : Colors.grey[300]!,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.local_taxi_outlined,
                            size: 28,
                            color: categoryCtrl.text == 'transport'
                                ? DriverFormStyles.primaryColor
                                : Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(context)!.transport,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: categoryCtrl.text == 'transport'
                                  ? DriverFormStyles.primaryColor
                                  : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppLocalizations.of(context)!.passengersRides,
                            style: TextStyle(fontSize: 9, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: DriverFormStyles.verticalSpacing),

            // Full Name
            TextFormField(
              controller: nameCtrl,
              decoration: DriverFormStyles.inputDecoration(
                label: AppLocalizations.of(context)!.fullName,
                hint: AppLocalizations.of(context)!.enterFullName,
                prefixIcon: Icons.badge_outlined,
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return AppLocalizations.of(context)!.fieldIsRequired(AppLocalizations.of(context)!.fullName);
                if (!RegExp(r'^[\u0600-\u06FFa-zA-Z\s]+$').hasMatch(v)) {
                  return AppLocalizations.of(context)!.nameAlphaOnly;
                }
                return null;
              },
            ),
            const SizedBox(height: DriverFormStyles.verticalSpacing),

            // National ID Number
            TextFormField(
              controller: nationalIdCtrl,
              decoration: DriverFormStyles.inputDecoration(
                label: AppLocalizations.of(context)!.nationalIdNumber,
                hint: '14 digits',
                prefixIcon: Icons.perm_identity_outlined,
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return AppLocalizations.of(context)!.nationalIdRequired;
                }
                if (!RegExp(r'^\d{14}$').hasMatch(v.trim())) {
                  return AppLocalizations.of(context)!.nationalIdLength;
                }
                return null;
              },
            ),
            const SizedBox(height: DriverFormStyles.verticalSpacing),

            // City
            TextFormField(
              controller: cityCtrl,
              decoration: DriverFormStyles.inputDecoration(
                label: AppLocalizations.of(context)!.city,
                hint: AppLocalizations.of(context)!.enterCity,
                prefixIcon: Icons.location_city_outlined,
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? AppLocalizations.of(context)!.fieldIsRequired(AppLocalizations.of(context)!.city) : null,
            ),
            const SizedBox(height: DriverFormStyles.verticalSpacing),

            // Date of Birth
            TextFormField(
              controller: dobCtrl,
              decoration: DriverFormStyles.inputDecoration(
                label: AppLocalizations.of(context)!.dateOfBirth,
                hint: 'DD/MM/YYYY',
                prefixIcon: Icons.cake_outlined,
              ),
              keyboardType: TextInputType.datetime,
              readOnly: true,
              onTap: () => _pickDate(context),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? AppLocalizations.of(context)!.fieldIsRequired(AppLocalizations.of(context)!.dateOfBirth)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 21),
      firstDate: DateTime(1950),
      lastDate: now, // allow any birth date up to today (beyond 2008)
    );
    if (picked != null) {
      dobCtrl.text =
          '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
    }
  }
}
