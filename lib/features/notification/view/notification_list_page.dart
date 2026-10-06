import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:z_speed/components/promo_code_dialog.dart';
import 'package:z_speed/features/customer/view/vendor_menu_page.dart';
import 'package:z_speed/l10n/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:z_speed/core/injection.dart';
import 'package:z_speed/features/notification/cubit/notification_cubit.dart';
import 'package:z_speed/features/notification/cubit/notification_state.dart';
import 'package:z_speed/features/notification/widgets/notification_tile.dart';
import 'package:z_speed/features/notification/model/app_notification.dart';
import 'package:z_speed/features/admin/view/admin_application_detail_view.dart';
import 'package:z_speed/features/admin/cubit/admin_application_cubit.dart';
import 'package:z_speed/features/admin/repository/application_repository.dart';
import 'package:z_speed/features/customer/view/customer_order_history_screen.dart';
import 'package:z_speed/features/driver/model/delivery_request.dart';
import 'package:z_speed/features/driver/cubit/driver_dashboard_cubit.dart';
import 'package:z_speed/features/driver/screens/driver_tracking_screen.dart';
import 'package:z_speed/features/order/model/order.dart' as app_order;
import 'package:z_speed/core/enums/order_enums.dart';
import 'package:z_speed/core/enums/notification_enums.dart';

enum _NotificationFilter { all, unread, orders, promos }

class NotificationListPage extends StatefulWidget {
  /// Optional callback — called with a page index when a notification
  /// targets a tab inside the parent shell (e.g. restaurant hub).
  final void Function(int pageIndex)? onNavigateToPage;

  const NotificationListPage({super.key, this.onNavigateToPage});

  @override
  State<NotificationListPage> createState() => _NotificationListPageState();
}

class _NotificationListPageState extends State<NotificationListPage> {
  _NotificationFilter _selectedFilter = _NotificationFilter.all;

  @override
  Widget build(BuildContext context) {
    const Color brandOrange = Color(0xFFF35535);
    const Color brandOrangeDark = Color(0xFFE03E1A);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.notifications,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [brandOrange, brandOrangeDark],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        actions: [
          BlocBuilder<NotificationCubit, NotificationState>(
            builder: (context, state) {
              if (state.unreadCount == 0) return const SizedBox.shrink();
              return IconButton(
                onPressed: () {
                  context.read<NotificationCubit>().markAllAsRead();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(AppLocalizations.of(context)!.allNotificationsMarkedRead),
                        ],
                      ),
                      backgroundColor: const Color(0xFFF35535),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                },
                tooltip: AppLocalizations.of(context)!.markAllRead,
                icon: const Icon(Icons.done_all_rounded, color: Colors.white, size: 22),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: BlocBuilder<NotificationCubit, NotificationState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(brandOrange),
              ),
            );
          }

          if (state.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade400),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.failure!.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: Colors.grey.shade800),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(AppLocalizations.of(context)!.retry),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandOrange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final allNotifications = state.notifications;
          final filteredNotifications = _getFilteredNotifications(allNotifications);

          return Column(
            children: [
              // Filter Chips Bar
              _buildFilterBar(allNotifications, state.unreadCount),

              // Unread Info Banner with Clean Mark All Read button
              _buildUnreadHeaderBanner(state.unreadCount),

              // Notification List or Empty state
              Expanded(
                child: filteredNotifications.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: () async {
                          await Future.delayed(const Duration(milliseconds: 300));
                        },
                        color: brandOrange,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(top: 8, bottom: 24),
                          itemCount: filteredNotifications.length,
                          itemBuilder: (context, index) {
                            final notification = filteredNotifications[index];
                            return NotificationTile(
                              notification: notification,
                              onTap: () {
                                context.read<NotificationCubit>().markAsRead(notification.id);
                                _navigateToTarget(context, notification);
                              },
                              onDismiss: () {
                                context.read<NotificationCubit>().deleteNotification(
                                  notification.id,
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      AppLocalizations.of(context)!.notificationDeleted,
                                    ),
                                    duration: const Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterBar(List<AppNotification> all, int unreadCount) {
    final ordersCount = all.where((n) => _isOrderNotification(n)).length;
    final promosCount = all.where((n) => _isPromoNotification(n)).length;

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(
              filter: _NotificationFilter.all,
              label: AppLocalizations.of(context)!.filterAll,
              count: all.length,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              filter: _NotificationFilter.unread,
              label: AppLocalizations.of(context)!.filterUnread,
              count: unreadCount,
              badgeColor: const Color(0xFFF35535),
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              filter: _NotificationFilter.orders,
              label: AppLocalizations.of(context)!.filterOrders,
              count: ordersCount,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              filter: _NotificationFilter.promos,
              label: AppLocalizations.of(context)!.filterPromos,
              count: promosCount,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnreadHeaderBanner(int unreadCount) {
    if (unreadCount == 0) return const SizedBox.shrink();
    const Color brandOrange = Color(0xFFF35535);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: brandOrange.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: brandOrange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.unreadCountNotice(unreadCount),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          InkWell(
            onTap: () {
              context.read<NotificationCubit>().markAllAsRead();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(AppLocalizations.of(context)!.allNotificationsMarkedRead),
                    ],
                  ),
                  backgroundColor: brandOrange,
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.done_all_rounded,
                    size: 15,
                    color: brandOrange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    AppLocalizations.of(context)!.markAllRead,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: brandOrange,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required _NotificationFilter filter,
    required String label,
    required int count,
    Color? badgeColor,
  }) {
    final isSelected = _selectedFilter == filter;
    const Color brandOrange = Color(0xFFF35535);

    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? brandOrange : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? brandOrange : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : (badgeColor ?? Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Colors.white
                        : (badgeColor != null ? Colors.white : Colors.grey.shade800),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<AppNotification> _getFilteredNotifications(List<AppNotification> list) {
    switch (_selectedFilter) {
      case _NotificationFilter.unread:
        return list.where((n) => !n.read).toList();
      case _NotificationFilter.orders:
        return list.where((n) => _isOrderNotification(n)).toList();
      case _NotificationFilter.promos:
        return list.where((n) => _isPromoNotification(n)).toList();
      case _NotificationFilter.all:
        return list;
    }
  }

  bool _isOrderNotification(AppNotification n) {
    if (n.data['orderId'] != null) return true;
    return switch (n.type) {
      NotificationType.orderCreated ||
      NotificationType.orderStatusChanged ||
      NotificationType.orderReady ||
      NotificationType.driverAssigned ||
      NotificationType.deliveryRequest ||
      NotificationType.orderTimeout => true,
      _ => false,
    };
  }

  bool _isPromoNotification(AppNotification n) {
    if (n.data['screen'] == 'promo_code' ||
        n.data['promoCode'] != null ||
        n.data['code'] != null) {
      return true;
    }
    final titleLower = n.title.toLowerCase();
    return titleLower.contains('discount') ||
        titleLower.contains('promo') ||
        n.title.contains('خصم') ||
        n.title.contains('🎁');
  }

  Widget _buildEmptyState() {
    String message = AppLocalizations.of(context)!.noNotificationsYet;
    IconData icon = Icons.notifications_off_outlined;

    if (_selectedFilter == _NotificationFilter.unread) {
      message = AppLocalizations.of(context)!.noUnreadNotifications;
      icon = Icons.mark_email_read_outlined;
    } else if (_selectedFilter == _NotificationFilter.orders) {
      message = AppLocalizations.of(context)!.noOrderNotifications;
      icon = Icons.receipt_long_outlined;
    } else if (_selectedFilter == _NotificationFilter.promos) {
      message = AppLocalizations.of(context)!.noPromoNotifications;
      icon = Icons.local_offer_outlined;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0EC),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFF35535).withValues(alpha: 0.15),
                  width: 2,
                ),
              ),
              child: Icon(
                icon,
                size: 56,
                color: const Color(0xFFF35535),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.allNotificationsWillAppear,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            if (_selectedFilter != _NotificationFilter.all) ...[
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedFilter = _NotificationFilter.all;
                  });
                },
                child: Text(
                  AppLocalizations.of(context)!.viewAllNotifications,
                  style: const TextStyle(
                    color: Color(0xFFF35535),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _navigateToTarget(BuildContext context, AppNotification notification) {
    final screen = notification.data['screen'];
    final applicationId = notification.data['applicationId'];
    final orderId = notification.data['orderId'];

    switch (screen) {
      // ── Admin ──────────────────────────────────────────────────────
      case 'admin_applications':
      case 'admin_application_detail':
        if (applicationId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider<AdminApplicationCubit>(
                create: (_) => AdminApplicationCubit(
                  repository: getIt<ApplicationRepository>(),
                ),
                child: AdminApplicationDetailView(applicationId: applicationId),
              ),
            ),
          );
        } else {
          Navigator.pushNamed(context, '/admin');
        }
        break;

      // ── Promo Code Action ──────────────────────────────────────────
      case 'promo_code':
        final code = (notification.data['promoCode'] ??
            notification.data['code'] ??
            notification.data['targetEntityId'])?.toString();
        if (code != null && code.isNotEmpty) {
          DateTime? expiresAt;
          final expiresRaw = notification.data['expiresAt'] ??
              notification.data['validUntil'];
          if (expiresRaw is Timestamp) {
            expiresAt = (expiresRaw as Timestamp).toDate();
          } else if (expiresRaw is String) {
            expiresAt = DateTime.tryParse(expiresRaw);
          }
          PromoCodeDialog.show(context, code, expiresAt: expiresAt);
        }
        break;

      // ── Vendor / Restaurant Screen ────────────────────────────────
      case 'vendor':
      case 'restaurant':
        final vendorId = (notification.data['targetEntityId'] ??
            notification.data['vendorId'] ??
            notification.data['restaurantId'])?.toString();
        if (vendorId != null && vendorId.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RestaurantMenuPage(restaurantId: vendorId),
            ),
          );
        }
        break;

      // ── Custom URL Link ───────────────────────────────────────────
      case 'custom_url':
      case 'url':
        final urlStr = (notification.data['targetEntityId'] ??
            notification.data['url'] ??
            notification.data['custom_url'])?.toString();
        if (urlStr != null && urlStr.isNotEmpty) {
          final uri = Uri.tryParse(urlStr);
          if (uri != null) {
            launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
        break;

      // ── Restaurant owner — new order ───────────────────────────────
      case 'restaurant_order_detail':
        Navigator.of(context).pop(); // close notifications
        widget.onNavigateToPage?.call(1); // orders tab = index 1
        break;

      // ── Restaurant owner — menu updated ───────────────────────────
      case 'restaurant_menu':
        Navigator.of(context).pop();
        widget.onNavigateToPage?.call(2); // menu tab = index 2
        break;

      // ── Application status changed (vendor/driver) ─────────────────
      case 'application_status':
        Navigator.of(context).pop();
        // No specific tab — just close and let them see the status
        break;

      // ── Customer — order tracking ─────────────────────────────────
      case 'order_detail':
      case 'order_tracking':
      case 'vendor_order_detail':
        if (orderId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CustomerOrderHistoryScreen(),
            ),
          );
        }
        break;

      // ── Driver — delivery request ──────────────────────────────────
      case 'delivery_request':
        final requestId = notification.data['requestId'];
        final notifOrderId = notification.data['orderId'];
        _showDeliveryRequestSheet(context, requestId, notifOrderId);
        break;

      default:
        debugPrint('Unknown notification screen: $screen');
        break;
    }
  }

  Future<void> _showDeliveryRequestSheet(
    BuildContext context,
    String? requestId,
    String? orderId,
  ) async {
    // جيب الـ request من Firestore
    DeliveryRequest? request;

    try {
      // جرب بالـ requestId الأول
      if (requestId != null && requestId.isNotEmpty) {
        final doc = await FirebaseFirestore.instance
            .collection('deliveryRequests')
            .doc(requestId)
            .get();
        if (doc.exists) {
          request = DeliveryRequest.fromMap(doc.data()!, doc.id);
        }
      }

      // لو مش لاقيه بالـ requestId، جرب بالـ orderId
      if (request == null && orderId != null && orderId.isNotEmpty) {
        final snap = await FirebaseFirestore.instance
            .collection('deliveryRequests')
            .where('orderId', isEqualTo: orderId)
            .where('status', isEqualTo: 'pending')
            .limit(1)
            .get();
        if (snap.docs.isNotEmpty) {
          request = DeliveryRequest.fromMap(
            snap.docs.first.data(),
            snap.docs.first.id,
          );
        }
      }
    } catch (_) {}

    if (!context.mounted) return;

    if (request == null) {
      // الـ request اتقبل أو انتهى وقته
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.newDeliveryRequestsWillAppear,
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final req = request;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _DeliveryRequestSheet(request: req),
    );
  }
}

// ── Bottom sheet بيعرض تفاصيل الـ delivery request ──────────────────────────

class _DeliveryRequestSheet extends StatefulWidget {
  final DeliveryRequest request;
  const _DeliveryRequestSheet({required this.request});

  @override
  State<_DeliveryRequestSheet> createState() => _DeliveryRequestSheetState();
}

class _DeliveryRequestSheetState extends State<_DeliveryRequestSheet> {
  bool _isBusy = false;

  Future<void> _accept() async {
    setState(() => _isBusy = true);

    // لو في DriverDashboardCubit في الشجرة، استخدمه - لو لأ، اعمل direct Firestore call
    try {
      DriverDashboardCubit? cubit;
      try {
        cubit = context.read<DriverDashboardCubit>();
      } catch (_) {}

      if (cubit != null) {
        final success = await cubit.acceptRequest(
          widget.request.id,
          widget.request.orderId,
        );
        if (!mounted) return;
        if (success) {
          Navigator.pop(context);
          final order = app_order.Order(
            id: widget.request.orderId,
            customerId: '',
            restaurantId: widget.request.restaurantId,
            driverId: widget.request.driverId,
            status: OrderStatus.driverAssigned,
            subtotal: 0,
            deliveryFee: widget.request.deliveryFee,
            total: widget.request.deliveryFee,
            deliveryAddress: widget.request.customerAddress,
            deliveryLat: widget.request.customerLat,
            deliveryLng: widget.request.customerLng,
            createdAt: widget.request.createdAt,
            updatedAt: widget.request.createdAt,
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider<DriverDashboardCubit>.value(
                value: cubit!,
                child: DriverTrackingScreen(order: order),
              ),
            ),
          );
        } else {
          if (mounted) setState(() => _isBusy = false);
        }
      } else {
        // مفيش cubit - بس ارجع للـ driver app
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (_) {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _reject() async {
    setState(() => _isBusy = true);
    try {
      DriverDashboardCubit? cubit;
      try {
        cubit = context.read<DriverDashboardCubit>();
      } catch (_) {}

      if (cubit != null) {
        await cubit.rejectRequest(
          widget.request.id,
          widget.request.orderId,
          AppLocalizations.of(context)!.driverDeclined,
        );
      }
    } catch (_) {}
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.request;
    final isExpired = req.expiresAt.isBefore(DateTime.now());

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.delivery_dining,
                  color: Colors.purple.shade700,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.noPendingRequests,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Order #${req.orderId.substring(0, 8).toUpperCase()}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              // Delivery fee
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Text(
                  '${req.deliveryFee.toStringAsFixed(0)} EGP',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // من (المطعم)
          _InfoRow(
            icon: Icons.restaurant,
            iconColor: Colors.orange.shade700,
            label: AppLocalizations.of(context)!.restaurant,
            value: req.restaurantName,
          ),
          const SizedBox(height: 4),
          // خط واصل
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 18),
            child: Container(width: 2, height: 20, color: Colors.grey.shade300),
          ),
          const SizedBox(height: 4),
          // لـ (العميل)
          _InfoRow(
            icon: Icons.location_on,
            iconColor: Colors.green.shade700,
            label: AppLocalizations.of(context)!.customer,
            value: req.customerAddress.isNotEmpty
                ? req.customerAddress
                : '${req.customerLat.toStringAsFixed(4)}, ${req.customerLng.toStringAsFixed(4)}',
          ),
          const SizedBox(height: 16),

          // الأيتمز
          if (req.itemNames.isNotEmpty) ...[
            Text(
              AppLocalizations.of(context)!.itemsToDeliver,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            ...req.itemNames.map(
              (name) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: Colors.orange.shade600,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(name, style: const TextStyle(fontSize: 14)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ] else ...[
            Text(
              AppLocalizations.of(context)!.itemsToDeliver,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('orders')
                  .doc(req.orderId)
                  .collection('items')
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }
                if (snapshot.hasError ||
                    !snapshot.hasData ||
                    snapshot.data!.docs.isEmpty) {
                  return Text(
                    AppLocalizations.of(context)!.noItemDetailsAvailable,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  );
                }
                final names = snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>?;
                  final quantity = data?['quantity'] ?? 1;
                  final name = data?['name'] ?? data?['menuItemName'] ?? 'Item';
                  return '${quantity}x $name';
                }).toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: names
                      .map(
                        (name) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 16,
                                color: Colors.orange.shade600,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 16),
          ],

          // تحذير لو انتهى الوقت
          if (isExpired)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.timer_off, color: Colors.red.shade600, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)!.expired,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 20),

          // Buttons
          if (!isExpired)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isBusy ? null : _reject,
                    icon: const Icon(Icons.close, size: 18),
                    label: Text(AppLocalizations.of(context)!.reject),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isBusy ? null : _accept,
                    icon: _isBusy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check, size: 18),
                    label: Text(AppLocalizations.of(context)!.accept),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(AppLocalizations.of(context)!.close),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
