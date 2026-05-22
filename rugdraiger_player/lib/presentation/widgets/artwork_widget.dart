import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart' show QueryArtworkWidget, ArtworkType;
import '../../core/theme/app_colors.dart';
import '../../data/models/song_model.dart';

class ArtworkWidget extends StatelessWidget {
  final SongModel song;
  final double size;
  final double borderRadius;
  final bool showGlow;

  const ArtworkWidget({
    super.key,
    required this.song,
    this.size = 56,
    this.borderRadius = 8,
    this.showGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: AppColors.neonRed.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: song.artwork != null
            ? Image.memory(
                song.artwork!,
                fit: BoxFit.cover,
                width: size,
                height: size,
              )
            : QueryArtworkWidget(
                id: song.id,
                type: ArtworkType.AUDIO,
                artworkWidth: size,
                artworkHeight: size,
                artworkFit: BoxFit.cover,
                artworkBorder: BorderRadius.circular(borderRadius),
                nullArtworkWidget: _PlaceholderArtwork(size: size, radius: borderRadius),
                keepOldArtwork: true,
              ),
      ),
    );
  }
}

class _PlaceholderArtwork extends StatelessWidget {
  final double size;
  final double radius;

  const _PlaceholderArtwork({required this.size, required this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Icon(
        Icons.music_note_rounded,
        color: AppColors.neonRed.withValues(alpha: 0.6),
        size: size * 0.4,
      ),
    );
  }
}

class LargeArtworkWidget extends StatelessWidget {
  final SongModel song;
  final double size;

  const LargeArtworkWidget({
    super.key,
    required this.song,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppColors.neonRed.withValues(alpha: 0.15),
            blurRadius: 40,
            spreadRadius: -5,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: song.artwork != null
            ? Image.memory(
                song.artwork!,
                fit: BoxFit.cover,
                width: size,
                height: size,
              )
            : QueryArtworkWidget(
                id: song.id,
                type: ArtworkType.AUDIO,
                artworkWidth: size,
                artworkHeight: size,
                artworkFit: BoxFit.cover,
                artworkBorder: BorderRadius.circular(16),
                nullArtworkWidget: _LargePlaceholder(size: size),
                keepOldArtwork: true,
              ),
      ),
    );
  }
}

class _LargePlaceholder extends StatelessWidget {
  final double size;

  const _LargePlaceholder({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceCard,
            AppColors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        Icons.music_note_rounded,
        color: AppColors.neonRed.withValues(alpha: 0.4),
        size: size * 0.35,
      ),
    );
  }
}
