import 'package:deen_connect/features/prayer/data/prayer_convention.dart';
import 'package:deen_connect/features/prayer/data/prayer_time_zone.dart';
import 'package:deen_connect/features/prayer/data/prayer_times_calculator.dart';
import 'package:deen_connect/features/prayer/domain/prayer_coordinates.dart';
import 'package:deen_connect/features/prayer/domain/prayer_method.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(PrayerTimeZone.ensureInitialized);

  group('PrayerConvention', () {
    test('Makkah uses Umm al-Qura', () {
      final c = PrayerConvention.resolve(country: 'Saudi Arabia');
      expect(c.method, PrayerCalculationMethod.ummAlQura);
      expect(c.madhab, PrayerMadhab.shafi);
    });

    test('Karachi uses University of Karachi and Hanafi', () {
      final c = PrayerConvention.resolve(country: 'Pakistan');
      expect(c.method, PrayerCalculationMethod.karachi);
      expect(c.madhab, PrayerMadhab.hanafi);
    });

    test('Istanbul uses Diyanet and Hanafi', () {
      final c = PrayerConvention.resolve(country: 'Türkiye');
      expect(c.method, PrayerCalculationMethod.turkiye);
      expect(c.madhab, PrayerMadhab.hanafi);
    });

    test('Paris uses France UOIF', () {
      final c = PrayerConvention.resolve(country: 'France');
      expect(c.method, PrayerCalculationMethod.france);
    });

    test('New York uses ISNA', () {
      final c = PrayerConvention.resolve(country: 'United States');
      expect(c.method, PrayerCalculationMethod.northAmerica);
    });

    test('Jakarta uses Kemenag', () {
      final c = PrayerConvention.resolve(country: 'Indonesia');
      expect(c.method, PrayerCalculationMethod.indonesian);
    });

    test('Cairo uses Egyptian authority', () {
      final c = PrayerConvention.resolve(country: 'Egypt');
      expect(c.method, PrayerCalculationMethod.egyptian);
    });

    test('manual override wins', () {
      final c = PrayerConvention.resolve(
        country: 'Saudi Arabia',
        methodOverride: PrayerCalculationMethod.northAmerica,
        madhabOverride: PrayerMadhab.hanafi,
      );
      expect(c.method, PrayerCalculationMethod.northAmerica);
      expect(c.madhab, PrayerMadhab.hanafi);
    });
  });

  test('Makkah times are in Arabian wall clock, not the phone zone', () {
    tz.setLocalLocation(tz.getLocation('America/New_York'));
    const makkah = PrayerCoordinates(latitude: 21.4225, longitude: 39.8262);
    final day = PrayerTimesCalculator.forDate(
      DateTime(2026, 8, 18),
      makkah,
      method: PrayerCalculationMethod.ummAlQura,
    );
    expect(day.timeZoneId, anyOf('Asia/Riyadh', 'Asia/Mecca'));
    expect(day.fajr.hour, inInclusiveRange(3, 6));
    expect(day.dhuhr.hour, inInclusiveRange(11, 13));
    expect(day.maghrib.hour, inInclusiveRange(18, 20));
    expect(day.fajr.isBefore(day.sunrise), isTrue);
    expect(day.sunrise.isBefore(day.dhuhr), isTrue);
    expect(day.dhuhr.isBefore(day.asr), isTrue);
    expect(day.asr.isBefore(day.maghrib), isTrue);
    expect(day.maghrib.isBefore(day.isha), isTrue);
  });

  test('ISNA prayer times for New York are in order', () {
    tz.setLocalLocation(tz.getLocation('America/New_York'));
    final day = PrayerTimesCalculator.forDate(
      DateTime(2026, 8, 18),
      const PrayerCoordinates(latitude: 40.7128, longitude: -74.0060),
      method: PrayerCalculationMethod.northAmerica,
    );
    expect(day.timeZoneId, 'America/New_York');
    expect(day.fajr.isBefore(day.dhuhr), isTrue);
    expect(day.dhuhr.isBefore(day.asr), isTrue);
    expect(day.asr.isBefore(day.maghrib), isTrue);
    expect(day.maghrib.isBefore(day.isha), isTrue);
    expect(day.fajr.isBefore(day.sunrise), isTrue);
    expect(day.sunrise.isBefore(day.dhuhr), isTrue);
    expect(day.maghrib.isBefore(day.lastThird), isTrue);
  });

  test('Hanafi Asr is later than Shafi Asr', () {
    const ny = PrayerCoordinates(latitude: 40.7128, longitude: -74.0060);
    final date = DateTime(2026, 8, 18);
    final shafi = PrayerTimesCalculator.forDate(
      date,
      ny,
      method: PrayerCalculationMethod.northAmerica,
      madhab: PrayerMadhab.shafi,
    );
    final hanafi = PrayerTimesCalculator.forDate(
      date,
      ny,
      method: PrayerCalculationMethod.northAmerica,
      madhab: PrayerMadhab.hanafi,
    );
    expect(hanafi.asr.isAfter(shafi.asr), isTrue);
  });
}
