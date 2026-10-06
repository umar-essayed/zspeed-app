import 'package:z_speed/core/utils/phone_helper.dart';
import 'package:z_speed/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:z_speed/features/auth/cubit/auth_cubit.dart';

/// Dialog prompting an email-signup customer to verify their phone number.
///
/// Shown post-login when customer needs phone.
/// TEMP: Skip is re-enabled until Play Integrity is fixed in Firebase Console.
class PhoneVerificationDialog extends StatefulWidget {
  const PhoneVerificationDialog({super.key});

  /// Show the dialog. Returns `true` if the phone was verified, `false`/null if skipped.
  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PhoneVerificationDialog(),
    );
  }

  @override
  State<PhoneVerificationDialog> createState() =>
      _PhoneVerificationDialogState();
}

class _PhoneVerificationDialogState extends State<PhoneVerificationDialog> {
  final _phoneCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();

  bool _codeSent = false;
  bool _sending = false;
  bool _verifying = false;
  String? _error;

  dynamic _webConfirmation;
  String? _verificationId;
  int? _resendToken;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  // ── Phone normalization ───────────────────────────────────────────────────

  /// Normalizes Egyptian local format to E.164: 01XXXXXXXX → +201XXXXXXXX.
  String _normalizePhone(String phone) {
    return PhoneHelper.normalizePhone(phone);
  }

  Future<void> _sendCode() async {
    final l10n = AppLocalizations.of(context)!;
    final phone = _normalizePhone(_phoneCtrl.text);
    if (phone.isEmpty || !PhoneHelper.isValidEgyptianPhone(phone)) {
      setState(() => _error = l10n.enterValidPhoneNumber);
      return;
    }

    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      if (kIsWeb) {
        // On web, use signInWithPhoneNumber just for verification.
        // We'll link the phone or just store it after code confirmation.
        final confirmation =
            await FirebaseAuth.instance.signInWithPhoneNumber(phone);
        if (mounted) {
          setState(() {
            _webConfirmation = confirmation;
            _codeSent = true;
            _sending = false;
          });
        }
      } else {
        await FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: phone,
          forceResendingToken: _resendToken,
          timeout: const Duration(seconds: 60),
          verificationCompleted: (PhoneAuthCredential credential) async {
            // Auto-verified on Android
            if (!mounted) return;
            await _completeVerification();
          },
          verificationFailed: (FirebaseAuthException e) {
            if (mounted) {
              setState(() {
                _error = _mapError(e);
                _sending = false;
              });
            }
          },
          codeSent: (String vid, int? token) {
            if (mounted) {
              setState(() {
                _verificationId = vid;
                _resendToken = token;
                _codeSent = true;
                _sending = false;
              });
            }
          },
          codeAutoRetrievalTimeout: (String vid) {
            _verificationId = vid;
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = l10n.failedToSendVerificationCodeRetry;
          _sending = false;
        });
      }
    }
  }

  String _mapError(FirebaseAuthException e) {
    final l10n = AppLocalizations.of(context)!;
    switch (e.code) {
      case 'invalid-verification-code':
        return l10n.invalidCodeError;
      case 'session-expired':
        return l10n.sessionExpired;
      case 'too-many-requests':
        return l10n.tooManyRequests;
      case 'invalid-phone-number':
        return l10n.invalidPhoneNumber;
      case 'invalid-app-credential':
        return l10n.invalidAppCredential;
      default:
        return e.message ?? l10n.verificationFailedRetry;
    }
  }

  Future<void> _verifyCode() async {
    final l10n = AppLocalizations.of(context)!;
    final code = _codeCtrl.text.trim();
    if (code.length != 6) {
      setState(() => _error = l10n.pleaseEnterSixDigitCode);
      return;
    }

    setState(() {
      _verifying = true;
      _error = null;
    });

    try {
      if (kIsWeb && _webConfirmation != null) {
        // On web, confirm but we just need to verify it's the user's phone;
        // we don't want to swap auth accounts.
        final confirmResult = _webConfirmation as ConfirmationResult;
        await confirmResult.confirm(code);
        // Phone verified — save the phone number to user profile
        await _completeVerification();
      } else if (_verificationId != null) {
        // Mobile: create credential and verify
        final credential = PhoneAuthProvider.credential(
          verificationId: _verificationId!,
          smsCode: code,
        );
        // Link phone to existing account
        try {
          await FirebaseAuth.instance.currentUser
              ?.linkWithCredential(credential);
        } catch (e) {
          // If already linked or account exists, that's OK — phone is still verified
          final msg = e.toString().toLowerCase();
          if (!msg.contains('already') &&
              !msg.contains('credential-already-in-use')) {
            rethrow;
          }
        }
        await _completeVerification();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = AppLocalizations.of(context)!.verificationFailedRetry;
          _verifying = false;
        });
      }
    }
  }

  Future<void> _completeVerification() async {
    final phone = _normalizePhone(_phoneCtrl.text);
    final authCubit = context.read<AuthCubit>();
    await authCubit.updateUserPhone(phone);
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.phone_android,
                color: Color(0xFF4CAF50),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              AppLocalizations.of(context)!.verifyPhoneTitle,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              AppLocalizations.of(context)!.verifyPhoneSubtitle,
              style: const TextStyle(fontSize: 13, color: Color(0xFF718096)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            if (!_codeSent) ...[
              // Phone input
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                style: const TextStyle(fontSize: 16, color: Color(0xFF2D3748)),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.phoneNum,
                  hintText: AppLocalizations.of(context)!.phoneHint,
                  prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFF4CAF50), width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ] else ...[
              // Show phone + change link
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.phone, size: 18, color: Color(0xFF718096)),
                    const SizedBox(width: 10),
                    Text(
                      _phoneCtrl.text,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => setState(() {
                        _codeSent = false;
                        _codeCtrl.clear();
                        _error = null;
                      }),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.change,
                        style: const TextStyle(
                          color: Color(0xFF4CAF50),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Code input
              TextFormField(
                controller: _codeCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 8,
                  color: Color(0xFF2D3748),
                ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: '------',
                  hintStyle: TextStyle(
                    color: Colors.grey[300],
                    letterSpacing: 8,
                    fontSize: 20,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFF4CAF50), width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  counterText: '',
                ),
                maxLength: 6,
              ),
              const SizedBox(height: 4),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: _sending ? null : _sendCode,
                  child: Text(
                    AppLocalizations.of(context)!.resendCode2,
                    style: TextStyle(
                      color: _sending ? Colors.grey : const Color(0xFF4CAF50),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],

            // Error
            if (_error != null) ...[
              const SizedBox(height: 8),
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

            // Action button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: (_sending || _verifying)
                    ? null
                    : _codeSent
                        ? _verifyCode
                        : _sendCode,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: (_sending || _verifying)
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _codeSent
                            ? AppLocalizations.of(context)!.verifyPhone
                            : AppLocalizations.of(context)!.sendCode,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 12),

            // TEMP: Skip / Later button — re-enabled until Play Integrity is fixed.
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                AppLocalizations.of(context)!.illDoThisLater,
                style: const TextStyle(
                  color: Color(0xFF718096),
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
