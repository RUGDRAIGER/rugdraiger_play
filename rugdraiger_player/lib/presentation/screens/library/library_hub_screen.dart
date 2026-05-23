import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/navigation/view_name.dart';
import '../../../core/theme/app_colors.dart';
import '../../bloc/library/library_bloc.dart';

class LibraryHubScreen extends StatelessWidget {
  final ValueChanged<ViewName> onNavigate;

  const LibraryHubScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryBloc, LibraryBlocState>(
      builder: (context, state) {
        final counts = {
          ViewName.songs: state.songs.length,
          ViewName.albums: state.albums.length,
          ViewName.artists: state.artists.length,
          ViewName.playlists: state.playlists.length,
        };

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          children: [
            const Text(
              'Biblioteca',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.95,
              children: [
                _SectionCard(
                  label: 'Canciones',
                  desc: 'Toda tu música',
                  icon: Icons.music_note_rounded,
                  count: counts[ViewName.songs] ?? 0,
                  onTap: () => onNavigate(ViewName.songs),
                ),
                _SectionCard(
                  label: 'Álbumes',
                  desc: 'Por álbum',
                  icon: Icons.album_rounded,
                  count: counts[ViewName.albums] ?? 0,
                  onTap: () => onNavigate(ViewName.albums),
                ),
                _SectionCard(
                  label: 'Artistas',
                  desc: 'Por artista',
                  icon: Icons.person_rounded,
                  count: counts[ViewName.artists] ?? 0,
                  onTap: () => onNavigate(ViewName.artists),
                ),
                _SectionCard(
                  label: 'Playlists',
                  desc: 'Tus listas',
                  icon: Icons.queue_music_rounded,
                  count: counts[ViewName.playlists] ?? 0,
                  onTap: () => onNavigate(ViewName.playlists),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String label;
  final String desc;
  final IconData icon;
  final int count;
  final VoidCallback onTap;

  const _SectionCard({
    required this.label,
    required this.desc,
    required this.icon,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceElevated,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.accent, size: 28),
              const Spacer(),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Text(
                '$count',
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
