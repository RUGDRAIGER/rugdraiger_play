import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/playlist_model.dart';
import '../../bloc/library/library_bloc.dart';
import '../../bloc/player/player_bloc.dart';
import '../../utils/player_navigation.dart';
import '../../widgets/playing_track_row.dart';
import '../../widgets/song_actions_sheet.dart';

class PlaylistsScreen extends StatefulWidget {
  const PlaylistsScreen({super.key});

  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> {
  PlaylistModel? _selectedPlaylist;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryBloc, LibraryBlocState>(
      builder: (context, state) {
        if (_selectedPlaylist != null) {
          final playlist = state.playlists.firstWhere(
            (p) => p.id == _selectedPlaylist!.id,
            orElse: () => _selectedPlaylist!,
          );
          final playlistSongs = state.songs
              .where((s) => playlist.songIds.contains(s.id))
              .toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailHeader(
                title: playlist.name,
                subtitle: '${playlistSongs.length} canciones',
                onBack: () => setState(() => _selectedPlaylist = null),
              ),
              Expanded(
                child: playlistSongs.isEmpty
                    ? const Center(
                        child: Text('Playlist vacía', style: AppTextStyles.bodyMedium),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: playlistSongs.length,
                        itemBuilder: (context, index) {
                          final song = playlistSongs[index];
                          return PlayingTrackRow(
                            song: song,
                            index: index,
                            queue: playlistSongs,
                            onTap: () {
                              context.read<PlayerBloc>().add(
                                PlaySongEvent(song, queue: playlistSongs, index: index),
                              );
                              openFullPlayer(context);
                            },
                            trailing: IconButton(
                              icon: Icon(Icons.more_vert_rounded, color: AppColors.textTertiary, size: 20),
                              onPressed: () => showSongActionsSheet(
                                context,
                                song: song,
                                playlistId: playlist.id,
                              ),
                            ),
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
                  Text('Playlists', style: AppTextStyles.displayMedium.copyWith(fontSize: 22)),
                  const SizedBox(height: 4),
                  Text('${state.playlists.length} listas', style: AppTextStyles.bodyMedium),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _createPlaylist(context),
                  icon: Icon(Icons.add_rounded, color: AppColors.accent),
                  label: Text('Nueva playlist', style: TextStyle(color: AppColors.accent)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.borderAccent),
                    backgroundColor: AppColors.accentSubtle,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
            Expanded(
              child: state.playlists.isEmpty
                  ? const Center(child: Text('No hay playlists', style: AppTextStyles.bodyMedium))
                  : ListView.builder(
                      itemCount: state.playlists.length,
                      itemBuilder: (context, index) {
                        final playlist = state.playlists[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.borderSubtle),
                            ),
                            child: Icon(Icons.queue_music_rounded, color: AppColors.accent),
                          ),
                          title: Text(playlist.name, style: AppTextStyles.titleMedium),
                          subtitle: Text(
                            '${playlist.songCount} canciones',
                            style: AppTextStyles.bodyMedium,
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
                          onTap: () => setState(() => _selectedPlaylist = playlist),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  void _createPlaylist(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface2,
        title: const Text('Nueva playlist', style: AppTextStyles.headlineMedium),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: AppTextStyles.bodyLarge,
          decoration: const InputDecoration(hintText: 'Nombre'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textTertiary)),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                context.read<LibraryBloc>().add(CreatePlaylistEvent(controller.text.trim()));
                Navigator.pop(dialogCtx);
              }
            },
            child: Text('Crear', style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
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
