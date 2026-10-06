import 'package:flutter/material.dart';
import 'package:z_speed/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:z_speed/features/auth/cubit/auth_cubit.dart';
import 'package:z_speed/features/admin/model/admin_models.dart';
import 'package:z_speed/features/admin/view/admin_analytics_view.dart';
import 'package:z_speed/features/restaurant/datasource/cuisine_type_datasource.dart';
import 'package:z_speed/features/admin/view/admin_dashboard_view.dart';
import 'package:z_speed/features/admin/view/admin_settings_view.dart';
import 'package:z_speed/features/admin/view/admin_users_view.dart';
import 'package:z_speed/features/admin/view/admin_drivers_view.dart';
import 'package:z_speed/features/admin/view/admin_applications_view.dart';
import 'package:z_speed/features/admin/view/admin_manage_admins_view.dart';
import 'package:z_speed/features/admin/view/admin_promo_codes_view.dart';
import 'package:z_speed/features/admin/widgets/admin_shell.dart';
import 'package:z_speed/features/admin/view/admin_transport_screen.dart';
import 'package:z_speed/features/admin/model/admin_theme.dart';
import 'package:z_speed/features/notification/notification.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/core/injection.dart';

import 'package:z_speed/features/admin/view/admin_vendors_view.dart';
import 'package:z_speed/features/admin/view/admin_logistics_kpi_tab.dart';
import 'package:z_speed/features/admin/cubit/admin_vendors_cubit.dart';
import 'package:z_speed/features/admin/cubit/admin_analytics_cubit.dart';
import 'package:z_speed/features/admin/cubit/admin_dashboard_cubit.dart';
import 'package:z_speed/features/admin/cubit/admin_orders_cubit.dart';
import 'package:z_speed/features/admin/cubit/admin_reports_cubit.dart';
import 'package:z_speed/features/admin/cubit/admin_settings_cubit.dart';
import 'package:z_speed/features/admin/cubit/admin_users_cubit.dart';
import 'package:z_speed/features/admin/datasource/audit_log_datasource.dart';
import 'package:z_speed/features/admin/cubit/admin_application_cubit.dart';
import 'package:z_speed/features/admin/cubit/admin_management_cubit.dart';
import 'package:z_speed/features/admin/cubit/admin_settlements_cubit.dart';
import 'package:z_speed/features/admin/repository/admin_repository.dart';
import 'package:z_speed/features/admin/repository/application_repository.dart';
import 'package:z_speed/features/admin/view/admin_settlements_view.dart';
import 'package:z_speed/features/driver/repository/driver_repository.dart';
import 'package:z_speed/core/services/media_upload_service.dart';
import 'package:z_speed/features/restaurant_owner/repository/restaurant_wallet_repository.dart';
import 'package:z_speed/features/admin/cubit/admin_transport_cubit.dart';
import 'package:z_speed/features/support_chat/cubit/admin_support_cubit.dart';
import 'package:z_speed/features/support_chat/view/admin_support_chats_screen.dart';
import 'package:z_speed/features/admin/cubit/admin_broadcast_cubit.dart';
import 'package:z_speed/features/admin/view/admin_broadcast_notification_view.dart';
import 'package:z_speed/features/admin/cubit/admin_stories_cubit.dart';
import 'package:z_speed/features/admin/view/admin_stories_view.dart';
import 'package:z_speed/features/stories/repository/story_repository.dart';


/// Entry point for admin dashboard.
///
/// Provides ViewModels via MultiProvider and manages tab navigation.
/// Sample data is used temporarily until views are refactored in Step 10.
class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AdminDashboardCubit(
            adminRepository: getIt<AdminRepository>(),
          )..loadDashboard(), // tab 0 — load immediately on open
        ),
        BlocProvider(
          create: (context) => AdminUsersCubit(
            repository: getIt<AdminRepository>(),
            auditLogDatasource: getIt<AuditLogDatasource>(),
            currentUser: context.read<AuthCubit>().state.user,
          ),
        ),
        BlocProvider(
          create: (context) => AdminOrdersCubit(
            repository: getIt<AdminRepository>(),
          ),
        ),
        BlocProvider(
          create: (context) => AdminVendorsCubit(
            repository: getIt<AdminRepository>(),
          ),
        ),
        BlocProvider(
          create: (context) => AdminAnalyticsCubit(
            repository: getIt<AdminRepository>(),
          ),
        ),
        BlocProvider(
          create: (context) => AdminReportsCubit(),
        ),
        BlocProvider(
          create: (context) => AdminSettingsCubit(
            cuisineDatasource: getIt<CuisineTypeDatasource>(),
          ),
        ),
        BlocProvider(
          create: (context) => AdminApplicationCubit(
            repository: getIt<ApplicationRepository>(),
          ),
        ),
        BlocProvider(
          create: (context) => AdminManagementCubit(
            repository: getIt<AdminRepository>(),
          ),
        ),
        BlocProvider(
          create: (context) => AdminSettlementsCubit(
            restaurantWalletRepo: getIt<RestaurantWalletRepository>(),
            driverRepo: getIt<DriverRepository>(),
            uploadService: getIt<MediaUploadService>(),
            notificationDatasource: getIt<NotificationFirebaseDatasource>(),
          ),
        ),
        BlocProvider(
          create: (context) => AdminTransportCubit(FirebaseFirestore.instance),
        ),
        BlocProvider(
          create: (context) => AdminSupportCubit(),
        ),
        BlocProvider(
          create: (context) => AdminBroadcastCubit(
            repository: getIt<AdminRepository>(),
          ),
        ),
        BlocProvider(
          create: (context) => AdminStoriesCubit(
            getIt<StoryRepository>(),
          ),
        ),
      ],
      child: const _AdminAppContent(),
    );
  }
}

class _AdminAppContent extends StatefulWidget {
  const _AdminAppContent();

  @override
  State<_AdminAppContent> createState() => _AdminAppContentState();
}

/// Descriptor for a tab in the admin dashboard.
/// Bundles the nav metadata, the widget builder, and the data loader.
class _TabDescriptor {
  final AdminView view;
  final Widget Function(BuildContext) buildContent;
  final void Function(BuildContext)? onSelected;
  final bool isScrollable;

  const _TabDescriptor({
    required this.view,
    required this.buildContent,
    this.onSelected,
    this.isScrollable = true,
  });
}

class _AdminAppContentState extends State<_AdminAppContent>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _sidebarAnimation;

  AppUser? _currentUser;
  bool _isLoading = true;

  /// Dynamically built based on user role (rebuilt in build() for l10n support).
  List<_TabDescriptor> _tabs = [];

  /// Cached page widgets for the mobile PageView — rebuilt only when _tabs changes.
  List<Widget> _cachedPages = [];

  /// Tracks which tab indices have already loaded their data (lazy loading guard).
  final Set<int> _loadedTabs = {0}; // Dashboard (tab 0) loads immediately.


  @override
  void initState() {
    super.initState();

    // Animation Controller initialization
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _sidebarAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward();

    // Load user data
    _loadUserData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _loadUserData() async {
    try {
      final authCubit = context.read<AuthCubit>();
      final user = authCubit.state.user;
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
      if (mounted) {
        context.read<AdminSupportCubit>().loadSessions();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Build the list of tabs based on user role.
  ///
  /// - **superAdmin**: all 10 tabs (Dashboard, User Management, Order Management,
  ///   Restaurant Management, Analytics, Report Generation, Review Drivers,
  ///   Review Restaurants, System Settings, Admin Management)
  /// - **admin**: 1 tab only — Admin Management
  ///   All other tabs are disabled (commented out) for admin role.
  List<_TabDescriptor> _buildTabs(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tabs = <_TabDescriptor>[];

    // ── SuperAdmin Exclusive Logistics KPI Tab ───────────────────────────
    tabs.add(_TabDescriptor(
      view: AdminView(
        title: l10n.kpiTabTitle,
        shortTitle: l10n.kpiTabShortTitle,
        icon: Icons.dashboard_customize_rounded,
        subtitle: l10n.kpiTabSubtitle,
      ),
      buildContent: (_) => const AdminLogisticsKpiTab(),
    ));

    // Dashboard Overview
    tabs.add(_TabDescriptor(
      view: AdminView(
        title: l10n.navDashboardTitle,
        shortTitle: l10n.drawerDashboard,
        icon: Icons.dashboard_outlined,
        subtitle: l10n.navDashboardSubtitle,
      ),
      buildContent: (_) => _buildDashboardView(),
      onSelected: (ctx) => ctx.read<AdminDashboardCubit>().loadDashboard(),
    ));

    // User Management
    tabs.add(_TabDescriptor(
      view: AdminView(
        title: l10n.navUserManagementTitle,
        shortTitle: l10n.usersTab,
        icon: Icons.people_outlined,
        subtitle: l10n.navUserManagementSubtitle,
      ),
      buildContent: (_) => const AdminUsersView(),
      onSelected: (ctx) => ctx.read<AdminUsersCubit>().loadUsers(),
    ));

    // Vendor Management
    tabs.add(_TabDescriptor(
      view: AdminView(
        title: l10n.vendorManagement,
        shortTitle: l10n.vendorsTab,
        icon: Icons.store_outlined,
        subtitle: l10n.manageActiveRestaurantsSubtitle,
      ),
      buildContent: (_) => const AdminVendorsView(),
      onSelected: (ctx) => ctx.read<AdminVendorsCubit>().loadVendors(),
    ));

    // Story Approvals Moderation
    tabs.add(_TabDescriptor(
      view: AdminView(
        title: l10n.localeName == 'ar' ? 'اعتماد القصص' : 'Story Approvals',
        shortTitle: l10n.localeName == 'ar' ? 'القصص' : 'Stories',
        icon: Icons.auto_awesome_motion_outlined,
        subtitle: l10n.localeName == 'ar' ? 'مراجعة وتوثيق قصص العارضين' : 'Review & approve vendor stories',
      ),
      buildContent: (_) => const AdminStoriesView(),
      onSelected: (ctx) => ctx.read<AdminStoriesCubit>().watchPendingStories(),
      isScrollable: false,
    ));

    // Transport Management
    tabs.add(_TabDescriptor(
      view: AdminView(
        title: l10n.transportSystemTitle,
        shortTitle: l10n.transportTab,
        icon: Icons.local_taxi_outlined,
        subtitle: l10n.transportSystemSubtitle,
      ),
      buildContent: (_) => const AdminTransportScreen(),
      onSelected: (ctx) => ctx.read<AdminTransportCubit>().watchAllTransports(),
      isScrollable: false,
    ));

    // Onboarding Applications Portal
    tabs.add(_TabDescriptor(
      view: AdminView(
        title: l10n.applicationsTitle,
        shortTitle: l10n.applicationsTab,
        icon: Icons.assignment_outlined,
        subtitle: l10n.applicationsSubtitle,
      ),
      buildContent: (_) => const AdminApplicationsView(),
      onSelected: (ctx) =>
          ctx.read<AdminApplicationCubit>().loadApplications(),
    ));

    // Analytics & Reports
    tabs.add(_TabDescriptor(
      view: AdminView(
        title: l10n.navAnalyticsTitle,
        shortTitle: l10n.analyticsTab,
        icon: Icons.analytics_outlined,
        subtitle: l10n.navAnalyticsSubtitle,
      ),
      buildContent: (_) => const AdminAnalyticsView(),
      onSelected: (ctx) => ctx.read<AdminAnalyticsCubit>().loadAnalytics(),
    ));

    // Drivers Directory
    tabs.add(_TabDescriptor(
      view: AdminView(
        title: l10n.activeDrivers,
        shortTitle: l10n.driversTab,
        icon: Icons.directions_car_outlined,
        subtitle: l10n.navReviewDriversSubtitle,
      ),
      buildContent: (_) => const AdminDriversView(),
      onSelected: (ctx) => ctx.read<AdminUsersCubit>().loadUsers(),
    ));

    // System Settings
    tabs.add(_TabDescriptor(
      view: AdminView(
        title: l10n.navSystemSettingsTitle,
        shortTitle: l10n.settingsTab,
        icon: Icons.settings_outlined,
        subtitle: l10n.navSystemSettingsSubtitle,
      ),
      buildContent: (_) => const AdminSettingsView(),
      onSelected: (ctx) => ctx.read<AdminSettingsCubit>().loadSettings(),
    ));

    // Promo Codes
    tabs.add(_TabDescriptor(
      view: AdminView(
        title: l10n.promoCodesTitle,
        shortTitle: l10n.promosTab,
        icon: Icons.local_offer_outlined,
        subtitle: l10n.promoCodesSubtitle,
      ),
      buildContent: (_) => const AdminPromoCodesView(),
    ));

    // Settlements
    tabs.add(_TabDescriptor(
      view: AdminView(
        title: l10n.settlementsTitle,
        shortTitle: l10n.settlementsTab,
        icon: Icons.account_balance_wallet_outlined,
        subtitle: l10n.settlementsSubtitle,
      ),
      buildContent: (_) => const AdminSettlementsView(),
      onSelected: (ctx) => ctx.read<AdminSettlementsCubit>().loadWallets(),
    ));

    // Support Chats
    tabs.add(_TabDescriptor(
      view: AdminView(
        title: l10n.supportChats,
        shortTitle: l10n.supportTab,
        icon: Icons.support_agent_outlined,
        subtitle: l10n.replyToCustomerSupport,
      ),
      isScrollable: false,
      buildContent: (_) => const AdminSupportChatsScreen(),
      onSelected: (ctx) => ctx.read<AdminSupportCubit>().loadSessions(),
    ));

    // Broadcast Notifications (Super Admin)
    if (_currentUser?.type == UserType.superAdmin) {
      tabs.add(_TabDescriptor(
        view: AdminView(
          title: l10n.broadcastTabTitle,
          shortTitle: l10n.broadcastTabTitle,
          icon: Icons.campaign_outlined,
          subtitle: l10n.broadcastTabSubtitle,
        ),
        buildContent: (_) => const AdminBroadcastNotificationView(),
      ));
    }

    // Admin Management
    tabs.add(_TabDescriptor(
      view: AdminView(
        title: l10n.navAdminManagementTitle,
        shortTitle: l10n.adminManagementTab,
        icon: Icons.shield_outlined,
        subtitle: l10n.navAdminManagementSubtitle,
      ),
      buildContent: (_) => const AdminManageAdminsView(),
      onSelected: (ctx) => ctx.read<AdminManagementCubit>().loadAdmins(),
    ));

    return tabs;
  }

  void _logout() async {
    await context.read<AuthCubit>().logout();
  }

  void _navigateToNotifications() {
    final cubit = context.read<NotificationCubit>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider<NotificationCubit>.value(
          value: cubit,
          child: const NotificationListPage(),
        ),
      ),
    );
  }

  /// Called when tab changes - lazily loads data only on first visit.
  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });

    if (!_loadedTabs.contains(index)) {
      _loadedTabs.add(index);
      _tabs[index].onSelected?.call(context);
    }
  }

  Widget _getCurrentView() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(_currentIndex),
        child: _tabs[_currentIndex].buildContent(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoading) {
      _tabs = _buildTabs(context);
      _cachedPages = _tabs.map((tab) => tab.buildContent(context)).toList();
    }

    if (_isLoading || _tabs.isEmpty) {
      return Scaffold(
        backgroundColor: AdminTheme.contentBg,
        body: Center(
          child: CircularProgressIndicator(
            color: AdminTheme.primaryOrange,
          ),
        ),
      );
    }

    final supportIndex = _tabs.indexWhere((t) => t.view.icon == Icons.support_agent_outlined);
    final isSupportSelected = _currentIndex == supportIndex;

    // Badge count from cubit sessions
    final unreadSupportCount = context.watch<AdminSupportCubit>().state.sessions
        .where((s) => s.unreadByAdmin && s.isOpen)
        .length;

    final showFab = !isSupportSelected && supportIndex >= 0;

    final fabWidget = showFab
        ? Stack(
            clipBehavior: Clip.none,
            children: [
              FloatingActionButton(
                onPressed: () => _onTabChanged(supportIndex),
                backgroundColor: AdminTheme.primaryOrange,
                foregroundColor: Colors.white,
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.support_agent, size: 26),
              ),
              if (unreadSupportCount > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Text(
                      unreadSupportCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          )
        : null;

    return Scaffold(
      backgroundColor: AdminTheme.contentBg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 768;

          if (isMobile) {
            return _buildMobileLayout(fabWidget);
          } else {
            return _buildDesktopLayout();
          }
        },
      ),
    );
  }

  List<AdminShellNavItem> get _navItems => _tabs
      .map(
        (tab) => AdminShellNavItem(
          icon: tab.view.icon,
          title: tab.view.title,
          subtitle: tab.view.subtitle,
          bottomLabel: tab.view.shortTitle ?? tab.view.title,
        ),
      )
      .toList();

  Widget _buildDesktopLayout() {
    return AdminDesktopShell(
      navItems: _navItems,
      currentIndex: _currentIndex,
      onIndexSelected: _onTabChanged,
      sidebarAnimation: _sidebarAnimation,
      currentUserName: _currentUser?.name ?? 'Admin User',
      currentUserEmail: _currentUser?.email ?? 'admin@vendorhub.com',
      onLogout: _logout,
      onNotificationTap: _navigateToNotifications,
      unreadCount: context.watch<NotificationCubit>().state.unreadCount,
      content: _getCurrentView(),
      isScrollable: _tabs[_currentIndex].isScrollable,
      surfaceWhite: AdminTheme.surfaceWhite,
      backgroundWhite: AdminTheme.backgroundWhite,
      borderColor: AdminTheme.borderColor,
      primaryOrange: AdminTheme.primaryOrange,
      accentOrange: AdminTheme.accentOrange,
      white: AdminTheme.white,
      textDark: AdminTheme.textDark,
      textMedium: AdminTheme.textMedium,
      textLight: AdminTheme.textLight,
    );
  }

  Widget _buildMobileLayout(Widget? floatingActionButton) {
    return AdminMobileShell(
      navItems: _navItems,
      currentIndex: _currentIndex,
      onIndexSelected: _onTabChanged,
      currentUserName: _currentUser?.name ?? 'Admin User',
      currentUserEmail: _currentUser?.email ?? 'admin@vendorhub.com',
      onLogout: _logout,
      onNotificationTap: _navigateToNotifications,
      unreadCount: context.watch<NotificationCubit>().state.unreadCount,
      pages: _cachedPages,
      pageScrollable: _tabs.map((t) => t.isScrollable).toList(),
      floatingActionButton: floatingActionButton,
      surfaceWhite: AdminTheme.surfaceWhite,
      backgroundWhite: AdminTheme.backgroundWhite,
      borderColor: AdminTheme.borderColor,
      primaryOrange: AdminTheme.primaryOrange,
      accentOrange: AdminTheme.accentOrange,
      white: AdminTheme.white,
      textDark: AdminTheme.textDark,
      textMedium: AdminTheme.textMedium,
      textLight: AdminTheme.textLight,
    );
  }

  // Dashboard View
  Widget _buildDashboardView() {
    // Find tab indices by icon (stable across locales)
    final usersIndex =
        _tabs.indexWhere((t) => t.view.icon == Icons.people_outlined);
    final ordersIndex =
        _tabs.indexWhere((t) => t.view.icon == Icons.shopping_bag_outlined);
    final analyticsIndex =
        _tabs.indexWhere((t) => t.view.icon == Icons.analytics_outlined);

    return AdminDashboardView(
      onStatCardTap: (index) {
        switch (index) {
          case 0: // Users
            if (usersIndex >= 0) _onTabChanged(usersIndex);
          case 1: // Orders
            if (ordersIndex >= 0) {
              _onTabChanged(ordersIndex);
            } else if (analyticsIndex >= 0) {
              _onTabChanged(analyticsIndex);
            }
          case 2: // Revenue/Analytics
            if (analyticsIndex >= 0) _onTabChanged(analyticsIndex);
          case 3: // Pending Orders
            if (ordersIndex >= 0) {
              _onTabChanged(ordersIndex);
            } else if (analyticsIndex >= 0) {
              _onTabChanged(analyticsIndex);
            }
        }
      },
    );
  }
}
