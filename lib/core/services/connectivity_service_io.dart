import 'dart:io';

/// Native (Android/iOS/Desktop) connectivity check via DNS lookup.
Future<bool> checkConnectivity() async {
  try {
    final result = await InternetAddress.lookup('google.com')
        .timeout(const Duration(seconds: 5));
    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  } catch (_) {
    return false;
  }
}
