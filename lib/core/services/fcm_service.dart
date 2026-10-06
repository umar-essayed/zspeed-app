import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


/// Singleton FCM service.
///
/// Every call to `FcmService()` returns the same instance, so
/// [_tokenRefreshSub] is always the live subscription regardless of
/// which call site invokes [removeToken] or [dispose].
class FcmService {
  // ── Singleton boilerplate ────────────────────────────────────────────────
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();
  // ────────────────────────────────────────────────────────────────────────

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _messageTapSub;

  /// Must match `channelId` sent from Cloud Functions (see send.ts).
  static const String _channelId = 'order_updates';
  static const String _channelName = 'Order Updates';
  static const String _channelDescription =
      'Notifications about your order status and delivery updates';

  static const String _driverChannelId = 'driver_ride_requests';
  static const String _driverChannelName = 'Driver Ride Requests';
  static const String _driverChannelDescription =
      'High priority alerts and custom loud ringtones for incoming ride and delivery requests';

  /// Cancel all active listeners (call before logout/delete account).
  void dispose() {
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    _foregroundSub?.cancel();
    _foregroundSub = null;
    _messageTapSub?.cancel();
    _messageTapSub = null;
  }

  /// Request notification permission and register FCM token.
  Future<void> initialize(String userId) async {
    // 1. Request permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('User denied notification permissions');
      return;
    }

    // 2. Create Android notification channel (must exist before notifications arrive)
    if (!kIsWeb) {
      if (defaultTargetPlatform == TargetPlatform.android) {
        await _createAndroidChannel();
      }

      // 3. Initialize local notifications plugin (for foreground display)
      await _localNotifications.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );
    }

    // 4. Get current token and save
    try {
      String? vapidKey;
      if (kIsWeb) {
        vapidKey = dotenv.maybeGet('FCM_VAPID_KEY');
        if (vapidKey == null || vapidKey.isEmpty) {
          debugPrint(
            'WARNING: FCM_VAPID_KEY is not defined in assets/env. FCM web token cannot be retrieved.',
          );
        }
      }
      final token = await _messaging.getToken(vapidKey: vapidKey);
      if (token != null) {
        await _saveToken(userId, token);
        debugPrint('FCM Token registered: ${token.substring(0, 20)}...');
      }
    } catch (e, st) {
      debugPrint('Error getting FCM token: $e\n$st');
    }

    // 5. Listen for token refresh (cancel previous sub first)
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = _messaging.onTokenRefresh.listen((newToken) {
      _saveToken(userId, newToken);
      debugPrint('FCM Token refreshed');
    });

    // 6. Configure foreground notification presentation
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// Create the Android notification channels. No-op on non-Android platforms.
  Future<void> _createAndroidChannel() async {
    const orderChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    // Premium high-importance channel with custom sound and long vibration for drivers
    final driverChannel = AndroidNotificationChannel(
      _driverChannelId,
      _driverChannelName,
      description: _driverChannelDescription,
      importance: Importance.max,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('driver_alert'),
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1500]),
    );

    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(orderChannel);
      await androidPlugin.createNotificationChannel(driverChannel);
    }
  }

  /// Display a system notification for a foreground FCM message.
  /// Called from setupMessageHandlers.onForeground.
  Future<void> showForegroundNotification(RemoteMessage message) async {
    if (kIsWeb) return;
    final notification = message.notification;
    if (notification == null) return;

    // Check if the message is a driver request or ride request to use driver channel and sound
    final isRideRequest = message.data['type'] == 'ride_request' ||
        message.data['type'] == 'driver_orders' ||
        message.data['screen'] == 'delivery_request' ||
        message.data['screen'] == 'ride_request' ||
        message.from?.contains('driver_orders') == true;

    final activeChannelId = isRideRequest ? _driverChannelId : _channelId;
    final activeChannelName = isRideRequest ? _driverChannelName : _channelName;
    final activeChannelDescription =
        isRideRequest ? _driverChannelDescription : _channelDescription;

    await _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          activeChannelId,
          activeChannelName,
          channelDescription: activeChannelDescription,
          importance: isRideRequest ? Importance.max : Importance.high,
          priority: isRideRequest ? Priority.max : Priority.high,
          icon: '@mipmap/ic_launcher',
          sound: isRideRequest
              ? const RawResourceAndroidNotificationSound('driver_alert')
              : null,
          playSound: true,
          vibrationPattern: isRideRequest
              ? Int64List.fromList([0, 1000, 500, 1000, 500, 1500])
              : null,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: isRideRequest ? 'driver_alert.caf' : null,
        ),
      ),
      payload: message.data['orderId'] as String?,
    );
  }

  /// Save FCM token to user document (arrayUnion for multi-device).
  /// Uses set+merge so it works even if the document doesn't have fcmTokens yet.
  Future<void> _saveToken(String userId, String token) async {
    try {
      await _firestore.collection('users').doc(userId).set(
        {
          'fcmTokens': FieldValue.arrayUnion([token])
        },
        SetOptions(merge: true),
      );
      debugPrint('FCM token saved for user $userId');
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  /// Remove the current FCM token from Firestore.
  /// MUST be called BEFORE Firebase Auth sign-out while the user is still
  /// authenticated — otherwise Firestore will reject with permission-denied.
  Future<void> removeTokenFromFirestore(String userId) async {
    try {
      String? vapidKey;
      if (kIsWeb) {
        vapidKey = dotenv.maybeGet('FCM_VAPID_KEY');
      }
      final token = await _messaging
          .getToken(vapidKey: vapidKey)
          .timeout(const Duration(seconds: 3));
      if (token != null) {
        await _firestore.collection('users').doc(userId).update({
          'fcmTokens': FieldValue.arrayRemove([token])
        }).timeout(const Duration(seconds: 5));
        debugPrint('FCM Token removed from Firestore for user $userId');
      }
    } catch (e) {
      debugPrint('Error removing FCM token from Firestore: $e');
    }
  }

  /// Device-side FCM cleanup — call AFTER Firebase Auth sign-out.
  /// 1. Cancels the token-refresh listener so no new token is saved to the old user.
  /// 2. Deletes the token from the FCM server (invalidates push delivery and
  ///    all server-side topic subscriptions for this token).
  Future<void> removeToken(String userId) async {
    // Cancel BEFORE deleteToken() — otherwise onTokenRefresh fires with a new
    // token and saves it back to the old user's Firestore document.
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    debugPrint('FCM token-refresh listener cancelled');

    try {
      await _messaging.deleteToken();
      debugPrint('FCM Token deleted from device');
    } catch (e) {
      debugPrint('Error deleting FCM token from device: $e');
    }
  }

  /// Unsubscribe from all known role-based topics.
  /// Call this on logout BEFORE deleteToken() for an explicit server-side
  /// unsubscribe (belt-and-suspenders alongside token deletion).
  Future<void> unsubscribeFromAllTopics() async {
    const topics = ['driver_orders'];
    for (final topic in topics) {
      await unsubscribeFromTopic(topic);
    }
  }

  /// Clear all local notifications.
  Future<void> clearAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
      debugPrint('All local notifications cleared');
    } catch (e) {
      debugPrint('Error clearing local notifications: $e');
    }
  }

  /// Set up message handlers for foreground, background tap, terminated tap.
  /// Cancels any previous handlers first to avoid stacking duplicate listeners
  /// when the same user switches accounts.
  void setupMessageHandlers({
    required void Function(RemoteMessage) onForeground,
    required void Function(RemoteMessage) onMessageTap,
  }) {
    // Cancel old handlers first
    _foregroundSub?.cancel();
    _messageTapSub?.cancel();

    // Foreground messages — also show a system notification so the user sees it
    _foregroundSub = FirebaseMessaging.onMessage.listen((message) {
      showForegroundNotification(message);
      onForeground(message);
    });

    // User tapped notification while app was in background
    _messageTapSub = FirebaseMessaging.onMessageOpenedApp.listen(onMessageTap);
  }

  /// Subscribe to a specific topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from a specific topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic: $e');
    }
  }

  /// Check if app was opened via notification tap (cold start).
  Future<RemoteMessage?> getInitialMessage() {
    return _messaging.getInitialMessage();
  }
}
