import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:z_speed/core/utils/phone_helper.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:z_speed/core/injection.dart';
import 'package:z_speed/features/admin/datasource/settings_datasource.dart';
import 'package:z_speed/features/auth/cubit/auth_cubit.dart';
import 'package:z_speed/core/errors/failure_localization_ext.dart';
import 'package:z_speed/l10n/app_localizations.dart';

/// Bottom-sheet flow for "Sign in with Phone Number".
///
/// Step 1: Enter phone number → sends OTP
/// Step 2: Enter 6-digit SMS code → signs in / creates account
///
/// After successful sign-in, if this is a new user (name is empty),
/// the [onNewUser] callback is invoked so the parent can show
/// a name dialog.
class PhoneLoginSheet extends StatefulWidget {
  final VoidCallback? onNewUser;

  const PhoneLoginSheet({super.key, this.onNewUser});

  /// Show the sheet as a modal bottom sheet.
  static Future<void> show(BuildContext context, {VoidCallback? onNewUser}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PhoneLoginSheet(onNewUser: onNewUser),
    );
  }

  @override
  State<PhoneLoginSheet> createState() => _PhoneLoginSheetState();
}

class _PhoneLoginSheetState extends State<PhoneLoginSheet> {
  final _phoneCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();

  bool _codeSent = false;
  bool _sending = false;
  bool _verifying = false;
  String? _error;

  // web confirmation result
  dynamic _webConfirmation;
  // mobile verification id
  String? _verificationId;
  int? _resendToken;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final phone = PhoneHelper.normalizePhone(_phoneCtrl.text);
    if (!PhoneHelper.isValidEgyptianPhone(phone)) {
      setState(
          () => _error = AppLocalizations.of(context)!.enterValidPhoneNumber);
      return;
    }

    setState(() {
      _sending = true;
      _error = null;
    });

    final authCubit = context.read<AuthCubit>();
    try {
      final isBlocked =
          await getIt<SettingsDatasource>().isBlacklisted(phone: phone);
      if (isBlocked) {
        if (mounted) {
          setState(() {
            _error = AppLocalizations.of(context)!.phoneBlacklistedError;
            _sending = false;
          });
        }
        return;
      }
      if (kIsWeb) {
        final confirmation = await authCubit.signInWithPhoneWeb(phone);
        if (mounted && confirmation != null) {
          setState(() {
            _webConfirmation = confirmation;
            _codeSent = true;
            _sending = false;
          });
        } else if (mounted) {
          setState(() {
            _error = authCubit.state.failure?.getLocalizedMessage(context) ??
                AppLocalizations.of(context)!.failedToSendCode;
            _sending = false;
          });
        }
      } else {
        // Mobile
        await FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: phone,
          forceResendingToken: _resendToken,
          timeout: const Duration(seconds: 60),
          verificationCompleted: (PhoneAuthCredential credential) async {
            // Auto-resolved on Android
            if (!mounted) return;
            setState(() => _verifying = true);
            try {
              final authCubit = context.read<AuthCubit>();
              await authCubit.confirmPhoneCodeMobile(
                verificationId: credential.verificationId!,
                smsCode: credential.smsCode!,
              );
              if (mounted) _onSuccess();
            } catch (e) {
              if (mounted) {
                setState(() {
                  _error = AppLocalizations.of(context)!.autoVerificationFailed;
                  _verifying = false;
                });
              }
            }
          },
          verificationFailed: (FirebaseAuthException e) {
            if (mounted) {
              setState(() {
                _error =
                    e.message ?? AppLocalizations.of(context)!.failedToSendSms;
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
          _error = AppLocalizations.of(context)!.failedToSendSms;
          _sending = false;
        });
      }
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeCtrl.text.trim();
    if (code.length != 6) {
      setState(() => _error = AppLocalizations.of(context)!.enterSixDigitCode);
      return;
    }

    setState(() {
      _verifying = true;
      _error = null;
    });

    try {
      final authCubit = context.read<AuthCubit>();

      if (kIsWeb && _webConfirmation != null) {
        await authCubit.confirmPhoneCodeWeb(_webConfirmation, code);
      } else if (_verificationId != null) {
        await authCubit.confirmPhoneCodeMobile(
          verificationId: _verificationId!,
          smsCode: code,
        );
      }

      if (mounted) {
        if (!authCubit.state.hasError && authCubit.state.isAuthenticated) {
          _onSuccess();
        } else {
          setState(() {
            _error = authCubit.state.failure?.getLocalizedMessage(context) ??
                AppLocalizations.of(context)!.verificationFailed;
            _verifying = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = AppLocalizations.of(context)!.invalidCode;
          _verifying = false;
        });
      }
    }
  }

  void _onSuccess() {
    final authCubit = context.read<AuthCubit>();
    Navigator.of(context).pop(); // close sheet
    if (authCubit.state.user?.name.isEmpty ?? false) {
      widget.onNewUser?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsetsDirectional.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsetsDirectional.fromSTEB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF35535).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.phone_outlined,
                    color: Color(0xFFF35535),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.signInWithPhone,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppLocalizations.of(context)!.phoneVerificationSmsHint,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF718096),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Phone input
            if (!_codeSent) ...[
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                style: const TextStyle(fontSize: 16, color: Color(0xFF2D3748)),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.phoneNumberLabel,
                  hintText: '+20 1XX XXX XXXX',
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
                        const BorderSide(color: Color(0xFFF35535), width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ] else ...[
              // Display phone number (read-only)
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
                          color: Color(0xFFF35535),
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
                        const BorderSide(color: Color(0xFFF35535), width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  counterText: '',
                ),
                maxLength: 6,
              ),
              const SizedBox(height: 8),
              // Resend link
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: _sending ? null : _sendCode,
                  child: Text(
                    AppLocalizations.of(context)!.resendCode2,
                    style: TextStyle(
                      color: _sending ? Colors.grey : const Color(0xFFF35535),
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
              height: 50,
              child: FilledButton(
                onPressed: (_sending || _verifying)
                    ? null
                    : _codeSent
                        ? _verifyCode
                        : _sendCode,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFF35535),
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
                            ? AppLocalizations.of(context)!.verifyAndSignIn
                            : AppLocalizations.of(context)!
                                .sendVerificationCode,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
