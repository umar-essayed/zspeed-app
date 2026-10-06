import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/l10n/app_localizations.dart';
import 'package:z_speed/features/auth/cubit/auth_cubit.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    // Smooth infinite rotation for the settings gear
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // Pulse animation for the glowing ring
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final l10n = AppLocalizations.of(context);
    final authCubit = context.watch<AuthCubit>();
    final isLoggedIn = authCubit.state.user != null;

    const primaryColor = Color(0xFFF35535);
    final bgGradient = isDark
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1A1E), Color(0xFF121214)],
          )
        : const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFFF7F9FB)],
          );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: bgGradient),
        child: SafeArea(
          child: Stack(
            children: [
              // Subtle logout button at the top corner if logged in
              if (isLoggedIn)
                Positioned(
                  top: 16,
                  right: 16,
                  child: TextButton.icon(
                    onPressed: () => context.read<AuthCubit>().logout(),
                    icon: const Icon(Icons.logout_rounded, color: primaryColor, size: 18),
                    label: Text(
                      l10n?.logoutButton ?? 'Logout',
                      style: const TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                        fontSize: 14,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      backgroundColor: primaryColor.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              
              // Main content
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Z Speed Small Branding Logo
                      Image.asset(
                        'assets/images/icon.png',
                        width: 80,
                        height: 80,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Z Speed',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Cairo',
                          color: isDark ? Colors.white : const Color(0xFF2D3748),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Animated Premium Maintenance illustration
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Glowing outer pulsing circle
                          ScaleTransition(
                            scale: _pulseAnimation,
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: primaryColor.withValues(alpha: 0.08),
                                border: Border.all(
                                  color: primaryColor.withValues(alpha: 0.15),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                          ScaleTransition(
                            scale: _pulseAnimation,
                            child: Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: primaryColor.withValues(alpha: 0.12),
                              ),
                            ),
                          ),
                          // Rotating Gear Icon
                          RotationTransition(
                            turns: _rotationController,
                            child: const Icon(
                              Icons.settings_rounded,
                              size: 72,
                              color: primaryColor,
                            ),
                          ),
                          // Wrench Icon over the gear
                          Icon(
                            Icons.construction_rounded,
                            size: 32,
                            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                          ),
                        ],
                      ),
                      const SizedBox(height: 48),

                      // Title
                      Text(
                        l10n?.underMaintenanceTitle ?? 'Under Maintenance',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Cairo',
                          color: isDark ? Colors.white : const Color(0xFF2D3748),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Message
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.03)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.grey[200]!,
                          ),
                          boxShadow: !isDark
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          children: [
                            Text(
                              l10n?.underMaintenanceMessage ??
                                  'Z Speed is currently undergoing scheduled maintenance to improve our systems. We\'ll be back online shortly.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.6,
                                fontFamily: 'Cairo',
                                color: isDark ? Colors.grey[300] : Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Divider(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.grey[200],
                              height: 1,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l10n?.checkBackSoon ?? 'Please check back soon!',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Cairo',
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Footer with visual dot indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (index) {
                          return Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: primaryColor.withValues(
                                alpha: index == 0 ? 1.0 : (index == 1 ? 0.5 : 0.2),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
