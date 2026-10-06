import 'package:z_speed/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import 'package:z_speed/features/driver/widgets/driver_form_styles.dart';
import 'package:z_speed/features/driver/widgets/driver_form_widgets.dart';

/// Step 2: Vehicle Information
///
/// Collects: vehicle type, make/model, year, plate number, color.
class DriverVehicleInfoStep extends StatefulWidget {
  final String driverCategory;
  final TextEditingController? vehicleTypeController;
  final TextEditingController? vehicleMakeController;
  final TextEditingController? vehicleModelController;
  final TextEditingController? vehicleYearController;
  final TextEditingController? plateNumberController;
  final TextEditingController? vehicleColorController;
  final GlobalKey<FormState> formKey;

  const DriverVehicleInfoStep({
    super.key,
    required this.driverCategory,
    this.vehicleTypeController,
    this.vehicleMakeController,
    this.vehicleModelController,
    this.vehicleYearController,
    this.plateNumberController,
    this.vehicleColorController,
    required this.formKey,
  });

  @override
  State<DriverVehicleInfoStep> createState() => _DriverVehicleInfoStepState();
}

class _DriverVehicleInfoStepState extends State<DriverVehicleInfoStep> {
  List<String> get _vehicleTypes {
    if (widget.driverCategory == 'transport') {
      return ['Car', 'Motorcycle'];
    }
    return ['Car', 'Motorcycle', 'Cycle'];
  }

  static const _carBrands = [
    'Toyota',
    'Hyundai',
    'Nissan',
    'Kia',
    'Chevrolet',
    'Other'
  ];
  static const _motorcycleBrands = [
    'Honda',
    'Yamaha',
    'Suzuki',
    'Kawasaki',
    'Bajaj',
    'Other'
  ];
  static const _cycleTypes = ['Normal Cycle', 'Electronic Cycle'];

  late String selectedVehicleType;
  bool isOtherMakeSelected = false;

  TextEditingController? _localVehicleTypeCtrl;
  TextEditingController? _localVehicleMakeCtrl;
  TextEditingController? _localVehicleModelCtrl;
  TextEditingController? _localVehicleYearCtrl;
  TextEditingController? _localPlateNumberCtrl;
  TextEditingController? _localVehicleColorCtrl;

  late final TextEditingController vehicleTypeCtrl;
  late final TextEditingController vehicleMakeCtrl;
  late final TextEditingController vehicleModelCtrl;
  late final TextEditingController vehicleYearCtrl;
  late final TextEditingController plateNumberCtrl;
  late final TextEditingController vehicleColorCtrl;

  final List<TextEditingController> _plateLetterControllers =
      List.generate(4, (_) => TextEditingController());
  final List<TextEditingController> _plateNumberControllers =
      List.generate(4, (_) => TextEditingController());

  final List<FocusNode> _plateLetterNodes =
      List.generate(4, (_) => FocusNode());
  final List<FocusNode> _plateNumberNodes =
      List.generate(4, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    if (widget.vehicleTypeController == null) {
      _localVehicleTypeCtrl = TextEditingController();
    }
    if (widget.vehicleMakeController == null) {
      _localVehicleMakeCtrl = TextEditingController();
    }
    if (widget.vehicleModelController == null) {
      _localVehicleModelCtrl = TextEditingController();
    }
    if (widget.vehicleYearController == null) {
      _localVehicleYearCtrl = TextEditingController();
    }
    if (widget.plateNumberController == null) {
      _localPlateNumberCtrl = TextEditingController();
    }
    if (widget.vehicleColorController == null) {
      _localVehicleColorCtrl = TextEditingController();
    }

    vehicleTypeCtrl = widget.vehicleTypeController ?? _localVehicleTypeCtrl!;
    vehicleMakeCtrl = widget.vehicleMakeController ?? _localVehicleMakeCtrl!;
    vehicleModelCtrl = widget.vehicleModelController ?? _localVehicleModelCtrl!;
    vehicleYearCtrl = widget.vehicleYearController ?? _localVehicleYearCtrl!;
    plateNumberCtrl = widget.plateNumberController ?? _localPlateNumberCtrl!;
    vehicleColorCtrl = widget.vehicleColorController ?? _localVehicleColorCtrl!;

    final allowedTypes = _vehicleTypes;
    selectedVehicleType = vehicleTypeCtrl.text.isNotEmpty &&
            allowedTypes.contains(vehicleTypeCtrl.text)
        ? vehicleTypeCtrl.text
        : allowedTypes[0];
    vehicleTypeCtrl.text = selectedVehicleType;

    // Initialize plate controllers if there's existing data
    final String existingPlate = plateNumberCtrl.text;
    if (existingPlate.isNotEmpty && existingPlate != 'CYCLE000') {
      String letters = '';
      String numbers = '';
      for (int i = 0; i < existingPlate.length; i++) {
        if (RegExp(r'^[0-9]$').hasMatch(existingPlate[i])) {
          numbers += existingPlate[i];
        } else {
          letters += existingPlate[i];
        }
      }
      for (int i = 0; i < letters.length && i < 4; i++) {
        _plateLetterControllers[i].text = letters[i];
      }
      for (int i = 0; i < numbers.length && i < 4; i++) {
        _plateNumberControllers[i].text = numbers[i];
      }
    }
  }

  @override
  void dispose() {
    _localVehicleTypeCtrl?.dispose();
    _localVehicleMakeCtrl?.dispose();
    _localVehicleModelCtrl?.dispose();
    _localVehicleYearCtrl?.dispose();
    _localPlateNumberCtrl?.dispose();
    _localVehicleColorCtrl?.dispose();
    for (var c in _plateLetterControllers) {
      c.dispose();
    }
    for (var c in _plateNumberControllers) {
      c.dispose();
    }
    for (var n in _plateLetterNodes) {
      n.dispose();
    }
    for (var n in _plateNumberNodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _updatePlateNumber() {
    String p = '';
    for (var c in _plateLetterControllers) {
      p += c.text;
    }
    for (var c in _plateNumberControllers) {
      p += c.text;
    }
    plateNumberCtrl.text = p;
  }

  Widget _buildGranularInput({
    required TextEditingController controller,
    required FocusNode currentNode,
    FocusNode? nextNode,
    bool isNumber = false,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: TextFormField(
          controller: controller,
          focusNode: currentNode,
          textAlign: TextAlign.center,
          maxLength: 1,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            counterText: "",
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onChanged: (val) {
            _updatePlateNumber();
            if (val.isNotEmpty && nextNode != null) {
              FocusScope.of(context).requestFocus(nextNode);
            }
          },
          validator: (v) {
            if (isNumber) {
              final int count = _plateNumberControllers
                  .where((c) => c.text.isNotEmpty)
                  .length;
              if (count < 3) return ' ';
              if (v != null &&
                  v.isNotEmpty &&
                  !RegExp(r'^[0-9]+$').hasMatch(v)) {
                return ' ';
              }
            } else {
              final int count = _plateLetterControllers
                  .where((c) => c.text.isNotEmpty)
                  .length;
              if (count < 2) return ' ';
              if (v != null && v.isNotEmpty) {
                if (!RegExp(r'^[\u0600-\u06FFa-zA-Z]+$').hasMatch(v)) {
                  return ' ';
                }
              }
            }
            return null;
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> currentBrands = selectedVehicleType == 'Car'
        ? _carBrands
        : selectedVehicleType == 'Motorcycle'
            ? _motorcycleBrands
            : [];

    return Form(
      key: widget.formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(DriverFormStyles.horizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DriverFormSectionHeader(
              title: AppLocalizations.of(context)!.vehicleInfo,
              subtitle: AppLocalizations.of(context)!.provideVehicleDetails,
              icon: Icons.directions_car_outlined,
            ),

            DropdownButtonFormField<String>(
              initialValue: selectedVehicleType,
              decoration: DriverFormStyles.inputDecoration(
                label: AppLocalizations.of(context)!.vehicleType,
                prefixIcon: Icons.category_outlined,
              ),
              items: _vehicleTypes
                  .map((t) => DropdownMenuItem(
                      value: t,
                      child: Text(t == 'Car'
                          ? AppLocalizations.of(context)!.car
                          : t == 'Motorcycle'
                              ? AppLocalizations.of(context)!.motorcycle
                              : AppLocalizations.of(context)!.cycle)))
                  .toList(),
              // ignore: deprecated_member_use
              onChanged: (v) {
                if (v != null) {
                  setState(() {
                    selectedVehicleType = v;
                    vehicleTypeCtrl.text = v;
                    vehicleMakeCtrl.clear();
                    isOtherMakeSelected = false;

                    // Cycles don't need plate numbers
                    if (v == 'Cycle') {
                      plateNumberCtrl.text =
                          'CYCLE000'; // Dummy value to pass general form validation if needed somewhere higher
                    } else {
                      _updatePlateNumber();
                    }
                  });
                }
              },
            ),
            const SizedBox(height: DriverFormStyles.verticalSpacing),

            if (selectedVehicleType == 'Cycle') ...[
              // Cycle Type
              DropdownButtonFormField<String>(
                decoration: DriverFormStyles.inputDecoration(
                  label: AppLocalizations.of(context)!.cycleType,
                  prefixIcon: Icons.pedal_bike_outlined,
                ),
                items: _cycleTypes
                    .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(t == 'Normal Cycle'
                            ? AppLocalizations.of(context)!.normalCycle
                            : AppLocalizations.of(context)!.electronicCycle)))
                    .toList(),
                // ignore: deprecated_member_use
                onChanged: (v) => vehicleMakeCtrl.text = v ?? '',
                validator: (v) => (v == null || v.isEmpty)
                    ? AppLocalizations.of(context)!.selectCycleType
                    : null,
              ),
              const SizedBox(height: DriverFormStyles.verticalSpacing),
            ] else ...[
              // Make (Car / Motorcycle)
              DropdownButtonFormField<String>(
                decoration: DriverFormStyles.inputDecoration(
                  label: AppLocalizations.of(context)!.make,
                  prefixIcon: Icons.business_outlined,
                ),
                items: currentBrands
                    .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(t == 'Other'
                            ? AppLocalizations.of(context)!.other
                            : t)))
                    .toList(),
                // ignore: deprecated_member_use
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      isOtherMakeSelected = (v == 'Other');
                      if (!isOtherMakeSelected) {
                        vehicleMakeCtrl.text = v;
                      } else {
                        vehicleMakeCtrl.clear();
                      }
                    });
                  }
                },
                validator: (v) =>
                    (v == null || v.isEmpty) && !isOtherMakeSelected
                        ? AppLocalizations.of(context)!.makeRequired
                        : null,
              ),
              const SizedBox(height: DriverFormStyles.verticalSpacing),

              if (isOtherMakeSelected) ...[
                TextFormField(
                  controller: vehicleMakeCtrl,
                  decoration: DriverFormStyles.inputDecoration(
                    label: AppLocalizations.of(context)!.specifyMake,
                    hint: AppLocalizations.of(context)!.enterBrandManually,
                    prefixIcon: Icons.edit_outlined,
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? AppLocalizations.of(context)!.makeRequired
                      : null,
                ),
                const SizedBox(height: DriverFormStyles.verticalSpacing),
              ],

              // Model
              TextFormField(
                controller: vehicleModelCtrl,
                decoration: DriverFormStyles.inputDecoration(
                  label: AppLocalizations.of(context)!.model,
                  hint: AppLocalizations.of(context)!.corollaCivic,
                  prefixIcon: Icons.directions_car_filled_outlined,
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? AppLocalizations.of(context)!.modelRequired
                    : null,
              ),
              const SizedBox(height: DriverFormStyles.verticalSpacing),

              // Year
              TextFormField(
                controller: vehicleYearCtrl,
                decoration: DriverFormStyles.inputDecoration(
                  label: AppLocalizations.of(context)!.year,
                  hint: 'e.g. 2020',
                  prefixIcon: Icons.calendar_today_outlined,
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return AppLocalizations.of(context)!.yearRequired;
                  }
                  final year = int.tryParse(v.trim());
                  if (year == null ||
                      year < 1990 ||
                      year > DateTime.now().year + 1) {
                    return AppLocalizations.of(context)!.invalidYear;
                  }
                  return null;
                },
              ),
              const SizedBox(height: DriverFormStyles.verticalSpacing),
            ],

            // Color (For All types)
            TextFormField(
              controller: vehicleColorCtrl,
              decoration: DriverFormStyles.inputDecoration(
                label: AppLocalizations.of(context)!.exactColor,
                hint: AppLocalizations.of(context)!.matteBlack,
                prefixIcon: Icons.palette_outlined,
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? AppLocalizations.of(context)!.colorRequired
                  : null,
            ),
            const SizedBox(height: DriverFormStyles.verticalSpacing),

            // Plate Number (Hide for Cycle)
            if (selectedVehicleType != 'Cycle') ...[
              Text(AppLocalizations.of(context)!.licensePlate,
                  style: TextStyle(
                      color: DriverFormStyles.labelColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildGranularInput(
                            controller: _plateNumberControllers[0],
                            currentNode: _plateNumberNodes[0],
                            nextNode: _plateNumberNodes[1],
                            isNumber: true),
                        _buildGranularInput(
                            controller: _plateNumberControllers[1],
                            currentNode: _plateNumberNodes[1],
                            nextNode: _plateNumberNodes[2],
                            isNumber: true),
                        _buildGranularInput(
                            controller: _plateNumberControllers[2],
                            currentNode: _plateNumberNodes[2],
                            nextNode: _plateNumberNodes[3],
                            isNumber: true),
                        _buildGranularInput(
                            controller: _plateNumberControllers[3],
                            currentNode: _plateNumberNodes[3],
                            nextNode: _plateLetterNodes[0],
                            isNumber: true),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(AppLocalizations.of(context)!.symbolKeyXX,
                        style:
                            const TextStyle(fontSize: 24, color: Colors.grey)),
                  ),
                  Expanded(
                    flex: 1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildGranularInput(
                            controller: _plateLetterControllers[0],
                            currentNode: _plateLetterNodes[0],
                            nextNode: _plateLetterNodes[1],
                            isNumber: false),
                        _buildGranularInput(
                            controller: _plateLetterControllers[1],
                            currentNode: _plateLetterNodes[1],
                            nextNode: _plateLetterNodes[2],
                            isNumber: false),
                        _buildGranularInput(
                            controller: _plateLetterControllers[2],
                            currentNode: _plateLetterNodes[2],
                            nextNode: _plateLetterNodes[3],
                            isNumber: false),
                        _buildGranularInput(
                            controller: _plateLetterControllers[3],
                            currentNode: _plateLetterNodes[3],
                            nextNode: null,
                            isNumber: false),
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 4),
              Text(AppLocalizations.of(context)!.enter3Or4,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: DriverFormStyles.verticalSpacing),
            ]
          ],
        ),
      ),
    );
  }
}
