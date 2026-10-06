import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:z_speed/firebase_options.dart';
import 'package:z_speed/core/theme/theme_cubit.dart';
import 'package:z_speed/core/services/fcm_service.dart';
import 'package:z_speed/core/services/crashlytics_service.dart';
import 'package:z_speed/core/services/analytics_service.dart';
import 'package:z_speed/core/services/connectivity_cubit.dart';
import 'package:z_speed/core/injection.dart';
import 'package:z_speed/features/cart/cubit/cart_cubit.dart';
import 'package:z_speed/features/auth/cubit/auth_cubit.dart';
import 'package:z_speed/features/auth/cubit/auth_state.dart';
import 'package:z_speed/features/auth/model/user_model.dart';
import 'package:z_speed/features/notification/cubit/notification_cubit.dart';
import 'package:z_speed/features/notification/notification.dart';
import 'package:z_speed/features/auth/view/google_registration_screen.dart';
import 'package:z_speed/features/auth/view/login_screen.dart';
import 'package:z_speed/features/auth/view/account_blocked_screen.dart';
import 'package:z_speed/main_app.dart';
import 'package:z_speed/components/no_internet_screen.dart';
import 'package:z_speed/features/admin/view/admin_app_screen.dart';
import 'package:z_speed/features/driver/view/driver_app_screen.dart';
import 'package:z_speed/features/restaurant_owner/view/restaurant_hub_screen.dart';
import 'package:z_speed/features/order/view/order_tracking_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:z_speed/features/customer/view/vendor_menu_page.dart';
import 'package:z_speed/components/promo_code_dialog.dart';
import 'package:z_speed/core/theme/dark_mode.dart';
import 'package:z_speed/features/shared/widgets/pending_account_overlay.dart';
import 'package:z_speed/features/auth/widgets/name_dialog.dart';
import 'package:z_speed/features/auth/widgets/phone_verification_dialog.dart';
import 'package:z_speed/core/constants/app_routes.dart';
import 'package:z_speed/core/navigation/navigation.dart';
import 'package:z_speed/features/pharmacy_chat/view/pharmacy_chat_screen.dart';
import 'package:z_speed/features/pharmacy_chat/cubit/pharmacy_chat_cubit.dart';
import 'package:z_speed/features/admin/datasource/settings_datasource.dart';
import 'package:z_speed/features/shared/view/maintenance_screen.dart';
import 'package:z_speed/core/utils/app_version_helper.dart';
import 'package:z_speed/features/shared/view/force_update_screen.dart';
import 'package:z_speed/features/shared/widgets/flexible_update_dialog.dart';
import 'package:z_speed/features/onboarding/view/onboarding_screen.dart';

// Localization
import 'package:z_speed/l10n/app_localizations.dart';

import 'package:z_speed/core/localization/locale_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Top-level function for handling FCM background messages.
/// Must be a top-level function (not a method).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  debugPrint('Handling background message: ${message.messageId}');
  debugPrint('Title: ${message.notification?.title}');
  debugPrint('Body: ${message.notification?.body}');
  // Background processing can be added here
}

Future<void> main() async {
  // Global error zone (Phase 8.10)
  // Catches all async errors that escape the Flutter framework
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Load app version dynamically from native configurations
      await AppVersionHelper.loadVersionInfo();

      // Clear image cache on startup to avoid loading corrupted cached files/images
      try {
        await DefaultCacheManager().emptyCache();
        PaintingBinding.instance.imageCache.clear();
        PaintingBinding.instance.imageCache.clearLiveImages();
        debugPrint('Successfully cleared image cache on startup.');
      } catch (e) {
        debugPrint('Failed to clear image cache: $e');
      }

      try {
        // 1. Load environment variables first (needed by Firebase options)
        await dotenv.load(fileName: "assets/env");

        // 2. Initialize Firebase before DI (DI registers FirebaseAuth/Firestore instances)
        if (Firebase.apps.isEmpty) {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );
        }

        // Configure App Check for mobile, disable for Web local development
        try {
          if (!kIsWeb) {
            await FirebaseAppCheck.instance.activate(
              providerAndroid: kDebugMode
                  ? const AndroidDebugProvider()
                  : const AndroidPlayIntegrityProvider(),
              providerApple: kDebugMode
                  ? const AppleDebugProvider()
                  : const AppleDeviceCheckProvider(),
            );
          }
        } catch (e) {
          debugPrint('App Check activation failed (non-fatal): $e');
        }
        // 3. Initialize Google Sign In (must be called once before authenticate())
        if (!kIsWeb) {
          await GoogleSignIn.instance.initialize();
        }

        // 4. Now configure DI (safe to access Firebase instances)
        await configureDependencies();
      } catch (e, st) {
        debugPrint('INIT ERROR: $e\n$st');
        // Show a visible error screen instead of a silent white screen
        runApp(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Failed to initialize app:\n$e',
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        );
        return;
      }

      // Initialize Crashlytics (Phase 8.10) — not supported on web
      if (!kIsWeb) {
        await CrashlyticsService.init();
      }

      // Configure Firestore offline persistence (Phase 8.10)
      // Avoid offline persistence on Web to prevent IndexedDB hanging issues during auth.
      if (!kIsWeb) {
        FirebaseFirestore.instance.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: 100 * 1024 * 1024, // 100 MB
        );
      }

      // Register FCM background message handler — not supported on web
      if (!kIsWeb) {
        FirebaseMessaging.onBackgroundMessage(
          firebaseMessagingBackgroundHandler,
        );
      }

      final prefs = await SharedPreferences.getInstance();
      final savedLangCode = prefs.getString('selected_language');

      runApp(
        MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => getIt<CartCubit>()),
            BlocProvider(create: (_) => getIt<ConnectivityCubit>()),
            BlocProvider(create: (_) => getIt<AuthCubit>()),
            BlocProvider(create: (_) => LocaleCubit(prefs, savedLangCode)),
            BlocProvider(create: (_) => getIt<ThemeCubit>()),
          ],
          child: const MyApp(),
        ),
      );
    },
    (error, stackTrace) {
      // Catch all uncaught async errors
      debugPrint('Uncaught error: $error\n$stackTrace');
      if (!kIsWeb) {
        CrashlyticsService.recordError(error, stackTrace, fatal: true);
      }
    },
  );
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Set to true to bypass maintenance mode locally (e.g. during development/testing).
/// Toggle or uncomment this to bypass the maintenance screen.
const bool bypassMaintenanceMode = kDebugMode;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authCubit = context.read<AuthCubit>();

    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (previous, current) =>
          previous.isAuthenticated != current.isAuthenticated,
      listener: (context, state) {
        // User signed out OR logged in — pop everything pushed on top
        // of AuthWrapper so the root rebuilds cleanly.
        navigatorKey.currentState?.popUntil((route) => route.isFirst);
      },
      child: BlocBuilder<ThemeCubit, ThemeData>(
        builder: (context, theme) {
          return BlocBuilder<LocaleCubit, Locale>(
            builder: (context, locale) {
              return MaterialApp(
                navigatorKey: navigatorKey,
                locale: locale,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                debugShowCheckedModeBanner: false,
                title: 'Z Speed Delivery Service',
                theme: theme.copyWith(
                  primaryColor: const Color(0xFFF35535),
                  scaffoldBackgroundColor: Colors.white,
                  canvasColor: Colors.white,
                  cardColor: const Color(0xFFF9FAFB),
                  appBarTheme: const AppBarTheme(
                    backgroundColor: Colors.white,
                    foregroundColor: Color(0xFF2D3748),
                    elevation: 0,
                    iconTheme: IconThemeData(color: Color(0xFF2D3748)),
                  ),
                  drawerTheme: const DrawerThemeData(
                    backgroundColor: Colors.white,
                  ),
                  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
                    backgroundColor: Colors.white,
                    selectedItemColor: Color(0xFFF35535),
                    unselectedItemColor: Color(0xFF718096),
                  ),
                  colorScheme: const ColorScheme.light(
                    primary: Color(0xFFF35535),
                    secondary: Color(0xFFFFEBE8),
                    surface: Colors.white,
                    onPrimary: Colors.white,
                    onSurface: Color(0xFF2D3748),
                  ),
                ),
                darkTheme: darkMode,
                themeMode: context.read<ThemeCubit>().themeMode,
                home: const AuthWrapper(),
                builder: (context, child) {
                  return BlocBuilder<ConnectivityCubit, ConnectivityStatus>(
                    builder: (context, status) {
                      if (status == ConnectivityStatus.offline) {
                        return const NoInternetScreen();
                      }
                      return StreamBuilder<
                        DocumentSnapshot<Map<String, dynamic>>
                      >(
                        stream: getIt<SettingsDatasource>().watchAppSettings(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            debugPrint(
                              '[VersionCheck] Firestore Stream Error: ${snapshot.error}',
                            );
                          }
                          final settingsData = snapshot.data?.data() ?? {};
                          final maintenanceActive =
                              settingsData['maintenanceMode'] as bool? ?? false;
                          final minRequiredVersion =
                              settingsData['minRequiredVersion'] as String? ??
                              '1.0.0';
                          final updateUrl = AppVersionHelper.getUpdateUrl(
                            settingsData,
                          );

                          debugPrint(
                            '[VersionCheck] Current Version: ${AppVersionHelper.currentVersion}, Min Required: $minRequiredVersion, Latest: ${settingsData['latestVersion']}, isOlder: ${AppVersionHelper.isOlder(AppVersionHelper.currentVersion, minRequiredVersion)}',
                          );

                          final user = context.watch<AuthCubit>().state.user;
                          final isAdmin =
                              user != null &&
                              (user.type == UserType.admin ||
                                  user.type == UserType.superAdmin);

                          if (bypassMaintenanceMode) {
                            return child ?? const SizedBox.shrink();
                          }

                          // 1. Check for Critical/Force Update
                          if (AppVersionHelper.isOlder(
                                AppVersionHelper.currentVersion,
                                minRequiredVersion,
                              ) &&
                              !isAdmin) {
                            return ForceUpdateScreen(updateUrl: updateUrl);
                          }

                          // 2. Check for Maintenance Mode
                          if (maintenanceActive && !isAdmin) {
                            return const MaintenanceScreen();
                          }
                          return child ?? const SizedBox.shrink();
                        },
                      );
                    },
                  );
                },
                routes: AppRoutes.routeMap,
                navigatorObservers: [
                  AnalyticsService.observer,
                ], // Phase 8.10: Screen tracking
                onGenerateRoute: (settings) {
                  return RouteGuard.onGenerateRoute(settings, authCubit);
                },
              );
            },
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _initialCheckDone = false;
  bool _onboardingCompleted = false;

  static const Duration _minSplashDuration = Duration(milliseconds: 2500);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = getIt<SharedPreferences>();
      final isCompleted = prefs.getBool('onboarding_completed') ?? false;

      // Both the auth check AND the minimum splash duration must complete
      // before we dismiss the splash screen.
      await Future.wait([
        context.read<AuthCubit>().checkAuthStatus(),
        Future.delayed(_minSplashDuration),
      ]);
      if (mounted) {
        setState(() {
          _onboardingCompleted = isCompleted || kIsWeb;
          _initialCheckDone = true;
        });
        _checkFlexibleUpdate();
      }
    });
  }

  Future<void> _checkFlexibleUpdate() async {
    if (AppVersionHelper.wasFlexibleUpdatePrompted) return;
    AppVersionHelper.wasFlexibleUpdatePrompted = true;

    try {
      final settings = await getIt<SettingsDatasource>().getSettings();
      final latestVersion = settings['latestVersion'] as String? ?? '1.0.0';
      final minRequiredVersion =
          settings['minRequiredVersion'] as String? ?? '1.0.0';
      final updateUrl = AppVersionHelper.getUpdateUrl(settings);

      final current = AppVersionHelper.currentVersion;

      // Only prompt if current version is older than latestVersion, but not older than minRequiredVersion
      if (AppVersionHelper.isOlder(current, latestVersion) &&
          !AppVersionHelper.isOlder(current, minRequiredVersion)) {
        final prefs = await SharedPreferences.getInstance();
        final dismissedKey = 'dismissed_update_$latestVersion';
        final isDismissed = prefs.getBool(dismissedKey) ?? false;

        if (!isDismissed && mounted) {
          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (context) => FlexibleUpdateDialog(
              latestVersion: latestVersion,
              updateUrl: updateUrl,
              onLaterPressed: () async {
                await prefs.setBool(dismissedKey, true);
              },
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error checking flexible update: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;

    // Show splash only during the one-time initial auth check.
    // During login/register the LoginPage stays mounted so it can
    // display its own spinner and show error SnackBars.
    if (!_initialCheckDone) {
      return const SplashScreen();
    }

    if (!_onboardingCompleted) {
      return OnboardingScreen(
        onCompleted: () {
          setState(() {
            _onboardingCompleted = true;
          });
        },
        onLoginSignup: () {
          setState(() {
            _onboardingCompleted = true;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            navigatorKey.currentState?.pushNamed(AppRoutes.login);
          });
        },
      );
    }

    if (authState.isBlocked) {
      return const AccountBlockedScreen();
    }

    if (authState.needsRoleSelection) {
      return GoogleRegistrationScreen(
        pendingUser: authState.pendingGoogleUser!,
      );
    }

    if (!authState.isAuthenticated) {
      return const LoginPage();
    }

    // User is authenticated - provide NotificationViewModel
    return AuthenticatedApp(currentUser: authState.user!);
  }
}

/// Wrapper for authenticated users - provides NotificationViewModel and initializes FCM
class AuthenticatedApp extends StatefulWidget {
  final AppUser currentUser;

  const AuthenticatedApp({super.key, required this.currentUser});

  @override
  State<AuthenticatedApp> createState() => _AuthenticatedAppState();
}

class _AuthenticatedAppState extends State<AuthenticatedApp> {
  final FcmService _fcmService = FcmService();
  late NotificationCubit _notificationCubit;

  @override
  void initState() {
    super.initState();

    // Initialize NotificationCubit synchronously so it's available in build().
    _notificationCubit = getIt<NotificationCubit>(
      param1: widget.currentUser.id,
    );

    // Kick off async FCM setup separately.
    _initializeNotifications();

    // Check if customer needs name or phone verification (post-login prompts).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showPostLoginPrompts();
    });
  }

  /// Show name dialog (if needed) then phone verification dialog (if needed)
  /// for customer users who signed in via phone (no name) or email (no phone).
  Future<void> _showPostLoginPrompts() async {
    if (!mounted) return;
    final authCubit = context.read<AuthCubit>();

    // 1. Name dialog for phone-signup users with empty name
    if (authCubit.state.needsName) {
      await NameDialog.show(context);
      if (!mounted) return;
    }

    // 2. Phone verification for email-signup customers without phone
    if (authCubit.state.customerNeedsPhone) {
      final prefs = await SharedPreferences.getInstance();
      final skippedKey = 'phone_verification_skipped_${widget.currentUser.id}';
      final hasSkipped = prefs.getBool(skippedKey) ?? false;
      if (!hasSkipped) {
        if (!mounted) return;
        final verified = await PhoneVerificationDialog.show(context);
        if (verified == false) {
          await prefs.setBool(skippedKey, true);
        }
      }
    }
  }

  Future<void> _initializeNotifications() async {
    // Initialize FCM
    await _fcmService.initialize(widget.currentUser.id);

    // Phase 11: Subscribe to role-specific topics
    if (widget.currentUser.type == UserType.driver) {
      await _fcmService.subscribeToTopic('driver_orders');
    }

    // Set up message handlers
    _fcmService.setupMessageHandlers(
      onForeground: (message) {
        debugPrint('Foreground message: ${message.notification?.title}');
        if (mounted && message.notification != null) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.notification!.title ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(message.notification!.body ?? ''),
                ],
              ),
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Open',
                onPressed: () {
                  _handleNotificationNavigation(message.data);
                },
              ),
            ),
          );
        }
      },
      onMessageTap: (message) {
        debugPrint('Message tapped: ${message.data}');
        _handleNotificationNavigation(message.data);
      },
    );

    // Check for cold-start notification tap
    final initialMessage = await _fcmService.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('App opened from notification: ${initialMessage.data}');
      _handleNotificationNavigation(initialMessage.data);
    }
  }

  void _handleNotificationNavigation(Map<String, dynamic> data) {
    final screen = data['screen'] as String?;
    final orderId = data['orderId'] as String?;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      switch (screen) {
        case 'promo_code':
          final code =
              (data['promoCode'] ?? data['code'] ?? data['targetEntityId'])
                  ?.toString();
          if (code != null && code.isNotEmpty) {
            final navCtx = navigatorKey.currentContext;
            if (navCtx != null) {
              DateTime? expiresAt;
              final expiresRaw = data['expiresAt'] ?? data['validUntil'];
              if (expiresRaw is String) {
                expiresAt = DateTime.tryParse(expiresRaw);
              }
              PromoCodeDialog.show(navCtx, code, expiresAt: expiresAt);
            }
          }
          break;
        case 'vendor':
        case 'restaurant':
          final vendorId =
              (data['targetEntityId'] ??
                      data['vendorId'] ??
                      data['restaurantId'])
                  ?.toString();
          if (vendorId != null && vendorId.isNotEmpty) {
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (_) => RestaurantMenuPage(restaurantId: vendorId),
              ),
            );
          }
          break;
        case 'custom_url':
        case 'url':
          final urlStr =
              (data['targetEntityId'] ?? data['url'] ?? data['custom_url'])
                  as String?;
          if (urlStr != null && urlStr.isNotEmpty) {
            final uri = Uri.tryParse(urlStr);
            if (uri != null) {
              launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          }
          break;
        case 'pharmacy_chat':
          final chatId = data['chatId'] as String?;
          final requestId = data['requestId'] as String?;
          final pharmacyName =
              data['pharmacyName'] as String? ?? 'Pharmacy Support';
          if (chatId != null) {
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (_) => BlocProvider(
                  create: (_) => PharmacyChatCubit(),
                  child: PharmacyChatScreen(
                    chatId: chatId,
                    requestId: requestId,
                    pharmacyName: pharmacyName,
                  ),
                ),
              ),
            );
          }
          break;
        case 'order_detail':
        case 'order_tracking':
        case 'vendor_order_detail':
          if (orderId != null) {
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (_) => OrderTrackingScreen(orderId: orderId),
              ),
            );
          }
          break;
        case 'admin_applications':
        case 'admin_application_detail':
          navigatorKey.currentState?.pushNamed('/admin');
          break;
        case 'delivery_request':
          // الـ driver يشوف الـ request في الـ dashboard
          break;
        default:
          if (orderId != null) {
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (_) => OrderTrackingScreen(orderId: orderId),
              ),
            );
          }
      }
    });
  }

  @override
  void didUpdateWidget(AuthenticatedApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentUser.id != widget.currentUser.id) {
      _fcmService.dispose();
      _notificationCubit.cancelStreams();
      _notificationCubit = getIt<NotificationCubit>(
        param1: widget.currentUser.id,
      );
      _initializeNotifications();
    }
  }

  @override
  void dispose() {
    _fcmService.dispose();
    _notificationCubit.cancelStreams();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Route users to role-specific dashboards
    // Read from AuthCubit directly so routing reacts to auth state changes.
    final user = context.watch<AuthCubit>().state.user ?? widget.currentUser;
    final appContent = switch (user.type) {
      UserType.superAdmin || UserType.admin => const AdminApp(),
      UserType.driver => const PendingAccountOverlay(child: DriverApp()),
      UserType.vendor => const PendingAccountOverlay(child: MainDashboard()),
      UserType.customer => MainApp(currentUser: user),
    };

    return BlocProvider<NotificationCubit>.value(
      value: _notificationCubit,
      child: appContent,
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _dotsController;

  @override
  void initState() {
    super.initState();
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color bg = Color(0xFF1C1C1E);
    const Color primary = Color(0xFFF35535);

    return Scaffold(
      backgroundColor: bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Image.asset(
              'assets/images/icon.png',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
            ),

            const SizedBox(height: 28),

            // App name
            const Text(
              'Z Speed',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                fontFamily: 'Cairo',
                letterSpacing: 1.0,
              ),
            ),

            const SizedBox(height: 6),

            // Tagline
            Text(
              'Fast Delivery, Delivered.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 13,
                fontFamily: 'Cairo',
              ),
            ),

            const SizedBox(height: 56),

            // Bouncing dots loader
            AnimatedBuilder(
              animation: _dotsController,
              builder: (_, _) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final delay = i / 3.0;
                    final raw = (_dotsController.value - delay).remainder(1.0);
                    final t = raw < 0 ? raw + 1.0 : raw;
                    final bounce = t < 0.5
                        ? Curves.easeOut.transform(t * 2)
                        : Curves.easeIn.transform(1.0 - (t - 0.5) * 2);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Opacity(
                        opacity: 0.3 + 0.7 * bounce,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: primary,
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
