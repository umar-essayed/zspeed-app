import 'package:flutter/material.dart';
import 'package:z_speed/core/injection.dart';
import 'package:z_speed/features/order/cubit/checkout_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/l10n/app_localizations.dart';
import 'package:z_speed/core/enums/order_enums.dart';
import 'package:z_speed/features/auth/cubit/auth_cubit.dart';
import 'package:z_speed/features/customer/cubit/customer_order_history_cubit.dart';
import 'package:z_speed/features/customer/cubit/customer_order_history_state.dart';
import 'package:z_speed/features/order/model/order.dart';
import 'package:z_speed/features/order/view/order_tracking_screen.dart';
import 'package:z_speed/features/review/datasource/review_firebase_datasource.dart';
import 'package:z_speed/features/review/view/rate_order_dialog.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:z_speed/features/cart/model/cart_item.dart';
import 'package:z_speed/features/cart/cubit/cart_cubit.dart';
import 'package:z_speed/features/order/view/checkout_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Customer Order History Screen — shows active and past orders.
///
/// Features:
/// - TabBar: Active orders | Past orders
/// - Active: pending → onTheWay
/// - Past: delivered, cancelled, refunded
/// - Actions: Track Order (active), Reorder (past), Rate (delivered)
class CustomerOrderHistoryScreen extends StatefulWidget {
  const CustomerOrderHistoryScreen({super.key});

  @override
  State<CustomerOrderHistoryScreen> createState() =>
      _CustomerOrderHistoryScreenState();
}

class _CustomerOrderHistoryScreenState extends State<CustomerOrderHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<String, RestaurantCacheInfo> _restaurantCache = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BlocProvider(
      create: (_) => CustomerOrderHistoryCubit(),
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF1A202C)
            : const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            AppLocalizations.of(context)!.myOrders,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 18,
              fontFamily: 'Cairo',
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF35535), Color(0xFFFF9800)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Colors.white.withValues(alpha: 0.85),
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  fontFamily: 'Cairo',
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  fontFamily: 'Cairo',
                ),
                tabs: [
                  Tab(text: AppLocalizations.of(context)!.activeOrdersTab),
                  Tab(text: AppLocalizations.of(context)!.pastOrdersTab),
                ],
              ),
            ),
          ),
        ),
        body: BlocBuilder<CustomerOrderHistoryCubit, CustomerOrderHistoryState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.error ??
                          AppLocalizations.of(context)!.errorOccurred,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, fontFamily: 'Cairo'),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () =>
                          context.read<CustomerOrderHistoryCubit>().init(),
                      child: Text(AppLocalizations.of(context)!.retry),
                    ),
                  ],
                ),
              );
            }

            return TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList(context, state.activeOrders, isActive: true),
                _buildOrderList(context, state.pastOrders, isActive: false),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildOrderList(
    BuildContext context,
    List<Order> orders, {
    required bool isActive,
  }) {
    if (orders.isEmpty) {
      return _buildEmptyState(context, isActive: isActive);
    }

    return RefreshIndicator(
      onRefresh: () => context.read<CustomerOrderHistoryCubit>().init(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return _buildOrderCard(order, isActive: isActive);
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, {required bool isActive}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.6,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isActive ? Icons.shopping_bag_outlined : Icons.history_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isActive
                  ? AppLocalizations.of(context)!.noActiveOrders
                  : AppLocalizations.of(context)!.noPastOrders,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isActive
                  ? AppLocalizations.of(context)!.activeOrdersAppearHere
                  : 'Your order history will appear here',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardHeader(
    BuildContext context,
    Order order,
    Color statusColor,
  ) {
    final restaurantId = order.restaurantId;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget buildHeaderContent(String name, String? logoUrl) {
      return Row(
        children: [
          // Restaurant Logo Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: logoUrl != null && logoUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: logoUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => Icon(
                        Icons.storefront_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 22,
                      ),
                    )
                  : Icon(
                      Icons.storefront_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 22,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // Restaurant Name and Order Reference
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    fontFamily: 'Cairo',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Order #${order.id.substring(0, 8).toUpperCase()}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[400] : Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: statusColor.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  order.status.label,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (_restaurantCache.containsKey(restaurantId)) {
      final info = _restaurantCache[restaurantId]!;
      return buildHeaderContent(info.name, info.logoUrl);
    }

    return FutureBuilder<firestore.DocumentSnapshot>(
      future: firestore.FirebaseFirestore.instance
          .collection('vendors')
          .doc(restaurantId)
          .get(),
      builder: (context, snapshot) {
        String name = AppLocalizations.of(context)!.restaurant;
        String? logoUrl;

        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>?;
            if (data != null) {
              final nameAr = data['nameAr'] as String?;
              final nameEn = data['name'] as String?;
              final langCode = Localizations.localeOf(context).languageCode;
              name = (langCode == 'ar' && nameAr != null && nameAr.isNotEmpty)
                  ? nameAr
                  : (nameEn ?? name);
              logoUrl = data['logoUrl'] as String?;
              _restaurantCache[restaurantId] = RestaurantCacheInfo(
                name,
                logoUrl,
              );
            }
          }
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.grey[100],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 14,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 80,
                      height: 10,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 80,
                height: 24,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          );
        }

        return buildHeaderContent(name, logoUrl);
      },
    );
  }

  Widget _buildOrderCard(Order order, {required bool isActive}) {
    final statusColor = _getStatusColor(order.status);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2530) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: isDark ? const Color(0xFF2D3748) : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => OrderTrackingScreen(orderId: order.id),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (logo, restaurant name, order id, status badge)
                _buildCardHeader(context, order, statusColor),

                // First Divider
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Container(
                    height: 1,
                    color: isDark ? Colors.white10 : Colors.grey[200],
                  ),
                ),

                // Order items list
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...order.items.take(2).map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${item.quantity}x',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? Colors.grey[300]
                                      : Colors.grey[800],
                                  fontFamily: 'Cairo',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              AppLocalizations.of(
                                context,
                              )!.egpAmount(item.totalPrice.toStringAsFixed(2)),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[700],
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    if (order.items.length > 2)
                      Padding(
                        padding: const EdgeInsets.only(top: 2, left: 4),
                        child: Text(
                          Localizations.localeOf(context).languageCode == 'ar'
                              ? '+ طلبات أخرى (${order.items.length - 2})'
                              : '+ ${order.items.length - 2} more items',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[500],
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                  ],
                ),

                // Second Divider
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Container(
                    height: 1,
                    color: isDark ? Colors.white10 : Colors.grey[200],
                  ),
                ),

                // Date and Total Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 16,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat(
                            'MMM dd, h:mm a',
                            Localizations.localeOf(context).toString(),
                          ).format(order.createdAt),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          Localizations.localeOf(context).languageCode == 'ar'
                              ? 'الإجمالي'
                              : 'Total',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppLocalizations.of(
                            context,
                          )!.egpAmount(order.total.toStringAsFixed(2)),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context).colorScheme.primary,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Action Buttons
                _buildActionButtons(order, isActive: isActive),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(Order order, {required bool isActive}) {
    if (isActive) {
      return Container(
        margin: const EdgeInsets.only(top: 14),
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => OrderTrackingScreen(orderId: order.id),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: const Icon(Icons.local_shipping_outlined, color: Colors.white),
          label: Text(
            AppLocalizations.of(context)!.trackOrder,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Cairo',
            ),
          ),
        ),
      );
    }

    // Past orders
    return Container(
      margin: const EdgeInsets.only(top: 14),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                try {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) =>
                        const Center(child: CircularProgressIndicator()),
                  );

                  final cartCubit = context.read<CartCubit>();
                  await cartCubit.clearCart();

                  // Fetch sections and items for this vendor to verify availability
                  final sectionsSnap = await firestore.FirebaseFirestore.instance
                      .collection('vendors')
                      .doc(order.restaurantId)
                      .collection('menuSections')
                      .get();

                  final Map<String, bool> itemAvailability = {};
                  final Map<String, Map<String, bool>> variantAvailability = {};

                  for (final secDoc in sectionsSnap.docs) {
                    final itemsSnap =
                        await secDoc.reference.collection('items').get();
                    for (final itemDoc in itemsSnap.docs) {
                      final itemData = itemDoc.data();
                      final isAvailable =
                          itemData['isAvailable'] as bool? ?? true;
                      itemAvailability[itemDoc.id] = isAvailable;

                      final variantsRaw =
                          itemData['variants'] as List<dynamic>? ?? [];
                      final vMap = <String, bool>{};
                      for (final v in variantsRaw) {
                        if (v is Map<String, dynamic>) {
                          final vId = v['id'] as String? ?? '';
                          final vAvail = v['isAvailable'] as bool? ?? true;
                          if (vId.isNotEmpty) vMap[vId] = vAvail;
                        }
                      }
                      variantAvailability[itemDoc.id] = vMap;
                    }
                  }

                  int skippedCount = 0;
                  int addedCount = 0;

                  for (final item in order.items) {
                    final isItemAvailable =
                        itemAvailability[item.menuItemId] ?? false;

                    if (!isItemAvailable) {
                      skippedCount++;
                      continue;
                    }

                    final cartItem = CartItem(
                      id: DateTime.now().millisecondsSinceEpoch.toString() +
                          item.menuItemId,
                      menuItemId: item.menuItemId,
                      restaurantId: order.restaurantId,
                      menuItemName: item.name,
                      unitPrice: item.price,
                      quantity: item.quantity.toDouble(),
                      itemTotal: item.totalPrice,
                      addedAt: DateTime.now(),
                    );
                    await cartCubit.addToCart(cartItem);
                    addedCount++;
                  }

                  if (!mounted) return;
                  Navigator.pop(context); // Remove loading

                  if (addedCount == 0 || skippedCount > 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!
                              .someItemsUnavailableSkipped,
                        ),
                        backgroundColor:
                            addedCount == 0 ? Colors.red : Colors.orange,
                      ),
                    );
                    if (addedCount == 0) return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (modalCtx) => BlocProvider<CheckoutCubit>(
                        create: (ctx) => CheckoutCubit(
                          cartCubit: ctx.read<CartCubit>(),
                          authCubit: ctx.read<AuthCubit>(),
                        ),
                        child: const CheckoutScreen(),
                      ),
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  Navigator.pop(context); // Remove loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(
                          context,
                        )!.failedToReorder(e.toString()),
                      ),
                    ),
                  );
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                side: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1.5,
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.replay_rounded, size: 20),
              label: Text(
                AppLocalizations.of(context)!.reorder,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
          ),
          if (order.status == OrderStatus.delivered) ...[
            const SizedBox(width: 12),
            Expanded(child: _RateButton(order: order)),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return const Color(0xFF3182CE);
      case OrderStatus.accepted:
      case OrderStatus.preparing:
        return const Color(0xFFDD6B20);
      case OrderStatus.ready:
      case OrderStatus.driverAssigned:
        return const Color(0xFF805AD5);
      case OrderStatus.pickedUp:
      case OrderStatus.onTheWay:
        return const Color(0xFF319795);
      case OrderStatus.delivered:
        return const Color(0xFF38A169);
      case OrderStatus.searching:
      case OrderStatus.unassigned:
      case OrderStatus.cancelled:
      case OrderStatus.refunded:
        return const Color(0xFFE53E3E);
    }
  }
}

// ── Rate Button ───────────────────────────────────────────────────────────────
/// Stateful widget that checks if the order was already reviewed,
/// then shows the rating dialog or a "Rated" badge accordingly.
class _RateButton extends StatefulWidget {
  final Order order;
  const _RateButton({required this.order});

  @override
  State<_RateButton> createState() => _RateButtonState();
}

class _RateButtonState extends State<_RateButton> {
  // null = still checking, true = already reviewed, false = not yet
  bool? _alreadyReviewed;

  @override
  void initState() {
    super.initState();
    _checkReviewed();
  }

  Future<void> _checkReviewed() async {
    final reviewed = await getIt<ReviewFirebaseDatasource>().hasReviewed(
      restaurantId: widget.order.restaurantId,
      orderId: widget.order.id,
    );
    if (mounted) setState(() => _alreadyReviewed = reviewed);
  }

  /// All async logic takes explicit [ctx] so the linter is satisfied —
  /// context is captured synchronously in build() before any await.
  Future<void> _onRateTap(BuildContext ctx) async {
    final authCubit = ctx.read<AuthCubit>();
    final userId = authCubit.currentUser?.id ?? '';
    final messenger = ScaffoldMessenger.of(ctx);

    String restaurantName = 'Restaurant';
    try {
      final doc = await firestore.FirebaseFirestore.instance
          .collection('vendors')
          .doc(widget.order.restaurantId)
          .get();
      if (doc.exists) {
        restaurantName = (doc.data()!['name'] as String?) ?? restaurantName;
      }
    } catch (_) {}

    if (!mounted || !ctx.mounted) return;

    final submitted = await RateOrderDialog.show(
      context: ctx,
      restaurantId: widget.order.restaurantId,
      restaurantName: restaurantName,
      customerId: userId,
      orderId: widget.order.id,
    );

    if (submitted) {
      if (!mounted) return;
      setState(() => _alreadyReviewed = true);
      messenger.showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.thankYouReview),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Still loading
    if (_alreadyReviewed == null) {
      return ElevatedButton.icon(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? Colors.white12 : Colors.grey[200],
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
        ),
        label: Text(
          AppLocalizations.of(context)!.rateButtonLabel,
          style: TextStyle(
            color: Colors.grey[500],
            fontFamily: 'Cairo',
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    // Already reviewed — show badge
    if (_alreadyReviewed == true) {
      return ElevatedButton.icon(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? Colors.white12 : Colors.grey[200],
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: Icon(
          Icons.check_circle_rounded,
          size: 18,
          color: Colors.grey[500],
        ),
        label: Text(
          AppLocalizations.of(context)!.alreadyRated,
          style: TextStyle(
            color: Colors.grey[500],
            fontFamily: 'Cairo',
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    // Not yet reviewed
    return ElevatedButton.icon(
      onPressed: () => _onRateTap(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: const Icon(Icons.star_rate_rounded, size: 18, color: Colors.white),
      label: Text(
        AppLocalizations.of(context)!.rate,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontFamily: 'Cairo',
        ),
      ),
    );
  }
}

class RestaurantCacheInfo {
  final String name;
  final String? logoUrl;
  RestaurantCacheInfo(this.name, this.logoUrl);
}
