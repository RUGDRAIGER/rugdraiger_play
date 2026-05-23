import '../../../core/constants/app_constants.dart';
import '../../../data/models/song_model.dart';

enum PlayerStatus { idle, loading, playing, paused, error }

class PlayerBlocState {
  final PlayerStatus status;
  final SongModel? currentSong;
  final Duration position;
  final Duration duration;
  final RepeatMode repeatMode;
  final bool shuffleEnabled;
  final double volume;
  final bool isMuted;
  final List<SongModel> queue;
  final int currentIndex;
  final String? errorMessage;

  const PlayerBlocState({
    this.status = PlayerStatus.idle,
    this.currentSong,
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

  bool get isPlaying => status == PlayerStatus.playing;
  bool get isLoading => status == PlayerStatus.loading;
  bool get hasActiveSong => currentSong != null;

  double get progress {
    if (duration.inMilliseconds == 0) return 0.0;
    return (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
  }

  PlayerBlocState copyWith({
    PlayerStatus? status,
    SongModel? currentSong,
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
  }) {
    return PlayerBlocState(
      status: status ?? this.status,
      currentSong: currentSong ?? this.currentSong,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      repeatMode: repeatMode ?? this.repeatMode,
      shuffleEnabled: shuffleEnabled ?? this.shuffleEnabled,
      volume: volume ?? this.volume,
      isMuted: isMuted ?? this.isMuted,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
