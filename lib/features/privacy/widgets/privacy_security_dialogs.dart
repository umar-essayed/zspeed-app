import 'package:flutter/material.dart';
import 'package:z_speed/l10n/app_localizations.dart';
import 'package:z_speed/features/settings/widgets/settings_password_dialog.dart';

/// Static utility class for security-related dialogs:
/// Two-Factor Authentication, Change Password, Active Sessions.
class PrivacySecurityDialogs {
  PrivacySecurityDialogs._(); // prevent instantiation

  // ───────────────────────── Two-Factor Authentication ─────────────────────
  static void show2FA(
    BuildContext context, {
    required bool email2FA,
    required bool sms2FA,
    required void Function(bool email, bool sms) onSaved,
  }) {
    bool emailEnabled = email2FA;
    bool smsEnabled = sms2FA;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.twofactorAuthentication),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context)!
                      .protectYourAccountWithAnExtraLayerOfSecurity),
                  const SizedBox(height: 20),
                  ListTile(
                    leading: const Icon(Icons.email, color: Color(0xFFF35535)),
                    title:
                        Text(AppLocalizations.of(context)!.emailVerification),
                    subtitle:
                        Text(AppLocalizations.of(context)!.receiveCodeViaEmail),
                    trailing: Switch(
                      value: emailEnabled,
                      // ignore: deprecated_member_use
                      onChanged: (val) {
                        setState(() {
                          emailEnabled = val;
                        });
                      },
                      activeThumbColor: const Color(0xFFF35535),
                    ),
                    contentPadding: EdgeInsets.zero,
                    onTap: () {
                      setState(() {
                        emailEnabled = !emailEnabled;
                      });
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.sms, color: Color(0xFFF35535)),
                    title: Text(AppLocalizations.of(context)!.smsVerification),
                    subtitle:
                        Text(AppLocalizations.of(context)!.receiveCodeViaSms),
                    trailing: Switch(
                      value: smsEnabled,
                      // ignore: deprecated_member_use
                      onChanged: (val) {
                        setState(() {
                          smsEnabled = val;
                        });
                      },
                      activeThumbColor: const Color(0xFFF35535),
                    ),
                    contentPadding: EdgeInsets.zero,
                    onTap: () {
                      setState(() {
                        smsEnabled = !smsEnabled;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  const Divider(),
                  const SizedBox(height: 10),
                  const Text(
                    'Security Tips:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text(AppLocalizations.of(context)!.enableAtLeastOne),
                  Text(AppLocalizations.of(context)!.useEmailForPrimary),
                  Text(AppLocalizations.of(context)!.smsIsGoodFor),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              ElevatedButton(
                onPressed: () {
                  onSaved(emailEnabled, smsEnabled);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context)!
                          .twoFaSettingsUpdatedSuccessfully),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF35535),
                  foregroundColor: Colors.white,
                ),
                child: Text(AppLocalizations.of(context)!.saveSettings,
                    style: const TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  // ───────────────────────── Change Password ──────────────────────────────
  static void showChangePassword(BuildContext context) {
    SettingsPasswordDialog.show(
      context: context,
      showSnackBar: (message, {color = Colors.green}) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message, style: const TextStyle(color: Colors.white)),
            backgroundColor: color,
            duration: const Duration(seconds: 2),
          ),
        );
      },
    );
  }

  // ───────────────────────── Active Sessions ──────────────────────────────
  static void showActiveSessions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.activeSessions),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              _buildSessionTile(
                context: context,
                icon: Icons.phone_iphone,
                device: 'iPhone 13',
                location: 'New York, USA',
                browser: 'Safari • iOS 16.4',
                lastActive: 'Now',
                isCurrent: true,
              ),
              const Divider(),
              _buildSessionTile(
                context: context,
                icon: Icons.computer,
                device: 'MacBook Pro',
                location: 'London, UK',
                browser: 'Chrome • macOS',
                lastActive: 'Yesterday, 14:30',
                isCurrent: false,
                onLogout: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context)!
                          .macbookProSessionLogged),
                      backgroundColor: const Color(0xFFF35535),
                    ),
                  );
                },
              ),
              const Divider(),
              _buildSessionTile(
                context: context,
                icon: Icons.tablet,
                device: 'iPad Air',
                location: 'Paris, France',
                browser: 'Safari • iPadOS',
                lastActive: '3 days ago',
                isCurrent: false,
                onLogout: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          AppLocalizations.of(context)!.ipadAirSessionLogged),
                      backgroundColor: const Color(0xFFF35535),
                    ),
                  );
                },
              ),
              const Divider(),
              _buildSessionTile(
                context: context,
                icon: Icons.phone_android,
                device: 'Samsung Galaxy',
                location: 'Tokyo, Japan',
                browser: 'Chrome • Android',
                lastActive: '1 week ago',
                isCurrent: false,
                onLogout: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context)!
                          .samsungGalaxySessionLogged),
                      backgroundColor: const Color(0xFFF35535),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.close,
                style: const TextStyle(color: Color(0xFFF35535))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      AppLocalizations.of(context)!.allOtherSessionsLogged),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context)!.logoutAllOthers,
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  static Widget _buildSessionTile({
    required BuildContext context,
    required IconData icon,
    required String device,
    required String location,
    required String browser,
    required String lastActive,
    required bool isCurrent,
    VoidCallback? onLogout,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFF35535).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFFF35535)),
      ),
      title: Text(device, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(location),
          Text(browser),
          Text(AppLocalizations.of(context)!.lastActiveDate(lastActive),
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
      trailing: isCurrent
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Current',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : IconButton(
              icon: const Icon(Icons.logout, color: Colors.red, size: 20),
              onPressed: onLogout,
            ),
      onTap: isCurrent ? null : onLogout,
    );
  }
}
