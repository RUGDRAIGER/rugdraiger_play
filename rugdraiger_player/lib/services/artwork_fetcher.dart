import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'filename_metadata.dart';

/// Port de web/src/services/artworkService.ts — busca carátulas en iTunes.
class ArtworkFetcher {
  ArtworkFetcher._();

  static final Map<String, Uint8List> _cache = {};
  static final Map<String, Future<Uint8List?>> _pending = {};

  static Future<Uint8List?> fetchForSong({
    required int songId,
    required String artist,
    required String album,
    required String title,
    String? filePath,
    bool force = false,
  }) async {
    final meta = resolveArtworkMeta(
      title: title,
      artist: artist,
      album: album,
      filePath: filePath ?? title,
    );

    final key = _cacheKey(meta.artist, meta.album, meta.title, songId);
    if (force) {
      _cache.remove(key);
      _pending.remove(key);
    } else {
      final cached = _cache[key];
      if (cached != null) return cached;
    }

    final inflight = _pending[key];
    if (inflight != null) return inflight;

    final task = _fetch(
      artist: meta.artist,
      album: meta.album,
      title: meta.title,
    );
    _pending[key] = task;
    try {
      final bytes = await task;
      if (bytes != null) _cache[key] = bytes;
      return bytes;
    } finally {
      _pending.remove(key);
    }
  }

  static Future<Uint8List?> _fetch({
    required String artist,
    required String album,
    required String title,
  }) async {
    final cleanArtist = _normalizeQuery(artist);
    final cleanAlbum = _normalizeQuery(album);
    final cleanTitle = _normalizeQuery(title);

    if (cleanArtist.isEmpty && cleanAlbum.isEmpty && cleanTitle.isEmpty) {
      return null;
    }

    final unknownAlbum = isGenericAlbum(cleanAlbum);

    // Misma secuencia que fetchArtworkUrl() en la web
    if (cleanTitle.isNotEmpty && unknownAlbum) {
      final url = await _searchAndPick(
        term: [cleanArtist, cleanTitle].where((v) => v.isNotEmpty).join(' '),
        entity: 'song',
        artist: cleanArtist,
        album: cleanAlbum,
        title: cleanTitle,
      );
      if (url != null) return _downloadArtwork(url);
    }

    if (cleanAlbum.isNotEmpty && !unknownAlbum) {
      final url = await _searchAndPick(
        term: [cleanArtist, cleanAlbum].where((v) => v.isNotEmpty).join(' '),
        entity: 'album',
        artist: cleanArtist,
        album: cleanAlbum,
        title: cleanTitle,
      );
      if (url != null) return _downloadArtwork(url);
    }

    if (cleanTitle.isNotEmpty) {
      final url = await _searchAndPick(
        term: [cleanArtist, cleanTitle].where((v) => v.isNotEmpty).join(' '),
        entity: 'song',
        artist: cleanArtist,
        album: cleanAlbum,
        title: cleanTitle,
      );
      if (url != null) return _downloadArtwork(url);
    }

    return null;
  }

  static Future<String?> _searchAndPick({
    required String term,
    required String entity,
    required String artist,
    required String album,
    required String title,
  }) async {
    if (term.trim().isEmpty) return null;

    final uri = Uri.https('itunes.apple.com', '/search', {
      'term': term,
      'entity': entity,
      'limit': '8',
    });

    final response = await http.get(uri).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final results = (data['results'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
    if (results.isEmpty) return null;

    final match = _pickBestMatch(results, artist, album, title);
    return match != null ? _artworkUrlFromItem(match) : null;
  }

  static Map<String, dynamic>? _pickBestMatch(
    List<Map<String, dynamic>> results,
    String artist,
    String album,
    String title,
  ) {
    final a = artist.toLowerCase();
    final al = album.toLowerCase();
    final t = title.toLowerCase();

    final scored = results.map((item) {
      var score = 0;
      final itemArtist = (item['artistName'] as String? ?? '').toLowerCase();
      final itemAlbum = (item['collectionName'] as String? ?? '').toLowerCase();
      final itemTitle = (item['trackName'] as String? ?? '').toLowerCase();

      if (a.isNotEmpty && (itemArtist.contains(a) || a.contains(itemArtist))) {
        score += 3;
      }
      if (al.isNotEmpty && (itemAlbum.contains(al) || al.contains(itemAlbum))) {
        score += 3;
      }
      if (t.isNotEmpty && (itemTitle.contains(t) || t.contains(itemTitle))) {
        score += 2;
      }
      if (item['artworkUrl600'] != null || item['artworkUrl100'] != null) {
        score += 1;
      }

      return {'item': item, 'score': score};
    }).toList();

    scored.sort((x, y) => (y['score'] as int).compareTo(x['score'] as int));
    final bestScore = scored.first['score'] as int;
    if (bestScore > 0) return scored.first['item'] as Map<String, dynamic>;
    return results.first;
  }

  static String? _artworkUrlFromItem(Map<String, dynamic> item) {
    final raw = (item['artworkUrl600'] as String?) ??
        (item['artworkUrl100'] as String?);
    if (raw == null || raw.isEmpty) return null;
    return raw
        .replaceAllMapped(
          RegExp(r'(\d+)x\d+(bb)?\.(jpg|png)', caseSensitive: false),
          (m) => '600x600${m.group(2) ?? ''}.${m.group(3)}',
        )
        .replaceAll('100x100', '600x600');
  }

  static Future<Uint8List?> _downloadArtwork(String url) async {
    final response =
        await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200 || response.bodyBytes.isEmpty) return null;
    return response.bodyBytes;
  }

  static String _cacheKey(
    String artist,
    String album,
    String title,
    int songId,
  ) {
    if (!canShareArtworkByAlbum(artist, album)) {
      return 'song::$songId::${_normalizeQuery(title).toLowerCase()}';
    }
    return albumArtworkKey(artist, album);
  }

  static String _normalizeQuery(String value) {
    return value
        .replaceAll(RegExp(r'\([^)]*\)'), '')
        .replaceAll(RegExp(r'\[[^\]]*\]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
