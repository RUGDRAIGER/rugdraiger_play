import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../bloc/player/player_bloc.dart';
import 'artwork_widget.dart';

class MiniPlayer extends StatelessWidget {
  final VoidCallback? onTap;

  const MiniPlayer({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerBlocState>(
      builder: (context, state) {
        if (!state.hasActiveSong) return const SizedBox.shrink();

        return GestureDetector(
          onTap: onTap,
          child: Container(
            height: AppConstants.miniPlayerHeight,
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
              border: Border.all(color: AppColors.border, width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.neonRed.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Progress bar at top
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppConstants.borderRadiusMedium),
                  ),
                  child: LinearProgressIndicator(
                    value: state.progress,
                    backgroundColor: AppColors.progressBackground,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.neonRed),
                    minHeight: 2,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        // Artwork
                        ArtworkWidget(
                          song: state.currentSong!,
                          size: 44,
                          borderRadius: 8,
                        ),
                        const SizedBox(width: 12),

                        // Song info
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                state.currentSong!.title,
                                style: AppTextStyles.titleMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                state.currentSong!.artist,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.neonRed,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        // Controls
                        Row(
                          children: [
                            _ControlButton(
                              icon: Icons.skip_previous_rounded,
                              onTap: () => context.read<PlayerBloc>().add(const SkipPreviousEvent()),
                              size: 28,
                            ),
                            const SizedBox(width: 4),
                            _PlayPauseButton(isPlaying: state.isPlaying),
                            const SizedBox(width: 4),
                            _ControlButton(
                              icon: Icons.skip_next_rounded,
                              onTap: () => context.read<PlayerBloc>().add(const SkipNextEvent()),
                              size: 28,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ).animate().slideY(begin: 1.0, end: 0.0, duration: 300.ms, curve: Curves.easeOut);
      },
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  final bool isPlaying;

  const _PlayPauseButton({required this.isPlaying});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<PlayerBloc>().add(const TogglePlayPauseEvent()),
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: AppColors.neonRed,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  const _ControlButton({
    required this.icon,
    required this.onTap,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, color: AppColors.textSecondary, size: size),
      ),
    );
  }
}
