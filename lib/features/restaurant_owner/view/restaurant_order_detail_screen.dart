import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:z_speed/core/enums/driver_enums.dart';
import 'package:z_speed/core/enums/order_enums.dart';
import 'package:z_speed/features/driver/model/order_driver.dart';
import 'package:z_speed/features/order/model/order.dart';
import 'package:z_speed/features/order/model/order_item_summary.dart';
import 'package:z_speed/features/order/model/order_item.dart';
import 'package:z_speed/features/restaurant_owner/view/driver_tracking_screen.dart';
import 'package:z_speed/features/restaurant_owner/cubit/restaurant_orders_cubit.dart';
import 'package:z_speed/features/restaurant_owner/cubit/restaurant_orders_state.dart';
import 'package:z_speed/features/shared/widgets/shared_order_summary_widget.dart';
import 'package:z_speed/features/restaurant_owner/widgets/driver_assignment_dialog.dart';
import 'package:z_speed/features/restaurant_owner/widgets/search_progress_widget.dart';
import 'package:z_speed/features/restaurant_owner/utils/order_receipt_printer.dart';
import 'package:z_speed/features/restaurant_owner/utils/order_receipt_labels.dart';
import 'package:z_speed/features/restaurant_owner/widgets/receipt_print_language_dialog.dart';
import 'package:intl/intl.dart';
import 'package:z_speed/components/address_text.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:z_speed/features/auth/model/user_model.dart';
import 'package:url_launcher/url_launcher.dart';

class RestaurantOrderDetailScreen extends StatefulWidget {
  final Order initialOrder;
  final RestaurantOrdersCubit cubit;

  const RestaurantOrderDetailScreen({
    super.key,
    required this.initialOrder,
    required this.cubit,
  });

  @override
  State<RestaurantOrderDetailScreen> createState() =>
      _RestaurantOrderDetailScreenState();
}

class _RestaurantOrderDetailScreenState
    extends State<RestaurantOrderDetailScreen> {
  Future<List<OrderItem>?>? _orderItemsFuture;
  AppUser? _customerUser;
  List<OrderItem>? _fetchedItems;

  String _getItemName(dynamic item) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    if (item is OrderItemSummary) {
      return isArabic
          ? (item.nameAr ?? widget.cubit.state.itemTranslations[item.menuItemId] ?? item.name)
          : item.name;
    } else if (item is OrderItem) {
      return isArabic
          ? (item.menuItemNameAr ?? widget.cubit.state.itemTranslations[item.menuItemId] ?? item.menuItemName)
          : item.menuItemName;
    }
    return '';
  }

  double _getItemQuantity(dynamic item) {
    if (item is OrderItemSummary) {
      return item.quantity.toDouble();
    } else if (item is OrderItem) {
      return item.quantity;
    }
    return 0.0;
  }

  double _getItemTotalPrice(dynamic item) {
    if (item is OrderItemSummary) {
      return item.totalPrice;
    } else if (item is OrderItem) {
      return item.itemTotal;
    }
    return 0.0;
  }

  String _getItemOptionsSummary(dynamic item) {
    if (item is OrderItemSummary) {
      return item.optionsSummary ?? '';
    } else if (item is OrderItem) {
      final List<String> parts = [];
      if (item.selectedVariantName != null && item.selectedVariantName!.isNotEmpty) {
        parts.add(item.selectedVariantName!);
      }
      for (final addon in item.selectedAddons) {
        parts.add(addon.optionName);
      }
      return parts.join(', ');
    }
    return '';
  }

  @override
  void initState() {
    super.initState();
    _fetchCustomerDetails();
    _orderItemsFuture = widget.cubit.getOrderItems(widget.initialOrder.id).then((items) {
      if (mounted) {
        setState(() {
          _fetchedItems = items;
        });
      }
      return items;
    });
  }

  Future<void> _fetchCustomerDetails() async {
    try {
      final customerId = widget.initialOrder.customerId;
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
          SnackBar(content: Text('Could not call $phoneNumber: $e')),
        );
      }
    }
  }

  void _callCustomer() {
    final phone = (_customerUser?.phone?.isNotEmpty == true ? _customerUser?.phone : null) ??
        widget.initialOrder.customerPhone ??
        _extractPhoneFromAddress(widget.initialOrder.deliveryAddress);
    if (phone != null && phone.isNotEmpty) {
      _callNumber(phone);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)?.errorOccurred ?? 'Customer phone number not available')),
      );
    }
  }

  void _showOrderDetailsBottomSheet() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final parsedAddress = _parseAddressDetails(widget.initialOrder.deliveryAddress);

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
                'ID: ${widget.initialOrder.id.substring(0, 8).toUpperCase()}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Created: ${_formatTime(widget.initialOrder.createdAt)}',
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
              widget.initialOrder.status.getLocalizedLabel(l10n),
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
    final customerPhone = (_customerUser?.phone?.isNotEmpty == true ? _customerUser?.phone : null) ??
        widget.initialOrder.customerPhone ??
        _extractPhoneFromAddress(widget.initialOrder.deliveryAddress) ??
        '';
    final customerName = (_customerUser?.name.isNotEmpty == true ? _customerUser?.name : null) ??
        widget.initialOrder.customerName ??
        l10n.customer;

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
                      const SizedBox(height: 4),
                      Text(
                        customerPhone.isNotEmpty ? customerPhone : 'No phone number provided',
                        style: TextStyle(
                          color: customerPhone.isNotEmpty ? Colors.grey.shade600 : Colors.red.shade400,
                          fontSize: 13,
                          fontStyle: customerPhone.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.phone, color: customerPhone.isNotEmpty ? Colors.green : Colors.grey),
                  onPressed: () {
                    if (customerPhone.isNotEmpty) {
                      _callNumber(customerPhone);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Customer phone number is not available.')),
                      );
                    }
                  },
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
                widget.initialOrder.deliveryAddress,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 13,
                ),
              ),
            ],
            if (widget.initialOrder.customerNote != null && widget.initialOrder.customerNote!.isNotEmpty) ...[
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
                        'Note: ${widget.initialOrder.customerNote}',
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

  Widget _buildItemsCard(ThemeData theme, AppLocalizations l10n) {
    final itemsList = _fetchedItems ?? widget.initialOrder.items;
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
            if (itemsList.isEmpty)
              const Center(child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ))
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: itemsList.length,
                separatorBuilder: (context, index) => const Divider(height: 16),
                itemBuilder: (context, index) {
                  final dynamic item = itemsList[index];
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
                          '${_getItemQuantity(item).toStringAsFixed(0)}x',
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
                              _getItemName(item),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            if (_getItemOptionsSummary(item).isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                _getItemOptionsSummary(item),
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
                        l10n.egpAmount(_getItemTotalPrice(item).toStringAsFixed(2)),
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
                  widget.initialOrder.paymentMethod.getLocalizedLabel(l10n),
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
                  widget.initialOrder.paymentStatus.getLocalizedLabel(l10n),
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
                  l10n.egpAmount(widget.initialOrder.total.toStringAsFixed(2)),
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
    return BlocProvider.value(
      value: widget.cubit,
      child: BlocBuilder<RestaurantOrdersCubit, RestaurantOrdersState>(
        builder: (context, state) {
          final order = state.allOrders.firstWhere(
            (o) => o.id == widget.initialOrder.id,
            orElse: () => widget.initialOrder,
          );

          final isProcessing = state.isProcessingOrder(order.id);

          return Scaffold(
            appBar: AppBar(
              title: Text(AppLocalizations.of(context)!
                  .orderWithId(order.id.substring(0, 8).toUpperCase())),
              actions: [
                if (kIsWeb || defaultTargetPlatform == TargetPlatform.android)
                  IconButton(
                    icon: const Icon(Icons.print_outlined),
                    tooltip: 'Print Receipt',
                    onPressed: () => _printReceipt(order),
                  ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStatusHeader(order),
                  const SizedBox(height: 24),

                  // FutureBuilder handles the fetching state gracefully
                  FutureBuilder<List<OrderItem>?>(
                    future: _orderItemsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Card(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        );
                      }

                      final items = snapshot.data ?? [];
                      return SharedOrderSummaryWidget(
                        order: order,
                        items: items,
                        itemTranslations: state.itemTranslations,
                      );
                    },
                  ),

                  const SizedBox(height: 24),
                  _buildDeliveryInfo(order),
                  const SizedBox(height: 24),
                  _buildActionButtons(context, order, isProcessing),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusHeader(Order order) {
    final statusColor = _getStatusColor(order.status);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLocalizations.of(context)!.status,
                        style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(
                      order.status
                          .getLocalizedLabel(AppLocalizations.of(context)!),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                Icon(Icons.receipt_long, color: statusColor, size: 40),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppLocalizations.of(context)!.placedAt,
                    style: const TextStyle(color: Colors.grey)),
                Text(
                  DateFormat('MMM dd, h:mm a').format(order.createdAt),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppLocalizations.of(context)!.paymentMethod,
                    style: const TextStyle(color: Colors.grey)),
                Row(
                  children: [
                    Icon(
                      order.paymentMethod == PaymentMethodType.cash
                          ? Icons.money
                          : Icons.credit_card,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      order.paymentMethod
                          .getLocalizedLabel(AppLocalizations.of(context)!),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryInfo(Order order) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.deliveryDetails,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Customer Row
            Builder(
              builder: (context) {
                final customerPhone = (_customerUser?.phone?.isNotEmpty == true ? _customerUser?.phone : null) ??
                    order.customerPhone ??
                    _extractPhoneFromAddress(order.deliveryAddress) ??
                    '';
                final customerName = (_customerUser?.name.isNotEmpty == true ? _customerUser?.name : null) ??
                    order.customerName ??
                    AppLocalizations.of(context)!.customer;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.person, color: Colors.green.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.customer,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            customerName,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            customerPhone.isNotEmpty ? customerPhone : 'No phone number provided',
                            style: TextStyle(
                              fontSize: 13,
                              color: customerPhone.isNotEmpty ? Colors.grey.shade600 : Colors.red.shade400,
                              fontStyle: customerPhone.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                            ),
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
                );
              },
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            // Location Row
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: AddressText(
                    address: order.deliveryAddress,
                    lat: order.deliveryLat,
                    lng: order.deliveryLng,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            // Stream assigned drivers
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
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
                    .where(
                        (od) => od.status != DriverAssignmentStatus.cancelled)
                    .toList();

                if (drivers.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(height: 24),
                    Text(
                      AppLocalizations.of(context)!
                          .assignedDriversCount(drivers.length),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...drivers.map((od) => _buildDriverCard(od, order)),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverCard(OrderDriver od, Order order) {
    final statusColor = _getDriverStatusColor(od.status);
    final statusLabel = _getDriverStatusLabel(context, od.status);
    final statusIcon = _getDriverStatusIcon(od.status);

    return Container(
      margin: const EdgeInsetsDirectional.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.teal.shade100,
                child: const Icon(Icons.person, size: 16, color: Colors.teal),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  od.driverName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 13, color: statusColor),
                    const SizedBox(width: 3),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Rejection reason
          if (od.status == DriverAssignmentStatus.rejected &&
              od.rejectionReason != null) ...[
            const SizedBox(height: 6),
            Text(
              AppLocalizations.of(context)!.reason(od.rejectionReason ?? ''),
              style: TextStyle(fontSize: 12, color: Colors.red.shade700),
            ),
          ],
          // Track button
          if (od.status == DriverAssignmentStatus.accepted ||
              od.status == DriverAssignmentStatus.pickedUp) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  final cubit = widget.cubit;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DriverTrackingScreen(
                        driverUserId: od.driverUserId,
                        driverName: od.driverName,
                        restaurantLat:
                            cubit.state.currentRestaurant?.latitude ?? 0,
                        restaurantLng:
                            cubit.state.currentRestaurant?.longitude ?? 0,
                        restaurantName:
                            cubit.state.currentRestaurant?.name ?? '',
                        orderId: order.id,
                        deliveryLat: order.deliveryLat,
                        deliveryLng: order.deliveryLng,
                        initialOrderStatus: order.status,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.map, size: 16),
                label: Text(AppLocalizations.of(context)!.trackDriver),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.teal,
                  side: const BorderSide(color: Colors.teal),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getDriverStatusColor(DriverAssignmentStatus status) {
    switch (status) {
      case DriverAssignmentStatus.pending:
        return Colors.orange;
      case DriverAssignmentStatus.accepted:
        return Colors.green;
      case DriverAssignmentStatus.rejected:
        return Colors.red;
      case DriverAssignmentStatus.cancelled:
        return Colors.grey;
      case DriverAssignmentStatus.pickedUp:
        return Colors.blue;
      case DriverAssignmentStatus.delivered:
        return Colors.green;
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

  IconData _getDriverStatusIcon(DriverAssignmentStatus status) {
    switch (status) {
      case DriverAssignmentStatus.pending:
        return Icons.hourglass_empty;
      case DriverAssignmentStatus.accepted:
        return Icons.check_circle;
      case DriverAssignmentStatus.rejected:
        return Icons.cancel;
      case DriverAssignmentStatus.cancelled:
        return Icons.block;
      case DriverAssignmentStatus.pickedUp:
        return Icons.shopping_bag;
      case DriverAssignmentStatus.delivered:
        return Icons.done_all;
    }
  }

  Widget _buildActionButtons(
      BuildContext context, Order order, bool isProcessing) {
    if (isProcessing) {
      return const Center(child: CircularProgressIndicator());
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
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showRejectDialog(context, order.id),
                icon: const Icon(Icons.cancel_outlined, size: 18),
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
                  padding: const EdgeInsets.symmetric(vertical: 16),
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
                label: Text(AppLocalizations.of(context)!.markAsReadyFor),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        );

      case OrderStatus.ready:
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('orders')
              .doc(order.id)
              .collection('orderDrivers')
              .snapshots(),
          builder: (context, snapshot) {
            // Check if there's any active (non-cancelled, non-rejected) driver
            final hasActiveDriver = snapshot.hasData &&
                snapshot.data!.docs.any((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final status = data['status'] as String? ?? 'pending';
                  return status != 'cancelled' && status != 'rejected';
                });

            if (hasActiveDriver) {
              return Center(
                child: Text(
                  AppLocalizations.of(context)!.awaitingDriverPickup,
                  style: const TextStyle(color: Colors.grey),
                ),
              );
            }

            return Column(
              children: [
                Center(
                  child: Text(
                    AppLocalizations.of(context)!.readyAssignDriver,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _startAutoDispatch(order.id),
                    icon: const Icon(Icons.flash_on, size: 18),
                    label: const Text('Start Auto-Dispatch'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
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
          onRetry: () => widget.cubit.markReady(order.id),
          onManualAssign: () => _showDriverAssignmentDialog(context, order),
        );

      default:
        // No actionable operations for delivered/cancelled/tracking states
        return const SizedBox.shrink();
    }
  }

  void _acceptOrder(String orderId) async {
    final success = await widget.cubit.acceptOrder(orderId);
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
    final success = await widget.cubit.startPreparing(orderId);
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
    final success = await widget.cubit.markReady(orderId);
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
    final isAlreadySearching = widget.cubit.state.allOrders.any(
      (o) => o.id == orderId && o.status == OrderStatus.searching,
    );
    if (!isAlreadySearching) {
      await widget.cubit.startSearching(orderId);
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

  void _showRejectDialog(BuildContext context, String orderId) {
    String? selectedReason;
    final l10n = AppLocalizations.of(context)!;
    final reasons = [
      l10n.itemsNotAvailable,
      l10n.tooBusy,
      l10n.closingSoon,
      l10n.duplicateOrder,
      l10n.other,
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
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
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            ElevatedButton(
              onPressed: selectedReason == null
                  ? null
                  : () async {
                      Navigator.pop(ctx);
                      final success = await widget.cubit
                          .rejectOrder(orderId, selectedReason!);
                      if (!context.mounted) return;
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                AppLocalizations.of(context)!.orderRejected),
                            backgroundColor: Colors.red,
                          ),
                        );
                        Navigator.pop(context); // Close details view
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

  void _showDriverAssignmentDialog(BuildContext context, Order order) {
    if (widget.cubit.state.currentRestaurant == null) {
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
        restaurant: widget.cubit.state.currentRestaurant!,
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

  Future<void> _printReceipt(Order order) async {
    String? customerName = _customerUser?.name ?? order.customerName;
    String? customerPhone = _customerUser?.phone ?? order.customerPhone;

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

    // Show a loading indicator while resolving item translations
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
    }
    final itemTranslations = await _resolveItemTranslations(order, language);
    if (mounted) {
      Navigator.pop(context);
    }

    final restaurantName = widget.cubit.state.currentRestaurant?.name ?? 'Vendor';
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
        orderItems: _fetchedItems,
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
}
