enum ReceiptPrintLanguage {
  en,
  ar,
}

class VendorReceiptLabels {
  final String receipt;
  final String vendor;
  final String orderId;
  final String customer;
  final String phone;
  final String date;
  final String address;
  final String item;
  final String qty;
  final String unitPrice;
  final String lineTotal;
  final String options;
  final String noItems;
  final String subtotal;
  final String deliveryFee;
  final String discount;
  final String total;
  final String scanForDetails;
  final String downloadApp;
  final String thankYou;
  final String notAvailable;
  final String htmlLang;
  final bool isRtl;

  const VendorReceiptLabels({
    required this.receipt,
    required this.vendor,
    required this.orderId,
    required this.customer,
    required this.phone,
    required this.date,
    required this.address,
    required this.item,
    required this.qty,
    required this.unitPrice,
    required this.lineTotal,
    required this.options,
    required this.noItems,
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
    required this.total,
    required this.scanForDetails,
    required this.downloadApp,
    required this.thankYou,
    required this.notAvailable,
    required this.htmlLang,
    required this.isRtl,
  });

  factory VendorReceiptLabels.forLanguage(ReceiptPrintLanguage language) {
    switch (language) {
      case ReceiptPrintLanguage.en:
        return const VendorReceiptLabels(
          receipt: 'Receipt',
          vendor: 'Vendor',
          orderId: 'Order ID',
          customer: 'Customer',
          phone: 'Phone',
          date: 'Date',
          address: 'Address',
          item: 'Item',
          qty: 'Qty',
          unitPrice: 'Unit',
          lineTotal: 'Total',
          options: 'Options',
          noItems: 'No items listed.',
          subtotal: 'Subtotal',
          deliveryFee: 'Delivery Fee',
          discount: 'Discount',
          total: 'Total',
          scanForDetails: 'Scan for order details',
          downloadApp: 'Download Z Speed App',
          thankYou: 'Thank you for ordering with Z Speed.',
          notAvailable: 'N/A',
          htmlLang: 'en',
          isRtl: false,
        );
      case ReceiptPrintLanguage.ar:
        return const VendorReceiptLabels(
          receipt: 'إيصال',
          vendor: 'المتجر',
          orderId: 'رقم الطلب',
          customer: 'العميل',
          phone: 'الهاتف',
          date: 'التاريخ',
          address: 'العنوان',
          item: 'الصنف',
          qty: 'الكمية',
          unitPrice: 'السعر',
          lineTotal: 'الإجمالي',
          options: 'الخيارات',
          noItems: 'لا توجد أصناف.',
          subtotal: 'المجموع الفرعي',
          deliveryFee: 'رسوم التوصيل',
          discount: 'الخصم',
          total: 'الإجمالي',
          scanForDetails: 'امسح لعرض تفاصيل الطلب',
          downloadApp: 'حمل تطبيق زد سبيد',
          thankYou: 'شكراً لطلبك من Z Speed.',
          notAvailable: 'غير متوفر',
          htmlLang: 'ar',
          isRtl: true,
        );
    }
  }
}
