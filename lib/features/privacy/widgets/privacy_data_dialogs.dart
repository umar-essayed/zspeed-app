import 'package:z_speed/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/features/auth/cubit/auth_cubit.dart';

/// Static utility class for data-management dialogs:
/// Download Your Data, Delete Account.
class PrivacyDataDialogs {
  PrivacyDataDialogs._(); // prevent instantiation

  // ───────────────────────── Download Your Data ───────────────────────────
  static void showDownloadData(BuildContext context) {
    String selectedFormat = 'JSON';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.downloadYourData),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context)!
                      .yourDataWillBePreparedAndSentToYourEmail),
                  const SizedBox(height: 15),
                  Text(AppLocalizations.of(context)!.selectDataFormat),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildFormatOption(
                        context: context,
                        format: 'JSON',
                        selectedFormat: selectedFormat,
                        onTap: () {
                          setState(() {
                            selectedFormat = 'JSON';
                          });
                        },
                      ),
                      const SizedBox(width: 10),
                      _buildFormatOption(
                        context: context,
                        format: 'CSV',
                        selectedFormat: selectedFormat,
                        onTap: () {
                          setState(() {
                            selectedFormat = 'CSV';
                          });
                        },
                      ),
                      const SizedBox(width: 10),
                      _buildFormatOption(
                        context: context,
                        format: 'PDF',
                        selectedFormat: selectedFormat,
                        onTap: () {
                          setState(() {
                            selectedFormat = 'PDF';
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(AppLocalizations.of(context)!.thisIncludes),
                  const SizedBox(height: 5),
                  Text(AppLocalizations.of(context)!.accountInformation),
                  Text(AppLocalizations.of(context)!.orderHistory),
                  Text(AppLocalizations.of(context)!.paymentRecords),
                  Text(AppLocalizations.of(context)!.restaurantSettings),
                  Text(AppLocalizations.of(context)!.preferences),
                  Text(AppLocalizations.of(context)!.activityLogs),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Note: Data preparation may take up to 24 hours. You will receive an email with download link.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.cancel,
                    style: const TextStyle(color: Color(0xFFF35535))),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Data download requested in $selectedFormat format. You will receive an email shortly.'),
                      backgroundColor: const Color(0xFFF35535),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF35535),
                  foregroundColor: Colors.white,
                ),
                child: Text(AppLocalizations.of(context)!.requestDownload,
                    style: const TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  static Widget _buildFormatOption({
    required BuildContext context,
    required String format,
    required String selectedFormat,
    required VoidCallback onTap,
  }) {
    final bool isSelected = selectedFormat == format;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF35535) : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFFF35535) : Colors.grey[300]!,
            ),
          ),
          child: Center(
            child: Text(
              format,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────────── Delete Account ───────────────────────────────
  static void showDeleteAccount(BuildContext context) {
    final confirmController = TextEditingController();
    final authCubit = context.read<AuthCubit>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(ctx)!.deleteAccount,
            style: const TextStyle(color: Colors.red)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(ctx)!.areYouSureYou),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '⚠️ This action cannot be undone!',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                    const SizedBox(height: 5),
                    Text(AppLocalizations.of(ctx)!.thisWill),
                    const SizedBox(height: 5),
                    Text(AppLocalizations.of(ctx)!.permanentlyDeleteAllYour),
                    Text(AppLocalizations.of(ctx)!.cancelAllPendingOrders),
                    Text(AppLocalizations.of(ctx)!.removeYourRestaurantFrom),
                    Text(AppLocalizations.of(ctx)!.deleteAllCustomerReviews),
                    Text(AppLocalizations.of(ctx)!.removePaymentInformation),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              Text(AppLocalizations.of(ctx)!.typeDeleteToConfirm,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextField(
                controller: confirmController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  hintText: 'Type DELETE here',
                  prefixIcon: const Icon(Icons.warning, color: Colors.red),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Consider downloading your data first!',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(ctx)!.cancel,
                style: const TextStyle(color: Color(0xFFF35535))),
          ),
          ElevatedButton(
            onPressed: () async {
              if (confirmController.text.toUpperCase() != 'DELETE') {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(ctx)!.pleaseTypeDeleteTo),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(ctx);
              final error = await authCubit.deleteAccount();
              if (error != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(error), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(
              AppLocalizations.of(ctx)!.deleteAccount,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
