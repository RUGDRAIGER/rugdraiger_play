import 'package:flutter/material.dart';
import '../../core/navigation/view_name.dart';
import '../../core/theme/app_colors.dart';

class BottomNavBar extends StatelessWidget {
  final ViewName activeView;
  final ValueChanged<ViewName> onNavigate;
  final VoidCallback onMenuOpen;

  const BottomNavBar({
    super.key,
    required this.activeView,
    required this.onNavigate,
    required this.onMenuOpen,
  });

  static const _items = [
    (ViewName.home, 'Inicio', Icons.home_rounded),
    (ViewName.playlists, 'Playlists', Icons.queue_music_rounded),
    (ViewName.search, 'Buscar', Icons.search_rounded),
    (ViewName.equalizer, 'Ecualizador', Icons.graphic_eq_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final menuActive = activeView.isDrawerSection;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.borderSubtle, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              for (final item in _items)
                Expanded(
                  child: _NavButton(
                    label: item.$2,
                    icon: item.$3,
                    isActive: activeView == item.$1,
                    onTap: () => onNavigate(item.$1),
                  ),
                ),
              Expanded(
                child: _NavButton(
                  label: 'Más',
                  icon: Icons.menu_rounded,
                  isActive: menuActive,
                  onTap: onMenuOpen,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _NavButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.accent : AppColors.textTertiary;

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
