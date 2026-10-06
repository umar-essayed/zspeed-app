import 'package:z_speed/core/localization/language_selector_widget.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:z_speed/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:z_speed/core/utils/image_utils.dart';
import 'package:z_speed/features/admin/model/admin_theme.dart';
import 'package:z_speed/features/admin/cubit/admin_settings_cubit.dart';
import 'package:z_speed/features/admin/cubit/admin_settings_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/core/enums/user_enums.dart';
import 'package:z_speed/features/restaurant/model/cuisine_type.dart';
import 'package:z_speed/features/restaurant/model/vendor_section.dart';
import 'package:z_speed/core/utils/upload_utils.dart';
import 'package:z_speed/features/auth/cubit/auth_cubit.dart';

class AdminSettingsView extends StatelessWidget {
  const AdminSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminSettingsCubit, AdminSettingsState>(
      builder: (context, state) {
        if (state.isBusy) {
          return const Center(child: CircularProgressIndicator());
        }
        return _SettingsContent(state: state);
      },
    );
  }
}

class _SettingsContent extends StatelessWidget {
  final AdminSettingsState state;
  const _SettingsContent({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AdminSettingsCubit>();
    final user = context.watch<AuthCubit>().state.user;
    final isSuperAdmin = user?.type == UserType.superAdmin;
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.systemSettings,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AdminTheme.textDark,
            ),
          ),
          const SizedBox(height: 16),

          // ── Localization ─────────────────────────────
          _buildSectionCard(
            title: AppLocalizations.of(context)!.localizationSection,
            children: [const LanguageSelectorTile()],
          ),
          const SizedBox(height: 16),

          // ── Platform Configuration ───────────────────────────────────
          _buildSectionCard(
            title: AppLocalizations.of(context)!.platformConfiguration,
            children: [
              // _buildSliderTile(
              //   context,
              //   title: 'Delivery Fee Rate',
              //   subtitle: '${(state.deliveryFeeRate * 100).toStringAsFixed(0)}%',
              //   value: state.deliveryFeeRate,
              //   // ignore: deprecated_member_use
              //   onChanged: (v) => cubit.updateDeliveryFeeRate(v),
              // ),
              // const Divider(height: 1),
              _CommissionInputTile(
                title: AppLocalizations.of(context)!.platformCommission,
                initialValue: state.platformCommission,
                onChanged: (v) => cubit.updatePlatformCommission(v),
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: Text(
                  AppLocalizations.of(context)!.maintenanceMode,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AdminTheme.textDark,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  !isSuperAdmin
                      ? AppLocalizations.of(
                          context,
                        )!.onlySuperAdminCanToggleMaintenance
                      : (state.maintenanceMode
                            ? AppLocalizations.of(context)!.platformIsOffline
                            : AppLocalizations.of(context)!.platformIsLive),
                  style: TextStyle(
                    color: !isSuperAdmin
                        ? Colors.red[400]
                        : AdminTheme.textLight,
                    fontSize: 11,
                  ),
                ),
                value: state.maintenanceMode,
                activeTrackColor: AdminTheme.primaryOrange.withValues(
                  alpha: 0.4,
                ),
                // ignore: deprecated_member_use
                onChanged: isSuperAdmin
                    ? (_) => cubit.toggleMaintenanceMode(UserType.superAdmin)
                    : null,
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: Text(
                  AppLocalizations.of(context)!.allowNewSignupsLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AdminTheme.textDark,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  !isSuperAdmin
                      ? AppLocalizations.of(
                          context,
                        )!.onlySuperAdminCanToggleMaintenance
                      : AppLocalizations.of(context)!.allowNewSignupsSubtitle,
                  style: TextStyle(
                    color: !isSuperAdmin
                        ? Colors.red[400]
                        : AdminTheme.textLight,
                    fontSize: 11,
                  ),
                ),
                value: state.allowNewSignups,
                activeTrackColor: AdminTheme.primaryOrange.withValues(
                  alpha: 0.4,
                ),
                onChanged: isSuperAdmin
                    ? (_) => cubit.toggleAllowNewSignups(UserType.superAdmin)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _VersionSettingsSection(),
          const SizedBox(height: 16),
          const _DriverEarningsLimitSection(),
          const SizedBox(height: 16),

          // ── Cuisine Types Management ───────────────────────────────
          const _CuisineTypesSection(),
          const SizedBox(height: 16),

          // ── Supermarket Sections ───────────────────────────────────
          const _VendorSectionsSection(vendorType: VendorType.supermarket),
          const SizedBox(height: 16),

          // ── Pharmacy Sections ──────────────────────────────────────
          const _VendorSectionsSection(vendorType: VendorType.pharmacy),
          const SizedBox(height: 16),

          // // ── General Settings ─────────────────────────────────────────
          // _buildSectionCard(
          //   title: 'General Settings',
          //   children: [
          //     const _AdminSettingsItem(
          //         title: 'Notifications', icon: Icons.notifications),
          //     const _AdminSettingsItem(title: 'Security', icon: Icons.security),
          //     const _AdminSettingsItem(
          //         title: 'Payment Settings', icon: Icons.payment),
          //     const _AdminSettingsItem(title: 'Dark Mode', icon: Icons.dark_mode),
          //     const _AdminSettingsItem(title: 'Language', icon: Icons.language),
          //   ],
          // ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminTheme.borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 4),
            spreadRadius: -5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AdminTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _CommissionInputTile extends StatefulWidget {
  final String title;
  final double initialValue;
  final ValueChanged<double> onChanged;

  const _CommissionInputTile({
    required this.title,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<_CommissionInputTile> createState() => _CommissionInputTileState();
}

class _CommissionInputTileState extends State<_CommissionInputTile> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: (widget.initialValue * 100).toStringAsFixed(0),
    );
    _focusNode = FocusNode();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final current = _controller.text;
    final original = (widget.initialValue * 100).toStringAsFixed(0);
    final dirty = current != original;
    if (dirty != _isDirty) {
      setState(() => _isDirty = dirty);
    }
  }

  @override
  void didUpdateWidget(covariant _CommissionInputTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue && !_focusNode.hasFocus) {
      _controller.text = (widget.initialValue * 100).toStringAsFixed(0);
      setState(() => _isDirty = false);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final parsed = double.tryParse(_controller.text);
    if (parsed != null && parsed >= 0 && parsed <= 100) {
      widget.onChanged(parsed / 100.0);
      setState(() => _isDirty = false);
    } else {
      _controller.text = (widget.initialValue * 100).toStringAsFixed(0);
      setState(() => _isDirty = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        widget.title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: AdminTheme.textDark,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        AppLocalizations.of(context)!.platformFeeDescription,
        style: TextStyle(color: AdminTheme.textLight, fontSize: 11),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 80,
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                isDense: true,
                suffixText: '%',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AdminTheme.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AdminTheme.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AdminTheme.primaryOrange),
                ),
              ),
              onSubmitted: (_) => _submit(),
            ),
          ),
          if (_isDirty) ...[
            const SizedBox(width: 8),
            SizedBox(
              height: 36,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminTheme.primaryOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Icon(Icons.check, size: 18),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AdminSettingsItem extends StatefulWidget {
  const _AdminSettingsItem({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  State<_AdminSettingsItem> createState() => _AdminSettingsItemState();
}

class _AdminSettingsItemState extends State<_AdminSettingsItem> {
  bool value = true;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(widget.icon, color: AdminTheme.primaryOrange, size: 20),
      title: Text(
        widget.title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: AdminTheme.textDark,
          fontSize: 14,
        ),
      ),
      trailing: Switch(
        value: value,
        activeThumbColor: AdminTheme.primaryOrange,
        // ignore: deprecated_member_use
        onChanged: (newValue) {
          setState(() {
            value = newValue;
          });
        },
      ),
    );
  }
}

// ── Cuisine Types Management Section ─────────────────────────────────────────

class _CuisineTypesSection extends StatefulWidget {
  const _CuisineTypesSection();

  @override
  State<_CuisineTypesSection> createState() => _CuisineTypesSectionState();
}

class _CuisineTypesSectionState extends State<_CuisineTypesSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminSettingsCubit, AdminSettingsState>(
      builder: (context, state) {
        final cubit = context.read<AdminSettingsCubit>();
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AdminTheme.surfaceWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AdminTheme.borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 15,
                offset: const Offset(0, 4),
                spreadRadius: -5,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.restaurant,
                          color: AdminTheme.primaryOrange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.cuisineTypesSection,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AdminTheme.textDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AdminTheme.primaryOrange.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${state.cuisineTypes.length}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AdminTheme.primaryOrange,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        AnimatedRotation(
                          turns: _isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AdminTheme.textLight,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showAddCuisineTypeDialog(context),
                      icon: const Icon(Icons.add, size: 16),
                      label: Text(AppLocalizations.of(context)!.add),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminTheme.primaryOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsetsDirectional.only(top: 12),
                  child: state.cuisineTypes.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              AppLocalizations.of(context)!.noCuisineTypesYet,
                              style: TextStyle(
                                color: AdminTheme.textLight,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: state.cuisineTypes.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final ct = state.cuisineTypes[index];
                            return _CuisineTypeTile(
                              cuisineType: ct,
                              onToggle: () => cubit.toggleCuisineTypeActive(ct),
                              onEdit: () =>
                                  _showEditCuisineTypeDialog(context, ct),
                              onDelete: () =>
                                  _showDeleteConfirmation(context, ct),
                            );
                          },
                        ),
                ),
                crossFadeState: _isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 250),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddCuisineTypeDialog(BuildContext context) {
    final cubit = context.read<AdminSettingsCubit>();
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider<AdminSettingsCubit>.value(
        value: cubit,
        child: const _AddCuisineTypeDialog(),
      ),
    );
  }

  void _showEditCuisineTypeDialog(BuildContext context, CuisineType ct) {
    final cubit = context.read<AdminSettingsCubit>();
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider<AdminSettingsCubit>.value(
        value: cubit,
        child: _EditCuisineTypeDialog(cuisineType: ct),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, CuisineType ct) {
    final cubit = context.read<AdminSettingsCubit>();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          AppLocalizations.of(context)!.deleteCuisineType,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        content: Text(AppLocalizations.of(context)!.deleteConfirmItem(ct.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(dialogContext);
              cubit.deleteCuisineType(ct.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.of(context)!.cuisineTypeDeleted,
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: Text(
              AppLocalizations.of(context)!.delete,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ADD CUISINE TYPE DIALOG
// ══════════════════════════════════════════════════════════════════════════════

class _AddCuisineTypeDialog extends StatefulWidget {
  const _AddCuisineTypeDialog();

  @override
  State<_AddCuisineTypeDialog> createState() => _AddCuisineTypeDialogState();
}

class _AddCuisineTypeDialogState extends State<_AddCuisineTypeDialog> {
  final _nameCtrl = TextEditingController();
  final _nameArCtrl = TextEditingController();
  XFile? _pickedImage;
  Uint8List? _imageBytes;
  bool _isUploading = false;
  double _uploadProgress = 0;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nameArCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImageUtils.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _pickedImage = picked;
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty || _nameArCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.bothEnglishAndArabic),
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      String? imageUrl;
      if (_pickedImage != null) {
        final uploadResult = await UploadUtils.uploadXFile(
          xFile: _pickedImage!,
          folder: 'cuisine_types',
          onProgress: (p) {
            if (mounted) setState(() => _uploadProgress = p);
          },
        );
        imageUrl = uploadResult.url;
      }

      if (!mounted) return;
      Navigator.pop(context);

      await context.read<AdminSettingsCubit>().createCuisineType(
        name: _nameCtrl.text.trim(),
        nameAr: _nameArCtrl.text.trim(),
        imageUrl: imageUrl,
        isActive: true,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.cuisineTypeCreated),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.errorValue(e.toString()),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        AppLocalizations.of(context)!.addCuisineType,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: AdminTheme.primaryOrange,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image Picker
            _buildImagePicker(),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.nameEnglishField,
                hintText: AppLocalizations.of(context)!.nameEnglishHint,
                border: const OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameArCtrl,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.nameArabicField,
                hintText: AppLocalizations.of(context)!.nameArabicHint,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isUploading ? null : () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AdminTheme.primaryOrange,
            foregroundColor: Colors.white,
          ),
          onPressed: _isUploading ? null : _submit,
          child: _isUploading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                    value: _uploadProgress > 0 ? _uploadProgress : null,
                  ),
                )
              : Text(
                  AppLocalizations.of(context)!.create,
                  style: const TextStyle(color: Colors.white),
                ),
        ),
      ],
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _isUploading ? null : _pickImage,
      child: Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AdminTheme.primaryOrange.withValues(alpha: 0.3),
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: _imageBytes != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(_imageBytes!, fit: BoxFit.cover),
                    PositionedDirectional(
                      top: 4,
                      end: 4,
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _pickedImage = null;
                          _imageBytes = null;
                        }),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 36,
                    color: AdminTheme.primaryOrange.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppLocalizations.of(context)!.tapToUploadImageOptional,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// EDIT CUISINE TYPE DIALOG
// ══════════════════════════════════════════════════════════════════════════════

class _EditCuisineTypeDialog extends StatefulWidget {
  const _EditCuisineTypeDialog({required this.cuisineType});
  final CuisineType cuisineType;

  @override
  State<_EditCuisineTypeDialog> createState() => _EditCuisineTypeDialogState();
}

class _EditCuisineTypeDialogState extends State<_EditCuisineTypeDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _nameArCtrl;
  XFile? _pickedImage;
  Uint8List? _imageBytes;
  String? _existingImageUrl;
  bool _isUploading = false;
  double _uploadProgress = 0;
  bool _imageRemoved = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.cuisineType.name);
    _nameArCtrl = TextEditingController(text: widget.cuisineType.nameAr);
    _existingImageUrl = widget.cuisineType.imageUrl;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nameArCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImageUtils.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _pickedImage = picked;
        _imageBytes = bytes;
        _imageRemoved = false;
      });
    }
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty || _nameArCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.bothEnglishAndArabic),
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      String? imageUrl = _imageRemoved ? null : _existingImageUrl;

      if (_pickedImage != null) {
        final uploadResult = await UploadUtils.uploadXFile(
          xFile: _pickedImage!,
          folder: 'cuisine_types',
          onProgress: (p) {
            if (mounted) setState(() => _uploadProgress = p);
          },
        );
        imageUrl = uploadResult.url;
      }

      if (!mounted) return;
      Navigator.pop(context);

      await context.read<AdminSettingsCubit>().updateCuisineType(
        widget.cuisineType.copyWith(
          name: _nameCtrl.text.trim(),
          nameAr: _nameArCtrl.text.trim(),
          imageUrl: imageUrl,
          isActive: true,
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.cuisineTypeUpdated),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.errorValue(e.toString()),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        AppLocalizations.of(context)!.editCuisineType,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: AdminTheme.primaryOrange,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image Picker / Preview
            _buildImagePicker(),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.nameEnglishField,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameArCtrl,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.nameArabicField,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isUploading ? null : () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AdminTheme.primaryOrange,
            foregroundColor: Colors.white,
          ),
          onPressed: _isUploading ? null : _submit,
          child: _isUploading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                    value: _uploadProgress > 0 ? _uploadProgress : null,
                  ),
                )
              : Text(
                  AppLocalizations.of(context)!.save,
                  style: const TextStyle(color: Colors.white),
                ),
        ),
      ],
    );
  }

  Widget _buildImagePicker() {
    final hasExisting =
        !_imageRemoved &&
        _existingImageUrl != null &&
        _existingImageUrl!.isNotEmpty &&
        _pickedImage == null;

    return GestureDetector(
      onTap: _isUploading ? null : _pickImage,
      child: Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AdminTheme.primaryOrange.withValues(alpha: 0.3),
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: _imageBytes != null
            ? _imagePreview(
                child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                onRemove: () => setState(() {
                  _pickedImage = null;
                  _imageBytes = null;
                }),
              )
            : hasExisting
            ? _imagePreview(
                child: _existingImageUrl!.startsWith('assets/')
                    ? Image.asset(
                        _existingImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _placeholder(),
                      )
                    : Image.network(
                        _existingImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _placeholder(),
                      ),
                onRemove: () => setState(() => _imageRemoved = true),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _imagePreview({
    required Widget child,
    required VoidCallback onRemove,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(11),
      child: Stack(
        fit: StackFit.expand,
        children: [
          child,
          PositionedDirectional(
            top: 4,
            end: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 36,
          color: AdminTheme.primaryOrange.withValues(alpha: 0.6),
        ),
        const SizedBox(height: 6),
        Text(
          AppLocalizations.of(context)!.tapToUploadImageOptional,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// VENDOR SECTIONS (Supermarket / Pharmacy)
// ══════════════════════════════════════════════════════════════════════════════

class _VendorSectionsSection extends StatefulWidget {
  const _VendorSectionsSection({required this.vendorType});
  final VendorType vendorType;

  @override
  State<_VendorSectionsSection> createState() => _VendorSectionsSectionState();
}

class _VendorSectionsSectionState extends State<_VendorSectionsSection> {
  bool _isExpanded = false;

  IconData get _icon => widget.vendorType == VendorType.supermarket
      ? Icons.shopping_cart_outlined
      : Icons.local_pharmacy_outlined;

  Color get _color => widget.vendorType == VendorType.supermarket
      ? const Color(0xFF10B981)
      : const Color(0xFF3B82F6);

  List<VendorSection> _sectionsFor(AdminSettingsState state) =>
      widget.vendorType == VendorType.supermarket
      ? state.supermarketSections
      : state.pharmacySections;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminSettingsCubit, AdminSettingsState>(
      builder: (context, state) {
        final cubit = context.read<AdminSettingsCubit>();
        final sections = _sectionsFor(state);
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AdminTheme.surfaceWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AdminTheme.borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 15,
                offset: const Offset(0, 4),
                spreadRadius: -5,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(_icon, color: _color, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          widget.vendorType == VendorType.supermarket
                              ? AppLocalizations.of(
                                  context,
                                )!.supermarketSectionsTitle
                              : AppLocalizations.of(
                                  context,
                                )!.pharmacySectionsTitle,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AdminTheme.textDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${sections.length}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        AnimatedRotation(
                          turns: _isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AdminTheme.textLight,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showAddDialog(context),
                      icon: const Icon(Icons.add, size: 16),
                      label: Text(AppLocalizations.of(context)!.add),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsetsDirectional.only(top: 12),
                  child: sections.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              AppLocalizations.of(context)!.noSectionsYet,
                              style: TextStyle(
                                color: AdminTheme.textLight,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: sections.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final s = sections[index];
                            return _VendorSectionTile(
                              section: s,
                              accentColor: _color,
                              onToggle: () =>
                                  cubit.toggleVendorSectionActive(s),
                              onEdit: () => _showEditDialog(context, s),
                              onDelete: () =>
                                  _showDeleteConfirmation(context, s, cubit),
                            );
                          },
                        ),
                ),
                crossFadeState: _isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 250),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddDialog(BuildContext context) {
    final cubit = context.read<AdminSettingsCubit>();
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider<AdminSettingsCubit>.value(
        value: cubit,
        child: _AddVendorSectionDialog(vendorType: widget.vendorType),
      ),
    );
  }

  void _showEditDialog(BuildContext context, VendorSection section) {
    final cubit = context.read<AdminSettingsCubit>();
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider<AdminSettingsCubit>.value(
        value: cubit,
        child: _EditVendorSectionDialog(section: section),
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    VendorSection section,
    AdminSettingsCubit cubit,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          AppLocalizations.of(context)!.deleteSection,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        content: Text(
          AppLocalizations.of(context)!.deleteSectionConfirm(section.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(dialogContext);
              cubit.deleteVendorSection(section.id);
            },
            child: Text(
              AppLocalizations.of(context)!.delete,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _VendorSectionTile extends StatelessWidget {
  const _VendorSectionTile({
    required this.section,
    required this.accentColor,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final VendorSection section;
  final Color accentColor;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: section.imageUrl != null && section.imageUrl!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                section.imageUrl!,
                width: 36,
                height: 36,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _defaultLeading(),
              ),
            )
          : _defaultLeading(),
      title: Text(
        section.name,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: section.isActive ? AdminTheme.textDark : AdminTheme.textLight,
        ),
      ),
      subtitle: Text(
        section.nameAr,
        style: TextStyle(fontSize: 12, color: AdminTheme.textLight),
        textDirection: TextDirection.rtl,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(
            value: section.isActive,
            activeTrackColor: accentColor.withValues(alpha: 0.5),
            thumbColor: WidgetStateProperty.resolveWith(
              (states) =>
                  states.contains(WidgetState.selected) ? accentColor : null,
            ),
            onChanged: (_) => onToggle(),
          ),
          IconButton(
            icon: Icon(Icons.edit, size: 18, color: accentColor),
            onPressed: onEdit,
            tooltip: 'Edit',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
            onPressed: onDelete,
            tooltip: 'Delete',
          ),
        ],
      ),
    );
  }

  Widget _defaultLeading() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.label_outline, size: 18, color: accentColor),
    );
  }
}

class _AddVendorSectionDialog extends StatefulWidget {
  const _AddVendorSectionDialog({required this.vendorType});
  final VendorType vendorType;

  @override
  State<_AddVendorSectionDialog> createState() =>
      _AddVendorSectionDialogState();
}

class _AddVendorSectionDialogState extends State<_AddVendorSectionDialog> {
  final _nameCtrl = TextEditingController();
  final _nameArCtrl = TextEditingController();
  XFile? _pickedImage;
  Uint8List? _imageBytes;
  bool _isSaving = false;
  double _uploadProgress = 0;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nameArCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImageUtils.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _pickedImage = picked;
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty || _nameArCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.bothEnglishAndArabic),
        ),
      );
      return;
    }
    setState(() => _isSaving = true);

    try {
      String? imageUrl;
      if (_pickedImage != null) {
        final uploadResult = await UploadUtils.uploadXFile(
          xFile: _pickedImage!,
          folder: 'vendor_sections',
          onProgress: (p) {
            if (mounted) setState(() => _uploadProgress = p);
          },
        );
        imageUrl = uploadResult.url;
      }

      if (!mounted) return;
      Navigator.pop(context);
      await context.read<AdminSettingsCubit>().createVendorSection(
        name: _nameCtrl.text.trim(),
        nameAr: _nameArCtrl.text.trim(),
        vendorType: widget.vendorType,
        isActive: true,
        imageUrl: imageUrl,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorOccurred),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.vendorType == VendorType.supermarket
        ? AppLocalizations.of(context)!.addSupermarketSection
        : AppLocalizations.of(context)!.addPharmacySection;
    final color = widget.vendorType == VendorType.supermarket
        ? const Color(0xFF10B981)
        : const Color(0xFF3B82F6);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold, color: color),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildImagePicker(color),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.nameEnglishField,
                border: const OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameArCtrl,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.nameArabicField,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
          ),
          onPressed: _isSaving ? null : _submit,
          child: _isSaving
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                    value: _uploadProgress > 0 ? _uploadProgress : null,
                  ),
                )
              : Text(
                  AppLocalizations.of(context)!.create,
                  style: const TextStyle(color: Colors.white),
                ),
        ),
      ],
    );
  }

  Widget _buildImagePicker(Color color) {
    return GestureDetector(
      onTap: _isSaving ? null : _pickImage,
      child: Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: _imageBytes != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(_imageBytes!, fit: BoxFit.cover),
                    PositionedDirectional(
                      top: 4,
                      end: 4,
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _pickedImage = null;
                          _imageBytes = null;
                        }),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 36,
                    color: color.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppLocalizations.of(context)!.tapToUploadImageOptional,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
      ),
    );
  }
}

class _EditVendorSectionDialog extends StatefulWidget {
  const _EditVendorSectionDialog({required this.section});
  final VendorSection section;

  @override
  State<_EditVendorSectionDialog> createState() =>
      _EditVendorSectionDialogState();
}

class _EditVendorSectionDialogState extends State<_EditVendorSectionDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _nameArCtrl;
  XFile? _pickedImage;
  Uint8List? _imageBytes;
  String? _existingImageUrl;
  bool _imageRemoved = false;
  bool _isSaving = false;
  double _uploadProgress = 0;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.section.name);
    _nameArCtrl = TextEditingController(text: widget.section.nameAr);
    _existingImageUrl = widget.section.imageUrl;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nameArCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImageUtils.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _pickedImage = picked;
        _imageBytes = bytes;
        _imageRemoved = false;
      });
    }
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty || _nameArCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.bothEnglishAndArabic),
        ),
      );
      return;
    }
    setState(() => _isSaving = true);

    try {
      String? imageUrl = _imageRemoved ? null : _existingImageUrl;
      if (_pickedImage != null) {
        final uploadResult = await UploadUtils.uploadXFile(
          xFile: _pickedImage!,
          folder: 'vendor_sections',
          onProgress: (p) {
            if (mounted) setState(() => _uploadProgress = p);
          },
        );
        imageUrl = uploadResult.url;
      }

      if (!mounted) return;
      Navigator.pop(context);
      await context.read<AdminSettingsCubit>().updateVendorSection(
        widget.section.copyWith(
          name: _nameCtrl.text.trim(),
          nameAr: _nameArCtrl.text.trim(),
          imageUrl: imageUrl,
          clearImageUrl: _imageRemoved && _pickedImage == null,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorOccurred),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.section.vendorType == VendorType.supermarket
        ? const Color(0xFF10B981)
        : const Color(0xFF3B82F6);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        AppLocalizations.of(context)!.editSection,
        style: TextStyle(fontWeight: FontWeight.bold, color: color),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildImagePicker(color),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.nameEnglishField,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameArCtrl,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.nameArabicField,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
          ),
          onPressed: _isSaving ? null : _submit,
          child: _isSaving
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                    value: _uploadProgress > 0 ? _uploadProgress : null,
                  ),
                )
              : Text(
                  AppLocalizations.of(context)!.save,
                  style: const TextStyle(color: Colors.white),
                ),
        ),
      ],
    );
  }

  Widget _buildImagePicker(Color color) {
    final hasExisting =
        !_imageRemoved &&
        _existingImageUrl != null &&
        _existingImageUrl!.isNotEmpty &&
        _pickedImage == null;

    return GestureDetector(
      onTap: _isSaving ? null : _pickImage,
      child: Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: _imageBytes != null
            ? _imagePreview(
                child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                onRemove: () => setState(() {
                  _pickedImage = null;
                  _imageBytes = null;
                }),
              )
            : hasExisting
            ? _imagePreview(
                child: Image.network(
                  _existingImageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _placeholder(color),
                ),
                onRemove: () => setState(() => _imageRemoved = true),
              )
            : _placeholder(color),
      ),
    );
  }

  Widget _imagePreview({
    required Widget child,
    required VoidCallback onRemove,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(11),
      child: Stack(
        fit: StackFit.expand,
        children: [
          child,
          PositionedDirectional(
            top: 4,
            end: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder(Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 36,
          color: color.withValues(alpha: 0.6),
        ),
        const SizedBox(height: 6),
        Text(
          AppLocalizations.of(context)!.tapToUploadImageOptional,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

class _CuisineTypeTile extends StatelessWidget {
  const _CuisineTypeTile({
    required this.cuisineType,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final CuisineType cuisineType;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  Widget _buildLeading() {
    if (cuisineType.imageUrl != null && cuisineType.imageUrl!.isNotEmpty) {
      final imgUrl = cuisineType.imageUrl!;
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: imgUrl.startsWith('assets/')
            ? Image.asset(
                imgUrl,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _placeholder(),
              )
            : Image.network(
                imgUrl,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _placeholder(),
              ),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: AdminTheme.primaryOrange.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Icon(Icons.restaurant, size: 18, color: AdminTheme.primaryOrange),
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        children: [
          _buildLeading(),
          const SizedBox(width: 12),
          // Name column — Expanded so it takes remaining space without overflow.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cuisineType.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: cuisineType.isActive
                        ? AdminTheme.textDark
                        : AdminTheme.textLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  cuisineType.nameAr,
                  style: TextStyle(fontSize: 12, color: AdminTheme.textLight),
                  textDirection: TextDirection.rtl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Fixed-width trailing actions — won't push the name column.
          Switch(
            value: cuisineType.isActive,
            activeTrackColor: AdminTheme.primaryOrange.withValues(alpha: 0.5),
            thumbColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? AdminTheme.primaryOrange
                  : null,
            ),
            onChanged: (_) => onToggle(),
          ),
          IconButton(
            icon: Icon(Icons.edit, size: 18, color: AdminTheme.primaryOrange),
            onPressed: onEdit,
            tooltip: 'Edit',
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
            onPressed: onDelete,
            tooltip: 'Delete',
          ),
        ],
      ),
    );
  }
}

class _VersionSettingsSection extends StatefulWidget {
  const _VersionSettingsSection();

  @override
  State<_VersionSettingsSection> createState() =>
      _VersionSettingsSectionState();
}

class _VersionSettingsSectionState extends State<_VersionSettingsSection> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _minVersionCtrl;
  late TextEditingController _latestVersionCtrl;
  late TextEditingController _iosUrlCtrl;
  late TextEditingController _androidUrlCtrl;
  late TextEditingController _fallbackUrlCtrl;

  @override
  void initState() {
    super.initState();
    final state = context.read<AdminSettingsCubit>().state;
    _minVersionCtrl = TextEditingController(text: state.minRequiredVersion);
    _latestVersionCtrl = TextEditingController(text: state.latestVersion);
    _iosUrlCtrl = TextEditingController(text: state.iosUpdateUrl);
    _androidUrlCtrl = TextEditingController(text: state.androidUpdateUrl);
    _fallbackUrlCtrl = TextEditingController(text: state.updateUrl);
  }

  @override
  void dispose() {
    _minVersionCtrl.dispose();
    _latestVersionCtrl.dispose();
    _iosUrlCtrl.dispose();
    _androidUrlCtrl.dispose();
    _fallbackUrlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = context.watch<AuthCubit>().state.user;
    final isSuperAdmin = user?.type == UserType.superAdmin;

    return BlocConsumer<AdminSettingsCubit, AdminSettingsState>(
      listenWhen: (prev, curr) =>
          prev.minRequiredVersion != curr.minRequiredVersion ||
          prev.latestVersion != curr.latestVersion ||
          prev.iosUpdateUrl != curr.iosUpdateUrl ||
          prev.androidUpdateUrl != curr.androidUpdateUrl ||
          prev.updateUrl != curr.updateUrl,
      listener: (context, state) {
        _minVersionCtrl.text = state.minRequiredVersion;
        _latestVersionCtrl.text = state.latestVersion;
        _iosUrlCtrl.text = state.iosUpdateUrl;
        _androidUrlCtrl.text = state.androidUpdateUrl;
        _fallbackUrlCtrl.text = state.updateUrl;
      },
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AdminTheme.surfaceWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AdminTheme.borderColor),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n?.versionSettingsTitle ?? 'App Update Configuration',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AdminTheme.textDark,
                  ),
                ),
                if (!isSuperAdmin) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n?.onlySuperAdminCanEdit ??
                        'Only super admin can modify these settings',
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Min Version & Latest Version in a Row
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _minVersionCtrl,
                        enabled: isSuperAdmin,
                        decoration: InputDecoration(
                          labelText:
                              l10n?.minRequiredVersionLabel ??
                              'Minimum Required Version',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _latestVersionCtrl,
                        enabled: isSuperAdmin,
                        decoration: InputDecoration(
                          labelText:
                              l10n?.latestVersionLabel ?? 'Latest App Version',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // iOS Update URL
                TextField(
                  controller: _iosUrlCtrl,
                  enabled: isSuperAdmin,
                  decoration: InputDecoration(
                    labelText:
                        l10n?.iosUrlLabel ?? 'iOS Update URL (App Store)',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Android Update URL
                TextField(
                  controller: _androidUrlCtrl,
                  enabled: isSuperAdmin,
                  decoration: InputDecoration(
                    labelText:
                        l10n?.androidUrlLabel ??
                        'Android Update URL (Play Store)',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Fallback Update URL
                TextField(
                  controller: _fallbackUrlCtrl,
                  enabled: isSuperAdmin,
                  decoration: InputDecoration(
                    labelText: l10n?.fallbackUrlLabel ?? 'Fallback Update URL',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),

                // Save button
                if (isSuperAdmin)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        await context
                            .read<AdminSettingsCubit>()
                            .updateVersionSettings(
                              userType: UserType.superAdmin,
                              minRequiredVersion: _minVersionCtrl.text.trim(),
                              latestVersion: _latestVersionCtrl.text.trim(),
                              iosUpdateUrl: _iosUrlCtrl.text.trim(),
                              androidUpdateUrl: _androidUrlCtrl.text.trim(),
                              updateUrl: _fallbackUrlCtrl.text.trim(),
                            );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                l10n?.settingsSaved ??
                                    'Settings saved successfully',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminTheme.primaryOrange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        l10n?.saveSettings ?? 'Save Settings',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DriverEarningsLimitSection extends StatefulWidget {
  const _DriverEarningsLimitSection();

  @override
  State<_DriverEarningsLimitSection> createState() =>
      _DriverEarningsLimitSectionState();
}

class _DriverEarningsLimitSectionState
    extends State<_DriverEarningsLimitSection> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _limitCtrl;

  @override
  void initState() {
    super.initState();
    final state = context.read<AdminSettingsCubit>().state;
    _limitCtrl = TextEditingController(
      text: state.driverEarningsLimit.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _limitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = context.watch<AuthCubit>().state.user;
    final isSuperAdmin = user?.type == UserType.superAdmin;

    return BlocConsumer<AdminSettingsCubit, AdminSettingsState>(
      listenWhen: (prev, curr) =>
          prev.driverEarningsLimit != curr.driverEarningsLimit,
      listener: (context, state) {
        _limitCtrl.text = state.driverEarningsLimit.toStringAsFixed(2);
      },
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AdminTheme.surfaceWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AdminTheme.borderColor),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Driver Earnings Limit Settings',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AdminTheme.textDark,
                  ),
                ),
                if (!isSuperAdmin) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Only super admin can modify these settings',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Global Driver Earnings Limit TextField
                TextFormField(
                  controller: _limitCtrl,
                  enabled: isSuperAdmin,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Global Earnings Limit (EGP)',
                    helperText:
                        '0.0 or empty means no limit. Drivers will be locked when unpaid card earnings reach this limit.',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return null;
                    if (double.tryParse(val.trim()) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Save button
                if (isSuperAdmin)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState?.validate() ?? false) {
                          final value =
                              double.tryParse(_limitCtrl.text.trim()) ?? 0.0;
                          await context
                              .read<AdminSettingsCubit>()
                              .updateDriverEarningsLimit(
                                value,
                                UserType.superAdmin,
                              );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  l10n?.settingsSaved ??
                                      'Settings saved successfully',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminTheme.primaryOrange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        l10n?.saveSettings ?? 'Save Settings',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

