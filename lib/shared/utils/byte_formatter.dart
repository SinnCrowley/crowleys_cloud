/// Utility for formatting raw byte counts into human-readable strings (e.g. "1.2 MB").
abstract final class ByteFormatter {
  /// Formats [bytes] into human-readable string representation (B, KB, MB, GB, TB, PB, EB).
  static String format(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB'];
    var size = bytes.toDouble();
    var unit = 0;
    while (size >= 1024 && unit < units.length - 1) {
      size /= 1024;
      unit++;
    }
    final value = unit == 0 ? size.toStringAsFixed(0) : size.toStringAsFixed(1);
    return '$value ${units[unit]}';
  }
}
