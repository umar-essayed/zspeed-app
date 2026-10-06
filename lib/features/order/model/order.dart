import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:z_speed/core/enums/order_enums.dart';
import 'package:z_speed/features/order/model/order_item_summary.dart';

/// A customer order.
///
/// Firestore path: `orders/{orderId}`
class Order extends Equatable {
  final String id;
  final String customerId;
  final String? customerName;
  final String? customerPhone;
  final String restaurantId;
  final String? driverId;
  final List<String> driverIds;
  final OrderStatus status;
  final List<OrderItemSummary> items;
  final double subtotal;
  final double deliveryFee;
  final double tax;
  final double serviceFee;
  final double discount;
  final String? appliedPromoCode;
  final String? discountType;
  final double total;
  final String deliveryAddress;
  final double deliveryLat;
  final double deliveryLng;
  final String? customerNote;
  final String? driverNote;
  final PaymentMethodType paymentMethod;
  final String? paymentId;
  final PaymentStatus paymentStatus;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? preparingAt;
  final DateTime? readyAt;
  final DateTime? driverAssignedAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final String? cancelledBy; // 'customer', 'restaurant', 'vendor', 'driver', 'admin'
  final String? statusUpdatedBy; // 'customer', 'restaurant', 'vendor', 'driver', 'admin'
  final DateTime updatedAt;
  final double? deliveryFeePerDriver;
  final double? refundAmount;
  final String? refundStatus;
  final String? refundInitiator;

  const Order({
    required this.id,
    required this.customerId,
    this.customerName,
    this.customerPhone,
    required this.restaurantId,
    this.driverId,
    this.driverIds = const [],
    this.status = OrderStatus.pending,
    this.items = const [],
    required this.subtotal,
    required this.deliveryFee,
    this.tax = 0.0,
    this.serviceFee = 0.0,
    this.discount = 0.0,
    this.appliedPromoCode,
    this.discountType,
    required this.total,
    required this.deliveryAddress,
    required this.deliveryLat,
    required this.deliveryLng,
    this.customerNote,
    this.driverNote,
    this.paymentMethod = PaymentMethodType.cash,
    this.paymentId,
    this.paymentStatus = PaymentStatus.pending,
    required this.createdAt,
    this.acceptedAt,
    this.preparingAt,
    this.readyAt,
    this.driverAssignedAt,
    this.pickedUpAt,
    this.deliveredAt,
    this.cancelledAt,
    this.cancellationReason,
    this.cancelledBy,
    this.statusUpdatedBy,
    required this.updatedAt,
    this.deliveryFeePerDriver,
    this.refundAmount,
    this.refundStatus,
    this.refundInitiator,
  });

  factory Order.fromMap(Map<String, dynamic> map, String documentId) {
    return Order(
      id: documentId,
      customerId: map['customerId'] as String? ?? '',
      customerName: map['customerName'] as String?,
      customerPhone: map['customerPhone'] as String?,
      restaurantId:
          map['restaurantId'] as String? ?? map['vendorId'] as String? ?? '',
      driverId: map['driverId'] as String?,
      driverIds: List<String>.from(map['driverIds'] ?? []),
      status: OrderStatusX.fromKey(map['status'] as String? ?? 'pending'),
      items: (map['items'] as List<dynamic>?)
              ?.whereType<Map>()
              .map(
                  (e) => OrderItemSummary.fromMap(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (map['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      tax: (map['tax'] as num?)?.toDouble() ?? 0.0,
      serviceFee: (map['serviceFee'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      appliedPromoCode: map['appliedPromoCode'] as String?,
      discountType: map['discountType'] as String?,
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      deliveryAddress: map['deliveryAddress'] as String? ?? '',
      deliveryLat: (map['deliveryLat'] as num?)?.toDouble() ?? 0.0,
      deliveryLng: (map['deliveryLng'] as num?)?.toDouble() ?? 0.0,
      customerNote: map['customerNote'] as String?,
      driverNote: map['driverNote'] as String?,
      paymentMethod:
          PaymentMethodTypeX.fromKey(map['paymentMethod'] as String? ?? 'cash'),
      paymentId: map['paymentId'] as String?,
      paymentStatus:
          PaymentStatusX.fromKey(map['paymentStatus'] as String? ?? 'pending'),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      acceptedAt: (map['acceptedAt'] as Timestamp?)?.toDate(),
      preparingAt: (map['preparingAt'] as Timestamp?)?.toDate(),
      readyAt: (map['readyAt'] as Timestamp?)?.toDate(),
      driverAssignedAt: (map['driverAssignedAt'] as Timestamp?)?.toDate(),
      pickedUpAt: (map['pickedUpAt'] as Timestamp?)?.toDate(),
      deliveredAt: (map['deliveredAt'] as Timestamp?)?.toDate(),
      cancelledAt: (map['cancelledAt'] as Timestamp?)?.toDate(),
      cancellationReason: map['cancellationReason'] as String?,
      cancelledBy: map['cancelledBy'] as String?,
      statusUpdatedBy: map['statusUpdatedBy'] as String?,
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      deliveryFeePerDriver: (map['deliveryFeePerDriver'] as num?)?.toDouble(),
      refundAmount: (map['refundAmount'] as num?)?.toDouble(),
      refundStatus: map['refundStatus'] as String?,
      refundInitiator: map['refundInitiator'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      if (customerName != null) 'customerName': customerName,
      if (customerPhone != null) 'customerPhone': customerPhone,
      'restaurantId': restaurantId,
      'vendorId': restaurantId,
      'driverId': driverId,
      'driverIds': driverIds,
      'status': status.key,
      'items': items.map((i) => i.toMap()).toList(),
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'tax': tax,
      'serviceFee': serviceFee,
      'discount': discount,
      if (appliedPromoCode != null) 'appliedPromoCode': appliedPromoCode,
      if (discountType != null) 'discountType': discountType,
      'total': total,
      'deliveryAddress': deliveryAddress,
      'deliveryLat': deliveryLat,
      'deliveryLng': deliveryLng,
      'customerNote': customerNote,
      'driverNote': driverNote,
      'paymentMethod': paymentMethod.key,
      'paymentId': paymentId,
      'paymentStatus': paymentStatus.key,
      'createdAt': Timestamp.fromDate(createdAt),
      'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
      'preparingAt':
          preparingAt != null ? Timestamp.fromDate(preparingAt!) : null,
      'readyAt': readyAt != null ? Timestamp.fromDate(readyAt!) : null,
      'driverAssignedAt': driverAssignedAt != null
          ? Timestamp.fromDate(driverAssignedAt!)
          : null,
      'pickedUpAt': pickedUpAt != null ? Timestamp.fromDate(pickedUpAt!) : null,
      'deliveredAt':
          deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
      'cancelledAt':
          cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'cancellationReason': cancellationReason,
      'cancelledBy': cancelledBy,
      if (statusUpdatedBy != null) 'statusUpdatedBy': statusUpdatedBy,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'deliveryFeePerDriver': deliveryFeePerDriver,
      if (refundAmount != null) 'refundAmount': refundAmount,
      if (refundStatus != null) 'refundStatus': refundStatus,
      if (refundInitiator != null) 'refundInitiator': refundInitiator,
    };
  }

  Order copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? restaurantId,
    String? driverId,
    List<String>? driverIds,
    OrderStatus? status,
    List<OrderItemSummary>? items,
    double? subtotal,
    double? deliveryFee,
    double? tax,
    double? serviceFee,
    double? discount,
    String? appliedPromoCode,
    String? discountType,
    double? total,
    String? deliveryAddress,
    double? deliveryLat,
    double? deliveryLng,
    String? customerNote,
    String? driverNote,
    PaymentMethodType? paymentMethod,
    String? paymentId,
    PaymentStatus? paymentStatus,
    DateTime? createdAt,
    DateTime? acceptedAt,
    DateTime? preparingAt,
    DateTime? readyAt,
    DateTime? driverAssignedAt,
    DateTime? pickedUpAt,
    DateTime? deliveredAt,
    DateTime? cancelledAt,
    String? cancellationReason,
    String? cancelledBy,
    String? statusUpdatedBy,
    DateTime? updatedAt,
    double? deliveryFeePerDriver,
    double? refundAmount,
    String? refundStatus,
    String? refundInitiator,
  }) {
    return Order(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      restaurantId: restaurantId ?? this.restaurantId,
      driverId: driverId ?? this.driverId,
      driverIds: driverIds ?? this.driverIds,
      status: status ?? this.status,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      tax: tax ?? this.tax,
      serviceFee: serviceFee ?? this.serviceFee,
      discount: discount ?? this.discount,
      appliedPromoCode: appliedPromoCode ?? this.appliedPromoCode,
      discountType: discountType ?? this.discountType,
      total: total ?? this.total,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryLat: deliveryLat ?? this.deliveryLat,
      deliveryLng: deliveryLng ?? this.deliveryLng,
      customerNote: customerNote ?? this.customerNote,
      driverNote: driverNote ?? this.driverNote,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentId: paymentId ?? this.paymentId,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      preparingAt: preparingAt ?? this.preparingAt,
      readyAt: readyAt ?? this.readyAt,
      driverAssignedAt: driverAssignedAt ?? this.driverAssignedAt,
      pickedUpAt: pickedUpAt ?? this.pickedUpAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      statusUpdatedBy: statusUpdatedBy ?? this.statusUpdatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
      deliveryFeePerDriver: deliveryFeePerDriver ?? this.deliveryFeePerDriver,
      refundAmount: refundAmount ?? this.refundAmount,
      refundStatus: refundStatus ?? this.refundStatus,
      refundInitiator: refundInitiator ?? this.refundInitiator,
    );
  }

  @override
  List<Object?> get props => [
        id,
        customerId,
        customerName,
        customerPhone,
        restaurantId,
        driverId,
        driverIds,
        status,
        items,
        subtotal,
        deliveryFee,
        tax,
        serviceFee,
        discount,
        appliedPromoCode,
        discountType,
        total,
        deliveryAddress,
        deliveryLat,
        deliveryLng,
        customerNote,
        driverNote,
        paymentMethod,
        paymentId,
        paymentStatus,
        createdAt,
        acceptedAt,
        preparingAt,
        readyAt,
        driverAssignedAt,
        pickedUpAt,
        deliveredAt,
        cancelledAt,
        cancellationReason,
        cancelledBy,
        statusUpdatedBy,
        updatedAt,
        deliveryFeePerDriver,
        refundAmount,
        refundStatus,
        refundInitiator,
      ];
}
