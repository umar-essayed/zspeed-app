import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/core/utils/search_helper.dart';
import 'package:z_speed/features/auth/cubit/auth_cubit.dart';
import 'package:z_speed/features/customer/widgets/guest_auth_prompt.dart';
import 'package:z_speed/l10n/app_localizations.dart';
import 'package:z_speed/features/auth/model/user_model.dart';
import 'package:z_speed/features/home/widgets/home_service_grid.dart';
import 'package:z_speed/features/notification/cubit/notification_cubit.dart';
import 'package:z_speed/features/notification/cubit/notification_state.dart';
import 'package:z_speed/features/notification/view/notification_list_page.dart';
import 'package:z_speed/features/settings/view/settings_screen.dart';
import 'package:z_speed/features/customer/view/customer_app_screen.dart';
import 'package:z_speed/features/customer/view/history_hub_screen.dart';
import 'package:z_speed/features/cart/model/cart_item.dart';
import 'package:z_speed/features/cart/cubit/cart_cubit.dart';
import 'package:z_speed/features/home/widgets/home_discover_feed.dart';
import 'package:z_speed/features/stories/widgets/story_circle_list.dart';

class HomePage extends StatefulWidget {
  final AppUser? currentUser;
  final Function(VendorType)? onVendorTypeSelected;
  final Function(String query, VendorType detectedType)? onSearchSubmitted;

  const HomePage({
    super.key,
    this.currentUser,
    this.onVendorTypeSelected,
    this.onSearchSubmitted,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchFocused = false;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_onSearchFocusChange);
  }

  void _onSearchFocusChange() {
    setState(() {
      _isSearchFocused = _searchFocusNode.hasFocus;
    });
  }

  /// Service categories displayed on the home page.
  List<ServiceCategory> get _services {
    final l10n = AppLocalizations.of(context)!;

    // Display names from localization
    final meatProteins = l10n.meatAndProteins;
    final clothes = l10n.clothes;
    final buySell = l10n.buyAndSell;
    final electronics = l10n.electronics;

    return [
      ServiceCategory(
        name: l10n.food,
        title: l10n.gourmetDining,
        tag: l10n.food,
        image: 'assets/images/home/gourmet_dining.jpg',
        icon: Icons.restaurant_rounded,
        color: const Color(0xFFF35535),
        isActive: true,
      ),
      ServiceCategory(
        name: l10n.groceries,
        title: l10n.market,
        tag: l10n.groceries,
        image: 'assets/images/home/freshMarket.jpg',
        icon: Icons.local_grocery_store_rounded,
        color: const Color(0xFF4CAF50),
        isActive: true,
      ),
      ServiceCategory(
        name: l10n.transport,
        title: l10n.cityTravel,
        tag: l10n.transport,
        image: 'assets/images/home/transport.jpg',
        icon: Icons.local_taxi_rounded,
        color: const Color(0xFF2196F3),
        isActive: true,
      ),
      ServiceCategory(
        name: l10n.pharmacy,
        title: l10n.wellnessCheck,
        tag: l10n.pharmacy,
        image: 'assets/images/home/pharmacy.jpg',
        icon: Icons.local_pharmacy_rounded,
        color: const Color(0xFFE91E63),
        isActive: true,
      ),
      ServiceCategory(
        name: l10n.localeName == 'ar' ? 'المكتبات' : 'Bookstores',
        title: l10n.curatedReads,
        tag: l10n.localeName == 'ar' ? 'المكتبات' : 'Bookstores',
        image: 'assets/images/home/bookstores.jpg',
        icon: Icons.menu_book_rounded,
        color: const Color(0xFF8B5CF6),
        isActive: true,
      ),
      ServiceCategory(
        name: l10n.localeName == 'ar' ? 'الأثاث' : 'Furniture',
        title: l10n.cozySpaces,
        tag: l10n.localeName == 'ar' ? 'الأثاث' : 'Furniture',
        image: 'assets/images/home/furniture.jpg',
        icon: Icons.chair_rounded,
        color: const Color(0xFFF59E0B),
        isActive: true,
      ),

      // ── New categories ──
      ServiceCategory(
        name: meatProteins,
        title: meatProteins,
        tag: meatProteins,
        image: 'assets/images/home/meats.jpg',
        icon: Icons.restaurant_menu_rounded,
        color: const Color(0xFFEF4444),
        isActive: true,
      ),
      ServiceCategory(
        name: clothes,
        title: clothes,
        tag: clothes,
        image: 'assets/images/home/clothes.jpg',
        icon: Icons.checkroom_rounded,
        color: const Color(0xFFEC4899),
        isActive: true,
      ),
      ServiceCategory(
        name: buySell,
        title: buySell,
        tag: buySell,
        image: 'assets/images/home/sellbuy.jpg',
        icon: Icons.swap_horiz_rounded,
        color: const Color(0xFF8B5CF6),
        isActive: true,
      ),
      ServiceCategory(
        name: electronics,
        title: electronics,
        tag: electronics,
        image: 'assets/images/home/electronics.jpg',
        icon: Icons.devices_rounded,
        color: const Color(0xFF3B82F6),
        isActive: true,
      ),
    ];
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_onSearchFocusChange);
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToVendor(VendorType vendorType) {
    if (widget.onVendorTypeSelected != null) {
      widget.onVendorTypeSelected!(vendorType);
      return;
    }
    final notificationCubit = context.read<NotificationCubit>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider<NotificationCubit>.value(
          value: notificationCubit,
          child: CustomerApp(vendorType: vendorType),
        ),
      ),
    );
  }

  void _handleServiceTap(ServiceCategory service) {
    final l10n = AppLocalizations.of(context)!;

    // ignore: avoid_print
    print(
      '[TAP] service.name="${service.name}" food="${l10n.food}" groceries="${l10n.groceries}" pharmacy="${l10n.pharmacy}"',
    );

    if (service.name == l10n.food) {
      // ignore: avoid_print
      print('[TAP] → VendorType.restaurant');
      _navigateToVendor(VendorType.restaurant);
    } else if (service.name == l10n.groceries) {
      // ignore: avoid_print
      print('[TAP] → VendorType.supermarket');
      _navigateToVendor(VendorType.supermarket);
    } else if (service.name == l10n.pharmacy) {
      // ignore: avoid_print
      print('[TAP] → VendorType.pharmacy');
      _navigateToVendor(VendorType.pharmacy);
    } else if (service.name ==
        (l10n.localeName == 'ar' ? 'المكتبات' : 'Bookstores')) {
      // ignore: avoid_print
      print('[TAP] → VendorType.bookstore');
      _navigateToVendor(VendorType.bookstore);
    } else if (service.name ==
        (l10n.localeName == 'ar' ? 'الأثاث' : 'Furniture')) {
      // ignore: avoid_print
      print('[TAP] → VendorType.homeFurnishing');
      _navigateToVendor(VendorType.homeFurnishing);
    } else if (service.name == l10n.transport) {
      // ignore: avoid_print
      print('[TAP] → TransportBookingScreen');
      Navigator.of(context, rootNavigator: true).pushNamed('/transport/book');
    } else if (service.name == l10n.meatAndProteins) {
      _navigateToVendor(VendorType.meatAndProteins);
    } else if (service.name == l10n.clothes) {
      _navigateToVendor(VendorType.clothes);
    } else if (service.name == l10n.buyAndSell) {
      _navigateToVendor(VendorType.buyAndSell);
    } else if (service.name == l10n.electronics) {
      _navigateToVendor(VendorType.electronics);
    }
  }

  void _handleSearch(String query) {
    final notificationCubit = context.read<NotificationCubit>();
    final q = SearchHelper.normalize(query);
    var detectedType = VendorType.restaurant;

    if (q.contains('دوا') ||
        q.contains('ادوي') ||
        q.contains('علاج') ||
        q.contains('صيدل') ||
        q.contains('pharmacy') ||
        q.contains('medicine') ||
        q.contains('روشت') ||
        q.contains('دكتور')) {
      detectedType = VendorType.pharmacy;
    } else if (q.contains('سوبر') ||
        q.contains('ماركت') ||
        q.contains('grocery') ||
        q.contains('supermarket') ||
        q.contains('تسوق') ||
        q.contains('جبن') ||
        q.contains('حليب') ||
        q.contains('بقاله') ||
        q.contains('خضار') ||
        q.contains('فواكه') ||
        q.contains('مشروبات') ||
        q.contains('عصير') ||
        q.contains('شيبس')) {
      detectedType = VendorType.supermarket;
    } else if (q.contains('لحم') ||
        q.contains('لحوم') ||
        q.contains('دجاج') ||
        q.contains('فراخ') ||
        q.contains('سمك') ||
        q.contains('اسماك') ||
        q.contains('meat') ||
        q.contains('chicken') ||
        q.contains('fish') ||
        q.contains('protein')) {
      detectedType = VendorType.meatAndProteins;
    } else if (q.contains('ملابس') ||
        q.contains('ازياء') ||
        q.contains('فستان') ||
        q.contains('قميص') ||
        q.contains('عبايه') ||
        q.contains('موضه') ||
        q.contains('clothes') ||
        q.contains('fashion')) {
      detectedType = VendorType.clothes;
    } else if (q.contains('الكترونيات') ||
        q.contains('جوال') ||
        q.contains('هاتف') ||
        q.contains('موبايل') ||
        q.contains('لابتوب') ||
        q.contains('كمبيوتر') ||
        q.contains('تلفزيون') ||
        q.contains('electronics') ||
        q.contains('phone') ||
        q.contains('mobile') ||
        q.contains('laptop')) {
      detectedType = VendorType.electronics;
    } else if (q.contains('كتاب') ||
        q.contains('كتب') ||
        q.contains('مكتبه') ||
        q.contains('قلم') ||
        q.contains('book') ||
        q.contains('stationery')) {
      detectedType = VendorType.bookstore;
    } else if (q.contains('اثاث') ||
        q.contains('مفروشات') ||
        q.contains('سرير') ||
        q.contains('كرسي') ||
        q.contains('furniture') ||
        q.contains('chair')) {
      detectedType = VendorType.homeFurnishing;
    } else if (q.contains('مستعمل') ||
        q.contains('حراج') ||
        q.contains('بيع') ||
        q.contains('شراء') ||
        q.contains('used') ||
        q.contains('sell')) {
      detectedType = VendorType.buyAndSell;
    }

    if (widget.onSearchSubmitted != null) {
      widget.onSearchSubmitted!(query, detectedType);
      _searchController.clear();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider<NotificationCubit>.value(
          value: notificationCubit,
          child: CustomerApp(vendorType: detectedType, initialQuery: query),
        ),
      ),
    );
    _searchController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            Brightness.light, // Light icons on dark salmon background image
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.translucent,
          child: Stack(
            children: [
              // ── Background Image with Fade Overlay & Subtle Blur ──
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 340,
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
              // ── Scrollable Content ──
              Positioned.fill(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Hero Section ──
                      _buildHeaderRow(context),

                      // ── Titles Section ──
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(
                                context,
                              )!.chooseTheFoodYouLove,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Colors.black45,
                                    offset: Offset(0, 2),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              AppLocalizations.of(context)!.orderBestDishes,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.9),
                                shadows: const [
                                  Shadow(
                                    color: Colors.black38,
                                    offset: Offset(0, 1),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Order Now Button Section ──
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        child: Container(
                          height: 46,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFFF35535,
                                ).withValues(alpha: 0.15),
                                blurRadius: 15,
                                spreadRadius: 1,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: InkWell(
                                onTap: () =>
                                    _navigateToVendor(VendorType.restaurant),
                                borderRadius: BorderRadius.circular(30),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.shopping_bag_outlined,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      AppLocalizations.of(context)!.orderNow,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      // ── Stories Section ──
                      const StoryCircleList(),

                      // ── Services Section ──
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        child: HomeServiceGrid(
                          services: _services,
                          onServiceTap: _handleServiceTap,
                        ),
                      ),

                      // ── Discover Feed Section (Beautifully separated and aligned) ──
                      Container(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: HomeDiscoverFeed(
                          onSeeAllStores: () =>
                              _navigateToVendor(VendorType.restaurant),
                          onSeeAllProducts: () =>
                              _navigateToVendor(VendorType.restaurant),
                          onQuickOrder: (name, price, image, restaurantId, menuItemId, isOpen, isBusy) {
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

                            final isArabic = Localizations.localeOf(context).languageCode == 'ar';

                            if (!isOpen) {
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.storefront_rounded, color: Colors.white),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          isArabic
                                              ? 'هذا المتجر مغلق حالياً ولا يمكن استقبال طلبات'
                                              : 'This store is currently closed and not accepting orders',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: Colors.red.shade700,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                              return;
                            }

                            if (isBusy) {
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.access_time_filled_rounded, color: Colors.white),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          AppLocalizations.of(context)!.vendorCurrentlyBusy,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: Colors.amber.shade900,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                              return;
                            }

                            final cartCubit = context.read<CartCubit>();
                            final cartItem = CartItem(
                              id: DateTime.now().millisecondsSinceEpoch
                                  .toString(),
                              menuItemId: menuItemId,
                              restaurantId: restaurantId,
                              menuItemName: name,
                              unitPrice: price,
                              quantity: 1.0,
                              itemTotal: price,
                              addedAt: DateTime.now(),
                              imageUrl: image,
                            );

                            if (cartCubit.state.hasRestaurantConflict(restaurantId)) {
                              _showReplaceCartDialog(cartCubit, cartItem);
                              return;
                            }

                            cartCubit.addToCart(cartItem);
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        isArabic
                                            ? 'تمت إضافة $name إلى السلة بنجاح! 🛒'
                                            : 'Added $name to cart successfully! 🛒',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: const Color(0xFFF35535),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // ── Promo / Info Banner Section ──
                      Container(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 24,
                        ),
                        child: _buildPromoBanner(),
                      ),
                      const SizedBox(height: 110),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPromoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C1C1A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'PROMO',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF35535),
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.fastDelivery,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  AppLocalizations.of(context)!.orderFoodBestRestaurants,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.5),
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _navigateToVendor(VendorType.restaurant),
                    borderRadius: BorderRadius.circular(16),
                    child: Ink(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF35535),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.browseRestaurantsBtn,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Image.asset(
            'assets/images/icon.png',
            width: 100,
            height: 100,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Image.asset(
              'assets/images/z_speed_icon.png',
              width: 100,
              height: 100,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(
                Icons.restaurant_rounded,
                size: 60,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassButton({
    required Widget child,
    required VoidCallback onTap,
    double radius = 22,
  }) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
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

  Widget _buildHeaderButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return _buildGlassButton(
      onTap: onTap,
      radius: 22,
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  Widget _buildHeaderRow(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double safeAreaLeft = MediaQuery.of(context).padding.left;
    final double safeAreaRight = MediaQuery.of(context).padding.right;

    return Container(
      width: double.infinity,
      color: Colors.transparent,
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
                    alpha: _isSearchFocused ? 0.35 : 0.2,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: _isSearchFocused
                          ? const Color(0xFFF35535).withValues(alpha: 0.15)
                          : Colors.black.withValues(alpha: 0.05),
                      blurRadius: _isSearchFocused ? 25 : 15,
                      spreadRadius: _isSearchFocused ? 2 : 0,
                      offset: _isSearchFocused
                          ? const Offset(0, 8)
                          : const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: _isSearchFocused
                        ? const Color(0xFFF35535)
                        : Colors.white.withValues(alpha: 0.3),
                    width: _isSearchFocused ? 2.0 : 1.0,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      textAlignVertical: TextAlignVertical.center,
                      textDirection:
                          Localizations.localeOf(context).languageCode == 'ar'
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      textInputAction: TextInputAction.search,
                      onSubmitted: (query) {
                        if (query.trim().isNotEmpty) {
                          _handleSearch(query.trim());
                        }
                      },
                      decoration: InputDecoration(
                        hintText:
                            Localizations.localeOf(context).languageCode == 'ar'
                            ? 'ابحث عن مطعم، بقالة، صيدلية...'
                            : 'Search for restaurants, groceries, pharmacy...',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        border: InputBorder.none,
                        prefixIcon: AnimatedScale(
                          scale: _isSearchFocused ? 1.15 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: AnimatedRotation(
                            turns: _isSearchFocused ? 0.05 : 0.0,
                            duration: const Duration(milliseconds: 250),
                            child: Icon(
                              Icons.search_rounded,
                              color: _isSearchFocused
                                  ? const Color(0xFFF35535)
                                  : Colors.white.withValues(alpha: 0.7),
                              size: 22,
                            ),
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 16,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                      ),
                      onChanged: (text) {
                        setState(() {});
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 44,
              height: 44,
              child: AnimatedCrossFade(
                firstChild: _buildHeaderButton(
                  icon: Icons.history_rounded,
                  onTap: () {
                    final authState = context.read<AuthCubit>().state;
                    if (authState.isGuest) {
                      GuestAuthPrompt.show(
                        context,
                        actionLabel: AppLocalizations.of(context)!.viewOrders,
                      );
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HistoryHubScreen(),
                      ),
                    );
                  },
                ),
                secondChild: _buildHeaderButton(
                  icon: Icons.close_rounded,
                  onTap: () {
                    _searchFocusNode.unfocus();
                  },
                ),
                crossFadeState: _isSearchFocused
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 250),
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
                child: BlocBuilder<NotificationCubit, NotificationState>(
                  builder: (context, state) {
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _buildGlassButton(
                          radius: 22,
                          onTap: () {
                            final authState = context.read<AuthCubit>().state;
                            if (authState.isGuest) {
                              GuestAuthPrompt.show(
                                context,
                                actionLabel: 'notifications',
                              );
                              return;
                            }
                            final cubit = context.read<NotificationCubit>();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    BlocProvider<NotificationCubit>.value(
                                      value: cubit,
                                      child: const NotificationListPage(),
                                    ),
                              ),
                            );
                          },
                          child: const Icon(
                            Icons.notifications_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
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
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Center(
                                child: Text(
                                  state.unreadCount > 99
                                      ? '99+'
                                      : '${state.unreadCount}',
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
                    icon: Icons.person_outline,
                    onTap: () {
                      final authState = context.read<AuthCubit>().state;
                      if (authState.isGuest) {
                        GuestAuthPrompt.show(
                          context,
                          actionLabel: AppLocalizations.of(
                            context,
                          )!.viewProfile,
                        );
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsPage()),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show dialog to replace cart with items from a different restaurant.
  void _showReplaceCartDialog(CartCubit cartCubit, CartItem newItem) {
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
              cartCubit.replaceCartWithItem(newItem);
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.of(context)!
                        .addedToCartItem(newItem.menuItemName),
                  ),
                  backgroundColor: const Color(0xFFF35535),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF35535),
            ),
            child: Text(
              AppLocalizations.of(context)!.replace,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
