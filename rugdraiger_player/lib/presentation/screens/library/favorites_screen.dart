import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../bloc/library/library_bloc.dart';
import '../../bloc/player/player_bloc.dart';
import '../../utils/player_navigation.dart';
import '../../widgets/album_card.dart';
import '../../widgets/artwork_widget.dart';
import '../../widgets/song_actions_sheet.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryBloc, LibraryBlocState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Me gusta', style: AppTextStyles.displayMedium.copyWith(fontSize: 22)),
                  const SizedBox(height: 4),
                  Text(
                    '${state.favorites.length} canciones',
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            ),
            Expanded(
              child: state.favorites.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.favorite_border_rounded,
                              size: 48,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Marcá canciones con el corazón\nen el reproductor',
                              style: AppTextStyles.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : BlocBuilder<PlayerBloc, PlayerBlocState>(
                      builder: (context, playerState) {
                        return ListView.builder(
                          itemCount: state.favorites.length,
                          itemBuilder: (context, index) {
                            final song = state.favorites[index];
                            final isPlaying = playerState.currentSong?.id == song.id;
                            return SongListTile(
                              title: song.title,
                              artist: song.artist,
                              duration: DurationFormatter.formatMs(song.durationMs),
                              qualityBadge: song.format.name.toUpperCase(),
                              isPlaying: isPlaying,
                              leading: ArtworkWidget(
                                key: ValueKey('fav-artwork-${song.id}'),
                                song: song,
                                size: 46,
                                borderRadius: 6,
                              ),
                              onTap: () {
                                context.read<PlayerBloc>().add(
                                  PlaySongEvent(
                                    song,
                                    queue: state.favorites,
                                    index: index,
                                  ),
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
