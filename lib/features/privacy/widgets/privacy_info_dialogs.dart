import 'package:z_speed/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:z_speed/core/constants/app_constants.dart';

/// Static utility class for informational dialogs:
/// Privacy Policy, Terms of Service, Help & Support.
class PrivacyInfoDialogs {
  PrivacyInfoDialogs._(); // prevent instantiation

  // ───────────────────────── Privacy Policy ───────────────────────────────
  static void showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.privacyPolicy),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Last Updated: ${AppConstants.lastUpdated}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'We value your privacy and are committed to protecting your personal data. '
                'This privacy policy will inform you about how we look after your personal data '
                'when you visit our website and tell you about your privacy rights.',
              ),
              const SizedBox(height: 10),
              Text(AppLocalizations.of(context)!.keyPoints),
              const SizedBox(height: 5),
              Text(AppLocalizations.of(context)!.weCollectOnlyNecessary),
              Text(AppLocalizations.of(context)!.yourDataIsEncrypted),
              Text(AppLocalizations.of(context)!.weNeverSellYour),
              Text(AppLocalizations.of(context)!.youControlYourPrivacy),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  // Open full privacy policy
                },
                child:
                    Text(AppLocalizations.of(context)!.readFullPrivacyPolicy),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.close),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── Terms of Service ─────────────────────────────
  static void showTermsOfService(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.termsOfService),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'By using our service, you agree to our terms:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(AppLocalizations.of(context)!.youMustBeAt),
              Text(AppLocalizations.of(context)!.youAreResponsibleFor),
              Text(AppLocalizations.of(context)!.weReserveTheRight),
              Text(AppLocalizations.of(context)!.serviceMayBeInterrupted),
              Text(AppLocalizations.of(context)!.pricesAndFeesMay),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  // Open full terms
                },
                child: Text(AppLocalizations.of(context)!.readFullTerms),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.close),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── Help & Support ───────────────────────────────
  static void showHelpSupport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.helpSupport),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.email, color: Color(0xFFF35535)),
                title: Text(AppLocalizations.of(context)!.emailSupport),
                subtitle: Text(AppConstants.supportEmail),
                onTap: () {
                  // Open email
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.phone, color: Color(0xFFF35535)),
                title: Text(AppLocalizations.of(context)!.phoneSupport),
                subtitle: Text(AppConstants.supportPhone),
                onTap: () {
                  // Make phone call
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.chat, color: Color(0xFFF35535)),
                title: Text(AppLocalizations.of(context)!.liveChat),
                subtitle:
                    Text(AppLocalizations.of(context)!.available9am5pmEst),
                onTap: () {
                  // Open chat
                },
              ),
              const Divider(),
              ListTile(
                leading:
                    const Icon(Icons.help_center, color: Color(0xFFF35535)),
                title: Text(AppLocalizations.of(context)!.faq),
                subtitle: Text(
                    AppLocalizations.of(context)!.frequentlyAskedQuestions),
                onTap: () {
                  // Open FAQ
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.close),
          ),
        ],
      ),
    );
  }
}
