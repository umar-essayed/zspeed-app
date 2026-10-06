import 'package:z_speed/l10n/app_localizations.dart';
// lib/pages/privacy_security_screen.dart
import 'package:flutter/material.dart';
import 'package:z_speed/features/privacy/widgets/privacy_security_dialogs.dart';
import 'package:z_speed/features/privacy/widgets/privacy_data_dialogs.dart';
import 'package:z_speed/features/privacy/widgets/privacy_info_dialogs.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  // Privacy settings state
  bool dataCollection = true;
  bool analytics = true;
  bool marketingEmails = false;
  bool biometricLogin = false;
  bool email2FA = true;
  bool sms2FA = false;

  @override
  Widget build(BuildContext context) {
    const Color brandOrange = Color(0xFFF35535);
    const Color brandYellow = Color(0xFFFF9800);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.privacySecurity,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [brandOrange, brandYellow],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // Privacy Settings
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.privacySettings,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildPrivacyOption(
                    title: AppLocalizations.of(context)!.dataCollection,
                    subtitle: AppLocalizations.of(context)!.controlWhatData,
                    value: dataCollection,
                    // ignore: deprecated_member_use
                    onChanged: (val) {
                      setState(() {
                        dataCollection = val;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(val
                              ? AppLocalizations.of(context)!
                                  .dataCollectionEnabled
                              : AppLocalizations.of(context)!
                                  .dataCollectionDisabled),
                          backgroundColor: const Color(0xFFF35535),
                        ),
                      );
                    },
                  ),
                  _buildPrivacyOption(
                    title: AppLocalizations.of(context)!.analyticsTitle,
                    subtitle: AppLocalizations.of(context)!.helpUsImprove,
                    value: analytics,
                    // ignore: deprecated_member_use
                    onChanged: (val) {
                      setState(() {
                        analytics = val;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(val
                              ? AppLocalizations.of(context)!.analyticsEnabled
                              : AppLocalizations.of(context)!
                                  .analyticsDisabled),
                          backgroundColor: const Color(0xFFF35535),
                        ),
                      );
                    },
                  ),
                  _buildPrivacyOption(
                    title: AppLocalizations.of(context)!.marketingEmails,
                    subtitle:
                        AppLocalizations.of(context)!.receivePromotionalEmails,
                    value: marketingEmails,
                    // ignore: deprecated_member_use
                    onChanged: (val) {
                      setState(() {
                        marketingEmails = val;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(val
                              ? AppLocalizations.of(context)!
                                  .marketingEmailsEnabled
                              : AppLocalizations.of(context)!
                                  .marketingEmailsDisabled),
                          backgroundColor: const Color(0xFFF35535),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Security Settings
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.securitySettings,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    leading:
                        const Icon(Icons.fingerprint, color: Color(0xFFF35535)),
                    title: Text(AppLocalizations.of(context)!.biometricLogin),
                    subtitle: Text(
                        AppLocalizations.of(context)!.useFingerprintOrFace),
                    trailing: Switch(
                      value: biometricLogin,
                      // ignore: deprecated_member_use
                      onChanged: (val) {
                        setState(() {
                          biometricLogin = val;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(val
                                ? AppLocalizations.of(context)!.biometricEnabled
                                : AppLocalizations.of(context)!
                                    .biometricDisabled),
                            backgroundColor: const Color(0xFFF35535),
                          ),
                        );
                      },
                      activeThumbColor: const Color(0xFFF35535),
                    ),
                    onTap: () {
                      setState(() {
                        biometricLogin = !biometricLogin;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(!biometricLogin
                              ? 'Biometric login enabled'
                              : 'Biometric login disabled'),
                          backgroundColor: const Color(0xFFF35535),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.lock, color: Color(0xFFF35535)),
                    title: Text(
                        AppLocalizations.of(context)!.twofactorAuthentication),
                    subtitle:
                        Text(AppLocalizations.of(context)!.addAnExtraLayer),
                    trailing: const Icon(Icons.chevron_right,
                        color: Color(0xFFF35535)),
                    onTap: () {
                      PrivacySecurityDialogs.show2FA(
                        context,
                        email2FA: email2FA,
                        sms2FA: sms2FA,
                        onSaved: (email, sms) {
                          setState(() {
                            email2FA = email;
                            sms2FA = sms;
                          });
                        },
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading:
                        const Icon(Icons.vpn_key, color: Color(0xFFF35535)),
                    title: Text(AppLocalizations.of(context)!.changePassword),
                    subtitle: Text(AppLocalizations.of(context)!
                        .updateYourPasswordRegularly),
                    trailing: const Icon(Icons.chevron_right,
                        color: Color(0xFFF35535)),
                    onTap: () {
                      PrivacySecurityDialogs.showChangePassword(context);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading:
                        const Icon(Icons.devices, color: Color(0xFFF35535)),
                    title: Text(AppLocalizations.of(context)!.activeSessions),
                    subtitle: Text(
                        AppLocalizations.of(context)!.manageLoggedInDevices),
                    trailing: const Icon(Icons.chevron_right,
                        color: Color(0xFFF35535)),
                    onTap: () {
                      PrivacySecurityDialogs.showActiveSessions(context);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Data Management
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.dataManagement,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    leading:
                        const Icon(Icons.download, color: Color(0xFFF35535)),
                    title: Text(AppLocalizations.of(context)!.downloadYourData),
                    subtitle: Text(AppLocalizations.of(context)!.getACopyOf),
                    trailing: const Icon(Icons.chevron_right,
                        color: Color(0xFFF35535)),
                    onTap: () {
                      PrivacyDataDialogs.showDownloadData(context);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: Text(AppLocalizations.of(context)!.deleteAccount,
                        style: const TextStyle(color: Colors.red)),
                    subtitle: Text(
                        AppLocalizations.of(context)!
                            .permanentlyDeleteYourAccount,
                        style: const TextStyle(color: Colors.red)),
                    trailing:
                        const Icon(Icons.chevron_right, color: Colors.red),
                    onTap: () {
                      PrivacyDataDialogs.showDeleteAccount(context);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Additional Options
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.additionalOptions,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    leading:
                        const Icon(Icons.privacy_tip, color: Color(0xFFF35535)),
                    title: Text(AppLocalizations.of(context)!.privacyPolicy),
                    subtitle: Text(
                        AppLocalizations.of(context)!.readOurPrivacyPolicy),
                    trailing: const Icon(Icons.chevron_right,
                        color: Color(0xFFF35535)),
                    onTap: () {
                      PrivacyInfoDialogs.showPrivacyPolicy(context);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading:
                        const Icon(Icons.description, color: Color(0xFFF35535)),
                    title: Text(AppLocalizations.of(context)!.termsOfService),
                    subtitle:
                        Text(AppLocalizations.of(context)!.readOurTermsOf),
                    trailing: const Icon(Icons.chevron_right,
                        color: Color(0xFFF35535)),
                    onTap: () {
                      PrivacyInfoDialogs.showTermsOfService(context);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.help, color: Color(0xFFF35535)),
                    title: Text(AppLocalizations.of(context)!.helpSupport),
                    subtitle:
                        Text(AppLocalizations.of(context)!.getHelpWithPrivacy),
                    trailing: const Icon(Icons.chevron_right,
                        color: Color(0xFFF35535)),
                    onTap: () {
                      PrivacyInfoDialogs.showHelpSupport(context);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyOption({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            // ignore: deprecated_member_use
            onChanged: onChanged,
            activeThumbColor: const Color(0xFFF35535),
          ),
        ],
      ),
    );
  }
}
