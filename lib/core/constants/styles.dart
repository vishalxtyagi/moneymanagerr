import 'package:flutter/material.dart';
import 'colors.dart';

class AppStyles {
  AppStyles._();

  // Responsive Breakpoints
  static const double mobile = 768.0;
  static const double tablet = 1024.0;
  static const double desktop = 1440.0;

  // Spacing
  static const double xs = 8.0;
  static const double sm = 16.0;
  static const double md = 24.0;

  // Border Radius
  static const double borderRadius = 12.0;

  // Card Elevation
  static const double elevation = 3.0;

  // Common border radius
  static BorderRadius get defaultRadius => BorderRadius.circular(borderRadius);
  static BorderRadius get cardRadius => BorderRadius.circular(borderRadius);
  static BorderRadius get buttonRadius => BorderRadius.circular(borderRadius);
  static BorderRadius get chipRadius => BorderRadius.circular(borderRadius);

  // Common padding
  static const EdgeInsets paddingXS = EdgeInsets.all(xs);
  static const EdgeInsets paddingSM = EdgeInsets.all(sm);
  static const EdgeInsets paddingMD = EdgeInsets.all(md);

  // Common decorations
  static BoxDecoration get cardDecoration => BoxDecoration(
        borderRadius: cardRadius,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );

  static BoxDecoration get gradientDecoration => BoxDecoration(
        borderRadius: cardRadius,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryVariant],
        ),
      );

  // Common durations
  static const Duration fastAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 500);
  static const Duration slowAnimation = Duration(seconds: 1);
}
