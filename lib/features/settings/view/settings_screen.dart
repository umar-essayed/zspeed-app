import 'package:z_speed/l10n/app_localizations.dart';
import 'package:z_speed/core/localization/language_selector_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/core/utils/app_version_helper.dart';
import 'package:z_speed/features/auth/cubit/auth_cubit.dart';
import 'package:z_speed/features/auth/cubit/auth_state.dart';
import 'package:z_speed/features/auth/widgets/phone_verification_dialog.dart';
import 'package:z_speed/features/settings/widgets/settings_info_dialogs.dart';
import 'package:z_speed/features/settings/widgets/settings_password_dialog.dart';
import 'package:z_speed/features/settings/widgets/settings_payment_dialogs.dart';
import 'package:z_speed/features/settings/widgets/payment_method_model.dart';
import 'package:z_speed/features/settings/widgets/settings_profile_dialogs.dart';
import 'package:z_speed/features/customer/view/saved_addresses_screen.dart';
import 'package:z_speed/features/privacy/view/privacy_security_screen.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool notificationsEnabled = true;
  String selectedLanguage = "English";
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _profileImageUrl = '';
  List<PaymentMethod> walletMethods = const [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final user = context.read<AuthCubit>().state.user;
    if (user != null) {
      setState(() {
        _nameController.text = user.name;
        _emailController.text = user.email;
        _phoneController.text = user.phone ?? '';
      });
    }
  }

  void _showSnackBar(String message, {Color color = Colors.green}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── Delegate to extracted dialog classes ──────────────────────

  void _showEditProfileDialog() {
    SettingsProfileDialogs.showEditProfile(
      context: context,
      nameController: _nameController,
      emailController: _emailController,
      phoneController: _phoneController,
      profileImageUrl: _profileImageUrl,
      onProfileImageChanged: (url) => setState(() => _profileImageUrl = url),
      onSaved: () => setState(() {}),
      showSnackBar: _showSnackBar,
    );
  }

  void _showChangePasswordDialog() {
    SettingsPasswordDialog.show(
      context: context,
      showSnackBar: _showSnackBar,
    );
  }

  void _showPaymentMethodsDialog() {
    SettingsPaymentDialogs.showPaymentMethods(
      context: context,
      walletMethods: walletMethods,
      onWalletMethodsChanged: (methods) =>
          setState(() => walletMethods = methods),
      showSnackBar: _showSnackBar,
    );
  }

  void _showDeliveryAreaDialog() {
    SettingsInfoDialogs.showDeliveryArea(
      context: context,
      showSnackBar: _showSnackBar,
    );
  }

  void _showSupportDialog() {
    SettingsInfoDialogs.showSupport(
      context: context,
      showSnackBar: _showSnackBar,
    );
  }

  void _showPrivacyDialog() {
    SettingsInfoDialogs.showPrivacy(context: context);
  }

  void _showTermsDialog() {
    SettingsInfoDialogs.showTerms(
      context: context,
      showSnackBar: _showSnackBar,
    );
  }

  // ── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        _loadUserData();
      },
      builder: (context, state) {
        const Color brandOrange = Color(0xFFF35535);
        const Color brandYellow = Color(0xFFFF9800);
        final needsPhone = state.customerNeedsPhone;

        return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.accountSection,
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
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (needsPhone) ...[
            _buildPhoneVerificationBanner(),
            const SizedBox(height: 20),
          ],
          // Profile Card
          GestureDetector(
            onTap: _showEditProfileDialog,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor:
                        const Color(0xFFF35535).withValues(alpha: 0.1),
                    backgroundImage: _profileImageUrl.isNotEmpty
                        ? NetworkImage(_profileImageUrl)
                        : null,
                    child: _profileImageUrl.isEmpty
                        ? const Icon(Icons.person,
                            size: 30, color: Color(0xFFF35535))
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _nameController.text,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _emailController.text,
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _phoneController.text,
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _showEditProfileDialog,
                    icon: const Icon(Icons.edit, color: Color(0xFFF35535)),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Account Section
          _buildSectionTitle(AppLocalizations.of(context)!.account),
          _buildSettingCard(
            children: [
              _buildSettingItem(
                icon: Icons.person_outline,
                title: AppLocalizations.of(context)!.editProfileLabel,
                subtitle: AppLocalizations.of(context)!.updatePersonalInfo,
                onTap: _showEditProfileDialog,
              ),
              _buildSettingItem(
                icon: Icons.lock_outline,
                title: AppLocalizations.of(context)!.changePasswordLabel,
                subtitle: AppLocalizations.of(context)!.updateLoginPassword,
                onTap: _showChangePasswordDialog,
              ),
              _buildSettingItem(
                icon: Icons.payment,
                title: AppLocalizations.of(context)!.paymentMethodsLabel,
                subtitle: AppLocalizations.of(context)!.managePaymentOptions,
                onTap: _showPaymentMethodsDialog,
              ),
              _buildSettingItem(
                icon: Icons.location_on,
                title: AppLocalizations.of(context)!.savedAddressesLabel,
                subtitle: AppLocalizations.of(context)!.manageDeliveryLocations,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SavedAddressesScreen(),
                    ),
                  );
                },
              ),
              _buildSettingItem(
                icon: Icons.security,
                title: AppLocalizations.of(context)!.privacySecurity,
                subtitle:
                    AppLocalizations.of(context)!.permanentlyDeleteYourAccount,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PrivacySecurityScreen(),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          const LanguageSelectorTile(),
          // Preferences Section
          _buildSectionTitle(AppLocalizations.of(context)!.preferencesSection),
          _buildSettingCard(
            children: [
              _buildSettingItem(
                icon: Icons.notifications_none,
                title: AppLocalizations.of(context)!.notificationsLabel,
                subtitle: AppLocalizations.of(context)!.receiveOrderUpdates,
                trailing: Switch(
                  value: notificationsEnabled,
                  activeThumbColor: const Color(0xFFF35535),
                  // ignore: deprecated_member_use
                  onChanged: (value) {
                    setState(() {
                      notificationsEnabled = value;
                    });
                    _showSnackBar(
                      value
                          ? AppLocalizations.of(context)!
                              .notificationsEnabledMsg
                          : AppLocalizations.of(context)!
                              .notificationsDisabledMsg,
                      color: value ? Colors.green : Colors.grey,
                    );
                  },
                ),
              ),
              // _buildSettingItem(
              //   icon: Icons.language,
              //   title: AppLocalizations.of(context)!.languageLabel,
              //   subtitle: AppLocalizations.of(context)!.choosePreferredLanguage,
              //   trailing: Container(
              //     padding:
              //         const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              //     decoration: BoxDecoration(
              //       color: Colors.orange.shade50,
              //       borderRadius: BorderRadius.circular(8),
              //       border: Border.all(color: Colors.orange.shade100),
              //     ),
              //     child: DropdownButtonHideUnderline(
              //       child: DropdownButton<String>(
              //         value: selectedLanguage,
              //         icon: Icon(Icons.arrow_drop_down,
              //             color: Colors.orange.shade600),
              //         dropdownColor: Colors.white,
              //         style: const TextStyle(color: Colors.black),
              //         items: [
              //           DropdownMenuItem(
              //             value: "English",
              //             child: Text(AppLocalizations.of(context)!.english,
              //                 style: const TextStyle(color: Colors.black)),
              //           ),
              //           DropdownMenuItem(
              //             value: "Arabic",
              //             child: Text(AppLocalizations.of(context)!.symbolKeyXXX,
              //                 style: const TextStyle(color: Colors.black)),
              //           ),
              //         ],
              //         // ignore: deprecated_member_use
              //         onChanged: (value) {
              //           if (value != null) {
              //             setState(() {
              //               selectedLanguage = value;
              //             });
              //             _showSnackBar(
              //                 AppLocalizations.of(context)!.languageChangedTo(value));
              //           }
              //         },
              //       ),
              //     ),
              //   ),
              // ),
              _buildSettingItem(
                icon: Icons.location_on_outlined,
                title: AppLocalizations.of(context)!.deliveryAreaLabel,
                subtitle: AppLocalizations.of(context)!.selectServiceArea,
                onTap: _showDeliveryAreaDialog,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // About Section
          _buildSectionTitle(AppLocalizations.of(context)!.aboutSection),
          _buildSettingCard(
            children: [
              _buildSettingItem(
                icon: Icons.info_outline,
                title: AppLocalizations.of(context)!.aboutSpeedApp,
                subtitle: Localizations.localeOf(context).languageCode == 'ar'
                    ? 'الإصدار ${AppVersionHelper.currentVersion}'
                    : 'Version ${AppVersionHelper.currentVersion}',
                onTap: () => SettingsInfoDialogs.showAbout(context: context),
              ),
              _buildSettingItem(
                icon: Icons.support_agent,
                title: AppLocalizations.of(context)!.supportContact,
                subtitle: AppLocalizations.of(context)!.getHelpContact,
                onTap: _showSupportDialog,
              ),
              _buildSettingItem(
                icon: Icons.privacy_tip_outlined,
                title: AppLocalizations.of(context)!.privacyPolicyLabel,
                subtitle: AppLocalizations.of(context)!.readPrivacyPolicyLabel,
                onTap: _showPrivacyDialog,
              ),
              _buildSettingItem(
                icon: Icons.description_outlined,
                title: AppLocalizations.of(context)!.termsOfServiceLabel,
                subtitle: AppLocalizations.of(context)!.readTermsConditions,
                onTap: _showTermsDialog,
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Logout Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                context.read<AuthCubit>().logout();
              },
              icon: const Icon(Icons.logout, color: Colors.white),
              label: Text(
                AppLocalizations.of(context)!.logoutButton,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ),

          const SizedBox(height: 32),
          Center(
            child: Text(
              "Speed Rides ${AppVersionHelper.displayVersion}",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
      },
    );
  }

  Widget _buildPhoneVerificationBanner() {
    final l10n = AppLocalizations.of(context)!;
    const Color brandOrange = Color(0xFFF35535);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            brandOrange.withValues(alpha: 0.08),
            brandOrange.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: brandOrange.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: brandOrange.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.phone_android_rounded,
              color: brandOrange,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          // Text Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.verifyYourPhone,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  l10n.pleaseVerifyPhone,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Action Button
          ElevatedButton(
            onPressed: () async {
              final verified = await PhoneVerificationDialog.show(context);
              if (verified == true) {
                _showSnackBar(l10n.localeName == 'ar'
                    ? 'تم تأكيد رقم الهاتف بنجاح!'
                    : 'Phone number verified successfully!');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: brandOrange,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              l10n.verifyLabel,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 8, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFFF35535),
        ),
      ),
    );
  }

  Widget _buildSettingCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children
            .asMap()
            .entries
            .map((entry) => Column(
                  children: [
                    entry.value,
                    if (entry.key < children.length - 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Divider(
                          height: 1,
                          color: Colors.grey.shade200,
                        ),
                      ),
                  ],
                ))
            .toList(),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(0),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF35535).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFFF35535),
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null)
                trailing
              else
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey.shade400,
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
