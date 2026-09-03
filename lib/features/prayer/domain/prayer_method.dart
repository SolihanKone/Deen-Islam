import 'package:adhan_dart/adhan_dart.dart';

/// On-device salah calculation method (adhan_dart).
///
/// [auto] picks the official/local convention from the prayer location.
enum PrayerCalculationMethod {
  auto,
  muslimWorldLeague,
  northAmerica,
  egyptian,
  ummAlQura,
  karachi,
  turkiye,
  moonsightingCommittee,
  dubai,
  kuwait,
  qatar,
  singapore,
  morocco,
  france,
  indonesian,
  algerian,
  jordan,
  gulfRegion,
  russia,
  tunisia,
  tehran;

  static const PrayerCalculationMethod def = auto;

  static PrayerCalculationMethod parse(String? raw) {
    if (raw == null || raw.isEmpty || raw == 'auto') return auto;
    return PrayerCalculationMethod.values.firstWhere(
      (m) => m.name == raw,
      orElse: () => def,
    );
  }

  CalculationParameters parameters() {
    return switch (this) {
      auto => CalculationMethodParameters.muslimWorldLeague(),
      muslimWorldLeague => CalculationMethodParameters.muslimWorldLeague(),
      northAmerica => CalculationMethodParameters.northAmerica(),
      egyptian => CalculationMethodParameters.egyptian(),
      ummAlQura => CalculationMethodParameters.ummAlQura(),
      karachi => CalculationMethodParameters.karachi(),
      turkiye => CalculationMethodParameters.turkiye(),
      moonsightingCommittee =>
        CalculationMethodParameters.moonsightingCommittee(),
      dubai => CalculationMethodParameters.dubai(),
      kuwait => CalculationMethodParameters.kuwait(),
      qatar => CalculationMethodParameters.qatar(),
      singapore => CalculationMethodParameters.singapore(),
      morocco => CalculationMethodParameters.morocco(),
      france => CalculationMethodParameters.france(),
      indonesian => CalculationMethodParameters.indonesian(),
      algerian => CalculationMethodParameters.algerian(),
      jordan => CalculationMethodParameters.jordan(),
      gulfRegion => CalculationMethodParameters.gulfRegion(),
      russia => CalculationMethodParameters.russia(),
      tunisia => CalculationMethodParameters.tunisia(),
      tehran => CalculationMethodParameters.tehran(),
    };
  }
}

/// Asr shadow length: Shafi'i / Maliki / Hanbali vs Hanafi.
///
/// [auto] follows the region's usual school.
enum PrayerMadhab {
  auto,
  shafi,
  hanafi;

  static const PrayerMadhab def = auto;

  static PrayerMadhab parse(String? raw) {
    if (raw == 'hanafi') return hanafi;
    if (raw == 'shafi') return shafi;
    return auto;
  }

  Madhab toAdhan() => switch (this) {
    auto || shafi => Madhab.shafi,
    hanafi => Madhab.hanafi,
  };
}
