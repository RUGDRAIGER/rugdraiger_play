import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path_lib;
import '../../core/constants/app_constants.dart';
import '../models/song_model.dart';
import '../models/playlist_model.dart';

class DatabaseHelper {
  static DatabaseHelper? _instance;
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() {
    _instance ??= DatabaseHelper._internal();
    return _instance!;
  }

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final fullPath = path_lib.join(dbPath, AppConstants.dbName);

    return await openDatabase(
      fullPath,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE songs (
        id INTEGER PRIMARY KEY,
        title TEXT NOT NULL,
        artist TEXT,
        album TEXT,
        album_artist TEXT,
        genre TEXT,
        file_path TEXT NOT NULL UNIQUE,
        duration_ms INTEGER DEFAULT 0,
        file_size INTEGER DEFAULT 0,
        bitrate INTEGER DEFAULT 0,
        sample_rate INTEGER DEFAULT 0,
        year INTEGER DEFAULT 0,
        track_number INTEGER DEFAULT 0,
        format TEXT,
        is_lossless INTEGER DEFAULT 0,
        date_added INTEGER NOT NULL,
        play_count INTEGER DEFAULT 0,
        last_played INTEGER,
        is_favorite INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE playlists (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        cover_path TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE playlist_songs (
        playlist_id INTEGER NOT NULL,
        song_id INTEGER NOT NULL,
        position INTEGER NOT NULL,
        PRIMARY KEY (playlist_id, song_id),
        FOREIGN KEY (playlist_id) REFERENCES playlists(id) ON DELETE CASCADE,
        FOREIGN KEY (song_id) REFERENCES songs(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE recently_played (
        song_id INTEGER NOT NULL,
        played_at INTEGER NOT NULL,
        PRIMARY KEY (song_id),
        FOREIGN KEY (song_id) REFERENCES songs(id) ON DELETE CASCADE
      )
    ''');

    // Indexes for fast lookup
    await db.execute('CREATE INDEX idx_songs_artist ON songs(artist)');
    await db.execute('CREATE INDEX idx_songs_album ON songs(album)');
    await db.execute('CREATE INDEX idx_songs_genre ON songs(genre)');
    await db.execute('CREATE INDEX idx_songs_title ON songs(title)');
    await db.execute('CREATE INDEX idx_recently_played ON recently_played(played_at DESC)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Future migration support
  }

  // ── Songs ──────────────────────────────────────────────────────────────────

  Future<int> insertSong(SongModel song) async {
    final db = await database;
    return await db.insert(
      'songs',
      song.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertSongs(List<SongModel> songs) async {
    final db = await database;
    final batch = db.batch();
    for (final song in songs) {
      batch.insert('songs', song.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<SongModel>> getAllSongs({
    SortOrder sortOrder = SortOrder.titleAsc,
  }) async {
    final db = await database;
    final orderBy = _sortOrderToSql(sortOrder);
    final maps = await db.query('songs', orderBy: orderBy);
    return maps.map(SongModel.fromMap).toList();
  }

  Future<SongModel?> getSongById(int id) async {
    final db = await database;
    final maps = await db.query('songs', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return SongModel.fromMap(maps.first);
  }

  Future<List<SongModel>> searchSongs(String query) async {
    final db = await database;
    final likeQuery = '%$query%';
    final maps = await db.query(
      'songs',
      where: 'title LIKE ? OR artist LIKE ? OR album LIKE ?',
      whereArgs: [likeQuery, likeQuery, likeQuery],
      limit: 50,
    );
    return maps.map(SongModel.fromMap).toList();
  }

  Future<List<String>> getDistinctAlbums() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT DISTINCT album FROM songs WHERE album IS NOT NULL ORDER BY album ASC',
    );
    return result.map((r) => r['album'] as String).toList();
  }

  Future<List<String>> getDistinctArtists() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT DISTINCT artist FROM songs WHERE artist IS NOT NULL ORDER BY artist ASC',
    );
    return result.map((r) => r['artist'] as String).toList();
  }

  Future<List<String>> getDistinctGenres() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT DISTINCT genre FROM songs WHERE genre IS NOT NULL AND genre != "" ORDER BY genre ASC',
    );
    return result.map((r) => r['genre'] as String).toList();
  }

  Future<List<SongModel>> getSongsByAlbum(String album) async {
    final db = await database;
    final maps = await db.query(
      'songs',
      where: 'album = ?',
      whereArgs: [album],
      orderBy: 'track_number ASC, title ASC',
    );
    return maps.map(SongModel.fromMap).toList();
  }

  Future<List<SongModel>> getSongsByArtist(String artist) async {
    final db = await database;
    final maps = await db.query(
      'songs',
      where: 'artist = ?',
      whereArgs: [artist],
      orderBy: 'album ASC, track_number ASC',
    );
    return maps.map(SongModel.fromMap).toList();
  }

  Future<List<SongModel>> getFavoriteSongs() async {
    final db = await database;
    final maps = await db.query(
      'songs',
      where: 'is_favorite = 1',
      orderBy: 'title ASC',
    );
    return maps.map(SongModel.fromMap).toList();
  }

  Future<bool> isFavorite(int songId) async {
    final db = await database;
    final maps = await db.query(
      'songs',
      columns: ['is_favorite'],
      where: 'id = ?',
      whereArgs: [songId],
      limit: 1,
    );
    if (maps.isEmpty) return false;
    return (maps.first['is_favorite'] as int? ?? 0) == 1;
  }

  Future<List<SongModel>> getMostPlayed({int limit = 4}) async {
    final db = await database;
    final maps = await db.query(
      'songs',
      where: 'play_count > 0',
      orderBy: 'play_count DESC, last_played DESC',
      limit: limit,
    );
    return maps.map(SongModel.fromMap).toList();
  }

  Future<List<SongModel>> getRecentlyPlayed({int limit = 20}) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT s.* FROM songs s
      INNER JOIN recently_played rp ON s.id = rp.song_id
      ORDER BY rp.played_at DESC
      LIMIT ?
    ''', [limit]);
    return maps.map(SongModel.fromMap).toList();
  }

  Future<void> markAsPlayed(int songId) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert(
      'recently_played',
      {'song_id': songId, 'played_at': now},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await db.rawUpdate(
      'UPDATE songs SET play_count = play_count + 1, last_played = ? WHERE id = ?',
      [now, songId],
    );
  }

  Future<void> toggleFavorite(int songId) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE songs SET is_favorite = CASE WHEN is_favorite = 1 THEN 0 ELSE 1 END WHERE id = ?',
      [songId],
    );
  }

  Future<int> getSongCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM songs');
    return result.first['count'] as int;
  }

  Future<void> clearAllSongs() async {
    final db = await database;
    await db.delete('playlist_songs');
    await db.delete('recently_played');
    await db.delete('songs');
  }

  // ── Playlists ──────────────────────────────────────────────────────────────

  Future<int> createPlaylist(PlaylistModel playlist) async {
    final db = await database;
    return await db.insert('playlists', playlist.toMap());
  }

  Future<List<PlaylistModel>> getAllPlaylists() async {
    final db = await database;
    final maps = await db.query('playlists', orderBy: 'name ASC');
    final playlists = <PlaylistModel>[];

    for (final map in maps) {
      final songMaps = await db.query(
        'playlist_songs',
        where: 'playlist_id = ?',
        whereArgs: [map['id']],
        orderBy: 'position ASC',
      );
      final songIds = songMaps.map((s) => s['song_id'] as int).toList();
      playlists.add(PlaylistModel.fromMap(map).copyWith(songIds: songIds));
    }

    return playlists;
  }

  Future<void> addSongToPlaylist(int playlistId, int songId) async {
    final db = await database;
    final count = await db.rawQuery(
      'SELECT COUNT(*) as c FROM playlist_songs WHERE playlist_id = ?',
      [playlistId],
    );
    final position = (count.first['c'] as int);

    await db.insert('playlist_songs', {
      'playlist_id': playlistId,
      'song_id': songId,
      'position': position,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    await db.update(
      'playlists',
      {'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [playlistId],
    );
  }

  Future<void> deletePlaylist(int playlistId) async {
    final db = await database;
    await db.delete('playlists', where: 'id = ?', whereArgs: [playlistId]);
    await db.delete('playlist_songs', where: 'playlist_id = ?', whereArgs: [playlistId]);
  }

  Future<void> removeSongFromPlaylist(int playlistId, int songId) async {
    final db = await database;
    await db.delete(
      'playlist_songs',
      where: 'playlist_id = ? AND song_id = ?',
      whereArgs: [playlistId, songId],
    );
  }

  Future<void> deleteSong(int songId) async {
    final db = await database;
    await db.delete('songs', where: 'id = ?', whereArgs: [songId]);
    await db.delete('playlist_songs', where: 'song_id = ?', whereArgs: [songId]);
    await db.delete('recently_played', where: 'song_id = ?', whereArgs: [songId]);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _sortOrderToSql(SortOrder order) {
    switch (order) {
      case SortOrder.titleAsc:   return 'title ASC';
      case SortOrder.titleDesc:  return 'title DESC';
      case SortOrder.artistAsc:  return 'artist ASC, title ASC';
      case SortOrder.dateAdded:  return 'date_added DESC';
      case SortOrder.duration:   return 'duration_ms DESC';
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
