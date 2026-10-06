import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:z_speed/core/services/connectivity_cubit.dart';
import 'package:z_speed/l10n/app_localizations.dart';

class NoInternetScreen extends StatefulWidget {
  final Future<void> Function()? onRetry;

  const NoInternetScreen({
    super.key,
    this.onRetry,
  });

  @override
  State<NoInternetScreen> createState() => _NoInternetScreenState();
}

class _NoInternetScreenState extends State<NoInternetScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    // Pulse animation for the offline icon
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleRetry() async {
    if (_isChecking) return;

    final connectivityCubit = context.read<ConnectivityCubit>();

    setState(() {
      _isChecking = true;
    });

    // Run the optional custom onRetry logic
    if (widget.onRetry != null) {
      try {
        await widget.onRetry!();
      } catch (_) {}
    }

    // Direct check of connectivity status
    final isOnline = await connectivityCubit.checkConnectivity();

    if (mounted) {
      setState(() {
        _isChecking = false;
      });

      if (!isOnline) {
        // Show a premium floating snackbar if we are still offline
        final isAr = Localizations.localeOf(context).languageCode == 'ar';
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.wifi_off_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isAr
                      ? 'ما زلت غير متصل بالإنترنت. يرجى التحقق من اتصالك.'
                      : 'Still offline. Please check your internet connection.',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFF35535),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    // Styling elements
    final Color bgStart = isDark ? const Color(0xFF141A24) : const Color(0xFFF5F7FA);
    final Color bgEnd = isDark ? const Color(0xFF0F1319) : const Color(0xFFE4E8F0);
    final Color cardColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.7);
    final Color borderColor = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05);
    final Color titleColor = isDark ? Colors.white : const Color(0xFF1A202C);
    final Color descColor = isDark ? Colors.white70 : const Color(0xFF4A5568);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [bgStart, bgEnd],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Decorative background blur elements (Premium touch)
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF35535).withValues(alpha: isDark ? 0.08 : 0.05),
                ),
              ),
            ),
            Positioned(
              bottom: -150,
              left: -150,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF35535).withValues(alpha: isDark ? 0.05 : 0.03),
                ),
              ),
            ),

            // Main Content Area
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 40,
                        ),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: borderColor, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Pulse Animation containing the Connection Icon
                            AnimatedBuilder(
                              animation: _animationController,
                              builder: (context, child) {
                                return Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Outer pulse ring
                                    Container(
                                      width: 120 + (_animationController.value * 20),
                                      height: 120 + (_animationController.value * 20),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFFF35535)
                                            .withValues(alpha: 0.05 * (1.0 - _animationController.value)),
                                      ),
                                    ),
                                    // Inner pulse ring
                                    Container(
                                      width: 100 + (_animationController.value * 12),
                                      height: 100 + (_animationController.value * 12),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFFF35535)
                                            .withValues(alpha: 0.10 * (1.0 - _animationController.value)),
                                      ),
                                    ),
                                    // Static Icon Container
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFFFF7E61),
                                            Color(0xFFF35535),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFF35535).withValues(alpha: 0.4),
                                            blurRadius: 15,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.wifi_off_rounded,
                                        size: 40,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),

                            const SizedBox(height: 32),

                            // Title
                            Text(
                              l10n?.youAreOffline ?? "You're Offline",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: titleColor,
                                fontFamily: 'Cairo',
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 12),

                            // Description
                            Text(
                              l10n?.networkError ??
                                  "Network error, please check your connection.",
                              style: TextStyle(
                                fontSize: 14,
                                color: descColor,
                                height: 1.5,
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 36),

                            // Retry Button
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFF7E61),
                                      Color(0xFFF35535),
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFF35535).withValues(alpha: 0.3),
                                      blurRadius: 15,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _isChecking ? null : _handleRetry,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: _isChecking
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.refresh_rounded,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              l10n?.retry ?? "Retry",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Cairo',
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
                    ),
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
