import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:z_speed/core/enums/order_enums.dart';
import 'package:z_speed/core/enums/driver_enums.dart';
import 'package:z_speed/features/order/model/order.dart';
import 'package:z_speed/features/order/model/order_item.dart';
import 'package:z_speed/features/driver/model/order_driver.dart';
import 'package:z_speed/features/restaurant_owner/cubit/restaurant_orders_cubit.dart';
import 'package:z_speed/features/restaurant_owner/cubit/restaurant_orders_state.dart';
import 'package:z_speed/features/restaurant_owner/view/restaurant_order_detail_screen.dart';
import 'package:z_speed/features/restaurant_owner/view/driver_tracking_screen.dart';
import 'package:z_speed/features/restaurant_owner/widgets/driver_assignment_dialog.dart';
import 'package:z_speed/features/restaurant_owner/widgets/search_progress_widget.dart';
import 'package:z_speed/features/restaurant_owner/utils/order_receipt_printer.dart';
import 'package:z_speed/features/restaurant_owner/utils/order_receipt_labels.dart';
import 'package:z_speed/features/restaurant_owner/widgets/receipt_print_language_dialog.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Vendor Orders Screen — real-time order management interface.
///
/// Features:
/// - 4 tabs: All/New/Active/Ready with real-time badge counts
/// - Firestore stream (auto-updates)
/// - Vendor actions: Accept, Reject (with reason), Start Preparing, Mark Ready
/// - Per-order loading states
class RestaurantOrdersScreen extends StatefulWidget {
  const RestaurantOrdersScreen({super.key});

  @override
  State<RestaurantOrdersScreen> createState() => _RestaurantOrdersScreenState();
}

class _RestaurantOrdersScreenState extends State<RestaurantOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late RestaurantOrdersCubit _cubit;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _cubit = RestaurantOrdersCubit();

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _onTabChanged(_tabController.index);
      }
    });
  }

  void _onTabChanged(int index) {
    final filters = [
      VendorOrderFilter.all,
      VendorOrderFilter.pending,
      VendorOrderFilter.active,
      VendorOrderFilter.ready,
    ];
    _cubit.setFilter(filters[index]);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<RestaurantOrdersCubit, RestaurantOrdersState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    state.error ??
                        AppLocalizations.of(context)!.failedToLoadOrders,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _cubit.init(),
                    child: Text(AppLocalizations.of(context)!.retry),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFFF35535),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: const Color(0xFFF35535),
                  tabs: [
                    Tab(
                        text: AppLocalizations.of(context)!
                            .allCount(state.allOrders.length)),
                    Tab(
                        text: AppLocalizations.of(context)!
                            .newCount(state.pendingCount)),
                    Tab(
                        text: AppLocalizations.of(context)!
                            .activeCount(state.activeCount)),
                    Tab(
                        text: AppLocalizations.of(context)!
                            .readyCount(state.readyCount)),
                  ],
                ),
              ),
              Expanded(
                child: !state.translationsLoaded
                    ? const Center(child: CircularProgressIndicator())
                    : state.filteredOrders.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: state.filteredOrders.length,
                            itemBuilder: (context, index) {
                              final order = state.filteredOrders[index];
                              return _buildOrderCard(order, state);
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.noOrdersYet,
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Order order, RestaurantOrdersState state) {
    final statusColor = _getStatusColor(order.status);
    final isProcessing = state.isProcessingOrder(order.id);
    final dateFormat = DateFormat('h:mm a');

    return Container(
      margin: const EdgeInsetsDirectional.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          hoverColor: Colors.deepOrange.withValues(alpha: 0.05),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RestaurantOrderDetailScreen(
                  initialOrder: order,
                  cubit: _cubit,
                ),
              ),
            );
          },
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Item Names (Title) & Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                () {
                                  if (order.items.isEmpty) {
                                    return AppLocalizations.of(context)!.order;
                                  }
                                  final sorted = [
                                    ...order.items
                                  ]..sort((a, b) => b.price.compareTo(a.price));
                                  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
                                  final mainItem = isArabic
                                       ? (sorted.first.nameAr ?? state.itemTranslations[sorted.first.menuItemId] ?? sorted.first.name)
                                       : sorted.first.name;
                                  final otherCount = order.items.length - 1;
                                  return otherCount > 0
                                      ? AppLocalizations.of(context)!
                                          .andMoreItems(mainItem, otherCount)
                                      : mainItem;
                                }(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF333333),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppLocalizations.of(context)!.orderWithId(
                                    order.id.substring(0, 8).toUpperCase()),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            order.status.getLocalizedLabel(AppLocalizations.of(context)!),
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Time & Delivery Info
                    Row(
                      children: [
                        Icon(Icons.access_time,
                            size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          dateFormat.format(order.createdAt),
                          style:
                              TextStyle(fontSize: 13, color: Colors.grey[600]),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.location_on,
                            size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _localizeAddress(order.deliveryAddress, context),
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey[600]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Payment Method & Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              order.paymentMethod == PaymentMethodType.cash
                                  ? Icons.money
                                  : Icons.credit_card,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              order.paymentMethod.getLocalizedLabel(AppLocalizations.of(context)!),
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        Text(
                          AppLocalizations.of(context)!
                              .currencyEgp(order.total.toStringAsFixed(2)),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Customer Note (if any)
                    if (order.customerNote != null &&
                        order.customerNote!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.note,
                                size: 16, color: Colors.blue),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                order.customerNote!,
                                style: const TextStyle(
                                    fontSize: 13, color: Colors.blue),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 12),

                    // Action Buttons
                    _buildActionButtons(order, isProcessing),
                    if (kIsWeb || defaultTargetPlatform == TargetPlatform.android) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => _printReceipt(order),
                          icon: const Icon(Icons.print_outlined, size: 18),
                          label: const Text('Print Receipt'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFF35535),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(Order order, bool isProcessing) {
    if (isProcessing) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    switch (order.status) {
      case OrderStatus.pending:
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _acceptOrder(order.id),
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: Text(AppLocalizations.of(context)!.accept),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showRejectDialog(order.id),
                icon: const Icon(Icons.cancel_outlined, size: 18),
                label: Text(AppLocalizations.of(context)!.reject),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        );

      case OrderStatus.accepted:
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _startPreparing(order.id),
                icon: const Icon(Icons.restaurant, size: 18),
                label: Text(AppLocalizations.of(context)!.startPreparing),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF35535),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        );

      case OrderStatus.preparing:
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _markReady(order.id),
                icon: const Icon(Icons.done_all, size: 18),
                label: Text(AppLocalizations.of(context)!.markAsReady),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        );

      case OrderStatus.ready:
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    order.driverId != null
                        ? AppLocalizations.of(context)!
                            .driverAssignedAwaitingPickup
                        : AppLocalizations.of(context)!.readyAssignDriver,
                    style: const TextStyle(
                        color: Colors.green, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            if (order.driverId == null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _startAutoDispatch(order.id),
                  icon: const Icon(Icons.flash_on, size: 18),
                  label: const Text('Start Auto-Dispatch'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );

      case OrderStatus.searching:
        return SearchProgressWidget(
          key: ValueKey('search_progress_${order.id}'),
          orderId: order.id,
          isUnassignedState: false,
          onTimeout: () => _startAutoDispatch(order.id, showSnackbar: false),
          onCancel: () => _cancelAutoDispatch(order.id),
        );

      case OrderStatus.unassigned:
        return SearchProgressWidget(
          key: ValueKey('search_progress_${order.id}'),
          orderId: order.id,
          isUnassignedState: true,
          onRetry: () => _cubit.markReady(order.id),
          onManualAssign: () => _showDriverAssignmentDialog(order),
        );

      case OrderStatus.driverAssigned:
      case OrderStatus.pickedUp:
      case OrderStatus.onTheWay:
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('orders')
              .doc(order.id)
              .collection('orderDrivers')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const SizedBox.shrink();
            }

            final drivers = snapshot.data!.docs
                .map((doc) =>
                    OrderDriver.fromMap(doc.data() as Map<String, dynamic>))
                .where((od) =>
                    od.status != DriverAssignmentStatus.cancelled &&
                    od.status != DriverAssignmentStatus.rejected)
                .toList();

            if (drivers.isEmpty) return const SizedBox.shrink();

            final activeDriver = drivers.first;

            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.teal[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.teal.shade200),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.teal.shade100,
                        child: const Icon(Icons.person,
                            size: 16, color: Colors.teal),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activeDriver.driverName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              _getDriverStatusLabel(
                                  context, activeDriver.status),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.teal.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (activeDriver.driverPhone.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.phone,
                              color: Colors.teal, size: 20),
                          onPressed: () =>
                              _callNumber(activeDriver.driverPhone),
                        ),
                    ],
                  ),
                ),
                if (activeDriver.status == DriverAssignmentStatus.accepted ||
                    activeDriver.status == DriverAssignmentStatus.pickedUp) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DriverTrackingScreen(
                              driverUserId: activeDriver.driverUserId,
                              driverName: activeDriver.driverName,
                              restaurantLat:
                                  _cubit.state.currentRestaurant?.latitude ?? 0,
                              restaurantLng:
                                  _cubit.state.currentRestaurant?.longitude ??
                                      0,
                              restaurantName:
                                  _cubit.state.currentRestaurant?.name ?? '',
                              orderId: order.id,
                              deliveryLat: order.deliveryLat,
                              deliveryLng: order.deliveryLng,
                              initialOrderStatus: order.status,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.map, size: 18),
                      label: Text(AppLocalizations.of(context)!.trackDriver),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        );

      default:
        return const SizedBox.shrink();
    }
  }

  /// State-aware orange Assign Driver button.
  ///
  /// Streams the orderDrivers count from Firestore in real time and changes
  /// label/style when drivers are already assigned.
  // Widget _buildAssignDriverButton(Order order) {
  //   return StreamBuilder<QuerySnapshot>(
  //     stream: FirebaseFirestore.instance
  //         .collection('orders')
  //         .doc(order.id)
  //         .collection('orderDrivers')
  //         .where('status', whereNotIn: ['cancelled', 'rejected']).snapshots(),
  //     builder: (context, snapshot) {
  //       final count = snapshot.data?.docs.length ?? 0;
  //       final hasDrivers = count > 0;

  //       return SizedBox(
  //         width: double.infinity,
  //         child: ElevatedButton.icon(
  //           onPressed: () => _showDriverAssignmentDialog(order),
  //           icon: Icon(
  //             hasDrivers ? Icons.people : Icons.delivery_dining,
  //             size: 18,
  //           ),
  //           label: Text(
  //             hasDrivers
  //                 ? AppLocalizations.of(context)!.manageDriversCount(count)
  //                 : AppLocalizations.of(context)!.assignDriver,
  //           ),
  //           style: ElevatedButton.styleFrom(
  //             backgroundColor: hasDrivers
  //                 ? const Color(0xFFE65100) // darker orange when assigned
  //                 : const Color(0xFFF35535), // brand orange
  //             foregroundColor: Colors.white,
  //             padding: const EdgeInsets.symmetric(vertical: 12),
  //             shape: RoundedRectangleBorder(
  //               borderRadius: BorderRadius.circular(8),
  //             ),
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }

  void _acceptOrder(String orderId) async {
    final success = await _cubit.acceptOrder(orderId);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(AppLocalizations.of(context)!.orderAcceptedSuccessfully),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _startPreparing(String orderId) async {
    final success = await _cubit.startPreparing(orderId);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.orderPreparationStarted),
          backgroundColor: const Color(0xFFF35535),
        ),
      );
    }
  }

  void _markReady(String orderId) async {
    final success = await _cubit.markReady(orderId);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.orderMarkedAsReady),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  Future<void> _startAutoDispatch(String orderId, {bool showSnackbar = true}) async {
    // Only update status to searching if not already in searching state to avoid redundant rebuilds
    final isAlreadySearching = _cubit.state.allOrders.any(
      (o) => o.id == orderId && o.status == OrderStatus.searching,
    );
    if (!isAlreadySearching) {
      await _cubit.startSearching(orderId);
    }

    try {
      final callable = FirebaseFunctions.instance.httpsCallable('requestDispatch');
      await callable.call({'orderId': orderId});
      if (mounted && showSnackbar) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Auto-dispatch started successfully')),
        );
      }
    } catch (e) {
      if (mounted && showSnackbar) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start auto-dispatch: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cancelAutoDispatch(String orderId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('cancelDispatch');
      await callable.call({'orderId': orderId});
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Auto-dispatch cancelled successfully')),
        );
      }
    } catch (e) {
      // Direct Firestore fallback in case Cloud Functions are unreachable or throw an error
      try {
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .update({
          'status': OrderStatus.unassigned.key,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        final pendingSnap = await FirebaseFirestore.instance
            .collection('deliveryRequests')
            .where('orderId', isEqualTo: orderId)
            .where('status', isEqualTo: 'pending')
            .get();

        if (pendingSnap.docs.isNotEmpty) {
          final batch = FirebaseFirestore.instance.batch();
          for (final doc in pendingSnap.docs) {
            batch.update(doc.reference, {
              'status': 'cancelled',
              'updatedAt': FieldValue.serverTimestamp(),
            });
            final driverId = doc.data()['driverId'] as String?;
            if (driverId != null && driverId.isNotEmpty) {
              final orderDriverRef = FirebaseFirestore.instance
                  .collection('orders')
                  .doc(orderId)
                  .collection('orderDrivers')
                  .doc(driverId);
              batch.set(
                orderDriverRef,
                {
                  'status': 'cancelled',
                  'updatedAt': FieldValue.serverTimestamp(),
                },
                SetOptions(merge: true),
              );
            }
          }
          await batch.commit();
        }

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Auto-dispatch cancelled successfully')),
          );
        }
      } catch (fallbackError) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to cancel auto-dispatch: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showRejectDialog(String orderId) {
    String? selectedReason;
    final reasons = [
      AppLocalizations.of(context)!.itemsNotAvailable,
      AppLocalizations.of(context)!.tooBusy,
      AppLocalizations.of(context)!.closingSoon,
      AppLocalizations.of(context)!.duplicateOrder,
      AppLocalizations.of(context)!.other,
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.rejectOrder),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context)!.selectAReasonFor),
              const SizedBox(height: 16),
              ...reasons.map((reason) {
                return RadioListTile<String>(
                  title: Text(reason),
                  value: reason,
                  // ignore: deprecated_member_use
                  groupValue: selectedReason,
                  // ignore: deprecated_member_use
                  onChanged: (value) {
                    setState(() {
                      selectedReason = value;
                    });
                  },
                  activeColor: const Color(0xFFF35535),
                );
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            ElevatedButton(
              onPressed: selectedReason == null
                  ? null
                  : () async {
                      Navigator.pop(context);
                      final success =
                          await _cubit.rejectOrder(orderId, selectedReason!);
                      if (!context.mounted) return;
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                AppLocalizations.of(context)!.orderRejected),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(AppLocalizations.of(context)!.reject),
            ),
          ],
        ),
      ),
    );
  }

  void _showDriverAssignmentDialog(Order order) {
    if (_cubit.state.currentRestaurant == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(AppLocalizations.of(context)!.restaurantDetailsMissing)),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => DriverAssignmentDialog(
        order: order,
        restaurant: _cubit.state.currentRestaurant!,
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.blue;
      case OrderStatus.accepted:
      case OrderStatus.preparing:
        return Colors.orange;
      case OrderStatus.ready:
        return Colors.purple;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
      case OrderStatus.refunded:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getDriverStatusLabel(
      BuildContext context, DriverAssignmentStatus status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case DriverAssignmentStatus.pending:
        return l10n.statusPending;
      case DriverAssignmentStatus.accepted:
        return l10n.statusAccepted;
      case DriverAssignmentStatus.rejected:
        return l10n.statusRejected;
      case DriverAssignmentStatus.cancelled:
        return l10n.statusCancelled;
      case DriverAssignmentStatus.pickedUp:
        return l10n.statusPickedUp;
      case DriverAssignmentStatus.delivered:
        return l10n.statusDelivered;
    }
  }

  Future<void> _printReceipt(Order order) async {
    String? customerName = order.customerName;
    String? customerPhone = order.customerPhone;

    if (customerName == null || customerName.isEmpty || customerPhone == null || customerPhone.isEmpty) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(order.customerId)
            .get();
        if (doc.exists) {
          final data = doc.data();
          if (data != null) {
            customerName = data['name'] as String?;
            customerPhone = data['phone'] as String?;
          }
        }
      } catch (e) {
        debugPrint('Error fetching customer details for print: $e');
      }
      if (mounted) {
        Navigator.pop(context);
      }
    }

    if (!mounted) return;
    final language = await showReceiptPrintLanguageDialog(context);
    if (!mounted || language == null) return;

    // Show a loading indicator while resolving item translations and fetching order items
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
    }
    final results = await Future.wait([
      _resolveItemTranslations(order, language),
      _cubit.getOrderItems(order.id),
    ]);
    final itemTranslations = results[0] as Map<String, String>;
    final orderItems = results[1] as List<OrderItem>?;

    if (mounted) {
      Navigator.pop(context);
    }

    final restaurantName = _cubit.state.currentRestaurant?.name ?? 'Vendor';
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sending to printer... / جاري الإرسال للطابعة...'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    try {
      await printVendorOrderReceiptWeb(
        order: order,
        restaurantName: restaurantName,
        title: 'Vendor Order Receipt',
        language: language,
        customerName: customerName,
        customerPhone: customerPhone,
        customerAddress: order.deliveryAddress,
        itemTranslations: itemTranslations,
        orderItems: orderItems,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Receipt printed successfully! / تمت طباعة الفاتورة بنجاح!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Printer Error / خطأ في الطباعة'),
            content: SingleChildScrollView(
              child: Text(e.toString()),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK / موافق'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<Map<String, String>> _resolveItemTranslations(
      Order order, ReceiptPrintLanguage language) async {
    final Map<String, String> translations = {};
    try {
      final vendorId = order.restaurantId;
      final List<Future<void>> futures = [];

      // 1. Fetch direct items under vendors/{vendorId}/items
      futures.add(FirebaseFirestore.instance
          .collection('vendors')
          .doc(vendorId)
          .collection('items')
          .get()
          .then((itemsSnap) {
        for (final doc in itemsSnap.docs) {
          final data = doc.data();
          final itemId = doc.id;
          if (language == ReceiptPrintLanguage.ar) {
            final nameAr = data['nameAr'] as String?;
            if (nameAr != null && nameAr.isNotEmpty) {
              translations[itemId] = nameAr;
            }
          } else {
            final nameEn = data['name'] as String?;
            if (nameEn != null && nameEn.isNotEmpty) {
              translations[itemId] = nameEn;
            }
          }
        }
      }));

      // 2. Fetch sections and then their items
      futures.add(FirebaseFirestore.instance
          .collection('vendors')
          .doc(vendorId)
          .collection('menuSections')
          .get()
          .then((sectionsSnap) async {
        final List<Future<void>> sectionFutures = [];
        for (final sectionDoc in sectionsSnap.docs) {
          sectionFutures.add(sectionDoc.reference
              .collection('items')
              .get()
              .then((itemsSnap) {
            for (final doc in itemsSnap.docs) {
              final data = doc.data();
              final itemId = doc.id;
              if (language == ReceiptPrintLanguage.ar) {
                final nameAr = data['nameAr'] as String?;
                if (nameAr != null && nameAr.isNotEmpty) {
                  translations[itemId] = nameAr;
                }
              } else {
                final nameEn = data['name'] as String?;
                if (nameEn != null && nameEn.isNotEmpty) {
                  translations[itemId] = nameEn;
                }
              }
            }
          }));
        }
        await Future.wait(sectionFutures);
      }));

      await Future.wait(futures);
    } catch (e) {
      debugPrint('Error resolving item translations: $e');
    }
    return translations;
  }

  Future<void> _callNumber(String phoneNumber) async {
    final Uri url = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not call $phoneNumber: $e')),
        );
      }
    }
  }

  String _localizeAddress(String address, BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    if (!isAr) return address;

    var localized = address;
    final replacements = {
      'Apartment (': 'شقة (',
      'Apartment': 'شقة',
      'Villa (': 'فيلا (',
      'Villa': 'فيلا',
      'Office (': 'مكتب (',
      'Office': 'مكتب',
      'Building:': 'مبنى:',
      'Apt:': 'شقة:',
      'Floor:': 'دور:',
      'Street:': 'شارع:',
      'Landmark:': 'علامة مميزة:',
      'Phone:': 'هاتف:',
      'Area:': 'منطقة:',
    };

    replacements.forEach((en, ar) {
      localized = localized.replaceAll(en, ar);
    });

    return localized;
  }
}
