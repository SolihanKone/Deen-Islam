import 'package:adhan_dart/adhan_dart.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

import '../domain/prayer_coordinates.dart';
import '../domain/prayer_method.dart';
import '../domain/prayer_times_day.dart';
import 'prayer_time_zone.dart';

/// On-device salah times in the **city's** timezone, using the regional method.
abstract final class PrayerTimesCalculator {
  static const upcomingDays = 7;

  static PrayerTimesDay forDate(
    DateTime localDate,
    PrayerCoordinates coords, {
    PrayerCalculationMethod method = PrayerCalculationMethod.muslimWorldLeague,
    PrayerMadhab madhab = PrayerMadhab.shafi,
  }) {
    final zone = PrayerTimeZone.locationFor(coords.latitude, coords.longitude);
    final inCity = tz.TZDateTime.from(localDate, zone);
    final date = DateTime(inCity.year, inCity.month, inCity.day);
    final params = method.parameters()
      ..madhab = madhab.toAdhan()
      ..highLatitudeRule = HighLatitudeRule.recommended(
        Coordinates(coords.latitude, coords.longitude),
      );
    final times = PrayerTimes(
      coordinates: Coordinates(coords.latitude, coords.longitude),
      date: date,
      calculationParameters: params,
    );

    DateTime wall(DateTime utc) => _toCityWall(utc, zone);

    return PrayerTimesDay(
      dateReadable: DateFormat('d MMM y').format(date),
      fajr: wall(times.fajr),
      sunrise: wall(times.sunrise),
      dhuhr: wall(times.dhuhr),
      asr: wall(times.asr),
      maghrib: wall(times.maghrib),
      isha: wall(times.isha),
      lastThird: wall(
        _lastThirdUtc(maghrib: times.maghrib, nextFajr: times.fajrAfter),
      ),
      timeZoneId: zone.name,
    );
  }

  static List<PrayerTimesDay> upcoming(
    DateTime from,
    PrayerCoordinates coords, {
    required PrayerCalculationMethod method,
    required PrayerMadhab madhab,
    int days = upcomingDays,
  }) {
    final zone = PrayerTimeZone.locationFor(coords.latitude, coords.longitude);
    final start = tz.TZDateTime.from(from, zone);
    final startDay = DateTime(start.year, start.month, start.day);
    return [
      for (var i = 0; i < days; i++)
        forDate(
          startDay.add(Duration(days: i)),
          coords,
          method: method,
          madhab: madhab,
        ),
    ];
  }

  static DateTime _lastThirdUtc({
    required DateTime maghrib,
    required DateTime nextFajr,
  }) {
    var night = nextFajr.difference(maghrib);
    if (night.isNegative) {
      night = nextFajr.add(const Duration(days: 1)).difference(maghrib);
    }
    return nextFajr.subtract(Duration(milliseconds: night.inMilliseconds ~/ 3));
  }

  static DateTime _toCityWall(DateTime utc, tz.Location zone) {
    final local = tz.TZDateTime.from(utc, zone);
    return DateTime(
      local.year,
      local.month,
      local.day,
      local.hour,
      local.minute,
    );
  }
}
