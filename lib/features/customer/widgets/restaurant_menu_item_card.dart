import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:z_speed/components/shimmer_loading.dart';
import 'package:z_speed/features/restaurant/model/menu_item.dart' as models;
import 'package:z_speed/l10n/app_localizations.dart';

/// Grid Card layout for vendor menu items (Cards view style).
class RestaurantMenuItemCard extends StatelessWidget {
  final models.MenuItem item;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final bool showEditButton;

  const RestaurantMenuItemCard({
    super.key,
    required this.item,
    this.onTap,
    this.onEdit,
    this.showEditButton = false,
  });

  static const _brandOrange = Color(0xFFF35535);

  @override
  Widget build(BuildContext context) {
    final hasDiscount =
        item.discountedPrice != null && item.discountedPrice! < item.price;
    final displayPrice = item.discountedPrice ?? item.price;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            Column(
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
                        if (item.imageUrl.isNotEmpty)
                          CachedNetworkImage(
                            imageUrl: item.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const ShimmerLoading(
                              width: double.infinity,
                              height: double.infinity,
                            ),
                            errorWidget: (_, _, _) => _buildPlaceholder(),
                          )
                        else
                          _buildPlaceholder(),
                        if (!item.isAvailable)
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
                                AppLocalizations.of(context)!.unavailable,
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
                              item.getLocalizedName(
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
                            const SizedBox(height: 3),
                            Text(
                              item.getLocalizedDescription(
                                Localizations.localeOf(context).languageCode,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),

                        // Price Row
                        Row(
                          children: [
                            if (hasDiscount) ...[
                              Text(
                                AppLocalizations.of(context)!.egpAmount(
                                  displayPrice.toStringAsFixed(2),
                                ),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: _brandOrange,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                AppLocalizations.of(context)!.egpAmount(
                                  item.price.toStringAsFixed(2),
                                ),
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: Colors.grey[400],
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ] else
                              Text(
                                AppLocalizations.of(context)!.egpAmount(
                                  item.price.toStringAsFixed(2),
                                ),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: _brandOrange,
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

            // Edit button overlay for Owner
            if (showEditButton && onEdit != null)
              PositionedDirectional(
                top: 6,
                end: 6,
                child: GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x26000000),
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 15,
                      color: _brandOrange,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[100],
      child: const Center(
        child: Icon(
          Icons.fastfood_rounded,
          size: 32,
          color: Colors.grey,
        ),
      ),
    );
  }
}
