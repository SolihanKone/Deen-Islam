import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quran/quran.dart' as q;

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_ui.dart';
import '../../duas/domain/dua_item.dart';
import '../../duas/presentation/providers/duas_providers.dart';
import '../../quran/domain/mushaf_translation.dart';
import '../../quran/presentation/providers/quran_prefs_provider.dart';
import '../../settings/presentation/providers/settings_provider.dart';
import '../../tasbeeh/domain/tasbeeh_item.dart';
import '../../tasbeeh/presentation/providers/tasbeeh_providers.dart';
import '../../tasbeeh/presentation/screens/tasbeeh_screen.dart';
import 'widgets/dashboard_prayer_overlay.dart';

/// Stable daily ayah picked from the calendar day (no network).
({int surah, int ayah, String arabic, String translation}) _ayahOfTheDay(
  q.Translation translation,
) {
  final day = DateTime.now().difference(DateTime(2024)).inDays.abs();
  var remaining = (day % 6236) + 1;
  for (var s = 1; s <= 114; s++) {
    final count = q.getVerseCount(s);
    if (remaining <= count) {
      return (
        surah: s,
        ayah: remaining,
        arabic: q.getVerse(s, remaining),
        translation: q.getVerseTranslation(
          s,
          remaining,
          translation: translation,
        ),
      );
    }
    remaining -= count;
  }
  return (
    surah: 1,
    ayah: 1,
    arabic: q.getVerse(1, 1),
    translation: q.getVerseTranslation(1, 1, translation: translation),
  );
}

DuaItem? _duaOfTheDay(List<DuaItem> duas) {
  if (duas.isEmpty) return null;
  final day = DateTime.now().difference(DateTime(2024)).inDays.abs();
  return duas[day % duas.length];
}

TasbeehItem? _tasbeehOfTheDay(List<TasbeehItem> items) {
  if (items.isEmpty) return null;
  final day = DateTime.now().difference(DateTime(2024)).inDays.abs();
  return items[day % items.length];
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final prefs = ref.watch(quranPrefsProvider);
    final settings = ref.watch(settingsProvider);
    final duasAsync = ref.watch(duasListProvider);
    final tasbeehAsync = ref.watch(tasbeehListProvider);
    final strings = AppStrings.of(context);
    final locale = strings.languageCode;
    final ayahToday = _ayahOfTheDay(
      MushafTranslation.fromEditionId(settings.defaultTranslationId),
    );

    void openMushaf() {
      final page = prefs.lastMushafPage ?? 1;
      context.push('/mushaf?page=$page');
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
                child: Stack(
                  fit: StackFit.passthrough,
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 12,
                      child: Image.asset(
                        'assets/mecca.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.55),
                              Colors.black.withValues(alpha: 0.2),
                              Colors.black.withValues(alpha: 0.65),
                            ],
                            stops: const [0, 0.45, 1],
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                        child: Stack(
                          children: [
                            Align(
                              alignment: Alignment.topCenter,
                              child: Text(
                                'Deen Islam',
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(
                                      color:
                                          Colors.white.withValues(alpha: 0.95),
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.3,
                                    ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    strings.formatWeekdayDate(DateTime.now()),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: Colors.white
                                              .withValues(alpha: 0.85),
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  Text(
                                    strings.formatHijriDate(DateTime.now()),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: const Color(0xFFE8C547)
                                              .withValues(alpha: 0.95),
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 26, 8, 22),
                              child: Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: const DashboardPrayerOverlay(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                AppSpacing.md,
                AppSpacing.screenH,
                AppSpacing.screenBottom,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  AppSectionHeader(
                    title: strings.explore,
                    subtitle: strings.exploreSubtitle,
                  ),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1,
                    children: [
                      _DashboardTile(
                        icon: Icons.menu_book_rounded,
                        label: strings.quran,
                        color: scheme.primary,
                        onTap: openMushaf,
                      ),
                      _DashboardTile(
                        icon: Icons.school_rounded,
                        label: strings.learnQuran,
                        color: const Color(0xFF2D6A4F),
                        onTap: () => context.push('/learn-quran'),
                      ),
                      _DashboardTile(
                        icon: Icons.favorite_rounded,
                        label: strings.duas,
                        color: const Color(0xFF9B2335),
                        onTap: () => context.push('/duas'),
                      ),
                      _DashboardTile(
                        icon: Icons.radio_button_checked_rounded,
                        label: strings.tasbeeh,
                        color: const Color(0xFFBC6C25),
                        onTap: () => context.push('/tasbeeh'),
                      ),
                      _DashboardTile(
                        icon: Icons.auto_awesome_rounded,
                        label: strings.namesOfAllah,
                        color: const Color(0xFF0A9396),
                        onTap: () => context.push('/names-of-allah'),
                      ),
                      _DashboardTile(
                        icon: Icons.bookmark_rounded,
                        label: strings.bookmarks,
                        color: const Color(0xFF6B4E71),
                        onTap: () => context.push('/bookmarks'),
                      ),
                      _DashboardTile(
                        icon: Icons.mosque_rounded,
                        label: strings.prayer,
                        color: const Color(0xFF1B4332),
                        onTap: () => context.push('/prayer'),
                      ),
                      _DashboardTile(
                        icon: Icons.explore_rounded,
                        label: strings.qibla,
                        color: const Color(0xFF5C4D7D),
                        onTap: () => context.push('/qibla'),
                      ),
                      _DashboardTile(
                        icon: Icons.settings_rounded,
                        label: strings.settings,
                        color: scheme.secondary,
                        onTap: () => context.push('/settings'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppSurfaceCard(
                    onTap: () => context.push(
                      '/learn-quran/surah/${ayahToday.surah}',
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                strings.ayahOfTheDay,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                strings.surahAyahRef(
                                  ayahToday.surah,
                                  ayahToday.ayah,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.end,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                      color: scheme.primary,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Directionality(
                          textDirection: TextDirection.rtl,
                          child: Text(
                            ayahToday.arabic,
                            textAlign: TextAlign.center,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  height: 1.7,
                                ),
                          ),
                        ),
                        if (locale != 'ar') ...[
                          const SizedBox(height: 8),
                          Text(
                            ayahToday.translation,
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                  height: 1.35,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  duasAsync.maybeWhen(
                    data: (duas) {
                      final dua = _duaOfTheDay(duas);
                      if (dua == null) return const SizedBox.shrink();
                      final duaMeaning = dua.translationFor(locale);
                      return AppSurfaceCard(
                        onTap: () => context.push('/duas'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.favorite_rounded,
                                  size: 18,
                                  color: AppTheme.forest,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    strings.duaOfTheDay,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    dua.titleFor(locale),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.end,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: scheme.primary,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Directionality(
                              textDirection: TextDirection.rtl,
                              child: Text(
                                dua.arabic,
                                textAlign: TextAlign.center,
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      height: 1.7,
                                    ),
                              ),
                            ),
                            if (dua.transliteration.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                dua.transliteration,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      fontStyle: FontStyle.italic,
                                      height: 1.35,
                                    ),
                              ),
                            ],
                            if (duaMeaning.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                duaMeaning,
                                textAlign: TextAlign.center,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                      height: 1.35,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                    orElse: () => const SizedBox.shrink(),
                  ),
                  tasbeehAsync.maybeWhen(
                    data: (items) {
                      final item = _tasbeehOfTheDay(items);
                      if (item == null) return const SizedBox.shrink();
                      return AppSurfaceCard(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => TasbeehCounterScreen(item: item),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.radio_button_checked_rounded,
                                  size: 18,
                                  color: const Color(0xFFBC6C25),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    strings.tasbeehOfTheDay,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    item.titleFor(locale),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.end,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: scheme.primary,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Directionality(
                              textDirection: TextDirection.rtl,
                              child: Text(
                                item.arabic,
                                textAlign: TextAlign.center,
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      height: 1.7,
                                    ),
                              ),
                            ),
                            if (item.transliteration.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                item.transliteration,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      fontStyle: FontStyle.italic,
                                      height: 1.35,
                                    ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Text(
                              item.translationFor(locale),
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                    height: 1.35,
                                  ),
                            ),
                          ],
                        ),
                      );
                    },
                    orElse: () => const SizedBox.shrink(),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardTile extends StatelessWidget {
  const _DashboardTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Center(
                    child: Icon(icon, color: color, size: 36),
                  ),
                ),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
