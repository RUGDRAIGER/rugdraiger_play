import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/navigation/view_name.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/mini_player.dart';
import '../../widgets/mobile_nav_drawer.dart';
import '../../utils/player_navigation.dart';
import '../equalizer/equalizer_screen.dart';
import '../home/home_screen.dart';
import '../library/albums_screen.dart';
import '../library/artists_screen.dart';
import '../library/library_hub_screen.dart';
import '../library/songs_screen.dart';
import '../playlist/playlists_screen.dart';
import '../search/search_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  ViewName _activeView = ViewName.home;
  bool _drawerOpen = false;

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
      case ViewName.equalizer:
        return const EqualizerScreen();
      case ViewName.search:
        return const SearchScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
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
      ),
    );
  }
}
