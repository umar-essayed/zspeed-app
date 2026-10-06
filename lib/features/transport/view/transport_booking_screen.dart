import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:z_speed/features/transport/cubit/transport_booking_cubit.dart';
import 'package:z_speed/features/transport/cubit/transport_booking_state.dart';
import 'package:z_speed/features/transport/model/ride_location.dart';
import 'package:z_speed/features/transport/model/ride_model.dart';
import 'package:z_speed/features/transport/view/active_ride_screen.dart';
import 'package:z_speed/features/transport/view/transport_history_screen.dart';
import 'package:z_speed/features/transport/repository/transport_repository.dart';
import 'package:z_speed/components/map_location_picker.dart';
import 'package:z_speed/components/my_button.dart';
import 'package:z_speed/core/injection.dart';
import 'package:z_speed/core/services/routing_config.dart';
import 'dart:ui';

class TransportBookingScreen extends StatelessWidget {
  const TransportBookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<TransportBookingCubit>(),
      child: const Scaffold(
        resizeToAvoidBottomInset: false,
        body: TransportBookingBody(),
      ),
    );
  }
}

class TransportBookingBody extends StatefulWidget {
  const TransportBookingBody({super.key});

  @override
  State<TransportBookingBody> createState() => _TransportBookingBodyState();
}

class _TransportBookingBodyState extends State<TransportBookingBody> {
  final MapController _mapController = MapController();
  RideLocation? _pickup;
  RideLocation? _dropoff;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
    _checkActiveRide();
  }

  Future<void> _checkActiveRide() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('rides')
          .where('customerId', isEqualTo: user.uid)
          .where('status', whereIn: [
            RideStatus.pending.name,
            RideStatus.accepted.name,
            RideStatus.arrived.name,
            RideStatus.started.name,
          ])
          .orderBy('requestedAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final activeRideDoc = snapshot.docs.first;
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              settings: const RouteSettings(name: '/transport/active'),
              builder: (context) => ActiveRideScreen(
                rideId: activeRideDoc.id,
                isDriver: false,
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error checking active ride: $e');
    }
  }

  Future<void> _loadCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (!mounted) return;
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (!mounted) return;
      }

      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        final position = await Geolocator.getCurrentPosition();
        if (!mounted) return;
        final newPickup = RideLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          address: 'Current Location',
        );
        setState(() {
          _pickup = newPickup;
          _isLocating = false;
        });
        _mapController.move(LatLng(position.latitude, position.longitude), 15);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLocating = false);
    }
  }

  Future<void> _pickLocation(bool isPickup) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => const MapLocationPicker(),
      ),
    );

    if (!mounted) return;

    if (result != null) {
      setState(() {
        final loc = RideLocation(
          latitude: result['lat'] as double,
          longitude: result['lng'] as double,
          address: result['address'] as String? ?? 'Selected Location',
        );
        if (isPickup) {
          _pickup = loc;
        } else {
          _dropoff = loc;
        }
      });

      if (_pickup != null && _dropoff != null) {
        context
            .read<TransportBookingCubit>()
            .selectLocations(_pickup!, _dropoff!);
      }

      _mapController.move(
          LatLng(result['lat'] as double, result['lng'] as double), 15);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TransportBookingCubit, TransportBookingState>(
      listener: (context, state) {
        if (state is TransportBookingRequested) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Request sent! Waiting for driver...'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Color(0xFFF35535),
            ),
          );
        }
      },
      builder: (context, state) {
        return Stack(
          children: [
            // ── Map Layer ──
            _buildMap(state),

            // ── Glassmorphism Back Button ──
            _buildBackButton(),

            // ── History Button ──
            _buildHistoryButton(context),

            // ── My Location Button ──
            _buildMyLocationButton(),

            // ── Draggable Bottom Panel ──
            _buildDraggableSheet(state),

            // ── Loading Overlay ──
            if (state is TransportBookingRequesting) _buildLoadingOverlay(),
          ],
        );
      },
    );
  }

  Widget _buildMap(TransportBookingState state) {
    final List<Marker> markers = [];
    if (_pickup != null) {
      markers.add(Marker(
        point: LatLng(_pickup!.latitude, _pickup!.longitude),
        width: 80,
        height: 80,
        child: _buildMarkerIcon(Icons.my_location, Colors.blue),
      ));
    }
    if (_dropoff != null) {
      markers.add(Marker(
        point: LatLng(_dropoff!.latitude, _dropoff!.longitude),
        width: 80,
        height: 80,
        child: _buildMarkerIcon(Icons.location_on, const Color(0xFFF35535)),
      ));
    }

    if (state is TransportBookingDriversNearby) {
      for (var d in state.drivers) {
        markers.add(Marker(
          point: LatLng(d['lat'] as double, d['lng'] as double),
          width: 60,
          height: 60,
          child: _buildMarkerIcon(Icons.directions_car, Colors.black87),
        ));
      }
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _pickup != null
            ? LatLng(_pickup!.latitude, _pickup!.longitude)
            : const LatLng(29.9602, 31.6981),
        initialZoom: 14,
      ),
      children: [
        TileLayer(
          urlTemplate: RoutingConfig.tileUrl,
          subdomains: RoutingConfig.tileSubdomains,
          userAgentPackageName: RoutingConfig.userAgentPackageName,
        ),
        MarkerLayer(markers: markers),
      ],
    );
  }

  Widget _buildMarkerIcon(IconData icon, Color color) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Icon(icon, color: Colors.white, size: 16),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -3),
              child: Transform.rotate(
                angle: 0.785,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    border: const Border(
                      right: BorderSide(color: Colors.white, width: 1.5),
                      bottom: BorderSide(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBackButton() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
            ),
            child: Center(
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.black, size: 18),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMyLocationButton() {
    return Positioned(
      bottom: 320,
      right: 16,
      child: Material(
        elevation: 4,
        shape: const CircleBorder(),
        color: Colors.white,
        child: InkWell(
          onTap: _isLocating ? null : _loadCurrentLocation,
          customBorder: const CircleBorder(),
          child: Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: Center(
              child: _isLocating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Color(0xFFF35535)))
                  : const Icon(Icons.my_location_rounded, color: Colors.black87, size: 22),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDraggableSheet(TransportBookingState state) {
    double initialSize = 0.42;
    double minSize = 0.35;

    if (state is TransportBookingLocationSelected ||
        state is TransportBookingVehicleSelected ||
        state is TransportBookingDriversNearby ||
        (_pickup != null && _dropoff != null)) {
      initialSize = 0.62;
      minSize = 0.45;
    } else if (state is TransportBookingRequested || state is TransportBookingRequesting) {
      initialSize = 0.52;
      minSize = 0.40;
    }

    return DraggableScrollableSheet(
      key: ValueKey('${state.runtimeType}_${_pickup != null}_${_dropoff != null}'),
      initialChildSize: initialSize,
      minChildSize: minSize,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 15, spreadRadius: 5)
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              if (state is TransportBookingRequested) ...[
                const Text('Request Status',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 24),
                _buildRequestStatus(state),
              ] else if (state is TransportBookingRequesting) ...[
                const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: Color(0xFFF35535)),
                      SizedBox(height: 20),
                      Text('Sending your request...',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ] else if (state is TransportBookingError) ...[
                const Text('Error',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.red)),
                const SizedBox(height: 12),
                Text(state.message, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 20),
                MyButton(
                  text: 'Try Again',
                  onPressed: () => context
                      .read<TransportBookingCubit>()
                      .fetchDriversNearby(),
                ),
              ] else if (state is TransportBookingDriversNearby) ...[
                const Text('Available Drivers',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 16),
                _buildDriverSelection(state),
              ] else if (state is TransportBookingVehicleSelected) ...[
                const Text('Choose Ride',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 16),
                _buildVehicleSelection(state),
              ] else ...[
                Text(
                  state is TransportBookingLocationSelected
                      ? 'Confirm Your Trip'
                      : 'Where are you going?',
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5),
                ),
                const SizedBox(height: 20),

                // Location Inputs
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey[100]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 24,
                        spreadRadius: 4,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Visual Connector Line on the left
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          // Pickup Pin (Blue Circle)
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.blue, width: 3),
                              color: Colors.white,
                            ),
                          ),
                          // Connecting line
                          Container(
                            width: 2,
                            height: 40,
                            color: Colors.grey[200],
                          ),
                          // Destination Pin (Orange Circle)
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFF35535), width: 3),
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      // The fields on the right
                      Expanded(
                        child: Column(
                          children: [
                            _buildLocationField(
                              hint: 'Pickup Location',
                              value: _pickup?.address,
                              onTap: () => _pickLocation(true),
                            ),
                            const SizedBox(height: 10),
                            Divider(color: Colors.grey[100], height: 1, thickness: 1),
                            const SizedBox(height: 10),
                            _buildLocationField(
                              hint: 'Set Destination',
                              value: _dropoff?.address,
                              onTap: () => _pickLocation(false),
                              isDestination: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                if (state is TransportBookingLocationSelected) ...[
                  const SizedBox(height: 24),
                  _buildInitialConfirmation(state),
                ] else if (_pickup != null && _dropoff == null) ...[
                  const SizedBox(height: 40),
                  Center(
                    child: Text(
                      'Select a destination to see price',
                      style: TextStyle(
                          color: Colors.grey[400], fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ],

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInitialConfirmation(TransportBookingLocationSelected state) {
    return MyButton(
      text: 'Select Vehicle Type',
      onPressed: () {
        context.read<TransportBookingCubit>().selectVehicleType('sedan');
      },
    );
  }

  Widget _buildVehicleSelection(TransportBookingVehicleSelected state) {
    final cubit = context.read<TransportBookingCubit>();
    final distance = state.estimatedDistance;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    double getFare(String type) {
      final double calculatedFare = distance * 7.0;
      final double baseCost = calculatedFare > 35.0 ? calculatedFare : 35.0;

      final String custCommType =
          (cubit.pricingConfig['${type}_customerCommType'] as String?) ??
              'percentage';
      final double custCommVal =
          (cubit.pricingConfig['${type}_customerCommValue'] as num?)
                  ?.toDouble() ??
              0.0;

      double custComm = 0.0;
      if (custCommType == 'percentage') {
        custComm = baseCost * (custCommVal / 100.0);
      } else if (custCommType == 'flat_per_km') {
        custComm = distance * custCommVal;
      } else {
        custComm = custCommVal;
      }

      return double.parse((baseCost + custComm).toStringAsFixed(2));
    }

    int estimateDurationMin(String type, double dist) {
      if (type == 'sedan') {
        return ((dist / 35.0) * 60.0).ceil() + 3;
      } else if (type == 'moto') {
        return ((dist / 45.0) * 60.0).ceil() + 2;
      } else {
        return ((dist / 30.0) * 60.0).ceil() + 4;
      }
    }

    final sedanDur = estimateDurationMin('sedan', distance);
    final motoDur = estimateDurationMin('moto', distance);
    final luxuryDur = estimateDurationMin('luxury', distance);

    final List<Map<String, dynamic>> vehicles = [
      {
        'id': 'sedan',
        'name': isArabic ? 'سيارة عادية (سيدان)' : 'Standard Sedan',
        'icon': Icons.directions_car,
        'price': getFare('sedan'),
        'duration': isArabic ? '$sedanDur دقيقة' : '$sedanDur min',
        'isAvailable': true,
      },
      {
        'id': 'moto',
        'name': isArabic ? 'موتوسيكل (دراجة)' : 'Motorcycle',
        'icon': Icons.motorcycle,
        'price': getFare('moto'),
        'duration': isArabic ? '$motoDur دقيقة' : '$motoDur min',
        'isAvailable': true,
      },
      {
        'id': 'luxury',
        'name': isArabic ? 'بريميوم' : 'Premium',
        'icon': Icons.stars,
        'price': getFare('luxury'),
        'duration': isArabic ? '$luxuryDur دقيقة' : '$luxuryDur min',
        'isAvailable': true,
      },
    ];

    return Column(
      children: [
        ...vehicles.map((v) {
          final isAvailable = v['isAvailable'] as bool;
          return InkWell(
            onTap: isAvailable
                ? () {
                    context
                        .read<TransportBookingCubit>()
                        .selectVehicleType(v['id'] as String);
                  }
                : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.info_outline,
                                color: Colors.white),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isArabic
                                    ? 'خدمة السيارات البريميوم ستتوفر قريباً جداً!'
                                    : 'Premium ride service will be available very soon!',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: Colors.orange,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: state.vehicleType == v['id']
                    ? const Color(0xFFF35535).withValues(alpha: 0.05)
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: state.vehicleType == v['id']
                      ? const Color(0xFFF35535)
                      : Colors.grey.shade200,
                  width: state.vehicleType == v['id'] ? 2.0 : 1.0,
                ),
                boxShadow: state.vehicleType == v['id']
                    ? [
                        BoxShadow(
                          color: const Color(0xFFF35535).withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
              ),
              child: Opacity(
                opacity: isAvailable ? 1.0 : 0.55,
                child: Row(
                  children: [
                    // Icon container
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: state.vehicleType == v['id']
                          ? const Color(0xFFF35535).withValues(alpha: 0.1)
                          : Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        v['icon'] as IconData,
                        color: state.vehicleType == v['id']
                            ? const Color(0xFFF35535)
                            : Colors.grey.shade600,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Vehicle details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            v['name'] as String,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: state.vehicleType == v['id']
                                  ? const Color(0xFFF35535)
                                  : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.access_time_rounded,
                                  size: 14, color: Colors.grey.shade500),
                              const SizedBox(width: 4),
                              Text(
                                v['duration'] as String,
                                style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 12),
                              Icon(Icons.route_rounded,
                                  size: 14, color: Colors.grey.shade500),
                              const SizedBox(width: 4),
                              Text(
                                isArabic
                                    ? '${distance.toStringAsFixed(1)} كم'
                                    : '${distance.toStringAsFixed(1)} km',
                                style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Price or Soon badge
                    if (isAvailable)
                      Text(
                        '${(v['price'] as double).toStringAsFixed(0)} EGP',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: state.vehicleType == v['id']
                              ? const Color(0xFFF35535)
                              : Colors.black87,
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isArabic ? 'قريباً' : 'Soon',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        MyButton(
          text: isArabic ? 'البحث عن سائقين' : 'Find Drivers',
          onPressed: () {
            context.read<TransportBookingCubit>().fetchDriversNearby();
          },
        ),
      ],
    );
  }

  Widget _buildDriverSelection(TransportBookingDriversNearby state) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    if (state.drivers.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF35535).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_search_rounded,
                size: 48,
                color: Color(0xFFF35535),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isArabic ? 'لا يوجد سائقين متاحين' : 'No Drivers Available',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3142),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isArabic
                  ? 'لا يوجد سائقون نشطون لهذه الفئة بالقرب منك حالياً. يرجى المحاولة مرة أخرى بعد قليل أو اختيار فئة أخرى.'
                  : 'There are currently no active drivers for this category nearby. Please try again in a few moments or choose a different ride type.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      context.read<TransportBookingCubit>().goBackToVehicleSelection();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isArabic ? 'تغيير نوع الرحلة' : 'Change Ride Type',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<TransportBookingCubit>().fetchDriversNearby();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF35535),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isArabic ? 'البحث مجدداً' : 'Search Again',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
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

    return Column(
      children: [
        ...state.drivers.map((d) {
          final isArabic = Localizations.localeOf(context).languageCode == 'ar';
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Driver Avatar
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF35535).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      (d['name'] as String).isNotEmpty ? (d['name'] as String)[0].toUpperCase() : 'D',
                      style: const TextStyle(
                        color: Color(0xFFF35535),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Driver info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d['name'] as String,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${d['rating']}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Request Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF35535),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please log in to request a ride'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    _showConfirmContactSheet(
                        context, user.uid, d['id'] as String);
                  },
                  child: Text(
                    isArabic ? 'طلب' : 'Request',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  void _showConfirmContactSheet(
      BuildContext context, String customerId, String driverId) {
    final user = FirebaseAuth.instance.currentUser;
    final nameController = TextEditingController(text: user?.displayName ?? '');
    final phoneController =
        TextEditingController(text: user?.phoneNumber ?? '');
    final formKey = GlobalKey<FormState>();
    final cubit = context.read<TransportBookingCubit>();

    String selectedPaymentMethod = 'cash';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 48,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Confirm Contact & Payment',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3142),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ensure the driver has your correct details and select how you wish to pay.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Your Full Name',
                          prefixIcon: const Icon(Icons.person_outline,
                              color: Color(0xFFF35535)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Color(0xFFF35535), width: 2),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Contact Phone Number',
                          prefixIcon: const Icon(Icons.phone_outlined,
                              color: Color(0xFFF35535)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Color(0xFFF35535), width: 2),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Please enter your phone number';
                          }
                          if (v.trim().length < 7) {
                            return 'Please enter a valid phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      // Payment Method Selector
                      const Text(
                        'Payment Method',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3142),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => setModalState(() => selectedPaymentMethod = 'cash'),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: selectedPaymentMethod == 'cash'
                                      ? const Color(0xFFF35535).withValues(alpha: 0.1)
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selectedPaymentMethod == 'cash'
                                        ? const Color(0xFFF35535)
                                        : Colors.grey[300]!,
                                    width: selectedPaymentMethod == 'cash' ? 1.8 : 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.payments_outlined,
                                      size: 20,
                                      color: selectedPaymentMethod == 'cash'
                                          ? const Color(0xFFF35535)
                                          : Colors.grey[700],
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Cash',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: selectedPaymentMethod == 'cash'
                                            ? const Color(0xFFF35535)
                                            : Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () => setModalState(() => selectedPaymentMethod = 'card'),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: selectedPaymentMethod == 'card'
                                      ? const Color(0xFFF35535).withValues(alpha: 0.1)
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selectedPaymentMethod == 'card'
                                        ? const Color(0xFFF35535)
                                        : Colors.grey[300]!,
                                    width: selectedPaymentMethod == 'card' ? 1.8 : 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.credit_card,
                                      size: 20,
                                      color: selectedPaymentMethod == 'card'
                                          ? const Color(0xFFF35535)
                                          : Colors.grey[700],
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Card',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: selectedPaymentMethod == 'card'
                                            ? const Color(0xFFF35535)
                                            : Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF35535),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            Navigator.pop(sheetContext);
                            cubit.requestRide(
                              customerId,
                              driverId,
                              customerName: nameController.text.trim(),
                              customerPhone: phoneController.text.trim(),
                              paymentMethod: selectedPaymentMethod,
                            );
                          }
                        },
                        child: const Text(
                          'Confirm & Request Ride',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLocationField({
    required String hint,
    String? value,
    required VoidCallback onTap,
    bool isDestination = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hint,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value ?? (isDestination ? 'Select on map' : 'Current Location'),
                    style: TextStyle(
                      fontSize: 16,
                      color: value == null && isDestination ? Colors.grey[400] : Colors.black,
                      fontWeight: value == null && isDestination ? FontWeight.normal : FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey[300], size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Container(
        color: Colors.black26,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFFF35535)),
                SizedBox(height: 20),
                Text('Finding your driver...',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestStatus(TransportBookingRequested state) {
    return StreamBuilder<RideModel>(
      stream: getIt<TransportRepository>().watchRide(state.rideId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final ride = snapshot.data!;

        if (ride.status == RideStatus.accepted ||
            ride.status == RideStatus.arrived ||
            ride.status == RideStatus.started) {
          Future.microtask(() {
            if (context.mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  settings: const RouteSettings(name: '/transport/active'),
                  builder: (context) =>
                      ActiveRideScreen(rideId: state.rideId, isDriver: false),
                ),
              );
            }
          });
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              const CircularProgressIndicator(color: Color(0xFFF35535)),
              const SizedBox(height: 20),
              Text(
                ride.status == RideStatus.pending
                    ? 'Searching for Driver...'
                    : 'Driver Found!',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please stay on this screen. We will notify you once a driver accepts your request.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              if (ride.status == RideStatus.cancelled) ...[
                const SizedBox(height: 16),
                const Text('Request was rejected/cancelled.',
                    style: TextStyle(color: Colors.red)),
                const SizedBox(height: 8),
                MyButton(
                  text: 'Try Another Driver',
                  onPressed: () {
                    context.read<TransportBookingCubit>().fetchDriversNearby();
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistoryButton(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      right: 16,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
            ),
            child: Center(
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.history_rounded,
                    color: Colors.black, size: 20),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const TransportHistoryScreen()),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
