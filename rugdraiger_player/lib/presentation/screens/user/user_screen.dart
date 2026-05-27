import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../bloc/library/library_bloc.dart';
import '../../widgets/album_card.dart';
import '../../widgets/artwork_widget.dart';

class UserScreen extends StatelessWidget {
  const UserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildProfile()),
            SliverToBoxAdapter(child: _buildStats(context)),
            SliverToBoxAdapter(child: _buildFavorites(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildProfile() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.neonRed, width: 2),
              color: AppColors.surfaceCard,
            ),
            child: Icon(Icons.person_rounded, color: AppColors.neonRed, size: 40),
          ),
          const SizedBox(height: 12),
          Text(AppConstants.appName, style: AppTextStyles.headlineLarge.copyWith(
            color: AppColors.neonRed, letterSpacing: 3,
          )),
          Text('Local Music Player', style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildStats(BuildContext context) {
    return BlocBuilder<LibraryBloc, LibraryBlocState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(child: _StatCard(label: 'Songs', value: '${state.songs.length}')),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(label: 'Albums', value: '${state.albums.length}')),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(label: 'Artists', value: '${state.artists.length}')),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFavorites(BuildContext context) {
    return BlocBuilder<LibraryBloc, LibraryBlocState>(
      builder: (context, state) {
        if (state.favorites.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Text('Favorites', style: AppTextStyles.headlineMedium),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.favorites.length,
              itemBuilder: (context, index) {
                final song = state.favorites[index];
                return SongListTile(
                  title: song.title,
                  artist: song.artist,
                  leading: ArtworkWidget(song: song, size: 46, borderRadius: 6),
                  onTap: () {},
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          Text(value, style: AppTextStyles.headlineLarge.copyWith(color: AppColors.neonRed)),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}
