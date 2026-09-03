import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../quran/domain/entities/piper_voice.dart';
import '../../../quran/domain/entities/reciter.dart';
import '../../../quran/presentation/providers/quran_prefs_provider.dart';
import '../../../quran/services/recitation_audio_cache.dart';
import '../../../prayer/domain/prayer_method.dart';
import '../../../prayer/services/prayer_notification_service.dart';
import '../../../prayer/presentation/providers/prayer_providers.dart';
import '../../../prayer/presentation/widgets/prayer_city_sheet.dart';
import '../providers/settings_provider.dart';
import '../widgets/settings_option_sheet.dart';
import '../widgets/translation_voice_sheet.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final bookmarkCount = ref.watch(quranPrefsProvider).bookmarks.length;
    final scheme = Theme.of(context).colorScheme;
    final t = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(t.settings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH,
          AppSpacing.sm,
          AppSpacing.screenH,
          AppSpacing.xl,
        ),
        children: [
          AppSectionHeader(title: t.appearance, subtitle: t.themeAndLanguage),
          AppSurfaceCard(
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(t.darkMode),
                  subtitle: Text(t.darkModeSubtitle),
                  value: s.themeMode == ThemeMode.dark,
                  onChanged: (v) => ref
                      .read(settingsProvider.notifier)
                      .setTheme(v ? ThemeMode.dark : ThemeMode.light),
                ),
                Divider(
                  height: 1,
                  color: scheme.outlineVariant.withValues(alpha: 0.5),
                ),
                SettingsPickerTile(
                  icon: Icons.language_rounded,
                  label: t.appLanguage,
                  value: _localeLabel(t, s.localeCode),
                  onTap: () async {
                    final next = await showSettingsOptionSheet<String>(
                      context: context,
                      title: t.appLanguage,
                      selected: s.localeCode,
                      options: [
                        SettingsOption(value: 'en', title: t.localeEnglish),
                        SettingsOption(value: 'ar', title: t.localeArabic),
                        SettingsOption(value: 'ur', title: t.localeUrdu),
                        SettingsOption(value: 'fr', title: t.localeFrench),
                      ],
                    );
                    if (next != null) {
                      await ref.read(settingsProvider.notifier).setLocale(next);
                    }
                  },
                ),
              ],
            ),
          ),
          AppSectionHeader(title: t.quran, subtitle: t.quranPrefsSubtitle),
          AppSurfaceCard(
            child: Column(
              children: [
                SettingsPickerTile(
                  icon: Icons.translate_rounded,
                  label: t.defaultTranslation,
                  value: t.translationEdition(s.defaultTranslationId),
                  onTap: () async {
                    final next = await showSettingsOptionSheet<String>(
                      context: context,
                      title: t.defaultTranslation,
                      selected: s.defaultTranslationId,
                      options: [
                        for (final id in QuranEditions.translationIds())
                          SettingsOption(
                            value: id,
                            title: t.translationEdition(id),
                          ),
                      ],
                    );
                    if (next != null) {
                      await ref
                          .read(settingsProvider.notifier)
                          .setTranslation(next);
                    }
                  },
                ),
                Divider(
                  height: 1,
                  color: scheme.outlineVariant.withValues(alpha: 0.5),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(t.showTranslation),
                  subtitle: Text(t.showTranslationSubtitle),
                  value: s.showTranslation,
                  onChanged: (v) =>
                      ref.read(settingsProvider.notifier).setShowTranslation(v),
                ),
                Divider(
                  height: 1,
                  color: scheme.outlineVariant.withValues(alpha: 0.5),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.arabicFontSize,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Slider(
                        value: s.quranFontScale,
                        min: 0.85,
                        max: 1.6,
                        divisions: 15,
                        label: s.quranFontScale.toStringAsFixed(2),
                        onChanged: (v) =>
                            ref.read(settingsProvider.notifier).setFontScale(v),
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  color: scheme.outlineVariant.withValues(alpha: 0.5),
                ),
                SettingsPickerTile(
                  icon: Icons.record_voice_over_rounded,
                  label: t.arabicReciter,
                  value: Reciter.byId(s.reciterId).name,
                  hint: t.arabicReciterHint,
                  onTap: () async {
                    final next = await showSettingsOptionSheet<String>(
                      context: context,
                      title: t.arabicReciter,
                      subtitle: t.arabicReciterSubtitle,
                      selected: s.reciterId,
                      options: [
                        for (final r in Reciter.presets)
                          SettingsOption(value: r.id, title: r.name),
                      ],
                    );
                    if (next != null) {
                      await ref
                          .read(settingsProvider.notifier)
                          .setReciter(next);
                    }
                  },
                ),
                Divider(
                  height: 1,
                  color: scheme.outlineVariant.withValues(alpha: 0.5),
                ),
                SettingsPickerTile(
                  icon: Icons.spatial_audio_off_rounded,
                  label: t.translationVoice,
                  value:
                      '${PiperVoice.byId(s.translationVoiceId).name} — ${t.voiceStyle(PiperVoice.byId(s.translationVoiceId).style)}',
                  hint: t.translationVoiceHint,
                  onTap: () =>
                      showTranslationVoiceSheet(context: context, ref: ref),
                ),
              ],
            ),
          ),
          AppSectionHeader(title: t.prayer, subtitle: t.prayerSettingsSubtitle),
          AppSurfaceCard(
            child: Column(
              children: [
                SettingsPickerTile(
                  icon: Icons.location_on_outlined,
                  label: t.prayerLocation,
                  value: prayerLocationLabel(
                    useGps: s.useGpsLocation,
                    cityId: s.locationCityId,
                    locationLabel: s.locationLabel,
                    coords: ref.watch(userPositionProvider).valueOrNull,
                    gpsLabel: t.currentLocation,
                    chooseCityLabel: t.chooseCity,
                  ),
                  hint: t.prayerLocationHint,
                  onTap: () => showPrayerCitySheet(context: context, ref: ref),
                ),
                Divider(
                  height: 1,
                  color: scheme.outlineVariant.withValues(alpha: 0.5),
                ),
                SettingsPickerTile(
                  icon: Icons.calculate_outlined,
                  label: t.prayerCalculationMethod,
                  value: s.prayerMethodAuto
                      ? t.automaticMethodLabel(
                          t.prayerMethodName(
                            ref.watch(resolvedPrayerConventionProvider).method,
                          ),
                        )
                      : t.prayerMethodName(s.prayerCalculationMethod),
                  hint: t.prayerCalculationMethodHint,
                  onTap: () async {
                    final next =
                        await showSettingsOptionSheet<PrayerCalculationMethod>(
                          context: context,
                          title: t.prayerCalculationMethod,
                          subtitle: t.prayerCalculationMethodHint,
                          selected: s.prayerMethodAuto
                              ? PrayerCalculationMethod.auto
                              : s.prayerCalculationMethod,
                          options: [
                            for (final method in PrayerCalculationMethod.values)
                              SettingsOption(
                                value: method,
                                title: t.prayerMethodName(method),
                                subtitle: method == PrayerCalculationMethod.auto
                                    ? t.prayerMethodName(
                                        ref
                                            .read(
                                              resolvedPrayerConventionProvider,
                                            )
                                            .method,
                                      )
                                    : null,
                              ),
                          ],
                        );
                    if (next != null) {
                      await ref
                          .read(settingsProvider.notifier)
                          .setPrayerCalculationMethod(next);
                    }
                  },
                ),
                Divider(
                  height: 1,
                  color: scheme.outlineVariant.withValues(alpha: 0.5),
                ),
                SettingsPickerTile(
                  icon: Icons.mosque_outlined,
                  label: t.prayerMadhab,
                  value: s.prayerMadhabAuto
                      ? t.automaticMethodLabel(
                          t.prayerMadhabName(
                            ref.watch(resolvedPrayerConventionProvider).madhab,
                          ),
                        )
                      : t.prayerMadhabName(s.prayerMadhab),
                  hint: t.prayerMadhabHint,
                  onTap: () async {
                    final next = await showSettingsOptionSheet<PrayerMadhab>(
                      context: context,
                      title: t.prayerMadhab,
                      subtitle: t.prayerMadhabHint,
                      selected: s.prayerMadhabAuto
                          ? PrayerMadhab.auto
                          : s.prayerMadhab,
                      options: [
                        for (final madhab in PrayerMadhab.values)
                          SettingsOption(
                            value: madhab,
                            title: t.prayerMadhabName(madhab),
                          ),
                      ],
                    );
                    if (next != null) {
                      await ref
                          .read(settingsProvider.notifier)
                          .setPrayerMadhab(next);
                    }
                  },
                ),
                Divider(
                  height: 1,
                  color: scheme.outlineVariant.withValues(alpha: 0.5),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(t.prayerNotifications),
                  subtitle: Text(t.prayerNotificationsSubtitle),
                  value: s.prayerNotifications,
                  onChanged: (v) async {
                    if (v) {
                      final pluginOk =
                          await PrayerNotificationService.requestOsPermissions();
                      final st = await Permission.notification.request();
                      final granted =
                          pluginOk ||
                          st.isGranted ||
                          st.isLimited ||
                          st.isProvisional;
                      if (!granted && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(t.notificationPermissionDenied),
                          ),
                        );
                        return;
                      }
                      await Permission.scheduleExactAlarm.request();
                    } else {
                      await PrayerNotificationService.cancelAll();
                    }
                    await ref
                        .read(settingsProvider.notifier)
                        .setPrayerNotifications(v);
                    if (v) {
                      final count = await syncPrayerNotifications(ref);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            count == null || count == 0
                                ? t.prayerRemindersFailed
                                : t.prayerRemindersScheduled(count),
                          ),
                        ),
                      );
                    }
                  },
                ),
                Divider(
                  height: 1,
                  color: scheme.outlineVariant.withValues(alpha: 0.5),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(t.adhanSound),
                  subtitle: Text(t.adhanSoundSubtitle),
                  value: s.adhanSound,
                  onChanged: s.prayerNotifications
                      ? (v) async {
                          await ref
                              .read(settingsProvider.notifier)
                              .setAdhanSound(v);
                          await syncPrayerNotifications(ref);
                        }
                      : null,
                ),
              ],
            ),
          ),
          AppSectionHeader(title: t.storage),
          AppActionTile(
            icon: Icons.offline_bolt_outlined,
            title: t.recitationCache,
            subtitle: ref
                .watch(recitationCacheBytesProvider)
                .when(
                  data: t.recitationCacheSize,
                  loading: () => t.recitationCache,
                  error: (_, __) => t.recitationCache,
                ),
            onTap: () async {
              await RecitationAudioCache.instance.clearAll();
              ref.invalidate(recitationCacheBytesProvider);
              if (!context.mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(t.recitationCacheCleared)));
            },
          ),
          AppSectionHeader(title: t.bookmarks),
          AppActionTile(
            icon: Icons.bookmark_rounded,
            title: t.bookmarks,
            subtitle: bookmarkCount == 0
                ? t.noBookmarksYet
                : t.savedCount(bookmarkCount),
            onTap: () => context.push('/bookmarks'),
          ),
          AppSectionHeader(title: t.legal),
          AppActionTile(
            icon: Icons.privacy_tip_outlined,
            title: t.privacyPolicy,
            subtitle: t.privacyPolicySubtitle,
            onTap: () => context.push('/privacy'),
          ),
        ],
      ),
    );
  }

  static String _localeLabel(AppStrings t, String code) => switch (code) {
    'ar' => t.localeArabic,
    'ur' => t.localeUrdu,
    'fr' => t.localeFrench,
    _ => t.localeEnglish,
  };
}
