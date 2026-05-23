enum ViewName {
  home,
  library,
  songs,
  albums,
  artists,
  playlists,
  equalizer,
  search,
}

extension ViewNameX on ViewName {
  bool get isDrawerSection =>
      this == ViewName.library ||
      this == ViewName.albums ||
      this == ViewName.artists;

  static const bottomNavViews = [
    ViewName.home,
    ViewName.songs,
    ViewName.playlists,
    ViewName.equalizer,
    ViewName.search,
  ];
}
