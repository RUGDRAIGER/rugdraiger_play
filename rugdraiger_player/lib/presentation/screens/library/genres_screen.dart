import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../../data/models/song_model.dart';
import '../../../data/repositories/music_repository.dart';
import '../../bloc/library/library_bloc.dart';
import '../../bloc/player/player_bloc.dart';
import '../../utils/player_navigation.dart';
import '../../widgets/artwork_widget.dart';
import '../../widgets/song_actions_sheet.dart';

class GenresScreen extends StatefulWidget {
  const GenresScreen({super.key});

  @override
  State<GenresScreen> createState() => _GenresScreenState();
}

class _GenresScreenState extends State<GenresScreen> {
  String? _selectedGenre;
  List<SongModel> _genreSongs = [];
  bool _loading = false;

  Future<void> _openGenre(String genre) async {
    setState(() {
      _selectedGenre = genre;
      _loading = true;
    });
    final songs = await MusicRepository().getSongsByGenre(genre);
    if (mounted) {
      setState(() {
        _genreSongs = songs;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryBloc, LibraryBlocState>(
      builder: (context, state) {
        if (_selectedGenre != null) {
          return _buildDetail(context);
        }
        return _buildList(state);
      },
    );
  }

  Widget _buildList(LibraryBlocState state) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text('Géneros', style: AppTextStyles.headlineMedium),
            ),
            Expanded(
              child: state.genres.isEmpty
                  ? Center(
                      child: Text(
                        'Sin géneros en la biblioteca',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: state.genres.length,
                      separatorBuilder: (_, __) => const Divider(color: AppColors.borderSubtle, height: 1),
                      itemBuilder: (context, index) {
                        final genre = state.genres[index];
                        final count = state.songs.where((s) => s.genre == genre).length;
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.music_note_rounded, color: AppColors.neonRed),
                          ),
                          title: Text(genre, style: AppTextStyles.bodyLarge),
                          subtitle: Text('$count canciones', style: AppTextStyles.bodyMedium),
                          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
                          onTap: () => _openGenre(genre),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetail(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => setState(() => _selectedGenre = null),
        ),
        title: Text(_selectedGenre ?? 'Género', style: AppTextStyles.titleMedium),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.accent))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _genreSongs.length,
              separatorBuilder: (_, __) => const Divider(color: AppColors.borderSubtle, height: 1),
              itemBuilder: (context, index) {
                final song = _genreSongs[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: ArtworkWidget(song: song, size: 48, borderRadius: 8),
                  title: Text(song.title, style: AppTextStyles.bodyLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    '${song.artist} · ${DurationFormatter.format(Duration(milliseconds: song.durationMs))}',
                    style: AppTextStyles.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    context.read<PlayerBloc>().add(
                      PlaySongEvent(song, queue: _genreSongs, index: index),
                    );
                    openFullPlayer(context);
                  },
                  trailing: IconButton(
                    icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
                    onPressed: () => showSongActionsSheet(context, song: song),
                  ),
                );
              },
            ),
    );
  }
}
