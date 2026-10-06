import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:z_speed/core/utils/app_version_helper.dart';

void main() {
  group('AppVersionHelper.isOlder Tests', () {
    test('Should return true if current version is strictly older than target', () {
      expect(AppVersionHelper.isOlder('2.1.1', '2.2.0'), isTrue);
      expect(AppVersionHelper.isOlder('2.1.1', '3.0.0'), isTrue);
      expect(AppVersionHelper.isOlder('2.1.1', '2.1.2'), isTrue);
      expect(AppVersionHelper.isOlder('1.0.0', '1.0.1'), isTrue);
    });

    test('Should return false if current version is equal to target', () {
      expect(AppVersionHelper.isOlder('2.1.1', '2.1.1'), isFalse);
      expect(AppVersionHelper.isOlder('1.0.0', '1.0.0'), isFalse);
    });

    test('Should return false if current version is newer than target', () {
      expect(AppVersionHelper.isOlder('2.1.1', '2.1.0'), isFalse);
      expect(AppVersionHelper.isOlder('2.1.1', '2.0.0'), isFalse);
      expect(AppVersionHelper.isOlder('2.1.1', '1.9.9'), isFalse);
    });

    test('Should ignore build numbers and suffix metadata', () {
      expect(AppVersionHelper.isOlder('2.1.1+71', '2.1.1+82'), isFalse); // Equal semver
      expect(AppVersionHelper.isOlder('2.1.1+71', '2.1.2+1'), isTrue);   // Older semver
      expect(AppVersionHelper.isOlder('2.1.2+71', '2.1.1+99'), isFalse);  // Newer semver
    });

    test('Should handle mismatched number of parts cleanly', () {
      expect(AppVersionHelper.isOlder('2.1', '2.1.1'), isTrue);
      expect(AppVersionHelper.isOlder('2', '2.0.1'), isTrue);
      expect(AppVersionHelper.isOlder('2.1.1', '2.1'), isFalse);
      expect(AppVersionHelper.isOlder('2.1.0', '2.1'), isFalse);
    });
  });

  group('AppVersionHelper.getUpdateUrl Tests', () {
    test('Should resolve iOS url on iOS platform', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final settings = {
        'iosUpdateUrl': 'https://apple.com/app',
        'androidUpdateUrl': 'https://google.com/app',
        'updateUrl': 'https://fallback.com',
      };
      expect(AppVersionHelper.getUpdateUrl(settings), equals('https://apple.com/app'));
      debugDefaultTargetPlatformOverride = null;
    });

    test('Should resolve Android url on Android platform', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final settings = {
        'iosUpdateUrl': 'https://apple.com/app',
        'androidUpdateUrl': 'https://google.com/app',
        'updateUrl': 'https://fallback.com',
      };
      expect(AppVersionHelper.getUpdateUrl(settings), equals('https://google.com/app'));
      debugDefaultTargetPlatformOverride = null;
    });

    test('Should fallback to updateUrl if specific platform url is missing', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final settings = {
        'androidUpdateUrl': 'https://google.com/app',
        'updateUrl': 'https://fallback.com',
      };
      expect(AppVersionHelper.getUpdateUrl(settings), equals('https://fallback.com'));
      debugDefaultTargetPlatformOverride = null;
    });
  });
}
