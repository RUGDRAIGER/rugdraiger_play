import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/song_model.dart';
import '../bloc/library/library_bloc.dart';

Future<void> showMetadataEditorSheet(
  BuildContext context, {
  required SongModel song,
}) async {
  final libraryBloc = context.read<LibraryBloc>();
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface2,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => BlocProvider.value(
      value: libraryBloc,
      child: _MetadataEditorSheet(song: song),
    ),
  );
}

class _MetadataEditorSheet extends StatefulWidget {
  final SongModel song;

  const _MetadataEditorSheet({required this.song});

  @override
  State<_MetadataEditorSheet> createState() => _MetadataEditorSheetState();
}

class _MetadataEditorSheetState extends State<_MetadataEditorSheet> {
  late final TextEditingController _title;
  late final TextEditingController _artist;
  late final TextEditingController _album;
  late final TextEditingController _genre;
  late final TextEditingController _year;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.song.title);
    _artist = TextEditingController(text: widget.song.artist);
    _album = TextEditingController(text: widget.song.album);
    _genre = TextEditingController(text: widget.song.genre);
    _year = TextEditingController(
      text: widget.song.year > 0 ? '${widget.song.year}' : '',
    );
  }

  @override
  void dispose() {
    _title.dispose();
    _artist.dispose();
    _album.dispose();
    _genre.dispose();
    _year.dispose();
    super.dispose();
  }

  void _save() {
    final year = int.tryParse(_year.text.trim());
    context.read<LibraryBloc>().add(UpdateSongMetadataEvent(
      widget.song.id,
      title: _title.text.trim(),
      artist: _artist.text.trim(),
      album: _album.text.trim(),
      genre: _genre.text.trim(),
      year: year,
    ));
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Metadatos guardados en la biblioteca'),
        backgroundColor: AppColors.surfaceElevated,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text('Editar metadatos', style: AppTextStyles.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Los cambios se guardan en la app, no modifican el archivo en disco.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textTertiary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          _field('Título', _title),
          _field('Artista', _artist),
          _field('Álbum', _album),
          _field('Género', _genre),
          _field('Año', _year, keyboard: TextInputType.number),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.neonRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController controller, {TextInputType? keyboard}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        style: AppTextStyles.bodyLarge,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          filled: true,
          fillColor: AppColors.surfaceElevated,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.borderSubtle),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.borderSubtle),
          ),
        ),
      ),
    );
  }
}
