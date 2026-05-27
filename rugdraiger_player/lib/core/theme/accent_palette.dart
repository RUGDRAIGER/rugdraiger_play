import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'player_skins.dart';

Color _mix(Color c, Color target, double t) {
  return Color.lerp(c, target, t)!;
}

void applyPlayerSkin(String skinId) {
  final skin = getSkinById(skinId);
  final accent = skin.accent;

  AppColors.accent = accent;
  AppColors.accentDim = _mix(accent, Colors.black, 0.22);
  AppColors.accentBright = _mix(accent, Colors.white, 0.28);
  AppColors.accentIntense = _mix(accent, Colors.white, 0.12);
  AppColors.accentGlow = accent.withValues(alpha: 0.25);
  AppColors.accentSubtle = accent.withValues(alpha: 0.12);
  AppColors.borderAccent = accent.withValues(alpha: 0.4);
  AppColors.neonRed = accent;
  AppColors.neonRedLight = AppColors.accentIntense;
  AppColors.neonRedDark = AppColors.accentDim;
  AppColors.neonRedGlow = AppColors.accentGlow;
  AppColors.neonRedSubtle = AppColors.accentSubtle;
  AppColors.progressActive = accent;
}
