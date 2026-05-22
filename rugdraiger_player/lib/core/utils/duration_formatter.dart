class DurationFormatter {
  DurationFormatter._();

  static String format(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(1, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  static String formatMs(int milliseconds) {
    return format(Duration(milliseconds: milliseconds));
  }

  static String shortFormat(Duration duration) {
    final minutes = duration.inMinutes;
    if (minutes < 60) return '${minutes}m';
    final hours = duration.inHours;
    final remainingMinutes = duration.inMinutes.remainder(60);
    return '${hours}h ${remainingMinutes}m';
  }
}
