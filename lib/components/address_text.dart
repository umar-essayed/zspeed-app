import 'package:flutter/material.dart';
import 'package:z_speed/core/services/routing_service.dart';

/// Displays an address string. If the stored address is missing or invalid
/// (e.g. "API Key missing"), it fetches the address via reverse geocoding
/// using the provided lat/lng coordinates.
class AddressText extends StatefulWidget {
  final String address;
  final double lat;
  final double lng;
  final TextStyle? style;

  const AddressText({
    super.key,
    required this.address,
    required this.lat,
    required this.lng,
    this.style,
  });

  @override
  State<AddressText> createState() => _AddressTextState();
}

class _AddressTextState extends State<AddressText> {
  String? _resolved;
  bool _loading = false;

  static const _badValues = {
    '',
    'API Key missing',
    'No address provided',
    'Error fetching address',
  };

  bool get _needsFetch =>
      _badValues.contains(widget.address) &&
      widget.lat != 0.0 &&
      widget.lng != 0.0;

  @override
  void initState() {
    super.initState();
    if (_needsFetch) _fetch();
  }

  @override
  void didUpdateWidget(AddressText old) {
    super.didUpdateWidget(old);
    if (_needsFetch && _resolved == null && !_loading) _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);

    try {
      final result = await RoutingService.instance
          .reverseGeocodeDetailed(widget.lat, widget.lng, zoom: 16);
      if (result != null && mounted) {
        final addr = result.address;
        final parts = <String>[];
        final road = addr.road;
        final neighbourhood = addr.neighbourhood;
        final suburb = addr.suburb;
        final city = addr.city;
        final state = addr.state;
        for (final v in [road, neighbourhood, suburb, city, state]) {
          if (v != null && v.isNotEmpty) parts.add(v);
        }
        setState(() => _resolved =
            parts.isNotEmpty ? parts.join(', ') : result.displayName);
      }
    } catch (_) {
      // silently fail – fallback shown below
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _localizeAddress(String address, BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    if (!isAr) return address;

    var localized = address;
    final replacements = {
      'Apartment (': 'شقة (',
      'Apartment': 'شقة',
      'Villa (': 'فيلا (',
      'Villa': 'فيلا',
      'Office (': 'مكتب (',
      'Office': 'مكتب',
      'Building:': 'مبنى:',
      'Apt:': 'شقة:',
      'Floor:': 'دور:',
      'Street:': 'شارع:',
      'Landmark:': 'علامة مميزة:',
      'Phone:': 'هاتف:',
      'Area:': 'منطقة:',
    };

    replacements.forEach((en, ar) {
      localized = localized.replaceAll(en, ar);
    });

    return localized;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Row(
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: widget.style?.color ?? Colors.grey,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            Localizations.localeOf(context).languageCode == 'ar'
                ? 'جاري تحميل العنوان…'
                : 'Loading address…',
            style: widget.style,
          ),
        ],
      );
    }

    final display = _resolved ??
        (_badValues.contains(widget.address)
            ? (widget.lat != 0.0
                ? '${widget.lat.toStringAsFixed(5)}, ${widget.lng.toStringAsFixed(5)}'
                : (Localizations.localeOf(context).languageCode == 'ar'
                    ? 'لا يوجد عنوان'
                    : 'No address'))
            : widget.address);

    return Text(_localizeAddress(display, context), style: widget.style);
  }
}
