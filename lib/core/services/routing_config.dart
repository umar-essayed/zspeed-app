/// Configuration for free routing services
/// Replace the placeholder keys with your actual API keys
class RoutingConfig {
  static const String tileUrl = 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const List<String> tileSubdomains = ['a', 'b', 'c'];
  static const String userAgentPackageName = 'com.zspeed.app';

  // OpenRouteService - Free tier: 2,000 requests/day
  // Get your free API key at: https://openrouteservice.org/dev/#/signup
  static const String openRouteServiceKey =
      'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6ImJkYWVhMTQ1ODFmZjQ5MzI4OWY1NDU4YWI3ODc5NjZlIiwiaCI6Im11cm11cjY0In0=';

  // GraphHopper - Free tier: 1,000 requests/day
  // Get your free API key at: https://graphhopper.com/api/1/docs/
  static const String graphHopperKey = 'YOUR_GRAPHHOPPER_KEY';

  // Mapbox - Free tier: 100,000 requests/month
  // Get your free API key at: https://account.mapbox.com/access-tokens/
  static const String mapboxKey =
      'pk.eyJ1IjoibWFuYXJhYmRlbGhhbGltMTM4IiwiYSI6ImNtcTc0dHZjNzA3NjMyc3M5ZXd4bXVzMjkifQ.A6xPzDCgUjER56d7wF07qQ';

  // Enable/disable specific providers (useful for testing or cost control)
  static const bool enableOpenRouteService = true;
  static const bool enableGraphHopper = true;
  static const bool enableMapbox = true;
  static const bool enableOSRM = true; // Completely free, no API key needed
  static const bool enableValhalla = true; // Completely free, no API key needed
  static const bool enableStraightLineFallback =
      false; // Disabled by default - only real routing

  // Request timeout settings (in seconds)
  static const int requestTimeout = 10;
  static const int maxRetries = 2;

  // Default travel mode
  static const String defaultTravelMode = 'driving';

  // Route optimization settings
  static const bool avoidTolls = true;
  static const bool avoidHighways = false;
  static const bool avoidFerries = true;

  /// Get the primary routing provider based on configuration
  static String get primaryProvider {
    if (enableOpenRouteService &&
        openRouteServiceKey != 'YOUR_OPENROUTE_SERVICE_KEY') {
      return 'openrouteservice';
    } else if (enableMapbox && mapboxKey != 'YOUR_MAPBOX_KEY') {
      return 'mapbox';
    } else if (enableGraphHopper && graphHopperKey != 'YOUR_GRAPHHOPPER_KEY') {
      return 'graphhopper';
    } else {
      return 'straightline';
    }
  }

  /// Check if any routing provider is properly configured
  static bool get hasConfiguredProvider {
    return (enableOpenRouteService &&
            openRouteServiceKey != 'YOUR_OPENROUTE_SERVICE_KEY') ||
        (enableGraphHopper && graphHopperKey != 'YOUR_GRAPHHOPPER_KEY') ||
        (enableMapbox && mapboxKey != 'YOUR_MAPBOX_KEY');
  }

  /// Get list of available providers
  static List<String> get availableProviders {
    final providers = <String>[];

    if (enableOpenRouteService &&
        openRouteServiceKey != 'YOUR_OPENROUTE_SERVICE_KEY') {
      providers.add('openrouteservice');
    }
    if (enableGraphHopper && graphHopperKey != 'YOUR_GRAPHHOPPER_KEY') {
      providers.add('graphhopper');
    }
    if (enableMapbox && mapboxKey != 'YOUR_MAPBOX_KEY') {
      providers.add('mapbox');
    }
    if (enableOSRM) {
      providers.add('osrm');
    }
    if (enableValhalla) {
      providers.add('valhalla');
    }
    if (enableStraightLineFallback) {
      providers.add('straightline');
    }

    return providers;
  }
}
