import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:z_speed/core/services/routing_service.dart';
import 'package:z_speed/l10n/app_localizations.dart';

class InAppNavigationOverlay extends StatelessWidget {
  final bool isNavigationActive;
  final RouteStep? nextStep;
  final double distanceToNextStep; // in meters
  final double totalRemainingDistance; // in meters
  final double totalRemainingDuration; // in seconds
  final double currentSpeed; // in m/s
  final double speedLimit; // in km/h
  final VoidCallback onExitNavigation;

  const InAppNavigationOverlay({
    super.key,
    required this.isNavigationActive,
    required this.nextStep,
    required this.distanceToNextStep,
    required this.totalRemainingDistance,
    required this.totalRemainingDuration,
    required this.currentSpeed,
    required this.speedLimit,
    required this.onExitNavigation,
  });

  // Convert m/s to km/h
  double get currentSpeedKmH => currentSpeed * 3.6;

  // Format distance in meters to standard display string (meters or km)
  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  // Format duration in seconds to standard display string
  String _formatDuration(double seconds, BuildContext context) {
    final minutes = (seconds / 60).ceil();
    final minStr = AppLocalizations.of(context)?.minLabel ?? 'min';
    final hrStr = AppLocalizations.of(context)?.hrLabel ?? 'hr';
    if (minutes < 60) {
      return '$minutes $minStr';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return '$hours $hrStr $remainingMinutes $minStr';
    }
  }

  // Format ETA based on remaining seconds
  String _formatETA(double seconds) {
    final etaTime = DateTime.now().add(Duration(seconds: seconds.toInt()));
    final hour = etaTime.hour;
    final minute = etaTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  // Helper to resolve maneuver icon
  IconData _getManeuverIcon(String maneuver) {
    switch (maneuver.toLowerCase()) {
      case 'left':
      case 'turn-left':
        return Icons.turn_left_rounded;
      case 'right':
      case 'turn-right':
        return Icons.turn_right_rounded;
      case 'sharp_left':
      case 'sharp-left':
        return Icons.turn_sharp_left_rounded;
      case 'sharp_right':
      case 'sharp-right':
        return Icons.turn_sharp_right_rounded;
      case 'slight_left':
      case 'slight-left':
        return Icons.turn_slight_left_rounded;
      case 'slight_right':
      case 'slight-right':
        return Icons.turn_slight_right_rounded;
      case 'straight':
      case 'continue':
        return Icons.arrow_upward_rounded;
      case 'arrive':
        return Icons.flag_rounded;
      case 'depart':
        return Icons.navigation_rounded;
      default:
        return Icons.navigation_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isNavigationActive) return const SizedBox.shrink();

    final isSpeeding = currentSpeedKmH > speedLimit;

    return Stack(
      children: [
        // ── TOP INSTRUCTION CARD ──
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: SafeArea(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  color: const Color(0xFF0F172A).withValues(alpha: 0.85),
                  child: Row(
                    children: [
                      // Maneuver Icon Background
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          nextStep != null
                              ? _getManeuverIcon(nextStep!.maneuver)
                              : Icons.navigation_rounded,
                          color: const Color(0xFF22C55E),
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Instruction Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              AppLocalizations.of(context)?.inDistance(_formatDistance(distanceToNextStep)) ??
                                  'In ${_formatDistance(distanceToNextStep)}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              nextStep?.instruction ??
                                  (AppLocalizations.of(context)?.driveTowardYourDestination ??
                                      'Drive toward your destination'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // ── SPEEDOMETER WIDGET (Bottom Left) ──
        Positioned(
          left: 16,
          bottom: 150,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Speedometer Circular Badge
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: isSpeeding
                      ? Colors.red.withValues(alpha: 0.9)
                      : const Color(0xFF0F172A).withValues(alpha: 0.85),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSpeeding ? Colors.white : const Color(0xFF334155),
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        currentSpeedKmH.toStringAsFixed(0),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          shadows: isSpeeding
                              ? [
                                  const Shadow(
                                    blurRadius: 4.0,
                                    color: Colors.black45,
                                    offset: Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                      ),
                      const Text(
                        'km/h',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Speed Limit Sign
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.red, width: 4.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    speedLimit.toStringAsFixed(0),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── BOTTOM DASHBOARD ──
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Navigation Stats Dashboard
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    color: const Color(0xFF0F172A).withValues(alpha: 0.85),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Time Remaining (Large Green Text)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _formatDuration(totalRemainingDuration, context),
                                  style: const TextStyle(
                                    color: Color(0xFF22C55E),
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      _formatDistance(totalRemainingDistance),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.circle,
                                      size: 4,
                                      color: Colors.white30,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      AppLocalizations.of(context)?.navigationEtaLabel(_formatETA(totalRemainingDuration)) ??
                                          'ETA: ${_formatETA(totalRemainingDuration)}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            
                            // Exit Navigation Button
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFEF4444),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                              ),
                              onPressed: onExitNavigation,
                              child: Row(
                                children: [
                                  const Icon(Icons.close_rounded, size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    AppLocalizations.of(context)?.exit ?? 'Exit',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
