import 'package:flutter/material.dart';
import 'package:z_speed/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:z_speed/core/utils/image_utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/core/injection.dart';

import 'package:z_speed/core/core.dart';
import 'package:z_speed/core/utils/form_persistence.dart';
import 'package:z_speed/features/driver/cubit/driver_application_cubit.dart';
import 'package:z_speed/features/driver/cubit/driver_application_state.dart';
import 'package:z_speed/features/shared/widgets/account_setup_step.dart';
import 'package:z_speed/features/driver/widgets/driver_personal_info_step.dart';
import 'package:z_speed/features/driver/widgets/driver_vehicle_info_step.dart';
import 'package:z_speed/features/driver/widgets/driver_documents_step.dart';
import 'package:z_speed/features/driver/widgets/driver_review_step.dart';
import 'package:z_speed/features/driver/widgets/driver_form_styles.dart';
import 'package:z_speed/features/driver/widgets/driver_form_widgets.dart';

/// 5-step driver application form.
///
/// Step 0: Account Setup (email+verify, phone+verify, password)
/// Step 1: Personal Info (name, city, DOB)
/// Step 2: Vehicle Info
/// Step 3: Documents
/// Step 4: Review
class DriverApplicationForm extends StatefulWidget {
  final String? initialEmail;
  final bool initialEmailVerified;

  const DriverApplicationForm({
    super.key,
    this.initialEmail,
    this.initialEmailVerified = false,
  });

  @override
  State<DriverApplicationForm> createState() => _DriverApplicationFormState();
}

class _DriverApplicationFormState extends State<DriverApplicationForm> {
  // ── Form Keys (one per validatable step) ────────────────────────────────────

  final _accountFormKey = GlobalKey<FormState>();
  final _personalFormKey = GlobalKey<FormState>();
  final _vehicleFormKey = GlobalKey<FormState>();
  final _documentsFormKey = GlobalKey<FormState>();

  // ── Verification State ─────────────────────────────────────────────────────

  bool _emailVerified = false;
  bool _phoneVerified = false;
  String? _verifiedEmailValue;
  String? _verifiedPhoneValue;

  // ── Personal Info Controllers ──────────────────────────────────────────────

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _nationalIdCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController(text: 'delivery');
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  // ── Vehicle Info Controllers ───────────────────────────────────────────────

  final _vehicleTypeCtrl = TextEditingController();
  final _vehicleMakeCtrl = TextEditingController();
  final _vehicleModelCtrl = TextEditingController();
  final _vehicleYearCtrl = TextEditingController();
  final _plateNumberCtrl = TextEditingController();
  final _vehicleColorCtrl = TextEditingController();

  // ── Image Picker ───────────────────────────────────────────────────────────


  // ── Form Persistence ───────────────────────────────────────────────────────

  final _persistence = FormPersistence('driver_application');
  VoidCallback? _removeAutoSave;
  late final DriverApplicationCubit _cubit = getIt<DriverApplicationCubit>();

  /// Map of field name → controller for save/load.
  late final Map<String, TextEditingController> _fieldMap = {
    'name': _nameCtrl,
    'email': _emailCtrl,
    'phone': _phoneCtrl,
    'city': _cityCtrl,
    'dob': _dobCtrl,
    'nationalId': _nationalIdCtrl,
    'driverCategory': _categoryCtrl,
    'password': _passwordCtrl,
    'confirmPassword': _confirmPasswordCtrl,
    'vehicleType': _vehicleTypeCtrl,
    'vehicleMake': _vehicleMakeCtrl,
    'vehicleModel': _vehicleModelCtrl,
    'vehicleYear': _vehicleYearCtrl,
    'plateNumber': _plateNumberCtrl,
    'vehicleColor': _vehicleColorCtrl,
  };

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null) {
      _emailCtrl.text = widget.initialEmail!;
    }
    if (widget.initialEmailVerified) {
      _emailVerified = true;
    }
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final savedStep = await _persistence.load(_fieldMap);
    // Restore verification state — only valid if saved value matches loaded field
    final verifiedEmail = await _persistence.loadVerifiedValue('emailVerified');
    final verifiedPhone = await _persistence.loadVerifiedValue('phoneVerified');
    if (mounted) {
      setState(() {
        if (verifiedEmail != null && verifiedEmail == _emailCtrl.text) {
          _emailVerified = true;
          _verifiedEmailValue = verifiedEmail;
        }
        if (verifiedPhone != null && verifiedPhone == _phoneCtrl.text) {
          _phoneVerified = true;
          _verifiedPhoneValue = verifiedPhone;
        }
      });
    }
    // Attach auto-save listeners after loading
    _removeAutoSave = _persistence.autoSave(_fieldMap);
    _emailCtrl.addListener(_onEmailChanged);
    _phoneCtrl.addListener(_onPhoneChanged);
    if (savedStep > 0 && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _cubit.goToStep(savedStep);
      });
    }
  }

  void _onEmailChanged() {
    if (_emailVerified && _emailCtrl.text.trim() != _verifiedEmailValue) {
      setState(() => _emailVerified = false);
      _persistence.saveBool('emailVerified', false);
    }
  }

  void _onPhoneChanged() {
    if (_phoneVerified && _phoneCtrl.text.trim() != _verifiedPhoneValue) {
      setState(() => _phoneVerified = false);
      _persistence.saveBool('phoneVerified', false);
    }
  }

  @override
  void dispose() {
    _removeAutoSave?.call();
    _cubit.close();
    _emailCtrl.removeListener(_onEmailChanged);
    _phoneCtrl.removeListener(_onPhoneChanged);
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _dobCtrl.dispose();
    _nationalIdCtrl.dispose();
    _categoryCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _vehicleTypeCtrl.dispose();
    _vehicleMakeCtrl.dispose();
    _vehicleModelCtrl.dispose();
    _vehicleYearCtrl.dispose();
    _plateNumberCtrl.dispose();
    _vehicleColorCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<DriverApplicationCubit, DriverApplicationState>(
        builder: (context, state) {
          final cubit = context.read<DriverApplicationCubit>();
          return Scaffold(
            appBar: AppBar(
              title: Text(AppLocalizations.of(context)!.driverApplication),
              elevation: 0,
            ),
            body: Column(
              children: [
                // Progress bar
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    DriverFormStyles.horizontalPadding,
                    12,
                    DriverFormStyles.horizontalPadding,
                    8,
                  ),
                  child: DriverStepProgressBar(
                    currentStep: state.currentStep,
                    totalSteps: DriverApplicationCubit.totalSteps,
                    stepLabels: [
                      AppLocalizations.of(context)!.accountSetup,
                      AppLocalizations.of(context)!.personalInformation,
                      AppLocalizations.of(context)!.vehicleStep,
                      AppLocalizations.of(context)!.documentsStep,
                      AppLocalizations.of(context)!.reviewStep,
                    ],
                  ),
                ),

                // Upload stage label
                if (state.uploadStageLabel.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DriverFormStyles.horizontalPadding,
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
                            color: DriverFormStyles.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Error banner
                if (state.state == ViewState.error && state.failure != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(
                      horizontal: DriverFormStyles.horizontalPadding,
                      vertical: 4,
                    ),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: DriverFormStyles.errorColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            color: DriverFormStyles.errorColor, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            state.failure!.message,
                            style: TextStyle(
                              color: DriverFormStyles.errorColor,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Step content
                Expanded(
                  child: _buildStepContent(state, cubit),
                ),

                // Navigation buttons
                DriverFormNavigationButtons(
                  currentStep: state.currentStep,
                  totalSteps: DriverApplicationCubit.totalSteps,
                  isSubmitting: state.state == ViewState.loading,
                  onBack: () {
                    cubit.previousStep();
                    _persistence.saveCurrentStep(cubit.state.currentStep);
                  },
                  onNext: () => _validateAndAdvance(state, cubit),
                  onSubmit: () => _submit(cubit),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Step Builders ──────────────────────────────────────────────────────────

  Widget _buildStepContent(DriverApplicationState state, DriverApplicationCubit cubit) {
    switch (state.currentStep) {
      case 0:
        return AccountSetupStep(
          emailController: _emailCtrl,
          phoneController: _phoneCtrl,
          passwordController: _passwordCtrl,
          confirmPasswordController: _confirmPasswordCtrl,
          formKey: _accountFormKey,
          emailVerified: _emailVerified,
          phoneVerified: _phoneVerified,
          onEmailVerified: (v) {
            setState(() {
              _emailVerified = v;
              if (v) _verifiedEmailValue = _emailCtrl.text.trim();
            });
            _persistence.saveBool('emailVerified', v);
            if (v) _persistence.saveVerifiedValue('emailVerified', _emailCtrl.text.trim());
          },
          onPhoneVerified: (v) {
            setState(() {
              _phoneVerified = v;
              if (v) _verifiedPhoneValue = _phoneCtrl.text.trim();
            });
            _persistence.saveBool('phoneVerified', v);
            if (v) _persistence.saveVerifiedValue('phoneVerified', _phoneCtrl.text.trim());
          },
          primaryColor: DriverFormStyles.primaryColor,
          accentColor: DriverFormStyles.accentColor,
          errorColor: DriverFormStyles.errorColor,
          successColor: DriverFormStyles.successColor,
          borderColor: DriverFormStyles.borderColor,
          labelColor: DriverFormStyles.labelColor,
          hidePassword: widget.initialEmailVerified,
          sectionHeader: DriverFormSectionHeader(
            title: AppLocalizations.of(context)!.accountSetup,
            subtitle: AppLocalizations.of(context)!.fillDetailsToGetStarted,
            icon: Icons.verified_user_outlined,
          ),
        );
      case 1:
        return DriverPersonalInfoStep(
          nameController: _nameCtrl,
          cityController: _cityCtrl,
          dobController: _dobCtrl,
          nationalIdController: _nationalIdCtrl,
          categoryController: _categoryCtrl,
          formKey: _personalFormKey,
        );
      case 2:
        return DriverVehicleInfoStep(
          driverCategory: _categoryCtrl.text,
          vehicleTypeController: _vehicleTypeCtrl,
          vehicleMakeController: _vehicleMakeCtrl,
          vehicleModelController: _vehicleModelCtrl,
          vehicleYearController: _vehicleYearCtrl,
          plateNumberController: _plateNumberCtrl,
          vehicleColorController: _vehicleColorCtrl,
          formKey: _vehicleFormKey,
        );
      case 3:
        return DriverDocumentsStep(
          documents: state.pickedDocuments,
          uploadStatuses: state.uploadStatuses,
          onPickDocument: (label) => _pickDocument(cubit, label),
          formKey: _documentsFormKey,
        );
      case 4:
        return DriverReviewStep(
          name: _nameCtrl.text,
          email: _emailCtrl.text,
          phone: _phoneCtrl.text,
          city: _cityCtrl.text,
          dob: _dobCtrl.text,
          nationalId: _nationalIdCtrl.text,
          vehicleType: _vehicleTypeCtrl.text,
          vehicleMake: _vehicleMakeCtrl.text,
          vehicleModel: _vehicleModelCtrl.text,
          vehicleYear: _vehicleYearCtrl.text,
          vehicleColor: _vehicleColorCtrl.text,
          plateNumber: _plateNumberCtrl.text,
          documents: state.pickedDocuments,
          requiredDocumentLabels: DriverApplicationCubit.requiredDocumentLabels,
          onEditStep: cubit.goToStep,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Validation ─────────────────────────────────────────────────────────────

  void _validateAndAdvance(DriverApplicationState state, DriverApplicationCubit cubit) {
    bool valid = true;

    switch (state.currentStep) {
      case 0:
        valid = _accountFormKey.currentState?.validate() ?? false;
        // Verification disabled for testing
        // if (!_emailVerified || !_phoneVerified) {
        //   ScaffoldMessenger.of(context).showSnackBar(
        //     SnackBar(
        //       content: Text(AppLocalizations.of(context)!.verifyContact),
        //       backgroundColor: DriverFormStyles.errorColor,
        //     ),
        //   );
        // }
        break;
      case 1:
        valid = _personalFormKey.currentState?.validate() ?? false;
        break;
      case 2:
        valid = _vehicleFormKey.currentState?.validate() ?? false;
        break;
      case 3:
        // All documents must be picked
        if (!state.allDocumentsPicked) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.uploadRequiredDocs),
              backgroundColor: DriverFormStyles.errorColor,
            ),
          );
          valid = false;
        }
        break;
    }

    if (valid) {
      cubit.nextStep();
      _persistence.saveCurrentStep(cubit.state.currentStep);
    }
  }

  // ── Document Picking ───────────────────────────────────────────────────────

  Future<void> _pickDocument(
    DriverApplicationCubit cubit,
    String label,
  ) async {
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
            content: Text(AppLocalizations.of(context)!.fileExceedsLimit),
            backgroundColor: DriverFormStyles.errorColor,
          ),
        );
        return;
      }
      cubit.setDocument(label, picked);
    }
  }

  // ── Submission ─────────────────────────────────────────────────────────────

  Future<void> _submit(DriverApplicationCubit cubit) async {
    final user = await cubit.submitApplication(
      personalInfo: {
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'dob': _dobCtrl.text.trim(),
        'nationalId': _nationalIdCtrl.text.trim(),
        'driverCategory': _categoryCtrl.text.trim(),
      },
      vehicleInfo: {
        'type': _vehicleTypeCtrl.text.trim(),
        'make': _vehicleMakeCtrl.text.trim(),
        'model': _vehicleModelCtrl.text.trim(),
        'year': _vehicleYearCtrl.text.trim(),
        'color': _vehicleColorCtrl.text.trim(),
        'plateNumber': _plateNumberCtrl.text.trim(),
      },
      password: _passwordCtrl.text,
    );

    if (user != null && mounted) {
      await _persistence.clear();
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Icon(
          Icons.check_circle,
          color: DriverFormStyles.successColor,
          size: 56,
        ),
        title: Text(AppLocalizations.of(context)!.applicationSubmitted),
        content: Text(
          AppLocalizations.of(context)!.applicationSubmittedSuccess,
          textAlign: TextAlign.center,
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop(); // Return to previous screen
            },
            style: FilledButton.styleFrom(
              backgroundColor: DriverFormStyles.primaryColor,
            ),
            child: Text(AppLocalizations.of(context)!.done),
          ),
        ],
      ),
    );
  }
}
