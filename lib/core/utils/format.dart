/// Human-friendly duration formatting for the stats screen.
///
/// Kept deliberately small: no `intl` dependency, no localization plumbing.
library;

/// e.g. `0s`, `45s`, `12m`, `1h 12m`, `3h 5m`.
String formatDuration(int milliseconds) {
  if (milliseconds <= 0) return '0s';

  final totalSeconds = (milliseconds / 1000).round();
  if (totalSeconds < 60) return '${totalSeconds}s';

  final totalMinutes = totalSeconds ~/ 60;
  if (totalMinutes < 60) return '${totalMinutes}m';

  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  if (minutes == 0) return '${hours}h';
  return '${hours}h ${minutes}m';
}

/// Narrow variant for chart labels: `0`, `<1m`, `12m`, `1h`, `3h`.
String formatDurationCompact(int milliseconds) {
  if (milliseconds <= 0) return '0';
  final totalMinutes = (milliseconds / 60000).round();
  if (totalMinutes < 1) return '<1m';
  if (totalMinutes < 60) return '${totalMinutes}m';
  return '${totalMinutes ~/ 60}h';
}
