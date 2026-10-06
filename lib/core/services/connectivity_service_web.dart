import 'package:web/web.dart' as web;
import 'dart:async';
import 'dart:js_interop';

/// Web connectivity check using navigator.onLine and a HEAD fetch.
Future<bool> checkConnectivity() async {
  // Quick check via browser API
  if (!web.window.navigator.onLine) {
    return false;
  }

  // Confirm with an actual network request
  try {
    // Use a tiny request to the app's own origin to avoid CORS issues.
    // Any response (even 404) proves we're online — don't check response.ok.
    await web.window
        .fetch(
          '${web.window.location.origin}/favicon.ico'.toJS,
          web.RequestInit(method: 'HEAD'),
        )
        .toDart;
    return true;
  } catch (_) {
    // If the network request itself fails (no connection), fall back
    return web.window.navigator.onLine;
  }
}
