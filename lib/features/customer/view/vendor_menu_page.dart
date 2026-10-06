import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:z_speed/core/enums/user_enums.dart';
import 'package:z_speed/features/restaurant/model/restaurant.dart';
import 'package:z_speed/components/shimmer_loading.dart';
import 'package:z_speed/l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/features/customer/cubit/restaurant_detail_cubit.dart';
import 'package:z_speed/features/customer/cubit/restaurant_detail_state.dart';
import 'package:z_speed/features/customer/widgets/restaurant_menu_header.dart';
import 'package:z_speed/features/customer/widgets/restaurant_menu_item_row.dart';
import 'package:z_speed/features/customer/widgets/menu_section_tab_bar.dart';
import 'package:z_speed/features/customer/view/item_profile_page.dart';
import 'package:z_speed/features/restaurant_owner/widgets/add_edit_item_dialog.dart';
import 'package:z_speed/features/restaurant_owner/cubit/restaurant_menu_cubit.dart';
import 'package:z_speed/features/cart/cubit/cart_cubit.dart';
import 'package:z_speed/features/cart/model/cart_item.dart';
import 'package:z_speed/features/restaurant/repository/restaurant_menu_repository_impl.dart';
import 'package:z_speed/features/restaurant/model/menu_item.dart' as models;
import 'package:z_speed/features/cart/view/full_cart_screen.dart';
import 'package:z_speed/features/customer/cubit/restaurant_browse_state.dart';
import 'package:z_speed/features/customer/widgets/restaurant_menu_item_card.dart';
import 'package:z_speed/features/pharmacy_chat/view/prescription_upload_bottom_sheet.dart';

/// Talabat-style restaurant menu page.
///
/// Dual purpose:
/// - **Customer view**: browse menu sections & items, tap to see item profile.
/// - **Owner view** (when [isOwner] is true): same layout with inline edit
///   buttons and a FAB to add new items.
///
/// Reuses [RestaurantDetailCubit] for streaming restaurant metadata,
/// menu sections, and items.
class RestaurantMenuPage extends StatelessWidget {
  final String restaurantId;

  /// If true, force owner mode. If null, auto-detect from FirebaseAuth uid.
  final bool? isOwner;

  const RestaurantMenuPage({
    super.key,
    required this.restaurantId,
    this.isOwner,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RestaurantDetailCubit(restaurantId: restaurantId),
      child: _RestaurantMenuContent(
        restaurantId: restaurantId,
        forceOwner: isOwner,
      ),
    );
  }
}

class _RestaurantMenuContent extends StatefulWidget {
  final String restaurantId;
  final bool? forceOwner;

  const _RestaurantMenuContent({
    required this.restaurantId,
    this.forceOwner,
  });

  @override
  State<_RestaurantMenuContent> createState() => _RestaurantMenuContentState();
}

class _RestaurantMenuContentState extends State<_RestaurantMenuContent> {
  static const _brandOrange = Color(0xFFF35535);

  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _ownerVm?.close();
    _searchController.dispose();
    super.dispose();
  }

  /// Determine whether the current user is the restaurant owner.
  bool _isOwnerMode(RestaurantDetailState state) {
    if (widget.forceOwner != null) return widget.forceOwner!;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || state.restaurant == null) return false;
    return state.restaurant!.ownerId == uid;
  }

  String? _subscribedVendorId;

  void _checkAndSubscribeBackOnlineNotification(
      Restaurant restaurant, bool isOwner) {
    if (isOwner) return;
    if (!restaurant.isBusy && restaurant.isOpen) return;
    if (_subscribedVendorId == restaurant.id) return;

    _subscribedVendorId = restaurant.id;
    _subscribeForBackOnlineNotification(restaurant);
  }

  Future<void> _subscribeForBackOnlineNotification(
      Restaurant restaurant) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final subId = '${restaurant.id}_$uid';
      await FirebaseFirestore.instance
          .collection('vendor_notify_subscriptions')
          .doc(subId)
          .set({
        'vendorId': restaurant.id,
        'userId': uid,
        'vendorName': restaurant.name,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(
            DateTime.now().add(const Duration(hours: 2))),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Failed to register notify subscription: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RestaurantDetailCubit>();
    final state = context.watch<RestaurantDetailCubit>().state;

    if (state.restaurant != null) {
      _checkAndSubscribeBackOnlineNotification(
          state.restaurant!, _isOwnerMode(state));
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: state.isLoading
          ? _buildLoadingMenu(context)
          : state.error != null
              ? _buildError(state, cubit)
              : state.restaurant == null
                  ? _buildNotFound()
                  : _buildContent(state, cubit),

      // Owner FAB: add new item
      floatingActionButton:
          (!state.isLoading && state.restaurant != null && _isOwnerMode(state))
              ? FloatingActionButton(
                  backgroundColor: _brandOrange,
                  onPressed: () => _showAddItemDialog(state),
                  child: const Icon(Icons.add, color: Colors.white),
                )
              : null,
    );
  }

  // ── Error / Not-Found ────────────────────────────────────────

  Widget _buildError(RestaurantDetailState state, RestaurantDetailCubit cubit) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context)!.errorLoadingRestaurant),
          const SizedBox(height: 8),
          Text(state.error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: cubit.refresh,
            icon: const Icon(Icons.refresh),
            label: Text(AppLocalizations.of(context)!.retry),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.restaurant_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context)!.restaurantNotFound),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.goBack),
          ),
        ],
      ),
    );
  }

  // ── Main Content ─────────────────────────────────────────────

  Widget _buildContent(
      RestaurantDetailState state, RestaurantDetailCubit cubit) {
    final restaurant = state.restaurant!;
    final isOwner = _isOwnerMode(state);
    final sections = isOwner
        ? state.sections
        : state.sections
            .where((section) => state.getFilteredItems(section.id).isNotEmpty)
            .toList();

    return CustomScrollView(
      slivers: [
        // ── Restaurant header (cover + info card) ──
        SliverToBoxAdapter(
          child: RestaurantMenuHeader(
            restaurant: restaurant,
            isOwner: isOwner,
          ),
        ),

          // ── Closed banner ──
          if (!restaurant.isOpen)
            SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                color: Colors.red.shade50,
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.vendorCurrentlyClosed(
                            restaurant.vendorType.label.toLowerCase()),
                        style:
                            TextStyle(color: Colors.red.shade700, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Busy banner ──
          if (restaurant.isOpen && restaurant.isBusy)
            SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade400),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
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
                    if (!isOwner) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.notifications_active_outlined,
                              size: 16, color: Colors.amber.shade800),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!
                                  .willNotifyWhenAvailable,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.amber.shade900),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

          // ── Pharmacy Prescription Upload Banner ──
          if (restaurant.vendorType == VendorType.pharmacy && !isOwner)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF059669), Color(0xFF10B981)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.25),
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
                        const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)?.localeName == 'ar'
                                ? 'اطلب بروشتة طبية'
                                : 'Order by Prescription',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppLocalizations.of(context)?.localeName == 'ar'
                          ? 'ارفع صورة الروشتة وسيقوم الصيدلي بمراجعتها ومحادثتك لايف شات لتأكيد الأدوية وتجهيز طلبك فوراً!'
                          : 'Upload your prescription image. The pharmacist will review it, chat with you in real-time, and prepare your items!',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          PrescriptionUploadBottomSheet.show(
                            context,
                            pharmacyId: restaurant.id,
                            pharmacyName: restaurant.name,
                          );
                        },
                        icon: const Icon(Icons.cloud_upload_rounded, color: Color(0xFF059669), size: 18),
                        label: Text(
                          AppLocalizations.of(context)?.localeName == 'ar'
                              ? 'إرفاق روشتة طبية'
                              : 'Upload Prescription',
                          style: const TextStyle(
                            color: Color(0xFF059669),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Sticky section tab bar ──
          if (sections.isNotEmpty)
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyTabBarDelegate(
                child: MenuSectionTabBar(
                  sections: sections,
                  selectedSectionId: state.selectedSectionId,
                  onSectionSelected: cubit.selectSection,
                ),
              ),
            ),

          // ── Search bar & View Style Toggle ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: cubit.setSearchQuery,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.searchMenuItems,
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: state.searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  cubit.setSearchQuery('');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildViewStyleIconButton(
                          context,
                          icon: Icons.grid_view_rounded,
                          isSelected: state.viewStyle == BrowseViewStyle.cards,
                          onTap: () => cubit.setViewStyle(BrowseViewStyle.cards),
                          tooltip: 'Cards View',
                        ),
                        const SizedBox(width: 2),
                        _buildViewStyleIconButton(
                          context,
                          icon: Icons.view_list_rounded,
                          isSelected: state.viewStyle == BrowseViewStyle.list,
                          onTap: () => cubit.setViewStyle(BrowseViewStyle.list),
                          tooltip: 'List View',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Menu sections + items ──
          if (sections.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptySeederState(context, state, cubit),
            )
          else
            ..._buildSectionSlices(state, isOwner),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
    );
  }

  Widget _buildViewStyleIconButton(
    BuildContext context, {
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: isSelected ? _brandOrange : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: _brandOrange.withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            size: 19,
            color: isSelected ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  /// Build section headers + item lists as slivers.
  List<Widget> _buildSectionSlices(
    RestaurantDetailState state,
    bool isOwner,
  ) {
    final widgets = <Widget>[];

    final sectionsToRender = state.sections.where((section) =>
        state.searchQuery.isNotEmpty ||
        state.selectedSectionId == null ||
        section.id == state.selectedSectionId);

    for (final section in sectionsToRender) {
      final items = state.getFilteredItems(section.id);

      // Skip empty sections when searching or always on customer app
      if (items.isEmpty && (state.searchQuery.isNotEmpty || !isOwner)) continue;

      // Section header
      widgets.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 20, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    section.getLocalizedName(
                        Localizations.localeOf(context).languageCode),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                if (items.isNotEmpty)
                  Text(
                    items.length == 1
                        ? AppLocalizations.of(context)!
                            .sectionItemCount(items.length)
                        : AppLocalizations.of(context)!
                            .sectionItemCountPlural(items.length),
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
              ],
            ),
          ),
        ),
      );

      // Divider
      widgets.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1, color: Colors.grey.shade200),
          ),
        ),
      );

      // Items list (Cards view vs List view)
      if (items.isEmpty) {
        widgets.add(
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  AppLocalizations.of(context)!.noItemsInSection,
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ),
            ),
          ),
        );
      } else if (state.viewStyle == BrowseViewStyle.cards) {
        widgets.add(
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverLayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.crossAxisExtent;
                final crossAxisCount = width >= 1024
                    ? 4
                    : (width >= 600 ? 3 : 2);
                final childAspectRatio = width < 480
                    ? 0.76
                    : (width < 768 ? 0.82 : 0.88);

                return SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: childAspectRatio,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = items[index];
                      return RestaurantMenuItemCard(
                        item: item,
                        showEditButton: isOwner,
                        onTap: () => _navigateToItemProfile(item, section.id),
                        onEdit: isOwner
                            ? () => _showEditItemDialog(item, section.id)
                            : null,
                      );
                    },
                    childCount: items.length,
                  ),
                );
              },
            ),
          ),
        );
      } else {
        // List view mode
        widgets.add(
          SliverPadding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            sliver: SliverLayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.crossAxisExtent;
                if (width < 600) {
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = items[index];
                        return Column(
                          children: [
                            RestaurantMenuItemRow(
                              item: item,
                              showEditButton: isOwner,
                              onTap: () =>
                                  _navigateToItemProfile(item, section.id),
                              onEdit: isOwner
                                  ? () =>
                                      _showEditItemDialog(item, section.id)
                                  : null,
                            ),
                            if (index < items.length - 1)
                              Divider(
                                height: 1,
                                indent: 16,
                                endIndent: 16,
                                color: Colors.grey.shade100,
                              ),
                          ],
                        );
                      },
                      childCount: items.length,
                    ),
                  );
                }

                // Wide screens list view grid layout
                final crossAxisCount = width >= 1024 ? 3 : 2;
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      mainAxisExtent: 114,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = items[index];
                        return Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          elevation: 1,
                          shadowColor: Colors.black12,
                          child: RestaurantMenuItemRow(
                            item: item,
                            showEditButton: isOwner,
                            onTap: () =>
                                _navigateToItemProfile(item, section.id),
                            onEdit: isOwner
                                ? () => _showEditItemDialog(item, section.id)
                                : null,
                          ),
                        );
                      },
                      childCount: items.length,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      }
    }
    return widgets;
  }

  // ── Navigation ───────────────────────────────────────────────

  void _navigateToItemProfile(models.MenuItem item, String sectionId) {
    final cubit = context.read<RestaurantDetailCubit>();
    final isOwner = _isOwnerMode(cubit.state);
    final isOpen = cubit.state.restaurant?.isOpen ?? false;

    final vendorType =
        cubit.state.restaurant?.vendorType ?? VendorType.restaurant;

    Navigator.push<CartItem>(
      context,
      MaterialPageRoute(
        builder: (_) => ItemProfilePage(
          item: item,
          restaurantId: widget.restaurantId,
          sectionId: sectionId,
          isRestaurantOpen:
              isOpen && !(cubit.state.restaurant?.isBusy ?? false),
          vendorType: vendorType,
          onEditPressed:
              isOwner ? () => _showEditItemDialog(item, sectionId) : null,
        ),
      ),
    ).then((cartItem) {
      if (cartItem != null && mounted) {
        final cartVM = context.read<CartCubit>();
        // Check for restaurant conflict
        if (cartVM.state.hasRestaurantConflict(widget.restaurantId)) {
          _showReplaceCartDialog(cartVM, cartItem);
        } else {
          cartVM.addToCart(cartItem);
          final messenger = ScaffoldMessenger.of(context);
          messenger.hideCurrentSnackBar();
          messenger.showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!
                          .addedToCartItem(cartItem.menuItemName),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              action: SnackBarAction(
                label: AppLocalizations.of(context)!.viewCart,
                textColor: Colors.white,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FullCartPage(),
                    ),
                  );
                },
              ),
              backgroundColor: _brandOrange,
            ),
          );
          Future.delayed(const Duration(seconds: 3), () {
            messenger.hideCurrentSnackBar();
          });
        }
      }
    });
  }

  /// Show dialog to replace cart with items from a different restaurant.
  void _showReplaceCartDialog(CartCubit cartVM, CartItem newItem) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.replaceCartItems),
        content: Text(AppLocalizations.of(context)!.replaceCartContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              cartVM.replaceCartWithItem(newItem);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!
                      .addedToCartItem(newItem.menuItemName)),
                  backgroundColor: _brandOrange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _brandOrange,
            ),
            child: Text(AppLocalizations.of(context)!.replace,
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Owner dialogs ────────────────────────────────────────────

  /// Lazily-created owner cubit for the add/edit dialog.
  RestaurantMenuCubit? _ownerVm;

  RestaurantMenuCubit _getOwnerVm() {
    _ownerVm ??= RestaurantMenuCubit(
      repository: RestaurantMenuRepositoryImpl(),
      restaurantId: widget.restaurantId,
    );
    return _ownerVm!;
  }

  void _showAddItemDialog(RestaurantDetailState state) {
    final selectedSection = state.selectedSectionId ??
        (state.sections.isNotEmpty ? state.sections.first.id : null);

    if (selectedSection == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!.createAMenuSection)),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AddEditItemDialog(
        viewModel: _getOwnerVm(),
        restaurantId: widget.restaurantId,
        cuisineTypeId: selectedSection,
      ),
    );
  }

  void _showEditItemDialog(models.MenuItem item, String sectionId) {
    showDialog(
      context: context,
      builder: (_) => AddEditItemDialog(
        viewModel: _getOwnerVm(),
        restaurantId: widget.restaurantId,
        cuisineTypeId: sectionId,
        item: item,
      ),
    );
  }

  Widget _buildEmptySeederState(
    BuildContext context,
    RestaurantDetailState state,
    RestaurantDetailCubit cubit,
  ) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF35535).withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 40,
                  color: Color(0xFFF35535),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isAr ? 'هذا المتجر فارغ حالياً' : 'This Store is Currently Empty',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                isAr
                    ? 'هذا المتجر لا يحتوي على أي منتجات حالياً.'
                    : 'This store has no products listed currently.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingMenu(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: false,
            floating: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          SliverToBoxAdapter(
            child: _buildMenuHeaderShimmer(context),
          ),
          SliverToBoxAdapter(
            child: Container(
              height: 50,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  ShimmerLoading(width: 80, height: 30, borderRadius: BorderRadius.circular(15)),
                  const SizedBox(width: 10),
                  ShimmerLoading(width: 60, height: 30, borderRadius: BorderRadius.circular(15)),
                  const SizedBox(width: 10),
                  ShimmerLoading(width: 90, height: 30, borderRadius: BorderRadius.circular(15)),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 4),
              child: ShimmerLoading(
                width: double.infinity,
                height: 48,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return Column(
                  children: [
                    _buildMenuItemShimmerRow(context),
                    Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: Colors.grey.shade100,
                    ),
                  ],
                );
              },
              childCount: 4,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildMenuHeaderShimmer(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ShimmerLoading(
          width: double.infinity,
          height: 200,
          borderRadius: BorderRadius.zero,
        ),
        Container(
          color: Colors.white,
          padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerLoading(
                    width: 56,
                    height: 56,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerLoading(
                          width: 180,
                          height: 20,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 8),
                        ShimmerLoading(
                          width: 100,
                          height: 12,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          ShimmerLoading(width: 30, height: 12, borderRadius: BorderRadius.circular(4)),
                          const SizedBox(height: 6),
                          ShimmerLoading(width: 40, height: 10, borderRadius: BorderRadius.circular(4)),
                        ],
                      ),
                    ),
                    _dividerShimmer(),
                    Expanded(
                      child: Column(
                        children: [
                          ShimmerLoading(width: 40, height: 12, borderRadius: BorderRadius.circular(4)),
                          const SizedBox(height: 6),
                          ShimmerLoading(width: 25, height: 10, borderRadius: BorderRadius.circular(4)),
                        ],
                      ),
                    ),
                    _dividerShimmer(),
                    Expanded(
                      child: Column(
                        children: [
                          ShimmerLoading(width: 40, height: 12, borderRadius: BorderRadius.circular(4)),
                          const SizedBox(height: 6),
                          ShimmerLoading(width: 30, height: 10, borderRadius: BorderRadius.circular(4)),
                        ],
                      ),
                    ),
                    _dividerShimmer(),
                    Expanded(
                      child: Column(
                        children: [
                          ShimmerLoading(width: 45, height: 12, borderRadius: BorderRadius.circular(4)),
                          const SizedBox(height: 6),
                          ShimmerLoading(width: 35, height: 10, borderRadius: BorderRadius.circular(4)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dividerShimmer() {
    return Container(
      width: 1,
      height: 32,
      color: Colors.grey.shade300,
    );
  }

  Widget _buildMenuItemShimmerRow(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerLoading(
                  width: 130,
                  height: 14,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                ShimmerLoading(
                  width: 200,
                  height: 11,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 6),
                ShimmerLoading(
                  width: 160,
                  height: 11,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 12),
                ShimmerLoading(
                  width: 60,
                  height: 12,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ShimmerLoading(
            width: 90,
            height: 90,
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
    );
  }
}

// ── Sticky Tab Bar Delegate ──────────────────────────────────────

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyTabBarDelegate({required this.child});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: overlapsContent
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }

  @override
  double get maxExtent => 50;

  @override
  double get minExtent => 50;

  @override
  bool shouldRebuild(covariant _StickyTabBarDelegate oldDelegate) =>
      oldDelegate.child != child;
}
