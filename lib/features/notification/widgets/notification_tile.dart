import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:z_speed/core/enums/notification_enums.dart';
import 'package:z_speed/features/notification/model/app_notification.dart';
import 'package:z_speed/l10n/app_localizations.dart';

class NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  TextDirection _getTextDirection(String text) {
    final hasArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(text);
    return hasArabic ? TextDirection.rtl : TextDirection.ltr;
  }

  @override
  Widget build(BuildContext context) {
    final (iconData, iconColor, bgIconColor) = _getNotificationStyle();
    final promoCode = (notification.data['promoCode'] ??
            notification.data['code'] ??
            (notification.data['screen'] == 'promo_code'
                ? notification.data['targetEntityId']
                : null))
        ?.toString();
    final orderId = notification.data['orderId'];

    final isUnread = !notification.read;

    final title = _getLocalizedTitle(context);
    final body = _getLocalizedBody(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      child: Dismissible(
        key: Key(notification.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDismiss(),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red.shade400, Colors.red.shade700],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: AlignmentDirectional.centerEnd,
          padding: const EdgeInsetsDirectional.only(end: 20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context)!.delete,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
            ],
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isUnread ? const Color(0xFFFFF7F4) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isUnread
                      ? const Color(0xFFF35535).withValues(alpha: 0.25)
                      : Colors.grey.shade200,
                  width: isUnread ? 1.2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isUnread
                        ? const Color(0xFFF35535).withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.03),
                    blurRadius: isUnread ? 10 : 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon Avatar container
                  Stack(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: bgIconColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(iconData, color: iconColor, size: 22),
                      ),
                      if (isUnread)
                        PositionedDirectional(
                          top: 0,
                          end: 0,
                          child: Container(
                            width: 11,
                            height: 11,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF35535),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),

                  // Content Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Directionality(
                          textDirection: _getTextDirection(title),
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isUnread ? FontWeight.w800 : FontWeight.w600,
                              color: const Color(0xFF1A1A1A),
                              height: 1.25,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),

                        // Body
                        Directionality(
                          textDirection: _getTextDirection(body),
                          child: Text(
                            body,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: isUnread ? Colors.grey.shade800 : Colors.grey.shade600,
                              height: 1.35,
                            ),
                          ),
                        ),

                        // Tags / Chips (Promo code or Order ID)
                        if (promoCode != null && promoCode.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: promoCode));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const Icon(Icons.check_circle, color: Colors.white, size: 18),
                                          const SizedBox(width: 8),
                                          Text(AppLocalizations.of(context)!.promoCodeCopied(promoCode)),
                                        ],
                                      ),
                                      backgroundColor: const Color(0xFFF35535),
                                      duration: const Duration(seconds: 2),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF0EC),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFF35535).withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.local_offer_rounded,
                                        size: 13,
                                        color: Color(0xFFF35535),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        promoCode,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFF35535),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(
                                        Icons.copy_rounded,
                                        size: 12,
                                        color: Color(0xFFF35535),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else if (orderId != null && orderId.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Text(
                              '#${orderId.substring(0, orderId.length > 8 ? 8 : orderId.length).toUpperCase()}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 8),

                        // Time footer
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 13,
                              color: isUnread
                                  ? const Color(0xFFF35535).withValues(alpha: 0.8)
                                  : Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatTime(context, notification.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                                color: isUnread
                                    ? const Color(0xFFF35535)
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Trailing Chevron arrow
                  const SizedBox(width: 8),
                  Icon(
                    Directionality.of(context) == TextDirection.rtl
                        ? Icons.chevron_left_rounded
                        : Icons.chevron_right_rounded,
                    color: isUnread ? const Color(0xFFF35535) : Colors.grey.shade400,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  (IconData, Color, Color) _getNotificationStyle() {
    final titleLower = notification.title.toLowerCase();
    final isPromo = notification.data['screen'] == 'promo_code' ||
        titleLower.contains('discount') ||
        titleLower.contains('promo') ||
        notification.title.contains('خصم') ||
        notification.title.contains('🎁');

    if (isPromo) {
      return (
        Icons.card_giftcard_rounded,
        const Color(0xFFE65100),
        const Color(0xFFFFF3E0),
      );
    }

    switch (notification.type) {
      case NotificationType.orderCreated:
      case NotificationType.orderStatusChanged:
        return (
          Icons.receipt_long_rounded,
          const Color(0xFF1E88E5),
          const Color(0xFFE3F2FD),
        );
      case NotificationType.orderReady:
        return (
          Icons.restaurant_rounded,
          const Color(0xFFFB8C00),
          const Color(0xFFFFF3E0),
        );
      case NotificationType.driverAssigned:
        return (
          Icons.two_wheeler_rounded,
          const Color(0xFF00ACC1),
          const Color(0xFFE0F7FA),
        );
      case NotificationType.deliveryRequest:
        return (
          Icons.delivery_dining_rounded,
          const Color(0xFF8E24AA),
          const Color(0xFFF3E5F5),
        );
      case NotificationType.orderTimeout:
        return (
          Icons.cancel_outlined,
          const Color(0xFFE53935),
          const Color(0xFFFFEBEE),
        );
      case NotificationType.newApplication:
        return (
          Icons.badge_rounded,
          const Color(0xFF009688),
          const Color(0xFFE0F2F1),
        );
      case NotificationType.payoutInitiated:
      case NotificationType.settlementCompleted:
        return (
          Icons.account_balance_wallet_rounded,
          const Color(0xFF3F51B5),
          const Color(0xFFE8EAF6),
        );
      case NotificationType.general:
        return (
          Icons.notifications_active_rounded,
          const Color(0xFFF35535),
          const Color(0xFFFFEBE6),
        );
    }
  }

  String _formatTime(BuildContext context, DateTime time) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return l10n.justNow;
    } else if (difference.inHours < 1) {
      return l10n.minutesAgo(difference.inMinutes);
    } else if (difference.inDays < 1) {
      return l10n.hoursAgo(difference.inHours);
    } else if (difference.inDays < 7) {
      return l10n.daysAgo(difference.inDays);
    } else {
      return DateFormat('d MMM, h:mm a').format(time);
    }
  }

  String _getLocalizedTitle(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    if (!isArabic) return notification.title;

    final rawTitle = notification.title.trim();
    final cleanTitle = rawTitle.replaceAll(RegExp(r'^[!\.\s]+|[!\.\s]+$'), '');
    final titleLower = cleanTitle.toLowerCase();

    if (titleLower.contains('special discount code available') ||
        titleLower.contains('discount code') ||
        cleanTitle.contains('Discount')) {
      return '🎁 كود خصم خاص متاح!';
    }
    if (titleLower.contains('order cancelled') || titleLower.contains('cancelled')) {
      return '❌ تم إلغاء الطلب';
    }
    if (titleLower.contains('order received') || titleLower.contains('new order')) {
      return '🎉 تم استلام الطلب';
    }
    if (titleLower.contains('driver on the way') ||
        titleLower.contains('driver assigned') ||
        titleLower.contains('heading to pick')) {
      return '🏍️ السائق في الطريق إليك';
    }
    if (titleLower.contains('order ready') || titleLower.contains('ready for pickup')) {
      return '📦 الطلب جاهز للتوصيل';
    }
    if (titleLower.contains('order delivered')) {
      return '🎉 تم توصيل الطلب بنجاح';
    }
    if (titleLower.contains('order accepted')) {
      return '✅ تم قبول الطلب من المطعم';
    }
    if (titleLower.contains('being prepared') || titleLower.contains('preparing')) {
      return '👨‍🍳 جاري تحضير طلبك';
    }
    if (titleLower.contains('picked up') || titleLower.contains('on the way')) {
      return '🛵 الطلب في الطريق إليك';
    }
    if (titleLower.contains('order refunded') || titleLower.contains('refunded')) {
      return '💰 تم استرداد المبلغ';
    }

    final hasArabicChar = RegExp(r'[\u0600-\u06FF]').hasMatch(rawTitle);
    if (!hasArabicChar) {
      switch (notification.type) {
        case NotificationType.orderCreated:
          return '🎉 تم استلام الطلب';
        case NotificationType.orderStatusChanged:
          return '📦 تحديث حالة الطلب';
        case NotificationType.orderReady:
          return '📦 الطلب جاهز';
        case NotificationType.driverAssigned:
          return '🏍️ تم تعيين السائق';
        case NotificationType.deliveryRequest:
          return '🛵 طلب توصيل جديد';
        case NotificationType.orderTimeout:
          return '⚠️ انتهت مهلة الطلب';
        case NotificationType.newApplication:
          return '📋 طلب انضمام جديد';
        case NotificationType.payoutInitiated:
          return '💳 جاري معالجة السحب';
        case NotificationType.settlementCompleted:
          return '✅ تم تأكيد التسوية';
        case NotificationType.general:
          return rawTitle;
      }
    }

    return rawTitle;
  }

  String _getLocalizedBody(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    if (!isArabic) return notification.body;

    final body = notification.body.trim();
    final bodyLower = body.toLowerCase();
    final orderId = notification.data['orderId'] ?? '';
    final shortId = orderId.length >= 8 ? orderId.substring(0, 8).toUpperCase() : orderId;

    if (bodyLower.contains('save20') || bodyLower.contains('20% off your next order')) {
      return 'استخدم الكود SAVE20 عند إتمام الطلب للحصول على خصم 20% على طلبك القادم!';
    }
    if (bodyLower.contains('has been cancelled')) {
      final idMatch = RegExp(r'#([A-Za-z0-9]+)').firstMatch(body);
      final id = idMatch?.group(1) ?? shortId;
      return id.isNotEmpty
          ? 'تم إلغاء طلبك رقم #$id.'
          : 'تم إلغاء الطلب الخاص بك.';
    }
    if (bodyLower.contains('has been placed') &&
        (bodyLower.contains('waiting for vendor') || bodyLower.contains('vendor confirmation'))) {
      final idMatch = RegExp(r'#([A-Za-z0-9]+)').firstMatch(body);
      final id = idMatch?.group(1) ?? shortId;
      return id.isNotEmpty
          ? 'تم تقديم طلبك رقم #$id وهو في انتظار تأكيد المطعم.'
          : 'تم تقديم طلبك بنجاح وفي انتظار تأكيد المطعم.';
    }
    if (bodyLower.contains('accepted your order') &&
        (bodyLower.contains('heading to pick') || bodyLower.contains('heading to'))) {
      final driverName = body.split(' accepted').first.replaceAll(RegExp(r'^[!\.\s]+'), '');
      final idMatch = RegExp(r'#([A-Za-z0-9]+)').firstMatch(body);
      final id = idMatch?.group(1) ?? shortId;
      return id.isNotEmpty
          ? 'قبل السائق $driverName طلبك رقم #$id ويتوجه الآن لاستلامه.'
          : 'قبل السائق $driverName طلبك ويتوجه لاستلامه.';
    }
    if (bodyLower.contains('is ready and waiting for a driver')) {
      final idMatch = RegExp(r'#([A-Za-z0-9]+)').firstMatch(body);
      final id = idMatch?.group(1) ?? shortId;
      return id.isNotEmpty
          ? 'الطلب رقم #$id جاهز وفي انتظار السائق لاستلامه.'
          : 'الطلب جاهز وفي انتظار السائق.';
    }
    if (bodyLower.contains('is now being prepared')) {
      final idMatch = RegExp(r'#([A-Za-z0-9]+)').firstMatch(body);
      final id = idMatch?.group(1) ?? shortId;
      return id.isNotEmpty
          ? 'جاري تحضير طلبك رقم #$id الآن.'
          : 'جاري تحضير طلبك الآن.';
    }
    if (bodyLower.contains('has been delivered')) {
      final idMatch = RegExp(r'#([A-Za-z0-9]+)').firstMatch(body);
      final id = idMatch?.group(1) ?? shortId;
      return id.isNotEmpty
          ? 'تم توصيل طلبك رقم #$id. نتمنى لك وجبة شهية!'
          : 'تم توصيل طلبك بنجاح. بالهناء والشفاء!';
    }
    if (bodyLower.contains('has been refunded')) {
      final idMatch = RegExp(r'#([A-Za-z0-9]+)').firstMatch(body);
      final id = idMatch?.group(1) ?? shortId;
      return id.isNotEmpty
          ? 'تم استرداد مبلغ طلبك رقم #$id وسيطهر في حسابك قريباً.'
          : 'تم استرداد المبلغ وسيطهر في حسابك قريباً.';
    }

    return body;
  }
}

