import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart';

/// Web version of the thumbnail generator that uses HTML5 Canvas to capture the first frame of a video.
Future<Uint8List?> generateVideoThumbnail(String videoPath) async {
  try {
    final completer = Completer<Uint8List?>();
    final video = HTMLVideoElement();
    video.src = videoPath;
    video.crossOrigin = 'anonymous';
    // Mute to comply with autoplay/interaction rules
    video.muted = true;
    video.currentTime = 0.5; // Capture frame at 0.5 seconds

    video.addEventListener(
      'seeked',
      (Event _) {
        try {
          final canvas = HTMLCanvasElement();
          canvas.width = video.videoWidth > 0 ? video.videoWidth : 640;
          canvas.height = video.videoHeight > 0 ? video.videoHeight : 360;

          final ctx =
              canvas.getContext('2d') as CanvasRenderingContext2D?;
          if (ctx == null) {
            completer.complete(null);
            return;
          }
          ctx.drawImage(video, 0, 0);

          canvas.toBlob(
            ((JSObject? blob) {
              if (blob == null) {
                completer.complete(null);
                return;
              }
              final reader = FileReader();
              reader.addEventListener(
                'loadend',
                (Event _) {
                  final result = reader.result;
                  if (result == null) {
                    completer.complete(null);
                    return;
                  }
                  // result is a JSArrayBuffer; convert to Uint8List
                  final buffer = result as JSArrayBuffer;
                  completer.complete(
                    buffer.toDart.asUint8List(),
                  );
                }.toJS,
              );
              reader.readAsArrayBuffer(blob as Blob);
            }).toJS,
            'image/jpeg',
            0.85.toJS,
          );
        } catch (e) {
          completer.complete(null);
        }
      }.toJS,
    );

    video.addEventListener(
      'error',
      (Event _) {
        completer.complete(null);
      }.toJS,
    );

    return completer.future;
  } catch (e) {
    return null;
  }
}
