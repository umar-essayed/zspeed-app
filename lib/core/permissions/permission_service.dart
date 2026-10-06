import 'package:z_speed/core/enums/user_enums.dart';

/// Defines what each role can do to other users.
///
/// superAdmin → can edit/delete any role (superAdmin, admin, vendor, driver, customer)
/// admin      → can edit/delete only vendor and driver
class PermissionService {
  const PermissionService._();

  /// Returns true if [actor] can edit (update role/status) a user with [targetType].
  static bool canEditUser(UserType actor, UserType targetType) {
    switch (actor) {
      case UserType.superAdmin:
        return true;
      case UserType.admin:
        return targetType == UserType.vendor ||
            targetType == UserType.driver;
      case UserType.vendor:
      case UserType.driver:
      case UserType.customer:
        return false;
    }
  }

  /// Returns true if [actor] can delete a user with [targetType].
  static bool canDeleteUser(UserType actor, UserType targetType) {
    switch (actor) {
      case UserType.superAdmin:
        return true;
      case UserType.admin:
        return targetType == UserType.vendor ||
            targetType == UserType.driver;
      case UserType.vendor:
      case UserType.driver:
      case UserType.customer:
        return false;
    }
  }

  /// Returns true if [actor] can edit vendor details.
  static bool canEditVendor(UserType actor) {
    return actor == UserType.superAdmin || actor == UserType.admin;
  }

  /// Returns true if [actor] can delete a vendor.
  static bool canDeleteVendor(UserType actor) {
    return actor == UserType.superAdmin;
  }

  /// Returns true if [actor] can edit general content (promo codes, banners, etc).
  static bool canEditContent(UserType actor) {
    return actor == UserType.superAdmin || actor == UserType.admin;
  }

  /// Returns true if [actor] can delete general content.
  static bool canDeleteContent(UserType actor) {
    return actor == UserType.superAdmin;
  }

  /// Returns the roles that [actor] is allowed to assign to other users.
  static List<UserType> assignableRoles(UserType actor) {
    switch (actor) {
      case UserType.superAdmin:
        return UserType.values.where((t) => t != UserType.superAdmin).toList();
      case UserType.admin:
        return [UserType.vendor, UserType.driver, UserType.customer];
      case UserType.vendor:
      case UserType.driver:
      case UserType.customer:
        return [];
    }
  }
}
