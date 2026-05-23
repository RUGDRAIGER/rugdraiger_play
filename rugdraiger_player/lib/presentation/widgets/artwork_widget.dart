import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart' show QueryArtworkWidget, ArtworkType;
import '../../core/theme/app_colors.dart';
import '../../data/models/song_model.dart';
import '../../services/artwork_cache.dart';

class ArtworkWidget extends StatefulWidget {
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
  State<ArtworkWidget> createState() => _ArtworkWidgetState();
}

class _ArtworkWidgetState extends State<ArtworkWidget> {
  Uint8List? _artwork;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadArtwork();
  }

  @override
  void didUpdateWidget(ArtworkWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.song.id != widget.song.id) {
      _loadArtwork();
    }
  }

  Future<void> _loadArtwork() async {
    setState(() {
      _loading = true;
      _artwork = null;
    });

    final cached = ArtworkCache.get(widget.song.id) ?? widget.song.artwork;
    if (cached != null) {
      if (mounted) setState(() { _artwork = cached; _loading = false; });
      return;
    }

    final loaded = await ArtworkCache.loadForSong(widget.song);
    if (mounted) {
      setState(() {
        _artwork = loaded;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        boxShadow: widget.showGlow
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
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: _artwork != null
            ? Image.memory(
                _artwork!,
                fit: BoxFit.cover,
                width: widget.size,
                height: widget.size,
                gaplessPlayback: true,
              )
            : _loading
                ? _PlaceholderArtwork(size: widget.size, radius: widget.borderRadius)
                : QueryArtworkWidget(
                    id: widget.song.id,
                    type: ArtworkType.AUDIO,
                    artworkWidth: widget.size,
                    artworkHeight: widget.size,
                    artworkFit: BoxFit.cover,
                    artworkBorder: BorderRadius.circular(widget.borderRadius),
                    nullArtworkWidget: _PlaceholderArtwork(size: widget.size, radius: widget.borderRadius),
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

class LargeArtworkWidget extends StatefulWidget {
  final SongModel song;
  final double size;

  const LargeArtworkWidget({
    super.key,
    required this.song,
    required this.size,
  });

  @override
  State<LargeArtworkWidget> createState() => _LargeArtworkWidgetState();
}

class _LargeArtworkWidgetState extends State<LargeArtworkWidget> {
  Uint8List? _artwork;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadArtwork();
  }

  @override
  void didUpdateWidget(LargeArtworkWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.song.id != widget.song.id) {
      _loadArtwork();
    }
  }

  Future<void> _loadArtwork() async {
    setState(() { _loading = true; _artwork = null; });

    final cached = ArtworkCache.get(widget.song.id) ?? widget.song.artwork;
    if (cached != null) {
      if (mounted) setState(() { _artwork = cached; _loading = false; });
      return;
    }

    final loaded = await ArtworkCache.loadForSong(widget.song);
    if (mounted) setState(() { _artwork = loaded; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
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
        child: _artwork != null
            ? Image.memory(
                _artwork!,
                fit: BoxFit.cover,
                width: widget.size,
                height: widget.size,
                gaplessPlayback: true,
              )
            : _loading
                ? _LargePlaceholder(size: widget.size)
                : QueryArtworkWidget(
                    id: widget.song.id,
                    type: ArtworkType.AUDIO,
                    artworkWidth: widget.size,
                    artworkHeight: widget.size,
                    artworkFit: BoxFit.cover,
                    artworkBorder: BorderRadius.circular(16),
                    nullArtworkWidget: _LargePlaceholder(size: widget.size),
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
