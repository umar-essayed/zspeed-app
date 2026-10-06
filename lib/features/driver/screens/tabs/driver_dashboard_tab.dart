import 'package:flutter/material.dart';
import 'package:z_speed/l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/features/driver/cubit/driver_dashboard_cubit.dart';
import 'package:z_speed/features/driver/cubit/driver_dashboard_state.dart';
import 'package:z_speed/core/errors/failure_localization_ext.dart';

/// Dashboard tab for drivers - shows online status, earnings, and stats.
class DriverDashboardTab extends StatelessWidget {
  const DriverDashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: BlocConsumer<DriverDashboardCubit, DriverDashboardState>(
        listenWhen: (prev, curr) =>
            curr.noLocationError && !prev.noLocationError,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.location_off, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.updateLocationFirst,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.orange.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        },
        builder: (context, state) {
          if (state.isBusy) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    state.failure?.getLocalizedMessage(context) ??
                        AppLocalizations.of(context)!.errorOccurred,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      final uid = FirebaseAuth.instance.currentUser?.uid;
                      if (uid != null) {
                        context.read<DriverDashboardCubit>().init(uid);
                      }
                    },
                    child: Text(AppLocalizations.of(context)!.retry),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOnlineStatusCard(context, state),
                const SizedBox(height: 16),
                _buildEarningsCard(context, state),
                const SizedBox(height: 16),
                _buildStatsGrid(context, state),
                const SizedBox(height: 16),
                _buildPerformanceRow(context, state),
                const SizedBox(height: 16),
                _buildLocationCard(context, state),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOnlineStatusCard(
    BuildContext context,
    DriverDashboardState state,
  ) {
    final cubit = context.read<DriverDashboardCubit>();
    final isOnline = cubit.isOnline || cubit.isDriverBusy;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isOnline
              ? [const Color(0xFF16A34A), const Color(0xFF15803D)]
              : [const Color(0xFF1E293B), const Color(0xFF334155)],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
                (isOnline ? const Color(0xFF16A34A) : const Color(0xFF334155))
                    .withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.15),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  isOnline ? Icons.wifi_tethering : Icons.offline_bolt,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isOnline
                          ? AppLocalizations.of(context)!.youAreOnline
                          : AppLocalizations.of(context)!.youAreOffline,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isOnline
                          ? AppLocalizations.of(
                              context,
                            )!.readyToAcceptDeliveries
                          : AppLocalizations.of(
                              context,
                            )!.turnOnToStartReceivingOrders,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: isOnline
                    ? null
                    : const LinearGradient(
                        colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                      ),
                color: isOnline ? Colors.white : null,
                boxShadow: isOnline
                    ? null
                    : [
                        BoxShadow(
                          color: const Color(0xFF22C55E).withValues(alpha: 0.5),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: ElevatedButton.icon(
                onPressed: state.isBusy
                    ? null
                    : () {
                        if (cubit.isDriverBusy) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(
                                    Icons.warning_amber_rounded,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.cantGoOfflineWithActiveOrder,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: Colors.red.shade600,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        } else {
                          cubit.toggleOnlineStatus();
                        }
                      },
                icon: Icon(
                  isOnline ? Icons.power_settings_new : Icons.play_arrow,
                  size: 22,
                ),
                label: Text(
                  isOnline
                      ? AppLocalizations.of(context)!.goOffline
                      : AppLocalizations.of(context)!.goOnline,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: isOnline
                      ? Colors.red.shade600
                      : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsCard(BuildContext context, DriverDashboardState state) {
    final todayEarnings = state.todaysEarnings;
    final lifetimeEarnings = state.driverProfile?.totalEarnings ?? 0.0;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.account_balance_wallet,
                  color: Colors.green.shade700,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.todaysEarnings,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.egpAmount(todayEarnings.toStringAsFixed(2)),
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.totalEarnings,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  l10n.egpAmount(lifetimeEarnings.toStringAsFixed(2)),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, DriverDashboardState state) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            AppLocalizations.of(context)!.totalTrips,
            '${state.totalTripsCount}',
            Icons.route,
            Colors.deepPurple,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            AppLocalizations.of(context)!.statusPending,
            state.pendingCount.toString(),
            Icons.inbox,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            AppLocalizations.of(context)!.statusActive,
            state.activeCount.toString(),
            Icons.local_shipping,
            Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceRow(
    BuildContext context,
    DriverDashboardState state,
  ) {
    final profile = state.driverProfile;
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            AppLocalizations.of(context)!.rating,
            profile?.rating.toStringAsFixed(1) ?? '0.0',
            Icons.star,
            Colors.amber,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            AppLocalizations.of(context)!.acceptance,
            '${((profile?.acceptanceRate ?? 1.0) * 100).toStringAsFixed(0)}%',
            Icons.check_circle_outline,
            Colors.teal,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            AppLocalizations.of(context)!.wallet,
            AppLocalizations.of(
              context,
            )!.egpAmount((profile?.walletBalance ?? 0).toStringAsFixed(0)),
            Icons.account_balance_wallet_outlined,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(BuildContext context, DriverDashboardState state) {
    final profile = state.driverProfile;
    final lat = profile?.currentLat;
    final lng = profile?.currentLng;
    final locationError = state.failure?.getLocalizedMessage(context);
    final isUpdating = state.isUpdatingLocation;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.my_location,
                  color: Colors.blue.shade700,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Current Location',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              // Manual refresh button
              SizedBox(
                height: 36,
                child: ElevatedButton.icon(
                  onPressed: isUpdating
                      ? null
                      : () => context
                            .read<DriverDashboardCubit>()
                            .updateLocation(),
                  icon: isUpdating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.refresh, size: 18),
                  label: Text(
                    isUpdating ? 'Updating...' : 'Update',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isUpdating && lat == null) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            ),
          ] else if (lat != null && lng != null) ...[
            Row(
              children: [
                Icon(Icons.gps_fixed, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Lat: ${lat.toStringAsFixed(6)}, Lng: ${lng.toStringAsFixed(6)}',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 18,
                    color: Colors.green.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'GPS tracking active - Location updates every 30 seconds',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      locationError ??
                          'Location not available. Tap "Update" to detect your location.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
