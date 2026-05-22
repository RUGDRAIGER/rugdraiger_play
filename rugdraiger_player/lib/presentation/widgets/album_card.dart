import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';

class AlbumCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? artwork;
  final VoidCallback? onTap;
  final bool isActive;

  const AlbumCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.artwork,
    this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          border: Border.all(
            color: isActive ? AppColors.neonRed : AppColors.border,
            width: isActive ? 1.5 : 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Artwork
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppConstants.borderRadiusMedium - 1),
                ),
                child: artwork ??
                    Container(
                      color: AppColors.surfaceElevated,
                      child: Icon(
                        Icons.album_rounded,
                        color: AppColors.neonRed.withValues(alpha: 0.4),
                        size: 40,
                      ),
                    ),
              ),
            ),

            // Info
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SongListTile extends StatelessWidget {
  final String title;
  final String artist;
  final String? duration;
  final String? qualityBadge;
  final Widget? leading;
  final VoidCallback? onTap;
  final VoidCallback? onMoreTap;
  final bool isPlaying;
  final int? index;

  const SongListTile({
    super.key,
    required this.title,
    required this.artist,
    this.duration,
    this.qualityBadge,
    this.leading,
    this.onTap,
    this.onMoreTap,
    this.isPlaying = false,
    this.index,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // Index or artwork
            if (leading != null)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: leading!,
              )
            else if (index != null)
              SizedBox(
                width: 28,
                child: Text(
                  '${index! + 1}',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isPlaying ? AppColors.neonRed : AppColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isPlaying)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Icon(
                            Icons.equalizer_rounded,
                            color: AppColors.neonRed,
                            size: 14,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          title,
                          style: AppTextStyles.titleMedium.copyWith(
                            color: isPlaying ? AppColors.neonRed : AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (qualityBadge != null) ...[
                        const SizedBox(width: 8),
                        _QualityBadge(label: qualityBadge!),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    artist,
                    style: AppTextStyles.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Duration & more button
            if (duration != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(duration!, style: AppTextStyles.labelSmall),
              ),
            if (onMoreTap != null)
              GestureDetector(
                onTap: onMoreTap,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.more_vert_rounded, color: AppColors.textMuted, size: 20),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _QualityBadge extends StatelessWidget {
  final String label;

  const _QualityBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.neonRed.withValues(alpha: 0.6), width: 0.8),
        borderRadius: BorderRadius.circular(4),
        color: AppColors.neonRedSubtle,
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w700,
          color: AppColors.neonRedLight,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class NeonButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool filled;

  const NeonButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: filled ? AppColors.neonRed : Colors.transparent,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          border: filled ? null : Border.all(color: AppColors.neonRed, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
