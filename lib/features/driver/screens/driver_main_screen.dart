import 'package:flutter/material.dart';
import 'package:z_speed/l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:z_speed/core/constants/page_identity.dart';
import 'package:z_speed/core/navigation/navigation_policy.dart';
import 'package:z_speed/core/navigation/app_drawer.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/features/auth/cubit/auth_cubit.dart';
import 'package:z_speed/features/driver/cubit/driver_dashboard_cubit.dart';
import 'package:z_speed/features/driver/cubit/driver_dashboard_state.dart';
import 'package:z_speed/features/driver/screens/tabs/driver_dashboard_tab.dart';
import 'package:z_speed/features/driver/screens/tabs/driver_requests_tab.dart';
import 'package:z_speed/features/driver/screens/tabs/driver_history_tab.dart';
import 'package:z_speed/features/driver/screens/driver_profile_page.dart';
import 'package:z_speed/features/notification/widgets/notification_bell.dart';
import 'package:z_speed/features/notification/view/notification_list_page.dart';
import 'package:z_speed/features/notification/cubit/notification_cubit.dart';
import 'package:z_speed/features/transport/view/driver_transport_screen.dart';
import 'package:z_speed/features/driver/screens/driver_locked_screen.dart';
import 'package:z_speed/core/injection.dart';
import 'package:z_speed/features/transport/repository/transport_repository.dart';
import 'package:z_speed/features/transport/model/ride_model.dart';

/// Main driver app screen with 4-tab navigation.
///
/// Tabs:
/// 1. Dashboard - Online status, earnings, GPS location
/// 2. Deliveries - Current mission map and pending delivery requests (accept/reject)
/// History is moved to an action icon in the Deliveries tab.
class DriverMainScreen extends StatefulWidget {
  const DriverMainScreen({super.key});

  @override
  State<DriverMainScreen> createState() => _DriverMainScreenState();
}

class _DriverMainScreenState extends State<DriverMainScreen> {
  int _currentIndex = 0;

  List<Widget> get _tabs {
    final authState = context.read<AuthCubit>().state;
    final user = authState.user;
    if (user == null) {
      return [const Center(child: CircularProgressIndicator())];
    }

    final canTransport = user.canTransport;
    final canDeliver = user.canDeliver;

    if (canTransport) {
      return [
        const DriverDashboardTab(),
        const DriverTransportScreen(),
        const DriverHistoryTab(),
      ];
    } else if (canDeliver) {
      return [
        const DriverDashboardTab(),
        const DriverRequestsTab(),
        const DriverHistoryTab(),
      ];
    } else {
      return [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_person_outlined, size: 72, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'Account Pending Role Assignment',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Your driver profile is approved! Please contact administration to assign you as a Delivery or Transport driver to start taking requests.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ];
    }
  }

  @override
  void initState() {
    super.initState();
    // Initialize driver dashboard with actual Firebase Auth UID
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthCubit>().state.user;
      final isTransport = user?.canTransport ?? false;
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        context.read<DriverDashboardCubit>().init(uid, isTransport: isTransport);
      }
    });
  }

  void _onDrawerPageSelected(String pageKey) {
    final authCubit = context.read<AuthCubit>();
    final user = authCubit.state.user;
    if (user == null || !NavigationPolicy.canAccess(user, pageKey)) return;

    if (pageKey == PageIdentity.home) {
      // Driver naturally stays on Home if selected
      return;
    }

    Widget destination = NavigationPolicy.getPage(pageKey, user);

    // Provide the existing DriverDashboardCubit to the profile page route
    if (destination is DriverProfilePage) {
      final cubit = context.read<DriverDashboardCubit>();
      destination = BlocProvider<DriverDashboardCubit>.value(
        value: cubit,
        child: destination,
      );
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  String _getAppBarTitle(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    final user = authState.user;
    if (user == null || (!user.canTransport && !user.canDeliver)) {
      return 'Z-Speed Driver';
    }

    final canTransport = user.canTransport;

    switch (_currentIndex) {
      case 0:
        return AppLocalizations.of(context)!.drawerDashboard;
      case 1:
        return canTransport ? 'Ride Requests' : AppLocalizations.of(context)!.driverDeliveries;
      case 2:
        return AppLocalizations.of(context)!.driverHistory;
      default:
        return 'Z-Speed Driver';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final user = authState.user;

    return BlocBuilder<DriverDashboardCubit, DriverDashboardState>(
      builder: (context, state) {
        debugPrint('DriverMainScreen: isLockedDueToEarningsLimit = ${state.isLockedDueToEarningsLimit}');
        debugPrint('DriverMainScreen: driverProfile.name = ${state.driverProfile?.name}');
        debugPrint('DriverMainScreen: driverProfile.walletBalance = ${state.driverProfile?.walletBalance}');
        debugPrint('DriverMainScreen: driverProfile.earningsLimit = ${state.driverProfile?.earningsLimit}');
        debugPrint('DriverMainScreen: globalEarningsLimit = ${state.globalEarningsLimit}');

        if (state.isLockedDueToEarningsLimit) {
          final limit = state.driverProfile?.earningsLimit ?? 0.0;
          final limitToUse = limit > 0.0 ? limit : state.globalEarningsLimit;
          return DriverLockedScreen(
            currentEarnings: state.driverProfile?.totalEarnings ?? 0.0,
            limit: limitToUse,
          );
        }

        return Scaffold(
          appBar: AppBar(
            titleSpacing: 0,
            title: Text(_getAppBarTitle(context),
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 18)),
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF35535), Color(0xFFFF8C42)],
                  begin: AlignmentDirectional.topStart,
                  end: AlignmentDirectional.bottomEnd,
                ),
              ),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              NotificationBell(
                onTap: () {
                  final cubit = context.read<NotificationCubit>();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider<NotificationCubit>.value(
                        value: cubit,
                        child: const NotificationListPage(),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          drawer: user != null
              ? AppDrawer(
                  currentUser: user,
                  selectedPageKey: PageIdentity.home,
                  onPageSelected: _onDrawerPageSelected,
                )
              : null,
          body: IndexedStack(
            index: _currentIndex,
            children: _tabs,
          ),
          bottomNavigationBar: _buildBottomNavBar(),
        );
      },
    );
  }

  Widget _buildBottomNavBar() {
    return BlocBuilder<DriverDashboardCubit, DriverDashboardState>(
      builder: (context, state) {
        final pendingCount = state.pendingRequests.length;
        final authState = context.read<AuthCubit>().state;
        final user = authState.user;

        if (user == null || (!user.canTransport && !user.canDeliver)) {
          return const SizedBox.shrink();
        }

        final canTransport = user.canTransport;

        return BottomNavigationBar(
          currentIndex: _currentIndex >= _tabs.length ? 0 : _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.deepOrange,
          unselectedItemColor: Colors.grey,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.grid_view_rounded),
              label: AppLocalizations.of(context)!.drawerDashboard,
            ),
            if (canTransport)
              BottomNavigationBarItem(
                icon: StreamBuilder<List<RideModel>>(
                  stream: getIt<TransportRepository>().watchPendingRides(),
                  builder: (context, snapshot) {
                    final pendingRidesCount = snapshot.data?.length ?? 0;
                    return Badge(
                      isLabelVisible: pendingRidesCount > 0,
                      label: Text(
                        '$pendingRidesCount',
                        style: const TextStyle(fontSize: 10, color: Colors.white),
                      ),
                      backgroundColor: Colors.red,
                      child: const Icon(Icons.local_taxi_rounded),
                    );
                  },
                ),
                label: 'Ride Requests',
              )
            else
              BottomNavigationBarItem(
                icon: Badge(
                  isLabelVisible: pendingCount > 0,
                  label: Text(
                    '$pendingCount',
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.inbox),
                ),
                label: AppLocalizations.of(context)!.driverDeliveries,
              ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.history),
              label: AppLocalizations.of(context)!.driverHistory,
            ),
          ],
        );
      },
    );
  }
}
