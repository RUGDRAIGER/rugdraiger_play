import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:rxdart/rxdart.dart';
import '../core/constants/app_constants.dart';
import '../data/models/song_model.dart';

class PlayerState {
  final SongModel? currentSong;
  final bool isPlaying;
  final bool isBuffering;
  final Duration position;
  final Duration duration;
  final RepeatMode repeatMode;
  final bool shuffleEnabled;
  final double volume;
  final List<SongModel> queue;
  final int currentIndex;

  const PlayerState({
    this.currentSong,
    this.isPlaying = false,
    this.isBuffering = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.repeatMode = RepeatMode.none,
    this.shuffleEnabled = false,
    this.volume = 1.0,
    this.queue = const [],
    this.currentIndex = 0,
  });

  double get progress {
    if (duration.inMilliseconds == 0) return 0.0;
    return position.inMilliseconds / duration.inMilliseconds;
  }

  PlayerState copyWith({
    SongModel? currentSong,
    bool? isPlaying,
    bool? isBuffering,
    Duration? position,
    Duration? duration,
    RepeatMode? repeatMode,
    bool? shuffleEnabled,
    double? volume,
    List<SongModel>? queue,
    int? currentIndex,
  }) {
    return PlayerState(
      currentSong: currentSong ?? this.currentSong,
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      repeatMode: repeatMode ?? this.repeatMode,
      shuffleEnabled: shuffleEnabled ?? this.shuffleEnabled,
      volume: volume ?? this.volume,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }
}

class AudioPlayerService {
  static AudioPlayerService? _instance;
  late final AudioPlayer _player;

  final _stateController = BehaviorSubject<PlayerState>.seeded(const PlayerState());

  Stream<PlayerState> get stateStream => _stateController.stream;
  PlayerState get currentState => _stateController.value;

  AudioPlayerService._internal() {
    _player = AudioPlayer();
    _initListeners();
  }

  factory AudioPlayerService() {
    _instance ??= AudioPlayerService._internal();
    return _instance!;
  }

  void _initListeners() {
    // Playing state changes
    _player.playingStream.listen((playing) {
      _updateState((s) => s.copyWith(isPlaying: playing));
    });

    // Buffering / loading state
    _player.playerStateStream.listen((state) {
      final isBuffering = state.processingState == ProcessingState.loading ||
          state.processingState == ProcessingState.buffering;
      _updateState((s) => s.copyWith(isBuffering: isBuffering));
    });

    // Position updates
    _player.positionStream.listen((position) {
      _updateState((s) => s.copyWith(position: position));
    });

    // Duration updates
    _player.durationStream.listen((duration) {
      if (duration != null) {
        _updateState((s) => s.copyWith(duration: duration));
      }
    });

    // Auto-advance on song completion
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        _handleCompletion();
      }
    });

    // Current index changes (for playlists)
    _player.currentIndexStream.listen((index) {
      if (index != null) {
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

  // ── Playback Control ───────────────────────────────────────────────────────

  Future<void> playSong(SongModel song, {List<SongModel>? queue, int? index}) async {
    final playQueue = queue ?? [song];
    final playIndex = index ?? 0;

    final audioSources = playQueue.map((s) => AudioSource.uri(
      Uri.file(s.filePath),
      tag: MediaItem(
        id: s.id.toString(),
        title: s.title,
        artist: s.artist,
        album: s.album,
        duration: Duration(milliseconds: s.durationMs),
      ),
    )).toList();

    final playlist = ConcatenatingAudioSource(children: audioSources);

    await _player.setAudioSource(playlist, initialIndex: playIndex);
    _updateState((s) => s.copyWith(
      currentSong: song,
      queue: playQueue,
      currentIndex: playIndex,
      position: Duration.zero,
    ));
    await _player.play();
  }

  Future<void> play() async => await _player.play();
  Future<void> pause() async => await _player.pause();

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> seekTo(Duration position) async {
    await _player.seek(position);
  }

  Future<void> seekToProgress(double progress) async {
    final duration = currentState.duration;
    final position = Duration(
      milliseconds: (duration.inMilliseconds * progress).round(),
    );
    await seekTo(position);
  }

  Future<void> skipToNext() async {
    final state = currentState;
    if (state.queue.isEmpty) return;

    final nextIndex = (state.currentIndex + 1) % state.queue.length;
    await _player.seek(Duration.zero, index: nextIndex);
    if (!_player.playing) await _player.play();
  }

  Future<void> skipToPrevious() async {
    final state = currentState;
    if (state.queue.isEmpty) return;

    // If >3 seconds into song, restart it
    if (state.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
      return;
    }

    final prevIndex = (state.currentIndex - 1 + state.queue.length) % state.queue.length;
    await _player.seek(Duration.zero, index: prevIndex);
    if (!_player.playing) await _player.play();
  }

  Future<void> stop() async {
    await _player.stop();
    _updateState((_) => const PlayerState());
  }

  // ── Queue ──────────────────────────────────────────────────────────────────

  Future<void> setQueue(List<SongModel> songs, {int startIndex = 0}) async {
    if (songs.isEmpty) return;
    await playSong(songs[startIndex], queue: songs, index: startIndex);
  }

  void addToQueue(SongModel song) {
    final queue = [...currentState.queue, song];
    _updateState((s) => s.copyWith(queue: queue));
  }

  void removeFromQueue(int index) {
    final queue = List<SongModel>.from(currentState.queue);
    if (index >= 0 && index < queue.length) {
      queue.removeAt(index);
      _updateState((s) => s.copyWith(queue: queue));
    }
  }

  // ── Modes ──────────────────────────────────────────────────────────────────

  Future<void> setRepeatMode(RepeatMode mode) async {
    LoopMode loopMode;
    switch (mode) {
      case RepeatMode.none: loopMode = LoopMode.off; break;
      case RepeatMode.all:  loopMode = LoopMode.all; break;
      case RepeatMode.one:  loopMode = LoopMode.one; break;
    }
    await _player.setLoopMode(loopMode);
    _updateState((s) => s.copyWith(repeatMode: mode));
  }

  Future<void> toggleShuffle() async {
    final enabled = !currentState.shuffleEnabled;
    await _player.setShuffleModeEnabled(enabled);
    _updateState((s) => s.copyWith(shuffleEnabled: enabled));
  }

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0.0, 1.0));
    _updateState((s) => s.copyWith(volume: volume));
  }

  // ── Private ────────────────────────────────────────────────────────────────

  void _handleCompletion() {
    final state = currentState;
    if (state.repeatMode == RepeatMode.none &&
        state.currentIndex >= state.queue.length - 1) {
      _updateState((s) => s.copyWith(isPlaying: false));
    }
  }

  void _updateState(PlayerState Function(PlayerState) updater) {
    _stateController.add(updater(_stateController.value));
  }

  Future<void> dispose() async {
    await _player.dispose();
    await _stateController.close();
    _instance = null;
  }
}
