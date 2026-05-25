import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/navigation/view_name.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/song_model.dart';
import '../../bloc/library/library_bloc.dart';
import '../../bloc/player/player_bloc.dart';
import '../../utils/player_navigation.dart';
import '../../widgets/album_card.dart';
import '../../widgets/artwork_widget.dart';
import '../../widgets/favorite_button.dart';

String _greeting() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Buenos días';
  if (h < 19) return 'Buenas tardes';
  return 'Buenas noches';
}

const _libraryLinks = [
  (ViewName.artists, 'Artistas', Icons.person_rounded),
  (ViewName.albums, 'Álbumes', Icons.album_rounded),
  (ViewName.genres, 'Géneros', Icons.music_note_rounded),
  (ViewName.songs, 'Canciones', Icons.music_note_rounded),
];

class HomeScreen extends StatefulWidget {
  final ValueChanged<ViewName>? onNavigate;

  const HomeScreen({super.key, this.onNavigate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _clearStep = 0;

  Future<void> _pickFolder() async {
    final path = await FilePicker.platform.getDirectoryPath();
    if (path != null && mounted) {
      context.read<LibraryBloc>().add(ScanFolderEvent(path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildHeader(),
                _buildScanSection(),
                _buildActivitySection(),
                _buildLibraryLinks(),
                _buildRecentlyAdded(),
                _buildAlbumPreview(),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
            if (_clearStep > 0) _buildClearDialogs(),
          ],
        ),
      ),
    );
  }

  Widget _buildClearDialogs() {
    return BlocBuilder<LibraryBloc, LibraryBlocState>(
      builder: (context, state) {
        if (_clearStep == 1) {
          return _ConfirmOverlay(
            title: 'Limpiar biblioteca',
            message: '¿Estás seguro de que quieres eliminar todas las ${state.songs.length} canciones de tu biblioteca?',
            confirmLabel: 'Continuar',
            onConfirm: () => setState(() => _clearStep = 2),
            onCancel: () => setState(() => _clearStep = 0),
          );
        }
        if (_clearStep == 2) {
          return _ConfirmOverlay(
            title: 'Confirmación final',
            message: 'Esta acción borrará toda tu biblioteca de forma permanente y no se puede deshacer. ¿Deseas continuar?',
            confirmLabel: 'Sí, limpiar todo',
            isDestructive: true,
            onConfirm: () {
              context.read<PlayerBloc>().add(const StopPlaybackEvent());
              context.read<LibraryBloc>().add(const ClearLibraryEvent());
              setState(() => _clearStep = 0);
            },
            onCancel: () => setState(() => _clearStep = 0),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: BlocBuilder<LibraryBloc, LibraryBlocState>(
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _greeting(),
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppConstants.appName,
                        style: AppTextStyles.displayMedium.copyWith(
                          color: AppColors.accent,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        state.songs.isNotEmpty
                            ? '${state.songs.length} canciones · ${state.albums.length} álbumes'
                            : 'Tu biblioteca de música local',
                        style: AppTextStyles.bodyMedium.copyWith(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                  tooltip: 'Buscar',
                  onPressed: () => widget.onNavigate?.call(ViewName.search),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActivitySection() {
    return SliverToBoxAdapter(
      child: BlocBuilder<LibraryBloc, LibraryBlocState>(
        builder: (context, state) {
          final hasActivity = state.favorites.isNotEmpty ||
              state.mostPlayedThisMonth.isNotEmpty ||
              state.recentlyPlayed.isNotEmpty;
          if (!hasActivity) return const SizedBox.shrink();

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tu actividad', style: AppTextStyles.headlineMedium),
                const SizedBox(height: 12),
                if (state.favorites.isNotEmpty) _buildFavoritesContent(state),
                if (state.mostPlayedThisMonth.isNotEmpty) _buildMostPlayedContent(state),
                if (state.recentlyPlayed.isNotEmpty) _buildRecentlyPlayedContent(state),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLibraryLinks() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Biblioteca', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _libraryLinks.map((link) {
                return ActionChip(
                  avatar: Icon(link.$3, size: 18, color: AppColors.neonRed),
                  label: Text(link.$2),
                  backgroundColor: AppColors.surfaceCard,
                  side: const BorderSide(color: AppColors.border),
                  labelStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                  onPressed: () => widget.onNavigate?.call(link.$1),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentlyAdded() {
    return BlocBuilder<LibraryBloc, LibraryBlocState>(
      builder: (context, state) {
        if (state.recentlyAdded.isEmpty) return const SliverToBoxAdapter();
        final preview = state.recentlyAdded.take(6).toList();
        return SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: Text('Recién añadidas', style: AppTextStyles.headlineMedium),
              ),
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: preview.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final song = preview[index];
                    return GestureDetector(
                      onTap: () => _playSong(context, song, preview, index),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              ArtworkWidget(song: song, size: 80, borderRadius: 10),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: FavoriteButton(song: song, size: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: 80,
                            child: Text(
                              song.title,
                              style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScanSection() {
    return BlocBuilder<LibraryBloc, LibraryBlocState>(
      builder: (context, state) {
        final isScanning = state.status == LibraryStatus.scanning;
        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ElevatedButton.icon(
                      onPressed: isScanning ? null : () => context.read<LibraryBloc>().add(const ScanLibraryEvent()),
                      icon: const Icon(Icons.library_music_rounded, size: 18),
                      label: Text(isScanning ? 'Escaneando...' : 'Escanear biblioteca'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: isScanning ? null : _pickFolder,
                      icon: const Icon(Icons.folder_rounded, size: 18),
                      label: const Text('Elegir carpeta'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.borderSubtle),
                        foregroundColor: AppColors.textPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    if (state.songs.isNotEmpty)
                      OutlinedButton.icon(
                        onPressed: isScanning ? null : () => setState(() => _clearStep = 1),
                        icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                        label: const Text('Limpiar biblioteca'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.borderSubtle),
                          foregroundColor: AppColors.textSecondary,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                  ],
                ),
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    state.errorMessage!,
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.accent, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  'Escanea todo el dispositivo o elige una carpeta específica con tu música.',
                  style: AppTextStyles.bodyMedium.copyWith(fontSize: 12, color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMostPlayedContent(LibraryBlocState state) {
    final items = state.mostPlayedThisMonth.take(4).toList();
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isNarrow = width < 400;
        final tileWidth = isNarrow ? (width - 12) / 2 : (width - 12) / 2;
        final tileHeight = tileWidth + 52;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.trending_up_rounded, color: AppColors.neonRed, size: 20),
                  const SizedBox(width: 8),
                  Text('Lo más escuchado del mes', style: AppTextStyles.titleMedium.copyWith(fontSize: 16)),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: List.generate(items.length, (index) {
                  final song = items[index];
                  return SizedBox(
                    width: tileWidth,
                    height: tileHeight,
                    child: _MostPlayedTile(
                      rank: index + 1,
                      song: song,
                      playCount: song.playCount,
                      onTap: () => _playSong(context, song, items, index),
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFavoritesContent(LibraryBlocState state) {
    final preview = state.favorites.take(6).toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.favorite_rounded, color: AppColors.neonRed, size: 20),
                  const SizedBox(width: 8),
                  Text('Favoritas', style: AppTextStyles.titleMedium.copyWith(fontSize: 16)),
                ],
              ),
              TextButton(
                onPressed: () => widget.onNavigate?.call(ViewName.favorites),
                child: Text('Ver todos', style: AppTextStyles.neonLabel),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 128,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: preview.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final song = preview[index];
                return _FavoritePreviewTile(
                  song: song,
                  onTap: () => _playSong(context, song, state.favorites, index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentlyPlayedContent(LibraryBlocState state) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recientes', style: AppTextStyles.titleMedium.copyWith(fontSize: 16)),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: state.recentlyPlayed.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final song = state.recentlyPlayed[index];
                return GestureDetector(
                  onTap: () => _playSong(context, song, state.recentlyPlayed, index),
                  child: Column(
                    children: [
                      ArtworkWidget(song: song, size: 80, borderRadius: 10),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: 80,
                        child: Text(
                          song.title,
                          style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumPreview() {
    return BlocBuilder<LibraryBloc, LibraryBlocState>(
      builder: (context, state) {
        if (state.albums.isEmpty) return const SliverToBoxAdapter();
        final previewAlbums = state.albums.take(6).toList();
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Álbumes destacados', style: AppTextStyles.headlineMedium),
                  TextButton(
                    onPressed: () => widget.onNavigate?.call(ViewName.albums),
                    child: Text('Ver todos', style: AppTextStyles.neonLabel),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.82,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: previewAlbums.length,
                itemBuilder: (context, index) {
                  final album = previewAlbums[index];
                  final coverSongs = state.songs.where((s) => s.album == album);
                  final coverSong = coverSongs.isEmpty ? null : coverSongs.first;
                  return AlbumCard(
                    title: album,
                    subtitle: coverSongs.length == 1
                        ? coverSong!.artist
                        : '${coverSongs.length} canciones',
                    artwork: coverSong != null
                        ? ArtworkWidget(song: coverSong, size: double.infinity, borderRadius: 0)
                        : null,
                    onTap: () => widget.onNavigate?.call(ViewName.albums),
                  );
                },
              ),
            ]),
          ),
        );
      },
    );
  }

  void _playSong(BuildContext context, SongModel song, List<SongModel> songs, int index) {
    context.read<PlayerBloc>().add(PlaySongEvent(song, queue: songs, index: index));
    openFullPlayer(context);
  }
}

class _MostPlayedTile extends StatelessWidget {
  final int rank;
  final SongModel song;
  final int playCount;
  final VoidCallback onTap;

  const _MostPlayedTile({
    required this.rank,
    required this.song,
    required this.playCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ArtworkWidget(
                    key: ValueKey('top-artwork-${song.id}'),
                    song: song,
                    size: double.infinity,
                    borderRadius: 0,
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.neonRed,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$rank',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  if (playCount > 0)
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${playCount}x',
                          style: AppTextStyles.labelSmall.copyWith(fontSize: 9),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    style: AppTextStyles.titleMedium.copyWith(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    song.artist,
                    style: AppTextStyles.bodyMedium.copyWith(fontSize: 11),
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

class _FavoritePreviewTile extends StatelessWidget {
  final SongModel song;
  final VoidCallback onTap;

  const _FavoritePreviewTile({required this.song, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 88,
        child: Column(
          children: [
            Stack(
              children: [
                ArtworkWidget(song: song, size: 80, borderRadius: 10),
                Positioned(
                  top: 4,
                  right: 4,
                  child: Icon(
                    Icons.favorite_rounded,
                    color: AppColors.neonRed,
                    size: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              song.title,
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmOverlay extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final bool isDestructive;

  const _ConfirmOverlay({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.onConfirm,
    required this.onCancel,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.titleMedium.copyWith(fontSize: 18)),
              const SizedBox(height: 12),
              Text(message, style: AppTextStyles.bodyMedium),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: onCancel, child: const Text('Cancelar')),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDestructive ? AppColors.accent : AppColors.surfaceElevated,
                      foregroundColor: isDestructive ? Colors.white : AppColors.textPrimary,
                    ),
                    child: Text(confirmLabel),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
