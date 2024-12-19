import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static final headLineLarge32 = GoogleFonts.nunito(
    fontSize: 32,
    fontWeight: FontWeight.w700,
  );

  static final titleExtraLarge24 = GoogleFonts.nunito(
    fontSize: 24,
    fontWeight: FontWeight.w700,
  );

  static final titleLarge20 = GoogleFonts.nunito(
    fontSize: 20,
    fontWeight: FontWeight.w700,
  );

  static final titleMedium18 = GoogleFonts.nunito(
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );

  static final titleSmall16 = GoogleFonts.nunito(
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );

  static final titleExtraSmall14 = GoogleFonts.nunito(
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );

  static final titleTiny12 = GoogleFonts.nunito(
    fontSize: 12,
    fontWeight: FontWeight.w700,
  );

  static final bodyHuge20 = GoogleFonts.nunito(
    fontSize: 20,
    fontWeight: FontWeight.w400,
  );

  static final bodyExtraLarge18 = GoogleFonts.nunito(
    fontSize: 18,
    fontWeight: FontWeight.w400,
  );

  static final bodyLarge16 = GoogleFonts.nunito(
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  static final bodyMedium14 = GoogleFonts.nunito(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  static final bodySmall12 = GoogleFonts.nunito(
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  static final InputDecorationTheme inputDecorationTheme = InputDecorationTheme(
    border: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
    labelStyle: AppTheme.bodyLarge16,
  );

  static final ElevatedButtonThemeData elevatedButtonTheme =
      ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      foregroundColor: AppColors.mono0,
      backgroundColor: AppColors.blueberry100,
      disabledForegroundColor: AppColors.mono60,
      disabledBackgroundColor: AppColors.mono40,
      elevation: 0,
      textStyle: AppTheme.titleExtraSmall14,
      fixedSize: Size(double.infinity, 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
    ),
  );
}
