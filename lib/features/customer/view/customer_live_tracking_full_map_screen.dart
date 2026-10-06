import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:z_speed/core/services/routing_service.dart';
import 'package:z_speed/core/services/routing_config.dart';
import 'package:z_speed/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:z_speed/core/enums/order_enums.dart';
import 'package:intl/intl.dart';

/// Full-screen live driver tracking map for customers.
///
/// Streams the driver's GPS position from Firebase Realtime Database and displays
/// a route polyline from driver → customer's delivery location.
class CustomerLiveTrackingFullMapScreen extends StatefulWidget {
  final String orderId;
  final String driverUserId;
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

  const CustomerLiveTrackingFullMapScreen({
    super.key,
    required this.orderId,
    required this.driverUserId,
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
  State<CustomerLiveTrackingFullMapScreen> createState() =>
      _CustomerLiveTrackingFullMapScreenState();
}

class _CustomerLiveTrackingFullMapScreenState
    extends State<CustomerLiveTrackingFullMapScreen> {
  final MapController _mapController = MapController();
  StreamSubscription<DatabaseEvent>? _driverLocationSub;
  StreamSubscription<DocumentSnapshot>? _driverFirestoreSub;
  StreamSubscription<DocumentSnapshot>? _orderSubscription;

  LatLng? _driverLocation;
  List<LatLng> _routePoints = const [];
  double? _distanceKm;
  int? _etaMinutes;
  bool _isLoadingRoute = false;
  DateTime? _lastRouteUpdate;
  bool _isTrackingDriver = true;
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
    _startOrderSubscription();
  }

  @override
  void dispose() {
    _driverLocationSub?.cancel();
    _driverFirestoreSub?.cancel();
    _orderSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  void _startDriverLocationStream() {
    // Immediate one-time fetch for instant display
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
        final status = OrderStatusX.fromKey(statusKey);
        if (status == OrderStatus.delivered ||
            status == OrderStatus.cancelled ||
            status == OrderStatus.refunded) {
          _isClosing = true;
          _orderSubscription?.cancel();
          if (mounted && Navigator.canPop(context)) {
            Navigator.of(context).pop();
          }
        }
      }
    });
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
      debugPrint('Error fetching route for customer: $e');
    } finally {
      if (mounted) setState(() => _isLoadingRoute = false);
    }

    // Fallback: draw straight-line
    if (_driverLocation != null && mounted) {
      setState(() {
        _routePoints = [_driverLocation!, _destinationLocation];
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
          padding: const EdgeInsets.all(70),
        ),
      );
      _hasFittedInitialBounds = true;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // Map Layer
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
                      color: theme.primaryColor,
                      strokeWidth: 5.0,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  // Destination Marker
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
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isHeadingToRestaurant ? Icons.restaurant : Icons.location_on,
                        color: _isHeadingToRestaurant ? Colors.orange : Colors.green,
                        size: 26,
                      ),
                    ),
                  ),
                  // Driver Marker
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
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.delivery_dining,
                          color: Colors.teal,
                          size: 26,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Zoom Controls
          Positioned(
            right: 16,
            bottom: 220,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'track_driver',
                  onPressed: () {
                    setState(() => _isTrackingDriver = true);
                    if (_driverLocation != null) {
                      _mapController.move(_driverLocation!, 16.5);
                    }
                  },
                  backgroundColor: _isTrackingDriver ? theme.primaryColor : Colors.white,
                  child: Icon(
                    Icons.my_location,
                    color: _isTrackingDriver ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoom_in',
                  onPressed: () {
                    final zoom = _mapController.camera.zoom;
                    _mapController.move(_mapController.camera.center, zoom + 1);
                  },
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.add, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                FloatingActionButton.small(
                  heroTag: 'zoom_out',
                  onPressed: () {
                    final zoom = _mapController.camera.zoom;
                    _mapController.move(_mapController.camera.center, zoom - 1);
                  },
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.remove, color: Colors.black87),
                ),
              ],
            ),
          ),

          // Top Header (Driver details & back button)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
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
                        mainAxisSize: MainAxisSize.min,
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
                            _isHeadingToRestaurant
                                ? AppLocalizations.of(context)!.headingToRestaurant
                                : (widget.vehicleModel != null &&
                                        widget.vehicleModel!.isNotEmpty
                                    ? (widget.licensePlate != null &&
                                            widget.licensePlate!.isNotEmpty
                                        ? '${widget.vehicleModel} · ${widget.licensePlate}'
                                        : widget.vehicleModel!)
                                    : l10n.liveTracking),
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
            ),
          ),

          // Bottom Info Card (Remaining Distance & ETA)
          if (_distanceKm != null && _etaMinutes != null)
            PositionedDirectional(
              bottom: 85,
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
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _infoColumn(
                      Icons.timer,
                      l10n.minutesCount(_etaMinutes!),
                      l10n.eta(
                        DateFormat('h:mm a').format(
                          DateTime.now().add(Duration(minutes: _etaMinutes!)),
                        ),
                      ),
                      Colors.teal,
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.grey.shade200,
                    ),
                    _infoColumn(
                      Icons.route,
                      l10n.deliveryRadius(_distanceKm!.toStringAsFixed(1)),
                      l10n.distance,
                      theme.primaryColor,
                    ),
                  ],
                ),
              ),
            ),

          // Non-blocking status badge before the driver's location is streamed
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
                      BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: theme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        l10n.waitingForDriverLocation,
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
}
