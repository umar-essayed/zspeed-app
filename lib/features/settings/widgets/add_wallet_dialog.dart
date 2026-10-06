import 'package:z_speed/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:z_speed/features/settings/widgets/payment_method_model.dart';

/// Dialog for adding a digital wallet payment method.
void showAddWalletDialog({
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
      title: Text(AppLocalizations.of(context)!.addDigitalWallet,
          style: const TextStyle(color: Colors.black)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildWalletTile(
            context: context,
            name: "Vodafone Cash",
            subtitle: "0100 000 0000",
            iconColor: Colors.red,
            bgColor: Colors.red.shade50,
            icon: Icons.phone_android,
            walletMethods: walletMethods,
            onWalletMethodsChanged: onWalletMethodsChanged,
            showSnackBar: showSnackBar,
          ),
          _buildWalletTile(
            context: context,
            name: "Orange Money",
            subtitle: "0123 456 7890",
            iconColor: const Color(0xFFF35535),
            bgColor: Colors.orange.shade50,
            icon: Icons.account_balance_wallet,
            walletMethods: walletMethods,
            onWalletMethodsChanged: onWalletMethodsChanged,
            showSnackBar: showSnackBar,
          ),
          _buildWalletTile(
            context: context,
            name: "Etisalat Cash",
            subtitle: "0111 222 3333",
            iconColor: Colors.blue.shade600,
            bgColor: Colors.blue.shade50,
            icon: Icons.payment,
            walletMethods: walletMethods,
            onWalletMethodsChanged: onWalletMethodsChanged,
            showSnackBar: showSnackBar,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.cancel, style: const TextStyle(color: Colors.black54)),
        ),
      ],
    ),
  );
}

Widget _buildWalletTile({
  required BuildContext context,
  required String name,
  required String subtitle,
  required Color iconColor,
  required Color bgColor,
  required IconData icon,
  required List<PaymentMethod> walletMethods,
  required ValueChanged<List<PaymentMethod>> onWalletMethodsChanged,
  required void Function(String message, {Color color}) showSnackBar,
}) {
  return ListTile(
    leading: Container(
      width: 40,
      height: 40,
      decoration:
          BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, color: iconColor),
    ),
    title: Text(name,
        style:
            const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
    subtitle: Text(subtitle, style: const TextStyle(color: Colors.black54)),
    trailing: const Icon(Icons.add_circle, color: Color(0xFFF35535)),
    onTap: () => _showAddWalletDetailsDialog(
      context: context,
      walletType: name,
      walletMethods: walletMethods,
      onWalletMethodsChanged: onWalletMethodsChanged,
      showSnackBar: showSnackBar,
    ),
  );
}

void _showAddWalletDetailsDialog({
  required BuildContext context,
  required String walletType,
  required List<PaymentMethod> walletMethods,
  required ValueChanged<List<PaymentMethod>> onWalletMethodsChanged,
  required void Function(String message, {Color color}) showSnackBar,
}) {
  final formKey = GlobalKey<FormState>();
  final phoneController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title:
          Text(AppLocalizations.of(context)!.addWalletType(walletType.toString()), style: const TextStyle(color: Colors.black)),
      content: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppLocalizations.of(context)!.enterWalletPhone(walletType.toString()), style: const TextStyle(color: Colors.black54, fontSize: 14)),
              const SizedBox(height: 16),
              TextFormField(
                controller: phoneController,
                style: const TextStyle(color: Colors.black),
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: "Phone Number",
                  labelStyle: const TextStyle(color: Colors.black54),
                  prefixIcon: const Icon(Icons.phone, color: Color(0xFFF35535)),
                  hintText: "01XX XXX XXXX",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFFF35535)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter phone number';
                  }
                  if (value.length < 11) {
                    return 'Enter valid Egyptian phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              const Text(
                  "Make sure this is the phone number linked to your wallet",
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.cancel, style: const TextStyle(color: Colors.black54)),
        ),
        ElevatedButton(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              Navigator.pop(context);
              Navigator.pop(context);
              final updated = List<PaymentMethod>.from(walletMethods)
                ..add(PaymentMethod(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  type: walletType,
                  last4: phoneController.text
                      .substring(phoneController.text.length - 4),
                  expDate: '',
                  isDefault: false,
                ));
              onWalletMethodsChanged(updated);
              showSnackBar("$walletType added successfully!");
            }
          },
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF35535),
              foregroundColor: Colors.white),
          child:
              Text(AppLocalizations.of(context)!.addWallet, style: const TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}
