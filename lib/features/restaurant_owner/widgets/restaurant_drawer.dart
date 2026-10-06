import 'package:flutter/material.dart';
import 'package:z_speed/l10n/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/core/enums/user_enums.dart';
import 'package:z_speed/features/auth/cubit/auth_cubit.dart';
import 'package:z_speed/features/restaurant/model/restaurant.dart';

/// Navigation items for the restaurant sidebar drawer.
enum RestaurantPage {
  dashboard(0, Icons.dashboard_outlined, Icons.dashboard),
  orders(1, Icons.receipt_long_outlined, Icons.receipt_long),
  menu(2, Icons.restaurant_menu_outlined, Icons.restaurant_menu),
  analytics(3, Icons.analytics_outlined, Icons.analytics),
  profile(4, Icons.store_outlined, Icons.store),
  promotions(5, Icons.local_offer_outlined, Icons.local_offer),
  reviews(6, Icons.star_outline, Icons.star),
  settings(7, Icons.settings_outlined, Icons.settings),
  deliveryFees(8, Icons.delivery_dining_outlined, Icons.delivery_dining),
  support(9, Icons.support_agent_outlined, Icons.support_agent),
  about(10, Icons.info_outline, Icons.info),
  wallet(
    11,
    Icons.account_balance_wallet_outlined,
    Icons.account_balance_wallet,
  ),
  prescriptions(
    12,
    Icons.chat_bubble_outline_rounded,
    Icons.chat_bubble_rounded,
  ),
  stories(
    13,
    Icons.photo_library_outlined,
    Icons.photo_library,
  );

  final int pageIndex;
  final IconData icon;
  final IconData activeIcon;

  const RestaurantPage(this.pageIndex, this.icon, this.activeIcon);
}

/// Sidebar navigation drawer for the Restaurant Dashboard.
///
/// Displays:
/// - Restaurant header (logo, name, open/closed status)
/// - Primary navigation items (Dashboard, Orders, Menu, Analytics, Profile)
/// - Secondary items (Promotions, Reviews)
/// - Divider
/// - Utility items (Settings, Delivery Fees, Support, About)
/// - Logout
class RestaurantDrawer extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onPageSelected;
  final Restaurant? restaurant;
  final int pendingOrderCount;

  const RestaurantDrawer({
    super.key,
    required this.selectedIndex,
    required this.onPageSelected,
    this.restaurant,
    this.pendingOrderCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFF35535);

    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadiusDirectional.horizontal(
          end: Radius.circular(0),
        ),
      ),
      child: Column(
        children: [
          // ── Restaurant Header ──
          _buildHeader(context, orange),

          // ── Navigation Items ──
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // Primary
                _buildSectionLabel(AppLocalizations.of(context)!.drawerMain),
                _buildNavItem(context, RestaurantPage.dashboard),
                _buildNavItem(
                  context,
                  RestaurantPage.orders,
                  badge: pendingOrderCount > 0 ? pendingOrderCount : null,
                ),
                _buildNavItem(context, RestaurantPage.menu),
                _buildNavItem(context, RestaurantPage.analytics),
                _buildNavItem(context, RestaurantPage.profile),
                if (restaurant?.vendorType == VendorType.pharmacy)
                  _buildNavItem(context, RestaurantPage.prescriptions),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Divider(height: 1),
                ),

                // Secondary
                _buildSectionLabel(AppLocalizations.of(context)!.drawerEngage),
                _buildNavItem(context, RestaurantPage.promotions),
                _buildNavItem(context, RestaurantPage.reviews),
                _buildNavItem(context, RestaurantPage.stories),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Divider(height: 1),
                ),

                // Utility
                _buildSectionLabel(AppLocalizations.of(context)!.drawerMore),
                _buildNavItem(context, RestaurantPage.wallet),
                _buildNavItem(context, RestaurantPage.settings),
                _buildNavItem(context, RestaurantPage.deliveryFees),
                _buildNavItem(context, RestaurantPage.support),
                _buildNavItem(context, RestaurantPage.about),
              ],
            ),
          ),

          // ── Logout ──
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1),
          ),
          _buildLogoutTile(context),
          const SizedBox(height: 8),
        ],
      ),
    );
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

  Widget _buildHeader(BuildContext context, Color orange) {
    final name = restaurant?.name ?? AppLocalizations.of(context)!.myRestaurant;
    final address = restaurant?.address ?? '';
    final isOpen = restaurant?.isOpen ?? false;
    final logoUrl = restaurant?.logoUrl;

    return Container(
      width: double.infinity,
      padding: EdgeInsetsDirectional.only(
        top: MediaQuery.of(context).padding.top + 16,
        start: 20,
        end: 20,
        bottom: 20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [orange, orange.withValues(alpha: 0.85)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
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
                      color: const Color(0xFFF35535),
                      size: 28,
                    ),
                  )
                : Icon(
                    _iconForVendorType(restaurant?.vendorType),
                    color: const Color(0xFFF35535),
                    size: 28,
                  ),
          ),
          const SizedBox(height: 14),

          // Name
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          if (address.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 13,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    address,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 10),

          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isOpen
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.red.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isOpen ? const Color(0xFF4CAF50) : Colors.red[300],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isOpen
                      ? AppLocalizations.of(context)!.open
                      : AppLocalizations.of(context)!.closed,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
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

  String _localizedLabel(BuildContext context, RestaurantPage page) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    switch (page) {
      case RestaurantPage.dashboard:
        return l10n.drawerDashboard;
      case RestaurantPage.orders:
        return l10n.drawerOrders;
      case RestaurantPage.menu:
        final type = restaurant?.vendorType;
        if (locale == 'ar') {
          return switch (type) {
            VendorType.supermarket => 'المنتجات',
            VendorType.pharmacy => 'الأدوية',
            VendorType.bookstore => 'الأدوات المكتبية',
            VendorType.homeFurnishing => 'الأثاث',
            _ => l10n.drawerMenu,
          };
        } else {
          return switch (type) {
            VendorType.supermarket => l10n.groceriesAndDailyNeeds,
            VendorType.pharmacy => l10n.medicineAndHealthProducts,
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

  Widget _buildNavItem(
    BuildContext context,
    RestaurantPage page, {
    int? badge,
  }) {
    final isSelected = selectedIndex == page.pageIndex;
    const orange = Color(0xFFF35535);

    IconData icon = isSelected ? page.activeIcon : page.icon;
    if (page == RestaurantPage.menu) {
      final type = restaurant?.vendorType;
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
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        dense: true,
        visualDensity: const VisualDensity(vertical: -1),
        leading: Icon(
          icon,
          color: isSelected ? orange : Colors.grey[600],
          size: 22,
        ),
        title: Text(
          _localizedLabel(context, page),
          style: TextStyle(
            color: isSelected ? orange : const Color(0xFF2D3748),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        trailing: badge != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge > 99 ? '99+' : '$badge',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () {
          onPageSelected(page.pageIndex);
        },
      ),
    );
  }

  Widget _buildLogoutTile(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: ListTile(
        dense: true,
        visualDensity: const VisualDensity(vertical: -1),
        leading: Icon(Icons.logout, color: Colors.red[400], size: 22),
        title: Text(
          AppLocalizations.of(context)!.logout,
          style: TextStyle(
            color: Colors.red[400],
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () {
          _showLogoutConfirmation(context);
        },
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
  }
}
