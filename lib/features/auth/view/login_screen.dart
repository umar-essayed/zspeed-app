import 'dart:io' show Platform;
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:z_speed/core/errors/failure_localization_ext.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/features/auth/cubit/auth_cubit.dart';
import 'package:z_speed/features/auth/model/user_model.dart';
import 'package:z_speed/features/auth/widgets/login_glass_field.dart';
import 'package:z_speed/features/auth/widgets/login_button.dart';
import 'package:z_speed/features/auth/widgets/login_or_divider.dart';
import 'package:z_speed/features/auth/widgets/login_social_button.dart';
import 'package:z_speed/features/auth/widgets/login_toggle_row.dart';
import 'package:z_speed/features/auth/widgets/phone_login_sheet.dart';
import 'package:z_speed/features/auth/widgets/name_dialog.dart';
import 'package:z_speed/features/auth/widgets/email_verification_dialog.dart';
import 'package:z_speed/l10n/app_localizations.dart';
import 'package:z_speed/features/auth/widgets/partner_links_widget.dart';
import 'package:z_speed/features/auth/widgets/language_switcher_overlay.dart';
import 'package:z_speed/core/widgets/logo.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSignUp = false;
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _agreedToTerms = false;
  bool _rememberLogin = false;

  @override
  void initState() {
    super.initState();
    _loadRememberedEmail();
  }

  Future<void> _loadRememberedEmail() async {
    if (!kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool('remember_login') ?? false;
    if (remember) {
      final email = prefs.getString('remembered_email') ?? '';
      setState(() {
        _rememberLogin = true;
        _emailController.text = email;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final authCubit = context.read<AuthCubit>();

      if (_isSignUp) {
        if (!_agreedToTerms) {
          setState(() => _isLoading = false);
          _showError('You must agree to the Terms of Service to continue.');
          return;
        }
        // ── Step 1: Verify email BEFORE creating account ──
        final verified = await EmailVerificationDialog.show(
          context,
          email: _emailController.text.trim(),
          skipExistingCheck: false,
        );

        if (!mounted) return;
        if (verified != true) {
          setState(() => _isLoading = false);
          return;
        }

        // ── Step 2: Email verified → create account ──
        final newUser = AppUser(
          id: '',
          name: _emailController.text.split('@')[0],
          email: _emailController.text.trim(),
          password: _passwordController.text,
          type: UserType.customer,
        );
        await authCubit.register(newUser);
      } else {
        if (kIsWeb) {
          final prefs = await SharedPreferences.getInstance();
          if (_rememberLogin) {
            await prefs.setBool('remember_login', true);
            await prefs.setString('remembered_email', _emailController.text.trim());
          } else {
            await prefs.setBool('remember_login', false);
            await prefs.remove('remembered_email');
          }
        }

        await authCubit.login(
          _emailController.text.trim(),
          _passwordController.text,
          rememberMe: kIsWeb ? _rememberLogin : false,
        );
      }

      if (!mounted) return;

      if (authCubit.state.hasError || authCubit.state.user == null) {
        setState(() => _isLoading = false);
        final l10n = AppLocalizations.of(context)!;
        final msg = authCubit.state.failure?.getLocalizedMessage(context) ??
            (_isSignUp ? l10n.signUpFailed : l10n.loginFailed);
        _showError(msg);
        return;
      }

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Terms of Service',
            style: TextStyle(color: Colors.black)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTermItem('Age Requirement',
                  'You must be at least 18 years old to use our services.'),
              _buildTermItem('Service Area',
                  'Currently available only in selected Egyptian cities.'),
              _buildTermItem('Payment Terms',
                  'All payments must be completed before or during the ride.'),
              _buildTermItem('Cancellation Policy',
                  'Free cancellation within 5 minutes of booking.'),
              _buildTermItem('Safety Guidelines',
                  'Both drivers and riders must follow safety protocols.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              setState(() => _agreedToTerms = true);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFFFB74D),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Accept & Continue',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermItem(String title, String description) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.black)),
          const SizedBox(height: 4),
          Text(description,
              style: const TextStyle(color: Colors.black54, fontSize: 14)),
          const Divider(height: 16, color: Colors.grey),
        ],
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFE53E3E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _toggleSignUp() => setState(() {
        _isSignUp = !_isSignUp;
        _confirmPasswordController.clear();
      });

  void _showForgotPassword() {
    final emailCtrl = TextEditingController(text: _emailController.text.trim());
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ForgotPasswordSheet(
        emailController: emailCtrl,
        onSend: (email) async {
          final authCubit = context.read<AuthCubit>();
          final l10n = AppLocalizations.of(context)!;
          final messenger = ScaffoldMessenger.of(context);
          final sent = await authCubit.forgotPassword(email);
          if (!ctx.mounted) return;
          Navigator.of(ctx).pop();
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                sent ? l10n.resetLinkSent : l10n.failedToSendResetEmail,
              ),
              backgroundColor:
                  sent ? const Color(0xFF10B981) : const Color(0xFFE53E3E),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        },
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final authCubit = context.read<AuthCubit>();
      await authCubit.signInWithGoogle();
      if (!mounted) return;

      // New Google user — register directly as customer (no role selection screen)
      if (authCubit.state.pendingGoogleUser != null) {
        final customerUser = authCubit.state.pendingGoogleUser!.copyWith(
          type: UserType.customer,
        );
        await authCubit.completeGoogleRegistration(customerUser);
        if (!mounted) return;
      }

      setState(() => _isLoading = false);
      if (!authCubit.state.isAuthenticated || authCubit.state.user == null) {
        throw Exception(
          authCubit.state.failure?.getLocalizedMessage(context) ??
              AppLocalizations.of(context)!.googleSignInFailed,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError(e.toString());
    }
  }

  Future<void> _signInWithApple() async {
    setState(() => _isLoading = true);
    try {
      await context.read<AuthCubit>().signInWithApple();
      if (!mounted) return;
      final authCubit = context.read<AuthCubit>();
      if (!authCubit.state.isAuthenticated || authCubit.state.user == null) {
        throw Exception(
          authCubit.state.failure?.getLocalizedMessage(context) ??
              'Apple sign-in failed',
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _signInWithPhone() {
    PhoneLoginSheet.show(
      context,
      onNewUser: () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) NameDialog.show(context);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Full-screen background image ──────────────────────────
          Image.asset(
            'assets/images/restaurant_bg.jpg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),

          // ── Gradient overlay: dark at top & bottom, lighter center
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.35, 0.65, 1.0],
                  colors: [
                    Colors.black.withValues(alpha: 0.75),
                    Colors.black.withValues(alpha: 0.45),
                    Colors.black.withValues(alpha: 0.45),
                    Colors.black.withValues(alpha: 0.80),
                  ],
                ),
              ),
            ),
          ),

          // ── Scrollable content ────────────────────────────────────
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isTablet = constraints.maxWidth >= 600;
                final horizontalPad =
                    isTablet ? (constraints.maxWidth - 480) / 2 : 24.0;
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: horizontalPad),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: isTablet ? 32 : 48),

                      // Logo + brand header
                      // SizedBox(height: isTablet ? 32 : 48), // Reduced space if header is removed
                      SizedBox(height: isTablet ? 16 : 24),

                      // ── Glass form card ───────────────────────────────
                      _GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Form title row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const SpeedLogo(size: LogoSize.md),
                                const SizedBox(width: 14),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _isSignUp
                                          ? AppLocalizations.of(context)!
                                              .createAccount
                                          : AppLocalizations.of(context)!
                                              .welcomeBack,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: -0.5,
                                        height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _isSignUp
                                          ? AppLocalizations.of(context)!
                                              .joinOurDeliveryService
                                          : AppLocalizations.of(context)!
                                              .loginToYourAccount,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color:
                                            Colors.white.withValues(alpha: 0.7),
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),

                            // ── Form fields ───────────────────────────
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  // Email
                                  LoginGlassField(
                                    controller: _emailController,
                                    labelText: AppLocalizations.of(context)!
                                        .emailAddress,
                                    hintText:
                                        AppLocalizations.of(context)!.emailHint,
                                    prefixIcon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (v) {
                                      if (v == null || v.isEmpty) {
                                        return AppLocalizations.of(context)!
                                            .pleaseEnterYourEmail;
                                      }
                                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                          .hasMatch(v)) {
                                        return AppLocalizations.of(context)!
                                            .pleaseEnterValidEmail;
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  // Password
                                  LoginGlassField(
                                    controller: _passwordController,
                                    labelText:
                                        AppLocalizations.of(context)!.password,
                                    hintText: AppLocalizations.of(context)!
                                        .enterYourPassword,
                                    prefixIcon: Icons.lock_outline,
                                    obscureText: !_isPasswordVisible,
                                    suffixIcon: IconButton(
                                      onPressed: () => setState(
                                        () => _isPasswordVisible =
                                            !_isPasswordVisible,
                                      ),
                                      icon: Icon(
                                        _isPasswordVisible
                                            ? Icons.visibility_rounded
                                            : Icons.visibility_off_rounded,
                                        color: Colors.white
                                            .withValues(alpha: 0.65),
                                        size: 20,
                                      ),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty) {
                                        return AppLocalizations.of(context)!
                                            .pleaseEnterYourPasswordValidation;
                                      }
                                      if (v.length < 6) {
                                        return AppLocalizations.of(context)!
                                            .passwordMinLength;
                                      }
                                      return null;
                                    },
                                  ),

                                  // Confirm password (sign up only)
                                  if (_isSignUp) ...[
                                    const SizedBox(height: 16),
                                    AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      child: LoginGlassField(
                                        key: const ValueKey('confirm'),
                                        controller: _confirmPasswordController,
                                        labelText: AppLocalizations.of(context)!
                                            .confirmPassword,
                                        hintText: AppLocalizations.of(context)!
                                            .confirmPassword,
                                        prefixIcon: Icons.lock_outline,
                                        obscureText: !_isPasswordVisible,
                                        validator: (v) {
                                          if (v == null || v.isEmpty) {
                                            return AppLocalizations.of(context)!
                                                .pleaseConfirmYourPassword;
                                          }
                                          if (v != _passwordController.text) {
                                            return AppLocalizations.of(context)!
                                                .passwordsDoNotMatch;
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Checkbox(
                                          value: _agreedToTerms,
                                          onChanged: (v) => setState(() =>
                                              _agreedToTerms = v ?? false),
                                          activeColor: const Color(0xFFFFB74D),
                                          checkColor: Colors.black,
                                          side: const BorderSide(
                                              color: Colors.white54),
                                        ),
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: _showTermsDialog,
                                            child: RichText(
                                              text: TextSpan(
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.white
                                                      .withValues(alpha: 0.75),
                                                ),
                                                children: const [
                                                  TextSpan(
                                                      text: 'I agree to the '),
                                                  TextSpan(
                                                    text: 'Terms of Service',
                                                    style: TextStyle(
                                                      color: Color(0xFFFFB74D),
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      decoration: TextDecoration
                                                          .underline,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // Remember me & Forgot password row
                            if (!_isSignUp) ...[
                              const SizedBox(height: 8),
                              kIsWeb
                                  ? Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        GestureDetector(
                                          onTap: () => setState(() => _rememberLogin = !_rememberLogin),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              SizedBox(
                                                height: 24,
                                                width: 24,
                                                child: Checkbox(
                                                  value: _rememberLogin,
                                                  onChanged: (v) => setState(() => _rememberLogin = v ?? false),
                                                  activeColor: const Color(0xFFFFB74D),
                                                  checkColor: Colors.black,
                                                  side: const BorderSide(color: Colors.white54),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                AppLocalizations.of(context)!.rememberMe,
                                                style: TextStyle(
                                                  color: Colors.white.withValues(alpha: 0.75),
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: _showForgotPassword,
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 4, vertical: 4),
                                            minimumSize: Size.zero,
                                            tapTargetSize:
                                                MaterialTapTargetSize.shrinkWrap,
                                          ),
                                          child: Text(
                                            AppLocalizations.of(context)!
                                                .forgotPassword,
                                            style: TextStyle(
                                              color:
                                                  Colors.white.withValues(alpha: 0.75),
                                              fontWeight: FontWeight.w500,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Align(
                                      alignment: AlignmentDirectional.centerEnd,
                                      child: TextButton(
                                        onPressed: _showForgotPassword,
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 4, vertical: 4),
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text(
                                          AppLocalizations.of(context)!
                                              .forgotPassword,
                                          style: TextStyle(
                                            color:
                                                Colors.white.withValues(alpha: 0.75),
                                            fontWeight: FontWeight.w500,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ),
                            ],
                            const SizedBox(height: 20),

                            // Main CTA button
                            LoginButton(
                              isLoading: _isLoading,
                              isSignUp: _isSignUp,
                              onPressed: _submit,
                            ),

                            const SizedBox(height: 24),
                            const LoginOrDivider(),
                            const SizedBox(height: 20),

                            // Social login buttons
                            Row(
                              children: [
                                Expanded(
                                  child: LoginSocialButton(
                                    label: AppLocalizations.of(context)!.google,
                                    imagePath: 'assets/images/google_logo.png',
                                    color: const Color(0xFFEA4335),
                                    onPressed: _signInWithGoogle,
                                  ),
                                ),
                                if (!kIsWeb && Platform.isIOS) ...[
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: LoginSocialButton(
                                      label: 'Apple',
                                      icon: Icons.apple,
                                      color: Colors.white,
                                      onPressed: _signInWithApple,
                                    ),
                                  ),
                                ],
                                const SizedBox(width: 8),
                                Expanded(
                                  child: LoginSocialButton(
                                    label: AppLocalizations.of(context)!.phone,
                                    icon: Icons.phone_rounded,
                                    color: const Color(0xFFFF9800),
                                    onPressed: _signInWithPhone,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),
                            LoginToggleRow(
                              isSignUp: _isSignUp,
                              onToggle: _toggleSignUp,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Sign-up extra content
                      if (_isSignUp) ...[
                        const SizedBox(height: 20),
                        Text(
                          AppLocalizations.of(context)!.bySigningUp,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        const PartnerLinksWidget(),
                      ],

                      const SizedBox(height: 32),
                    ],
                  ),
                );
              },
            ),
          ),

          // Language switcher overlay (always on top)
          const LanguageSwitcherOverlay(),

          // Glassmorphic back button if pushed (pop-able)
          if (Navigator.of(context).canPop())
            Positioned(
              top: MediaQuery.paddingOf(context).top + 16,
              left: 20,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Glass card container ───────────────────────────────────────────────────

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.22),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 40,
                spreadRadius: -5,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
          child: child,
        ),
      ),
    );
  }
}

// ── Forgot password bottom sheet ────────────────────────────────────────

class _ForgotPasswordSheet extends StatefulWidget {
  const _ForgotPasswordSheet({
    required this.emailController,
    required this.onSend,
  });

  final TextEditingController emailController;
  final Future<void> Function(String email) onSend;

  @override
  State<_ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<_ForgotPasswordSheet> {
  bool _isSending = false;
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withValues(alpha: 0.95),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    AppLocalizations.of(context)!.resetPassword,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppLocalizations.of(context)!.resetPasswordInstructions,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),

                  LoginGlassField(
                    controller: widget.emailController,
                    labelText: AppLocalizations.of(context)!.emailAddress,
                    hintText: AppLocalizations.of(context)!.emailHint,
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return AppLocalizations.of(context)!
                            .pleaseEnterYourEmail;
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                        return AppLocalizations.of(context)!
                            .pleaseEnterValidEmail;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF35535), Color(0xFFFF9800)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFFF35535).withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _isSending
                              ? null
                              : () async {
                                  if (!_formKey.currentState!.validate()) {
                                    return;
                                  }
                                  setState(() => _isSending = true);
                                  await widget.onSend(
                                    widget.emailController.text.trim(),
                                  );
                                  if (mounted) {
                                    setState(() => _isSending = false);
                                  }
                                },
                          borderRadius: BorderRadius.circular(14),
                          child: Center(
                            child: _isSending
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : Text(
                                    AppLocalizations.of(context)!.sendResetLink,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
