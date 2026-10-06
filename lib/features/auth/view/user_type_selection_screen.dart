import 'package:flutter/material.dart';
import 'package:z_speed/features/auth/model/user_model.dart';
import 'package:z_speed/l10n/app_localizations.dart';

/// Full-screen user type selector with a dark glassmorphic design.
///
/// Shown during onboarding if a user needs to choose their role.
/// Each role card has icon, title, description, and a gradient accent.
class UserTypeSelection extends StatefulWidget {
  final Function(UserType) onUserTypeSelected;

  const UserTypeSelection({super.key, required this.onUserTypeSelected});

  @override
  State<UserTypeSelection> createState() => _UserTypeSelectionState();
}

class _UserTypeSelectionState extends State<UserTypeSelection> {
  UserType? _selected;

  List<_RoleData> _roles(AppLocalizations l10n) => [
        _RoleData(
          type: UserType.customer,
          icon: Icons.person_rounded,
          title: l10n.roleCustomer,
          subtitle: l10n.roleCustomerSubtitle,
          gradient: const [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
          glow: const Color(0xFF3B82F6),
        ),
        _RoleData(
          type: UserType.driver,
          icon: Icons.delivery_dining_rounded,
          title: l10n.roleDriver,
          subtitle: l10n.roleDriverSubtitle,
          gradient: const [Color(0xFF10B981), Color(0xFF047857)],
          glow: const Color(0xFF10B981),
        ),
        _RoleData(
          type: UserType.vendor,
          icon: Icons.storefront_rounded,
          title: l10n.roleVendor,
          subtitle: l10n.roleVendorSubtitle,
          gradient: const [Color(0xFFF35535), Color(0xFFFF9800)],
          glow: const Color(0xFFF35535),
        ),
        _RoleData(
          type: UserType.admin,
          icon: Icons.admin_panel_settings_rounded,
          title: l10n.roleAdmin,
          subtitle: l10n.roleAdminSubtitle,
          gradient: const [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
          glow: const Color(0xFF8B5CF6),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                ),
              ),
            ),
          ),
          // Decorative circles
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFF35535).withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF3B82F6).withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 48),

                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      Text(
                        AppLocalizations.of(context)!.chooseYourRole,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        AppLocalizations.of(context)!.selectHowYouWantToUse,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF94A3B8),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Role grid
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.82,
                      physics: const BouncingScrollPhysics(),
                      children: _roles(AppLocalizations.of(context)!)
                          .map((role) => _RoleCard(
                                data: role,
                                isSelected: _selected == role.type,
                                onTap: () =>
                                    setState(() => _selected = role.type),
                              ))
                          .toList(),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // CTA
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: AnimatedOpacity(
                    opacity: _selected != null ? 1.0 : 0.4,
                    duration: const Duration(milliseconds: 200),
                    child: _ContinueButton(
                      enabled: _selected != null,
                      onTap: _selected != null
                          ? () => widget.onUserTypeSelected(_selected!)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Role card ────────────────────────────────────────────────────────────────

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.data,
    required this.isSelected,
    required this.onTap,
  });

  final _RoleData data;
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
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? data.gradient[0].withValues(alpha: 0.8)
                : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1.5,
          ),
          color: isSelected
              ? data.gradient[0].withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.05),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: data.glow.withValues(alpha: 0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with gradient circle
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: data.gradient,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: data.glow.withValues(alpha: 0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Icon(data.icon, color: Colors.white, size: 30),
              ),
              const SizedBox(height: 14),
              Text(
                data.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                data.subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.75)
                      : const Color(0xFF64748B),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              if (isSelected) ...[
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: data.gradient[0].withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: data.gradient[0].withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.selected,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Continue button ──────────────────────────────────────────────────────────

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({required this.enabled, this.onTap});
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF35535), Color(0xFFFF9800)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF35535).withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context)!.continueButton,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded,
                    color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Data model ───────────────────────────────────────────────────────────────

class _RoleData {
  const _RoleData({
    required this.type,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.glow,
  });

  final UserType type;
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final Color glow;
}
