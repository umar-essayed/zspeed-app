import 'package:flutter/material.dart';
import 'package:z_speed/features/restaurant_owner/utils/order_receipt_labels.dart';
import 'package:z_speed/l10n/app_localizations.dart';

Future<ReceiptPrintLanguage?> showReceiptPrintLanguageDialog(
  BuildContext context,
) {
  final l10n = AppLocalizations.of(context)!;

  return showDialog<ReceiptPrintLanguage>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.orderReceipt),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.receipt_long_outlined),
            title: Text(l10n.english),
            onTap: () =>
                Navigator.of(dialogContext).pop(ReceiptPrintLanguage.en),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.receipt_long_outlined),
            title: Text(l10n.arabicLanguage),
            onTap: () =>
                Navigator.of(dialogContext).pop(ReceiptPrintLanguage.ar),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(l10n.cancel),
        ),
      ],
    ),
  );
}
