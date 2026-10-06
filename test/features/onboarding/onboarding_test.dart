import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:z_speed/core/injection.dart';
import 'package:z_speed/features/onboarding/view/onboarding_screen.dart';
import 'package:z_speed/l10n/app_localizations.dart';

void main() {
  setUp(() async {
    // Mock initial values for SharedPreferences
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    
    // Register SharedPreferences in GetIt if not registered
    if (!getIt.isRegistered<SharedPreferences>()) {
      getIt.registerSingleton<SharedPreferences>(prefs);
    }
  });

  tearDown(() async {
    // Unregister SharedPreferences to avoid state pollution between tests
    if (getIt.isRegistered<SharedPreferences>()) {
      await getIt.unregister<SharedPreferences>();
    }
  });

  // Helper to pump multiple intermediate frames so PageView transitions can complete
  // without triggering an infinite pumpAndSettle timeout from repeating animations.
  Future<void> pumpTransition(WidgetTester tester) async {
    for (int i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('OnboardingScreen transitions and completes as Guest', (WidgetTester tester) async {
    bool completed = false;
    bool loginRequested = false;

    // Pump OnboardingScreen with localizations
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: OnboardingScreen(
          onCompleted: () {
            completed = true;
          },
          onLoginSignup: () {
            loginRequested = true;
          },
        ),
      ),
    );

    // Verify first page renders with correct titles
    expect(find.text('Fast & Reliable Delivery'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);

    // Find the Next button
    final nextBtn = find.text('Next');
    expect(nextBtn, findsOneWidget);

    // Tap Next to go to the second page
    await tester.tap(nextBtn);
    await pumpTransition(tester);

    // Verify second page content
    expect(find.text('Diverse Services'), findsOneWidget);

    // Tap Next to go to the third page
    await tester.tap(find.text('Next'));
    await pumpTransition(tester);

    // Verify third page content
    expect(find.text('Real-time Tracking'), findsOneWidget);
    
    // The Skip button should be hidden on the last page
    expect(find.text('Skip'), findsNothing);

    // Find and tap Continue as Guest button
    final guestBtn = find.text('Continue as Guest');
    expect(guestBtn, findsOneWidget);

    await tester.tap(guestBtn);
    await pumpTransition(tester);

    // Verify callback was invoked and onboarding_completed was set to true in shared preferences
    expect(completed, isTrue);
    expect(loginRequested, isFalse);
    final prefs = getIt<SharedPreferences>();
    expect(prefs.getBool('onboarding_completed'), isTrue);
  });

  testWidgets('OnboardingScreen transitions and initiates Login/Signup', (WidgetTester tester) async {
    bool completed = false;
    bool loginRequested = false;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: OnboardingScreen(
          onCompleted: () {
            completed = true;
          },
          onLoginSignup: () {
            loginRequested = true;
          },
        ),
      ),
    );

    // Navigate to the final page
    await tester.tap(find.text('Next'));
    await pumpTransition(tester);
    await tester.tap(find.text('Next'));
    await pumpTransition(tester);

    // Find and tap Login / Sign Up button
    final loginBtn = find.text('Login / Sign Up');
    expect(loginBtn, findsOneWidget);

    await tester.tap(loginBtn);
    await pumpTransition(tester);

    // Verify correct callbacks and shared preference state
    expect(completed, isFalse);
    expect(loginRequested, isTrue);
    final prefs = getIt<SharedPreferences>();
    expect(prefs.getBool('onboarding_completed'), isTrue);
  });

  testWidgets('Tapping Skip completes onboarding directly', (WidgetTester tester) async {
    bool completed = false;
    bool loginRequested = false;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: OnboardingScreen(
          onCompleted: () {
            completed = true;
          },
          onLoginSignup: () {
            loginRequested = true;
          },
        ),
      ),
    );

    // Find and tap Skip
    final skipBtn = find.text('Skip');
    expect(skipBtn, findsOneWidget);

    await tester.tap(skipBtn);
    await pumpTransition(tester);

    // Verify callback was invoked and shared preference updated
    expect(completed, isTrue);
    expect(loginRequested, isFalse);
    final prefs = getIt<SharedPreferences>();
    expect(prefs.getBool('onboarding_completed'), isTrue);
  });
}
