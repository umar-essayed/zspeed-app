import 'package:flutter/material.dart';
import 'package:z_speed/features/driver/screens/driver_main_screen.dart';
import 'package:z_speed/features/driver/cubit/driver_dashboard_cubit.dart';
import 'package:z_speed/features/driver/repository/driver_repository_impl.dart';
import 'package:z_speed/features/notification/cubit/notification_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Driver portal entry point.
///
/// Provides [DriverDashboardCubit] and delegates to [DriverMainScreen]
/// which has 4 real-data tabs: Dashboard, Requests, Active, History.
class DriverApp extends StatelessWidget {
  const DriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    final notifCubit = context.read<NotificationCubit>();
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => DriverDashboardCubit(repository: DriverRepositoryImpl()),
        ),
        BlocProvider<NotificationCubit>.value(value: notifCubit),
      ],
      child: const DriverMainScreen(),
    );
  }
}
