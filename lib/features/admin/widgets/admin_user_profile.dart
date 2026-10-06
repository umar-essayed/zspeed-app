import 'package:flutter/material.dart';
import 'package:z_speed/features/admin/model/admin_theme.dart';

/// Footer profile section of the dark admin sidebar.
///
/// Shows the logged-in user's avatar (orange initials), name, email,
/// and a logout button — all styled for the dark navy sidebar.
class AdminUserProfile extends StatelessWidget {
  const AdminUserProfile({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.onLogout,
    // Legacy colour params kept for API compat — not used in new design.
    required this.backgroundWhite,
    required this.borderColor,
    required this.primaryOrange,
    required this.accentOrange,
    required this.white,
    required this.textDark,
    required this.textLight,
  });

  final String userName;
  final String userEmail;
  final VoidCallback onLogout;
  final Color backgroundWhite;
  final Color borderColor;
  final Color primaryOrange;
  final Color accentOrange;
  final Color white;
  final Color textDark;
  final Color textLight;

  @override
  Widget build(BuildContext context) {
    final initials =
        (userName.length >= 2 ? userName.substring(0, 2) : userName)
            .toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(
        color: AdminTheme.sidebarSurface,
        border: BorderDirectional(
          top: BorderSide(color: AdminTheme.sidebarBorder, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Orange avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AdminTheme.primaryOrange, AdminTheme.accentOrange],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AdminTheme.primaryOrange.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AdminTheme.sidebarTextActive,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  userEmail,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AdminTheme.sidebarText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.logout_rounded,
              size: 18,
              color: AdminTheme.sidebarText,
            ),
            tooltip: 'Logout',
            onPressed: onLogout,
            splashRadius: 20,
          ),
        ],
      ),
    );
  }
}
