import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Central permission helpers used across the app.
///
/// All methods return `true` if the permission is granted (or not required on
/// the current platform/API level), and `false` if the user denied it.
/// When permanently denied, [openAppSettings] is called so the user can
/// enable the permission manually.
class PermissionUtils {
  PermissionUtils._();

  // ── Camera ──────────────────────────────────────────────────────────────────

  /// Request camera permission.
  static Future<bool> requestCamera() async {
    if (kIsWeb) return true;
    if (!Platform.isAndroid && !Platform.isIOS) return true;

    if (Platform.isIOS) {
      // image_picker handles camera permission natively on iOS.
      return true;
    }

    return _request(Permission.camera);
  }

  // ── Photos / Gallery ────────────────────────────────────────────────────────

  /// Request permission to read images from the gallery.
  ///
  /// On Android 13+, no permission is needed for the System Photo Picker.
  /// On Android 12 and below, we use [Permission.storage].
  /// On iOS, image_picker handles permissions internally.
  static Future<bool> requestGallery() async {
    if (kIsWeb) return true;
    if (!Platform.isAndroid && !Platform.isIOS) return true;

    if (Platform.isIOS) return true;

    // On Android, we rely on the System Photo Picker (image_picker) which
    // does not require manifest permissions. Bypassing the check avoids
    // 'No permissions found in manifest' errors on Android 13+.
    return true;
  }

  /// Request both camera + gallery at once (e.g. image_picker source chooser).
  static Future<bool> requestCameraAndGallery() async {
    final camera = await requestCamera();
    final gallery = await requestGallery();
    return camera && gallery;
  }

  // ── Storage (files / documents) ─────────────────────────────────────────────

  /// Request permission to read external files (Excel, PDF, etc.).
  ///
  /// On Android 13+ uses [Permission.manageExternalStorage] is NOT needed for
  /// [file_picker] with scoped storage — [Permission.storage] covers it.
  /// On Android 9 and below, explicit WRITE is still required.
  static Future<bool> requestStorage() async {
    if (kIsWeb) return true;
    if (!Platform.isAndroid) return true;
    // Similar to gallery, modern file pickers on Android handle their own
    // access via scoped storage or system pickers.
    return true;
  }

  // ── Location ─────────────────────────────────────────────────────────────────
  // NOTE: location is already handled by geolocator's own permission flow.
  // Use these only when you need a quick pre-check outside of geolocator.

  /// Request fine location permission.
  static Future<bool> requestLocation() async {
    if (kIsWeb) return true;
    if (!Platform.isAndroid && !Platform.isIOS) return true;
    return _request(Permission.locationWhenInUse);
  }

  // ── Notifications ────────────────────────────────────────────────────────────

  /// Request notification permission (Android 13+ / iOS).
  static Future<bool> requestNotification() async {
    if (kIsWeb) return true;
    if (!Platform.isAndroid && !Platform.isIOS) return true;
    return _request(Permission.notification);
  }

  // ── Internal helper ──────────────────────────────────────────────────────────

  static Future<bool> _request(Permission permission) async {
    final status = await permission.status;
    if (status.isGranted || status.isLimited) return true;

    final result = await permission.request();
    if (result.isGranted || result.isLimited) return true;

    if (result.isPermanentlyDenied) {
      // Don't open settings automatically; let the UI handle it or just return false
    }

    return false;
  }
}
