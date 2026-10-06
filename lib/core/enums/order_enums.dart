/// Single source of truth for order, payment, and vendor status enumerations.
///
/// Replaces duplicates in:
///   - admin_models.dart (OrderStatus — only 4 values)
library;

import 'package:z_speed/l10n/app_localizations.dart';

enum OrderStatus {
  pending,
  accepted,
  preparing,
  ready,
  searching,      // Dispatch Engine searching for driver
  unassigned,     // Dispatch Engine failed to find driver
  driverAssigned,
  pickedUp,
  onTheWay,
  delivered,
  cancelled,
  refunded,
}

enum PaymentMethodType { cash, card, wallet }

enum PaymentStatus { pending, completed, failed, refunded }

enum RestaurantStatus { active, pending, suspended }

/// Extensions
extension OrderStatusX on OrderStatus {
  String getLocalizedLabel(AppLocalizations l10n) {
    switch (this) {
      case OrderStatus.pending:
        return l10n.statusPending;
      case OrderStatus.accepted:
        return l10n.statusAccepted;
      case OrderStatus.preparing:
        return l10n.statusPreparing;
      case OrderStatus.ready:
        return l10n.statusReady;
      case OrderStatus.searching:
        return l10n.statusSearching;
      case OrderStatus.unassigned:
        return l10n.statusUnassigned;
      case OrderStatus.driverAssigned:
        return l10n.statusDriverAssigned;
      case OrderStatus.pickedUp:
        return l10n.statusPickedUp;
      case OrderStatus.onTheWay:
        return l10n.statusOnTheWay;
      case OrderStatus.delivered:
        return l10n.statusDelivered;
      case OrderStatus.cancelled:
        return l10n.statusCancelled;
      case OrderStatus.refunded:
        return l10n.statusRefunded;
    }
  }

  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.accepted:
        return 'Accepted';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.searching:
        return 'Searching';
      case OrderStatus.unassigned:
        return 'Unassigned';
      case OrderStatus.driverAssigned:
        return 'Driver Assigned';
      case OrderStatus.pickedUp:
        return 'Picked Up';
      case OrderStatus.onTheWay:
        return 'On The Way';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.refunded:
        return 'Refunded';
    }
  }

  String get key => name;

  static OrderStatus fromKey(String key) => OrderStatus.values
      .firstWhere((e) => e.name == key, orElse: () => OrderStatus.pending);
}

extension PaymentMethodTypeX on PaymentMethodType {
  String getLocalizedLabel(AppLocalizations l10n) {
    switch (this) {
      case PaymentMethodType.cash:
        return l10n.paymentCash;
      case PaymentMethodType.card:
        return l10n.paymentCard;
      case PaymentMethodType.wallet:
        return l10n.paymentWallet;
    }
  }

  String get label {
    switch (this) {
      case PaymentMethodType.cash:
        return 'Cash';
      case PaymentMethodType.card:
        return 'Card';
      case PaymentMethodType.wallet:
        return 'Wallet';
    }
  }

  String get key => name;

  static PaymentMethodType fromKey(String key) => PaymentMethodType.values
      .firstWhere((e) => e.name == key, orElse: () => PaymentMethodType.cash);
}

extension PaymentStatusX on PaymentStatus {
  String getLocalizedLabel(AppLocalizations l10n) {
    switch (this) {
      case PaymentStatus.pending:
        return l10n.statusPending;
      case PaymentStatus.completed:
        return l10n.statusCompleted;
      case PaymentStatus.failed:
        return l10n.statusFailed;
      case PaymentStatus.refunded:
        return l10n.statusRefunded;
    }
  }

  String get label {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.completed:
        return 'Completed';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.refunded:
        return 'Refunded';
    }
  }

  String get key => name;

  static PaymentStatus fromKey(String key) => PaymentStatus.values
      .firstWhere((e) => e.name == key, orElse: () => PaymentStatus.pending);
}

extension RestaurantStatusX on RestaurantStatus {
  String getLocalizedLabel(AppLocalizations l10n) {
    switch (this) {
      case RestaurantStatus.active:
        return l10n.statusActive;
      case RestaurantStatus.pending:
        return l10n.statusPending;
      case RestaurantStatus.suspended:
        return l10n.statusSuspended;
    }
  }

  String get label {
    switch (this) {
      case RestaurantStatus.active:
        return 'Active';
      case RestaurantStatus.pending:
        return 'Pending';
      case RestaurantStatus.suspended:
        return 'Suspended';
    }
  }

  String get key => name;

  static RestaurantStatus fromKey(String key) => RestaurantStatus.values
      .firstWhere((e) => e.name == key, orElse: () => RestaurantStatus.pending);
}
