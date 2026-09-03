import 'package:deen_connect/features/prayer/data/city_geocoder.dart';
import 'package:deen_connect/features/prayer/services/prayer_notification_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  test('Photon parser keeps towns and cities', () {
    const json = {
      'features': [
        {
          'geometry': {
            'coordinates': [8.5167, 12.0001],
          },
          'properties': {
            'osm_key': 'place',
            'osm_value': 'city',
            'name': 'Kano',
            'country': 'Nigeria',
            'state': 'Kano',
          },
        },
        {
          'geometry': {
            'coordinates': [2.3522, 48.8566],
          },
          'properties': {
            'osm_key': 'highway',
            'osm_value': 'residential',
            'name': 'Rue de Rivoli',
            'country': 'France',
          },
        },
      ],
    };

    final hits = CityGeocoder.parsePhoton(json);
    expect(hits, hasLength(1));
    expect(hits.first.name, 'Kano');
    expect(hits.first.country, 'Nigeria');
    expect(hits.first.latitude, closeTo(12.0001, 0.0001));
    expect(hits.first.label, 'Kano, Nigeria');
  });

  test('Nominatim parser reads city from address', () {
    const json = [
      {
        'lat': '40.7128',
        'lon': '-74.0060',
        'name': 'New York',
        'category': 'place',
        'type': 'city',
        'address': {
          'city': 'New York',
          'state': 'New York',
          'country': 'United States',
        },
      },
    ];

    final hits = CityGeocoder.parseNominatim(json);
    expect(hits, hasLength(1));
    expect(hits.first.name, 'New York');
    expect(hits.first.subtitle, contains('United States'));
  });

  test('wall-clock salah time maps into the local timezone', () {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/New_York'));
    final when = PrayerNotificationService.tzFromWallClock(
      DateTime(2026, 9, 3, 13, 30),
    );
    expect(when.hour, 13);
    expect(when.minute, 30);
    expect(when.location.name, 'America/New_York');
  });
}
