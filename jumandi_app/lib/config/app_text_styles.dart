import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle get logo => GoogleFonts.bebasNeue(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.brandYellow,
        letterSpacing: 1.2,
      );

  static TextStyle get logoLarge => GoogleFonts.bebasNeue(
        fontSize: 42,
        fontWeight: FontWeight.w700,
        color: AppColors.brandYellow,
        letterSpacing: 2,
      );

  static TextStyle get heading => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: AppColors.white,
        letterSpacing: 0.5,
      );

  static TextStyle get headingSmall => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.white,
      );

  static TextStyle get body => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.5,
      );

  static TextStyle get label => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
        letterSpacing: 1.2,
      );

  static TextStyle get button => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        letterSpacing: 1,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
      );
}
