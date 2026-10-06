import 'package:z_speed/l10n/app_localizations.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:z_speed/core/utils/image_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:z_speed/core/enums/user_enums.dart';
import 'package:z_speed/features/restaurant_owner/cubit/restaurant_menu_cubit.dart';
import 'package:z_speed/features/restaurant/model/menu_item.dart';
import 'package:z_speed/features/restaurant/model/menu_item_variant.dart';
import 'package:z_speed/features/restaurant/model/cuisine_type.dart';
import 'package:z_speed/features/restaurant/model/menu_section.dart';
import 'package:z_speed/features/restaurant/model/vendor_section.dart';

/// Full-page dialog for adding or editing a menu item.
///
/// Features:
/// - Cuisine type dropdown (required, replaces old section picker)
/// - Name (English + Arabic, both required)
/// - Description (English + Arabic, both required)
/// - Image upload (required for new items)
/// - Price, discounted price, availability toggle
class AddEditItemDialog extends StatefulWidget {
  const AddEditItemDialog({
    super.key,
    required this.viewModel,
    required this.restaurantId,
    this.cuisineTypeId,
    this.item,
    this.vendorType = VendorType.restaurant,
  });

  final RestaurantMenuCubit viewModel;
  final String restaurantId;
  final String? cuisineTypeId;
  final MenuItem? item;
  final VendorType vendorType;

  @override
  State<AddEditItemDialog> createState() => _AddEditItemDialogState();
}

class _AddEditItemDialogState extends State<AddEditItemDialog> {
  late TextEditingController _nameController;
  late TextEditingController _nameArController;
  late TextEditingController _descriptionController;
  late TextEditingController _descriptionArController;
  late TextEditingController _priceController;
  late TextEditingController _discountedPriceController;
  late TextEditingController _stockController;
  late TextEditingController _warningLimitController;
  bool _isAvailable = true;
  bool _isSaving = false;
  String? _selectedCuisineTypeId;
  XFile? _pickedImage;
  String? _existingImageUrl;
  List<MenuItemVariant> _variants = [];

  static const _primaryOrange = Color(0xFFF35535);

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameController = TextEditingController(text: item?.name ?? '');
    _nameArController = TextEditingController(text: item?.nameAr ?? '');
    _descriptionController = TextEditingController(
      text: item?.description ?? '',
    );
    _descriptionArController = TextEditingController(
      text: item?.descriptionAr ?? '',
    );
    _priceController = TextEditingController(
      text: item?.price.toString() ?? '',
    );
    _discountedPriceController = TextEditingController(
      text: item?.discountedPrice?.toString() ?? '',
    );
    _stockController = TextEditingController(
      text: item?.stock?.toString() ?? '',
    );
    _warningLimitController = TextEditingController(
      text: item?.warningLimit?.toString() ?? '',
    );
    _isAvailable = item?.isAvailable ?? true;
    _selectedCuisineTypeId = item?.sectionId ?? widget.cuisineTypeId;
    _existingImageUrl = item?.imageUrl;
    _variants = item?.variants != null
        ? List<MenuItemVariant>.from(item!.variants)
        : [];
    // Pre-select last used section when opening for a new item with no pre-selection
    if (_selectedCuisineTypeId == null) {
      _loadLastCuisineType();
    }
  }

  Future<void> _loadLastCuisineType() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('menu_last_section_${widget.restaurantId}');
    if (saved != null && mounted) {
      setState(() => _selectedCuisineTypeId = saved);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameArController.dispose();
    _descriptionController.dispose();
    _descriptionArController.dispose();
    _priceController.dispose();
    _discountedPriceController.dispose();
    _stockController.dispose();
    _warningLimitController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final image = await ImageUtils.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _pickedImage = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.failedToPickImage(e.toString()),
            ),
          ),
        );
      }
    }
  }

  Future<void> _save() async {
    // Clear previous error
    setState(() => _errorMessage = null);

    // === Validation ===
    if (_selectedCuisineTypeId == null) {
      _showError(AppLocalizations.of(context)!.pleaseSelectCuisineType);
      return;
    }

    if (_nameController.text.trim().isEmpty) {
      _showError(AppLocalizations.of(context)!.englishNameRequired);
      return;
    }

    if (_nameArController.text.trim().isEmpty) {
      _showError(AppLocalizations.of(context)!.arabicNameRequired);
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      _showError(AppLocalizations.of(context)!.englishDescriptionRequired);
      return;
    }

    if (_descriptionArController.text.trim().isEmpty) {
      _showError(AppLocalizations.of(context)!.arabicDescriptionRequired);
      return;
    }

    if (_priceController.text.trim().isEmpty) {
      _showError(AppLocalizations.of(context)!.priceRequired);
      return;
    }

    final price = double.tryParse(_priceController.text);
    if (price == null || price <= 0) {
      _showError(AppLocalizations.of(context)!.invalidPrice);
      return;
    }

    final discountedPriceText = _discountedPriceController.text.trim();
    final double? discountedPrice = discountedPriceText.isEmpty
        ? null
        : double.tryParse(discountedPriceText);

    if (discountedPrice != null && discountedPrice >= price) {
      _showError(AppLocalizations.of(context)!.salePriceError);
      return;
    }

    // Image required for new items
    if (widget.item == null && _pickedImage == null) {
      _showError(AppLocalizations.of(context)!.pleaseUploadImage);
      return;
    }

    final bool isMarket =
        widget.vendorType == VendorType.supermarket ||
        widget.vendorType == VendorType.pharmacy ||
        widget.vendorType == VendorType.bookstore ||
        widget.vendorType == VendorType.homeFurnishing ||
        widget.vendorType == VendorType.meatAndProteins ||
        widget.vendorType == VendorType.clothes ||
        widget.vendorType == VendorType.buyAndSell ||
        widget.vendorType == VendorType.electronics;
    final int? stock = isMarket
        ? int.tryParse(_stockController.text.trim())
        : null;
    final int? warningLimit = isMarket
        ? int.tryParse(_warningLimitController.text.trim())
        : null;

    setState(() => _isSaving = true);

    try {
      // Upload image if picked
      String imageUrl = _existingImageUrl ?? '';
      if (_pickedImage != null) {
        final uploadedUrl = await widget.viewModel.uploadItemImage(
          _pickedImage!,
        );
        if (uploadedUrl == null) {
          if (!mounted) return;
          _showError(AppLocalizations.of(context)!.failedToUploadImage);
          setState(() => _isSaving = false);
          return;
        }
        imageUrl = uploadedUrl;
      }

      if (widget.item == null) {
        // Create new item
        await widget.viewModel.createItem(
          cuisineTypeId: _selectedCuisineTypeId!,
          name: _nameController.text.trim(),
          nameAr: _nameArController.text.trim(),
          description: _descriptionController.text.trim(),
          descriptionAr: _descriptionArController.text.trim(),
          price: price,
          discountedPrice: discountedPrice,
          imageUrl: imageUrl,
          stock: stock,
          warningLimit: warningLimit,
          variants: _variants,
        );
      } else {
        // Update existing item
        final updated = widget.item!.copyWith(
          sectionId: _selectedCuisineTypeId,
          name: _nameController.text.trim(),
          nameAr: _nameArController.text.trim(),
          description: _descriptionController.text.trim(),
          descriptionAr: _descriptionArController.text.trim(),
          price: price,
          discountedPrice: discountedPrice,
          imageUrl: imageUrl,
          isAvailable: _isAvailable,
          stock: stock,
          warningLimit: warningLimit,
          updatedAt: DateTime.now(),
          variants: _variants,
        );
        await widget.viewModel.updateItem(widget.item!.sectionId, updated);
      }

      // Persist the last-used section so the next new item pre-selects it
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'menu_last_section_${widget.restaurantId}',
        _selectedCuisineTypeId!,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.item == null
                  ? AppLocalizations.of(context)!.itemCreated
                  : AppLocalizations.of(context)!.itemUpdated,
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError(
          AppLocalizations.of(context)!.failedToSaveItem(e.toString()),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String? _errorMessage;

  void _showError(String message) {
    setState(() => _errorMessage = message);
  }

  @override
  Widget build(BuildContext context) {
    final bool isMarket =
        widget.vendorType == VendorType.supermarket ||
        widget.vendorType == VendorType.pharmacy ||
        widget.vendorType == VendorType.bookstore ||
        widget.vendorType == VendorType.homeFurnishing ||
        widget.vendorType == VendorType.meatAndProteins ||
        widget.vendorType == VendorType.clothes ||
        widget.vendorType == VendorType.buyAndSell ||
        widget.vendorType == VendorType.electronics;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: _primaryOrange,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.item == null
                          ? AppLocalizations.of(context)!.addMenuItem
                          : AppLocalizations.of(context)!.editMenuItem,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: _isSaving
                        ? null
                        : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Error Banner
            if (_errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                color: Colors.red.shade50,
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _errorMessage = null),
                      child: const Icon(
                        Icons.close,
                        color: Colors.red,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Dropdown (label adapts to vendor type)
                    _buildLabel(_sectionLabel(context)),
                    const SizedBox(height: 6),
                    _buildSectionDropdown(),
                    const SizedBox(height: 20),

                    // Image Upload
                    _buildLabel(
                      AppLocalizations.of(context)!.itemImageRequired,
                    ),
                    const SizedBox(height: 6),
                    _buildImagePicker(),
                    const SizedBox(height: 20),

                    // Name (English)
                    _buildLabel(
                      AppLocalizations.of(context)!.itemNameEnglishRequired,
                    ),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: _nameController,
                      hint: AppLocalizations.of(context)!.itemNameEnglishHint,
                    ),
                    const SizedBox(height: 16),

                    // Name (Arabic)
                    _buildLabel(
                      AppLocalizations.of(context)!.itemNameArabicRequired,
                    ),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: _nameArController,
                      hint: AppLocalizations.of(context)!.itemNameArabicHint,
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 16),

                    // Description (English)
                    _buildLabel(
                      AppLocalizations.of(context)!.descriptionEnglishRequired,
                    ),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: _descriptionController,
                      hint: AppLocalizations.of(
                        context,
                      )!.descriptionEnglishHint,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    // Description (Arabic)
                    _buildLabel(
                      AppLocalizations.of(context)!.descriptionArabicRequired,
                    ),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: _descriptionArController,
                      hint: AppLocalizations.of(context)!.descriptionArabicHint,
                      maxLines: 3,
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 16),

                    // Price row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel(
                                AppLocalizations.of(context)!.priceEgpRequired,
                              ),
                              const SizedBox(height: 6),
                              _buildTextField(
                                controller: _priceController,
                                hint: '0.00',
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                prefixText: 'EGP ',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel(
                                AppLocalizations.of(context)!.salePriceEgp,
                              ),
                              const SizedBox(height: 6),
                              _buildTextField(
                                controller: _discountedPriceController,
                                hint: AppLocalizations.of(context)!.optional,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                prefixText: 'EGP ',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Stock & Warning Limit
                    if (isMarket) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Stock Quantity'),
                                const SizedBox(height: 6),
                                _buildTextField(
                                  controller: _stockController,
                                  hint: '0',
                                  keyboardType: TextInputType.number,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Warning Limit'),
                                const SizedBox(height: 6),
                                _buildTextField(
                                  controller: _warningLimitController,
                                  hint: '0',
                                  keyboardType: TextInputType.number,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],

                    _buildVariantsSection(),
                    const SizedBox(height: 20),

                    // Availability toggle (only for edits)
                    if (widget.item != null) ...[
                      Row(
                        children: [
                          Switch(
                            value: _isAvailable,
                            activeThumbColor: _primaryOrange,
                            onChanged: (v) => setState(() => _isAvailable = v),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isAvailable
                                ? AppLocalizations.of(context)!.available
                                : AppLocalizations.of(context)!.unavailable,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _isAvailable ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Footer actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: Text(
                      AppLocalizations.of(context)!.cancel,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryOrange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 12,
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            widget.item == null
                                ? AppLocalizations.of(context)!.createItem
                                : AppLocalizations.of(context)!.saveChanges,
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF333333),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? prefixText,
    TextDirection? textDirection,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textDirection: textDirection,
      decoration: InputDecoration(
        hintText: hint,
        prefixText: prefixText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _primaryOrange, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }

  String _sectionLabel(BuildContext context) {
    switch (widget.vendorType) {
      case VendorType.supermarket:
        return 'Market Section *';
      case VendorType.pharmacy:
        return 'Pharmacy Section *';
      case VendorType.bookstore:
        return 'Library Section *';
      case VendorType.homeFurnishing:
        return 'Furnishing Section *';
      case VendorType.meatAndProteins:
        return 'Meat Section *';
      case VendorType.clothes:
        return 'Clothing Section *';
      case VendorType.buyAndSell:
        return 'Marketplace Section *';
      case VendorType.electronics:
        return 'Electronics Section *';
      case VendorType.restaurant:
        return AppLocalizations.of(context)!.cuisineTypeRequired;
    }
  }

  Widget _buildSectionDropdown() {
    final items = <DropdownMenuItem<String>>[];

    if (widget.vendorType == VendorType.restaurant) {
      final cuisineTypes = widget.viewModel.state.cuisineTypes
          .where((ct) => ct.isActive)
          .toList();
      for (final ct in cuisineTypes) {
        items.add(
          DropdownMenuItem(
            value: ct.id,
            child: Text('${ct.name} - ${ct.nameAr}'),
          ),
        );
      }
    } else {
      final vendorSections = widget.viewModel.state.vendorSections
          .where((s) => s.isActive)
          .toList();
      for (final vs in vendorSections) {
        items.add(
          DropdownMenuItem(
            value: vs.id,
            child: Text('${vs.name} - ${vs.nameAr}'),
          ),
        );
      }
    }

    if (_selectedCuisineTypeId != null) {
      final hasSelected = items.any(
        (item) => item.value == _selectedCuisineTypeId,
      );
      if (!hasSelected) {
        String? displayName;
        if (widget.vendorType == VendorType.restaurant) {
          final ct = widget.viewModel.state.cuisineTypes
              .cast<CuisineType?>()
              .firstWhere(
                (c) => c!.id == _selectedCuisineTypeId,
                orElse: () => null,
              );
          if (ct != null) {
            displayName = '${ct.name} - ${ct.nameAr}';
          } else {
            final sec = widget.viewModel.state.sections
                .cast<MenuSection?>()
                .firstWhere(
                  (s) => s!.id == _selectedCuisineTypeId,
                  orElse: () => null,
                );
            if (sec != null) {
              displayName = '${sec.name} - ${sec.nameAr}';
            }
          }
        } else {
          final vs = widget.viewModel.state.vendorSections
              .cast<VendorSection?>()
              .firstWhere(
                (s) => s!.id == _selectedCuisineTypeId,
                orElse: () => null,
              );
          if (vs != null) {
            displayName = '${vs.name} - ${vs.nameAr}';
          }
        }

        final label = displayName != null
            ? '$displayName (${AppLocalizations.of(context)!.inactive})'
            : '${AppLocalizations.of(context)!.inactive} ($_selectedCuisineTypeId)';

        items.add(
          DropdownMenuItem(value: _selectedCuisineTypeId, child: Text(label)),
        );
      }
    }

    final hint = widget.vendorType == VendorType.restaurant
        ? AppLocalizations.of(context)!.selectCuisineType
        : 'Select section';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCuisineTypeId,
          hint: Text(hint),
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: _primaryOrange),
          items: items,
          onChanged: (value) => setState(() => _selectedCuisineTypeId = value),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    final hasImage =
        _pickedImage != null || (_existingImageUrl?.isNotEmpty ?? false);

    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasImage ? _primaryOrange : Colors.grey.shade300,
            width: hasImage ? 2 : 1,
          ),
        ),
        child: _pickedImage != null
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: kIsWeb
                        ? Image.network(
                            _pickedImage!.path,
                            width: double.infinity,
                            height: 150,
                            fit: BoxFit.contain,
                          )
                        : FutureBuilder<Uint8List>(
                            future: _pickedImage!.readAsBytes(),
                            builder: (context, snap) {
                              if (snap.hasData) {
                                return Image.memory(
                                  snap.data!,
                                  width: double.infinity,
                                  height: 150,
                                  fit: BoxFit.contain,
                                );
                              }
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                          ),
                  ),
                  const PositionedDirectional(
                    top: 8,
                    end: 8,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: _primaryOrange,
                      child: Icon(Icons.edit, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              )
            : (_existingImageUrl?.isNotEmpty ?? false)
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Image.network(
                      _existingImageUrl!,
                      width: double.infinity,
                      height: 150,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => _buildImagePlaceholder(),
                    ),
                  ),
                  const PositionedDirectional(
                    top: 8,
                    end: 8,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: _primaryOrange,
                      child: Icon(Icons.edit, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              )
            : _buildImagePlaceholder(),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 40,
          color: Colors.grey[400],
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context)!.tapToUploadImage,
          style: TextStyle(color: Colors.grey[500], fontSize: 13),
        ),
        const SizedBox(height: 4),
        Text(
          AppLocalizations.of(context)!.imageRequirements,
          style: TextStyle(color: Colors.grey[400], fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildVariantsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Product Variants',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Manage options (e.g. sizes, packages)',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: () => _showVariantFormDialog(),
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text('Add Option'),
              style: TextButton.styleFrom(
                foregroundColor: _primaryOrange,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_variants.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.grey.shade200,
                style: BorderStyle.solid,
              ),
            ),
            child: Center(
              child: Text(
                'No variants added yet. Tap "Add Option" to create one.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _variants.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final variant = _variants[index];
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            variant.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (variant.nameAr != null &&
                              variant.nameAr!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              variant.nameAr!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _primaryOrange.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'EGP ${variant.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _primaryOrange,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 20,
                        color: Colors.blue,
                      ),
                      onPressed: () => _showVariantFormDialog(
                        variant: variant,
                        index: index,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: Colors.red,
                      ),
                      onPressed: () {
                        setState(() {
                          _variants.removeAt(index);
                        });
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  void _showVariantFormDialog({MenuItemVariant? variant, int? index}) {
    final nameController = TextEditingController(text: variant?.name ?? '');
    final nameArController = TextEditingController(text: variant?.nameAr ?? '');
    final priceController = TextEditingController(
      text: variant?.price.toString() ?? '',
    );
    bool isAvailable = variant?.isAvailable ?? true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                variant == null ? 'Add Variant Option' : 'Edit Variant Option',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Option Name (English) *'),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: nameController,
                      hint: 'e.g. Medium, 30 Tablets',
                    ),
                    const SizedBox(height: 12),
                    _buildLabel('Option Name (Arabic)'),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: nameArController,
                      hint: 'مثال: متوسط، ٣٠ قرص',
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 12),
                    _buildLabel('Price (EGP) *'),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: priceController,
                      hint: '0.00',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      prefixText: 'EGP ',
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Switch(
                          value: isAvailable,
                          activeThumbColor: _primaryOrange,
                          onChanged: (val) {
                            setDialogState(() {
                              isAvailable = val;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isAvailable ? 'Available' : 'Unavailable',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isAvailable ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final priceStr = priceController.text.trim();

                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Name is required')),
                      );
                      return;
                    }

                    final price = double.tryParse(priceStr);
                    if (price == null || price < 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a valid price'),
                        ),
                      );
                      return;
                    }

                    final newVariant = MenuItemVariant(
                      id:
                          variant?.id ??
                          'var_${DateTime.now().microsecondsSinceEpoch}',
                      foodItemId: widget.item?.id ?? '',
                      name: name,
                      nameAr: nameArController.text.trim().isEmpty
                          ? null
                          : nameArController.text.trim(),
                      price: price,
                      isAvailable: isAvailable,
                    );

                    setState(() {
                      if (variant == null) {
                        _variants.add(newVariant);
                      } else {
                        _variants[index!] = newVariant;
                      }
                    });

                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
