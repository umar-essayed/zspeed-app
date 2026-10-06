import 'package:flutter/material.dart';

import 'package:z_speed/features/admin/model/admin_models.dart';

Color resolveAdminUserStatusColor({
  required UserStatus status,
  required Color successGreen,
  required Color warningAmber,
  required Color errorRed,
}) {
  switch (status) {
    case UserStatus.active:
      return successGreen;
    case UserStatus.pendingVerification:
      return warningAmber;
    case UserStatus.suspended:
      return errorRed;
    case UserStatus.inactive:
      return const Color(0xFF9E9E9E);
    case UserStatus.banned:
      return errorRed;
  }
}

Color resolveAdminOrderStatusColor({
  required OrderStatus status,
  required Color successGreen,
  required Color warningAmber,
  required Color primaryOrange,
  required Color errorRed,
}) {
  switch (status) {
    case OrderStatus.delivered:
      return successGreen;
    case OrderStatus.preparing:
    case OrderStatus.ready:
    case OrderStatus.driverAssigned:
    case OrderStatus.pickedUp:
    case OrderStatus.onTheWay:
      return warningAmber;
    case OrderStatus.pending:
    case OrderStatus.accepted:
      return primaryOrange;
    case OrderStatus.searching:
      case OrderStatus.unassigned:
      case OrderStatus.cancelled:
    case OrderStatus.refunded:
      return errorRed;
  }
}
