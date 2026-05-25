enum ViewName {
  home,
  library,
  songs,
  albums,
  artists,
  genres,
  playlists,
  favorites,
  equalizer,
  search,
  settings,
}

extension ViewNameX on ViewName {
  bool get isDrawerSection =>
      this == ViewName.library ||
      this == ViewName.songs ||
      this == ViewName.albums ||
      this == ViewName.artists ||
      this == ViewName.genres ||
      this == ViewName.favorites ||
      this == ViewName.settings;

  static const bottomNavViews = [
    ViewName.home,
    ViewName.playlists,
    ViewName.search,
    ViewName.equalizer,
  ];
}
