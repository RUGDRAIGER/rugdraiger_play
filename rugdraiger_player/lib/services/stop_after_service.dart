class StopAfterService {
  StopAfterService._();
  static final StopAfterService instance = StopAfterService._();

  final Set<int> _songIds = {};

  bool isEnabled(int songId) => _songIds.contains(songId);

  void toggle(int songId) {
    if (_songIds.contains(songId)) {
      _songIds.remove(songId);
    } else {
      _songIds.add(songId);
    }
  }

  bool consumeIfEnabled(int? songId) {
    if (songId == null || !_songIds.contains(songId)) return false;
    _songIds.remove(songId);
    return true;
  }
}
