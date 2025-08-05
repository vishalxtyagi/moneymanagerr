import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Theme Colors
  static const Color primary = Color(0xFF4CAF50);
  static const Color primaryVariant = Color(0xFF388E3C);
  static const Color secondary = Color(0xFF81C784);

  // Semantic Colors
  static const Color success = primary;
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = secondary;

  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textDisabled = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Colors.white;


  // Backgrounds and Surfaces
  static const Color scaffoldBackground = Color(0xFFF5F7FA);
  static const Color surface = Colors.white;
  static const Color card = Colors.white;

  // Dark Mode Colors
  // static const Color darkScaffoldBackground = Color(0xFF121212);
  // static const Color darkSurface = Color(0xFF1E1E1E);
  // static const Color darkInputFill = Color(0xFF2A2A2A);

  // UI Elements
  static const Color border = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFEEEEEE);


  // Color Palette
  static const List<Color> colorPalette = [
    Color(0xFFF44336), // Red
    Color(0xFF4CAF50), // Green
    Color(0xFFFFEB3B), // Yellow
    Color(0xFFFF9800), // Orange
    Color(0xFF2196F3), // Blue
    Color(0xFF9C27B0), // Purple
    Color(0xFF795548), // Brown
    Color(0xFF607D8B), // Blue Grey
    Color(0xFFE91E63), // Pink
    Color(0xFF00BCD4), // Cyan
  ];

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryVariant],
  );
}
