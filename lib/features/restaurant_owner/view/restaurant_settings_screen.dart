import 'package:z_speed/core/localization/language_selector_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/l10n/app_localizations.dart';
import 'package:z_speed/features/auth/cubit/auth_cubit.dart';
import 'package:z_speed/features/restaurant/repository/restaurant_menu_repository_impl.dart';
import 'package:z_speed/features/restaurant_owner/view/restaurant_settings_dialogs.dart';
import 'package:z_speed/features/restaurant_owner/view/restaurant_settings_widgets.dart';
import 'package:z_speed/features/restaurant_owner/cubit/restaurant_profile_cubit.dart';
import 'package:z_speed/features/restaurant_owner/cubit/restaurant_profile_state.dart';
import 'package:z_speed/features/payment_settings/view/payment_settings_screen.dart';
import 'package:z_speed/features/settings/widgets/settings_password_dialog.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ownerId = FirebaseAuth.instance.currentUser?.uid;
    if (ownerId == null) {
      return Scaffold(
        body: Center(
          child: Text(AppLocalizations.of(context)!.notAuthenticatedPleaseLog),
        ),
      );
    }

    return BlocProvider<RestaurantProfileCubit>(
      create: (context) => RestaurantProfileCubit(
        repository: RestaurantMenuRepositoryImpl(),
        ownerId: ownerId,
      ),
      child: const _SettingsContent(),
    );
  }
}

class _SettingsContent extends StatefulWidget {
  const _SettingsContent();

  @override
  State<_SettingsContent> createState() => _SettingsContentState();
}

class _SettingsContentState extends State<_SettingsContent> {
  Map<String, bool> notifications = {
    'new_order': true,
    'email': true,
    'auto_accept': false,
  };
  bool _isLoadingSettings = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ownerId = FirebaseAuth.instance.currentUser?.uid ?? 'default';
      setState(() {
        notifications = {
          'new_order': prefs.getBool('notification_${ownerId}_new_order') ?? true,
          'email': prefs.getBool('notification_${ownerId}_email') ?? true,
          'auto_accept': prefs.getBool('notification_${ownerId}_auto_accept') ?? false,
        };
        _isLoadingSettings = false;
      });
    } catch (e) {
      debugPrint('Error loading settings: $e');
      setState(() {
        _isLoadingSettings = false;
      });
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSnackBar(String message, {Color color = Colors.green}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _saveNotificationSetting(String type, bool value) async {
    debugPrint('Notification $type saved: $value');
    try {
      final prefs = await SharedPreferences.getInstance();
      final ownerId = FirebaseAuth.instance.currentUser?.uid ?? 'default';
      await prefs.setBool('notification_${ownerId}_$type', value);
    } catch (e) {
      debugPrint('Error saving setting $type: $e');
    }
  }

  void _navigateToScreen(String screenName) {
    Widget? screen;
    switch (screenName) {
      case 'Payment Methods':
        screen = const PaymentSettingsPage();
      default:
        screen = null;
    }
    if (screen != null) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => screen!));
    }
  }

  void _showChangePasswordDialog(BuildContext context) {
    SettingsPasswordDialog.show(
      context: context,
      showSnackBar: _showSnackBar,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RestaurantProfileCubit, RestaurantProfileState>(
      builder: (context, state) {
        if ((state.isLoading && state.restaurant == null) || _isLoadingSettings) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state.error != null && state.restaurant == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    state.error ?? AppLocalizations.of(context)!.unknownError,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: context.read<RestaurantProfileCubit>().init,
                    child: Text(AppLocalizations.of(context)!.retry),
                  ),
                ],
              ),
            ),
          );
        }

        // Show create restaurant prompt if none exists
        if (!state.hasRestaurant) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.store,
                      size: 80,
                      color: Color(0xFFF35535),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      AppLocalizations.of(context)!.createYourRestaurant,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppLocalizations.of(context)!
                          .setUpRestaurantProfilePrompt,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () => _showCreateRestaurantDialog(
                        context.read<RestaurantProfileCubit>(),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF35535),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.createRestaurant,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.preferences,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 10),

                const LanguageSelectorTile(),
                const SizedBox(height: 5),
                Text(
                  AppLocalizations.of(context)!.manageSettingsSubtitle,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 30),

                // ── Notifications ──
                _card(
                  title: AppLocalizations.of(context)!.notifications,
                  subtitle:
                      AppLocalizations.of(context)!.configureAlertsSubtitle,
                  child: Column(children: _notificationToggles()),
                ),
                const SizedBox(height: 30),

                // ── Navigation ──
                _cardRaw(
                  child: Column(
                    children: [
                      VendorNavigationTile(
                        icon: Icons.payment,
                        title: AppLocalizations.of(context)!.paymentMethods,
                        onTap: () => _navigateToScreen('Payment Methods'),
                      ),
                      const Divider(),
                      VendorNavigationTile(
                        icon: Icons.lock_outline,
                        title: AppLocalizations.of(context)!.changePasswordLabel,
                        onTap: () => _showChangePasswordDialog(context),
                      ),
                      const Divider(),
                      VendorNavigationTile(
                        icon: Icons.logout,
                        title: AppLocalizations.of(context)!.logout,
                        color: Colors.red,
                        onTap: () => showVendorLogoutDialog(context: context),
                      ),
                      const Divider(),
                      VendorNavigationTile(
                        icon: Icons.delete_forever,
                        title: AppLocalizations.of(context)!.deleteAccount,
                        color: Colors.red,
                        onTap: () => _showDeleteAccountDialog(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────

  Widget _card(
      {required String title,
      required String subtitle,
      required Widget child}) {
    return _cardRaw(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(subtitle,
              style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _cardRaw({required Widget child}) {
    return Container(
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
      child: child,
    );
  }

  List<Widget> _notificationToggles() {
    return [
      VendorNotificationToggle(
        title: AppLocalizations.of(context)!.newOrderAlert,
        description: AppLocalizations.of(context)!.newOrderAlertDescription,
        value: notifications['new_order']!,
        // ignore: deprecated_member_use
        onChanged: (v) {
          setState(() => notifications['new_order'] = v);
          _saveNotificationSetting('new_order', v);
        },
      ),
      VendorNotificationToggle(
        title: AppLocalizations.of(context)!.emailNotifications,
        description:
            AppLocalizations.of(context)!.emailNotificationsDescription,
        value: notifications['email']!,
        // ignore: deprecated_member_use
        onChanged: (v) {
          setState(() => notifications['email'] = v);
          _saveNotificationSetting('email', v);
        },
      ),
      VendorNotificationToggle(
        title: AppLocalizations.of(context)!.autoAcceptOrders,
        description: AppLocalizations.of(context)!.autoAcceptOrdersDescription,
        value: notifications['auto_accept']!,
        // ignore: deprecated_member_use
        onChanged: (v) {
          setState(() => notifications['auto_accept'] = v);
          _saveNotificationSetting('auto_accept', v);
        },
      ),
    ];
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final confirmController = TextEditingController();
    final authCubit = context.read<AuthCubit>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(ctx)!.deleteAccount,
                style: const TextStyle(
                    color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(ctx)!.areYouSureYou),
            const SizedBox(height: 12),
            Text(AppLocalizations.of(ctx)!.typeDeleteToConfirm,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: confirmController,
              decoration: InputDecoration(
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                hintText: 'Type DELETE here',
                prefixIcon: const Icon(Icons.warning, color: Colors.red),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(ctx)!.cancel),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(AppLocalizations.of(ctx)!.deleteAccount,
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showCreateRestaurantDialog(RestaurantProfileCubit cubit) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    final emailController = TextEditingController();
    final cuisineController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.createRestaurant),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText:
                      AppLocalizations.of(context)!.restaurantNameAsterisk,
                  border: const OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.descriptionOptional,
                  hintText: AppLocalizations.of(context)!.descriptionPlaceholder,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.phoneNumber,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addressController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.address,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.email,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: cuisineController,
                decoration: InputDecoration(
                  labelText:
                      AppLocalizations.of(context)!.cuisineTypesCommaSeparated,
                  hintText: AppLocalizations.of(context)!.cuisineTypesHint,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        AppLocalizations.of(context)!.restaurantNameIsRequired),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(dialogContext);

              final cuisines = cuisineController.text
                  .split(',')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList();

              try {
                await cubit.createRestaurant(
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim().isEmpty
                      ? AppLocalizations.of(context)!.descriptionPlaceholder
                      : descriptionController.text.trim(),
                  phone: phoneController.text.trim(),
                  address: addressController.text.trim(),
                  cuisineTypes: cuisines,
                );
                if (!mounted) return;
                _showSuccess(AppLocalizations.of(context)!
                    .restaurantCreatedSuccessfully);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context)!
                          .failedToCreateRestaurant(e.toString())),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF35535),
            ),
            child: Text(AppLocalizations.of(context)!.create),
          ),
        ],
      ),
    );
  }
}
