import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../domain/next_prayer.dart' as prayer_next;
import '../../domain/prayer_times_day.dart';
import '../providers/prayer_providers.dart';
import '../widgets/prayer_city_sheet.dart';

class PrayerScreen extends ConsumerStatefulWidget {
  const PrayerScreen({super.key});

  @override
  ConsumerState<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends ConsumerState<PrayerScreen> {
  Timer? _tick;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(prayerTimesProvider);
    final tomorrow = ref.watch(prayerTimesTomorrowProvider).valueOrNull;
    final settings = ref.watch(settingsProvider);
    final scheme = Theme.of(context).colorScheme;
    final t = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.prayer),
        actions: [
          IconButton(
            tooltip: t.refresh,
            onPressed: () {
              ref.invalidate(userPositionProvider);
              ref.invalidate(prayerTimesProvider);
              ref.invalidate(prayerTimesTomorrowProvider);
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_off_rounded, size: 48, color: scheme.error),
                const SizedBox(height: 12),
                Text(
                  t.enableLocationForPrayerTimes,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () =>
                      showPrayerCitySheet(context: context, ref: ref),
                  icon: const Icon(Icons.search_rounded),
                  label: Text(t.chooseCity),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    ref.invalidate(userPositionProvider);
                    ref.invalidate(prayerTimesProvider);
                    ref.invalidate(prayerTimesTomorrowProvider);
                  },
                  child: Text(t.retry),
                ),
              ],
            ),
          ),
        ),
        data: (day) {
          final next = prayer_next.nextPrayer(_now, day, tomorrow: tomorrow);
          final coords = ref.watch(userPositionProvider).valueOrNull;
          final location = prayerLocationLabel(
            useGps: settings.useGpsLocation,
            cityId: settings.locationCityId,
            locationLabel: settings.locationLabel,
            coords: coords,
            gpsLabel: t.currentLocation,
            chooseCityLabel: t.chooseCity,
          );
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenH,
              AppSpacing.sm,
              AppSpacing.screenH,
              AppSpacing.screenBottom,
            ),
            children: [
              Text(
                t.formatFullDate(day.fajr),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '${t.prayerMethodName(ref.watch(resolvedPrayerConventionProvider).method)} · ${t.prayerMadhabName(ref.watch(resolvedPrayerConventionProvider).madhab)}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              _HeroNextPrayer(now: _now, next: next, day: day),
              const SizedBox(height: AppSpacing.md),
              AppSurfaceCard(
                onTap: () => showPrayerCitySheet(context: context, ref: ref),
                child: Row(
                  children: [
                    Icon(Icons.location_on_outlined, color: scheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.prayerLocation,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            location,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: scheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppSurfaceCard(
                onTap: () => context.push('/settings'),
                child: Row(
                  children: [
                    Icon(
                      Icons.notifications_active_outlined,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.prayerReminders,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            settings.prayerNotifications
                                ? t.remindersOn
                                : t.remindersOff,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: scheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
              AppSectionHeader(title: t.todaysTimes, subtitle: location),
              ...day.displayRows.map((e) {
                final isNext = next != null && next.key == e.key;
                final isPast = !day.instant(e.value).isAfter(_now);
                return AppSurfaceCard(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: isNext
                              ? scheme.primary.withValues(alpha: 0.15)
                              : scheme.surfaceContainerHighest.withValues(
                                  alpha: 0.5,
                                ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _iconFor(e.key),
                          color: isNext
                              ? scheme.primary
                              : scheme.onSurfaceVariant,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.prayerName(e.key),
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: isPast && !isNext
                                        ? scheme.onSurfaceVariant
                                        : null,
                                  ),
                            ),
                            if (isNext)
                              Text(
                                t.upNext,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: scheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        t.formatTime(e.value),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: isNext ? scheme.primary : null,
                            ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: AppSpacing.md),
              AppSurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.tips,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      t.prayerTipsBody,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  IconData _iconFor(String name) => switch (name) {
    'Fajr' => Icons.wb_twilight_rounded,
    'Sunrise' => Icons.wb_sunny_outlined,
    'Dhuhr' => Icons.wb_sunny_rounded,
    'Asr' => Icons.wb_cloudy_rounded,
    'Maghrib' => Icons.nightlight_round,
    'Isha' => Icons.dark_mode_rounded,
    'LastThird' => Icons.nights_stay_outlined,
    _ => Icons.mosque_rounded,
  };
}

class _HeroNextPrayer extends StatelessWidget {
  const _HeroNextPrayer({
    required this.now,
    required this.next,
    required this.day,
  });

  final DateTime now;
  final MapEntry<String, DateTime>? next;
  final PrayerTimesDay day;

  @override
  Widget build(BuildContext context) {
    if (next == null) {
      return AppSurfaceCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          AppStrings.of(context).seeYouAtFajr,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      );
    }

    final countdown = AppStrings.of(
      context,
    ).countdown(day.instant(next!.value).difference(now));
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.forest, scheme.primary.withValues(alpha: 0.85)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.forest.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            AppStrings.of(context).nextPrayer,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.of(context).prayerName(next!.key),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppStrings.of(context).formatTime(next!.value),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.accentGold,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                countdown,
                maxLines: 1,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  letterSpacing: 1.2,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
