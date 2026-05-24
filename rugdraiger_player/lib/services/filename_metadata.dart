import 'package:path/path.dart' as p;

/// Inferencia de metadatos desde el nombre de archivo (misma lógica que la PWA).
class FilenameMetadata {
  final String? title;
  final String? artist;
  final String? album;
  final int? track;

  const FilenameMetadata({this.title, this.artist, this.album, this.track});
}

const _genericFolderNames = {
  'music', 'música', 'musica', 'downloads', 'descargas', 'audio', 'songs',
  'canciones', 'albums', 'álbumes', 'albumes', 'mp3', 'flac', 'media',
  'my music', 'mi musica', 'telegram', 'whatsapp', 'documents', 'dcim',
  'misc', 'ringtones', 'notifications',
};

String _cleanSegment(String value) {
  return value.replaceAll(RegExp(r'[-_]+'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
}

bool isGenericArtist(String? value) {
  final normalized = (value ?? '').trim().toLowerCase();
  return normalized.isEmpty ||
      normalized == 'unknown artist' ||
      normalized == '<unknown>' ||
      normalized == 'unknown';
}

bool isGenericAlbum(String? value) {
  final normalized = (value ?? '').trim().toLowerCase();
  return normalized.isEmpty ||
      normalized == 'unknown album' ||
      normalized == '<unknown>' ||
      normalized == 'music' ||
      RegExp(r'^\d+$').hasMatch(normalized);
}

bool canShareArtworkByAlbum(String artist, String album) {
  return !isGenericArtist(artist) && !isGenericAlbum(album);
}

String albumArtworkKey(String artist, String album) =>
    '${artist.toLowerCase()}::${album.toLowerCase()}';
({int? track, String rest}) _stripTrackPrefix(String name) {
  final match = RegExp(r'^(\d{1,3})[\s.\-_]+(.+)$').firstMatch(name);
  if (match != null) {
    return (track: int.tryParse(match.group(1)!), rest: match.group(2)!.trim());
  }
  return (track: null, rest: name.trim());
}

FilenameMetadata parseFilenameMetadata(String nameWithoutExt, {String? parentFolder}) {
  final stripped = _stripTrackPrefix(nameWithoutExt);
  var track = stripped.track;
  var rest = stripped.rest;

  final bracketMatch = RegExp(r'^(.+?)\s*[\[\(]([^\]\)]+)[\]\)]\s*(.+)$').firstMatch(rest);
  if (bracketMatch != null) {
    return FilenameMetadata(
      artist: _cleanSegment(bracketMatch.group(1)!),
      album: _cleanSegment(bracketMatch.group(2)!),
      title: _cleanSegment(bracketMatch.group(3)!),
      track: track,
    );
  }

  if (rest.contains(' - ')) {
    final parts = rest.split(' - ').map(_cleanSegment).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 3) {
      return FilenameMetadata(
        artist: parts[0],
        album: parts[1],
        title: parts.sublist(2).join(' - '),
        track: track,
      );
    }
    if (parts.length == 2) {
      final first = parts[0];
      final second = parts[1];
      final secondParsed = _stripTrackPrefix(second);
      if (secondParsed.track != null) {
        return FilenameMetadata(
          album: first,
          title: secondParsed.rest,
          track: track ?? secondParsed.track,
        );
      }
      if (parentFolder != null &&
          _cleanSegment(parentFolder).toLowerCase() == first.toLowerCase()) {
        return FilenameMetadata(album: first, title: second, track: track);
      }
      return FilenameMetadata(artist: first, title: second, track: track);
    }
  }

  return FilenameMetadata(title: _cleanSegment(rest), track: track);
}

FilenameMetadata inferMetadataFromPath(String filePath) {
  final normalized = filePath.replaceAll('\\', '/');
  final segments = normalized.split('/').where((s) => s.isNotEmpty).toList();
  if (segments.isEmpty) return const FilenameMetadata();

  final filename = segments.last;
  final nameWithoutExt = p.basenameWithoutExtension(filename);
  final folders = segments
      .sublist(0, segments.length - 1)
      .map(_cleanSegment)
      .where((s) => s.isNotEmpty)
      .toList();
  final meaningfulFolders =
      folders.where((f) => !_genericFolderNames.contains(f.toLowerCase())).toList();

  final parentFolder =
      meaningfulFolders.isEmpty ? null : meaningfulFolders.last;
  final artistFolder =
      meaningfulFolders.length >= 2 ? meaningfulFolders[meaningfulFolders.length - 2] : null;

  final fromName = parseFilenameMetadata(nameWithoutExt, parentFolder: parentFolder);

  return FilenameMetadata(
    title: fromName.title,
    artist: fromName.artist ?? artistFolder,
    album: fromName.album ?? parentFolder,
    track: fromName.track,
  );
}

/// Metadatos efectivos para carátula/búsqueda (tags + nombre de archivo).
class SongArtworkMeta {
  final String artist;
  final String album;
  final String title;

  const SongArtworkMeta({
    required this.artist,
    required this.album,
    required this.title,
  });
}

SongArtworkMeta resolveArtworkMeta({
  required String title,
  required String artist,
  required String album,
  required String filePath,
}) {
  final inferred = inferMetadataFromPath(filePath);

  final resolvedTitle = _resolveTitle(title, inferred, filePath);

  var resolvedArtist = artist.trim();
  if (isGenericArtist(resolvedArtist)) {
    resolvedArtist = inferred.artist?.trim() ?? resolvedArtist;
  }

  var resolvedAlbum = album.trim();
  if (isGenericAlbum(resolvedAlbum)) {
    resolvedAlbum = inferred.album?.trim() ?? resolvedAlbum;
  }

  return SongArtworkMeta(
    artist: resolvedArtist,
    album: resolvedAlbum,
    title: resolvedTitle,
  );
}

String _resolveTitle(String storedTitle, FilenameMetadata inferred, String filePath) {
  final stored = storedTitle.trim();
  final inferredTitle = inferred.title?.trim();

  if (isGenericTitle(stored)) {
    final fromFile = _titleFromTaggedFilename(filePath);
    if (fromFile != null) return fromFile;
  }

  if (inferredTitle != null && inferredTitle.isNotEmpty) {
    if (stored.isEmpty) return inferredTitle;
    // MediaStore suele guardar el nombre completo del archivo como título
    if (stored.contains(' - ') || RegExp(r'^\d{1,3}[\s.\-_]').hasMatch(stored)) {
      return inferredTitle;
    }
  }

  if (stored.isNotEmpty && !isGenericTitle(stored)) return stored;
  return inferredTitle ?? p.basenameWithoutExtension(filePath);
}

bool isGenericTitle(String? value) {
  final normalized = (value ?? '').trim().toLowerCase();
  if (normalized.isEmpty || normalized == 'unknown title') return true;
  if (RegExp(r'^\[[^\]]+\]$').hasMatch(normalized)) return true;
  if (RegExp(r'^(hd|hq|official|video|audio|lyrics)$').hasMatch(normalized)) {
    return true;
  }
  return false;
}

String? _titleFromTaggedFilename(String filePath) {
  final base = p.basenameWithoutExtension(filePath.replaceAll('\\', '/'));
  final withoutTag = base.replaceFirst(RegExp(r'^\[[^\]]+\]\s*'), '').trim();
  if (withoutTag.isEmpty) return null;

  if (withoutTag.contains(' - ')) {
    final parts = withoutTag.split(' - ').map(_cleanSegment).where((s) => s.isNotEmpty).toList();
    if (parts.length >= 2) return parts.sublist(1).join(' - ');
  }

  final tokens = withoutTag.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
  if (tokens.length >= 2) return tokens.last;

  return withoutTag;
}

String? _artistFromTaggedFilename(String filePath) {
  final base = p.basenameWithoutExtension(filePath.replaceAll('\\', '/'));
  final withoutTag = base.replaceFirst(RegExp(r'^\[[^\]]+\]\s*'), '').trim();
  if (withoutTag.isEmpty) return null;

  if (withoutTag.contains(' - ')) {
    final parts = withoutTag.split(' - ').map(_cleanSegment).where((s) => s.isNotEmpty).toList();
    if (parts.isNotEmpty) return parts.first;
  }

  final tokens = withoutTag.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
  if (tokens.length >= 2) return tokens.sublist(0, tokens.length - 1).join(' ');

  return null;
}

/// Metadatos optimizados para búsqueda manual de carátula (iTunes).
SongArtworkMeta resolveArtworkSearchMeta({
  required String title,
  required String artist,
  required String album,
  required String filePath,
}) {
  var meta = resolveArtworkMeta(
    title: title,
    artist: artist,
    album: album,
    filePath: filePath,
  );

  if (isGenericTitle(meta.title)) {
    final fromFileTitle = _titleFromTaggedFilename(filePath);
    final fromFileArtist = _artistFromTaggedFilename(filePath);
    if (fromFileTitle != null) {
      meta = SongArtworkMeta(
        artist: fromFileArtist ?? meta.artist,
        album: meta.album,
        title: fromFileTitle,
      );
    }
  }

  if (isGenericArtist(meta.artist) && !isGenericArtist(artist)) {
    final combined = artist.trim();
    final tokens = combined.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    if (tokens.length >= 2 && isGenericTitle(meta.title)) {
      meta = SongArtworkMeta(
        artist: tokens.sublist(0, tokens.length - 1).join(' '),
        album: meta.album,
        title: tokens.last,
      );
    }
  }

  return meta;
}
