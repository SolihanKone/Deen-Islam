import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../../core/widgets/async_body.dart';
import '../providers/quran_prefs_provider.dart';
import '../providers/quran_providers.dart';

class SurahListScreen extends ConsumerWidget {
  const SurahListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(surahListProvider);
    final prefs = ref.watch(quranPrefsProvider);
    final scheme = Theme.of(context).colorScheme;
    final t = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.surahs),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => context.push('/learn-quran/search'),
          ),
        ],
      ),
      body: Column(
        children: [
          if (prefs.lastSurah != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, AppSpacing.sm, AppSpacing.screenH, 0),
              child: AppActionTile(
                icon: Icons.history_rounded,
                title: t.continueReading,
                subtitle: t.continueSurahAyah(
                  prefs.lastSurah!,
                  prefs.lastAyahInSurah ?? 1,
                ),
                onTap: () => context.push('/learn-quran/surah/${prefs.lastSurah}'),
              ),
            ),
          Expanded(
            child: AsyncBody(
              async: async,
              onRetry: () => ref.invalidate(surahListProvider),
              data: (context, list) => ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenH,
                  AppSpacing.sm,
                  AppSpacing.screenH,
                  AppSpacing.screenBottom,
                ),
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final s = list[i];
                  return AppSurfaceCard(
                    onTap: () => context.push('/learn-quran/surah/${s.number}'),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${s.number}',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.surahName(s.number),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              Text(
                                '${s.nameArabic} · ${t.ayahsCount(s.numberOfAyahs)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
