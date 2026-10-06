import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/l10n/app_localizations.dart';
import 'package:z_speed/features/auth/cubit/auth_cubit.dart';
import 'package:z_speed/features/driver/cubit/driver_dashboard_cubit.dart';

class DriverLockedScreen extends StatefulWidget {
  final double currentEarnings;
  final double limit;

  const DriverLockedScreen({
    super.key,
    required this.currentEarnings,
    required this.limit,
  });

  @override
  State<DriverLockedScreen> createState() => _DriverLockedScreenState();
}

class _DriverLockedScreenState extends State<DriverLockedScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
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
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    const errorColor = Color(0xFFD32F2F);
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
              // Logout Button in top right corner
              Positioned(
                top: 16,
                right: 16,
                child: TextButton.icon(
                  onPressed: () => context.read<AuthCubit>().logout(),
                  icon: const Icon(Icons.logout_rounded, color: errorColor, size: 18),
                  label: Text(
                    l10n?.logoutButton ?? 'Logout',
                    style: const TextStyle(
                      color: errorColor,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                      fontSize: 14,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    backgroundColor: errorColor.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),

              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Z Speed Branding
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
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Lock Illustration with Glowing Rings
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          ScaleTransition(
                            scale: _pulseAnimation,
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: errorColor.withValues(alpha: 0.08),
                                border: Border.all(
                                  color: errorColor.withValues(alpha: 0.15),
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
                                color: errorColor.withValues(alpha: 0.12),
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.lock_clock_outlined,
                            size: 64,
                            color: errorColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),

                      // Locked Title
                      const Text(
                        'Account Locked',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Cairo',
                          color: errorColor,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Details Card
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
                              'You have reached your earnings limit. To continue taking requests, please contact administration or visit a hub to settle your balance.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                fontFamily: 'Cairo',
                                color: isDark ? Colors.grey[300] : Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 8),
                            
                            // Earnings stats
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total Earnings:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Cairo',
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'EGP ${widget.currentEarnings.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'Cairo',
                                    fontSize: 16,
                                    color: errorColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Limit Threshold:',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  'EGP ${widget.limit.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Cairo',
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Refresh / Retry button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final uid = context.read<AuthCubit>().state.user?.id;
                            if (uid != null) {
                              context.read<DriverDashboardCubit>().init(uid);
                            }
                          },
                          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                          label: const Text(
                            'Refresh Status',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                              fontSize: 15,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF35535),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
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
