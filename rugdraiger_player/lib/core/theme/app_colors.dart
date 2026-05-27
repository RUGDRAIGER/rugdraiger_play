import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color background = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF141414);
  static const Color surfaceElevated = Color(0xFF1C1C1E);
  static const Color surface2 = Color(0xFF2C2C2E);
  static const Color surface3 = Color(0xFF3A3A3C);

  static Color accent = const Color(0xFFFF2020);
  static Color accentDim = const Color(0xFFCC1A1A);
  static Color accentBright = const Color(0xFFFF6060);
  static Color accentIntense = const Color(0xFFFF3333);
  static Color accentGlow = const Color(0x40FF2020);
  static Color accentSubtle = const Color(0x1FFF2020);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color textTertiary = Color(0xFF48484A);

  static const Color borderSubtle = Color(0x14FFFFFF);
  static Color borderAccent = const Color(0x66FF2020);

  static const Color error = Color(0xFFFF1744);

  static const LinearGradient playerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1A0000), Color(0xFF0A0A0A)],
  );

  static Color neonRed = accent;
  static Color neonRedLight = accentIntense;
  static Color neonRedDark = accentDim;
  static Color neonRedGlow = accentGlow;
  static Color neonRedSubtle = accentSubtle;
  static const Color textMuted = textTertiary;
  static const Color surfaceCard = surfaceElevated;
  static const Color surfaceModal = surface2;
  static const Color border = borderSubtle;
  static const Color divider = borderSubtle;
  static const Color progressBackground = surface2;
  static Color progressActive = accent;
}
