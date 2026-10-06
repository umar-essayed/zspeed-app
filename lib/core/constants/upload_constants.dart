/// Upload constraints shared across the app.
///
/// Mirrors the limits enforced by Firebase Storage security rules
/// (storage.rules) so the client can validate before uploading.
class UploadConstants {
  UploadConstants._();

  // ── Size & quality ─────────────────────────────────────────────────────────

  /// Maximum upload size in bytes (10 MB — same as storage.rules).
  static const int maxFileSizeBytes = 10 * 1024 * 1024;

  /// JPEG compression quality used when picking images.
  static const int imageQuality = 75;

  /// Maximum image dimensions after compression.
  static const double imageMaxWidth = 1920;
  static const double imageMaxHeight = 1920;

  // ── Allowed MIME types (must match storage.rules content-type check) ───────

  static List<String> allowedMimeTypes = [
    'image/jpeg',
    'image/png',
    'image/webp',
    'image/gif',
    'image/heic',
    'image/heif',
    'application/pdf',
  ];

  // ── Storage folder prefixes ────────────────────────────────────────────────

  static String folderDriverDocs = 'drivers';
  static String folderRestaurants = 'restaurants';
  static String folderVendors = 'vendors';
  static String folderMenu = 'menu';
  static String folderProfiles = 'profiles';
}
