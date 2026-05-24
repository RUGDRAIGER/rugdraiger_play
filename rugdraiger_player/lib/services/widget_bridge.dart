import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'artwork_media_uri.dart';
import 'audio_service.dart';

/// Sincroniza el widget de escritorio Android con el estado del reproductor.
class WidgetBridge {
  WidgetBridge._();

  static const _channel = MethodChannel('rugdraiger/widget');

  static String? _lastSongId;
  static bool? _lastPlaying;
  static DateTime? _lastSync;

  static Future<void> sync(PlayerState state) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    final song = state.currentSong;
    if (song == null) {
      try {
        await _channel.invokeMethod('clearWidget');
        _lastSongId = null;
      } catch (_) {}
      return;
    }

    final songId = song.id.toString();
    final now = DateTime.now();
    final shouldSync = _lastSongId != songId ||
        _lastPlaying != state.isPlaying ||
        _lastSync == null ||
        now.difference(_lastSync!) > const Duration(seconds: 4);

    if (!shouldSync) return;

    _lastSongId = songId;
    _lastPlaying = state.isPlaying;
    _lastSync = now;

    try {
      final artPath = await ArtworkMediaUri.resolveFilePath(song);
      final meta = ArtworkMediaUri.displayMeta(song);
      await _channel.invokeMethod('updateWidget', {
        'title': meta.title,
        'artist': meta.artist,
        'album': meta.album,
        'artworkPath': artPath,
        'isPlaying': state.isPlaying,
        'positionMs': state.position.inMilliseconds,
        'durationMs': state.duration.inMilliseconds,
        'queueSize': state.queue.length,
        'queueIndex': state.currentIndex,
      });
    } catch (e) {
      debugPrint('[WidgetBridge] sync failed: $e');
    }
  }
}
