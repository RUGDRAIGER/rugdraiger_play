import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Persiste carátulas descargadas en disco (por id de canción).
class ArtworkStorage {
  ArtworkStorage._();

  static Directory? _dir;

  static Future<Directory> _artworksDir() async {
    if (_dir != null) return _dir!;
    final base = await getApplicationDocumentsDirectory();
    _dir = Directory(p.join(base.path, 'artworks'));
    if (!await _dir!.exists()) {
      await _dir!.create(recursive: true);
    }
    return _dir!;
  }

  static Future<File> _fileFor(int songId) async {
    final dir = await _artworksDir();
    return File(p.join(dir.path, '$songId.jpg'));
  }

  static Future<Uint8List?> load(int songId) async {
    try {
      final file = await _fileFor(songId);
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      return bytes.isEmpty ? null : bytes;
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(int songId, Uint8List data) async {
    if (data.isEmpty) return;
    try {
      final file = await _fileFor(songId);
      await file.writeAsBytes(data, flush: true);
    } catch (_) {}
  }

  static Future<void> delete(int songId) async {
    try {
      final file = await _fileFor(songId);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  static Future<void> clearAll() async {
    try {
      final dir = await _artworksDir();
      if (await dir.exists()) {
        await for (final entity in dir.list()) {
          if (entity is File) await entity.delete();
        }
      }
    } catch (_) {}
  }
}
