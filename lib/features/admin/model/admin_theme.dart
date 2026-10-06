import 'package:flutter/material.dart';

/// Centralised admin-panel colour palette.
///
/// All admin feature widgets reference these constants via
/// `AdminTheme.primaryOrange`, etc.  The previous approach of private
/// `_AdminAppState` statics is replaced by this public, importable class.
class AdminTheme {
  AdminTheme._(); // prevent instantiation

  // ── Brand / Primary ────────────────────────────────────────────────
  static Color primaryOrange = const Color(0xFFF35535);
  static Color primaryLight = const Color(0xFFFF8B5E);
  static Color primaryDark = const Color(0xFFCC552A);
  static Color accentOrange = const Color(0xFFFF914D);

  // ── Neutrals ───────────────────────────────────────────────────────
  static Color white = Colors.white;
  static Color backgroundWhite = const Color(0xFFFFFFFF);
  static Color surfaceWhite = const Color(0xFFFFFFFF);
  static Color cardWhite = const Color(0xFFFEFEFE);
  static Color contentBg = const Color(0xFFF8FAFC);

  // ── Text ───────────────────────────────────────────────────────────
  static Color textDark = const Color(0xFF2D3748);
  static Color textMedium = const Color(0xFF4A5568);
  static Color textLight = const Color(0xFF718096);

  // ── Border ─────────────────────────────────────────────────────────
  static Color borderColor = const Color(0xFFE2E8F0);

  // ── Semantic ───────────────────────────────────────────────────────
  static Color successGreen = const Color(0xFF38A169);
  static Color warningAmber = const Color(0xFFED8936);
  static Color errorRed = const Color(0xFFE53E3E);
  static Color infoBlue = const Color(0xFF3182CE);

  // ── Light Sidebar ───────────────────────────────────────────────────
  /// White background used as the sidebar background.
  static const Color sidebarBg = Color(0xFFFFFFFF);

  /// Slightly darker surface inside the sidebar (footer bg).
  static const Color sidebarSurface = Color(0xFFF8FAFC);

  /// Subtle separator/border inside the sidebar.
  static const Color sidebarBorder = Color(0xFFE2E8F0);

  /// Default text & icon colour on the light sidebar.
  static const Color sidebarText = Color(0xFF718096);

  /// Active / highlighted text & icon colour on the light sidebar.
  static const Color sidebarTextActive = Color(0xFF2D3748);
}
