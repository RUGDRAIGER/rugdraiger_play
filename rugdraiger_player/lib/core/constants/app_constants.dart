class AppConstants {
  AppConstants._();

  static const String appName = 'Rugdraiger Play';
  static const String appVersion = '1.0.0';

  // Supported audio formats
  static const List<String> supportedFormats = [
    'mp3', 'flac', 'aac', 'wav', 'ogg', 'm4a', 'alac', 'aiff', 'opus', 'wma',
  ];

  static const List<String> losslessFormats = ['flac', 'wav', 'alac', 'aiff'];

  // Database
  static const String dbName = 'rugdraiger.db';
  static const int dbVersion = 1;

  // SharedPreferences Keys
  static const String keyLastSong = 'last_song_id';
  static const String keyLastPosition = 'last_position_ms';
  static const String keyRepeatMode = 'repeat_mode';
  static const String keyShuffleEnabled = 'shuffle_enabled';
  static const String keyVolume = 'volume';
  static const String keyEqEnabled = 'eq_enabled';
  static const String keyEqPreset = 'eq_preset';
  static const String keyEqBands = 'eq_bands';
  static const String keySortOrder = 'sort_order';
  static const String keyThemeAccent = 'theme_accent';

  // Audio
  static const int defaultBassBoost = 0;
  static const double defaultVolume = 1.0;
  static const int eqBandCount = 10;
  static const List<int> eqFrequencies = [32, 64, 125, 250, 500, 1000, 2000, 4000, 8000, 16000];

  /// Orden de presets igual que la web (Flat → Vocal).
  static const List<EqPreset> eqDisplayPresets = [
    EqPreset.flat,
    EqPreset.bass,
    EqPreset.treble,
    EqPreset.rock,
    EqPreset.jazz,
    EqPreset.classical,
    EqPreset.electronic,
    EqPreset.vocal,
  ];

  // UI
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  static const double borderRadiusXLarge = 24.0;
  static const double borderWidth = 1.0;
  static const double miniPlayerHeight = 76.0;
  static const double bottomNavHeight = 56.0;

  // Animation Durations
  static const Duration animFast = Duration(milliseconds: 150);
  static const Duration animNormal = Duration(milliseconds: 300);
  static const Duration animSlow = Duration(milliseconds: 500);
}

enum RepeatMode { none, all, one }

enum SortOrder { titleAsc, titleDesc, artistAsc, dateAdded, duration }

enum AudioFormat { mp3, flac, aac, wav, ogg, m4a, alac, aiff, opus, wma, unknown }

enum EqPreset {
  flat,
  bass,
  treble,
  vocal,
  electronic,
  rock,
  jazz,
  classical,
  custom;

  String get displayName {
    switch (this) {
      case EqPreset.flat: return 'Flat';
      case EqPreset.bass: return 'Bass Boost';
      case EqPreset.treble: return 'Treble Boost';
      case EqPreset.vocal: return 'Vocal';
      case EqPreset.electronic: return 'Electronic';
      case EqPreset.rock: return 'Rock';
      case EqPreset.jazz: return 'Jazz';
      case EqPreset.classical: return 'Classical';
      case EqPreset.custom: return 'Custom';
    }
  }

  List<double> get bands {
    switch (this) {
      case EqPreset.flat:       return [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
      case EqPreset.bass:       return [6, 5, 4, 2, 0, 0, 0, 0, 0, 0];
      case EqPreset.treble:     return [0, 0, 0, 0, 0, 2, 3, 4, 5, 6];
      case EqPreset.vocal:      return [-2, -1, 0, 2, 4, 4, 3, 2, 0, -1];
      case EqPreset.electronic: return [4, 3, 0, -2, -2, 0, 2, 3, 4, 4];
      case EqPreset.rock:       return [4, 3, 2, 0, -1, 0, 2, 3, 3, 4];
      case EqPreset.jazz:       return [3, 2, 1, 2, -1, -1, 0, 1, 2, 3];
      case EqPreset.classical:  return [4, 3, 2, 2, -1, -1, 0, 2, 3, 4];
      case EqPreset.custom:     return [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    }
  }
}
