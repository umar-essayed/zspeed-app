import 'package:flutter/material.dart';
import 'package:z_speed/core/enums/user_enums.dart';
import 'package:z_speed/features/restaurant_owner/widgets/restaurant_form_styles.dart';
import 'package:z_speed/features/restaurant_owner/widgets/restaurant_form_widgets.dart';
import 'package:z_speed/l10n/app_localizations.dart';

/// Step 0 of the vendor application form.
///
/// Lets the applicant pick whether they are a Restaurant, Supermarket,
/// or Pharmacy before filling in the rest of their details.
class VendorTypeSelectionStep extends StatelessWidget {
  final VendorType selectedType;
  final void Function(VendorType) onTypeSelected;

  const VendorTypeSelectionStep({
    super.key,
    required this.selectedType,
    required this.onTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final options = [
      _VendorOption(
        type: VendorType.restaurant,
        icon: Icons.restaurant_rounded,
        title: l10n.restaurant,
        subtitle: l10n.foodAndDining,
        gradient: const [Color(0xFFF35535), Color(0xFFFF9800)],
        glow: const Color(0xFFF35535),
      ),
      _VendorOption(
        type: VendorType.supermarket,
        icon: Icons.shopping_cart_rounded,
        title: l10n.supermarket,
        subtitle: l10n.groceriesAndDailyNeeds,
        gradient: const [Color(0xFF10B981), Color(0xFF047857)],
        glow: const Color(0xFF10B981),
      ),
      _VendorOption(
        type: VendorType.pharmacy,
        icon: Icons.local_pharmacy_rounded,
        title: l10n.pharmacy,
        subtitle: l10n.medicineAndHealthProducts,
        gradient: const [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
        glow: const Color(0xFF3B82F6),
      ),
      _VendorOption(
        type: VendorType.bookstore,
        icon: Icons.menu_book_rounded,
        title: l10n.localeName == 'ar' ? 'مكتبة ومستلزمات مكتبية' : 'Bookstore & Stationery',
        subtitle: l10n.localeName == 'ar' ? 'كتب وروايات، أدوات مكتبية ومدرسية' : 'Books, novels, and school supplies',
        gradient: const [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
        glow: const Color(0xFF8B5CF6),
      ),
      _VendorOption(
        type: VendorType.homeFurnishing,
        icon: Icons.chair_rounded,
        title: l10n.localeName == 'ar' ? 'معرض أثاث ومفروشات' : 'Furniture & Furnishing',
        subtitle: l10n.localeName == 'ar' ? 'أثاث منزلي، مفروشات، وسائد ومراتب' : 'Home furniture, bedding, and pillows',
        gradient: const [Color(0xFFF59E0B), Color(0xFFD97706)],
        glow: const Color(0xFFF59E0B),
      ),
      _VendorOption(
        type: VendorType.meatAndProteins,
        icon: Icons.restaurant_menu_rounded,
        title: l10n.meatAndProteins,
        subtitle: l10n.meatAndProteinsSubtitle,
        gradient: const [Color(0xFFEF4444), Color(0xFFB91C1C)],
        glow: const Color(0xFFEF4444),
      ),
      _VendorOption(
        type: VendorType.clothes,
        icon: Icons.checkroom_rounded,
        title: l10n.clothes,
        subtitle: l10n.clothesSubtitle,
        gradient: const [Color(0xFFEC4899), Color(0xFFBE185D)],
        glow: const Color(0xFFEC4899),
      ),
      _VendorOption(
        type: VendorType.buyAndSell,
        icon: Icons.swap_horiz_rounded,
        title: l10n.buyAndSell,
        subtitle: l10n.buyAndSellSubtitle,
        gradient: const [Color(0xFF8B5CF6), Color(0xFF5B21B6)],
        glow: const Color(0xFF8B5CF6),
      ),
      _VendorOption(
        type: VendorType.electronics,
        icon: Icons.devices_rounded,
        title: l10n.electronics,
        subtitle: l10n.electronicsSubtitle,
        gradient: const [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
        glow: const Color(0xFF3B82F6),
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(RestaurantFormStyles.horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RestaurantFormSectionHeader(
            title: l10n.vendorTypeStep,
            subtitle: l10n.vendorTypeSubtitle,
            icon: Icons.storefront_outlined,
          ),
          const SizedBox(height: RestaurantFormStyles.sectionSpacing),
          ...options.expand((opt) => [
                _VendorTypeCard(
                  option: opt,
                  isSelected: selectedType == opt.type,
                  onTap: () => onTypeSelected(opt.type),
                ),
                const SizedBox(height: 12),
              ]),
        ],
      ),
    );
  }
}

// ── Card ─────────────────────────────────────────────────────────────────────

class _VendorTypeCard extends StatelessWidget {
  const _VendorTypeCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final _VendorOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(RestaurantFormStyles.cardRadius),
          border: Border.all(
            color: isSelected
                ? option.gradient[0]
                : RestaurantFormStyles.borderColor,
            width: isSelected ? 2 : 1.5,
          ),
          color: isSelected
              ? option.gradient[0].withValues(alpha: 0.08)
              : Colors.white,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: option.glow.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  const BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: option.gradient,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(option.icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      option.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? option.gradient[0]
                            : const Color(0xFF212121),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      option.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: RestaurantFormStyles.labelColor,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? option.gradient[0]
                        : RestaurantFormStyles.borderColor,
                    width: 2,
                  ),
                  color: isSelected ? option.gradient[0] : Colors.transparent,
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Data model ────────────────────────────────────────────────────────────────

class _VendorOption {
  const _VendorOption({
    required this.type,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.glow,
  });

  final VendorType type;
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final Color glow;
}
