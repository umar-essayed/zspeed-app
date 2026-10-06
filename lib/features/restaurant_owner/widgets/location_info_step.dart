import 'package:z_speed/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import 'package:z_speed/features/restaurant_owner/widgets/restaurant_form_styles.dart';
import 'package:z_speed/features/restaurant_owner/widgets/restaurant_form_widgets.dart';

/// Step 2: Location & Operating Hours
///
/// Collects: address, city, and per-day operating hours (7 days).
class LocationInfoStep extends StatelessWidget {
  final TextEditingController addressController;
  final TextEditingController cityController;

  /// Map of day name → {'open': TimeOfDay, 'close': TimeOfDay, 'closed': bool}
  final Map<String, Map<String, dynamic>> operatingHours;
  final void Function(String day, String field, dynamic value) onUpdateHours;
  final GlobalKey<FormState> formKey;
  final double? latitude;
  final double? longitude;
  final VoidCallback onGetLocation;
  final VoidCallback onPickOnMap;
  final bool isGettingLocation;

  const LocationInfoStep({
    super.key,
    required this.addressController,
    required this.cityController,
    required this.operatingHours,
    required this.onUpdateHours,
    required this.formKey,
    required this.latitude,
    required this.longitude,
    required this.onGetLocation,
    required this.onPickOnMap,
    required this.isGettingLocation,
  });

  static const _days = [
    'Saturday',
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
  ];

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(RestaurantFormStyles.horizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RestaurantFormSectionHeader(
              title: AppLocalizations.of(context)!.locationAndHoursStep,
              subtitle: AppLocalizations.of(context)!.whereIsRestaurant,
              icon: Icons.map_outlined,
            ),

            // Address
            TextFormField(
              controller: addressController,
              decoration: RestaurantFormStyles.inputDecoration(
                label: AppLocalizations.of(context)!.fullAddress,
                hint: AppLocalizations.of(context)!.streetBuildingFloor,
                prefixIcon: Icons.location_on_outlined,
              ),
              maxLines: 2,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? AppLocalizations.of(context)!.addressRequired
                  : null,
            ),
            const SizedBox(height: RestaurantFormStyles.verticalSpacing),

            // City
            TextFormField(
              controller: cityController,
              decoration: RestaurantFormStyles.inputDecoration(
                label: AppLocalizations.of(context)!.city,
                hint: AppLocalizations.of(context)!.enterCity,
                prefixIcon: Icons.location_city_outlined,
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? AppLocalizations.of(context)!.cityRequired
                  : null,
            ),

            // Coordinates
            const SizedBox(height: RestaurantFormStyles.verticalSpacing),
            Text(AppLocalizations.of(context)!.map,
                style: RestaurantFormStyles.sectionTitle),
            const SizedBox(height: 4),
            Text(AppLocalizations.of(context)!.pinpointLocation,
                style: RestaurantFormStyles.sectionSubtitle),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: RestaurantFormStyles.borderColor),
                borderRadius:
                    BorderRadius.circular(RestaurantFormStyles.inputRadius),
              ),
              child: Row(
                children: [
                  Icon(Icons.gps_fixed,
                      color: RestaurantFormStyles.primaryColor, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: latitude != null && longitude != null
                        ? Text(
                            'Lat: ${latitude!.toStringAsFixed(6)}\nLng: ${longitude!.toStringAsFixed(6)}',
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w500),
                          )
                        : Text(
                            AppLocalizations.of(context)!.locationNotSet,
                            style: TextStyle(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                color: RestaurantFormStyles.labelColor),
                          ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton.icon(
                        onPressed: isGettingLocation ? null : onGetLocation,
                        icon: isGettingLocation
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.my_location, size: 16),
                        label: Text(isGettingLocation
                            ? AppLocalizations.of(context)!.wait
                            : AppLocalizations.of(context)!.gps),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: RestaurantFormStyles.primaryColor,
                          side: BorderSide(
                              color: RestaurantFormStyles.primaryColor),
                        ),
                      ),
                      const SizedBox(height: 4),
                      OutlinedButton.icon(
                        onPressed: onPickOnMap,
                        icon: const Icon(Icons.map_outlined, size: 16),
                        label: Text(AppLocalizations.of(context)!.pickOnMap),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: RestaurantFormStyles.primaryColor,
                          side: BorderSide(
                              color: RestaurantFormStyles.primaryColor),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: RestaurantFormStyles.sectionSpacing),

            // Operating Hours
            Text(AppLocalizations.of(context)!.operatingHours,
                style: RestaurantFormStyles.sectionTitle),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context)!.setOpeningClosingTimes,
              style: RestaurantFormStyles.sectionSubtitle,
            ),
            const SizedBox(height: 12),

            ..._days.map((day) {
              final hours = operatingHours[day]!;
              final isClosed = hours['closed'] as bool;
              final open = hours['open'] as TimeOfDay;
              final close = hours['close'] as TimeOfDay;

              return Padding(
                padding: const EdgeInsetsDirectional.only(bottom: 8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isClosed
                        ? RestaurantFormStyles.chipUnselected
                        : Colors.white,
                    borderRadius:
                        BorderRadius.circular(RestaurantFormStyles.inputRadius),
                    border: Border.all(color: RestaurantFormStyles.borderColor),
                  ),
                  child: Row(
                    children: [
                      // Day name
                      SizedBox(
                        width: 90,
                        child: Text(
                          _getLocalizedDay(context, day),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isClosed
                                ? RestaurantFormStyles.labelColor
                                : const Color(0xFF212121),
                          ),
                        ),
                      ),
                      // Closed toggle
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: !isClosed,
                          // ignore: deprecated_member_use
                          onChanged: (v) =>
                              onUpdateHours(day, 'closed', !(v ?? true)),
                          activeColor: RestaurantFormStyles.primaryColor,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Time pickers
                      if (!isClosed) ...[
                        _TimePicker(
                          label: AppLocalizations.of(context)!.open,
                          time: open,
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: open,
                            );
                            if (picked != null) {
                              onUpdateHours(day, 'open', picked);
                            }
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(AppLocalizations.of(context)!.symbolKeyX,
                              style: TextStyle(
                                  color: RestaurantFormStyles.labelColor)),
                        ),
                        _TimePicker(
                          label: AppLocalizations.of(context)!.close,
                          time: close,
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: close,
                            );
                            if (picked != null) {
                              onUpdateHours(day, 'close', picked);
                            }
                          },
                        ),
                      ] else
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)!.closed,
                            style: TextStyle(
                              color: RestaurantFormStyles.labelColor,
                              fontStyle: FontStyle.italic,
                              fontSize: 13,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _getLocalizedDay(BuildContext context, String day) {
    final l10n = AppLocalizations.of(context)!;
    switch (day) {
      case 'Monday':
        return l10n.monday;
      case 'Tuesday':
        return l10n.tuesday;
      case 'Wednesday':
        return l10n.wednesday;
      case 'Thursday':
        return l10n.thursday;
      case 'Friday':
        return l10n.friday;
      case 'Saturday':
        return l10n.saturday;
      case 'Sunday':
        return l10n.sunday;
      default:
        return day;
    }
  }
}

// ── Time Picker Chip ─────────────────────────────────────────────────────────

class _TimePicker extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  const _TimePicker({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: RestaurantFormStyles.borderColor),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          time.format(context),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
