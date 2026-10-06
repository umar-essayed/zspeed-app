import 'package:z_speed/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:z_speed/core/utils/image_utils.dart';
import 'package:z_speed/core/utils/phone_helper.dart';

import 'package:z_speed/components/map_location_picker.dart';
import 'package:z_speed/core/utils/form_persistence.dart';
import 'package:z_speed/features/restaurant_owner/cubit/restaurant_application_cubit.dart';
import 'package:z_speed/features/restaurant_owner/cubit/restaurant_application_state.dart';
import 'package:z_speed/features/shared/widgets/account_setup_step.dart';
import 'package:z_speed/features/restaurant_owner/widgets/business_info_step.dart';
import 'package:z_speed/features/restaurant_owner/widgets/location_info_step.dart';
import 'package:z_speed/features/restaurant_owner/widgets/documents_step.dart';
import 'package:z_speed/features/restaurant_owner/widgets/branding_step.dart';
import 'package:z_speed/features/restaurant_owner/widgets/bank_info_step.dart';
import 'package:z_speed/features/restaurant_owner/widgets/restaurant_review_step.dart';
import 'package:z_speed/features/restaurant_owner/widgets/restaurant_form_styles.dart';
import 'package:z_speed/features/restaurant_owner/widgets/restaurant_form_widgets.dart';
import 'package:z_speed/features/restaurant_owner/widgets/vendor_type_selection_step.dart';
import 'package:z_speed/core/enums/user_enums.dart';

/// 6-step vendor application form.
///
/// Owns all [TextEditingController]s and delegates state to
/// [RestaurantApplicationCubit] via BlocProvider.
class RestaurantApplicationForm extends StatefulWidget {
  final String? initialEmail;
  final bool initialEmailVerified;

  const RestaurantApplicationForm({
    super.key,
    this.initialEmail,
    this.initialEmailVerified = false,
  });

  @override
  State<RestaurantApplicationForm> createState() =>
      _RestaurantApplicationFormState();
}

class _RestaurantApplicationFormState extends State<RestaurantApplicationForm> {
  // ── Form Keys ──────────────────────────────────────────────────────────────

  final _accountFormKey = GlobalKey<FormState>();
  final _businessFormKey = GlobalKey<FormState>();
  final _locationFormKey = GlobalKey<FormState>();
  final _documentsFormKey = GlobalKey<FormState>();
  final _brandingFormKey = GlobalKey<FormState>();
  final _bankFormKey = GlobalKey<FormState>();

  // ── Verification State ─────────────────────────────────────────────────────

  bool _emailVerified = false;
  bool _phoneVerified = false;
  String? _verifiedEmailValue;
  String? _verifiedPhoneValue;

  // ── Business Info Controllers ──────────────────────────────────────────────

  final _restaurantNameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _ownerNameCtrl = TextEditingController();

  // ── Location Controllers ───────────────────────────────────────────────────

  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();

  // ── Contact Controllers ────────────────────────────────────────────────────

  final _ownerPhoneCtrl = TextEditingController();
  final _ownerEmailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _restaurantPhoneCtrl = TextEditingController();

  // ── Bank Controllers ───────────────────────────────────────────────────────

  final _bankNameCtrl = TextEditingController();
  final _accountHolderCtrl = TextEditingController();
  final _ibanCtrl = TextEditingController();

  // ── Picker ─────────────────────────────────────────────────────────────────

  // ── Form Persistence ───────────────────────────────────────────────────────

  final _persistence = FormPersistence('vendor_application');
  VoidCallback? _removeAutoSave;
  late final RestaurantApplicationCubit _cubit;

  /// Map of field name → controller for save/load.
  late final Map<String, TextEditingController> _fieldMap = {
    'restaurantName': _restaurantNameCtrl,
    'description': _descriptionCtrl,
    'ownerName': _ownerNameCtrl,
    'address': _addressCtrl,
    'city': _cityCtrl,
    'ownerPhone': _ownerPhoneCtrl,
    'ownerEmail': _ownerEmailCtrl,
    'password': _passwordCtrl,
    'confirmPassword': _confirmPasswordCtrl,
    'restaurantPhone': _restaurantPhoneCtrl,
    'bankName': _bankNameCtrl,
    'accountHolder': _accountHolderCtrl,
    'iban': _ibanCtrl,
  };

  @override
  void initState() {
    super.initState();
    _cubit = RestaurantApplicationCubit();
    if (widget.initialEmail != null) {
      _ownerEmailCtrl.text = widget.initialEmail!;
    }
    if (widget.initialEmailVerified) {
      _emailVerified = true;
    }
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final savedStep = await _persistence.load(_fieldMap);
    // Attach auto-save listeners after loading
    _removeAutoSave = _persistence.autoSave(_fieldMap);

    // Restore verification flags — only if the verified value matches what was loaded
    final verifiedEmail = await _persistence.loadVerifiedValue('emailVerified');
    final verifiedPhone = await _persistence.loadVerifiedValue('phoneVerified');

    // Restore vendor type and cuisines
    final savedVendorType = await _persistence.loadJson('vendorType');
    final savedCuisines = await _persistence.loadJson('selectedCuisines');

    if (mounted) {
      // Use the local _cubit instead of context.read to avoid ProviderNotFoundException in initState
      final cubit = _cubit;

      setState(() {
        if (verifiedEmail != null && verifiedEmail == _ownerEmailCtrl.text) {
          _emailVerified = true;
          _verifiedEmailValue = verifiedEmail;
        }
        if (verifiedPhone != null && verifiedPhone == _ownerPhoneCtrl.text) {
          _phoneVerified = true;
          _verifiedPhoneValue = verifiedPhone;
        }
      });

      if (savedVendorType != null) {
        final type = VendorType.values.firstWhere(
          (e) => e.name == savedVendorType,
          orElse: () => VendorType.restaurant,
        );
        cubit.setVendorType(type);
      }

      if (savedCuisines != null && savedCuisines is List) {
        cubit.setSelectedCuisines(List<String>.from(savedCuisines));
      }

      // Restore coordinates
      final savedLat = await _persistence.loadJson('latitude');
      final savedLng = await _persistence.loadJson('longitude');
      if (savedLat != null && savedLng != null) {
        cubit.setLocation(
            (savedLat as num).toDouble(), (savedLng as num).toDouble());
      }

      // Restore document paths if they still exist
      final savedDocs = await _persistence.loadJson('pickedDocuments');
      if (savedDocs != null && savedDocs is Map) {
        for (final entry in savedDocs.entries) {
          final label = entry.key as String;
          final path = entry.value as String;
          cubit.setDocument(label, XFile(path));
        }
      }

      final savedLogo = await _persistence.loadJson('logoImage');
      if (savedLogo != null) cubit.setLogoImage(XFile(savedLogo as String));

      final savedCover = await _persistence.loadJson('coverImage');
      if (savedCover != null) cubit.setCoverImage(XFile(savedCover as String));

      if (savedStep > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          cubit.goToStep(savedStep);
        });
      }
    }

    // Reset verification if the user edits the email/phone after verifying
    _ownerEmailCtrl.addListener(_onEmailChanged);
    _ownerPhoneCtrl.addListener(_onPhoneChanged);
  }

  void _onEmailChanged() {
    if (_emailVerified && _ownerEmailCtrl.text.trim() != _verifiedEmailValue) {
      setState(() => _emailVerified = false);
      _persistence.saveBool('emailVerified', false);
    }
  }

  void _onPhoneChanged() {
    if (_phoneVerified && _ownerPhoneCtrl.text.trim() != _verifiedPhoneValue) {
      setState(() => _phoneVerified = false);
      _persistence.saveBool('phoneVerified', false);
    }
  }

  @override
  void dispose() {
    _removeAutoSave?.call();
    _cubit.close();
    _ownerEmailCtrl.removeListener(_onEmailChanged);
    _ownerPhoneCtrl.removeListener(_onPhoneChanged);
    _restaurantNameCtrl.dispose();
    _descriptionCtrl.dispose();
    _ownerNameCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _ownerPhoneCtrl.dispose();
    _ownerEmailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _restaurantPhoneCtrl.dispose();
    _bankNameCtrl.dispose();
    _accountHolderCtrl.dispose();
    _ibanCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child:
          BlocBuilder<RestaurantApplicationCubit, RestaurantApplicationState>(
        builder: (context, state) {
          final cubit = context.read<RestaurantApplicationCubit>();
          return Scaffold(
            appBar: AppBar(
              title: Text(AppLocalizations.of(context)!.vendorApplication(
                  _vendorTypeLabel(
                      AppLocalizations.of(context)!, state.vendorType))),
              elevation: 0,
            ),
            body: Column(
              children: [
                // Progress bar
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    RestaurantFormStyles.horizontalPadding,
                    12,
                    RestaurantFormStyles.horizontalPadding,
                    8,
                  ),
                  child: RestaurantStepProgressBar(
                    currentStep: state.currentStep,
                    totalSteps: RestaurantApplicationState.totalSteps,
                    stepLabels: RestaurantApplicationCubit.getStepLabels(
                        AppLocalizations.of(context)!),
                  ),
                ),

                // Upload stage label
                if (state.uploadStageLabel.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: RestaurantFormStyles.horizontalPadding,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          state.uploadStageLabel,
                          style: TextStyle(
                            fontSize: 13,
                            color: RestaurantFormStyles.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Error banner
                if (state.error != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(
                      horizontal: RestaurantFormStyles.horizontalPadding,
                      vertical: 4,
                    ),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: RestaurantFormStyles.errorColor
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            color: RestaurantFormStyles.errorColor, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            state.error!,
                            style: TextStyle(
                              color: RestaurantFormStyles.errorColor,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Step content
                Expanded(child: _buildStep(cubit, state)),

                // Navigation buttons
                RestaurantFormNavigationButtons(
                  currentStep: state.currentStep,
                  totalSteps: RestaurantApplicationState.totalSteps,
                  isSubmitting: state.isLoading,
                  onBack: () {
                    cubit.previousStep();
                    _persistence.saveCurrentStep(state.currentStep);
                  },
                  onNext: () => _validateAndAdvance(cubit, state),
                  onSubmit: () => _submit(cubit),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _vendorTypeLabel(AppLocalizations l10n, VendorType type) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    switch (type) {
      case VendorType.restaurant:
        return l10n.restaurant;
      case VendorType.supermarket:
        return l10n.supermarket;
      case VendorType.pharmacy:
        return l10n.pharmacy;
      case VendorType.bookstore:
        return isAr ? 'مكتبة ومستلزمات' : 'Bookstore & Stationery';
      case VendorType.homeFurnishing:
        return isAr ? 'أثاث ومستلزمات منزلية' : 'Home Furnishings';
      case VendorType.meatAndProteins:
        return l10n.meatAndProteins;
      case VendorType.clothes:
        return l10n.clothes;
      case VendorType.buyAndSell:
        return l10n.buyAndSell;
      case VendorType.electronics:
        return l10n.electronics;
    }
  }

  // ── Step Builder ───────────────────────────────────────────────────────────

  Widget _buildStep(
      RestaurantApplicationCubit cubit, RestaurantApplicationState state) {
    switch (state.currentStep) {
      case 0:
        return VendorTypeSelectionStep(
          selectedType: state.vendorType,
          onTypeSelected: (type) {
            cubit.setVendorType(type);
            _persistence.saveJson('vendorType', type.name);
            _persistence.saveJson(
                'selectedCuisines', []); // clear cuisines on type change
          },
        );
      case 1:
        return AccountSetupStep(
          emailController: _ownerEmailCtrl,
          phoneController: _ownerPhoneCtrl,
          passwordController: _passwordCtrl,
          confirmPasswordController: _confirmPasswordCtrl,
          formKey: _accountFormKey,
          emailVerified: _emailVerified,
          phoneVerified: _phoneVerified,
          onEmailVerified: (v) {
            setState(() {
              _emailVerified = v;
              if (v) {
                _verifiedEmailValue = _ownerEmailCtrl.text.trim();
              }
            });
            _persistence.saveBool('emailVerified', v);
            if (v) {
              _persistence.saveVerifiedValue(
                  'emailVerified', _ownerEmailCtrl.text.trim());
            }
          },
          onPhoneVerified: (v) {
            setState(() {
              _phoneVerified = v;
              if (v) {
                _verifiedPhoneValue = _ownerPhoneCtrl.text.trim();
              }
            });
            _persistence.saveBool('phoneVerified', v);
            if (v) {
              _persistence.saveVerifiedValue(
                  'phoneVerified', _ownerPhoneCtrl.text.trim());
            }
          },
          primaryColor: RestaurantFormStyles.primaryColor,
          accentColor: RestaurantFormStyles.accentColor,
          errorColor: RestaurantFormStyles.errorColor,
          successColor: RestaurantFormStyles.successColor,
          borderColor: RestaurantFormStyles.borderColor,
          labelColor: RestaurantFormStyles.labelColor,
          hidePassword: widget.initialEmailVerified,
          sectionHeader: RestaurantFormSectionHeader(
            title: AppLocalizations.of(context)!.accountSetup,
            subtitle: AppLocalizations.of(context)!.accountSetupSubtitle,
            icon: Icons.verified_user_outlined,
          ),
        );
      case 2:
        return BusinessInfoStep(
          restaurantNameController: _restaurantNameCtrl,
          descriptionController: _descriptionCtrl,
          ownerNameController: _ownerNameCtrl,
          restaurantPhoneController: _restaurantPhoneCtrl,
          selectedCuisines: state.selectedCuisines,
          availableCuisines: state.availableCuisines,
          isLoadingCuisines: state.isLoadingCuisines,
          onToggleCuisine: (cuisine) {
            cubit.toggleCuisine(cuisine);
            // Save after cubit updates its state
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _persistence.saveJson(
                  'selectedCuisines', cubit.state.selectedCuisines);
            });
          },
          formKey: _businessFormKey,
          vendorType: state.vendorType,
        );
      case 3:
        return LocationInfoStep(
          addressController: _addressCtrl,
          cityController: _cityCtrl,
          operatingHours: state.operatingHours,
          onUpdateHours: cubit.updateHours,
          formKey: _locationFormKey,
          latitude: state.latitude,
          longitude: state.longitude,
          onGetLocation: () async {
            final address = await cubit.getCurrentLocation();
            if (address != null) {
              _addressCtrl.text = address;
            }
            // Save coordinates to persistence
            if (cubit.state.latitude != null && cubit.state.longitude != null) {
              _persistence.saveJson('latitude', cubit.state.latitude);
              _persistence.saveJson('longitude', cubit.state.longitude);
            }
          },
          onPickOnMap: () async {
            final result = await Navigator.push<Map<String, dynamic>>(
              context,
              MaterialPageRoute(
                builder: (context) => MapLocationPicker(
                  initialLocation:
                      state.latitude != null && state.longitude != null
                          ? null
                          : null,
                ),
              ),
            );
            if (result != null) {
              final lat = result['lat'] as double;
              final lng = result['lng'] as double;
              final address = result['address'] as String;
              cubit.setLocation(lat, lng);
              _addressCtrl.text = address;
              _persistence.saveJson('latitude', lat);
              _persistence.saveJson('longitude', lng);
            }
          },
          isGettingLocation: state.isGettingLocation,
        );
      case 4:
        return DocumentsStep(
          documents: state.pickedDocuments,
          uploadStatuses: state.uploadStatuses,
          onPickDocument: (label) => _pickDocument(cubit, label),
          formKey: _documentsFormKey,
        );
      case 5:
        return BrandingStep(
          logoImage: state.logoImage,
          coverImage: state.coverImage,
          onPickLogo: () => _pickImage(cubit, isLogo: true),
          onPickCover: () => _pickImage(cubit, isLogo: false),
          formKey: _brandingFormKey,
          vendorType: state.vendorType,
        );
      case 6:
        return BankInfoStep(
          bankNameController: _bankNameCtrl,
          accountHolderController: _accountHolderCtrl,
          ibanController: _ibanCtrl,
          formKey: _bankFormKey,
        );
      case 7:
        return RestaurantReviewStep(
          restaurantName: _restaurantNameCtrl.text,
          description: _descriptionCtrl.text,
          ownerName: _ownerNameCtrl.text,
          restaurantPhone: _restaurantPhoneCtrl.text,
          selectedCuisines: state.selectedCuisines,
          availableCuisines: state.availableCuisines,
          address: _addressCtrl.text,
          city: _cityCtrl.text,
          operatingHours: state.operatingHours,
          ownerEmail: _ownerEmailCtrl.text,
          ownerPhone: _ownerPhoneCtrl.text,
          bankName: _bankNameCtrl.text,
          accountHolder: _accountHolderCtrl.text,
          iban: _ibanCtrl.text,
          documents: state.pickedDocuments,
          logoImage: state.logoImage,
          coverImage: state.coverImage,
          onEditStep: cubit.goToStep,
          vendorType: state.vendorType,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Validation ─────────────────────────────────────────────────────────────

  void _validateAndAdvance(
      RestaurantApplicationCubit cubit, RestaurantApplicationState state) {
    bool valid = true;

    switch (state.currentStep) {
      case 0:
        // Vendor type always has a default; step is always valid.
        break;
      case 1:
        valid = _accountFormKey.currentState?.validate() ?? false;
        break;
      case 2:
        final formValid = _businessFormKey.currentState?.validate() ?? false;
        if (formValid) {
          _restaurantPhoneCtrl.text = PhoneHelper.normalizePhone(_restaurantPhoneCtrl.text);
        }
        final needsCuisine = state.vendorType == VendorType.restaurant;
        final cuisineValid = !needsCuisine || state.selectedCuisines.isNotEmpty;
        valid = formValid && cuisineValid;
        if (needsCuisine && state.selectedCuisines.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.selectAtLeastOne),
              backgroundColor: RestaurantFormStyles.errorColor,
            ),
          );
        }
        break;
      case 3:
        valid = _locationFormKey.currentState?.validate() ?? false;
        if (valid && (state.latitude == null || state.longitude == null)) {
          valid = false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.location_off, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Please set your location using GPS or the map picker.',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              backgroundColor: RestaurantFormStyles.errorColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 4),
            ),
          );
        }
        break;
      case 4:
        if (!state.allDocumentsPicked) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.pleaseUploadAllRequired),
              backgroundColor: RestaurantFormStyles.errorColor,
            ),
          );
          valid = false;
        }
        break;
      case 5:
        if (!state.allBrandingPicked) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.pleaseUploadBothLogo),
              backgroundColor: RestaurantFormStyles.errorColor,
            ),
          );
          valid = false;
        }
        break;
      case 6:
        valid = _bankFormKey.currentState?.validate() ?? false;
        break;
    }

    if (valid) {
      cubit.nextStep();
      _persistence.saveCurrentStep(state.currentStep);
    }
  }

  // ── File Picking ───────────────────────────────────────────────────────────

  Future<void> _pickDocument(
      RestaurantApplicationCubit cubit, String label) async {
    final picked = await ImageUtils.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 80,
    );
    if (picked != null) {
      final sizeBytes = await picked.length();
      if (sizeBytes > 10 * 1024 * 1024) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.fileExceedsThe10mb),
            backgroundColor: RestaurantFormStyles.errorColor,
          ),
        );
        return;
      }
      cubit.setDocument(label, picked);
      _persistence.saveJson('pickedDocuments',
          cubit.state.pickedDocuments.map((k, v) => MapEntry(k, v?.path)));
    }
  }

  Future<void> _pickImage(RestaurantApplicationCubit cubit,
      {required bool isLogo}) async {
    final picked = await ImageUtils.pickImage(
      source: ImageSource.gallery,
      maxWidth: isLogo ? 512 : 1920,
      maxHeight: isLogo ? 512 : 1080,
      imageQuality: isLogo ? 90 : 85,
    );
    if (picked != null) {
      final sizeBytes = await picked.length();
      if (sizeBytes > 10 * 1024 * 1024) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.fileExceedsThe10mb),
            backgroundColor: RestaurantFormStyles.errorColor,
          ),
        );
        return;
      }
      if (isLogo) {
        cubit.setLogoImage(picked);
        _persistence.saveJson('logoImage', picked.path);
      } else {
        cubit.setCoverImage(picked);
        _persistence.saveJson('coverImage', picked.path);
      }
    }
  }

  // ── Submission ─────────────────────────────────────────────────────────────

  Future<void> _submit(RestaurantApplicationCubit cubit) async {
    // Bank info was already validated when advancing past step 5.

    final user = await cubit.submitApplication(
      businessInfo: {
        'restaurantName': _restaurantNameCtrl.text.trim(),
        'description': _descriptionCtrl.text.trim(),
        'ownerName': _ownerNameCtrl.text.trim(),
      },
      contactInfo: {
        'ownerEmail': _ownerEmailCtrl.text.trim(),
        'ownerPhone': _ownerPhoneCtrl.text.trim(),
        'restaurantPhone': _restaurantPhoneCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
      },
      bankInfo: {
        'bankName': _bankNameCtrl.text.trim(),
        'accountHolder': _accountHolderCtrl.text.trim(),
        'iban': _ibanCtrl.text.replaceAll(' ', ''),
      },
      password: _passwordCtrl.text,
      creatingAccountLabel: AppLocalizations.of(context)!.creatingAccount,
      uploadingDocsLabel: AppLocalizations.of(context)!.uploadingDocuments,
      uploadingBrandingLabel: AppLocalizations.of(context)!.uploadingBranding,
      savingAppLabel: AppLocalizations.of(context)!.savingApplication,
    );

    if (user != null && mounted) {
      await _persistence.clear();
      _clearAllInputs(cubit);
      _showSuccessDialog();
    }
  }

  void _clearAllInputs(RestaurantApplicationCubit cubit) {
    for (final ctrl in _fieldMap.values) {
      ctrl.clear();
    }
    _passwordCtrl.clear();
    _confirmPasswordCtrl.clear();

    setState(() {
      _emailVerified = false;
      _phoneVerified = false;
    });

    cubit.reset();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Icon(
          Icons.check_circle,
          color: RestaurantFormStyles.successColor,
          size: 56,
        ),
        title: Text(AppLocalizations.of(context)!.applicationSubmitted),
        content: Text(
          AppLocalizations.of(context)!.applicationSubmittedSubtitle,
          textAlign: TextAlign.center,
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: RestaurantFormStyles.primaryColor,
            ),
            child: Text(AppLocalizations.of(context)!.done),
          ),
        ],
      ),
    );
  }
}
