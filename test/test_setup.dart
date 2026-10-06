import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

typedef Callback = void Function(MethodCall call);

void setupFirebaseAuthMocks([Callback? customHandlers]) {
  TestWidgetsFlutterBinding.ensureInitialized();

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/firebase_core'), (MethodCall methodCall) async {
    if (methodCall.method == 'Firebase#initializeCore') {
      return [
        {
          'name': '[DEFAULT]',
          'options': {
            'apiKey': '123',
            'appId': '123',
            'messagingSenderId': '123',
            'projectId': '123',
          },
          'pluginConstants': {},
        }
      ];
    }
    if (methodCall.method == 'Firebase#initializeApp') {
      return {
        'name': methodCall.arguments['appName'],
        'options': methodCall.arguments['options'],
        'pluginConstants': {},
      };
    }
    if (customHandlers != null) {
      customHandlers(methodCall);
    }
    return null;
  });
  
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
    .setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/firebase_crashlytics'), (MethodCall methodCall) async {
      return null;
  });

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
    .setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/firebase_analytics'), (MethodCall methodCall) async {
      return null;
  });
}
