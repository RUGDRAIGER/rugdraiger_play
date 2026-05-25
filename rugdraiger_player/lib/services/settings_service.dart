import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  SettingsService._();
  static final SettingsService instance = SettingsService._();

  static const _keyGapless = 'gapless_playback';
  static const _keyReplayGain = 'replay_gain';
  static const _keyDynamicColors = 'dynamic_colors';
  static const _keyDrivingMode = 'driving_mode';
  static const _keyMediaKeys = 'media_keys';
  static const _keyShowLyrics = 'show_lyrics';

  bool gaplessPlayback = true;
  bool replayGainEnabled = true;
  bool dynamicColors = true;
  bool drivingMode = false;
  bool mediaKeysEnabled = true;
  bool showLyrics = true;
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    gaplessPlayback = prefs.getBool(_keyGapless) ?? true;
    replayGainEnabled = prefs.getBool(_keyReplayGain) ?? true;
    dynamicColors = prefs.getBool(_keyDynamicColors) ?? true;
    drivingMode = prefs.getBool(_keyDrivingMode) ?? false;
    mediaKeysEnabled = prefs.getBool(_keyMediaKeys) ?? true;
    showLyrics = prefs.getBool(_keyShowLyrics) ?? true;
    _loaded = true;
    notifyListeners();
  }

  Future<void> _save(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> setGaplessPlayback(bool value) async {
    gaplessPlayback = value;
    await _save(_keyGapless, value);
    notifyListeners();
  }

  Future<void> setReplayGainEnabled(bool value) async {
    replayGainEnabled = value;
    await _save(_keyReplayGain, value);
    notifyListeners();
  }

  Future<void> setDynamicColors(bool value) async {
    dynamicColors = value;
    await _save(_keyDynamicColors, value);
    notifyListeners();
  }

  Future<void> setDrivingMode(bool value) async {
    drivingMode = value;
    await _save(_keyDrivingMode, value);
    notifyListeners();
  }

  Future<void> setMediaKeysEnabled(bool value) async {
    mediaKeysEnabled = value;
    await _save(_keyMediaKeys, value);
    notifyListeners();
  }

  Future<void> setShowLyrics(bool value) async {
    showLyrics = value;
    await _save(_keyShowLyrics, value);
    notifyListeners();
  }
}
