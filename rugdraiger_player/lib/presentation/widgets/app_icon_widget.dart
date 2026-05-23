import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class AppIconWidget extends StatelessWidget {
  final double size;
  final double borderRadius;

  const AppIconWidget({
    super.key,
    required this.size,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.asset(
        'assets/icons/app_icon.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Icon(Icons.play_arrow_rounded, color: AppColors.accent, size: size * 0.55),
        ),
      ),
    );
  }
}
