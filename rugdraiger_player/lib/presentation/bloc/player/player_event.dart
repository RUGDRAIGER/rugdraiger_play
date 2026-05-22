import '../../../core/constants/app_constants.dart';
import '../../../data/models/song_model.dart';
import '../../../services/audio_service.dart' show PlayerState;

abstract class PlayerEvent {
  const PlayerEvent();
}

class PlaySongEvent extends PlayerEvent {
  final SongModel song;
  final List<SongModel>? queue;
  final int? index;
  const PlaySongEvent(this.song, {this.queue, this.index});
}

class PauseEvent extends PlayerEvent {
  const PauseEvent();
}

class ResumeEvent extends PlayerEvent {
  const ResumeEvent();
}

class TogglePlayPauseEvent extends PlayerEvent {
  const TogglePlayPauseEvent();
}

class SeekEvent extends PlayerEvent {
  final Duration position;
  const SeekEvent(this.position);
}

class SeekProgressEvent extends PlayerEvent {
  final double progress;
  const SeekProgressEvent(this.progress);
}

class SkipNextEvent extends PlayerEvent {
  const SkipNextEvent();
}

class SkipPreviousEvent extends PlayerEvent {
  const SkipPreviousEvent();
}

class SetQueueEvent extends PlayerEvent {
  final List<SongModel> songs;
  final int startIndex;
  const SetQueueEvent(this.songs, {this.startIndex = 0});
}

class ToggleShuffleEvent extends PlayerEvent {
  const ToggleShuffleEvent();
}

class SetRepeatModeEvent extends PlayerEvent {
  final RepeatMode mode;
  const SetRepeatModeEvent(this.mode);
}

class SetVolumeEvent extends PlayerEvent {
  final double volume;
  const SetVolumeEvent(this.volume);
}

class PlayerStateUpdatedEvent extends PlayerEvent {
  final PlayerState playerState;
  const PlayerStateUpdatedEvent(this.playerState);
}

class ToggleFavoriteEvent extends PlayerEvent {
  final int songId;
  const ToggleFavoriteEvent(this.songId);
}
