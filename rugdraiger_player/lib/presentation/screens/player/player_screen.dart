import 'dart:ui';

import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../../data/models/song_model.dart';
import '../../../services/artwork_cache.dart';
import '../../bloc/player/player_bloc.dart';
import '../../widgets/artwork_widget.dart';
import '../../widgets/favorite_button.dart';
import '../../widgets/stop_after_hand_button.dart';
import '../../widgets/volume_fader.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  bool _isSeeking = false;
  double _seekValue = 0.0;
  bool _searchingArtwork = false;
  int _artworkKey = 0;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PlayerBloc, PlayerBlocState>(
      listener: (context, state) {
        if (state.isPlaying) {
          _rotationController.forward();
        } else {
          _rotationController.stop();
        }
      },
      builder: (context, state) {
        if (!state.hasActiveSong && state.status != PlayerStatus.loading) {
          return _buildEmptyPlayer(context);
        }

        if (state.status == PlayerStatus.loading && state.currentSong != null) {
          return _buildLoadingPlayer(context, state);
        }
        if (state.status == PlayerStatus.error && state.errorMessage != null) {
          return _buildErrorPlayer(context, state.errorMessage!);
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Container(
            decoration: const BoxDecoration(gradient: AppColors.playerGradient),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = MediaQuery.of(context).size.width;
                  final screenHeight = MediaQuery.of(context).size.height;
                  final isCompact = screenHeight < 700;
                  final horizontalPadding = screenWidth < 360 ? 16.0 : 24.0;
                  final artworkSize = (screenWidth - horizontalPadding * 2)
                      .clamp(180.0, isCompact ? 260.0 : 340.0);

                  return Column(
                    children: [
                      _buildTopBar(context, state),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                            child: Column(
                              children: [
                                SizedBox(height: isCompact ? 4 : 8),
                                _buildQualityBadge(state),
                                SizedBox(height: isCompact ? 10 : 16),
                                _buildArtworkRow(state, artworkSize),
                                SizedBox(height: isCompact ? 16 : 28),
                                _buildSongInfo(context, state),
                                SizedBox(height: isCompact ? 16 : 24),
                                _buildWaveformProgress(state, horizontalPadding),
                                const SizedBox(height: 8),
                                _buildProgressBar(context, state),
                                const SizedBox(height: 4),
                                _buildTimeRow(state),
                                SizedBox(height: isCompact ? 20 : 32),
                                _buildControls(context, state, isCompact: isCompact),
                                SizedBox(height: isCompact ? 12 : 20),
                                VolumeFader(
                                  volume: state.volume,
                                  isMuted: state.isMuted,
                                  width: screenWidth - horizontalPadding * 2 - 32,
                                  onVolumeChange: (v) =>
                                      context.read<PlayerBloc>().add(SetVolumeEvent(v)),
                                  onToggleMute: () =>
                                      context.read<PlayerBloc>().add(const ToggleMuteEvent()),
                                ),
                                SizedBox(height: isCompact ? 16 : 24),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar(BuildContext context, PlayerBlocState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 30),
            color: AppColors.textSecondary,
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              AppConstants.appName,
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.neonRed,
                letterSpacing: 3,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 48,
            height: 48,
            child: _searchingArtwork
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    icon: const Icon(Icons.more_vert_rounded),
                    color: AppColors.textSecondary,
                    onPressed: () => _showArtworkMenu(context, state),
                  ),
          ),
        ],
      ),
    );
  }

  void _showArtworkMenu(BuildContext context, PlayerBlocState state) {
    final song = state.currentSong;
    if (song == null) return;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceModal,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Icon(Icons.image_search_rounded, color: AppColors.neonRed),
                title: const Text('Buscar imagen de carátula'),
                subtitle: Text(
                  song.title,
                  style: AppTextStyles.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _searchArtwork(context, song);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _searchArtwork(BuildContext context, SongModel song) async {
    setState(() => _searchingArtwork = true);
    try {
      final art = await ArtworkCache.searchRemoteArtwork(song);
      if (!mounted) return;

      final messenger = ScaffoldMessenger.of(context);
      if (art != null) {
        setState(() => _artworkKey++);
        messenger.showSnackBar(
          SnackBar(
            content: const Text('Carátula encontrada y aplicada'),
            backgroundColor: AppColors.surfaceElevated,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: const Text('No se encontró carátula. Verificá conexión a internet.'),
            backgroundColor: AppColors.surfaceElevated,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _searchingArtwork = false);
    }
  }

  Widget _buildQualityBadge(PlayerBlocState state) {
    final song = state.currentSong!;
    if (!song.isLossless && song.bitrate == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(20),
        color: AppColors.surfaceElevated,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.hd_outlined, color: AppColors.neonRed, size: 14),
          const SizedBox(width: 6),
          Text(
            song.isLossless ? song.qualityBadge : song.formattedBitrate,
            style: AppTextStyles.neonLabel.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildArtworkRow(PlayerBlocState state, double size) {
    final prev = _neighborSong(state, -1);
    final next = _neighborSong(state, 1);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        prev != null ? _buildNeighborPreview(prev) : const SizedBox(width: 72),
        const SizedBox(width: 12),
        _buildArtwork(state, size),
        const SizedBox(width: 12),
        next != null ? _buildNeighborPreview(next) : const SizedBox(width: 72),
      ],
    );
  }

  SongModel? _neighborSong(PlayerBlocState state, int delta) {
    if (state.queue.isEmpty) return null;
    final idx = state.currentIndex + delta;
    if (idx < 0 || idx >= state.queue.length) return null;
    return state.queue[idx];
  }

  Widget _buildNeighborPreview(SongModel song) {
    return SizedBox(
      width: 72,
      child: Opacity(
        opacity: 0.55,
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
                child: ArtworkWidget(song: song, size: 56, borderRadius: 8),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              song.title,
              style: AppTextStyles.labelSmall.copyWith(fontSize: 10, color: AppColors.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtwork(PlayerBlocState state, double size) {
    return GestureDetector(
      onTap: () => context.read<PlayerBloc>().add(const TogglePlayPauseEvent()),
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity < -200) {
          context.read<PlayerBloc>().add(const SkipNextEvent());
        } else if (velocity > 200) {
          context.read<PlayerBloc>().add(const SkipPreviousEvent());
        }
      },
      child: Hero(
        tag: 'artwork-${state.currentSong!.id}',
        child: LargeArtworkWidget(
          key: ValueKey('player-art-${state.currentSong!.id}-$_artworkKey'),
          song: state.currentSong!,
          size: size,
        ).animate(target: state.isPlaying ? 1.0 : 0.95).scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1.0, 1.0),
          duration: 300.ms,
          curve: Curves.easeOut,
        ),
      ),
    );
  }

  Widget _buildSongInfo(BuildContext context, PlayerBlocState state) {
    final song = state.currentSong!;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                song.title,
                style: AppTextStyles.displayMedium.copyWith(fontSize: 22),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                song.artist,
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.neonRed),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FavoriteButton(song: song, size: 28),
            const SizedBox(height: 8),
            StopAfterHandButton(songId: song.id, size: 22),
          ],
        ),
      ],
    );
  }

  Widget _buildWaveformProgress(PlayerBlocState state, double horizontalPadding) {
    final width = MediaQuery.of(context).size.width - horizontalPadding * 2;
    return SizedBox(
      height: 40,
      child: CustomPaint(
        painter: _WaveformPainter(progress: state.progress),
        size: Size(width, 40),
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context, PlayerBlocState state) {
    final progress = _isSeeking ? _seekValue : state.progress;
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
        activeTrackColor: AppColors.neonRed,
        inactiveTrackColor: AppColors.progressBackground,
        thumbColor: AppColors.neonRed,
        overlayColor: AppColors.neonRedGlow,
      ),
      child: Slider(
        value: progress.clamp(0.0, 1.0),
        onChangeStart: (_) => setState(() => _isSeeking = true),
        onChanged: (value) => setState(() => _seekValue = value),
        onChangeEnd: (value) {
          setState(() => _isSeeking = false);
          context.read<PlayerBloc>().add(SeekProgressEvent(value));
        },
      ),
    );
  }

  Widget _buildTimeRow(PlayerBlocState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            DurationFormatter.format(state.position),
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
          ),
          Text(
            DurationFormatter.format(state.duration),
            style: AppTextStyles.labelSmall,
          ),
        ],
      ),
    );
  }

  Widget _buildControls(BuildContext context, PlayerBlocState state, {bool isCompact = false}) {
    final mainSize = isCompact ? 64.0 : 72.0;
    final sideSize = isCompact ? 38.0 : 42.0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ModeButton(
          icon: Icons.shuffle_rounded,
          isActive: state.shuffleEnabled,
          onTap: () => context.read<PlayerBloc>().add(const ToggleShuffleEvent()),
        ),
        _ControlButton(
          icon: Icons.skip_previous_rounded,
          size: sideSize,
          onTap: () => context.read<PlayerBloc>().add(const SkipPreviousEvent()),
        ),
        GestureDetector(
          onTap: () => context.read<PlayerBloc>().add(const TogglePlayPauseEvent()),
          child: AnimatedContainer(
            duration: AppConstants.animFast,
            width: mainSize,
            height: mainSize,
            decoration: BoxDecoration(
              color: AppColors.neonRed,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.neonRed.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              state.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
              size: mainSize * 0.52,
            ),
          ),
        ),
        _ControlButton(
          icon: Icons.skip_next_rounded,
          size: sideSize,
          onTap: () => context.read<PlayerBloc>().add(const SkipNextEvent()),
        ),
        _RepeatButton(mode: state.repeatMode),
      ],
    );
  }

  Widget _buildErrorPlayer(BuildContext context, String error) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              leading: IconButton(
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 56,
                        color: AppColors.accent,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error al reproducir',
                        style: AppTextStyles.titleMedium
                            .copyWith(color: AppColors.accent),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error,
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingPlayer(BuildContext context, PlayerBlocState state) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context, state),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ArtworkWidget(song: state.currentSong!, size: 200, borderRadius: 16),
                    const SizedBox(height: 24),
                    Text(
                      state.currentSong!.title,
                      style: AppTextStyles.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.currentSong!.artist,
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 32),
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                      strokeWidth: 2,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Cargando...',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPlayer(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              leading: IconButton(
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.music_off_rounded,
                        size: 64,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Seleccioná una canción para reproducir',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size + 12,
        height: size + 12,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border, width: 1),
          borderRadius: BorderRadius.circular(14),
          color: AppColors.surfaceElevated,
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: size - 10),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _ModeButton({required this.icon, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(
        icon,
        color: isActive ? AppColors.neonRed : AppColors.textMuted,
        size: 24,
      ),
    );
  }
}

class _RepeatButton extends StatelessWidget {
  final RepeatMode mode;

  const _RepeatButton({required this.mode});

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    switch (mode) {
      case RepeatMode.none:
        icon = Icons.repeat_rounded;
        break;
      case RepeatMode.all:
        icon = Icons.repeat_rounded;
        break;
      case RepeatMode.one:
        icon = Icons.repeat_one_rounded;
        break;
    }
    return GestureDetector(
      onTap: () {
        final next = RepeatMode.values[(mode.index + 1) % RepeatMode.values.length];
        context.read<PlayerBloc>().add(SetRepeatModeEvent(next));
      },
      child: Icon(
        icon,
        color: mode != RepeatMode.none ? AppColors.neonRed : AppColors.textMuted,
        size: 24,
      ),
    );
  }
}

// ── Waveform Painter ───────────────────────────────────────────────────────────

class _WaveformPainter extends CustomPainter {
  final double progress;

  _WaveformPainter({required this.progress});

  static const List<double> _heights = [
    0.3, 0.6, 0.4, 0.8, 0.5, 0.9, 0.4, 0.7, 0.3, 0.6,
    0.8, 0.4, 0.7, 0.5, 0.9, 0.3, 0.6, 0.8, 0.4, 0.7,
    0.5, 0.3, 0.6, 0.9, 0.4, 0.7, 0.5, 0.8, 0.3, 0.6,
    0.9, 0.4, 0.7, 0.5, 0.3, 0.8, 0.6, 0.4, 0.7, 0.5,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = size.width / (_heights.length * 1.5);
    final spacing = barWidth * 0.5;
    final progressX = size.width * progress;

    for (int i = 0; i < _heights.length; i++) {
      final x = i * (barWidth + spacing);
      final barHeight = size.height * _heights[i];
      final top = (size.height - barHeight) / 2;
      final isActive = x < progressX;

      final paint = Paint()
        ..color = isActive
            ? AppColors.neonRed
            : AppColors.textMuted.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, top, barWidth, barHeight),
          const Radius.circular(2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
