import 'package:flutter/material.dart';
import 'package:z_speed/l10n/app_localizations.dart';
import 'package:z_speed/core/enums/driver_enums.dart';
import 'package:z_speed/features/driver/model/driver_profile.dart';
import 'package:z_speed/features/driver/model/order_driver.dart';
import 'package:z_speed/features/driver/cubit/restaurant_driver_assignment_cubit.dart';
import 'package:z_speed/features/driver/cubit/restaurant_driver_assignment_state.dart';
import 'package:z_speed/features/order/model/order.dart';
import 'package:z_speed/features/restaurant/model/restaurant.dart';
import 'package:z_speed/features/restaurant_owner/view/driver_tracking_screen.dart';
import 'package:z_speed/features/restaurant_owner/view/driver_last_known_location_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/core/injection.dart';
import 'package:z_speed/features/driver/repository/driver_repository.dart';

class DriverAssignmentDialog extends StatefulWidget {
  final Order order;
  final Restaurant restaurant;

  const DriverAssignmentDialog({
    super.key,
    required this.order,
    required this.restaurant,
  });

  @override
  State<DriverAssignmentDialog> createState() => _DriverAssignmentDialogState();
}

class _DriverAssignmentDialogState extends State<DriverAssignmentDialog> {
  late RestaurantDriverAssignmentCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit =
        RestaurantDriverAssignmentCubit(repository: getIt<DriverRepository>());
    _cubit.init(widget.order.id, widget.order, widget.restaurant);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.delivery_dining, color: Colors.teal),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context)!.assignDriver,
                style: const TextStyle(fontSize: 20)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: BlocBuilder<RestaurantDriverAssignmentCubit,
              RestaurantDriverAssignmentState>(
            builder: (context, state) {
              final cubit = context.read<RestaurantDriverAssignmentCubit>();
              if (state.isBusy) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state.failure != null) {
                return Center(
                  child: Text(
                    state.failure!.message,
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---- Assigned Drivers Section (show only active ones) ----
                  if (cubit.assignedDrivers
                      .where((d) =>
                          d.status != DriverAssignmentStatus.cancelled &&
                          d.status != DriverAssignmentStatus.rejected)
                      .isNotEmpty) ...[
                    Builder(builder: (context) {
                      final activeDrivers = cubit.assignedDrivers
                          .where((d) =>
                              d.status != DriverAssignmentStatus.cancelled &&
                              d.status != DriverAssignmentStatus.rejected)
                          .toList();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Assigned Drivers (${activeDrivers.length})',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ...activeDrivers
                              .map((od) => _buildAssignedDriverCard(od, cubit)),
                        ],
                      );
                    }),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                  ],

                  // ---- Available Drivers Section ----
                  Text(
                    'Available Drivers (${cubit.availableDrivers.length})',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (cubit.availableDrivers.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: Text(
                          'No drivers available nearby.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: cubit.availableDrivers.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final driver = cubit.availableDrivers[index];
                          final isAssigned =
                              cubit.isDriverAssigned(driver.userId);
                          return _buildDriverTile(driver, cubit, isAssigned);
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.close),
          ),
        ],
      ),
    );
  }

  /// Rich status card for an assigned driver.
  Widget _buildAssignedDriverCard(
      OrderDriver od, RestaurantDriverAssignmentCubit cubit) {
    final statusInfo = _getStatusInfo(context, od.status);

    // Try to get live distance if driver profile is available
    double? distanceKm;
    int? etaMinutes;
    final driverProfiles = cubit.state.onlineDrivers;
    DriverProfile? driverProfile;
    try {
      driverProfile = driverProfiles.firstWhere(
        (d) => d.userId == od.driverUserId,
      );
      distanceKm = cubit.getDistanceToDriver(driverProfile);
      if (distanceKm != null) {
        etaMinutes = (distanceKm / 20 * 60).round(); // ~20km/h city speed
      }
    } catch (_) {}

    return Container(
      margin: const EdgeInsetsDirectional.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusInfo.color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusInfo.color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Driver name + status badge
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.teal.shade100,
                child: const Icon(Icons.person, size: 18, color: Colors.teal),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      od.driverName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (od.driverPhone.isNotEmpty)
                      Text(
                        od.driverPhone,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusInfo.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusInfo.icon, size: 14, color: statusInfo.color),
                    const SizedBox(width: 4),
                    Text(
                      statusInfo.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: statusInfo.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Rejection reason
          if (od.status == DriverAssignmentStatus.rejected &&
              od.rejectionReason != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 14, color: Colors.red.shade700),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Reason: ${od.rejectionReason}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Distance + ETA
          if (distanceKm != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(_getVehicleIcon(driverProfile?.vehicleType ?? od.vehicleModel),
                    size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '${distanceKm.toStringAsFixed(1)} km away',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
                if (etaMinutes != null) ...[
                  const SizedBox(width: 12),
                  Icon(Icons.timer, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '~$etaMinutes min',
                    style: TextStyle(fontSize: 12, color: Colors.teal.shade700),
                  ),
                ],
              ],
            ),
          ],

          // Action buttons
          const SizedBox(height: 10),
          Row(
            children: [
              // Track button (only when accepted or pickedUp)
              if (od.status == DriverAssignmentStatus.accepted ||
                  od.status == DriverAssignmentStatus.pickedUp)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openTracking(od, cubit),
                    icon: const Icon(Icons.map, size: 16),
                    label: Text(AppLocalizations.of(context)!.track),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.teal,
                      side: const BorderSide(color: Colors.teal),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),

              // Cancel button (only when pending)
              if (od.status == DriverAssignmentStatus.pending) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => cubit.removeDriver(od.driverUserId),
                    icon: const Icon(Icons.close, size: 16),
                    label: Text(AppLocalizations.of(context)!.cancel),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _openTracking(OrderDriver od, RestaurantDriverAssignmentCubit cubit) {
    Navigator.pop(context); // Close dialog first
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DriverTrackingScreen(
          driverUserId: od.driverUserId,
          driverName: od.driverName,
          restaurantLat: widget.restaurant.latitude,
          restaurantLng: widget.restaurant.longitude,
          restaurantName: widget.restaurant.name,
          orderId: widget.order.id,
          deliveryLat: widget.order.deliveryLat,
          deliveryLng: widget.order.deliveryLng,
          initialOrderStatus: widget.order.status,
        ),
      ),
    );
  }

  Widget _buildDriverTile(DriverProfile driver,
      RestaurantDriverAssignmentCubit cubit, bool isAssigned) {
    final distance = cubit.getDistanceToDriver(driver);
    final etaMinutes = distance != null ? (distance / 20 * 60).round() : null;
    final driverName = driver.name.isNotEmpty ? driver.name : driver.userId;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.teal.shade100,
            child: const Icon(Icons.person, color: Colors.teal),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driverName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.star, size: 13, color: Colors.amber),
                    const SizedBox(width: 2),
                    Text(driver.rating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 8),
                    Icon(_getVehicleIcon(driver.vehicleType),
                        size: 13, color: Colors.grey),
                    const SizedBox(width: 2),
                    Text('${distance?.toStringAsFixed(1) ?? 'N/A'} km',
                        style: const TextStyle(fontSize: 12)),
                  ],
                ),
                if (etaMinutes != null)
                  Text(
                    etaMinutes > 59
                        ? '~ ${etaMinutes ~/ 60}h ${etaMinutes % 60}m away'
                        : '~ $etaMinutes min away',
                    style: TextStyle(fontSize: 11, color: Colors.teal.shade700),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (!isAssigned) ...[
            IconButton(
              icon: const Icon(Icons.location_on, color: Colors.teal),
              tooltip: 'Show Location',
              onPressed: () {
                if (driver.currentLat == null || driver.currentLng == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Driver location not available'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DriverLastKnownLocationScreen(
                      driver: driver,
                      restaurantLat: widget.restaurant.latitude,
                      restaurantLng: widget.restaurant.longitude,
                      restaurantName: widget.restaurant.name,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 4),
          ],
          isAssigned
              ? const Icon(Icons.check_circle, color: Colors.green, size: 28)
              : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => cubit.assignDriver(driver, []),
                  child: Text(AppLocalizations.of(context)!.assign),
                ),
        ],
      ),
    );
  }

  IconData _getVehicleIcon(String type) {
    final t = type.toLowerCase();
    if (t.contains('motorcycle') || t.contains('moto') || t.contains('motor')) {
      return Icons.motorcycle;
    } else if (t.contains('cycle') || t.contains('bike') || t.contains('pedal')) {
      return Icons.directions_bike;
    } else if (t.contains('scooter') || t.contains('moped')) {
      return Icons.moped;
    }
    return Icons.directions_car;
  }

  _StatusInfo _getStatusInfo(BuildContext context, DriverAssignmentStatus status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case DriverAssignmentStatus.pending:
        return _StatusInfo(
            l10n.statusPending, Colors.orange, Icons.hourglass_empty);
      case DriverAssignmentStatus.accepted:
        return _StatusInfo(l10n.statusAccepted, Colors.green, Icons.check_circle);
      case DriverAssignmentStatus.rejected:
        return _StatusInfo(l10n.statusRejected, Colors.red, Icons.cancel);
      case DriverAssignmentStatus.cancelled:
        return _StatusInfo(l10n.statusCancelled, Colors.grey, Icons.block);
      case DriverAssignmentStatus.pickedUp:
        return _StatusInfo(l10n.statusPickedUp, Colors.blue, Icons.shopping_bag);
      case DriverAssignmentStatus.delivered:
        return _StatusInfo(l10n.statusDelivered, Colors.green, Icons.done_all);
    }
  }
}

class _StatusInfo {
  final String label;
  final Color color;
  final IconData icon;

  const _StatusInfo(this.label, this.color, this.icon);
}
