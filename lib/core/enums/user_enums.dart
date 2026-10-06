/// Single source of truth for all user-related enumerations.
///
/// Replaces duplicates in:
///   - user_model.dart (UserType, UserStatus, ApplicationStatus)
///   - admin_models.dart (UserRole, UserStatus)
///   - application_model.dart (ReviewStatus ≡ ApplicationStatus)
library;

import 'package:z_speed/l10n/app_localizations.dart';

enum UserType { superAdmin, admin, vendor, customer, driver }

enum UserStatus { active, inactive, suspended, pendingVerification, banned }

enum ApplicationStatus { pending, underReview, approved, rejected }

/// Extension for display labels
extension UserTypeX on UserType {
  String get label {
    switch (this) {
      case UserType.superAdmin:
        return 'Super Admin';
      case UserType.admin:
        return 'Admin';
      case UserType.vendor:
        return 'Vendor';
      case UserType.customer:
        return 'Customer';
      case UserType.driver:
        return 'Driver';
    }
  }

  /// Firestore string key
  String get key => name;

  static UserType fromKey(String key) {
    if (key == 'restaurant') return UserType.vendor;
    return UserType.values
        .firstWhere((e) => e.name == key, orElse: () => UserType.customer);
  }
}

extension UserStatusX on UserStatus {
  String get label {
    switch (this) {
      case UserStatus.active:
        return 'Active';
      case UserStatus.inactive:
        return 'Inactive';
      case UserStatus.suspended:
        return 'Suspended';
      case UserStatus.pendingVerification:
        return 'Pending Verification';
      case UserStatus.banned:
        return 'Banned';
    }
  }

  String get key => name;

  static UserStatus fromKey(String key) => UserStatus.values
      .firstWhere((e) => e.name == key, orElse: () => UserStatus.active);
}

extension ApplicationStatusX on ApplicationStatus {
  String get label {
    switch (this) {
      case ApplicationStatus.pending:
        return 'Pending';
      case ApplicationStatus.underReview:
        return 'Under Review';
      case ApplicationStatus.approved:
        return 'Approved';
      case ApplicationStatus.rejected:
        return 'Rejected';
    }
  }

  String get key => name;

  static ApplicationStatus fromKey(String key) =>
      ApplicationStatus.values.firstWhere((e) => e.name == key,
          orElse: () => ApplicationStatus.pending);
}

enum VendorType {
  restaurant,
  supermarket,
  pharmacy,
  bookstore,
  homeFurnishing,
  meatAndProteins,
  clothes,
  buyAndSell,
  electronics,
}

extension VendorTypeX on VendorType {
  String getLocalizedLabel(AppLocalizations l10n) {
    switch (this) {
      case VendorType.restaurant:
        return l10n.restaurant;
      case VendorType.supermarket:
        return l10n.supermarket;
      case VendorType.pharmacy:
        return l10n.pharmacy;
      case VendorType.bookstore:
        return l10n.bookstore;
      case VendorType.homeFurnishing:
        return l10n.homeFurnishing;
      case VendorType.meatAndProteins:
        return l10n.meatAndProteins;
      case VendorType.clothes:
        return l10n.clothes;
      case VendorType.buyAndSell:
        return l10n.buyAndSell;
      case VendorType.electronics:
        return l10n.electronics;
    }
  }

  String get label {
    switch (this) {
      case VendorType.restaurant:
        return 'Restaurant';
      case VendorType.supermarket:
        return 'Supermarket';
      case VendorType.pharmacy:
        return 'Pharmacy';
      case VendorType.bookstore:
        return 'Bookstore & Stationery';
      case VendorType.homeFurnishing:
        return 'Home & Furnishing';
      case VendorType.meatAndProteins:
        return 'Meat & Proteins';
      case VendorType.clothes:
        return 'Clothing & Fashion';
      case VendorType.buyAndSell:
        return 'Buy & Sell';
      case VendorType.electronics:
        return 'Electronics';
    }
  }

  String get key => name;

  static VendorType fromKey(String key) => VendorType.values
      .firstWhere((e) => e.name == key, orElse: () => VendorType.restaurant);
}

