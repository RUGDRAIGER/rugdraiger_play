import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:rxdart/rxdart.dart';
import '../core/constants/app_constants.dart';
import '../data/models/song_model.dart';
import 'artwork_media_uri.dart';
import 'stop_after_service.dart';
import 'widget_bridge.dart';

class PlayerState {
  final SongModel? currentSong;
  final bool isPlaying;
  final bool isBuffering;
  final Duration position;
  final Duration duration;
  final RepeatMode repeatMode;
  final bool shuffleEnabled;
  final double volume;
  final bool isMuted;
  final List<SongModel> queue;
  final int currentIndex;
  final String? errorMessage;

  const PlayerState({
    this.currentSong,
    this.isPlaying = false,
    this.isBuffering = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.repeatMode = RepeatMode.none,
    this.shuffleEnabled = false,
    this.volume = 1.0,
    this.isMuted = false,
    this.queue = const [],
    this.currentIndex = 0,
    this.errorMessage,
  });

  double get progress {
    if (duration.inMilliseconds == 0) return 0.0;
    return position.inMilliseconds / duration.inMilliseconds;
  }

  double get effectiveVolume => isMuted ? 0.0 : volume;

  PlayerState copyWith({
    SongModel? currentSong,
    bool? isPlaying,
    bool? isBuffering,
    Duration? position,
    Duration? duration,
    RepeatMode? repeatMode,
    bool? shuffleEnabled,
    double? volume,
    bool? isMuted,
    List<SongModel>? queue,
    int? currentIndex,
    String? errorMessage,
    bool clearError = false,
    bool clearSong = false,
  }) {
    return PlayerState(
      currentSong: clearSong ? null : (currentSong ?? this.currentSong),
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      repeatMode: repeatMode ?? this.repeatMode,
      shuffleEnabled: shuffleEnabled ?? this.shuffleEnabled,
      volume: volume ?? this.volume,
      isMuted: isMuted ?? this.isMuted,
      queue: clearSong ? const [] : (queue ?? this.queue),
      currentIndex: currentIndex ?? this.currentIndex,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AudioPlayerService {
  static AudioPlayerService? _instance;
  static bool backgroundEnabled = false;

  AudioPlayer? _player;
  bool _listenersReady = false;

  final _stateController = BehaviorSubject<PlayerState>.seeded(const PlayerState());

  Stream<PlayerState> get stateStream => _stateController.stream;
  PlayerState get currentState => _stateController.value;

  AudioPlayerService._internal();

  factory AudioPlayerService() {
    _instance ??= AudioPlayerService._internal();
    return _instance!;
  }

  AudioPlayer get _activePlayer {
    _player ??= AudioPlayer();
    if (!_listenersReady) {
      _initListeners();
      _listenersReady = true;
    }
    return _player!;
  }

  void _initListeners() {
    final player = _player!;

    player.playingStream.listen((playing) {
      _updateState((s) => s.copyWith(isPlaying: playing, clearError: true));
    });

    player.playerStateStream.listen((state) {
      final isBuffering = state.processingState == ProcessingState.loading ||
          state.processingState == ProcessingState.buffering;
      _updateState((s) => s.copyWith(isBuffering: isBuffering));
    });

    player.positionStream.listen((position) {
      _updateState((s) => s.copyWith(position: position));
    });

    player.durationStream.listen((duration) {
      if (duration != null && duration.inMilliseconds > 0) {
        _updateState((s) => s.copyWith(duration: duration));
      }
    });

    player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        unawaited(_handleCompletion());
      }
    });

    player.currentIndexStream.listen((index) {
      if (index != null) {
        final prev = currentState;
        if (prev.currentSong != null &&
            index > prev.currentIndex &&
            StopAfterService.instance.consumeIfEnabled(prev.currentSong!.id)) {
          unawaited(_pauseAtIndex(prev.currentIndex, prev.currentSong!));
          return;
        }
        if (prev.repeatMode == RepeatMode.none &&
            prev.queue.isNotEmpty &&
            prev.currentIndex >= prev.queue.length - 1 &&
            index == 0 &&
            prev.queue.length > 1) {
          unawaited(_stopAtQueueEnd());
          return;
        }
        _updateState((s) {
          if (index < s.queue.length) {
            return s.copyWith(
              currentIndex: index,
              currentSong: s.queue[index],
            );
          }
          return s;
        });
      }
    });
  }

  Future<void> _stopAtQueueEnd() async {
    final state = currentState;
    if (state.queue.isEmpty) return;
    final lastIndex = state.queue.length - 1;
    await _activePlayer.pause();
    await _activePlayer.seek(Duration.zero, index: lastIndex);
    final dur = _activePlayer.duration ?? state.duration;
    if (dur.inMilliseconds > 0) {
      await _activePlayer.seek(dur, index: lastIndex);
    }
    _updateState((s) => s.copyWith(
      isPlaying: false,
      currentIndex: lastIndex,
      currentSong: s.queue[lastIndex],
      position: dur.inMilliseconds > 0 ? dur : s.position,
      duration: dur.inMilliseconds > 0 ? dur : s.duration,
    ));
  }

  Future<void> _ensureSessionActive() async {
    try {
      final session = await AudioSession.instance;
      await session.setActive(true);
    } catch (e) {
      debugPrint('AudioSession.setActive failed: $e');
    }
  }

  List<Uri> _urisForSong(SongModel song) {
    final path = song.filePath.trim();
    final uris = <Uri>{};

    if (path.startsWith('content://')) {
      uris.add(Uri.parse(path));
    } else if (path.startsWith('file://')) {
      uris.add(Uri.parse(path));
      try {
        uris.add(Uri.file(Uri.parse(path).toFilePath()));
      } catch (_) {}
    } else if (path.isNotEmpty) {
      uris.add(Uri.file(path));
      uris.add(Uri.parse('file://$path'));
    }

    return uris.toList();
  }

  Future<MediaItem> _mediaItemFor(SongModel song) async {
    final meta = ArtworkMediaUri.displayMeta(song);
    final artUri = await ArtworkMediaUri.resolve(song);
    return MediaItem(
      id: song.id.toString(),
      title: meta.title,
      artist: meta.artist,
      album: meta.album,
      displayTitle: meta.title,
      displaySubtitle: meta.artist,
      displayDescription: meta.album,
      duration: song.durationMs > 0
          ? Duration(milliseconds: song.durationMs)
          : null,
      artUri: artUri,
    );
  }

  Future<AudioSource> _sourceForSong(SongModel song, {required bool withBackgroundTag}) async {
    final uri = _urisForSong(song).first;
    if (withBackgroundTag) {
      final tag = await _mediaItemFor(song);
      return AudioSource.uri(uri, tag: tag);
    }
    return AudioSource.uri(uri);
  }

  AudioSource _sourceForUri(Uri uri, SongModel song, {required bool withBackgroundTag}) {
    if (withBackgroundTag) {
      final meta = ArtworkMediaUri.displayMeta(song);
      return AudioSource.uri(
        uri,
        tag: MediaItem(
          id: song.id.toString(),
          title: meta.title,
          artist: meta.artist,
          album: meta.album,
          displayTitle: meta.title,
          displaySubtitle: meta.artist,
          duration: song.durationMs > 0
              ? Duration(milliseconds: song.durationMs)
              : null,
        ),
      );
    }
    return AudioSource.uri(uri);
  }

  Future<void> _setSourceWithFallback(
    AudioPlayer player,
    SongModel song,
    List<SongModel> playQueue,
    int safeIndex,
  ) async {
    final targetSong = playQueue[safeIndex];
    final uris = _urisForSong(targetSong);
    Object? lastError;

    // Intento 1: playlist completa con tags (background)
    if (backgroundEnabled) {
      try {
        final sources = <AudioSource>[];
        for (final s in playQueue) {
          sources.add(await _sourceForSong(s, withBackgroundTag: true));
        }
        await player.setAudioSource(
          ConcatenatingAudioSource(children: sources),
          initialIndex: safeIndex,
          preload: true,
        );
        return;
      } catch (e) {
        lastError = e;
        debugPrint('Playback with background tags failed: $e');
      }
    }

    // Intento 2: playlist sin tags
    try {
      final sources = playQueue.map((s) {
        final songUris = _urisForSong(s);
        return _sourceForUri(songUris.first, s, withBackgroundTag: false);
      }).toList();
      await player.setAudioSource(
        ConcatenatingAudioSource(children: sources),
        initialIndex: safeIndex,
        preload: true,
      );
      return;
    } catch (e) {
      lastError = e;
      debugPrint('Playback playlist failed: $e');
    }

    // Intento 3: solo la canción actual, probando cada URI
    for (final uri in uris) {
      try {
        await player.setAudioSource(
          _sourceForUri(uri, targetSong, withBackgroundTag: false),
          preload: true,
        );
        return;
      } catch (e) {
        lastError = e;
        debugPrint('Playback URI failed ($uri): $e');
      }
    }

    throw Exception('No se pudo abrir el audio: ${targetSong.title}\n${lastError ?? ''}');
  }

  Future<void> playSong(SongModel song, {List<SongModel>? queue, int? index}) async {
    final playQueue = queue ?? [song];
    final playIndex = index ?? playQueue.indexWhere((s) => s.id == song.id);
    final safeIndex = playIndex >= 0 ? playIndex : 0;

    await _ensureSessionActive();

    final player = _activePlayer;
    await player.setShuffleModeEnabled(false);

    await _setSourceWithFallback(player, song, playQueue, safeIndex);

    await setRepeatMode(currentState.repeatMode);

    final vol = currentState.effectiveVolume;
    await player.setVolume(vol);

    _updateState((s) => s.copyWith(
      currentSong: playQueue[safeIndex],
      queue: playQueue,
      currentIndex: safeIndex,
      position: Duration.zero,
      clearError: true,
    ));

    try {
      await player.play();
    } catch (e) {
      _updateState((s) => s.copyWith(
        errorMessage: 'Error al reproducir: ${playQueue[safeIndex].title}',
      ));
      rethrow;
    }
  }

  Future<void> play() async {
    await _ensureSessionActive();
    await _activePlayer.play();
  }

  Future<void> pause() async => _activePlayer.pause();

  Future<void> togglePlayPause() async {
    final player = _activePlayer;
    if (player.playing) {
      await player.pause();
    } else {
      await _ensureSessionActive();
      await player.play();
    }
  }

  Future<void> seekTo(Duration position) async => _activePlayer.seek(position);

  Future<void> seekToProgress(double progress) async {
    final duration = currentState.duration;
    await seekTo(Duration(milliseconds: (duration.inMilliseconds * progress).round()));
  }

  Future<void> skipToNext() async {
    final state = currentState;
    if (state.queue.isEmpty) return;

    if (state.repeatMode == RepeatMode.none && state.currentIndex >= state.queue.length - 1) {
      return;
    }

    final nextIndex = state.repeatMode == RepeatMode.all
        ? (state.currentIndex + 1) % state.queue.length
        : state.currentIndex + 1;

    if (nextIndex >= state.queue.length) return;

    await _activePlayer.seek(Duration.zero, index: nextIndex);
    if (!_activePlayer.playing) await play();
  }

  Future<void> skipToPrevious() async {
    final state = currentState;
    if (state.queue.isEmpty) return;
    if (state.position.inSeconds > 3) {
      await _activePlayer.seek(Duration.zero);
      return;
    }
    if (state.repeatMode == RepeatMode.none && state.currentIndex <= 0) {
      await _activePlayer.seek(Duration.zero);
      return;
    }
    final prevIndex = state.repeatMode == RepeatMode.all
        ? (state.currentIndex - 1 + state.queue.length) % state.queue.length
        : state.currentIndex - 1;
    if (prevIndex < 0) {
      await _activePlayer.seek(Duration.zero);
      return;
    }
    await _activePlayer.seek(Duration.zero, index: prevIndex);
    if (!_activePlayer.playing) await play();
  }

  Future<void> stop() async {
    await _activePlayer.stop();
    _updateState((_) => const PlayerState());
  }

  Future<void> setQueue(List<SongModel> songs, {int startIndex = 0}) async {
    if (songs.isEmpty) return;
    await playSong(songs[startIndex], queue: songs, index: startIndex);
  }

  void addToQueue(SongModel song) {
    _updateState((s) => s.copyWith(queue: [...s.queue, song]));
  }

  Future<void> setRepeatMode(RepeatMode mode) async {
    LoopMode loopMode;
    switch (mode) {
      case RepeatMode.none:
        loopMode = LoopMode.off;
        break;
      case RepeatMode.all:
        loopMode = LoopMode.all;
        break;
      case RepeatMode.one:
        loopMode = LoopMode.one;
        break;
    }
    await _activePlayer.setLoopMode(loopMode);
    _updateState((s) => s.copyWith(repeatMode: mode));
  }

  Future<void> toggleShuffle() async {
    final enabled = !currentState.shuffleEnabled;
    await _activePlayer.setShuffleModeEnabled(enabled);
    _updateState((s) => s.copyWith(shuffleEnabled: enabled));
  }

  Future<void> setVolume(double volume) async {
    final v = volume.clamp(0.0, 1.0);
    await _activePlayer.setVolume(currentState.isMuted ? 0.0 : v);
    _updateState((s) => s.copyWith(volume: v, isMuted: false));
  }

  Future<void> toggleMute() async {
    final muted = !currentState.isMuted;
    await _activePlayer.setVolume(muted ? 0.0 : currentState.volume);
    _updateState((s) => s.copyWith(isMuted: muted));
  }

  Future<void> _pauseAtIndex(int index, SongModel song) async {
    await _activePlayer.seek(Duration.zero, index: index);
    await pause();
    _updateState((s) => s.copyWith(currentIndex: index, currentSong: song));
  }

  Future<void> _handleCompletion() async {
    final state = currentState;
    if (StopAfterService.instance.consumeIfEnabled(state.currentSong?.id)) {
      await pause();
      await seekTo(Duration.zero);
      return;
    }
    if (state.repeatMode == RepeatMode.one || state.repeatMode == RepeatMode.all) {
      return;
    }
    if (state.queue.isEmpty) return;
    if (state.currentIndex >= state.queue.length - 1) {
      await _stopAtQueueEnd();
    }
  }

  void _updateState(PlayerState Function(PlayerState) updater) {
    final next = updater(_stateController.value);
    _stateController.add(next);
    WidgetBridge.sync(next);
  }

  Future<void> dispose() async {
    await _player?.dispose();
    await _stateController.close();
    _instance = null;
  }
}
