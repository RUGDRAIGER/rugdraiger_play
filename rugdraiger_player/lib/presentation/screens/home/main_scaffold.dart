import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../widgets/mini_player.dart';
import '../home/home_screen.dart';
import '../library/library_screen.dart';
import '../search/search_screen.dart';
import '../equalizer/equalizer_screen.dart';
import '../user/user_screen.dart';
import '../player/player_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    LibraryScreen(),
    SearchScreen(),
    EqualizerScreen(),
    UserScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mini Player above nav bar
          MiniPlayer(
            onTap: () => Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (_, animation, __) => const PlayerScreen(),
                transitionsBuilder: (_, animation, __, child) => SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                ),
                transitionDuration: AppConstants.animNormal,
              ),
            ),
          ),
          // Bottom Navigation
          Container(
            decoration: const BoxDecoration(
              color: AppColors.surfaceElevated,
              border: Border(
                top: BorderSide(color: AppColors.border, width: 0.5),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: AppConstants.bottomNavHeight,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavItem(
                      icon: Icons.home_filled,
                      outlinedIcon: Icons.home_outlined,
                      label: 'Library',
                      isSelected: _currentIndex == 0,
                      onTap: () => setState(() => _currentIndex = 0),
                    ),
                    _NavItem(
                      icon: Icons.library_music_rounded,
                      outlinedIcon: Icons.library_music_outlined,
                      label: 'Songs',
                      isSelected: _currentIndex == 1,
                      onTap: () => setState(() => _currentIndex = 1),
                    ),
                    _NavItem(
                      icon: Icons.graphic_eq_rounded,
                      outlinedIcon: Icons.graphic_eq_outlined,
                      label: 'EQ',
                      isSelected: _currentIndex == 3,
                      onTap: () => setState(() => _currentIndex = 3),
                    ),
                    _NavItem(
                      icon: Icons.favorite_rounded,
                      outlinedIcon: Icons.favorite_border_rounded,
                      label: 'Likes',
                      isSelected: _currentIndex == 4,
                      onTap: () => setState(() => _currentIndex = 4),
                    ),
                    _NavItem(
                      icon: Icons.person_rounded,
                      outlinedIcon: Icons.person_outline_rounded,
                      label: 'User',
                      isSelected: _currentIndex == 4,
                      onTap: () => setState(() => _currentIndex = 4),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData outlinedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.outlinedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: AppConstants.animFast,
              child: Icon(
                isSelected ? icon : outlinedIcon,
                key: ValueKey(isSelected),
                color: isSelected ? AppColors.neonRed : AppColors.textMuted,
                size: 24,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: isSelected ? AppColors.neonRed : AppColors.textMuted,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
