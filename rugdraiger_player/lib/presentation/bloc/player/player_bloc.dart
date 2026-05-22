import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/music_repository.dart';
import '../../../services/audio_service.dart';
import 'player_event.dart';
import 'player_state.dart' as bloc_state;

export 'player_event.dart';
export 'player_state.dart';

class PlayerBloc extends Bloc<PlayerEvent, bloc_state.PlayerBlocState> {
  final AudioPlayerService _audioService;
  final MusicRepository _repository;
  StreamSubscription? _playerSubscription;

  PlayerBloc({
    required AudioPlayerService audioService,
    required MusicRepository repository,
  })  : _audioService = audioService,
        _repository = repository,
        super(const bloc_state.PlayerBlocState()) {
    on<PlaySongEvent>(_onPlaySong);
    on<PauseEvent>(_onPause);
    on<ResumeEvent>(_onResume);
    on<TogglePlayPauseEvent>(_onTogglePlayPause);
    on<SeekEvent>(_onSeek);
    on<SeekProgressEvent>(_onSeekProgress);
    on<SkipNextEvent>(_onSkipNext);
    on<SkipPreviousEvent>(_onSkipPrevious);
    on<SetQueueEvent>(_onSetQueue);
    on<ToggleShuffleEvent>(_onToggleShuffle);
    on<SetRepeatModeEvent>(_onSetRepeatMode);
    on<SetVolumeEvent>(_onSetVolume);
    on<PlayerStateUpdatedEvent>(_onPlayerStateUpdated);
    on<ToggleFavoriteEvent>(_onToggleFavorite);

    _playerSubscription = _audioService.stateStream.listen((playerState) {
      add(PlayerStateUpdatedEvent(playerState));
    });
  }

  Future<void> _onPlaySong(PlaySongEvent event, Emitter emit) async {
    emit(state.copyWith(status: bloc_state.PlayerStatus.loading));
    try {
      await _audioService.playSong(event.song, queue: event.queue, index: event.index);
      await _repository.markAsPlayed(event.song.id);
    } catch (e) {
      emit(state.copyWith(
        status: bloc_state.PlayerStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onPause(PauseEvent event, Emitter emit) async {
    await _audioService.pause();
  }

  Future<void> _onResume(ResumeEvent event, Emitter emit) async {
    await _audioService.play();
  }

  Future<void> _onTogglePlayPause(TogglePlayPauseEvent event, Emitter emit) async {
    await _audioService.togglePlayPause();
  }

  Future<void> _onSeek(SeekEvent event, Emitter emit) async {
    await _audioService.seekTo(event.position);
  }

  Future<void> _onSeekProgress(SeekProgressEvent event, Emitter emit) async {
    await _audioService.seekToProgress(event.progress);
  }

  Future<void> _onSkipNext(SkipNextEvent event, Emitter emit) async {
    await _audioService.skipToNext();
  }

  Future<void> _onSkipPrevious(SkipPreviousEvent event, Emitter emit) async {
    await _audioService.skipToPrevious();
  }

  Future<void> _onSetQueue(SetQueueEvent event, Emitter emit) async {
    await _audioService.setQueue(event.songs, startIndex: event.startIndex);
  }

  Future<void> _onToggleShuffle(ToggleShuffleEvent event, Emitter emit) async {
    await _audioService.toggleShuffle();
  }

  Future<void> _onSetRepeatMode(SetRepeatModeEvent event, Emitter emit) async {
    await _audioService.setRepeatMode(event.mode);
  }

  Future<void> _onSetVolume(SetVolumeEvent event, Emitter emit) async {
    await _audioService.setVolume(event.volume);
  }

  Future<void> _onPlayerStateUpdated(PlayerStateUpdatedEvent event, Emitter emit) async {
    final ps = event.playerState;
    emit(state.copyWith(
      status: ps.isPlaying
          ? bloc_state.PlayerStatus.playing
          : ps.isBuffering
              ? bloc_state.PlayerStatus.loading
              : bloc_state.PlayerStatus.paused,
      currentSong: ps.currentSong,
      position: ps.position,
      duration: ps.duration,
      repeatMode: ps.repeatMode,
      shuffleEnabled: ps.shuffleEnabled,
      volume: ps.volume,
      queue: ps.queue,
      currentIndex: ps.currentIndex,
    ));
  }

  Future<void> _onToggleFavorite(ToggleFavoriteEvent event, Emitter emit) async {
    await _repository.toggleFavorite(event.songId);
  }

  @override
  Future<void> close() {
    _playerSubscription?.cancel();
    return super.close();
  }
}
