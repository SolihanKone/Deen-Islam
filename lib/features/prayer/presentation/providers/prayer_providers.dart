import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/storage/hive_boxes.dart';
import '../../../settings/domain/app_settings.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/prayer_cities.dart';
import '../../data/prayer_convention.dart';
import '../../data/prayer_times_calculator.dart';
import '../../domain/prayer_coordinates.dart';
import '../../domain/prayer_method.dart';
import '../../domain/prayer_times_day.dart';
import '../../services/prayer_notification_service.dart';

final userPositionProvider = FutureProvider<PrayerCoordinates>((ref) async {
  final settings = ref.watch(settingsProvider);
  final box = Hive.box<dynamic>(HiveBoxes.settings);
  final cached = _cachedCoordinates(box);

  if (!settings.useGpsLocation) {
    final city = PrayerCities.byId(settings.locationCityId);
    if (city != null) {
      await _persistCoordinates(box, city.coords);
      return city.coords;
    }
    if (cached != null) return cached;
  }

  var perm = await Geolocator.checkPermission();
  if (perm == LocationPermission.denied) {
    perm = await Geolocator.requestPermission();
  }
  if (perm == LocationPermission.denied ||
      perm == LocationPermission.deniedForever) {
    final city = PrayerCities.byId(settings.locationCityId);
    if (city != null) return city.coords;
    if (cached != null) return cached;
    throw Exception('Location permission denied');
  }

  try {
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 8),
      ),
    );
    final coords = PrayerCoordinates(
      latitude: pos.latitude,
      longitude: pos.longitude,
    );
    await _persistCoordinates(box, coords);
    return coords;
  } catch (_) {
    final last = await Geolocator.getLastKnownPosition();
    if (last != null) {
      final coords = PrayerCoordinates(
        latitude: last.latitude,
        longitude: last.longitude,
      );
      await _persistCoordinates(box, coords);
      return coords;
    }
    final city = PrayerCities.byId(settings.locationCityId);
    if (city != null) return city.coords;
    if (cached != null) return cached;
    rethrow;
  }
});

PrayerConvention resolvedPrayerConvention({
  required bool methodAuto,
  required bool madhabAuto,
  required PrayerCalculationMethod method,
  required PrayerMadhab madhab,
  required String country,
  required String locationLabel,
  required bool useGps,
  PrayerCoordinates? coords,
}) {
  var resolvedCountry = country.trim();
  if (resolvedCountry.isEmpty) {
    resolvedCountry = countryFromLabel(locationLabel);
  }
  if (resolvedCountry.isEmpty && useGps && coords != null) {
    resolvedCountry =
        PrayerCities.nearest(
          coords.latitude,
          coords.longitude,
          maxKm: 400,
        )?.country ??
        '';
  }
  return PrayerConvention.resolve(
    country: resolvedCountry,
    latitude: coords?.latitude,
    longitude: coords?.longitude,
    methodOverride: (!methodAuto && method != PrayerCalculationMethod.auto)
        ? method
        : null,
    madhabOverride: (!madhabAuto && madhab != PrayerMadhab.auto)
        ? madhab
        : null,
  );
}

final resolvedPrayerConventionProvider = Provider<PrayerConvention>((ref) {
  final settings = ref.watch(settingsProvider);
  final coords = ref.watch(userPositionProvider).valueOrNull;
  return resolvedPrayerConvention(
    methodAuto: settings.prayerMethodAuto,
    madhabAuto: settings.prayerMadhabAuto,
    method: settings.prayerCalculationMethod,
    madhab: settings.prayerMadhab,
    country: settings.locationCountry,
    locationLabel: settings.locationLabel,
    useGps: settings.useGpsLocation,
    coords: coords,
  );
});

final prayerTimesProvider = FutureProvider<PrayerTimesDay>((ref) async {
  final coords = await ref.watch(userPositionProvider.future);
  final convention = ref.watch(resolvedPrayerConventionProvider);
  return PrayerTimesCalculator.forDate(
    DateTime.now(),
    coords,
    method: convention.method,
    madhab: convention.madhab,
  );
});

final prayerTimesTomorrowProvider = FutureProvider<PrayerTimesDay>((ref) async {
  final coords = await ref.watch(userPositionProvider.future);
  final convention = ref.watch(resolvedPrayerConventionProvider);
  final now = DateTime.now();
  final tomorrow = DateTime(
    now.year,
    now.month,
    now.day,
  ).add(const Duration(days: 1));
  return PrayerTimesCalculator.forDate(
    tomorrow,
    coords,
    method: convention.method,
    madhab: convention.madhab,
  );
});

int _notificationSyncGen = 0;

/// Returns how many alerts were scheduled, or null if scheduling failed.
Future<int?> syncPrayerNotifications(WidgetRef ref) async {
  final gen = ++_notificationSyncGen;
  await Future<void>.delayed(const Duration(milliseconds: 50));
  if (gen != _notificationSyncGen) return null;

  final settings = ref.read(settingsProvider);
  if (!settings.prayerNotifications) {
    await PrayerNotificationService.cancelAll();
    return 0;
  }

  try {
    final coords = await ref.read(userPositionProvider.future);
    if (gen != _notificationSyncGen) return null;
    final convention = resolvedPrayerConvention(
      methodAuto: settings.prayerMethodAuto,
      madhabAuto: settings.prayerMadhabAuto,
      method: settings.prayerCalculationMethod,
      madhab: settings.prayerMadhab,
      country: settings.locationCountry,
      locationLabel: settings.locationLabel,
      useGps: settings.useGpsLocation,
      coords: coords,
    );
    final days = PrayerTimesCalculator.upcoming(
      DateTime.now(),
      coords,
      method: convention.method,
      madhab: convention.madhab,
    );
    return PrayerNotificationService.scheduleUpcoming(
      days,
      localeCode: settings.localeCode,
      adhanSound: settings.adhanSound,
    );
  } catch (e, st) {
    debugPrint('Prayer notifications: sync failed $e\n$st');
    return null;
  }
}

String prayerLocationLabel({
  required bool useGps,
  required String cityId,
  String locationLabel = '',
  PrayerCoordinates? coords,
  required String gpsLabel,
  required String chooseCityLabel,
}) {
  if (!useGps) {
    if (locationLabel.trim().isNotEmpty) return locationLabel.trim();
    return PrayerCities.byId(cityId)?.label ?? chooseCityLabel;
  }
  if (coords != null) {
    final near = PrayerCities.nearest(coords.latitude, coords.longitude);
    if (near != null) return '$gpsLabel · ${near.name}';
  }
  return gpsLabel;
}

PrayerCoordinates? _cachedCoordinates(Box<dynamic> box) {
  final lat = box.get(HiveBoxes.lastLatitude);
  final lng = box.get(HiveBoxes.lastLongitude);
  if (lat is num && lng is num) {
    return PrayerCoordinates(
      latitude: lat.toDouble(),
      longitude: lng.toDouble(),
    );
  }
  return null;
}

Future<void> _persistCoordinates(
  Box<dynamic> box,
  PrayerCoordinates coords,
) async {
  await box.put(HiveBoxes.lastLatitude, coords.latitude);
  await box.put(HiveBoxes.lastLongitude, coords.longitude);
}
