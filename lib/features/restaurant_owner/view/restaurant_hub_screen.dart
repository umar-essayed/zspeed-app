import 'package:z_speed/l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/features/restaurant_owner/view/restaurant_analytics_screen.dart';
import 'package:z_speed/features/restaurant_owner/view/restaurant_extra_pages.dart';
import 'package:z_speed/features/restaurant_owner/view/restaurant_orders_screen.dart';
import 'package:z_speed/features/restaurant_owner/view/restaurant_overview_screen.dart';
import 'package:z_speed/features/restaurant_owner/view/restaurant_profile_page.dart';
import 'package:z_speed/features/restaurant_owner/view/restaurant_settings_screen.dart';
import 'package:z_speed/features/restaurant_owner/screens/delivery_fee_settings_screen.dart';
import 'package:z_speed/features/restaurant_owner/widgets/menu_manager.dart';
import 'package:z_speed/features/stories/view/vendor_stories_screen.dart';
import 'package:z_speed/features/restaurant_owner/widgets/restaurant_drawer.dart';
import 'package:z_speed/core/injection.dart';
import 'package:z_speed/features/notification/notification.dart';
import 'package:z_speed/features/restaurant_owner/cubit/restaurant_dashboard_cubit.dart';
import 'package:z_speed/features/restaurant_owner/cubit/restaurant_dashboard_state.dart';
import 'package:z_speed/features/restaurant_owner/cubit/restaurant_wallet_cubit.dart';
import 'package:z_speed/features/restaurant_owner/repository/restaurant_wallet_repository.dart';
import 'package:z_speed/features/restaurant_owner/view/restaurant_wallet_screen.dart';
import 'package:z_speed/features/restaurant/datasource/restaurant_firebase_datasource.dart';
import 'package:z_speed/features/restaurant/model/restaurant.dart';
import 'package:z_speed/core/enums/order_enums.dart';
import 'package:z_speed/core/enums/user_enums.dart';
import 'package:z_speed/features/restaurant_owner/view/restaurant_prescriptions_screen.dart';
import 'package:z_speed/features/auth/cubit/auth_cubit.dart';

// NOTE: The main() in this file is for demo/dev only.
// Production entrypoint is lib/main.dart.

void main() {
  runApp(const RestaurantHubApp());
}

class RestaurantHubApp extends StatelessWidget {
  const RestaurantHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vendor Dashboard',
      theme: ThemeData(
        primaryColor: const Color(0xFFF35535),
        primarySwatch: Colors.orange,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFFF35535),
          secondary: Color(0xFFFFA726),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 2,
          centerTitle: false,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF35535),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        fontFamily: 'Inter',
      ),
      home: const MainDashboard(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _selectedIndex = RestaurantPage.dashboard.pageIndex;
  bool _hideBottomNavBar = false;
  late final RestaurantDashboardCubit _dashboardCubit;

  @override
  void initState() {
    super.initState();
    _dashboardCubit = RestaurantDashboardCubit();
  }

  @override
  void dispose() {
    _dashboardCubit.close();
    super.dispose();
  }

  /// Maps a [RestaurantPage] index to its corresponding screen widget.
  Widget _screenForIndex(int index, {String? restaurantId}) {
    switch (index) {
      case 0: // Dashboard / Overview
        return const OverviewScreen();
      case 1: // Orders
        return const RestaurantOrdersScreen();
      case 2: // Menu
        return const MenuManagerPage();
      case 3: // Analytics
        return const RestaurantAnalyticsScreen();
      case 4: // Profile
        return const RestaurantProfilePage();
      case 5: // Promotions
        return const RestaurantPromotionsPage();
      case 6: // Reviews
        return RestaurantReviewsPage(restaurantId: restaurantId ?? '');
      case 7: // Settings
        return const SettingsScreen();
      case 8: // Delivery Fees
        return const _DeliveryFeeWrapper();
      case 9: // Support
        return const RestaurantSupportPage();
      case 10: // About
        return const RestaurantAboutPage();
      case 11: // Wallet
        return RestaurantWalletScreen(restaurantId: restaurantId ?? '');
      case 12: // Prescriptions
        return PharmacyPrescriptionsScreen(
          restaurantId: restaurantId ?? '',
          onChatStateChanged: (isChatting) {
            setState(() {
              _hideBottomNavBar = isChatting;
            });
          },
        );
      case 13: // Stories
        return const VendorStoriesScreen();
      default:
        return const OverviewScreen();
    }
  }

  IconData _iconForVendorType(VendorType? type) {
    switch (type) {
      case VendorType.supermarket:
        return Icons.shopping_cart_rounded;
      case VendorType.pharmacy:
        return Icons.local_pharmacy_rounded;
      case VendorType.bookstore:
        return Icons.menu_book_rounded;
      case VendorType.homeFurnishing:
        return Icons.chair_rounded;
      case VendorType.meatAndProteins:
        return Icons.restaurant_menu_rounded;
      case VendorType.clothes:
        return Icons.checkroom_rounded;
      case VendorType.buyAndSell:
        return Icons.swap_horiz_rounded;
      case VendorType.electronics:
        return Icons.devices_rounded;
      default:
        return Icons.restaurant_rounded;
    }
  }

  String _titleForIndex(
    BuildContext context,
    int index,
    VendorType? vendorType,
  ) {
    final page = RestaurantPage.values.firstWhere(
      (p) => p.pageIndex == index,
      orElse: () => RestaurantPage.dashboard,
    );
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    switch (page) {
      case RestaurantPage.dashboard:
        return l10n.drawerDashboard;
      case RestaurantPage.orders:
        return l10n.drawerOrders;
      case RestaurantPage.menu:
        if (locale == 'ar') {
          return switch (vendorType) {
            VendorType.pharmacy => 'الأدوية',
            VendorType.supermarket => 'المنتجات',
            VendorType.bookstore => 'الكتب والأدوات المكتبية',
            VendorType.homeFurnishing => 'الأثاث',
            _ => l10n.drawerMenu,
          };
        } else {
          return switch (vendorType) {
            VendorType.pharmacy => l10n.medicineAndHealthProducts,
            VendorType.supermarket => l10n.groceriesAndDailyNeeds,
            VendorType.bookstore => l10n.bookstore,
            VendorType.homeFurnishing => l10n.homeFurnishing,
            _ => l10n.drawerMenu,
          };
        }
      case RestaurantPage.analytics:
        return l10n.drawerAnalytics;
      case RestaurantPage.profile:
        return l10n.drawerProfile;
      case RestaurantPage.promotions:
        return l10n.drawerPromotions;
      case RestaurantPage.reviews:
        return l10n.drawerReviews;
      case RestaurantPage.settings:
        return l10n.drawerSettings;
      case RestaurantPage.deliveryFees:
        return l10n.drawerDeliveryFees;
      case RestaurantPage.support:
        return l10n.drawerSupport;
      case RestaurantPage.about:
        return l10n.drawerAbout;
      case RestaurantPage.wallet:
        return 'Wallet';
      case RestaurantPage.prescriptions:
        return locale == 'ar' ? 'الروشتات والمحادثات' : 'Prescription Chats';
      case RestaurantPage.stories:
        return locale == 'ar' ? 'القصص اليومية' : 'Daily Stories';
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _dashboardCubit),
        BlocProvider(
          create: (_) => RestaurantWalletCubit(
            walletRepo: getIt<RestaurantWalletRepository>(),
            notificationDatasource: getIt<NotificationFirebaseDatasource>(),
          ),
        ),
      ],
      child: BlocBuilder<RestaurantDashboardCubit, RestaurantDashboardState>(
        builder: (context, state) {
          // Count pending orders for drawer badge
          final pendingCount = state.recentOrders
              .where((o) => o.status == OrderStatus.pending)
              .length;

          return Scaffold(
            backgroundColor: Colors.grey[50],
            body: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 768;

                if (isMobile) {
                  return Scaffold(
                    backgroundColor: Colors.grey[50],
                    appBar:
                        ((_hideBottomNavBar && _selectedIndex == 12) ||
                            _selectedIndex == 2)
                        ? null
                        : AppBar(
                            leading: Builder(
                              builder: (ctx) => IconButton(
                                icon: const Icon(Icons.menu, size: 26),
                                onPressed: () => Scaffold.of(ctx).openDrawer(),
                              ),
                            ),
                            title: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF35535),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _iconForVendorType(
                                      state.restaurant?.vendorType,
                                    ),
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _titleForIndex(
                                      context,
                                      _selectedIndex,
                                      state.restaurant?.vendorType,
                                    ),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      color: Color(0xFFF35535),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            actions: [
                              NotificationBell(
                                onTap: () {
                                  final cubit = context
                                      .read<NotificationCubit>();
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => BlocProvider.value(
                                        value: cubit,
                                        child: NotificationListPage(
                                          onNavigateToPage: (index) {
                                            setState(
                                              () => _selectedIndex = index,
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 4),
                            ],
                            backgroundColor: Colors.white,
                            elevation: 2,
                          ),
                    drawer: RestaurantDrawer(
                      selectedIndex: _selectedIndex,
                      onPageSelected: (index) {
                        setState(() => _selectedIndex = index);
                        Navigator.of(context).pop(); // close drawer
                      },
                      restaurant: state.restaurant,
                      pendingOrderCount: pendingCount,
                    ),
                    body: _screenForIndex(
                      _selectedIndex,
                      restaurantId: state.restaurant?.id,
                    ),
                    bottomNavigationBar:
                        _hideBottomNavBar && _selectedIndex == 12
                        ? null
                        : _BottomNavBar(
                            selectedIndex: _selectedIndex,
                            pendingOrderCount: pendingCount,
                            vendorType: state.restaurant?.vendorType,
                            onTap: (index) {
                              setState(() {
                                _selectedIndex = index;
                                _hideBottomNavBar = false;
                              });
                            },
                          ),
                  );
                } else {
                  // Desktop Layout with permanent sidebar
                  return Row(
                    children: [
                      _buildDesktopSidebar(context, state, pendingCount),
                      Expanded(
                        child: Scaffold(
                          backgroundColor: Colors.grey[50],
                          appBar: _selectedIndex == 2
                              ? null
                              : AppBar(
                                  automaticallyImplyLeading: false,
                                  title: Text(
                                    _titleForIndex(
                                      context,
                                      _selectedIndex,
                                      state.restaurant?.vendorType,
                                    ),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 22,
                                      color: Color(0xFFF35535),
                                    ),
                                  ),
                                  actions: [
                                    NotificationBell(
                                      onTap: () {
                                        final cubit = context
                                            .read<NotificationCubit>();
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => BlocProvider.value(
                                              value: cubit,
                                              child: NotificationListPage(
                                                onNavigateToPage: (index) {
                                                  setState(
                                                    () =>
                                                        _selectedIndex = index,
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 16),
                                  ],
                                  backgroundColor: Colors.white,
                                  elevation: 1,
                                ),
                          body: _screenForIndex(
                            _selectedIndex,
                            restaurantId: state.restaurant?.id,
                          ),
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildDesktopSidebar(
    BuildContext context,
    RestaurantDashboardState state,
    int pendingCount,
  ) {
    const orange = Color(0xFFF35535);
    final restaurant = state.restaurant;
    final name = restaurant?.name ?? AppLocalizations.of(context)!.myRestaurant;
    final isOpen = restaurant?.isOpen ?? false;
    final logoUrl = restaurant?.logoUrl;

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey[200]!, width: 1)),
      ),
      child: Column(
        children: [
          // ── Header (Logo + Name + Open status) ──
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [orange, Color(0xFFE64A19)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: logoUrl != null && logoUrl.isNotEmpty
                          ? Image.network(
                              logoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Icon(
                                _iconForVendorType(restaurant?.vendorType),
                                color: orange,
                                size: 24,
                              ),
                            )
                          : Icon(
                              _iconForVendorType(restaurant?.vendorType),
                              color: orange,
                              size: 24,
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isOpen
                                  ? Colors.green.withValues(alpha: 0.3)
                                  : Colors.red.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              isOpen
                                  ? AppLocalizations.of(context)!.open
                                  : AppLocalizations.of(context)!.closed,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Navigation List ──
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildSidebarSectionLabel(
                  AppLocalizations.of(context)!.drawerMain,
                ),
                _buildSidebarItem(context, RestaurantPage.dashboard),
                _buildSidebarItem(
                  context,
                  RestaurantPage.orders,
                  badge: pendingCount > 0 ? pendingCount : null,
                ),
                _buildSidebarItem(context, RestaurantPage.menu),
                _buildSidebarItem(context, RestaurantPage.analytics),
                _buildSidebarItem(context, RestaurantPage.profile),
                if (restaurant?.vendorType == VendorType.pharmacy)
                  _buildSidebarItem(context, RestaurantPage.prescriptions),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Divider(height: 1),
                ),

                _buildSidebarSectionLabel(
                  AppLocalizations.of(context)!.drawerEngage,
                ),
                _buildSidebarItem(context, RestaurantPage.promotions),
                _buildSidebarItem(context, RestaurantPage.reviews),
                _buildSidebarItem(context, RestaurantPage.stories),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Divider(height: 1),
                ),

                _buildSidebarSectionLabel(
                  AppLocalizations.of(context)!.drawerMore,
                ),
                _buildSidebarItem(context, RestaurantPage.wallet),
                _buildSidebarItem(context, RestaurantPage.settings),
                _buildSidebarItem(context, RestaurantPage.deliveryFees),
                _buildSidebarItem(context, RestaurantPage.support),
                _buildSidebarItem(context, RestaurantPage.about),
              ],
            ),
          ),

          const Divider(height: 1),
          _buildSidebarLogoutButton(context),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildSidebarSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 20, top: 12, bottom: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.grey[400],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSidebarItem(
    BuildContext context,
    RestaurantPage page, {
    int? badge,
  }) {
    final isSelected = _selectedIndex == page.pageIndex;
    const orange = Color(0xFFF35535);
    final locale = Localizations.localeOf(context).languageCode;
    final l10n = AppLocalizations.of(context)!;

    String label = switch (page) {
      RestaurantPage.dashboard => l10n.drawerDashboard,
      RestaurantPage.orders => l10n.drawerOrders,
      RestaurantPage.menu => l10n.drawerMenu,
      RestaurantPage.analytics => l10n.drawerAnalytics,
      RestaurantPage.profile => l10n.drawerProfile,
      RestaurantPage.promotions => l10n.drawerPromotions,
      RestaurantPage.reviews => l10n.drawerReviews,
      RestaurantPage.settings => l10n.drawerSettings,
      RestaurantPage.deliveryFees => l10n.drawerDeliveryFees,
      RestaurantPage.support => l10n.drawerSupport,
      RestaurantPage.about => l10n.drawerAbout,
      RestaurantPage.wallet => 'Wallet',
      RestaurantPage.prescriptions =>
        locale == 'ar' ? 'الروشتات والمحادثات' : 'Prescription Chats',
      RestaurantPage.stories =>
        locale == 'ar' ? 'القصص اليومية' : 'Daily Stories',
    };

    if (page == RestaurantPage.menu) {
      final type = _dashboardCubit.state.restaurant?.vendorType;
      if (locale == 'ar') {
        label = switch (type) {
          VendorType.supermarket => 'المنتجات',
          VendorType.pharmacy => 'الأدوية',
          VendorType.bookstore => 'الكتب والأدوات المكتبية',
          VendorType.homeFurnishing => 'الأثاث',
          _ => l10n.drawerMenu,
        };
      } else {
        label = switch (type) {
          VendorType.supermarket => l10n.groceriesAndDailyNeeds,
          VendorType.pharmacy => l10n.medicineAndHealthProducts,
          VendorType.bookstore => l10n.bookstore,
          VendorType.homeFurnishing => l10n.homeFurnishing,
          _ => l10n.drawerMenu,
        };
      }
    }

    IconData icon = isSelected ? page.activeIcon : page.icon;
    if (page == RestaurantPage.menu) {
      final type = _dashboardCubit.state.restaurant?.vendorType;
      icon = switch (type) {
        VendorType.supermarket =>
          isSelected ? Icons.shopping_basket : Icons.shopping_basket_outlined,
        VendorType.pharmacy =>
          isSelected ? Icons.medical_services : Icons.medical_services_outlined,
        VendorType.bookstore =>
          isSelected ? Icons.auto_stories : Icons.auto_stories_outlined,
        VendorType.homeFurnishing =>
          isSelected ? Icons.chair : Icons.chair_outlined,
        _ => isSelected ? page.activeIcon : page.icon,
      };
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? orange.withValues(alpha: 0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        dense: true,
        visualDensity: const VisualDensity(vertical: -1),
        leading: Icon(
          icon,
          color: isSelected ? orange : Colors.grey[600],
          size: 20,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? orange : const Color(0xFF2D3748),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
        trailing: badge != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge > 99 ? '99+' : '$badge',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onTap: () {
          setState(() {
            _selectedIndex = page.pageIndex;
          });
        },
      ),
    );
  }

  Widget _buildSidebarLogoutButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: ListTile(
        dense: true,
        visualDensity: const VisualDensity(vertical: -1),
        leading: Icon(Icons.logout, color: Colors.red[400], size: 20),
        title: Text(
          AppLocalizations.of(context)!.logout,
          style: TextStyle(
            color: Colors.red[400],
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onTap: () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(AppLocalizations.of(context)!.logout),
              content: Text(AppLocalizations.of(context)!.areYouSureYouX),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.read<AuthCubit>().logout();
                  },
                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                  child: Text(AppLocalizations.of(context)!.logout),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Wrapper that loads the restaurant from Firestore before showing
/// the delivery fee settings screen.
class _DeliveryFeeWrapper extends StatelessWidget {
  const _DeliveryFeeWrapper();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Center(
        child: Text(AppLocalizations.of(context)!.notAuthenticated),
      );
    }

    return FutureBuilder<Restaurant?>(
      future: RestaurantFirebaseDatasource().getByOwnerId(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final restaurant = snapshot.data;
        if (restaurant == null) {
          return Center(
            child: Text(
              AppLocalizations.of(context)!.createYourRestaurantFirst,
            ),
          );
        }
        return DeliveryFeeSettingsScreen(
          restaurant: restaurant,
          onSave: (updated) async {
            await RestaurantFirebaseDatasource().update(updated);
          },
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Bottom navigation bar
// ═══════════════════════════════════════════════════════════════════════════════

/// The primary bottom navigation tabs:
/// Dashboard(0), Orders(1), Menu(2), Analytics(3), Profile(4)
const _bottomNavPages = [0, 1, 2, 3, 4];

class _BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final int pendingOrderCount;
  final VendorType? vendorType;
  final ValueChanged<int> onTap;

  const _BottomNavBar({
    required this.selectedIndex,
    required this.pendingOrderCount,
    this.vendorType,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Map the selected page index to a bottom-nav tab index (0-4).
    // Pages not in [0,1,2,3,4] (e.g. Settings=7) → no tab highlighted.
    final tabIndex = _bottomNavPages.indexOf(selectedIndex);
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    final menuLabel = locale == 'ar'
        ? switch (vendorType) {
            VendorType.pharmacy => 'الأدوية',
            VendorType.supermarket => 'المنتجات',
            VendorType.bookstore => 'الأدوات المكتبية',
            VendorType.homeFurnishing => 'الأثاث',
            _ => l10n.drawerMenu,
          }
        : switch (vendorType) {
            VendorType.pharmacy => l10n.medicineAndHealthProducts,
            VendorType.supermarket => l10n.groceriesAndDailyNeeds,
            VendorType.bookstore => l10n.bookstore,
            VendorType.homeFurnishing => l10n.homeFurnishing,
            _ => l10n.drawerMenu,
          };

    final menuIcon = switch (vendorType) {
      VendorType.supermarket => Icons.shopping_basket_outlined,
      VendorType.pharmacy => Icons.medical_services_outlined,
      VendorType.bookstore => Icons.auto_stories_outlined,
      VendorType.homeFurnishing => Icons.chair_outlined,
      _ => Icons.restaurant_menu_outlined,
    };

    final activeMenuIcon = switch (vendorType) {
      VendorType.supermarket => Icons.shopping_basket,
      VendorType.pharmacy => Icons.medical_services,
      VendorType.bookstore => Icons.auto_stories,
      VendorType.homeFurnishing => Icons.chair,
      _ => Icons.restaurant_menu,
    };

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              _NavTab(
                icon: Icons.dashboard_outlined,
                activeIcon: Icons.dashboard,
                label: l10n.drawerDashboard,
                isSelected: tabIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavTab(
                icon: Icons.receipt_long_outlined,
                activeIcon: Icons.receipt_long,
                label: l10n.drawerOrders,
                isSelected: tabIndex == 1,
                badge: pendingOrderCount,
                onTap: () => onTap(1),
              ),
              _NavTab(
                icon: menuIcon,
                activeIcon: activeMenuIcon,
                label: menuLabel,
                isSelected: tabIndex == 2,
                onTap: () => onTap(2),
              ),
              _NavTab(
                icon: Icons.analytics_outlined,
                activeIcon: Icons.analytics,
                label: l10n.drawerAnalytics,
                isSelected: tabIndex == 3,
                onTap: () => onTap(3),
              ),
              _NavTab(
                icon: Icons.person_outlined,
                activeIcon: Icons.person,
                label: l10n.drawerProfile,
                isSelected: tabIndex == 4,
                onTap: () => onTap(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final int badge;
  final VoidCallback onTap;

  const _NavTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    this.badge = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFFF35535);
    final inactiveColor = Colors.grey[500]!;
    final color = isSelected ? activeColor : inactiveColor;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(isSelected ? activeIcon : icon, color: color, size: 24),
                if (badge > 0)
                  PositionedDirectional(
                    end: -8,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      constraints: const BoxConstraints(minWidth: 16),
                      child: Text(
                        badge > 9 ? '9+' : '$badge',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsetsDirectional.only(top: 2),
                width: 20,
                height: 2,
                decoration: BoxDecoration(
                  color: activeColor,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
