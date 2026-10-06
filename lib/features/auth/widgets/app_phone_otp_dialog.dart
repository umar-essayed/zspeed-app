import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:z_speed/core/utils/phone_helper.dart';
import 'package:z_speed/l10n/app_localizations.dart';

/// OTP dialog for verifying a phone number during vendor/driver application.
///
/// Sends SMS via [FirebaseAuth.verifyPhoneNumber] (native mobile path — no
/// reCAPTCHA web redirect when device attestation is properly configured).
///
/// Verification avoids creating a persistent session:
/// - No current user  → signs in to confirm the OTP, deletes the temp user if
///   the phone is new, or shows "already registered" if the phone exists.
/// - Current user present → links the credential to verify, then immediately
///   unlinks it; throws "already registered" on `credential-already-in-use`.
class AppPhoneOtpDialog extends StatefulWidget {
  final String phone;
  final VoidCallback? onVerified;

  const AppPhoneOtpDialog({
    super.key,
    required this.phone,
    this.onVerified,
  });

  /// Show the dialog. Returns `true` if verified, `false`/null if skipped.
  static Future<bool?> show(
    BuildContext context, {
    required String phone,
    VoidCallback? onVerified,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AppPhoneOtpDialog(phone: phone, onVerified: onVerified),
    );
  }

  @override
  State<AppPhoneOtpDialog> createState() => _AppPhoneOtpDialogState();
}

class _AppPhoneOtpDialogState extends State<AppPhoneOtpDialog> {
  bool _codeSent = false;
  bool _sending = false;
  bool _verifying = false;
  bool _verified = false;
  String? _error;

  String? _verificationId;
  int? _resendToken;

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

  // ── Phone normalization ───────────────────────────────────────────────────

  /// Normalizes Egyptian local format to E.164: 01XXXXXXXX → +201XXXXXXXX.
  String _normalizePhone(String phone) {
    return PhoneHelper.normalizePhone(phone);
  }

  // ── Send SMS ──────────────────────────────────────────────────────────────

  Future<void> _sendCode() async {
    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      final normalized = _normalizePhone(widget.phone);

      // Query Firestore to see if this phone number is already registered
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: normalized)
          .get();

      if (query.docs.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          _sending = false;
          _error = AppLocalizations.of(context)!.phoneAlreadyRegistered;
        });
        return;
      }

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: normalized,
        forceResendingToken: _resendToken,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verified on Android (Play Integrity / silent push)
          await _verifyCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          if (!mounted) return;
          setState(() {
            _sending = false;
            _error = _mapError(e);
          });
        },
        codeSent: (String vid, int? token) {
          if (!mounted) return;
          setState(() {
            _verificationId = vid;
            _resendToken = token;
            _codeSent = true;
            _sending = false;
          });
          _startResendCooldown();
        },
        codeAutoRetrievalTimeout: (String vid) {
          _verificationId = vid;
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = 'Error sending verification code: $e';
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

  // ── Verify OTP ────────────────────────────────────────────────────────────

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(
          () => _error = AppLocalizations.of(context)!.pleaseEnterSixDigitCode);
      return;
    }
    if (_verificationId == null) {
      setState(() =>
          _error = AppLocalizations.of(context)!.failedToSendVerificationCode);
      return;
    }

    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: code,
    );
    await _verifyCredential(credential);
  }

  Future<void> _verifyCredential(PhoneAuthCredential credential) async {
    if (!mounted) return;
    setState(() {
      _verifying = true;
      _error = null;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        // ── Already logged in → link to verify, immediately unlink ──────────
        await currentUser.linkWithCredential(credential);
        await currentUser.unlink(PhoneAuthProvider.PROVIDER_ID);
      } else {
        // ── Not logged in → sign in to verify the code ───────────────────────
        final result =
            await FirebaseAuth.instance.signInWithCredential(credential);
        if (result.additionalUserInfo?.isNewUser == false) {
          // Phone is already registered under a different account
          await FirebaseAuth.instance.signOut();
          if (!mounted) return;
          setState(() {
            _verifying = false;
            _error = AppLocalizations.of(context)!.phoneAlreadyRegistered;
          });
          return;
        }
        // Brand-new phone — delete the temp Firebase user we just created
        await result.user?.delete();
      }

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
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      if (e.code == 'credential-already-in-use' ||
          e.code == 'account-exists-with-different-credential') {
        setState(() {
          _verifying = false;
          _error = AppLocalizations.of(context)!.phoneAlreadyRegistered;
        });
      } else {
        setState(() {
          _verifying = false;
          _error = _mapError(e);
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _error = AppLocalizations.of(context)!.verificationFailedRetry;
      });
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
      default:
        return e.message ?? l10n.verificationFailedRetry;
    }
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    const brandOrange = Color(0xFFF35535);
    final l10n = AppLocalizations.of(context)!;

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
                      child: const Icon(Icons.check_circle,
                          color: Color(0xFF4CAF50), size: 36),
                    )
                  : Container(
                      key: const ValueKey('pending'),
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: brandOrange.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.phone_android_outlined,
                          color: brandOrange, size: 32),
                    ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              _verified ? l10n.phoneVerified : l10n.verifyYourPhone,
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
              if (_sending && !_codeSent)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: brandOrange),
                    ),
                    const SizedBox(width: 8),
                    Text(l10n.sending,
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF718096))),
                  ],
                )
              else ...[
                Text(
                  l10n.sentSixDigitCodeTo,
                  style:
                      const TextStyle(fontSize: 13, color: Color(0xFF718096)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.phone,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
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
                      fontSize: 28, letterSpacing: 12, color: Colors.grey[300]),
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
                l10n.phoneVerifiedSuccessfully,
                style: const TextStyle(fontSize: 13, color: Color(0xFF4CAF50)),
                textAlign: TextAlign.center,
              ),
            ],

            // Error banner
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
                            fontSize: 12, color: Color(0xFFD32F2F)),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            if (!_verified) ...[
              // Verify Code button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: (_verifying || !_codeSent) ? null : _verifyCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    disabledBackgroundColor: Colors.grey[300],
                  ),
                  child: _verifying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          l10n.verifyCode,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
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
                        ? l10n.sending
                        : _resendCooldown > 0
                            ? l10n.resendInSeconds(_resendCooldown)
                            : l10n.resendCode2,
                    style: const TextStyle(fontSize: 14),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: brandOrange,
                    side: const BorderSide(color: brandOrange),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}
