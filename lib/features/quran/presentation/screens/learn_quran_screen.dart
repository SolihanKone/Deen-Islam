import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/app_ui.dart';
import '../providers/quran_prefs_provider.dart';

class LearnQuranScreen extends ConsumerWidget {
  const LearnQuranScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(quranPrefsProvider);
    final t = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.learnQuran),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH,
          AppSpacing.sm,
          AppSpacing.screenH,
          AppSpacing.screenBottom,
        ),
        children: [
          AppSectionHeader(
            title: t.explore,
            subtitle: t.studyListenSearch,
          ),
          AppActionTile(
            icon: Icons.format_list_numbered_rounded,
            title: t.browseBySurah,
            subtitle: t.browseBySurahSubtitle,
            onTap: () => context.push('/learn-quran/surahs'),
          ),
          if (prefs.lastSurah != null)
            AppActionTile(
              icon: Icons.history_rounded,
              title: t.continueSurahStudy,
              subtitle: t.continueSurahAyah(
                prefs.lastSurah!,
                prefs.lastAyahInSurah ?? 1,
              ),
              onTap: () => context.push('/learn-quran/surah/${prefs.lastSurah}'),
            ),
          AppActionTile(
            icon: Icons.search_rounded,
            title: t.searchQuran,
            subtitle: t.searchQuranSubtitle,
            onTap: () => context.push('/learn-quran/search'),
          ),
        ],
      ),
    );
  }
}
