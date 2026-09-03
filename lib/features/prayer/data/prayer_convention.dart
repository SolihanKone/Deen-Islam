import '../domain/prayer_method.dart';

/// Official/local salah convention for a country or region.
class PrayerConvention {
  const PrayerConvention({required this.method, required this.madhab});

  final PrayerCalculationMethod method;
  final PrayerMadhab madhab;

  /// Picks the method and Asr school used by mosques in this place.
  ///
  /// [methodOverride] / [madhabOverride] skip auto when the user chose one.
  static PrayerConvention resolve({
    String? country,
    double? latitude,
    double? longitude,
    PrayerCalculationMethod? methodOverride,
    PrayerMadhab? madhabOverride,
  }) {
    final auto =
        _fromCountry(country) ??
        _fromCoordinates(latitude, longitude) ??
        const PrayerConvention(
          method: PrayerCalculationMethod.muslimWorldLeague,
          madhab: PrayerMadhab.shafi,
        );
    return PrayerConvention(
      method: methodOverride ?? auto.method,
      madhab: madhabOverride ?? auto.madhab,
    );
  }

  static PrayerConvention? _fromCountry(String? raw) {
    final key = _norm(raw);
    if (key.isEmpty) return null;
    return _countries[key] ?? _countries[_aliases[key] ?? ''];
  }

  static PrayerConvention? _fromCoordinates(double? lat, double? lng) {
    if (lat == null || lng == null) return null;
    // Arabian Peninsula
    if (lat >= 12 && lat <= 32.5 && lng >= 34 && lng <= 60) {
      return _umm;
    }
    // Indonesia / Malaysia / Brunei
    if (lat >= -11 && lat <= 8 && lng >= 95 && lng <= 141) {
      return _indo;
    }
    // South Asia
    if (lat >= 5 && lat <= 37 && lng >= 60 && lng <= 97) {
      return _karachi;
    }
    // Turkey
    if (lat >= 35.8 && lat <= 42.3 && lng >= 25.6 && lng <= 45) {
      return _turkiye;
    }
    // North Africa (Egypt-ward)
    if (lat >= 22 && lat <= 32 && lng >= 24 && lng <= 37) {
      return _egypt;
    }
    // Maghreb west
    if (lat >= 27 && lat <= 36.5 && lng >= -13 && lng <= 0) {
      return _morocco;
    }
    // US & Canada
    if (lat >= 24 && lat <= 72 && lng >= -170 && lng <= -52) {
      return _isna;
    }
    return null;
  }

  static String _norm(String? raw) {
    if (raw == null) return '';
    var s = raw.trim().toLowerCase();
    const replacements = {
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'ü': 'u',
      'ö': 'o',
      'ä': 'a',
      'á': 'a',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'ç': 'c',
      'ñ': 'n',
      'ş': 's',
      'ı': 'i',
      'ğ': 'g',
      'â': 'a',
    };
    for (final e in replacements.entries) {
      s = s.replaceAll(e.key, e.value);
    }
    return s.replaceAll(RegExp(r'[^a-z]'), '');
  }

  static const _mwl = PrayerConvention(
    method: PrayerCalculationMethod.muslimWorldLeague,
    madhab: PrayerMadhab.shafi,
  );
  static const _isna = PrayerConvention(
    method: PrayerCalculationMethod.northAmerica,
    madhab: PrayerMadhab.shafi,
  );
  static const _egypt = PrayerConvention(
    method: PrayerCalculationMethod.egyptian,
    madhab: PrayerMadhab.shafi,
  );
  static const _umm = PrayerConvention(
    method: PrayerCalculationMethod.ummAlQura,
    madhab: PrayerMadhab.shafi,
  );
  static const _karachi = PrayerConvention(
    method: PrayerCalculationMethod.karachi,
    madhab: PrayerMadhab.hanafi,
  );
  static const _turkiye = PrayerConvention(
    method: PrayerCalculationMethod.turkiye,
    madhab: PrayerMadhab.hanafi,
  );
  static const _dubai = PrayerConvention(
    method: PrayerCalculationMethod.dubai,
    madhab: PrayerMadhab.shafi,
  );
  static const _kuwait = PrayerConvention(
    method: PrayerCalculationMethod.kuwait,
    madhab: PrayerMadhab.shafi,
  );
  static const _qatar = PrayerConvention(
    method: PrayerCalculationMethod.qatar,
    madhab: PrayerMadhab.shafi,
  );
  static const _singapore = PrayerConvention(
    method: PrayerCalculationMethod.singapore,
    madhab: PrayerMadhab.shafi,
  );
  static const _morocco = PrayerConvention(
    method: PrayerCalculationMethod.morocco,
    madhab: PrayerMadhab.shafi,
  );
  static const _france = PrayerConvention(
    method: PrayerCalculationMethod.france,
    madhab: PrayerMadhab.shafi,
  );
  static const _indo = PrayerConvention(
    method: PrayerCalculationMethod.indonesian,
    madhab: PrayerMadhab.shafi,
  );
  static const _algeria = PrayerConvention(
    method: PrayerCalculationMethod.algerian,
    madhab: PrayerMadhab.shafi,
  );
  static const _jordan = PrayerConvention(
    method: PrayerCalculationMethod.jordan,
    madhab: PrayerMadhab.shafi,
  );
  static const _gulf = PrayerConvention(
    method: PrayerCalculationMethod.gulfRegion,
    madhab: PrayerMadhab.shafi,
  );
  static const _russia = PrayerConvention(
    method: PrayerCalculationMethod.russia,
    madhab: PrayerMadhab.hanafi,
  );
  static const _tunisia = PrayerConvention(
    method: PrayerCalculationMethod.tunisia,
    madhab: PrayerMadhab.shafi,
  );
  static const _tehran = PrayerConvention(
    method: PrayerCalculationMethod.tehran,
    madhab: PrayerMadhab.shafi,
  );
  static const _hanafiMwl = PrayerConvention(
    method: PrayerCalculationMethod.muslimWorldLeague,
    madhab: PrayerMadhab.hanafi,
  );

  static const _aliases = {
    'usa': 'unitedstates',
    'us': 'unitedstates',
    'america': 'unitedstates',
    'unitedstatesofamerica': 'unitedstates',
    'uk': 'unitedkingdom',
    'britain': 'unitedkingdom',
    'greatbritain': 'unitedkingdom',
    'england': 'unitedkingdom',
    'uae': 'unitedarabemirates',
    'emirates': 'unitedarabemirates',
    'ksa': 'saudiarabia',
    'saudi': 'saudiarabia',
    'turkey': 'turkiye',
    'turkiye': 'turkiye',
    'westbank': 'palestine',
    'gaza': 'palestine',
    'holland': 'netherlands',
    'thenetherlands': 'netherlands',
    'korea': 'southkorea',
    'republicofkorea': 'southkorea',
    'prchina': 'china',
    'peoplesrepublicofchina': 'china',
    'bosnia': 'bosniaandherzegovina',
    'bih': 'bosniaandherzegovina',
  };

  static const _countries = {
    'saudiarabia': _umm,
    'yemen': _umm,
    'oman': _umm,
    'unitedarabemirates': _dubai,
    'dubai': _dubai,
    'qatar': _qatar,
    'kuwait': _kuwait,
    'bahrain': _gulf,
    'jordan': _jordan,
    'palestine': _jordan,
    'israel': _jordan,
    'lebanon': _mwl,
    'syria': _mwl,
    'iraq': _hanafiMwl,
    'iran': _tehran,
    'egypt': _egypt,
    'sudan': _egypt,
    'libya': _egypt,
    'morocco': _morocco,
    'algeria': _algeria,
    'tunisia': _tunisia,
    'mauritania': _morocco,
    'westernsahara': _morocco,
    'turkiye': _turkiye,
    'turkey': _turkiye,
    'northerncyprus': _turkiye,
    'pakistan': _karachi,
    'india': _karachi,
    'bangladesh': _karachi,
    'afghanistan': _karachi,
    'srilanka': _karachi,
    'maldives': _karachi,
    'nepal': _karachi,
    'indonesia': _indo,
    'malaysia': _singapore,
    'singapore': _singapore,
    'brunei': _singapore,
    'bruneidarussalam': _singapore,
    'unitedstates': _isna,
    'canada': _isna,
    'unitedkingdom': _mwl,
    'france': _france,
    'belgium': _mwl,
    'netherlands': _mwl,
    'germany': _mwl,
    'austria': _mwl,
    'switzerland': _mwl,
    'sweden': _mwl,
    'norway': _mwl,
    'denmark': _mwl,
    'ireland': _mwl,
    'spain': _mwl,
    'italy': _mwl,
    'portugal': _mwl,
    'greece': _mwl,
    'bosniaandherzegovina': _hanafiMwl,
    'kosovo': _hanafiMwl,
    'albania': _hanafiMwl,
    'northmacedonia': _hanafiMwl,
    'montenegro': _hanafiMwl,
    'serbia': _hanafiMwl,
    'russia': _russia,
    'uzbekistan': _karachi,
    'kazakhstan': _karachi,
    'kyrgyzstan': _karachi,
    'tajikistan': _karachi,
    'turkmenistan': _karachi,
    'azerbaijan': _hanafiMwl,
    'nigeria': _mwl,
    'senegal': _mwl,
    'mali': _mwl,
    'burkinafaso': _mwl,
    'niger': _mwl,
    'chad': _mwl,
    'guinea': _mwl,
    'gambia': _mwl,
    'sierraleone': _mwl,
    'ivorycoast': _mwl,
    'cotedivoire': _mwl,
    'ghana': _mwl,
    'cameroon': _mwl,
    'somalia': _mwl,
    'ethiopia': _mwl,
    'kenya': _mwl,
    'tanzania': _mwl,
    'uganda': _mwl,
    'djibouti': _mwl,
    'southafrica': _mwl,
    'australia': _mwl,
    'newzealand': _mwl,
    'japan': _mwl,
    'southkorea': _mwl,
    'china': _hanafiMwl,
    'mexico': _mwl,
    'brazil': _mwl,
    'argentina': _mwl,
  };
}
