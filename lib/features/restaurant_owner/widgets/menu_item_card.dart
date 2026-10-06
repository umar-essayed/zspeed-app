import 'package:flutter/material.dart';
import 'package:z_speed/features/restaurant/model/menu_item.dart';
import 'package:z_speed/l10n/app_localizations.dart';

class MenuItemCard extends StatelessWidget {
  const MenuItemCard({
    super.key,
    required this.item,
    required this.sectionName,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleAvailability,
    this.onPreview,
    this.isGrid = false,
  });

  final MenuItem item;
  final String sectionName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleAvailability;
  final VoidCallback? onPreview;
  final bool isGrid;

  static const _orange = Color(0xFFF35535);
  static const _lightOrange = Color(0xFFFFF3E0);
  static const _saleRed = Color(0xFFE53935);
  static const _saleGreen = Color(0xFF43A047);

  bool get _isOnSale => item.discountedPrice != null;
  double get _displayPrice => item.discountedPrice ?? item.price;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final l10n = AppLocalizations.of(context)!;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image + availability toggle ──────────────────────────
          Stack(
            children: [
              SizedBox(
                height: 140,
                width: double.infinity,
                child: _buildItemImage(item.imageUrl),
              ),
              // availability chip top-right
              Positioned(
                top: 10,
                right: 10,
                child: GestureDetector(
                  onTap: onToggleAvailability,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: item.isAvailable
                          ? Colors.green.shade600
                          : Colors.grey.shade600,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.isAvailable ? Icons.check_circle : Icons.cancel,
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.isAvailable ? l10n.available : l10n.outOfStock,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // sale badge top-left
              if (_isOnSale)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _saleRed,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.local_offer,
                          size: 11,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          l10n.onSale.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          // ── Details ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // name
                Text(
                  item.getLocalizedName(locale),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // description
                Text(
                  item.getLocalizedDescription(locale),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF888888),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),

                // price row + section badge
                Row(
                  children: [
                    // price
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isOnSale)
                          Text(
                            l10n.currencyEgp(item.price.toStringAsFixed(2)),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        Text(
                          l10n.currencyEgp(_displayPrice.toStringAsFixed(2)),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _isOnSale ? _saleGreen : _orange,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // section badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _lightOrange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        sectionName,
                        style: const TextStyle(
                          fontSize: 11,
                          color: _orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                // stock badge
                if (item.stock != null) ...[
                  const SizedBox(height: 8),
                  _buildStockBadge(l10n),
                ],
              ],
            ),
          ),

          if (isGrid) const Spacer(),
          if (!isGrid) const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              children: [
                if (onPreview != null)
                  _ActionButton(
                    icon: Icons.visibility_outlined,
                    label: AppLocalizations.of(context)!.preview,
                    color: Colors.blueGrey,
                    onTap: onPreview!,
                  ),
                _ActionButton(
                  icon: Icons.edit_outlined,
                  label: AppLocalizations.of(context)!.edit,
                  color: _orange,
                  onTap: onEdit,
                ),
                _ActionButton(
                  icon: Icons.delete_outline,
                  label: AppLocalizations.of(context)!.delete,
                  color: Colors.red.shade400,
                  onTap: onDelete,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemImage(String? imagePath) {
    if (imagePath != null && imagePath.isNotEmpty) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, _, _) => _imagePlaceholder(),
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return Container(
            color: _lightOrange,
            child: Center(
              child: CircularProgressIndicator(
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded /
                          progress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
                color: _orange,
              ),
            ),
          );
        },
      );
    }
    return _imagePlaceholder();
  }

  Widget _imagePlaceholder() {
    return Container(
      color: _lightOrange,
      child: const Center(
        child: Icon(Icons.restaurant, color: _orange, size: 40),
      ),
    );
  }

  Widget _buildStockBadge(AppLocalizations l10n) {
    final stock = item.stock!;
    final isLow = item.warningLimit != null && stock <= item.warningLimit!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isLow ? Colors.amber.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isLow ? Colors.amber.shade300 : Colors.blue.shade200,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLow ? Icons.warning_amber_rounded : Icons.inventory_2_outlined,
            size: 12,
            color: isLow ? Colors.orange.shade700 : Colors.blue.shade600,
          ),
          const SizedBox(width: 4),
          Text(
            l10n.stockCount(stock),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isLow ? Colors.orange.shade700 : Colors.blue.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
