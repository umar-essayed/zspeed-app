import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:z_speed/core/injection.dart';
import 'package:z_speed/core/localization/locale_cubit.dart';
import 'package:z_speed/l10n/app_localizations.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onCompleted;
  final VoidCallback onLoginSignup;

  const OnboardingScreen({
    super.key,
    required this.onCompleted,
    required this.onLoginSignup,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _floatController;
  late AnimationController _pulseController;
  late AnimationController _radarController;

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Controller for floating cards on page 2
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    // Controller for pulsing elements on page 1 & 3
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Controller for radar rotation on page 3
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _floatController.dispose();
    _pulseController.dispose();
    _radarController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding({bool goToLogin = false}) async {
    HapticFeedback.mediumImpact();
    final prefs = getIt<SharedPreferences>();
    await prefs.setBool('onboarding_completed', true);
    if (goToLogin) {
      widget.onLoginSignup();
    } else {
      widget.onCompleted();
    }
  }

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentIndex < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark Slate 900
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Stack(
          children: [
            // 1. Premium Background Gradient and Glowing Orbs
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF0F172A), // Slate 900
                      Color(0xFF1E293B), // Slate 800
                      Color(0xFF0F172A), // Slate 900
                    ],
                  ),
                ),
              ),
            ),
            // Glowing Orb 1 (Top Left)
            Positioned(
              top: -size.height * 0.1,
              left: -size.width * 0.2,
              child: Container(
                width: size.width * 0.8,
                height: size.width * 0.8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF35535).withValues(alpha: 0.12),
                ),
              ),
            ),
            // Glowing Orb 2 (Middle Right)
            Positioned(
              top: size.height * 0.35,
              right: -size.width * 0.3,
              child: Container(
                width: size.width * 0.9,
                height: size.width * 0.9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFFA07A).withValues(alpha: 0.08),
                ),
              ),
            ),

            // 2. Main Page View
            AnimatedBuilder(
              animation: _pageController,
              builder: (context, child) {
                double pageOffset = 0.0;
                if (_pageController.hasClients) {
                  pageOffset = _pageController.page ?? 0.0;
                }
                return PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                    HapticFeedback.selectionClick();
                  },
                  children: [
                    // Page 1: Delivery
                    _buildPage(
                      index: 0,
                      offset: pageOffset,
                      title: localizations.onboardingTitle1,
                      subtitle: localizations.onboardingSub1,
                      graphic: _buildCourierTrailGraphic(),
                    ),
                    // Page 2: Services
                    _buildPage(
                      index: 1,
                      offset: pageOffset,
                      title: localizations.onboardingTitle2,
                      subtitle: localizations.onboardingSub2,
                      graphic: _buildServicesGraphic(),
                    ),
                    // Page 3: Realtime Tracking
                    _buildPage(
                      index: 2,
                      offset: pageOffset,
                      title: localizations.onboardingTitle3,
                      subtitle: localizations.onboardingSub3,
                      graphic: _buildRadarGraphic(),
                    ),
                  ],
                );
              },
            ),

            // 3. Skip Button (Top Right / Left based on RTL)
            if (_currentIndex < 2)
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                right: isArabic ? null : 24,
                left: isArabic ? 24 : null,
                child: TextButton(
                  onPressed: _completeOnboarding,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white70,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  child: Text(
                    localizations.onboardingSkip,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

            // Language Switcher Button (First onboarding page only)
            if (_currentIndex == 0)
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: isArabic ? null : 24,
                right: isArabic ? 24 : null,
                child: _buildLanguageSwitcher(context, isArabic),
              ),

            // 4. Bottom Controls (Indicators & Actions)
            Positioned(
              bottom:
                  MediaQuery.of(context).padding.bottom +
                  (_currentIndex == 2 ? 16 : 28),
              left: 24,
              right: 24,
              child: _currentIndex < 2
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Page Indicators
                        Row(
                          children: List.generate(3, (index) {
                            final bool isActive = _currentIndex == index;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.only(right: 8),
                              height: 8,
                              width: isActive ? 24 : 8,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: isActive
                                    ? const Color(0xFFF35535)
                                    : Colors.white24,
                              ),
                            );
                          }),
                        ),

                        // Action Button
                        GestureDetector(
                          onTap: _nextPage,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFF35535), // Primary orange
                                  Color(0xFFFF7A5C), // Lighter orange
                                ],
                              ),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFF35535,
                                  ).withValues(alpha: 0.4),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  localizations.onboardingNext,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'Cairo',
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  isArabic
                                      ? Icons.arrow_back
                                      : Icons.arrow_forward,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Page Indicators Centered
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(3, (index) {
                            final bool isActive = _currentIndex == index;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.only(right: 8),
                              height: 8,
                              width: isActive ? 24 : 8,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: isActive
                                    ? const Color(0xFFF35535)
                                    : Colors.white24,
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 24),

                        // Login / Sign Up Primary Button
                        GestureDetector(
                          onTap: () => _completeOnboarding(goToLogin: true),
                          child: Container(
                            width: double.infinity,
                            height: 52,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFF35535), // Primary orange
                                  Color(0xFFFF7A5C), // Lighter orange
                                ],
                              ),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFF35535,
                                  ).withValues(alpha: 0.4),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Text(
                              localizations.onboardingLoginSignup,
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'Cairo',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                        if (!kIsWeb) ...[
                          const SizedBox(height: 12),
                          // Guest Mode Secondary Button
                          GestureDetector(
                            onTap: () => _completeOnboarding(goToLogin: false),
                            child: Container(
                              width: double.infinity,
                              height: 52,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                localizations.onboardingGuest,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Cairo',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSwitcher(BuildContext context, bool isArabic) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                HapticFeedback.lightImpact();
                context.read<LocaleCubit>().toggleLanguage();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.language_rounded,
                      color: Colors.white.withValues(alpha: 0.9),
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isArabic ? 'English' : 'العربية',
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPage({
    required int index,
    required double offset,
    required String title,
    required String subtitle,
    required Widget graphic,
  }) {
    // Parallax effect calculations
    final double diff = offset - index;
    final double opacity = (1.0 - diff.abs() * 1.5).clamp(0.0, 1.0);
    final double translationX = diff * 150.0;

    return Opacity(
      opacity: opacity,
      child: Transform.translate(
        offset: Offset(translationX, 0.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Animated Graphic Container
              Expanded(flex: 4, child: Center(child: graphic)),

              const SizedBox(height: 24),

              // Glassmorphic text card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Colors.white.withValues(alpha: 0.04),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Cairo',
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontFamily: 'Cairo',
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }

  // Page 1 graphic: Glowing Speedometer / Courier Trail
  Widget _buildCourierTrailGraphic() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        return Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 240,
              height: 240,
              child: CustomPaint(
                painter: _CourierTrailPainter(
                  pulseValue: _pulseController.value,
                ),
              ),
            ),
            // Floating center icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF35535).withValues(alpha: 0.15),
                border: Border.all(
                  color: const Color(0xFFF35535).withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.flash_on_rounded,
                color: Color(0xFFF35535),
                size: 40,
              ),
            ),
          ],
        );
      },
    );
  }

  // Page 2 graphic: Floating service cards
  Widget _buildServicesGraphic() {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, _) {
        final floatValue = _floatController.value;
        final floatOffset1 = math.sin(floatValue * math.pi) * 8.0;
        final floatOffset2 = math.cos(floatValue * math.pi) * 12.0;
        final floatOffset3 = math.sin((floatValue + 0.5) * math.pi) * 10.0;

        return Stack(
          alignment: Alignment.center,
          children: [
            // Background grid visualizer
            Opacity(
              opacity: 0.1,
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: 20,
                itemBuilder: (_, _) => Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),

            // Card 1: Restaurant/Food
            Transform.translate(
              offset: Offset(-45, -45 + floatOffset1),
              child: Transform.rotate(
                angle: -0.08,
                child: _buildServiceCard(
                  title: 'Food Delivery',
                  icon: Icons.restaurant_rounded,
                  color: const Color(0xFFF35535),
                ),
              ),
            ),

            // Card 2: Transport/Ride
            Transform.translate(
              offset: Offset(45, -10 + floatOffset2),
              child: Transform.rotate(
                angle: 0.08,
                child: _buildServiceCard(
                  title: 'Ride Booking',
                  icon: Icons.directions_car_rounded,
                  color: const Color(0xFF22C55E),
                ),
              ),
            ),

            // Card 3: Pharmacy
            Transform.translate(
              offset: Offset(-15, 60 + floatOffset3),
              child: Transform.rotate(
                angle: -0.03,
                child: _buildServiceCard(
                  title: 'Pharmacy',
                  icon: Icons.local_pharmacy_rounded,
                  color: const Color(0xFF3B82F6),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildServiceCard({
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 140,
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.9), // Slate 800
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Cairo',
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Page 3 graphic: Sonar Radar animation
  Widget _buildRadarGraphic() {
    return AnimatedBuilder(
      animation: Listenable.merge([_radarController, _pulseController]),
      builder: (context, _) {
        return Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 240,
              height: 240,
              child: CustomPaint(
                painter: _RadarPainter(
                  sweepAngle: _radarController.value * 2 * math.pi,
                  pulseValue: _pulseController.value,
                ),
              ),
            ),
            // Central glowing location pin
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF35535),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF35535).withValues(alpha: 0.6),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.location_on_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        );
      },
    );
  }
}

// Custom Painter for Page 1 Speedometer Trail
class _CourierTrailPainter extends CustomPainter {
  final double pulseValue;

  _CourierTrailPainter({required this.pulseValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4;

    final basePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    // Background track arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi * 1.15,
      math.pi * 1.3,
      false,
      basePaint,
    );

    final activePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFF35535), Color(0xFFFF8E75)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 6;

    // Active speed arc (changes slightly with pulse)
    final sweep = math.pi * 0.8 + (pulseValue * 0.15 * math.pi);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi * 1.15,
      sweep,
      false,
      activePaint,
    );

    // Glowing speed ticks
    final tickPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    const tickCount = 12;
    for (int i = 0; i <= tickCount; i++) {
      final angle = -math.pi * 1.15 + (math.pi * 1.3) * (i / tickCount);
      final isPassed = -math.pi * 1.15 + sweep > angle;

      tickPaint.color = isPassed
          ? const Color(0xFFF35535).withValues(alpha: 0.6 + 0.4 * pulseValue)
          : Colors.white10;

      final inner = radius - 10;
      final outer = radius - 2;

      canvas.drawLine(
        Offset(
          center.dx + inner * math.cos(angle),
          center.dy + inner * math.sin(angle),
        ),
        Offset(
          center.dx + outer * math.cos(angle),
          center.dy + outer * math.sin(angle),
        ),
        tickPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CourierTrailPainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue;
  }
}

// Custom Painter for Page 3 Sonar Radar
class _RadarPainter extends CustomPainter {
  final double sweepAngle;
  final double pulseValue;

  _RadarPainter({required this.sweepAngle, required this.pulseValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    final circlePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw concentric circles
    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(center, maxRadius * (i / 3), circlePaint);
    }

    // Draw crosshair lines
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, center.dy),
      Offset(size.width, center.dy),
      linePaint,
    );
    canvas.drawLine(
      Offset(center.dx, 0),
      Offset(center.dx, size.height),
      linePaint,
    );

    // Draw sweeping radar sonar arc
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          Colors.transparent,
          const Color(0xFFF35535).withValues(alpha: 0.15),
          const Color(0xFFF35535).withValues(alpha: 0.35),
        ],
        stops: const [0.0, 0.85, 1.0],
        transform: GradientRotation(sweepAngle - 0.5 * math.pi),
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, maxRadius, sweepPaint);

    // Draw active target dots
    final dotPaint = Paint()
      ..color = const Color(
        0xFFF35535,
      ).withValues(alpha: 0.6 + 0.4 * pulseValue)
      ..style = PaintingStyle.fill;

    // Dot 1 (Top right sector)
    canvas.drawCircle(
      Offset(center.dx + maxRadius * 0.5, center.dy - maxRadius * 0.4),
      4 + pulseValue * 2,
      dotPaint,
    );
    // Dot 2 (Bottom left sector)
    canvas.drawCircle(
      Offset(center.dx - maxRadius * 0.6, center.dy + maxRadius * 0.3),
      3 + (1 - pulseValue) * 2,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) {
    return oldDelegate.sweepAngle != sweepAngle ||
        oldDelegate.pulseValue != pulseValue;
  }
}
