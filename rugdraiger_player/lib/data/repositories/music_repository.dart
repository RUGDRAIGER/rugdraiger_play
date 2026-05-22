import 'dart:io';
import 'package:on_audio_query/on_audio_query.dart' as oaq;
import 'package:path/path.dart' as path_lib;
import '../../core/constants/app_constants.dart';
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

      final models = supported.map(_fromOaqSong).toList();
      await _db.insertSongs(models);
      return models.length;
    } catch (_) {
      return 0;
    }
  }

  SongModel _fromOaqSong(oaq.SongModel song) {
    final ext = song.fileExtension.toLowerCase();
    final isLossless = AppConstants.losslessFormats.contains(ext);
    final format = AudioFormat.values.firstWhere(
      (f) => f.name == ext,
      orElse: () => AudioFormat.unknown,
    );

    return SongModel(
      id: song.id,
      title: song.title,
      artist: song.artist ?? 'Unknown Artist',
      album: song.album ?? 'Unknown Album',
      genre: song.genre ?? '',
      filePath: song.data,
      durationMs: song.duration ?? 0,
      fileSize: song.size,
      trackNumber: song.track ?? 0,
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
      songs.add(SongModel(
        id: id++,
        title: name,
        artist: 'Unknown Artist',
        album: 'Unknown Album',
        filePath: file.path,
        durationMs: 0,
        fileSize: await file.length(),
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
}
