import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:z_speed/features/auth/cubit/auth_cubit.dart';
import 'package:z_speed/components/shimmer_loading.dart';
import 'package:z_speed/features/notification/cubit/notification_cubit.dart';
import 'package:z_speed/features/notification/cubit/notification_state.dart';
import 'package:z_speed/features/notification/view/notification_list_page.dart';
import 'package:z_speed/features/settings/view/settings_screen.dart';
import 'package:z_speed/features/customer/widgets/guest_auth_prompt.dart';
import 'package:z_speed/l10n/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/core/enums/user_enums.dart';
import 'package:z_speed/features/customer/cubit/restaurant_browse_cubit.dart';
import 'package:z_speed/features/customer/cubit/restaurant_browse_state.dart';
import 'package:z_speed/features/customer/widgets/vendor_browse_card.dart';
import 'package:z_speed/features/customer/widgets/cuisine_filter_bar.dart';
import 'package:z_speed/features/customer/view/vendor_menu_page.dart';
import 'package:z_speed/features/stories/widgets/story_circle_list.dart';

/// Vendor browse screen for customers — works for restaurants, supermarkets and pharmacies.
class RestaurantBrowseScreen extends StatefulWidget {
  final bool isGuest;
  final Function(VendorType)? onVendorTypeChanged;

  const RestaurantBrowseScreen({
    super.key,
    this.isGuest = false,
    this.onVendorTypeChanged,
  });

  @override
  State<RestaurantBrowseScreen> createState() => _RestaurantBrowseScreenState();
}

class _RestaurantBrowseScreenState extends State<RestaurantBrowseScreen> {
  final FocusNode _searchFocusNode = FocusNode();
  late TextEditingController _searchController;
  bool _isSearchFocused = false;
  late final ScrollController _categoriesScrollController;
  final GlobalKey _startOfLoopKey = GlobalKey();
  int _middleLoopStart = 0;
  bool _isControllerInitialized = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
        text: context.read<RestaurantBrowseCubit>().state.searchQuery);
    _searchFocusNode.addListener(_onSearchFocusChange);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isControllerInitialized) {
      final services = _getBrowseServices(context);
      final servicesCount = services.length;
      _middleLoopStart = servicesCount > 0
          ? (5000 ~/ servicesCount) * servicesCount
          : 0;
      _categoriesScrollController = ScrollController(
        initialScrollOffset: _middleLoopStart * 115.0,
      );
      _isControllerInitialized = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_categoriesScrollController.hasClients) {
          final context = _startOfLoopKey.currentContext;
          if (context != null) {
            Scrollable.ensureVisible(
              context,
              alignment: 0.0,
              duration: Duration.zero,
            );
          }
        }
      });
    }
  }

  void _onSearchFocusChange() {
    setState(() {
      _isSearchFocused = _searchFocusNode.hasFocus;
    });
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_onSearchFocusChange);
    _searchFocusNode.dispose();
    _searchController.dispose();
    _categoriesScrollController.dispose();
    super.dispose();
  }

  Widget _buildGlassButton({
    required Widget child,
    required VoidCallback onTap,
    double radius = 20,
  }) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(radius),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RestaurantBrowseCubit>();
    final state = context.watch<RestaurantBrowseCubit>().state;

    if (state.error != null) {
      final l10n = AppLocalizations.of(context)!;
      final errorLabel = switch (state.vendorType) {
        VendorType.supermarket => l10n.errorLoadingSupermarkets,
        VendorType.pharmacy => l10n.errorLoadingPharmacies,
        VendorType.bookstore => l10n.localeName == 'ar'
            ? 'حدث خطأ أثناء تحميل المكتبات'
            : 'Error loading bookstores',
        VendorType.homeFurnishing => l10n.localeName == 'ar'
            ? 'حدث خطأ أثناء تحميل معارض الأثاث'
            : 'Error loading furniture stores',
        VendorType.meatAndProteins => l10n.errorLoadingMeatAndProteins,
        VendorType.clothes => l10n.errorLoadingClothes,
        VendorType.buyAndSell => l10n.errorLoadingBuyAndSell,
        VendorType.electronics => l10n.errorLoadingElectronics,
        _ => l10n.errorLoadingRestaurants,
      };
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              errorLabel,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              state.error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => cubit.refresh(),
              icon: const Icon(Icons.refresh),
              label: Text(AppLocalizations.of(context)!.retry),
            ),
          ],
        ),
      );
    }

    final l10n = AppLocalizations.of(context)!;
    final searchHint = switch (state.vendorType) {
      VendorType.supermarket => l10n.searchSupermarkets,
      VendorType.pharmacy => l10n.searchPharmacies,
      VendorType.bookstore => l10n.localeName == 'ar'
          ? 'ابحث عن كتب، أدوات مكتبية ومدرسية...'
          : 'Search for books, stationery...',
      VendorType.homeFurnishing => l10n.localeName == 'ar'
          ? 'ابحث عن أثاث، مفروشات، وسائد...'
          : 'Search for furniture, bedding, pillows...',
      VendorType.meatAndProteins => l10n.searchMeatAndProteins,
      VendorType.clothes => l10n.searchClothes,
      VendorType.buyAndSell => l10n.searchBuyAndSell,
      VendorType.electronics => l10n.searchElectronics,
      _ => l10n.searchRestaurantsDishes,
    };

    final emptyIcon = switch (state.vendorType) {
      VendorType.supermarket => Icons.shopping_cart_outlined,
      VendorType.pharmacy => Icons.local_pharmacy_outlined,
      VendorType.bookstore => Icons.menu_book_outlined,
      VendorType.homeFurnishing => Icons.chair_outlined,
      VendorType.meatAndProteins => Icons.restaurant_menu_rounded,
      VendorType.clothes => Icons.checkroom_rounded,
      VendorType.buyAndSell => Icons.swap_horiz_rounded,
      VendorType.electronics => Icons.devices_rounded,
      _ => Icons.restaurant_outlined,
    };

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Stack(
        children: [
          // ── Background Image with Fade Overlay & Subtle Blur ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 180,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/home/hero.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.25),
                          Colors.transparent,
                          Theme.of(context).scaffoldBackgroundColor,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // ── Content ──
          Positioned.fill(
            child: RefreshIndicator(
              onRefresh: () async => cubit.refresh(),
              child: CustomScrollView(
                slivers: [
                  // Search Bar + Profile/Notification
                  SliverToBoxAdapter(
                    child: Builder(
                      builder: (context) {
                        final double statusBarHeight =
                            MediaQuery.of(context).padding.top;
                        final double safeAreaLeft =
                            MediaQuery.of(context).padding.left;
                        final double safeAreaRight =
                            MediaQuery.of(context).padding.right;

                        return Padding(
                          padding: EdgeInsets.fromLTRB(
                            16 + safeAreaLeft,
                            statusBarHeight + 8,
                            16 + safeAreaRight,
                            8,
                          ),
                          child: SizedBox(
                            height: 46,
                            child: Row(
                              children: [
                                Expanded(
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOutCubic,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                          alpha: _isSearchFocused ? 0.35 : 0.2),
                                      borderRadius: BorderRadius.circular(30),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _isSearchFocused
                                              ? const Color(0xFFF35535)
                                                  .withValues(alpha: 0.15)
                                              : Colors.black
                                                  .withValues(alpha: 0.05),
                                          blurRadius:
                                              _isSearchFocused ? 25 : 15,
                                          spreadRadius:
                                              _isSearchFocused ? 2 : 0,
                                          offset: _isSearchFocused
                                              ? const Offset(0, 8)
                                              : const Offset(0, 4),
                                        ),
                                      ],
                                      border: Border.all(
                                        color: _isSearchFocused
                                            ? const Color(0xFFF35535)
                                            : Colors.white
                                                .withValues(alpha: 0.3),
                                        width: _isSearchFocused ? 2.0 : 1.0,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(30),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(
                                            sigmaX: 10, sigmaY: 10),
                                        child: TextField(
                                          focusNode: _searchFocusNode,
                                          controller: _searchController,
                                          textAlignVertical:
                                              TextAlignVertical.center,
                                          textDirection:
                                              Localizations.localeOf(context)
                                                          .languageCode ==
                                                      'ar'
                                                  ? TextDirection.rtl
                                                  : TextDirection.ltr,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: searchHint,
                                            hintStyle: TextStyle(
                                              color: Colors.white
                                                  .withValues(alpha: 0.6),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            prefixIcon: AnimatedScale(
                                              scale:
                                                  _isSearchFocused ? 1.15 : 1.0,
                                              duration: const Duration(
                                                  milliseconds: 200),
                                              child: AnimatedRotation(
                                                turns: _isSearchFocused
                                                    ? 0.05
                                                    : 0.0,
                                                duration: const Duration(
                                                    milliseconds: 250),
                                                child: Icon(
                                                  Icons.search_rounded,
                                                  color: _isSearchFocused
                                                      ? const Color(0xFFF35535)
                                                      : Colors.white.withValues(
                                                          alpha: 0.7),
                                                  size: 22,
                                                ),
                                              ),
                                            ),
                                            suffixIcon: state
                                                    .searchQuery.isNotEmpty
                                                ? IconButton(
                                                    icon: const Icon(
                                                        Icons.clear_rounded,
                                                        color: Colors.white,
                                                        size: 18),
                                                    onPressed: () {
                                                      _searchController.clear();
                                                      cubit.setSearchQuery('');
                                                    },
                                                  )
                                                : null,
                                            border: InputBorder.none,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                    vertical: 14,
                                                    horizontal: 16),
                                          ),
                                          onChanged: (query) =>
                                              cubit.setSearchQuery(query),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                 SizedBox(
                                   width: 44,
                                   height: 44,
                                   child: AnimatedSwitcher(
                                     duration: const Duration(milliseconds: 250),
                                     child: _isSearchFocused
                                         ? SizedBox(
                                             key: const ValueKey('close'),
                                             width: 44,
                                             height: 44,
                                             child: _buildHeaderButton(
                                               context,
                                               icon: Icons.close_rounded,
                                               onTap: () {
                                                 _searchFocusNode.unfocus();
                                               },
                                             ),
                                           )
                                         : SizedBox(
                                             key: const ValueKey('notification'),
                                             width: 44,
                                             height: 44,
                                             child: _buildNotificationButton(context),
                                           ),
                                   ),
                                 ),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeInOut,
                                  width: _isSearchFocused ? 0 : 8,
                                ),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeInOut,
                                  width: _isSearchFocused ? 0 : 44,
                                  height: _isSearchFocused ? 0 : 44,
                                  child: AnimatedOpacity(
                                    duration: const Duration(milliseconds: 200),
                                    opacity: _isSearchFocused ? 0.0 : 1.0,
                                    child: ClipRRect(
                                      child: _buildHeaderButton(
                                        context,
                                        icon: Icons.person_outline,
                                        onTap: () {
                                          final authState =
                                              context.read<AuthCubit>().state;
                                          if (authState.isGuest) {
                                            GuestAuthPrompt.show(
                                              context,
                                              actionLabel:
                                                  AppLocalizations.of(context)!
                                                      .viewProfile,
                                            );
                                            return;
                                          }
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) =>
                                                      const SettingsPage()));
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // ── Premium Services Horizontal Navigation Bar ──
                  SliverToBoxAdapter(
                    child: Container(
                      height: 50,
                      margin: const EdgeInsets.only(top: 18, bottom: 16),
                      child: ListView.builder(
                        controller: _categoriesScrollController,
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: 10000,
                        itemBuilder: (context, index) {
                          final services = _getBrowseServices(context);
                          if (services.isEmpty) return const SizedBox.shrink();
                          final serviceIndex = index % services.length;
                          final service = services[serviceIndex];
                          final isSelected = service.vendorType != null &&
                              state.vendorType == service.vendorType;

                          return GestureDetector(
                            key: index == _middleLoopStart ? _startOfLoopKey : null,
                            onTap: () {
                              if (service.vendorType != null) {
                                cubit.setVendorType(service.vendorType!);
                                widget.onVendorTypeChanged
                                    ?.call(service.vendorType!);
                              } else if (service.route != null) {
                                Navigator.of(context, rootNavigator: true)
                                    .pushNamed(service.route!);
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(right: 8),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? service.color
                                    : service.color.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: isSelected
                                      ? service.color
                                      : service.color.withValues(alpha: 0.12),
                                  width: 1.5,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: service.color
                                              .withValues(alpha: 0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        )
                                      ]
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    service.icon,
                                    size: 18,
                                    color: isSelected
                                        ? Colors.white
                                        : service.color,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    service.name,
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.black87),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Stories Section (filtered by current vendor type)
                  SliverToBoxAdapter(
                    child: StoryCircleList(
                      vendorTypeFilter: state.vendorType,
                    ),
                  ),

                  // Cuisine Filter Bar (restaurants only)
                  if (state.showCuisineFilter &&
                      state.availableCuisines.isNotEmpty)
                    SliverToBoxAdapter(
                      child: CuisineFilterBar(
                        cuisines: state.availableCuisines,
                        cuisineTypes: state.cuisineTypes,
                        selectedCuisine: state.selectedCuisine,
                        onCuisineSelected: (cuisine) =>
                            cubit.setCuisineFilter(cuisine),
                      ),
                    ),

                  // Sort and Filter Controls
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        children: [
                          // Sort Dropdown
                          Expanded(
                            child: DropdownButtonFormField<SortOption>(
                              isExpanded: true,
                              initialValue: state.sortOption,
                              onChanged: (value) {
                                if (value != null) cubit.setSortOption(value);
                              },
                              decoration: InputDecoration(
                                labelText: AppLocalizations.of(context)!.sortBy,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: SortOption.rating,
                                  child: Text(
                                    AppLocalizations.of(context)!.rating,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: SortOption.deliveryTime,
                                  child: Text(
                                    AppLocalizations.of(context)!.deliveryTimeFilter,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: SortOption.deliveryFee,
                                  child: Text(
                                    AppLocalizations.of(context)!.deliveryFeeFilter,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: SortOption.name,
                                  child: Text(
                                    AppLocalizations.of(context)!.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 6),

                          // Open Only Toggle
                          FilterChip(
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 0),
                            labelStyle: const TextStyle(fontSize: 12),
                            label: Text(AppLocalizations.of(context)!.openOnly),
                            selected: state.showOpenOnly,
                            onSelected: (_) => cubit.toggleOpenOnly(),
                            avatar: Icon(
                              state.showOpenOnly
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              size: 16,
                            ),
                          ),

                          const SizedBox(width: 6),

                          // View Style Toggle (Cards vs List)
                          Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.grey.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            padding: const EdgeInsets.all(3),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildViewStyleIconButton(
                                  context,
                                  icon: Icons.grid_view_rounded,
                                  isSelected:
                                      state.viewStyle == BrowseViewStyle.cards,
                                  onTap: () =>
                                      cubit.setViewStyle(BrowseViewStyle.cards),
                                  tooltip: 'Cards View',
                                ),
                                const SizedBox(width: 2),
                                _buildViewStyleIconButton(
                                  context,
                                  icon: Icons.view_list_rounded,
                                  isSelected:
                                      state.viewStyle == BrowseViewStyle.list,
                                  onTap: () =>
                                      cubit.setViewStyle(BrowseViewStyle.list),
                                  tooltip: 'List View',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Restaurant List (or loading/empty state)
                  if (state.isLoading)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      sliver: SliverLayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.crossAxisExtent;
                          if (state.viewStyle == BrowseViewStyle.cards) {
                            final crossAxisCount = width >= 1024
                                ? 4
                                : (width >= 768 ? 3 : 2);
                            final childAspectRatio = width < 480
                                ? 0.75
                                : (width < 768 ? 0.82 : 0.88);
                            return SliverGrid(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: childAspectRatio,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) =>
                                    _buildBrowseGridShimmerCard(context),
                                childCount: 6,
                              ),
                            );
                          } else {
                            if (width < 600) {
                              return SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) =>
                                      _buildBrowseShimmerCard(context),
                                  childCount: 5,
                                ),
                              );
                            }
                            final crossAxisCount = width >= 1024 ? 3 : 2;
                            return SliverGrid(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                mainAxisExtent: 132,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) =>
                                    _buildBrowseShimmerCard(context),
                                childCount: 6,
                              ),
                            );
                          }
                        },
                      ),
                    )
                  else if (state.restaurants.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyBrowseSeederState(
                          context, state, cubit, emptyIcon, l10n),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      sliver: SliverLayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.crossAxisExtent;
                          if (state.viewStyle == BrowseViewStyle.cards) {
                            final crossAxisCount = width >= 1024
                                ? 4
                                : (width >= 768 ? 3 : 2);
                            final childAspectRatio = width < 480
                                ? 0.75
                                : (width < 768 ? 0.82 : 0.88);
                            return SliverGrid(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: childAspectRatio,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final restaurant = state.restaurants[index];
                                  return RestaurantBrowseGridCard(
                                    restaurant: restaurant,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => RestaurantMenuPage(
                                            restaurantId: restaurant.id,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                                childCount: state.restaurants.length,
                              ),
                            );
                          } else {
                            if (width < 600) {
                              return SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final restaurant = state.restaurants[index];
                                    return RestaurantBrowseCard(
                                      restaurant: restaurant,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => RestaurantMenuPage(
                                              restaurantId: restaurant.id,
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                  childCount: state.restaurants.length,
                                ),
                              );
                            }
                            final crossAxisCount = width >= 1024 ? 3 : 2;
                            return SliverGrid(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                mainAxisExtent: 132,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final restaurant = state.restaurants[index];
                                  return RestaurantBrowseCard(
                                    restaurant: restaurant,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => RestaurantMenuPage(
                                            restaurantId: restaurant.id,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                                childCount: state.restaurants.length,
                              ),
                            );
                          }
                        },
                      ),
                    ),

                  // Bottom padding
                  const SliverToBoxAdapter(child: SizedBox(height: 110)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton(BuildContext context,
      {required IconData icon, required VoidCallback onTap}) {
    return _buildGlassButton(
      onTap: onTap,
      radius: 20,
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  Widget _buildNotificationButton(BuildContext context) {
    NotificationCubit? notificationCubit;
    try {
      notificationCubit = context.read<NotificationCubit>();
    } catch (_) {}

    if (notificationCubit == null) {
      return _buildHeaderButton(context,
          icon: Icons.notifications_outlined, onTap: () {});
    }

    return BlocBuilder<NotificationCubit, NotificationState>(
      bloc: notificationCubit,
      builder: (context, state) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            _buildHeaderButton(
              context,
              icon: Icons.notifications_outlined,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider<NotificationCubit>.value(
                      value: notificationCubit!,
                      child: const NotificationListPage(),
                    ),
                  ),
                );
              },
            ),
            if (state.unreadCount > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF4B2B),
                    shape: BoxShape.circle,
                  ),
                  constraints:
                      const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Center(
                    child: Text(
                      state.unreadCount > 99 ? '99+' : '${state.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyBrowseSeederState(
    BuildContext context,
    RestaurantBrowseState state,
    RestaurantBrowseCubit cubit,
    IconData emptyIcon,
    AppLocalizations l10n,
  ) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    final title = switch (state.vendorType) {
      VendorType.pharmacy => l10n.noPharmaciesFound,
      VendorType.supermarket => l10n.noSupermarketsFound,
      VendorType.bookstore =>
        isAr ? 'لم يتم العثور على مكتبات' : 'No bookstores found',
      VendorType.homeFurnishing =>
        isAr ? 'لم يتم العثور على معارض أثاث' : 'No furniture stores found',
      VendorType.meatAndProteins => l10n.noMeatAndProteinsFound,
      VendorType.clothes => l10n.noClothesFound,
      VendorType.buyAndSell => l10n.noBuyAndSellFound,
      VendorType.electronics => l10n.noElectronicsFound,
      _ => l10n.noRestaurantsFound,
    };

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
                child: Icon(
                  emptyIcon,
                  size: 40,
                  color: const Color(0xFFF35535),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isAr
                    ? 'هذا التصنيف فارغ حالياً من أي متاجر نشطة.'
                    : 'This category is currently empty.',
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

  Widget _buildBrowseShimmerCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ShimmerLoading(
              width: 130,
              height: 120,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerLoading(
                      width: 60,
                      height: 11,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 6),
                    ShimmerLoading(
                      width: 150,
                      height: 15,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 3),
                        ShimmerLoading(
                          width: 30,
                          height: 12,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded,
                            size: 14, color: Colors.grey[400]),
                        const SizedBox(width: 3),
                        ShimmerLoading(
                          width: 60,
                          height: 11,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(width: 6),
                        const Text('•', style: TextStyle(color: Colors.grey)),
                        const SizedBox(width: 6),
                        ShimmerLoading(
                          width: 80,
                          height: 11,
                          borderRadius: BorderRadius.circular(4),
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
    );
  }

  Widget _buildViewStyleIconButton(
    BuildContext context, {
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    const brandOrange = Color(0xFFF35535);
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isSelected ? brandOrange : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: brandOrange.withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            size: 18,
            color: isSelected ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildBrowseGridShimmerCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AspectRatio(
            aspectRatio: 16 / 10,
            child: ShimmerLoading(
              width: double.infinity,
              height: double.infinity,
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerLoading(
                        width: 110,
                        height: 13,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 6),
                      ShimmerLoading(
                        width: 70,
                        height: 10,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ShimmerLoading(
                        width: 55,
                        height: 11,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      ShimmerLoading(
                        width: 45,
                        height: 11,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Browse Service Helpers ──
class BrowseService {
  final String name;
  final IconData icon;
  final Color color;
  final VendorType? vendorType;
  final String? route;

  const BrowseService({
    required this.name,
    required this.icon,
    required this.color,
    this.vendorType,
    this.route,
  });
}

List<BrowseService> _getBrowseServices(BuildContext context) {
  final isAr = Localizations.localeOf(context).languageCode == 'ar';
  final l10n = AppLocalizations.of(context)!;
  return [
    BrowseService(
      name: isAr ? 'طعام' : 'Food',
      icon: Icons.restaurant_rounded,
      color: const Color(0xFFF35535),
      vendorType: VendorType.restaurant,
    ),
    BrowseService(
      name: isAr ? 'السوبرماركت' : 'Groceries',
      icon: Icons.local_grocery_store_rounded,
      color: const Color(0xFF4CAF50),
      vendorType: VendorType.supermarket,
    ),
    BrowseService(
      name: isAr ? 'النقل والتوصيل' : 'Transport',
      icon: Icons.local_taxi_rounded,
      color: const Color(0xFF2196F3),
      route: '/transport/book',
    ),
    BrowseService(
      name: isAr ? 'الصيدليات' : 'Pharmacy',
      icon: Icons.local_pharmacy_rounded,
      color: const Color(0xFFE91E63),
      vendorType: VendorType.pharmacy,
    ),
    BrowseService(
      name: isAr ? 'المكتبات والمستلزمات' : 'Bookstores',
      icon: Icons.menu_book_rounded,
      color: const Color(0xFF8B5CF6),
      vendorType: VendorType.bookstore,
    ),
    BrowseService(
      name: isAr ? 'الأثاث والمفروشات' : 'Furniture',
      icon: Icons.chair_rounded,
      color: const Color(0xFFF59E0B),
      vendorType: VendorType.homeFurnishing,
    ),
    BrowseService(
      name: l10n.meatAndProteins,
      icon: Icons.restaurant_menu_rounded,
      color: const Color(0xFFEF4444),
      vendorType: VendorType.meatAndProteins,
    ),
    BrowseService(
      name: l10n.clothes,
      icon: Icons.checkroom_rounded,
      color: const Color(0xFFEC4899),
      vendorType: VendorType.clothes,
    ),
    BrowseService(
      name: l10n.buyAndSell,
      icon: Icons.swap_horiz_rounded,
      color: const Color(0xFF8B5CF6),
      vendorType: VendorType.buyAndSell,
    ),
    BrowseService(
      name: l10n.electronics,
      icon: Icons.devices_rounded,
      color: const Color(0xFF3B82F6),
      vendorType: VendorType.electronics,
    ),
  ];
}
