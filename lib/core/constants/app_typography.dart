import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typography system based on reference design
/// Uses bold condensed headings and clean body text
class AppTypography {
  AppTypography._();

  // Heading styles - Bold condensed (Bebas Neue via Google Fonts)
  static TextStyle get displayLarge => GoogleFonts.bebasNeue(
        fontSize: 64,
        fontWeight: FontWeight.w400,
        letterSpacing: 4,
        height: 1.1,
        color: AppColors.textPrimary,
      );

  static TextStyle get displayMedium => GoogleFonts.bebasNeue(
        fontSize: 48,
        fontWeight: FontWeight.w400,
        letterSpacing: 3,
        height: 1.1,
        color: AppColors.textPrimary,
      );

  static TextStyle get displaySmall => GoogleFonts.bebasNeue(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        letterSpacing: 2,
        height: 1.2,
        color: AppColors.textPrimary,
      );

  static TextStyle get headlineLarge => GoogleFonts.bebasNeue(
        fontSize: 32,
        fontWeight: FontWeight.w400,
        letterSpacing: 2,
        height: 1.2,
        color: AppColors.textPrimary,
      );

  static TextStyle get headlineMedium => GoogleFonts.bebasNeue(
        fontSize: 28,
        fontWeight: FontWeight.w400,
        letterSpacing: 1.5,
        height: 1.2,
        color: AppColors.textPrimary,
      );

  static TextStyle get headlineSmall => GoogleFonts.bebasNeue(
        fontSize: 24,
        fontWeight: FontWeight.w400,
        letterSpacing: 1,
        height: 1.3,
        color: AppColors.textPrimary,
      );

  // Body styles - Clean sans-serif (Inter)
  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.textSecondary,
      );

  // Label styles
  static TextStyle get labelLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: AppColors.textPrimary,
      );

  static TextStyle get labelMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: AppColors.textPrimary,
      );

  static TextStyle get labelSmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: AppColors.textSecondary,
      );

  // Button text
  static TextStyle get buttonLarge => GoogleFonts.bebasNeue(
        fontSize: 20,
        fontWeight: FontWeight.w400,
        letterSpacing: 2,
        color: AppColors.textOnAccent,
      );

  static TextStyle get buttonMedium => GoogleFonts.bebasNeue(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 1.5,
        color: AppColors.textOnAccent,
      );

  // Caption and metadata
  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textMuted,
      );

  static TextStyle get overline => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
        color: AppColors.textSecondary,
      );
}
