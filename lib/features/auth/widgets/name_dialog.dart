import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:z_speed/features/auth/cubit/auth_cubit.dart';
import 'package:z_speed/core/errors/failure_localization_ext.dart';
import 'package:z_speed/l10n/app_localizations.dart';

/// Dialog shown after phone-based signup (or any auth method that
/// results in an empty name).
///
/// Forces the customer to enter their full name before continuing.
class NameDialog extends StatefulWidget {
  const NameDialog({super.key});

  /// Show the dialog and return `true` when name is saved.
  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const NameDialog(),
    );
  }

  @override
  State<NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<NameDialog> {
  final _nameCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final authCubit = context.read<AuthCubit>();
      await authCubit.updateUserName(_nameCtrl.text.trim());

      if (!mounted) return;

      if (!authCubit.state.hasError) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _error = authCubit.state.failure?.getLocalizedMessage(context) ??
              AppLocalizations.of(context)!.failedToSaveName;
          _saving = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = AppLocalizations.of(context)!.somethingWentWrong;
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFF35535).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_outline,
                color: Color(0xFFF35535),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              AppLocalizations.of(context)!.enterName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              AppLocalizations.of(context)!.weNeedYourName,
              style: const TextStyle(fontSize: 13, color: Color(0xFF718096)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            Form(
              key: _formKey,
              child: TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                autofocus: true,
                style: const TextStyle(fontSize: 16, color: Color(0xFF2D3748)),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.fullName,
                  hintText: AppLocalizations.of(context)!.fullNameHint,
                  prefixIcon: const Icon(Icons.badge_outlined, size: 20),
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
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return AppLocalizations.of(context)!.fullNameRequired;
                  }
                  if (v.trim().length < 2) {
                    return AppLocalizations.of(context)!.nameTooShort;
                  }
                  return null;
                },
              ),
            ),

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

            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFF35535),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        AppLocalizations.of(context)!.continueButton,
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
