import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;

import '../data/prayer_time_zone.dart';
import '../domain/prayer_times_day.dart';
import '../../../core/l10n/app_strings.dart';

/// Schedules local notifications at salah times when enabled in settings.
class PrayerNotificationService {
  PrayerNotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    await _ensureLocalTz();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(
        android: android,
        iOS: darwin,
        macOS: darwin,
      ),
    );
    _initialized = true;
  }

  static Future<void> _ensureLocalTz() async {
    PrayerTimeZone.ensureInitialized();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (e) {
      debugPrint('Prayer notifications: timezone fallback ($e)');
      try {
        tz.setLocalLocation(tz.getLocation('Etc/UTC'));
      } catch (_) {
        tz.setLocalLocation(tz.UTC);
      }
    }
  }

  /// Prompts for iOS/Android notification permission. Returns whether alerts
  /// can be posted.
  static Future<bool> requestOsPermissions() async {
    await init();
    var granted = false;
    try {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final iosOk = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      if (iosOk == true) granted = true;
    } catch (e) {
      debugPrint('Prayer notifications: iOS permission error $e');
    }
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final androidOk = await android?.requestNotificationsPermission();
      if (androidOk == true) granted = true;
      await android?.requestExactAlarmsPermission();
    } catch (e) {
      debugPrint('Prayer notifications: Android permission error $e');
    }
    return granted;
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  static Future<AndroidScheduleMode> _androidMode() async {
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final canExact = await android?.canScheduleExactNotifications();
      if (canExact == true) {
        return AndroidScheduleMode.exactAllowWhileIdle;
      }
    } catch (_) {}
    return AndroidScheduleMode.inexactAllowWhileIdle;
  }

  /// Wall-clock time in [tz.local], matching calculated salah times.
  @visibleForTesting
  static tz.TZDateTime tzFromWallClock(DateTime wall) {
    return tz.TZDateTime(
      tz.local,
      wall.year,
      wall.month,
      wall.day,
      wall.hour,
      wall.minute,
    );
  }

  /// Schedules using the device wall clock derived from calculated times.
  static Future<int> scheduleDay(PrayerTimesDay day) => scheduleUpcoming([day]);

  /// Replaces all prayer alerts with [days] (typically the next 7 days).
  ///
  /// Adhan clip: Wikimedia Commons “Adhan wiki.oga” by Jarih,
  /// CC BY-SA 3.0 (trimmed to notification length).
  ///
  /// Returns how many notifications were actually scheduled.
  static Future<int> scheduleUpcoming(
    List<PrayerTimesDay> days, {
    String localeCode = 'en',
    bool adhanSound = true,
  }) async {
    await init();
    await cancelAll();
    final t = AppStrings.fromCode(localeCode);
    final mode = await _androidMode();
    var id = 0;
    var scheduled = 0;
    final now = tz.TZDateTime.now(tz.local);
    for (final day in days) {
      for (final e in day.ordered) {
        final when = day.instant(e.value);
        if (!when.isAfter(now)) continue;
        final ok = await _scheduleOne(
          id: id,
          title: t.prayerName(e.key),
          body: '${t.prayerTimeBody} — ${day.dateReadable}',
          when: when,
          t: t,
          mode: mode,
          adhanSound: adhanSound,
        );
        id++;
        if (ok) scheduled++;
      }
    }
    debugPrint('Prayer notifications: scheduled $scheduled alerts');
    return scheduled;
  }

  static Future<bool> _scheduleOne({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime when,
    required AppStrings t,
    required AndroidScheduleMode mode,
    required bool adhanSound,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        when,
        _details(t, adhanSound: adhanSound),
        androidScheduleMode: mode,
      );
      return true;
    } on ArgumentError catch (e) {
      debugPrint('Prayer notifications: skip id=$id $e');
      return false;
    } catch (e) {
      debugPrint(
        'Prayer notifications: id=$id failed ($e), retrying default sound',
      );
      if (!adhanSound) return false;
      try {
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          when,
          _details(t, adhanSound: false),
          androidScheduleMode: mode,
        );
        return true;
      } catch (e2) {
        debugPrint('Prayer notifications: id=$id retry failed $e2');
        return false;
      }
    }
  }

  static NotificationDetails _details(
    AppStrings t, {
    required bool adhanSound,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        adhanSound ? 'prayer_adhan_v2' : 'prayer_channel',
        t.prayerTimes,
        channelDescription: t.salahReminders,
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        sound: adhanSound
            ? const RawResourceAndroidNotificationSound('adhan')
            : null,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        category: AndroidNotificationCategory.alarm,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        presentBanner: true,
        presentList: true,
        sound: adhanSound ? 'adhan.wav' : null,
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
      macOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        presentBanner: true,
        presentList: true,
        sound: adhanSound ? 'adhan.wav' : null,
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    );
  }
}
