import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'styles.dart';
import 'colors.dart';

class AppThemes {
  AppThemes._();

  static final String _fontFamily = GoogleFonts.inter().fontFamily!;
  static final BorderRadius _borderRadius =
      BorderRadius.circular(AppStyles.borderRadius);

  static ThemeData get lightTheme => ThemeData(
        brightness: Brightness.light,
        fontFamily: _fontFamily,
        scaffoldBackgroundColor: AppColors.scaffoldBackground,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
          error: AppColors.error,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.primary,
          elevation: 0,
          foregroundColor: AppColors.textOnPrimary,
          toolbarHeight: 70,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: _fontFamily,
            color: AppColors.textOnPrimary,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textOnPrimary,
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(borderRadius: _borderRadius),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: _borderRadius,
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: _borderRadius,
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.all(16),
          filled: true,
          fillColor: AppColors.textOnPrimary,
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.divider,
          thickness: 1,
          space: 1,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 8,
        ),
        cardTheme: CardTheme(
          elevation: AppStyles.elevation,
          shape: RoundedRectangleBorder(borderRadius: _borderRadius),
          margin: const EdgeInsets.symmetric(vertical: 4),
          color: AppColors.card,
        ),
      );

  // static ThemeData get darkTheme => lightTheme.copyWith(
  //   brightness: Brightness.dark,
  //   scaffoldBackgroundColor: AppColors.darkScaffoldBackground,
  //   colorScheme: const ColorScheme.dark(
  //     primary: AppColors.primary,
  //     secondary: AppColors.secondary,
  //     surface: AppColors.darkSurface,
  //     error: AppColors.error,
  //   ),
  //   cardTheme: lightTheme.cardTheme.copyWith(color: AppColors.darkSurface),
  //   inputDecorationTheme: lightTheme.inputDecorationTheme.copyWith(
  //     fillColor: AppColors.darkInputFill,
  //   ),
  // );
}
