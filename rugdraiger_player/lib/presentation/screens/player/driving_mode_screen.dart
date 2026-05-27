import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../../services/settings_service.dart';
import '../../bloc/player/player_bloc.dart';
import '../../utils/player_navigation.dart';
import '../../widgets/artwork_widget.dart';

class DrivingModeScreen extends StatelessWidget {
  const DrivingModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      child: SafeArea(
        child: BlocBuilder<PlayerBloc, PlayerBlocState>(
          builder: (context, state) {
            if (!state.hasActiveSong) {
              return Center(
                child: TextButton(
                  onPressed: () => SettingsService.instance.setDrivingMode(false),
                  child: const Text('Cerrar modo conducción'),
                ),
              );
            }

            final song = state.currentSong!;
            return Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                    onPressed: () => SettingsService.instance.setDrivingMode(false),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => context.read<PlayerBloc>().add(const TogglePlayPauseEvent()),
                    child: Center(
                      child: ArtworkWidget(
                        song: song,
                        size: MediaQuery.of(context).size.width * 0.72,
                        borderRadius: 20,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Text(
                        song.title,
                        style: AppTextStyles.displayMedium.copyWith(fontSize: 26),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        song.artist,
                        style: AppTextStyles.bodyLarge.copyWith(color: AppColors.neonRed),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: state.progress.clamp(0.0, 1.0),
                        backgroundColor: AppColors.surface3,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.neonRed),
                        minHeight: 4,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DurationFormatter.format(state.position),
                            style: AppTextStyles.labelSmall,
                          ),
                          Text(
                            DurationFormatter.format(state.duration),
                            style: AppTextStyles.labelSmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _BigControl(
                      icon: Icons.skip_previous_rounded,
                      onTap: () => context.read<PlayerBloc>().add(const SkipPreviousEvent()),
                    ),
                    _BigControl(
                      icon: state.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      size: 88,
                      filled: true,
                      onTap: () => context.read<PlayerBloc>().add(const TogglePlayPauseEvent()),
                    ),
                    _BigControl(
                      icon: Icons.skip_next_rounded,
                      onTap: () => context.read<PlayerBloc>().add(const SkipNextEvent()),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () {
                    SettingsService.instance.setDrivingMode(false);
                    openFullPlayer(context);
                  },
                  child: const Text('Reproductor completo'),
                ),
                const SizedBox(height: 16),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BigControl extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final bool filled;

  const _BigControl({
    required this.icon,
    required this.onTap,
    this.size = 64,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: filled ? AppColors.neonRed : AppColors.surfaceElevated,
          shape: BoxShape.circle,
          border: filled ? null : Border.all(color: AppColors.border),
          boxShadow: filled
              ? [
                  BoxShadow(
                    color: AppColors.neonRed.withValues(alpha: 0.35),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          color: filled ? Colors.white : AppColors.textPrimary,
          size: size * 0.45,
        ),
      ),
    );
  }
}
