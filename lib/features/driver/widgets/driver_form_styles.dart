import 'package:flutter/material.dart';

/// Shared design constants for the driver application form.
abstract final class DriverFormStyles {
  // ── Colors ─────────────────────────────────────────────────────────────────

  static Color primaryColor = const Color(0xFF1976D2);
  static Color accentColor = const Color(0xFF42A5F5);
  static Color errorColor = const Color(0xFFD32F2F);
  static Color successColor = const Color(0xFF388E3C);
  static Color surfaceColor = const Color(0xFFF5F5F5);
  static Color borderColor = const Color(0xFFE0E0E0);
  static Color labelColor = const Color(0xFF616161);
  static Color uploadBg = const Color(0xFFF0F7FF);

  // ── Spacing ────────────────────────────────────────────────────────────────

  static const double horizontalPadding = 20.0;
  static const double verticalSpacing = 16.0;
  static const double sectionSpacing = 24.0;
  static const double cardRadius = 12.0;
  static const double inputRadius = 10.0;

  // ── Input Decoration ───────────────────────────────────────────────────────

  static InputDecoration inputDecoration({
    required String label,
    String? hint,
    IconData? prefixIcon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
      suffix: suffix,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputRadius),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputRadius),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputRadius),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputRadius),
        borderSide: BorderSide(color: errorColor),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  // ── Section Header ─────────────────────────────────────────────────────────

  static TextStyle get sectionTitle => const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Color(0xFF212121),
      );

  static TextStyle get sectionSubtitle => TextStyle(
        fontSize: 14,
        color: labelColor,
        height: 1.4,
      );

  // ── Card Decoration ────────────────────────────────────────────────────────

  static BoxDecoration get cardDecoration => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(cardRadius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      );
}
