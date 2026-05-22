import 'dart:typed_data';
import '../../core/constants/app_constants.dart';

class SongModel {
  final int id;
  final String title;
  final String artist;
  final String album;
  final String albumArtist;
  final String genre;
  final String filePath;
  final int durationMs;
  final int fileSize;
  final int bitrate;
  final int sampleRate;
  final int year;
  final int trackNumber;
  final AudioFormat format;
  final bool isLossless;
  final DateTime dateAdded;
  final Uint8List? artwork;

  const SongModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    this.albumArtist = '',
    this.genre = '',
    required this.filePath,
    required this.durationMs,
    this.fileSize = 0,
    this.bitrate = 0,
    this.sampleRate = 0,
    this.year = 0,
    this.trackNumber = 0,
    this.format = AudioFormat.mp3,
    this.isLossless = false,
    required this.dateAdded,
    this.artwork,
  });

  String get formattedBitrate {
    if (bitrate >= 1000) return '${(bitrate / 1000).toStringAsFixed(1)} Mbps';
    return '$bitrate kbps';
  }

  String get formattedSampleRate {
    if (sampleRate >= 1000) return '${(sampleRate / 1000).toStringAsFixed(0)} kHz';
    return '$sampleRate Hz';
  }

  String get qualityBadge {
    if (isLossless) {
      final khz = sampleRate >= 1000 ? sampleRate ~/ 1000 : sampleRate;
      final bits = bitrate >= 1000 ? '${bitrate ~/ 1000}-BIT' : null;
      if (bits != null) return 'FLAC • $bits / ${khz}KHZ';
      return format.name.toUpperCase();
    }
    return format.name.toUpperCase();
  }

  SongModel copyWith({
    int? id,
    String? title,
    String? artist,
    String? album,
    String? albumArtist,
    String? genre,
    String? filePath,
    int? durationMs,
    int? fileSize,
    int? bitrate,
    int? sampleRate,
    int? year,
    int? trackNumber,
    AudioFormat? format,
    bool? isLossless,
    DateTime? dateAdded,
    Uint8List? artwork,
  }) {
    return SongModel(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      albumArtist: albumArtist ?? this.albumArtist,
      genre: genre ?? this.genre,
      filePath: filePath ?? this.filePath,
      durationMs: durationMs ?? this.durationMs,
      fileSize: fileSize ?? this.fileSize,
      bitrate: bitrate ?? this.bitrate,
      sampleRate: sampleRate ?? this.sampleRate,
      year: year ?? this.year,
      trackNumber: trackNumber ?? this.trackNumber,
      format: format ?? this.format,
      isLossless: isLossless ?? this.isLossless,
      dateAdded: dateAdded ?? this.dateAdded,
      artwork: artwork ?? this.artwork,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'album_artist': albumArtist,
      'genre': genre,
      'file_path': filePath,
      'duration_ms': durationMs,
      'file_size': fileSize,
      'bitrate': bitrate,
      'sample_rate': sampleRate,
      'year': year,
      'track_number': trackNumber,
      'format': format.name,
      'is_lossless': isLossless ? 1 : 0,
      'date_added': dateAdded.millisecondsSinceEpoch,
    };
  }

  factory SongModel.fromMap(Map<String, dynamic> map) {
    return SongModel(
      id: map['id'] as int,
      title: map['title'] as String? ?? 'Unknown Title',
      artist: map['artist'] as String? ?? 'Unknown Artist',
      album: map['album'] as String? ?? 'Unknown Album',
      albumArtist: map['album_artist'] as String? ?? '',
      genre: map['genre'] as String? ?? '',
      filePath: map['file_path'] as String,
      durationMs: map['duration_ms'] as int? ?? 0,
      fileSize: map['file_size'] as int? ?? 0,
      bitrate: map['bitrate'] as int? ?? 0,
      sampleRate: map['sample_rate'] as int? ?? 0,
      year: map['year'] as int? ?? 0,
      trackNumber: map['track_number'] as int? ?? 0,
      format: AudioFormat.values.firstWhere(
        (e) => e.name == map['format'],
        orElse: () => AudioFormat.unknown,
      ),
      isLossless: (map['is_lossless'] as int? ?? 0) == 1,
      dateAdded: DateTime.fromMillisecondsSinceEpoch(
        map['date_added'] as int? ?? 0,
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SongModel && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
