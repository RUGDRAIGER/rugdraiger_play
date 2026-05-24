import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../bloc/library/library_bloc.dart';
import '../../bloc/player/player_bloc.dart';
import '../../utils/player_navigation.dart';
import '../../widgets/album_card.dart';
import '../../widgets/artwork_widget.dart';
import '../../widgets/song_actions_sheet.dart';

class SongsScreen extends StatefulWidget {
  const SongsScreen({super.key});

  @override
  State<SongsScreen> createState() => _SongsScreenState();
}

class _SongsScreenState extends State<SongsScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryBloc, LibraryBlocState>(
      builder: (context, state) {
        final filtered = state.songs.where((s) {
          if (_search.isEmpty) return true;
          final q = _search.toLowerCase();
          return s.title.toLowerCase().contains(q) ||
              s.artist.toLowerCase().contains(q) ||
              s.album.toLowerCase().contains(q);
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Canciones', style: AppTextStyles.displayMedium.copyWith(fontSize: 22)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (v) => setState(() => _search = v),
                          decoration: const InputDecoration(
                            hintText: 'Buscar canciones...',
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: filtered.isEmpty
                            ? null
                            : () {
                                context.read<PlayerBloc>().add(
                                  PlaySongEvent(filtered.first, queue: filtered, index: 0),
                                );
                                openFullPlayer(context);
                              },
                        icon: const Icon(Icons.play_arrow_rounded, size: 16),
                        label: const Text('Reproducir'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('${filtered.length} canciones', style: AppTextStyles.bodyMedium),
                ],
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('No hay canciones', style: AppTextStyles.bodyMedium))
                  : BlocBuilder<PlayerBloc, PlayerBlocState>(
                      builder: (context, playerState) {
                        return ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final song = filtered[index];
                            final isPlaying = playerState.currentSong?.id == song.id;

                            return SongListTile(
                              title: song.title,
                              artist: song.artist,
                              duration: DurationFormatter.formatMs(song.durationMs),
                              qualityBadge: song.format.name.toUpperCase(),
                              isPlaying: isPlaying,
                              leading: ArtworkWidget(
                                key: ValueKey('artwork-${song.id}'),
                                song: song,
                                size: 46,
                                borderRadius: 6,
                              ),
                              onTap: () {
                                context.read<PlayerBloc>().add(
                                  PlaySongEvent(song, queue: filtered, index: index),
                                );
                                openFullPlayer(context);
                              },
                              onMoreTap: () => showSongActionsSheet(context, song: song),
                            );
                          },
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
