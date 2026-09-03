import '../domain/prayer_times_day.dart';

/// Next upcoming prayer for [now], or tomorrow's Fajr when [tomorrow] is set.
///
/// Compares real instants so city-local wall clocks stay correct worldwide.
MapEntry<String, DateTime>? nextPrayer(
  DateTime now,
  PrayerTimesDay day, {
  PrayerTimesDay? tomorrow,
}) {
  MapEntry<String, DateTime>? best;
  for (final e in day.ordered) {
    if (!day.instant(e.value).isAfter(now)) continue;
    if (best == null ||
        day.instant(e.value).isBefore(day.instant(best.value))) {
      best = e;
    }
  }
  if (best != null) return best;
  if (tomorrow != null) return MapEntry('Fajr', tomorrow.fajr);
  return null;
}

String formatCountdown(Duration diff) {
  if (diff.isNegative) return '0h 0m 0s';
  final h = diff.inHours;
  final m = diff.inMinutes.remainder(60);
  final s = diff.inSeconds.remainder(60);
  return '${h}h ${m}m ${s}s';
}
