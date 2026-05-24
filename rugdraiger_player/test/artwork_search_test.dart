import 'package:flutter_test/flutter_test.dart';
import 'package:rugdraiger_player/data/models/song_model.dart';
import 'package:rugdraiger_player/services/artwork_cache.dart';
import 'package:rugdraiger_player/services/filename_metadata.dart';

void main() {
  test('metadata Slipknot Duality desde nombre de archivo', () {
    final meta = resolveArtworkSearchMeta(
      title: '[HD]',
      artist: 'Slipknot Duality',
      album: 'Unknown Album',
      filePath: '/sdcard/Music/[HD] Slipknot Duality.mp3',
    );
    expect(meta.title.toLowerCase(), 'duality');
    expect(meta.artist.toLowerCase(), contains('slipknot'));
  });

  test('búsqueda manual encuentra carátula Slipknot Duality', () async {
    final song = SongModel(
      id: 999001,
      title: '[HD]',
      artist: 'Slipknot Duality',
      album: 'Unknown Album',
      filePath: '/sdcard/Music/[HD] Slipknot Duality.mp3',
      durationMs: 214000,
      dateAdded: DateTime.now(),
    );

    final art = await ArtworkCache.searchRemoteArtwork(song);
    expect(art, isNotNull);
    expect(art!.length, greaterThan(1000));
  });
}
