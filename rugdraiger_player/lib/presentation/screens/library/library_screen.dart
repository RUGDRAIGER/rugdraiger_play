import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../bloc/library/library_bloc.dart';
import '../../bloc/player/player_bloc.dart';
import '../../widgets/album_card.dart';
import '../../widgets/artwork_widget.dart';
import '../player/player_screen.dart';

enum LibraryTab { songs, albums, artists, playlists }

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _SongsTab(),
                  _AlbumsTab(),
                  _ArtistsTab(),
                  _PlaylistsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Your Library', style: AppTextStyles.displayMedium),
          IconButton(
            icon: const Icon(Icons.sort_rounded, color: AppColors.textSecondary),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicator: BoxDecoration(
          color: AppColors.neonRed,
          borderRadius: BorderRadius.circular(20),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: AppTextStyles.labelLarge.copyWith(fontSize: 11),
        unselectedLabelStyle: AppTextStyles.labelLarge.copyWith(
          fontSize: 11,
          color: AppColors.textMuted,
        ),
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textMuted,
        labelPadding: const EdgeInsets.symmetric(horizontal: 16),
        tabs: const [
          Tab(text: 'SONGS'),
          Tab(text: 'ALBUMS'),
          Tab(text: 'ARTISTS'),
          Tab(text: 'PLAYLISTS'),
        ],
      ),
    );
  }
}

class _SongsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryBloc, LibraryBlocState>(
      builder: (context, state) {
        if (state.songs.isEmpty) {
          return const Center(
            child: Text('No songs found', style: AppTextStyles.bodyMedium),
          );
        }

        final playerState = context.watch<PlayerBloc>().state;

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 16),
          itemCount: state.songs.length,
          itemBuilder: (context, index) {
            final song = state.songs[index];
            final isPlaying = playerState.currentSong?.id == song.id;

            return SongListTile(
              title: song.title,
              artist: song.artist,
              duration: DurationFormatter.formatMs(song.durationMs),
              qualityBadge: song.isLossless ? song.format.name.toUpperCase() : null,
              isPlaying: isPlaying,
              leading: ArtworkWidget(song: song, size: 46, borderRadius: 6),
              onTap: () {
                context.read<PlayerBloc>().add(
                  PlaySongEvent(song, queue: state.songs, index: index),
                );
                Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (_, animation, __) => const PlayerScreen(),
                    transitionsBuilder: (_, animation, __, child) => SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 1),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                      child: child,
                    ),
                  ),
                );
              },
              onMoreTap: () => _showSongOptions(context, song),
            );
          },
        );
      },
    );
  }

  void _showSongOptions(BuildContext context, song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceModal,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<LibraryBloc>(),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: ArtworkWidget(song: song, size: 50, borderRadius: 8),
                title: Text(song.title, style: AppTextStyles.titleMedium),
                subtitle: Text(song.artist, style: AppTextStyles.bodyMedium),
              ),
              const Divider(color: AppColors.divider),
              ListTile(
                leading: const Icon(Icons.playlist_add_rounded, color: AppColors.textSecondary),
                title: const Text('Add to playlist', style: AppTextStyles.bodyLarge),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.favorite_border_rounded, color: AppColors.textSecondary),
                title: const Text('Add to favorites', style: AppTextStyles.bodyLarge),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline_rounded, color: AppColors.textSecondary),
                title: const Text('Song details', style: AppTextStyles.bodyLarge),
                onTap: () {
                  Navigator.pop(context);
                  _showSongDetails(context, song);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSongDetails(BuildContext context, song) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceModal,
        title: Text(song.title, style: AppTextStyles.titleLarge),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRow('Artist', song.artist),
            _DetailRow('Album', song.album),
            _DetailRow('Format', song.format.name.toUpperCase()),
            if (song.bitrate > 0) _DetailRow('Bitrate', song.formattedBitrate),
            if (song.sampleRate > 0) _DetailRow('Sample Rate', song.formattedSampleRate),
            if (song.year > 0) _DetailRow('Year', '${song.year}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: AppColors.neonRed)),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: AppTextStyles.bodyMedium),
          ),
          Expanded(
            child: Text(value, style: AppTextStyles.bodyLarge),
          ),
        ],
      ),
    );
  }
}

class _AlbumsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryBloc, LibraryBlocState>(
      builder: (context, state) {
        if (state.albums.isEmpty) {
          return const Center(
            child: Text('No albums found', style: AppTextStyles.bodyMedium),
          );
        }

        return GridView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.8,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: state.albums.length,
          itemBuilder: (context, index) {
            final album = state.albums[index];
            return AlbumCard(
              title: album,
              subtitle: '',
              onTap: () {},
            );
          },
        );
      },
    );
  }
}

class _ArtistsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryBloc, LibraryBlocState>(
      builder: (context, state) {
        if (state.artists.isEmpty) {
          return const Center(
            child: Text('No artists found', style: AppTextStyles.bodyMedium),
          );
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: state.artists.length,
          itemBuilder: (context, index) {
            final artist = state.artists[index];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: CircleAvatar(
                backgroundColor: AppColors.surfaceCard,
                radius: 24,
                child: const Icon(Icons.person_rounded, color: AppColors.neonRed, size: 24),
              ),
              title: Text(artist, style: AppTextStyles.titleMedium),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
              onTap: () {},
            );
          },
        );
      },
    );
  }
}

class _PlaylistsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryBloc, LibraryBlocState>(
      builder: (context, state) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: GestureDetector(
                onTap: () => _createPlaylist(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.neonRed.withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.neonRedSubtle,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_rounded, color: AppColors.neonRed),
                      const SizedBox(width: 8),
                      Text('NEW PLAYLIST', style: AppTextStyles.neonLabel),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: state.playlists.isEmpty
                  ? const Center(
                      child: Text('No playlists yet', style: AppTextStyles.bodyMedium),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: state.playlists.length,
                      itemBuilder: (context, index) {
                        final playlist = state.playlists[index];
                        return ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceCard,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Icon(
                              Icons.playlist_play_rounded,
                              color: AppColors.neonRed,
                            ),
                          ),
                          title: Text(playlist.name, style: AppTextStyles.titleMedium),
                          subtitle: Text(
                            '${playlist.songCount} songs',
                            style: AppTextStyles.bodyMedium,
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                          onTap: () {},
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
        backgroundColor: AppColors.surfaceModal,
        title: const Text('New Playlist', style: AppTextStyles.headlineMedium),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: AppTextStyles.bodyLarge,
          decoration: const InputDecoration(hintText: 'Playlist name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                context.read<LibraryBloc>().add(CreatePlaylistEvent(controller.text.trim()));
                Navigator.pop(dialogCtx);
              }
            },
            child: const Text('Create', style: TextStyle(color: AppColors.neonRed)),
          ),
        ],
      ),
    );
  }
}
