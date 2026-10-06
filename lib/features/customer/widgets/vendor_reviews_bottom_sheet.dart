import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:z_speed/core/injection.dart';
import 'package:z_speed/features/review/datasource/review_firebase_datasource.dart';
import 'package:z_speed/features/review/model/review.dart';
import 'package:z_speed/l10n/app_localizations.dart';

/// Modal bottom sheet showing customer reviews for a specific vendor.
class VendorReviewsBottomSheet extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;
  final double rating;
  final int ratingCount;

  const VendorReviewsBottomSheet._({
    required this.restaurantId,
    required this.restaurantName,
    required this.rating,
    required this.ratingCount,
  });

  /// Displays the reviews bottom sheet modal for the given restaurant/vendor.
  static Future<void> show({
    required BuildContext context,
    required String restaurantId,
    required String restaurantName,
    required double rating,
    required int ratingCount,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VendorReviewsBottomSheet._(
        restaurantId: restaurantId,
        restaurantName: restaurantName,
        rating: rating,
        ratingCount: ratingCount,
      ),
    );
  }

  @override
  State<VendorReviewsBottomSheet> createState() =>
      _VendorReviewsBottomSheetState();
}

class _VendorReviewsBottomSheetState
    extends State<VendorReviewsBottomSheet> {
  late Future<List<Review>> _reviewsFuture;

  @override
  void initState() {
    super.initState();
    _reviewsFuture = getIt<ReviewFirebaseDatasource>().fetchReviews(
      restaurantId: widget.restaurantId,
      limit: 30,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Title Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.customerReviewsTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.restaurantName,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(height: 24),

          // Rating summary banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFFFF9E6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFFFC107).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            widget.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFFC107),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '/ 5.0',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: List.generate(5, (i) {
                          final star = i + 1;
                          return Icon(
                            star <= widget.rating.round()
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: const Color(0xFFFFC107),
                            size: 18,
                          );
                        }),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        l.reviewsCount(widget.ratingCount),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l.customerFeedback,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Reviews List
          Expanded(
            child: FutureBuilder<List<Review>>(
              future: _reviewsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      l.failedSubmitReview,
                      style: TextStyle(color: Colors.red.shade400),
                    ),
                  );
                }

                final reviews = snapshot.data ?? [];
                if (reviews.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.rate_review_outlined,
                          size: 48,
                          color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l.noReviewsYet,
                          style: TextStyle(
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: reviews.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final review = reviews[index];
                    return _ReviewCard(review: review, isDark: isDark);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Review review;
  final bool isDark;

  const _ReviewCard({required this.review, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Rating Stars
              Row(
                children: List.generate(5, (i) {
                  final star = i + 1;
                  return Icon(
                    star <= review.rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: const Color(0xFFFFC107),
                    size: 16,
                  );
                }),
              ),
              const SizedBox(width: 8),
              Text(
                review.rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                dateFormat.format(review.createdAt),
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                ),
              ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              review.comment!,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey.shade200 : Colors.black87,
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
