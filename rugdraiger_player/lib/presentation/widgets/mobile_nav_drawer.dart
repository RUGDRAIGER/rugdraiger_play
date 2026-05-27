import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/navigation/view_name.dart';
import '../../core/theme/app_colors.dart';
import 'app_icon_widget.dart';

class MobileNavDrawer extends StatelessWidget {
  final bool open;
  final ViewName activeView;
  final ValueChanged<ViewName> onNavigate;
  final VoidCallback onClose;

  const MobileNavDrawer({
    super.key,
    required this.open,
    required this.activeView,
    required this.onNavigate,
    required this.onClose,
  });

  static const _items = [
    (ViewName.home, 'Inicio', Icons.home_rounded),
    (ViewName.library, 'Biblioteca', Icons.library_music_rounded),
    (ViewName.songs, 'Canciones', Icons.music_note_rounded),
    (ViewName.albums, 'Álbumes', Icons.album_rounded),
    (ViewName.artists, 'Artistas', Icons.person_rounded),
    (ViewName.genres, 'Géneros', Icons.music_note_rounded),
    (ViewName.favorites, 'Favoritos', Icons.favorite_rounded),
    (ViewName.playlists, 'Playlists', Icons.queue_music_rounded),
    (ViewName.equalizer, 'Ecualizador', Icons.graphic_eq_rounded),
    (ViewName.search, 'Buscar', Icons.search_rounded),
    (ViewName.settings, 'Ajustes', Icons.settings_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    if (!open) return const SizedBox.shrink();

    return Stack(
      children: [
        GestureDetector(
          onTap: onClose,
          child: Container(color: Colors.black.withValues(alpha: 0.55)),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Material(
            color: AppColors.surface,
            child: Container(
              width: 280,
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: AppColors.borderSubtle)),
              ),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: Row(
                        children: [
                          const AppIconWidget(size: 36, borderRadius: 8),
                          const SizedBox(width: 10),
                          Text(
                            AppConstants.appName,
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        children: [
                          for (final item in _items)
                            _DrawerItem(
                              label: item.$2,
                              icon: item.$3,
                              isActive: activeView == item.$1,
                              onTap: () {
                                onNavigate(item.$1);
                                onClose();
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: isActive ? AppColors.accentSubtle : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isActive ? AppColors.accent : AppColors.textSecondary,
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    color: isActive ? AppColors.accent : AppColors.textSecondary,
                    fontSize: 15,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
