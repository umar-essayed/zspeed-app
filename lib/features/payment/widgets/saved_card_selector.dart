import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:z_speed/features/payment/datasource/paylink_datasource.dart';
import 'package:z_speed/features/payment/model/saved_card_model.dart';
import 'package:z_speed/features/payment/widgets/add_card_bottom_sheet.dart';

class SavedCardSelector extends StatelessWidget {
  final PaylinkDatasource datasource;
  final SavedCardModel? selectedCard;
  final bool useHostedCheckout;
  final ValueChanged<SavedCardModel?> onCardSelected;
  final ValueChanged<bool> onHostedCheckoutChanged;

  const SavedCardSelector({
    super.key,
    required this.datasource,
    required this.selectedCard,
    required this.useHostedCheckout,
    required this.onCardSelected,
    required this.onHostedCheckoutChanged,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    const orange = Color(0xFFF35535);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return StreamBuilder<List<SavedCardModel>>(
      stream: datasource.streamSavedCards(user.uid),
      builder: (context, snapshot) {
        final cards = snapshot.data ?? [];

        // Auto-select default/first card if available and none selected yet
        if (cards.isNotEmpty && selectedCard == null && !useHostedCheckout) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final defaultCard =
                cards.firstWhere((c) => c.isDefault, orElse: () => cards.first);
            onCardSelected(defaultCard);
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (cards.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isAr ? 'البطاقات المحفوظة' : 'Saved Cards',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => AddCardBottomSheet.show(context, datasource),
                    icon: const Icon(Icons.add, size: 16, color: orange),
                    label: Text(
                      isAr ? 'إضافة بطاقة' : 'Add Card',
                      style: const TextStyle(
                        color: orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ...cards.map((card) {
                final isSelected = !useHostedCheckout && selectedCard?.id == card.id;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? orange : Colors.grey.shade200,
                      width: isSelected ? 1.8 : 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    leading: Icon(
                      card.brand.toLowerCase().contains('visa')
                          ? Icons.credit_card
                          : Icons.payment,
                      color: isSelected ? orange : Colors.grey[700],
                      size: 26,
                    ),
                    title: Text(
                      '${card.brand} •••• ${card.last4}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: Text(
                      isAr
                          ? 'تنتهي ${card.formattedExpiry}'
                          : 'Expires ${card.formattedExpiry}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Radio<String>(
                          value: card.id,
                          groupValue: useHostedCheckout ? null : selectedCard?.id,
                          activeColor: orange,
                          onChanged: (_) {
                            onHostedCheckoutChanged(false);
                            onCardSelected(card);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              size: 20, color: Colors.grey),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text(isAr ? 'حذف البطاقة' : 'Delete Card'),
                                content: Text(
                                  isAr
                                      ? 'هل أنت متأكد من حذف ${card.brand} •••• ${card.last4}؟'
                                      : 'Remove ${card.brand} •••• ${card.last4}?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: Text(isAr ? 'إلغاء' : 'Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red),
                                    child: Text(
                                      isAr ? 'حذف' : 'Delete',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await datasource.deleteCard(card.id);
                            }
                          },
                        ),
                      ],
                    ),
                    onTap: () {
                      onHostedCheckoutChanged(false);
                      onCardSelected(card);
                    },
                  ),
                );
              }),
            ] else ...[
              // Prompt banner when no cards are saved yet
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBF8F5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFF0E5D8)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: orange.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.credit_card_rounded,
                          color: orange, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAr ? 'لم تحفظ أي بطاقة بعد' : 'No saved cards yet',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13.5),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isAr
                                ? 'أضف بطاقتك لمرة واحدة واستمتع بالدفع السريع.'
                                : 'Save your card for fast 1-click checkout.',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () =>
                          AddCardBottomSheet.show(context, datasource),
                      icon: const Icon(Icons.add, size: 16),
                      label: Text(isAr ? 'إضافة' : 'Add'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Clean, simplified Option: Pay with Card (direct / hosted)
            Container(
              margin: const EdgeInsets.only(top: 2, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: useHostedCheckout ? orange : Colors.grey.shade200,
                  width: useHostedCheckout ? 1.8 : 1,
                ),
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                leading: Icon(
                  Icons.payment_rounded,
                  color: useHostedCheckout ? orange : Colors.grey[700],
                  size: 26,
                ),
                title: Text(
                  isAr ? 'الدفع بالكارت' : 'Pay with Card',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 13,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isAr ? 'دفع آمن ومحمي' : 'Secure Payment',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                trailing: Radio<bool>(
                  value: true,
                  groupValue: useHostedCheckout ? true : null,
                  activeColor: orange,
                  onChanged: (_) {
                    onHostedCheckoutChanged(true);
                    onCardSelected(null);
                  },
                ),
                onTap: () {
                  onHostedCheckoutChanged(true);
                  onCardSelected(null);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
