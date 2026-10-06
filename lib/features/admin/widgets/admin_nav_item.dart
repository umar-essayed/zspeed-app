import 'package:flutter/material.dart';
import 'package:z_speed/features/admin/model/admin_theme.dart';

/// A single navigation item for the dark admin sidebar.
///
/// Active state: orange gradient pill + left accent bar + white text.
/// Inactive state: slate icon + text with dark hover ripple.
class AdminNavItem extends StatelessWidget {
  const AdminNavItem({
    super.key,
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
    // Legacy colour params kept for API compat — not used in new design.
    required this.primaryOrange,
    required this.textMedium,
  });

  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;
  final Color primaryOrange;
  final Color textMedium;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            // Orange gradient fill for the active item
            if (isSelected)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        AdminTheme.primaryOrange,
                        AdminTheme.accentOrange,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AdminTheme.primaryOrange.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),

            // Inactive transparent background
            if (!isSelected)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

            // Ink ripple sits on top
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(10),
                highlightColor:
                    Colors.white.withValues(alpha: isSelected ? 0.08 : 0.04),
                splashColor:
                    Colors.white.withValues(alpha: isSelected ? 0.12 : 0.06),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        size: 20,
                        color: isSelected
                            ? Colors.white
                            : AdminTheme.sidebarText,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : AdminTheme.sidebarText,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
