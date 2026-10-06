import 'dart:developer';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';

import 'package:z_speed/core/constants/upload_constants.dart';
import 'package:z_speed/core/services/media_upload_service.dart';
import 'package:z_speed/core/utils/image_utils.dart';

/// High-level convenience wrappers around [MediaUploadService].
///
/// All methods work correctly on Web, Mobile, and Desktop.
/// On Web, dart:io [File] is NOT used — only [XFile] from image_picker.
class UploadUtils {
  UploadUtils._();

  static bool _initialized = false;

  // ── Bootstrap ──────────────────────────────────────────────────────────────

  /// No-op — Firebase Storage requires no manual initialization.
  static Future<void> ensureInitialized({
    String? b2KeyId,
    String? b2AppKey,
  }) async {
    if (_initialized) return;
    _initialized = true;
    log('UploadUtils: initialized (Firebase Storage)');
  }

  // ── Pick + Upload Combos ───────────────────────────────────────────────────

  /// Pick an image from [source], compress it, and upload to [folder].
  ///
  /// Returns the [UploadResult] or null if the user cancelled the picker.
  /// Works correctly on Flutter Web (uses XFile, not dart:io File).
  static Future<UploadResult?> pickAndUploadImage({
    required String folder,
    ImageSource source = ImageSource.gallery,
    void Function(double)? onProgress,
  }) async {
    // Use pickImage (returns XFile) — works on ALL platforms including Web.
    final xFile = await ImageUtils.pickImage(
      source: source,
      maxWidth: UploadConstants.imageMaxWidth,
      maxHeight: UploadConstants.imageMaxHeight,
      imageQuality: UploadConstants.imageQuality,
    );

    if (xFile == null) return null;

    final sizeBytes = await xFile.length();
    if (sizeBytes > UploadConstants.maxFileSizeBytes) {
      throw Exception(
        'Image is too large (max ${ImageUtils.humanReadableSize(UploadConstants.maxFileSizeBytes)})',
      );
    }

    return await uploadXFile(xFile: xFile, folder: folder, onProgress: onProgress);
  }

  /// Pick a document from gallery and upload to [folder].
  ///
  /// Returns the [UploadResult] or null if the user cancelled the picker.
  /// Works correctly on Flutter Web (uses XFile, not dart:io File).
  static Future<UploadResult?> pickAndUploadDocument({
    required String folder,
    void Function(double)? onProgress,
  }) async {
    // Use pickImage (returns XFile) — works on ALL platforms including Web.
    final xFile = await ImageUtils.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (xFile == null) return null;

    final sizeBytes = await xFile.length();
    if (sizeBytes > UploadConstants.maxFileSizeBytes) {
      throw Exception(
        'Document is too large (max ${ImageUtils.humanReadableSize(UploadConstants.maxFileSizeBytes)})',
      );
    }

    return await uploadXFile(xFile: xFile, folder: folder, onProgress: onProgress);
  }

  /// Upload an already-picked [XFile] to Firebase Storage under [folder].
  ///
  /// Preferred method — works on ALL platforms.
  static Future<UploadResult> uploadXFile({
    required XFile xFile,
    required String folder,
    void Function(double)? onProgress,
  }) async {
    if (!_initialized) await ensureInitialized();
    final service = MediaUploadService();
    return await service.uploadXFile(xFile, folder, onProgress: onProgress);
  }

  /// Upload an already-picked [File] (dart:io) to Firebase Storage under [folder].
  ///
  /// WARNING: dart:io File does NOT exist on Flutter Web.
  /// Use [uploadXFile] instead when on Web.
  static Future<UploadResult> uploadFile({
    required dynamic file, // dart:io File — only use on mobile/desktop
    required String folder,
    void Function(double)? onProgress,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError(
        'UploadUtils.uploadFile(File) is not supported on Web. '
        'Use UploadUtils.uploadXFile(XFile) instead.',
      );
    }
    if (!_initialized) await ensureInitialized();
    final service = MediaUploadService();
    // On mobile/desktop, file.path is a real file system path.
    final xFile = XFile(file.path as String);
    return await service.uploadXFile(xFile, folder, onProgress: onProgress);
  }
}
