import 'package:flutter/material.dart';
import 'package:z_speed/l10n/app_localizations.dart';
import 'package:z_speed/features/admin/model/admin_models.dart';
import 'package:z_speed/features/admin/model/admin_theme.dart';
import 'package:z_speed/features/admin/cubit/admin_vendors_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Full-detail view and editor for a vendor/restaurant.
class AdminVendorDetailView extends StatefulWidget {
  final Restaurant restaurant;

  const AdminVendorDetailView({super.key, required this.restaurant});

  @override
  State<AdminVendorDetailView> createState() => _AdminVendorDetailViewState();
}

class _AdminVendorDetailViewState extends State<AdminVendorDetailView> {
  late Restaurant _restaurant;
  bool _isSaving = false;

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _deliveryFeeController;
  late TextEditingController _minOrderController;
  late TextEditingController _deliveryTimeMinController;
  late TextEditingController _deliveryTimeMaxController;

  // Advanced delivery fee settings
  late DeliveryFeeMode _deliveryFeeMode;
  DeliveryFeeSubMode? _deliveryFeeSubMode;
  late TextEditingController _deliveryRadiusController;
  late TextEditingController _baseFeeController;
  late TextEditingController _perKmFeeController;
  late List<Map<String, dynamic>> _deliveryFeeTiers;

  @override
  void initState() {
    super.initState();
    _restaurant = widget.restaurant;
    _nameController = TextEditingController(text: _restaurant.name);
    _phoneController = TextEditingController(text: _restaurant.phone);
    _addressController = TextEditingController(text: _restaurant.address);
    _deliveryFeeController =
        TextEditingController(text: _restaurant.deliveryFee.toString());
    _minOrderController =
        TextEditingController(text: _restaurant.minimumOrder.toString());
    _deliveryTimeMinController =
        TextEditingController(text: _restaurant.deliveryTimeMin.toString());
    _deliveryTimeMaxController =
        TextEditingController(text: _restaurant.deliveryTimeMax.toString());

    // Init advanced settings
    _deliveryFeeMode = _restaurant.deliveryFeeMode;
    _deliveryFeeSubMode =
        _restaurant.deliveryFeeSubMode ?? DeliveryFeeSubMode.formula;
    _deliveryRadiusController =
        TextEditingController(text: _restaurant.deliveryRadiusKm.toString());

    final formula = _restaurant.deliveryFeeFormula ?? {};
    _baseFeeController =
        TextEditingController(text: (formula['baseFee'] ?? 15.0).toString());
    _perKmFeeController =
        TextEditingController(text: (formula['perKmFee'] ?? 5.0).toString());

    _deliveryFeeTiers =
        List<Map<String, dynamic>>.from(_restaurant.deliveryFeeTiers ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _deliveryFeeController.dispose();
    _minOrderController.dispose();
    _deliveryTimeMinController.dispose();
    _deliveryTimeMaxController.dispose();
    _deliveryRadiusController.dispose();
    _baseFeeController.dispose();
    _perKmFeeController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);

    final baseFee = double.tryParse(_baseFeeController.text) ?? 15.0;
    final perKmFee = double.tryParse(_perKmFeeController.text) ?? 5.0;

    final updatedRestaurant = _restaurant.copyWith(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      deliveryFee: double.tryParse(_deliveryFeeController.text) ??
          _restaurant.deliveryFee,
      minimumOrder:
          double.tryParse(_minOrderController.text) ?? _restaurant.minimumOrder,
      deliveryTimeMin: int.tryParse(_deliveryTimeMinController.text) ??
          _restaurant.deliveryTimeMin,
      deliveryTimeMax: int.tryParse(_deliveryTimeMaxController.text) ??
          _restaurant.deliveryTimeMax,
      deliveryFeeMode: _deliveryFeeMode,
      deliveryFeeSubMode: _deliveryFeeSubMode,
      deliveryRadiusKm: double.tryParse(_deliveryRadiusController.text) ??
          _restaurant.deliveryRadiusKm,
      deliveryFeeFormula: {
        'baseFee': baseFee,
        'perKmFee': perKmFee,
      },
      deliveryFeeTiers: _deliveryFeeTiers,
      deliveryFeeAreas: _restaurant.deliveryFeeAreas,
      updatedAt: DateTime.now(),
    );

    await context.read<AdminVendorsCubit>().updateVendor(updatedRestaurant);

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(AppLocalizations.of(context)!.vendorUpdatedSuccessfully),
          backgroundColor: AdminTheme.successGreen,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AdminTheme.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AdminTheme.surfaceWhite,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AdminTheme.textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.editVendor,
          style: TextStyle(
              color: AdminTheme.textDark,
              fontWeight: FontWeight.w700,
              fontSize: 18),
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            TextButton(
              onPressed: _saveChanges,
              child: Text(
                l10n.save,
                style: TextStyle(
                    color: AdminTheme.primaryOrange,
                    fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(l10n.basicInformation),
            const SizedBox(height: 16),
            _buildTextField(_nameController, l10n.name, Icons.store),
            _buildTextField(_phoneController, l10n.phone, Icons.phone,
                keyboardType: TextInputType.phone),
            _buildTextField(
                _addressController, l10n.address, Icons.location_on),
            const SizedBox(height: 24),
            _buildSectionTitle(l10n.deliverySettings),
            const SizedBox(height: 16),

            // Delivery fee mode & details editor
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AdminTheme.surfaceWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AdminTheme.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Delivery Pricing Mode',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AdminTheme.textDark),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Fixed Flat Fee')),
                          selected: _deliveryFeeMode == DeliveryFeeMode.fixed,
                          selectedColor:
                              AdminTheme.primaryOrange.withValues(alpha: 0.15),
                          checkmarkColor: AdminTheme.primaryOrange,
                          labelStyle: TextStyle(
                            color: _deliveryFeeMode == DeliveryFeeMode.fixed
                                ? AdminTheme.primaryOrange
                                : AdminTheme.textMedium,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (val) {
                            if (val) {
                              setState(() {
                                _deliveryFeeMode = DeliveryFeeMode.fixed;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Distance-Based')),
                          selected: _deliveryFeeMode == DeliveryFeeMode.distance,
                          selectedColor:
                              AdminTheme.primaryOrange.withValues(alpha: 0.15),
                          checkmarkColor: AdminTheme.primaryOrange,
                          labelStyle: TextStyle(
                            color: _deliveryFeeMode == DeliveryFeeMode.distance
                                ? AdminTheme.primaryOrange
                                : AdminTheme.textMedium,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (val) {
                            if (val) {
                              setState(() {
                                _deliveryFeeMode = DeliveryFeeMode.distance;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (_deliveryFeeMode == DeliveryFeeMode.fixed) ...[
                    _buildTextField(_deliveryFeeController,
                        'Flat Delivery Fee (EGP)', Icons.money,
                        keyboardType: TextInputType.number),
                  ] else ...[
                    Text(
                      'Distance Calculation Type',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AdminTheme.textDark),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Formula Pricing')),
                            selected:
                                _deliveryFeeSubMode == DeliveryFeeSubMode.formula,
                            selectedColor:
                                AdminTheme.primaryOrange.withValues(alpha: 0.15),
                            checkmarkColor: AdminTheme.primaryOrange,
                            labelStyle: TextStyle(
                              color: _deliveryFeeSubMode ==
                                      DeliveryFeeSubMode.formula
                                  ? AdminTheme.primaryOrange
                                  : AdminTheme.textMedium,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (val) {
                              if (val) {
                                setState(() {
                                  _deliveryFeeSubMode =
                                      DeliveryFeeSubMode.formula;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Bracket Tiers')),
                            selected:
                                _deliveryFeeSubMode == DeliveryFeeSubMode.tiers,
                            selectedColor:
                                AdminTheme.primaryOrange.withValues(alpha: 0.15),
                            checkmarkColor: AdminTheme.primaryOrange,
                            labelStyle: TextStyle(
                              color:
                                  _deliveryFeeSubMode == DeliveryFeeSubMode.tiers
                                      ? AdminTheme.primaryOrange
                                      : AdminTheme.textMedium,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (val) {
                              if (val) {
                                setState(() {
                                  _deliveryFeeSubMode = DeliveryFeeSubMode.tiers;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (_deliveryFeeSubMode == DeliveryFeeSubMode.formula) ...[
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(_baseFeeController,
                                'Base Fee (EGP)', Icons.money,
                                keyboardType: TextInputType.number),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(_perKmFeeController,
                                'Per KM Fee (EGP)', Icons.directions_car,
                                keyboardType: TextInputType.number),
                          ),
                        ],
                      ),
                    ] else ...[
                      _buildTiersBuilder(),
                    ],
                  ],
                  const SizedBox(height: 8),
                  _buildTextField(_deliveryRadiusController,
                      'Maximum Delivery Radius (KM)', Icons.explore,
                      keyboardType: TextInputType.number),
                ],
              ),
            ),

            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                      _minOrderController, l10n.minimumOrder, Icons.shopping_bag,
                      keyboardType: TextInputType.number),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(_deliveryTimeMinController,
                      l10n.minDeliveryTime, Icons.timer_outlined,
                      keyboardType: TextInputType.number),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(_deliveryTimeMaxController,
                      l10n.maxDeliveryTime, Icons.timer,
                      keyboardType: TextInputType.number),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSectionTitle(l10n.workingHours),
            const SizedBox(height: 16),
            _buildWorkingHoursList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AdminTheme.textDark,
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AdminTheme.textLight, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AdminTheme.borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AdminTheme.primaryOrange, width: 2),
          ),
          filled: true,
          fillColor: AdminTheme.surfaceWhite,
        ),
      ),
    );
  }

  Widget _buildTiersBuilder() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Delivery Fee Brackets',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.grey),
            ),
            TextButton.icon(
              onPressed: _addNewTier,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Bracket', style: TextStyle(fontSize: 11)),
              style: TextButton.styleFrom(
                foregroundColor: AdminTheme.primaryOrange,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_deliveryFeeTiers.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Text(
                'No brackets defined. Click Add to create one.',
                style: TextStyle(fontSize: 12, color: AdminTheme.textLight),
              ),
            ),
          )
        else
          ..._deliveryFeeTiers.asMap().entries.map((entry) {
            final idx = entry.key;
            final tier = entry.value;
            final minVal = tier['minDist']?.toString() ?? '0';
            final maxVal = tier['maxDist']?.toString() ?? '5';
            final feeVal = tier['fee']?.toString() ?? '15';

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AdminTheme.backgroundWhite,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AdminTheme.borderColor),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '$minVal to $maxVal km',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AdminTheme.textDark),
                            ),
                          ),
                          Text(
                            '$feeVal EGP',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AdminTheme.successGreen),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 16, color: Colors.blue),
                    onPressed: () => _editTierDialog(idx),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.delete,
                        size: 16, color: AdminTheme.errorRed),
                    onPressed: () => _removeTier(idx),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            );
          }),
        const SizedBox(height: 12),
      ],
    );
  }

  void _addNewTier() {
    _showTierDialog(null);
  }

  void _editTierDialog(int index) {
    _showTierDialog(index);
  }

  void _removeTier(int index) {
    setState(() {
      _deliveryFeeTiers.removeAt(index);
    });
  }

  void _showTierDialog(int? index) {
    final isEdit = index != null;
    final minDistCtrl = TextEditingController(
        text: isEdit ? _deliveryFeeTiers[index]['minDist'].toString() : '0');
    final maxDistCtrl = TextEditingController(
        text: isEdit ? _deliveryFeeTiers[index]['maxDist'].toString() : '5');
    final feeCtrl = TextEditingController(
        text: isEdit ? _deliveryFeeTiers[index]['fee'].toString() : '15');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(isEdit ? 'Edit Bracket' : 'Add Bracket'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: minDistCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Min Dist (KM)',
                          border: OutlineInputBorder()),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Required';
                        if (double.tryParse(val.trim()) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: maxDistCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Max Dist (KM)',
                          border: OutlineInputBorder()),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Required';
                        if (double.tryParse(val.trim()) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: feeCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Delivery Fee (EGP)',
                    border: OutlineInputBorder()),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Required';
                  if (double.tryParse(val.trim()) == null) return 'Invalid';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final minDist = double.parse(minDistCtrl.text.trim());
                final maxDist = double.parse(maxDistCtrl.text.trim());
                final fee = double.parse(feeCtrl.text.trim());

                setState(() {
                  final newTier = {
                    'minDist': minDist,
                    'maxDist': maxDist,
                    'fee': fee,
                  };
                  if (isEdit) {
                    _deliveryFeeTiers[index] = newTier;
                  } else {
                    _deliveryFeeTiers.add(newTier);
                  }
                });
                Navigator.pop(dialogCtx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminTheme.primaryOrange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkingHoursList() {
    final days = [
      'Saturday',
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday'
    ];

    return Column(
      children: days.map((day) {
        final hours = _restaurant.workingHours[day] ??
            const WorkingHours(open: '09:00', close: '23:00');
        return _WorkingHoursRow(
          day: day,
          hours: hours,
          onChanged: (newHours) {
            setState(() {
              final newMap =
                  Map<String, WorkingHours>.from(_restaurant.workingHours);
              newMap[day] = newHours;
              _restaurant = _restaurant.copyWith(workingHours: newMap);
            });
          },
        );
      }).toList(),
    );
  }
}

class _WorkingHoursRow extends StatelessWidget {
  final String day;
  final WorkingHours hours;
  final Function(WorkingHours) onChanged;

  const _WorkingHoursRow({
    required this.day,
    required this.hours,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              day,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AdminTheme.textDark,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              onTap: hours.isClosed ? null : () => _selectTime(context, true),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: hours.isClosed
                      ? AdminTheme.borderColor.withValues(alpha: 0.3)
                      : AdminTheme.surfaceWhite,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AdminTheme.borderColor),
                ),
                child: Text(
                  hours.isClosed ? '—' : hours.open,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: hours.isClosed
                        ? AdminTheme.textLight
                        : AdminTheme.textDark,
                  ),
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('to'),
          ),
          Expanded(
            child: InkWell(
              onTap: hours.isClosed ? null : () => _selectTime(context, false),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: hours.isClosed
                      ? AdminTheme.borderColor.withValues(alpha: 0.3)
                      : AdminTheme.surfaceWhite,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AdminTheme.borderColor),
                ),
                child: Text(
                  hours.isClosed ? '—' : hours.close,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: hours.isClosed
                        ? AdminTheme.textLight
                        : AdminTheme.textDark,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              Text(
                'Closed',
                style: TextStyle(fontSize: 10, color: AdminTheme.textLight),
              ),
              Switch(
                value: hours.isClosed,
                onChanged: (val) {
                  onChanged(WorkingHours(
                    open: hours.open,
                    close: hours.close,
                    isClosed: val,
                  ));
                },
                activeThumbColor: AdminTheme.primaryOrange,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _selectTime(BuildContext context, bool isOpenTime) async {
    final currentTime = isOpenTime ? hours.open : hours.close;
    final parts = currentTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 9,
      minute: int.tryParse(parts[1]) ?? 0,
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      final formattedTime =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      if (isOpenTime) {
        onChanged(WorkingHours(
          open: formattedTime,
          close: hours.close,
          isClosed: hours.isClosed,
        ));
      } else {
        onChanged(WorkingHours(
          open: hours.open,
          close: formattedTime,
          isClosed: hours.isClosed,
        ));
      }
    }
  }
}
