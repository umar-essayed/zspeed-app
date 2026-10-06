import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:z_speed/l10n/app_localizations.dart';
import 'package:z_speed/features/restaurant_owner/widgets/restaurant_form_styles.dart';
import 'package:z_speed/features/restaurant_owner/widgets/restaurant_form_widgets.dart';

/// Custom TextInputFormatter that auto-spaces IBAN every 4 characters.
class _IbanFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '').toUpperCase();
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(text[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Step 6: Bank / Payment Information
///
/// Collects: bank name, account holder name, IBAN.
class BankInfoStep extends StatelessWidget {
  final TextEditingController bankNameController;
  final TextEditingController accountHolderController;
  final TextEditingController ibanController;
  final GlobalKey<FormState> formKey;

  const BankInfoStep({
    super.key,
    required this.bankNameController,
    required this.accountHolderController,
    required this.ibanController,
    required this.formKey,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(RestaurantFormStyles.horizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RestaurantFormSectionHeader(
              title: AppLocalizations.of(context)!.bankAccountDetails,
              subtitle: AppLocalizations.of(context)!.payoutInfoDesc,
              icon: Icons.account_balance_outlined,
            ),

            // Bank Name
            TextFormField(
              controller: bankNameController,
              decoration: RestaurantFormStyles.inputDecoration(
                label: AppLocalizations.of(context)!.bankName,
                hint: AppLocalizations.of(context)!.bankNameHint,
                prefixIcon: Icons.account_balance_outlined,
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return AppLocalizations.of(context)!.bankNameRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: RestaurantFormStyles.verticalSpacing),

            // Account Holder
            TextFormField(
              controller: accountHolderController,
              decoration: RestaurantFormStyles.inputDecoration(
                label: AppLocalizations.of(context)!.accountHolderName,
                hint: AppLocalizations.of(context)!.accountHolderNameHint,
                prefixIcon: Icons.person_outline,
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return AppLocalizations.of(context)!
                      .accountHolderNameRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: RestaurantFormStyles.verticalSpacing),

            // IBAN
            TextFormField(
              controller: ibanController,
              decoration: RestaurantFormStyles.inputDecoration(
                label: AppLocalizations.of(context)!.iban,
                hint: AppLocalizations.of(context)!.ibanHint,
                prefixIcon: Icons.numbers_outlined,
              ),
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9 ]')),
                _IbanFormatter(),
              ],
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return AppLocalizations.of(context)!.ibanRequired;
                }
                final cleaned = v.replaceAll(' ', '');
                if (!cleaned.toUpperCase().startsWith('EG')) {
                  return AppLocalizations.of(context)!.ibanMustStartWithEG;
                }
                if (cleaned.length < 15 || cleaned.length > 34) {
                  return AppLocalizations.of(context)!
                      .ibanLengthValidation(cleaned.length);
                }
                return null;
              },
            ),
            const SizedBox(height: RestaurantFormStyles.sectionSpacing),

            // Info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.security_outlined,
                      color: Colors.blue, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.bankSecurityNote,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppLocalizations.of(context)!.bankSecurityDesc,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
