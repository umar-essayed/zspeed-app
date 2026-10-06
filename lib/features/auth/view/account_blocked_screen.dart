import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:z_speed/features/auth/cubit/auth_cubit.dart';
import 'package:z_speed/l10n/app_localizations.dart';

class AccountBlockedScreen extends StatefulWidget {
  final String? customReason;

  const AccountBlockedScreen({super.key, this.customReason});

  @override
  State<AccountBlockedScreen> createState() => _AccountBlockedScreenState();
}

class _AccountBlockedScreenState extends State<AccountBlockedScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  static const _supportEmail = 'support@z-speed.com';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
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

  Future<void> _contactSupportEmail() async {
    final uri = Uri.parse(
      'mailto:$_supportEmail?subject=Account%20Suspension%20Inquiry',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final user = context.watch<AuthCubit>().state.user;

    const errorColor = Color(0xFFE53E3E);
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

    final reason = widget.customReason ??
        user?.rejectionReason ??
        (user?.status.name == 'suspended'
            ? 'Account temporarily suspended pending administrative review.'
            : null);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: bgGradient),
        child: SafeArea(
          child: Stack(
            children: [
              // Top right logout button
              Positioned(
                top: 16,
                right: 16,
                child: TextButton.icon(
                  onPressed: () => context.read<AuthCubit>().logout(),
                  icon: const Icon(Icons.logout_rounded,
                      color: primaryColor, size: 18),
                  label: Text(
                    l10n?.logout ?? 'Log Out',
                    style: const TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                      fontSize: 14,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Z Speed Branding Logo
                      Image.asset(
                        'assets/images/icon.png',
                        width: 72,
                        height: 72,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Z Speed',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Cairo',
                          color:
                              isDark ? Colors.white : const Color(0xFF2D3748),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 36),

                      // Animated Pulsing Warning Shield
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          ScaleTransition(
                            scale: _pulseAnimation,
                            child: Container(
                              width: 130,
                              height: 130,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: errorColor.withValues(alpha: 0.08),
                                border: Border.all(
                                  color: errorColor.withValues(alpha: 0.2),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                          ScaleTransition(
                            scale: _pulseAnimation,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: errorColor.withValues(alpha: 0.15),
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.block_rounded,
                            size: 60,
                            color: errorColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 36),

                      // Title
                      Text(
                        l10n?.accountBlockedTitle ?? 'Account Suspended',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Cairo',
                          color:
                              isDark ? Colors.white : const Color(0xFF2D3748),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Message Card
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 20),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.04)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.grey[200]!,
                          ),
                          boxShadow: !isDark
                              ? [
                                  BoxShadow(
                                    color:
                                        Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          children: [
                            Text(
                              l10n?.accountBlockedMessage ??
                                  'Your account has been suspended by administration. If you believe this is a mistake or need assistance, please contact our support team.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.6,
                                fontFamily: 'Cairo',
                                color: isDark
                                    ? Colors.grey[300]
                                    : Colors.grey[700],
                              ),
                            ),
                            if (reason != null && reason.trim().isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: errorColor.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: errorColor.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n?.blockReason ?? 'Reason',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: errorColor,
                                        fontFamily: 'Cairo',
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      reason,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontFamily: 'Cairo',
                                        color: isDark
                                            ? Colors.white70
                                            : const Color(0xFF2D3748),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Action Button: Contact Support
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _contactSupportEmail,
                          icon: const Icon(Icons.support_agent_rounded,
                              color: Colors.white, size: 20),
                          label: Text(
                            l10n?.contactSupport ?? 'Contact Support',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Action Button: Logout
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () => context.read<AuthCubit>().logout(),
                          icon: const Icon(Icons.logout_rounded, size: 18),
                          label: Text(
                            l10n?.logout ?? 'Log Out',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? Colors.white70 : Colors.grey[800],
                            side: BorderSide(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.15)
                                  : Colors.grey[300]!,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
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
