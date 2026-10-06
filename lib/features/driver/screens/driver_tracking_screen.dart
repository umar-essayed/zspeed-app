import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:z_speed/features/order/model/order.dart';
import 'package:z_speed/core/enums/order_enums.dart';
import 'package:z_speed/features/auth/model/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:z_speed/features/restaurant/model/restaurant.dart';
import 'package:z_speed/features/driver/cubit/driver_dashboard_cubit.dart';
import 'package:z_speed/features/driver/cubit/driver_dashboard_state.dart';
import 'package:z_speed/l10n/app_localizations.dart';
import 'package:z_speed/core/errors/failure_localization_ext.dart';
import 'package:z_speed/core/services/routing_service.dart';
import 'package:z_speed/core/services/routing_config.dart';
import 'package:z_speed/features/shared/widgets/navigation/in_app_navigation_overlay.dart';

class DriverTrackingScreen extends StatefulWidget {
  final Order order;

  const DriverTrackingScreen({
    super.key,
    required this.order,
  });

  @override
  State<DriverTrackingScreen> createState() => _DriverTrackingScreenState();
}

class _DriverTrackingScreenState extends State<DriverTrackingScreen> with WidgetsBindingObserver {
  final MapController _mapController = MapController();

  StreamSubscription<Position>? _positionStream;
  LatLng? _currentDriverLocation;
  double _driverHeading = 0.0;

  LatLng? _targetLocation;
  Color _targetColor = Colors.red;
  bool _isLoadingTarget = true;
  String _targetName = '';
  String _targetAddress = '';
  bool _isPermissionGranted = true;
  bool _isPermanentlyDenied = false;

  final List<Marker> _markers = [];
  final List<Polyline> _polylines = [];
  DirectionsData? _directionsData;

  bool _isTrackingDriver = true;

  // In-app Navigation State
  bool _inNavigationMode = false;
  List<RouteStep> _navigationSteps = [];
  int _currentStepIndex = 0;
  double _currentSpeed = 0.0; // in m/s
  final double _speedLimit = 60.0; // in km/h
  bool _hasFittedInitialBounds = false;

  static const Color _primaryColor = Color(0xFFF35535);

  late Order _currentOrder;
  bool _orderSeenInStream = false;
  bool _isPopping = false;

  AppUser? _customerUser;
  Restaurant? _restaurant;

  Future<void> _fetchCustomerDetails() async {
    try {
      final customerId = _currentOrder.customerId;
      if (customerId.isEmpty) return;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(customerId)
          .get();
      if (doc.exists && mounted) {
        final customer = AppUser.fromMap(doc.data()!, doc.id);
        setState(() {
          _customerUser = customer;
          if (_currentOrder.status != OrderStatus.driverAssigned &&
              _currentOrder.status != OrderStatus.preparing &&
              _currentOrder.status != OrderStatus.ready) {
            _targetName = customer.name;
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching customer details: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentOrder = widget.order;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _resolveTargetCoordinates();
        _startLocationTracking();
      }
    });
  }

  Future<void> _resolveTargetCoordinates() async {
    _fetchCustomerDetails();

    debugPrint('[DriverTracking] _resolveTargetCoordinates: orderId=${_currentOrder.id}, status=${_currentOrder.status}, restaurantId=${_currentOrder.restaurantId}, customerId=${_currentOrder.customerId}');

    if (_currentOrder.status == OrderStatus.driverAssigned ||
        _currentOrder.status == OrderStatus.preparing ||
        _currentOrder.status == OrderStatus.ready) {
      // Heading to Restaurant
      try {
        if (_currentOrder.restaurantId.isEmpty) {
          debugPrint('[DriverTracking] RestaurantId is empty!');
          if (mounted) {
            setState(() {
              _isLoadingTarget = false;
            });
          }
          return;
        }
        final doc = await FirebaseFirestore.instance
            .collection('vendors')
            .doc(_currentOrder.restaurantId)
            .get();
        debugPrint('[DriverTracking] Restaurant doc query completed. Exists: ${doc.exists}');
        if (doc.exists && mounted) {
          final restaurant = Restaurant.fromMap(doc.data()!, doc.id);
          setState(() {
            _restaurant = restaurant;
            _targetLocation = LatLng(restaurant.latitude, restaurant.longitude);
            _targetColor = Colors.orange;
            _targetName = restaurant.name;
            _targetAddress = restaurant.address;
            _isLoadingTarget = false;
          });
          _updateMap(); // trigger map redraw
        } else {
          debugPrint('[DriverTracking] Restaurant doc does not exist!');
          if (mounted) {
            setState(() {
              _isLoadingTarget = false;
            });
          }
        }
      } catch (e) {
        debugPrint('[DriverTracking] Error resolving restaurant coordinates: $e');
        if (mounted) {
          setState(() {
            _isLoadingTarget = false;
          });
        }
      }
    } else {
      // Heading to Customer
      if (mounted) {
        setState(() {
          _targetLocation =
              LatLng(_currentOrder.deliveryLat, _currentOrder.deliveryLng);
          _targetColor = Colors.green;
          _targetName = _customerUser?.name ?? AppLocalizations.of(context)!.customer;
          _targetAddress = _currentOrder.deliveryAddress;
          _isLoadingTarget = false;
        });
        _updateMap();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAndResumeTracking();
    }
  }

  Future<void> _checkAndResumeTracking() async {
    if (_positionStream == null) {
      final permission = await Geolocator.checkPermission();
      if (!mounted) return;
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        debugPrint('[DriverTracking] App resumed with location permissions. Restarting tracking.');
        
        final profile = context.read<DriverDashboardCubit>().state.driverProfile;
        final isUsingFallback = _currentDriverLocation == _targetLocation ||
            (profile != null &&
                _currentDriverLocation?.latitude == profile.currentLat &&
                _currentDriverLocation?.longitude == profile.currentLng);

        if (isUsingFallback) {
          setState(() {
            _currentDriverLocation = null;
          });
        }
        
        _startLocationTracking();
      }
    }
  }

  void _processPositionUpdate(Position position) {
    final newLoc = LatLng(position.latitude, position.longitude);
    final double heading = position.heading;
    final double speed = position.speed; // speed in meters per second

    double distanceMoved = 0.0;
    if (_currentDriverLocation != null) {
      distanceMoved = Geolocator.distanceBetween(
        _currentDriverLocation!.latitude,
        _currentDriverLocation!.longitude,
        position.latitude,
        position.longitude,
      );
    }

    // Ignore micro GPS position jitter (< 1.5 meters) when updating location
    if (_currentDriverLocation == null || distanceMoved >= 1.5) {
      _currentDriverLocation = newLoc;
    }

    // Determine target heading with noise filtering
    double targetHeading = _driverHeading;
    final bool isGpsHeadingValid = heading > 0 && !heading.isNaN && (speed > 0.8 || distanceMoved >= 2.0);

    if (isGpsHeadingValid) {
      targetHeading = heading;
    } else if (distanceMoved >= 3.0 && _currentDriverLocation != null) {
      targetHeading = Geolocator.bearingBetween(
        _currentDriverLocation!.latitude,
        _currentDriverLocation!.longitude,
        position.latitude,
        position.longitude,
      );
    } else if (_driverHeading == 0.0 && _targetLocation != null) {
      targetHeading = Geolocator.bearingBetween(
        newLoc.latitude,
        newLoc.longitude,
        _targetLocation!.latitude,
        _targetLocation!.longitude,
      );
    }

    if (targetHeading < 0) {
      targetHeading = (targetHeading % 360 + 360) % 360;
    }

    // Smooth heading transition to eliminate shaking
    final double diff = (targetHeading - _driverHeading + 540) % 360 - 180;
    if (diff.abs() > 3.0) {
      _driverHeading = (_driverHeading + diff * 0.3 + 360) % 360;
    }

    if (_isTrackingDriver && _currentDriverLocation != null) {
      try {
        final currentZoom = _mapController.camera.zoom;
        final targetZoom = math.max(currentZoom, 16.5);
        _mapController.move(_currentDriverLocation!, targetZoom);
      } catch (_) {}
    }
  }

  Future<void> _startLocationTracking() async {
    try {
      if (_positionStream != null) {
        await _positionStream!.cancel();
        _positionStream = null;
      }

      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint(
            '[DriverTracking] Location services disabled, using fallback');
        _useFallbackLocation();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        debugPrint(
            '[DriverTracking] Location permission denied, using fallback');
        setState(() {
          _isPermissionGranted = false;
          _isPermanentlyDenied = false;
        });
        _useFallbackLocation();
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint(
            '[DriverTracking] Location permission permanently denied, using fallback');
        setState(() {
          _isPermissionGranted = false;
          _isPermanentlyDenied = true;
        });
        _useFallbackLocation();
        return;
      }

      // Upgrade permission to "Always Allow" progressively for background tracking
      if (permission == LocationPermission.whileInUse) {
        await Geolocator.requestPermission();
        if (!mounted) return;
        permission = await Geolocator.checkPermission();
      }

      setState(() {
        _isPermissionGranted = true;
        _isPermanentlyDenied = false;
      });

      // Try to get an initial position quickly
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        ).timeout(const Duration(seconds: 5));

        if (mounted) {
          setState(() {
            _processPositionUpdate(position);
          });
          _updateMap();
          
          // Upload initial location immediately so RTDB / Firestore are in sync
          context.read<DriverDashboardCubit>().uploadLocation(
                position.latitude,
                position.longitude,
              );
        }
      } catch (e) {
        debugPrint(
            '[DriverTracking] Initial position failed: $e, using fallback');
        _useFallbackLocation();
      }

      if (!mounted) return;
      LocationSettings locationSettings;
      if (Theme.of(context).platform == TargetPlatform.android) {
        locationSettings = AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 1,
          intervalDuration: const Duration(seconds: 1),
          foregroundNotificationConfig: const ForegroundNotificationConfig(
            notificationText: "Z-SPEED Driver tracking is active.",
            notificationTitle: "Tracking Location",
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

      _positionStream =
          Geolocator.getPositionStream(locationSettings: locationSettings)
              .listen(
        (Position position) {
          if (mounted) {
            setState(() {
              _processPositionUpdate(position);
              _updateMap();
            });
            context.read<DriverDashboardCubit>().uploadLocation(
                  position.latitude,
                  position.longitude,
                );
          }
        },
        onError: (e) {
          debugPrint('[DriverTracking] Position stream error: $e');
          if (_currentDriverLocation == null) _useFallbackLocation();
        },
      );
    } catch (e) {
      debugPrint('[DriverTracking] Location tracking failed: $e');
      _useFallbackLocation();
    }
  }

  /// Fallback: use driver's stored location from Firestore, or the target location
  void _useFallbackLocation() {
    if (_currentDriverLocation != null) return;

    try {
      final state = context.read<DriverDashboardCubit>().state;
      final profile = state.driverProfile;
      if (profile != null &&
          profile.currentLat != null &&
          profile.currentLng != null &&
          profile.currentLat != 0.0) {
        if (mounted) {
          setState(() {
            _currentDriverLocation =
                LatLng(profile.currentLat!, profile.currentLng!);
          });
          _updateMap();
          return;
        }
      }
    } catch (_) {}

    // Last resort: use target location so the map at least renders
    if (_targetLocation != null && mounted) {
      setState(() {
        _currentDriverLocation = _targetLocation;
      });
      _updateMap();
    }
  }

  Future<void> _updateMap() async {
    if (_currentDriverLocation == null) return;

    if (_driverHeading == 0.0 && _targetLocation != null) {
      _driverHeading = Geolocator.bearingBetween(
        _currentDriverLocation!.latitude,
        _currentDriverLocation!.longitude,
        _targetLocation!.latitude,
        _targetLocation!.longitude,
      );
      if (_driverHeading < 0) {
        _driverHeading = (_driverHeading % 360 + 360) % 360;
      }
    }

    // Auto center and rotate map when in navigation mode
    if (_inNavigationMode && _isTrackingDriver) {
      _mapController.move(_currentDriverLocation!, 17.5);
      _mapController.rotate(360 - _driverHeading);
    }

    _markers.clear();
    _markers.add(
      Marker(
        point: _currentDriverLocation!,
        width: 40,
        height: 40,
        child: Transform.rotate(
          angle: _driverHeading * (math.pi / 180),
          child: const Icon(Icons.navigation, color: Colors.blue, size: 30),
        ),
      ),
    );

    // Target Location
    if (_targetLocation != null) {
      _markers.add(
        Marker(
          point: _targetLocation!,
          width: 40,
          height: 40,
          child: Icon(Icons.location_on, color: _targetColor, size: 30),
        ),
      );

      // Only draw polyline if not already computed to avoid redundant API calls
      if (_directionsData == null || _polylines.isEmpty) {
        await _drawPolyline(_currentDriverLocation!, _targetLocation!);
      } else if (_inNavigationMode) {
        // Update progress when real GPS updates arrive
        _updateNavigationProgress(_currentDriverLocation!);
      }
    }
  }

  Future<void> _drawPolyline(LatLng origin, LatLng destination) async {
    try {
      debugPrint('[DriverTracking] Fetching route from LocationIQ...');
      final result =
          await RoutingService.instance.getDirections(origin, destination);

      if (result != null && mounted) {
        setState(() {
          _directionsData = result;
          _navigationSteps = result.steps;
          _polylines.clear();
          _polylines.add(
            Polyline(
              points: result.points,
              color: _primaryColor,
              strokeWidth: 5,
            ),
          );
        });
        if (!_inNavigationMode) {
          _fitMapToBounds(result.points);
        }
        return;
      }
    } catch (e) {
      debugPrint('[DriverTracking] LocationIQ failed: $e');
    }

    // Fallback: Draw straight line
    debugPrint('[DriverTracking] Route API failed, drawing straight line');
    _drawStraightLine(origin, destination);
  }

  /// Fallback: draw a solid straight line between origin and destination
  void _drawStraightLine(LatLng origin, LatLng destination) {
    if (!mounted) return;
    final distanceMeters = Geolocator.distanceBetween(
      origin.latitude,
      origin.longitude,
      destination.latitude,
      destination.longitude,
    );
    // 40 km/h = 11.11 m/s
    final durationSeconds = distanceMeters / 11.11;
    final fallbackData = DirectionsData(
      points: [origin, destination],
      distanceMeters: distanceMeters,
      durationSeconds: durationSeconds,
      steps: RoutingService.generateStepsFromPoints([origin, destination]),
    );
    setState(() {
      _directionsData = fallbackData;
      _navigationSteps = fallbackData.steps;
      _polylines.clear();
      _polylines.add(
        Polyline(
          points: [origin, destination],
          color: _primaryColor,
          strokeWidth: 5,
        ),
      );
    });
    if (!_inNavigationMode) {
      _fitMapToBounds([origin, destination]);
    }
  }

  void _fitMapToBounds(List<LatLng> points) {
    if (points.isEmpty) return;
    if (_hasFittedInitialBounds && _isTrackingDriver) return;

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
          padding: const EdgeInsets.all(32.0),
        ),
      );
      _hasFittedInitialBounds = true;
    } catch (e) {
      debugPrint('[DriverTracking] fitCamera failed: $e');
    }
  }

  // ── IN-APP NAVIGATION METHODS ──
  void _enterInAppNavigation() {
    if (_currentDriverLocation == null || _targetLocation == null) return;
    
    if (_directionsData != null) {
      setState(() {
        _navigationSteps = _directionsData!.steps;
        if (_navigationSteps.isEmpty) {
          _navigationSteps = RoutingService.generateStepsFromPoints(_directionsData!.points);
        }
      });
    }

    setState(() {
      _inNavigationMode = true;
      _currentStepIndex = 0;
      _isTrackingDriver = true;
      _currentSpeed = 0.0;
    });

    _mapController.move(_currentDriverLocation!, 17.5);
    _mapController.rotate(360 - _driverHeading);
  }

  void _exitInAppNavigation() {
    setState(() {
      _inNavigationMode = false;
      _currentSpeed = 0.0;
      _isTrackingDriver = true;
    });
    _mapController.rotate(0.0);
    if (_directionsData != null) {
      _fitMapToBounds(_directionsData!.points);
    }
  }

  void _updateNavigationProgress(LatLng currentLoc) {
    if (_navigationSteps.isEmpty) {
      if (_directionsData != null) {
        _navigationSteps = _directionsData!.steps;
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

    if (_directionsData != null && _directionsData!.points.isNotEmpty) {
      final drift = _getDistanceToPolyline(currentLoc, _directionsData!.points);
      if (drift > 50.0) {
        debugPrint('[DriverNavigation] Driver drifted $drift meters off route. Re-routing...');
        _reRoute();
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

  Future<void> _reRoute() async {
    if (_currentDriverLocation == null || _targetLocation == null) return;
    final directions = await RoutingService.instance.getDirections(
      _currentDriverLocation!,
      _targetLocation!,
    );
    if (directions != null && mounted) {
      setState(() {
        _directionsData = directions;
        _navigationSteps = directions.steps;
        _currentStepIndex = 0;
        
        _polylines.clear();
        _polylines.add(
          Polyline(
            points: directions.points,
            color: _primaryColor,
            strokeWidth: 5.0,
          ),
        );
      });
    }
  }

  void _showNavigationSelector() {
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
                  AppLocalizations.of(context)!.startNavigation,
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
                  _enterInAppNavigation();
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
                  _openGoogleMapsNavigation();
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isHeadingToRestaurant =
        _currentOrder.status == OrderStatus.driverAssigned ||
        _currentOrder.status == OrderStatus.preparing ||
        _currentOrder.status == OrderStatus.ready;

    return BlocListener<DriverDashboardCubit, DriverDashboardState>(
        listener: (context, state) {
          if (_isPopping) return;

          if (state.hasError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.failure?.getLocalizedMessage(context) ??
                    AppLocalizations.of(context)!.errorOccurred),
                backgroundColor: Colors.red,
              ),
            );
            context.read<DriverDashboardCubit>().clearError();
          }

          // Direct delivery confirmation from cubit
          if (state.deliveredOrderId == widget.order.id) {
            _isPopping = true;
            Future.microtask(() {
              if (context.mounted) {
                context.read<DriverDashboardCubit>().clearDeliveredOrder();
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              }
            });
            return;
          }

          final latest = state.activeOrders
              .where((o) => o.id == widget.order.id)
              .firstOrNull;

          if (latest != null) {
            if (!_orderSeenInStream) {
              setState(() => _orderSeenInStream = true);
            }
            if (latest.status != _currentOrder.status || _currentOrder.customerId.isEmpty) {
              setState(() {
                _currentOrder = latest;
                _isLoadingTarget = true;
              });
              _resolveTargetCoordinates();
            } else {
              setState(() {
                _currentOrder = latest;
              });
            }
          } else if (_orderSeenInStream) {
            _isPopping = true;
            Future.microtask(() {
              if (context.mounted) {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              }
            });
          }
        },
        child: Scaffold(
          appBar: _inNavigationMode
              ? null
              : AppBar(
                  title: Text(isHeadingToRestaurant
                      ? AppLocalizations.of(context)!.headingToRestaurant
                      : AppLocalizations.of(context)!.headingToCustomer),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 1,
                ),
          body: Column(
            children: [
              Expanded(
                child: _currentDriverLocation == null || _isLoadingTarget
                    ? const Center(child: CircularProgressIndicator())
                    : Stack(
                        children: [
                          FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: _currentDriverLocation!,
                              initialZoom: 16.5,
                              onMapReady: () {
                                _updateMap();
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
                              PolylineLayer(polylines: _polylines),
                              MarkerLayer(markers: _markers),
                            ],
                          ),
                          // Map controls
                          if (!_inNavigationMode)
                            PositionedDirectional(
                              end: 12,
                              bottom: 16,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Start Navigation button
                                  _buildMapButton(
                                    icon: Icons.navigation_rounded,
                                    color: const Color(0xFF16A34A),
                                    iconColor: Colors.white,
                                    tooltip: AppLocalizations.of(context)!
                                        .startNavigation,
                                    onTap: _showNavigationSelector,
                                  ),
                                  const SizedBox(height: 10),
                                  // Re-center button
                                  _buildMapButton(
                                    icon: Icons.my_location,
                                    tooltip: AppLocalizations.of(context)!.reCenter,
                                    color: _isTrackingDriver ? _primaryColor : null,
                                    iconColor: _isTrackingDriver ? Colors.white : null,
                                    onTap: () {
                                      setState(() => _isTrackingDriver = true);
                                      if (_currentDriverLocation != null) {
                                        _mapController.move(
                                            _currentDriverLocation!, 16.5);
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  // Zoom In
                                  _buildMapButton(
                                    icon: Icons.add,
                                    tooltip: AppLocalizations.of(context)!.zoomIn,
                                    onTap: () {
                                      final currentZoom =
                                          _mapController.camera.zoom;
                                      _mapController.move(
                                          _mapController.camera.center,
                                          currentZoom + 1);
                                    },
                                  ),
                                  const SizedBox(height: 2),
                                  // Zoom Out
                                  _buildMapButton(
                                    icon: Icons.remove,
                                    tooltip:
                                        AppLocalizations.of(context)!.zoomOut,
                                    onTap: () {
                                      final currentZoom =
                                          _mapController.camera.zoom;
                                      _mapController.move(
                                          _mapController.camera.center,
                                          currentZoom - 1);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          // Resume Center button for Navigation Mode
                          if (_inNavigationMode && !_isTrackingDriver)
                            Positioned(
                              right: 16,
                              bottom: 150,
                              child: FloatingActionButton.extended(
                                backgroundColor: _primaryColor,
                                foregroundColor: Colors.white,
                                onPressed: () {
                                  setState(() {
                                    _isTrackingDriver = true;
                                  });
                                  if (_currentDriverLocation != null) {
                                    _mapController.move(_currentDriverLocation!, 17.5);
                                    _mapController.rotate(360 - _driverHeading);
                                  }
                                },
                                icon: const Icon(Icons.my_location),
                                label: Text(AppLocalizations.of(context)!.reCenter),
                              ),
                            ),
                          // In-App Navigation Overlay
                          if (_inNavigationMode)
                            InAppNavigationOverlay(
                              isNavigationActive: _inNavigationMode,
                              nextStep: _navigationSteps.isNotEmpty && _currentStepIndex < _navigationSteps.length
                                  ? _navigationSteps[_currentStepIndex]
                                  : null,
                              distanceToNextStep: _navigationSteps.isNotEmpty && _currentStepIndex < _navigationSteps.length
                                  ? Geolocator.distanceBetween(
                                      _currentDriverLocation!.latitude,
                                      _currentDriverLocation!.longitude,
                                      _navigationSteps[_currentStepIndex].location.latitude,
                                      _navigationSteps[_currentStepIndex].location.longitude,
                                    )
                                  : 0.0,
                              totalRemainingDistance: _directionsData != null
                                  ? _calculateRemainingDistance(
                                      _currentDriverLocation!,
                                      _directionsData!.points,
                                      _findClosestRoutePointIndex(_currentDriverLocation!, _directionsData!.points),
                                    )
                                  : 0.0,
                              totalRemainingDuration: _directionsData != null
                                  ? (_calculateRemainingDistance(
                                      _currentDriverLocation!,
                                      _directionsData!.points,
                                      _findClosestRoutePointIndex(_currentDriverLocation!, _directionsData!.points),
                                    ) / 11.0)
                                  : 0.0,
                              currentSpeed: _currentSpeed,
                              speedLimit: _speedLimit,
                              onExitNavigation: _exitInAppNavigation,
                            ),
                        ],
                      ),
              ),
              if (!_inNavigationMode)
                _buildBottomActionPanel(isHeadingToRestaurant),
            ],
          ),
        ));
  }

  Widget _buildMapButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color? color,
    Color? iconColor,
  }) {
    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(10),
      color: color ?? Colors.white,
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

  void _openGoogleMapsNavigation() {
    if (_targetLocation == null) return;
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${_targetLocation!.latitude},${_targetLocation!.longitude}'
      '&travelmode=driving',
    );
    launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color.withValues(alpha: 0.1),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Map<String, String> _parseAddressDetails(String address) {
    final Map<String, String> details = {};
    final typeIndex = address.indexOf('(');
    if (typeIndex != -1) {
      details['Type'] = address.substring(0, typeIndex).trim();
    }
    final startParenthesis = address.indexOf('(');
    final endParenthesis = address.indexOf(')');
    if (startParenthesis != -1 && endParenthesis != -1 && endParenthesis > startParenthesis) {
      final innerText = address.substring(startParenthesis + 1, endParenthesis);
      final parts = innerText.split(RegExp(r'[,،]'));
      for (var part in parts) {
        final kv = part.split(':');
        if (kv.length >= 2) {
          final key = kv[0].trim();
          final val = kv.sublist(1).join(':').trim();
          details[key] = val;
        }
      }
    }
    final areaIndex = address.indexOf(RegExp(r'\)\.\s*(?:Area|المنطقة)\s*:'));
    if (areaIndex != -1) {
      final labelIndex = address.indexOf(':', areaIndex);
      if (labelIndex != -1) {
        details['Area'] = address.substring(labelIndex + 1).trim();
      }
    }
    return details;
  }

  String? _extractPhoneFromAddress(String address) {
    final phoneRegex = RegExp(r'(?:Phone:|هاتف:)\s*([+\d\s-]+)');
    final match = phoneRegex.firstMatch(address);
    if (match != null) {
      final phone = match.group(1)?.trim();
      if (phone != null) {
        final cleanPhone = phone.split(')').first.split(',').first.split('،').first.trim();
        if (cleanPhone.isNotEmpty) {
          return cleanPhone;
        }
      }
    }
    return null;
  }

  Future<void> _callNumber(String phoneNumber) async {
    final Uri url = Uri(scheme: 'tel', path: phoneNumber);
    try {
      await launchUrl(url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.couldNotCall(phoneNumber, e.toString()))),
        );
      }
    }
  }

  void _callCustomer() {
    final phone = (_customerUser?.phone?.isNotEmpty == true ? _customerUser?.phone : null) ??
        _currentOrder.customerPhone ??
        _extractPhoneFromAddress(_currentOrder.deliveryAddress);
    if (phone != null && phone.isNotEmpty) {
      _callNumber(phone);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)?.errorOccurred ?? 'Customer phone number not available')),
      );
    }
  }

  void _showOrderDetailsBottomSheet() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final parsedAddress = _parseAddressDetails(_currentOrder.deliveryAddress);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
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
                          l10n.orderDetails,
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
                        _buildSummaryCard(theme, l10n),
                        const SizedBox(height: 16),
                        _buildCustomerDetailsCard(theme, l10n, parsedAddress),
                        const SizedBox(height: 16),
                        if (_restaurant != null) ...[
                          _buildRestaurantDetailsCard(theme, l10n),
                          const SizedBox(height: 16),
                        ],
                        _buildItemsCard(theme, l10n),
                        const SizedBox(height: 16),
                        _buildPaymentCard(theme, l10n),
                        const SizedBox(height: 24),
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

  Widget _buildSummaryCard(ThemeData theme, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ID: ${_currentOrder.id.substring(0, 8).toUpperCase()}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Created: ${_formatTime(_currentOrder.createdAt)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              _currentOrder.status.getLocalizedLabel(l10n),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: theme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildCustomerDetailsCard(
    ThemeData theme,
    AppLocalizations l10n,
    Map<String, String> parsedAddress,
  ) {
    final customerPhone = (_customerUser?.phone?.isNotEmpty == true ? _customerUser?.phone : null) ??
        _currentOrder.customerPhone ??
        _extractPhoneFromAddress(_currentOrder.deliveryAddress) ??
        '';
    final customerName = (_customerUser?.name.isNotEmpty == true ? _customerUser?.name : null) ??
        _currentOrder.customerName ??
        l10n.customer;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  l10n.customer,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        customerPhone.isNotEmpty ? customerPhone : 'No phone number provided',
                        style: TextStyle(
                          color: customerPhone.isNotEmpty ? Colors.grey.shade600 : Colors.red.shade400,
                          fontSize: 13,
                          fontStyle: customerPhone.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.phone, color: customerPhone.isNotEmpty ? Colors.green : Colors.grey),
                  onPressed: () {
                    if (customerPhone.isNotEmpty) {
                      _callNumber(customerPhone);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppLocalizations.of(context)!.customerPhoneNotAvailable)),
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Delivery Address',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 6),
            if (parsedAddress.isNotEmpty) ...[
              ...parsedAddress.entries.map((entry) {
                final localizedKey = _localizeAddressKey(entry.key, l10n);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 100,
                        child: Text(
                          '$localizedKey:',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ] else ...[
              Text(
                _currentOrder.deliveryAddress,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 13,
                ),
              ),
            ],
            if (_currentOrder.customerNote != null && _currentOrder.customerNote!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade100),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.note_alt_outlined, color: Colors.orange, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Note: ${_currentOrder.customerNote}',
                        style: TextStyle(
                          color: Colors.orange.shade900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _localizeAddressKey(String key, AppLocalizations l10n) {
    final lowerKey = key.toLowerCase();
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    if (lowerKey.contains('building') || lowerKey.contains('مبنى')) {
      return isAr ? 'مبنى' : 'Building';
    }
    if (lowerKey.contains('apt') || lowerKey.contains('apartment') || lowerKey.contains('شقة')) {
      return isAr ? 'شقة' : 'Apartment';
    }
    if (lowerKey.contains('floor') || lowerKey.contains('دور')) {
      return isAr ? 'دور' : 'Floor';
    }
    if (lowerKey.contains('street') || lowerKey.contains('شارع')) {
      return isAr ? 'شارع' : 'Street';
    }
    if (lowerKey.contains('landmark') || lowerKey.contains('علامة')) {
      return isAr ? 'علامة مميزة' : 'Landmark';
    }
    if (lowerKey.contains('phone') || lowerKey.contains('هاتف')) {
      return isAr ? 'هاتف' : 'Phone';
    }
    if (lowerKey.contains('area') || lowerKey.contains('منطقة')) {
      return isAr ? 'المنطقة' : 'Area';
    }
    if (lowerKey.contains('type')) {
      return isAr ? 'النوع' : 'Type';
    }
    return key;
  }

  Widget _buildRestaurantDetailsCard(ThemeData theme, AppLocalizations l10n) {
    if (_restaurant == null) return const SizedBox.shrink();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.restaurant, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  l10n.restaurant,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _restaurant!.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      if (_restaurant!.phone.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          _restaurant!.phone,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (_restaurant!.phone.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.phone, color: Colors.orange),
                    onPressed: () => _callNumber(_restaurant!.phone),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _restaurant!.address,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsCard(ThemeData theme, AppLocalizations l10n) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shopping_bag_outlined, color: theme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  l10n.itemsInOrder,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _currentOrder.items.length,
              separatorBuilder: (context, index) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final item = _currentOrder.items[index];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${item.quantity}x',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          if (item.optionsSummary != null && item.optionsSummary!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              item.optionsSummary!,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Text(
                      l10n.egpAmount(item.totalPrice.toStringAsFixed(2)),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(ThemeData theme, AppLocalizations l10n) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.payment, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  l10n.paymentDetails,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Payment Method',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                Text(
                  _currentOrder.paymentMethod.getLocalizedLabel(l10n),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Payment Status',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                Text(
                  _currentOrder.paymentStatus.getLocalizedLabel(l10n),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  l10n.egpAmount(_currentOrder.total.toStringAsFixed(2)),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: theme.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActionPanel(bool isHeadingToRestaurant) {
    return BlocBuilder<DriverDashboardCubit, DriverDashboardState>(
      builder: (context, state) {
        final isBusy = state.isBusy;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isHeadingToRestaurant
                          ? Colors.orange.shade50
                          : Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isHeadingToRestaurant ? Icons.restaurant : Icons.person,
                      color:
                          isHeadingToRestaurant ? Colors.orange : Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _targetName.isEmpty ? 'Loading...' : _targetName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _targetAddress.isEmpty ? '...' : _targetAddress,
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    icon: Icons.phone,
                    color: const Color(0xFF16A34A),
                    tooltip: AppLocalizations.of(context)!.callCustomer,
                    onTap: _callCustomer,
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    icon: Icons.info_outline,
                    color: Colors.blue,
                    tooltip: AppLocalizations.of(context)!.viewDetails,
                    onTap: _showOrderDetailsBottomSheet,
                  ),
                ],
              ),
              if (!_isPermissionGranted) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade100),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_off, color: Colors.red.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _isPermanentlyDenied
                              ? AppLocalizations.of(context)!.locationPermissionPermanentlyDenied
                              : AppLocalizations.of(context)!.locationPermissionDenied,
                          style: TextStyle(
                            color: Colors.red.shade900,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () async {
                          if (_isPermanentlyDenied) {
                            await Geolocator.openAppSettings();
                          } else {
                            _startLocationTracking();
                          }
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.red.shade100,
                          foregroundColor: Colors.red.shade900,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          _isPermanentlyDenied
                              ? AppLocalizations.of(context)!.settings
                              : AppLocalizations.of(context)!.retry,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (_directionsData != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Row(
                    children: [
                      // ETA Column
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF35535).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.access_time_filled_rounded,
                                color: Color(0xFFF35535),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.etaLabel,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  AppLocalizations.of(context)!.etaMinutes(_directionsData!.etaMinutes.toString()),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Divider
                      Container(
                        height: 30,
                        width: 1,
                        color: Colors.grey.shade200,
                      ),
                      // Distance Column
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.directions_rounded,
                                color: Colors.blue,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.distanceLabel,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  AppLocalizations.of(context)!.distanceKm(_directionsData!.distanceKm.toStringAsFixed(1)),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
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
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isBusy
                      ? null
                      : () async {
                          final cubit = context.read<DriverDashboardCubit>();
                          if (isHeadingToRestaurant) {
                            cubit.markPickedUp(_currentOrder.id);
                          } else {
                            final l10n = AppLocalizations.of(context)!;
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text(l10n.confirmDelivery),
                                content: Text(l10n.confirmDeliveryProceed),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(false),
                                    child: Text(l10n.cancel),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(true),
                                    child: Text(l10n.confirm),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true) {
                              cubit.markDelivered(_currentOrder.id);
                            }
                          }
                        },
                  icon: Icon(isHeadingToRestaurant
                      ? Icons.location_on
                      : Icons.verified),
                  label: Text(isHeadingToRestaurant
                      ? AppLocalizations.of(context)!.arrivedAtRestaurant
                      : AppLocalizations.of(context)!.orderReceivedByCustomer),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isHeadingToRestaurant
                        ? const Color(0xFFF35535)
                        : Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
