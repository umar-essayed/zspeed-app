import 'package:flutter/material.dart';
import 'package:z_speed/features/admin/model/admin_theme.dart';
import 'package:z_speed/l10n/app_localizations.dart';

/// Frosted-glass top bar for the admin content area.
///
/// Shows the current page title, a pill search field, and a
/// notification bell — all on a clean white surface with a
/// soft bottom shadow (no hard border).
class AdminTopBar extends StatelessWidget {
  const AdminTopBar({
    super.key,
    required this.title,
    required this.subtitle,
    // Legacy colour params kept for API compat.
    required this.surfaceWhite,
    required this.backgroundWhite,
    required this.borderColor,
    required this.textDark,
    required this.textMedium,
    required this.textLight,
    required this.primaryOrange,
    this.onNotificationTap,
    this.unreadCount = 0,
  });

  final String title;
  final String subtitle;
  final Color surfaceWhite;
  final Color backgroundWhite;
  final Color borderColor;
  final Color textDark;
  final Color textMedium;
  final Color textLight;
  final Color primaryOrange;
  final VoidCallback? onNotificationTap;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Page title + subtitle
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AdminTheme.textDark,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: AdminTheme.textLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Search + notification row
          Row(
            children: [
              // Pill search field
              Container(
                width: 220,
                height: 42,
                decoration: BoxDecoration(
                  color: AdminTheme.contentBg,
                  borderRadius: BorderRadius.circular(21),
                  border: Border.all(
                    color: AdminTheme.borderColor,
                    width: 1,
                  ),
                ),
                child: TextField(
                  textAlignVertical: TextAlignVertical.center,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.searchHint,
                    hintStyle: TextStyle(
                      color: AdminTheme.textLight,
                      fontSize: 13,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: AdminTheme.textLight,
                      size: 18,
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 42,
                    ),
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.only(right: 12),
                  ),
                  style: TextStyle(fontSize: 13, color: AdminTheme.textDark),
                ),
              ),
              const SizedBox(width: 12),

              // Notification bell button
              _NotificationButton(
                unreadCount: unreadCount,
                onTap: onNotificationTap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({
    required this.unreadCount,
    this.onTap,
  });

  final int unreadCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: AdminTheme.contentBg,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AdminTheme.borderColor, width: 1),
              ),
              child: Icon(
                Icons.notifications_outlined,
                size: 20,
                color: AdminTheme.textMedium,
              ),
            ),
          ),
        ),
        if (unreadCount > 0)
          PositionedDirectional(
            end: 2,
            top: 2,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: AdminTheme.primaryOrange,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}
