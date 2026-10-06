enum NotificationType {
  orderCreated,
  orderStatusChanged,
  orderReady,
  driverAssigned,
  deliveryRequest,
  orderTimeout,
  newApplication,
  payoutInitiated,
  settlementCompleted,
  general;

  String get key => name;

  static NotificationType fromKey(String key) {
    // Map legacy/snake_case keys from Cloud Functions
    const aliases = {
      'new_delivery_request': 'deliveryRequest',
      'order_created': 'orderCreated',
      'order_status_changed': 'orderStatusChanged',
      'order_ready': 'orderReady',
      'driver_assigned': 'driverAssigned',
      'order_timeout': 'orderTimeout',
      'new_application': 'newApplication',
    };
    final normalized = aliases[key] ?? key;
    return NotificationType.values.firstWhere(
      (e) => e.key == normalized,
      orElse: () => NotificationType.general,
    );
  }

  String get label => switch (this) {
        orderCreated => 'New Order',
        orderStatusChanged => 'Order Update',
        orderReady => 'Order Ready',
        driverAssigned => 'Driver Assigned',
        deliveryRequest => 'Delivery Request',
        orderTimeout => 'Order Timeout',
        newApplication => 'New Application',
        payoutInitiated => 'Payout Initiated',
        settlementCompleted => 'Payout Confirmed',
        general => 'Notification',
      };
}
