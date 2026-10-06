import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:z_speed/core/utils/phone_helper.dart';
import 'package:z_speed/features/order/model/order.dart';
import 'package:z_speed/features/order/model/order_item.dart';
import 'package:z_speed/features/restaurant_owner/utils/order_receipt_labels.dart';

const _printerChannel = MethodChannel('com.zspeed.app/printer');

String buildVendorOrderReceiptHtml({
  required Order order,
  required String restaurantName,
  required String title,
  required ReceiptPrintLanguage language,
  String? customerName,
  String? customerPhone,
  String? customerAddress,
  Map<String, String>? itemTranslations,
  List<OrderItem>? orderItems,
}) {
  return '';
}

Future<void> printVendorOrderReceiptWeb({
  required Order order,
  required String restaurantName,
  required String title,
  required ReceiptPrintLanguage language,
  String? customerName,
  String? customerPhone,
  String? customerAddress,
  Map<String, String>? itemTranslations,
  List<OrderItem>? orderItems,
}) async {
  if (!Platform.isAndroid) {
    return;
  }

  final labels = VendorReceiptLabels.forLanguage(language);
  final locale = labels.htmlLang;
  final currencyFormatter = NumberFormat.currency(symbol: 'EGP ', locale: locale);
  final priceFormatter = NumberFormat.currency(symbol: '', locale: locale);
  final dateFormatter = DateFormat('dd MMM yyyy • hh:mm a', locale);

  final displayOrderId = order.id.length > 8
      ? '#${order.id.substring(0, 8).toUpperCase()}'
      : '#${order.id.toUpperCase()}';

  // Construct structured, flexible layout command list
  final List<Map<String, dynamic>> lines = [];

  // --- 1. Header ---
  lines.add({
    'type': 'text',
    'text': labels.receipt,
    'size': 28,
    'align': 'CENTER',
    'bold': true,
  });
  lines.add({
    'type': 'text',
    'text': restaurantName,
    'size': 24,
    'align': 'CENTER',
    'bold': true,
  });
  lines.add({
    'type': 'text',
    'text': '--------------------------------',
    'size': 20,
    'align': 'CENTER',
    'bold': false,
  });

  // --- 2. Meta Info ---
  lines.add({
    'type': 'text',
    'text': '${labels.orderId}: $displayOrderId',
    'size': 22,
    'align': labels.isRtl ? 'RIGHT' : 'LEFT',
    'bold': false,
  });
  lines.add({
    'type': 'text',
    'text': '${labels.date}: ${dateFormatter.format(order.createdAt.toLocal())}',
    'size': 22,
    'align': labels.isRtl ? 'RIGHT' : 'LEFT',
    'bold': false,
  });
  if (customerName != null) {
    lines.add({
      'type': 'text',
      'text': '${labels.customer}: $customerName',
      'size': 22,
      'align': labels.isRtl ? 'RIGHT' : 'LEFT',
      'bold': false,
    });
  }
  if (customerPhone != null) {
    lines.add({
      'type': 'text',
      'text': '${labels.phone}: ${PhoneHelper.normalizePhone(customerPhone)}',
      'size': 22,
      'align': 'LEFT',
      'bold': false,
    });
  }
  if (customerAddress != null) {
    lines.add({
      'type': 'text',
      'text': '${labels.address}: $customerAddress',
      'size': 22,
      'align': labels.isRtl ? 'RIGHT' : 'LEFT',
      'bold': false,
    });
  }

  lines.add({
    'type': 'text',
    'text': '================================',
    'size': 20,
    'align': 'CENTER',
    'bold': false,
  });

  // --- 3. Items Header ---
  lines.add({
    'type': 'text',
    'text': '${labels.item}   |   ${labels.qty}   |   ${labels.total}',
    'size': 22,
    'align': labels.isRtl ? 'RIGHT' : 'LEFT',
    'bold': true,
  });
  lines.add({
    'type': 'text',
    'text': '--------------------------------',
    'size': 20,
    'align': 'CENTER',
    'bold': false,
  });

  // --- 4. Items ---
  for (final item in order.items) {
    final name = itemTranslations?[item.menuItemId] ??
        (language == ReceiptPrintLanguage.ar && item.nameAr != null && item.nameAr!.isNotEmpty
            ? item.nameAr!
            : item.name);
    
    // Resolve Options & Variants
    String optionsSummaryText = item.optionsSummary ?? '';
    if (orderItems != null) {
      try {
        final matchingOrderItem = orderItems.firstWhere(
          (oi) => oi.id == item.id || (oi.menuItemId == item.menuItemId && oi.id == item.id),
          orElse: () => orderItems.firstWhere(
            (oi) => oi.menuItemId == item.menuItemId,
          ),
        );
        final langCode = language == ReceiptPrintLanguage.ar ? 'ar' : 'en';
        final variantName = matchingOrderItem.getLocalizedVariantName(langCode);
        final parts = <String>[];
        if (variantName.isNotEmpty) {
          parts.add(variantName);
        }
        for (final addon in matchingOrderItem.selectedAddons) {
          parts.add(addon.optionName);
        }
        optionsSummaryText = parts.join(', ');
      } catch (_) {}
    }

    lines.add({
      'type': 'text',
      'text': name,
      'size': 22,
      'align': labels.isRtl ? 'RIGHT' : 'LEFT',
      'bold': true,
    });
    if (optionsSummaryText.isNotEmpty) {
      lines.add({
        'type': 'text',
        'text': '  ($optionsSummaryText)',
        'size': 18,
        'align': labels.isRtl ? 'RIGHT' : 'LEFT',
        'bold': false,
      });
    }
    
    final priceStr = priceFormatter.format(item.price).trim();
    final totalStr = priceFormatter.format(item.totalPrice).trim();
    lines.add({
      'type': 'text',
      'text': '  ${item.quantity} x EGP $priceStr = EGP $totalStr',
      'size': 20,
      'align': labels.isRtl ? 'RIGHT' : 'LEFT',
      'bold': false,
    });
  }

  lines.add({
    'type': 'text',
    'text': '--------------------------------',
    'size': 20,
    'align': 'CENTER',
    'bold': false,
  });

  // --- 5. Totals ---
  lines.add({
    'type': 'text',
    'text': '${labels.subtotal}: ${currencyFormatter.format(order.subtotal)}',
    'size': 22,
    'align': labels.isRtl ? 'RIGHT' : 'LEFT',
    'bold': false,
  });
  lines.add({
    'type': 'text',
    'text': '${labels.deliveryFee}: ${currencyFormatter.format(order.deliveryFee)}',
    'size': 22,
    'align': labels.isRtl ? 'RIGHT' : 'LEFT',
    'bold': false,
  });
  if (order.discount > 0) {
    lines.add({
      'type': 'text',
      'text': '${labels.discount}: -${currencyFormatter.format(order.discount)}',
      'size': 22,
      'align': labels.isRtl ? 'RIGHT' : 'LEFT',
      'bold': false,
    });
  }
  lines.add({
    'type': 'text',
    'text': '${labels.total}: ${currencyFormatter.format(order.total)}',
    'size': 24,
    'align': labels.isRtl ? 'RIGHT' : 'LEFT',
    'bold': true,
  });

  lines.add({
    'type': 'text',
    'text': '================================',
    'size': 20,
    'align': 'CENTER',
    'bold': false,
  });

  // --- 6. Footer ---
  lines.add({
    'type': 'text',
    'text': labels.thankYou,
    'size': 20,
    'align': 'CENTER',
    'bold': false,
  });
  
  lines.add({
    'type': 'qrcode',
    'text': 'https://zspeedapp.com/download',
    'size': 180,
    'align': 'CENTER',
  });
  
  lines.add({
    'type': 'text',
    'text': labels.downloadApp,
    'size': 16,
    'align': 'CENTER',
    'bold': false,
  });

  // Safe paper feed at the end of printout to allow tearing it off
  lines.add({
    'type': 'feed',
    'lines': 3,
  });

  try {
    await _printerChannel.invokeMethod('printReceipt', {'lines': lines});
  } on PlatformException catch (e) {
    final msg = e.message ?? e.details?.toString() ?? e.code;
    throw msg;
  } catch (e) {
    throw e.toString();
  }
}

