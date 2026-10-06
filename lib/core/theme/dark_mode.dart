import 'package:flutter/material.dart';

ThemeData darkMode = ThemeData(
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    surface: Color(0xFF1A202C),
    primary: Color(0xFFF35535),
    secondary: Color(0xFF2D3748),
    onSurface: Colors.white,
  ),
  scaffoldBackgroundColor: const Color(0xFF1A202C),
  fontFamily: 'Cairo',
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF1A202C),
    foregroundColor: Colors.white,
    elevation: 0,
    iconTheme: IconThemeData(color: Colors.white),
  ),
);
