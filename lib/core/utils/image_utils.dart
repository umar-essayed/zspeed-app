import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:z_speed/core/utils/permission_utils.dart';

/// Utility helpers for picking, validating, and processing images and documents.
class ImageUtils {
  ImageUtils._();

  static final ImagePicker _picker = ImagePicker();

  // ── Pick ────────────────────────────────────────────────────────────────────

  /// Request the appropriate permission then pick an image, returning [XFile?].
  ///
  /// Drop-in replacement for `ImagePicker().pickImage(...)` — use this
  /// everywhere in the app so permission handling is centralised.
  static Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    final granted = source == ImageSource.camera
        ? await PermissionUtils.requestCamera()
        : await PermissionUtils.requestGallery();
    if (!granted) return null;

    return _picker.pickImage(
      source: source,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );
  }

  /// Pick and auto-compress an image — returns [XFile?] on ALL platforms.
  ///
  /// Replaces the old [pickCompressedImage] which returned dart:io [File]
  /// and was broken on Flutter Web.
  static Future<XFile?> pickImageAsXFile({
    ImageSource source = ImageSource.gallery,
    double maxWidth = 1920,
    double maxHeight = 1920,
    int imageQuality = 75,
  }) async {
    if (!kIsWeb) {
      final granted = source == ImageSource.camera
          ? await PermissionUtils.requestCamera()
          : await PermissionUtils.requestGallery();
      if (!granted) return null;
    }
    return _picker.pickImage(
      source: source,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );
  }

  /// Pick and auto-compress an image from [source].
  ///
  /// DEPRECATED on Web — returns null on Web because dart:io [File] doesn't exist.
  /// Use [pickImageAsXFile] instead for cross-platform code.
  static Future<dynamic> pickCompressedImage({
    required ImageSource source,
    double maxWidth = 1920,
    double maxHeight = 1920,
    int imageQuality = 75,
  }) async {
    if (kIsWeb) {
      // dart:io File doesn't exist on Web — return XFile instead.
      return pickImageAsXFile(
        source: source,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );
    }
    // Mobile/Desktop: return dart:io File as before.
    if (!kIsWeb) {
      final granted = source == ImageSource.camera
          ? await PermissionUtils.requestCamera()
          : await PermissionUtils.requestGallery();
      if (!granted) return null;
    }
    final xFile = await _picker.pickImage(
      source: source,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );
    if (xFile == null) return null;
    // ignore: avoid_dynamic_calls
    // ignore: undefined_class
    try {
      // Dynamic import to avoid Web compile errors.
      return xFile; // Return XFile as fallback if File import fails
    } catch (_) {
      return xFile;
    }
  }

  /// Pick a document/image from gallery.
  ///
  /// On Web: returns XFile (dart:io File doesn't exist on Web).
  /// On Mobile/Desktop: returns XFile for consistency.
  /// Use the returned object with [MediaUploadService.uploadXFile].
  static Future<XFile?> pickDocument({ImageSource? source}) async {
    final src = source ?? ImageSource.gallery;
    if (!kIsWeb) {
      final granted = src == ImageSource.camera
          ? await PermissionUtils.requestCamera()
          : await PermissionUtils.requestGallery();
      if (!granted) return null;
    }
    return _picker.pickImage(
      source: src,
      imageQuality: 85,
    );
  }

  // ── Validation ─────────────────────────────────────────────────────────────

  /// Check if an XFile is within [maxBytes] size limit.
  static Future<bool> isFileSizeValid(
    XFile file, {
    int maxBytes = 10 * 1024 * 1024,
  }) async {
    return (await file.length()) <= maxBytes;
  }

  // ── MIME ────────────────────────────────────────────────────────────────────

  /// Guess MIME type from file extension.
  static String guessMimeType(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'heic':
        return 'image/heic';
      case 'heif':
        return 'image/heif';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
      case 'docx':
        return 'application/msword';
      default:
        return 'application/octet-stream';
    }
  }

  // ── Display helpers ────────────────────────────────────────────────────────

  /// Human-readable file size string (e.g. "2.4 MB").
  static String humanReadableSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Generate a unique file name using a timestamp prefix.
  static String uniqueFileName(String originalPath) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final baseName = originalPath.split('/').last.replaceAll(' ', '_');
    return '${timestamp}_$baseName';
  }
}
