import 'dart:typed_data';

/// Stub version of the thumbnail generator that returns null on native platforms.
Future<Uint8List?> generateVideoThumbnail(String videoPath) async {
  return null;
}
