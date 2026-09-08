import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static final title32 = GoogleFonts.nunito(
    fontSize: 32,
    fontWeight: FontWeight.w700,
  );

  static final title24 = GoogleFonts.nunito(
    fontSize: 24,
    fontWeight: FontWeight.w700,
  );

  static final title20 = GoogleFonts.nunito(
    fontSize: 20,
    fontWeight: FontWeight.w700,
  );

  static final title18 = GoogleFonts.nunito(
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );

  static final title16 = GoogleFonts.nunito(
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );

  static final title14 = GoogleFonts.nunito(
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );

  static final title12 = GoogleFonts.nunito(
    fontSize: 12,
    fontWeight: FontWeight.w700,
  );

  static final title10 = GoogleFonts.nunito(
    fontSize: 10,
    fontWeight: FontWeight.w700,
  );

  static final subtitle16 = GoogleFonts.nunito(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static final subtitle14 = GoogleFonts.nunito(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  static final subtitle12 = GoogleFonts.nunito(
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );

  static final label16 = GoogleFonts.nunito(
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  static final label14 = GoogleFonts.nunito(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static final label12 = GoogleFonts.nunito(
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  static final body16 = GoogleFonts.nunito(
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  static final body14 = GoogleFonts.nunito(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  static final body12 = GoogleFonts.nunito(
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  static ThemeData get materialTheme {
    const primary = Color(0xFF7C3AED);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      surface: const Color(0xFFF7F4FD),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF7F4FD),
      textTheme: GoogleFonts.nunitoTextTheme(),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE8E1F4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE8E1F4)),
        ),
      ),
    );
  }

  static ThemeData get darkMaterialTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.brandSurface,
      brightness: Brightness.dark,
      surface: AppColors.mono90,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.mono100,
      textTheme: GoogleFonts.nunitoTextTheme(ThemeData.dark().textTheme),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.mono90,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.mono80),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.mono80),
        ),
      ),
    );
  }
}
