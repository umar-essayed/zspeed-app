import 'package:flutter/material.dart';
import 'package:z_speed/l10n/app_localizations.dart';

/// Card widget displaying a custom delivery area rule configured on the map.
class DeliveryAreaCard extends StatelessWidget {
  final Map<String, dynamic> area;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const DeliveryAreaCard({
    super.key,
    required this.area,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    final name = (area['name'] as String?)?.isNotEmpty == true
        ? area['name'] as String
        : (isAr ? 'منطقة بدون اسم' : 'Unnamed Area');

    final radiusKm = (area['radiusKm'] as num?)?.toDouble() ?? 10.0;
    final totalFee = (area['totalFee'] as num?)?.toDouble() ??
        (area['fixedFee'] as num?)?.toDouble() ??
        (area['baseFee'] as num?)?.toDouble() ??
        60.0;
    final address = (area['address'] as String?) ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF35535).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.map_rounded,
                  color: Color(0xFFF35535),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D2D2D),
                      ),
                    ),
                    if (address.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.edit_rounded,
                  color: Colors.blueAccent,
                  size: 20,
                ),
                onPressed: onEdit,
                tooltip: l10n.editArea,
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                  size: 20,
                ),
                onPressed: onDelete,
                tooltip: l10n.deleteArea,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildBadge(
                icon: Icons.radar,
                label: isAr
                    ? 'القطر: ${radiusKm.toStringAsFixed(0)} كم'
                    : 'Radius: ${radiusKm.toStringAsFixed(0)} km',
                color: Colors.deepOrange.shade50,
                textColor: Colors.deepOrange.shade800,
              ),
              _buildBadge(
                icon: Icons.attach_money,
                label: isAr
                    ? 'رسوم التوصيل: ${totalFee.toStringAsFixed(0)} ج.م'
                    : 'Delivery Cost: ${totalFee.toStringAsFixed(0)} EGP',
                color: Colors.green.shade50,
                textColor: Colors.green.shade800,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
