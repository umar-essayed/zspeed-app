import 'package:z_speed/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:z_speed/features/restaurant/model/cuisine_type.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Talabat-style horizontal scrolling cuisine filter with circular images.
class CuisineFilterBar extends StatelessWidget {
  final List<String> cuisines;
  final List<CuisineType> cuisineTypes;
  final String? selectedCuisine;
  final ValueChanged<String?> onCuisineSelected;

  const CuisineFilterBar({
    super.key,
    required this.cuisines,
    this.cuisineTypes = const [],
    required this.selectedCuisine,
    required this.onCuisineSelected,
  });

  /// Look up the CuisineType metadata (with imageUrl) for a cuisine name.
  CuisineType? _findType(String name) {
    final lower = name.toLowerCase();
    for (final ct in cuisineTypes) {
      if (ct.name.toLowerCase() == lower || ct.nameAr.toLowerCase() == lower) {
        return ct;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          // "All" chip
          _CuisineChip(
            label: AppLocalizations.of(context)!.all,
            imageUrl: 'assets/images/cuisines/all.jpg',
            isSelected: selectedCuisine == null,
            onTap: () => onCuisineSelected(null),
          ),

          // Cuisine chips
          ...cuisines.map((cuisine) {
            final ct = _findType(cuisine);
            final isSelected = selectedCuisine == cuisine;
            return _CuisineChip(
              label: cuisine,
              imageUrl: ct?.imageUrl ?? getCuisineImageUrl(cuisine),
              isSelected: isSelected,
              onTap: () => onCuisineSelected(isSelected ? null : cuisine),
            );
          }),
        ],
      ),
    );
  }
}

class _CuisineChip extends StatelessWidget {
  final String label;
  final String? imageUrl;
  final bool isSelected;
  final VoidCallback onTap;

  const _CuisineChip({
    required this.label,
    required this.imageUrl,
    required this.isSelected,
    required this.onTap,
  });

  Widget _buildImage(String path, Color brandOrange) {
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        width: 60,
        height: 60,
        errorBuilder: (_, _, _) => _fallbackIcon(isSelected),
      );
    }
    return CachedNetworkImage(
      imageUrl: path,
      fit: BoxFit.cover,
      width: 60,
      height: 60,
      placeholder: (context, url) => Container(
        color: Colors.grey[100],
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              valueColor: AlwaysStoppedAnimation<Color>(brandOrange),
            ),
          ),
        ),
      ),
      errorWidget: (context, url, error) => _fallbackIcon(isSelected),
    );
  }

  @override
  Widget build(BuildContext context) {
    const brandOrange = Color(0xFFF35535);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 76,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Circular image / icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? brandOrange : Colors.grey[300]!,
                  width: isSelected ? 2.5 : 1.5,
                ),
                color: isSelected
                    ? brandOrange.withValues(alpha: 0.08)
                    : Colors.grey[50],
              ),
              child: ClipOval(
                child: imageUrl != null && imageUrl!.isNotEmpty
                    ? _buildImage(imageUrl!, brandOrange)
                    : _fallbackIcon(isSelected),
              ),
            ),
            const SizedBox(height: 6),
            // Label
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w800,
                color: isSelected ? brandOrange : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackIcon(bool selected) {
    const brandOrange = Color(0xFFF35535);
    return Center(
      child: Icon(
        Icons.restaurant_rounded,
        size: 24,
        color: selected ? brandOrange : Colors.grey[400],
      ),
    );
  }
}
