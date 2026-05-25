import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/song_model.dart';
import '../bloc/library/library_bloc.dart';

class FavoriteButton extends StatelessWidget {
  final SongModel song;
  final double size;

  const FavoriteButton({
    super.key,
    required this.song,
    this.size = 22,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryBloc, LibraryBlocState>(
      buildWhen: (prev, curr) =>
          prev.favorites != curr.favorites || prev.songs != curr.songs,
      builder: (context, state) {
        final isFavorite = state.isFavorite(song.id);
        return Semantics(
          button: true,
          label: isFavorite ? 'Quitar de favoritos' : 'Agregar a favoritos',
          child: GestureDetector(
            onTap: () => context.read<LibraryBloc>().add(ToggleFavoriteEvent(song.id)),
            child: AnimatedScale(
              scale: isFavorite ? 1.08 : 1.0,
              duration: const Duration(milliseconds: 150),
              child: Icon(
                isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: isFavorite ? AppColors.neonRed : AppColors.textSecondary,
                size: size,
                shadows: isFavorite
                    ? [
                        Shadow(
                          color: AppColors.neonRed.withValues(alpha: 0.65),
                          blurRadius: 6,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        );
      },
    );
  }
}
