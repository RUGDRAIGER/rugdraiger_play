import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/navigation/view_name.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/song_model.dart';
import '../../bloc/library/library_bloc.dart';
import '../../bloc/player/player_bloc.dart';
import '../../utils/player_navigation.dart';
import '../../widgets/album_card.dart';
import '../../widgets/app_icon_widget.dart';
import '../../widgets/artwork_widget.dart';

class HomeScreen extends StatefulWidget {
  final ValueChanged<ViewName>? onNavigate;

  const HomeScreen({super.key, this.onNavigate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _clearStep = 0;

  @override
  void initState() {
    super.initState();
    context.read<LibraryBloc>().add(const LoadLibraryEvent());
  }

  Future<void> _pickFolder() async {
    final path = await FilePicker.platform.getDirectoryPath();
    if (path != null && mounted) {
      context.read<LibraryBloc>().add(ScanFolderEvent(path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildHeader(),
                _buildScanSection(),
                _buildRecentlyPlayed(),
                _buildAlbumPreview(),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
            if (_clearStep > 0) _buildClearDialogs(),
          ],
        ),
      ),
    );
  }

  Widget _buildClearDialogs() {
    return BlocBuilder<LibraryBloc, LibraryBlocState>(
      builder: (context, state) {
        if (_clearStep == 1) {
          return _ConfirmOverlay(
            title: 'Limpiar biblioteca',
            message: '¿Estás seguro de que quieres eliminar todas las ${state.songs.length} canciones de tu biblioteca?',
            confirmLabel: 'Continuar',
            onConfirm: () => setState(() => _clearStep = 2),
            onCancel: () => setState(() => _clearStep = 0),
          );
        }
        if (_clearStep == 2) {
          return _ConfirmOverlay(
            title: 'Confirmación final',
            message: 'Esta acción borrará toda tu biblioteca de forma permanente y no se puede deshacer. ¿Deseas continuar?',
            confirmLabel: 'Sí, limpiar todo',
            isDestructive: true,
            onConfirm: () {
              context.read<PlayerBloc>().add(const StopPlaybackEvent());
              context.read<LibraryBloc>().add(const ClearLibraryEvent());
              setState(() => _clearStep = 0);
            },
            onCancel: () => setState(() => _clearStep = 0),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: BlocBuilder<LibraryBloc, LibraryBlocState>(
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                const AppIconWidget(size: 64, borderRadius: 14),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppConstants.appName,
                        style: AppTextStyles.displayMedium.copyWith(
                          color: AppColors.accent,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        state.songs.isNotEmpty
                            ? '${state.songs.length} canciones · ${state.albums.length} álbumes'
                            : 'Tu biblioteca de música local',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildScanSection() {
    return BlocBuilder<LibraryBloc, LibraryBlocState>(
      builder: (context, state) {
        final isScanning = state.status == LibraryStatus.scanning;
        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ElevatedButton.icon(
                      onPressed: isScanning ? null : () => context.read<LibraryBloc>().add(const ScanLibraryEvent()),
                      icon: const Icon(Icons.library_music_rounded, size: 18),
                      label: Text(isScanning ? 'Escaneando...' : 'Escanear biblioteca'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: isScanning ? null : _pickFolder,
                      icon: const Icon(Icons.folder_rounded, size: 18),
                      label: const Text('Elegir carpeta'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.borderSubtle),
                        foregroundColor: AppColors.textPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    if (state.songs.isNotEmpty)
                      OutlinedButton.icon(
                        onPressed: isScanning ? null : () => setState(() => _clearStep = 1),
                        icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                        label: const Text('Limpiar biblioteca'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.borderSubtle),
                          foregroundColor: AppColors.textSecondary,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                  ],
                ),
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    state.errorMessage!,
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.accent, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  'Escanea todo el dispositivo o elige una carpeta específica con tu música.',
                  style: AppTextStyles.bodyMedium.copyWith(fontSize: 12, color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentlyPlayed() {
    return BlocBuilder<LibraryBloc, LibraryBlocState>(
      builder: (context, state) {
        if (state.recentlyPlayed.isEmpty) return const SliverToBoxAdapter();
        return SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: Text('Recientes', style: AppTextStyles.headlineMedium),
              ),
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
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
                              style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
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
          ),
        );
      },
    );
  }

  Widget _buildAlbumPreview() {
    return BlocBuilder<LibraryBloc, LibraryBlocState>(
      builder: (context, state) {
        if (state.albums.isEmpty) return const SliverToBoxAdapter();
        final previewAlbums = state.albums.take(6).toList();
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Álbumes', style: AppTextStyles.headlineMedium),
                  TextButton(
                    onPressed: () => widget.onNavigate?.call(ViewName.albums),
                    child: Text('Ver todos', style: AppTextStyles.neonLabel),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.82,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: previewAlbums.length,
                itemBuilder: (context, index) {
                  final album = previewAlbums[index];
                  final coverSongs = state.songs.where((s) => s.album == album);
                  final coverSong = coverSongs.isEmpty ? null : coverSongs.first;
                  return AlbumCard(
                    title: album,
                    subtitle: '',
                    artwork: coverSong != null
                        ? ArtworkWidget(song: coverSong, size: double.infinity, borderRadius: 0)
                        : null,
                    onTap: () => widget.onNavigate?.call(ViewName.albums),
                  );
                },
              ),
            ]),
          ),
        );
      },
    );
  }

  void _playSong(BuildContext context, SongModel song, List<SongModel> songs, int index) {
    context.read<PlayerBloc>().add(PlaySongEvent(song, queue: songs, index: index));
    openFullPlayer(context);
  }
}

class _ConfirmOverlay extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final bool isDestructive;

  const _ConfirmOverlay({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.onConfirm,
    required this.onCancel,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.titleMedium.copyWith(fontSize: 18)),
              const SizedBox(height: 12),
              Text(message, style: AppTextStyles.bodyMedium),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: onCancel, child: const Text('Cancelar')),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDestructive ? AppColors.accent : AppColors.surfaceElevated,
                      foregroundColor: isDestructive ? Colors.white : AppColors.textPrimary,
                    ),
                    child: Text(confirmLabel),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
