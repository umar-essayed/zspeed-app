import 'package:flutter/material.dart';

enum PaymentStatusType { success, failure }

class PaymentStatusSheet extends StatefulWidget {
  final PaymentStatusType type;
  final String? title;
  final String? message;
  final String? rawReason;
  final String? transactionReference;
  final VoidCallback? onPrimaryAction;
  final VoidCallback? onSecondaryAction;
  final String? primaryActionText;
  final String? secondaryActionText;

  const PaymentStatusSheet({
    super.key,
    required this.type,
    this.title,
    this.message,
    this.rawReason,
    this.transactionReference,
    this.onPrimaryAction,
    this.onSecondaryAction,
    this.primaryActionText,
    this.secondaryActionText,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required PaymentStatusType type,
    String? title,
    String? message,
    String? rawReason,
    String? transactionReference,
    VoidCallback? onPrimaryAction,
    VoidCallback? onSecondaryAction,
    String? primaryActionText,
    String? secondaryActionText,
    bool isDismissible = false,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: isDismissible,
      enableDrag: isDismissible,
      backgroundColor: Colors.transparent,
      builder: (_) => PaymentStatusSheet(
        type: type,
        title: title,
        message: message,
        rawReason: rawReason,
        transactionReference: transactionReference,
        onPrimaryAction: onPrimaryAction,
        onSecondaryAction: onSecondaryAction,
        primaryActionText: primaryActionText,
        secondaryActionText: secondaryActionText,
      ),
    );
  }

  @override
  State<PaymentStatusSheet> createState() => _PaymentStatusSheetState();
}

class _PaymentStatusSheetState extends State<PaymentStatusSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getLocalizedTitle(bool isAr) {
    if (widget.title != null) return widget.title!;
    if (widget.type == PaymentStatusType.success) {
      return isAr ? 'تم الدفع بنجاح! 🎉' : 'Payment Successful! 🎉';
    } else {
      return isAr ? 'فشلت عملية الدفع' : 'Payment Failed';
    }
  }

  String _getLocalizedMessage(bool isAr) {
    if (widget.message != null && widget.message!.isNotEmpty) {
      return widget.message!;
    }

    final reason = (widget.rawReason ?? '').toLowerCase();

    if (widget.type == PaymentStatusType.success) {
      return isAr
          ? 'تم تأكيد عملية الدفع واستلام طلبك بنجاح، وسيبدأ تجهيزه الآن.'
          : 'Your payment has been verified and your order is confirmed.';
    }

    // Dynamic failure parsing
    if (reason.contains('insufficient') || reason.contains('4051')) {
      return isAr
          ? 'عذراً، الرصيد غير كافٍ في بطاقتك لإتمام العملية. يُرجى شحن البطاقة أو استخدام وسيلة دفع أخرى.'
          : 'Insufficient funds on your card. Please top up your card or use another payment method.';
    } else if (reason.contains('expired') || reason.contains('4054')) {
      return isAr
          ? 'تاريخ صلاحية البطاقة منتهي. يُرجى مراجعة تاريخ البطاقة أو استخدام بطاقة أخرى سارية.'
          : 'Your card has expired. Please check your card expiry or try another valid card.';
    } else if (reason.contains('honor') ||
        reason.contains('bank') ||
        reason.contains('4005')) {
      return isAr
          ? 'تم رفض العملية من قِبل البنك الخاص بك. يُرجى التواصل مع خدمة عملاء البنك أو تجربة بطاقة أخرى.'
          : 'Transaction declined by your issuing bank. Please contact your bank or try another card.';
    } else if (reason.contains('stolen') ||
        reason.contains('lost') ||
        reason.contains('rejected') ||
        reason.contains('4041') ||
        reason.contains('4043') ||
        reason.contains('7001')) {
      return isAr
          ? 'تعذر قبول البطاقة لدواعي أمان مصرفية. يُرجى التواصل مع البنك الخاص بك.'
          : 'Card was rejected for security reasons. Please contact your issuing bank.';
    } else if (reason.contains('cancel') || reason.contains('cancelled')) {
      return isAr
          ? 'تم إلغاء عملية الدفع. يمكنك إعادة المحاولة في أي وقت.'
          : 'Payment was cancelled. You can retry at any time.';
    }

    return isAr
        ? 'تعذر إتمام العملية في الوقت الحالي. يُرجى التحقق من بيانات البطاقة أو تجربة وسيلة دفع بديلة.'
        : 'Payment could not be processed right now. Please check your details or try another payment method.';
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final isSuccess = widget.type == PaymentStatusType.success;

    const brandOrange = Color(0xFFF35535);
    const successGreen = Color(0xFF16A34A);
    const failureRed = Color(0xFFDC2626);

    final statusColor = isSuccess ? successGreen : failureRed;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Animated Icon Badge
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: statusColor.withValues(alpha: 0.12),
                border: Border.all(
                  color: statusColor.withValues(alpha: 0.25),
                  width: 3,
                ),
              ),
              child: Center(
                child: Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor,
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    isSuccess ? Icons.check_rounded : Icons.close_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),

          // Title
          FadeTransition(
            opacity: _fadeAnimation,
            child: Text(
              _getLocalizedTitle(isAr),
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1A1A2E),
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 10),

          // Message
          FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                _getLocalizedMessage(isAr),
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Reference Number (if available)
          if (widget.transactionReference != null &&
              widget.transactionReference!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${isAr ? 'رقم المعاملة: ' : 'Ref: '}${widget.transactionReference}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],

          const SizedBox(height: 28),

          // Action Buttons
          Row(
            children: [
              // Secondary button (if failure or action provided)
              if (widget.onSecondaryAction != null) ...[
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onSecondaryAction?.call();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2D3142),
                        side: BorderSide(color: Colors.grey[300]!, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        widget.secondaryActionText ??
                            (isAr ? 'وسيلة أخرى' : 'Change Method'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],

              // Primary button
              Expanded(
                flex: widget.onSecondaryAction != null ? 1 : 2,
                child: SizedBox(
                  height: 52,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        colors: isSuccess
                            ? [brandOrange, const Color(0xFFFF9800)]
                            : [brandOrange, brandOrange],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: brandOrange.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onPrimaryAction?.call();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        widget.primaryActionText ??
                            (isSuccess
                                ? (isAr ? 'متابعة الطلب' : 'Track Order')
                                : (isAr ? 'إعادة المحاولة' : 'Try Again')),
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
