import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:z_speed/l10n/app_localizations.dart';
import 'package:z_speed/features/transport/model/ride_model.dart';
import 'package:z_speed/features/transport/view/active_ride_screen.dart';
import 'package:z_speed/components/my_button.dart';
import 'package:z_speed/features/transport/repository/transport_repository.dart';
import 'package:z_speed/core/injection.dart';
import 'package:z_speed/features/auth/cubit/auth_cubit.dart';
import 'dart:async';

class DriverTransportScreen extends StatelessWidget {
  const DriverTransportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: const DriverTransportBody(),
    );
  }
}

class DriverTransportBody extends StatefulWidget {
  const DriverTransportBody({super.key});

  @override
  State<DriverTransportBody> createState() => _DriverTransportBodyState();
}

class _DriverTransportBodyState extends State<DriverTransportBody> {
  RideModel? _activeRide;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchActiveRide();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) _fetchActiveRide();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchActiveRide() async {
    final user = context.read<AuthCubit>().state.user;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('rides')
          .where('driverId', isEqualTo: user.id)
          .get();

      final activeStatuses = {
        RideStatus.accepted.name,
        RideStatus.arrived.name,
        RideStatus.started.name,
        RideStatus.arrivedAtDestination.name,
      };

      final activeDocs = snapshot.docs.where((doc) {
        final status = doc.data()['status'] as String?;
        return activeStatuses.contains(status);
      }).toList();

      if (activeDocs.isNotEmpty) {
        activeDocs.sort((a, b) {
          final tA = a.data()['requestedAt'];
          final tB = b.data()['requestedAt'];
          if (tA is Timestamp && tB is Timestamp) {
            return tB.compareTo(tA);
          }
          return 0;
        });

        final doc = activeDocs.first;
        final ride = RideModel.fromMap(doc.id, doc.data());
        if (mounted) {
          setState(() {
            _activeRide = ride;
          });
        }
      } else {
        if (mounted && _activeRide != null) {
          setState(() {
            _activeRide = null;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching active ride for driver: $e');
    }
  }

  void _openGoogleMapsDirections(RideModel ride) {
    final isHeadingToPickup = ride.status == RideStatus.pending ||
        ride.status == RideStatus.accepted ||
        ride.status == RideStatus.arrived;

    final target = isHeadingToPickup ? ride.pickupLocation : ride.dropoffLocation;
    final lat = target.latitude;
    final lng = target.longitude;

    if (lat == 0.0 && lng == 0.0) return;

    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
    );
    launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _callCustomer(String phoneNumber) async {
    final Uri url = Uri(scheme: 'tel', path: phoneNumber);
    try {
      await launchUrl(url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not call $phoneNumber: $e')),
        );
      }
    }
  }

  void _showCustomerDetailsModal(BuildContext context, RideModel ride) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Customer Details',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      children: [
                        // Customer Profile Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: const Color(0xFFF35535).withValues(alpha: 0.1),
                                child: const Icon(Icons.person, size: 28, color: Color(0xFFF35535)),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ride.customerName ?? l10n.customer,
                                      style: const TextStyle(
                                          fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      ride.customerPhone ?? 'No phone provided',
                                      style: TextStyle(
                                          fontSize: 13, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ),
                              if (ride.customerPhone != null && ride.customerPhone!.isNotEmpty)
                                ElevatedButton.icon(
                                  onPressed: () => _callCustomer(ride.customerPhone!),
                                  icon: const Icon(Icons.phone, size: 16),
                                  label: const Text('Call'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF16A34A),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Ride Info Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 8,
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'RIDE SUMMARY',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                    letterSpacing: 1),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Vehicle: ${ride.vehicleType.toUpperCase()}',
                                    style: const TextStyle(
                                        fontSize: 14, fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    '${ride.totalFare} EGP',
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Text(
                                    'Status: ',
                                    style: TextStyle(
                                        fontSize: 14, fontWeight: FontWeight.w600),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      ride.status.name.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Locations Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TRIP ROUTE',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                    letterSpacing: 1),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.circle_outlined,
                                      size: 18, color: Colors.blue),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Pickup Location',
                                            style: TextStyle(
                                                fontSize: 11, color: Colors.grey)),
                                        const SizedBox(height: 2),
                                        Text(
                                          ride.pickupLocation.address,
                                          style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Container(
                                    width: 2, height: 20, color: Colors.grey.shade300),
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.location_on,
                                      size: 18, color: Color(0xFFF35535)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Dropoff Location',
                                            style: TextStyle(
                                                fontSize: 11, color: Colors.grey)),
                                        const SizedBox(height: 2),
                                        Text(
                                          ride.dropoffLocation.address,
                                          style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        _buildStatusHeader(),
        if (_activeRide != null) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Text(
                'Active Mission',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.grey[800]),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _buildActiveRideCard(_activeRide!),
          ),
        ],
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Text(
              'Available Requests',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.grey[800]),
            ),
          ),
        ),
        _buildRequestsList(),
      ],
    );
  }

  Widget _buildStatusHeader() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle),
              child: const Icon(Icons.radar, color: Colors.green),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('You are Online',
                      style:
                          TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  Text('Searching for nearby rides...',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            Switch(
                value: true, onChanged: (v) {}, activeThumbColor: Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveRideCard(RideModel ride) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: status + fare
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.directions_car, size: 16, color: Colors.orange.shade700),
                    const SizedBox(width: 6),
                    Text(
                      ride.status.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${ride.totalFare} EGP',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          // Route indicators
          Row(
            children: [
              const Icon(Icons.circle_outlined, size: 18, color: Colors.blue),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  ride.pickupLocation.address,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8.5),
            child: Container(width: 1, height: 16, color: Colors.grey.shade300),
          ),
          Row(
            children: [
              const Icon(Icons.location_on, size: 18, color: Color(0xFFF35535)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  ride.dropoffLocation.address,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          // Customer Row
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFF35535).withValues(alpha: 0.1),
                radius: 18,
                child: const Icon(Icons.person, color: Color(0xFFF35535), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ride.customerName ?? l10n.customer,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    if (ride.customerPhone != null && ride.customerPhone!.isNotEmpty)
                      Text(
                        ride.customerPhone!,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.info_outline, color: Colors.blue.shade700, size: 18),
                ),
                onPressed: () => _showCustomerDetailsModal(context, ride),
              ),
              if (ride.customerPhone != null && ride.customerPhone!.isNotEmpty)
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.phone, color: Colors.green.shade700, size: 18),
                  ),
                  onPressed: () => _callCustomer(ride.customerPhone!),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Action Buttons Row: Open Map & Start Navigation
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ActiveRideScreen(
                          rideId: ride.id,
                          isDriver: true,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.map, size: 18),
                  label: Text(
                    l10n.openMap,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF35535),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openGoogleMapsDirections(ride),
                  icon: const Icon(Icons.navigation_rounded, size: 18),
                  label: Text(
                    l10n.startNavigation,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsList() {
    return StreamBuilder<List<RideModel>>(
      stream: getIt<TransportRepository>().watchPendingRides(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && _activeRide == null) {
          return const SliverFillRemaining(
            child: Center(
                child: CircularProgressIndicator(color: Color(0xFFF35535))),
          );
        }

        if (snapshot.hasError && _activeRide == null) {
          return SliverFillRemaining(
            child: Center(
                child: Text('Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red))),
          );
        }

        final rides = snapshot.data ?? [];

        if (rides.isEmpty) {
          if (_activeRide != null) {
            return const SliverToBoxAdapter(child: SizedBox.shrink());
          }
          return const SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_taxi_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No ride requests nearby',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final ride = rides[index];
              return _buildRideRequestCard(ride);
            },
            childCount: rides.length,
          ),
        );
      },
    );
  }

  Widget _buildRideRequestCard(RideModel ride) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12)),
                      child: Text(ride.vehicleType.toUpperCase(),
                          style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.w900,
                              fontSize: 10)),
                    ),
                    Text('${ride.totalFare} EGP',
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.green)),
                  ],
                ),
                const SizedBox(height: 20),
                _buildLocationStep(Icons.circle_outlined, Colors.blue,
                    ride.pickupLocation.address),
                Padding(
                  padding: const EdgeInsets.only(left: 11),
                  child:
                      Container(width: 1, height: 20, color: Colors.grey[200]),
                ),
                _buildLocationStep(Icons.location_on, const Color(0xFFF35535),
                    ride.dropoffLocation.address),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor:
                          const Color(0xFFF35535).withValues(alpha: 0.1),
                      radius: 20,
                      child: const Icon(Icons.person, color: Color(0xFFF35535)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ride.customerName ?? 'Customer',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ride.customerPhone ?? 'No phone provided',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(24))),
            child: Row(
              children: [
                Expanded(
                  child: MyButton(
                    text: 'Accept Ride',
                    onPressed: () async {
                      try {
                        final user = context.read<AuthCubit>().state.user;
                        if (user != null) {
                          await getIt<TransportRepository>().acceptRide(
                            ride.id,
                            user.id,
                            driverName: user.name,
                            driverPhone: user.phone,
                          );
                          if (!mounted) return;
                          _fetchActiveRide();
                        }
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to accept: $e')));
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationStep(IconData icon, Color color, String address) {
    return Row(
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            address,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
