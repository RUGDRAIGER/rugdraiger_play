import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../bloc/library/library_bloc.dart';
import '../../bloc/player/player_bloc.dart';
import '../../widgets/album_card.dart';
import '../../widgets/artwork_widget.dart';
import '../player/player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<LibraryBloc>().add(const LoadLibraryEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(context),
            _buildRecentlyPlayed(context),
            _buildLibraryGrid(context),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 0,
      backgroundColor: AppColors.background,
      elevation: 0,
      title: Text(
        AppConstants.appName,
        style: AppTextStyles.displayMedium.copyWith(
          color: AppColors.neonRed,
          letterSpacing: 3,
          fontWeight: FontWeight.w700,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: AppColors.textSecondary),
          onPressed: () => _showSettings(context),
        ),
      ],
    );
  }

  Widget _buildRecentlyPlayed(BuildContext context) {
    return BlocBuilder<LibraryBloc, LibraryBlocState>(
      builder: (context, state) {
        if (state.recentlyPlayed.isEmpty) return const SliverToBoxAdapter();

        return SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Recently Played', style: AppTextStyles.headlineMedium),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'VIEW ALL',
                        style: AppTextStyles.neonLabel,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  physics: const BouncingScrollPhysics(),
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
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
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
          ).animate().fadeIn(delay: 100.ms),
        );
      },
    );
  }

  Widget _buildLibraryGrid(BuildContext context) {
    return BlocBuilder<LibraryBloc, LibraryBlocState>(
      builder: (context, state) {
        if (state.status == LibraryStatus.loading || state.status == LibraryStatus.scanning) {
          return SliverToBoxAdapter(
            child: _buildLoadingState(state.status == LibraryStatus.scanning),
          );
        }

        if (state.status == LibraryStatus.initial) {
          return SliverToBoxAdapter(child: _buildEmptyState(context));
        }

        if (state.songs.isEmpty) {
          return SliverToBoxAdapter(child: _buildEmptyState(context));
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Your Library', style: AppTextStyles.headlineMedium),
                  Row(
                    children: [
                      Text(
                        '${state.songs.length} songs',
                        style: AppTextStyles.bodyMedium,
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _showSortOptions(context),
                        child: const Icon(
                          Icons.sort_rounded,
                          color: AppColors.textSecondary,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: state.songs.length.clamp(0, 20),
                itemBuilder: (context, index) {
                  final song = state.songs[index];
                  return AlbumCard(
                    title: song.title,
                    subtitle: song.artist,
                    artwork: ArtworkWidget(
                      song: song,
                      size: double.infinity,
                      borderRadius: 0,
                    ),
                    onTap: () => _playSong(context, song, state.songs, index),
                  ).animate().fadeIn(delay: (index * 40).ms);
                },
              ),
            ]),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.neonRed, width: 2),
              color: AppColors.neonRedSubtle,
            ),
            child: const Icon(
              Icons.library_music_rounded,
              color: AppColors.neonRed,
              size: 46,
            ),
          ),
          const SizedBox(height: 24),
          Text('No Music Found', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Scan your device to find your music library',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          NeonButton(
            label: 'SCAN LIBRARY',
            icon: Icons.search_rounded,
            onTap: () => _scanLibrary(context),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(bool isScanning) {
    return Padding(
      padding: const EdgeInsets.all(60),
      child: Column(
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.neonRed),
            strokeWidth: 2,
          ),
          const SizedBox(height: 20),
          Text(
            isScanning ? 'Scanning your library...' : 'Loading...',
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }

  void _playSong(BuildContext context, song, songs, int index) {
    context.read<PlayerBloc>().add(PlaySongEvent(song, queue: songs, index: index));
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => const PlayerScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          );
        },
        transitionDuration: AppConstants.animNormal,
      ),
    );
  }

  void _scanLibrary(BuildContext context) {
    context.read<LibraryBloc>().add(const ScanLibraryEvent());
  }

  void _showSortOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceModal,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sort By', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 16),
            ...SortOrder.values.map((order) => ListTile(
              title: Text(_sortOrderLabel(order), style: AppTextStyles.bodyLarge),
              onTap: () {
                context.read<LibraryBloc>().add(SetSortOrderEvent(order));
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  String _sortOrderLabel(SortOrder order) {
    switch (order) {
      case SortOrder.titleAsc: return 'Title (A–Z)';
      case SortOrder.titleDesc: return 'Title (Z–A)';
      case SortOrder.artistAsc: return 'Artist';
      case SortOrder.dateAdded: return 'Recently Added';
      case SortOrder.duration: return 'Duration';
    }
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceModal,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Settings', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.refresh_rounded, color: AppColors.neonRed),
              title: Text('Rescan Library', style: AppTextStyles.bodyLarge),
              onTap: () {
                Navigator.pop(context);
                _scanLibrary(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline_rounded, color: AppColors.textMuted),
              title: Text('${AppConstants.appName} v${AppConstants.appVersion}',
                  style: AppTextStyles.bodyMedium),
            ),
          ],
        ),
      ),
    );
  }
}
