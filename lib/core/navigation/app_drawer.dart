import 'package:z_speed/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:z_speed/core/constants/page_identity.dart';
import 'package:z_speed/core/navigation/navigation_policy.dart';
import 'package:z_speed/features/auth/model/user_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/features/auth/cubit/auth_cubit.dart';
class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.currentUser,
    required this.selectedPageKey,
    required this.onPageSelected,
  });

  final AppUser currentUser;
  final String selectedPageKey;
  final ValueChanged<String> onPageSelected;

  Widget _buildDrawerItem(BuildContext context, String pageKey) {
    final iconColor = PageIdentity.getColorForKey(pageKey);
    final title = _getLocalizedPageTitle(context, pageKey);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: pageKey == selectedPageKey
            ? iconColor.withValues(alpha: 0.08)
            : Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            blurRadius: 2,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            PageIdentity.getIconForKey(pageKey),
            color: iconColor,
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF333333),
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        onTap: () {
          Navigator.pop(context);
          onPageSelected(pageKey);
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allowedPages = NavigationPolicy.mainPageKeysFor(currentUser.type);

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd,
                colors: [
                  const Color(0xFFF35535),
                  const Color(0xFFF35535).withValues(alpha: 0.8),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    currentUser.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    currentUser.type.name.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                for (final key in allowedPages)
                  if (key != PageIdentity.home && key != PageIdentity.logout)
                    _buildDrawerItem(context, key),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.logout,
                  color: Colors.red,
                  size: 22,
                ),
              ),
              title: Text(
                AppLocalizations.of(context)!.drawerLogout,
                style: const TextStyle(
                  color: Color(0xFF333333),
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
              trailing:
                  const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
              onTap: () {
                Navigator.pop(context);
                context.read<AuthCubit>().logout();
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getLocalizedPageTitle(BuildContext context, String key) {
    switch (key) {
      case PageIdentity.profile:
        return AppLocalizations.of(context)!.drawerProfile;
      case PageIdentity.wallet:
        return AppLocalizations.of(context)!.drawerWallet;
      case PageIdentity.settings:
        return AppLocalizations.of(context)!.account;
      case PageIdentity.helpSupport:
        return AppLocalizations.of(context)!.drawerHelpSupport;
      case PageIdentity.logout:
        return AppLocalizations.of(context)!.drawerLogout;
      default:
        return PageIdentity.titleFromKey(key);
    }
  }
}
