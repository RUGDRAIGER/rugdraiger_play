import 'dart:typed_data';
import 'package:on_audio_query/on_audio_query.dart' as oaq;
import '../data/models/song_model.dart';
import 'artwork_fetcher.dart';
import 'artwork_refresh.dart';
import 'artwork_storage.dart';
import 'embedded_artwork_extractor.dart';
import 'filename_metadata.dart';

class ArtworkCache {
  ArtworkCache._();

  static final Map<int, Uint8List> _cache = {};
  static final Map<String, Uint8List> _albumCache = {};
  static oaq.OnAudioQuery? _query;
  static Future<void> _loadQueue = Future.value();

  static Uint8List? get(int songId) => _cache[songId];

  static Uint8List? getForAlbum(String artist, String album) {
    if (!canShareArtworkByAlbum(artist, album)) return null;
    return _albumCache[albumArtworkKey(artist, album)];
  }

  static void set(
    int songId,
    Uint8List data, {
    String? artist,
    String? album,
  }) {
    _cache[songId] = data;
    if (artist != null &&
        album != null &&
        canShareArtworkByAlbum(artist, album)) {
      _albumCache[albumArtworkKey(artist, album)] = data;
    }
    ArtworkStorage.save(songId, data);
  }

  static void clear() {
    _cache.clear();
    _albumCache.clear();
    ArtworkStorage.clearAll();
  }

  /// Búsqueda manual de carátula (iTunes) para canciones sin arte.
  static Future<Uint8List?> searchRemoteArtwork(SongModel song) async {
    _cache.remove(song.id);

    final meta = resolveArtworkSearchMeta(
      title: song.title,
      artist: song.artist,
      album: song.album,
      filePath: song.filePath,
    );

    final remote = await ArtworkFetcher.fetchForSong(
      songId: song.id,
      artist: meta.artist,
      album: meta.album,
      title: meta.title,
      filePath: song.filePath,
      force: true,
    );

    if (remote != null && remote.isNotEmpty) {
      set(song.id, remote, artist: meta.artist, album: meta.album);
      ArtworkRefresh.bump();
      return remote;
    }

    return null;
  }

  static Future<Uint8List?> loadForSong(SongModel song) async {
    final task = _loadQueue.then((_) => _loadForSongImpl(song));
    _loadQueue = task.then((_) {}, onError: (_) {});
    return task;
  }

  static Future<Uint8List?> _loadForSongImpl(SongModel song) async {
    final cached = _cache[song.id];
    if (cached != null) return cached;

    final stored = await ArtworkStorage.load(song.id);
    if (stored != null && stored.isNotEmpty) {
      set(
        song.id,
        stored,
        artist: song.artist,
        album: song.album,
      );
      return stored;
    }

    if (song.artwork != null && song.artwork!.isNotEmpty) {
      set(
        song.id,
        song.artwork!,
        artist: song.artist,
        album: song.album,
      );
      return song.artwork;
    }

    final meta = resolveArtworkMeta(
      title: song.title,
      artist: song.artist,
      album: song.album,
      filePath: song.filePath,
    );

    if (canShareArtworkByAlbum(meta.artist, meta.album)) {
      final albumArt = getForAlbum(meta.artist, meta.album);
      if (albumArt != null) {
        _cache[song.id] = albumArt;
        return albumArt;
      }
    }

    _query ??= oaq.OnAudioQuery();

    // 1) Arte embebido en el archivo (único por pista)
    final paths = await _resolveReadablePaths(song);
    for (final path in paths) {
      final embedded = await EmbeddedArtworkExtractor.extractFromPath(path);
      if (embedded != null && embedded.isNotEmpty) {
        set(song.id, embedded, artist: meta.artist, album: meta.album);
        return embedded;
      }
    }

    // 2) iTunes — carátula por canción (evita clonar arte de álbum MediaStore)
    final remote = await ArtworkFetcher.fetchForSong(
      songId: song.id,
      artist: meta.artist,
      album: meta.album,
      title: meta.title,
      filePath: song.filePath,
    );
    if (remote != null && remote.isNotEmpty) {
      set(song.id, remote, artist: meta.artist, album: meta.album);
      return remote;
    }

    // 3) MediaStore solo si hay metadata real de álbum/artista (no carpeta "Music")
    if (canShareArtworkByAlbum(meta.artist, meta.album)) {
      try {
        final mediaId = await _resolveMediaStoreId(song);
        if (mediaId != null) {
          for (final format in [oaq.ArtworkFormat.JPEG, oaq.ArtworkFormat.PNG]) {
            final art = await _query!.queryArtwork(
              mediaId,
              oaq.ArtworkType.AUDIO,
              format: format,
              size: 512,
            ).timeout(const Duration(seconds: 3), onTimeout: () => null);
            if (art != null && art.isNotEmpty) {
              set(song.id, art, artist: meta.artist, album: meta.album);
              return art;
            }
          }
        }
      } catch (_) {}
    }

    return null;
  }

  /// Equivalente a enrichSongsArtwork() de la web.
  static Future<void> enrichAll(List<SongModel> songs) async {
    final sharedAlbumArt = <String, Uint8List>{};

    for (final song in songs) {
      if (_cache.containsKey(song.id) || (song.artwork?.isNotEmpty ?? false)) {
        continue;
      }

      final meta = resolveArtworkMeta(
        title: song.title,
        artist: song.artist,
        album: song.album,
        filePath: song.filePath,
      );

      final shareByAlbum = canShareArtworkByAlbum(meta.artist, meta.album);
      final groupKey = shareByAlbum
          ? albumArtworkKey(meta.artist, meta.album)
          : 'song:${song.id}';

      if (shareByAlbum && sharedAlbumArt.containsKey(groupKey)) {
        set(
          song.id,
          sharedAlbumArt[groupKey]!,
          artist: meta.artist,
          album: meta.album,
        );
        continue;
      }

      final art = await loadForSong(song);
      if (art != null && shareByAlbum) {
        sharedAlbumArt[groupKey] = art;
      }

      await Future.delayed(const Duration(milliseconds: 120));
    }
  }

  static Future<void> prefetchAll(List<SongModel> songs) async {
    await enrichAll(songs);
  }

  static Future<int?> _resolveMediaStoreId(SongModel song) async {
    if (_isMediaStoreId(song.id)) return song.id;

    try {
      final songs = await _query!.querySongs(
        sortType: oaq.SongSortType.TITLE,
        orderType: oaq.OrderType.ASC_OR_SMALLER,
        uriType: oaq.UriType.EXTERNAL,
        ignoreCase: true,
      );

      final normalizedPath = song.filePath.replaceFirst('file://', '');
      for (final s in songs) {
        if (s.data == normalizedPath ||
            s.data == song.filePath ||
            s.uri == song.filePath ||
            s.uri == normalizedPath) {
          return s.id;
        }
      }
    } catch (_) {}

    return null;
  }

  static bool _isMediaStoreId(int id) => id > 0 && id < 1000000000;

  static Future<List<String>> _resolveReadablePaths(SongModel song) async {
    final paths = <String>[];
    final seen = <String>{};

    void add(String? value) {
      final trimmed = value?.trim();
      if (trimmed == null || trimmed.isEmpty || !seen.add(trimmed)) return;
      paths.add(trimmed);
    }

    final filePath = song.filePath.trim();
    add(filePath);

    final normalized = filePath.replaceFirst('file://', '');
    if (normalized.startsWith('/') && !normalized.startsWith('content://')) {
      return paths;
    }

    if (!filePath.startsWith('content://')) {
      return paths;
    }

    try {
      _query ??= oaq.OnAudioQuery();
      final songs = await _query!.querySongs(
        sortType: oaq.SongSortType.TITLE,
        orderType: oaq.OrderType.ASC_OR_SMALLER,
        uriType: oaq.UriType.EXTERNAL,
        ignoreCase: true,
      );

      for (final s in songs) {
        final matches = s.id == song.id ||
            s.data == normalized ||
            s.data == filePath ||
            s.uri == filePath ||
            s.uri == normalized;
        if (!matches) continue;

        add(s.data);
        add(s.uri);
        break;
      }
    } catch (_) {}

    paths.sort((a, b) {
      int score(String path) {
        if (path.startsWith('content://')) return 2;
        if (path.startsWith('/storage/') || path.startsWith('/data/')) return 0;
        return 1;
      }

      return score(a).compareTo(score(b));
    });

    return paths;
  }
}
