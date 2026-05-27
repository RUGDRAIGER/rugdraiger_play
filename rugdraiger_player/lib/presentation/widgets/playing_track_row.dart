import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/duration_formatter.dart';
import '../../data/models/song_model.dart';
import '../bloc/player/player_bloc.dart';
import 'artwork_widget.dart';
import 'stop_after_hand_button.dart';

class PlayingTrackRow extends StatelessWidget {
  final SongModel song;
  final int index;
  final List<SongModel> queue;
  final VoidCallback onTap;
  final Widget? trailing;

  const PlayingTrackRow({
    super.key,
    required this.song,
    required this.index,
    required this.queue,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerBlocState>(
      buildWhen: (prev, next) =>
          prev.currentSong?.id != next.currentSong?.id ||
          prev.position != next.position ||
          prev.duration != next.duration ||
          prev.status != next.status,
      builder: (context, state) {
        final isCurrent = state.currentSong?.id == song.id;
        final durationMs = state.duration.inMilliseconds;
        final progress = isCurrent && durationMs > 0
            ? (state.position.inMilliseconds / durationMs).clamp(0.0, 1.0)
            : 0.0;

        return Stack(
          children: [
            if (isCurrent)
              Positioned.fill(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.accent.withValues(alpha: 0.2),
                            AppColors.accent.withValues(alpha: 0.07),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            Material(
              color: isCurrent ? AppColors.accentSubtle : Colors.transparent,
              child: InkWell(
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 28,
                        child: Center(
                          child: isCurrent && state.isPlaying
                              ? Icon(Icons.equalizer_rounded, size: 16, color: AppColors.accent)
                              : isCurrent
                                  ? Icon(Icons.play_arrow_rounded, size: 16, color: AppColors.accent)
                                  : Text(
                                      '${song.trackNumber > 0 ? song.trackNumber : index + 1}',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: AppColors.textTertiary,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                        ),
                      ),
                      ArtworkWidget(song: song, size: 38, borderRadius: 4),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          song.title,
                          style: AppTextStyles.titleMedium.copyWith(
                            color: isCurrent ? AppColors.accent : AppColors.textPrimary,
                            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        DurationFormatter.formatMs(song.durationMs),
                        style: AppTextStyles.labelSmall,
                      ),
                      if (trailing != null) trailing!,
                      StopAfterHandButton(songId: song.id, size: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
