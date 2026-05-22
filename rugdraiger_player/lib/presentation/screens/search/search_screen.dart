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

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(context),
            Expanded(
              child: BlocBuilder<LibraryBloc, LibraryBlocState>(
                builder: (context, state) {
                  if (state.searchQuery == null || state.searchQuery!.isEmpty) {
                    return _buildSearchHint();
                  }
                  if (state.searchResults.isEmpty) {
                    return _buildNoResults(state.searchQuery!);
                  }
                  return _buildResults(context, state);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        style: AppTextStyles.bodyLarge,
        onChanged: (query) {
          context.read<LibraryBloc>().add(SearchSongsEvent(query));
        },
        decoration: InputDecoration(
          hintText: 'Search songs, artists, albums...',
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, color: AppColors.textMuted),
                  onPressed: () {
                    _controller.clear();
                    context.read<LibraryBloc>().add(const ClearSearchEvent());
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildSearchHint() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_rounded, color: AppColors.textMuted.withValues(alpha: 0.4), size: 64),
          const SizedBox(height: 16),
          Text('Search your library', style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildNoResults(String query) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.music_off_rounded, color: AppColors.textMuted.withValues(alpha: 0.4), size: 64),
          const SizedBox(height: 16),
          Text('No results for "$query"', style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext context, LibraryBlocState state) {
    final playerState = context.watch<PlayerBloc>().state;

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: state.searchResults.length,
      itemBuilder: (context, index) {
        final song = state.searchResults[index];
        final isPlaying = playerState.currentSong?.id == song.id;

        return SongListTile(
          title: song.title,
          artist: song.artist,
          duration: DurationFormatter.formatMs(song.durationMs),
          isPlaying: isPlaying,
          leading: ArtworkWidget(song: song, size: 46, borderRadius: 6),
          onTap: () {
            context.read<PlayerBloc>().add(
              PlaySongEvent(song, queue: state.searchResults, index: index),
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
        );
      },
    );
  }
}
