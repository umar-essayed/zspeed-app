import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:z_speed/features/transport/cubit/active_ride_cubit.dart';
import 'package:z_speed/features/transport/cubit/active_ride_state.dart';
import 'package:z_speed/features/transport/model/ride_model.dart';
import 'package:z_speed/core/injection.dart';
import 'package:z_speed/components/my_button.dart';
import 'package:z_speed/core/services/routing_service.dart';
import 'package:z_speed/core/services/routing_config.dart';
import 'dart:ui';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:z_speed/l10n/app_localizations.dart';
import 'package:z_speed/features/shared/widgets/navigation/in_app_navigation_overlay.dart';
import 'package:z_speed/features/payment/datasource/paylink_datasource.dart';
import 'package:z_speed/features/payment/view/paylink_webview_page.dart';
import 'package:z_speed/features/payment/widgets/payment_status_sheet.dart';

class ActiveRideScreen extends StatelessWidget {
  final String rideId;
  final bool isDriver;

  const ActiveRideScreen(
      {super.key, required this.rideId, required this.isDriver});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<ActiveRideCubit>()..watchRide(rideId),
      child: Scaffold(
        body: ActiveRideBody(isDriver: isDriver),
      ),
    );
  }
}

class ActiveRideBody extends StatefulWidget {
  final bool isDriver;

  const ActiveRideBody({super.key, required this.isDriver});

  @override
  State<ActiveRideBody> createState() => _ActiveRideBodyState();
}

class _ActiveRideBodyState extends State<ActiveRideBody> {
  final MapController _mapController = MapController();
  List<LatLng> _routePoints = [];
  LatLng? _lastCalculatedOrigin;
  RideStatus? _lastStatus;
  double? _distanceKm;
  int? _durationMin;
  bool _isTrackingDriver = true;
  /// Guard: prevents Navigator.pop from being called more than once
  /// when the BlocConsumer listener fires multiple times for completed/cancelled rides.
  bool _hasNavigatedAway = false;

  bool _inNavigationMode = false;
  List<RouteStep> _navigationSteps = [];
  int _currentStepIndex = 0;
  double _currentSpeed = 0.0; // m/s
  final double _speedLimit = 60.0; // km/h
  double _driverHeading = 0.0;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ActiveRideCubit, ActiveRideState>(
      listener: (context, state) {
        if (state is ActiveRideLoaded) {
          final ride = state.ride;
          if (ride.status == RideStatus.completed) {
            if (_hasNavigatedAway) return;
            _hasNavigatedAway = true;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ride completed successfully!'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.green,
              ),
            );
            Navigator.maybePop(context);
          } else if (ride.status == RideStatus.cancelled) {
            if (_hasNavigatedAway) return;
            _hasNavigatedAway = true;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ride cancelled.'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.red,
              ),
            );
            Navigator.maybePop(context);
          } else {
            _updateRoute(ride);
            if (widget.isDriver && _locationSubscription == null) {
              _startDriverTracking(ride.id);
            }
            if (_isTrackingDriver && ride.currentDriverLocation != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _isTrackingDriver && ride.currentDriverLocation != null) {
                  _mapController.move(
                    LatLng(ride.currentDriverLocation!.latitude,
                        ride.currentDriverLocation!.longitude),
                    _inNavigationMode ? 17.5 : _mapController.camera.zoom,
                  );
                  if (_inNavigationMode) {
                    _mapController.rotate(360 - _driverHeading);
                  }
                }
              });
            }
            if (_inNavigationMode && ride.currentDriverLocation != null) {
              _updateNavigationProgress(LatLng(
                  ride.currentDriverLocation!.latitude,
                  ride.currentDriverLocation!.longitude));
            }
          }
        }
      },
      builder: (context, state) {
        if (state is ActiveRideLoading) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFFF35535)));
        }

        if (state is ActiveRideError) {
          return Scaffold(
            appBar: AppBar(elevation: 0, backgroundColor: Colors.transparent),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message,
                      style: const TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          );
        }

        if (state is ActiveRideLoaded) {
          final ride = state.ride;

          return Stack(
            children: [
              // ── Map Layer ──
              _buildMap(ride),

              // ── Top Header ──
              if (!_inNavigationMode)
                _buildHeader(context, ride),

              // ── Map Controls ──
              if (!_inNavigationMode)
                Positioned(
                  right: 16,
                  bottom: 295, // Stays cleanly above the bottom panel
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.isDriver) ...[
                        _buildMapControl(
                          icon: Icons.navigation_rounded,
                          onTap: () => _showNavigationSelector(ride),
                          tooltip: AppLocalizations.of(context)?.startNavigation ?? 'Start Navigation',
                          backgroundColor: const Color(0xFF16A34A),
                          iconColor: Colors.white,
                        ),
                        const SizedBox(height: 10),
                      ],
                      // Re-center Button
                      _buildMapControl(
                        icon: Icons.my_location,
                        onTap: () => _reCenterMap(ride),
                        tooltip: 'Re-center Map',
                        backgroundColor: _isTrackingDriver ? const Color(0xFFF35535) : null,
                        iconColor: _isTrackingDriver ? Colors.white : null,
                      ),
                      const SizedBox(height: 10),
                      // Zoom In Button
                      _buildMapControl(
                        icon: Icons.add,
                        onTap: () {
                          final zoom = _mapController.camera.zoom;
                          _mapController.move(_mapController.camera.center, zoom + 1);
                        },
                        tooltip: 'Zoom In',
                      ),
                      const SizedBox(height: 10),
                      // Zoom Out Button
                      _buildMapControl(
                        icon: Icons.remove,
                        onTap: () {
                          final zoom = _mapController.camera.zoom;
                          _mapController.move(_mapController.camera.center, zoom - 1);
                        },
                        tooltip: 'Zoom Out',
                      ),
                    ],
                  ),
                ),

              // ── Bottom Panel ──
              if (!_inNavigationMode)
                _buildBottomPanel(context, ride),

              // Resume Center button for Navigation Mode
              if (_inNavigationMode && !_isTrackingDriver)
                Positioned(
                  right: 16,
                  bottom: 150,
                  child: FloatingActionButton.extended(
                    backgroundColor: const Color(0xFFF35535),
                    foregroundColor: Colors.white,
                    onPressed: () {
                      setState(() {
                        _isTrackingDriver = true;
                      });
                      if (ride.currentDriverLocation != null) {
                        _mapController.move(
                          LatLng(ride.currentDriverLocation!.latitude,
                              ride.currentDriverLocation!.longitude),
                          17.5,
                        );
                        _mapController.rotate(360 - _driverHeading);
                      }
                    },
                    icon: const Icon(Icons.my_location),
                    label: const Text('Re-center'),
                  ),
                ),

              // In-App Navigation Overlay
              if (_inNavigationMode)
                InAppNavigationOverlay(
                  isNavigationActive: _inNavigationMode,
                  nextStep: _navigationSteps.isNotEmpty && _currentStepIndex < _navigationSteps.length
                      ? _navigationSteps[_currentStepIndex]
                      : null,
                  distanceToNextStep: _navigationSteps.isNotEmpty && _currentStepIndex < _navigationSteps.length && ride.currentDriverLocation != null
                      ? Geolocator.distanceBetween(
                          ride.currentDriverLocation!.latitude,
                          ride.currentDriverLocation!.longitude,
                          _navigationSteps[_currentStepIndex].location.latitude,
                          _navigationSteps[_currentStepIndex].location.longitude,
                        )
                      : 0.0,
                  totalRemainingDistance: _routePoints.isNotEmpty && ride.currentDriverLocation != null
                      ? _calculateRemainingDistance(
                          LatLng(ride.currentDriverLocation!.latitude, ride.currentDriverLocation!.longitude),
                          _routePoints,
                          _findClosestRoutePointIndex(
                            LatLng(ride.currentDriverLocation!.latitude, ride.currentDriverLocation!.longitude),
                            _routePoints,
                          ),
                        )
                      : 0.0,
                  totalRemainingDuration: _routePoints.isNotEmpty && ride.currentDriverLocation != null
                      ? (_calculateRemainingDistance(
                          LatLng(ride.currentDriverLocation!.latitude, ride.currentDriverLocation!.longitude),
                          _routePoints,
                          _findClosestRoutePointIndex(
                            LatLng(ride.currentDriverLocation!.latitude, ride.currentDriverLocation!.longitude),
                            _routePoints,
                          ),
                        ) / 11.0)
                      : 0.0,
                  currentSpeed: _currentSpeed,
                  speedLimit: _speedLimit,
                  onExitNavigation: () => _exitInAppNavigation(ride),
                ),
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Future<void> _updateRoute(RideModel ride) async {
    LatLng origin;
    if (ride.currentDriverLocation != null) {
      origin = LatLng(ride.currentDriverLocation!.latitude,
          ride.currentDriverLocation!.longitude);
    } else {
      origin = LatLng(ride.pickupLocation.latitude, ride.pickupLocation.longitude);
    }

    LatLng destination;
    if (ride.status == RideStatus.accepted ||
        ride.status == RideStatus.arrived) {
      destination =
          LatLng(ride.pickupLocation.latitude, ride.pickupLocation.longitude);
    } else if (ride.status == RideStatus.started) {
      destination =
          LatLng(ride.dropoffLocation.latitude, ride.dropoffLocation.longitude);
    } else {
      return;
    }

    // Continuously calculate dynamic real-time distance and ETA
    double meters = Geolocator.distanceBetween(
      origin.latitude,
      origin.longitude,
      destination.latitude,
      destination.longitude,
    );

    // If heading to pickup and driver is at/near pickup (< 100m), show total trip distance to dropoff
    if ((ride.status == RideStatus.accepted || ride.status == RideStatus.arrived) && meters < 100) {
      meters = Geolocator.distanceBetween(
        ride.pickupLocation.latitude,
        ride.pickupLocation.longitude,
        ride.dropoffLocation.latitude,
        ride.dropoffLocation.longitude,
      );
    }

    final double calcKm = meters / 1000;
    final int calcEta = ((calcKm * 1.3) / 40 * 60).ceil();

    if (mounted) {
      setState(() {
        _distanceKm = calcKm < 0.1 ? 0.1 : calcKm;
        _durationMin = calcEta < 1 ? 1 : calcEta;
      });
    }

    final bool statusChanged = _lastStatus != ride.status;
    final bool distanceChanged = _lastCalculatedOrigin == null ||
        Geolocator.distanceBetween(
              _lastCalculatedOrigin!.latitude,
              _lastCalculatedOrigin!.longitude,
              origin.latitude,
              origin.longitude,
            ) >
            200;

    if (statusChanged || _routePoints.isEmpty || distanceChanged) {
      _lastStatus = ride.status;
      _lastCalculatedOrigin = origin;

      final LatLng routeTarget = (ride.status == RideStatus.accepted || ride.status == RideStatus.arrived) && meters < 100
          ? LatLng(ride.dropoffLocation.latitude, ride.dropoffLocation.longitude)
          : destination;

      final directions =
          await RoutingService.instance.getDirections(origin, routeTarget);
      if (directions != null && mounted) {
        setState(() {
          _routePoints = directions.points;
          _navigationSteps = directions.steps;
          if (_navigationSteps.isEmpty) {
            _navigationSteps = RoutingService.generateStepsFromPoints(directions.points);
          }
          if (directions.distanceKm > 0.1) {
            _distanceKm = directions.distanceKm;
            _durationMin = directions.etaMinutes < 1 ? 1 : directions.etaMinutes;
          }
        });

        if (!_inNavigationMode) {
          _fitMapToBounds(directions.points);
        }
      } else {
        if (mounted) {
          setState(() {
            _routePoints = [origin, routeTarget];
            _navigationSteps = RoutingService.generateStepsFromPoints([origin, routeTarget]);
          });
          if (!_inNavigationMode) {
            _fitMapToBounds([origin, routeTarget]);
          }
        }
      }
    }
  }

  void _fitMapToBounds(List<LatLng> points) {
    if (points.isEmpty) return;

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

    // If the bounds are zero-area (single point or all identical points),
    // flutter_map will warn and fail to fit. Fall back to a simple move().
    const double minSpan = 0.002; // ~200m minimum span to ensure non-zero bounds
    if ((maxLat - minLat) < minSpan && (maxLng - minLng) < minSpan) {
      final centerLat = (minLat + maxLat) / 2;
      final centerLng = (minLng + maxLng) / 2;
      try {
        _mapController.move(LatLng(centerLat, centerLng), 15.0);
      } catch (e) {
        debugPrint('[ActiveRide] mapController.move failed: $e');
      }
      return;
    }

    try {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng)),
          padding: const EdgeInsets.all(70),
        ),
      );
    } catch (e) {
      debugPrint('[ActiveRide] fitCamera failed: $e');
    }
  }


  void _reCenterMap(RideModel ride) {
    setState(() {
      _isTrackingDriver = true;
    });
    if (ride.currentDriverLocation != null) {
      _mapController.move(
        LatLng(ride.currentDriverLocation!.latitude,
            ride.currentDriverLocation!.longitude),
        16.5,
      );
    } else if (_routePoints.isNotEmpty) {
      _fitMapToBounds(_routePoints);
    } else {
      _mapController.move(
        LatLng(ride.pickupLocation.latitude, ride.pickupLocation.longitude),
        16.5,
      );
    }
  }

  // ── IN-APP NAVIGATION METHODS ──
  void _enterInAppNavigation(RideModel ride) {
    if (ride.currentDriverLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)?.waitingForGpsCoordinates ?? 'Waiting for GPS coordinates...'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() {
      _navigationSteps = _routePoints.isNotEmpty
          ? RoutingService.generateStepsFromPoints(_routePoints)
          : [];
      _inNavigationMode = true;
      _currentStepIndex = 0;
      _isTrackingDriver = true;
      _currentSpeed = 0.0;
    });

    _mapController.move(
      LatLng(ride.currentDriverLocation!.latitude, ride.currentDriverLocation!.longitude),
      17.5,
    );
    _mapController.rotate(360 - _driverHeading);
  }

  void _exitInAppNavigation(RideModel ride) {
    setState(() {
      _inNavigationMode = false;
      _currentSpeed = 0.0;
      _isTrackingDriver = true;
    });
    _mapController.rotate(0.0);
    if (_routePoints.isNotEmpty) {
      _fitMapToBounds(_routePoints);
    }
  }

  void _updateNavigationProgress(LatLng currentLoc) {
    if (_navigationSteps.isEmpty) {
      if (_routePoints.isNotEmpty) {
        _navigationSteps = RoutingService.generateStepsFromPoints(_routePoints);
      }
      if (_navigationSteps.isEmpty) return;
    }

    if (_currentStepIndex < _navigationSteps.length - 1) {
      final targetStepLoc = _navigationSteps[_currentStepIndex + 1].location;
      final distToNext = Geolocator.distanceBetween(
        currentLoc.latitude, currentLoc.longitude,
        targetStepLoc.latitude, targetStepLoc.longitude,
      );
      if (distToNext < 20.0) {
        setState(() {
          _currentStepIndex++;
        });
      }
    }

    // Drift / Off-route check
    if (_routePoints.isNotEmpty) {
      final drift = _getDistanceToPolyline(currentLoc, _routePoints);
      if (drift > 50.0) {
        debugPrint('[ActiveRideNavigation] Driver drifted $drift meters off route. Re-routing...');
        // Trigger Cuban re-route by calculating new directions locally (which will fire a state update)
        final state = context.read<ActiveRideCubit>().state;
        if (state is ActiveRideLoaded) {
          _updateRoute(state.ride);
        }
      }
    }
  }

  double _getDistanceToPolyline(LatLng loc, List<LatLng> polylinePoints) {
    if (polylinePoints.isEmpty) return 0.0;
    double minDistance = double.infinity;
    for (final point in polylinePoints) {
      final dist = Geolocator.distanceBetween(
        loc.latitude, loc.longitude,
        point.latitude, point.longitude,
      );
      if (dist < minDistance) {
        minDistance = dist;
      }
    }
    return minDistance;
  }

  double _calculateRemainingDistance(LatLng currentLoc, List<LatLng> routePoints, int currentPointIndex) {
    if (routePoints.isEmpty) return 0.0;
    double dist = Geolocator.distanceBetween(
      currentLoc.latitude, currentLoc.longitude,
      routePoints[currentPointIndex].latitude, routePoints[currentPointIndex].longitude,
    );
    for (int i = currentPointIndex; i < routePoints.length - 1; i++) {
      dist += Geolocator.distanceBetween(
        routePoints[i].latitude, routePoints[i].longitude,
        routePoints[i + 1].latitude, routePoints[i + 1].longitude,
      );
    }
    return dist;
  }

  int _findClosestRoutePointIndex(LatLng currentLoc, List<LatLng> routePoints) {
    if (routePoints.isEmpty) return 0;
    int minIndex = 0;
    double minDistance = double.infinity;
    for (int i = 0; i < routePoints.length; i++) {
      final dist = Geolocator.distanceBetween(
        currentLoc.latitude, currentLoc.longitude,
        routePoints[i].latitude, routePoints[i].longitude,
      );
      if (dist < minDistance) {
        minDistance = dist;
        minIndex = i;
      }
    }
    return minIndex;
  }



  void _showNavigationSelector(RideModel ride) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  AppLocalizations.of(context)?.startNavigation ?? 'Start Navigation',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.navigation_rounded, color: Colors.blue),
                ),
                title: Text(
                  AppLocalizations.of(context)?.inAppNavigationMode ?? 'In-App Navigation Mode',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  AppLocalizations.of(context)?.keepZSpeedAppOpen ?? 'Keep Z-SPEED app open with live turn-by-turn guidance',
                ),
                onTap: () {
                  Navigator.pop(context);
                  _enterInAppNavigation(ride);
                },
              ),
              const Divider(),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.map_rounded, color: Colors.green),
                ),
                title: Text(
                  AppLocalizations.of(context)?.externalGoogleMaps ?? 'External Google Maps',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  AppLocalizations.of(context)?.openTurnByTurnRoute ?? 'Open turn-by-turn route in Google Maps app',
                ),
                onTap: () {
                  Navigator.pop(context);
                  _openGoogleMapsDirections(ride);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  StreamSubscription<Position>? _locationSubscription;

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startDriverTracking(String rideId) async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!mounted) return;
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (!mounted) return;
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (!mounted) return;
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    // Upgrade permission to "Always Allow" progressively for background tracking
    if (permission == LocationPermission.whileInUse) {
      permission = await Geolocator.requestPermission();
      if (!mounted) return;
    }

    LocationSettings locationSettings;
    if (Theme.of(context).platform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1,
        intervalDuration: const Duration(seconds: 1),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText: "Z-SPEED Active ride tracking is running.",
          notificationTitle: "Active Ride Location",
          enableWakeLock: true,
        ),
      );
    } else if (Theme.of(context).platform == TargetPlatform.iOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1,
        activityType: ActivityType.fitness,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1,
      );
    }

    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      if (!mounted) return;

      final state = context.read<ActiveRideCubit>().state;
      if (state is ActiveRideLoaded) {
        final ride = state.ride;
        if (ride.status == RideStatus.completed ||
            ride.status == RideStatus.cancelled) {
          _locationSubscription?.cancel();
          return;
        }

        double heading = position.heading;
        if (heading == 0.0 && ride.currentDriverLocation != null) {
          final calc = Geolocator.bearingBetween(
            ride.currentDriverLocation!.latitude,
            ride.currentDriverLocation!.longitude,
            position.latitude,
            position.longitude,
          );
          if (calc != 0.0) {
            heading = calc < 0 ? (calc % 360 + 360) % 360 : calc;
          }
        }

        if (heading != 0.0) {
          setState(() {
            _driverHeading = heading;
          });
        }

        context
            .read<ActiveRideCubit>()
            .updateRideLocation(rideId, position.latitude, position.longitude);
      }
    });
  }

  Widget _buildMap(RideModel ride) {
    final List<Marker> markers = [
      Marker(
        point:
            LatLng(ride.pickupLocation.latitude, ride.pickupLocation.longitude),
        width: 60,
        height: 60,
        child: _buildMarker(Icons.my_location, Colors.blue),
      ),
      Marker(
        point: LatLng(
            ride.dropoffLocation.latitude, ride.dropoffLocation.longitude),
        width: 60,
        height: 60,
        child: _buildMarker(Icons.location_on, const Color(0xFFF35535)),
      ),
    ];

    if (ride.currentDriverLocation != null) {
      markers.add(Marker(
        point: LatLng(ride.currentDriverLocation!.latitude,
            ride.currentDriverLocation!.longitude),
        width: 60,
        height: 60,
        child: Transform.rotate(
          angle: _driverHeading * 0.017453292519943295,
          child: _buildMarker(Icons.directions_car, Colors.black87),
        ),
      ));
    }

    final List<LatLng> historyPoints =
        ride.pathPoints.map((p) => LatLng(p.latitude, p.longitude)).toList();

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: ride.currentDriverLocation != null
            ? LatLng(ride.currentDriverLocation!.latitude,
                ride.currentDriverLocation!.longitude)
            : LatLng(
                ride.pickupLocation.latitude, ride.pickupLocation.longitude),
        initialZoom: 16.5,
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
        if (historyPoints.isNotEmpty)
          PolylineLayer<Object>(
            polylines: [
              Polyline(
                points: historyPoints,
                color: Colors.grey.withValues(alpha: 0.5),
                strokeWidth: 3,
              ),
            ],
          ),
        if (_routePoints.isNotEmpty)
          PolylineLayer<Object>(
            polylines: [
              Polyline(
                points: _routePoints,
                color: const Color(0xFFF35535),
                strokeWidth: 4,
              ),
            ],
          ),
        MarkerLayer(markers: markers),
      ],
    );
  }

  Widget _buildMarker(IconData icon, Color color) {
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

  Widget _buildHeader(BuildContext context, RideModel ride) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildGlassIconButton(
            icon: Icons.arrow_back_ios_new,
            onTap: () => Navigator.pop(context),
          ),
          _buildGlassStatusBadge(ride),
        ],
      ),
    );
  }

  Widget _buildGlassIconButton(
      {required IconData icon, required VoidCallback onTap}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(50),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.black, size: 18),
            onPressed: onTap,
          ),
        ),
      ),
    );
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

  void _showDetailsModal(BuildContext context, RideModel ride) {
    final l10n = AppLocalizations.of(context)!;
    final isDriverView = widget.isDriver;
    final title = isDriverView ? 'Customer Details' : 'Driver Details';
    final name = isDriverView
        ? (ride.customerName ?? l10n.customer)
        : (ride.driverName ?? 'Driver');
    final phone = isDriverView
        ? ride.customerPhone
        : (ride.driverPhone ?? ride.customerPhone);

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
                        Text(
                          title,
                          style: const TextStyle(
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
                        // Profile Card
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
                                child: Icon(
                                  isDriverView ? Icons.person : Icons.directions_car,
                                  size: 28,
                                  color: const Color(0xFFF35535),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                          fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      phone ?? 'No phone provided',
                                      style: TextStyle(
                                          fontSize: 13, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ),
                              if (phone != null && phone.isNotEmpty)
                                ElevatedButton.icon(
                                  onPressed: () => _callCustomer(phone),
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

                        if (!isDriverView) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.blue.shade100),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.directions_car, color: Colors.blue.shade700, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'VEHICLE DETAILS',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue.shade800,
                                          letterSpacing: 1),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      ride.fullVehicleName,
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.black87,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        ride.formattedPlate,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            letterSpacing: 1.2),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Text(
                                      'Type: ${ride.vehicleType.toUpperCase()}',
                                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      '•  Color: ${ride.formattedColor}',
                                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

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

  Widget _buildMapControl({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
    Color? backgroundColor,
    Color? iconColor,
  }) {
    return Tooltip(
      message: tooltip,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: backgroundColor ?? Colors.white.withValues(alpha: 0.85),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(50),
                child: Center(
                  child: Icon(icon, color: iconColor ?? Colors.black87, size: 20),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassStatusBadge(RideModel ride) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _getStatusIcon(ride.status),
              const SizedBox(width: 8),
              Text(
                ride.status.name.toUpperCase(),
                style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getStatusIcon(RideStatus status) {
    IconData icon;
    Color color;
    switch (status) {
      case RideStatus.pending:
        icon = Icons.timer_outlined;
        color = Colors.orange;
        break;
      case RideStatus.accepted:
        icon = Icons.check_circle_outline;
        color = Colors.blue;
        break;
      case RideStatus.arrived:
        icon = Icons.directions_car;
        color = Colors.purple;
        break;
      case RideStatus.started:
        icon = Icons.local_taxi;
        color = Colors.green;
        break;
      case RideStatus.arrivedAtDestination:
        icon = Icons.receipt_long;
        color = Colors.orangeAccent;
        break;
      case RideStatus.completed:
        icon = Icons.done_all;
        color = Colors.green;
        break;
      case RideStatus.cancelled:
        icon = Icons.cancel_outlined;
        color = Colors.red;
        break;
    }
    return Icon(icon, size: 16, color: color);
  }

  Widget _buildBottomPanel(BuildContext context, RideModel ride) {
    final isCheckout = ride.status == RideStatus.arrivedAtDestination;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 20, spreadRadius: 5)
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 24),
            if (isCheckout) ...[
              // Gorgeous Premium Glassmorphism Checkout Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFF35535).withValues(alpha: 0.05),
                      const Color(0xFFF35535).withValues(alpha: 0.02)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xFFF35535).withValues(alpha: 0.15)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                          color: Color(0xFFF35535), shape: BoxShape.circle),
                      child: const Icon(Icons.receipt_long,
                          color: Colors.white, size: 36),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'TRIP TOTAL FARE',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 1),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${ride.totalFare} EGP',
                      style: const TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFF35535)),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 4)
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            ride.paymentMethod == 'card' && ride.paymentStatus == 'completed'
                                ? Icons.check_circle_outline
                                : Icons.info_outline,
                            color: ride.paymentMethod == 'card' && ride.paymentStatus == 'completed'
                                ? Colors.green
                                : const Color(0xFFF35535),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              ride.paymentMethod == 'card'
                                  ? (ride.paymentStatus == 'completed'
                                      ? (widget.isDriver
                                          ? 'Payment of ${ride.totalFare} EGP completed online via Card ✅.'
                                          : 'Thank you! Your payment of ${ride.totalFare} EGP was completed online via Card ✅.')
                                      : (widget.isDriver
                                          ? 'Passenger selected Card payment. Waiting for online confirmation...'
                                          : 'Please complete your ride payment online via Card below.'))
                                  : (widget.isDriver
                                      ? 'Please collect exactly ${ride.totalFare} EGP from the passenger. Once received, click Confirm Collection below.'
                                      : 'Thank you for riding with Z-SPEED! Please hand exactly ${ride.totalFare} EGP to the driver. They will confirm your payment.'),
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ] else ...[
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(16)),
                    child:
                        const Icon(Icons.person, color: Colors.grey, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isDriver
                              ? (ride.status == RideStatus.started
                                  ? 'TRIP IN PROGRESS'
                                  : 'HEADING TO PICKUP')
                              : _getCustomerStatusText(ride.status)
                                  .toUpperCase(),
                          style: const TextStyle(
                              color: Color(0xFFF35535),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1),
                        ),
                        Text(
                          widget.isDriver
                              ? (ride.customerName ?? 'Customer')
                              : '${ride.fullVehicleName} (${ride.vehicleType})',
                          style: const TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 17),
                        ),
                        if (widget.isDriver &&
                            ride.customerPhone != null &&
                            ride.customerPhone!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              ride.customerPhone!,
                              style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        if (_distanceKm != null && _durationMin != null)
                          Text(
                            '${_distanceKm!.toStringAsFixed(1)} km • $_durationMin mins',
                            style: const TextStyle(
                                color: Color(0xFFF35535),
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                            icon: Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                            ),
                            onPressed: () => _showDetailsModal(context, ride),
                          ),
                          Builder(builder: (context) {
                            final phone = widget.isDriver
                                ? ride.customerPhone
                                : (ride.driverPhone ?? ride.customerPhone);
                            if (phone == null || phone.isEmpty) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: IconButton(
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                icon: Container(
                                  padding: const EdgeInsets.all(9),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.phone, color: Colors.green.shade700, size: 20),
                                ),
                                onPressed: () => _callCustomer(phone),
                              ),
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${ride.totalFare} EGP',
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFF35535)),
                      ),
                      const Text('Total Price',
                          style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
            if (widget.isDriver)
              _buildDriverControls(context, ride)
            else
              _buildCustomerControls(context, ride),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverControls(BuildContext context, RideModel ride) {
    String buttonText = '';
    RideStatus nextStatus = RideStatus.completed;

    if (ride.status == RideStatus.accepted) {
      buttonText = 'I Have Arrived';
      nextStatus = RideStatus.arrived;
    } else if (ride.status == RideStatus.arrived) {
      buttonText = 'Customer Picked Up';
      nextStatus = RideStatus.started;
    } else if (ride.status == RideStatus.started) {
      buttonText = 'Arrived at Destination';
      nextStatus = RideStatus.arrivedAtDestination;
    } else if (ride.status == RideStatus.arrivedAtDestination) {
      if (ride.paymentMethod == 'card' && ride.paymentStatus != 'completed') {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Text(
              'Waiting for passenger online payment (بانتظار دفع الراكب بالفيزا)...',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
            ),
          ),
        );
      }
      return MyButton(
        text: ride.paymentMethod == 'card'
            ? 'Complete Trip (إنهاء الرحلة)'
            : 'Confirm Collection (تاكيد التحصيل)',
        backgroundColor: Colors.green,
        onPressed: () => context
            .read<ActiveRideCubit>()
            .updateStatus(ride.id, RideStatus.completed),
      );
    } else {
      return MyButton(
          text: 'Return Home', onPressed: () => Navigator.pop(context));
    }

    final mainButton = MyButton(
      text: buttonText,
      onPressed: () =>
          context.read<ActiveRideCubit>().updateStatus(ride.id, nextStatus),
    );

    return Row(
      children: [
        Expanded(child: mainButton),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          onPressed: () => _openGoogleMapsDirections(ride),
          icon: const Icon(Icons.navigation_rounded, size: 20),
          label: Text(
            AppLocalizations.of(context)?.startNavigation ?? 'Start Navigation',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF16A34A),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerControls(BuildContext context, RideModel ride) {
    if (ride.status == RideStatus.pending ||
        ride.status == RideStatus.accepted) {
      return MyButton(
        text: 'Cancel Ride',
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        foregroundColor: Colors.red,
        onPressed: () async {
          await context
              .read<ActiveRideCubit>()
              .cancelRide(ride.id, 'User cancelled');
          if (context.mounted) {
            Navigator.pop(context);
          }
        },
      );
    }
    if (ride.status == RideStatus.arrivedAtDestination) {
      if (ride.paymentMethod == 'card') {
        if (ride.paymentStatus == 'completed') {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'Payment Completed Online ✅ (تم الدفع بالفيزا بنجاح)',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ),
          );
        }

        return MyButton(
          text: 'Pay Fare Online with Card (ادفع الآن بالفيزا)',
          backgroundColor: const Color(0xFFF35535),
          onPressed: () async {
            try {
              final paylink = PaylinkDatasource();
              final res = await paylink.initCheckout(rideId: ride.id);
              final checkoutUrl = res['checkoutUrl'] as String;
              final invoiceId = (res['invoiceId'] as num).toInt();

              if (!context.mounted) return;
              final result = await Navigator.push<PaylinkWebviewResult>(
                context,
                MaterialPageRoute(
                  builder: (_) => PaylinkWebviewPage(
                    checkoutUrl: checkoutUrl,
                    expectedInvoiceId: invoiceId,
                  ),
                ),
              );

              if (result != null && result.success && context.mounted) {
                await PaymentStatusSheet.show(
                  context: context,
                  type: PaymentStatusType.success,
                  transactionReference: invoiceId.toString(),
                );
              } else if (context.mounted && result != null && !result.success) {
                await PaymentStatusSheet.show(
                  context: context,
                  type: PaymentStatusType.failure,
                  rawReason: result.message,
                );
              }
            } catch (e) {
              if (context.mounted) {
                await PaymentStatusSheet.show(
                  context: context,
                  type: PaymentStatusType.failure,
                  rawReason: e.toString(),
                );
              }
            }
          },
        );
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16)),
        child: const Center(
          child: Text(
            'Waiting for driver to confirm cash receipt...',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
          ),
        ),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
          color: Colors.grey[50], borderRadius: BorderRadius.circular(16)),
      child: const Center(
        child: Text(
          'Tracking your journey...',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
        ),
      ),
    );
  }

  String _getCustomerStatusText(RideStatus status) {
    switch (status) {
      case RideStatus.pending:
        return 'Looking for driver...';
      case RideStatus.accepted:
        return 'Driver is on the way!';
      case RideStatus.arrived:
        return 'Driver has arrived at pickup!';
      case RideStatus.started:
        return 'Heading to destination...';
      case RideStatus.arrivedAtDestination:
        return 'Arrived! Payment pending.';
      case RideStatus.completed:
        return 'Trip completed!';
      case RideStatus.cancelled:
        return 'Trip cancelled!';
    }
  }
}
