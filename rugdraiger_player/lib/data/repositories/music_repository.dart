import 'dart:io';
import 'package:on_audio_query/on_audio_query.dart' as oaq;
import 'package:path/path.dart' as path_lib;
import '../../core/constants/app_constants.dart';
import '../../core/platform/desktop_music_paths.dart';
import '../../core/platform/platform_config.dart';
import '../../services/filename_metadata.dart';
import '../models/song_model.dart';
import '../models/playlist_model.dart';
import '../sources/database_helper.dart';

class MusicRepository {
  final DatabaseHelper _db;
  final oaq.OnAudioQuery _audioQuery;

  MusicRepository({
    DatabaseHelper? db,
    oaq.OnAudioQuery? audioQuery,
  })  : _db = db ?? DatabaseHelper(),
        _audioQuery = audioQuery ?? oaq.OnAudioQuery();

  // ── Scanning ───────────────────────────────────────────────────────────────

  Future<int> scanAndIndexLibrary() async {
    if (PlatformConfig.isDesktop) {
      return scanDesktopLibrary();
    }

    final permitted = await _audioQuery.checkAndRequest(retryRequest: true);
    if (!permitted) {
      throw Exception(
        'Permiso denegado. Activa el acceso a música en Ajustes del dispositivo.',
      );
    }

    try {
      final songs = await _audioQuery.querySongs(
        sortType: oaq.SongSortType.TITLE,
        orderType: oaq.OrderType.ASC_OR_SMALLER,
        uriType: oaq.UriType.EXTERNAL,
        ignoreCase: true,
      );

      final supported = songs
          .where((s) =>
              AppConstants.supportedFormats.contains(s.fileExtension.toLowerCase()))
          .toList();

      if (supported.isEmpty) return 0;

      final models = supported.map(_fromOaqSong).toList();
      await _db.insertSongs(models);
      return models.length;
    } catch (e) {
      throw Exception('Error al escanear biblioteca: $e');
    }
  }

  /// Escanea carpetas de música típicas en Windows/macOS/Linux.
  Future<int> scanDesktopLibrary() async {
    final folders = DesktopMusicPaths.defaultMusicFolders();
    if (folders.isEmpty) return 0;

    var total = 0;
    for (final folder in folders) {
      total += await scanDirectory(folder);
    }
    return total;
  }

  SongModel _fromOaqSong(oaq.SongModel song) {
    final ext = song.fileExtension.toLowerCase();
    final isLossless = AppConstants.losslessFormats.contains(ext);
    final format = AudioFormat.values.firstWhere(
      (f) => f.name == ext,
      orElse: () => AudioFormat.unknown,
    );

    final filePath = song.data.isNotEmpty ? song.data : (song.uri ?? song.data);
    final inferred = inferMetadataFromPath(filePath);
    final meta = resolveArtworkMeta(
      title: song.title,
      artist: song.artist ?? '',
      album: song.album ?? '',
      filePath: filePath,
    );

    final title = meta.title.isNotEmpty ? meta.title : 'Unknown Title';
    final artist = isGenericArtist(meta.artist)
        ? (inferred.artist?.trim().isNotEmpty == true
            ? inferred.artist!.trim()
            : 'Unknown Artist')
        : meta.artist;
    final album = isGenericAlbum(meta.album)
        ? (inferred.album?.trim().isNotEmpty == true &&
                !isGenericAlbum(inferred.album)
            ? inferred.album!.trim()
            : (!isGenericArtist(artist) ? artist : 'Unknown Album'))
        : meta.album;

    return SongModel(
      id: song.id,
      title: title,
      artist: artist,
      album: album,
      genre: song.genre ?? '',
      filePath: filePath,
      durationMs: song.duration ?? 0,
      fileSize: song.size,
      trackNumber: song.track ?? inferred.track ?? 0,
      format: format,
      isLossless: isLossless,
      dateAdded: DateTime.fromMillisecondsSinceEpoch(
        (song.dateAdded ?? 0) * 1000,
      ),
    );
  }

  Future<int> scanDirectory(String directoryPath) async {
    final dir = Directory(directoryPath);
    if (!await dir.exists()) return 0;

    final files = await _collectAudioFiles(dir);
    final songs = <SongModel>[];
    int id = DateTime.now().millisecondsSinceEpoch;

    for (final file in files) {
      final ext = path_lib.extension(file.path).replaceAll('.', '').toLowerCase();
      if (!AppConstants.supportedFormats.contains(ext)) continue;

      final isLossless = AppConstants.losslessFormats.contains(ext);
      final format = AudioFormat.values.firstWhere(
        (f) => f.name == ext,
        orElse: () => AudioFormat.unknown,
      );

      final name = path_lib.basenameWithoutExtension(file.path);
      final inferred = inferMetadataFromPath(file.path);
      songs.add(SongModel(
        id: id++,
        title: inferred.title ?? name,
        artist: inferred.artist ?? 'Unknown Artist',
        album: inferred.album ?? 'Unknown Album',
        filePath: file.path,
        durationMs: 0,
        fileSize: await file.length(),
        trackNumber: inferred.track ?? 0,
        format: format,
        isLossless: isLossless,
        dateAdded: await file.lastModified(),
      ));
    }

    await _db.insertSongs(songs);
    return songs.length;
  }

  Future<List<File>> _collectAudioFiles(Directory dir) async {
    final files = <File>[];
    try {
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          final ext = path_lib.extension(entity.path).replaceAll('.', '').toLowerCase();
          if (AppConstants.supportedFormats.contains(ext)) {
            files.add(entity);
          }
        }
      }
    } catch (_) {}
    return files;
  }

  // ── Songs ──────────────────────────────────────────────────────────────────

  Future<List<SongModel>> getAllSongs({SortOrder sortOrder = SortOrder.titleAsc}) =>
      _db.getAllSongs(sortOrder: sortOrder);

  Future<SongModel?> getSongById(int id) => _db.getSongById(id);

  Future<List<SongModel>> searchSongs(String query) => _db.searchSongs(query);

  Future<List<SongModel>> getRecentlyPlayed({int limit = 20}) =>
      _db.getRecentlyPlayed(limit: limit);

  Future<List<SongModel>> getFavoriteSongs() => _db.getFavoriteSongs();

  Future<bool> isFavorite(int songId) => _db.isFavorite(songId);

  Future<List<SongModel>> getMostPlayed({int limit = 4}) =>
      _db.getMostPlayed(limit: limit);

  Future<List<SongModel>> getSongsByAlbum(String album) => _db.getSongsByAlbum(album);

  Future<List<SongModel>> getSongsByArtist(String artist) => _db.getSongsByArtist(artist);

  Future<void> markAsPlayed(int songId) => _db.markAsPlayed(songId);

  Future<void> toggleFavorite(int songId) => _db.toggleFavorite(songId);

  Future<int> getSongCount() => _db.getSongCount();

  // ── Library Groups ─────────────────────────────────────────────────────────

  Future<List<String>> getAlbums() => _db.getDistinctAlbums();

  Future<List<String>> getArtists() => _db.getDistinctArtists();

  Future<List<String>> getGenres() => _db.getDistinctGenres();

  // ── Playlists ──────────────────────────────────────────────────────────────

  Future<List<PlaylistModel>> getPlaylists() => _db.getAllPlaylists();

  Future<int> createPlaylist(String name, {String? description}) {
    final now = DateTime.now();
    return _db.createPlaylist(PlaylistModel(
      id: 0,
      name: name,
      description: description,
      createdAt: now,
      updatedAt: now,
    ));
  }

  Future<void> addSongToPlaylist(int playlistId, int songId) =>
      _db.addSongToPlaylist(playlistId, songId);

  Future<void> deletePlaylist(int playlistId) => _db.deletePlaylist(playlistId);

  Future<void> deleteSong(int songId) => _db.deleteSong(songId);

  Future<void> clearLibrary() => _db.clearAllSongs();

  Future<void> removeSongFromPlaylist(int playlistId, int songId) =>
      _db.removeSongFromPlaylist(playlistId, songId);

  // ── Playback URI resolution ────────────────────────────────────────────────

  /// Resuelve la mejor ruta/URI reproducible para una canción.
  /// Las rutas guardadas en SQLite pueden quedar obsoletas; MediaStore siempre
  /// devuelve el URI content:// válido en Android moderno.
  Future<SongModel> resolveForPlayback(SongModel song) async {
    if (PlatformConfig.isDesktop) {
      final path = song.filePath.trim().replaceFirst('file://', '');
      if (path.isNotEmpty && File(path).existsSync()) {
        return song;
      }
      return song;
    }

    final path = await _resolvePlayablePath(song);
    if (path == song.filePath) return song;
    return song.copyWith(filePath: path);
  }

  Future<List<SongModel>> resolveQueueForPlayback(List<SongModel> songs) async {
    return Future.wait(songs.map(resolveForPlayback));
  }

  Future<String> _resolvePlayablePath(SongModel song) async {
    final existing = song.filePath.trim();
    if (existing.startsWith('content://')) return existing;

    // IDs de MediaStore (enteros pequeños) — re-consultar URI fresco
    if (_isMediaStoreId(song.id)) {
      try {
        final fresh = await _findInMediaStore(byId: song.id);
        if (fresh != null) return fresh;
      } catch (_) {}
    }

    // Canciones de carpeta: buscar coincidencia por ruta en MediaStore
    if (existing.isNotEmpty) {
      try {
        final fresh = await _findInMediaStore(byPath: existing);
        if (fresh != null) return fresh;
      } catch (_) {}
    }

    return existing;
  }

  bool _isMediaStoreId(int id) => id > 0 && id < 1000000000;

  Future<String?> _findInMediaStore({int? byId, String? byPath}) async {
    final songs = await _audioQuery.querySongs(
      sortType: oaq.SongSortType.TITLE,
      orderType: oaq.OrderType.ASC_OR_SMALLER,
      uriType: oaq.UriType.EXTERNAL,
      ignoreCase: true,
    );

    for (final s in songs) {
      if (byId != null && s.id == byId) {
        return _bestUri(s);
      }
      if (byPath != null) {
        final normalized = byPath.replaceFirst('file://', '');
        if (s.data == byPath || s.data == normalized || s.uri == byPath) {
          return _bestUri(s);
        }
      }
    }
    return null;
  }

  String _bestUri(oaq.SongModel song) {
    final uri = song.uri?.trim();
    if (uri != null && uri.isNotEmpty && uri.startsWith('content://')) {
      return uri;
    }
    final data = song.data.trim();
    if (data.startsWith('content://')) return data;
    if (uri != null && uri.isNotEmpty) return uri;
    return data;
  }
}
