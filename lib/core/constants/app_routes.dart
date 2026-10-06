import 'package:flutter/material.dart';
import 'package:z_speed/features/help_support/view/help_support_screen.dart';
import 'package:z_speed/features/privacy/view/privacy_security_screen.dart';
import 'package:z_speed/features/admin/view/admin_app_screen.dart';
import 'package:z_speed/features/customer/view/customer_app_screen.dart';
import 'package:z_speed/features/driver/view/driver_app_screen.dart';
import 'package:z_speed/features/auth/view/login_screen.dart';
import 'package:z_speed/features/settings/view/settings_screen.dart';
import 'package:z_speed/features/restaurant_owner/view/restaurant_hub_screen.dart';
import 'package:z_speed/features/transport/view/transport_booking_screen.dart';
import 'package:z_speed/features/transport/view/driver_transport_screen.dart';
import 'package:z_speed/features/transport/view/active_ride_screen.dart';

class AppRoutes {
  static String login = '/login';
  static String admin = '/admin';
  static String restaurant = '/restaurant';
  static String customer = '/customer';
  static String driver = '/driver';

  static String homeAlias = '/home';
  static String settingsAlias = '/settings';
  static String helpAlias = '/help';
  static String privacyAlias = '/privacy';
  static String orderTracking = '/tracking';
  static String transportBooking = '/transport/book';
  static String transportDriver = '/transport/driver';
  static String transportActive = '/transport/active';

  static Map<String, WidgetBuilder> get routeMap => {
        login: (_) => const LoginPage(),
        admin: (_) => const AdminApp(),
        restaurant: (_) => const RestaurantHubApp(),
        customer: (_) => const CustomerApp(),
        driver: (_) => const DriverApp(),
        homeAlias: (_) => const CustomerApp(),
        settingsAlias: (_) => const SettingsPage(),
        helpAlias: (_) => const HelpSupportScreen(),
        privacyAlias: (_) => const PrivacySecurityScreen(),
        transportBooking: (_) => const TransportBookingScreen(),
        transportDriver: (_) => const DriverTransportScreen(),
        transportActive: (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return ActiveRideScreen(
            rideId: args['rideId'] as String,
            isDriver: args['isDriver'] as bool,
          );
        },
      };
}
