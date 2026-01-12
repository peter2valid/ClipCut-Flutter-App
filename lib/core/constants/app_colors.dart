import 'package:flutter/material.dart';

/// App color palette based on the dark modern design style
/// Extracted from reference images with warm peach accents
class AppColors {
  AppColors._();

  // Primary backgrounds
  static const Color background = Color(0xFF1A1A1A);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surface = Color(0xFF2A2A2A);
  static const Color surfaceLight = Color(0xFF3A3A3A);
  static const Color surfaceLighter = Color(0xFF4A4A4A);

  // Accent colors - warm peach/coral gradient
  static const Color accent = Color(0xFFE8A87C);
  static const Color accentLight = Color(0xFFF5B895);
  static const Color accentDark = Color(0xFFD4956A);

  // Secondary accent - coral/orange
  static const Color secondary = Color(0xFFE86A4C);
  static const Color secondaryLight = Color(0xFFFF8A6A);

  // Text colors
  static const Color textPrimary = Color(0xFFF5F5F0);
  static const Color textSecondary = Color(0xFF8A8A8A);
  static const Color textMuted = Color(0xFF5A5A5A);
  static const Color textOnAccent = Color(0xFF1A1A1A);

  // Semantic colors
  static const Color error = Color(0xFFE57373);
  static const Color errorDark = Color(0xFFCF6679);
  static const Color success = Color(0xFF81C784);
  static const Color successDark = Color(0xFF66BB6A);
  static const Color warning = Color(0xFFFFB74D);

  // Overlay colors
  static const Color overlay = Color(0x80000000);
  static const Color overlayLight = Color(0x40000000);

  // Border colors
  static const Color border = Color(0xFF3A3A3A);
  static const Color borderLight = Color(0xFF4A4A4A);

  // Gradient definitions
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentLight, accent, accentDark],
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [surface, background],
  );

  static const LinearGradient peachGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFF5B895),
      Color(0xFFE8A87C),
      Color(0xFFD4956A),
      Color(0xFFBF8260),
    ],
  );
}
