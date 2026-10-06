import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/l10n/app_localizations.dart';
import 'package:z_speed/features/customer/model/saved_address.dart';
import 'package:z_speed/core/services/routing_config.dart';
import 'package:z_speed/components/map_location_picker.dart';
import 'package:z_speed/features/auth/cubit/auth_cubit.dart';

class AddressDetailsDialog extends StatefulWidget {
  final LatLng initialLocation;
  final String initialAddress;
  final SavedAddress? existingAddress;

  const AddressDetailsDialog({
    super.key,
    required this.initialLocation,
    required this.initialAddress,
    this.existingAddress,
  });

  static Future<SavedAddress?> show(
    BuildContext context, {
    required LatLng initialLocation,
    required String initialAddress,
    SavedAddress? existingAddress,
  }) {
    return showModalBottomSheet<SavedAddress>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AddressDetailsDialog(
        initialLocation: initialLocation,
        initialAddress: initialAddress,
        existingAddress: existingAddress,
      ),
    );
  }

  @override
  State<AddressDetailsDialog> createState() => _AddressDetailsDialogState();
}

class _AddressDetailsDialogState extends State<AddressDetailsDialog> {
  final _formKey = GlobalKey<FormState>();

  late LatLng _currentCenter;
  late String _currentAddress;

  // Fields state
  String _selectedType = 'apartment'; // 'apartment', 'villa', 'office'
  final _buildingCtrl = TextEditingController();
  final _apartmentCtrl = TextEditingController();
  final _floorCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _landmarkCtrl = TextEditingController();

  String _stripCountryCode(String phoneVal) {
    String cleaned = phoneVal.trim().replaceAll(' ', '');
    while (true) {
      if (cleaned.startsWith('+20')) {
        cleaned = cleaned.substring(3).trim();
      } else if (cleaned.startsWith('20') && cleaned.length > 10) {
        cleaned = cleaned.substring(2).trim();
      } else {
        break;
      }
    }
    return cleaned;
  }

  @override
  void initState() {
    super.initState();
    _currentCenter = widget.initialLocation;
    _currentAddress = widget.initialAddress;

    // Load existing address if editing
    if (widget.existingAddress != null) {
      final addr = widget.existingAddress!;
      _selectedType = addr.type ?? 'apartment';
      _buildingCtrl.text = addr.building ?? '';
      _apartmentCtrl.text = addr.apartment ?? '';
      _floorCtrl.text = addr.floor ?? '';
      _streetCtrl.text = addr.street ?? '';
      _phoneCtrl.text = _stripCountryCode(addr.phone ?? '');
      _landmarkCtrl.text = addr.landmark ?? '';
    } else {
      // Pre-populate phone number from auth profile
      final user = context.read<AuthCubit>().currentUser;
      if (user != null && user.phone != null) {
        _phoneCtrl.text = _stripCountryCode(user.phone!);
      }
    }
  }

  @override
  void dispose() {
    _buildingCtrl.dispose();
    _apartmentCtrl.dispose();
    _floorCtrl.dispose();
    _streetCtrl.dispose();
    _phoneCtrl.dispose();
    _landmarkCtrl.dispose();
    super.dispose();
  }

  Future<void> _editMapLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapLocationPicker(
          initialLocation: _currentCenter,
          initialAddress: _currentAddress,
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _currentAddress = result['address'] as String;
        _currentCenter =
            LatLng(result['lat'] as double, result['lng'] as double);
      });
    }
  }

  void _onConfirm() {
    if (!_formKey.currentState!.validate()) return;

    final finalAddress = SavedAddress(
      id: widget.existingAddress?.id ?? const Uuid().v4(),
      label: _selectedType.toUpperCase(),
      address: _currentAddress,
      latitude: _currentCenter.latitude,
      longitude: _currentCenter.longitude,
      type: _selectedType,
      building: _buildingCtrl.text.trim(),
      apartment: _selectedType == 'villa' ? null : _apartmentCtrl.text.trim(),
      floor: _floorCtrl.text.trim().isEmpty ? null : _floorCtrl.text.trim(),
      street: _streetCtrl.text.trim(),
      phone: '+20 ${_stripCountryCode(_phoneCtrl.text)}',
      landmark:
          _landmarkCtrl.text.trim().isEmpty ? null : _landmarkCtrl.text.trim(),
    );

    Navigator.pop(context, finalAddress);
  }

  Widget _buildTypeButton(String type, String label, IconData icon) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedType = type),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.black : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected ? Colors.black : Colors.grey.shade300,
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey.shade700,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final titleText = localizations.addressDetailsTitle;
    final regionLabel = localizations.areaLabel;
    final editButtonText = localizations.edit;

    // Type toggles
    final aptLabel = localizations.typeApartment;
    final villaLabel = localizations.typeVilla;
    final officeLabel = localizations.typeOffice;

    // Building input
    String buildingLabel = localizations.buildingName;
    if (_selectedType == 'villa') {
      buildingLabel = localizations.villaNameNumber;
    } else if (_selectedType == 'office') {
      buildingLabel = localizations.buildingCompany;
    }

    // Apartment/Floor labels
    final aptNumLabel = _selectedType == 'office'
        ? localizations.officeNumber
        : localizations.apartmentNumber;
    final floorLabel = localizations.floorOptional;

    // Street, Phone, Landmark
    final streetLabel = localizations.street;
    final phoneLabel = localizations.mobilePhoneNumber;
    final landmarkLabel = localizations.uniqueLandmark;
    final confirmText = localizations.confirmAddressDetails;

    return Container(
      padding: EdgeInsets.only(bottom: bottomInset),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle & Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 32), // Spacer to center the title
                      Text(
                        titleText,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Scrollable fields
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mini Map Preview
                    SizedBox(
                      height: 140,
                      width: double.infinity,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            FlutterMap(
                              options: MapOptions(
                                initialCenter: _currentCenter,
                                initialZoom: 16.0,
                                interactionOptions: const InteractionOptions(
                                  flags: InteractiveFlag.none,
                                ),
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: RoutingConfig.tileUrl,
                                  subdomains: RoutingConfig.tileSubdomains,
                                  userAgentPackageName: RoutingConfig.userAgentPackageName,
                                ),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: _currentCenter,
                                      width: 40,
                                      height: 40,
                                      child: const Icon(
                                        Icons.location_on_rounded,
                                        color: Color(0xFFF35535),
                                        size: 36,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Area Card
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border:
                            Border.all(color: Colors.grey.shade100, width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF35535)
                                  .withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.location_on_rounded,
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
                                  regionLabel,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _currentAddress,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A1A2E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: _editMapLocation,
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFFF35535),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              editButtonText,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Type Selector Toggles
                    Row(
                      children: [
                        _buildTypeButton(
                            'apartment', aptLabel, Icons.apartment_rounded),
                        const SizedBox(width: 10),
                        _buildTypeButton(
                            'villa', villaLabel, Icons.cottage_rounded),
                        const SizedBox(width: 10),
                        _buildTypeButton('office', officeLabel,
                            Icons.business_center_rounded),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Building Name
                    _buildTextField(
                      controller: _buildingCtrl,
                      label: buildingLabel,
                      isRequired: true,
                      icon: Icons.store_mall_directory_outlined,
                    ),
                    const SizedBox(height: 14),

                    // Apartment & Floor Row (shown only if not villa)
                    if (_selectedType != 'villa') ...[
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _apartmentCtrl,
                              label: aptNumLabel,
                              isRequired: _selectedType == 'apartment',
                              icon: Icons.tag_rounded,
                              keyboardType: TextInputType.text,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              controller: _floorCtrl,
                              label: floorLabel,
                              isRequired: false,
                              icon: Icons.layers_outlined,
                              keyboardType: TextInputType.text,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                    ] else ...[
                      // If villa, we can optionally show only floor or nothing
                      _buildTextField(
                        controller: _floorCtrl,
                        label: floorLabel,
                        isRequired: false,
                        icon: Icons.layers_outlined,
                        keyboardType: TextInputType.text,
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Street
                    _buildTextField(
                      controller: _streetCtrl,
                      label: streetLabel,
                      isRequired: true,
                      icon: Icons.add_road_outlined,
                    ),
                    const SizedBox(height: 14),

                    // Phone Number with flag/dropdown
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.grey.shade200, width: 1.2),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 4),
                          child: Row(
                            children: [
                              // Flag & drop icon
                              const Text('🇪🇬',
                                  style: TextStyle(fontSize: 22)),
                              const SizedBox(width: 4),
                              const Icon(Icons.keyboard_arrow_down,
                                  size: 18, color: Colors.grey),
                              Container(
                                height: 26,
                                width: 1.2,
                                color: Colors.grey.shade300,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 12),
                              ),
                              // Country code & Phone Text field
                              Expanded(
                                child: TextFormField(
                                  controller: _phoneCtrl,
                                  keyboardType: TextInputType.phone,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A1A2E),
                                  ),
                                  decoration: InputDecoration(
                                    labelText: phoneLabel,
                                    labelStyle: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontWeight: FontWeight.normal,
                                      fontSize: 13,
                                    ),
                                    hintText: '1000000000',
                                    prefixText: '+20 ',
                                    prefixStyle: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1A1A2E),
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding:
                                        const EdgeInsets.symmetric(vertical: 6),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return localizations.phoneRequiredError;
                                    }
                                    final cleanVal =
                                        value.trim().replaceAll(' ', '');
                                    if (cleanVal.length < 9 ||
                                        cleanVal.length > 11) {
                                      return localizations.phoneLengthError;
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Unique Landmark
                    _buildTextField(
                      controller: _landmarkCtrl,
                      label: landmarkLabel,
                      isRequired: false,
                      icon: Icons.assistant_photo_outlined,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Confirm Button Footer
            Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF35535), Color(0xFFFF9800)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF35535).withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        confirmText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required bool isRequired,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    final localizations = AppLocalizations.of(context)!;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1A1A2E),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey.shade500,
          fontWeight: FontWeight.normal,
          fontSize: 13,
        ),
        prefixIcon: Icon(icon, color: const Color(0xFFF35535), size: 20),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF35535), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
      validator: (value) {
        if (isRequired && (value == null || value.trim().isEmpty)) {
          return localizations.fieldRequiredError;
        }
        return null;
      },
    );
  }
}
