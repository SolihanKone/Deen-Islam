import 'package:lat_lng_to_timezone/lat_lng_to_timezone.dart' as tzmap;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// IANA timezone for prayer coordinates (city clock, not the phone's).
abstract final class PrayerTimeZone {
  static var _ready = false;

  static void ensureInitialized() {
    if (_ready) return;
    tz_data.initializeTimeZones();
    _ready = true;
  }

  static tz.Location locationFor(double latitude, double longitude) {
    ensureInitialized();
    try {
      final raw = tzmap.latLngToTimezoneString(latitude, longitude);
      return tz.getLocation(_aliases[raw] ?? raw);
    } catch (_) {
      return tz.local;
    }
  }

  static const _aliases = {
    'Asia/Calcutta': 'Asia/Kolkata',
    'Asia/Saigon': 'Asia/Ho_Chi_Minh',
    'Asia/Rangoon': 'Asia/Yangon',
    'Asia/Katmandu': 'Asia/Kathmandu',
    'Europe/Kiev': 'Europe/Kyiv',
    'America/Godthab': 'America/Nuuk',
    'Pacific/Ponape': 'Pacific/Pohnpei',
    'Asia/Chongqing': 'Asia/Shanghai',
    'Asia/Harbin': 'Asia/Shanghai',
  };
}
