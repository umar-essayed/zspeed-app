import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/features/admin/cubit/admin_vendors_cubit.dart';
import 'package:z_speed/features/admin/model/admin_models.dart';
import 'package:z_speed/features/admin/model/admin_theme.dart';
import 'package:z_speed/l10n/app_localizations.dart';

/// Shows the "Add Vendor" bottom sheet and returns when dismissed.
Future<void> showAddVendorSheet(BuildContext context) {
  final cubit = context.read<AdminVendorsCubit>();
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider<AdminVendorsCubit>.value(
      value: cubit,
      child: const _AddVendorSheet(),
    ),
  );
}

class _AddVendorSheet extends StatefulWidget {
  const _AddVendorSheet();

  @override
  State<_AddVendorSheet> createState() => _AddVendorSheetState();
}

class _AddVendorSheetState extends State<_AddVendorSheet> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _deliveryFeeController = TextEditingController(text: '0');
  final _minOrderController = TextEditingController(text: '0');
  final _deliveryTimeMinController = TextEditingController(text: '30');
  final _deliveryTimeMaxController = TextEditingController(text: '60');

  VendorType _vendorType = VendorType.restaurant;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _deliveryFeeController.dispose();
    _minOrderController.dispose();
    _deliveryTimeMinController.dispose();
    _deliveryTimeMaxController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final now = DateTime.now();
    final restaurant = Restaurant(
      id: '', // assigned by Firestore
      ownerId: '',
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      logoUrl: '',
      coverImageUrl: '',
      deliveryTimeMin: int.tryParse(_deliveryTimeMinController.text) ?? 30,
      deliveryTimeMax: int.tryParse(_deliveryTimeMaxController.text) ?? 60,
      deliveryFee: double.tryParse(_deliveryFeeController.text) ?? 0.0,
      minimumOrder: double.tryParse(_minOrderController.text) ?? 0.0,
      address: _addressController.text.trim(),
      phone: _phoneController.text.trim(),
      createdAt: now,
      updatedAt: now,
      vendorType: _vendorType,
      isActive: true,
    );

    final success =
        await context.read<AdminVendorsCubit>().addVendor(restaurant);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vendor added successfully'),
          backgroundColor: AdminTheme.successGreen,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to add vendor. Please try again.'),
          backgroundColor: AdminTheme.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: AdminTheme.backgroundWhite,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 8,
        bottom: 24 + bottomPadding,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AdminTheme.borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Title row
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AdminTheme.primaryOrange,
                          AdminTheme.accentOrange
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.store, color: AdminTheme.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    l10n.addVendor,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AdminTheme.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Vendor Type selector ────────────────────────────
              Text(
                'Vendor Type',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AdminTheme.textMedium,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: VendorType.values.map((type) {
                  final selected = _vendorType == type;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _vendorType = type),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selected
                                ? AdminTheme.primaryOrange
                                : AdminTheme.surfaceWhite,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected
                                  ? AdminTheme.primaryOrange
                                  : AdminTheme.borderColor,
                            ),
                          ),
                          child: Text(
                            type.label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color:
                                  selected ? Colors.white : AdminTheme.textDark,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // ── Basic info ──────────────────────────────────────
              _SectionTitle(title: l10n.basicInformation),
              const SizedBox(height: 12),
              _Field(
                controller: _nameController,
                label: l10n.name,
                icon: Icons.store_outlined,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              _Field(
                controller: _descriptionController,
                label: l10n.description,
                icon: Icons.notes_outlined,
                maxLines: 2,
              ),
              _Field(
                controller: _phoneController,
                label: l10n.phone,
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              _Field(
                controller: _addressController,
                label: l10n.address,
                icon: Icons.location_on_outlined,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 8),

              // ── Delivery settings ───────────────────────────────
              _SectionTitle(title: l10n.deliverySettings),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _Field(
                      controller: _deliveryFeeController,
                      label: l10n.deliveryFee,
                      icon: Icons.money_outlined,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Field(
                      controller: _minOrderController,
                      label: l10n.minimumOrder,
                      icon: Icons.shopping_bag_outlined,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: _Field(
                      controller: _deliveryTimeMinController,
                      label: l10n.minDeliveryTime,
                      icon: Icons.timer_outlined,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Field(
                      controller: _deliveryTimeMaxController,
                      label: l10n.maxDeliveryTime,
                      icon: Icons.timer,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // ── Submit button ───────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _submit,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.add, size: 18),
                  label: Text(
                    _isSaving ? 'Saving…' : l10n.addVendor,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminTheme.primaryOrange,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AdminTheme.primaryOrange.withValues(alpha: 0.6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 14,
        color: AdminTheme.textDark,
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.maxLines = 1,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AdminTheme.textLight, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AdminTheme.borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AdminTheme.borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AdminTheme.primaryOrange, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AdminTheme.errorRed, width: 1.5),
          ),
          filled: true,
          fillColor: AdminTheme.surfaceWhite,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
