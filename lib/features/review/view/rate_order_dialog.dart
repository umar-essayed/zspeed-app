import 'package:flutter/material.dart';
import 'package:z_speed/core/injection.dart';
import 'package:z_speed/features/review/datasource/review_firebase_datasource.dart';
import 'package:z_speed/l10n/app_localizations.dart';

/// Full-featured rating dialog — fully localized (AR/EN).
class RateOrderDialog extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;
  final String customerId;
  final String orderId;

  const RateOrderDialog._({
    required this.restaurantId,
    required this.restaurantName,
    required this.customerId,
    required this.orderId,
  });

  /// Shows the dialog and returns `true` if the review was submitted.
  static Future<bool> show({
    required BuildContext context,
    required String restaurantId,
    required String restaurantName,
    required String customerId,
    required String orderId,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RateOrderDialog._(
        restaurantId: restaurantId,
        restaurantName: restaurantName,
        customerId: customerId,
        orderId: orderId,
      ),
    );
    return result ?? false;
  }

  @override
  State<RateOrderDialog> createState() => _RateOrderDialogState();
}

class _RateOrderDialogState extends State<RateOrderDialog> {
  double _rating = 0;
  final _commentCtrl = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  List<String> _labels(AppLocalizations l) => [
        '',
        l.ratingLabelTerrible,
        l.ratingLabelBad,
        l.ratingLabelOkay,
        l.ratingLabelGood,
        l.ratingLabelExcellent,
      ];

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(AppLocalizations l) async {
    if (_rating == 0) {
      setState(() => _error = l.pleaseSelectRating);
      return;
    }
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final datasource = getIt<ReviewFirebaseDatasource>();
      final alreadyReviewed = await datasource.hasReviewed(
        restaurantId: widget.restaurantId,
        orderId: widget.orderId,
      );

      if (alreadyReviewed) {
        if (mounted) Navigator.pop(context, false);
        return;
      }

      await datasource.submitReview(
        restaurantId: widget.restaurantId,
        customerId: widget.customerId,
        orderId: widget.orderId,
        rating: _rating,
        comment: _commentCtrl.text,
      );

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _error = l.failedSubmitReview;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final labels = _labels(l);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      title: Column(
        children: [
          const Icon(Icons.star_rounded, color: Color(0xFFFFC107), size: 48),
          const SizedBox(height: 8),
          Text(
            l.rateYourOrder,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            l.rateDialogSubtitle(widget.restaurantName),
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),

            // ── Stars ──────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final star = i + 1;
                return GestureDetector(
                  onTap: () => setState(() => _rating = star.toDouble()),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      star <= _rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: star <= _rating
                          ? const Color(0xFFFFC107)
                          : Colors.grey.shade400,
                      size: 40,
                    ),
                  ),
                );
              }),
            ),

            // ── Label ──────────────────────────────────────────────
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: Text(
                _rating > 0 ? labels[_rating.toInt()] : l.tapToRate,
                key: ValueKey(_rating),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _rating > 0
                      ? const Color(0xFFFFC107)
                      : Colors.grey.shade400,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Comment ────────────────────────────────────────────
            TextField(
              controller: _commentCtrl,
              maxLines: 3,
              maxLength: 300,
              decoration: InputDecoration(
                hintText: l.shareExperienceHint,
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFFFC107)),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),

            // ── Error ──────────────────────────────────────────────
            if (_error != null) ...[
              const SizedBox(height: 4),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],

            const SizedBox(height: 8),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context, false),
          child: Text(l.skipRating,
              style: const TextStyle(color: Colors.black45)),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : () => _submit(l),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFC107),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.black),
                )
              : Text(l.submitRating,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
