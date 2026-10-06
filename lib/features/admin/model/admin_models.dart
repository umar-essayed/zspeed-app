import 'package:flutter/material.dart';
import 'package:z_speed/core/enums/enums.dart';

// ── Re-exports of canonical models ──────────────────────────────────────────
export 'package:z_speed/core/enums/enums.dart';
export 'package:z_speed/features/auth/model/user_model.dart';
export 'package:z_speed/features/restaurant/model/restaurant.dart';
export 'package:z_speed/features/restaurant/model/menu_section.dart';
export 'package:z_speed/features/restaurant/model/menu_item.dart';
export 'package:z_speed/features/restaurant/model/addon_group.dart';
export 'package:z_speed/features/order/model/order.dart';
export 'package:z_speed/features/order/model/order_item.dart';
export 'package:z_speed/features/driver/model/driver_profile.dart';
export 'package:z_speed/features/payment/model/payment.dart';
export 'package:z_speed/features/review/model/review.dart';
export 'package:z_speed/features/admin/model/application_model.dart';

// ── Admin-specific UI models ────────────────────────────────────────────────

/// A recent activity entry for the admin dashboard.
class AdminActivity {
  final String title;
  final String description;
  final DateTime timestamp;
  final AdminActivityType type;

  AdminActivity({
    required this.title,
    required this.description,
    required this.timestamp,
    required this.type,
  });

  String get timeAgo {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }
}

enum AdminActivityType {
  userRegistration,
  orderCompleted,
  restaurantApproved,
  orderPlaced,
  applicationSubmitted
}

class AdminView {
  final String title;
  final IconData icon;
  final String subtitle;
  /// Short label for the mobile bottom TabBar. Falls back to [title] when null.
  final String? shortTitle;

  AdminView({
    required this.title,
    required this.icon,
    required this.subtitle,
    this.shortTitle,
  });
}

enum StatCardKey { totalUsers, totalOrders, totalRevenue, pendingOrders }

class StatCardData {
  final String title;
  final StatCardKey? key;
  final String value;
  final String change;
  final IconData icon;
  final Color color;
  final Color secondaryColor;
  final StatTrend trend;

  StatCardData({
    required this.title,
    this.key,
    required this.value,
    required this.change,
    required this.icon,
    required this.color,
    required this.secondaryColor,
    required this.trend,
  });
}

enum StatTrend { up, down, neutral }

class QuickActionData {
  final String title;
  final IconData icon;
  final Color color;

  QuickActionData({
    required this.title,
    required this.icon,
    required this.color,
  });
}

// ── Admin list view models (backward compatibility) ─────────────────────────

/// A simplified user model for admin list views.
/// Renamed from `User` to avoid collision with canonical AppUser.
class AdminUser {
  final String id;
  final String name;
  final String email;
  final UserType role;
  final UserStatus status;
  final String phone;
  final String joinDate;

  AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    required this.phone,
    required this.joinDate,
  });
}

/// A simplified order model for admin list views.
/// Renamed from `Order` to avoid collision with canonical Order.
class AdminOrder {
  final String id;
  final String customerName;
  final String restaurantName;
  final double amount;
  final OrderStatus status;
  final int items;
  final String date;
  final String time;

  AdminOrder({
    required this.id,
    required this.customerName,
    required this.restaurantName,
    required this.amount,
    required this.status,
    required this.items,
    required this.date,
    required this.time,
  });
}

/// A simplified vendor model for admin list views.
/// Renamed from `Vendor` to avoid collision with canonical Restaurant.
class AdminVendor {
  final String id;
  final String name;
  final String category;
  final RestaurantStatus status;
  final double rating;
  final int ordersToday;
  final double totalRevenue;
  final VendorType vendorType;

  AdminVendor({
    required this.id,
    required this.name,
    required this.category,
    required this.status,
    required this.rating,
    required this.ordersToday,
    required this.totalRevenue,
    this.vendorType = VendorType.restaurant,
  });

  AdminVendor copyWith({
    String? id,
    String? name,
    String? category,
    RestaurantStatus? status,
    double? rating,
    int? ordersToday,
    double? totalRevenue,
    VendorType? vendorType,
  }) {
    return AdminVendor(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      status: status ?? this.status,
      rating: rating ?? this.rating,
      ordersToday: ordersToday ?? this.ordersToday,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      vendorType: vendorType ?? this.vendorType,
    );
  }
}
