import "dart:io";
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Crashlytics Service (Phase 8.10)
///
/// Wrapper for Firebase Crashlytics with global error boundary setup.
///
/// Features:
/// - Automatic Flutter framework error capture
/// - Zone error capture (async errors)
/// - User ID tracking
/// - Custom logging
/// - Debug mode opt-out
class CrashlyticsService {
  /// Initialize Crashlytics and set up error handlers.
  ///
  /// This sets FlutterError.onError to route all Flutter framework
  /// errors to Crashlytics as fatal crashes.
  ///
  /// Crashlytics is disabled in debug mode to avoid noise.
  static Future<void> init() async {
    // Route Flutter framework errors to Crashlytics
    FlutterError.onError = (details) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    };

    // Platform errors from native code (iOS, Android)
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    // Disable in debug mode to avoid polluting crash reports
    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(!kDebugMode);
  }

  /// Record a non-fatal error.
  ///
  /// Use for caught exceptions that you want to track but don't
  /// crash the app.
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   await networkCall();
  /// } catch (e, stack) {
  ///   CrashlyticsService.recordError(e, stack);
  ///   showErrorToUser();
  /// }
  /// ```
  static void recordError(
    dynamic error,
    StackTrace? stack, {
    bool fatal = false,
  }) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: fatal);
  }

  /// Set the user ID for crash reports.
  ///
  /// Call this on login to associate crashes with specific users.
  /// Call with empty string on logout.
  ///
  /// Example:
  /// ```dart
  /// // On login
  /// CrashlyticsService.setUserId(user.uid);
  ///
  /// // On logout
  /// CrashlyticsService.setUserId('');
  /// ```
  static void setUserId(String uid) {
    if (kIsWeb) {
      FirebaseCrashlytics.instance.setUserIdentifier(uid);
      return;
    }
    if (Platform.environment.containsKey("FLUTTER_TEST")) return;
    FirebaseCrashlytics.instance.setUserIdentifier(uid);
  }

  /// Log a message to the crash report.
  ///
  /// These logs appear in the crash report timeline, helping
  /// you understand what the user was doing before the crash.
  ///
  /// Example:
  /// ```dart
  /// CrashlyticsService.log('User navigated to checkout screen');
  /// ```
  static void log(String message) {
    FirebaseCrashlytics.instance.log(message);
  }

  /// Set a custom key-value pair.
  ///
  /// Custom keys appear in crash reports and can be used for
  /// filtering and grouping.
  ///
  /// Example:
  /// ```dart
  /// CrashlyticsService.setCustomKey('user_role', 'customer');
  /// CrashlyticsService.setCustomKey('cart_item_count', 3);
  /// ```
  static void setCustomKey(String key, Object value) {
    FirebaseCrashlytics.instance.setCustomKey(key, value);
  }
}
