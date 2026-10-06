import 'dart:async';
import 'dart:developer';
import 'package:injectable/injectable.dart';
import 'package:video_compress/video_compress.dart';

/// Service providing client-side video and media compression.
/// 
/// Uses native hardware acceleration (AVFoundation on iOS, MediaCodec on Android)
/// to transcode video files without the overhead of FFmpeg.
@lazySingleton
class MediaCompressionService {
  Subscription? _progressSubscription;

  /// Compresses a video file at the given [videoPath] using hardware acceleration.
  /// 
  /// Emits progress from 0.0 to 1.0 via [onProgress].
  Future<MediaInfo?> compressVideo(
    String videoPath, {
    VideoQuality quality = VideoQuality.MediumQuality,
    void Function(double progress)? onProgress,
  }) async {
    log('MediaCompressionService: Starting video compression for: $videoPath');
    _progressSubscription?.unsubscribe();
    
    _progressSubscription = VideoCompress.compressProgress$.subscribe(
      (progress) {
        onProgress?.call(progress / 100.0);
      },
    );

    try {
      final mediaInfo = await VideoCompress.compressVideo(
        videoPath,
        quality: quality,
        deleteOrigin: false,
        includeAudio: true,
      );
      if (mediaInfo != null) {
        log('MediaCompressionService: Compression complete. Path: ${mediaInfo.path}, Size: ${mediaInfo.filesize} bytes');
      }
      return mediaInfo;
    } catch (e) {
      log('MediaCompressionService: Error compressing video: $e');
      rethrow;
    } finally {
      _progressSubscription?.unsubscribe();
      _progressSubscription = null;
    }
  }

  /// Cancels any active compression tasks and cleans up resources.
  Future<void> cancelCompression() async {
    log('MediaCompressionService: Cancelling active compression tasks');
    _progressSubscription?.unsubscribe();
    _progressSubscription = null;
    await VideoCompress.cancelCompression();
  }

  /// Generates a JPEG thumbnail file from the video at [videoPath].
  Future<String?> getThumbnailPath(String videoPath) async {
    try {
      final thumbnailFile = await VideoCompress.getFileThumbnail(videoPath);
      return thumbnailFile.path;
    } catch (e) {
      log('MediaCompressionService: Error generating video thumbnail: $e');
      return null;
    }
  }
}
