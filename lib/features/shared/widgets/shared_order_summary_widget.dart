import 'package:z_speed/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:z_speed/core/enums/order_enums.dart';
import 'package:z_speed/features/order/model/order.dart';
import 'package:z_speed/features/order/model/order_item.dart';

class SharedOrderSummaryWidget extends StatelessWidget {
  final Order order;
  final List<OrderItem> items;
  final Map<String, String>? itemTranslations;

  const SharedOrderSummaryWidget({
    super.key,
    required this.order,
    required this.items,
    this.itemTranslations,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.orderSummary,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (items.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    AppLocalizations.of(context)!.loadingItems,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...items.map((item) => _buildOrderItemTile(context, item)),
            const Divider(height: 24),
            // Subtotal (items only)
            _buildPriceRow(
              context,
              AppLocalizations.of(context)!.subtotal,
              order.subtotal,
            ),
            const SizedBox(height: 8),
            // Tax
            if (order.tax > 0) ...[
              _buildPriceRow(
                context,
                AppLocalizations.of(context)!.taxFourteen,
                order.tax,
              ),
              const SizedBox(height: 8),
            ],
            // Delivery Fee
            _buildPriceRow(
              context,
              AppLocalizations.of(context)!.deliveryFee,
              order.deliveryFee,
            ),
            // Service Fee
            if (order.serviceFee > 0) ...[
              const SizedBox(height: 8),
              _buildPriceRow(
                context,
                AppLocalizations.of(context)!.serviceFeeSimple,
                order.serviceFee,
              ),
            ],
            // Discount
            if (order.discount > 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        AppLocalizations.of(context)!.discountLabel,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.green,
                        ),
                      ),
                      if (order.appliedPromoCode != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            order.appliedPromoCode!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    '-${AppLocalizations.of(context)!.egpAmount(order.discount.toStringAsFixed(2))}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.total,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!.egpAmount(
                    order.total.toStringAsFixed(2),
                  ),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            if (order.paymentStatus == PaymentStatus.completed &&
                (order.paymentMethod == PaymentMethodType.card ||
                    order.paymentMethod == PaymentMethodType.wallet)) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        order.paymentMethod == PaymentMethodType.card
                            ? Icons.credit_card_rounded
                            : Icons.account_balance_wallet_rounded,
                        size: 16,
                        color: const Color(0xFF16A34A),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        Localizations.localeOf(context).languageCode == 'ar'
                            ? (order.paymentMethod == PaymentMethodType.card
                                ? 'المدفوع إلكترونياً بالبطاقة'
                                : 'المدفوع من المحفظة')
                            : (order.paymentMethod == PaymentMethodType.card
                                ? 'Paid by Card'
                                : 'Paid by Wallet'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '-${AppLocalizations.of(context)!.egpAmount(order.total.toStringAsFixed(2))}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF16A34A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    Localizations.localeOf(context).languageCode == 'ar'
                        ? 'المتبقي للدفع عند الاستلام'
                        : 'Remaining on Delivery',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context)!.egpAmount('0.00'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ],
            if (order.customerNote != null &&
                order.customerNote!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.noteLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.customerNote!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItemTile(BuildContext context, OrderItem item) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                item.quantity % 1 == 0
                    ? '${item.quantity.toInt()}x'
                    : '${item.quantity}x',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Text(
                  (() {
                    final langCode = Localizations.localeOf(context).languageCode;
                    if (langCode == 'ar') {
                      return item.menuItemNameAr ?? itemTranslations?[item.menuItemId] ?? item.menuItemName;
                    }
                    return item.menuItemName;
                  })(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (item.selectedVariantName != null &&
                    item.selectedVariantName!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.getLocalizedVariantName(
                          Localizations.localeOf(context).languageCode),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
                if (item.selectedAddons.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  ...item.selectedAddons.map(
                    (addon) => Text(
                      AppLocalizations.of(context)!.addonLine(addon.optionName,
                          addon.extraPrice.toStringAsFixed(2)),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
                if (item.specialNote != null &&
                    item.specialNote!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context)!
                        .notePrefixed(item.specialNote!),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            AppLocalizations.of(context)!
                .egpAmount(item.itemTotal.toStringAsFixed(2).toString()),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(
    BuildContext context,
    String label,
    double amount,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        Text(
          AppLocalizations.of(context)!.egpAmount(
            amount.toStringAsFixed(2),
          ),
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }
}
