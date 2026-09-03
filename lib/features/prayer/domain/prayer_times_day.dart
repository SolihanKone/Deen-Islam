import 'package:equatable/equatable.dart';
import 'package:timezone/timezone.dart' as tz;

class PrayerTimesDay extends Equatable {
  const PrayerTimesDay({
    required this.dateReadable,
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.lastThird,
    required this.timeZoneId,
  });

  final String dateReadable;
  final DateTime fajr;
  final DateTime sunrise;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;

  /// Start of the last third of the night (tonight), from Maghrib to next Fajr.
  final DateTime lastThird;

  /// IANA zone the wall-clock times are in (e.g. Asia/Riyadh).
  final String timeZoneId;

  /// Instant of a city wall-clock time, for countdowns and notifications.
  tz.TZDateTime instant(DateTime wall) {
    try {
      return tz.TZDateTime(
        tz.getLocation(timeZoneId),
        wall.year,
        wall.month,
        wall.day,
        wall.hour,
        wall.minute,
      );
    } catch (_) {
      return tz.TZDateTime.from(wall, tz.local);
    }
  }

  /// The five salah times used for countdown and notifications.
  List<MapEntry<String, DateTime>> get ordered => [
    MapEntry('Fajr', fajr),
    MapEntry('Dhuhr', dhuhr),
    MapEntry('Asr', asr),
    MapEntry('Maghrib', maghrib),
    MapEntry('Isha', isha),
  ];

  /// Times shown on the prayer screen, including sunrise and last third.
  List<MapEntry<String, DateTime>> get displayRows => [
    MapEntry('Fajr', fajr),
    MapEntry('Sunrise', sunrise),
    MapEntry('Dhuhr', dhuhr),
    MapEntry('Asr', asr),
    MapEntry('Maghrib', maghrib),
    MapEntry('Isha', isha),
    MapEntry('LastThird', lastThird),
  ];

  @override
  List<Object?> get props => [
    dateReadable,
    fajr,
    sunrise,
    dhuhr,
    asr,
    maghrib,
    isha,
    lastThird,
    timeZoneId,
  ];
}
