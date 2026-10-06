import 'package:z_speed/features/customer/widgets/customer_live_tracking_map.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:z_speed/features/driver/model/order_driver.dart';
import 'package:z_speed/core/injection.dart';
import 'package:flutter/material.dart';
import 'package:z_speed/l10n/app_localizations.dart';
import 'package:z_speed/core/enums/order_enums.dart';
import 'package:z_speed/features/order/model/order.dart';
import 'package:z_speed/features/order/model/tracking_step.dart';
import 'package:z_speed/features/order/cubit/order_tracking_cubit.dart';
import 'package:z_speed/features/order/cubit/order_tracking_state.dart';
import 'package:z_speed/features/payment/payment.dart';
import 'package:z_speed/features/payment/cubit/payment_cubit.dart';
import 'package:z_speed/features/payment/cubit/payment_state.dart';
import 'package:z_speed/features/shared/widgets/shared_order_summary_widget.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/core/constants/app_constants.dart';
import 'package:z_speed/features/help_support/widgets/help_support_actions.dart';

/// Order Tracking Screen — real-time order status tracking for customers.
///
/// Features:
/// - Real-time status updates via OrderTrackingViewModel
/// - Visual timeline of order progress
/// - ETA estimation
/// - Cancel order (if status ≤ accepted)
/// - Order summary with items and addons
class OrderTrackingScreen extends StatelessWidget {
  final String orderId;

  const OrderTrackingScreen({
    super.key,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<OrderTrackingCubit>(
          create: (_) => getIt<OrderTrackingCubit>()..init(orderId),
        ),
        BlocProvider<PaymentCubit>(
          create: (_) => getIt<PaymentCubit>()..loadPaymentByOrderId(orderId),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            AppLocalizations.of(context)!.trackOrder,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
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
        body: BlocBuilder<OrderTrackingCubit, OrderTrackingState>(
          builder: (context, state) {
            if (state.isBusy) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      state.failure?.getLocalizedMessage(context) ??
                          AppLocalizations.of(context)!.failedToLoadOrder,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () =>
                          context.read<OrderTrackingCubit>().init(orderId),
                      child: Text(AppLocalizations.of(context)!.retry),
                    ),
                  ],
                ),
              );
            }

            final order = state.order;
            if (order == null) {
              return Center(
                  child: Text(AppLocalizations.of(context)!.orderNotFound));
            }

            return RefreshIndicator(
              onRefresh: () => context.read<OrderTrackingCubit>().init(orderId),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStatusHeader(context, order, state),
                    const SizedBox(height: 24),
                    _buildTimeline(context, state.trackingSteps),
                    const SizedBox(height: 24),
                    _buildDriverInfo(context, order, state),
                    const SizedBox(height: 24),
                    SharedOrderSummaryWidget(
                        order: order, items: state.orderItems ?? []),
                    const SizedBox(height: 24),
                    _buildPaymentSection(context, order),
                    const SizedBox(height: 24),
                    if (context.read<OrderTrackingCubit>().canCancel())
                      _buildCancelButton(
                          context, context.read<OrderTrackingCubit>()),
                    const SizedBox(height: 16),
                    _buildSupportButton(context),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusHeader(
      BuildContext context, Order order, OrderTrackingState state) {
    final statusColor = _getStatusColor(order.status);
    final eta =
        state.estimatedTime ?? AppLocalizations.of(context)!.etaCalculating;
    final progress = state.progressPercentage;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('vendors')
                          .doc(order.restaurantId)
                          .get(),
                      builder: (context, snapshot) {
                        String name =
                            'Order #${order.id.substring(0, 8).toUpperCase()}';
                        if (snapshot.hasData && snapshot.data!.exists) {
                          name = (snapshot.data!.data()
                                  as Map<String, dynamic>)['name'] ??
                              name;
                        }
                        return Text(
                          name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM dd, h:mm a').format(order.createdAt),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    order.status.label,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.access_time, size: 20, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.eta(eta),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(BuildContext context, List<TrackingStep> steps) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.orderTimeline,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ...List.generate(steps.length, (index) {
              final step = steps[index];
              final isLast = index == steps.length - 1;
              return _buildTimelineStep(context, step, isLast);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineStep(
      BuildContext context, TrackingStep step, bool isLast) {
    final color = step.isComplete ? Colors.green : Colors.grey;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: color,
                  width: 2,
                ),
              ),
              child: Icon(
                step.icon,
                size: 20,
                color: color,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                color: step.isComplete ? Colors.green : Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsetsDirectional.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _localizeStepTitle(context, step.title),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: step.isComplete ? Colors.black87 : Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _localizeStepSubtitle(context, step.subtitle),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                if (step.timestamp != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('h:mm a').format(step.timestamp!),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDriverInfo(BuildContext context, Order order, OrderTrackingState state) {
    final hasDriver = order.status.index >= OrderStatus.driverAssigned.index;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.deliveryDriver,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (!hasDriver)
              Center(
                child: Column(
                  children: [
                    Icon(Icons.delivery_dining,
                        size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      AppLocalizations.of(context)!.driverNotAssignedYet,
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.driverWillBeAssignedSoon,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
                  ],
                ),
              )
            else
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('orders')
                    .doc(order.id)
                    .collection('orderDrivers')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final activeDrivers = snapshot.data!.docs.where((doc) {
                    final s = (doc.data() as Map<String, dynamic>)['status']
                            as String? ??
                        '';
                    return s == 'accepted' ||
                        s == 'pickedUp' ||
                        s == 'delivered';
                  }).toList();

                  if (activeDrivers.isEmpty) {
                    return Center(
                      child: Column(
                        children: [
                          Icon(Icons.delivery_dining,
                              size: 56, color: Colors.grey[400]),
                          const SizedBox(height: 10),
                          Text(
                            AppLocalizations.of(context)!.searchingForDriver,
                            style: TextStyle(
                                fontSize: 15, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: activeDrivers.map((doc) {
                      final driver = OrderDriver.fromMap(
                          doc.data() as Map<String, dynamic>);
                      final canTrack = order.status == OrderStatus.pickedUp ||
                          order.status == OrderStatus.onTheWay;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildDriverCard(context, driver),
                          if (canTrack) ...[
                            const SizedBox(height: 16),
                            CustomerLiveTrackingMap(
                              orderId: order.id,
                              driverId: driver.driverUserId,
                              driverName: driver.driverName,
                              driverPhone: driver.driverPhone,
                              vehicleModel: driver.vehicleModel,
                              licensePlate: driver.licensePlate,
                              deliveryLat: order.deliveryLat,
                              deliveryLng: order.deliveryLng,
                              deliveryAddress: order.deliveryAddress,
                              restaurantLat: state.restaurantLocation?.latitude,
                              restaurantLng: state.restaurantLocation?.longitude,
                              orderStatus: order.status,
                            ),
                          ],
                        ],
                      );
                    }).toList(),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverCard(BuildContext context, OrderDriver driver) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.orange.shade100,
            child: const Icon(Icons.delivery_dining,
                color: Colors.orange, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driver.driverName.isNotEmpty
                      ? driver.driverName
                      : AppLocalizations.of(context)!.driverFallback,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
                ),
                if (driver.driverPhone.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.phone_outlined,
                          size: 13, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(driver.driverPhone,
                          style:
                              TextStyle(fontSize: 13, color: Colors.grey[700])),
                    ],
                  ),
                ],
                if (driver.vehicleModel.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.directions_car_outlined,
                          size: 13, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        driver.licensePlate.isNotEmpty
                            ? '${driver.vehicleModel} · ${driver.licensePlate}'
                            : driver.vehicleModel,
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection(BuildContext context, Order order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.paymentSection,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              PaymentStatusBadge(status: order.paymentStatus),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Payment method
          Row(
            children: [
              Icon(
                _getPaymentMethodIcon(order.paymentMethod),
                size: 20,
                color: const Color(0xFFF35535),
              ),
              const SizedBox(width: 8),
              Text(
                _getPaymentMethodName(context, order.paymentMethod),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // View Receipt Button (only if payment exists)
          BlocBuilder<PaymentCubit, PaymentState>(
            builder: (context, state) {
              if (state.currentPayment != null) {
                return SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PaymentReceiptView(
                            payment: state.currentPayment!,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.receipt_long),
                    label: Text(AppLocalizations.of(context)!.viewReceipt),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFF35535),
                      side: const BorderSide(color: Color(0xFFF35535)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  IconData _getPaymentMethodIcon(PaymentMethodType method) {
    switch (method) {
      case PaymentMethodType.cash:
        return Icons.payments_outlined;
      case PaymentMethodType.card:
        return Icons.credit_card_outlined;
      case PaymentMethodType.wallet:
        return Icons.account_balance_wallet_outlined;
    }
  }

  String _getPaymentMethodName(BuildContext context, PaymentMethodType method) {
    final l10n = AppLocalizations.of(context)!;
    switch (method) {
      case PaymentMethodType.cash:
        return l10n.cashOnDelivery;
      case PaymentMethodType.card:
        return l10n.creditDebitCard;
      case PaymentMethodType.wallet:
        return l10n.mobileWallet;
    }
  }

  Widget _buildCancelButton(BuildContext context, OrderTrackingCubit cubit) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: () => _showCancelDialog(context, cubit),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          AppLocalizations.of(context)!.cancelOrder,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSupportButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: () => _showSupportOptions(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.blue,
          side: const BorderSide(color: Colors.blue),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.support_agent),
        label: Text(
          AppLocalizations.of(context)!.contactSupportLabel,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showSupportOptions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.contactSupportTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFFF0EC),
                  child: Icon(Icons.chat, color: Color(0xFFF35535)),
                ),
                title: Text(l10n.liveChat),
                subtitle: Text(l10n.chatWithSupportAgents),
                onTap: () {
                  Navigator.pop(ctx);
                  HelpSupportActions.openLiveChat(context);
                },
              ),
              const Divider(),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEBF3FE),
                  child: Icon(Icons.email, color: Colors.blue),
                ),
                title: Text(l10n.emailUs),
                subtitle: Text(AppConstants.supportEmail),
                onTap: () {
                  Navigator.pop(ctx);
                  HelpSupportActions.sendEmail(
                    context: context,
                    subject: l10n.supportEmailSubject(
                      AppConstants.appName,
                      orderId,
                    ),
                    body: l10n.supportEmailBody(orderId),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE8F5E9),
                  child: Icon(Icons.phone, color: Colors.green),
                ),
                title: Text(l10n.callUs),
                subtitle: Text(AppConstants.supportPhone),
                onTap: () {
                  Navigator.pop(ctx);
                  HelpSupportActions.makePhoneCall(context: context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCancelDialog(
      BuildContext context, OrderTrackingCubit cubit) async {
    String? selectedReason;
    final l10n = AppLocalizations.of(context)!;
    final reasons = [
      l10n.cancelReasonChangedMind,
      l10n.cancelReasonMistake,
      l10n.cancelReasonTooLong,
      l10n.cancelReasonBetterOption,
      l10n.cancelReasonOther,
    ];

    return showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.cancelOrder),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context)!.pleaseSelectAReason),
              const SizedBox(height: 16),
              ...reasons.map(
                (reason) => RadioListTile<String>(
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
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(AppLocalizations.of(context)!.keepOrder),
            ),
            ElevatedButton(
              onPressed: selectedReason == null
                  ? null
                  : () async {
                      Navigator.of(ctx).pop();
                      final success = await cubit.cancelOrder(selectedReason!);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? AppLocalizations.of(context)!
                                      .orderCancelledSuccess
                                  : AppLocalizations.of(context)!
                                      .failedToCancelOrder,
                            ),
                            backgroundColor:
                                success ? Colors.green : Colors.red,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Text(
                AppLocalizations.of(context)!.cancelOrder,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
      case OrderStatus.searching:
        return Colors.blue;
      case OrderStatus.accepted:
      case OrderStatus.preparing:
        return Colors.orange;
      case OrderStatus.ready:
      case OrderStatus.driverAssigned:
        return Colors.purple;
      case OrderStatus.pickedUp:
      case OrderStatus.onTheWay:
        return Colors.indigo;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
      case OrderStatus.refunded:
      case OrderStatus.unassigned:
        return Colors.red;
    }
  }

  String _localizeStepTitle(BuildContext context, String original) {
    if (original == 'Order Placed' || original == 'Pending') {
      return AppLocalizations.of(context)!.statusPending;
    }
    if (original == 'Accepted') {
      return AppLocalizations.of(context)!.statusAccepted;
    }
    if (original == 'Preparing') {
      return AppLocalizations.of(context)!.statusPreparing;
    }
    if (original == 'Driver Assigned') {
      return AppLocalizations.of(context)!.statusDriverAssigned;
    }
    if (original == 'Ready') return AppLocalizations.of(context)!.statusReady;
    if (original == 'Picked Up') {
      return AppLocalizations.of(context)!.statusPickedUp;
    }
    if (original == 'On The Way') {
      return AppLocalizations.of(context)!.statusOnTheWay;
    }
    if (original == 'Delivered') {
      return AppLocalizations.of(context)!.statusDelivered;
    }

    if (original == 'Dispatching') {
      return AppLocalizations.of(context)!.dispatching;
    }
    if (original == 'Out for Delivery') {
      return AppLocalizations.of(context)!.outForDelivery;
    }
    return original;
  }

  String _localizeStepSubtitle(BuildContext context, String original) {
    if (original == 'Waiting for restaurant') {
      return AppLocalizations.of(context)!.waitingForRestaurant;
    }
    if (original == 'Pending') {
      return AppLocalizations.of(context)!.statusPending;
    }
    if (original == 'Accepted') {
      return AppLocalizations.of(context)!.statusAccepted;
    }
    // Subtitles we used:
    // 'Restaurant is preparing your order'
    if (original == 'Restaurant is preparing your order') {
      return AppLocalizations.of(context)!.restaurantPreparingOrder;
    }
    if (original == 'Looking for a driver') {
      return AppLocalizations.of(context)!.lookingForDriver;
    }
    if (original == 'Driver has been assigned') {
      return AppLocalizations.of(context)!.driverAssigned;
    }
    if (original == 'Waiting for order completion') {
      return AppLocalizations.of(context)!.waitingForOrderCompletion;
    }
    if (original == 'Waiting for pickup') {
      return AppLocalizations.of(context)!.waitingForPickup;
    }
    if (original == 'Driver is being dispatched') {
      return AppLocalizations.of(context)!.driverBeingDispatched;
    }

    if (original == 'Waiting to assign driver') {
      return AppLocalizations.of(context)!.waitingToAssignDriver;
    }
    if (original == 'Searching for nearby driver via LocationIQ...') {
      return AppLocalizations.of(context)!.searchingForNearbyDriver;
    }
    if (original == 'No drivers available in vicinity') {
      return AppLocalizations.of(context)!.noDriversAvailableVicinity;
    }
    if (original == 'Driver assigned!') {
      return AppLocalizations.of(context)!.driverAssigned;
    }
    if (original == 'Driver is on the way') {
      return AppLocalizations.of(context)!.outForDelivery;
    }
    if (original == 'Waiting for pick up') {
      return AppLocalizations.of(context)!.waitingForPickUp;
    }
    if (original == 'Enjoy your meal!') {
      return AppLocalizations.of(context)!.enjoyYourMeal;
    }
    if (original == 'Arriving soon') {
      return AppLocalizations.of(context)!.arrivingSoon;
    }
    return original;
  }
}
