import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/song_model.dart';
import '../../bloc/library/library_bloc.dart';
import '../../bloc/player/player_bloc.dart';
import '../../utils/player_navigation.dart';
import '../../widgets/album_card.dart';
import '../../widgets/artwork_widget.dart';
import '../../widgets/playing_track_row.dart';
import '../../widgets/song_actions_sheet.dart';

class AlbumsScreen extends StatefulWidget {
  const AlbumsScreen({super.key});

  @override
  State<AlbumsScreen> createState() => _AlbumsScreenState();
}

class _AlbumsScreenState extends State<AlbumsScreen> {
  String? _selectedAlbum;
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryBloc, LibraryBlocState>(
      builder: (context, state) {
        if (_selectedAlbum != null) {
          return _AlbumDetail(
            album: _selectedAlbum!,
            songs: state.songs.where((s) => s.album == _selectedAlbum).toList(),
            onBack: () => setState(() => _selectedAlbum = null),
          );
        }

        final filtered = state.albums
            .where((a) => _search.isEmpty || a.toLowerCase().contains(_search.toLowerCase()))
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Álbumes', style: AppTextStyles.displayMedium.copyWith(fontSize: 22)),
                  const SizedBox(height: 12),
                  TextField(
                    onChanged: (v) => setState(() => _search = v),
                    style: AppTextStyles.bodyLarge,
                    decoration: InputDecoration(
                      hintText: 'Buscar álbumes...',
                      filled: true,
                      fillColor: AppColors.surfaceElevated,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.borderSubtle),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.borderSubtle),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('No hay álbumes', style: AppTextStyles.bodyMedium))
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.82,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final album = filtered[index];
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
                          onTap: () => setState(() => _selectedAlbum = album),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _AlbumDetail extends StatelessWidget {
  final String album;
  final List<SongModel> songs;
  final VoidCallback onBack;

  const _AlbumDetail({
    required this.album,
    required this.songs,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final cover = songs.isNotEmpty ? songs.first : null;
    final artist = cover?.artist ?? '';

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textSecondary),
                  ),
                  const Text('Álbumes', style: AppTextStyles.bodyMedium),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      if (cover != null)
                        ArtworkWidget(song: cover, size: 140, borderRadius: 12)
                      else
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.album_rounded, color: AppColors.accent, size: 48),
                        ),
                      if (cover != null)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Material(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(6),
                            child: InkWell(
                              onTap: () => showSongActionsSheet(context, song: cover),
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(Icons.more_vert, color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(album, style: AppTextStyles.displayMedium.copyWith(fontSize: 22)),
                        const SizedBox(height: 4),
                        Text(artist, style: AppTextStyles.bodyLarge),
                        const SizedBox(height: 8),
                        Text('${songs.length} canciones', style: AppTextStyles.bodyMedium),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: songs.isEmpty
                              ? null
                              : () {
                                  context.read<PlayerBloc>().add(PlaySongEvent(songs.first, queue: songs, index: 0));
                                  openFullPlayer(context);
                                },
                          icon: const Icon(Icons.play_arrow_rounded, size: 18),
                          label: const Text('Reproducir álbum'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ...songs.asMap().entries.map((entry) {
                final i = entry.key;
                final song = entry.value;
                return PlayingTrackRow(
                  song: song,
                  index: i,
                  queue: songs,
                  onTap: () {
                    context.read<PlayerBloc>().add(PlaySongEvent(song, queue: songs, index: i));
                    openFullPlayer(context);
                  },
                  trailing: IconButton(
                    icon: Icon(Icons.more_vert_rounded, color: AppColors.textTertiary, size: 20),
                    onPressed: () => showSongActionsSheet(context, song: song),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}
