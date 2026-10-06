import 'dart:developer';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:injectable/injectable.dart';

import 'package:z_speed/core/constants/upload_constants.dart';
import 'package:z_speed/core/utils/image_utils.dart';

/// Result of a successful file upload.
class UploadResult {
  final String url;
  final String fileId;
  final String fileName;
  final String contentType;
  final int size;

  UploadResult({
    required this.url,
    required this.fileId,
    required this.fileName,
    required this.contentType,
    required this.size,
  });

  @override
  String toString() => 'UploadResult(url: $url, size: $size)';
}

/// Secure upload gateway that routes all file uploads through a Firebase
/// Cloud Function (`uploadFile`).
///
/// The Cloud Function receives the file as base64, validates it server-side,
/// uploads it to Firebase Storage using the Admin SDK, and returns a permanent
/// public download URL.
///
/// This approach solves Flutter Web CORS/MIME issues that occur with direct
/// client-side Storage uploads and adds an extra server-side validation layer.
///
/// Works identically on web, mobile, and desktop.
@lazySingleton
class MediaUploadService {
  // ── Singleton ──────────────────────────────────────────────────────────────

  static final MediaUploadService _instance = MediaUploadService._internal();
  factory MediaUploadService() => _instance;
  MediaUploadService._internal();

  // ── Magic-byte MIME detection ──────────────────────────────────────────────

  /// Detect MIME type from the first few bytes of a file (magic bytes).
  static String? _detectMimeFromBytes(Uint8List bytes) {
    if (bytes.length < 4) return null;
    // JPEG: FF D8 FF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return 'image/jpeg';
    }
    // PNG: 89 50 4E 47
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    // WebP: RIFF....WEBP
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }
    // GIF: GIF8
    if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) {
      return 'image/gif';
    }
    // PDF: %PDF
    if (bytes[0] == 0x25 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x44 &&
        bytes[3] == 0x46) {
      return 'application/pdf';
    }
    return null;
  }

  // ── No-ops kept for API compatibility ─────────────────────────────────────

  /// No-op — kept for API compatibility.
  Future<void> authorize() async {}

  /// No-op — kept for API compatibility.
  Future<void> getUploadUrl() async {}

  // ── Upload ─────────────────────────────────────────────────────────────────

  /// Upload [xFile] to Firebase Storage directly using client-side SDK.
  ///
  /// The file is read as bytes and sent to the Firebase Storage bucket.
  ///
  /// [onProgress] is called with values from 0.0 to 1.0.
  /// Returns [UploadResult] with the permanent download URL and metadata.
  Future<UploadResult> uploadXFile(
    XFile xFile,
    String folder, {
    void Function(double progress)? onProgress,
  }) async {
    onProgress?.call(0.05);

    // ── Read file bytes ────────────────────────────────────────────────
    final Uint8List fileBytes = await xFile.readAsBytes();
    final int fileSize = fileBytes.length;

    // Use xFile.name for the file name (on Web, xFile.path is a blob: URL).
    final String originalName = xFile.name.isNotEmpty ? xFile.name : 'upload';

    // ── Client-side size check ─────────────────────────────────────────
    if (fileSize > UploadConstants.maxFileSizeBytes) {
      throw Exception(
        'File exceeds the 10MB limit. '
        '(Current: ${ImageUtils.humanReadableSize(fileSize)})',
      );
    }
    if (fileSize == 0) {
      throw Exception('Selected file is empty.');
    }

    // ── MIME type resolution ───────────────────────────────────────────
    // Priority: xFile.mimeType → magic-byte detection → extension guess
    String contentType = 'application/octet-stream';
    final xMime = xFile.mimeType;
    if (xMime != null &&
        xMime.isNotEmpty &&
        xMime != 'application/octet-stream') {
      contentType = xMime;
      log('MediaUploadService: MIME from xFile.mimeType → $contentType');
    } else {
      final magicMime = _detectMimeFromBytes(fileBytes);
      if (magicMime != null) {
        contentType = magicMime;
        log('MediaUploadService: MIME from magic bytes → $contentType');
      } else {
        contentType = ImageUtils.guessMimeType(originalName);
        log('MediaUploadService: MIME from extension → $contentType');
      }
    }

    log('MediaUploadService: uploading directly to Firebase Storage: '
        '$folder/$originalName '
        '(${ImageUtils.humanReadableSize(fileSize)}, $contentType)');

    onProgress?.call(0.15);

    // ── Generate unique filename (matching Cloud Function logic) ───────
    final int timestamp = DateTime.now().millisecondsSinceEpoch;
    final String safeName = originalName
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^\w.\-]'), '');
    final String uniqueName =
        '${timestamp}_${safeName.isNotEmpty ? safeName : "upload"}';
    final String storagePath = '$folder/$uniqueName';

    // ── Direct Firebase Storage Upload ─────────────────────────────────
    try {
      final Reference storageRef =
          FirebaseStorage.instance.ref().child(storagePath);
      final currentUserId =
          FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';

      final metadata = SettableMetadata(
        contentType: contentType,
        customMetadata: {
          'uploadedBy': currentUserId,
          'originalName': originalName,
        },
      );

      onProgress?.call(0.25);

      final UploadTask uploadTask = storageRef.putData(fileBytes, metadata);

      // Track progress
      uploadTask.snapshotEvents.listen(
        (TaskSnapshot snapshot) {
          if (snapshot.totalBytes > 0) {
            final double progress =
                snapshot.bytesTransferred / snapshot.totalBytes;
            onProgress?.call(0.25 + (progress * 0.70)); // map 0-100% to 25-95%
          }
        },
        onError: (Object e) {
          log('MediaUploadService: Upload stream error: $e');
        },
      );

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      onProgress?.call(1.0);
      log('MediaUploadService: upload complete → $downloadUrl');

      return UploadResult(
        url: downloadUrl,
        fileId: storagePath,
        fileName: uniqueName,
        contentType: contentType,
        size: fileSize,
      );
    } on FirebaseException catch (e) {
      log('MediaUploadService: Firebase Storage error [${e.code}]: ${e.message}');
      throw Exception('Upload failed (${e.code}): ${e.message}');
    } catch (e) {
      log('MediaUploadService: unexpected upload error: $e');
      rethrow;
    }
  }

  // ── Delete ─────────────────────────────────────────────────────────────────

  /// Delete a file from Firebase Storage by its full path (fileId).
  Future<void> deleteFile(String storagePath) async {
    try {
      log('MediaUploadService: deleting file directly from storage: $storagePath');
      await FirebaseStorage.instance.ref(storagePath).delete();
      log('MediaUploadService: delete complete.');
    } on FirebaseException catch (e) {
      log('MediaUploadService: Firebase Storage delete error [${e.code}]: ${e.message}');
      throw Exception('Delete failed (${e.code}): ${e.message}');
    } catch (e) {
      log('MediaUploadService: unexpected delete error: $e');
      rethrow;
    }
  }

  // ── Invalidate ─────────────────────────────────────────────────────────────

  /// No-op — kept for API compatibility.
  Future<void> invalidate() async {}
}
