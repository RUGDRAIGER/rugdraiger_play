import 'package:flutter_test/flutter_test.dart';
import 'package:rugdraiger_player/services/artwork_fetcher.dart';
import 'package:rugdraiger_player/services/filename_metadata.dart';

void main() {
  test('infiere artista Fire Force desde el nombre del archivo', () {
    const path =
        '/storage/emulated/0/Music/Fire Force - Opening 1  Inferno.mp3';

    final meta = resolveArtworkMeta(
      title: 'Fire Force - Opening 1  Inferno',
      artist: '<unknown>',
      album: 'Music',
      filePath: path,
    );

    expect(meta.artist.toLowerCase(), contains('fire force'));
    expect(meta.title.toLowerCase(), contains('inferno'));
  });

  test('obtiene carátula iTunes para Fire Force Inferno', () async {
    const path =
        '/storage/emulated/0/Music/Fire Force - Opening 1  Inferno.mp3';

    final artwork = await ArtworkFetcher.fetchForSong(
      songId: 1000000020,
      artist: '<unknown>',
      album: 'Music',
      title: 'Fire Force - Opening 1  Inferno',
      filePath: path,
    );

    expect(artwork, isNotNull);
    expect(artwork!.length, greaterThan(1000));
    expect(artwork[0], 0xFF);
    expect(artwork[1], 0xD8);
  });
}
