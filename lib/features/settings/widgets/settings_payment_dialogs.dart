import 'package:z_speed/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:z_speed/features/settings/widgets/add_card_dialog.dart';
import 'package:z_speed/features/settings/widgets/add_wallet_dialog.dart';
import 'package:z_speed/features/settings/widgets/payment_method_model.dart';

/// Extracted payment-method dialogs from SettingsPage.
///
/// Usage:
///   SettingsPaymentDialogs.showPaymentMethods(
///     context: context,
///     walletMethods: walletMethods,
///     onWalletMethodsChanged: (methods) => setState(() => walletMethods = methods),
///     showSnackBar: _showSnackBar,
///   );
class SettingsPaymentDialogs {
  SettingsPaymentDialogs._();

  /// Shows the main payment-methods dialog.
  static void showPaymentMethods({
    required BuildContext context,
    required List<PaymentMethod> walletMethods,
    required ValueChanged<List<PaymentMethod>> onWalletMethodsChanged,
    required void Function(String message, {Color color}) showSnackBar,
  }) {
    final List<PaymentMethod> paymentMethods = [
      PaymentMethod(
          id: 'cash', type: 'Cash', last4: 'COD', expDate: '', isDefault: true),
    ];
    paymentMethods.addAll(walletMethods);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(AppLocalizations.of(context)!.paymentMethods,
                style: const TextStyle(color: Colors.black)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...paymentMethods.map((method) => _buildPaymentMethodTile(
                        context: context,
                        method: method,
                        localSetState: setState,
                        walletMethods: walletMethods,
                        onWalletMethodsChanged: onWalletMethodsChanged,
                        showSnackBar: showSnackBar,
                      )),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showAddPaymentMethod(
                      context: context,
                      walletMethods: walletMethods,
                      onWalletMethodsChanged: onWalletMethodsChanged,
                      showSnackBar: showSnackBar,
                    ),
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: Text(
                        AppLocalizations.of(context)!.addNewPaymentMethod,
                        style: const TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF35535),
                        foregroundColor: Colors.white),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.close,
                    style: const TextStyle(color: Colors.black54)),
              ),
            ],
          );
        },
      ),
    );
  }

  static Widget _buildPaymentMethodTile({
    required BuildContext context,
    required PaymentMethod method,
    required StateSetter localSetState,
    required List<PaymentMethod> walletMethods,
    required ValueChanged<List<PaymentMethod>> onWalletMethodsChanged,
    required void Function(String message, {Color color}) showSnackBar,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => localSetState(() {
          showSnackBar("${method.type} set as default");
        }),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: const Color(0xFFF35535).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(
                  method.type == 'Cash'
                      ? Icons.money
                      : method.type == 'Visa' || method.type == 'MasterCard'
                          ? Icons.credit_card
                          : Icons.account_balance_wallet,
                  color: const Color(0xFFF35535),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method.type == 'Cash'
                          ? 'Cash on Delivery'
                          : '${method.type} •••• ${method.last4}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    if (method.type != 'Cash' && method.type != 'Wallet')
                      Text(
                        AppLocalizations.of(context)!
                            .expiresDate(method.expDate),
                        style: const TextStyle(
                            color: Colors.black54, fontSize: 12),
                      ),
                  ],
                ),
              ),
              if (method.isDefault)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(4)),
                  child: Text(AppLocalizations.of(context)!.defaultText,
                      style: TextStyle(
                          color: Colors.green.shade700, fontSize: 12)),
                ),
              IconButton(
                icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                onPressed: () => _showPaymentMethodOptions(
                  context: context,
                  method: method,
                  walletMethods: walletMethods,
                  onWalletMethodsChanged: onWalletMethodsChanged,
                  showSnackBar: showSnackBar,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _showPaymentMethodOptions({
    required BuildContext context,
    required PaymentMethod method,
    required List<PaymentMethod> walletMethods,
    required ValueChanged<List<PaymentMethod>> onWalletMethodsChanged,
    required void Function(String message, {Color color}) showSnackBar,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.star, color: Color(0xFFF35535)),
            title: Text(AppLocalizations.of(context)!.setAsDefault,
                style: const TextStyle(color: Colors.black)),
            onTap: () {
              Navigator.pop(context);
              showSnackBar("${method.type} set as default");
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit, color: Color(0xFFF35535)),
            title: Text(AppLocalizations.of(context)!.editDetails,
                style: const TextStyle(color: Colors.black)),
            onTap: () {
              Navigator.pop(context);
              showSnackBar("Edit feature coming soon");
            },
          ),
          ListTile(
            leading: Icon(Icons.delete, color: Colors.red.shade600),
            title: Text(AppLocalizations.of(context)!.remove,
                style: const TextStyle(color: Colors.black)),
            onTap: () {
              Navigator.pop(context);
              if (method.type == 'Vodafone Cash' ||
                  method.type == 'Orange Money' ||
                  method.type == 'Etisalat Cash') {
                final updated = List<PaymentMethod>.from(walletMethods)
                  ..removeWhere((m) => m.id == method.id);
                onWalletMethodsChanged(updated);
              }
              showSnackBar("${method.type} removed");
            },
          ),
        ],
      ),
    );
  }

  static void _showAddPaymentMethod({
    required BuildContext context,
    required List<PaymentMethod> walletMethods,
    required ValueChanged<List<PaymentMethod>> onWalletMethodsChanged,
    required void Function(String message, {Color color}) showSnackBar,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(AppLocalizations.of(context)!.addPaymentMethod,
            style: const TextStyle(color: Colors.black)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.credit_card, color: Color(0xFFF35535)),
              title: Text(AppLocalizations.of(context)!.creditdebitCard,
                  style: const TextStyle(color: Colors.black)),
              onTap: () {
                Navigator.pop(context);
                showAddCardDialog(context: context, showSnackBar: showSnackBar);
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet,
                  color: Color(0xFFF35535)),
              title: Text(AppLocalizations.of(context)!.digitalWallet,
                  style: const TextStyle(color: Colors.black)),
              onTap: () {
                Navigator.pop(context);
                showAddWalletDialog(
                  context: context,
                  walletMethods: walletMethods,
                  onWalletMethodsChanged: onWalletMethodsChanged,
                  showSnackBar: showSnackBar,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
