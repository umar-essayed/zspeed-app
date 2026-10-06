import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/core/enums/user_enums.dart';
import 'package:z_speed/core/result/result.dart';
import 'package:z_speed/features/auth/repository/auth_repository_impl.dart';
import 'package:z_speed/features/customer/view/item_profile_page.dart';
import 'package:z_speed/features/restaurant/model/menu_item.dart';
import 'package:z_speed/features/restaurant/repository/restaurant_menu_repository_impl.dart';
import 'package:z_speed/features/restaurant_owner/cubit/restaurant_menu_cubit.dart';
import 'package:z_speed/features/restaurant_owner/cubit/restaurant_menu_state.dart';
import 'package:z_speed/features/restaurant_owner/cubit/restaurant_profile_cubit.dart';
import 'package:z_speed/features/restaurant_owner/cubit/restaurant_profile_state.dart';
import 'package:z_speed/features/restaurant_owner/services/menu_excel_service.dart';
import 'package:z_speed/features/restaurant_owner/widgets/add_edit_item_dialog.dart';
import 'package:z_speed/features/restaurant_owner/widgets/excel_import_dialog.dart';
import 'package:z_speed/features/restaurant_owner/widgets/menu_item_card.dart';
import 'package:z_speed/features/restaurant_owner/widgets/menu_stat_card.dart';
import 'package:z_speed/l10n/app_localizations.dart';

String getMenuTitleForType(BuildContext context, VendorType vendorType) {
  final locale = Localizations.localeOf(context).languageCode;
  switch (vendorType) {
    case VendorType.pharmacy:
      return locale == 'ar' ? 'الأدوية' : 'Medicines';
    case VendorType.supermarket:
      return locale == 'ar' ? 'المنتجات' : 'Products';
    case VendorType.bookstore:
      return locale == 'ar' ? 'الكتب والأدوات المكتبية' : 'Books & Stationery';
    case VendorType.homeFurnishing:
      return locale == 'ar' ? 'الأثاث' : 'Furniture';
    case VendorType.meatAndProteins:
      return locale == 'ar' ? 'اللحوم والبروتينات' : 'Meat & Proteins';
    case VendorType.clothes:
      return locale == 'ar' ? 'الملابس' : 'Clothing';
    case VendorType.buyAndSell:
      return locale == 'ar' ? 'المنتجات المعروضة' : 'Listed Items';
    case VendorType.electronics:
      return locale == 'ar' ? 'الأجهزة الإلكترونية' : 'Electronics';
    default:
      return locale == 'ar' ? 'المنيو' : 'Menu';
  }
}

/// Menu management page for vendors.
///
/// Provides CRUD operations for menu sections, items, and addon groups.
/// Uses RestaurantProfileCubit and RestaurantMenuCubit via BlocProvider.
class MenuManagerPage extends StatelessWidget {
  const MenuManagerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getOwnerId(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final ownerId = snapshot.data;
        if (ownerId == null) {
          return Scaffold(
            appBar:
                AppBar(title: Text(AppLocalizations.of(context)!.menuManager)),
            body: Center(
              child: Text(AppLocalizations.of(context)!.pleaseLogInTo),
            ),
          );
        }

        final repository = RestaurantMenuRepositoryImpl();

        return MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => RestaurantProfileCubit(
                repository: repository,
                ownerId: ownerId,
              ),
            ),
          ],
          child: BlocBuilder<RestaurantProfileCubit, RestaurantProfileState>(
            builder: (context, restaurantState) {
              if (restaurantState.isLoading) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (restaurantState.error != null) {
                final vType = restaurantState.restaurant?.vendorType ??
                    VendorType.restaurant;
                return Scaffold(
                  appBar:
                      AppBar(title: Text(getMenuTitleForType(context, vType))),
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 64, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text(AppLocalizations.of(context)!
                            .failed(restaurantState.error.toString())),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () =>
                              context.read<RestaurantProfileCubit>().init(),
                          child: Text(AppLocalizations.of(context)!.retry),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (!restaurantState.hasRestaurant) {
                return Scaffold(
                  appBar: AppBar(
                      title: Text(AppLocalizations.of(context)!.menuManager)),
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.restaurant,
                            size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 20),
                        Text(
                          AppLocalizations.of(context)!.noRestaurantFound,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(AppLocalizations.of(context)!
                            .completeRestaurantSetup),
                      ],
                    ),
                  ),
                );
              }

              // Restaurant loaded, now provide menu cubit
              return BlocProvider(
                create: (_) => RestaurantMenuCubit(
                  repository: repository,
                  restaurantId: restaurantState.restaurantId!,
                  vendorType: restaurantState.restaurant?.vendorType ??
                      VendorType.restaurant,
                ),
                child: const _MenuManagerContent(),
              );
            },
          ),
        );
      },
    );
  }

  Future<String?> _getOwnerId() async {
    final authRepo = AuthRepositoryImpl();
    final result = await authRepo.getCurrentUser();
    switch (result) {
      case Success(:final data):
        return data.id;
      case Err():
        return null;
    }
  }
}

/// Internal content widget for menu manager (assumes Cubits are provided).
class _MenuManagerContent extends StatelessWidget {
  const _MenuManagerContent();

  String _getMenuTitle(BuildContext context, VendorType vendorType) {
    final locale = Localizations.localeOf(context).languageCode;
    switch (vendorType) {
      case VendorType.pharmacy:
        return locale == 'ar' ? 'الأدوية' : 'Medicines';
      case VendorType.supermarket:
        return locale == 'ar' ? 'المنتجات' : 'Products';
      case VendorType.bookstore:
        return locale == 'ar'
            ? 'الكتب والأدوات المكتبية'
            : 'Books & Stationery';
      case VendorType.homeFurnishing:
        return locale == 'ar' ? 'الأثاث' : 'Furniture';
      case VendorType.meatAndProteins:
        return locale == 'ar' ? 'اللحوم والبروتينات' : 'Meat & Proteins';
      case VendorType.clothes:
        return locale == 'ar' ? 'الملابس' : 'Clothing';
      case VendorType.buyAndSell:
        return locale == 'ar' ? 'المنتجات المعروضة' : 'Listed Items';
      case VendorType.electronics:
        return locale == 'ar' ? 'الأجهزة الإلكترونية' : 'Electronics';
      default:
        return locale == 'ar' ? 'المنيو' : 'Menu';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RestaurantMenuCubit, RestaurantMenuState>(
      builder: (context, state) {
        final cubit = context.read<RestaurantMenuCubit>();
        return Column(
          children: [
            _buildAppBarContent(context, cubit),
            Expanded(child: _buildBody(context, cubit, state)),
          ],
        );
      },
    );
  }

  Widget _buildAppBarContent(BuildContext context, RestaurantMenuCubit cubit) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.menu,
                      size: 24, color: Color(0xFF333333)),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _getMenuTitle(context, cubit.vendorType),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.5,
                      fontSize: 18,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _showImportDialog(context, cubit),
                  icon: const Icon(Icons.table_chart_outlined,
                      size: 16, color: Color(0xFFE65100)),
                  label: Text(AppLocalizations.of(context)!.excelImportBtn,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFFE65100))),
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    side: const BorderSide(color: Color(0xFFE65100)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _showAddItemDialog(context, cubit),
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(AppLocalizations.of(context)!.addItem,
                      style:
                          const TextStyle(fontSize: 13, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    backgroundColor: const Color(0xFFFF9800),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          Container(color: Colors.grey.shade200, height: 1),
        ],
      ),
    );
  }

  void _showImportDialog(BuildContext context, RestaurantMenuCubit cubit) {
    final profileState = context.read<RestaurantProfileCubit>().state;
    final vendorType =
        profileState.restaurant?.vendorType ?? VendorType.restaurant;

    final List<String> sectionNames;
    if (vendorType == VendorType.restaurant) {
      sectionNames = cubit.state.cuisineTypes.map((ct) => ct.name).toList();
    } else {
      // Use the sections the admin has configured in System Settings (VendorSection
      // documents from Firestore), so the import validates against the real section
      // list rather than the hardcoded fallback in VendorSections.forType().
      final dbSections =
          cubit.state.vendorSections.map((vs) => vs.name).toList();
      sectionNames = dbSections.isNotEmpty
          ? dbSections
          : (VendorSections.forType(vendorType) ?? []);
    }

    showDialog(
      context: context,
      builder: (_) => ExcelImportDialog(
        cubit: cubit,
        vendorType: vendorType,
        sectionNames: sectionNames,
      ),
    );
  }

  Widget _buildBody(BuildContext context, RestaurantMenuCubit cubit,
      RestaurantMenuState state) {
    const primaryOrange = Color(0xFFFF9800);
    const lightOrange = Color(0xFFFFF3E0);
    const textColor = Color(0xFF333333);
    const greyColor = Color(0xFF666666);

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.failed(state.error.toString())),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => cubit.init(),
              style: ElevatedButton.styleFrom(
                  backgroundColor: primaryOrange,
                  foregroundColor: Colors.white),
              child: Text(AppLocalizations.of(context)!.retry),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Search and Stats Section
        Container(
          padding: const EdgeInsets.all(20),
          color: Colors.white,
          child: Column(
            children: [
              // Search Bar
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.searchMenuItems,
                    hintStyle: const TextStyle(color: greyColor),
                    prefixIcon: const Icon(Icons.search, color: primaryOrange),
                    suffixIcon: state.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: primaryOrange),
                            onPressed: () => cubit.setSearchQuery(''),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: lightOrange.withValues(alpha: 0.3),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  // ignore: deprecated_member_use
                  onChanged: (value) => cubit.setSearchQuery(value),
                ),
              ),
              const SizedBox(height: 20),

              // Quick Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  MenuStatCard(
                    title: AppLocalizations.of(context)!.totalItems,
                    value: state.totalItems.toString(),
                    color: primaryOrange,
                    isSelected: state.statusFilter == ItemStatusFilter.all,
                    onTap: () => cubit.setStatusFilter(ItemStatusFilter.all),
                  ),
                  MenuStatCard(
                    title: AppLocalizations.of(context)!.available,
                    value: state.availableItems.toString(),
                    color: const Color(0xFF4CAF50),
                    isSelected:
                        state.statusFilter == ItemStatusFilter.available,
                    onTap: () =>
                        cubit.setStatusFilter(ItemStatusFilter.available),
                  ),
                  MenuStatCard(
                    title: AppLocalizations.of(context)!.unavailable,
                    value: state.unavailableItems.toString(),
                    color: const Color(0xFF757575),
                    isSelected:
                        state.statusFilter == ItemStatusFilter.unavailable,
                    onTap: () =>
                        cubit.setStatusFilter(ItemStatusFilter.unavailable),
                  ),
                  MenuStatCard(
                    title: AppLocalizations.of(context)!.onSale,
                    value: state.onSaleItems.toString(),
                    color: const Color(0xFFE53935),
                    isSelected: state.statusFilter == ItemStatusFilter.onSale,
                    onTap: () => cubit.setStatusFilter(ItemStatusFilter.onSale),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Section Tabs
              _buildSectionTabs(context, cubit, state, primaryOrange),
            ],
          ),
        ),

        Container(height: 8, color: Colors.grey.shade50),

        // Menu Items List + Pagination
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.filteredItems.isEmpty
                  ? _buildEmptyState(context, cubit, state, primaryOrange,
                      lightOrange, textColor, greyColor)
                  : _buildItemsList(context, cubit, state),
        ),
      ],
    );
  }

  Widget _buildSectionTabs(BuildContext context, RestaurantMenuCubit cubit,
      RestaurantMenuState state, Color primaryOrange) {
    final langCode = Localizations.localeOf(context).languageCode;

    // Build (id, label) pairs using the restaurant's menu sections, hiding empty ones
    final tabEntries = state.sections
        .map((section) {
          final count =
              state.allItems.where((i) => i.sectionId == section.id).length;
          return (section.id, section, count);
        })
        .where((tup) => tup.$3 > 0)
        .map((tup) =>
            (tup.$1, '${tup.$2.getLocalizedName(langCode)} (${tup.$3})'))
        .toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // "All" chip
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: ChoiceChip(
              label: Text(
                  AppLocalizations.of(context)!.allCount(state.totalItems)),
              selected: state.selectedCuisineTypeId == null,
              onSelected: (_) => cubit.selectCuisineType(null),
              selectedColor: primaryOrange,
              labelStyle: TextStyle(
                color: state.selectedCuisineTypeId == null
                    ? Colors.white
                    : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Section chips
          ...tabEntries.map((entry) {
            final (id, label) = entry;
            return Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: ChoiceChip(
                label: Text(label),
                selected: state.selectedCuisineTypeId == id,
                onSelected: (_) => cubit.selectCuisineType(id),
                selectedColor: primaryOrange,
                labelStyle: TextStyle(
                  color: state.selectedCuisineTypeId == id
                      ? Colors.white
                      : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    RestaurantMenuCubit cubit,
    RestaurantMenuState state,
    Color primaryOrange,
    Color lightOrange,
    Color textColor,
    Color greyColor,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.fromSTEB(40, 24, 40, 80),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.restaurant_menu, size: 64, color: lightOrange),
          const SizedBox(height: 16),
          Text(
            state.allItems.isEmpty
                ? AppLocalizations.of(context)!.noMenuItemsYet
                : AppLocalizations.of(context)!.tryAdjustingYourSearch,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            cubit.state.allItems.isEmpty
                ? AppLocalizations.of(context)!.tapAddItemToCreate
                : AppLocalizations.of(context)!.tryAdjustingYourSearch,
            style: TextStyle(color: greyColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _showAddItemDialog(context, cubit),
            icon: const Icon(Icons.add, size: 20),
            label: Text(AppLocalizations.of(context)!.addFirstItem,
                style: const TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationFooter(
    BuildContext context,
    RestaurantMenuCubit cubit,
    RestaurantMenuState state,
    Color primaryOrange,
  ) {
    final total = state.filteredItems.length;
    final page = state.currentPage;
    final pages = state.totalPages;
    final start = page * state.pageSize + 1;
    final end = (start + state.pageSize - 1).clamp(1, total);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: page > 0 ? () => cubit.previousPage() : null,
            icon: const Icon(Icons.chevron_left),
            label: const Text('Prev'),
            style: TextButton.styleFrom(foregroundColor: primaryOrange),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Page ${page + 1} of $pages',
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              Text(
                '$start–$end of $total',
                style: const TextStyle(fontSize: 11, color: Color(0xFF888888)),
              ),
            ],
          ),
          TextButton.icon(
            onPressed: page < pages - 1 ? () => cubit.nextPage() : null,
            icon: const Icon(Icons.chevron_right),
            label: const Text('Next'),
            style: TextButton.styleFrom(foregroundColor: primaryOrange),
            iconAlignment: IconAlignment.end,
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(BuildContext context, RestaurantMenuCubit cubit,
      RestaurantMenuState state) {
    const primaryOrange = Color(0xFFFF9800);
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        const double spacing = 16.0;
        final int columns = (width / 280).floor().clamp(1, 5);

        // Adjust height estimation: image (140) + padding & details (~130) + action bar (~50) + stock badge if present (~30)
        final bool hasStock = state.paginatedItems.any((i) => i.stock != null);
        final double itemHeight = hasStock ? 380.0 : 340.0;

        if (columns == 1) {
          return ListView.builder(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 80),
            itemCount: state.paginatedItems.length + 1,
            itemBuilder: (context, index) {
              if (index == state.paginatedItems.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 24),
                  child: _buildPaginationFooter(
                      context, cubit, state, primaryOrange),
                );
              }
              final item = state.paginatedItems[index];
              final sectionName = state.cuisineTypeName(item.sectionId);

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: MenuItemCard(
                  item: item,
                  sectionName: sectionName,
                  onEdit: () => _showEditItemDialog(context, cubit, item),
                  onDelete: () => _deleteItem(context, cubit, item),
                  onToggleAvailability: () =>
                      cubit.toggleItemAvailability(item),
                  onPreview: () => _previewItem(context, cubit, item),
                ),
              );
            },
          );
        }

        final double itemWidth = (width - (spacing * (columns - 1))) / columns;
        final double aspectRatio = itemWidth / itemHeight;

        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 16),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: spacing,
                  crossAxisSpacing: spacing,
                  childAspectRatio: aspectRatio,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = state.paginatedItems[index];
                    final sectionName = state.cuisineTypeName(item.sectionId);

                    return MenuItemCard(
                      item: item,
                      sectionName: sectionName,
                      onEdit: () => _showEditItemDialog(context, cubit, item),
                      onDelete: () => _deleteItem(context, cubit, item),
                      onToggleAvailability: () =>
                          cubit.toggleItemAvailability(item),
                      onPreview: () => _previewItem(context, cubit, item),
                      isGrid: true,
                    );
                  },
                  childCount: state.paginatedItems.length,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
                child: _buildPaginationFooter(
                    context, cubit, state, primaryOrange),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Dialogs ──────────────────────────────────────────────────────

  void _showAddItemDialog(BuildContext context, RestaurantMenuCubit cubit) {
    final vendorType = cubit.vendorType;
    final hasOptions = vendorType == VendorType.restaurant
        ? cubit.state.cuisineTypes.isNotEmpty
        : cubit.state.vendorSections.isNotEmpty;

    if (!hasOptions) {
      final msg = vendorType == VendorType.restaurant
          ? AppLocalizations.of(context)!.noCuisineTypesAvailable
          : 'No sections available. Ask your admin to add sections first.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.orange),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AddEditItemDialog(
        viewModel: cubit,
        restaurantId: cubit.restaurantId,
        cuisineTypeId: cubit.state.selectedCuisineTypeId,
        vendorType: vendorType,
      ),
    );
  }

  void _previewItem(
      BuildContext context, RestaurantMenuCubit cubit, MenuItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ItemProfilePage(
          item: item,
          restaurantId: cubit.restaurantId,
          sectionId: item.sectionId,
          onEditPressed: () {
            Navigator.pop(context);
            _showEditItemDialog(context, cubit, item);
          },
        ),
      ),
    );
  }

  void _showEditItemDialog(
      BuildContext context, RestaurantMenuCubit cubit, MenuItem item) {
    showDialog(
      context: context,
      builder: (dialogContext) => AddEditItemDialog(
        viewModel: cubit,
        restaurantId: cubit.restaurantId,
        cuisineTypeId: item.sectionId,
        item: item,
        vendorType: cubit.vendorType,
      ),
    );
  }

  void _deleteItem(
      BuildContext context, RestaurantMenuCubit cubit, MenuItem item) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          AppLocalizations.of(context)!.deleteItem,
          style: const TextStyle(
            color: Color(0xFFFF9800),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(AppLocalizations.of(context)!.confirmDeleteItem(item
            .getLocalizedName(Localizations.localeOf(context).languageCode))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.of(context)!.cancel,
                style: const TextStyle(color: Color(0xFF666666))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);

              try {
                await cubit.deleteItem(item);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context)!
                          .itemDeletedSuccessfully),
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          '${AppLocalizations.of(context)!.failedToDeleteItem}: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text(AppLocalizations.of(context)!.delete,
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
