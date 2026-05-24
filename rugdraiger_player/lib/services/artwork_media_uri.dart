import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../data/models/song_model.dart';
import 'artwork_cache.dart';
import 'filename_metadata.dart';

/// Resuelve carátulas como URI accesible para notificación / pantalla bloqueada.
class ArtworkMediaUri {
  ArtworkMediaUri._();

  static const _channel = MethodChannel('rugdraiger/widget');

  static Future<Uri?> resolve(SongModel song) async {
    final path = await resolveFilePath(song);
    if (path == null) return null;

    if (!kIsWeb && Platform.isAndroid) {
      try {
        final contentUri = await _channel.invokeMethod<String>(
          'getArtworkContentUri',
          {'path': path},
        );
        if (contentUri != null && contentUri.isNotEmpty) {
          return Uri.parse(contentUri);
        }
      } catch (e) {
        debugPrint('[ArtworkMediaUri] content uri failed: $e');
      }
    }

    return Uri.file(path);
  }

  static Future<String?> resolveFilePath(SongModel song) async {
    var bytes = ArtworkCache.get(song.id);
    bytes ??= await ArtworkCache.loadForSong(song);
    if (bytes == null || bytes.isEmpty) return null;

    final cacheDir = await getTemporaryDirectory();
    final dir = Directory('${cacheDir.path}/media_art');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final file = File('${dir.path}/${song.id}.jpg');
    if (!await file.exists() || await file.length() < 512) {
      await file.writeAsBytes(bytes, flush: true);
    }
    return file.path;
  }

  static ({String title, String artist, String album}) displayMeta(SongModel song) {
    final meta = resolveArtworkSearchMeta(
      title: song.title,
      artist: song.artist,
      album: song.album,
      filePath: song.filePath,
    );
    return (title: meta.title, artist: meta.artist, album: meta.album);
  }
}
