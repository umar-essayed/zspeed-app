import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:z_speed/features/auth/cubit/auth_cubit.dart';
import 'package:z_speed/l10n/app_localizations.dart';

/// Dialog shown after a customer signs up with email/password.
///
/// Sends a 6-digit OTP via the `sendEmailOTP` cloud function and verifies
/// it via `verifyEmailOTP`. This matches the driver/restaurant flow.
class EmailVerificationDialog extends StatefulWidget {
  final String? email;
  final VoidCallback? onVerified;

  /// When false (default), `sendEmailOTP` checks Firebase Auth for an existing
  /// account and shows "already registered" if found — use this in
  /// pre-registration flows. Set to true for post-registration flows where the
  /// account already exists (e.g. customer email verification after sign-up).
  final bool skipExistingCheck;

  const EmailVerificationDialog({
    super.key,
    this.email,
    this.onVerified,
    this.skipExistingCheck = true,
  });

  /// Show the dialog. Returns `true` if email was verified, `false`/null if skipped.
  static Future<bool?> show(
    BuildContext context, {
    String? email,
    VoidCallback? onVerified,
    bool skipExistingCheck = true,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => EmailVerificationDialog(
        email: email,
        onVerified: onVerified,
        skipExistingCheck: skipExistingCheck,
      ),
    );
  }

  @override
  State<EmailVerificationDialog> createState() =>
      _EmailVerificationDialogState();
}

class _EmailVerificationDialogState extends State<EmailVerificationDialog> {
  bool _codeSent = false;
  bool _sending = false;
  bool _verifying = false;
  bool _verified = false;
  String? _error;

  final _codeController = TextEditingController();
  Timer? _resendTimer;
  int _resendCooldown = 0;

  @override
  void initState() {
    super.initState();
    _sendCode();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  String get _email {
    if (widget.email != null && widget.email!.isNotEmpty) {
      return widget.email!;
    }
    final authCubit = context.read<AuthCubit>();
    return authCubit.state.user?.email ?? '';
  }

  Future<void> _sendCode() async {
    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      final callable = FirebaseFunctions.instance.httpsCallable('sendEmailOTP');
      await callable.call(
          {'email': _email, 'skipExistingCheck': widget.skipExistingCheck});

      if (!mounted) return;
      setState(() {
        _sending = false;
        _codeSent = true;
      });
      _startResendCooldown();
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      debugPrint('sendEmailOTP error: [${e.code}] ${e.message} ${e.details}');
      setState(() {
        _sending = false;
        // If it's a configuration, internal, or SMTP failure, show a helpful message
        if (e.code == 'internal' ||
            e.code == 'failed-precondition' ||
            e.message == 'INTERNAL' ||
            e.message == null) {
          _error = (e.message != null && e.message != 'INTERNAL')
              ? e.message!
              : 'Server email verification service is not configured (SMTP credentials missing). Please contact support.';
        } else {
          _error = e.message ??
              AppLocalizations.of(context)!.failedToSendVerificationCode;
        }
      });
    } catch (e) {
      if (!mounted) return;
      debugPrint('sendEmailOTP generic error: $e');
      setState(() {
        _sending = false;
        _error =
            AppLocalizations.of(context)!.failedToSendVerificationCodeRetry;
      });
    }
  }

  void _startResendCooldown() {
    _resendCooldown = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _resendCooldown--);
      if (_resendCooldown <= 0) timer.cancel();
    });
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(
          () => _error = AppLocalizations.of(context)!.pleaseEnterSixDigitCode);
      return;
    }

    setState(() {
      _verifying = true;
      _error = null;
    });

    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('verifyEmailOTP');
      await callable.call({'email': _email, 'code': code});

      if (!mounted) return;
      setState(() {
        _verifying = false;
        _verified = true;
      });
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        widget.onVerified?.call();
        Navigator.of(context).pop(true);
      }
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      debugPrint('verifyEmailOTP error: [${e.code}] ${e.message}');
      setState(() {
        _verifying = false;
        _error = e.message ?? AppLocalizations.of(context)!.invalidCodeError;
      });
    } catch (e) {
      if (!mounted) return;
      debugPrint('verifyEmailOTP generic error: $e');
      setState(() {
        _verifying = false;
        _error = AppLocalizations.of(context)!.verificationFailedRetry;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const brandOrange = Color(0xFFF35535);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: _verified
                  ? Container(
                      key: const ValueKey('verified'),
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F5E9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Color(0xFF4CAF50),
                        size: 36,
                      ),
                    )
                  : Container(
                      key: const ValueKey('pending'),
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: brandOrange.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.mark_email_read_outlined,
                        color: brandOrange,
                        size: 32,
                      ),
                    ),
            ),
            const SizedBox(height: 16),

            Text(
              _verified
                  ? AppLocalizations.of(context)!.emailVerified
                  : AppLocalizations.of(context)!.verifyYourEmail,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _verified
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 8),

            if (!_verified) ...[
              Text(
                AppLocalizations.of(context)!.sentSixDigitCodeTo,
                style: const TextStyle(fontSize: 13, color: Color(0xFF718096)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                _email,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3748),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // 6-digit code input
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 12,
                  color: Color(0xFF2D3748),
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '------',
                  hintStyle: TextStyle(
                    fontSize: 28,
                    letterSpacing: 12,
                    color: Colors.grey[300],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: brandOrange, width: 2),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ] else ...[
              Text(
                AppLocalizations.of(context)!.emailVerifiedSuccessfully,
                style: const TextStyle(fontSize: 13, color: Color(0xFF4CAF50)),
                textAlign: TextAlign.center,
              ),
            ],

            // Error
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3F3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        size: 16, color: Color(0xFFD32F2F)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFD32F2F),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            if (!_verified) ...[
              // Verify button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: (_verifying || !_codeSent) ? null : _verifyCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: Colors.grey[300],
                  ),
                  child: _verifying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          AppLocalizations.of(context)!.verifyCode,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),

              // Resend button
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  onPressed:
                      (_sending || _resendCooldown > 0) ? null : _sendCode,
                  icon: _sending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh, size: 18),
                  label: Text(
                    _sending
                        ? AppLocalizations.of(context)!.sending
                        : _resendCooldown > 0
                            ? AppLocalizations.of(context)!
                                .resendInSeconds(_resendCooldown)
                            : AppLocalizations.of(context)!.resendCode2,
                    style: const TextStyle(fontSize: 14),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: brandOrange,
                    side: const BorderSide(color: brandOrange),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
