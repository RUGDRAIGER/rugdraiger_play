import 'package:flutter_test/flutter_test.dart';
import 'package:rugdraiger_player/services/artwork_fetcher.dart';
import 'package:rugdraiger_player/services/filename_metadata.dart';

void main() {
  const musicPath = '/storage/emulated/0/Music';

  final songs = [
    (
      id: 1,
      file: '$musicPath/01 - Avril Lavigne - Girlfriend.wav',
      storedTitle: '01 - Avril Lavigne - Girlfriend',
      storedArtist: '<unknown>',
      storedAlbum: 'Music',
    ),
    (
      id: 2,
      file: '$musicPath/01 - Evanescence - Going Under.wav',
      storedTitle: '01 - Evanescence - Going Under',
      storedArtist: '<unknown>',
      storedAlbum: 'Music',
    ),
    (
      id: 3,
      file: '$musicPath/01 - blink-182 - Feeling This.wav',
      storedTitle: '01 - blink-182 - Feeling This',
      storedArtist: '<unknown>',
      storedAlbum: 'Music',
    ),
    (
      id: 4,
      file: '$musicPath/Fire Force - Opening 1  Inferno.mp3',
      storedTitle: 'Fire Force - Opening 1  Inferno',
      storedArtist: '<unknown>',
      storedAlbum: 'Music',
    ),
  ];

  test('cada canción obtiene metadata distinta para carátula', () {
    final metas = songs.map((s) {
      return resolveArtworkMeta(
        title: s.storedTitle,
        artist: s.storedArtist,
        album: s.storedAlbum,
        filePath: s.file,
      );
    }).toList();

    final titles = metas.map((m) => m.title.toLowerCase()).toSet();
    final artists = metas.map((m) => m.artist.toLowerCase()).toSet();

    expect(titles.length, 4);
    expect(artists.length, 4);
    expect(metas[0].title, 'Girlfriend');
    expect(metas[1].title, 'Going Under');
    expect(metas[2].title, 'Feeling This');
  });

  test('cada canción obtiene carátula iTunes distinta', () async {
    final artworks = <int, List<int>>{};

    for (final s in songs) {
      final meta = resolveArtworkMeta(
        title: s.storedTitle,
        artist: s.storedArtist,
        album: s.storedAlbum,
        filePath: s.file,
      );

      final bytes = await ArtworkFetcher.fetchForSong(
        songId: s.id,
        artist: meta.artist,
        album: meta.album,
        title: meta.title,
        filePath: s.file,
      );

      expect(bytes, isNotNull, reason: 'Sin carátula para ${s.file}');
      artworks[s.id] = bytes!;
    }

    final hashes = artworks.values.map((b) => b.length).toSet();
    expect(hashes.length, greaterThan(1), reason: 'Todas las carátulas tienen el mismo tamaño');

    // Comparar contenido: ningún par debe ser idéntico
    final ids = artworks.keys.toList();
    for (var i = 0; i < ids.length; i++) {
      for (var j = i + 1; j < ids.length; j++) {
        final a = artworks[ids[i]]!;
        final b = artworks[ids[j]]!;
        final same = a.length == b.length &&
            List.generate(a.length, (k) => a[k] == b[k]).every((v) => v);
        expect(same, isFalse, reason: 'Carátulas idénticas entre ${ids[i]} y ${ids[j]}');
      }
    }
  });
}
