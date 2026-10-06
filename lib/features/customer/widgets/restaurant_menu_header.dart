import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:z_speed/features/customer/widgets/vendor_reviews_bottom_sheet.dart';
import 'package:z_speed/features/restaurant/model/restaurant.dart';
import 'package:z_speed/l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:z_speed/components/shimmer_loading.dart';

/// Talabat-style restaurant menu header.
///
/// Shows a cover image with gradient overlay, restaurant logo, name,
/// rating, delivery time, delivery fee, and open/closed status.
class RestaurantMenuHeader extends StatelessWidget {
  final Restaurant restaurant;
  final bool isOwner;

  const RestaurantMenuHeader({
    super.key,
    required this.restaurant,
    this.isOwner = false,
  });

  static const _brandOrange = Color(0xFFF35535);

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // ── Cover Image with Overlays (background) ──
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 200,
          child: Stack(
            children: [
              // Cover image
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: restaurant.coverImageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const ShimmerLoading(
                    width: double.infinity,
                    height: double.infinity,
                  ),
                  errorWidget: (_, _, _) => Container(
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.restaurant,
                      size: 64,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),

              // Gradient overlay
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.6, 1.0],
                      colors: [
                        Colors.black.withValues(alpha: 0.3),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.5),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Main content column (defines the layout height dynamically) ──
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Spacer to match the cover photo height minus the overlap
            const SizedBox(height: 184), // 200 - 16
            // Restaurant Info Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              padding: const EdgeInsetsDirectional.fromSTEB(16, 20, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo + Name row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CachedNetworkImage(
                            imageUrl: restaurant.logoUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const ShimmerLoading(
                              width: double.infinity,
                              height: double.infinity,
                            ),
                            errorWidget: (_, _, _) => Container(
                              color: Colors.white,
                              child: Icon(
                                Icons.restaurant,
                                size: 32,
                                color: Colors.grey[400],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Name + cuisine chips
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              restaurant.getLocalizedName(
                                Localizations.localeOf(context).languageCode,
                              ),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A1A),
                                fontFamily: 'Cairo',
                              ),
                            ),
                            if (restaurant.cuisineTypes.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                restaurant.cuisineTypes.join(' • '),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                  fontFamily: 'Cairo',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Info chips row ──
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        // Rating
                        Expanded(
                          child: _InfoChip(
                            icon: Icons.star_rounded,
                            iconColor: Colors.amber,
                            iconBgColor: Colors.amber.withValues(alpha: 0.15),
                            label: restaurant.rating.toStringAsFixed(1),
                            sublabel: '(${restaurant.ratingCount})',
                            onTap: () {
                              VendorReviewsBottomSheet.show(
                                context: context,
                                restaurantId: restaurant.id,
                                restaurantName: restaurant.name,
                                rating: restaurant.rating,
                                ratingCount: restaurant.ratingCount,
                              );
                            },
                          ),
                        ),

                        _divider(),

                        // Delivery time
                        Expanded(
                          child: _InfoChip(
                            icon: Icons.access_time_rounded,
                            iconColor: _brandOrange,
                            iconBgColor: _brandOrange.withValues(alpha: 0.15),
                            label:
                                '${restaurant.deliveryTimeMin}-${restaurant.deliveryTimeMax}',
                            sublabel: 'min',
                          ),
                        ),

                        _divider(),

                        // Delivery fee
                        Expanded(
                          child: _InfoChip(
                            icon: Icons.delivery_dining_rounded,
                            iconColor: Colors.teal,
                            iconBgColor: Colors.teal.withValues(alpha: 0.15),
                            label: AppLocalizations.of(context)!.egpAmount(
                              restaurant.deliveryFee.toStringAsFixed(0),
                            ),
                            sublabel: AppLocalizations.of(
                              context,
                            )!.deliverySublabel,
                          ),
                        ),

                        _divider(),

                        // Min order
                        Expanded(
                          child: _InfoChip(
                            icon: Icons.shopping_bag_outlined,
                            iconColor: Colors.blueGrey,
                            iconBgColor: Colors.blueGrey.withValues(
                              alpha: 0.15,
                            ),
                            label: AppLocalizations.of(context)!.egpAmount(
                              restaurant.minimumOrder.toStringAsFixed(0),
                            ),
                            sublabel: AppLocalizations.of(
                              context,
                            )!.minOrderSublabel,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // ── Floating back button & owner badge ──
        PositionedDirectional(
          top: 12 + topPadding,
          start: 12,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildGlassButton(
                onTap: () => Navigator.pop(context),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              if (isOwner) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _brandOrange.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.owner.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // ── Open/Closed Status Badge ──
        PositionedDirectional(
          top: 12 + topPadding,
          end: 12,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: restaurant.isOpen
                            ? Colors.greenAccent
                            : Colors.redAccent,
                        boxShadow: [
                          BoxShadow(
                            color:
                                (restaurant.isOpen
                                        ? Colors.greenAccent
                                        : Colors.redAccent)
                                    .withValues(alpha: 0.6),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      (restaurant.isOpen
                              ? AppLocalizations.of(context)!.openStatus
                              : AppLocalizations.of(context)!.closedStatus)
                          .toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassButton({
    required Widget child,
    required VoidCallback onTap,
  }) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.35),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }

  Widget _divider() {
    return Container(width: 1, height: 32, color: Colors.grey.shade200);
  }
}

/// Single info chip: icon with circular pastel background + label + sublabel stacked vertically.
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String label;
  final String sublabel;
  final VoidCallback? onTap;

  const _InfoChip({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.label,
    required this.sublabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
          child: Center(child: Icon(icon, size: 16, color: iconColor)),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          sublabel,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 10,
            color: Colors.grey[500],
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: content,
        ),
      );
    }

    return content;
  }
}
