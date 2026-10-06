import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppVersionHelper {
  /// The current app version, loaded dynamically at startup using package_info_plus.
  /// Defaults to '2.3.7' if not successfully loaded.
  static String currentVersion = '2.3.7';

  /// The build number of the app (e.g. '96').
  static String buildNumber = '96';

  /// App name from native configuration.
  static String appName = 'Z Speed';

  /// Package name / bundle id.
  static String packageName = 'com.zspeed.app';

  /// Ensures that the flexible update is only prompted once per launch/session.
  static bool wasFlexibleUpdatePrompted = false;

  /// Loads package information dynamically using [PackageInfo.fromPlatform].
  static Future<void> loadVersionInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      currentVersion = packageInfo.version;
      buildNumber = packageInfo.buildNumber;
      appName = packageInfo.appName;
      packageName = packageInfo.packageName;
      debugPrint(
        'Dynamic App Version loaded: $currentVersion',
      );
    } catch (e) {
      debugPrint('Failed to load PackageInfo, using default: $e');
    }
  }

  /// Full semver string (e.g. '2.3.7')
  static String get fullVersion => currentVersion;

  /// Display string for UI (e.g. 'v2.3.7')
  static String get displayVersion => 'v$currentVersion';

  /// Display string for UI without build number (e.g. 'v2.3.7')
  static String get displayVersionWithBuild => 'v$currentVersion';

  /// Compares two semver strings (e.g., '2.1.1' and '2.2.0').
  /// Ignores any trailing build numbers (e.g., '+71').
  /// Returns true if [v1] is strictly older than [v2].
  static bool isOlder(String v1, String v2) {
    try {
      final String cleanV1 = v1.split('+').first.trim();
      final String cleanV2 = v2.split('+').first.trim();

      if (cleanV1 == cleanV2) return false;

      final List<int> parts1 = cleanV1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final List<int> parts2 = cleanV2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      final int maxLength = parts1.length > parts2.length ? parts1.length : parts2.length;
      while (parts1.length < maxLength) {
        parts1.add(0);
      }
      while (parts2.length < maxLength) {
        parts2.add(0);
      }

      for (int i = 0; i < maxLength; i++) {
        if (parts1[i] < parts2[i]) return true;
        if (parts1[i] > parts2[i]) return false;
      }
    } catch (e) {
      debugPrint('Error comparing versions ($v1 vs $v2): $e');
    }
    return false;
  }

  /// Resolves the appropriate update URL from the app settings depending on the platform.
  static String getUpdateUrl(Map<String, dynamic> settings) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return settings['iosUpdateUrl'] as String? ?? settings['updateUrl'] as String? ?? '';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return settings['androidUpdateUrl'] as String? ?? settings['updateUrl'] as String? ?? '';
    }
    return settings['updateUrl'] as String? ?? '';
  }
}

