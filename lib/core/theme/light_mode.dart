import 'package:flutter/material.dart';

ThemeData lightMode = ThemeData(
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    surface: Colors.white,
    primary: Color(0xFFF35535),
    secondary: Color(0xFFE17421),
    onSurface: Color(0xFF2D3748),
  ),
  scaffoldBackgroundColor: Colors.white,
  fontFamily: 'Cairo',
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: Color(0xFF2D3748),
    elevation: 0,
    iconTheme: IconThemeData(color: Color(0xFF2D3748)),
  ),
);
