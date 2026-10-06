import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/core/services/connectivity_cubit.dart';

/// Offline Banner (Phase 8.10)
///
/// Displays a thin amber banner at the top of the screen when offline.
/// Automatically shows/hides based on ConnectivityCubit status.
///
/// Usage:
/// ```dart
/// // In your app scaffold:
/// Column(
///   children: [
///     OfflineBanner(),
///     Expanded(child: yourContent),
///   ],
/// )
/// ```
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final isOnline = context.watch<ConnectivityCubit>().state == ConnectivityStatus.online;

    if (isOnline) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.amber.shade700,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wifi_off,
            color: Colors.white,
            size: 16,
          ),
          SizedBox(width: 8),
          Text(
            'You\'re offline — changes will sync when reconnected',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
