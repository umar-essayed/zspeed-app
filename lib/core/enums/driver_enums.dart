// Driver-related enumerations for Phase 8.6.
// Covers driver status, delivery fee configuration, driver assignments,
// and wallet transactions.

/// Driver availability status.
enum DriverStatus {
  offline, // Driver is not available
  online, // Driver is available and waiting for deliveries
  busy, // Driver is currently on a delivery
  inService, // Driver is in a ride or order delivery process
}

/// Delivery fee calculation mode set by restaurant.
enum DeliveryFeeMode {
  fixed, // Flat delivery fee
  distance, // Distance-based calculation (tiers or formula)
}

/// Sub-mode for distance-based delivery fees.
enum DeliveryFeeSubMode {
  tiers, // Bracket-based (e.g., 0-3km = 15 EGP, 3-7km = 25 EGP)
  formula, // Formula-based (baseFee + perKmRate × distance)
}

/// Status of a driver's assignment to an order.
enum DriverAssignmentStatus {
  pending, // Vendor assigned, driver hasn't responded
  accepted, // Driver accepted the delivery
  rejected, // Driver rejected the delivery
  cancelled, // Restaurant cancelled the assignment
  pickedUp, // Driver picked up from restaurant
  delivered, // Driver completed delivery
}

/// Type of wallet transaction.
enum WalletTransactionType {
  credit, // Money added to wallet (delivery fees)
  debit, // Money removed from wallet (payout confirmed)
}

/// Status of a wallet transaction.
enum WalletTransactionStatus {
  pending, // Transaction created, awaiting action
  confirmed, // Driver confirmed payout received
  disputed, // Admin flagged for review
}

/// Payout method used to pay driver or restaurant.
enum PayoutMethod {
  instapay,
  vodafoneCash,
  bankTransfer,
}

/// Extensions
extension DriverStatusX on DriverStatus {
  String get label {
    switch (this) {
      case DriverStatus.offline:
        return 'Offline';
      case DriverStatus.online:
        return 'Online';
      case DriverStatus.busy:
        return 'Busy';
      case DriverStatus.inService:
        return 'In Service';
    }
  }

  String get key => name;

  static DriverStatus fromKey(String key) => DriverStatus.values
      .firstWhere((e) => e.name == key, orElse: () => DriverStatus.offline);
}

extension DeliveryFeeModeX on DeliveryFeeMode {
  String get label {
    switch (this) {
      case DeliveryFeeMode.fixed:
        return 'Fixed Fee';
      case DeliveryFeeMode.distance:
        return 'Distance-Based';
    }
  }

  String get key => name;

  static DeliveryFeeMode fromKey(String key) => DeliveryFeeMode.values
      .firstWhere((e) => e.name == key, orElse: () => DeliveryFeeMode.fixed);
}

extension DeliveryFeeSubModeX on DeliveryFeeSubMode {
  String get label {
    switch (this) {
      case DeliveryFeeSubMode.tiers:
        return 'Bracket Tiers';
      case DeliveryFeeSubMode.formula:
        return 'Base + Per-km Formula';
    }
  }

  String get key => name;

  static DeliveryFeeSubMode fromKey(String key) =>
      DeliveryFeeSubMode.values.firstWhere(
        (e) => e.name == key,
        orElse: () => DeliveryFeeSubMode.tiers,
      );
}

extension DriverAssignmentStatusX on DriverAssignmentStatus {
  String get label {
    switch (this) {
      case DriverAssignmentStatus.pending:
        return 'Pending';
      case DriverAssignmentStatus.accepted:
        return 'Accepted';
      case DriverAssignmentStatus.rejected:
        return 'Rejected';
      case DriverAssignmentStatus.cancelled:
        return 'Cancelled';
      case DriverAssignmentStatus.pickedUp:
        return 'Picked Up';
      case DriverAssignmentStatus.delivered:
        return 'Delivered';
    }
  }

  String get key => name;

  static DriverAssignmentStatus fromKey(String key) =>
      DriverAssignmentStatus.values.firstWhere(
        (e) => e.name == key,
        orElse: () => DriverAssignmentStatus.pending,
      );
}

extension WalletTransactionTypeX on WalletTransactionType {
  String get label {
    switch (this) {
      case WalletTransactionType.credit:
        return 'Credit';
      case WalletTransactionType.debit:
        return 'Debit';
    }
  }

  String get key => name;

  static WalletTransactionType fromKey(String key) =>
      WalletTransactionType.values.firstWhere(
        (e) => e.name == key,
        orElse: () => WalletTransactionType.credit,
      );
}

extension WalletTransactionStatusX on WalletTransactionStatus {
  String get label {
    switch (this) {
      case WalletTransactionStatus.pending:
        return 'Pending';
      case WalletTransactionStatus.confirmed:
        return 'Confirmed';
      case WalletTransactionStatus.disputed:
        return 'Disputed';
    }
  }

  String get key => name;

  static WalletTransactionStatus fromKey(String key) =>
      WalletTransactionStatus.values.firstWhere(
        (e) => e.name == key,
        orElse: () => WalletTransactionStatus.pending,
      );
}

extension PayoutMethodX on PayoutMethod {
  String get label {
    switch (this) {
      case PayoutMethod.instapay:
        return 'InstaPay';
      case PayoutMethod.vodafoneCash:
        return 'Vodafone Cash';
      case PayoutMethod.bankTransfer:
        return 'Bank Transfer';
    }
  }

  String get key => name;

  static PayoutMethod fromKey(String key) => PayoutMethod.values.firstWhere(
        (e) => e.name == key,
        orElse: () => PayoutMethod.instapay,
      );
}
