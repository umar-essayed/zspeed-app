import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:z_speed/l10n/app_localizations.dart';
import 'package:z_speed/features/auth/cubit/auth_cubit.dart';

class ForceUpdateScreen extends StatefulWidget {
  final String updateUrl;

  const ForceUpdateScreen({super.key, required this.updateUrl});

  @override
  State<ForceUpdateScreen> createState() => _ForceUpdateScreenState();
}

class _ForceUpdateScreenState extends State<ForceUpdateScreen>
    with SingleTickerProviderStateMixin {
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

  Future<void> _launchUpdateUrl() async {
    if (widget.updateUrl.isEmpty) {
      debugPrint('No update URL provided.');
      return;
    }
    final Uri url = Uri.parse(widget.updateUrl);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Could not launch update URL: ${widget.updateUrl}');
      }
    } catch (e) {
      debugPrint('Error launching update URL: $e');
    }
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
                      // Z Speed Branding Logo
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

                      // Animated Premium Update illustration
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
                          // System Update Icon
                          const Icon(
                            Icons.system_update_rounded,
                            size: 64,
                            color: primaryColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 48),

                      // Title
                      Text(
                        l10n?.criticalUpdateTitle ?? 'Update Required',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Cairo',
                          color: isDark ? Colors.white : const Color(0xFF2D3748),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Message Container
                      Container(
                        padding: const EdgeInsets.all(20),
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
                        child: Text(
                          l10n?.criticalUpdateMessage ??
                              'A new version of Z Speed is available. You must update the app to continue using our services.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.6,
                            fontFamily: 'Cairo',
                            color: isDark ? Colors.grey[300] : Colors.grey[700],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Update Button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _launchUpdateUrl,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                          ),
                          child: Text(
                            l10n?.updateNow ?? 'Update Now',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
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
