import 'dart:math';
import 'package:z_speed/core/enums/driver_enums.dart';
import 'package:z_speed/features/restaurant/model/restaurant.dart';

/// Service for calculating delivery fees based on restaurant configuration.
///
/// Supports three modes:
/// 1. Fixed fee (flat rate)
/// 2. Distance-based with bracket tiers (e.g., 0-3km = 15 EGP, 3-7km = 25 EGP)
/// 3. Distance-based with formula (baseFee + perKmRate × distance)
class DeliveryFeeCalculator {
  DeliveryFeeCalculator._();

  /// Calculate distance in kilometers between two lat/lng points using Haversine formula.
  ///
  /// Returns straight-line distance (not road distance).
  static double calculateDistanceKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadiusKm = 6371.0;

    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadiusKm * c;
  }

  /// Calculate delivery fee based on restaurant settings and customer location.
  ///
  /// Returns fee in the restaurant's currency (typically EGP).
  ///
  /// Throws [ArgumentError] if restaurant settings are invalid.
  static double calculateFee({
    required Restaurant restaurant,
    required double customerLat,
    required double customerLng,
    double? distanceKm,
  }) {
    // Use routed distance when provided; otherwise fall back to straight-line.
    final distance = distanceKm ??
        calculateDistanceKm(
          restaurant.latitude,
          restaurant.longitude,
          customerLat,
          customerLng,
        );

    final minFee = restaurant.deliveryFee > 0.0 ? restaurant.deliveryFee : 49.0;

    // Priority 1: Multi-Area map override rules
    if (restaurant.deliveryFeeAreas != null &&
        restaurant.deliveryFeeAreas!.isNotEmpty) {
      for (final area in restaurant.deliveryFeeAreas!) {
        final centerLat = (area['centerLat'] as num?)?.toDouble() ?? 0.0;
        final centerLng = (area['centerLng'] as num?)?.toDouble() ?? 0.0;
        final radiusKm = (area['radiusKm'] as num?)?.toDouble() ?? 10.0;
        final totalFee = (area['totalFee'] as num?)?.toDouble() ??
            (area['fixedFee'] as num?)?.toDouble() ??
            (area['baseFee'] as num?)?.toDouble() ??
            60.0;

        // Check if customer location is inside this map area
        final distFromCenter = calculateDistanceKm(
          centerLat,
          centerLng,
          customerLat,
          customerLng,
        );

        if (distFromCenter <= radiusKm) {
          // Return fixed total delivery fee for this custom area
          return totalFee;
        }
      }
    }

    // Priority 2: Standard deliveryFeeMode (Formula, Tiers, or Fixed)
    if (restaurant.deliveryFeeMode == DeliveryFeeMode.distance) {
      if (restaurant.deliveryFeeSubMode == DeliveryFeeSubMode.formula) {
        if (restaurant.deliveryFeeFormula != null) {
          final baseFee = restaurant.deliveryFeeFormula!['baseFee'] ?? 0.0;
          final perKmRate = restaurant.deliveryFeeFormula!['perKmRate'] ?? 0.0;
          double calculated = baseFee;
          if (perKmRate > 0.0) {
            final baseKm = baseFee / perKmRate;
            if (distance > baseKm) {
              calculated = baseFee + (distance - baseKm) * perKmRate;
            }
          }
          return calculated > minFee ? calculated : minFee;
        }
      } else if (restaurant.deliveryFeeSubMode == DeliveryFeeSubMode.tiers) {
        if (restaurant.deliveryFeeTiers != null &&
            restaurant.deliveryFeeTiers!.isNotEmpty) {
          double tierFee = restaurant.deliveryFee;
          for (final tier in restaurant.deliveryFeeTiers!) {
            final maxKm = (tier['maxKm'] as num).toDouble();
            if (distance <= maxKm) {
              tierFee = (tier['fee'] as num).toDouble();
              break;
            }
          }
          return tierFee > minFee ? tierFee : minFee;
        }
      }
    }

    if (restaurant.deliveryFeeMode == DeliveryFeeMode.fixed) {
      return restaurant.deliveryFee > 0.0 ? restaurant.deliveryFee : 49.0;
    }

    // Default static delivery fee rule: minimum minFee, plus 7 EGP per km for every km exceeding 7 km
    if (distance > 7.0) {
      return minFee + (distance - 7.0) * 7.0;
    }
    return minFee;
  }

  /// Check if customer is within the restaurant's delivery radius.
  ///
  /// Returns true if distance <= restaurant.deliveryRadiusKm.
  static bool isWithinDeliveryRadius({
    required Restaurant restaurant,
    required double customerLat,
    required double customerLng,
  }) {
    final distance = calculateDistanceKm(
      restaurant.latitude,
      restaurant.longitude,
      customerLat,
      customerLng,
    );
    return distance <= restaurant.deliveryRadiusKm;
  }

  static double _toRadians(double degrees) {
    return degrees * pi / 180.0;
  }
}
