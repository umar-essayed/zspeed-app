import 'package:flutter/material.dart';
import 'package:z_speed/core/constants/app_routes.dart';
import 'package:z_speed/core/constants/page_identity.dart';
import 'package:z_speed/features/admin/widgets/dispute_resolution.dart';
import 'package:z_speed/features/admin/view/admin_users_screen.dart';
import 'package:z_speed/features/customer/view/customer_order_history_screen.dart';
import 'package:z_speed/features/auth/model/user_model.dart';
import 'package:z_speed/features/admin/view/admin_app_screen.dart';
import 'package:z_speed/features/customer/view/customer_app_screen.dart';
import 'package:z_speed/features/driver/view/driver_app_screen.dart';
import 'package:z_speed/features/home/view/home_screen.dart';
import 'package:z_speed/features/payment_settings/view/payment_settings_screen.dart';
import 'package:z_speed/features/settings/view/settings_screen.dart';
import 'package:z_speed/features/driver/view/transport_app_screen.dart';
import 'package:z_speed/features/restaurant_owner/view/restaurant_hub_screen.dart';
import 'package:z_speed/features/help_support/view/help_support_screen.dart';
import 'package:z_speed/features/driver/screens/driver_profile_page.dart';

class NavigationPolicy {
  static Map<String, String> routeKeyMap = {
    AppRoutes.admin: PageIdentity.adminPanel,
    AppRoutes.restaurant: PageIdentity.restaurantDashboard,
    AppRoutes.customer: PageIdentity.customerDashboard,
    AppRoutes.driver: PageIdentity.driverPortal,
    AppRoutes.homeAlias: PageIdentity.home,
    AppRoutes.settingsAlias: PageIdentity.settings,
    AppRoutes.helpAlias: PageIdentity.helpSupport,
  };

  static Map<String, List<String>> pageHierarchy = {
    'customer_dashboard': [
      'home',
      'browse_restaurants',
      'cart',
      'my_orders',
      'order_history',
      'favorites',
      'notifications',
    ],
    'restaurant_dashboard': [
      'home',
      'restaurant_overview',
      'menu_management',
      'order_management',
      'inventory',
      'staff_management',
      'revenue_reports',
      'customer_reviews',
    ],
    'admin_panel': [
      'home',
      'system_overview',
      'user_management',
      'restaurant_management',
      'driver_management',
      'financial_reports',
      'system_logs',
      'backup_restore',
    ],
    'admin_management': [
      'home',
      'list_admins',
      'add_admin',
    ],
    'payment': [
      'home',
      'payment_methods',
      'card_management',
      'wallet',
      'transaction_history',
      'invoices',
      'refunds',
    ],
    'dispute_resolution': [
      'home',
      'open_disputes',
      'resolved_disputes',
      'create_dispute',
      'dispute_chat',
      'evidence_upload',
    ],
    'user_management': [
      'home',
      'all_users',
      'add_user',
      'edit_user',
      'user_roles',
      'user_activity',
      'block_unblock',
    ],
    'receipt': [
      'home',
      'order_receipt',
      'download_receipt',
      'share_receipt',
      'receipt_history',
      'tax_invoice',
    ],
    'order_tracking': [
      'home',
      'active_orders',
      'order_details',
      'live_tracking',
      'status_updates',
      'delivery_proof',
    ],
    'driver_portal': [
      'home',
      'driver_dashboard',
      'assigned_orders',
      'earnings',
      'performance',
      'vehicle_info',
      'documents',
    ],
    'transport_management': [
      'home',
      'fleet_overview',
      'assign_drivers',
      'route_optimization',
      'vehicle_tracking',
      'maintenance',
      'fuel_logs',
    ],
    'settings': [
      'home',
      'profile_settings',
      'security',
      'notifications_settings',
      'privacy',
      'language',
      'theme',
    ],
    'help_support': [
      'home',
      'faq',
      'contact_support',
      'tutorials',
      'feedback',
      'terms_conditions',
      'privacy_policy',
    ],
    'logout': [],
  };

  static Widget getPage(String pageKey, AppUser user) {
    switch (pageKey) {
      case PageIdentity.customerDashboard:
        return const CustomerApp();
      case PageIdentity.restaurantDashboard:
        return const RestaurantHubApp();
      case PageIdentity.adminPanel:
        return const AdminApp();
      case PageIdentity.adminManagement:
        return const AdminApp();
      case PageIdentity.payment:
        return const PaymentSettingsPage();
      case PageIdentity.disputeResolution:
        return const DisputeResolution();
      case PageIdentity.userManagement:
        return const AdminUsersScreen();
      case PageIdentity.receipt:
        return const CustomerOrderHistoryScreen();
      case PageIdentity.orderTracking:
        return const CustomerOrderHistoryScreen();
      case PageIdentity.driverPortal:
        return const DriverApp();
      case PageIdentity.transportManagement:
        return const TransportApp();
      case PageIdentity.profile:
        if (user.type == UserType.driver) return const DriverProfilePage();
        return const SettingsPage();
      case PageIdentity.wallet:
        return const PaymentSettingsPage();
      case PageIdentity.settings:
        if (user.type == UserType.driver) return const DriverProfilePage();
        return const SettingsPage();
      case PageIdentity.helpSupport:
        return const HelpSupportScreen();
      case PageIdentity.home:
      default:
        return HomePage(currentUser: user);
    }
  }

  static bool canAccess(AppUser user, String pageKey) {
    return PageIdentity.getMainPageKeys(user.type).contains(pageKey);
  }

  static List<String> mainPageKeysFor(UserType userType) {
    return PageIdentity.getMainPageKeys(userType);
  }

  static List<String> mainPageTitlesFor(UserType userType) {
    return mainPageKeysFor(userType).map(PageIdentity.titleFromKey).toList();
  }

  static String getPageDescription(String pageKey) {
    switch (pageKey) {
      case 'customer_dashboard':
        return 'Browse restaurants and place orders';
      case 'restaurant_dashboard':
        return 'Manage your restaurant and orders';
      case 'admin_panel':
        return 'System administration and management';
      case 'restaurant_list':
        return 'View all available restaurants';
      case 'payment':
        return 'Payment methods and transaction history';
      case 'dispute_resolution':
        return 'Resolve disputes and issues';
      case 'user_management':
        return 'Manage system users and roles';
      case 'admin_management':
        return 'Manage administrator accounts';
      case 'receipt':
        return 'View and manage order receipts';
      case 'order_tracking':
        return 'Track your orders in real-time';
      case 'driver_portal':
        return 'Driver assignments and earnings';
      case 'transport_management':
        return 'Manage delivery fleet and logistics';
      case 'settings':
        return 'Account and application settings';
      case 'help_support':
        return 'Get help and support';
      case 'logout':
        return 'Sign out of your account';
      default:
        return '';
    }
  }
}
