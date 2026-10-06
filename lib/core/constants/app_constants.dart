/// Centralized app-wide constants for Z Speed delivery app.
///
/// Contains contact info, branding, and support details.
/// These values should eventually come from Firebase Remote Config.
class AppConstants {
  AppConstants._();

  // ── Branding ───────────────────────────────────────────────────
  static String appName = 'Z Speed';
  static String appTagline = 'Fast & Reliable Delivery Service';
  static String developer = 'Z Speed Technologies';

  // ── Contact & Support ──────────────────────────────────────────
  static String supportEmail = 'support@zspeedapp.com';
  static String supportPhone = '+20 127 943 2917';
  static String supportPhoneRaw = '+201279432917';

  // ── App Info ───────────────────────────────────────────────────
  static String appVersion = '1.0.0';
  static String buildNumber = '1';
  static String lastUpdated = 'May 2026';

  // ── Currency ───────────────────────────────────────────────────
  static String currency = 'EGP';
  static String currencySymbol = 'EGP';
}
