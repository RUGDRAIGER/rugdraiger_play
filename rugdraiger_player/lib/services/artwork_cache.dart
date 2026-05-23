import 'dart:typed_data';
import 'package:on_audio_query/on_audio_query.dart' as oaq;
import '../data/models/song_model.dart';

class ArtworkCache {
  ArtworkCache._();

  static final Map<int, Uint8List> _cache = {};
  static oaq.OnAudioQuery? _query;

  static Uint8List? get(int songId) => _cache[songId];

  static void set(int songId, Uint8List data) => _cache[songId] = data;

  static void clear() => _cache.clear();

  static Future<Uint8List?> loadForSong(SongModel song) async {
    final cached = _cache[song.id];
    if (cached != null) return cached;

    if (song.artwork != null) {
      _cache[song.id] = song.artwork!;
      return song.artwork;
    }

    _query ??= oaq.OnAudioQuery();

    try {
      var art = await _query!.queryArtwork(
        song.id,
        oaq.ArtworkType.AUDIO,
        format: oaq.ArtworkFormat.JPEG,
        size: 300,
      );
      if (art != null && art.isNotEmpty) {
        _cache[song.id] = art;
        return art;
      }

      // Canciones indexadas por carpeta: buscar ID real en MediaStore por ruta
      if (!song.filePath.startsWith('content://')) {
        final mediaId = await _findMediaStoreId(song.filePath);
        if (mediaId != null) {
          art = await _query!.queryArtwork(
            mediaId,
            oaq.ArtworkType.AUDIO,
            format: oaq.ArtworkFormat.JPEG,
            size: 300,
          );
          if (art != null && art.isNotEmpty) {
            _cache[song.id] = art;
            return art;
          }
        }
      }
    } catch (_) {}

    return null;
  }

  static Future<void> prefetchAll(List<SongModel> songs) async {
    const batchSize = 8;
    for (var i = 0; i < songs.length; i += batchSize) {
      final batch = songs.skip(i).take(batchSize);
      await Future.wait(batch.map((s) => loadForSong(s)));
    }
  }

  static Future<int?> _findMediaStoreId(String filePath) async {
    try {
      final songs = await _query!.querySongs(
        sortType: oaq.SongSortType.TITLE,
        orderType: oaq.OrderType.ASC_OR_SMALLER,
        uriType: oaq.UriType.EXTERNAL,
        ignoreCase: true,
      );
      final normalized = filePath.replaceAll('file://', '');
      for (final s in songs) {
        if (s.data == normalized || s.data == filePath) return s.id;
      }
    } catch (_) {}
    return null;
  }
}
