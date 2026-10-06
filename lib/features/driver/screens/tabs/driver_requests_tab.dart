import 'package:flutter/material.dart';
import 'package:z_speed/l10n/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:z_speed/features/driver/cubit/driver_dashboard_cubit.dart';
import 'package:z_speed/features/driver/cubit/driver_dashboard_state.dart';
import 'package:z_speed/features/driver/model/delivery_request.dart';
import 'package:z_speed/features/order/model/order.dart';
import 'package:z_speed/core/enums/order_enums.dart';
import 'package:z_speed/features/driver/screens/driver_tracking_screen.dart';
import 'package:z_speed/features/driver/widgets/countdown_timer.dart';
import 'package:z_speed/components/address_text.dart';
import 'package:z_speed/features/auth/model/user_model.dart';
import 'package:z_speed/features/restaurant/model/restaurant.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:z_speed/core/errors/failure_localization_ext.dart';

/// Requests tab - shows pending delivery requests for driver to accept/reject.
class DriverRequestsTab extends StatelessWidget {
  const DriverRequestsTab({super.key});

  static String _resolveAddress(
      String address, double lat, double lng, String fallback) {
    if (address.isEmpty || address == 'API Key missing') {
      if (lat != 0.0 && lng != 0.0) {
        return '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
      }
      return fallback;
    }
    return address;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: BlocListener<DriverDashboardCubit, DriverDashboardState>(
        listener: (context, state) {
          if (state.hasError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.failure?.getLocalizedMessage(context) ??
                    AppLocalizations.of(context)!.errorOccurred),
                backgroundColor: Colors.red,
              ),
            );
            context.read<DriverDashboardCubit>().clearError();
          }
        },
        child: BlocBuilder<DriverDashboardCubit, DriverDashboardState>(
          builder: (context, state) {
            final activeOrders = state.activeOrders;
            final requests = state.pendingRequests;

            if (activeOrders.isEmpty && requests.isEmpty) {
              return _buildEmptyState();
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (activeOrders.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12, top: 8),
                    child: Text(
                      'Active Missions (${activeOrders.length})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  ...activeOrders.map((order) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: ActiveOrderCard(order: order),
                      )),
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                ],
                if (requests.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Pending Requests (${requests.length})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  ...requests.map((request) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: KeyedSubtree(
                          key: ValueKey(request.id),
                          child: _buildRequestCard(context, state, request),
                        ),
                      )),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Builder(
        builder: (context) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.noPendingRequests,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.newDeliveryRequestsWillAppear,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ));
  }

  Widget _buildRequestCard(
    BuildContext context,
    DriverDashboardState state,
    DeliveryRequest request,
  ) {
    return InkWell(
      onTap: () => _showOrderDetails(context, request),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsetsDirectional.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.newLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Order #${request.orderId.substring(0, 8).toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                Text(
                  AppLocalizations.of(context)!.egpAmount(
                      request.orderTotal.toStringAsFixed(2).toString()),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.restaurant, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    request.restaurantName,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: AddressText(
                    address: request.customerAddress,
                    lat: request.customerLat,
                    lng: request.customerLng,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.shopping_bag, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.itemsAssigned(
                      request.itemNames.isNotEmpty
                          ? request.itemNames.length
                          : request.assignedItems.length),
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.timer_outlined,
                    size: 18, color: Colors.orange),
                const SizedBox(width: 8),
                CountdownTimer(
                  expiresAt: request.expiresAt,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  AppLocalizations.of(context)!.remainingToAccept,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: state.isBusy
                        ? null
                        : () => _confirmReject(context,
                            context.read<DriverDashboardCubit>(), request),
                    icon: const Icon(Icons.close, size: 18),
                    label: Text(AppLocalizations.of(context)!.reject),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: state.isBusy
                        ? null
                        : () async {
                            final cubit = context.read<DriverDashboardCubit>();
                            await cubit.acceptRequest(request.id, request.orderId);
                          },
                    icon: const Icon(Icons.check, size: 18),
                    label: Text(AppLocalizations.of(context)!.accept),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showOrderDetails(BuildContext context, DeliveryRequest request) {
    Widget buildItemRow(String name) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.check_circle_outline,
                size: 18, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(
                child: Text(name,
                    style: const TextStyle(fontSize: 15))),
          ],
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.orderDetails,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.itemsToDeliver,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: Colors.grey)),
            const SizedBox(height: 8),
            if (request.itemNames.isNotEmpty)
              ...request.itemNames.map((name) => buildItemRow(name))
            else
              FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('orders')
                    .doc(request.orderId)
                    .collection('items')
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  }
                  if (snapshot.hasError ||
                      !snapshot.hasData ||
                      snapshot.data!.docs.isEmpty) {
                    return Text(AppLocalizations.of(context)!.noItemDetailsAvailable,
                        style: const TextStyle(color: Colors.grey));
                  }
                  final names = snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>?;
                    final quantity = data?['quantity'] ?? 1;
                    final name = data?['name'] ?? data?['menuItemName'] ?? 'Item';
                    return '${quantity}x $name';
                  }).toList();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: names.map((name) => buildItemRow(name)).toList(),
                  );
                },
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(AppLocalizations.of(context)!.closeDetails,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmReject(
    BuildContext context,
    DriverDashboardCubit cubit,
    DeliveryRequest request,
  ) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.rejectRequest),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.areYouSureRejectRequest,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.rejectReason,
                hintText: AppLocalizations.of(context)!.rejectReasonHint,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              cubit.rejectRequest(
                request.id,
                request.orderId,
                reasonController.text.trim().isEmpty
                    ? AppLocalizations.of(context)!.driverDeclined
                    : reasonController.text.trim(),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context)!.reject),
          ),
        ],
      ),
    );
  }
}

class ActiveMissionCard extends StatefulWidget {
  final Order order;
  final DriverDashboardState state;

  const ActiveMissionCard({
    super.key,
    required this.order,
    required this.state,
  });

  @override
  State<ActiveMissionCard> createState() => _ActiveMissionCardState();
}

class _ActiveMissionCardState extends State<ActiveMissionCard> {
  AppUser? _customerUser;
  Restaurant? _restaurant;

  @override
  void initState() {
    super.initState();
    _fetchCustomerDetails();
    _fetchRestaurantDetails();
  }

  @override
  void didUpdateWidget(ActiveMissionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.order.id != oldWidget.order.id) {
      _fetchCustomerDetails();
      _fetchRestaurantDetails();
    }
  }

  Future<void> _fetchCustomerDetails() async {
    try {
      final customerId = widget.order.customerId;
      if (customerId.isEmpty) return;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(customerId)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _customerUser = AppUser.fromMap(doc.data()!, doc.id);
        });
      }
    } catch (e) {
      debugPrint('Error fetching customer details: $e');
    }
  }

  Future<void> _fetchRestaurantDetails() async {
    try {
      final restaurantId = widget.order.restaurantId;
      if (restaurantId.isEmpty) return;
      final doc = await FirebaseFirestore.instance
          .collection('vendors')
          .doc(restaurantId)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _restaurant = Restaurant.fromMap(doc.data()!, doc.id);
        });
      }
    } catch (e) {
      debugPrint('Error fetching restaurant details: $e');
    }
  }

  Future<void> _openGoogleMapsDirections() async {
    final order = widget.order;
    final isHeadingToRestaurant = order.status == OrderStatus.driverAssigned ||
        order.status == OrderStatus.preparing ||
        order.status == OrderStatus.ready;

    double lat = order.deliveryLat;
    double lng = order.deliveryLng;

    if (isHeadingToRestaurant) {
      Restaurant? rest = _restaurant;
      if (rest == null && order.restaurantId.isNotEmpty) {
        try {
          final doc = await FirebaseFirestore.instance
              .collection('vendors')
              .doc(order.restaurantId)
              .get();
          if (doc.exists) {
            rest = Restaurant.fromMap(doc.data()!, doc.id);
          }
        } catch (e) {
          debugPrint('Error fetching restaurant for directions: $e');
        }
      }
      if (rest != null) {
        lat = rest.latitude;
        lng = rest.longitude;
      }
    }

    if (lat == 0.0 && lng == 0.0) return;

    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
    );
    launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color.withValues(alpha: 0.1),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Map<String, String> _parseAddressDetails(String address) {
    final Map<String, String> details = {};
    final typeIndex = address.indexOf('(');
    if (typeIndex != -1) {
      details['Type'] = address.substring(0, typeIndex).trim();
    }
    final startParenthesis = address.indexOf('(');
    final endParenthesis = address.indexOf(')');
    if (startParenthesis != -1 && endParenthesis != -1 && endParenthesis > startParenthesis) {
      final innerText = address.substring(startParenthesis + 1, endParenthesis);
      final parts = innerText.split(RegExp(r'[,،]'));
      for (var part in parts) {
        final kv = part.split(':');
        if (kv.length >= 2) {
          final key = kv[0].trim();
          final val = kv.sublist(1).join(':').trim();
          details[key] = val;
        }
      }
    }
    final areaIndex = address.indexOf(RegExp(r'\)\.\s*(?:Area|المنطقة)\s*:'));
    if (areaIndex != -1) {
      final labelIndex = address.indexOf(':', areaIndex);
      if (labelIndex != -1) {
        details['Area'] = address.substring(labelIndex + 1).trim();
      }
    }
    return details;
  }

  String? _extractPhoneFromAddress(String address) {
    final phoneRegex = RegExp(r'(?:Phone:|هاتف:)\s*([+\d\s-]+)');
    final match = phoneRegex.firstMatch(address);
    if (match != null) {
      final phone = match.group(1)?.trim();
      if (phone != null) {
        final cleanPhone = phone.split(')').first.split(',').first.split('،').first.trim();
        if (cleanPhone.isNotEmpty) {
          return cleanPhone;
        }
      }
    }
    return null;
  }

  Future<void> _callNumber(String phoneNumber) async {
    final Uri url = Uri(scheme: 'tel', path: phoneNumber);
    try {
      await launchUrl(url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.couldNotCall(phoneNumber, e.toString()))),
        );
      }
    }
  }

  void _callCustomer() {
    final phone = _customerUser?.phone ?? _extractPhoneFromAddress(widget.order.deliveryAddress);
    if (phone != null && phone.isNotEmpty) {
      _callNumber(phone);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.customerPhoneNotAvailable)),
      );
    }
  }

  void _showOrderDetailsBottomSheet() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final parsedAddress = _parseAddressDetails(widget.order.deliveryAddress);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.orderDetails,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      children: [
                        _buildSummaryCard(theme, l10n),
                        const SizedBox(height: 16),
                        _buildCustomerDetailsCard(theme, l10n, parsedAddress),
                        const SizedBox(height: 16),
                        if (_restaurant != null) ...[
                          _buildRestaurantDetailsCard(theme, l10n),
                          const SizedBox(height: 16),
                        ],
                        _buildItemsCard(theme, l10n),
                        const SizedBox(height: 16),
                        _buildPaymentCard(theme, l10n),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSummaryCard(ThemeData theme, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ID: ${widget.order.id.substring(0, 8).toUpperCase()}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Created: ${_formatTime(widget.order.createdAt)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              widget.order.status.getLocalizedLabel(l10n),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: theme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildCustomerDetailsCard(
    ThemeData theme,
    AppLocalizations l10n,
    Map<String, String> parsedAddress,
  ) {
    final customerPhone = _customerUser?.phone ?? _extractPhoneFromAddress(widget.order.deliveryAddress) ?? '';
    final customerName = _customerUser?.name ?? l10n.customer;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  l10n.customer,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      if (customerPhone.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          customerPhone,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (customerPhone.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.phone, color: Colors.green),
                    onPressed: () => _callNumber(customerPhone),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Delivery Address',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 6),
            if (parsedAddress.isNotEmpty) ...[
              ...parsedAddress.entries.map((entry) {
                final localizedKey = _localizeAddressKey(entry.key, l10n);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 100,
                        child: Text(
                          '$localizedKey:',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ] else ...[
              Text(
                widget.order.deliveryAddress,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 13,
                ),
              ),
            ],
            if (widget.order.customerNote != null && widget.order.customerNote!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade100),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.note_alt_outlined, color: Colors.orange, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Note: ${widget.order.customerNote}',
                        style: TextStyle(
                          color: Colors.orange.shade900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _localizeAddressKey(String key, AppLocalizations l10n) {
    final lowerKey = key.toLowerCase();
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    if (lowerKey.contains('building') || lowerKey.contains('مبنى')) {
      return isAr ? 'مبنى' : 'Building';
    }
    if (lowerKey.contains('apt') || lowerKey.contains('apartment') || lowerKey.contains('شقة')) {
      return isAr ? 'شقة' : 'Apartment';
    }
    if (lowerKey.contains('floor') || lowerKey.contains('دور')) {
      return isAr ? 'دور' : 'Floor';
    }
    if (lowerKey.contains('street') || lowerKey.contains('شارع')) {
      return isAr ? 'شارع' : 'Street';
    }
    if (lowerKey.contains('landmark') || lowerKey.contains('علامة')) {
      return isAr ? 'علامة مميزة' : 'Landmark';
    }
    if (lowerKey.contains('phone') || lowerKey.contains('هاتف')) {
      return isAr ? 'هاتف' : 'Phone';
    }
    if (lowerKey.contains('area') || lowerKey.contains('منطقة')) {
      return isAr ? 'المنطقة' : 'Area';
    }
    if (lowerKey.contains('type')) {
      return isAr ? 'النوع' : 'Type';
    }
    return key;
  }

  Widget _buildRestaurantDetailsCard(ThemeData theme, AppLocalizations l10n) {
    if (_restaurant == null) return const SizedBox.shrink();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.restaurant, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  l10n.restaurant,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _restaurant!.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      if (_restaurant!.phone.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          _restaurant!.phone,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (_restaurant!.phone.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.phone, color: Colors.orange),
                    onPressed: () => _callNumber(_restaurant!.phone),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _restaurant!.address,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsCard(ThemeData theme, AppLocalizations l10n) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shopping_bag_outlined, color: theme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  l10n.itemsInOrder,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.order.items.length,
              separatorBuilder: (context, index) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final item = widget.order.items[index];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${item.quantity}x',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          if (item.optionsSummary != null && item.optionsSummary!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              item.optionsSummary!,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Text(
                      l10n.egpAmount(item.totalPrice.toStringAsFixed(2)),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(ThemeData theme, AppLocalizations l10n) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.payment, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  l10n.paymentDetails,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Payment Method',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                Text(
                  widget.order.paymentMethod.getLocalizedLabel(l10n),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Payment Status',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                Text(
                  widget.order.paymentStatus.getLocalizedLabel(l10n),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  l10n.egpAmount(widget.order.total.toStringAsFixed(2)),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: theme.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(
      IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(value,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          Text(label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF16A34A), Color(0xFF15803D)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delivery_dining,
                      size: 28, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppLocalizations.of(context)!.activeMission,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(
                        'Order #${order.id.substring(0, 8).toUpperCase()}',
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.85)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    (order.status == OrderStatus.driverAssigned ||
                            order.status == OrderStatus.ready ||
                            order.status == OrderStatus.preparing ||
                            order.status == OrderStatus.accepted)
                        ? AppLocalizations.of(context)!.toRestaurant
                        : AppLocalizations.of(context)!.toCustomer,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: (order.status == OrderStatus.driverAssigned ||
                              order.status == OrderStatus.ready ||
                              order.status == OrderStatus.preparing ||
                              order.status == OrderStatus.accepted)
                          ? Colors.orange.shade700
                          : Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Restaurant Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.restaurant,
                          color: Colors.orange.shade700, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppLocalizations.of(context)!.restaurant,
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey)),
                          const SizedBox(height: 2),
                          FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('vendors')
                                .doc(order.restaurantId)
                                .get(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Text(
                                    AppLocalizations.of(context)!.loading,
                                    style: const TextStyle(fontSize: 14));
                              }
                              final data = snapshot.data?.data()
                                  as Map<String, dynamic>?;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data?['name'] ??
                                        AppLocalizations.of(context)!
                                            .unknownRestaurant,
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  if (data?['address'] != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      data!['address'],
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      const SizedBox(width: 19),
                      Container(
                          width: 2, height: 24, color: Colors.grey.shade300),
                    ],
                  ),
                ),
                // Customer row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.person_pin_circle,
                          color: Colors.green.shade700, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppLocalizations.of(context)!.customer,
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text(
                            DriverRequestsTab._resolveAddress(
                                order.deliveryAddress,
                                order.deliveryLat,
                                order.deliveryLng,
                                AppLocalizations.of(context)!
                                    .noAddressProvided),
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      icon: Icons.phone,
                      color: const Color(0xFF16A34A),
                      tooltip: AppLocalizations.of(context)!.callCustomer,
                      onTap: _callCustomer,
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      icon: Icons.info_outline,
                      color: Colors.blue,
                      tooltip: AppLocalizations.of(context)!.viewDetails,
                      onTap: _showOrderDetailsBottomSheet,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Order details row
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildMiniStat(
                    Icons.shopping_bag_outlined,
                    '${order.items.length}',
                    AppLocalizations.of(context)!.items,
                    Colors.blue),
                Container(width: 1, height: 32, color: Colors.grey.shade200),
                _buildMiniStat(
                    Icons.payments_outlined,
                    AppLocalizations.of(context)!
                        .egpAmount(order.deliveryFee.toStringAsFixed(0)),
                    AppLocalizations.of(context)!.deliveryFee,
                    Colors.green),
                Container(width: 1, height: 32, color: Colors.grey.shade200),
                _buildMiniStat(
                    Icons.receipt_long,
                    AppLocalizations.of(context)!
                        .egpAmount(order.total.toStringAsFixed(0)),
                    AppLocalizations.of(context)!.total,
                    Colors.orange),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action Buttons: Open Map (In-App) & Directions (Google Maps)
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider<DriverDashboardCubit>.value(
                          value: context.read<DriverDashboardCubit>(),
                          child: DriverTrackingScreen(order: order),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.map, size: 20),
                  label: Text(
                    AppLocalizations.of(context)!.openMap,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF35535),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _openGoogleMapsDirections,
                  icon: const Icon(Icons.navigation_rounded, size: 20),
                  label: Text(
                    AppLocalizations.of(context)!.startNavigation,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ActiveOrderCard extends StatefulWidget {
  final Order order;
  const ActiveOrderCard({super.key, required this.order});

  @override
  State<ActiveOrderCard> createState() => _ActiveOrderCardState();
}

class _ActiveOrderCardState extends State<ActiveOrderCard> {
  AppUser? _customerUser;
  Restaurant? _restaurant;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  @override
  void didUpdateWidget(ActiveOrderCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.order.id != oldWidget.order.id) {
      _loadDetails();
    }
  }

  Future<void> _loadDetails() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final customerId = widget.order.customerId;
      if (customerId.isNotEmpty) {
        final custDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(customerId)
            .get();
        if (custDoc.exists && mounted) {
          setState(() {
            _customerUser = AppUser.fromMap(custDoc.data()!, custDoc.id);
          });
        }
      }
      final restaurantId = widget.order.restaurantId;
      if (restaurantId.isNotEmpty) {
        final restDoc = await FirebaseFirestore.instance
            .collection('vendors')
            .doc(restaurantId)
            .get();
        if (restDoc.exists && mounted) {
          setState(() {
            _restaurant = Restaurant.fromMap(restDoc.data()!, restDoc.id);
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading active order card details: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Map<String, String> _parseAddressDetails(String address) {
    final Map<String, String> details = {};
    final typeIndex = address.indexOf('(');
    if (typeIndex != -1) {
      details['Type'] = address.substring(0, typeIndex).trim();
    }
    final startParenthesis = address.indexOf('(');
    final endParenthesis = address.indexOf(')');
    if (startParenthesis != -1 && endParenthesis != -1 && endParenthesis > startParenthesis) {
      final innerText = address.substring(startParenthesis + 1, endParenthesis);
      final parts = innerText.split(RegExp(r'[,،]'));
      for (var part in parts) {
        final kv = part.split(':');
        if (kv.length >= 2) {
          final key = kv[0].trim();
          final val = kv.sublist(1).join(':').trim();
          details[key] = val;
        }
      }
    }
    final areaIndex = address.indexOf(RegExp(r'\)\.\s*(?:Area|المنطقة)\s*:'));
    if (areaIndex != -1) {
      final labelIndex = address.indexOf(':', areaIndex);
      if (labelIndex != -1) {
        details['Area'] = address.substring(labelIndex + 1).trim();
      }
    }
    return details;
  }

  String? _extractPhoneFromAddress(String address) {
    final phoneRegex = RegExp(r'(?:Phone:|هاتف:)\s*([+\d\s-]+)');
    final match = phoneRegex.firstMatch(address);
    if (match != null) {
      final phone = match.group(1)?.trim();
      if (phone != null) {
        final cleanPhone = phone.split(')').first.split(',').first.split('،').first.trim();
        if (cleanPhone.isNotEmpty) {
          return cleanPhone;
        }
      }
    }
    return null;
  }

  Future<void> _callNumber(String phoneNumber) async {
    final Uri url = Uri(scheme: 'tel', path: phoneNumber);
    try {
      await launchUrl(url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.couldNotCall(phoneNumber, e.toString()))),
        );
      }
    }
  }

  Future<void> _openGoogleMapsDirections() async {
    final order = widget.order;
    final isHeadingToRestaurant = order.status == OrderStatus.driverAssigned ||
        order.status == OrderStatus.preparing ||
        order.status == OrderStatus.ready ||
        order.status == OrderStatus.accepted;

    double lat = order.deliveryLat;
    double lng = order.deliveryLng;

    if (isHeadingToRestaurant) {
      Restaurant? rest = _restaurant;
      if (rest == null && order.restaurantId.isNotEmpty) {
        try {
          final doc = await FirebaseFirestore.instance
              .collection('vendors')
              .doc(order.restaurantId)
              .get();
          if (doc.exists) {
            rest = Restaurant.fromMap(doc.data()!, doc.id);
          }
        } catch (e) {
          debugPrint('Error fetching restaurant for directions: $e');
        }
      }
      if (rest != null) {
        lat = rest.latitude;
        lng = rest.longitude;
      }
    }

    if (lat == 0.0 && lng == 0.0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.coordinatesNotAvailable)),
        );
      }
      return;
    }

    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
    );
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.couldNotOpenMap(e.toString()))),
        );
      }
    }
  }

  String _localizeAddressKey(String key, AppLocalizations l10n) {
    final lowerKey = key.toLowerCase();
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    if (lowerKey.contains('building') || lowerKey.contains('مبنى')) {
      return isAr ? 'مبنى' : 'Building';
    }
    if (lowerKey.contains('apt') || lowerKey.contains('apartment') || lowerKey.contains('شقة')) {
      return isAr ? 'شقة' : 'Apartment';
    }
    if (lowerKey.contains('floor') || lowerKey.contains('دور')) {
      return isAr ? 'دور' : 'Floor';
    }
    if (lowerKey.contains('street') || lowerKey.contains('شارع')) {
      return isAr ? 'شارع' : 'Street';
    }
    if (lowerKey.contains('landmark') || lowerKey.contains('علامة')) {
      return isAr ? 'علامة مميزة' : 'Landmark';
    }
    if (lowerKey.contains('phone') || lowerKey.contains('هاتف')) {
      return isAr ? 'هاتف' : 'Phone';
    }
    if (lowerKey.contains('area') || lowerKey.contains('منطقة')) {
      return isAr ? 'المنطقة' : 'Area';
    }
    if (lowerKey.contains('type')) {
      return isAr ? 'النوع' : 'Type';
    }
    return key;
  }

  void _showOrderDetailsBottomSheet(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final parsedAddress = _parseAddressDetails(widget.order.deliveryAddress);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.orderDetails,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      children: [
                        _buildSummaryCard(theme, l10n),
                        const SizedBox(height: 16),
                        _buildCustomerDetailsCard(theme, l10n, parsedAddress),
                        const SizedBox(height: 16),
                        if (_restaurant != null) ...[
                          _buildRestaurantDetailsCard(theme, l10n),
                          const SizedBox(height: 16),
                        ],
                        _buildItemsCard(theme, l10n),
                        const SizedBox(height: 16),
                        _buildPaymentCard(theme, l10n),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSummaryCard(ThemeData theme, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ID: ${widget.order.id.substring(0, 8).toUpperCase()}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Created: ${_formatTime(widget.order.createdAt)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              widget.order.status.getLocalizedLabel(l10n),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: theme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildCustomerDetailsCard(
    ThemeData theme,
    AppLocalizations l10n,
    Map<String, String> parsedAddress,
  ) {
    final customerPhone = _customerUser?.phone ?? _extractPhoneFromAddress(widget.order.deliveryAddress) ?? '';
    final customerName = _customerUser?.name ?? l10n.customer;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  l10n.customer,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      if (customerPhone.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          customerPhone,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (customerPhone.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.phone, color: Colors.green),
                    onPressed: () => _callNumber(customerPhone),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Delivery Address',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 6),
            if (parsedAddress.isNotEmpty) ...[
              ...parsedAddress.entries.map((entry) {
                final localizedKey = _localizeAddressKey(entry.key, l10n);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 100,
                        child: Text(
                          '$localizedKey:',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ] else ...[
              Text(
                widget.order.deliveryAddress,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 13,
                ),
              ),
            ],
            if (widget.order.customerNote != null && widget.order.customerNote!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade100),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.note_alt_outlined, color: Colors.orange, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Note: ${widget.order.customerNote}',
                        style: TextStyle(
                          color: Colors.orange.shade900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantDetailsCard(ThemeData theme, AppLocalizations l10n) {
    if (_restaurant == null) return const SizedBox.shrink();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.restaurant, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  l10n.restaurant,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _restaurant!.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      if (_restaurant!.phone.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          _restaurant!.phone,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (_restaurant!.phone.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.phone, color: Colors.orange),
                    onPressed: () => _callNumber(_restaurant!.phone),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _restaurant!.address,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsCard(ThemeData theme, AppLocalizations l10n) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shopping_bag_outlined, color: theme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  l10n.itemsInOrder,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.order.items.length,
              separatorBuilder: (context, index) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final item = widget.order.items[index];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${item.quantity}x',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          if (item.optionsSummary != null && item.optionsSummary!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              item.optionsSummary!,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Text(
                      l10n.egpAmount(item.totalPrice.toStringAsFixed(2)),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(ThemeData theme, AppLocalizations l10n) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.payment, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  l10n.paymentDetails,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Payment Method',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                Text(
                  widget.order.paymentMethod.getLocalizedLabel(l10n),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Payment Status',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                Text(
                  widget.order.paymentStatus.getLocalizedLabel(l10n),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  l10n.egpAmount(widget.order.total.toStringAsFixed(2)),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: theme.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final order = widget.order;

    final isHeadingToRestaurant = order.status == OrderStatus.driverAssigned ||
        order.status == OrderStatus.preparing ||
        order.status == OrderStatus.ready ||
        order.status == OrderStatus.accepted;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Header with status indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: isHeadingToRestaurant
                  ? Colors.orange.shade50
                  : Colors.green.shade50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isHeadingToRestaurant
                            ? Icons.restaurant
                            : Icons.person_pin_circle,
                        color: isHeadingToRestaurant
                            ? Colors.orange.shade700
                            : Colors.green.shade700,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Order #${order.id.substring(0, 8).toUpperCase()}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isHeadingToRestaurant
                          ? Colors.orange.shade600
                          : Colors.green.shade600,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isHeadingToRestaurant
                          ? l10n.toRestaurant
                          : l10n.toCustomer,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: _loading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Restaurant info
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.storefront_outlined,
                                size: 18, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _restaurant?.name ?? l10n.unknownRestaurant,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Customer Address info
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on_outlined,
                                size: 18, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                DriverRequestsTab._resolveAddress(
                                    order.deliveryAddress,
                                    order.deliveryLat,
                                    order.deliveryLng,
                                    l10n.noAddressProvided),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        // Price and items info row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${l10n.itemsInOrder}: ${order.items.length}',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade600),
                            ),
                            Text(
                              '${l10n.deliveryFee}: ${l10n.egpAmount(order.deliveryFee.toStringAsFixed(0))}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  _showOrderDetailsBottomSheet(context);
                                },
                                icon:
                                    const Icon(Icons.info_outline, size: 16),
                                label: Text(l10n.viewDetails),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BlocProvider<
                                          DriverDashboardCubit>.value(
                                        value: context
                                            .read<DriverDashboardCubit>(),
                                        child:
                                            DriverTrackingScreen(order: order),
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.map, size: 16),
                                label: Text(l10n.openMap),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF35535),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Tooltip(
                              message: 'Google Maps Directions',
                              child: Material(
                                color: const Color(0xFF16A34A),
                                borderRadius: BorderRadius.circular(8),
                                child: InkWell(
                                  onTap: _openGoogleMapsDirections,
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.directions_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
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
  }
}
