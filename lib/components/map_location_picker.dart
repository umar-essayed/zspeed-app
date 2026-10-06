import 'package:z_speed/l10n/app_localizations.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:z_speed/core/services/routing_service.dart';
import 'package:z_speed/core/services/routing_config.dart';

class MapLocationPicker extends StatefulWidget {
  final LatLng? initialLocation;
  final String? initialAddress;
  final bool showRadiusPicker;
  final double initialRadiusKm;

  const MapLocationPicker({
    super.key,
    this.initialLocation,
    this.initialAddress,
    this.showRadiusPicker = false,
    this.initialRadiusKm = 10.0,
  });

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  LatLng? _currentCenter;
  String _currentAddress = '';
  String _shortAddress = '';
  String _areaInfo = '';
  bool _isLoadingAddress = false;
  bool _isLoadingMap = true;
  bool _isLocating = false;

  // Search state
  List<Map<String, dynamic>> _searchResults = const [];
  bool _isSearching = false;
  bool _showSearchResults = false;
  Timer? _debounceTimer;

  late double _radiusKm;

  @override
  void initState() {
    super.initState();
    _radiusKm = widget.initialRadiusKm;
    if (widget.initialLocation != null) {
      _currentCenter = widget.initialLocation;
      _currentAddress = widget.initialAddress ?? '';
      _isLoadingMap = false;
    } else {
      _determineInitialPosition();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_currentAddress.isEmpty) {
      if (widget.initialLocation != null) {
        _currentAddress =
            widget.initialAddress ??
            AppLocalizations.of(context)!.selectedLocation;
      } else {
        _currentAddress = AppLocalizations.of(context)!.loadingLocation;
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // ─── Location Detection ───────────────────────────────────────────

  Future<void> _determineInitialPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!mounted) return;
    if (!serviceEnabled) {
      _setDefaultLocation(
        AppLocalizations.of(context)!.locationServicesDisabled,
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (!mounted) return;
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (!mounted) return;
      if (permission == LocationPermission.denied) {
        _setDefaultLocation(
          AppLocalizations.of(context)!.locationPermissionDenied,
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _setDefaultLocation(
        AppLocalizations.of(context)!.locationPermissionPermanentlyDenied,
      );
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;
      setState(() {
        _currentCenter = LatLng(position.latitude, position.longitude);
        _isLoadingMap = false;
      });
      _fetchAddressForCenter();
    } catch (e) {
      if (!mounted) return;
      _setDefaultLocation(
        AppLocalizations.of(context)!.failedToGetCurrentLocation,
      );
    }
  }

  void _setDefaultLocation(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      setState(() {
        _currentCenter = const LatLng(30.0444, 31.2357);
        _isLoadingMap = false;
      });
      _fetchAddressForCenter();
    }
  }

  Future<void> _goToMyLocation() async {
    setState(() => _isLocating = true);
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;
      final newCenter = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentCenter = newCenter;
        _isLocating = false;
      });
      _mapController.move(newCenter, 18.0);
      _fetchAddressForCenter();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLocating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.couldNotDetectLocation),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  // ─── Search / Autocomplete ────────────────────────────────────────

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().length < 2) {
      setState(() {
        _searchResults = const [];
        _showSearchResults = false;
      });
      return;
    }
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      _searchAddress(query.trim());
    });
  }

  Future<void> _searchAddress(String query) async {
    setState(() => _isSearching = true);

    try {
      final results = await RoutingService.instance.autocomplete(
        query,
        limit: 5,
        tag:
            'place:city,place:town,place:village,place:suburb,place:neighbourhood,highway:residential,highway:primary,highway:secondary',
      );
      if (mounted) {
        setState(() {
          _searchResults = results
              .map(
                (r) => {
                  'lat': r.lat,
                  'lon': r.lon,
                  'display_name': r.displayName,
                  'address': r.address != null
                      ? {
                          'road': r.address!.road,
                          'suburb': r.address!.suburb,
                          'neighbourhood': r.address!.neighbourhood,
                          'city': r.address!.city,
                          'state': r.address!.state,
                          'country': r.address!.country,
                        }
                      : null,
                },
              )
              .toList();
          _showSearchResults = _searchResults.isNotEmpty;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _showSearchResults = false;
        });
      }
    }
  }

  void _selectSearchResult(Map<String, dynamic> result) {
    final lat = double.tryParse(result['lat']?.toString() ?? '');
    final lon = double.tryParse(result['lon']?.toString() ?? '');

    if (lat != null && lon != null) {
      final newCenter = LatLng(lat, lon);
      setState(() {
        _currentCenter = newCenter;
        _showSearchResults = false;
        _searchResults = const [];
        _searchController.clear();
      });
      _mapController.move(newCenter, 17.0);
      _fetchAddressForCenter();
    }

    FocusScope.of(context).unfocus();
  }

  // ─── Reverse Geocoding ────────────────────────────────────────────

  String _buildDetailedAddress(Map<String, dynamic> data) {
    final address = data['address'] as Map<String, dynamic>?;
    if (address == null) {
      return data['display_name'] as String? ?? 'Unknown location';
    }

    final parts = <String>[];

    final houseNumber = address['house_number'] as String?;
    final road = address['road'] as String?;
    if (road != null && road.isNotEmpty) {
      if (houseNumber != null && houseNumber.isNotEmpty) {
        parts.add('$houseNumber $road');
      } else {
        parts.add(road);
      }
    }

    final neighbourhood = address['neighbourhood'] as String?;
    final suburb = address['suburb'] as String?;
    final quarter = address['quarter'] as String?;
    final hamlet = address['hamlet'] as String?;
    final village = address['village'] as String?;

    final area = neighbourhood ?? suburb ?? quarter ?? hamlet ?? village;
    if (area != null && area.isNotEmpty && !parts.contains(area)) {
      parts.add(area);
    }

    final city = address['city'] as String?;
    final town = address['town'] as String?;
    final county = address['county'] as String?;
    final cityName = city ?? town ?? county;
    if (cityName != null && cityName.isNotEmpty && !parts.contains(cityName)) {
      parts.add(cityName);
    }

    final state = address['state'] as String?;
    if (state != null && state.isNotEmpty && !parts.contains(state)) {
      parts.add(state);
    }

    final country = address['country'] as String?;
    if (country != null && country.isNotEmpty) {
      parts.add(country);
    }

    if (parts.isEmpty) {
      return data['display_name'] as String? ?? 'Unknown location';
    }

    return parts.join(', ');
  }

  String _buildShortAddress(Map<String, dynamic> data) {
    final address = data['address'] as Map<String, dynamic>?;
    if (address == null) return '';

    final parts = <String>[];

    final road = address['road'] as String?;
    final houseNumber = address['house_number'] as String?;
    if (road != null && road.isNotEmpty) {
      if (houseNumber != null && houseNumber.isNotEmpty) {
        parts.add('$houseNumber $road');
      } else {
        parts.add(road);
      }
    }

    final neighbourhood = address['neighbourhood'] as String?;
    final suburb = address['suburb'] as String?;
    final quarter = address['quarter'] as String?;
    final area = neighbourhood ?? suburb ?? quarter;
    if (area != null && area.isNotEmpty && !parts.contains(area)) {
      parts.add(area);
    }

    return parts.join(' - ');
  }

  String _buildAreaInfo(Map<String, dynamic> data) {
    final address = data['address'] as Map<String, dynamic>?;
    if (address == null) return '';

    final parts = <String>[];

    final city = address['city'] as String?;
    final town = address['town'] as String?;
    final county = address['county'] as String?;
    final village = address['village'] as String?;
    final cityName = city ?? town ?? county ?? village;
    if (cityName != null && cityName.isNotEmpty) {
      parts.add(cityName);
    }

    final state = address['state'] as String?;
    if (state != null && state.isNotEmpty && state != cityName) {
      parts.add(state);
    }

    final country = address['country'] as String?;
    if (country != null && country.isNotEmpty) {
      parts.add(country);
    }

    return parts.join(', ');
  }

  Future<void> _fetchAddressForCenter() async {
    if (_currentCenter == null) return;

    setState(() => _isLoadingAddress = true);

    try {
      final result = await RoutingService.instance.reverseGeocodeDetailed(
        _currentCenter!.latitude,
        _currentCenter!.longitude,
        zoom: 18,
      );
      if (result != null && mounted) {
        final addressMap = result.address.toJson();
        final data = <String, dynamic>{
          'display_name': result.displayName,
          'address': addressMap,
        };
        setState(() {
          _currentAddress = _buildDetailedAddress(data);
          _shortAddress = _buildShortAddress(data);
          _areaInfo = _buildAreaInfo(data);
          _isLoadingAddress = false;
        });
      } else if (mounted) {
        setState(() {
          _currentAddress = 'Location info unavailable';
          _shortAddress = 'Location info unavailable';
          _areaInfo = '';
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentAddress = 'Error fetching address';
          _shortAddress = 'Error fetching address';
          _areaInfo = '';
          _isLoadingAddress = false;
        });
      }
    }
  }

  // ─── Build UI ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: _isLoadingMap
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFF35535)),
            )
          : Stack(
              children: [
                // ── Map ──
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentCenter!,
                    initialZoom: 17.0,
                    onPositionChanged: (position, hasGesture) {
                      if (hasGesture) {
                        _currentCenter = position.center;
                      }
                    },
                    onMapEvent: (event) {
                      if (event is MapEventMoveEnd) {
                        _fetchAddressForCenter();
                      }
                    },
                    onTap: (_, _) {
                      // Dismiss search when tapping map
                      setState(() => _showSearchResults = false);
                      FocusScope.of(context).unfocus();
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: RoutingConfig.tileUrl,
                      subdomains: RoutingConfig.tileSubdomains,
                      maxZoom: 20,
                      userAgentPackageName: RoutingConfig.userAgentPackageName,
                    ),
                    if (widget.showRadiusPicker && _currentCenter != null)
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: _currentCenter!,
                            radius: _radiusKm * 1000,
                            useRadiusInMeter: true,
                            color: const Color(0xFFF35535).withValues(alpha: 0.22),
                            borderColor: const Color(0xFFF35535),
                            borderStrokeWidth: 3.0,
                          ),
                        ],
                      ),
                  ],
                ),

                // ── Center pin ──
                Center(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(bottom: 44.0),
                    child: Icon(
                      Icons.location_on,
                      size: 50,
                      color: const Color(0xFFF35535),
                      shadows: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Search Bar + Results (top) ──
                _buildSearchOverlay(),

                // ── Zoom controls + My Location (stacked on right) ──
                if (!_showSearchResults)
                  PositionedDirectional(
                    bottom: widget.showRadiusPicker ? 370 : 290,
                    end: 16,
                  child: Column(
                    children: [
                      // My Location button above zoom
                      Material(
                        elevation: 4,
                        shape: const CircleBorder(),
                        color: Colors.white,
                        child: InkWell(
                          onTap: _isLocating ? null : _goToMyLocation,
                          customBorder: const CircleBorder(),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                            ),
                            child: _isLocating
                                ? const Padding(
                                    padding: EdgeInsets.all(11),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Color(0xFFF35535),
                                    ),
                                  )
                                : const Icon(
                                    Icons.my_location_rounded,
                                    color: Color(0xFFF35535),
                                    size: 22,
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildZoomButton(Icons.add, () {
                        final zoom = _mapController.camera.zoom;
                        _mapController.move(_currentCenter!, zoom + 1);
                      }),
                      const SizedBox(height: 8),
                      _buildZoomButton(Icons.remove, () {
                        final zoom = _mapController.camera.zoom;
                        _mapController.move(_currentCenter!, zoom - 1);
                      }),
                    ],
                  ),
                ),

                // ── Bottom address panel ──
                if (!_showSearchResults) _buildBottomPanel(),
              ],
            ),
    );
  }

  // ─── Search Overlay ───────────────────────────────────────────────

  Widget _buildSearchOverlay() {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return PositionedDirectional(
      top: 0,
      start: 0,
      end: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 12, 0),
          child: Column(
            children: [
              // Search bar row
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Back button
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.adaptive.arrow_back,
                        color: const Color(0xFF333333),
                      ),
                    ),
                    // Search field
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        onTap: () {
                          if (_searchResults.isNotEmpty) {
                            setState(() => _showSearchResults = true);
                          }
                        },
                        decoration: InputDecoration(
                          hintText: isAr
                              ? 'ابحث عن عنوان أو منطقة...'
                              : 'Search for an address or area...',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                        ),
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ),
                    // Loading or clear
                    if (_isSearching)
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFF35535),
                          ),
                        ),
                      )
                    else if (_searchController.text.isNotEmpty)
                      IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchResults = const [];
                            _showSearchResults = false;
                          });
                        },
                        icon: Icon(
                          Icons.close_rounded,
                          color: Colors.grey.shade400,
                          size: 20,
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          Icons.search_rounded,
                          color: Colors.grey.shade400,
                          size: 22,
                        ),
                      ),
                  ],
                ),
              ),

              // Search results dropdown
              if (_showSearchResults && _searchResults.isNotEmpty)
                Container(
                  margin: const EdgeInsetsDirectional.only(top: 4),
                  constraints: const BoxConstraints(maxHeight: 280),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      separatorBuilder: (_, _) =>
                          Divider(height: 1, color: Colors.grey.shade100),
                      itemBuilder: (context, index) {
                        final result = _searchResults[index];
                        return _buildSearchResultItem(result);
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResultItem(Map<String, dynamic> result) {
    final displayName = result['display_name'] as String? ?? '';
    final address = result['address'] as Map<String, dynamic>?;

    // Build a primary label (road + area) and a secondary label (city, country)
    String primary = '';
    String secondary = '';

    if (address != null) {
      final road =
          address['road'] as String? ?? address['name'] as String? ?? '';
      final suburb = address['suburb'] as String?;
      final neighbourhood = address['neighbourhood'] as String?;
      final area = neighbourhood ?? suburb;

      if (road.isNotEmpty) {
        primary = area != null ? '$road, $area' : road;
      } else if (area != null) {
        primary = area;
      }

      final city =
          address['city'] as String? ?? address['town'] as String? ?? '';
      final state = address['state'] as String? ?? '';
      final country = address['country'] as String? ?? '';
      final secondaryParts = [
        city,
        state,
        country,
      ].where((s) => s.isNotEmpty).toList();
      secondary = secondaryParts.join(', ');
    }

    // Fall back to display_name if parsing failed
    if (primary.isEmpty) {
      final parts = displayName.split(',');
      primary = parts.isNotEmpty ? parts[0].trim() : displayName;
      secondary = parts.length > 1
          ? parts.sublist(1).map((s) => s.trim()).join(', ')
          : '';
    }

    return InkWell(
      onTap: () => _selectSearchResult(result),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFF35535).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.location_on_outlined,
                color: Color(0xFFF35535),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    primary,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (secondary.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      secondary,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.north_west_rounded,
              size: 16,
              color: Colors.grey.shade300,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Bottom Panel ─────────────────────────────────────────────────

  Widget _buildBottomPanel() {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return PositionedDirectional(
      bottom: 0,
      start: 0,
      end: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Address display
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF35535).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: Color(0xFFF35535),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _isLoadingAddress
                        ? _buildLoadingSkeleton()
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _shortAddress.isNotEmpty
                                    ? _shortAddress
                                    : _currentAddress,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF333333),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (_areaInfo.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  _areaInfo,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                  ),
                ],
              ),

              // Coordinates chip
              if (_currentCenter != null && !_isLoadingAddress)
                Padding(
                  padding: const EdgeInsetsDirectional.only(top: 10, start: 58),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_currentCenter!.latitude.toStringAsFixed(6)}, ${_currentCenter!.longitude.toStringAsFixed(6)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

              if (widget.showRadiusPicker) ...[
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isAr ? 'نطاق التغطية المستهدف' : 'Target Coverage Radius',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF35535).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isAr
                            ? '${_radiusKm.toStringAsFixed(0)} كم'
                            : '${_radiusKm.toStringAsFixed(0)} km',
                        style: const TextStyle(
                          color: Color(0xFFF35535),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _radiusKm,
                  min: 1.0,
                  max: 100.0,
                  divisions: 99,
                  activeColor: const Color(0xFFF35535),
                  label: isAr
                      ? '${_radiusKm.toStringAsFixed(0)} كم'
                      : '${_radiusKm.toStringAsFixed(0)} km',
                  onChanged: (val) {
                    setState(() {
                      _radiusKm = val;
                    });
                  },
                ),
              ],

              const SizedBox(height: 20),

              // Confirm button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoadingAddress
                      ? null
                      : () {
                          Navigator.pop(context, {
                            'lat': _currentCenter!.latitude,
                            'lng': _currentCenter!.longitude,
                            'radiusKm': _radiusKm,
                            'address': _currentAddress,
                          });
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF35535),
                    disabledBackgroundColor: Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.confirmLocation,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Utility Widgets ──────────────────────────────────────────────

  Widget _buildLoadingSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 16,
          width: 180,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 12,
          width: 120,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _buildZoomButton(IconData icon, VoidCallback onTap) {
    return Material(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          child: Icon(icon, color: const Color(0xFF333333), size: 22),
        ),
      ),
    );
  }
}
