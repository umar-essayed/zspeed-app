import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:z_speed/l10n/app_localizations.dart';
import 'package:z_speed/features/driver/view/driver_application_form.dart';
import 'package:z_speed/features/restaurant_owner/view/restaurant_application_form.dart';

/// "Want to partner with us?" section shown below the sign-up form.
///
/// Two pill-shaped glass buttons: Join as Driver / Join as Restaurant.
class PartnerLinksWidget extends StatelessWidget {
  const PartnerLinksWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Column(
      children: [
        Text(
          l.wantToPartnerWithUs,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65),
            fontSize: 13,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _PartnerPill(
              icon: Icons.directions_car_rounded,
              label: l.joinAsDriver,
              gradientColors: const [Color(0xFF1976D2), Color(0xFF1565C0)],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DriverApplicationForm(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            _PartnerPill(
              icon: Icons.storefront_rounded,
              label: l.joinAsRestaurant,
              gradientColors: const [Color(0xFFF35535), Color(0xFFFF9800)],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const RestaurantApplicationForm(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Partner pill button ──────────────────────────────────────────────────────

class _PartnerPill extends StatelessWidget {
  const _PartnerPill({
    required this.icon,
    required this.label,
    required this.gradientColors,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Material(
          color: Colors.white.withValues(alpha: 0.08),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            splashColor: gradientColors[0].withValues(alpha: 0.2),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: gradientColors[0].withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: gradientColors,
                    ).createShader(bounds),
                    child: Icon(icon, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 8),
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: gradientColors,
                    ).createShader(bounds),
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
