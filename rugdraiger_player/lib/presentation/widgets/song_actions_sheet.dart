import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/song_model.dart';
import '../bloc/library/library_bloc.dart';
import '../bloc/player/player_bloc.dart' hide ToggleFavoriteEvent;
import 'metadata_editor_sheet.dart';

Future<void> showSongActionsSheet(
  BuildContext context, {
  required SongModel song,
  int? playlistId,
}) async {
  final rootContext = context;
  final libraryBloc = context.read<LibraryBloc>();
  final playerBloc = context.read<PlayerBloc>();

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface2,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: libraryBloc),
        BlocProvider.value(value: playerBloc),
      ],
      child: _SongActionsSheet(
        song: song,
        playlistId: playlistId,
        rootContext: rootContext,
      ),
    ),
  );
}

class _SongActionsSheet extends StatelessWidget {
  final SongModel song;
  final int? playlistId;
  final BuildContext rootContext;

  const _SongActionsSheet({
    required this.song,
    required this.playlistId,
    required this.rootContext,
  });

  Future<void> _confirmDelete(BuildContext sheetContext) async {
    final libraryBloc = sheetContext.read<LibraryBloc>();
    final playerBloc = sheetContext.read<PlayerBloc>();
    Navigator.pop(sheetContext);

    final ok = await showDialog<bool>(
      context: rootContext,
      builder: (dCtx) => AlertDialog(
        backgroundColor: AppColors.surface2,
        title: const Text('Eliminar canción'),
        content: Text('¿Eliminar "${song.title}" de la biblioteca?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(dCtx, true),
            child: const Text('Eliminar', style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );

    if (ok != true) return;

    if (playerBloc.state.currentSong?.id == song.id) {
      playerBloc.add(const StopPlaybackEvent());
    }
    libraryBloc.add(DeleteSongEvent(song.id));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryBloc, LibraryBlocState>(
      builder: (context, state) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.borderSubtle,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Text(
                    song.title,
                    style: AppTextStyles.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Divider(color: AppColors.borderSubtle),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  child: Text(
                    'Agregar a playlist',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (state.playlists.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text('Sin playlists', style: AppTextStyles.bodyMedium),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 160),
                    child: ListView(
                      shrinkWrap: true,
                      children: state.playlists.map((pl) {
                        return ListTile(
                          dense: true,
                          title: Text(pl.name, style: AppTextStyles.bodyLarge),
                          onTap: () {
                            context.read<LibraryBloc>().add(
                              AddSongToPlaylistEvent(pl.id, song.id),
                            );
                            Navigator.pop(context);
                          },
                        );
                      }).toList(),
                    ),
                  ),
                const Divider(color: AppColors.borderSubtle),
                ListTile(
                  leading: Icon(
                    state.isFavorite(song.id) ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: state.isFavorite(song.id) ? AppColors.neonRed : AppColors.textSecondary,
                  ),
                  title: Text(
                    state.isFavorite(song.id) ? 'Quitar de favoritos' : 'Agregar a favoritos',
                    style: TextStyle(
                      color: state.isFavorite(song.id) ? AppColors.neonRed : AppColors.textPrimary,
                    ),
                  ),
                  onTap: () {
                    context.read<LibraryBloc>().add(ToggleFavoriteEvent(song.id));
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.edit_rounded, color: AppColors.textSecondary),
                  title: const Text('Editar metadatos', style: AppTextStyles.bodyLarge),
                  onTap: () {
                    Navigator.pop(context);
                    showMetadataEditorSheet(rootContext, song: song);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.queue_music_rounded, color: AppColors.textSecondary),
                  title: const Text('Agregar a la cola', style: AppTextStyles.bodyLarge),
                  onTap: () {
                    context.read<PlayerBloc>().add(AddToQueueEvent(song));
                    Navigator.pop(context);
                  },
                ),
                if (playlistId != null)
                  ListTile(
                    leading: const Icon(Icons.playlist_remove_rounded, color: AppColors.textSecondary),
                    title: const Text('Quitar de playlist', style: AppTextStyles.bodyLarge),
                    onTap: () {
                      context.read<LibraryBloc>().add(
                        RemoveSongFromPlaylistEvent(playlistId!, song.id),
                      );
                      Navigator.pop(context);
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: AppColors.accent),
                  title: const Text('Eliminar canción', style: TextStyle(color: AppColors.accent)),
                  onTap: () => _confirmDelete(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
