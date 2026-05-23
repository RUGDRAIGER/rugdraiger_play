import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Web design tokens
  static const Color background = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF141414);
  static const Color surfaceElevated = Color(0xFF1C1C1E);
  static const Color surface2 = Color(0xFF2C2C2E);
  static const Color surface3 = Color(0xFF3A3A3C);

  static const Color accent = Color(0xFFFF2020);
  static const Color accentDim = Color(0xFFCC1A1A);
  static const Color accentGlow = Color(0x40FF2020);
  static const Color accentSubtle = Color(0x1FFF2020);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color textTertiary = Color(0xFF48484A);

  static const Color borderSubtle = Color(0x14FFFFFF);
  static const Color borderAccent = Color(0x66FF2020);

  static const Color error = Color(0xFFFF1744);

  static const LinearGradient playerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1A0000), Color(0xFF0A0A0A)],
  );

  // Legacy aliases used across existing widgets
  static const Color neonRed = accent;
  static const Color neonRedLight = Color(0xFFFF3333);
  static const Color neonRedDark = accentDim;
  static const Color neonRedGlow = accentGlow;
  static const Color neonRedSubtle = accentSubtle;
  static const Color textMuted = textTertiary;
  static const Color surfaceCard = surfaceElevated;
  static const Color surfaceModal = surface2;
  static const Color border = borderSubtle;
  static const Color divider = borderSubtle;
  static const Color progressBackground = surface2;
  static const Color progressActive = accent;
}
