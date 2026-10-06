import 'dart:js_interop';
import 'package:intl/intl.dart';
import 'package:web/web.dart' as web;
import 'package:z_speed/core/utils/phone_helper.dart';
import 'package:z_speed/features/order/model/order.dart';
import 'package:z_speed/features/order/model/order_item.dart';
import 'package:z_speed/features/restaurant_owner/utils/order_receipt_labels.dart';

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
  final labels = VendorReceiptLabels.forLanguage(language);
  final locale = labels.htmlLang;
  final currencyFormatter = NumberFormat.currency(
    symbol: 'EGP ',
    locale: locale,
  );
  final priceFormatter = NumberFormat.currency(
    symbol: '',
    locale: locale,
  );
  final dateFormatter = DateFormat('dd MMM yyyy • hh:mm a', locale);

  final resolvedCustomerName = _displayValue(
    customerName ?? order.customerName ?? order.customerId,
    labels.notAvailable,
  );
  final rawPhone = customerPhone ?? order.customerPhone;
  final resolvedCustomerPhone = _displayValue(
    rawPhone != null && rawPhone.trim().isNotEmpty
        ? PhoneHelper.normalizePhone(rawPhone)
        : null,
    labels.notAvailable,
  );
  final rawAddress = customerAddress ?? order.deliveryAddress;
  final resolvedCustomerAddress = _displayValue(
    rawAddress.trim().isNotEmpty ? _cleanAddress(rawAddress, language) : null,
    labels.notAvailable,
  );
  final textAlign = labels.isRtl ? 'right' : 'left';
  final direction = labels.isRtl ? 'rtl' : 'ltr';

  final displayOrderId = order.id.length > 8
      ? '#${order.id.substring(0, 8).toUpperCase()}'
      : '#${order.id.toUpperCase()}';

  final itemsHtml = order.items.isEmpty
      ? '<tr><td colspan="4" class="muted" style="text-align: center;">${_escapeHtml(labels.noItems)}</td></tr>'
      : order.items.map((item) {
          final translatedName = itemTranslations?[item.menuItemId] ??
              (language == ReceiptPrintLanguage.ar && item.nameAr != null && item.nameAr!.isNotEmpty
                  ? item.nameAr!
                  : item.name);
          final escapedName = _escapeHtml(translatedName);
          
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
            } catch (_) {
              // fallback
            }
          }

          final escapedOptions = _escapeHtml(optionsSummaryText);
          return '''
              <tr>
                <td class="item-name">
                  <strong>$escapedName</strong>
                  ${escapedOptions.isEmpty ? '' : '<div class="item-options">$escapedOptions</div>'}
                </td>
                <td class="item-qty">${item.quantity}</td>
                <td class="item-price">${priceFormatter.format(item.price).trim()}</td>
                <td class="item-total">${priceFormatter.format(item.totalPrice).trim()}</td>
              </tr>
            ''';
        }).join();

  const downloadQrImageUrl = 'https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=https%3A%2F%2Fzspeedapp.com%2Fdownload';

  return '''
<!DOCTYPE html>
<html lang="$locale" dir="$direction">
<head>
  <meta charset="utf-8" />
  <title>$title</title>
  <style>
    @page {
      size: 80mm 297mm;
      margin: 0;
    }
    
    html, body {
      margin: 0 auto;
      padding: 0;
      width: 72.1mm;
      font-family: 'Courier New', Courier, monospace;
      font-size: 11px;
      color: #000;
      line-height: 1.3;
      background-color: #fff;
    }

    /* RTL specific fonts if needed, otherwise Courier works well for monospace formatting */
    html[dir="rtl"] body {
      font-family: 'Courier New', Courier, monospace;
    }

    .receipt {
      width: 100%;
      box-sizing: border-box;
      max-width: 72.1mm;
      margin: 0 auto;
      padding: 4mm 2mm;
    }

    .header {
      text-align: center;
      margin-bottom: 12px;
    }

    .header h1 {
      margin: 0 0 4px;
      font-size: 18px;
      font-weight: bold;
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }

    .header h2 {
      margin: 0 0 6px;
      font-size: 14px;
      font-weight: normal;
    }

    .divider {
      border-top: 1px dashed #000;
      margin: 8px 0;
    }

    .double-divider {
      border-top: 3px double #000;
      margin: 10px 0;
    }

    .meta-section {
      margin-bottom: 8px;
    }

    .meta-row {
      display: flex;
      justify-content: space-between;
      margin-bottom: 4px;
    }

    .meta-label {
      font-weight: bold;
      color: #333;
    }

    .meta-value {
      text-align: $textAlign;
      max-width: 65%;
      word-break: break-word;
    }

    .qr-box {
      text-align: center;
      margin: 12px auto;
      width: 120px;
    }

    .qr-box img {
      width: 90px;
      height: 90px;
      border: 1px solid #ddd;
      padding: 3px;
      background: #fff;
      display: block;
      margin: 0 auto 4px;
    }

    .qr-label {
      font-size: 8px;
      color: #555;
      font-weight: bold;
      text-transform: uppercase;
      letter-spacing: 0.2px;
    }

    table {
      width: 100%;
      border-collapse: collapse;
      margin: 8px 0;
      table-layout: fixed;
    }

    th {
      font-size: 10px;
      font-weight: bold;
      border-bottom: 1px solid #000;
      padding: 4px 4px;
      text-align: $textAlign;
      text-transform: uppercase;
    }

    td {
      padding: 6px 4px;
      border-bottom: 1px dashed #eee;
      text-align: $textAlign;
      vertical-align: top;
      word-break: break-word;
    }

    tr:last-child td {
      border-bottom: none;
    }

    .item-name {
      width: 36%;
      word-break: break-word;
    }

    .item-qty {
      width: 12%;
      text-align: center;
    }

    .item-price {
      width: 26%;
      text-align: right;
    }

    .item-total {
      width: 26%;
      text-align: right;
    }

    /* Adjust alignments based on document direction */
    html[dir="rtl"] th.item-qty, html[dir="rtl"] td.item-qty {
      text-align: center;
    }
    html[dir="rtl"] th.item-price, html[dir="rtl"] td.item-price {
      text-align: left;
    }
    html[dir="rtl"] th.item-total, html[dir="rtl"] td.item-total {
      text-align: left;
    }
    html[dir="ltr"] th.item-price, html[dir="ltr"] td.item-price {
      text-align: right;
    }
    html[dir="ltr"] th.item-total, html[dir="ltr"] td.item-total {
      text-align: right;
    }

    .item-options {
      font-size: 9px;
      font-style: italic;
      color: #555;
      margin-top: 2px;
      padding-left: 6px;
    }

    html[dir="rtl"] .item-options {
      padding-left: 0;
      padding-right: 6px;
    }

    .totals-section {
      margin-top: 8px;
    }

    .totals-row {
      display: flex;
      justify-content: space-between;
      margin-bottom: 4px;
      font-size: 11px;
    }

    .grand-total {
      font-size: 14px;
      font-weight: bold;
      margin-top: 6px;
    }

    .footer {
      margin-top: 16px;
      text-align: center;
      font-size: 9px;
      color: #444;
      line-height: 1.4;
    }

    @media print {
      html, body {
        width: 72.1mm;
        height: auto;
      }
      .receipt {
        padding: 0;
      }
      @page {
        margin: 0;
      }
    }
  </style>
</head>
<body>
  <div class="receipt">
    <div class="header">
      <h1>${_escapeHtml(labels.receipt)}</h1>
      <h2>${_escapeHtml(restaurantName)}</h2>
    </div>

    <div class="divider"></div>

    <div class="meta-section">
      <div class="meta-row">
        <span class="meta-label">${_escapeHtml(labels.orderId)}:</span>
        <span class="meta-value" style="direction: ltr; display: inline-block;">${_escapeHtml(displayOrderId)}</span>
      </div>
      <div class="meta-row">
        <span class="meta-label">${_escapeHtml(labels.date)}:</span>
        <span class="meta-value">${dateFormatter.format(order.createdAt.toLocal())}</span>
      </div>
      <div class="meta-row">
        <span class="meta-label">${_escapeHtml(labels.customer)}:</span>
        <span class="meta-value">${_escapeHtml(resolvedCustomerName)}</span>
      </div>
      <div class="meta-row">
        <span class="meta-label">${_escapeHtml(labels.phone)}:</span>
        <span class="meta-value" style="direction: ltr; display: inline-block;">${_escapeHtml(resolvedCustomerPhone)}</span>
      </div>
      <div class="meta-row">
        <span class="meta-label">${_escapeHtml(labels.address)}:</span>
        <span class="meta-value">${_escapeHtml(resolvedCustomerAddress)}</span>
      </div>
    </div>

    <div class="double-divider"></div>

    <table>
      <thead>
        <tr>
          <th class="item-name">${_escapeHtml(labels.item)}</th>
          <th class="item-qty">${_escapeHtml(labels.qty)}</th>
          <th class="item-price">${_escapeHtml(labels.unitPrice)}</th>
          <th class="item-total">${_escapeHtml(labels.total)}</th>
        </tr>
      </thead>
      <tbody>
        $itemsHtml
      </tbody>
    </table>

    <div class="divider"></div>

    <div class="totals-section">
      <div class="totals-row">
        <span>${_escapeHtml(labels.subtotal)}:</span>
        <span>${currencyFormatter.format(order.subtotal)}</span>
      </div>
      <div class="totals-row">
        <span>${_escapeHtml(labels.deliveryFee)}:</span>
        <span>${currencyFormatter.format(order.deliveryFee)}</span>
      </div>
      <div class="totals-row">
        <span>${_escapeHtml(labels.discount)}:</span>
        <span>${currencyFormatter.format(order.discount)}</span>
      </div>
      <div class="totals-row grand-total">
        <span>${_escapeHtml(labels.total)}:</span>
        <span>${currencyFormatter.format(order.total)}</span>
      </div>
    </div>

    <div class="divider"></div>

    <div class="footer">
      <p>${_escapeHtml(labels.thankYou)}</p>
      
      <!-- App Download QR Code -->
      <div class="qr-box" style="margin-top: 14px;">
        <img src="$downloadQrImageUrl" alt="Download QR" />
        <div class="qr-label">${_escapeHtml(labels.downloadApp)}</div>
      </div>
    </div>
  </div>
  <script>
    window.onload = function() {
      setTimeout(function() {
        window.print();
      }, 300);
    };
  </script>
</body>
</html>
''';
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
  final html = buildVendorOrderReceiptHtml(
    order: order,
    restaurantName: restaurantName,
    title: title,
    language: language,
    customerName: customerName,
    customerPhone: customerPhone,
    customerAddress: customerAddress,
    itemTranslations: itemTranslations,
    orderItems: orderItems,
  );

  final newWindow = web.window.open('', '_blank', 'width=320,height=900');
  if (newWindow == null) return;

  newWindow.document.write(html.toJS);
  newWindow.document.close();
  newWindow.focus();
}

String _displayValue(String? value, String fallback) {
  if (value == null || value.trim().isEmpty) return fallback;
  return value.trim();
}

String _escapeHtml(String value) {
  return value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');
}

String _cleanAddress(String address, ReceiptPrintLanguage language) {
  var cleaned = address;
  
  // Remove phone numbers from the address string (e.g. "Phone: +20 01508399092" or "هاتف: 01508399092")
  cleaned = cleaned.replaceAll(RegExp(r'\b(Phone|phone|هاتف):\s*[^\),]+'), '');
  
  // Clean up any double commas or leading/trailing commas inside parentheses
  cleaned = cleaned.replaceAll(RegExp(r'\(\s*,\s*'), '(');
  cleaned = cleaned.replaceAll(RegExp(r'\s*,\s*\)'), ')');
  cleaned = cleaned.replaceAll(RegExp(r',\s*,'), ',');
  
  // Remove empty parentheses
  cleaned = cleaned.replaceAll(RegExp(r'\(\s*\)'), '');
  
  // Replace the separator ". Area: " or ". المنطقة: " with a comma to make it flow better
  cleaned = cleaned.replaceAll(RegExp(r'\.\s*(Area|المنطقة):\s*'), ', ');
  
  // Clean up double spaces/commas that might result from removal
  cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');
  cleaned = cleaned.replaceAll(RegExp(r',\s*,'), ',');
  cleaned = cleaned.trim();

  // Translate labels based on target language
  final isAr = language == ReceiptPrintLanguage.ar;
  
  // 1. Translate the type prefix (e.g. "Apartment (" -> "شقة (")
  final typeMap = {
    'apartment': isAr ? 'شقة' : 'Apartment',
    'Apartment': isAr ? 'شقة' : 'Apartment',
    'شقة': isAr ? 'شقة' : 'Apartment',
    'villa': isAr ? 'فيلا' : 'Villa',
    'Villa': isAr ? 'فيلا' : 'Villa',
    'فيلا': isAr ? 'فيلا' : 'Villa',
    'office': isAr ? 'مكتب' : 'Office',
    'Office': isAr ? 'مكتب' : 'Office',
    'مكتب': isAr ? 'مكتب' : 'Office',
  };
  
  for (final entry in typeMap.entries) {
    cleaned = cleaned.replaceAll(RegExp('^${entry.key}\\s*\\('), '${entry.value} (');
  }

  // 2. Translate keys inside parentheses (followed by a colon)
  final keyMap = {
    'Building': isAr ? 'عمارة' : 'Building',
    'building': isAr ? 'عمارة' : 'Building',
    'عمارة': isAr ? 'عمارة' : 'Building',
    
    'Apt': isAr ? 'شقة' : 'Apt',
    'apt': isAr ? 'شقة' : 'Apt',
    
    'Floor': isAr ? 'دور' : 'Floor',
    'floor': isAr ? 'دور' : 'Floor',
    'دور': isAr ? 'دور' : 'Floor',
    
    'Street': isAr ? 'شارع' : 'Street',
    'street': isAr ? 'شارع' : 'Street',
    'شارع': isAr ? 'شارع' : 'Street',
    
    'Landmark': isAr ? 'علامة مميزة' : 'Landmark',
    'landmark': isAr ? 'علامة مميزة' : 'Landmark',
    'علامة مميزة': isAr ? 'علامة مميزة' : 'Landmark',
    
    // 'شقة' is used for both 'Apartment' type and 'Apt' unit in Arabic.
    // Inside parenthesis, it translates to 'Apt' in English.
    'شقة': isAr ? 'شقة' : 'Apt',
  };

  for (final entry in keyMap.entries) {
    cleaned = cleaned.replaceAll(RegExp('\\b${entry.key}\\s*:'), '${entry.value}:');
  }
  
  // Remove trailing or leading comma if present
  if (cleaned.startsWith(',')) {
    cleaned = cleaned.substring(1).trim();
  }
  if (cleaned.endsWith(',')) {
    cleaned = cleaned.substring(0, cleaned.length - 1).trim();
  }
  
  return cleaned;
}
