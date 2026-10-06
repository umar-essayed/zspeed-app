import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import 'package:z_speed/l10n/app_localizations.dart';
import 'package:z_speed/core/enums/order_enums.dart';
import 'package:z_speed/core/enums/user_enums.dart';
import 'package:z_speed/core/services/payment_guard.dart';
import 'package:z_speed/features/auth/cubit/auth_cubit.dart';
import 'package:z_speed/features/cart/cubit/cart_cubit.dart';
import 'package:z_speed/features/customer/model/saved_address.dart';
import 'package:z_speed/features/payment/datasource/paylink_datasource.dart';
import 'package:z_speed/features/payment/model/saved_card_model.dart';
import 'package:z_speed/features/payment/view/paylink_webview_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:z_speed/features/payment/widgets/add_card_bottom_sheet.dart';
import 'package:z_speed/features/payment/widgets/saved_card_selector.dart';
import 'package:z_speed/features/payment/widgets/payment_status_sheet.dart';
import 'package:z_speed/features/order/view/order_tracking_screen.dart';
import 'package:z_speed/features/order/cubit/checkout_cubit.dart';
import 'package:z_speed/features/order/cubit/checkout_state.dart';
import 'package:z_speed/features/order/datasource/promo_code_datasource.dart';
import 'package:z_speed/features/order/model/promo_code.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/components/map_location_picker.dart';
import 'package:z_speed/features/customer/widgets/address_details_dialog.dart';

/// Checkout screen — order summary, delivery info, payment, and submission.
///
/// Replaces the old PaymentPage with real Firestore order creation.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();
  final _promoController = TextEditingController();
  final _paylinkDatasource = PaylinkDatasource();
  SavedCardModel? _selectedSavedCard;
  bool _useHostedCheckout = false;
  bool _isPickingLocation = false;
  bool _isProcessingOrder = false;

  @override
  void initState() {
    super.initState();

    // Initialize checkout (load restaurant details)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CheckoutCubit>().init();
    });
  }

  @override
  void dispose() {
    _addressController.dispose();
    _noteController.dispose();
    _promoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final checkoutCubit = context.read<CheckoutCubit>();
    final checkoutState = context.watch<CheckoutCubit>().state;
    final cartState = context.watch<CartCubit>().state;

    // Sync _addressController with state on load if empty but state has an address
    if (_addressController.text.isEmpty &&
        checkoutState.deliveryAddress.isNotEmpty) {
      _addressController.text = checkoutState.deliveryAddress;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.checkout,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF35535), Color(0xFFFF9800)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: checkoutState.isBusy
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Restaurant name header
                  if (checkoutState.restaurant != null) ...[
                    _buildRestaurantHeader(
                      checkoutState.restaurantName,
                      checkoutState.restaurant?.logoUrl,
                    ),
                    if (checkoutState.restaurant != null && !checkoutState.restaurant!.isOpen) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade400),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.storefront_rounded,
                                color: Colors.red.shade900, size: 22),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                AppLocalizations.of(context)!.vendorCurrentlyClosed(
                                  checkoutState.restaurant?.vendorType.label ??
                                      (Localizations.localeOf(context).languageCode == 'ar' ? 'المتجر' : 'Vendor'),
                                ),
                                style: TextStyle(
                                  color: Colors.red.shade900,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (checkoutState.restaurant != null && checkoutState.restaurant!.isBusy) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.shade400),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.access_time_filled_rounded,
                                color: Colors.amber.shade900, size: 22),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                AppLocalizations.of(context)!.vendorCurrentlyBusy,
                                style: TextStyle(
                                  color: Colors.amber.shade900,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],

                  const SizedBox(height: 20),

                  // Order summary section
                  _buildSectionHeader(
                    AppLocalizations.of(context)!.orderSummarySection,
                  ),
                  const SizedBox(height: 12),
                  _buildOrderItemsList(cartState.items),

                  const SizedBox(height: 24),

                  // Delivery address section
                  _buildSectionHeader(
                    AppLocalizations.of(context)!.deliveryAddressSection,
                  ),
                  const SizedBox(height: 12),
                  _buildDeliveryAddressInput(checkoutCubit),

                  const SizedBox(height: 24),

                  // Delivery instructions
                  _buildSectionHeader(
                    AppLocalizations.of(context)!.deliveryInstructionsSection,
                  ),
                  const SizedBox(height: 12),
                  _buildDeliveryNoteInput(checkoutCubit),

                  const SizedBox(height: 24),

                  // Payment method section
                  _buildSectionHeader(
                    AppLocalizations.of(context)!.paymentMethodSection,
                  ),
                  const SizedBox(height: 12),
                  _buildPaymentMethodSelector(checkoutCubit, checkoutState),
                  if (checkoutState.paymentMethod == PaymentMethodType.card) ...[
                    const SizedBox(height: 16),
                    SavedCardSelector(
                      datasource: _paylinkDatasource,
                      selectedCard: _selectedSavedCard,
                      useHostedCheckout: _useHostedCheckout,
                      onCardSelected: (card) => setState(() {
                        _selectedSavedCard = card;
                        _useHostedCheckout = false;
                      }),
                      onHostedCheckoutChanged: (val) => setState(() {
                        _useHostedCheckout = val;
                        if (val) _selectedSavedCard = null;
                      }),
                    ),
                  ] else if (checkoutState.paymentMethod == PaymentMethodType.wallet) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.account_balance_wallet_rounded,
                                color: Colors.green, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  Localizations.localeOf(context).languageCode == 'ar'
                                      ? 'الدفع بالمحافظ الإلكترونية (مصر)'
                                      : 'Mobile Wallets Payment (Egypt)',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.5,
                                    color: Color(0xFF166534),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  Localizations.localeOf(context).languageCode == 'ar'
                                      ? 'فودافون كاش، أورنج كاش، اتصالات كاش، وي باي والمحافظ الذكية. ستكتمل عملية الدفع عبر بوابة الدفع الآمنة.'
                                      : 'Vodafone Cash, Orange Cash, Etisalat Cash, WE Pay & smart bank wallets. Fast & secure checkout.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Promo code section
                  _buildSectionHeader(
                    AppLocalizations.of(context)!.promoCodeSection,
                  ),
                  const SizedBox(height: 12),
                  _buildPromoCodeInput(checkoutCubit),

                  const SizedBox(height: 24),

                  // Price breakdown
                  _buildSectionHeader(
                    AppLocalizations.of(context)!.priceBreakdownSection,
                  ),
                  const SizedBox(height: 12),
                  _buildPriceBreakdown(checkoutState),

                  const SizedBox(height: 16),

                  // Validation errors
                  if (checkoutState.validationErrors.isNotEmpty)
                    _buildValidationErrors(checkoutState.validationErrors),

                  const SizedBox(height: 100), // Space for sticky button
                ],
              ),
            ),
      bottomNavigationBar: _buildCheckoutFooter(checkoutCubit, checkoutState),
    );
  }

  Widget _buildRestaurantHeader(String name, String? logoUrl) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFF35535).withValues(alpha: 0.15),
                  const Color(0xFFFF9800).withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: logoUrl != null && logoUrl.isNotEmpty
                  ? Image.network(
                      logoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.storefront_rounded,
                        color: Color(0xFFF35535),
                        size: 24,
                      ),
                    )
                  : const Icon(
                      Icons.storefront_rounded,
                      color: Color(0xFFF35535),
                      size: 24,
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: Color(0xFF1A1A2E),
      ),
    );
  }

  Widget _buildOrderItemsList(List items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, _) =>
            Divider(height: 1, color: Colors.grey.shade100),
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF35535).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                    ? Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.fastfood_outlined,
                              color: Color(0xFFF35535),
                              size: 22,
                            ),
                      )
                    : const Icon(
                        Icons.fastfood_outlined,
                        color: Color(0xFFF35535),
                        size: 22,
                      ),
              ),
            ),
            title: Text(
              item.menuItemName,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: Color(0xFF1A1A2E),
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.selectedAddons.isNotEmpty)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(top: 4),
                    child: Text(
                      item.selectedAddons.map((a) => a.name).join(', '),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                if (item.specialNote != null && item.specialNote!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(top: 2),
                    child: Text(
                      '"${item.specialNote}"',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      AppLocalizations.of(
                        context,
                      )!.egpAmount(item.unitPrice.toStringAsFixed(2)),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF35535).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '× ${item.quantity.toStringAsFixed(item.quantity % 1 == 0 ? 0 : 1)} ${item.measureType.label}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFF35535),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Text(
              AppLocalizations.of(
                context,
              )!.egpAmount(item.itemTotal.toStringAsFixed(2).toString()),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: Color(0xFF1A1A2E),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDetailedAddress(SavedAddress savedAddr) {
    final isArabic = AppLocalizations.of(context)!.localeName == 'ar';
    if (isArabic) {
      final typeText = savedAddr.type == 'apartment'
          ? 'شقة'
          : (savedAddr.type == 'villa' ? 'فيلا' : 'مكتب');
      final buildingLabelText = savedAddr.type == 'villa' ? 'فيلا' : 'مبنى';
      final apartmentText =
          savedAddr.apartment != null && savedAddr.apartment!.isNotEmpty
          ? '، شقة: ${savedAddr.apartment}'
          : '';
      final floorText = savedAddr.floor != null && savedAddr.floor!.isNotEmpty
          ? '، دور: ${savedAddr.floor}'
          : '';
      final streetText =
          savedAddr.street != null && savedAddr.street!.isNotEmpty
          ? '، شارع: ${savedAddr.street}'
          : '';
      final landmarkText =
          savedAddr.landmark != null && savedAddr.landmark!.isNotEmpty
          ? '، علامة مميزة: ${savedAddr.landmark}'
          : '';
      final phoneText = savedAddr.phone != null && savedAddr.phone!.isNotEmpty
          ? '، هاتف: ${savedAddr.phone}'
          : '';

      return '$typeText ($buildingLabelText: ${savedAddr.building}$apartmentText$floorText$streetText$landmarkText$phoneText). المنطقة: ${savedAddr.address}';
    } else {
      final typeText = savedAddr.type == 'apartment'
          ? 'Apartment'
          : (savedAddr.type == 'villa' ? 'Villa' : 'Office');
      final buildingLabelText = savedAddr.type == 'villa'
          ? 'Villa'
          : 'Building';
      final apartmentText =
          savedAddr.apartment != null && savedAddr.apartment!.isNotEmpty
          ? ', Apt: ${savedAddr.apartment}'
          : '';
      final floorText = savedAddr.floor != null && savedAddr.floor!.isNotEmpty
          ? ', Floor: ${savedAddr.floor}'
          : '';
      final streetText =
          savedAddr.street != null && savedAddr.street!.isNotEmpty
          ? ', Street: ${savedAddr.street}'
          : '';
      final landmarkText =
          savedAddr.landmark != null && savedAddr.landmark!.isNotEmpty
          ? ', Landmark: ${savedAddr.landmark}'
          : '';
      final phoneText = savedAddr.phone != null && savedAddr.phone!.isNotEmpty
          ? ', Phone: ${savedAddr.phone}'
          : '';

      return '$typeText ($buildingLabelText: ${savedAddr.building}$apartmentText$floorText$streetText$landmarkText$phoneText). Area: ${savedAddr.address}';
    }
  }

  void _applyDetailedAddress(
    CheckoutCubit cubit,
    AuthCubit authCubit,
    SavedAddress savedAddr,
  ) {
    final formatted = _formatDetailedAddress(savedAddr);
    setState(() {
      _addressController.text = formatted;
    });
    cubit.setDeliveryAddress(
      formatted,
      lat: savedAddr.latitude,
      lng: savedAddr.longitude,
    );
    authCubit.addSavedAddress(savedAddr);
  }

  /// Shows saved addresses bottom sheet. Returns true if user picked one.
  Future<bool> _showSavedAddressPicker(
    CheckoutCubit cubit,
    List<SavedAddress> savedAddresses,
  ) async {
    final picked = await showModalBottomSheet<SavedAddress>(
      context: context,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              AppLocalizations.of(sheetContext)!.savedAddresses,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          ...savedAddresses.map(
            (addr) => ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFF35535).withValues(alpha: 0.1),
                child: const Icon(Icons.location_on, color: Color(0xFFF35535)),
              ),
              title: Text(
                addr.label,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                addr.address,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => Navigator.pop(sheetContext, addr),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
    if (picked == null) return false;

    final formatted = _formatDetailedAddress(picked);
    setState(() => _addressController.text = formatted);
    cubit.setDeliveryAddress(
      formatted,
      lat: picked.latitude,
      lng: picked.longitude,
    );
    return true;
  }

  Widget _buildDeliveryAddressInput(CheckoutCubit cubit) {
    final hasAddress = _addressController.text.isNotEmpty;
    final authCubit = context.read<AuthCubit>();
    final savedAddresses = authCubit.currentUser?.savedAddresses ?? [];

    return Column(
      children: [
        // Saved addresses quick-pick (shown only when addresses exist)
        if (savedAddresses.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showSavedAddressPicker(cubit, savedAddresses),
                icon: const Icon(
                  Icons.bookmark_outline,
                  color: Color(0xFFF35535),
                  size: 18,
                ),
                label: Text(
                  AppLocalizations.of(context)!.savedAddresses,
                  style: const TextStyle(
                    color: Color(0xFFF35535),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFF35535), width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: hasAddress ? Colors.white : const Color(0xFFFFF9F6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasAddress
                  ? Colors.grey.shade100
                  : const Color(0xFFFFD4C4),
              width: hasAddress ? 1.2 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: hasAddress
                    ? Colors.black.withValues(alpha: 0.03)
                    : const Color(0xFFF35535).withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _isPickingLocation
                ? null
                : () async {
                    SavedAddress? currentAddressObj;
                    // If an address is already selected, try to find it or create a transient edit model
                    if (cubit.state.deliveryAddress.isNotEmpty) {
                      currentAddressObj = savedAddresses.firstWhere(
                        (a) =>
                            (a.latitude - cubit.state.deliveryLat).abs() <
                                0.0001 &&
                            (a.longitude - cubit.state.deliveryLng).abs() <
                                0.0001,
                        orElse: () {
                          // Try parsing details from the formatted string, or fallback
                          return SavedAddress(
                            id: const Uuid().v4(),
                            label: 'CUSTOM',
                            address: cubit.state.deliveryAddress,
                            latitude: cubit.state.deliveryLat,
                            longitude: cubit.state.deliveryLng,
                          );
                        },
                      );
                    }

                    if (currentAddressObj != null) {
                      final savedAddr = await AddressDetailsDialog.show(
                        context,
                        initialLocation: LatLng(
                          currentAddressObj.latitude,
                          currentAddressObj.longitude,
                        ),
                        initialAddress: currentAddressObj.address,
                        existingAddress: currentAddressObj,
                      );

                      if (savedAddr != null && mounted) {
                        _applyDetailedAddress(cubit, authCubit, savedAddr);
                      }
                    } else {
                      setState(() => _isPickingLocation = true);
                      try {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MapLocationPicker(),
                          ),
                        );

                        if (result != null &&
                            result is Map<String, dynamic> &&
                            mounted) {
                          final address = result['address'] as String;
                          final lat = result['lat'] as double;
                          final lng = result['lng'] as double;

                          final savedAddr = await AddressDetailsDialog.show(
                            context,
                            initialLocation: LatLng(lat, lng),
                            initialAddress: address,
                          );

                          if (savedAddr != null && mounted) {
                            _applyDetailedAddress(cubit, authCubit, savedAddr);
                          }
                        }
                      } finally {
                        if (mounted) {
                          setState(() => _isPickingLocation = false);
                        }
                      }
                    }
                  },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: hasAddress
                          ? const Color(0xFFFFF3E0)
                          : const Color(0xFFFFEBE3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      hasAddress ? Icons.location_on : Icons.map_outlined,
                      color: const Color(0xFFF35535),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasAddress
                              ? AppLocalizations.of(context)!.deliveryLocation
                              : AppLocalizations.of(
                                  context,
                                )!.selectLocationOnMap,
                          style: TextStyle(
                            color: hasAddress
                                ? Colors.grey.shade600
                                : const Color(0xFFF35535),
                            fontSize: hasAddress ? 13 : 15,
                            fontWeight: hasAddress
                                ? FontWeight.normal
                                : FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hasAddress
                              ? _addressController.text
                              : AppLocalizations.of(
                                  context,
                                )!.tapToPinYourDeliveryLocation,
                          style: TextStyle(
                            color: hasAddress
                                ? const Color(0xFF1A1A2E)
                                : Colors.grey.shade500,
                            fontSize: hasAddress ? 15 : 13,
                            fontWeight: hasAddress
                                ? FontWeight.w700
                                : FontWeight.normal,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    hasAddress ? Icons.edit_outlined : Icons.chevron_right,
                    color: const Color(0xFFF35535),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryNoteInput(CheckoutCubit cubit) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _noteController,
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.ringDoorbellHint,
          filled: true,
          fillColor: Colors.grey.shade50,
          prefixIcon: const Icon(Icons.note_outlined, color: Color(0xFFF35535)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFF35535), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        maxLines: 2,
        onChanged: (value) {
          cubit.setCustomerNote(value);
        },
      ),
    );
  }

  Widget _buildPaymentMethodSelector(CheckoutCubit cubit, CheckoutState state) {
    return RadioGroup<PaymentMethodType>(
      groupValue: state.paymentMethod,
      onChanged: (value) {
        if (value != null) {
          cubit.setPaymentMethod(value);
        }
      },
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _buildPaymentCardWrapper(
                isSelected: state.paymentMethod == PaymentMethodType.cash,
                child: _buildHorizontalPaymentOption(
                  cubit,
                  state,
                  PaymentMethodType.cash,
                  AppLocalizations.of(context)!.cashOnDelivery,
                  Icons.payments_outlined,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildPaymentCardWrapper(
                isSelected: state.paymentMethod == PaymentMethodType.card,
                child: _buildHorizontalPaymentOption(
                  cubit,
                  state,
                  PaymentMethodType.card,
                  'Card',
                  Icons.credit_card,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildPaymentCardWrapper(
                isSelected: state.paymentMethod == PaymentMethodType.wallet,
                isEnabled: true,
                child: _buildHorizontalPaymentOption(
                  cubit,
                  state,
                  PaymentMethodType.wallet,
                  AppLocalizations.of(context)!.mobileWallet,
                  Icons.account_balance_wallet_outlined,
                  enabled: true,
                ),
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildPaymentCardWrapper({
    required Widget child,
    required bool isSelected,
    bool isEnabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFFF35535).withValues(alpha: 0.02)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? const Color(0xFFF35535) : Colors.grey.shade200,
          width: isSelected ? 1.8 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? const Color(0xFFF35535).withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(16), child: child),
    );
  }

  Widget _buildHorizontalPaymentOption(
    CheckoutCubit cubit,
    CheckoutState state,
    PaymentMethodType method,
    String label,
    IconData icon, {
    bool enabled = true,
    String? badge,
  }) {
    final isSelected = state.paymentMethod == method;

    // Shorten the labels for horizontal fit
    String displayLabel = label;
    if (method == PaymentMethodType.cash) {
      displayLabel = AppLocalizations.of(context)!.localeName == 'ar'
          ? 'نقدي'
          : 'Cash';
    } else if (method == PaymentMethodType.card) {
      displayLabel = AppLocalizations.of(context)!.localeName == 'ar'
          ? 'بطاقة'
          : 'Card';
    } else if (method == PaymentMethodType.wallet) {
      displayLabel = AppLocalizations.of(context)!.localeName == 'ar'
          ? 'محفظة'
          : 'Wallet';
    }

    return InkWell(
      onTap: enabled ? () => cubit.setPaymentMethod(method) : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 28,
                      color: enabled
                          ? (isSelected
                                ? const Color(0xFFF35535)
                                : Colors.grey.shade600)
                          : Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      displayLabel,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w600,
                        color: enabled
                            ? (isSelected
                                  ? const Color(0xFFF35535)
                                  : Colors.grey.shade700)
                            : Colors.grey.shade400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (badge != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF35535).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFF35535),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (isSelected)
              const Positioned(
                top: 8,
                right: 8,
                child: Icon(
                  Icons.check_circle,
                  color: Color(0xFFF35535),
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoCodeInput(CheckoutCubit cubit) {
    final checkoutState = context.watch<CheckoutCubit>().state;
    final isLoading = checkoutState.promoStatus == PromoStatus.loading;
    final isValid = checkoutState.promoStatus == PromoStatus.valid;
    final isInvalid = checkoutState.promoStatus == PromoStatus.invalid;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _promoController,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.enterPromoCode,
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isValid
                            ? Colors.green
                            : isInvalid
                            ? Colors.red
                            : Colors.grey.shade200,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isValid
                            ? Colors.green
                            : isInvalid
                            ? Colors.red.shade300
                            : Colors.grey.shade200,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isValid
                            ? Colors.green
                            : isInvalid
                            ? Colors.red
                            : const Color(0xFFF35535),
                        width: 1.5,
                      ),
                    ),
                    prefixIcon: Icon(
                      Icons.local_offer_outlined,
                      color: isValid
                          ? Colors.green
                          : isInvalid
                          ? Colors.red
                          : const Color(0xFFF35535),
                    ),
                    suffixIcon: isValid
                        ? const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 20,
                          )
                        : isInvalid
                        ? const Icon(Icons.cancel, color: Colors.red, size: 20)
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () {
                        cubit.applyPromoCode(_promoController.text.trim());
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF35535),
                  disabledBackgroundColor: const Color(
                    0xFFF35535,
                  ).withValues(alpha: 0.6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        AppLocalizations.of(context)!.apply,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
          // Feedback message
          if (checkoutState.promoMessage != null ||
              checkoutState.promoValidationResult != null) ...[
            const SizedBox(height: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isValid ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isValid ? Colors.green.shade200 : Colors.red.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isValid ? Icons.check_circle_outline : Icons.error_outline,
                    size: 16,
                    color: isValid
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getLocalizedPromoMessage(context, checkoutState),
                      style: TextStyle(
                        fontSize: 13,
                        color: isValid
                            ? Colors.green.shade800
                            : Colors.red.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getLocalizedPromoMessage(BuildContext context, CheckoutState state) {
    final l10n = AppLocalizations.of(context)!;
    if (state.promoStatus == PromoStatus.valid && state.appliedPromo != null) {
      final promo = state.appliedPromo!;
      return switch (promo.type) {
        PromoCodeType.percentage => l10n.promoPercentageDiscountApplied(
            promo.discountValue.toStringAsFixed(0),
            state.discount.toStringAsFixed(2),
          ),
        PromoCodeType.fixed => l10n.promoFixedDiscountApplied(
            state.discount.toStringAsFixed(2),
          ),
        PromoCodeType.freeDelivery => l10n.promoFreeDeliveryApplied,
      };
    }
    if (state.promoValidationResult != null) {
      final minAmt = state.appliedPromo?.minOrderAmount ?? 0.0;
      return switch (state.promoValidationResult!) {
        PromoValidationResult.valid => l10n.promoApplied,
        PromoValidationResult.notFound => l10n.promoInvalid,
        PromoValidationResult.inactive => l10n.promoInactive,
        PromoValidationResult.expired => l10n.promoExpired,
        PromoValidationResult.maxUsageReached => l10n.promoMaxUsageReached,
        PromoValidationResult.userLimitReached => l10n.promoUserLimitReached,
        PromoValidationResult.minimumOrderNotMet =>
          l10n.promoMinOrderNotMet(minAmt.toStringAsFixed(2)),
        PromoValidationResult.wrongRestaurant => l10n.promoWrongRestaurant,
      };
    }
    return state.promoMessage ?? l10n.promoInvalid;
  }

  Widget _buildPriceBreakdown(CheckoutState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildPriceRow(
            AppLocalizations.of(context)!.subtotal,
            state.subtotal,
          ),
          if (state.deliveryDistanceKm != null) ...[
            const SizedBox(height: 10),
            _buildDeliveryFeeRow(state),
          ],
          if (state.serviceFee > 0) ...[
            const SizedBox(height: 10),
            _buildPriceRow(
              AppLocalizations.of(context)!.serviceFeeSimple,
              state.serviceFee,
            ),
          ],
          if (state.discount > 0) ...[
            const SizedBox(height: 10),
            _buildPriceRow(
              AppLocalizations.of(context)!.discountLabel,
              -state.discount,
              isDiscount: true,
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: DashedDivider(
              color: Colors.black12,
              height: 1,
              dashWidth: 6,
              dashSpace: 4,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.totalLabel,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              Text(
                (state.deliveryLat != 0.0 && state.deliveryLng != 0.0 && state.deliveryDistanceKm == null)
                    ? AppLocalizations.of(context)!.calculating
                    : AppLocalizations.of(
                        context,
                      )!.egpAmount(state.total.toStringAsFixed(2)),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFF35535),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    double amount, {
    bool isDiscount = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
        ),
        Text(
          AppLocalizations.of(
            context,
          )!.egpAmount(amount.toStringAsFixed(2).toString()),
          style: TextStyle(
            color: isDiscount ? Colors.green : const Color(0xFF1A1A2E),
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  /// Build delivery fee row with distance information.
  Widget _buildDeliveryFeeRow(CheckoutState state) {
    final distance = state.deliveryDistanceKm;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context)!.deliveryFee,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
            ),
            Text(
              AppLocalizations.of(
                context,
              )!.egpAmount(state.deliveryFee.toStringAsFixed(2).toString()),
              style: const TextStyle(
                color: Color(0xFF333333),
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
        if (distance != null && state.deliveryAddress.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                AppLocalizations.of(
                  context,
                )!.kmAway(distance.toStringAsFixed(1)),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildValidationErrors(List<String> errors) {
    return Container(
      margin: const EdgeInsetsDirectional.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.pleaseFixFollowing,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...errors.map(
            (error) => Padding(
              padding: const EdgeInsetsDirectional.only(start: 28, top: 4),
              child: Text(
                '• $error',
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutFooter(CheckoutCubit cubit, CheckoutState state) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (state.restaurant != null && !(state.restaurant!.isOpen))
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: Colors.red.shade50,
                child: Row(
                  children: [
                    Icon(Icons.storefront_rounded, color: Colors.red.shade700, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.vendorCurrentlyClosed(
                          state.restaurant?.vendorType.label ??
                              (Localizations.localeOf(context).languageCode == 'ar' ? 'المتجر' : 'Vendor'),
                        ),
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Builder(builder: (context) {
              final isVendorAvailable = (state.restaurant?.isOpen ?? true) &&
                  !(state.restaurant?.isBusy ?? false);
              final canSubmit = state.canPlaceOrder && isVendorAvailable;
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: canSubmit
                          ? const LinearGradient(
                              colors: [Color(0xFFF35535), Color(0xFFFF9800)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: canSubmit ? null : Colors.grey.shade300,
                      boxShadow: canSubmit
                          ? [
                              BoxShadow(
                                color: const Color(0xFFF35535).withValues(
                                  alpha: 0.25,
                                ),
                                blurRadius: 12,
                                offset: const Offset(0, 5),
                              ),
                            ]
                          : null,
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: (canSubmit &&
                              !state.isSubmitting &&
                              !_isProcessingOrder)
                          ? () => _handlePlaceOrder(cubit, state)
                          : null,
                      child: (state.isSubmitting || _isProcessingOrder)
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              (state.deliveryLat != 0.0 &&
                                      state.deliveryLng != 0.0 &&
                                      state.deliveryDistanceKm == null)
                                  ? AppLocalizations.of(context)!
                                      .placeOrderCalculating
                                  : (state.deliveryDistanceKm == null
                                      ? AppLocalizations.of(context)!
                                          .placeOrderLabel
                                      : (state.paymentMethod == PaymentMethodType.card
                                          ? (_selectedSavedCard != null && !_useHostedCheckout
                                              ? (Localizations.localeOf(context).languageCode == 'ar'
                                                  ? 'ادفع بالبطاقة (${_selectedSavedCard!.brand} •••• ${_selectedSavedCard!.last4})'
                                                  : 'Pay with Saved Card (•••• ${_selectedSavedCard!.last4})')
                                              : (_useHostedCheckout
                                                  ? (Localizations.localeOf(context).languageCode == 'ar'
                                                      ? 'ادفع بالكارت (${state.total.toStringAsFixed(2)} ج.م)'
                                                      : 'Pay with Card (${state.total.toStringAsFixed(2)})')
                                                  : (Localizations.localeOf(context).languageCode == 'ar'
                                                      ? 'إضافة بطاقة بنكية'
                                                      : 'Add Payment Card')))
                                          : (state.paymentMethod == PaymentMethodType.wallet
                                              ? (Localizations.localeOf(context).languageCode == 'ar'
                                                  ? 'ادفع بالمحفظة الإلكترونية (${state.total.toStringAsFixed(2)} ج.م)'
                                                  : 'Pay with Mobile Wallet (${state.total.toStringAsFixed(2)})')
                                              : AppLocalizations.of(context)!
                                                  .placeOrderAmount(
                                                  state.total.toStringAsFixed(2),
                                                )))),
                              style: TextStyle(
                                color: canSubmit
                                    ? Colors.white
                                    : Colors.grey.shade500,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  UserRole _parseRole(UserType? type) {
    switch (type) {
      case UserType.customer:
        return UserRole.customer;
      case UserType.driver:
        return UserRole.driver;
      case UserType.admin:
        return UserRole.admin;
      case UserType.vendor:
        return UserRole.vendorOwner;
      default:
        return UserRole.guest;
    }
  }

  Future<String?> _showMissingPhoneDialog() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.phone_android, color: Color(0xFFF35535)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Phone Number Required',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Please enter your mobile phone number so the driver and restaurant can contact you regarding your delivery.',
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller,
                  keyboardType: TextInputType.phone,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText:
                        AppLocalizations.of(dialogContext)?.phone ??
                        'Phone Number',
                    hintText: '01000000000',
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().length < 8) {
                      return 'Please enter a valid phone number';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, null),
              child: Text(
                AppLocalizations.of(dialogContext)?.cancel ?? 'Cancel',
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF35535),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dialogContext, controller.text.trim());
                }
              },
              child: const Text(
                'Save & Continue',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handlePlaceOrder(
    CheckoutCubit cubit,
    CheckoutState state,
  ) async {
    if (_isProcessingOrder) return;
    setState(() {
      _isProcessingOrder = true;
    });

    try {
      final currentUser = context.read<AuthCubit>().currentUser;
      final userPhone = currentUser?.phone?.trim();
      final hasPhoneInProfile = userPhone != null && userPhone.isNotEmpty;
      final hasPhoneInAddress =
          state.deliveryAddress.contains('Phone:') ||
          state.deliveryAddress.contains('هاتف:');

      if (!hasPhoneInProfile && !hasPhoneInAddress) {
        final phoneEntered = await _showMissingPhoneDialog();
        if (phoneEntered == null || phoneEntered.trim().isEmpty) {
          return;
        }
        if (!mounted) return;
        await context.read<AuthCubit>().updateUserPhone(phoneEntered.trim());
      }

      // If user selected card but has no card selected and hasn't chosen hosted checkout, prompt to add a card
      if (cubit.state.paymentMethod == PaymentMethodType.card &&
          _selectedSavedCard == null &&
          !_useHostedCheckout) {
        final added = await AddCardBottomSheet.show(context, _paylinkDatasource);
        if (added == true && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                Localizations.localeOf(context).languageCode == 'ar'
                    ? 'تم حفظ البطاقة بنجاح! يمكنك الآن تأكيد الطلب والدفع.'
                    : 'Card saved successfully! You can now place your order.',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
        return;
      }

      // ── 1. CASH ON DELIVERY FLOW ──
      if (cubit.state.paymentMethod == PaymentMethodType.cash) {
        if (!mounted) return;
        final success = await cubit.placeOrder();
        if (!success || !mounted) return;

        final orderId = cubit.state.submittedOrderId;
        if (orderId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order submission failed. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        final shortOrderId = orderId.length > 8
            ? orderId.substring(0, 8).toUpperCase()
            : orderId.toUpperCase();

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 28),
                const SizedBox(width: 12),
                Text(AppLocalizations.of(dialogContext)!.orderPlaced),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(dialogContext)!.orderIdValue(shortOrderId),
                ),
                const SizedBox(height: 8),
                Text(_estimateDeliveryTime(cubit.state)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  Navigator.of(context).pop();
                },
                child: Text(AppLocalizations.of(dialogContext)!.ok),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => OrderTrackingScreen(orderId: orderId),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF35535),
                ),
                child: Text(
                  AppLocalizations.of(context)!.trackOrder,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
        return;
      }

      // ── 2. PRE-PAYMENT FLOW (ONLINE CARD OR WALLET) ──
      // Crucial: payment MUST be executed and verified BEFORE creating an order in Firestore.
      // This prevents ghost orders, false vendor alerts, and cart loss if user aborts or card fails.
      bool paymentSuccess = false;
      String? errorMessage;
      String? transactionRef;

      if (cubit.state.paymentMethod == PaymentMethodType.card &&
          !_useHostedCheckout &&
          _selectedSavedCard != null) {
        // One-click charge with saved token
        try {
          final res = await _paylinkDatasource.chargeSavedCard(
            cardId: _selectedSavedCard!.id,
            amount: state.total,
            orderTitle: 'Z-SPEED Order (${state.restaurantName})',
          );
          final paidStatus = res['paidStatus']?.toString().toUpperCase() ?? '';
          if (res['success'] == true || paidStatus == 'PAID') {
            paymentSuccess = true;
            transactionRef = res['invoiceId']?.toString();
          } else {
            final rawInv = res['invoiceId'];
            final inv = rawInv is num ? rawInv.toInt() : (int.tryParse(rawInv?.toString() ?? '') ?? 0);
            if (inv > 0) {
              final statusCheck = await _paylinkDatasource.checkPaymentStatus(inv);
              if (statusCheck['isPaid'] == true) {
                paymentSuccess = true;
                transactionRef = inv.toString();
              } else {
                paymentSuccess = false;
                errorMessage = res['message']?.toString() ?? 'Card charge was not approved';
              }
            } else {
              paymentSuccess = false;
              errorMessage = res['message']?.toString() ?? 'Card charge was not approved';
            }
          }
        } catch (e) {
          paymentSuccess = false;
          errorMessage = e.toString().replaceFirst('Exception: ', '');
        }
      } else {
        // Hosted checkout via PayLink (Card or Mobile Wallet)
        try {
          final initRes = await _paylinkDatasource.initCheckout(
            amount: state.total,
            orderTitle: 'Z-SPEED Order (${state.restaurantName})',
          );
          final checkoutUrl = initRes['checkoutUrl']?.toString() ?? '';
          final rawInvoiceId = initRes['invoiceId'];
          final invoiceId = rawInvoiceId is num
              ? rawInvoiceId.toInt()
              : (int.tryParse(rawInvoiceId?.toString() ?? '') ?? 0);

          if (checkoutUrl.isEmpty) {
            throw Exception('Could not connect to payment gateway. Please try again.');
          }

          if (!mounted) return;
          final result = await Navigator.of(context).push<PaylinkWebviewResult>(
            MaterialPageRoute(
              builder: (_) => PaylinkWebviewPage(
                checkoutUrl: checkoutUrl,
                expectedInvoiceId: invoiceId,
              ),
            ),
          );

          if (result != null && result.success) {
            paymentSuccess = true;
            transactionRef = (result.invoiceId != 0 ? result.invoiceId : invoiceId).toString();
          } else {
            // Verify with PayLink directly before reporting failure!
            if (invoiceId > 0) {
              final statusCheck = await _paylinkDatasource.checkPaymentStatus(invoiceId);
              if (statusCheck['isPaid'] == true) {
                paymentSuccess = true;
                transactionRef = invoiceId.toString();
              } else {
                paymentSuccess = false;
                errorMessage = result?.message ??
                    (Localizations.localeOf(context).languageCode == 'ar'
                        ? 'تم إلغاء عملية الدفع أو لم تكتمل.'
                        : 'Payment was cancelled or closed.');
              }
            } else {
              paymentSuccess = false;
              errorMessage = result?.message ??
                  (Localizations.localeOf(context).languageCode == 'ar'
                      ? 'تم إلغاء عملية الدفع أو لم تكتمل.'
                      : 'Payment was cancelled or closed.');
            }
          }
        } catch (e) {
          paymentSuccess = false;
          errorMessage = e.toString().replaceFirst('Exception: ', '');
        }
      }

      if (!mounted) return;

      if (!paymentSuccess) {
        // Payment failed or cancelled: DO NOT CREATE ANY ORDER. Cart stays intact!
        await PaymentStatusSheet.show(
          context: context,
          type: PaymentStatusType.failure,
          rawReason: errorMessage,
        );
        return;
      }

      // Online payment succeeded! Now create the order in Firestore.
      final success = await cubit.placeOrder();
      if (!success || !mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Localizations.localeOf(context).languageCode == 'ar'
                  ? 'تم تأكيد الدفع بنجاح (فاتورة #$transactionRef)! يرجى التواصل مع الدعم الفني لتأكيد طلبك.'
                  : 'Payment succeeded (#$transactionRef)! Please contact support to confirm order.',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 8),
          ),
        );
        return;
      }

      final orderId = cubit.state.submittedOrderId;
      if (orderId != null) {
        try {
          await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
            'status': 'pending',
            'paymentStatus': 'completed',
            'paymentState': 'paid',
            'paymentInvoiceId': transactionRef,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } catch (_) {}
      }

      // Clear the cart atomically now that payment and order are complete
      await context.read<CartCubit>().clearCart();

      await PaymentStatusSheet.show(
        context: context,
        type: PaymentStatusType.success,
        transactionReference: transactionRef,
        onPrimaryAction: () {
          Navigator.of(context).pop();
          if (orderId != null) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => OrderTrackingScreen(orderId: orderId),
              ),
            );
          }
        },
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingOrder = false;
        });
      }
    }
  }

  String _estimateDeliveryTime(CheckoutState state) {
    final restaurant = state.restaurant;
    if (restaurant == null ||
        state.deliveryLat == 0.0 ||
        state.deliveryLng == 0.0) {
      return AppLocalizations.of(context)!.estimatedDelivery3045Minutes;
    }

    const dist = Distance();
    final meters = dist.as(
      LengthUnit.Meter,
      LatLng(restaurant.latitude, restaurant.longitude),
      LatLng(state.deliveryLat, state.deliveryLng),
    );

    // Clamp delivery distance to restaurant's delivery radius or 15 km limit to handle mock coordinate testing gracefully
    final maxRadius = (restaurant.deliveryRadiusKm > 0)
        ? restaurant.deliveryRadiusKm
        : 15.0;
    final km = (meters / 1000).clamp(0.0, maxRadius);

    // Prep time (restaurant's own estimate) + delivery time (~40 km/h, x1.3 road factor)
    final isQuickService =
        restaurant.vendorType == VendorType.restaurant ||
        restaurant.vendorType == VendorType.pharmacy ||
        restaurant.vendorType == VendorType.supermarket ||
        restaurant.vendorType == VendorType.bookstore ||
        restaurant.vendorType == VendorType.meatAndProteins;

    int prepMin = restaurant.deliveryTimeMin;
    if (prepMin <= 0) {
      prepMin = 20;
    } else if (isQuickService && prepMin > 60) {
      prepMin = 60;
    }

    final deliveryMin = ((km * 1.3) / 40 * 60).ceil();
    final totalMin = prepMin + deliveryMin;
    final totalMax = totalMin + 15;

    return AppLocalizations.of(context)!.estimatedMinutes(totalMin, totalMax);
  }
}

class DashedDivider extends StatelessWidget {
  final double height;
  final Color color;
  final double dashWidth;
  final double dashSpace;

  const DashedDivider({
    super.key,
    this.height = 1,
    this.color = Colors.grey,
    this.dashWidth = 5,
    this.dashSpace = 3,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: height,
              child: DecoratedBox(decoration: BoxDecoration(color: color)),
            );
          }),
        );
      },
    );
  }
}
