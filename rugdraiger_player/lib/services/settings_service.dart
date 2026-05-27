import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/accent_palette.dart';
import '../core/theme/player_skins.dart';

class SettingsService extends ChangeNotifier {
  SettingsService._();
  static final SettingsService instance = SettingsService._();

  static const _keyGapless = 'gapless_playback';
  static const _keyReplayGain = 'replay_gain';
  static const _keyDynamicColors = 'dynamic_colors';
  static const _keyDrivingMode = 'driving_mode';
  static const _keyMediaKeys = 'media_keys';
  static const _keyShowLyrics = 'show_lyrics';
  static const _keySkinId = AppConstants.keyThemeAccent;

  bool gaplessPlayback = true;
  bool replayGainEnabled = true;
  bool dynamicColors = true;
  bool drivingMode = false;
  bool mediaKeysEnabled = true;
  bool showLyrics = true;
  String skinId = defaultSkinId;
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
    skinId = prefs.getString(_keySkinId) ?? defaultSkinId;
    applyPlayerSkin(skinId);
    _loaded = true;
    notifyListeners();
  }

  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _saveString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<void> setGaplessPlayback(bool value) async {
    gaplessPlayback = value;
    await _saveBool(_keyGapless, value);
    notifyListeners();
  }

  Future<void> setReplayGainEnabled(bool value) async {
    replayGainEnabled = value;
    await _saveBool(_keyReplayGain, value);
    notifyListeners();
  }

  Future<void> setDynamicColors(bool value) async {
    dynamicColors = value;
    await _saveBool(_keyDynamicColors, value);
    notifyListeners();
  }

  Future<void> setDrivingMode(bool value) async {
    drivingMode = value;
    await _saveBool(_keyDrivingMode, value);
    notifyListeners();
  }

  Future<void> setMediaKeysEnabled(bool value) async {
    mediaKeysEnabled = value;
    await _saveBool(_keyMediaKeys, value);
    notifyListeners();
  }

  Future<void> setShowLyrics(bool value) async {
    showLyrics = value;
    await _saveBool(_keyShowLyrics, value);
    notifyListeners();
  }

  Future<void> setSkinId(String id) async {
    skinId = id;
    applyPlayerSkin(id);
    await _saveString(_keySkinId, id);
    notifyListeners();
  }
}
