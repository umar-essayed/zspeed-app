import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/features/auth/cubit/auth_cubit.dart';
import 'package:z_speed/features/transport/model/ride_model.dart';
import 'package:z_speed/features/transport/view/active_ride_screen.dart';

class TransportHistoryScreen extends StatefulWidget {
  const TransportHistoryScreen({super.key});

  @override
  State<TransportHistoryScreen> createState() => _TransportHistoryScreenState();
}

class _TransportHistoryScreenState extends State<TransportHistoryScreen> {
  List<RideModel>? _rides;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchMyRides();
  }

  Future<void> _fetchMyRides() async {
    final user = context.read<AuthCubit>().state.user;
    if (user == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Please login to see your history';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('rides')
          .where('customerId', isEqualTo: user.id)
          .orderBy('requestedAt', descending: true)
          .get();

      if (!mounted) return;

      final rides = snapshot.docs
          .map((doc) => RideModel.fromMap(doc.id, doc.data()))
          .toList();

      setState(() {
        _rides = rides;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load rides: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthCubit>().state.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please login to see your history')),
      );
    }

    Widget bodyContent;

    if (_isLoading) {
      bodyContent = const Center(child: CircularProgressIndicator());
    } else if (_errorMessage != null) {
      bodyContent = SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchMyRides,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF35535),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child:
                    const Text('Retry', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    } else {
      final rides = _rides ?? [];
      if (rides.isEmpty) {
        bodyContent = SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.7,
            alignment: Alignment.center,
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_rounded, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No rides found', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        );
      } else {
        bodyContent = ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
          itemCount: rides.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return _RideHistoryCard(ride: rides[index], onRefresh: _fetchMyRides);
          },
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transport History',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchMyRides,
        child: bodyContent,
      ),
    );
  }
}

class _RideHistoryCard extends StatelessWidget {
  final RideModel ride;
  final VoidCallback? onRefresh;

  const _RideHistoryCard({required this.ride, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final isCompleted = ride.status == RideStatus.completed;
    final isActive = !isCompleted && ride.status != RideStatus.cancelled;

    return InkWell(
      onTap: () async {
        if (isActive) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              settings: const RouteSettings(name: '/transport/active'),
              builder: (context) =>
                  ActiveRideScreen(rideId: ride.id, isDriver: false),
            ),
          );
          onRefresh?.call();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(ride.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    ride.status.name.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(ride.status),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  _formatDate(ride.requestedAt),
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Column(
                  children: [
                    Icon(Icons.my_location, size: 16, color: Colors.blue),
                    SizedBox(height: 4),
                    SizedBox(
                        height: 20,
                        child: VerticalDivider(width: 1, thickness: 1)),
                    SizedBox(height: 4),
                    Icon(Icons.location_on, size: 16, color: Color(0xFFF35535)),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ride.pickupLocation.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        ride.dropoffLocation.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isCompleted) ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    ride.vehicleType.toUpperCase(),
                    style: const TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${ride.totalFare} EGP',
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                ],
              ),
            ],
            if (isActive) ...[
              const SizedBox(height: 12),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.touch_app, size: 14, color: Colors.blue),
                  SizedBox(width: 4),
                  Text('Tap to track your ride',
                      style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(RideStatus status) {
    switch (status) {
      case RideStatus.pending:
        return Colors.orange;
      case RideStatus.accepted:
        return Colors.blue;
      case RideStatus.arrived:
        return Colors.purple;
      case RideStatus.started:
        return Colors.green;
      case RideStatus.arrivedAtDestination:
        return Colors.orangeAccent;
      case RideStatus.completed:
        return Colors.grey;
      case RideStatus.cancelled:
        return Colors.red;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
