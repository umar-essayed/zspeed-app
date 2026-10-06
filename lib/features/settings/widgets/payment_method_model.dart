/// Data model for payment methods.
class PaymentMethod {
  final String id;
  final String type;
  final String last4;
  final String expDate;
  bool isDefault;

  PaymentMethod({
    required this.id,
    required this.type,
    required this.last4,
    required this.expDate,
    required this.isDefault,
  });
}
