import 'package:z_speed/l10n/app_localizations.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:z_speed/core/services/routing_service.dart';
import 'package:z_speed/core/services/routing_config.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:z_speed/core/enums/order_enums.dart';
import 'package:z_speed/core/enums/driver_enums.dart';

/// Full-screen live driver tracking map for restaurant owners.
///
/// Streams the driver's GPS position from Firestore and displays
/// a route polyline from driver → restaurant/customer using LocationIQ.
import 'package:firebase_database/firebase_database.dart';

class DriverTrackingScreen extends StatefulWidget {
  final String driverUserId;
  final String driverName;
  final double restaurantLat;
  final double restaurantLng;
  final String restaurantName;
  final String orderId;
  final double deliveryLat;
  final double deliveryLng;
  final OrderStatus initialOrderStatus;

  const DriverTrackingScreen({
    super.key,
    required this.driverUserId,
    required this.driverName,
    required this.restaurantLat,
    required this.restaurantLng,
    required this.restaurantName,
    required this.orderId,
    required this.deliveryLat,
    required this.deliveryLng,
    required this.initialOrderStatus,
  });

  @override
  State<DriverTrackingScreen> createState() => _DriverTrackingScreenState();
}

class _DriverTrackingScreenState extends State<DriverTrackingScreen> {
  final MapController _mapController = MapController();
  StreamSubscription<DatabaseEvent>? _driverLocationSub;
  StreamSubscription<DocumentSnapshot>? _driverFirestoreSub;
  StreamSubscription<DocumentSnapshot>? _orderSubscription;
  StreamSubscription<DocumentSnapshot>? _orderDriverSubscription;

  LatLng? _driverLocation;
  List<LatLng> _routePoints = const [];
  double? _distanceKm;
  int? _etaMinutes;
  bool _isLoadingRoute = false;
  DateTime? _lastRouteUpdate;
  OrderStatus? _orderStatus;
  DriverAssignmentStatus? _driverAssignmentStatus;
  bool _isTrackingDriver = true;
  bool _hasFittedInitialBounds = false;

  bool get _isDeliveringToCustomer {
    final status = _orderStatus ?? widget.initialOrderStatus;
    final isDelivering = status == OrderStatus.pickedUp || status == OrderStatus.onTheWay;
    final isDriverPickedUp = _driverAssignmentStatus == DriverAssignmentStatus.pickedUp;
    return isDelivering || isDriverPickedUp;
  }

  LatLng get _destinationLocation {
    if (_isDeliveringToCustomer) {
      return LatLng(widget.deliveryLat, widget.deliveryLng);
    }
    return LatLng(widget.restaurantLat, widget.restaurantLng);
  }

  @override
  void initState() {
    super.initState();
    _orderStatus = widget.initialOrderStatus;
    _startDriverLocationStream();
    _startOrderSubscription();
    _startOrderDriverSubscription();
  }

  @override
  void dispose() {
    _driverLocationSub?.cancel();
    _driverFirestoreSub?.cancel();
    _orderSubscription?.cancel();
    _orderDriverSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  bool _isClosing = false;

  void _startOrderSubscription() {
    _orderSubscription = FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId)
        .snapshots()
        .listen((snapshot) {
      if (!mounted || _isClosing) return;
      if (snapshot.exists) {
        final statusKey = snapshot.data()?['status'] as String? ?? '';
        debugPrint('[DriverTrackingScreen] Order status updated in Firestore: $statusKey');
        final status = OrderStatusX.fromKey(statusKey);
        if (status == OrderStatus.delivered ||
            status == OrderStatus.cancelled ||
            status == OrderStatus.refunded) {
          _isClosing = true;
          _orderSubscription?.cancel();
          _orderDriverSubscription?.cancel();
          if (mounted && Navigator.canPop(context)) {
            Navigator.of(context).pop();
          }
          return;
        }
        if (status != _orderStatus) {
          setState(() {
            _orderStatus = status;
          });
          _fetchRoute();
        }
      }
    });
  }

  void _startOrderDriverSubscription() {
    _orderDriverSubscription = FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId)
        .collection('orderDrivers')
        .doc(widget.driverUserId)
        .snapshots()
        .listen((snapshot) {
      if (!mounted || _isClosing) return;
      if (snapshot.exists) {
        final statusKey = snapshot.data()?['status'] as String? ?? '';
        debugPrint('[DriverTrackingScreen] OrderDriver status updated in Firestore: $statusKey');
        final status = DriverAssignmentStatusX.fromKey(statusKey);
        if (status == DriverAssignmentStatus.delivered ||
            status == DriverAssignmentStatus.cancelled ||
            status == DriverAssignmentStatus.rejected) {
          _isClosing = true;
          _orderSubscription?.cancel();
          _orderDriverSubscription?.cancel();
          if (mounted && Navigator.canPop(context)) {
            Navigator.of(context).pop();
          }
          return;
        }
        if (status != _driverAssignmentStatus) {
          setState(() {
            _driverAssignmentStatus = status;
          });
          _fetchRoute();
        }
      }
    });
  }

  void _startDriverLocationStream() {
    // Immediate one-time fetch to display driver location instantly
    FirebaseFirestore.instance
        .collection('driverProfiles')
        .doc(widget.driverUserId)
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
        .ref('active_drivers/${widget.driverUserId}')
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
        .doc(widget.driverUserId)
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

  void _updateDriverLocationState(LatLng newLoc, {bool force = false}) {
    if (!force && _driverLocation != null) {
      const distThreshold = Distance();
      final movedMeters = distThreshold.as(LengthUnit.Meter, _driverLocation!, newLoc);
      if (movedMeters < 1.8) return; // Filter micro GPS jitter to prevent map shaking
    }

    const dist = Distance();
    final meters = dist.as(LengthUnit.Meter, newLoc, _destinationLocation);
    final km = meters / 1000;
    final etaMin = ((km * 1.3) / 40 * 60).ceil();

    setState(() {
      _driverLocation = newLoc;
      _distanceKm = km;
      _etaMinutes = etaMin < 1 ? 1 : etaMin;
    });

    if (_isTrackingDriver) {
      try {
        final currentZoom = _mapController.camera.zoom;
        final targetZoom = math.max(currentZoom, 16.5);
        _mapController.move(newLoc, targetZoom);
      } catch (_) {}
    }

    final now = DateTime.now();
    if (_lastRouteUpdate == null ||
        now.difference(_lastRouteUpdate!).inSeconds >= 30) {
      _fetchRoute();
    }
  }

  Future<void> _fetchRoute() async {
    if (_driverLocation == null || _isLoadingRoute) return;

    setState(() => _isLoadingRoute = true);

    try {
      final result = await RoutingService.instance
          .getDirections(_driverLocation!, _destinationLocation);

      if (result != null && mounted) {
        setState(() {
          _routePoints = result.points;
          _distanceKm = result.distanceKm;
          _etaMinutes = result.etaMinutes;
          _lastRouteUpdate = DateTime.now();
        });

        _fitMapToBounds();
        return;
      }
    } catch (e) {
      debugPrint('Error fetching route: $e');
    } finally {
      if (mounted) setState(() => _isLoadingRoute = false);
    }

    // Fallback: calculate straight-line distance & draw direct line
    if (_driverLocation != null && mounted) {
      const distance = Distance();
      final meters = distance.as(
        LengthUnit.Meter,
        _driverLocation!,
        _destinationLocation,
      );
      final km = meters / 1000;
      // Estimate ~40 km/h average city speed, multiply distance by 1.3 for road factor
      final etaMin = ((km * 1.3) / 40 * 60).ceil();

      setState(() {
        _routePoints = [_driverLocation!, _destinationLocation];
        _distanceKm = km;
        _etaMinutes = etaMin < 1 ? 1 : etaMin;
        _lastRouteUpdate = DateTime.now();
      });

      _fitMapToBounds();
    }
  }

  void _fitMapToBounds() {
    if (_driverLocation == null) return;
    if (_hasFittedInitialBounds && _isTrackingDriver) return;

    final points = [_driverLocation!, _destinationLocation];
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (var p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    try {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng)),
          padding: const EdgeInsets.all(60),
        ),
      );
      _hasFittedInitialBounds = true;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _driverLocation ?? _destinationLocation,
              initialZoom: 16.5,
              onMapReady: () {
                if (_driverLocation != null) {
                  try {
                    _mapController.move(_driverLocation!, 16.5);
                  } catch (_) {}
                }
                _fitMapToBounds();
              },
              onPositionChanged: (camera, hasGesture) {
                if (hasGesture && _isTrackingDriver) {
                  setState(() => _isTrackingDriver = false);
                }
              },
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
                      color: const Color(0xFFF35535),
                      strokeWidth: 5.0,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  // Destination marker (Restaurant or Customer)
                  Marker(
                    point: _destinationLocation,
                    width: 44,
                    height: 44,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black26,
                              blurRadius: 6,
                              offset: Offset(0, 2)),
                        ],
                      ),
                      child: Icon(
                        _isDeliveringToCustomer
                            ? Icons.location_on
                            : Icons.restaurant,
                        color: _isDeliveringToCustomer
                            ? Colors.green
                            : const Color(0xFFF35535),
                        size: 26,
                      ),
                    ),
                  ),
                  // Driver marker
                  if (_driverLocation != null)
                    Marker(
                      point: _driverLocation!,
                      width: 44,
                      height: 44,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black26,
                                blurRadius: 6,
                                offset: Offset(0, 2)),
                          ],
                        ),
                        child: const Icon(Icons.delivery_dining,
                            color: Colors.teal, size: 26),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Back button + driver info
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_back, size: 20),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.driverName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _isDeliveringToCustomer
                                    ? AppLocalizations.of(context)!.headingToCustomer
                                    : AppLocalizations.of(context)!
                                        .headingTo(widget.restaurantName),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (_isLoadingRoute)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Map controls
          PositionedDirectional(
            end: 16,
            bottom: (_distanceKm != null && _etaMinutes != null) ? 160 : 32,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Re-center button
                _buildMapButton(
                  icon: Icons.my_location,
                  tooltip: 'Re-center',
                  bgColor: _isTrackingDriver ? const Color(0xFFF35535) : Colors.white,
                  iconColor: _isTrackingDriver ? Colors.white : Colors.grey.shade800,
                  onTap: () {
                    setState(() => _isTrackingDriver = true);
                    if (_driverLocation != null) {
                      _mapController.move(_driverLocation!, 16.5);
                    }
                  },
                ),
                const SizedBox(height: 10),
                // Zoom In
                _buildMapButton(
                  icon: Icons.add,
                  tooltip: AppLocalizations.of(context)!.zoomIn,
                  onTap: () {
                    final currentZoom = _mapController.camera.zoom;
                    _mapController.move(
                        _mapController.camera.center, currentZoom + 1);
                  },
                ),
                const SizedBox(height: 2),
                // Zoom Out
                _buildMapButton(
                  icon: Icons.remove,
                  tooltip: AppLocalizations.of(context)!.zoomOut,
                  onTap: () {
                    final currentZoom = _mapController.camera.zoom;
                    _mapController.move(
                        _mapController.camera.center, currentZoom - 1);
                  },
                ),
              ],
            ),
          ),

          // Bottom ETA card
          if (_distanceKm != null && _etaMinutes != null)
            PositionedDirectional(
              bottom: 32,
              start: 16,
              end: 16,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 15,
                        offset: Offset(0, -2)),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _infoColumn(
                      Icons.timer,
                      AppLocalizations.of(context)!.minutesCount(_etaMinutes!),
                      AppLocalizations.of(context)!.eta(
                        DateFormat('h:mm a').format(
                          DateTime.now().add(Duration(minutes: _etaMinutes!)),
                        ),
                      ),
                      Colors.teal,
                    ),
                    Container(
                        width: 1, height: 40, color: Colors.grey.shade200),
                    _infoColumn(
                      Icons.route,
                      AppLocalizations.of(context)!
                          .deliveryRadius(_distanceKm!.toStringAsFixed(1)),
                      AppLocalizations.of(context)!.distance,
                      const Color(0xFFF35535),
                    ),
                  ],
                ),
              ),
            ),

          // Non-blocking status badge when no driver GPS location yet
          if (_driverLocation == null)
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  margin: const EdgeInsets.only(top: 110, left: 24, right: 24),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Color(0xFFF35535),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        AppLocalizations.of(context)!.waitingForDriverLocation,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoColumn(IconData icon, String value, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildMapButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color? bgColor,
    Color? iconColor,
  }) {
    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(10),
      color: bgColor ?? Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: Icon(icon, size: 22, color: iconColor ?? Colors.grey.shade800),
        ),
      ),
    );
  }
}
