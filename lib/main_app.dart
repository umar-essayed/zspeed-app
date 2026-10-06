import 'package:z_speed/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/core/constants/page_identity.dart';
import 'package:z_speed/core/navigation/navigation.dart';
import 'package:z_speed/features/auth/model/user_model.dart';
import 'package:z_speed/components/offline_banner.dart';
import 'package:z_speed/features/home/view/home_screen.dart';
import 'package:z_speed/features/cart/cubit/cart_cubit.dart';
import 'package:z_speed/features/customer/cubit/restaurant_browse_cubit.dart';
import 'package:z_speed/features/customer/view/restaurant_browse_screen.dart';
import 'package:z_speed/features/customer/view/history_hub_screen.dart';
import 'package:z_speed/features/customer/widgets/customer_bottom_bar.dart';
import 'package:z_speed/features/cart/view/full_cart_screen.dart';
import 'package:z_speed/features/customer/widgets/guest_auth_prompt.dart';
import 'package:z_speed/features/auth/cubit/auth_cubit.dart';
import 'package:z_speed/core/injection.dart';
import 'package:z_speed/features/stories/cubit/customer_stories_cubit.dart';

class MainApp extends StatefulWidget {
  final AppUser? currentUser;

  const MainApp({super.key, this.currentUser});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  String _selectedPageKey = PageIdentity.home;
  // ValueNotifier so only the BottomBar rebuilds on scroll — not the whole tree.
  final ValueNotifier<bool> _isScrollingNotifier = ValueNotifier(false);
  int _tabIndex = 0;
  DateTime? _lastPressedAt;
  final List<GlobalKey<NavigatorState>> _navigatorKeys = List.generate(
    4,
    (_) => GlobalKey<NavigatorState>(),
  );

  // Screens are created once and reused so Navigator widget identity is stable.
  List<Widget>? _screens;
  late final List<_TabNavigatorObserver> _navigatorObservers;

  /// Safely schedule a setState call after the current frame completes,
  /// avoiding the "Build scheduled during frame" error.
  void _setStateAfterFrame(VoidCallback fn) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(fn);
    });
  }

  String get _activeViewString {
    switch (_tabIndex) {
      case 0:
        return 'home';
      case 1:
        return 'browse';
      case 2:
        return 'cart';
      case 3:
        return 'tracking';
      default:
        return 'home';
    }
  }

  void _onTabTapped(int index) {
    if (_tabIndex == index) {
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
    } else {
      setState(() {
        _tabIndex = index;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _navigatorObservers = List.generate(
      4,
      (index) => _TabNavigatorObserver(() {
        _setStateAfterFrame(() {});
      }),
    );
    // Show welcome toast after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _showWelcomeToast();
      }
    });
  }

  bool get _shouldShowBottomBar {
    if (_tabIndex < 0 || _tabIndex >= _navigatorKeys.length) return true;
    final navState = _navigatorKeys[_tabIndex].currentState;
    if (navState == null) return true;
    return !navState.canPop();
  }

  bool get _isTransportScreen {
    if (_tabIndex < 0 || _tabIndex >= _navigatorObservers.length) return false;
    final activeRoute = _navigatorObservers[_tabIndex].activeRoute;
    if (activeRoute == null) return false;
    final name = activeRoute.settings.name ?? '';
    return name.contains('transport') || name.contains('ride');
  }

  @override
  void didUpdateWidget(covariant MainApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentUser != widget.currentUser) {
      _screens = _buildScreens();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Build the screens list once so Navigator widget identity stays stable
    // across setState calls (prevents scroll-position resets in child screens).
    _screens ??= _buildScreens();
  }

  List<Widget> _buildScreens() {
    return [
      // Tab 0: Home
      Navigator(
        key: _navigatorKeys[0],
        observers: [_navigatorObservers[0]],
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (navContext) => HomePage(
            currentUser: widget.currentUser,
            onVendorTypeSelected: (vendorType) {
              // navContext has access to RestaurantBrowseCubit from BlocProvider above.
              navContext
                  .read<RestaurantBrowseCubit>()
                  .setVendorType(vendorType);
              _navigatorKeys[1]
                  .currentState
                  ?.popUntil((route) => route.isFirst);
              _setStateAfterFrame(() => _tabIndex = 1);
            },
            onSearchSubmitted: (query, detectedType) {
              final browseCubit = navContext.read<RestaurantBrowseCubit>();
              browseCubit.setVendorType(detectedType);
              browseCubit.setSearchQuery(query);
              _navigatorKeys[1]
                  .currentState
                  ?.popUntil((route) => route.isFirst);
              _setStateAfterFrame(() => _tabIndex = 1);
            },
          ),
        ),
      ),
      // Tab 1: Browse
      Navigator(
        key: _navigatorKeys[1],
        observers: [_navigatorObservers[1]],
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (navContext) => const RestaurantBrowseScreen(),
        ),
      ),
      // Tab 2: Cart
      Navigator(
        key: _navigatorKeys[2],
        observers: [_navigatorObservers[2]],
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (navContext) => const FullCartPage(),
        ),
      ),
      // Tab 3: Track
      Navigator(
        key: _navigatorKeys[3],
        observers: [_navigatorObservers[3]],
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (navContext) => const HistoryHubScreen(),
        ),
      ),
    ];
  }

  void _showWelcomeToast() {
    if (widget.currentUser == null) return;
    final firstName = widget.currentUser!.name.split(' ')[0];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.waving_hand_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocalizations.of(context)!.welcomeBackToast(firstName),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppLocalizations.of(context)!.whatAreYouCravingToday,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFF35535),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 16),
        duration: const Duration(seconds: 3),
        elevation: 6,
      ),
    );
  }

  void _navigateToPage(String pageKey) {
    final user = widget.currentUser;
    if (user == null || !NavigationPolicy.canAccess(user, pageKey)) {
      return;
    }

    setState(() {
      _selectedPageKey = pageKey;
    });

    if (pageKey == PageIdentity.home) {
      return;
    }

    final destinationPage =
        NavigationPolicy.getPage(pageKey, user);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => destinationPage),
    );
  }

  void _goHome() {
    for (final key in _navigatorKeys) {
      key.currentState?.popUntil((route) => route.isFirst);
    }
    _setStateAfterFrame(() {
      _tabIndex = 0;
    });
  }

  @override
  void dispose() {
    _isScrollingNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCustomer = widget.currentUser == null ||
        widget.currentUser!.type == UserType.customer;

    if (!isCustomer) {
      return Scaffold(
        drawer: AppDrawer(
          currentUser: widget.currentUser!,
          selectedPageKey: _selectedPageKey,
          onPageSelected: _navigateToPage,
        ),
        body: Column(
          children: [
            const OfflineBanner(),
            Expanded(
              child: HomePage(
                currentUser: widget.currentUser!,
              ),
            ),
          ],
        ),
      );
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider<RestaurantBrowseCubit>(
          create: (_) => RestaurantBrowseCubit(),
        ),
        BlocProvider<CustomerStoriesCubit>(
          create: (_) => getIt<CustomerStoriesCubit>()..init(widget.currentUser?.id),
        ),
      ],
      child: Builder(
        builder: (context) {
          final screens = _screens!;

          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) async {
              if (didPop) return;

              // 1. Pop nested navigator first
              final currentNavigator = _navigatorKeys[_tabIndex].currentState;
              if (currentNavigator != null && currentNavigator.canPop()) {
                currentNavigator.pop();
                return;
              }

              // 2. Switch to Home tab if on other tab
              if (_tabIndex != 0) {
                setState(() {
                  _tabIndex = 0;
                });
                return;
              }

              // 3. Double press back on Home tab to exit
              final now = DateTime.now();
              final isFirstPress = _lastPressedAt == null ||
                  now.difference(_lastPressedAt!) > const Duration(seconds: 2);

              if (isFirstPress) {
                _lastPressedAt = now;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      Localizations.localeOf(context).languageCode == 'ar'
                          ? 'اضغط مرة أخرى للخروج من التطبيق'
                          : 'Press back again to exit',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 13),
                    ),
                    backgroundColor: const Color(0xFFF35535),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    duration: const Duration(seconds: 2),
                  ),
                );
              } else {
                await SystemNavigator.pop();
              }
            },
            child: Scaffold(
              extendBody: true,
              body: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  // Only respond to depth-0 scroll events (direct tab content).
                  // Deeper notifications come from modals/pushed routes and
                  // should not affect the bottom bar or trigger any rebuild.
                  if (notification.depth != 0) return false;
                  if (notification is ScrollStartNotification) {
                    if (!_isScrollingNotifier.value) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          _isScrollingNotifier.value = true;
                        }
                      });
                    }
                  } else if (notification is ScrollEndNotification) {
                    if (_isScrollingNotifier.value) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          _isScrollingNotifier.value = false;
                        }
                      });
                    }
                  }
                  return false;
                },
                child: Column(
                  children: [
                    const OfflineBanner(),
                    Expanded(
                      child: FadeIndexedStack(
                        index: _tabIndex,
                        children: screens,
                      ),
                    ),
                  ],
                ),
              ),
              bottomNavigationBar: ValueListenableBuilder<bool>(
                valueListenable: _isScrollingNotifier,
                builder: (context, isScrolling, _) => CustomerBottomBar(
                  isScrolling: isScrolling,
                  activeView: _activeViewString,
                  cartItemCount: context.watch<CartCubit>().state.items.length,
                  onHome: () {
                    if (!_shouldShowBottomBar) {
                      _goHome();
                    } else {
                      _onTabTapped(0);
                    }
                  },
                  onBrowse: () => _onTabTapped(1),
                  onCart: () {
                    final authState = context.read<AuthCubit>().state;
                    if (authState.isGuest) {
                      GuestAuthPrompt.show(
                        context,
                        actionLabel: AppLocalizations.of(context)!.viewCart,
                      );
                    } else {
                      _onTabTapped(2);
                    }
                  },
                  onTrack: () {
                    final authState = context.read<AuthCubit>().state;
                    if (authState.isGuest) {
                      GuestAuthPrompt.show(
                        context,
                        actionLabel: AppLocalizations.of(context)!.viewOrders,
                      );
                    } else {
                      _onTabTapped(3);
                    }
                  },
                  showOnlyHome: !_shouldShowBottomBar,
                  hideBottomBar: _isTransportScreen,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TabNavigatorObserver extends NavigatorObserver {
  final VoidCallback onRouteChanged;
  Route<dynamic>? activeRoute;

  _TabNavigatorObserver(this.onRouteChanged);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    activeRoute = route;
    onRouteChanged();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    activeRoute = previousRoute;
    onRouteChanged();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    activeRoute = previousRoute;
    onRouteChanged();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    activeRoute = newRoute;
    onRouteChanged();
  }
}

class FadeIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;
  final Duration duration;

  const FadeIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 250),
  });

  @override
  State<FadeIndexedStack> createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<FadeIndexedStack>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(FadeIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: IndexedStack(
        index: widget.index,
        children: widget.children,
      ),
    );
  }
}
