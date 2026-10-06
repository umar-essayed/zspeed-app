import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:z_speed/features/payment/datasource/paylink_datasource.dart';

class AddCardBottomSheet extends StatefulWidget {
  final PaylinkDatasource datasource;

  const AddCardBottomSheet({super.key, required this.datasource});

  static Future<bool?> show(BuildContext context, PaylinkDatasource datasource) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddCardBottomSheet(datasource: datasource),
    );
  }

  @override
  State<AddCardBottomSheet> createState() => _AddCardBottomSheetState();
}

class _AddCardBottomSheetState extends State<AddCardBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  bool _setAsDefault = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  String _mapErrorMessage(String error, bool isAr) {
    final lower = error.toLowerCase();
    if (lower.contains('declined') || lower.contains('202')) {
      return isAr
          ? 'تم رفض البطاقة من قبل البنك المصدر. يرجى مراجعة البنك أو تجربة بطاقة أخرى.'
          : 'Card was declined by issuing bank. Please contact your bank or try another card.';
    }
    if (lower.contains('unsupported') || lower.contains('brand')) {
      return isAr
          ? 'نوع هذه البطاقة غير مدعوم حالياً. يرجى استخدام فيزا، ماستركارد، أو ميزة.'
          : 'This card brand is currently unsupported. Please use Visa, MasterCard, or Meeza.';
    }
    if (lower.contains('expired') || lower.contains('expiry')) {
      return isAr
          ? 'تاريخ انتهاء البطاقة غير صحيح أو البطاقة منتهية الصلاحية.'
          : 'Invalid expiry date or card has expired.';
    }
    if (lower.contains('cvv') || lower.contains('security')) {
      return isAr
          ? 'رمز الأمان CVV غير صحيح.'
          : 'Invalid CVV security code.';
    }
    return isAr
        ? 'تعذر حفظ البطاقة. يرجى التحقق من صحة البيانات والمحاولة مجدداً.'
        : 'Failed to save card. Please check details and try again.';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    setState(() => _isLoading = true);

    try {
      final nameParts = _nameController.text.trim().split(' ');
      final firstName = nameParts.first;
      final lastName =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : 'Cardholder';

      final expiryParts = _expiryController.text.trim().split('/');
      final expMonth = expiryParts[0].trim().padLeft(2, '0');
      String expYear = expiryParts[1].trim();
      if (expYear.length == 2) {
        expYear = '20$expYear';
      }

      final rawCardNumber =
          _cardNumberController.text.replaceAll(' ', '').trim();
      final cvv = _cvvController.text.trim();

      await widget.datasource.saveCard(
        firstName: firstName,
        lastName: lastName,
        cardNumber: rawCardNumber,
        cardExpiryMonth: expMonth,
        cardExpiryYear: expYear,
        cardCvv: cvv.isNotEmpty ? cvv : null,
        setAsDefault: _setAsDefault,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        final friendlyMsg = _mapErrorMessage(e.toString(), isAr);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyMsg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFF35535);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.credit_card, color: orange, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    isAr ? 'إضافة بطاقة دفع جديدة' : 'Add New Card',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Cardholder Name
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: isAr ? 'اسم صاحب البطاقة' : 'Cardholder Name',
                  hintText: isAr ? 'مثال: محمد أحمد' : 'e.g. John Doe',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) => (val == null || val.trim().isEmpty)
                    ? (isAr ? 'يرجى إدخال اسم صاحب البطاقة' : 'Please enter cardholder name')
                    : null,
              ),
              const SizedBox(height: 14),

              // Card Number
              TextFormField(
                controller: _cardNumberController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(19),
                  _CardNumberFormatter(),
                ],
                decoration: InputDecoration(
                  labelText: isAr ? 'رقم البطاقة' : 'Card Number',
                  hintText: '4111 1111 1111 1111',
                  prefixIcon: const Icon(Icons.payment_outlined),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) {
                  final digits = val?.replaceAll(' ', '') ?? '';
                  if (digits.length < 13 || digits.length > 19) {
                    return isAr
                        ? 'يرجى إدخال رقم بطاقة صحيح'
                        : 'Please enter a valid card number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Expiry & CVV
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _expiryController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                        _ExpiryDateFormatter(),
                      ],
                      decoration: InputDecoration(
                        labelText: isAr ? 'الانتهاء (MM/YY)' : 'Expiry (MM/YY)',
                        hintText: '12/28',
                        prefixIcon: const Icon(Icons.calendar_today_outlined),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) {
                        if (val == null || !val.contains('/') || val.length < 5) {
                          return isAr ? 'تاريخ غير صالح' : 'MM/YY required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextFormField(
                      controller: _cvvController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      decoration: InputDecoration(
                        labelText: isAr ? 'رمز الأمان (CVV)' : 'CVV',
                        hintText: '123',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) {
                        if (val == null || val.length < 3) {
                          return isAr ? 'رمز CVV مطلوب' : 'CVV required';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Default checkbox
              Row(
                children: [
                  Checkbox(
                    value: _setAsDefault,
                    activeColor: orange,
                    onChanged: (val) =>
                        setState(() => _setAsDefault = val ?? false),
                  ),
                  Text(
                    isAr
                        ? 'تعيين كبطاقة دفع افتراضية'
                        : 'Set as default payment card',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          isAr
                              ? 'حفظ البطاقة واستخدامها'
                              : 'Save & Use Card',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(text[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll('/', '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i == 2) buffer.write('/');
      buffer.write(text[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
