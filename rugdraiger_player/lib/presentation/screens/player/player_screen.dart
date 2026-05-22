import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../bloc/player/player_bloc.dart';
import '../../widgets/artwork_widget.dart';

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
        if (!state.hasActiveSong) {
          return _buildEmptyPlayer(context);
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Container(
            decoration: const BoxDecoration(gradient: AppColors.playerGradient),
            child: SafeArea(
              child: Column(
                children: [
                  _buildTopBar(context),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            const SizedBox(height: 8),
                            _buildQualityBadge(state),
                            const SizedBox(height: 16),
                            _buildArtwork(state),
                            const SizedBox(height: 28),
                            _buildSongInfo(context, state),
                            const SizedBox(height: 24),
                            _buildWaveformProgress(state),
                            const SizedBox(height: 8),
                            _buildProgressBar(context, state),
                            const SizedBox(height: 4),
                            _buildTimeRow(state),
                            const SizedBox(height: 32),
                            _buildControls(context, state),
                            const SizedBox(height: 24),
                            _buildBottomActions(context, state),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 30),
            color: AppColors.textSecondary,
            onPressed: () => Navigator.of(context).pop(),
          ),
          Text(
            AppConstants.appName,
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.neonRed,
              letterSpacing: 3,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            color: AppColors.textSecondary,
            onPressed: () => _showSongOptions(context),
          ),
        ],
      ),
    );
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
          const Icon(Icons.hd_outlined, color: AppColors.neonRed, size: 14),
          const SizedBox(width: 6),
          Text(
            song.isLossless ? song.qualityBadge : song.formattedBitrate,
            style: AppTextStyles.neonLabel.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildArtwork(PlayerBlocState state) {
    final size = MediaQuery.of(context).size.width - 48;
    return Hero(
      tag: 'artwork-${state.currentSong!.id}',
      child: LargeArtworkWidget(
        song: state.currentSong!,
        size: size,
      ).animate(target: state.isPlaying ? 1.0 : 0.95).scale(
        begin: const Offset(0.95, 0.95),
        end: const Offset(1.0, 1.0),
        duration: 300.ms,
        curve: Curves.easeOut,
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
                maxLines: 1,
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
        GestureDetector(
          onTap: () => context.read<PlayerBloc>().add(ToggleFavoriteEvent(song.id)),
          child: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Icon(
              Icons.favorite_border_rounded,
              color: AppColors.textMuted,
              size: 26,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWaveformProgress(PlayerBlocState state) {
    return SizedBox(
      height: 40,
      child: CustomPaint(
        painter: _WaveformPainter(progress: state.progress),
        size: Size(MediaQuery.of(context).size.width - 48, 40),
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

  Widget _buildControls(BuildContext context, PlayerBlocState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Shuffle
        _ModeButton(
          icon: Icons.shuffle_rounded,
          isActive: state.shuffleEnabled,
          onTap: () => context.read<PlayerBloc>().add(const ToggleShuffleEvent()),
        ),

        // Previous
        _ControlButton(
          icon: Icons.skip_previous_rounded,
          size: 42,
          onTap: () => context.read<PlayerBloc>().add(const SkipPreviousEvent()),
        ),

        // Play/Pause — main button
        GestureDetector(
          onTap: () => context.read<PlayerBloc>().add(const TogglePlayPauseEvent()),
          child: AnimatedContainer(
            duration: AppConstants.animFast,
            width: 72,
            height: 72,
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
              size: 38,
            ),
          ),
        ),

        // Next
        _ControlButton(
          icon: Icons.skip_next_rounded,
          size: 42,
          onTap: () => context.read<PlayerBloc>().add(const SkipNextEvent()),
        ),

        // Repeat
        _RepeatButton(mode: state.repeatMode),
      ],
    );
  }

  Widget _buildBottomActions(BuildContext context, PlayerBlocState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _ActionButton(
          icon: Icons.favorite_border_rounded,
          label: 'LIKE',
          onTap: () {},
        ),
        _ActionButton(
          icon: Icons.lyrics_outlined,
          label: 'LYRICS',
          onTap: () {},
        ),
        _ActionButton(
          icon: Icons.queue_music_rounded,
          label: 'QUEUE',
          onTap: () => _showQueue(context, state),
        ),
        _ActionButton(
          icon: Icons.output_rounded,
          label: 'OUTPUT',
          onTap: () {},
        ),
      ],
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
            const Expanded(
              child: Center(
                child: Text('No song playing', style: AppTextStyles.headlineMedium),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSongOptions(BuildContext context) {
    final state = context.read<PlayerBloc>().state;
    final song = state.currentSong;
    if (song == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceModal,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
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
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.album_rounded, color: AppColors.textSecondary),
              title: Text(song.album, style: AppTextStyles.bodyLarge),
              subtitle: Text(song.artist, style: AppTextStyles.bodyMedium),
            ),
            const Divider(color: AppColors.divider),
            _OptionTile(icon: Icons.playlist_add_rounded, label: 'Add to playlist'),
            _OptionTile(icon: Icons.info_outline_rounded, label: 'Song info'),
            _OptionTile(icon: Icons.equalizer_rounded, label: 'Equalizer'),
          ],
        ),
      ),
    );
  }

  void _showQueue(BuildContext context, PlayerBlocState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceModal,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Text('Queue', style: AppTextStyles.headlineMedium),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: state.queue.length,
                  itemBuilder: (context, index) {
                    final song = state.queue[index];
                    final isCurrent = index == state.currentIndex;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Text(
                        '${index + 1}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isCurrent ? AppColors.neonRed : AppColors.textMuted,
                        ),
                      ),
                      title: Text(
                        song.title,
                        style: AppTextStyles.titleMedium.copyWith(
                          color: isCurrent ? AppColors.neonRed : AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(song.artist, style: AppTextStyles.bodyMedium),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Reusable Controls ──────────────────────────────────────────────────────────

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

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 22),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.labelSmall),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;

  const _OptionTile({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(label, style: AppTextStyles.bodyLarge),
      onTap: () => Navigator.pop(context),
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
