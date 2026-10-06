import 'package:z_speed/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:z_speed/features/restaurant/model/menu_item.dart' as models;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:z_speed/components/shimmer_loading.dart';

/// Talabat-style horizontal menu item row.
///
/// [Left]  Name, description (2 lines), price/discounted price
/// [Right] Rounded square thumbnail image
class RestaurantMenuItemRow extends StatelessWidget {
  final models.MenuItem item;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;

  /// When true, shows a small edit icon button.
  final bool showEditButton;

  const RestaurantMenuItemRow({
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

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Left: Text info ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    item.getLocalizedName(
                      Localizations.localeOf(context).languageCode,
                    ),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Description
                  Text(
                    item.getLocalizedDescription(
                      Localizations.localeOf(context).languageCode,
                    ),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Price row
                  Row(
                    children: [
                      if (hasDiscount) ...[
                        Text(
                          AppLocalizations.of(context)!.egpAmount(
                            item.discountedPrice!.toStringAsFixed(2).toString(),
                          ),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _brandOrange,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          AppLocalizations.of(context)!.egpAmount(
                            item.price.toStringAsFixed(2).toString(),
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ] else
                        Text(
                          AppLocalizations.of(context)!.egpAmount(
                            item.price.toStringAsFixed(2).toString(),
                          ),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _brandOrange,
                          ),
                        ),

                      // Unavailable badge
                      if (!item.isAvailable) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.unavailable,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // ── Right: Image + optional edit icon ──
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 90,
                    height: 90,
                    child: item.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: item.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const ShimmerLoading(
                              width: double.infinity,
                              height: double.infinity,
                            ),
                            errorWidget: (_, _, _) => _placeholder(),
                          )
                        : _placeholder(),
                  ),
                ),

                // Edit button
                if (showEditButton && onEdit != null)
                  PositionedDirectional(
                    top: -6,
                    end: -6,
                    child: GestureDetector(
                      onTap: onEdit,
                      child: Container(
                        width: 28,
                        height: 28,
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
                          size: 14,
                          color: _brandOrange,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: Colors.grey[100],
      child: Icon(Icons.fastfood_rounded, size: 32, color: Colors.grey[300]),
    );
  }
}
