import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/song_model.dart';
import '../../../data/models/playlist_model.dart';
import '../../../data/repositories/music_repository.dart';
import '../../../services/artwork_cache.dart';
import '../../../core/constants/app_constants.dart';

// Events
abstract class LibraryEvent {
  const LibraryEvent();
}

class LoadLibraryEvent extends LibraryEvent {
  const LoadLibraryEvent();
}

class ScanLibraryEvent extends LibraryEvent {
  const ScanLibraryEvent();
}

class SearchSongsEvent extends LibraryEvent {
  final String query;
  const SearchSongsEvent(this.query);
}

class ClearSearchEvent extends LibraryEvent {
  const ClearSearchEvent();
}

class SetSortOrderEvent extends LibraryEvent {
  final SortOrder sortOrder;
  const SetSortOrderEvent(this.sortOrder);
}

class LoadAlbumSongsEvent extends LibraryEvent {
  final String album;
  const LoadAlbumSongsEvent(this.album);
}

class LoadArtistSongsEvent extends LibraryEvent {
  final String artist;
  const LoadArtistSongsEvent(this.artist);
}

class CreatePlaylistEvent extends LibraryEvent {
  final String name;
  final String? description;
  const CreatePlaylistEvent(this.name, {this.description});
}

class AddSongToPlaylistEvent extends LibraryEvent {
  final int playlistId;
  final int songId;
  const AddSongToPlaylistEvent(this.playlistId, this.songId);
}

class DeletePlaylistEvent extends LibraryEvent {
  final int playlistId;
  const DeletePlaylistEvent(this.playlistId);
}

class ScanFolderEvent extends LibraryEvent {
  final String folderPath;
  const ScanFolderEvent(this.folderPath);
}

class DeleteSongEvent extends LibraryEvent {
  final int songId;
  const DeleteSongEvent(this.songId);
}

class RemoveSongFromPlaylistEvent extends LibraryEvent {
  final int playlistId;
  final int songId;
  const RemoveSongFromPlaylistEvent(this.playlistId, this.songId);
}

class ClearLibraryEvent extends LibraryEvent {
  const ClearLibraryEvent();
}

class LoadFavoritesEvent extends LibraryEvent {
  const LoadFavoritesEvent();
}

class ToggleFavoriteEvent extends LibraryEvent {
  final int songId;
  const ToggleFavoriteEvent(this.songId);
}

class UpdateSongMetadataEvent extends LibraryEvent {
  final int songId;
  final String? title;
  final String? artist;
  final String? album;
  final String? genre;
  final int? year;
  const UpdateSongMetadataEvent(
    this.songId, {
    this.title,
    this.artist,
    this.album,
    this.genre,
    this.year,
  });
}

class RefreshPlayStatsEvent extends LibraryEvent {
  const RefreshPlayStatsEvent();
}

// State
enum LibraryStatus { initial, loading, scanning, loaded, error }

class LibraryBlocState {
  final LibraryStatus status;
  final List<SongModel> songs;
  final List<SongModel> searchResults;
  final List<SongModel> recentlyPlayed;
  final List<SongModel> mostPlayed;
  final List<SongModel> mostPlayedThisMonth;
  final List<SongModel> recentlyAdded;
  final List<SongModel> favorites;
  final List<String> albums;
  final List<String> artists;
  final List<String> genres;
  final List<PlaylistModel> playlists;
  final String? searchQuery;
  final SortOrder sortOrder;
  final String? errorMessage;
  final int scannedCount;

  const LibraryBlocState({
    this.status = LibraryStatus.initial,
    this.songs = const [],
    this.searchResults = const [],
    this.recentlyPlayed = const [],
    this.mostPlayed = const [],
    this.mostPlayedThisMonth = const [],
    this.recentlyAdded = const [],
    this.favorites = const [],
    this.albums = const [],
    this.artists = const [],
    this.genres = const [],
    this.playlists = const [],
    this.searchQuery,
    this.sortOrder = SortOrder.titleAsc,
    this.errorMessage,
    this.scannedCount = 0,
  });

  bool get isSearching => searchQuery != null && searchQuery!.isNotEmpty;

  bool isFavorite(int songId) => favorites.any((s) => s.id == songId);

  LibraryBlocState copyWith({
    LibraryStatus? status,
    List<SongModel>? songs,
    List<SongModel>? searchResults,
    List<SongModel>? recentlyPlayed,
    List<SongModel>? mostPlayed,
    List<SongModel>? mostPlayedThisMonth,
    List<SongModel>? recentlyAdded,
    List<SongModel>? favorites,
    List<String>? albums,
    List<String>? artists,
    List<String>? genres,
    List<PlaylistModel>? playlists,
    String? searchQuery,
    SortOrder? sortOrder,
    String? errorMessage,
    int? scannedCount,
  }) {
    return LibraryBlocState(
      status: status ?? this.status,
      songs: songs ?? this.songs,
      searchResults: searchResults ?? this.searchResults,
      recentlyPlayed: recentlyPlayed ?? this.recentlyPlayed,
      mostPlayed: mostPlayed ?? this.mostPlayed,
      mostPlayedThisMonth: mostPlayedThisMonth ?? this.mostPlayedThisMonth,
      recentlyAdded: recentlyAdded ?? this.recentlyAdded,
      favorites: favorites ?? this.favorites,
      albums: albums ?? this.albums,
      artists: artists ?? this.artists,
      genres: genres ?? this.genres,
      playlists: playlists ?? this.playlists,
      searchQuery: searchQuery ?? this.searchQuery,
      sortOrder: sortOrder ?? this.sortOrder,
      errorMessage: errorMessage ?? this.errorMessage,
      scannedCount: scannedCount ?? this.scannedCount,
    );
  }
}

// BLoC
class LibraryBloc extends Bloc<LibraryEvent, LibraryBlocState> {
  final MusicRepository _repository;

  LibraryBloc({required MusicRepository repository})
      : _repository = repository,
        super(const LibraryBlocState()) {
    on<LoadLibraryEvent>(_onLoadLibrary);
    on<ScanLibraryEvent>(_onScanLibrary);
    on<SearchSongsEvent>(_onSearchSongs);
    on<ClearSearchEvent>(_onClearSearch);
    on<SetSortOrderEvent>(_onSetSortOrder);
    on<CreatePlaylistEvent>(_onCreatePlaylist);
    on<AddSongToPlaylistEvent>(_onAddSongToPlaylist);
    on<DeletePlaylistEvent>(_onDeletePlaylist);
    on<ScanFolderEvent>(_onScanFolder);
    on<DeleteSongEvent>(_onDeleteSong);
    on<RemoveSongFromPlaylistEvent>(_onRemoveSongFromPlaylist);
    on<LoadFavoritesEvent>(_onLoadFavorites);
    on<ToggleFavoriteEvent>(_onToggleFavorite);
    on<RefreshPlayStatsEvent>(_onRefreshPlayStats);
    on<UpdateSongMetadataEvent>(_onUpdateSongMetadata);
    on<ClearLibraryEvent>(_onClearLibrary);
  }

  Future<void> _onLoadLibrary(LoadLibraryEvent event, Emitter emit) async {
    emit(state.copyWith(status: LibraryStatus.loading));
    try {
      final results = await Future.wait([
        _repository.getAllSongs(sortOrder: state.sortOrder),
        _repository.getRecentlyPlayed(),
        _repository.getMostPlayedThisMonth(limit: 4),
        _repository.getRecentlyAdded(limit: 8),
        _repository.getAlbums(),
        _repository.getArtists(),
        _repository.getGenres(),
        _repository.getPlaylists(),
        _repository.getFavoriteSongs(),
      ]);

      emit(state.copyWith(
        status: LibraryStatus.loaded,
        songs: results[0] as List<SongModel>,
        recentlyPlayed: results[1] as List<SongModel>,
        mostPlayedThisMonth: results[2] as List<SongModel>,
        mostPlayed: results[2] as List<SongModel>,
        recentlyAdded: results[3] as List<SongModel>,
        albums: results[4] as List<String>,
        artists: results[5] as List<String>,
        genres: results[6] as List<String>,
        playlists: results[7] as List<PlaylistModel>,
        favorites: results[8] as List<SongModel>,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: LibraryStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onScanLibrary(ScanLibraryEvent event, Emitter emit) async {
    emit(state.copyWith(status: LibraryStatus.scanning, errorMessage: null));
    try {
      final count = await _repository.scanAndIndexLibrary();
      emit(state.copyWith(scannedCount: count));
      add(const LoadLibraryEvent());
    } catch (e) {
      emit(state.copyWith(
        status: LibraryStatus.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onSearchSongs(SearchSongsEvent event, Emitter emit) async {
    if (event.query.isEmpty) {
      emit(state.copyWith(searchQuery: '', searchResults: []));
      return;
    }
    try {
      final results = await _repository.searchSongs(event.query);
      emit(state.copyWith(
        searchQuery: event.query,
        searchResults: results,
      ));
    } catch (_) {}
  }

  Future<void> _onClearSearch(ClearSearchEvent event, Emitter emit) async {
    emit(state.copyWith(searchQuery: '', searchResults: []));
  }

  Future<void> _onSetSortOrder(SetSortOrderEvent event, Emitter emit) async {
    emit(state.copyWith(sortOrder: event.sortOrder));
    add(const LoadLibraryEvent());
  }

  Future<void> _onCreatePlaylist(CreatePlaylistEvent event, Emitter emit) async {
    await _repository.createPlaylist(event.name, description: event.description);
    final playlists = await _repository.getPlaylists();
    emit(state.copyWith(playlists: playlists));
  }

  Future<void> _onAddSongToPlaylist(AddSongToPlaylistEvent event, Emitter emit) async {
    await _repository.addSongToPlaylist(event.playlistId, event.songId);
    final playlists = await _repository.getPlaylists();
    emit(state.copyWith(playlists: playlists));
  }

  Future<void> _onDeletePlaylist(DeletePlaylistEvent event, Emitter emit) async {
    await _repository.deletePlaylist(event.playlistId);
    final playlists = await _repository.getPlaylists();
    emit(state.copyWith(playlists: playlists));
  }

  Future<void> _onScanFolder(ScanFolderEvent event, Emitter emit) async {
    emit(state.copyWith(status: LibraryStatus.scanning));
    try {
      final count = await _repository.scanDirectory(event.folderPath);
      emit(state.copyWith(scannedCount: count));
      add(const LoadLibraryEvent());
    } catch (e) {
      emit(state.copyWith(status: LibraryStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onDeleteSong(DeleteSongEvent event, Emitter emit) async {
    await _repository.deleteSong(event.songId);
    add(const LoadLibraryEvent());
  }

  Future<void> _onRemoveSongFromPlaylist(RemoveSongFromPlaylistEvent event, Emitter emit) async {
    await _repository.removeSongFromPlaylist(event.playlistId, event.songId);
    final playlists = await _repository.getPlaylists();
    emit(state.copyWith(playlists: playlists));
  }

  Future<void> _onLoadFavorites(LoadFavoritesEvent event, Emitter emit) async {
    final favorites = await _repository.getFavoriteSongs();
    emit(state.copyWith(favorites: favorites));
  }

  Future<void> _onToggleFavorite(ToggleFavoriteEvent event, Emitter emit) async {
    await _repository.toggleFavorite(event.songId);
    final favorites = await _repository.getFavoriteSongs();
    final favoriteIds = favorites.map((s) => s.id).toSet();
    final songs = state.songs
        .map((s) => s.copyWith(isFavorite: favoriteIds.contains(s.id)))
        .toList();
    emit(state.copyWith(favorites: favorites, songs: songs));
  }

  Future<void> _onRefreshPlayStats(RefreshPlayStatsEvent event, Emitter emit) async {
    final recent = await _repository.getRecentlyPlayed();
    final most = await _repository.getMostPlayedThisMonth(limit: 4);
    emit(state.copyWith(
      recentlyPlayed: recent,
      mostPlayed: most,
      mostPlayedThisMonth: most,
    ));
  }

  Future<void> _onUpdateSongMetadata(UpdateSongMetadataEvent event, Emitter emit) async {
    await _repository.updateSongMetadata(
      event.songId,
      title: event.title,
      artist: event.artist,
      album: event.album,
      genre: event.genre,
      year: event.year,
    );
    add(const LoadLibraryEvent());
  }

  Future<void> _onClearLibrary(ClearLibraryEvent event, Emitter emit) async {
    emit(state.copyWith(status: LibraryStatus.loading));
    try {
      await _repository.clearLibrary();
      ArtworkCache.clear();
      emit(const LibraryBlocState(status: LibraryStatus.loaded));
    } catch (e) {
      emit(state.copyWith(
        status: LibraryStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
}
