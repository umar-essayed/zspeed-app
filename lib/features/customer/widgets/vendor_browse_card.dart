import 'package:z_speed/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:z_speed/features/restaurant/model/restaurant.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:z_speed/components/shimmer_loading.dart';

/// Talabat-style horizontal row restaurant card for browse screen.
///
/// Shows cover image on the left with restaurant info on the right.
class RestaurantBrowseCard extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback onTap;

  const RestaurantBrowseCard({
    super.key,
    required this.restaurant,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isClosed = !restaurant.isOpen;
    const brandOrange = Color(0xFFF35535);

    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 2,
        shadowColor: Colors.black12,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Cover Image (left side) ──
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 130,
                    height: 120,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: restaurant.coverImageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const ShimmerLoading(
                            width: double.infinity,
                            height: double.infinity,
                          ),
                          errorWidget: (_, _, _) => Container(
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.restaurant,
                              size: 36,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        if (isClosed)
                          Container(
                            color: Colors.black.withValues(alpha: 0.55),
                            alignment: Alignment.center,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                AppLocalizations.of(context)!.closed,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          )
                        else if (restaurant.isBusy)
                          Container(
                            color: Colors.black.withValues(alpha: 0.4),
                            alignment: Alignment.center,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF9800),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                AppLocalizations.of(context)!.busyModeActive,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // ── Info (right side) ──
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          restaurant.getLocalizedName(
                            Localizations.localeOf(context).languageCode,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        if (restaurant.cuisineTypes.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            restaurant.cuisineTypes.first,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: brandOrange,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: Color(0xFFFFC107),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              restaurant.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A2E),
                              ),
                            ),
                            if (restaurant.ratingCount > 0) ...[
                              const SizedBox(width: 2),
                              Text(
                                '(${_formatCount(restaurant.ratingCount)})',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 14,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${restaurant.deliveryTimeMin}-${restaurant.deliveryTimeMax} mins',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              child: Text(
                                '•',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ),
                            Flexible(
                              child: Text(
                                '${AppLocalizations.of(context)!.deliveryFee}: ${AppLocalizations.of(context)!.egpAmount(restaurant.deliveryFee.toStringAsFixed(2))}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        if (restaurant.cuisineTypes.length > 1)
                          SizedBox(
                            height: 20,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: restaurant.cuisineTypes
                                  .skip(1)
                                  .take(3)
                                  .length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 4),
                              itemBuilder: (_, i) {
                                final type = restaurant.cuisineTypes
                                    .skip(1)
                                    .elementAt(i);
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    type,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Format rating count: 1000+ → "1k+", 10000+ → "10k+"
  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(count % 1000 == 0 ? 0 : 1)}k+';
    }
    return '$count';
  }
}

/// Grid card style for browse screen (Cards view style).
///
/// Features cover image at top with rounded corners, overlay rating pill,
/// closed badge if applicable, vendor name, cuisines, delivery info at bottom.
class RestaurantBrowseGridCard extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback onTap;

  const RestaurantBrowseGridCard({
    super.key,
    required this.restaurant,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isClosed = !restaurant.isOpen;
    const brandOrange = Color(0xFFF35535);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cover Image Header ──
            AspectRatio(
              aspectRatio: 16 / 10,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(14)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: restaurant.coverImageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const ShimmerLoading(
                        width: double.infinity,
                        height: double.infinity,
                      ),
                      errorWidget: (_, _, _) => Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.restaurant,
                          size: 32,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    // Rating overlay pill on image top-end
                    PositionedDirectional(
                      top: 8,
                      end: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 13,
                              color: Color(0xFFFFC107),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              restaurant.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (isClosed)
                      Container(
                        color: Colors.black.withValues(alpha: 0.55),
                        alignment: Alignment.center,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.closed,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      )
                    else if (restaurant.isBusy)
                      Container(
                        color: Colors.black.withValues(alpha: 0.4),
                        alignment: Alignment.center,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF9800),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.busyModeActive,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Info Section ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          restaurant.getLocalizedName(
                            Localizations.localeOf(context).languageCode,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          restaurant.cuisineTypes.isNotEmpty
                              ? restaurant.cuisineTypes.join(' • ')
                              : '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: brandOrange,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 13,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${restaurant.deliveryTimeMin}-${restaurant.deliveryTimeMax}m',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.two_wheeler_rounded,
                          size: 13,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 3),
                        Text(
                          AppLocalizations.of(context)!.egpAmount(
                              restaurant.deliveryFee.toStringAsFixed(0)),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
