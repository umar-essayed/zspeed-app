import 'package:z_speed/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/core/enums/order_enums.dart';
import 'package:z_speed/features/driver/cubit/driver_dashboard_cubit.dart';
import 'package:z_speed/features/driver/cubit/driver_dashboard_state.dart';
import 'package:z_speed/features/order/model/order.dart';

import 'package:z_speed/features/auth/cubit/auth_cubit.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:z_speed/features/transport/model/ride_model.dart';

/// History tab - shows completed/cancelled deliveries from Firestore.
class DriverHistoryTab extends StatelessWidget {
  const DriverHistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthCubit>().state.user;
    final isTransport = user?.canTransport ?? false;

    if (isTransport) {
      return _buildTransportHistory(context, user!.id);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: BlocBuilder<DriverDashboardCubit, DriverDashboardState>(
        builder: (context, state) {
          if (state.isBusy) {
            return const Center(child: CircularProgressIndicator());
          }

          final history = state.orderHistory;

          if (history.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: history.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) =>
                _buildHistoryCard(context, history[index]),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              l10n.noDeliveryHistory,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.completedDeliveriesWillAppear,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, Order order) {
    final isCancelled = order.status == OrderStatus.cancelled;
    final statusColor = isCancelled ? Colors.red : Colors.green;
    final dateFormat = DateFormat('MMM d, yyyy  h:mm a');
    final completedAt =
        order.deliveredAt ?? order.cancelledAt ?? order.createdAt;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order ID + Status
          Row(
            children: [
              Expanded(
                child: Text(
                  '#${order.id.length > 8 ? order.id.substring(0, 8).toUpperCase() : order.id.toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  order.status.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Delivery address
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  order.deliveryAddress.isNotEmpty
                      ? order.deliveryAddress
                      : AppLocalizations.of(context)!.addressNotAvailable,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Date
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                dateFormat.format(completedAt),
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
            ],
          ),

          const Divider(height: 20),

          // Driver Earnings (Primary)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.deliveryFee,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isCancelled ? Colors.grey : Colors.green.shade700,
                ),
              ),
              Text(
                AppLocalizations.of(
                  context,
                )!.egpAmount(order.deliveryFee.toStringAsFixed(2)),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isCancelled ? Colors.grey : Colors.green.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Order Total (Secondary / Customer Bill)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${AppLocalizations.of(context)!.total} (${AppLocalizations.of(context)!.orderDetails})',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              Text(
                AppLocalizations.of(
                  context,
                )!.egpAmount(order.total.toStringAsFixed(2)),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isCancelled ? Colors.grey : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransportHistory(BuildContext context, String driverId) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: FutureBuilder<List<RideModel>>(
        future: _fetchDriverRides(driverId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFF35535)),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          final rides = snapshot.data ?? [];
          if (rides.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text(
                    'No ride history found',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: rides.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) =>
                _buildRideCard(context, rides[index]),
          );
        },
      ),
    );
  }

  Future<List<RideModel>> _fetchDriverRides(String driverId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('rides')
          .where('driverId', isEqualTo: driverId)
          .get();

      final rides = snapshot.docs
          .map((doc) => RideModel.fromMap(doc.id, doc.data()))
          .toList();

      rides.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
      return rides;
    } catch (e) {
      debugPrint('Error loading driver ride history: $e');
      throw Exception('Failed to load rides: $e');
    }
  }

  Widget _buildRideCard(BuildContext context, RideModel ride) {
    final isCompleted = ride.status == RideStatus.completed;
    final statusColor = isCompleted ? Colors.green : Colors.red;
    final dateFormat = DateFormat('MMM d, yyyy  h:mm a');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'RIDE #${ride.id.length > 8 ? ride.id.substring(0, 8).toUpperCase() : ride.id.toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  ride.status.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.my_location, size: 16, color: Colors.blue),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  ride.pickupLocation.address,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Color(0xFFF35535)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  ride.dropoffLocation.address,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                dateFormat.format(ride.requestedAt),
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Earnings',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              Text(
                '${ride.totalFare.toStringAsFixed(2)} EGP',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
