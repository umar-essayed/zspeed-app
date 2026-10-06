import 'package:flutter/material.dart';
import 'package:z_speed/features/admin/model/admin_theme.dart';
import 'package:z_speed/l10n/app_localizations.dart';

/// Top section of the dark admin sidebar.
///
/// Shows the app logo badge and "Admin Panel" brand label
/// on a deep navy background.
class AdminSidebarHeader extends StatelessWidget {
  const AdminSidebarHeader({
    super.key,
    required this.userName,
    // Legacy colour params kept for API compatibility — not used in new design.
    required this.primaryOrange,
    required this.accentOrange,
    required this.white,
    required this.borderColor,
  });

  final String userName;
  final Color primaryOrange;
  final Color accentOrange;
  final Color white;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AdminTheme.sidebarBg,
        border: BorderDirectional(
          bottom: BorderSide(color: AdminTheme.sidebarBorder, width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Row(
            children: [
              // Orange glow logo badge
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AdminTheme.primaryOrange, AdminTheme.accentOrange],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AdminTheme.primaryOrange.withValues(alpha: 0.45),
                      blurRadius: 18,
                      spreadRadius: -2,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.adminPanelLabel,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AdminTheme.sidebarTextActive,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
