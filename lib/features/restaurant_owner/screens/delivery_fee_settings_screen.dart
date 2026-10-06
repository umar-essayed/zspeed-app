import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:z_speed/components/map_location_picker.dart';
import 'package:z_speed/features/restaurant_owner/widgets/delivery_area_card.dart';
import 'package:z_speed/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:z_speed/core/enums/driver_enums.dart';
import 'package:z_speed/features/restaurant/model/restaurant.dart';

/// Vendor screen for configuring delivery fee settings.
///
/// Allows vendors to set:
/// - Delivery fee mode (fixed or distance-based)
/// - Delivery fee sub-mode (per order, per km, tiered)
/// - Base fee, per-km rate, delivery radius
/// - Tiered pricing rules
class DeliveryFeeSettingsScreen extends StatefulWidget {
  final Restaurant restaurant;
  final Future<void> Function(Restaurant updatedRestaurant) onSave;

  const DeliveryFeeSettingsScreen({
    super.key,
    required this.restaurant,
    required this.onSave,
  });

  @override
  State<DeliveryFeeSettingsScreen> createState() =>
      _DeliveryFeeSettingsScreenState();
}

class _DeliveryFeeSettingsScreenState extends State<DeliveryFeeSettingsScreen> {
  late DeliveryFeeMode _selectedMode;
  late DeliveryFeeSubMode? _selectedSubMode;
  late TextEditingController _baseFeeController;
  late TextEditingController _perKmRateController;
  late TextEditingController _radiusController;
  late List<TierConfig> _tiers;
  late List<Map<String, dynamic>> _customAreas;

  bool _hasChanges = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.restaurant.deliveryFeeMode;
    _selectedSubMode = widget.restaurant.deliveryFeeSubMode;
    _baseFeeController = TextEditingController(
      text: widget.restaurant.deliveryFee.toString(),
    );
    _perKmRateController = TextEditingController(
      text:
          widget.restaurant.deliveryFeeFormula?['perKmRate']?.toString() ?? '0',
    );
    _radiusController = TextEditingController(
      text: widget.restaurant.deliveryRadiusKm.toString(),
    );

    // Load existing tiers if any
    _tiers = widget.restaurant.deliveryFeeTiers
            ?.map((t) => TierConfig(
                  minKm: t['minKm'] as double,
                  maxKm: t['maxKm'] as double,
                  fee: t['fee'] as double,
                ))
            .toList() ??
        [];

    // Load existing custom map areas if any
    _customAreas = widget.restaurant.deliveryFeeAreas != null
        ? List<Map<String, dynamic>>.from(
            widget.restaurant.deliveryFeeAreas!.map((e) => Map<String, dynamic>.from(e)))
        : [];
  }

  @override
  void dispose() {
    _baseFeeController.dispose();
    _perKmRateController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _confirmDiscard();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoCard(),
              const SizedBox(height: 20),
              _buildModeSelection(),
              const SizedBox(height: 20),
              if (_selectedMode == DeliveryFeeMode.fixed)
                _buildFixedModeSettings()
              else
                _buildDistanceBasedSettings(),
              const SizedBox(height: 20),
              _buildMultiAreaSection(),
              const SizedBox(height: 20),
              _buildRadiusSettings(),
              const SizedBox(height: 80),
            ],
          ),
        ),
        floatingActionButton: _hasChanges
            ? FloatingActionButton.extended(
                onPressed: _isSaving ? null : _saveSettings,
                backgroundColor: Colors.deepOrange,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(_isSaving
                    ? AppLocalizations.of(context)!.wait
                    : AppLocalizations.of(context)!.saveChanges),
              )
            : null,
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.configureDeliveryFees,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  /// Mode selection: Fixed or Distance-Based.
  Widget _buildModeSelection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.deliveryFeeMode,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          RadioListTile<DeliveryFeeMode>(
            title: Text(AppLocalizations.of(context)!.fixedFee),
            subtitle: Text(AppLocalizations.of(context)!.chargeAFixedDelivery),
            value: DeliveryFeeMode.fixed,
            // ignore: deprecated_member_use
            groupValue: _selectedMode,
            // ignore: deprecated_member_use
            onChanged: (value) {
              setState(() {
                _selectedMode = value!;
                _selectedSubMode = null;
                _hasChanges = true;
              });
            },
          ),
          RadioListTile<DeliveryFeeMode>(
            title: Text(AppLocalizations.of(context)!.distanceBasedFeeLabel),
            subtitle: Text(AppLocalizations.of(context)!.calculateFeeBasedOn),
            value: DeliveryFeeMode.distance,
            // ignore: deprecated_member_use
            groupValue: _selectedMode,
            // ignore: deprecated_member_use
            onChanged: (value) {
              setState(() {
                _selectedMode = value!;
                _selectedSubMode = DeliveryFeeSubMode.formula;
                _hasChanges = true;
              });
            },
          ),
        ],
      ),
    );
  }

  /// Settings for fixed delivery fee mode.
  Widget _buildFixedModeSettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.fixedDeliveryFee,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _baseFeeController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.fixedFeeEgp,
              hintText: 'e.g., 30.00',
              prefixText: ' ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            // ignore: deprecated_member_use
            onChanged: (_) => setState(() => _hasChanges = true),
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.fixedFeeDescription,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  /// Settings for distance-based delivery fee mode.
  Widget _buildDistanceBasedSettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.distanceBasedFeeLabel,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.subMode,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          RadioListTile<DeliveryFeeSubMode>(
            title: Text(AppLocalizations.of(context)!.perKilometer),
            subtitle: Text(AppLocalizations.of(context)!.baseFeePerKm),
            value: DeliveryFeeSubMode.formula,
            // ignore: deprecated_member_use
            groupValue: _selectedSubMode,
            // ignore: deprecated_member_use
            onChanged: (value) {
              setState(() {
                _selectedSubMode = value;
                _hasChanges = true;
              });
            },
          ),
          RadioListTile<DeliveryFeeSubMode>(
            title: Text(AppLocalizations.of(context)!.tieredPricing),
            subtitle: Text(AppLocalizations.of(context)!.differentRatesForDistance),
            value: DeliveryFeeSubMode.tiers,
            // ignore: deprecated_member_use
            groupValue: _selectedSubMode,
            // ignore: deprecated_member_use
            onChanged: (value) {
              setState(() {
                _selectedSubMode = value;
                _hasChanges = true;
              });
            },
          ),
          const SizedBox(height: 16),
          if (_selectedSubMode == DeliveryFeeSubMode.formula)
            _buildPerKmSettings()
          else if (_selectedSubMode == DeliveryFeeSubMode.tiers)
            _buildTieredSettings(),
        ],
      ),
    );
  }

  /// Settings for per-km sub-mode.
  Widget _buildPerKmSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _baseFeeController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.baseFeeEgp,
            hintText: 'e.g., 20.00',
            prefixText: ' ',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          // ignore: deprecated_member_use
          onChanged: (_) => setState(() => _hasChanges = true),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _perKmRateController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.perKmRateEgp,
            hintText: 'e.g., 5.00',
            prefixIcon: const Icon(Icons.straighten),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          // ignore: deprecated_member_use
          onChanged: (_) => setState(() => _hasChanges = true),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.calculate, color: Colors.orange.shade700, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.formulaDescription,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.orange.shade900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Settings for tiered pricing sub-mode.
  Widget _buildTieredSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context)!.pricingTiers,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            TextButton.icon(
              onPressed: _addTier,
              icon: const Icon(Icons.add, size: 18),
              label: Text(AppLocalizations.of(context)!.addTier),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_tiers.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Center(
              child: Text(
                AppLocalizations.of(context)!.noTiersConfigured,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ),
          )
        else
          ..._tiers.asMap().entries.map((entry) {
            final index = entry.key;
            final tier = entry.value;
            return _buildTierCard(tier, index);
          }),
      ],
    );
  }

  Widget _buildTierCard(TierConfig tier, int index) {
    return Container(
      margin: const EdgeInsetsDirectional.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.tierWithNumber(index + 1),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                onPressed: () => _removeTier(index),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.minKm,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  controller:
                      TextEditingController(text: tier.minKm.toString()),
                  // ignore: deprecated_member_use
                  onChanged: (value) {
                    final newValue = double.tryParse(value) ?? 0;
                    setState(() {
                      _tiers[index] = tier.copyWith(minKm: newValue);
                      _hasChanges = true;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.maxKm,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  controller:
                      TextEditingController(text: tier.maxKm.toString()),
                  // ignore: deprecated_member_use
                  onChanged: (value) {
                    final newValue = double.tryParse(value) ?? 0;
                    setState(() {
                      _tiers[index] = tier.copyWith(maxKm: newValue);
                      _hasChanges = true;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.feeEgp,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  controller: TextEditingController(text: tier.fee.toString()),
                  // ignore: deprecated_member_use
                  onChanged: (value) {
                    final newValue = double.tryParse(value) ?? 0;
                    setState(() {
                      _tiers[index] = tier.copyWith(fee: newValue);
                      _hasChanges = true;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRadiusSettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.deliveryRadiusLabel,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _radiusController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.maxDeliveryDistanceKm,
              hintText: 'e.g., 10.00',
              prefixIcon: const Icon(Icons.local_shipping),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            // ignore: deprecated_member_use
            onChanged: (_) => setState(() => _hasChanges = true),
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.radiusDescription,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  void _addTier() {
    setState(() {
      _tiers.add(TierConfig(minKm: 0, maxKm: 5, fee: 30));
      _hasChanges = true;
    });
  }

  void _removeTier(int index) {
    setState(() {
      _tiers.removeAt(index);
      _hasChanges = true;
    });
  }

  Future<bool> _confirmDiscard() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.discardChanges),
        content: Text(
          AppLocalizations.of(context)!.unsavedChangesDescription,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.discard),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _saveSettings() async {
    // Validate inputs
    final baseFee = double.tryParse(_baseFeeController.text);
    final perKmRate = double.tryParse(_perKmRateController.text);
    final radius = double.tryParse(_radiusController.text);

    if (baseFee == null || baseFee < 0) {
      _showError(AppLocalizations.of(context)!.invalidBaseFee);
      return;
    }

    if (radius == null || radius <= 0) {
      _showError(AppLocalizations.of(context)!.invalidRadius);
      return;
    }

    if (_selectedMode == DeliveryFeeMode.distance &&
        _selectedSubMode == DeliveryFeeSubMode.formula &&
        (perKmRate == null || perKmRate < 0)) {
      _showError(AppLocalizations.of(context)!.invalidPerKmRate);
      return;
    }

    if (_selectedMode == DeliveryFeeMode.distance &&
        _selectedSubMode == DeliveryFeeSubMode.tiers &&
        _tiers.isEmpty) {
      _showError(AppLocalizations.of(context)!.addAtLeastOneTier);
      return;
    }

    // Build updated restaurant
    final updatedRestaurant = widget.restaurant.copyWith(
      deliveryFee: baseFee,
      deliveryFeeMode: _selectedMode,
      deliveryFeeSubMode: _selectedSubMode,
      deliveryFeeFormula: _selectedMode == DeliveryFeeMode.distance &&
              _selectedSubMode == DeliveryFeeSubMode.formula
          ? {'baseFee': baseFee, 'perKmRate': perKmRate ?? 0}
          : null,
      deliveryFeeTiers: _selectedMode == DeliveryFeeMode.distance &&
              _selectedSubMode == DeliveryFeeSubMode.tiers
          ? _tiers
              .map((t) => {
                    'minKm': t.minKm,
                    'maxKm': t.maxKm,
                    'fee': t.fee,
                  })
              .toList()
          : null,
      deliveryFeeAreas: _customAreas,
      deliveryRadiusKm: radius,
    );

    setState(() => _isSaving = true);
    try {
      await widget.onSave(updatedRestaurant);
      setState(() {
        _hasChanges = false;
        _isSaving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.deliveryFeeSettingsSaved),
            backgroundColor: Colors.green,
          ),
        );
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      setState(() => _isSaving = false);
      _showError(e.toString());
    }
  }

  Widget _buildMultiAreaSection() {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.add_location_alt_rounded, color: Color(0xFFF35535)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.configuredDeliveryAreas,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              l10n.areaRulesInfo,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            if (_customAreas.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Center(
                  child: Text(
                    l10n.noAreasConfigured,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _customAreas.length,
                itemBuilder: (context, index) {
                  return DeliveryAreaCard(
                    area: _customAreas[index],
                    onEdit: () => _editArea(index),
                    onDelete: () => _deleteArea(index),
                  );
                },
              ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _addNewAreaOnMap,
                icon: const Icon(Icons.map_outlined, color: Color(0xFFF35535)),
                label: Text(
                  l10n.addDeliveryArea,
                  style: const TextStyle(
                    color: Color(0xFFF35535),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFF35535)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addNewAreaOnMap() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => MapLocationPicker(
          showRadiusPicker: true,
          initialRadiusKm: 10.0,
          initialLocation: LatLng(
            widget.restaurant.latitude != 0.0 ? widget.restaurant.latitude : 30.0444,
            widget.restaurant.longitude != 0.0 ? widget.restaurant.longitude : 31.2357,
          ),
        ),
      ),
    );

    if (result == null || !mounted) return;

    final lat = result['lat'] as double?;
    final lng = result['lng'] as double?;
    final radiusKm = result['radiusKm'] as double? ?? 10.0;
    final address = result['address'] as String? ?? '';

    if (lat == null || lng == null) return;

    _showAreaDetailsDialog(
      centerLat: lat,
      centerLng: lng,
      radiusKm: radiusKm,
      address: address,
    );
  }

  void _showAreaDetailsDialog({
    required double centerLat,
    required double centerLng,
    required double radiusKm,
    required String address,
    int? editIndex,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final existing = editIndex != null ? _customAreas[editIndex] : null;

    final nameController = TextEditingController(
      text: existing?['name'] as String? ?? '',
    );
    final totalFeeController = TextEditingController(
      text: existing?['totalFee']?.toString() ??
          existing?['fixedFee']?.toString() ??
          existing?['baseFee']?.toString() ??
          '60.0',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(editIndex != null ? l10n.editArea : l10n.addDeliveryArea),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: l10n.areaNameLabel,
                  hintText: isAr ? 'مثال: المعادي / القاهرة الجديدة' : 'e.g. Maadi / New Cairo Zone',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: totalFeeController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: isAr ? 'إجمالي رسوم التوصيل للمنطقة (ج.م)' : 'Total Area Delivery Fee (EGP)',
                  suffixText: 'EGP',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(ctx)!.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF35535),
            ),
            onPressed: () {
              final areaName = nameController.text.trim();
              final totalFee = double.tryParse(totalFeeController.text) ?? 60.0;

              final areaObj = {
                'id': existing?['id'] ?? 'area_${DateTime.now().millisecondsSinceEpoch}',
                'name': areaName.isNotEmpty ? areaName : 'Zone ${editIndex != null ? editIndex + 1 : _customAreas.length + 1}',
                'centerLat': centerLat,
                'centerLng': centerLng,
                'radiusKm': radiusKm,
                'totalFee': totalFee,
                'fixedFee': totalFee,
                'address': address,
              };

              setState(() {
                if (editIndex != null) {
                  _customAreas[editIndex] = areaObj;
                } else {
                  _customAreas.add(areaObj);
                }
                _hasChanges = true;
              });

              Navigator.pop(ctx);
            },
            child: Text(
              AppLocalizations.of(ctx)!.save,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _editArea(int index) {
    final area = _customAreas[index];
    _showAreaDetailsDialog(
      centerLat: (area['centerLat'] as num).toDouble(),
      centerLng: (area['centerLng'] as num).toDouble(),
      radiusKm: (area['radiusKm'] as num).toDouble(),
      address: area['address'] as String? ?? '',
      editIndex: index,
    );
  }

  void _deleteArea(int index) {
    setState(() {
      _customAreas.removeAt(index);
      _hasChanges = true;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}

/// Configuration for a single pricing tier.
class TierConfig {
  final double minKm;
  final double maxKm;
  final double fee;

  TierConfig({
    required this.minKm,
    required this.maxKm,
    required this.fee,
  });

  TierConfig copyWith({
    double? minKm,
    double? maxKm,
    double? fee,
  }) {
    return TierConfig(
      minKm: minKm ?? this.minKm,
      maxKm: maxKm ?? this.maxKm,
      fee: fee ?? this.fee,
    );
  }
}
