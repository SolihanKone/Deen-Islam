import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/api_constants.dart';
import '../../prayer/domain/prayer_method.dart';
import '../../quran/domain/arabic_playback_speed.dart';
import '../../quran/domain/entities/piper_voice.dart';

class AppSettings extends Equatable {
  const AppSettings({
    required this.themeMode,
    required this.localeCode,
    required this.defaultTranslationId,
    required this.reciterId,
    required this.quranFontScale,
    required this.showTranslation,
    required this.prayerNotifications,
    required this.prayerCalculationMethod,
    required this.prayerMadhab,
    required this.prayerMethodAuto,
    required this.prayerMadhabAuto,
    required this.translationVoiceId,
    required this.arabicPlaybackSpeed,
    required this.repeatAyah,
    required this.useGpsLocation,
    required this.locationCityId,
    required this.locationLabel,
    required this.locationCountry,
    required this.adhanSound,
  });

  final ThemeMode themeMode;
  final String localeCode;
  final String defaultTranslationId;
  final String reciterId;
  final double quranFontScale;
  final bool showTranslation;
  final bool prayerNotifications;
  final PrayerCalculationMethod prayerCalculationMethod;
  final PrayerMadhab prayerMadhab;
  final bool prayerMethodAuto;
  final bool prayerMadhabAuto;
  final String translationVoiceId;
  final double arabicPlaybackSpeed;
  final bool repeatAyah;
  final bool useGpsLocation;
  final String locationCityId;
  final String locationLabel;
  final String locationCountry;
  final bool adhanSound;

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? localeCode,
    String? defaultTranslationId,
    String? reciterId,
    double? quranFontScale,
    bool? showTranslation,
    bool? prayerNotifications,
    PrayerCalculationMethod? prayerCalculationMethod,
    PrayerMadhab? prayerMadhab,
    bool? prayerMethodAuto,
    bool? prayerMadhabAuto,
    String? translationVoiceId,
    double? arabicPlaybackSpeed,
    bool? repeatAyah,
    bool? useGpsLocation,
    String? locationCityId,
    String? locationLabel,
    String? locationCountry,
    bool? adhanSound,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      localeCode: localeCode ?? this.localeCode,
      defaultTranslationId: defaultTranslationId ?? this.defaultTranslationId,
      reciterId: reciterId ?? this.reciterId,
      quranFontScale: quranFontScale ?? this.quranFontScale,
      showTranslation: showTranslation ?? this.showTranslation,
      prayerNotifications: prayerNotifications ?? this.prayerNotifications,
      prayerCalculationMethod:
          prayerCalculationMethod ?? this.prayerCalculationMethod,
      prayerMadhab: prayerMadhab ?? this.prayerMadhab,
      prayerMethodAuto: prayerMethodAuto ?? this.prayerMethodAuto,
      prayerMadhabAuto: prayerMadhabAuto ?? this.prayerMadhabAuto,
      translationVoiceId: translationVoiceId ?? this.translationVoiceId,
      arabicPlaybackSpeed: arabicPlaybackSpeed ?? this.arabicPlaybackSpeed,
      repeatAyah: repeatAyah ?? this.repeatAyah,
      useGpsLocation: useGpsLocation ?? this.useGpsLocation,
      locationCityId: locationCityId ?? this.locationCityId,
      locationLabel: locationLabel ?? this.locationLabel,
      locationCountry: locationCountry ?? this.locationCountry,
      adhanSound: adhanSound ?? this.adhanSound,
    );
  }

  static AppSettings fromMap(Map<dynamic, dynamic> box) {
    ThemeMode mode = ThemeMode.system;
    final t = box['theme'] as String?;
    if (t == 'light') mode = ThemeMode.light;
    if (t == 'dark') mode = ThemeMode.dark;

    final voiceId =
        box['translation_voice'] as String? ??
        box['piper_tts_voice'] as String? ??
        box['gemini_tts_voice'] as String?;

    return AppSettings(
      themeMode: mode,
      localeCode: box['locale'] as String? ?? 'en',
      defaultTranslationId:
          box['translation'] as String? ?? QuranEditions.englishSahih,
      reciterId: box['reciter'] as String? ?? 'mishary',
      quranFontScale: (box['font_scale'] as num?)?.toDouble() ?? 1.0,
      showTranslation: box['show_translation'] as bool? ?? true,
      prayerNotifications: box['prayer_notifications'] as bool? ?? false,
      prayerCalculationMethod: PrayerCalculationMethod.parse(
        box['prayer_method'] as String?,
      ),
      prayerMadhab: PrayerMadhab.parse(box['prayer_madhab'] as String?),
      prayerMethodAuto:
          box['prayer_method_auto'] as bool? ??
          _defaultMethodAuto(box['prayer_method'] as String?),
      prayerMadhabAuto:
          box['prayer_madhab_auto'] as bool? ??
          ((box['prayer_madhab'] as String?) != 'hanafi'),
      translationVoiceId: PiperVoice.migrateStoredId(voiceId),
      arabicPlaybackSpeed: ArabicPlaybackSpeed.sanitize(
        (box['arabic_playback_speed'] as num?)?.toDouble(),
      ),
      repeatAyah: box['repeat_ayah'] as bool? ?? false,
      useGpsLocation: box['use_gps_location'] as bool? ?? true,
      locationCityId: box['location_city_id'] as String? ?? '',
      locationLabel: box['location_label'] as String? ?? '',
      locationCountry:
          box['location_country'] as String? ??
          countryFromLabel(box['location_label'] as String? ?? ''),
      adhanSound: box['adhan_sound'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
    'theme': themeMode == ThemeMode.dark
        ? 'dark'
        : themeMode == ThemeMode.light
        ? 'light'
        : 'system',
    'locale': localeCode,
    'translation': defaultTranslationId,
    'reciter': reciterId,
    'font_scale': quranFontScale,
    'show_translation': showTranslation,
    'prayer_notifications': prayerNotifications,
    'prayer_method': prayerCalculationMethod.name,
    'prayer_madhab': prayerMadhab.name,
    'prayer_method_auto': prayerMethodAuto,
    'prayer_madhab_auto': prayerMadhabAuto,
    'translation_voice': translationVoiceId,
    'arabic_playback_speed': arabicPlaybackSpeed,
    'repeat_ayah': repeatAyah,
    'use_gps_location': useGpsLocation,
    'location_city_id': locationCityId,
    'location_label': locationLabel,
    'location_country': locationCountry,
    'adhan_sound': adhanSound,
  };

  @override
  List<Object?> get props => [
    themeMode,
    localeCode,
    defaultTranslationId,
    reciterId,
    quranFontScale,
    showTranslation,
    prayerNotifications,
    prayerCalculationMethod,
    prayerMadhab,
    prayerMethodAuto,
    prayerMadhabAuto,
    translationVoiceId,
    arabicPlaybackSpeed,
    repeatAyah,
    useGpsLocation,
    locationCityId,
    locationLabel,
    locationCountry,
    adhanSound,
  ];
}

String countryFromLabel(String label) {
  final i = label.lastIndexOf(',');
  if (i < 0) return '';
  return label.substring(i + 1).trim();
}

bool _defaultMethodAuto(String? stored) {
  return stored == null || stored == 'northAmerica' || stored == 'auto';
}
