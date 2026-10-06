import 'dart:ui';
import 'package:z_speed/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:z_speed/components/shimmer_loading.dart';
import 'package:z_speed/core/enums/user_enums.dart';
import 'package:z_speed/features/restaurant/model/menu_item.dart';
import 'package:z_speed/features/restaurant/model/menu_item_variant.dart';
import 'package:z_speed/features/customer/cubit/item_detail_cubit.dart';
import 'package:z_speed/features/customer/cubit/item_detail_state.dart';
import 'package:z_speed/features/customer/widgets/addon_group_selector.dart';
import 'package:z_speed/features/cart/cubit/cart_cubit.dart';
import 'package:z_speed/features/cart/cubit/cart_state.dart';
import 'package:z_speed/features/auth/cubit/auth_cubit.dart';
import 'package:z_speed/features/customer/widgets/guest_auth_prompt.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/features/customer/repository/customer_restaurant_repository_impl.dart';

/// Full-page item profile screen.
///
/// Displays item hero image, name, description, addon groups with
/// Required/Optional badges, special instructions, and a sticky
/// bottom bar with quantity selector + "Add item" button.
///
/// When [onEditPressed] is provided an edit FAB is shown (for restaurant owner).
class ItemProfilePage extends StatelessWidget {
  final MenuItem item;
  final String restaurantId;
  final String sectionId;

  /// Called when the edit button is tapped. If null, no edit FAB is shown.
  final VoidCallback? onEditPressed;

  /// Whether the vendor is currently open. If false, add-to-cart is disabled.
  final bool isRestaurantOpen;

  /// The type of vendor (restaurant, supermarket, pharmacy).
  final VendorType vendorType;

  const ItemProfilePage({
    super.key,
    required this.item,
    required this.restaurantId,
    required this.sectionId,
    this.onEditPressed,
    this.isRestaurantOpen = true,
    this.vendorType = VendorType.restaurant,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ItemDetailCubit(
        item: item,
        restaurantId: restaurantId,
        sectionId: sectionId,
      ),
      child: _ItemProfileContent(
        onEditPressed: onEditPressed,
        isRestaurantOpen: isRestaurantOpen,
        vendorType: vendorType,
      ),
    );
  }
}

class _ItemProfileContent extends StatefulWidget {
  final VoidCallback? onEditPressed;
  final bool isRestaurantOpen;
  final VendorType vendorType;
  const _ItemProfileContent({
    this.onEditPressed,
    this.isRestaurantOpen = true,
    this.vendorType = VendorType.restaurant,
  });

  @override
  State<_ItemProfileContent> createState() => _ItemProfileContentState();
}

class _ItemProfileContentState extends State<_ItemProfileContent> {
  final _noteController = TextEditingController();
  late final Stream<List<MenuItem>> _itemsStream;
  late final Stream<List<MenuItem>> _allItemsStream;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<ItemDetailCubit>();
    final repository = CustomerRestaurantRepositoryImpl();
    _itemsStream = repository.streamItems(
      cubit.state.restaurantId,
      cubit.state.sectionId,
    );
    _allItemsStream = repository.streamAllItems(cubit.state.restaurantId);
  }

  IconData get _vendorIcon {
    switch (widget.vendorType) {
      case VendorType.supermarket:
        return Icons.shopping_cart_outlined;
      case VendorType.pharmacy:
        return Icons.local_pharmacy_outlined;
      case VendorType.bookstore:
        return Icons.menu_book_outlined;
      case VendorType.homeFurnishing:
        return Icons.chair_outlined;
      case VendorType.restaurant:
        return Icons.restaurant;
      case VendorType.meatAndProteins:
        return Icons.restaurant_menu_outlined;
      case VendorType.clothes:
        return Icons.checkroom_outlined;
      case VendorType.buyAndSell:
        return Icons.swap_horiz_outlined;
      case VendorType.electronics:
        return Icons.devices_outlined;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ItemDetailCubit>();
    final state = context.watch<ItemDetailCubit>().state;
    final item = state.item;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          // ── Scrollable Content ────────────────────────────────
          Expanded(
            child: CustomScrollView(
              slivers: [
                // ── Hero Image ─────────────────────────────────
                _buildHeroImage(context, item),

                // ── Item Info Section ──────────────────────────
                SliverToBoxAdapter(child: _buildItemInfo(context, state)),

                // ── Variants Selection Section ────────────────
                if (item.variants.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _buildVariantsSection(context, state, cubit),
                  ),

                // ── Addon Groups ───────────────────────────────
                if (state.isLoadingAddons)
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildAddonShimmer(context),
                      childCount: 2,
                    ),
                  )
                else if (state.addonGroups.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        16,
                        20,
                        16,
                        8,
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.customizeYourItem,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final group = state.addonGroups[index];
                      final selected = state.selectedAddons[group.id] ?? {};
                      return AddonGroupSelector(
                        group: group,
                        selectedAddonIds: selected,
                        onToggleAddon: (id) => cubit.toggleAddon(group.id, id),
                      );
                    }, childCount: state.addonGroups.length),
                  ),
                ],

                // ── Special Instructions ───────────────────────
                SliverToBoxAdapter(
                  child: _buildSpecialInstructions(context, state, cubit),
                ),

                // ── Validation Errors ──────────────────────────
                if (state.validationErrors.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _buildValidationErrors(context, state),
                  ),

                // ── Recommended Products ────────────────────────
                _buildRecommendedProducts(context, state),

                // Bottom padding so content doesn't hide behind bar
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          ),

          // ── Sticky Bottom Bar ────────────────────────────────
          _buildBottomBar(context, state, cubit, bottomPadding),
        ],
      ),

      // ── Owner Edit FAB ───────────────────────────────────────
      floatingActionButton: widget.onEditPressed != null
          ? _buildOwnerFab(context)
          : null,
    );
  }

  // ══════════════════════════════════════════════════════════════
  // HERO IMAGE
  // ══════════════════════════════════════════════════════════════
  Widget _buildGlassButton({
    required Widget child,
    required VoidCallback onTap,
  }) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.35),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroImage(BuildContext context, MenuItem item) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leadingWidth: 56,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12.0, top: 8.0, bottom: 8.0),
        child: _buildGlassButton(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
      ),
      actions: [
        // Cart badge
        Padding(
          padding: const EdgeInsetsDirectional.only(end: 12.0),
          child: BlocBuilder<CartCubit, CartState>(
            builder: (context, cartState) {
              final count = cartState.itemCount;
              return _buildGlassButton(
                onTap: () => Navigator.pop(context),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.shopping_cart_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                    if (count > 0)
                      PositionedDirectional(
                        end: -6,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF35535),
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(20),
        child: Container(
          height: 20,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            item.imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: item.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const ShimmerLoading(
                      width: double.infinity,
                      height: double.infinity,
                    ),
                    errorWidget: (_, _, _) => Container(
                      color: Colors.grey.shade300,
                      child: Center(
                        child: Icon(
                          _vendorIcon,
                          size: 80,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                  )
                : Container(
                    color: Colors.grey.shade300,
                    child: Center(
                      child: Icon(_vendorIcon, size: 80, color: Colors.white54),
                    ),
                  ),
            // Top and bottom gradient shadows
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black38,
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black12,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.25, 0.75, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // ITEM INFO
  // ══════════════════════════════════════════════════════════════
  Widget _buildItemInfo(BuildContext context, ItemDetailState state) {
    final item = state.item;
    final MenuItemVariant? selectedVariant = state.selectedVariant;

    final bool hasDiscount;
    final double currentPrice;
    final double? originalPrice;

    if (selectedVariant != null) {
      hasDiscount =
          selectedVariant.originalPrice != null &&
          selectedVariant.originalPrice! > selectedVariant.price;
      currentPrice = selectedVariant.price;
      originalPrice = selectedVariant.originalPrice;
    } else {
      hasDiscount =
          item.discountedPrice != null && item.price > item.discountedPrice!;
      currentPrice = item.discountedPrice ?? item.price;
      originalPrice = hasDiscount ? item.price : null;
    }

    final int discountPct =
        hasDiscount && originalPrice != null && originalPrice > 0
        ? (((originalPrice - currentPrice) / originalPrice) * 100).round()
        : 0;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name Row + Popular Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.getLocalizedName(
                    Localizations.localeOf(context).languageCode,
                  ),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    height: 1.25,
                  ),
                ),
              ),
              if (item.isPopular) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.orange.shade100.withValues(alpha: 0.5),
                        Colors.orange.shade50.withValues(alpha: 0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.shade300,
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_fire_department_rounded,
                        size: 14,
                        color: Colors.orange.shade800,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        AppLocalizations.of(context)!.popular,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 12),

          // Price Row + Discount Percentage
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                AppLocalizations.of(
                  context,
                )!.egpAmount(currentPrice.toStringAsFixed(2)),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFF35535),
                ),
              ),
              if (hasDiscount && originalPrice != null) ...[
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(
                    context,
                  )!.egpAmount(originalPrice.toStringAsFixed(2)),
                  style: TextStyle(
                    fontSize: 14,
                    decoration: TextDecoration.lineThrough,
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5F5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFFEB2B2),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    '-$discountPct%',
                    style: const TextStyle(
                      color: Color(0xFFE53E3E),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ],
          ),

          if (!item.isAvailable ||
              (selectedVariant != null && !selectedVariant.isAvailable)) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.itemCurrentlyUnavailable,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Description
          if (item
              .getLocalizedDescription(
                Localizations.localeOf(context).languageCode,
              )
              .isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              item.getLocalizedDescription(
                Localizations.localeOf(context).languageCode,
              ),
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.grey.shade600,
              ),
            ),
          ],

          // Item info chips (prep time, calories, rating)
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              if (item.preparationTime > 0)
                _infoChip(
                  icon: Icons.access_time_rounded,
                  label: '${item.preparationTime} min',
                  iconColor: const Color(0xFF3182CE),
                  backgroundColor: const Color(0xFFEBF8FF),
                  textColor: const Color(0xFF2B6CB0),
                ),
              if (item.calories != null)
                _infoChip(
                  icon: Icons.local_fire_department_rounded,
                  label: '${item.calories} cal',
                  iconColor: const Color(0xFFE53E3E),
                  backgroundColor: const Color(0xFFFFF5F5),
                  textColor: const Color(0xFFC53030),
                ),
              if (item.rating > 0)
                _infoChip(
                  icon: Icons.star_rounded,
                  label:
                      '${item.rating.toStringAsFixed(1)} (${item.ratingCount})',
                  iconColor: const Color(0xFFD69E2E),
                  backgroundColor: const Color(0xFFFEFCBF),
                  textColor: const Color(0xFFB7791F),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // VARIANTS SELECTOR
  // ══════════════════════════════════════════════════════════════
  Widget _buildVariantsSection(
    BuildContext context,
    ItemDetailState state,
    ItemDetailCubit cubit,
  ) {
    final langCode = Localizations.localeOf(context).languageCode;
    final isAr = langCode == 'ar';
    final title = isAr ? 'الخيارات المتاحة' : 'Available Options';
    final variants = state.item.variants;

    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
          const SizedBox(height: 14),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: variants.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final variant = variants[index];
              final isSelected = state.selectedVariant == variant;
              final isAvailable = variant.isAvailable;

              return InkWell(
                onTap: isAvailable ? () => cubit.selectVariant(variant) : null,
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFF35535).withValues(alpha: 0.03)
                        : (isAvailable ? Colors.white : Colors.grey.shade50),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFF35535)
                          : Colors.grey.shade200,
                      width: isSelected ? 1.8 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(
                                0xFFF35535,
                              ).withValues(alpha: 0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      // Custom Radio check indicator
                      isSelected
                          ? Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFF35535),
                                  width: 5.5,
                                ),
                                color: Colors.white,
                              ),
                            )
                          : Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isAvailable
                                      ? Colors.grey.shade300
                                      : Colors.grey.shade200,
                                  width: 1.5,
                                ),
                                color: Colors.transparent,
                              ),
                            ),
                      const SizedBox(width: 12),

                      // Variant Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              variant.getLocalizedName(langCode),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                color: isAvailable
                                    ? Colors.black87
                                    : Colors.grey.shade400,
                              ),
                            ),
                            if (!isAvailable) ...[
                              const SizedBox(height: 4),
                              Text(
                                AppLocalizations.of(context)!
                                    .itemCurrentlyUnavailable,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.red.shade400,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Price
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (variant.originalPrice != null &&
                              variant.originalPrice! > variant.price) ...[
                            Text(
                              AppLocalizations.of(context)!.egpAmount(
                                variant.originalPrice!.toStringAsFixed(2),
                              ),
                              style: TextStyle(
                                fontSize: 11,
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey.shade400,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                          ],
                          Text(
                            AppLocalizations.of(
                              context,
                            )!.egpAmount(variant.price.toStringAsFixed(2)),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? const Color(0xFFF35535)
                                  : (isAvailable
                                        ? Colors.black87
                                        : Colors.grey.shade400),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _infoChip({
    required IconData icon,
    required String label,
    required Color iconColor,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // SPECIAL INSTRUCTIONS
  // ══════════════════════════════════════════════════════════════
  Widget _buildSpecialInstructions(
    BuildContext context,
    ItemDetailState state,
    ItemDetailCubit cubit,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 0.8),
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
              const Icon(
                Icons.edit_note_rounded,
                size: 20,
                color: Color(0xFFF35535),
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.specialInstructions,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            onChanged: cubit.setNote,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.specialInstructionsHint,
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            maxLines: 2,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // VALIDATION ERRORS
  // ══════════════════════════════════════════════════════════════
  Widget _buildValidationErrors(BuildContext context, ItemDetailState state) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: state.validationErrors
            .map(
              (error) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 16,
                      color: Colors.red.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        error,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // BOTTOM BAR — Quantity + Add to Cart
  // ══════════════════════════════════════════════════════════════
  Widget _buildBottomBar(
    BuildContext context,
    ItemDetailState state,
    ItemDetailCubit cubit,
    double bottomPadding,
  ) {
    return Container(
      padding: EdgeInsetsDirectional.fromSTEB(20, 14, 20, 14 + bottomPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Row(
        children: [
          // ── Quantity Selector (compact — inline) ──────────
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _qtyButton(
                  icon: Icons.remove,
                  onPressed: state.quantity > state.minQuantity
                      ? cubit.decrementQuantity
                      : null,
                ),
                Container(
                  constraints: const BoxConstraints(minWidth: 32),
                  alignment: Alignment.center,
                  child: Text(
                    state.quantity.toInt().toString(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                ),
                _qtyButton(
                  icon: Icons.add,
                  onPressed: state.quantity < state.maxQuantity
                      ? cubit.incrementQuantity
                      : null,
                ),
              ],
            ),
          ),

          const SizedBox(width: 14),

          // ── Add to Cart Button ───────────────────────────
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: (state.canAddToCart && widget.isRestaurantOpen)
                    ? () {
                        final authState = context.read<AuthCubit>().state;
                        if (authState.isGuest) {
                          GuestAuthPrompt.show(
                            context,
                            actionLabel: AppLocalizations.of(
                              context,
                            )!.addToCart,
                          );
                          return;
                        }
                        final cartItem = state.toCartItem();
                        Navigator.pop(context, cartItem);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF35535),
                  disabledBackgroundColor: Colors.grey.shade200,
                  disabledForegroundColor: Colors.grey.shade400,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  !state.item.isAvailable ||
                          (state.selectedVariant != null &&
                              !state.selectedVariant!.isAvailable)
                      ? AppLocalizations.of(context)!.itemCurrentlyUnavailable
                      : (widget.isRestaurantOpen
                          ? AppLocalizations.of(
                              context,
                            )!.addItemWithPrice(
                              state.itemTotal.toStringAsFixed(2),
                            )
                          : AppLocalizations.of(
                              context,
                            )!.vendorClosedLabel(widget.vendorType.label)),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyButton({required IconData icon, VoidCallback? onPressed}) {
    final enabled = onPressed != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 36,
          height: 44,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 18,
            color: enabled ? const Color(0xFFF35535) : Colors.grey.shade400,
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // OWNER EDIT FAB
  // ══════════════════════════════════════════════════════════════
  Widget _buildOwnerFab(BuildContext context) {
    return FloatingActionButton(
      onPressed: widget.onEditPressed,
      child: const Icon(Icons.edit, color: Colors.white),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // RECOMMENDED PRODUCTS
  // ══════════════════════════════════════════════════════════════
  Widget _buildRecommendedProducts(
    BuildContext context,
    ItemDetailState state,
  ) {
    return StreamBuilder<List<MenuItem>>(
      stream: _itemsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SliverToBoxAdapter(
            child: _buildRecommendedShimmerList(context),
          );
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        final currentItemId = state.item.id;
        final items = snapshot.data!
            .where((item) => item.id != currentItemId)
            .toList();

        if (items.isEmpty) {
          return StreamBuilder<List<MenuItem>>(
            stream: _allItemsStream,
            builder: (context, fallbackSnapshot) {
              if (fallbackSnapshot.connectionState == ConnectionState.waiting) {
                return SliverToBoxAdapter(
                  child: _buildRecommendedShimmerList(context),
                );
              }
              if (!fallbackSnapshot.hasData || fallbackSnapshot.data == null) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }
              final fallbackItems = fallbackSnapshot.data!
                  .where((item) => item.id != currentItemId)
                  .toList();
              if (fallbackItems.isEmpty) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }
              return SliverToBoxAdapter(
                child: _buildRecommendedList(context, state, fallbackItems),
              );
            },
          );
        }

        return SliverToBoxAdapter(
          child: _buildRecommendedList(context, state, items),
        );
      },
    );
  }

  Widget _buildRecommendedList(
    BuildContext context,
    ItemDetailState state,
    List<MenuItem> items,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              AppLocalizations.of(context)!.recommendedProducts,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1A1A),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 230,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final recommendedItem = items[index];
                return _buildRecommendedCard(context, state, recommendedItem);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedCard(
    BuildContext context,
    ItemDetailState state,
    MenuItem recommendedItem,
  ) {
    final locale = Localizations.localeOf(context).languageCode;
    final hasDiscount =
        recommendedItem.discountedPrice != null &&
        recommendedItem.price > recommendedItem.discountedPrice!;
    final displayPrice =
        recommendedItem.discountedPrice ?? recommendedItem.price;
    final int discountPct = hasDiscount && recommendedItem.price > 0
        ? (((recommendedItem.price - recommendedItem.discountedPrice!) /
                      recommendedItem.price) *
                  100)
              .round()
        : 0;

    return Container(
      width: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ItemProfilePage(
                    item: recommendedItem,
                    restaurantId: state.restaurantId,
                    sectionId: recommendedItem.sectionId.isNotEmpty
                        ? recommendedItem.sectionId
                        : state.sectionId,
                    vendorType: widget.vendorType,
                    isRestaurantOpen: widget.isRestaurantOpen,
                  ),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 1.3,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: recommendedItem.imageUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: recommendedItem.imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    const ShimmerLoading(
                                      width: double.infinity,
                                      height: double.infinity,
                                    ),
                                errorWidget: (_, _, _) => Container(
                                  color: Colors.grey.shade100,
                                  child: Icon(
                                    _vendorIcon,
                                    size: 32,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              )
                            : Container(
                                color: Colors.grey.shade100,
                                child: Icon(
                                  _vendorIcon,
                                  size: 32,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                      ),
                      if (recommendedItem.isPopular)
                        PositionedDirectional(
                          top: 8,
                          start: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.orange.shade100.withValues(alpha: 0.8),
                                  Colors.orange.shade50.withValues(alpha: 0.5),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.orange.shade300,
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.local_fire_department_rounded,
                                  size: 10,
                                  color: Colors.orange.shade800,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  AppLocalizations.of(context)!.popular,
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (hasDiscount)
                        PositionedDirectional(
                          top: 8,
                          end: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE53E3E),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '-$discountPct%',
                              style: const TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recommendedItem.getLocalizedName(locale),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            if (hasDiscount) ...[
                              Text(
                                AppLocalizations.of(context)!.egpAmount(
                                  recommendedItem.price.toStringAsFixed(2),
                                ),
                                style: TextStyle(
                                  fontSize: 10,
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              AppLocalizations.of(
                                context,
                              )!.egpAmount(displayPrice.toStringAsFixed(2)),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: hasDiscount
                                    ? const Color(0xFFF35535)
                                    : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddonShimmer(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerLoading(
            width: 140,
            height: 16,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ShimmerLoading(
                width: 20,
                height: 20,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(width: 12),
              ShimmerLoading(
                width: 100,
                height: 12,
                borderRadius: BorderRadius.circular(4),
              ),
              const Spacer(),
              ShimmerLoading(
                width: 40,
                height: 12,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              ShimmerLoading(
                width: 20,
                height: 20,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(width: 12),
              ShimmerLoading(
                width: 120,
                height: 12,
                borderRadius: BorderRadius.circular(4),
              ),
              const Spacer(),
              ShimmerLoading(
                width: 40,
                height: 12,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedShimmerList(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ShimmerLoading(
              width: 160,
              height: 16,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 230,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 3,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                return Container(
                  width: 150,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.06),
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const ShimmerLoading(
                          width: double.infinity,
                          height: 110,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ShimmerLoading(
                                width: 110,
                                height: 12,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              const SizedBox(height: 8),
                              ShimmerLoading(
                                width: 70,
                                height: 10,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  ShimmerLoading(
                                    width: 50,
                                    height: 12,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.add,
                                      size: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
