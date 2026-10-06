import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:z_speed/core/services/routing_service.dart';
import 'package:z_speed/core/services/routing_config.dart';
import 'package:z_speed/features/customer/view/customer_live_tracking_full_map_screen.dart';

import 'package:z_speed/core/enums/order_enums.dart';

class CustomerLiveTrackingMap extends StatefulWidget {
  final String orderId;
  final String driverId;
  final String driverName;
  final String? driverPhone;
  final String? vehicleModel;
  final String? licensePlate;
  final double deliveryLat;
  final double deliveryLng;
  final String deliveryAddress;
  final double? restaurantLat;
  final double? restaurantLng;
  final OrderStatus? orderStatus;

  const CustomerLiveTrackingMap({
    super.key,
    required this.orderId,
    required this.driverId,
    required this.driverName,
    this.driverPhone,
    this.vehicleModel,
    this.licensePlate,
    required this.deliveryLat,
    required this.deliveryLng,
    required this.deliveryAddress,
    this.restaurantLat,
    this.restaurantLng,
    this.orderStatus,
  });

  @override
  State<CustomerLiveTrackingMap> createState() =>
      _CustomerLiveTrackingMapState();
}

class _CustomerLiveTrackingMapState extends State<CustomerLiveTrackingMap> {
  final MapController _mapController = MapController();
  StreamSubscription<DatabaseEvent>? _driverLocationSub;
  StreamSubscription<DocumentSnapshot>? _driverFirestoreSub;
  LatLng? _driverLocation;
  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = false;
  DateTime? _lastRouteUpdate;
  bool _hasFittedInitialBounds = false;

  bool get _isHeadingToRestaurant {
    final status = widget.orderStatus;
    return status == OrderStatus.driverAssigned ||
        status == OrderStatus.preparing ||
        status == OrderStatus.ready;
  }

  LatLng get _destinationLocation {
    if (_isHeadingToRestaurant &&
        widget.restaurantLat != null &&
        widget.restaurantLng != null) {
      return LatLng(widget.restaurantLat!, widget.restaurantLng!);
    }
    return LatLng(widget.deliveryLat, widget.deliveryLng);
  }

  @override
  void initState() {
    super.initState();
    _startDriverLocationStream();
  }

  @override
  void dispose() {
    _driverLocationSub?.cancel();
    _driverFirestoreSub?.cancel();
    super.dispose();
  }

  void _updateDriverLocationState(LatLng newLoc, {bool force = false}) {
    if (!mounted) return;
    if (!force && _driverLocation != null) {
      const dist = Distance();
      final movedMeters = dist.as(LengthUnit.Meter, _driverLocation!, newLoc);
      if (movedMeters < 1.8) {
        return; // Filter micro GPS jitter to prevent map shaking
      }
    }

    setState(() {
      _driverLocation = newLoc;
    });

    try {
      final currentZoom = _mapController.camera.zoom;
      final targetZoom = math.max(currentZoom, 16.0);
      _mapController.move(newLoc, targetZoom);
    } catch (_) {}

    final now = DateTime.now();
    if ((_routePoints.isEmpty ||
            _lastRouteUpdate == null ||
            now.difference(_lastRouteUpdate!).inSeconds >= 30) &&
        !_isLoadingRoute) {
      _fetchRoute(newLoc);
    }
  }

  void _startDriverLocationStream() {
    // Immediate one-time fetch for instant display
    FirebaseFirestore.instance
        .collection('driverProfiles')
        .doc(widget.driverId)
        .get()
        .then((doc) {
      if (mounted && doc.exists) {
        final data = doc.data();
        if (data != null) {
          final lat = (data['currentLat'] as num?)?.toDouble();
          final lng = (data['currentLng'] as num?)?.toDouble();
          if (lat != null && lng != null) {
            _updateDriverLocationState(LatLng(lat, lng), force: true);
          }
        }
      }
    }).catchError((_) {});

    // 1. Primary RTDB stream
    _driverLocationSub = FirebaseDatabase.instance
        .ref('active_drivers/${widget.driverId}')
        .onValue
        .listen((event) {
      if (!mounted || event.snapshot.value == null) return;
      final val = event.snapshot.value;
      if (val is Map) {
        final data = Map<dynamic, dynamic>.from(val);
        final lat = (data['currentLat'] as num?)?.toDouble();
        final lng = (data['currentLng'] as num?)?.toDouble();

        if (lat != null && lng != null) {
          _updateDriverLocationState(LatLng(lat, lng));
        }
      }
    });

    // 2. Fallback Firestore stream
    _driverFirestoreSub = FirebaseFirestore.instance
        .collection('driverProfiles')
        .doc(widget.driverId)
        .snapshots()
        .listen((doc) {
      if (!mounted || !doc.exists) return;
      final data = doc.data();
      if (data == null) return;
      final lat = (data['currentLat'] as num?)?.toDouble();
      final lng = (data['currentLng'] as num?)?.toDouble();

      if (lat != null && lng != null) {
        _updateDriverLocationState(LatLng(lat, lng));
      }
    });
  }

  Future<void> _fetchRoute(LatLng driverLoc) async {
    setState(() => _isLoadingRoute = true);

    try {
      final destination = _destinationLocation;
      final result =
          await RoutingService.instance.getDirections(driverLoc, destination);

      if (result != null && mounted) {
        setState(() {
          _routePoints = result.points;
          _isLoadingRoute = false;
          _lastRouteUpdate = DateTime.now();
        });

        // Fit bounds on initial load
        if (!_hasFittedInitialBounds) {
          final bounds = LatLngBounds.fromPoints(
              [driverLoc, destination, ..._routePoints]);
          _mapController.fitCamera(
            CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
          );
          _hasFittedInitialBounds = true;
        }
        return;
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isLoadingRoute = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_driverLocation == null) {
      return const SizedBox(
        height: 200,
        child:
            Center(child: CircularProgressMessage(text: "Locating driver...")),
      );
    }

    return GestureDetector(
      onTap: () {
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
            builder: (_) => CustomerLiveTrackingFullMapScreen(
              orderId: widget.orderId,
              driverUserId: widget.driverId,
              driverName: widget.driverName,
              driverPhone: widget.driverPhone,
              vehicleModel: widget.vehicleModel,
              licensePlate: widget.licensePlate,
              deliveryLat: widget.deliveryLat,
              deliveryLng: widget.deliveryLng,
              deliveryAddress: widget.deliveryAddress,
              restaurantLat: widget.restaurantLat,
              restaurantLng: widget.restaurantLng,
              orderStatus: widget.orderStatus,
            ),
          ),
        );
      },
      child: Container(
        height: 250,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _driverLocation!,
                initialZoom: 16.0,
                onMapReady: () {
                  if (_driverLocation != null) {
                    try {
                      _mapController.move(_driverLocation!, 16.0);
                    } catch (_) {}
                  }
                },
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.none,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: RoutingConfig.tileUrl,
                  subdomains: RoutingConfig.tileSubdomains,
                  userAgentPackageName: RoutingConfig.userAgentPackageName,
                ),
                if (_routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routePoints,
                        color: Colors.blue,
                        strokeWidth: 4.0,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _driverLocation!,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.delivery_dining,
                          color: Colors.blue, size: 30),
                    ),
                    Marker(
                      point: _destinationLocation,
                      width: 40,
                      height: 40,
                      child: Icon(
                        _isHeadingToRestaurant
                            ? Icons.restaurant
                            : Icons.location_on,
                        color: _isHeadingToRestaurant
                            ? Colors.orange
                            : Colors.green,
                        size: 30,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 4),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fullscreen,
                        size: 16, color: Colors.grey.shade800),
                    const SizedBox(width: 4),
                    Text(
                      'Tap to expand',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CircularProgressMessage extends StatelessWidget {
  final String text;
  const CircularProgressMessage({super.key, required this.text});
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 8),
        Text(text),
      ],
    );
  }
}
