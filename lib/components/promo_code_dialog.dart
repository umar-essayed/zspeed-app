import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A modern, branded promo code dialog with live countdown timer designed for Z_Speed app.
class PromoCodeDialog extends StatelessWidget {
  final String code;
  final DateTime? expiresAt;

  const PromoCodeDialog({
    super.key,
    required this.code,
    this.expiresAt,
  });

  /// Displays the [PromoCodeDialog].
  static Future<void> show(
    BuildContext context,
    String code, {
    DateTime? expiresAt,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => PromoCodeDialog(
        code: code,
        expiresAt: expiresAt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    const primaryOrange = Color(0xFFF35535);
    const secondaryYellow = Color(0xFFFF9800);

    final targetExpiry = expiresAt ??
        DateTime.now().add(const Duration(hours: 23, minutes: 59, seconds: 59));

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 16,
      backgroundColor: Colors.white,
      clipBehavior: Clip.antiAlias,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Header Banner with Gradient
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryOrange, secondaryYellow],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.card_giftcard_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isAr ? 'كود خصم حصري! 🎉' : 'Exclusive Promo Code! 🎉',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                // Close Button Top Corner
                PositionedDirectional(
                  top: 8,
                  end: 8,
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),

            // Content Body
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    isAr
                        ? 'استخدم كود الخصم التالي عند إتمام الطلب للحصول على التخفيض المباشر!'
                        : 'Use this promo code at checkout to enjoy your special discount!',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 14,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Live Expiration Countdown Badge
                  _PromoCountdownBadge(
                    targetTime: targetExpiry,
                    isAr: isAr,
                  ),
                  const SizedBox(height: 18),

                  // Coupon Ticket Container
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: primaryOrange.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: primaryOrange.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.confirmation_number_outlined,
                          color: primaryOrange,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SelectableText(
                            code,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                              color: primaryOrange,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Copy Code Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryOrange,
                        foregroundColor: Colors.white,
                        elevation: 3,
                        shadowColor: primaryOrange.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.copy_rounded, size: 20),
                      label: Text(
                        isAr ? 'نسخ الكود واستخدامه' : 'Copy Code & Use',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: code));
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: Colors.white),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    isAr
                                        ? 'تم نسخ كود الخصم ($code) بنجاح!'
                                        : 'Promo code ($code) copied to clipboard!',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: const Color(0xFF2E7D32),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A widget displaying a live 1-second interval countdown badge.
class _PromoCountdownBadge extends StatefulWidget {
  final DateTime targetTime;
  final bool isAr;

  const _PromoCountdownBadge({
    required this.targetTime,
    required this.isAr,
  });

  @override
  State<_PromoCountdownBadge> createState() => _PromoCountdownBadgeState();
}

class _PromoCountdownBadgeState extends State<_PromoCountdownBadge> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _calculateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _calculateRemaining();
    });
  }

  void _calculateRemaining() {
    final now = DateTime.now();
    final diff = widget.targetTime.difference(now);
    final newRemaining = diff.isNegative ? Duration.zero : diff;
    if (mounted && newRemaining != _remaining) {
      setState(() {
        _remaining = newRemaining;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_remaining == Duration.zero) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, color: Colors.red.shade700, size: 18),
            const SizedBox(width: 6),
            Text(
              widget.isAr ? 'انتهت صلاحية هذا الكود' : 'This code has expired',
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    final hours = _remaining.inHours.toString().padLeft(2, '0');
    final minutes = (_remaining.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (_remaining.inSeconds % 60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFB74D)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.alarm_rounded,
            color: Color(0xFFE65100),
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            widget.isAr ? 'ينتهي الخصم خلال: ' : 'Offer ends in: ',
            style: const TextStyle(
              color: Color(0xFFE65100),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            '$hours:$minutes:$seconds',
            style: const TextStyle(
              color: Color(0xFFE65100),
              fontSize: 14,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
