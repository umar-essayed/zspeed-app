import 'package:flutter/material.dart';
import 'package:z_speed/features/auth/model/user_model.dart';

class PageIdentity {
  static const String home = 'home';
  static const String customerDashboard = 'customer_dashboard';
  static const String restaurantDashboard = 'restaurant_dashboard';
  static const String adminPanel = 'admin_panel';
  static const String payment = 'payment';
  static const String disputeResolution = 'dispute_resolution';
  static const String userManagement = 'user_management';
  static const String receipt = 'receipt';
  static const String orderTracking = 'order_tracking';
  static const String driverPortal = 'driver_portal';
  static const String transportManagement = 'transport_management';
  static const String settings = 'settings';
  static const String helpSupport = 'help_support';
  static const String logout = 'logout';
  static const String profile = 'profile';
  static const String wallet = 'wallet';
  static const String adminManagement = 'admin_management';

  static final Map<String, String> _titlesByKey = {
    home: 'Home Page',
    customerDashboard: 'Customer Dashboard',
    restaurantDashboard: 'Restaurant Dashboard',
    adminPanel: 'Admin Panel',
    payment: 'Payment',
    disputeResolution: 'Dispute Resolution',
    userManagement: 'User Management',
    receipt: 'Receipt',
    orderTracking: 'Order Tracking',
    driverPortal: 'Driver Portal',
    transportManagement: 'Transport Management',
    settings: 'Account',
    helpSupport: 'Help & Support',
    logout: 'Logout',
    profile: 'Profile',
    wallet: 'Wallet',
    adminManagement: 'Admin Management',
  };

  static final Map<String, IconData> _iconsByKey = {
    home: Icons.home,
    customerDashboard: Icons.dashboard,
    restaurantDashboard: Icons.restaurant,
    adminPanel: Icons.admin_panel_settings,
    payment: Icons.payment,
    disputeResolution: Icons.gavel,
    userManagement: Icons.people,
    receipt: Icons.receipt,
    orderTracking: Icons.track_changes,
    driverPortal: Icons.delivery_dining,
    transportManagement: Icons.local_shipping,
    settings: Icons.settings,
    helpSupport: Icons.help,
    logout: Icons.logout,
    profile: Icons.person,
    wallet: Icons.account_balance_wallet,
    adminManagement: Icons.shield,
  };

  static final Map<String, Color> _colorsByKey = {
    home: const Color(0xFFF35535),
    customerDashboard: Colors.blue,
    restaurantDashboard: const Color(0xFFF35535),
    adminPanel: Colors.red,
    payment: Colors.purple,
    disputeResolution: Colors.amber,
    userManagement: Colors.indigo,
    receipt: Colors.teal,
    orderTracking: const Color(0xFFF35535),
    driverPortal: Colors.green,
    transportManagement: Colors.blueGrey,
    settings: Colors.grey,
    helpSupport: Colors.blue,
    logout: Colors.grey,
    profile: const Color(0xFFF35535),
    wallet: Colors.green,
    adminManagement: Colors.deepPurple,
  };

  static final Map<UserType, List<String>> _mainPagesByRole = {
    UserType.superAdmin: [
      home,
      customerDashboard,
      restaurantDashboard,
      adminPanel,
      payment,
      disputeResolution,
      userManagement,
      adminManagement,
      receipt,
      orderTracking,
      driverPortal,
      transportManagement,
      settings,
      helpSupport,
      logout,
    ],
    UserType.admin: [
      home,
      customerDashboard,
      restaurantDashboard,
      adminPanel,
      payment,
      disputeResolution,
      userManagement,
      receipt,
      orderTracking,
      driverPortal,
      transportManagement,
      settings,
      helpSupport,
      logout,
    ],
    UserType.vendor: [
      home,
      customerDashboard,
      restaurantDashboard,
      payment,
      disputeResolution,
      receipt,
      orderTracking,
      driverPortal,
      transportManagement,
      settings,
      helpSupport,
      logout,
    ],
    UserType.driver: [
      home,
      profile,
      settings,
      wallet,
      helpSupport,
      logout,
    ],
    UserType.customer: [
      home,
      settings,
      orderTracking,
      helpSupport,
      logout,
    ],
  };

  static final Map<String, String> _keyByNormalizedTitle = {
    for (final entry in _titlesByKey.entries)
      entry.value.toLowerCase(): entry.key,
    'restaurant hub': restaurantDashboard,
    'home': home,
  };

  static String keyFromTitle(String title) {
    final normalized = title.trim().toLowerCase();
    final mapped = _keyByNormalizedTitle[normalized];
    if (mapped != null) {
      return mapped;
    }
    return normalized
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  static String titleFromKey(String key) => _titlesByKey[key] ?? key;

  static IconData getIconForKey(String key) => _iconsByKey[key] ?? Icons.error;

  static Color getColorForKey(String key) => _colorsByKey[key] ?? Colors.grey;

  static IconData getIconForTitle(String title) {
    return getIconForKey(keyFromTitle(title));
  }

  static Color getColorForTitle(String title) {
    return getColorForKey(keyFromTitle(title));
  }

  static List<String> getMainPageKeys(UserType userType) {
    return List<String>.from(_mainPagesByRole[userType] ?? [home, logout]);
  }

  static List<String> getMainPageTitles(UserType userType) {
    return getMainPageKeys(userType).map(titleFromKey).toList();
  }

  static Map<UserType, List<String>> getAccessibleMainPages() {
    return _mainPagesByRole.map(
      (key, value) => MapEntry(key, List<String>.from(value)),
    );
  }
}
