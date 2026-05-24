import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Extrae carátulas embebidas en archivos de audio (ID3 APIC y JPEG/PNG en el binario).
class EmbeddedArtworkExtractor {
  EmbeddedArtworkExtractor._();

  static const _channel = MethodChannel('rugdraiger/artwork');

  static Future<Uint8List?> extractFromPath(String path) async {
    final normalized = path.trim();
    if (normalized.isEmpty) return null;

    if (!await _shouldTryEmbedded(normalized)) return null;

    if (!kIsWeb && Platform.isAndroid) {
      try {
        final nativeArt = await _channel.invokeMethod<Uint8List>(
          'extractArtwork',
          {'path': normalized},
        );
        if (nativeArt != null && nativeArt.isNotEmpty) return nativeArt;
      } catch (e) {
        debugPrint('[EmbeddedArtworkExtractor] native extract failed: $e');
      }
    }

    try {
      final bytes = await _readFileBytes(normalized);
      if (bytes == null || bytes.isEmpty) return null;
      return extractFromBytes(bytes);
    } catch (e) {
      debugPrint('[EmbeddedArtworkExtractor] dart extract failed: $e');
      return null;
    }
  }

  static Future<bool> _shouldTryEmbedded(String path) async {
    final filePath = path.replaceFirst('file://', '');
    if (filePath.startsWith('content://')) return true;

    final file = File(filePath);
    if (!await file.exists()) return false;

    final length = await file.length();
    if (length > 8 * 1024 * 1024) return false;

    final lower = filePath.toLowerCase();
    if (lower.endsWith('.wav') || lower.endsWith('.flac') || lower.endsWith('.aiff')) {
      return length <= 2 * 1024 * 1024;
    }

    return true;
  }

  static Future<Uint8List?> _readFileBytes(String path) async {
    final filePath = path.replaceFirst('file://', '');
    if (filePath.startsWith('content://')) return null;

    final file = File(filePath);
    if (!await file.exists()) return null;

    final length = await file.length();
    if (length <= 5 * 1024 * 1024) {
      return file.readAsBytes();
    }

    final raf = await file.open();
    try {
      final headerSize = length < 512 * 1024 ? length : 512 * 1024;
      final header = Uint8List(headerSize);
      await raf.readInto(header);

      final fromHeader = extractFromBytes(header);
      if (fromHeader != null) return fromHeader;

      final tailSize = length < 768 * 1024 ? length : 768 * 1024;
      await raf.setPosition(length - tailSize);
      final tail = Uint8List(tailSize);
      await raf.readInto(tail);
      return extractFromBytes(tail);
    } finally {
      await raf.close();
    }
  }

  static Uint8List? extractFromBytes(Uint8List bytes) {
    final fromId3 = _extractFromId3(bytes);
    if (fromId3 != null && fromId3.isNotEmpty) return fromId3;
    return _scanForImage(bytes);
  }

  static Uint8List? _extractFromId3(Uint8List bytes) {
    if (bytes.length < 10) return null;
    if (String.fromCharCodes(bytes.sublist(0, 3)) != 'ID3') return null;

    final versionMajor = bytes[3];
    final versionMinor = bytes[4];
    final tagSize = _syncSafeInt(bytes.sublist(6, 10));
    final isV24 = versionMajor == 4 && versionMinor == 0;
    final isV22 = versionMajor == 2;

    var pos = 10;
    final end = (10 + tagSize).clamp(0, bytes.length);

    while (pos + (isV22 ? 6 : 10) <= end) {
      final frameId = isV22
          ? String.fromCharCodes(bytes.sublist(pos, pos + 3))
          : String.fromCharCodes(bytes.sublist(pos, pos + 4));

      if (frameId.replaceAll('\x00', '').isEmpty) break;

      late int frameSize;
      if (isV22) {
        frameSize = (bytes[pos + 3] << 16) | (bytes[pos + 4] << 8) | bytes[pos + 5];
        pos += 6;
      } else if (isV24) {
        frameSize = _syncSafeInt(bytes.sublist(pos + 4, pos + 8));
        pos += 10;
      } else {
        frameSize = _int32(bytes.sublist(pos + 4, pos + 8));
        pos += 10;
      }

      if (frameSize <= 0 || pos + frameSize > bytes.length) break;

      if (frameId == 'APIC' || frameId == 'PIC') {
        final frame = bytes.sublist(pos, pos + frameSize);
        final picture = _parseApicFrame(frame, isV22: isV22);
        if (picture != null && picture.isNotEmpty) return picture;
      }

      pos += frameSize;
    }

    return null;
  }

  static Uint8List? _parseApicFrame(Uint8List frame, {required bool isV22}) {
    if (frame.isEmpty) return null;

    var offset = 1;
    if (!isV22) {
      offset = _skipNullTerminated(frame, offset);
      if (offset >= frame.length) return null;
      offset += 1;
      offset = _skipNullTerminated(frame, offset);
    } else {
      offset += 3;
      if (offset >= frame.length) return null;
      offset += 1;
      offset = _skipNullTerminated(frame, offset);
    }

    if (offset >= frame.length) return null;
    return Uint8List.fromList(frame.sublist(offset));
  }

  static int _skipNullTerminated(Uint8List data, int start) {
    var i = start;
    while (i < data.length && data[i] != 0) {
      i++;
    }
    return i + 1;
  }

  static Uint8List? _scanForImage(Uint8List bytes) {
    Uint8List? best;
    var bestSize = 0;

    final jpeg = _largestJpeg(bytes);
    if (jpeg != null && jpeg.length > bestSize) {
      best = jpeg;
      bestSize = jpeg.length;
    }

    final png = _largestPng(bytes);
    if (png != null && png.length > bestSize) {
      best = png;
      bestSize = png.length;
    }

    return bestSize >= 1024 ? best : null;
  }

  static bool _isValidJpeg(Uint8List data) {
    if (data.length < 10) return false;
    if (data[0] != 0xFF || data[1] != 0xD8 || data[2] != 0xFF) return false;
    if (data[data.length - 2] != 0xFF || data[data.length - 1] != 0xD9) {
      return false;
    }

    const validMarkers = {0xC0, 0xC1, 0xC2, 0xC4, 0xDB, 0xDD, 0xE0, 0xE1, 0xFE};
    return validMarkers.contains(data[3]);
  }

  static Uint8List? _largestJpeg(Uint8List bytes) {
    Uint8List? best;
    var bestSize = 0;
    var start = 0;

    while (start < bytes.length - 3) {
      final idx = _indexOf(bytes, const [0xFF, 0xD8, 0xFF], start);
      if (idx < 0) break;

      final endIdx = _indexOf(bytes, const [0xFF, 0xD9], idx + 3);
      if (endIdx < 0) break;

      final length = endIdx - idx + 2;
      if (length > bestSize && length >= 1024) {
        final candidate = bytes.sublist(idx, endIdx + 2);
        if (_isValidJpeg(candidate)) {
          best = candidate;
          bestSize = length;
        }
      }
      start = endIdx + 2;
    }

    return best;
  }

  static Uint8List? _largestPng(Uint8List bytes) {
    const signature = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
    final idx = _indexOf(bytes, signature, 0);
    if (idx < 0) return null;

    var pos = idx + 8;
    while (pos + 12 <= bytes.length) {
      final chunkLen = _int32(bytes.sublist(pos, pos + 4));
      final chunkType = String.fromCharCodes(bytes.sublist(pos + 4, pos + 8));
      pos += 8 + chunkLen + 4;
      if (chunkType == 'IEND') {
        final total = pos - idx;
        if (total >= 1024) return bytes.sublist(idx, pos);
        return null;
      }
      if (chunkLen < 0 || pos > bytes.length) return null;
    }

    return null;
  }

  static int _indexOf(Uint8List data, List<int> pattern, int start) {
    if (pattern.isEmpty || start >= data.length) return -1;
    for (var i = start; i <= data.length - pattern.length; i++) {
      var match = true;
      for (var j = 0; j < pattern.length; j++) {
        if (data[i + j] != pattern[j]) {
          match = false;
          break;
        }
      }
      if (match) return i;
    }
    return -1;
  }

  static int _syncSafeInt(Uint8List bytes) =>
      ((bytes[0] & 0x7F) << 21) |
      ((bytes[1] & 0x7F) << 14) |
      ((bytes[2] & 0x7F) << 7) |
      (bytes[3] & 0x7F);

  static int _int32(Uint8List bytes) =>
      (bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3];
}
