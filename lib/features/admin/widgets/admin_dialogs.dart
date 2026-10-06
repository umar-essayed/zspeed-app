import 'package:z_speed/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:z_speed/features/admin/model/admin_models.dart';
import 'package:z_speed/features/admin/model/admin_theme.dart';

/// Reusable admin dialogs for confirm/delete/status actions.
class AdminDialogs {
  AdminDialogs._();

  // ── Generic Confirmation ─────────────────────────────────────────────────

  /// Shows a confirmation dialog and returns `true` if confirmed.
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    Color? confirmColor,
    IconData? icon,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: confirmColor, size: 22),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(title,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AdminTheme.textDark)),
            ),
          ],
        ),
        content: Text(message,
            style: TextStyle(fontSize: 14, color: AdminTheme.textMedium)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context)!.cancel,
                style: TextStyle(color: AdminTheme.textLight)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor ?? AdminTheme.primaryOrange,
              foregroundColor: AdminTheme.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(confirmLabel, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ── Delete Confirmation ──────────────────────────────────────────────────

  static Future<bool> confirmDelete(
    BuildContext context, {
    required String itemType,
    required String itemName,
  }) {
    return confirm(
      context,
      title: AppLocalizations.of(context)!.deleteItemType(itemType),
      message: AppLocalizations.of(context)!.deleteItemConfirm(itemName),
      confirmLabel: AppLocalizations.of(context)!.delete,
      confirmColor: AdminTheme.errorRed,
      icon: Icons.delete_outline,
    );
  }

  // ── Status Picker ────────────────────────────────────────────────────────

  /// Shows a bottom sheet / dialog to pick a new [UserStatus].
  static Future<UserStatus?> pickUserStatus(
    BuildContext context, {
    required UserStatus currentStatus,
  }) {
    return _pickEnum<UserStatus>(
      context,
      title: AppLocalizations.of(context)!.changeUserStatusTitle,
      values: UserStatus.values,
      current: currentStatus,
      labelOf: (s) => s.name[0].toUpperCase() + s.name.substring(1),
      colorOf: (s) => _userStatusColor(s),
    );
  }

  /// Shows a dialog to pick a new [UserType].
  static Future<UserType?> pickUserRole(
    BuildContext context, {
    required UserType currentRole,
  }) {
    return _pickEnum<UserType>(
      context,
      title: AppLocalizations.of(context)!.changeUserRoleTitle,
      values: UserType.values,
      current: currentRole,
      labelOf: (t) => t.name[0].toUpperCase() + t.name.substring(1),
      colorOf: (_) => AdminTheme.primaryOrange,
    );
  }

  /// Shows a dialog to pick a new [OrderStatus].
  static Future<OrderStatus?> pickOrderStatus(
    BuildContext context, {
    required OrderStatus currentStatus,
  }) {
    return _pickEnum<OrderStatus>(
      context,
      title: AppLocalizations.of(context)!.updateOrderStatusTitle,
      values: OrderStatus.values,
      current: currentStatus,
      labelOf: (s) => s.name[0].toUpperCase() + s.name.substring(1),
      colorOf: (s) => _orderStatusColor(s),
    );
  }

  /// Shows a dialog to pick a new [RestaurantStatus].
  static Future<RestaurantStatus?> pickVendorStatus(
    BuildContext context, {
    required RestaurantStatus currentStatus,
  }) {
    return _pickEnum<RestaurantStatus>(
      context,
      title: AppLocalizations.of(context)!.updateStatus,
      values: RestaurantStatus.values,
      current: currentStatus,
      labelOf: (s) => s.name[0].toUpperCase() + s.name.substring(1),
      colorOf: (s) => _vendorStatusColor(s),
    );
  }

  // ── Snackbar Helpers ─────────────────────────────────────────────────────

  static void showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
  }

  static void showComingSoon(BuildContext context, String feature) {
    showSnack(context, '$feature ${AppLocalizations.of(context)!.comingSoonSuffix}');
  }

  // ── Private Helpers ──────────────────────────────────────────────────────

  static Future<T?> _pickEnum<T>(
    BuildContext context, {
    required String title,
    required List<T> values,
    required T current,
    required String Function(T) labelOf,
    required Color Function(T) colorOf,
  }) async {
    return showDialog<T>(
      context: context,
      builder: (ctx) => SimpleDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AdminTheme.textDark)),
        children: values.map((val) {
          final isSelected = val == current;
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, val),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: colorOf(val),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  labelOf(val),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                    color: AdminTheme.textDark,
                  ),
                ),
                if (isSelected) ...[
                  const Spacer(),
                  Icon(Icons.check,
                      color: AdminTheme.primaryOrange, size: 18),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  static Color _userStatusColor(UserStatus s) {
    return switch (s) {
      UserStatus.active => AdminTheme.successGreen,
      UserStatus.inactive => AdminTheme.textLight,
      UserStatus.suspended => AdminTheme.warningAmber,
      UserStatus.pendingVerification => AdminTheme.infoBlue,
      UserStatus.banned => AdminTheme.errorRed,
    };
  }

  static Color _orderStatusColor(OrderStatus s) {
    return switch (s) {
      OrderStatus.pending ||
      OrderStatus.searching ||
      OrderStatus.unassigned => AdminTheme.warningAmber,
      OrderStatus.accepted ||
      OrderStatus.preparing ||
      OrderStatus.ready =>
        AdminTheme.infoBlue,
      OrderStatus.driverAssigned ||
      OrderStatus.pickedUp ||
      OrderStatus.onTheWay =>
        AdminTheme.primaryOrange,
      OrderStatus.delivered => AdminTheme.successGreen,
      OrderStatus.cancelled || OrderStatus.refunded => AdminTheme.errorRed,
    };
  }

  static Color _vendorStatusColor(RestaurantStatus s) {
    return switch (s) {
      RestaurantStatus.active => AdminTheme.successGreen,
      RestaurantStatus.pending => AdminTheme.warningAmber,
      RestaurantStatus.suspended => AdminTheme.errorRed,
    };
  }
}
