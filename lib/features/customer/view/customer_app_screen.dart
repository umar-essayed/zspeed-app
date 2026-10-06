import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:z_speed/core/enums/user_enums.dart';

import 'package:z_speed/features/auth/cubit/auth_cubit.dart';
import 'package:z_speed/features/order/cubit/checkout_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/features/cart/cubit/cart_cubit.dart';
import 'package:z_speed/features/cart/widgets/cart_sidebar_widget.dart';
import 'package:z_speed/features/customer/cubit/restaurant_browse_cubit.dart';
import 'package:z_speed/features/customer/view/restaurant_browse_screen.dart';
import 'package:z_speed/features/customer/view/history_hub_screen.dart';
import 'package:z_speed/features/customer/widgets/customer_bottom_bar.dart';
import 'package:z_speed/features/customer/widgets/guest_auth_prompt.dart';
import 'package:z_speed/features/order/view/checkout_screen.dart';
import 'package:z_speed/features/cart/view/full_cart_screen.dart';
import 'package:z_speed/l10n/app_localizations.dart';

class CustomerApp extends StatefulWidget {
  final VendorType vendorType;
  final bool startOnTracking;
  final String initialQuery;
  final bool showBottomBar;

  const CustomerApp({
    super.key,
    this.vendorType = VendorType.restaurant,
    this.startOnTracking = false,
    this.initialQuery = '',
    this.showBottomBar = true,
  });

  @override
  State<CustomerApp> createState() => _CustomerAppState();
}

class _CustomerAppState extends State<CustomerApp> {
  late int _tabIndex = widget.startOnTracking ? 1 : 0;
  late VendorType _currentVendorType;
  final ValueNotifier<bool> _isScrollingNotifier = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _currentVendorType = widget.vendorType;
  }

  @override
  void dispose() {
    _isScrollingNotifier.dispose();
    super.dispose();
  }

  String get _activeView {
    final isGuest = context.read<AuthCubit>().state.isGuest;
    if (isGuest) return _tabIndex == 0 ? "home" : "tracking";
    return _tabIndex == 0 ? "browse" : "tracking";
  }

  CartCubit get _cartCubit => context.watch<CartCubit>();

  @override
  Widget build(BuildContext context) {
    final content = LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            Expanded(
              child: BlocProvider(
                create: (_) => RestaurantBrowseCubit(
                  vendorType: _currentVendorType,
                  initialQuery: widget.initialQuery,
                ),
                child: IndexedStack(
                  index: _tabIndex,
                  children: [
                    RestaurantBrowseScreen(
                      onVendorTypeChanged: (type) {
                        setState(() {
                          _currentVendorType = type;
                        });
                      },
                    ),
                    const HistoryHubScreen(),
                  ],
                ),
              ),
            ),
            if (_tabIndex == 0 && constraints.maxWidth > 700)
              CartSidebarWidget(
                sidebarWidth: constraints.maxWidth * 0.32,
                onCheckout: _proceedToCheckout,
              ),
          ],
        );
      },
    );

    if (!widget.showBottomBar) {
      // embedded inside GuestCustomerApp's Scaffold — no extra Scaffold needed
      return content;
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Theme.of(context).brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
        statusBarBrightness: Theme.of(context).brightness,
      ),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        extendBody: true,
        body: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollStartNotification) {
              if (!_isScrollingNotifier.value) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _isScrollingNotifier.value = true;
                });
              }
            } else if (notification is ScrollEndNotification) {
              if (_isScrollingNotifier.value) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _isScrollingNotifier.value = false;
                });
              }
            }
            return false;
          },
          child: SafeArea(
            bottom: false,
            child: content,
          ),
        ),
        bottomNavigationBar: ValueListenableBuilder<bool>(
          valueListenable: _isScrollingNotifier,
          builder: (context, isScrolling, _) => CustomerBottomBar(
            isScrolling: isScrolling,
            activeView: _activeView,
            cartItemCount: _cartCubit.state.items.length,
            onHome: () {
              final authState = context.read<AuthCubit>().state;
              if (authState.isGuest) {
                setState(() => _tabIndex = 0);
              } else if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
            onCart: () {
              final authState = context.read<AuthCubit>().state;
              if (authState.isGuest) {
                GuestAuthPrompt.show(
                  context,
                  actionLabel: AppLocalizations.of(context)!.viewCart,
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const FullCartPage()),
              );
            },
            onBrowse: () => setState(() => _tabIndex = 0),
            onTrack: () {
              final authState = context.read<AuthCubit>().state;
              if (authState.isGuest) {
                GuestAuthPrompt.show(
                  context,
                  actionLabel: AppLocalizations.of(context)!.viewOrders,
                );
                return;
              }
              setState(() => _tabIndex = 1);
            },
          ),
        ),
      ),
    );
  }

  void _proceedToCheckout() {
    if (_cartCubit.state.items.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider<CheckoutCubit>(
          create: (ctx) => CheckoutCubit(
            cartCubit: ctx.read<CartCubit>(),
            authCubit: ctx.read<AuthCubit>(),
          ),
          child: const CheckoutScreen(),
        ),
      ),
    );
  }
}
