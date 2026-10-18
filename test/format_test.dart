import 'package:flutter_helper/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatDuration', () {
    expect(formatDuration(0), '0m');
    expect(formatDuration(-5), '0m');
    expect(formatDuration(30), '30s');
    expect(formatDuration(45 * 60), '45m');
    expect(formatDuration(2 * 3600), '2h');
    expect(formatDuration(2 * 3600 + 5 * 60), '2h05m');
  });

  test('formatStopwatch', () {
    expect(formatStopwatch(Duration.zero), '00:00');
    expect(formatStopwatch(const Duration(seconds: -3)), '00:00');
    expect(formatStopwatch(const Duration(minutes: 23, seconds: 45)), '23:45');
    expect(
      formatStopwatch(const Duration(hours: 1, minutes: 2, seconds: 3)),
      '1:02:03',
    );
    expect(
      formatStopwatch(
        const Duration(hours: 1, minutes: 2, seconds: 3),
        padHours: true,
      ),
      '01:02:03',
    );
  });

  test('formatBytes', () {
    expect(formatBytes(512), '512 B');
    expect(formatBytes(1536), '1.5 KB');
    expect(formatBytes(2 * 1024 * 1024), '2.0 MB');
    expect(formatBytes(3 * 1024 * 1024 * 1024), '3.0 GB');
  });

  test('date and time formats', () {
    final date = DateTime(2026, 10, 4, 9, 5);

    expect(twoDigits(7), '07');
    expect(formatIsoDate(date), '2026-10-04');
    expect(formatDay(date), 'Sun 4 Oct');
    expect(formatDate(date), 'Oct 4, 2026');
    expect(formatTime(date), '09:05');
    expect(formatDateTime(date), '2026-10-04 09:05');
  });
}
