import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:z_speed/core/utils/phone_helper.dart';
import 'package:z_speed/features/auth/widgets/app_phone_otp_dialog.dart';
import 'package:z_speed/features/auth/widgets/email_verification_dialog.dart';
import 'package:z_speed/l10n/app_localizations.dart';

/// Reusable Step 0 for both driver and restaurant application forms.
///
/// Collects email (with OTP verification), phone (with SMS verification),
/// password and confirm-password. The parent form supplies controllers and
/// receives verification-state callbacks.
class AccountSetupStep extends StatefulWidget {
  // ── Controllers (owned by the parent form) ──
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final GlobalKey<FormState> formKey;

  // ── Verification state (managed by parent for persistence) ──
  final bool emailVerified;
  final bool phoneVerified;
  final ValueChanged<bool> onEmailVerified;
  final ValueChanged<bool> onPhoneVerified;

  // ── Theming ──
  final Color primaryColor;
  final Color accentColor;
  final Color errorColor;
  final Color successColor;
  final Color borderColor;
  final Color labelColor;
  final double inputRadius;
  final double horizontalPadding;
  final double verticalSpacing;
  final double sectionSpacing;

  // ── Section header widget builder ──
  final Widget sectionHeader;

  /// When true, hides the password fields (e.g. Google sign-in users don't need a password)
  final bool hidePassword;

  const AccountSetupStep({
    super.key,
    required this.emailController,
    required this.phoneController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.formKey,
    required this.emailVerified,
    required this.phoneVerified,
    required this.onEmailVerified,
    required this.onPhoneVerified,
    required this.sectionHeader,
    this.hidePassword = false,
    this.primaryColor = const Color(0xFFE65100),
    this.accentColor = const Color(0xFFFF8A65),
    this.errorColor = const Color(0xFFD32F2F),
    this.successColor = const Color(0xFF388E3C),
    this.borderColor = const Color(0xFFE0E0E0),
    this.labelColor = const Color(0xFF616161),
    this.inputRadius = 12.0,
    this.horizontalPadding = 20.0,
    this.verticalSpacing = 16.0,
    this.sectionSpacing = 24.0,
  });

  @override
  State<AccountSetupStep> createState() => _AccountSetupStepState();
}

class _AccountSetupStepState extends State<AccountSetupStep>
    with TickerProviderStateMixin {
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  // ── Email OTP state ──
  /*
  bool _emailOtpSent = false;
  bool _emailSending = false;
  final _emailOtpCtrl = TextEditingController();
  bool _emailVerifying = false;
  String? _emailError;

  // ── Phone OTP state ──
  bool _phoneOtpSent = false;
  bool _phoneSending = false;
  final _phoneOtpCtrl = TextEditingController();
  bool _phoneVerifying = false;
  String? _phoneError;
  String? _phoneVerificationId;
  int? _phoneResendToken;
  ConfirmationResult? _webConfirmation;
  */

  // ── Animations ──
  late final AnimationController _emailCheckAnim;
  late final AnimationController _phoneCheckAnim;

  @override
  void initState() {
    super.initState();
    _emailCheckAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _phoneCheckAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    if (widget.emailVerified) _emailCheckAnim.value = 1.0;
    if (widget.phoneVerified) _phoneCheckAnim.value = 1.0;
  }

  @override
  void dispose() {
    // _emailOtpCtrl.dispose();
    // _phoneOtpCtrl.dispose();
    _emailCheckAnim.dispose();
    _phoneCheckAnim.dispose();
    super.dispose();
  }

  // ── Decoration helper ─────────────────────────────────────────────────────

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(color: widget.labelColor, fontSize: 14),
      hintStyle: TextStyle(color: widget.labelColor.withValues(alpha: 0.5)),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, size: 20, color: widget.labelColor)
          : null,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(widget.inputRadius),
        borderSide: BorderSide(color: widget.borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(widget.inputRadius),
        borderSide: BorderSide(color: widget.borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(widget.inputRadius),
        borderSide: BorderSide(color: widget.primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(widget.inputRadius),
        borderSide: BorderSide(color: widget.errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(widget.inputRadius),
        borderSide: BorderSide(color: widget.errorColor, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  // ── Verify button widget ──────────────────────────────────────────────────

  // Verification status banner and other sub-widgets removed for brevity.

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(widget.horizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            widget.sectionHeader,

            // ━━━ EMAIL VERIFICATION CARD ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            _VerificationCard(
              icon: Icons.email_outlined,
              title: AppLocalizations.of(context)!.emailAddress,
              verified: widget.emailVerified,
              primaryColor: widget.primaryColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: widget.emailController,
                    readOnly: widget.emailVerified,
                    decoration: _inputDecoration(
                      label: AppLocalizations.of(context)!.emailAddress,
                      hint: AppLocalizations.of(context)!.emailHint,
                      prefixIcon: Icons.email_outlined,
                      suffixIcon: widget.emailVerified
                          ? null
                          : TextButton(
                              onPressed: () {
                                if (widget.emailController.text
                                    .trim()
                                    .isEmpty) {
                                  return;
                                }
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (_) => EmailVerificationDialog(
                                    email: widget.emailController.text.trim(),
                                    skipExistingCheck: false,
                                    onVerified: () {
                                      widget.onEmailVerified.call(true);
                                    },
                                  ),
                                );
                              },
                              child: Text(
                                  AppLocalizations.of(context)!.verifyLabel),
                            ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return AppLocalizations.of(context)!
                            .pleaseEnterYourEmail;
                      }
                      if (!RegExp(r'^[\w.\-]+@[\w.\-]+\.\w+$')
                          .hasMatch(v.trim())) {
                        return AppLocalizations.of(context)!
                            .pleaseEnterValidEmail;
                      }
                      if (!widget.emailVerified) {
                        return AppLocalizations.of(context)!.pleaseVerifyEmail;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  if (widget.emailVerified)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8)),
                      child: Row(children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(AppLocalizations.of(context)!.emailVerifiedMsg,
                            style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold))
                      ]),
                    ),
                ],
              ),
            ),

            SizedBox(height: widget.verticalSpacing),

            // ━━━ PHONE VERIFICATION CARD ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            _VerificationCard(
              icon: Icons.phone_outlined,
              title: AppLocalizations.of(context)!.phoneNumberLabel,
              verified: widget.phoneVerified,
              primaryColor: widget.primaryColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: widget.phoneController,
                    enabled: !widget.phoneVerified,
                    decoration: _inputDecoration(
                      label: AppLocalizations.of(context)!.phoneNumberLabel,
                      hint: AppLocalizations.of(context)!.phoneHint,
                      prefixIcon: Icons.phone_outlined,
                      suffixIcon: widget.phoneVerified
                          ? null
                          : TextButton(
                              onPressed: () async {
                                final inputPhone = widget.phoneController.text.trim();
                                if (inputPhone.isEmpty) return;

                                final normalized = PhoneHelper.normalizePhone(inputPhone);

                                if (!PhoneHelper.isValidEgyptianPhone(normalized)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(AppLocalizations.of(context)!.enterValidPhoneNumber),
                                      backgroundColor: widget.errorColor,
                                    ),
                                  );
                                  return;
                                }

                                // Show loading spinner dialog while checking
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );

                                try {
                                  final query = await FirebaseFirestore.instance
                                      .collection('users')
                                      .where('phone', isEqualTo: normalized)
                                      .get();

                                  if (context.mounted) {
                                    Navigator.pop(context); // Dismiss loading spinner
                                  }

                                  if (query.docs.isNotEmpty) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(AppLocalizations.of(context)!.phoneAlreadyRegistered),
                                          backgroundColor: widget.errorColor,
                                        ),
                                      );
                                    }
                                    return;
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    Navigator.pop(context); // Dismiss loading spinner
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error checking phone number: $e'),
                                        backgroundColor: widget.errorColor,
                                      ),
                                    );
                                  }
                                  return;
                                }

                                if (context.mounted) {
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (_) => AppPhoneOtpDialog(
                                      phone: normalized,
                                      onVerified: () {
                                        widget.phoneController.text = normalized;
                                        widget.onPhoneVerified.call(true);
                                      },
                                    ),
                                  );
                                }
                              },
                              child: Text(
                                  AppLocalizations.of(context)!.verifyLabel),
                            ),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return AppLocalizations.of(context)!.fieldIsRequired(
                            AppLocalizations.of(context)!.phoneNumberLabel);
                      }
                      if (!widget.phoneVerified) {
                        return AppLocalizations.of(context)!.pleaseVerifyPhone;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  if (widget.phoneVerified)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8)),
                      child: Row(children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(AppLocalizations.of(context)!.phoneVerifiedMsg,
                            style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold))
                      ]),
                    ),
                ],
              ),
            ),

            SizedBox(height: widget.sectionSpacing),

            // ━━━ PASSWORD SECTION ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            if (!widget.hidePassword) ...[
              _SectionLabel(
                icon: Icons.lock_outlined,
                title: AppLocalizations.of(context)!.password,
                primaryColor: widget.primaryColor,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: widget.passwordController,
                decoration: _inputDecoration(
                  label: AppLocalizations.of(context)!.password,
                  hint: AppLocalizations.of(context)!.passwordMinLength,
                  prefixIcon: Icons.lock_outlined,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                      color: Colors.grey,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                obscureText: _obscurePassword,
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return AppLocalizations.of(context)!
                        .pleaseEnterYourPasswordValidation;
                  }
                  if (v.length < 6) {
                    return AppLocalizations.of(context)!.passwordMinLength;
                  }
                  return null;
                },
              ),
              SizedBox(height: widget.verticalSpacing),
              TextFormField(
                controller: widget.confirmPasswordController,
                decoration: _inputDecoration(
                  label: AppLocalizations.of(context)!.confirmPassword,
                  hint: AppLocalizations.of(context)!.pleaseConfirmYourPassword,
                  prefixIcon: Icons.lock_outlined,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                      color: Colors.grey,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                obscureText: _obscureConfirm,
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return AppLocalizations.of(context)!
                        .pleaseConfirmYourPassword;
                  }
                  if (v != widget.passwordController.text) {
                    return AppLocalizations.of(context)!.passwordsDoNotMatch;
                  }
                  return null;
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

/// Card wrapper for a verification section (email / phone).
class _VerificationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool verified;
  final Color primaryColor;
  final Widget child;

  const _VerificationCard({
    required this.icon,
    required this.title,
    required this.verified,
    required this.primaryColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = verified
        ? const Color(0xFF81C784)
        : primaryColor.withValues(alpha: 0.15);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: verified ? 0.03 : 0.05),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Color(0xFF424242),
                  ),
                ),
                const Spacer(),
                if (verified)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF388E3C).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF81C784)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified,
                            size: 12, color: Color(0xFF388E3C)),
                        const SizedBox(width: 4),
                        Text(AppLocalizations.of(context)!.verifiedLabel,
                            style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF388E3C),
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 16),
            child: child,
          ),
        ],
      ),
    );
  }
}

/// Section label for password area.
class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color primaryColor;

  const _SectionLabel({
    required this.icon,
    required this.title,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: primaryColor),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Color(0xFF424242),
          ),
        ),
      ],
    );
  }
}
