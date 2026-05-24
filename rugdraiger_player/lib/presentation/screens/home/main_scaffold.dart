import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/navigation/view_name.dart';
import '../../../core/platform/platform_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../bloc/library/library_bloc.dart';
import '../../bloc/player/player_bloc.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/mini_player.dart';
import '../../widgets/mobile_nav_drawer.dart';
import '../../utils/player_navigation.dart';
import '../equalizer/equalizer_screen.dart';
import '../home/home_screen.dart';
import '../library/albums_screen.dart';
import '../library/artists_screen.dart';
import '../library/favorites_screen.dart';
import '../library/library_hub_screen.dart';
import '../library/songs_screen.dart';
import '../playlist/playlists_screen.dart';
import '../search/search_screen.dart';

class MainScaffold extends StatefulWidget {
  final bool autoScanOnStart;

  const MainScaffold({super.key, this.autoScanOnStart = false});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  ViewName _activeView = ViewName.home;
  bool _drawerOpen = false;
  bool _initialScanDone = false;

  @override
  void initState() {
    super.initState();
    context.read<LibraryBloc>().add(const LoadLibraryEvent());
  }

  void _maybeAutoScan(LibraryBlocState state) {
    if (!widget.autoScanOnStart || _initialScanDone) return;
    if (state.status != LibraryStatus.loaded) return;
    _initialScanDone = true;
    if (state.songs.isEmpty) {
      context.read<LibraryBloc>().add(const ScanLibraryEvent());
    }
  }

  void _navigate(ViewName view) {
    setState(() {
      _activeView = view;
      _drawerOpen = false;
    });
  }

  Widget _buildView() {
    switch (_activeView) {
      case ViewName.home:
        return HomeScreen(onNavigate: _navigate);
      case ViewName.library:
        return LibraryHubScreen(onNavigate: _navigate);
      case ViewName.songs:
        return const SongsScreen();
      case ViewName.albums:
        return const AlbumsScreen();
      case ViewName.artists:
        return const ArtistsScreen();
      case ViewName.playlists:
        return const PlaylistsScreen();
      case ViewName.favorites:
        return const FavoritesScreen();
      case ViewName.equalizer:
        return const EqualizerScreen();
      case ViewName.search:
        return const SearchScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PlayerBloc, PlayerBlocState>(
      listenWhen: (prev, curr) =>
          prev.currentSong?.id != curr.currentSong?.id && curr.currentSong != null,
      listener: (context, _) {
        context.read<LibraryBloc>().add(const RefreshPlayStatsEvent());
      },
      child: BlocListener<LibraryBloc, LibraryBlocState>(
        listener: (context, state) => _maybeAutoScan(state),
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: PlatformConfig.isDesktop
              ? Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520, maxHeight: 960),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _buildShell(),
                    ),
                  ),
                )
              : _buildShell(),
        ),
      ),
    );
  }

  Widget _buildShell() {
    return Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: AnimatedSwitcher(
                    duration: AppConstants.animFast,
                    child: KeyedSubtree(
                      key: ValueKey(_activeView),
                      child: _buildView(),
                    ),
                  ),
                ),
                MiniPlayer(onTap: () => openFullPlayer(context)),
                BottomNavBar(
                  activeView: _activeView,
                  onNavigate: _navigate,
                  onMenuOpen: () => setState(() => _drawerOpen = true),
                ),
              ],
            ),
            MobileNavDrawer(
              open: _drawerOpen,
              activeView: _activeView,
              onNavigate: _navigate,
              onClose: () => setState(() => _drawerOpen = false),
            ),
          ],
        );
  }
}
