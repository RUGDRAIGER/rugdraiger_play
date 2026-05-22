import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Palette - Carbon Black
  static const Color background = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF141414);
  static const Color surfaceElevated = Color(0xFF1C1C1C);
  static const Color surfaceCard = Color(0xFF1E1E1E);
  static const Color surfaceModal = Color(0xFF242424);

  // Neon Red Accent
  static const Color neonRed = Color(0xFFFF0000);
  static const Color neonRedLight = Color(0xFFFF3333);
  static const Color neonRedDark = Color(0xFFCC0000);
  static const Color neonRedGlow = Color(0x40FF0000);
  static const Color neonRedSubtle = Color(0x1AFF0000);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textMuted = Color(0xFF6B6B6B);
  static const Color textDisabled = Color(0xFF3A3A3A);

  // Borders & Dividers
  static const Color border = Color(0xFF2A2A2A);
  static const Color borderActive = Color(0xFFFF0000);
  static const Color divider = Color(0xFF1F1F1F);

  // Progress & Indicators
  static const Color progressBackground = Color(0xFF2A2A2A);
  static const Color progressActive = Color(0xFFFF0000);

  // Semantic
  static const Color success = Color(0xFF00C853);
  static const Color warning = Color(0xFFFFAB00);
  static const Color error = Color(0xFFFF1744);

  // Gradients
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0A0A0A), Color(0xFF121212)],
  );

  static const LinearGradient neonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF0000), Color(0xFFCC0000)],
  );

  static const LinearGradient playerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1A0000), Color(0xFF0A0A0A)],
  );

  static RadialGradient neonGlow(Color color) => RadialGradient(
    colors: [color.withValues(alpha: 0.3), Colors.transparent],
    radius: 1.0,
  );
}
