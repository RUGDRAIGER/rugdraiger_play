import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../core/constants/app_constants.dart';

class EqualizerState {
  final bool enabled;
  final EqPreset preset;
  final List<double> bands;
  final int bassBoost;

  const EqualizerState({
    this.enabled = false,
    this.preset = EqPreset.flat,
    this.bands = const [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    this.bassBoost = 0,
  });

  EqualizerState copyWith({
    bool? enabled,
    EqPreset? preset,
    List<double>? bands,
    int? bassBoost,
  }) {
    return EqualizerState(
      enabled: enabled ?? this.enabled,
      preset: preset ?? this.preset,
      bands: bands ?? this.bands,
      bassBoost: bassBoost ?? this.bassBoost,
    );
  }
}

class EqualizerService {
  static EqualizerService? _instance;
  late SharedPreferences _prefs;
  EqualizerState _state = const EqualizerState();

  EqualizerService._internal();

  factory EqualizerService() {
    _instance ??= EqualizerService._internal();
    return _instance!;
  }

  EqualizerState get state => _state;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadSettings();
  }

  void _loadSettings() {
    final enabled = _prefs.getBool(AppConstants.keyEqEnabled) ?? false;
    final presetIndex = _prefs.getInt(AppConstants.keyEqPreset) ?? 0;
    final bandsJson = _prefs.getString(AppConstants.keyEqBands);
    final bassBoost = _prefs.getInt('bass_boost') ?? 0;

    List<double> bands;
    if (bandsJson != null) {
      final decoded = jsonDecode(bandsJson) as List;
      bands = decoded.map((e) => (e as num).toDouble()).toList();
    } else {
      bands = List.filled(AppConstants.eqBandCount, 0.0);
    }

    _state = EqualizerState(
      enabled: enabled,
      preset: EqPreset.values[presetIndex.clamp(0, EqPreset.values.length - 1)],
      bands: bands,
      bassBoost: bassBoost,
    );
  }

  Future<void> setEnabled(bool enabled) async {
    _state = _state.copyWith(enabled: enabled);
    await _prefs.setBool(AppConstants.keyEqEnabled, enabled);
  }

  Future<void> applyPreset(EqPreset preset) async {
    _state = _state.copyWith(
      preset: preset,
      bands: List<double>.from(preset.bands),
    );
    await _saveSettings();
  }

  Future<void> setBand(int index, double value) async {
    if (index < 0 || index >= AppConstants.eqBandCount) return;
    final newBands = List<double>.from(_state.bands);
    newBands[index] = value.clamp(-12.0, 12.0);
    _state = _state.copyWith(
      bands: newBands,
      preset: EqPreset.custom,
    );
    await _saveSettings();
  }

  Future<void> setBassBoost(int value) async {
    _state = _state.copyWith(bassBoost: value.clamp(0, 100));
    await _prefs.setInt('bass_boost', _state.bassBoost);
  }

  Future<void> reset() async {
    _state = const EqualizerState();
    await _saveSettings();
  }

  Future<void> _saveSettings() async {
    await _prefs.setInt(AppConstants.keyEqPreset, _state.preset.index);
    await _prefs.setString(
      AppConstants.keyEqBands,
      jsonEncode(_state.bands),
    );
  }
}
