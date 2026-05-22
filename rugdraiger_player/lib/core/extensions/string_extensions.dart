extension StringExtensions on String {
  String get audioFormatExtension => split('.').last.toLowerCase();

  bool get isLossless {
    const lossless = ['flac', 'wav', 'alac', 'aiff'];
    return lossless.contains(audioFormatExtension);
  }

  String get capitalizeFirst {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  String truncate(int maxLength, {String ellipsis = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - ellipsis.length)}$ellipsis';
  }
}

extension NullableStringExtensions on String? {
  String get orEmpty => this ?? '';
  bool get isNullOrEmpty => this == null || this!.isEmpty;
}
