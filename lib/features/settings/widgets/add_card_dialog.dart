import 'package:z_speed/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Dialog for adding a credit/debit card.
void showAddCardDialog({
  required BuildContext context,
  required void Function(String message, {Color color}) showSnackBar,
}) {
  final formKey = GlobalKey<FormState>();
  final cardNumberController = TextEditingController();
  final expiryController = TextEditingController();
  final cvvController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(AppLocalizations.of(context)!.addCard,
          style: const TextStyle(color: Colors.black)),
      content: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: cardNumberController,
                style: const TextStyle(color: Colors.black),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Card Number",
                  labelStyle: const TextStyle(color: Colors.black54),
                  prefixIcon:
                      const Icon(Icons.credit_card, color: Color(0xFFF35535)),
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
                  if (value == null || value.length < 16) {
                    return 'Enter valid card number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: expiryController,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        labelText: "MM/YY",
                        labelStyle: const TextStyle(color: Colors.black54),
                        prefixIcon: const Icon(Icons.calendar_today,
                            color: Color(0xFFF35535)),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              const BorderSide(color: Color(0xFFF35535)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter expiry date';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: cvvController,
                      style: const TextStyle(color: Colors.black),
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "CVV",
                        labelStyle: const TextStyle(color: Colors.black54),
                        prefixIcon:
                            const Icon(Icons.lock, color: Color(0xFFF35535)),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              const BorderSide(color: Color(0xFFF35535)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.length < 3) {
                          return 'Enter valid CVV';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.cancel,
              style: const TextStyle(color: Colors.black54)),
        ),
        ElevatedButton(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              Navigator.pop(context);
              showSnackBar("Card added successfully!");
            }
          },
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF35535),
              foregroundColor: Colors.white),
          child: Text(AppLocalizations.of(context)!.addCard,
              style: const TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}
