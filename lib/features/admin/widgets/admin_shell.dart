import 'package:flutter/material.dart';
import 'package:z_speed/l10n/app_localizations.dart';

import 'package:z_speed/features/admin/model/admin_theme.dart';
import 'package:z_speed/features/admin/widgets/admin_nav_item.dart';
import 'package:z_speed/features/admin/widgets/admin_sidebar_header.dart';
import 'package:z_speed/features/admin/widgets/admin_top_bar.dart';
import 'package:z_speed/features/admin/widgets/admin_user_profile.dart';

class AdminShellNavItem {
  AdminShellNavItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.bottomLabel,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String bottomLabel;
}

// ── Desktop Shell ──────────────────────────────────────────────────────────

/// Desktop admin shell with a dark navy sidebar and light content area.
///
/// The `sidebarAnimation` drives a combined fade + horizontal slide
/// on the sidebar for a smoother entrance than the old ScaleTransition.
class AdminDesktopShell extends StatelessWidget {
  const AdminDesktopShell({
    super.key,
    required this.navItems,
    required this.currentIndex,
    required this.onIndexSelected,
    required this.sidebarAnimation,
    required this.currentUserName,
    required this.currentUserEmail,
    required this.onLogout,
    required this.content,
    this.isScrollable = true,
    // Legacy colour params kept for API compat — forwarded to sub-widgets.
    required this.surfaceWhite,
    required this.backgroundWhite,
    required this.borderColor,
    required this.primaryOrange,
    required this.accentOrange,
    required this.white,
    required this.textDark,
    required this.textMedium,
    required this.textLight,
    this.onNotificationTap,
    this.unreadCount = 0,
  });

  final List<AdminShellNavItem> navItems;
  final int currentIndex;
  final ValueChanged<int> onIndexSelected;
  final Animation<double> sidebarAnimation;
  final String currentUserName;
  final String currentUserEmail;
  final VoidCallback onLogout;
  final Widget content;
  final bool isScrollable;
  final Color surfaceWhite;
  final Color backgroundWhite;
  final Color borderColor;
  final Color primaryOrange;
  final Color accentOrange;
  final Color white;
  final Color textDark;
  final Color textMedium;
  final Color textLight;
  final VoidCallback? onNotificationTap;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ── Dark Sidebar ──────────────────────────────────────────────
        FadeTransition(
          opacity: sidebarAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(-0.04, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: sidebarAnimation,
              curve: Curves.easeOutCubic,
            )),
            child: Container(
              width: 260,
              color: AdminTheme.sidebarBg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AdminSidebarHeader(
                    userName: currentUserName,
                    primaryOrange: primaryOrange,
                    accentOrange: accentOrange,
                    white: white,
                    borderColor: borderColor,
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      itemCount: navItems.length,
                      itemBuilder: (context, index) {
                        final item = navItems[index];
                        return AdminNavItem(
                          icon: item.icon,
                          title: item.bottomLabel,
                          isSelected: currentIndex == index,
                          onTap: () => onIndexSelected(index),
                          primaryOrange: primaryOrange,
                          textMedium: textMedium,
                        );
                      },
                    ),
                  ),
                  AdminUserProfile(
                    userName: currentUserName,
                    userEmail: currentUserEmail,
                    onLogout: onLogout,
                    backgroundWhite: backgroundWhite,
                    borderColor: borderColor,
                    primaryOrange: primaryOrange,
                    accentOrange: accentOrange,
                    white: white,
                    textDark: textDark,
                    textLight: textLight,
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Content Area ──────────────────────────────────────────────
        Expanded(
          child: Container(
            color: AdminTheme.contentBg,
            child: Column(
              children: [
                AdminTopBar(
                  title: navItems[currentIndex].title,
                  subtitle: navItems[currentIndex].subtitle,
                  surfaceWhite: surfaceWhite,
                  backgroundWhite: backgroundWhite,
                  borderColor: borderColor,
                  textDark: textDark,
                  textMedium: textMedium,
                  textLight: textLight,
                  primaryOrange: primaryOrange,
                  onNotificationTap: onNotificationTap,
                  unreadCount: unreadCount,
                ),
                Expanded(
                  child: isScrollable
                      ? SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.all(28),
                            child: content,
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(28),
                          child: content,
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Mobile Shell ───────────────────────────────────────────────────────────

/// Mobile admin shell with a hamburger drawer using the dark sidebar style.
///
/// Uses a scrollable [TabBar] at the bottom so all nav items fit without
/// crowding, and supports left/right swipe via [PageView].
class AdminMobileShell extends StatefulWidget {
  const AdminMobileShell({
    super.key,
    required this.navItems,
    required this.currentIndex,
    required this.onIndexSelected,
    required this.currentUserName,
    required this.currentUserEmail,
    required this.onLogout,
    required this.pages,
    this.pageScrollable,
    this.floatingActionButton,
    // Legacy colour params kept for API compat.
    required this.surfaceWhite,
    required this.backgroundWhite,
    required this.borderColor,
    required this.primaryOrange,
    required this.accentOrange,
    required this.white,
    required this.textDark,
    required this.textMedium,
    required this.textLight,
    this.onNotificationTap,
    this.unreadCount = 0,
  });

  final List<AdminShellNavItem> navItems;
  final int currentIndex;
  final ValueChanged<int> onIndexSelected;
  final String currentUserName;
  final String currentUserEmail;
  final VoidCallback onLogout;
  /// One widget per nav item — rendered inside [PageView] for swipe support.
  final List<Widget> pages;
  final List<bool>? pageScrollable;
  final Widget? floatingActionButton;
  final Color surfaceWhite;
  final Color backgroundWhite;
  final Color borderColor;
  final Color primaryOrange;
  final Color accentOrange;
  final Color white;
  final Color textDark;
  final Color textMedium;
  final Color textLight;
  final VoidCallback? onNotificationTap;
  final int unreadCount;

  @override
  State<AdminMobileShell> createState() => _AdminMobileShellState();
}

class _AdminMobileShellState extends State<AdminMobileShell> {
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.contentBg,
      floatingActionButton: widget.floatingActionButton,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        title: Text(
          widget.navItems[widget.currentIndex].title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AdminTheme.textDark,
            letterSpacing: -0.3,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        iconTheme: IconThemeData(color: AdminTheme.textDark),
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: Icon(
                  Icons.notifications_outlined,
                  color: AdminTheme.textMedium,
                ),
                onPressed: widget.onNotificationTap,
              ),
              if (widget.unreadCount > 0)
                PositionedDirectional(
                  end: 10,
                  top: 10,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: AdminTheme.primaryOrange,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      drawer: Drawer(
        width: 272,
        backgroundColor: AdminTheme.sidebarBg,
        child: Column(
          children: [
            AdminSidebarHeader(
              userName: widget.currentUserName,
              primaryOrange: widget.primaryOrange,
              accentOrange: widget.accentOrange,
              white: widget.white,
              borderColor: widget.borderColor,
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemCount: widget.navItems.length,
                itemBuilder: (context, index) {
                  final item = widget.navItems[index];
                  return AdminNavItem(
                    icon: item.icon,
                    title: item.bottomLabel,
                    isSelected: widget.currentIndex == index,
                    onTap: () {
                      Navigator.of(context).pop(); // close drawer
                      widget.onIndexSelected(index);
                    },
                    primaryOrange: widget.primaryOrange,
                    textMedium: widget.textMedium,
                  );
                },
              ),
            ),
            AdminUserProfile(
              userName: widget.currentUserName,
              userEmail: widget.currentUserEmail,
              onLogout: widget.onLogout,
              backgroundWhite: widget.backgroundWhite,
              borderColor: widget.borderColor,
              primaryOrange: widget.primaryOrange,
              accentOrange: widget.accentOrange,
              white: widget.white,
              textDark: widget.textDark,
              textLight: widget.textLight,
            ),
          ],
        ),
      ),
      body: (widget.pageScrollable != null && widget.pageScrollable!.length > widget.currentIndex && !widget.pageScrollable![widget.currentIndex])
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: widget.pages[widget.currentIndex],
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: widget.pages[widget.currentIndex],
              ),
            ),
      // Bottom nav shows first 5 tabs only — rest are accessible via drawer.
      bottomNavigationBar: widget.navItems.length >= 2
          ? _BottomNavBar(
              navItems: widget.navItems,
              currentIndex: widget.currentIndex,
              onTap: widget.onIndexSelected,
            )
          : null,
    );
  }
}

// ── Bottom Nav Bar (max 5 visible tabs) ───────────────────────────────────

class _BottomNavBar extends StatelessWidget {
  static const int _maxVisible = 5;

  const _BottomNavBar({
    required this.navItems,
    required this.currentIndex,
    required this.onTap,
  });

  final List<AdminShellNavItem> navItems;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    // Show only the first _maxVisible tabs; rest reachable via drawer.
    final visible = navItems.take(_maxVisible).toList();
    final isCurrentVisible = currentIndex < _maxVisible;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AdminTheme.borderColor, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              // Visible tabs — each gets equal width
              ...List.generate(visible.length, (i) {
                final item = visible[i];
                final isSelected = isCurrentVisible && currentIndex == i;
                return Expanded(
                  child: InkWell(
                    onTap: () => onTap(i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item.icon,
                          size: 22,
                          color: isSelected
                              ? AdminTheme.primaryOrange
                              : AdminTheme.textLight,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.bottomLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isSelected
                                ? AdminTheme.primaryOrange
                                : AdminTheme.textLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // Active indicator dot
                        if (isSelected)
                          Container(
                            margin: const EdgeInsets.only(top: 3),
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AdminTheme.primaryOrange,
                              shape: BoxShape.circle,
                            ),
                          )
                        else
                          const SizedBox(height: 7),
                      ],
                    ),
                  ),
                );
              }),
              // "More" button if there are hidden tabs
              if (navItems.length > _maxVisible)
                Expanded(
                  child: Builder(
                    builder: (ctx) => InkWell(
                      onTap: () => Scaffold.of(ctx).openDrawer(),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.menu,
                            size: 22,
                            color: !isCurrentVisible
                                ? AdminTheme.primaryOrange
                                : AdminTheme.textLight,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            AppLocalizations.of(ctx)?.drawerMore ?? 'More',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: !isCurrentVisible
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: !isCurrentVisible
                                  ? AdminTheme.primaryOrange
                                  : AdminTheme.textLight,
                            ),
                          ),
                          if (!isCurrentVisible)
                            Container(
                              margin: const EdgeInsets.only(top: 3),
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: AdminTheme.primaryOrange,
                                shape: BoxShape.circle,
                              ),
                            )
                          else
                            const SizedBox(height: 7),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
