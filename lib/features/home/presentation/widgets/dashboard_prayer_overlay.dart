import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../prayer/domain/next_prayer.dart' as prayer_next;
import '../../../prayer/presentation/providers/prayer_providers.dart';
import '../../../prayer/presentation/widgets/prayer_city_sheet.dart';
import '../../../../core/l10n/app_strings.dart';

/// Live next-prayer overlay for the dashboard hero (centered, framed).
class DashboardPrayerOverlay extends ConsumerStatefulWidget {
  const DashboardPrayerOverlay({super.key});

  @override
  ConsumerState<DashboardPrayerOverlay> createState() =>
      _DashboardPrayerOverlayState();
}

class _DashboardPrayerOverlayState
    extends ConsumerState<DashboardPrayerOverlay> {
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
    final strings = AppStrings.of(context);

    return async.when(
      data: (day) {
        final next = prayer_next.nextPrayer(_now, day, tomorrow: tomorrow);
        if (next == null) {
          return _PrayerFrame(
            child: Text(
              strings.allPrayersComplete,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        }
        final countdown = strings.countdown(
          day.instant(next.value).difference(_now),
        );
        return _PrayerFrame(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                strings.nextPrayer,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                strings.prayerName(next.key),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                strings.formatTime(next.value),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: const Color(0xFFE8C547),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  countdown,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => _PrayerFrame(
        child: Text(
          strings.loadingPrayerTimes,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      error: (_, __) => GestureDetector(
        onTap: () => showPrayerCitySheet(context: context, ref: ref),
        child: _PrayerFrame(
          child: Text(
            strings.chooseCity,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _PrayerFrame extends StatelessWidget {
  const _PrayerFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.20),
                  Colors.white.withValues(alpha: 0.08),
                ],
              ),
              border: Border.all(
                color: const Color(0xFFE8C547).withValues(alpha: 0.55),
                width: 1.15,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
