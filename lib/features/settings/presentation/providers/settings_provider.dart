import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/storage/hive_boxes.dart';
import '../../../prayer/data/prayer_cities.dart';
import '../../../prayer/domain/prayer_method.dart';
import '../../../quran/domain/arabic_playback_speed.dart';
import '../../domain/app_settings.dart';

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

class SettingsNotifier extends Notifier<AppSettings> {
  Box<dynamic> get _box => Hive.box<dynamic>(HiveBoxes.settings);

  @override
  AppSettings build() {
    final map = <dynamic, dynamic>{};
    for (final k in _box.keys) {
      map[k] = _box.get(k);
    }
    return AppSettings.fromMap(map);
  }

  Future<void> _persist(AppSettings next) async {
    for (final e in next.toMap().entries) {
      await _box.put(e.key, e.value);
    }
    state = next;
  }

  Future<void> setTheme(ThemeMode mode) =>
      _persist(state.copyWith(themeMode: mode));

  /// Updates UI locale and syncs the Quran translation edition to match.
  Future<void> setLocale(String code) async {
    final translationId = translationIdForLocale(code);
    await _persist(
      state.copyWith(localeCode: code, defaultTranslationId: translationId),
    );
  }

  Future<void> setTranslation(String id) =>
      _persist(state.copyWith(defaultTranslationId: id));

  Future<void> setReciter(String id) => _persist(state.copyWith(reciterId: id));

  Future<void> setTranslationVoice(String id) =>
      _persist(state.copyWith(translationVoiceId: id));

  Future<void> setArabicPlaybackSpeed(double speed) => _persist(
    state.copyWith(arabicPlaybackSpeed: ArabicPlaybackSpeed.sanitize(speed)),
  );

  Future<void> setFontScale(double v) =>
      _persist(state.copyWith(quranFontScale: v.clamp(0.85, 1.6)));

  Future<void> setShowTranslation(bool v) =>
      _persist(state.copyWith(showTranslation: v));

  Future<void> setPrayerNotifications(bool v) =>
      _persist(state.copyWith(prayerNotifications: v));

  Future<void> setPrayerCalculationMethod(PrayerCalculationMethod method) =>
      _persist(
        state.copyWith(
          prayerCalculationMethod: method,
          prayerMethodAuto: method == PrayerCalculationMethod.auto,
        ),
      );

  Future<void> setPrayerMadhab(PrayerMadhab madhab) => _persist(
    state.copyWith(
      prayerMadhab: madhab,
      prayerMadhabAuto: madhab == PrayerMadhab.auto,
    ),
  );

  Future<void> setRepeatAyah(bool v) => _persist(state.copyWith(repeatAyah: v));

  Future<void> setAdhanSound(bool v) => _persist(state.copyWith(adhanSound: v));

  Future<void> setUseGpsLocation() =>
      _persist(state.copyWith(useGpsLocation: true, locationCountry: ''));

  Future<void> setLocationCity(String cityId) {
    final city = PrayerCities.byId(cityId);
    return _persist(
      state.copyWith(
        useGpsLocation: false,
        locationCityId: cityId,
        locationLabel: city?.label ?? '',
        locationCountry: city?.country ?? '',
      ),
    );
  }

  Future<void> setManualLocation({
    required String label,
    required double latitude,
    required double longitude,
    String cityId = '',
    String country = '',
  }) async {
    await _box.put(HiveBoxes.lastLatitude, latitude);
    await _box.put(HiveBoxes.lastLongitude, longitude);
    await _persist(
      state.copyWith(
        useGpsLocation: false,
        locationCityId: cityId,
        locationLabel: label,
        locationCountry: country.isNotEmpty ? country : countryFromLabel(label),
      ),
    );
  }

  static String translationIdForLocale(String code) => switch (code) {
    'ur' => QuranEditions.urdu,
    'fr' => QuranEditions.french,
    // Arabic UI still uses an English meaning translation (no ar edition).
    'ar' => QuranEditions.englishSahih,
    _ => QuranEditions.englishSahih,
  };
}
