import 'dart:io';
import 'package:path/path.dart' as p;

/// Carpetas de música por defecto en escritorio.
class DesktopMusicPaths {
  DesktopMusicPaths._();

  static List<String> defaultMusicFolders() {
    final folders = <String>[];

    if (Platform.isWindows) {
      final profile = Platform.environment['USERPROFILE'];
      if (profile != null && profile.isNotEmpty) {
        _addIfExists(folders, p.join(profile, 'Music'));
        _addIfExists(folders, p.join(profile, 'Downloads'));
        _addIfExists(folders, p.join(profile, 'Documents'));
      }
      for (final drive in ['C', 'D', 'E']) {
        _addIfExists(folders, '$drive:\\Users\\Public\\Music');
      }
    } else if (Platform.isMacOS) {
      final home = Platform.environment['HOME'];
      if (home != null && home.isNotEmpty) {
        _addIfExists(folders, p.join(home, 'Music'));
        _addIfExists(folders, p.join(home, 'Downloads'));
      }
    } else if (Platform.isLinux) {
      final home = Platform.environment['HOME'];
      if (home != null && home.isNotEmpty) {
        _addIfExists(folders, p.join(home, 'Music'));
        _addIfExists(folders, p.join(home, 'Downloads'));
      }
      _addIfExists(folders, '/mnt/c/Users/Public/Music');
    }

    return folders;
  }

  static void _addIfExists(List<String> list, String path) {
    if (Directory(path).existsSync() && !list.contains(path)) {
      list.add(path);
    }
  }
}
