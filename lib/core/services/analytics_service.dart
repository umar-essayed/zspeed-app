import "dart:io";
import 'package:flutter/foundation.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

/// Analytics Service (Phase 8.10)
///
/// Typed wrapper for Firebase Analytics with predefined events.
///
/// Key Features:
/// - 12 typed event methods for main user flows
/// - User ID and role tracking
/// - Screen tracking via NavigatorObserver
/// - No raw string events in ViewModels
///
/// Events tracked:
/// 1. add_to_cart
/// 2. remove_from_cart
/// 3. begin_checkout
/// 4. apply_promo
/// 5. place_order
/// 6. order_delivered
/// 7. cancel_order
/// 8. view_restaurant
/// 9. search_restaurant
/// 10. driver_accept_order
/// 11. vendor_update_menu
/// 12. sign_up
class AnalyticsService {
  static FirebaseAnalytics get _analytics => FirebaseAnalytics.instance;

  /// Get the NavigatorObserver for automatic screen tracking.
  ///
  /// Add this to MaterialApp.navigatorObservers:
  /// ```dart
  /// MaterialApp(
  ///   navigatorObservers: [AnalyticsService.observer],
  ///   ...
  /// );
  /// ```
  static FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  /// Set the user ID for analytics.
  ///
  /// Call on login with user UID, and on logout with null.
  static Future<void> setUserId(String? uid) async {
    if (kIsWeb) {
      await _analytics.setUserId(id: uid);
      return;
    }
    if (Platform.environment.containsKey("FLUTTER_TEST")) return;
    await _analytics.setUserId(id: uid);
  }

  /// Set the user's role (customer, vendor, driver, admin).
  static Future<void> setUserRole(String role) async {
    if (kIsWeb) {
      await _analytics.setUserProperty(name: 'role', value: role);
      return;
    }
    if (Platform.environment.containsKey("FLUTTER_TEST")) return;
    await _analytics.setUserProperty(name: 'role', value: role);
  }

  // ── Cart Events ──────────────────────────────────────

  /// Log when a user adds an item to their cart.
  static Future<void> logAddToCart({
    required String itemId,
    required String itemName,
    required double price,
    required int quantity,
    required String restaurantId,
  }) =>
      _analytics.logAddToCart(
        items: [
          AnalyticsEventItem(
            itemId: itemId,
            itemName: itemName,
            price: price,
            quantity: quantity,
          )
        ],
        value: price * quantity,
        currency: 'EGP',
        parameters: {'restaurant_id': restaurantId},
      );

  /// Log when a user removes an item from their cart.
  static Future<void> logRemoveFromCart({
    required String itemId,
    required String itemName,
    required String restaurantId,
  }) =>
      _analytics.logEvent(
        name: 'remove_from_cart',
        parameters: {
          'item_id': itemId,
          'item_name': itemName,
          'restaurant_id': restaurantId,
        },
      );

  // ── Checkout Events ──────────────────────────────────

  /// Log when a user begins the checkout process.
  static Future<void> logBeginCheckout({
    required double subtotal,
    required int itemCount,
    required String restaurantId,
  }) =>
      _analytics.logBeginCheckout(
        value: subtotal,
        currency: 'EGP',
        items: [
          AnalyticsEventItem(
            itemId: restaurantId,
            quantity: itemCount,
          )
        ],
      );

  /// Log when a user applies a promo code.
  static Future<void> logApplyPromo({
    required String promoCode,
    required bool valid,
    required double discount,
  }) =>
      _analytics.logEvent(
        name: 'apply_promo',
        parameters: {
          'promo_code': promoCode,
          'valid': valid ? 1 : 0,
          'discount': discount,
        },
      );

  // ── Order Events ─────────────────────────────────────

  /// Log when a user places an order.
  static Future<void> logPlaceOrder({
    required String orderId,
    required double total,
    required String paymentMethod,
    required int itemCount,
    required String restaurantId,
  }) =>
      _analytics.logPurchase(
        transactionId: orderId,
        value: total,
        currency: 'EGP',
        items: [
          AnalyticsEventItem(
            itemId: restaurantId,
            quantity: itemCount,
          )
        ],
        parameters: {
          'payment_method': paymentMethod,
        },
      );

  /// Log when an order is delivered successfully.
  static Future<void> logOrderDelivered({
    required String orderId,
    required int deliveryTimeMinutes,
  }) =>
      _analytics.logEvent(
        name: 'order_delivered',
        parameters: {
          'order_id': orderId,
          'delivery_time_minutes': deliveryTimeMinutes,
        },
      );

  /// Log when a user cancels an order.
  static Future<void> logCancelOrder({
    required String orderId,
    required String reason,
  }) =>
      _analytics.logEvent(
        name: 'cancel_order',
        parameters: {
          'order_id': orderId,
          'reason': reason,
        },
      );

  // ── Restaurant Events ────────────────────────────────

  /// Log when a user views a restaurant menu.
  static Future<void> logViewRestaurant({
    required String restaurantId,
    required String restaurantName,
  }) =>
      _analytics.logViewItem(
        items: [
          AnalyticsEventItem(
            itemId: restaurantId,
            itemName: restaurantName,
          )
        ],
      );

  /// Log when a user searches for restaurants.
  static Future<void> logSearchRestaurant({
    required String query,
    required int resultCount,
  }) =>
      _analytics.logSearch(
        searchTerm: query,
        parameters: {
          'result_count': resultCount,
        },
      );

  // ── Driver Events ────────────────────────────────────

  /// Log when a driver accepts an order.
  static Future<void> logDriverAcceptOrder({
    required String orderId,
    required String driverId,
  }) =>
      _analytics.logEvent(
        name: 'driver_accept_order',
        parameters: {
          'order_id': orderId,
          'driver_id': driverId,
        },
      );

  // ── Vendor Events ────────────────────────────────────

  /// Log when a vendor updates their menu (add/edit/delete item).
  static Future<void> logRestaurantUpdateMenu({
    required String restaurantId,
    required String action, // 'add', 'edit', 'delete'
  }) =>
      _analytics.logEvent(
        name: 'vendor_update_menu',
        parameters: {
          'restaurant_id': restaurantId,
          'action': action,
        },
      );

  // ── Auth Events ──────────────────────────────────────

  /// Log when a user signs up.
  static Future<void> logSignUp({
    required String method, // 'email', 'google'
  }) =>
      _analytics.logSignUp(
        signUpMethod: method,
      );
}
