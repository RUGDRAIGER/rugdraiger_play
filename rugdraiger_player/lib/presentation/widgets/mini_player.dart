import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/duration_formatter.dart';
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

        return Material(
          color: AppColors.surfaceElevated,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(
                value: state.progress.clamp(0.0, 1.0),
                backgroundColor: AppColors.surface3,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                minHeight: 3,
              ),
              SizedBox(
                height: AppConstants.miniPlayerHeight - 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: onTap,
                        child: Row(
                          children: [
                            ArtworkWidget(song: state.currentSong!, size: 44, borderRadius: 6),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 120,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    state.currentSong!.title,
                                    style: AppTextStyles.titleMedium.copyWith(fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    state.errorMessage ?? state.currentSong!.artist,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontSize: 12,
                                      color: state.errorMessage != null ? Colors.redAccent : AppColors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${DurationFormatter.format(state.position)}/${DurationFormatter.format(state.duration)}',
                        style: AppTextStyles.labelSmall.copyWith(fontSize: 11),
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_previous_rounded, size: 22),
                        color: AppColors.textSecondary,
                        onPressed: () => context.read<PlayerBloc>().add(const SkipPreviousEvent()),
                      ),
                      GestureDetector(
                        onTap: () => context.read<PlayerBloc>().add(const TogglePlayPauseEvent()),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                          child: Icon(
                            state.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next_rounded, size: 22),
                        color: AppColors.textSecondary,
                        onPressed: () => context.read<PlayerBloc>().add(const SkipNextEvent()),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
