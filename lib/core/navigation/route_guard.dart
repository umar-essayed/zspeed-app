import 'package:z_speed/features/order/view/order_tracking_screen.dart';
import 'package:flutter/material.dart';
import 'package:z_speed/core/constants/app_routes.dart';
import 'package:z_speed/core/navigation/navigation_policy.dart';
import 'package:z_speed/features/auth/cubit/auth_cubit.dart';
import 'package:z_speed/features/auth/view/login_screen.dart';
import 'package:z_speed/main_app.dart';

class RouteGuard {
  static Route<dynamic>? onGenerateRoute(
    RouteSettings settings,
    AuthCubit authCubit,
  ) {
    final routeName = settings.name;
    if (routeName == null || routeName.isEmpty) {
      return null;
    }

    if (routeName == AppRoutes.login) {
      return MaterialPageRoute(
        builder: (_) => const LoginPage(),
        settings: settings,
      );
    }

    if (routeName.startsWith('${AppRoutes.orderTracking}/')) {
      final uri = Uri.parse(routeName);
      final pathSegments = uri.pathSegments;
      if (pathSegments.length >= 2 && pathSegments[0] == 'tracking') {
        final orderId = pathSegments[1];

        final currentUser = authCubit.state.user;
        if (!authCubit.state.isAuthenticated || currentUser == null) {
          return MaterialPageRoute(
            builder: (_) => const LoginPage(),
            settings: settings,
          );
        }

        return MaterialPageRoute(
          builder: (_) => OrderTrackingScreen(orderId: orderId),
          settings: settings,
        );
      }
    }

    if (routeName.startsWith('${AppRoutes.orderTracking}/')) {
      final uri = Uri.parse(routeName);
      final pathSegments = uri.pathSegments;
      if (pathSegments.length >= 2 && pathSegments[0] == 'tracking') {
        final orderId = pathSegments[1];

        final currentUser = authCubit.state.user;
        if (!authCubit.state.isAuthenticated || currentUser == null) {
          return MaterialPageRoute(
            builder: (_) => const LoginPage(),
            settings: settings,
          );
        }

        return MaterialPageRoute(
          builder: (_) => OrderTrackingScreen(orderId: orderId),
          settings: settings,
        );
      }
    }

    final routeKey = NavigationPolicy.routeKeyMap[routeName];
    final routeBuilder = AppRoutes.routeMap[routeName];

    if (routeKey == null) {
      if (routeBuilder == null) {
        return null;
      }
      return MaterialPageRoute(builder: routeBuilder, settings: settings);
    }

    final currentUser = authCubit.state.user;
    final isGuest = authCubit.state.isGuest;

    if (!authCubit.state.isAuthenticated && !isGuest) {
      return MaterialPageRoute(
        builder: (_) => const LoginPage(),
        settings: settings,
      );
    }

    if (isGuest && currentUser == null) {
      final guestAllowedRoutes = ['/customer', '/home', '/restaurant'];
      final isAllowed = guestAllowedRoutes.any((r) => routeName.startsWith(r));
      if (!isAllowed) {
        return MaterialPageRoute(
          builder: (_) => const LoginPage(),
          settings: settings,
        );
      }
    }

    if (currentUser == null) {
      return MaterialPageRoute(
        builder: (_) => const LoginPage(),
        settings: settings,
      );
    }

    if (!NavigationPolicy.canAccess(currentUser, routeKey)) {
      return MaterialPageRoute(
        builder: (_) => MainApp(currentUser: currentUser),
        settings: settings,
      );
    }

    if (routeBuilder != null) {
      return MaterialPageRoute(builder: routeBuilder, settings: settings);
    }

    return MaterialPageRoute(
      builder: (_) => NavigationPolicy.getPage(routeKey, currentUser),
      settings: settings,
    );
  }
}
