import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/song_model.dart';
import '../../services/artwork_cache.dart';
import '../../services/artwork_refresh.dart';

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
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    ArtworkRefresh.notifier.addListener(_onGlobalArtworkRefresh);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadArtwork());
  }

  @override
  void dispose() {
    ArtworkRefresh.notifier.removeListener(_onGlobalArtworkRefresh);
    super.dispose();
  }

  void _onGlobalArtworkRefresh() {
    if (!mounted) return;
    _loadArtwork();
  }

  @override
  void didUpdateWidget(ArtworkWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.song.id != widget.song.id ||
        oldWidget.song.filePath != widget.song.filePath) {
      _loadArtwork();
    }
  }

  Future<void> _loadArtwork({bool forceRemote = false}) async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _failed = false;
      if (!forceRemote) _artwork = null;
    });

    if (!forceRemote) {
      final cached = ArtworkCache.get(widget.song.id) ?? widget.song.artwork;
      if (cached != null && cached.isNotEmpty) {
        if (mounted) {
          setState(() {
            _artwork = cached;
            _loading = false;
          });
        }
        return;
      }
    }

    final loaded = await ArtworkCache.loadForSong(widget.song);
    if (!mounted) return;

    setState(() {
      _artwork = loaded;
      _loading = false;
      _failed = loaded == null;
    });
  }

  void _handleImageError() {
    if (_failed) return;
    setState(() => _failed = true);
    _loadArtwork(forceRemote: true);
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
        child: _artwork != null && !_failed
            ? Image.memory(
                _artwork!,
                fit: BoxFit.cover,
                width: widget.size,
                height: widget.size,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) {
                  _handleImageError();
                  return _PlaceholderArtwork(
                    size: widget.size,
                    radius: widget.borderRadius,
                    loading: _loading,
                  );
                },
              )
            : _PlaceholderArtwork(
                size: widget.size,
                radius: widget.borderRadius,
                loading: _loading,
              ),
      ),
    );
  }
}

class _PlaceholderArtwork extends StatelessWidget {
  final double size;
  final double radius;
  final bool loading;

  const _PlaceholderArtwork({
    required this.size,
    required this.radius,
    this.loading = false,
  });

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
      child: loading
          ? Padding(
              padding: EdgeInsets.all(size * 0.28),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.neonRed.withValues(alpha: 0.7),
              ),
            )
          : Icon(
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
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    ArtworkRefresh.notifier.addListener(_onGlobalArtworkRefresh);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadArtwork());
  }

  @override
  void dispose() {
    ArtworkRefresh.notifier.removeListener(_onGlobalArtworkRefresh);
    super.dispose();
  }

  void _onGlobalArtworkRefresh() {
    if (!mounted) return;
    _loadArtwork();
  }

  @override
  void didUpdateWidget(LargeArtworkWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.song.id != widget.song.id ||
        oldWidget.song.filePath != widget.song.filePath) {
      _loadArtwork();
    }
  }

  Future<void> _loadArtwork({bool forceRemote = false}) async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _failed = false;
      if (!forceRemote) _artwork = null;
    });

    if (!forceRemote) {
      final cached = ArtworkCache.get(widget.song.id) ?? widget.song.artwork;
      if (cached != null && cached.isNotEmpty) {
        if (mounted) {
          setState(() {
            _artwork = cached;
            _loading = false;
          });
        }
        return;
      }
    }

    final loaded = await ArtworkCache.loadForSong(widget.song);
    if (!mounted) return;

    setState(() {
      _artwork = loaded;
      _loading = false;
      _failed = loaded == null;
    });
  }

  void _handleImageError() {
    if (_failed) return;
    setState(() => _failed = true);
    _loadArtwork(forceRemote: true);
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
        child: _artwork != null && !_failed
            ? Image.memory(
                _artwork!,
                fit: BoxFit.cover,
                width: widget.size,
                height: widget.size,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) {
                  _handleImageError();
                  return _LargePlaceholder(size: widget.size, loading: _loading);
                },
              )
            : _LargePlaceholder(size: widget.size, loading: _loading),
      ),
    );
  }
}

class _LargePlaceholder extends StatelessWidget {
  final double size;
  final bool loading;

  const _LargePlaceholder({required this.size, this.loading = false});

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
      child: loading
          ? Center(
              child: SizedBox(
                width: size * 0.12,
                height: size * 0.12,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.neonRed.withValues(alpha: 0.7),
                ),
              ),
            )
          : Icon(
              Icons.music_note_rounded,
              color: AppColors.neonRed.withValues(alpha: 0.4),
              size: size * 0.35,
            ),
    );
  }
}
