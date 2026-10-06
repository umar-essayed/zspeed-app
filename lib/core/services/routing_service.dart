import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:z_speed/core/services/routing_config.dart';

enum TravelMode { driving, walking, bicycling, transit }

/// Free routing service that provides alternatives to Google's routing API
/// Supports multiple providers with automatic fallback
class RoutingService {
  static RoutingService? _instance;
  static RoutingService get instance {
    _instance ??= RoutingService._();
    return _instance!;
  }

  RoutingService._();

  String get apiKey => '';

  /// Tile URL for flutter_map TileLayer (PNG with subdomains).
  /// Switched to CartoDB Voyager styling which requires no key.
  String get tileUrlPng =>
      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png';

  List<String> get tileSubdomains => const ['a', 'b', 'c', 'd'];

  /// Tile URL for flutter_map TileLayer (simple PNG, no subdomains).
  String get tileUrl =>
      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png';

  /// Premium Minimalist Light map layer
  String get premiumLightTileUrl =>
      'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png';

  /// Premium Sleek Dark map layer
  String get premiumDarkTileUrl =>
      'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';

  /// Premium Colorful Voyager map layer
  String get premiumVoyagerTileUrl =>
      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png';

  /// Reverse geocode: coordinates → display name.
  Future<String?> reverseGeocode(double lat, double lng, {int? zoom}) async {
    try {
      final result = await reverseGeocodeDetailed(lat, lng, zoom: zoom ?? 18);
      return result?.displayName;
    } catch (_) {
      return null;
    }
  }

  /// Reverse geocode with full result (address parts, etc).
  Future<LocationIQReverseResult?> reverseGeocodeDetailed(
    double lat,
    double lng, {
    int zoom = 18,
  }) async {
    // 1. Try Mapbox geocoding if enabled and configured
    if (RoutingConfig.enableMapbox &&
        RoutingConfig.mapboxKey != 'YOUR_MAPBOX_KEY' &&
        RoutingConfig.mapboxKey.isNotEmpty) {
      try {
        final url = Uri.parse(
          'https://api.mapbox.com/geocoding/v5/mapbox.places/$lng,$lat.json?access_token=${RoutingConfig.mapboxKey}',
        );
        final response = await http
            .get(url)
            .timeout(const Duration(seconds: RoutingConfig.requestTimeout));
        if (response.statusCode == 200) {
          final data = json.decode(response.body) as Map<String, dynamic>;
          return _parseMapboxGeocode(data);
        }
      } catch (_) {}
    }

    // 2. Try OpenRouteService geocoding if enabled and configured
    if (RoutingConfig.enableOpenRouteService &&
        RoutingConfig.openRouteServiceKey != 'YOUR_OPENROUTE_SERVICE_KEY' &&
        RoutingConfig.openRouteServiceKey.isNotEmpty) {
      try {
        final url = Uri.parse(
          'https://api.openrouteservice.org/geocode/reverse?api_key=${RoutingConfig.openRouteServiceKey}&point.lat=$lat&point.lon=$lng&size=1',
        );
        final response = await http
            .get(url)
            .timeout(const Duration(seconds: RoutingConfig.requestTimeout));
        if (response.statusCode == 200) {
          final data = json.decode(response.body) as Map<String, dynamic>;
          return _parseORSGeocode(data);
        }
      } catch (_) {}
    }

    // 3. Fallback to free OpenStreetMap Nominatim
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lng&addressdetails=1&zoom=$zoom',
      );
      final response = await http
          .get(url, headers: {'User-Agent': 'Z-SPEED App (com.zspeed.app)'})
          .timeout(const Duration(seconds: RoutingConfig.requestTimeout));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final displayName = data['display_name'] as String? ?? '';
        final addressJson = data['address'] as Map<String, dynamic>? ?? {};
        return LocationIQReverseResult(
          displayName: displayName,
          address: LocationIQAddress.fromJson(addressJson),
        );
      }
    } catch (_) {}

    return null;
  }

  /// Autocomplete search suggestions.
  Future<List<LocationIQAutocompleteResult>> autocomplete(
    String query, {
    int limit = 5,
    String? tag,
  }) async {
    // 1. Try Mapbox forward geocoding if enabled and configured
    if (RoutingConfig.enableMapbox &&
        RoutingConfig.mapboxKey != 'YOUR_MAPBOX_KEY' &&
        RoutingConfig.mapboxKey.isNotEmpty) {
      try {
        final url = Uri.parse(
          'https://api.mapbox.com/geocoding/v5/mapbox.places/${Uri.encodeComponent(query)}.json?access_token=${RoutingConfig.mapboxKey}&limit=$limit',
        );
        final response = await http
            .get(url)
            .timeout(const Duration(seconds: RoutingConfig.requestTimeout));
        if (response.statusCode == 200) {
          final data = json.decode(response.body) as Map<String, dynamic>;
          return _parseMapboxAutocomplete(data);
        }
      } catch (_) {}
    }

    // 2. Try OpenRouteService forward geocoding if enabled and configured
    if (RoutingConfig.enableOpenRouteService &&
        RoutingConfig.openRouteServiceKey != 'YOUR_OPENROUTE_SERVICE_KEY' &&
        RoutingConfig.openRouteServiceKey.isNotEmpty) {
      try {
        final url = Uri.parse(
          'https://api.openrouteservice.org/geocode/search?api_key=${RoutingConfig.openRouteServiceKey}&text=${Uri.encodeComponent(query)}&size=$limit',
        );
        final response = await http
            .get(url)
            .timeout(const Duration(seconds: RoutingConfig.requestTimeout));
        if (response.statusCode == 200) {
          final data = json.decode(response.body) as Map<String, dynamic>;
          return _parseORSAutocomplete(data);
        }
      } catch (_) {}
    }

    // 3. Fallback to free OpenStreetMap Nominatim
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=jsonv2&addressdetails=1&limit=$limit',
      );
      final response = await http
          .get(url, headers: {'User-Agent': 'Z-SPEED App (com.zspeed.app)'})
          .timeout(const Duration(seconds: RoutingConfig.requestTimeout));
      if (response.statusCode == 200) {
        final list = json.decode(response.body) as List;
        return list.map<LocationIQAutocompleteResult>((item) {
          final map = item as Map<String, dynamic>;
          final addressJson = map['address'] as Map<String, dynamic>? ?? {};
          return LocationIQAutocompleteResult(
            displayName: map['display_name'] as String? ?? '',
            lat: map['lat']?.toString() ?? '',
            lon: map['lon']?.toString() ?? '',
            address: LocationIQAddress.fromJson(addressJson),
          );
        }).toList();
      }
    } catch (_) {}

    return [];
  }

  /// Get driving directions and return route points + distance + duration.
  Future<DirectionsData?> getDirections(
    LatLng origin,
    LatLng destination,
  ) async {
    return getRouteBetweenCoordinates(
      startLat: origin.latitude,
      startLng: origin.longitude,
      endLat: destination.latitude,
      endLng: destination.longitude,
    );
  }

  void dispose() {
    // No-op for singleton service to maintain stable instance reference
  }

  /// Retry a function with exponential backoff
  /// Only retries on timeout or network errors, not on API errors
  static Future<T> _retryWithBackoff<T>({
    required Future<T> Function() operation,
    int maxRetries = 2,
    Duration initialDelay = const Duration(milliseconds: 500),
  }) async {
    int attempt = 0;
    while (true) {
      try {
        return await operation();
      } catch (e) {
        attempt++;

        // Don't retry if we've exceeded max retries
        if (attempt > maxRetries) {
          rethrow;
        }

        // Don't retry on API errors (these won't succeed on retry)
        // Only retry on timeout or network errors
        final errorString = e.toString().toLowerCase();
        if (errorString.contains('api error') ||
            errorString.contains('statuscode') ||
            errorString.contains('400') ||
            errorString.contains('401') ||
            errorString.contains('403') ||
            errorString.contains('404') ||
            errorString.contains('not configured')) {
          rethrow;
        }

        // Exponential backoff: delay = initialDelay * 2^(attempt-1)
        final delay = Duration(
          milliseconds: initialDelay.inMilliseconds * (1 << (attempt - 1)),
        );
        await Future.delayed(delay);
      }
    }
  }

  /// Get route between coordinates using free services with fallback
  static Future<DirectionsData?> getRouteBetweenCoordinates({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    TravelMode mode = TravelMode.driving,
  }) async {
    // Try real routing providers first (in order of preference)
    final realRoutingProviders = [
      'openrouteservice',
      'graphhopper',
      'mapbox',
      'osrm',
      'valhalla',
    ];

    for (final provider in realRoutingProviders) {
      try {
        DirectionsData? result;
        switch (provider) {
          case 'openrouteservice':
            if (RoutingConfig.enableOpenRouteService) {
              result = await _retryWithBackoff(
                operation: () =>
                    _getRouteFromOpenRouteService(
                      startLat,
                      startLng,
                      endLat,
                      endLng,
                      mode,
                    ).timeout(
                      const Duration(seconds: RoutingConfig.requestTimeout),
                    ),
                maxRetries: RoutingConfig.maxRetries,
              );
            }
            break;
          case 'graphhopper':
            if (RoutingConfig.enableGraphHopper) {
              result = await _retryWithBackoff(
                operation: () =>
                    _getRouteFromGraphHopper(
                      startLat,
                      startLng,
                      endLat,
                      endLng,
                      mode,
                    ).timeout(
                      const Duration(seconds: RoutingConfig.requestTimeout),
                    ),
                maxRetries: RoutingConfig.maxRetries,
              );
            }
            break;
          case 'mapbox':
            if (RoutingConfig.enableMapbox) {
              result = await _retryWithBackoff(
                operation: () =>
                    _getRouteFromMapbox(
                      startLat,
                      startLng,
                      endLat,
                      endLng,
                      mode,
                    ).timeout(
                      const Duration(seconds: RoutingConfig.requestTimeout),
                    ),
                maxRetries: RoutingConfig.maxRetries,
              );
            }
            break;
          case 'osrm':
            if (RoutingConfig.enableOSRM) {
              result = await _retryWithBackoff(
                operation: () =>
                    _getRouteFromOSRM(
                      startLat,
                      startLng,
                      endLat,
                      endLng,
                      mode,
                    ).timeout(
                      const Duration(seconds: RoutingConfig.requestTimeout),
                    ),
                maxRetries: RoutingConfig.maxRetries,
              );
            }
            break;
          case 'valhalla':
            if (RoutingConfig.enableValhalla) {
              result = await _retryWithBackoff(
                operation: () =>
                    _getRouteFromValhalla(
                      startLat,
                      startLng,
                      endLat,
                      endLng,
                      mode,
                    ).timeout(
                      const Duration(seconds: RoutingConfig.requestTimeout),
                    ),
                maxRetries: RoutingConfig.maxRetries,
              );
            }
            break;
        }
        if (result != null) {
          return result;
        }
      } catch (e) {
        continue; // Try next provider
      }
    }

    // Final fallback: simple straight-line route
    return _getStraightLineRoute(startLat, startLng, endLat, endLng);
  }

  /// OpenRouteService routing (free tier: 2,000 requests/day)
  static Future<DirectionsData?> _getRouteFromOpenRouteService(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
    TravelMode mode,
  ) async {
    if (RoutingConfig.openRouteServiceKey == 'YOUR_OPENROUTE_SERVICE_KEY') {
      throw Exception('OpenRouteService API key not configured');
    }

    final String profile = _getOpenRouteServiceProfile(mode);
    final String url =
        'https://api.openrouteservice.org/v2/directions/$profile/geojson';

    final client = http.Client();
    try {
      final response = await client
          .post(
            Uri.parse(url),
            headers: {
              'Authorization': RoutingConfig.openRouteServiceKey,
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'coordinates': [
                [startLng, startLat],
                [endLng, endLat],
              ],
              'format': 'geojson',
              'options': {
                'avoid_features': ['tollways', 'ferries'],
                'profile_params': {
                  'weightings': {'green': 0.1, 'quiet': 0.1},
                },
              },
            }),
          )
          .timeout(const Duration(seconds: RoutingConfig.requestTimeout));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseOpenRouteServiceResponse(data);
      } else {
        throw Exception('OpenRouteService API error: ${response.statusCode}');
      }
    } finally {
      client.close();
    }
  }

  /// GraphHopper routing (free tier: 1,000 requests/day)
  static Future<DirectionsData?> _getRouteFromGraphHopper(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
    TravelMode mode,
  ) async {
    if (RoutingConfig.graphHopperKey == 'YOUR_GRAPHHOPPER_KEY') {
      throw Exception('GraphHopper API key not configured');
    }

    final String profile = _getGraphHopperProfile(mode);
    const String url = 'https://graphhopper.com/api/1/route';

    final client = http.Client();
    try {
      final response = await client
          .get(
            Uri.parse(
              '$url?point=$startLat,$startLng&point=$endLat,$endLng&profile=$profile&key=${RoutingConfig.graphHopperKey}&instructions=false&calc_points=true',
            ),
          )
          .timeout(const Duration(seconds: RoutingConfig.requestTimeout));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseGraphHopperResponse(data);
      } else {
        throw Exception('GraphHopper API error: ${response.statusCode}');
      }
    } finally {
      client.close();
    }
  }

  /// Mapbox routing (free tier: 100,000 requests/month)
  static Future<DirectionsData?> _getRouteFromMapbox(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
    TravelMode mode,
  ) async {
    if (RoutingConfig.mapboxKey == 'YOUR_MAPBOX_KEY') {
      throw Exception('Mapbox API key not configured');
    }

    final String profile = _getMapboxProfile(mode);
    final String url =
        'https://api.mapbox.com/directions/v5/mapbox/$profile/$startLng,$startLat;$endLng,$endLat';

    final client = http.Client();
    try {
      final response = await client
          .get(
            Uri.parse(
              '$url?access_token=${RoutingConfig.mapboxKey}&geometries=polyline&overview=full&steps=true',
            ),
          )
          .timeout(const Duration(seconds: RoutingConfig.requestTimeout));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseMapboxResponse(data);
      } else {
        throw Exception('Mapbox API error: ${response.statusCode}');
      }
    } finally {
      client.close();
    }
  }

  /// OSRM routing (completely free, no API key needed)
  static Future<DirectionsData?> _getRouteFromOSRM(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
    TravelMode mode,
  ) async {
    final String profile = _getOSRMProfile(mode);
    final String url =
        'https://router.project-osrm.org/route/v1/$profile/$startLng,$startLat;$endLng,$endLat';

    final client = http.Client();
    try {
      final response = await client
          .get(Uri.parse('$url?overview=full&geometries=polyline&steps=true'))
          .timeout(const Duration(seconds: RoutingConfig.requestTimeout));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseOSRMResponse(data);
      } else {
        throw Exception('OSRM API error: ${response.statusCode}');
      }
    } finally {
      client.close();
    }
  }

  /// Valhalla routing (completely free, no API key needed)
  static Future<DirectionsData?> _getRouteFromValhalla(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
    TravelMode mode,
  ) async {
    final String profile = _getValhallaProfile(mode);
    const String url = 'https://valhalla1.openstreetmap.de/route';

    final client = http.Client();
    try {
      final response = await client
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'locations': [
                {'lat': startLat, 'lon': startLng},
                {'lat': endLat, 'lon': endLng},
              ],
              'costing': profile,
              'directions_options': {'units': 'kilometers'},
              'shape_match': 'edge_walk',
              'filters': {
                'attributes': ['edge.distance', 'edge.speed', 'edge.duration'],
              },
            }),
          )
          .timeout(const Duration(seconds: RoutingConfig.requestTimeout));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseValhallaResponse(data);
      } else {
        throw Exception('Valhalla API error: ${response.statusCode}');
      }
    } finally {
      client.close();
    }
  }

  /// Fallback: Simple straight-line route
  static DirectionsData _getStraightLineRoute(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    final distance = Geolocator.distanceBetween(
      startLat,
      startLng,
      endLat,
      endLng,
    );
    final duration = (distance / 1000) * 60; // Assume 60 km/h average speed
    final points = [LatLng(startLat, startLng), LatLng(endLat, endLng)];

    return DirectionsData(
      points: points,
      distanceMeters: distance,
      durationSeconds: duration,
      steps: generateStepsFromPoints(points),
    );
  }

  /// Parse OpenRouteService response
  static DirectionsData _parseOpenRouteServiceResponse(
    Map<String, dynamic> data,
  ) {
    final features = data['features'] as List;
    if (features.isEmpty) {
      throw Exception('No route found');
    }

    final feature = features.first;
    final geometry = feature['geometry'];
    final coordinates = geometry['coordinates'] as List;
    final properties = feature['properties'];
    final summary = properties['summary'];

    final points = <LatLng>[];
    for (final coord in coordinates) {
      if (coord != null && coord is List && coord.length >= 2) {
        final lng = coord[0]?.toDouble() ?? 0.0;
        final lat = coord[1]?.toDouble() ?? 0.0;
        points.add(LatLng(lat, lng)); // Note: OpenRouteService uses [lng, lat]
      }
    }

    final distance = (summary['distance'] as num).toDouble();
    final duration = (summary['duration'] as num).toDouble();

    return DirectionsData(
      points: points,
      distanceMeters: distance,
      durationSeconds: duration,
      steps: generateStepsFromPoints(points),
    );
  }

  /// Parse GraphHopper response
  static DirectionsData _parseGraphHopperResponse(Map<String, dynamic> data) {
    final paths = data['paths'] as List;
    if (paths.isEmpty) {
      throw Exception('No route found');
    }

    final path = paths.first;
    final points = path['points'] as String;
    final distance = (path['distance'] as num).toDouble();
    final time = (path['time'] as num).toDouble();

    // Decode polyline
    final decodedPoints = _decodePolyline(points);

    return DirectionsData(
      points: decodedPoints,
      distanceMeters: distance,
      durationSeconds: time / 1000,
      steps: generateStepsFromPoints(decodedPoints),
    );
  }

  /// Parse Mapbox response
  static DirectionsData _parseMapboxResponse(Map<String, dynamic> data) {
    final routes = data['routes'] as List;
    if (routes.isEmpty) {
      throw Exception('No route found');
    }

    final route = routes.first;
    final geometry = route['geometry'] as String;
    final distance = (route['distance'] as num).toDouble();
    final duration = (route['duration'] as num).toDouble();

    // Decode polyline
    final decodedPoints = _decodePolyline(geometry);

    // Parse steps if available
    List<RouteStep> parsedSteps = _parseOSRMSteps(route);
    if (parsedSteps.isEmpty) {
      parsedSteps = generateStepsFromPoints(decodedPoints);
    }

    return DirectionsData(
      points: decodedPoints,
      distanceMeters: distance,
      durationSeconds: duration,
      steps: parsedSteps,
    );
  }

  /// Parse OSRM response
  static DirectionsData _parseOSRMResponse(Map<String, dynamic> data) {
    final routes = data['routes'] as List;
    if (routes.isEmpty) {
      throw Exception('No route found');
    }

    final route = routes.first;
    final geometry = route['geometry'] as String;
    final distance = (route['distance'] as num).toDouble();
    final duration = (route['duration'] as num).toDouble();

    // Decode polyline
    final decodedPoints = _decodePolyline(geometry);

    // Parse steps if available
    List<RouteStep> parsedSteps = _parseOSRMSteps(route);
    if (parsedSteps.isEmpty) {
      parsedSteps = generateStepsFromPoints(decodedPoints);
    }

    return DirectionsData(
      points: decodedPoints,
      distanceMeters: distance,
      durationSeconds: duration,
      steps: parsedSteps,
    );
  }

  /// Parse Valhalla response
  static DirectionsData _parseValhallaResponse(Map<String, dynamic> data) {
    final trip = data['trip'];
    if (trip == null) {
      throw Exception('No route found');
    }

    final legs = trip['legs'] as List;
    if (legs.isEmpty) {
      throw Exception('No route found');
    }

    final leg = legs.first;
    final distance =
        (leg['summary']['length'] as num).toDouble() *
        1000; // Convert km to meters
    final duration = (leg['summary']['time'] as num).toDouble();

    // Get shape points
    final shape = trip['shape'] as String;
    final decodedPoints = _decodePolyline(shape);

    return DirectionsData(
      points: decodedPoints,
      distanceMeters: distance,
      durationSeconds: duration,
      steps: generateStepsFromPoints(decodedPoints),
    );
  }

  /// Helper to generate simulated route steps from a list of polyline points (e.g. for offline fallbacks)
  static List<RouteStep> generateStepsFromPoints(List<LatLng> points) {
    final steps = <RouteStep>[];
    if (points.isEmpty) return steps;

    steps.add(
      RouteStep(
        location: points.first,
        instruction: 'Depart and head toward your destination',
        maneuver: 'depart',
        distanceMeters: 0.0,
        durationSeconds: 0.0,
      ),
    );

    if (points.length < 3) {
      steps.add(
        RouteStep(
          location: points.last,
          instruction: 'Arrive at destination',
          maneuver: 'arrive',
          distanceMeters: 100.0,
          durationSeconds: 10.0,
        ),
      );
      return steps;
    }

    double accumDistance = 0.0;
    double accumDuration = 0.0;
    double lastBearing = Geolocator.bearingBetween(
      points[0].latitude,
      points[0].longitude,
      points[1].latitude,
      points[1].longitude,
    );

    for (int i = 1; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final dist = Geolocator.distanceBetween(
        p1.latitude,
        p1.longitude,
        p2.latitude,
        p2.longitude,
      );
      accumDistance += dist;
      accumDuration += dist / 11.0; // Assume ~40 km/h average speed (11 m/s)

      final currentBearing = Geolocator.bearingBetween(
        p1.latitude,
        p1.longitude,
        p2.latitude,
        p2.longitude,
      );

      double diff = currentBearing - lastBearing;
      diff = (diff + 180) % 360 - 180;

      if (diff.abs() > 25.0 && accumDistance > 50.0) {
        String instruction;
        String maneuver;
        if (diff < -45.0) {
          instruction = 'Sharp left turn';
          maneuver = 'sharp_left';
        } else if (diff < -25.0) {
          instruction = 'Turn left';
          maneuver = 'left';
        } else if (diff > 45.0) {
          instruction = 'Sharp right turn';
          maneuver = 'sharp_right';
        } else {
          instruction = 'Turn right';
          maneuver = 'right';
        }

        steps.add(
          RouteStep(
            location: p1,
            instruction: instruction,
            maneuver: maneuver,
            distanceMeters: accumDistance,
            durationSeconds: accumDuration,
          ),
        );

        accumDistance = 0.0;
        accumDuration = 0.0;
        lastBearing = currentBearing;
      }
    }

    steps.add(
      RouteStep(
        location: points.last,
        instruction: 'Arrive at destination',
        maneuver: 'arrive',
        distanceMeters: accumDistance,
        durationSeconds: accumDuration,
      ),
    );

    return steps;
  }

  /// Parser helper for OSRM/Mapbox JSON steps
  static List<RouteStep> _parseOSRMSteps(Map<String, dynamic> route) {
    final stepsList = <RouteStep>[];
    final legs = route['legs'] as List?;
    if (legs == null || legs.isEmpty) return stepsList;
    final firstLeg = legs.first;
    final steps = firstLeg['steps'] as List?;
    if (steps == null || steps.isEmpty) return stepsList;

    for (final step in steps) {
      final maneuverJson = step['maneuver'] as Map<String, dynamic>?;
      if (maneuverJson == null) continue;

      final locationJson = maneuverJson['location'] as List?;
      if (locationJson == null || locationJson.length < 2) continue;
      final lng = locationJson[0]?.toDouble() ?? 0.0;
      final lat = locationJson[1]?.toDouble() ?? 0.0;

      final type = maneuverJson['type'] as String? ?? 'turn';
      final modifier = maneuverJson['modifier'] as String? ?? 'straight';
      final name = step['name'] as String? ?? '';

      final distance = (step['distance'] as num?)?.toDouble() ?? 0.0;
      final duration = (step['duration'] as num?)?.toDouble() ?? 0.0;

      String instruction = maneuverJson['instruction'] as String? ?? '';
      if (instruction.isEmpty) {
        if (type == 'arrive') {
          instruction = 'Arrive at your destination';
        } else if (type == 'depart') {
          instruction =
              'Head toward ${name.isNotEmpty ? name : 'your destination'}';
        } else if (type == 'turn' || type == 'ramp' || type == 'merge') {
          final dir = modifier == 'left'
              ? 'left'
              : modifier == 'right'
              ? 'right'
              : modifier == 'sharp left'
              ? 'sharp left'
              : modifier == 'sharp right'
              ? 'sharp right'
              : modifier == 'slight left'
              ? 'slight left'
              : modifier == 'slight right'
              ? 'slight right'
              : 'straight';
          instruction = 'Turn $dir ${name.isNotEmpty ? 'onto $name' : ''}';
        } else {
          instruction = 'Continue ${name.isNotEmpty ? 'onto $name' : ''}';
        }
      }

      stepsList.add(
        RouteStep(
          location: LatLng(lat, lng),
          instruction: instruction,
          maneuver: type == 'arrive'
              ? 'arrive'
              : type == 'depart'
              ? 'depart'
              : modifier,
          distanceMeters: distance,
          durationSeconds: duration,
        ),
      );
    }
    return stepsList;
  }

  /// Decode polyline string to list of points
  static List<LatLng> _decodePolyline(String polyline) {
    final points = <LatLng>[];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < polyline.length) {
      int b, shift = 0, result = 0;
      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return points;
  }

  /// Get OpenRouteService profile based on travel mode
  static String _getOpenRouteServiceProfile(TravelMode mode) {
    switch (mode) {
      case TravelMode.driving:
        return 'driving-car';
      case TravelMode.walking:
        return 'foot-walking';
      case TravelMode.bicycling:
        return 'cycling-regular';
      case TravelMode.transit:
        return 'driving-car'; // OpenRouteService doesn't have transit, use driving
    }
  }

  /// Get GraphHopper profile based on travel mode
  static String _getGraphHopperProfile(TravelMode mode) {
    switch (mode) {
      case TravelMode.driving:
        return 'car';
      case TravelMode.walking:
        return 'foot';
      case TravelMode.bicycling:
        return 'bike';
      case TravelMode.transit:
        return 'car'; // GraphHopper doesn't have transit, use car
    }
  }

  /// Get Mapbox profile based on travel mode
  static String _getMapboxProfile(TravelMode mode) {
    switch (mode) {
      case TravelMode.driving:
        return 'driving';
      case TravelMode.walking:
        return 'walking';
      case TravelMode.bicycling:
        return 'cycling';
      case TravelMode.transit:
        return 'driving'; // Mapbox doesn't have transit, use driving
    }
  }

  /// Get OSRM profile based on travel mode
  static String _getOSRMProfile(TravelMode mode) {
    switch (mode) {
      case TravelMode.driving:
        return 'driving';
      case TravelMode.walking:
        return 'walking';
      case TravelMode.bicycling:
        return 'cycling';
      case TravelMode.transit:
        return 'driving'; // OSRM doesn't have transit, use driving
    }
  }

  /// Get Valhalla profile based on travel mode
  static String _getValhallaProfile(TravelMode mode) {
    switch (mode) {
      case TravelMode.driving:
        return 'auto';
      case TravelMode.walking:
        return 'pedestrian';
      case TravelMode.bicycling:
        return 'bicycle';
      case TravelMode.transit:
        return 'auto'; // Valhalla doesn't have transit, use auto
    }
  }

  /// Get distance between two points using Haversine formula
  static double calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const double earthRadius = 6371000; // Earth's radius in meters
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLng = _degreesToRadians(lng2 - lng1);
    final double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  static LocationIQReverseResult _parseMapboxGeocode(
    Map<String, dynamic> data,
  ) {
    final features = data['features'] as List?;
    if (features == null || features.isEmpty) {
      throw Exception('No results found');
    }
    final feature = features.first as Map<String, dynamic>;
    final displayName = feature['place_name'] as String? ?? '';
    final road = feature['text'] as String?;
    final houseNumber = feature['address'] as String?;

    String? neighbourhood;
    String? suburb;
    String? city;
    String? state;
    String? country;

    final context = feature['context'] as List?;
    if (context != null) {
      for (final item in context) {
        final id = item['id'] as String? ?? '';
        final text = item['text'] as String? ?? '';
        if (id.startsWith('neighborhood')) {
          neighbourhood = text;
        } else if (id.startsWith('locality')) {
          suburb = text;
        } else if (id.startsWith('place')) {
          city = text;
        } else if (id.startsWith('region')) {
          state = text;
        } else if (id.startsWith('country')) {
          country = text;
        }
      }
    }

    return LocationIQReverseResult(
      displayName: displayName,
      address: LocationIQAddress(
        road: road,
        neighbourhood: neighbourhood,
        suburb: suburb,
        city: city,
        state: state,
        country: country,
        houseNumber: houseNumber,
      ),
    );
  }

  static LocationIQReverseResult _parseORSGeocode(Map<String, dynamic> data) {
    final features = data['features'] as List?;
    if (features == null || features.isEmpty) {
      throw Exception('No results found');
    }
    final feature = features.first as Map<String, dynamic>;
    final props = feature['properties'] as Map<String, dynamic>? ?? {};

    final displayName =
        props['label'] as String? ?? props['name'] as String? ?? '';
    final road = props['street'] as String?;
    final houseNumber = props['housenumber'] as String?;
    final neighbourhood = props['neighbourhood'] as String?;
    final suburb = props['suburb'] as String? ?? props['locality'] as String?;
    final city =
        props['localadmin'] as String? ??
        props['city'] as String? ??
        props['county'] as String?;
    final state = props['region'] as String?;
    final country = props['country'] as String?;

    return LocationIQReverseResult(
      displayName: displayName,
      address: LocationIQAddress(
        road: road,
        neighbourhood: neighbourhood,
        suburb: suburb,
        city: city,
        state: state,
        country: country,
        houseNumber: houseNumber,
      ),
    );
  }

  static List<LocationIQAutocompleteResult> _parseMapboxAutocomplete(
    Map<String, dynamic> data,
  ) {
    final features = data['features'] as List?;
    if (features == null) return [];

    return features.map<LocationIQAutocompleteResult>((f) {
      final feature = f as Map<String, dynamic>;
      final displayName = feature['place_name'] as String? ?? '';
      final center = feature['center'] as List?;
      final lon = center != null && center.isNotEmpty
          ? center[0].toString()
          : '';
      final lat = center != null && center.length > 1
          ? center[1].toString()
          : '';

      final road = feature['text'] as String?;
      final houseNumber = feature['address'] as String?;

      String? neighbourhood;
      String? suburb;
      String? city;
      String? state;
      String? country;

      final context = feature['context'] as List?;
      if (context != null) {
        for (final item in context) {
          final id = item['id'] as String? ?? '';
          final text = item['text'] as String? ?? '';
          if (id.startsWith('neighborhood')) {
            neighbourhood = text;
          } else if (id.startsWith('locality')) {
            suburb = text;
          } else if (id.startsWith('place')) {
            city = text;
          } else if (id.startsWith('region')) {
            state = text;
          } else if (id.startsWith('country')) {
            country = text;
          }
        }
      }

      return LocationIQAutocompleteResult(
        displayName: displayName,
        lat: lat,
        lon: lon,
        address: LocationIQAddress(
          road: road,
          neighbourhood: neighbourhood,
          suburb: suburb,
          city: city,
          state: state,
          country: country,
          houseNumber: houseNumber,
        ),
      );
    }).toList();
  }

  static List<LocationIQAutocompleteResult> _parseORSAutocomplete(
    Map<String, dynamic> data,
  ) {
    final features = data['features'] as List?;
    if (features == null) return [];

    return features.map<LocationIQAutocompleteResult>((f) {
      final feature = f as Map<String, dynamic>;
      final geom = feature['geometry'] as Map<String, dynamic>? ?? {};
      final coordinates = geom['coordinates'] as List?;
      final lon = coordinates != null && coordinates.isNotEmpty
          ? coordinates[0].toString()
          : '';
      final lat = coordinates != null && coordinates.length > 1
          ? coordinates[1].toString()
          : '';

      final props = feature['properties'] as Map<String, dynamic>? ?? {};
      final displayName =
          props['label'] as String? ?? props['name'] as String? ?? '';

      final road = props['street'] as String?;
      final houseNumber = props['housenumber'] as String?;
      final neighbourhood = props['neighbourhood'] as String?;
      final suburb = props['suburb'] as String? ?? props['locality'] as String?;
      final city =
          props['localadmin'] as String? ??
          props['city'] as String? ??
          props['county'] as String?;
      final state = props['region'] as String?;
      final country = props['country'] as String?;

      return LocationIQAutocompleteResult(
        displayName: displayName,
        lat: lat,
        lon: lon,
        address: LocationIQAddress(
          road: road,
          neighbourhood: neighbourhood,
          suburb: suburb,
          city: city,
          state: state,
          country: country,
          houseNumber: houseNumber,
        ),
      );
    }).toList();
  }
}

class RouteStep {
  final LatLng location;
  final String instruction;
  final String
  maneuver; // 'left', 'right', 'straight', 'arrive', 'depart', etc.
  final double distanceMeters;
  final double durationSeconds;

  const RouteStep({
    required this.location,
    required this.instruction,
    required this.maneuver,
    required this.distanceMeters,
    required this.durationSeconds,
  });
}

class DirectionsData {
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;
  final List<RouteStep> steps;

  const DirectionsData({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
    this.steps = const [],
  });

  double get distanceKm => distanceMeters / 1000;
  int get etaMinutes => (durationSeconds / 60).ceil();
}

class LocationIQReverseResult {
  final String displayName;
  final LocationIQAddress address;

  LocationIQReverseResult({required this.displayName, required this.address});
}

class LocationIQAddress {
  final String? road;
  final String? neighbourhood;
  final String? suburb;
  final String? city;
  final String? state;
  final String? country;
  final String? houseNumber;

  LocationIQAddress({
    this.road,
    this.neighbourhood,
    this.suburb,
    this.city,
    this.state,
    this.country,
    this.houseNumber,
  });

  factory LocationIQAddress.fromJson(Map<String, dynamic> json) {
    return LocationIQAddress(
      road: json['road'] as String?,
      neighbourhood: json['neighbourhood'] as String?,
      suburb: json['suburb'] as String?,
      city:
          json['city'] as String? ??
          json['town'] as String? ??
          json['village'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      houseNumber: json['house_number'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'road': road,
    'neighbourhood': neighbourhood,
    'suburb': suburb,
    'city': city,
    'state': state,
    'country': country,
    'house_number': houseNumber,
  };
}

class LocationIQAutocompleteResult {
  final String displayName;
  final String lat;
  final String lon;
  final LocationIQAddress? address;

  LocationIQAutocompleteResult({
    required this.displayName,
    required this.lat,
    required this.lon,
    this.address,
  });
}
