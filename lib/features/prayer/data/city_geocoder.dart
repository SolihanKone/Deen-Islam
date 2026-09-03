import 'package:dio/dio.dart';

class CitySearchHit {
  const CitySearchHit({
    required this.name,
    required this.country,
    required this.latitude,
    required this.longitude,
    this.admin = '',
    this.id = '',
  });

  final String name;
  final String country;
  final String admin;
  final double latitude;
  final double longitude;
  final String id;

  String get label => country.isEmpty ? name : '$name, $country';

  String get subtitle {
    final parts = <String>[
      if (admin.isNotEmpty && admin != name && admin != country) admin,
      if (country.isNotEmpty && country != name) country,
    ];
    return parts.join(', ');
  }
}

/// Looks up any populated place worldwide (Photon, Nominatim fallback).
class CityGeocoder {
  CityGeocoder(this._dio, {this.localeCode = 'en'});

  final Dio _dio;
  final String localeCode;

  Future<List<CitySearchHit>> search(
    String query, {
    CancelToken? cancelToken,
  }) async {
    final q = query.trim();
    if (q.length < 2) return const [];
    try {
      final photon = await _searchPhoton(q, cancelToken: cancelToken);
      if (photon.isNotEmpty) return photon;
    } catch (_) {}
    return _searchNominatim(q, cancelToken: cancelToken);
  }

  Future<List<CitySearchHit>> _searchPhoton(
    String query, {
    CancelToken? cancelToken,
  }) async {
    final res = await _dio.get<dynamic>(
      'https://photon.komoot.io/api/',
      queryParameters: {'q': query, 'limit': 12, 'lang': _photonLang},
      options: Options(headers: {'User-Agent': _userAgent}),
      cancelToken: cancelToken,
    );
    return parsePhoton(res.data);
  }

  Future<List<CitySearchHit>> _searchNominatim(
    String query, {
    CancelToken? cancelToken,
  }) async {
    final res = await _dio.get<dynamic>(
      'https://nominatim.openstreetmap.org/search',
      queryParameters: {
        'q': query,
        'format': 'jsonv2',
        'addressdetails': 1,
        'limit': 12,
      },
      options: Options(
        headers: {'User-Agent': _userAgent, 'Accept-Language': localeCode},
      ),
      cancelToken: cancelToken,
    );
    return parseNominatim(res.data);
  }

  String get _photonLang => switch (localeCode) {
    'ar' || 'fr' || 'de' => localeCode,
    _ => 'en',
  };

  static const _userAgent = 'DeenIslam/1.0 (com.solihan.deenConnect)';

  static const _placeTypes = {
    'city',
    'town',
    'village',
    'hamlet',
    'municipality',
    'suburb',
    'neighbourhood',
    'neighborhood',
    'locality',
    'county',
    'state',
    'province',
    'district',
    'region',
    'isolated_dwelling',
    'quarter',
    'borough',
  };

  static List<CitySearchHit> parsePhoton(dynamic data) {
    if (data is! Map) return const [];
    final features = data['features'];
    if (features is! List) return const [];
    final out = <CitySearchHit>[];
    final seen = <String>{};
    for (final raw in features) {
      if (raw is! Map) continue;
      final props = raw['properties'];
      final geometry = raw['geometry'];
      if (props is! Map || geometry is! Map) continue;
      final osmValue = '${props['osm_value'] ?? ''}'.toLowerCase();
      final osmKey = '${props['osm_key'] ?? ''}'.toLowerCase();
      if (osmKey.isNotEmpty &&
          osmKey != 'place' &&
          osmKey != 'boundary' &&
          !_placeTypes.contains(osmValue)) {
        continue;
      }
      final coords = geometry['coordinates'];
      if (coords is! List || coords.length < 2) continue;
      final lon = (coords[0] as num?)?.toDouble();
      final lat = (coords[1] as num?)?.toDouble();
      if (lat == null || lon == null) continue;
      final name = '${props['name'] ?? props['city'] ?? ''}'.trim();
      if (name.isEmpty) continue;
      final country = '${props['country'] ?? ''}'.trim();
      final admin = '${props['state'] ?? props['county'] ?? ''}'.trim();
      final key = _dedupeKey(name, lat, lon);
      if (!seen.add(key)) continue;
      out.add(
        CitySearchHit(
          name: name,
          country: country,
          admin: admin,
          latitude: lat,
          longitude: lon,
        ),
      );
    }
    return out;
  }

  static List<CitySearchHit> parseNominatim(dynamic data) {
    if (data is! List) return const [];
    final out = <CitySearchHit>[];
    final seen = <String>{};
    for (final raw in data) {
      if (raw is! Map) continue;
      final cls = '${raw['category'] ?? raw['class'] ?? ''}'.toLowerCase();
      final type = '${raw['addresstype'] ?? raw['type'] ?? ''}'.toLowerCase();
      if (cls.isNotEmpty &&
          cls != 'place' &&
          cls != 'boundary' &&
          !_placeTypes.contains(type)) {
        continue;
      }
      final lat = double.tryParse('${raw['lat']}');
      final lon = double.tryParse('${raw['lon']}');
      if (lat == null || lon == null) continue;
      final address = raw['address'];
      final nameFromAddress = address is Map
          ? '${address['city'] ?? address['town'] ?? address['village'] ?? address['municipality'] ?? address['hamlet'] ?? ''}'
                .trim()
          : '';
      final name = '${raw['name'] ?? nameFromAddress}'.trim();
      if (name.isEmpty) continue;
      final country = address is Map
          ? '${address['country'] ?? ''}'.trim()
          : '';
      final admin = address is Map
          ? '${address['state'] ?? address['county'] ?? ''}'.trim()
          : '';
      final key = _dedupeKey(name, lat, lon);
      if (!seen.add(key)) continue;
      out.add(
        CitySearchHit(
          name: name,
          country: country,
          admin: admin,
          latitude: lat,
          longitude: lon,
        ),
      );
    }
    return out;
  }

  static String _dedupeKey(String name, double lat, double lon) =>
      '${name.toLowerCase()}|${lat.toStringAsFixed(2)}|${lon.toStringAsFixed(2)}';
}
