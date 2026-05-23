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

class ArtistsScreen extends StatefulWidget {
  const ArtistsScreen({super.key});

  @override
  State<ArtistsScreen> createState() => _ArtistsScreenState();
}

class _ArtistsScreenState extends State<ArtistsScreen> {
  String? _selectedArtist;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryBloc, LibraryBlocState>(
      builder: (context, state) {
        if (_selectedArtist != null) {
          final artistSongs = state.songs.where((s) => s.artist == _selectedArtist).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailHeader(
                title: _selectedArtist!,
                subtitle: '${artistSongs.length} canciones',
                onBack: () => setState(() => _selectedArtist = null),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: artistSongs.length,
                  itemBuilder: (context, index) {
                    final song = artistSongs[index];
                    return SongListTile(
                      title: song.title,
                      artist: song.album,
                      duration: DurationFormatter.formatMs(song.durationMs),
                      leading: ArtworkWidget(song: song, size: 46, borderRadius: 6),
                      onTap: () {
                        context.read<PlayerBloc>().add(
                          PlaySongEvent(song, queue: artistSongs, index: index),
                        );
                        openFullPlayer(context);
                      },
                      onMoreTap: () => showSongActionsSheet(context, song: song),
                    );
                  },
                ),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Artistas', style: AppTextStyles.displayMedium.copyWith(fontSize: 22)),
                  const SizedBox(height: 4),
                  Text('${state.artists.length} artistas', style: AppTextStyles.bodyMedium),
                ],
              ),
            ),
            Expanded(
              child: state.artists.isEmpty
                  ? const Center(child: Text('No hay artistas', style: AppTextStyles.bodyMedium))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: state.artists.length,
                      itemBuilder: (context, index) {
                        final artist = state.artists[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.surfaceElevated,
                            radius: 24,
                            child: const Icon(Icons.person_rounded, color: AppColors.accent),
                          ),
                          title: Text(artist, style: AppTextStyles.titleMedium),
                          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
                          onTap: () => setState(() => _selectedArtist = artist),
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

class _DetailHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onBack;

  const _DetailHeader({
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textSecondary),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.headlineMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(subtitle, style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
