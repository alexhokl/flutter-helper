/// Formatting helpers, kept in one place so that every screen of every app
/// shows durations, sizes and dates the same way.
library;

import 'package:intl/intl.dart';

/// Pads [value] to two digits: `7` becomes `07`.
String twoDigits(int value) => value.toString().padLeft(2, '0');

/// Formats a number of seconds compactly: "2h30m", "2h", "45m", "30s".
/// Zero and negative values are "0m".
String formatDuration(int seconds) {
  if (seconds <= 0) return '0m';

  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;

  if (hours > 0 && minutes > 0) return '${hours}h${twoDigits(minutes)}m';
  if (hours > 0) return '${hours}h';
  if (minutes > 0) return '${minutes}m';
  return '${seconds}s';
}

/// Formats a duration as a clock reading: "1:23:45" or "23:45", or
/// "01:23:45" when [padHours] is true. Negative durations read as zero.
///
/// Used for running timers and media positions, where a ticking clock reads
/// better than the compact [formatDuration].
String formatStopwatch(Duration duration, {bool padHours = false}) {
  final seconds = duration.isNegative ? 0 : duration.inSeconds;

  final hours = seconds ~/ 3600;
  final mm = twoDigits((seconds % 3600) ~/ 60);
  final ss = twoDigits(seconds % 60);

  if (hours == 0) return '$mm:$ss';
  return '${padHours ? twoDigits(hours) : hours}:$mm:$ss';
}

/// Formats a byte count with binary units: "512 B", "1.5 KB", "2.0 MB",
/// "1.2 GB".
String formatBytes(int bytes) {
  const units = ['KB', 'MB', 'GB', 'TB'];
  if (bytes < 1024) return '$bytes B';
  var value = bytes / 1024;
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  return '${value.toStringAsFixed(1)} ${units[unit]}';
}

/// "2026-10-18". Locale independent, for values the user may copy or type.
String formatIsoDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${twoDigits(date.month)}-${twoDigits(date.day)}';

/// "Sun 18 Oct".
String formatDay(DateTime date) => DateFormat('EEE d MMM').format(date);

/// "Oct 18, 2026" in English, localised by the current [Intl.defaultLocale].
String formatDate(DateTime date) => DateFormat.yMMMd().format(date);

/// "14:05", 24-hour.
String formatTime(DateTime date) => DateFormat('HH:mm').format(date);

/// "2026-10-18 14:05", 24-hour, locale independent.
String formatDateTime(DateTime date) =>
    '${formatIsoDate(date)} ${twoDigits(date.hour)}:${twoDigits(date.minute)}';
